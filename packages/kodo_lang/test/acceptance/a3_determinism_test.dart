/// Acceptance test 3 — determinism.
///
/// *"The same program with the same seed produces an identical path signature across 100
/// runs and across all three platforms."*
///
/// Grading depends on this. `FR-M6-09` promises that a fix to an item never retroactively
/// invalidates a child's mastery, and `FR-M6-08` stores the program so an attempt can be
/// replayed. Both are false if the same program can draw two different figures.
library;

import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

import '../support/generator.dart';

void main() {
  test('FR-M1-09 · 100 runs of a random-using program give one signature', () {
    const source = '''
répète 12 {
  avance hasard 20, 60
  tournedroite hasard 10, 90
}''';
    final program = parse(source, KeywordTables.fr).program;

    final signatures = <String>{};
    for (var i = 0; i < 100; i++) {
      final canvas = HeadlessCanvas();
      runProgram(program, canvas, seed: 4242);
      signatures.add(canvas.pathSignature());
    }
    expect(signatures, hasLength(1));
  });

  test('a different seed gives a different drawing', () {
    const source = 'répète 12 {\n  avance hasard 20, 60\n  tournedroite 30\n}';
    final program = parse(source, KeywordTables.fr).program;

    String draw(int seed) {
      final canvas = HeadlessCanvas();
      runProgram(program, canvas, seed: seed);
      return canvas.pathSignature();
    }

    expect(draw(1), isNot(draw(2)));
  });

  test(
      'FR-M1-09 · the generator is byte-stable — this golden catches a platform drift',
      () {
    // If this value ever changes, the random number generator has changed behaviour, and
    // every stored attempt that used `hasard` has silently become unreplayable. It is
    // pinned here so that the failure is a red build rather than a support ticket.
    final random = SeededRandom(4242);
    final rolls = [
      for (var i = 0; i < 10; i++) random.nextIntInclusive(1, 100)
    ];
    expect(rolls, [32, 57, 39, 82, 88, 23, 67, 84, 30, 59]);
  });

  test('FR-M1-09 · 300 generated programs each give one signature over 10 runs',
      () {
    final generator = ProgramGenerator(31337);
    for (var i = 0; i < 300; i++) {
      final program = generator.generate();
      final signatures = <String>{};
      for (var run = 0; run < 10; run++) {
        final canvas = HeadlessCanvas();
        runProgram(program, canvas, seed: 77);
        signatures.add(canvas.pathSignature());
      }
      expect(signatures, hasLength(1),
          reason: 'program #$i is not deterministic');
    }
  });

  test('geometry is exact for the figures World 1 and 2 are built on', () {
    // A square closes, and the turtle comes home. If this drifts, every build-to-target
    // item in Worlds 1-2 drifts with it.
    final canvas = HeadlessCanvas();
    final program = parse(
            'répète 4 {\n  avance 100\n  tournedroite 90\n}', KeywordTables.fr)
        .program;
    runProgram(program, canvas);

    expect(canvas.segmentCount, 4);
    expect(canvas.positionX, closeTo(200, 1e-9));
    expect(canvas.positionY, closeTo(200, 1e-9));
    expect(canvas.direction, closeTo(0, 1e-9));
  });

  test('path signature is order-insensitive, as FR-M6-02 requires', () {
    // G4-001 in the workbook is a real recorded finding: "a correct square built with the
    // turn before the move is graded as failed". The grader must not care.
    String draw(String source) {
      final canvas = HeadlessCanvas();
      runProgram(parse(source, KeywordTables.fr).program, canvas);
      return canvas.pathSignature();
    }

    final clockwise = draw('répète 4 {\n  avance 100\n  tournedroite 90\n}');
    // The same four sides of the same square, begun facing right and turned the other
    // way: identical geometry, opposite drawing order.
    final anticlockwise = draw('''
direction 90
répète 4 {
  avance 100
  tournegauche 90
}''');
    expect(anticlockwise, clockwise);
  });
}
