/// The verification loop: one check per finding, run until every one is green.
///
/// A review is worth what its findings' fixes are worth, and a fix is worth what proves it
/// is still there next month. Every finding in `docs/reports/G5_FINAL_REVIEW.md` has a
/// check here, named by its id, that fails if the defect comes back. Some of them reach
/// into the repository, some read the built artefacts, and the ones that cannot be decided
/// from a repository at all say so out loud rather than passing quietly.
///
///     dart run tools/verify_findings.dart            # the whole loop
///     dart run tools/verify_findings.dart --web      # include the built-web checks
///
/// The web checks need `flutter build web` to have run; without `--web` they are reported
/// as skipped rather than failed, so the loop is usable on a machine with no Flutter.
library;

import 'dart:convert';
import 'dart:io';

/// What one check concluded.
enum Outcome {
  /// The defect is gone and something here proves it.
  fixed,

  /// The defect is still there.
  open,

  /// Cannot be decided here — a device, a person, a panel. Never silently a pass.
  outOfScope,

  /// Needs an artefact this run did not have.
  skipped,
}

class Finding {
  Finding(this.id, this.title, this.check);
  final String id;
  final String title;
  final (Outcome, String) Function() check;
}

final _root = Directory.current.path;

String _read(String path) => File('$_root/$path').readAsStringSync();
bool _exists(String path) =>
    File('$_root/$path').existsSync() || Directory('$_root/$path').existsSync();

/// What the browser run recorded, if one happened.
Map<String, Object?>? _webRun() {
  final file = File('$_root/build/web_offline.json');
  if (!file.existsSync()) return null;
  try {
    return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  } catch (_) {
    return null;
  }
}

List<Map<String, Object?>> _worlds() {
  final out = <Map<String, Object?>>[];
  for (var world = 0; world <= 12; world++) {
    final file = File('$_root/content/world$world.json');
    if (!file.existsSync()) continue;
    out.add(jsonDecode(file.readAsStringSync()) as Map<String, Object?>);
  }
  return out;
}

Iterable<Map<String, Object?>> _items() sync* {
  for (final pack in _worlds()) {
    for (final item in (pack['items']! as List<Object?>)) {
      yield item! as Map<String, Object?>;
    }
  }
}

void main(List<String> args) {
  final includeWeb = args.contains('--web');

  final findings = <Finding>[
    // ---------------------------------------------------------------- blockers
    Finding('G5-01', 'the right answer is not always in slot 0', () {
      /* The shuffle itself is proved by `choice_order_test.dart` and by a bank-wide test
         in kodo_content. What this checks is the part a test file cannot: that the
         application still routes a tap through it. A shuffle nobody calls is not a fix. */
      final screens = _read('app/lib/src/screens.dart');
      final loop = _read('app/lib/src/learning.dart');
      if (!screens.contains('presentedChoices(item)')) {
        return (
          Outcome.open,
          'the item screen renders the authored order again',
        );
      }
      if (!loop.contains('authoredIndexOf(')) {
        return (Outcome.open, 'the loop grades the displayed index');
      }
      // And the gate that would catch a regression in the content.
      if (!_read('packages/kodo_grader/lib/src/publish_gate.dart')
          .contains("'choice-position'")) {
        return (
          Outcome.open,
          'the publish gate no longer checks answer position',
        );
      }
      var withChoices = 0;
      for (final item in _items()) {
        if (((item['choices'] as List<Object?>?) ?? const []).length >= 2) {
          withChoices++;
        }
      }
      return (
        Outcome.fixed,
        '$withChoices choice items, presented shuffled and gated',
      );
    }),

    Finding('G5-02', 'the app ships every world it carries', () {
      final loader = _read('app/lib/src/pack_loader.dart');
      final declared = RegExp(r'const bundledWorlds = \[([^\]]*)\]')
          .firstMatch(loader)
          ?.group(1);
      if (declared == null) return (Outcome.open, 'bundledWorlds is gone');
      final listed = declared
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toSet();
      final onDisk = <int>{};
      for (var world = 0; world <= 40; world++) {
        if (_exists('app/assets/content/world$world.json')) onDisk.add(world);
      }
      if (listed.length != onDisk.length || !listed.containsAll(onDisk)) {
        return (Outcome.open, 'ships $onDisk, loads $listed');
      }
      var items = 0;
      for (final pack in _worlds()) {
        items += (pack['items']! as List<Object?>).length;
      }
      return (
        Outcome.fixed,
        '${listed.length} worlds, $items exercises reachable',
      );
    }),

    // -------------------------------------------------------------------- high
    Finding('G5-03', 'cold start does not hash the whole bundle', () {
      final loader = _read('app/lib/src/pack_loader.dart');
      if (!loader.contains('_verifyBundled = false')) {
        return (Outcome.open, 'the bundle is re-hashed on every launch');
      }
      if (!loader.contains('verify: true')) {
        return (Outcome.open, 'a sideloaded pack is no longer verified');
      }
      final pack = _read('packages/kodo_content/lib/src/pack.dart');
      if (!pack.contains('bool verify = true')) {
        return (Outcome.open, 'install() no longer defaults to verifying');
      }
      return (Outcome.fixed, 'bundle trusted, sideload verified, default on');
    }),

    Finding('G5-04', 'the web build works with the network off', () {
      if (!_exists('app/web/index.html')) {
        return (Outcome.open, 'no web shell');
      }
      final html = _read('app/web/index.html');
      if (!html.contains("serviceWorker.register('kodo_sw.js')")) {
        return (Outcome.open, 'nothing registers a service worker');
      }
      if (!_exists('app/tool/make_service_worker.dart')) {
        return (Outcome.open, 'the worker generator is gone');
      }
      if (!includeWeb) {
        return (Outcome.skipped, 'pass --web after `flutter build web`');
      }
      if (!_exists('app/build/web/kodo_sw.js')) {
        return (
          Outcome.open,
          'the build carries no worker — run the generator',
        );
      }
      if (_exists('app/build/web/flutter_service_worker.js')) {
        return (
          Outcome.open,
          "Flutter's self-unregistering worker is still deployed",
        );
      }
      /* The proof is a browser, not a grep. `web_offline_check.js` serves the build,
         opens it, cuts the network and asks for a world's exercises. */
      final run = _webRun();
      if (run == null) return (Outcome.skipped, 'no browser run recorded');
      if (run['ran'] != true) {
        return (Outcome.skipped, 'browser run did not happen: ${run['why']}');
      }
      if (run['passed'] != true) {
        return (
          Outcome.open,
          'the browser run failed — see build/web_offline.json',
        );
      }
      final cold =
          (run['steps']! as Map<String, Object?>)['coldStartOffline']!
              as Map<String, Object?>;
      final world = cold['world']! as Map<String, Object?>;
      return (
        Outcome.fixed,
        'offline cold start renders and reads world ${world['world']}, '
            '${world['items']} exercises',
      );
    }),

    Finding('G5-05', 'the web build fetches nothing from a CDN', () {
      /* Found by running the thing: the built app fetched CanvasKit from gstatic.com, so
         it could not start without Google and every child's IP reached a third party. */
      final ci = _read('.github/workflows/ci.yml');
      if (!ci.contains('--no-web-resources-cdn')) {
        return (Outcome.open, 'CI builds web against the CDN');
      }
      if (!includeWeb) {
        return (Outcome.skipped, 'pass --web after `flutter build web`');
      }
      /* The bootstrap carries the CDN's address either way — the branch is dead when the
         flag is set, and grepping for the string reports a defect that is not there. The
         flag decides, and the browser run settles it. */
      if (!_read('app/build/web/flutter_bootstrap.js')
          .contains('"useLocalCanvasKit":true')) {
        return (Outcome.open, 'the build will fetch CanvasKit from a CDN');
      }
      final run = _webRun();
      if (run == null || run['ran'] != true) {
        return (Outcome.skipped, 'no browser run to confirm it');
      }
      final online =
          (run['steps']! as Map<String, Object?>)['online']!
              as Map<String, Object?>;
      final foreign = (online['foreignOrigins']! as List<Object?>);
      if (foreign.isNotEmpty) {
        return (Outcome.open, 'the running app reached $foreign');
      }
      return (
        Outcome.fixed,
        'a real browser run asked no third party for anything',
      );
    }),

    Finding('G5-06', 'the app is called KODO wherever a person can see it', () {
      final manifest = _read('app/android/app/src/main/AndroidManifest.xml');
      if (!manifest.contains('android:label="KODO"')) {
        return (Outcome.open, 'the Android label is not KODO');
      }
      final web =
          jsonDecode(_read('app/web/manifest.json')) as Map<String, Object?>;
      if ('${web['description']}'.contains('Flutter')) {
        return (
          Outcome.open,
          'the web manifest still describes a Flutter project',
        );
      }
      for (final bucket in const [
        'mdpi',
        'hdpi',
        'xhdpi',
        'xxhdpi',
        'xxxhdpi',
      ]) {
        final icon = File(
          '$_root/app/android/app/src/main/res/mipmap-$bucket/ic_launcher.png',
        );
        if (!icon.existsSync()) return (Outcome.open, 'no $bucket icon');
        // Flutter's template icon is 544 bytes. Tika is thousands.
        if (icon.lengthSync() < 4000) {
          return (Outcome.open, '$bucket is still the template logo');
        }
      }
      return (
        Outcome.fixed,
        'name, description and five launcher icons are KODO\'s',
      );
    }),

    // ------------------------------------------------------------------ medium
    Finding('G5-07', 'hashing gives the same number in a browser', () {
      if (!_exists('packages/kodo_lang/lib/src/fnv.dart')) {
        return (Outcome.open, 'the web-safe hash is gone');
      }
      final raster = _read('packages/kodo_stage/lib/src/raster.dart');
      if (raster.contains('0x01000193')) {
        return (Outcome.open, 'Bitmap.hash multiplies past 2^53 again');
      }
      final ci = _read('.github/workflows/ci.yml');
      if (!ci.contains('dart test -p headless')) {
        return (Outcome.open, 'CI no longer runs the core suites in a browser');
      }
      for (final package in const ['kodo_lang', 'kodo_stage', 'kodo_grader']) {
        if (!_exists('packages/$package/dart_test.yaml')) {
          return (Outcome.open, '$package has no browser platform defined');
        }
      }
      return (Outcome.fixed, 'three packages gated on VM and Chrome');
    }),

    Finding(
      'G5-08',
      "a child's work is not backed up to a stranger's account",
      () {
        final manifest = _read('app/android/app/src/main/AndroidManifest.xml');
        if (!manifest.contains('android:allowBackup="false"')) {
          return (Outcome.open, 'automatic backup is on again');
        }
        if (!_exists(
          'app/android/app/src/main/res/xml/data_extraction_rules.xml',
        )) {
          return (Outcome.open, 'no Android 12 extraction rules');
        }
        final declared = RegExp(r'<uses-permission[^>]*android:name="([^"]+)"')
            .allMatches(manifest)
            .map((m) => m.group(1))
            .toList();
        if (declared.isNotEmpty) {
          return (Outcome.open, 'the release build now asks for $declared');
        }
        return (Outcome.fixed, 'no permissions, no backup, no device transfer');
      },
    ),

    Finding('G5-09', 'no question is asked twice', () {
      final seen = <String, String>{};
      final twins = <String>[];
      final prompts = <String, String>{};
      final crossing = <String>[];
      for (final item in _items()) {
        final fingerprint = jsonEncode({
          'p': item['prompt'],
          't': item['target'],
          'r': item['reference'],
          'c': item['choices'],
          'u': item['rubric'],
        });
        final twin = seen[fingerprint];
        if (twin != null) {
          twins.add('${item['id']}=$twin');
        } else {
          seen[fingerprint] = item['id']! as String;
        }
        final prompt =
            ((item['prompt']! as Map<String, Object?>)['fr'] as String? ?? '')
                .trim();
        final owner = prompts[prompt];
        if (owner == null) {
          prompts[prompt] = item['concept']! as String;
        } else if (owner != item['concept']) {
          crossing.add('${item['id']} shares a prompt with $owner');
        }
      }
      if (twins.isNotEmpty || crossing.isNotEmpty) {
        return (Outcome.open, [...twins, ...crossing].take(5).join('; '));
      }
      final templates = _read('packages/kodo_content/lib/src/templates.dart');
      if (!templates.contains('a value with')) {
        return (Outcome.open, 'fillBoth no longer refuses a dead substitution');
      }
      return (
        Outcome.fixed,
        '${seen.length} distinct questions, and fillBoth refuses a dead hole',
      );
    }),

    Finding('G5-10', 'an exported drawing is not a third of a megabyte', () {
      final png = _read('packages/kodo_stage/lib/src/png.dart');
      if (!png.contains('encodeIndexedPng')) {
        return (Outcome.open, 'the indexed encoder is gone');
      }
      if (!png.contains('_deflateFixed')) {
        return (Outcome.open, 'PNG is still written as stored blocks');
      }
      return (Outcome.fixed, 'indexed colour and a real deflate');
    }),

    Finding('G5-11', 'the build is reproducible', () {
      final ci = _read('.github/workflows/ci.yml');
      if (ci.contains('sdk: stable')) {
        return (Outcome.open, 'the Dart SDK floats');
      }
      if (!RegExp(r'sdk: \d+\.\d+\.\d+').hasMatch(ci)) {
        return (Outcome.open, 'no pinned Dart SDK');
      }
      if (!RegExp(r'flutter-version: \d+\.\d+\.\d+').hasMatch(ci)) {
        return (Outcome.open, 'no pinned Flutter');
      }
      return (Outcome.fixed, 'Dart and Flutter pinned');
    }),

    Finding('G5-12', 'a concept is named, not numbered', () {
      /* Found by opening the application and walking it: the screen where a child chooses
         what to learn next listed `C0.1`, `C0.2`, `C0.3`. */
      final screens = _read('app/lib/src/screens.dart');
      if (!screens.contains('conceptNames[id] ?? id')) {
        return (Outcome.open, 'the concept list prints ids');
      }
      if (!_read('app/lib/src/app.dart').contains('conceptNameIn(')) {
        return (Outcome.open, 'nothing supplies the names');
      }
      var named = 0, total = 0;
      for (final pack in _worlds()) {
        final taught = <String>{
          for (final t in (pack['tutorials']! as List<Object?>))
            (t! as Map<String, Object?>)['concept']! as String,
        };
        for (final concept
            in (pack['concepts']! as Map<String, Object?>).keys) {
          total++;
          if (taught.contains(concept)) named++;
        }
      }
      if (named != total) {
        return (Outcome.open, '$named of $total concepts have a name');
      }
      return (Outcome.fixed, 'all $total concepts carry a child-facing name');
    }),

    // ------------------------------------------------- what no repository closes
    Finding(
      'G5-D1',
      'Android base-app size against the 25 MB budget',
      () => (Outcome.outOfScope, 'needs an Android SDK and a release build'),
    ),
    Finding(
      'G5-D2',
      'cold start, item in 1.2 s, 50 force-kills',
      () =>
          (Outcome.outOfScope, 'needs the reference device (Android 11, 2 GB)'),
    ),
    Finding(
      'G5-D3',
      'backdrop import, microphone, screen capture',
      () => (
        Outcome.outOfScope,
        'platform APIs; v1 ships none on purpose — see D-016',
      ),
    ),
    Finding(
      'G5-D4',
      'ghost-path value, phone layout, field test',
      () => (Outcome.outOfScope, 'needs a child panel and a classroom'),
    ),
    Finding(
      'G5-D5',
      'Wolof',
      () => (Outcome.outOfScope, 'v1.2 by the specification itself'),
    ),
  ];

  final results = <String, Object?>{};
  var open = 0, fixed = 0, skipped = 0, out = 0;

  stdout.writeln('KODO — verification loop over ${findings.length} findings\n');
  for (final finding in findings) {
    late Outcome outcome;
    late String detail;
    try {
      (outcome, detail) = finding.check();
    } catch (e) {
      outcome = Outcome.open;
      detail = 'the check itself failed: $e';
    }
    final mark = switch (outcome) {
      Outcome.fixed => 'FIXED   ',
      Outcome.open => 'OPEN  ! ',
      Outcome.outOfScope => 'ELSEWHERE',
      Outcome.skipped => 'SKIPPED ',
    };
    switch (outcome) {
      case Outcome.fixed:
        fixed++;
      case Outcome.open:
        open++;
      case Outcome.skipped:
        skipped++;
      case Outcome.outOfScope:
        out++;
    }
    stdout.writeln('  $mark  ${finding.id}  ${finding.title}');
    stdout.writeln('             $detail');
    results[finding.id] = {
      'title': finding.title,
      'outcome': outcome.name,
      'detail': detail,
    };
  }

  Directory('$_root/build').createSync(recursive: true);
  File('$_root/build/verification.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(results));

  stdout
    ..writeln()
    ..writeln(
      '$fixed fixed · $open open · $skipped skipped · '
      '$out cannot be decided here',
    )
    ..writeln('report: build/verification.json');

  /* Only a genuinely open finding fails the loop. Something that needs a child, a
     classroom or a phone is not a defect this run can close, and pretending otherwise is
     how a green tick comes to mean nothing. */
  if (open > 0) {
    stderr.writeln('\n$open finding(s) still open.');
    exitCode = 1;
  }
}
