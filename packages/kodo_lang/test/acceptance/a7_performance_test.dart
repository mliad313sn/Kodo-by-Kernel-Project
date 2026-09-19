/// Acceptance test 7 — performance.
///
/// *"A 2 000-segment rosette completes in under 2 s on the reference device."*
///
/// **What this test can and cannot prove.** It runs on CI hardware, not on the reference
/// device (Android 11, 2 GB RAM, Snapdragon 4-class). It therefore proves that the
/// interpreter has no pathological cost, and it guards against a regression — it does not
/// discharge the requirement. The reference-device measurement is a named G3 deliverable
/// and is recorded as outstanding in `docs/modules/M1_DONE.md`. Saying so here is cheaper
/// than discovering at G3 that a green tick meant nothing.
///
/// **VM only**, and it is the only file in M1 that is. The rest of the language suite runs
/// in a browser as well, which is how the product's cross-platform promise is kept honest
/// — this one writes its measurements to a file, and a browser has no filesystem. A timing
/// number from a JavaScript runtime would also be measuring the wrong machine.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

/// The rosette of the source manual's main window: `repeat 8 { repeat 4 { … } }`, the
/// figure the World-2 boss is built on.
const _rosette = '''
nettoietout
répète 50 {
  répète 40 {
    avance 8
    tournedroite 9
  }
  tournedroite 7.2
}''';

final _measurements = <String, Object?>{};

void main() {
  tearDownAll(() {
    if (_measurements.isEmpty) return;
    final file = File('build/m1_performance.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(_measurements));
    stdout.writeln('\nM1 performance (CI hardware, not the reference device):');
    _measurements.forEach((k, v) => stdout.writeln('  $k: $v'));
  });

  test('a 2 000-segment rosette runs well inside the budget', () {
    final parsed = parse(_rosette, KeywordTables.fr);
    expect(parsed.errors, isEmpty);

    // Warm the VM so the number reflects steady state rather than first-run compilation.
    runProgram(parsed.program, HeadlessCanvas(),
        limits: const RunLimits(maxSegments: 100000));

    final canvas = HeadlessCanvas();
    final stopwatch = Stopwatch()..start();
    final run = runProgram(parsed.program, canvas,
        limits: const RunLimits(maxSegments: 100000));
    stopwatch.stop();

    expect(run.status, RunStatus.finished);
    expect(canvas.segmentCount, 2000);

    _measurements['rosette_segments'] = canvas.segmentCount;
    _measurements['rosette_ms'] = stopwatch.elapsedMicroseconds / 1000;
    _measurements['rosette_steps'] = run.stepsExecuted;

    // The hard gate from the module prompt. It is generous on CI on purpose: the point of
    // the assertion is to catch an order-of-magnitude regression, and the honest budget
    // for the reference device is measured on the reference device.
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test(
      'NFR-PERF-03 · parsing a large program is fast enough for the toggle budget',
      () {
    // FR-M3-05 / acceptance test 2 of M3: the block-text toggle must complete in 100 ms
    // for a 200-node program on the reference device. Parse and render are the whole cost
    // of that toggle, so their cost is measured here, where they live.
    final source = List.filled(100, 'avance 100\ntournedroite 36').join('\n');
    final warm = parse(source, KeywordTables.fr);
    expect(warm.errors, isEmpty);
    expect(warm.program.body.length, 200);

    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      final parsed = parse(source, KeywordTables.fr);
      render(parsed.program, KeywordTables.en);
    }
    stopwatch.stop();

    final perToggleMs = stopwatch.elapsedMicroseconds / 1000 / 100;
    _measurements['toggle_200_nodes_ms'] = perToggleMs;
    expect(perToggleMs, lessThan(100));
  });

  test('block counting is linear, not quadratic', () {
    // The structural grader calls blockCount on every attempt, and the golf item type
    // (T7) calls it on every keystroke.
    double measure(int statements) {
      final source = List.filled(statements, 'avance 10').join('\n');
      final program = parse(source, KeywordTables.fr).program;
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 200; i++) {
        blockCount(program);
      }
      stopwatch.stop();
      return stopwatch.elapsedMicroseconds / 200;
    }

    measure(50);
    final small = measure(100);
    final large = measure(800);
    _measurements['blockcount_100_us'] = small;
    _measurements['blockcount_800_us'] = large;

    // 8x the input should cost well under 30x the time if the walk is linear.
    expect(large, lessThan(small * 30 + 50));
  });

  test('a stepped run costs about what a full-speed run costs', () {
    // Step mode is what the anti-frustration escalation of §4.7 uses. If stepping were an
    // order of magnitude more expensive, the help offered to a struggling child would be
    // the slowest path in the product.
    final program = parse(_rosette, KeywordTables.fr).program;
    const limits = RunLimits(maxSegments: 100000);

    final full = Stopwatch()..start();
    runProgram(program, HeadlessCanvas(), limits: limits);
    full.stop();

    final stepped = Stopwatch()..start();
    final interpreter = Interpreter(program, HeadlessCanvas(), limits: limits);
    while (interpreter.step()) {}
    stepped.stop();

    _measurements['full_ms'] = full.elapsedMicroseconds / 1000;
    _measurements['stepped_ms'] = stepped.elapsedMicroseconds / 1000;
    expect(stepped.elapsedMicroseconds,
        lessThan(full.elapsedMicroseconds * 8 + 50000));
  });
}
