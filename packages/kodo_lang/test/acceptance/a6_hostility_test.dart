/// Acceptance test 6 — hostility.
///
/// *"A fuzzer of 10 000 malformed programs produces only catalogued errors, no crash, no
/// hang past the guards."*
///
/// The real-world version of this test is an eight-year-old with a phone, and they are
/// more inventive than the fuzzer. What the child must never see is the app disappearing,
/// because §4.7 forbids anything that makes a child feel they broke the computer — which
/// is, verbatim, the misconception concept C11.3 exists to break.
library;

import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

import '../support/generator.dart';

/// Fragments chosen to be individually plausible and jointly nonsensical — the shape of
/// what a child actually types.
final _fragments = <String>[
  'avance',
  'répète',
  '{',
  '}',
  '(',
  ')',
  '[',
  ']',
  '100',
  '-5',
  '3.5',
  '"texte',
  '"fini"',
  r'$x',
  r'$',
  '#note',
  'tournegauche',
  'si',
  'sinon',
  'tantque',
  'apprends',
  'retourne',
  'coupure',
  'sortie',
  'pour',
  'à',
  'pas',
  '=',
  '==',
  '!=',
  '<',
  '>',
  '+',
  '*',
  '/',
  '^',
  'et',
  'ou',
  'non',
  'vrai',
  'faux',
  ',',
  '@',
  '%',
  '&',
  'forward',
  'hasard',
  'attends',
  'écris',
  'va',
  'avnce',
  'Répète',
  'REPETE',
  '\n',
  '\t',
  '',
  '99999999999',
  '0.0000001',
  'é',
  '🐢',
  'a' * 50,
];

String _garbage(SeededRandom random, int pieces) {
  final buffer = StringBuffer();
  for (var i = 0; i < pieces; i++) {
    buffer.write(_fragments[random.nextIntInclusive(0, _fragments.length - 1)]);
    if (random.nextIntInclusive(0, 3) == 0) buffer.write(' ');
  }
  return buffer.toString();
}

/// Corrupts a valid program, which finds different bugs from pure noise: the parser is
/// deepest inside a structure that was nearly right.
String _mutate(String source, SeededRandom random) {
  if (source.isEmpty) return source;
  final at = random.nextIntInclusive(0, source.length - 1);
  switch (random.nextIntInclusive(0, 3)) {
    case 0:
      return source.substring(0, at);
    case 1:
      return source.substring(0, at) +
          _fragments[random.nextIntInclusive(0, _fragments.length - 1)] +
          source.substring(at);
    case 2:
      return source.substring(0, at) + source.substring(at + 1);
    default:
      return source.replaceRange(at, at + 1, '}');
  }
}

void main() {
  test('10 000 malformed programs produce only catalogued errors', () {
    final random = SeededRandom(1312);
    final generator = ProgramGenerator(1312);
    final seen = <ErrorCode>{};
    var parsed = 0;

    for (var i = 0; i < 10000; i++) {
      final source = i.isEven
          ? _garbage(random, random.nextIntInclusive(1, 14))
          : _mutate(render(generator.generate(statements: 3), KeywordTables.fr),
              random);

      late ParseResult result;
      expect(() => result = parse(source, KeywordTables.fr), returnsNormally,
          reason: 'parser threw on:\n$source');

      for (final error in result.errors) {
        expect(ErrorCode.values, contains(error.code));
        expect(error.message('fr'), isNotEmpty);
        expect(error.message('en'), isNotEmpty);
        expect(error.span.line, greaterThanOrEqualTo(1));
        seen.add(error.code);
      }
      parsed++;
    }

    expect(parsed, 10000);
    // A fuzzer that only ever produces one kind of error is not fuzzing.
    expect(seen.length, greaterThanOrEqualTo(5),
        reason: 'the fuzzer reached only $seen');
  });

  test('10 000 malformed programs also run without crashing or hanging', () {
    final random = SeededRandom(90210);
    final generator = ProgramGenerator(90210);
    // Tight ceilings so a 10 000-program soak stays inside a test run. The guard *logic*
    // is what is under test; the shipped numbers are asserted separately below.
    const limits =
        RunLimits(stepsPerSecond: 2000, seconds: 1, maxSegments: 500);

    final stopwatch = Stopwatch()..start();
    for (var i = 0; i < 10000; i++) {
      final source = i.isEven
          ? _garbage(random, random.nextIntInclusive(1, 10))
          : _mutate(render(generator.generate(statements: 3), KeywordTables.fr),
              random);

      expect(() {
        final result = parse(source, KeywordTables.fr);
        final run =
            runProgram(result.program, HeadlessCanvas(), limits: limits);
        final error = run.error;
        if (error != null) expect(ErrorCode.values, contains(error.code));
      }, returnsNormally, reason: 'running threw on:\n$source');
    }
    stopwatch.stop();

    // No hang: 10 000 runs, each individually capped, must finish in reasonable wall time.
    expect(stopwatch.elapsed, lessThan(const Duration(minutes: 2)));
  });

  test('FR-M1-12 · an infinite loop stops at the ceiling instead of hanging',
      () {
    final program =
        parse('tantque vrai {\n  tournedroite 1\n}', KeywordTables.fr).program;
    final run = runProgram(program, HeadlessCanvas());
    expect(run.status, RunStatus.failed);
    expect(run.error!.code, ErrorCode.timeout);
    // FR-M1-12: the ceiling is 50 000 steps/second over 30 seconds, counted in steps so
    // that a slow phone and a fast desktop fail in the same place.
    expect(
        run.stepsExecuted, lessThanOrEqualTo(const RunLimits().maxSteps + 1));
  });

  test(
      'FR-M1-06, FR-M1-12 · runaway recursion stops at depth 200 with a child-legible message',
      () {
    final program =
        parse('apprends creuse {\n  creuse\n}\ncreuse', KeywordTables.fr)
            .program;
    final run = runProgram(program, HeadlessCanvas());
    expect(run.error!.code, ErrorCode.depth);
    expect(run.error!.message('fr'), contains('creuse'));
    expect(run.error!.message('fr').contains('stack'), isFalse);
  });

  test('FR-M1-12 · a runaway drawing stops at the segment ceiling', () {
    final program =
        parse('répète 50000 {\n  avance 1\n}', KeywordTables.fr).program;
    final canvas = HeadlessCanvas();
    final run = runProgram(program, canvas);
    expect(run.error!.code, ErrorCode.segmentLimit);
    expect(canvas.segmentCount,
        lessThanOrEqualTo(const RunLimits().maxSegments + 1));
  });

  test('deeply nested braces do not blow the host stack', () {
    // The parser is recursive descent; 500 levels is far past anything a child builds and
    // well inside what a fuzzer produces.
    final source = '${'répète 2 {' * 500}avance 1${'}' * 500}';
    expect(() => parse(source, KeywordTables.fr), returnsNormally);
  });

  test('every error carries a span inside the source', () {
    final random = SeededRandom(5);
    for (var i = 0; i < 500; i++) {
      final source = _garbage(random, 6);
      for (final error in parse(source, KeywordTables.fr).errors) {
        expect(error.span.start, greaterThanOrEqualTo(0));
        expect(error.span.end, lessThanOrEqualTo(source.length));
        expect(error.span.column, greaterThanOrEqualTo(1));
      }
    }
  });
}
