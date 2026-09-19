// Requirement traceability gate.
//
// The cahier des charges asks that every requirement be "verified by a named test"
// (§14.1) and that every FR be "tagged and traceable" (G1 exit criteria). A spreadsheet
// cannot enforce that; this can.
//
// Three checks, all of which fail the build:
//
//   1. A requirement whose status says it is done must be named in a test file. A green
//      test suite that tests something other than the requirement is the failure mode
//      this exists to catch.
//   2. M1 must import no platform library. "Pure Dart, no platform APIs" is what makes
//      the interpreter's semantics identical on Android, iOS, desktop and WASM, and
//      therefore what makes a grading verdict portable (§11.1).
//   3. Every requirement id referenced in code must exist in the register. A reference to
//      FR-M1-99 means someone is building against a requirement nobody agreed.
//   4. Every concept in the ledger must be expressible in the language (`FR-M21-06`).
//      This one exists because of what D-014 found: M1's prompt specified a language
//      against Worlds 0-4, the curriculum runs to World 12, and nobody compared the two
//      documents line by line because no gate read both. Now one does.
//
// Run: dart tools/trace_check.dart
//
// It is deliberately dependency-free so CI can run it before any `pub get`.

import 'dart:convert';
import 'dart:io';

final _requirementPattern = RegExp(r'\b((?:FR|NFR)-[A-Z0-9]+-\d{2})\b');

/// Libraries that would tie the language core to one platform.
const _forbiddenImports = [
  'dart:io',
  'dart:html',
  'dart:ui',
  'dart:ffi',
  'dart:js',
  'dart:js_interop',
  'package:flutter/',
];

int _failures = 0;

void _fail(String message) {
  stderr.writeln('  FAIL  $message');
  _failures++;
}

void main() {
  final root = Directory.current;
  final registerFile = File('${root.path}/spec/requirements.json');
  if (!registerFile.existsSync()) {
    stderr.writeln('spec/requirements.json is missing — run tools/gen_spec.py');
    exit(2);
  }

  final register =
      jsonDecode(registerFile.readAsStringSync()) as Map<String, Object?>;
  final requirements = (register['requirements']! as List<Object?>)
      .cast<Map<String, Object?>>();
  final known = {for (final r in requirements) r['id']! as String};

  // `app/` is a delivery location like any package: M19 lives there, and a requirement it
  // claims must be named by a test there. Added when the application itself was built —
  // before that there was no application, which is the whole of PO decision D-012.
  final testFiles = [
    ..._dartFiles('${root.path}/packages', within: 'test'),
    ..._dartFiles('${root.path}/app', within: 'test'),
  ];
  final libFiles = [
    ..._dartFiles('${root.path}/packages', within: 'lib'),
    ..._dartFiles('${root.path}/app', within: 'lib'),
  ];

  // --- 1. done requirements are named in a test ------------------------------------------
  final referencedInTests = <String, List<String>>{};
  for (final file in testFiles) {
    for (final match in _requirementPattern.allMatches(
      file.readAsStringSync(),
    )) {
      referencedInTests
          .putIfAbsent(match.group(1)!, () => [])
          .add(_relative(file.path, root.path));
    }
  }

  final done = requirements
      .where((r) => _isDone(r['status'] as String?))
      .toList();
  for (final requirement in done) {
    final id = requirement['id']! as String;
    if (!referencedInTests.containsKey(id)) {
      _fail('$id is marked "${requirement['status']}" but no test names it');
    }
  }

  // --- 2. the language core stays pure ---------------------------------------------------
  for (final file in libFiles) {
    if (!file.path.contains('/kodo_lang/')) continue;
    final source = file.readAsStringSync();
    for (final forbidden in _forbiddenImports) {
      if (RegExp("import\\s+'${RegExp.escape(forbidden)}").hasMatch(source)) {
        _fail(
          '${_relative(file.path, root.path)} imports $forbidden — M1 must stay '
          'platform-free, or grading stops being portable',
        );
      }
    }
  }

  /* --- 3. the learning path never reaches for the network (`NFR-OFF-01`) --------------
  
     "100 % of learning features work offline" is a claim about what the code CANNOT do,
     and the honest way to check it is to look for the ability rather than the use. A
     package that can open a socket will eventually open one — on a launch day, in a
     hurry, with the best of intentions — and a child in a classroom with no signal will
     be the one who finds out.
  
     The packages listed here are the whole learning path: the language, the grader, the
     canvas, the content, progression and the block editor. The app shell is NOT on the
     list, because sync and the parent space are allowed to talk (`FR-M13`), and neither
     is the school package, for the same reason. */
  const offlinePackages = [
    'kodo_lang',
    'kodo_grader',
    'kodo_stage',
    'kodo_content',
    'kodo_progress',
    'kodo_app',
    'kodo_access',
  ];
  const networkImports = [
    'dart:io',
    'package:http/',
    'dart:html',
    'package:web_socket_channel/',
    'package:dio/',
  ];
  var offlineChecked = 0;
  for (final file in libFiles) {
    final package = offlinePackages
        .where((p) => file.path.contains('/$p/lib/'))
        .firstOrNull;
    if (package == null) continue;
    offlineChecked++;
    final source = file.readAsStringSync();
    for (final network in networkImports) {
      // `dart:io` is a file system as well as a socket, and content packs are read from
      // disk. The rule is therefore about the packages that must never need either: the
      // ones above are pure, and the shell hands them what they need.
      if (RegExp("import\\s+'${RegExp.escape(network)}").hasMatch(source)) {
        _fail(
          '${_relative(file.path, root.path)} imports $network — '
          '$package is on the offline learning path (NFR-OFF-01)',
        );
      }
    }
  }
  stdout.writeln(
    'offline: $offlineChecked file(s) on the learning path carry no '
    'way to reach the network',
  );

  // --- 4. no references to requirements nobody agreed ------------------------------------
  for (final file in [...testFiles, ...libFiles]) {
    for (final match in _requirementPattern.allMatches(
      file.readAsStringSync(),
    )) {
      final id = match.group(1)!;
      if (!known.contains(id)) {
        _fail(
          '${_relative(file.path, root.path)} references $id, '
          'which is not in the requirement register',
        );
      }
    }
  }

  // --- report ----------------------------------------------------------------------------
  final byModule = <String, List<Map<String, Object?>>>{};
  for (final requirement in requirements) {
    byModule
        .putIfAbsent(requirement['moduleId']! as String, () => [])
        .add(requirement);
  }

  final report = StringBuffer()
    ..writeln('# Requirement traceability')
    ..writeln()
    ..writeln(
      'Generated by `tools/trace_check.dart`. A requirement is traceable when a '
      'test names it.',
    )
    ..writeln()
    ..writeln('| Module | Requirements | Done | Named by a test |')
    ..writeln('| --- | ---: | ---: | ---: |');

  final moduleIds = byModule.keys.toList()..sort(_moduleOrder);
  for (final moduleId in moduleIds) {
    final rows = byModule[moduleId]!;
    final doneCount = rows.where((r) => _isDone(r['status'] as String?)).length;
    final traced = rows
        .where((r) => referencedInTests.containsKey(r['id']))
        .length;
    report.writeln('| $moduleId | ${rows.length} | $doneCount | $traced |');
  }

  report
    ..writeln()
    ..writeln('## Requirements named by a test')
    ..writeln()
    ..writeln('| Requirement | Status | Named in |')
    ..writeln('| --- | --- | --- |');
  final tracedIds = referencedInTests.keys.toList()..sort();
  for (final id in tracedIds) {
    final requirement = requirements.firstWhere(
      (r) => r['id'] == id,
      orElse: () => <String, Object?>{'status': '—'},
    );
    final files = referencedInTests[id]!.toSet().toList()..sort();
    report.writeln('| $id | ${requirement['status']} | ${files.join(', ')} |');
  }

  final out = File('${root.path}/build/traceability.md');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(report.toString());

  stdout.writeln(
    'traceability: ${requirements.length} requirements, '
    '${done.length} marked done, ${referencedInTests.length} named by a test',
  );
  stdout.writeln('report: build/traceability.md');

  _checkCurriculumIsExpressible(root.path);

  if (_failures > 0) {
    stderr.writeln('\n$_failures traceability failure(s)');
    exit(1);
  }
  stdout.writeln('OK');
}

/// `FR-M21-06` — a concept the language cannot express fails the build.
///
/// The ledger says what each world teaches, in words. This maps those words onto the
/// opcode table and shouts when a world names something the language has no block for.
/// It is a coarse check on purpose: it is looking for a WORLD with no vocabulary at all,
/// which is the failure that actually happened, not for a missing argument.
void _checkCurriculumIsExpressible(String root) {
  final ledgerFile = File('$root/spec/concepts.json');
  final opcodeFile = File('$root/packages/kodo_lang/lib/src/opcodes.dart');
  if (!ledgerFile.existsSync() || !opcodeFile.existsSync()) return;

  final opcodes = opcodeFile.readAsStringSync();
  final keywords =
      File('$root/packages/kodo_lang/lib/src/keywords.dart').existsSync()
      ? File('$root/packages/kodo_lang/lib/src/keywords.dart')
            .readAsStringSync()
      : '';

  /* A concept may need an OPCODE (`WHEN_FLAG`) or a SYNTAX WORD (`while_`). Both are
     vocabulary as far as a curriculum designer is concerned, and checking only the first
     is how this gate would have reported a missing `while` that has been there since M1.
     Syntax words are named with a trailing underscore, which is how they are told apart. */
  bool has(String id) => id.startsWith('syntax:')
      ? keywords.contains('SyntaxWord.${id.substring(7)}')
      : opcodes.contains("'$id'");

  /* What a concept needs, by the words the ledger uses for it. Authored, because the
     ledger is prose written for a curriculum designer and the opcode table is code: the
     bridge between them is a judgement and belongs in one visible place. */
  const needs = <String, List<String>>{
    'green flag': ['WHEN_FLAG'],
    'key pressed': ['WHEN_KEY'],
    'sprite clicked': ['WHEN_CLICKED'],
    'two scripts': ['WHEN_FLAG'],
    'sensing': ['KEY_DOWN', 'MOUSE_X', 'TOUCHING_COLOUR'],
    'costumes': ['NEXT_COSTUME', 'SET_COSTUME'],
    'sounds': ['PLAY_SOUND', 'PLAY_DRUM'],
    'backdrops': ['SET_BACKDROP'],
    'graphic effects': ['SET_EFFECT', 'CLEAR_EFFECTS'],
    'assignment': ['PRINT'],
    'random': ['RANDOM'],
    'while': ['syntax:while_'],
    'if': ['syntax:if_'],
    'else': ['syntax:else_'],
    'define a block': ['syntax:learn'],
    'return': ['syntax:return_'],
    'break': ['syntax:break_'],
    'booleans': ['syntax:true_', 'syntax:false_'],
    'and / or / not': ['syntax:and', 'syntax:or', 'syntax:not'],
  };

  final ledger = jsonDecode(ledgerFile.readAsStringSync());
  final rows = ledger is List
      ? ledger.cast<Map<String, Object?>>()
      : ((ledger as Map<String, Object?>)['concepts']! as List<Object?>)
            .cast<Map<String, Object?>>();

  var checked = 0;
  for (final row in rows) {
    final english = (row['en'] as String? ?? '').toLowerCase();
    for (final entry in needs.entries) {
      if (!english.contains(entry.key)) continue;
      checked++;
      for (final id in entry.value) {
        if (!has(id)) {
          _fail(
            '${row['id']} — "${row['en']}" needs an opcode the language does '
            'not have: $id. A concept the language cannot express is a world '
            'nobody can author (FR-M21-06).',
          );
        }
      }
    }
  }
  stdout.writeln(
    'curriculum: $checked concept(s) checked against the opcode '
    'table, ${rows.length} in the ledger',
  );
}

bool _isDone(String? status) {
  final s = (status ?? '').toLowerCase();
  return s == 'done' || s == 'conforme' || s == 'implemented';
}

int _moduleOrder(String a, String b) {
  final aNum = int.tryParse(a.replaceFirst('M', ''));
  final bNum = int.tryParse(b.replaceFirst('M', ''));
  if (aNum != null && bNum != null) return aNum.compareTo(bNum);
  if (aNum != null) return -1;
  if (bNum != null) return 1;
  return a.compareTo(b);
}

String _relative(String path, String root) =>
    path.startsWith(root) ? path.substring(root.length + 1) : path;

List<File> _dartFiles(String path, {required String within}) {
  final directory = Directory(path);
  if (!directory.existsSync()) return [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => f.path.contains('/$within/'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}
