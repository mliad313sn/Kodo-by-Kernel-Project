/// Acceptance test 5 — the error catalogue.
///
/// *"Every error path is reachable by a test, and every code has an FR and EN message; a
/// test fails the build if any message key is missing."*
///
/// The stronger claim this file also makes is the one `FR-M1-10` actually cares about: no
/// technical string reaches a child. A message is not "localised" because it exists in two
/// languages — it is localised when neither version contains a word from the machine.
library;

import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

/// One reachable source (or tree) per catalogued code.
///
/// The set of keys is asserted to equal `ErrorCode.values`, so adding a code without a way
/// to reach it fails the build.
final Map<ErrorCode, String> _reachableBySource = {
  ErrorCode.unknownCommand: 'avnce 100',
  ErrorCode.unexpectedToken: 'avance 100 @',
  ErrorCode.unclosedBlock: 'répète 4 {\n  avance 100',
  ErrorCode.unclosedString: 'écris "bonjour',
  ErrorCode.badNumber: 'avance 12abc',
  ErrorCode.missingArg: 'avance',
  ErrorCode.argCount: 'va 10',
  ErrorCode.expectedVariable: r'pour = 1 à 5 { avance 10 }',
  ErrorCode.expectedName: 'apprends { avance 10 }',
  ErrorCode.duplicateProc: 'apprends avance { avance 10 }',
  // D-014: a trigger is only ever the head of a script, never a step inside one.
  ErrorCode.eventNested: 'répète 2 {\n  quand drapeau {\n    avance 10\n  }\n}',
  ErrorCode.expectedTrigger: 'quand {\n  avance 10\n}',
  /* A block that needs a stage, run on a plain canvas. This is the one code whose
     message is about the WORLD rather than about the program: the child wrote something
     correct, and there is nothing here for it to act on. */
  ErrorCode.needsStage: 'costumesuivant',
  ErrorCode.type: 'avance "bonjour"',
  ErrorCode.undefinedVar: r'avance $côté',
  ErrorCode.divZero: r'$x = 5 / 0',
  ErrorCode.notAValue: r'$x = avance 100',
  ErrorCode.badIndex: r'$l = [1, 2]' '\n' r'écris $l[5]',
  ErrorCode.negativeCount: 'répète -1 {\n  avance 10\n}',
  ErrorCode.breakOutsideLoop: 'coupure',
  ErrorCode.returnOutsideProc: 'retourne 5',
  ErrorCode.depth: 'apprends boucle {\n  boucle\n}\nboucle',
  ErrorCode.timeout: 'tantque 1 == 1 {\n  tournedroite 1\n}',
  ErrorCode.segmentLimit: 'répète 20000 {\n  avance 1\n}',
};

/// Reached by building the tree directly, because the parser cannot produce it — the block
/// editor can, by deleting a definition that a block still calls.
final Set<ErrorCode> _reachableByTree = {ErrorCode.undefinedProc};

Set<ErrorCode> _codesFrom(String source) {
  final parsed = parse(source, KeywordTables.fr);
  final codes = parsed.errors.map((e) => e.code).toSet();
  if (codes.isNotEmpty) return codes;
  final run = runProgram(parsed.program, HeadlessCanvas());
  final error = run.error;
  return error == null ? {} : {error.code};
}

void main() {
  test('FR-M1-10 · every catalogued code has a French and an English message',
      () {
    for (final locale in ['fr', 'en']) {
      expect(ErrorCatalogue.missingIn(locale), isEmpty,
          reason: 'locale "$locale" is missing messages');
    }
  });

  test('the French and English messages use the same placeholders', () {
    // A translator who drops `{word}` produces a sentence that is grammatical and useless.
    for (final code in ErrorCode.values) {
      expect(ErrorCatalogue.placeholdersOf(code, 'en'),
          ErrorCatalogue.placeholdersOf(code, 'fr'),
          reason: '${code.id} has different placeholders in FR and EN');
    }
  });

  test('every code is reachable, and the reachability table is complete', () {
    final covered = {..._reachableBySource.keys, ..._reachableByTree};
    expect(covered, ErrorCode.values.toSet(),
        reason:
            'a code with no way to reach it is a message nobody has ever read');
  });

  group('each code is actually produced', () {
    _reachableBySource.forEach((code, source) {
      test(code.id, () {
        expect(_codesFrom(source), contains(code),
            reason: 'this source no longer produces ${code.id}:\n$source');
      });
    });

    test('E_UNDEFINED_PROC', () {
      // A block that calls a procedure whose definition has been deleted.
      final call = ProcCall('n1', SourceSpan.none, 'carré', const []);
      final program = Program('n0', SourceSpan.none, [call]);
      final run = runProgram(program, HeadlessCanvas());
      expect(run.error?.code, ErrorCode.undefinedProc);
    });
  });

  test('FR-M1-10 · no message contains a technical string, in either language',
      () {
    // The words below are the ones that actually leak in products like this: they are all
    // perfectly natural to an engineer writing an error at 6pm.
    const banned = [
      'null',
      'undefined',
      'exception',
      'stack',
      'token',
      'parse',
      'ast',
      'opcode',
      'syntax error',
      'invalid',
      'nullptr',
      'index out of',
      'runtime',
      'internal',
    ];
    for (final locale in ['fr', 'en']) {
      for (final code in ErrorCode.values) {
        final text = ErrorCatalogue.byLocale[locale]![code]!.toLowerCase();
        for (final word in banned) {
          expect(text.contains(word), isFalse,
              reason: '${code.id} in $locale contains "$word": $text');
        }
      }
    }
  });

  test('FR-M1-10 · a rendered message never shows an opcode identifier', () {
    // The regression this pins: `args` once carried `MOVE_FORWARD`, and it rendered
    // straight onto the screen inside a French sentence.
    for (final entry in _reachableBySource.entries) {
      final parsed = parse(entry.value, KeywordTables.fr);
      final runtimeError = runProgram(parsed.program, HeadlessCanvas()).error;
      final errors = parsed.errors.isNotEmpty
          ? parsed.errors
          : [if (runtimeError != null) runtimeError];
      for (final error in errors) {
        for (final locale in ['fr', 'en']) {
          final table = KeywordTables.of(locale);
          final text = error.message(locale, keywords: table);
          expect(RegExp(r'[A-Z]{3,}_[A-Z]').hasMatch(text), isFalse,
              reason:
                  '${error.code.id} rendered a machine word in $locale: $text');
          expect(text.trim(), isNotEmpty);
        }
        for (final value in error.args.values) {
          expect(ErrorCatalogue.looksTechnical(value), isFalse,
              reason: '${error.code.id} passes a raw technical value: $value');
        }
      }
    }
  });

  test('an error names the offending line, so the editor can mark it red', () {
    final parsed =
        parse('avance 100\ntournegauche 90\navnce 50', KeywordTables.fr);
    expect(parsed.errors, hasLength(1));
    expect(parsed.errors.single.line, 3);
    expect(parsed.errors.single.repair.kind, RepairKind.didYouMean);
    expect(parsed.errors.single.repair.word, 'avance');
  });

  test('a runtime error names the node, so the block editor can highlight it',
      () {
    final parsed = parse('avance 10\navance "x"', KeywordTables.fr);
    final run = runProgram(parsed.program, HeadlessCanvas());
    final offending = run.error!.nodeId;
    expect(offending, isNotNull);
    expect(walk(parsed.program).map((n) => n.id), contains(offending));
  });

  test('messages read as whole sentences', () {
    // §0 of the prompt library: "Every message is a full sentence at a CE2/CM1 reading
    // level". A fragment cannot be narrated (FR-M16-02) and cannot be translated safely
    // (FR-M15-04 forbids concatenated fragments).
    for (final locale in ['fr', 'en']) {
      for (final code in ErrorCode.values) {
        final text = ErrorCatalogue.byLocale[locale]![code]!;
        expect(text.trimRight(),
            anyOf(endsWith('.'), endsWith('…'), endsWith('!')),
            reason: '${code.id} in $locale is not a sentence: $text');
        final first = text.replaceAll(RegExp(r'^[«"\s]+'), '')[0];
        expect(first, first.toUpperCase(),
            reason:
                '${code.id} in $locale does not start with a capital: $text');
      }
    }
  });

  test('the interpreter never throws across the module boundary', () {
    for (final source in _reachableBySource.values) {
      expect(() {
        final parsed = parse(source, KeywordTables.fr);
        runProgram(parsed.program, HeadlessCanvas());
      }, returnsNormally, reason: source);
    }
  });
}
