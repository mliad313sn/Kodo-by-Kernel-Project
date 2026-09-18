/// Acceptance test 4 — step equality.
///
/// *"A program executed in step mode draws the same figure as at full speed, including
/// `attends` and `hasard`."*
///
/// §4.7's anti-frustration doctrine escalates a child who has failed five times to a
/// guided step-through that stops at the divergence point. That only works if stepping
/// shows the same run — otherwise the help shows the child a program they did not write.
library;

import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

import '../support/generator.dart';

String _atFullSpeed(Program program, {int seed = 5}) {
  final canvas = HeadlessCanvas();
  runProgram(program, canvas, seed: seed);
  return canvas.pathSignature();
}

String _oneStepAtATime(Program program, {int seed = 5}) {
  final canvas = HeadlessCanvas();
  final interpreter = Interpreter(program, canvas, seed: seed);
  interpreter.setSpeed(RunSpeed.step);
  var guard = 0;
  while (interpreter.step()) {
    if (++guard > 200000) fail('stepping did not terminate');
  }
  return canvas.pathSignature();
}

void main() {
  test(
      'FR-M1-11 · stepping and running draw the same figure, with wait and random',
      () {
    const source = '''
répète 8 {
  avance hasard 30, 70
  attends 0.2
  tournedroite 45
}''';
    final program = parse(source, KeywordTables.fr).program;
    expect(_oneStepAtATime(program), _atFullSpeed(program));
  });

  test('wait advances a virtual clock, not a real one', () {
    // A stepped run and a full-speed run must agree; a real sleep would make them differ
    // and would also block the UI thread on the reference device.
    final program = parse('attends 3\navance 10', KeywordTables.fr).program;
    final canvas = HeadlessCanvas();
    final stopwatch = Stopwatch()..start();
    final run = runProgram(program, canvas);
    stopwatch.stop();

    expect(run.virtualClockMs, 3000);
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));
  });

  test('FR-M1-11 · 200 generated programs step-equal their full-speed run', () {
    final generator = ProgramGenerator(606);
    for (var i = 0; i < 200; i++) {
      final program = generator.generate();
      expect(_oneStepAtATime(program), _atFullSpeed(program),
          reason: 'program #$i differs between step mode and full speed');
    }
  });

  test('FR-M1-07 · speed can be changed while the program is running', () {
    final program = parse(
            'répète 20 {\n  avance 10\n  tournedroite 18\n}', KeywordTables.fr)
        .program;
    final canvas = HeadlessCanvas();
    final interpreter = Interpreter(program, canvas);

    interpreter.setSpeed(RunSpeed.slow);
    for (var i = 0; i < 10; i++) {
      interpreter.step();
    }
    expect(interpreter.speed, RunSpeed.slow);

    interpreter.setSpeed(RunSpeed.full);
    interpreter.run();

    expect(interpreter.status, RunStatus.finished);
    expect(canvas.pathSignature(), _atFullSpeed(program));
  });

  test('FR-M1-08 · pause and resume leave the drawing unchanged', () {
    final program = parse(
            'répète 12 {\n  avance 40\n  tournegauche 30\n}', KeywordTables.fr)
        .program;
    final canvas = HeadlessCanvas();
    final interpreter = Interpreter(program, canvas);

    for (var i = 0; i < 5; i++) {
      interpreter.step();
    }
    interpreter.pause();
    expect(interpreter.status, RunStatus.paused);
    final midway = canvas.segmentCount;

    interpreter.resume();
    interpreter.run();
    expect(interpreter.status, RunStatus.finished);
    expect(canvas.segmentCount, greaterThan(midway));
    expect(canvas.pathSignature(), _atFullSpeed(program));
  });

  test('FR-M1-08 · stop halts the run and leaves what was drawn', () {
    final program =
        parse('répète 100 {\n  avance 5\n  tournedroite 3\n}', KeywordTables.fr)
            .program;
    final canvas = HeadlessCanvas();
    final interpreter = Interpreter(program, canvas);
    for (var i = 0; i < 6; i++) {
      interpreter.step();
    }
    interpreter.stop();

    expect(interpreter.isDone, isTrue);
    expect(canvas.segmentCount, greaterThan(0));
    expect(canvas.segmentCount, lessThan(100));
  });

  test('FR-M1-11 · a breakpoint stops the run before the marked statement runs',
      () {
    final parsed = parse('avance 10\navance 20\navance 30', KeywordTables.fr);
    final third = parsed.program.body[2] as Node;
    final canvas = HeadlessCanvas();
    final interpreter = Interpreter(parsed.program, canvas);

    interpreter.runUntilBreakpoint({third.id});
    expect(interpreter.status, RunStatus.paused);
    expect(canvas.segmentCount, 2);
  });
}
