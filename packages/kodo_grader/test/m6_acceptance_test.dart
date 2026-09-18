/// M6 acceptance tests, from the module prompt.
///
/// 1. Negative testing: every shipped item is failed by ≥3 wrong programs and passed by
///    ≥2 alternative correct programs. A publish gate, not a suggestion.
/// 2. No verdict changes when whitespace, block position or the order of independent
///    statements changes.
/// 3. Grading is fully offline.
/// 4. 100 % of failure messages are authored and localised; a generic string fails CI.
/// 5. Item load-to-interactive ≤ 1.2 s at the 95th percentile on the reference device.
/// 6. A replayed attempt from stored AST reproduces the original verdict exactly.
library;

import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

Program _p(String source) {
  final parsed = parse(source, KeywordTables.fr);
  expect(parsed.errors, isEmpty,
      reason: parsed.errors.map((e) => e.message('fr')).join('\n'));
  return parsed.program;
}

Map<String, String> _bilingual(String fr, String en) => {'fr': fr, 'en': en};

/// A complete, publishable World-2 item: build a hexagon with `répète`.
///
/// It is written out in full rather than with a helper, because the point of several of
/// these tests is precisely that an item carries everything it needs.
Item hexagon({int version = 1}) => Item(
      id: 'C2.1-07',
      version: version,
      conceptId: 'C2.1',
      type: ItemType.t1BuildToTarget,
      difficulty: Difficulty.d3,
      promptKeys: _bilingual(
        'Dessine cette figure à six côtés avec répète.',
        'Draw this six-sided shape using repeat.',
      ),
      targetProgramSource: 'répète 6 {\n  avance 80\n  tournedroite 60\n}',
      referenceSolutionSource: 'répète 6 {\n  avance 80\n  tournedroite 60\n}',
      alternativeSolutionSources: [
        // The same six vertices, walked the other way round. Heading 120 aims at the
        // last vertex of the reference figure, so the hexagon is identical and only the
        // order of the strokes differs — which is exactly what FR-M6-02 says must pass.
        'direction 120\nrépète 6 {\n  avance 80\n  tournegauche 60\n}',
        // Same figure, written with a variable — a shape the tutorial never showed.
        r'$côté = 80'
            '\nrépète 6 {\n'
            r'  avance $côté'
            '\n  tournedroite 60\n}',
      ],
      wrongSolutionSources: [
        'répète 4 {\n  avance 80\n  tournedroite 90\n}',
        'répète 6 {\n  avance 80\n  tournedroite 90\n}',
        'avance 80\ntournedroite 60\navance 80\ntournedroite 60',
      ],
      assertions: const [
        ContainsNode('Repeat'),
        BodyLength('Repeat', min: 2),
      ],
      hints: [
        Hint(
          textKeys: _bilingual(
            'Un hexagone a six côtés. Regarde le nombre dans répète.',
            'A hexagon has six sides. Look at the number in repeat.',
          ),
          spotlightOpcodeId: 'MOVE_FORWARD',
        ),
        Hint(
          textKeys: _bilingual(
            'Pour fermer une figure, tous les tours font 360 en tout.',
            'To close a shape, all the turns add up to 360.',
          ),
        ),
      ],
      diagnostics: [
        DiagnosticPattern(
          when: 'drewTooLittle',
          textKeys: _bilingual(
            'Ta figure a {actual} traits, la cible en a {expected}. Regarde le nombre dans répète.',
            'Your shape has {actual} lines, the target has {expected}. Look at the number in repeat.',
          ),
        ),
        DiagnosticPattern(
          when: 'drewTooMuch',
          textKeys: _bilingual(
            'Ta figure a {actual} traits, la cible en a {expected}. Tu en as dessiné trop.',
            'Your shape has {actual} lines, the target has {expected}. You drew too many.',
          ),
        ),
        DiagnosticPattern(
          when: 'wrongShape',
          textKeys: _bilingual(
            'Ta figure a {actual} traits, la cible en a {expected}. '
                'Regarde le nombre dans répète et le nombre de degrés.',
            'Your shape has {actual} lines, the target has {expected}. '
                'Look at the number in repeat and the number of degrees.',
          ),
        ),
        DiagnosticPattern(
          when: 'structureMissing',
          textKeys: _bilingual(
            'Ça ressemble à la cible, mais il faut utiliser répète pour y arriver.',
            'It looks like the target, but you need to use repeat to get there.',
          ),
        ),
        DiagnosticPattern(
          when: 'programFailed',
          textKeys: _bilingual(
            'Ton programme s\'est arrêté avant la fin. Regarde la ligne en rouge.',
            'Your program stopped before the end. Look at the red line.',
          ),
        ),
      ],
      paletteScope: const ['MOVE_FORWARD', 'TURN_RIGHT', 'TURN_LEFT'],
    );

/// A T8 "explique" item, to cover the choice path and the misconception model.
Item whyItCloses() => Item(
      id: 'C2.1-19',
      version: 1,
      conceptId: 'C2.1',
      type: ItemType.t8Explain,
      difficulty: Difficulty.d4,
      promptKeys: _bilingual(
        'Pourquoi répète 6 { avance 100 tournegauche 60 } ferme la figure ?',
        'Why does repeat 6 { forward 100 turnleft 60 } close the shape?',
      ),
      choices: [
        Choice(
          labelKeys: _bilingual(
              'Parce que 6 fois 60 font 360.', 'Because 6 times 60 is 360.'),
          correct: true,
        ),
        Choice(
          labelKeys: _bilingual('Parce que répète ramène toujours à la maison.',
              'Because repeat always brings you home.'),
          correct: false,
          misconception: 'C2.1-repeat-returns-home',
        ),
        Choice(
          labelKeys: _bilingual('Parce que 6 côtés font un hexagone.',
              'Because 6 sides make a hexagon.'),
          correct: false,
          misconception: 'C2.1-repeat-means-sides',
        ),
      ],
      hints: [
        Hint(
            textKeys: _bilingual(
                'Additionne tous les tours.', 'Add up all the turns.')),
        Hint(
            textKeys: _bilingual('Un tour complet fait 360 degrés.',
                'A full turn is 360 degrees.')),
      ],
      diagnostics: [
        DiagnosticPattern(
          when: 'wrongChoice',
          textKeys: _bilingual(
            'Pas tout à fait. Compte les tours : combien font-ils en tout ?',
            'Not quite. Count the turns: how much do they add up to?',
          ),
        ),
      ],
    );

void main() {
  const grader = Grader();

  group('FR-M6-01 · acceptance 1 — negative testing is a gate', () {
    test('FR-M18-02 · a complete item passes the publish gate', () {
      expect(checkItem(hexagon()), isEmpty,
          reason: checkItem(hexagon()).join('\n'));
      expect(checkItem(whyItCloses()), isEmpty,
          reason: checkItem(whyItCloses()).join('\n'));
    });

    test('the reference solution passes its own item', () {
      final verdict = grader.grade(
          hexagon(), ProgramResponse(_p(hexagon().referenceSolutionSource!)));
      expect(verdict.passed, isTrue);
    });

    test('both alternative correct solutions pass', () {
      for (final source in hexagon().alternativeSolutionSources) {
        final verdict = grader.grade(hexagon(), ProgramResponse(_p(source)));
        expect(verdict.passed, isTrue,
            reason: 'this alternative should pass:\n$source\n'
                'situation: ${verdict.situation}');
      }
    });

    test('all three wrong solutions fail, each with an authored message', () {
      for (final source in hexagon().wrongSolutionSources) {
        final verdict = grader.grade(hexagon(), ProgramResponse(_p(source)));
        expect(verdict.passed, isFalse, reason: 'this should fail:\n$source');
        expect(verdict.messageFor(hexagon(), 'fr'), isNotNull);
        expect(verdict.messageFor(hexagon(), 'en'), isNotNull);
      }
    });

    test(
        'ten deliberately incomplete items are all rejected, each with a reason',
        () {
      // The M18 acceptance test, run here because the rule lives here.
      final broken = <String, Item Function()>{
        'no concept': () => Item(
            id: 'x1',
            version: 1,
            conceptId: '',
            type: ItemType.t1BuildToTarget,
            difficulty: Difficulty.d1,
            promptKeys: _bilingual('a', 'b')),
        'one hint': () => Item(
            id: 'x2',
            version: 1,
            conceptId: 'C1.1',
            type: ItemType.t1BuildToTarget,
            difficulty: Difficulty.d1,
            promptKeys: _bilingual('a', 'b'),
            hints: [Hint(textKeys: _bilingual('a', 'b'))]),
        'no English prompt': () => Item(
            id: 'x3',
            version: 1,
            conceptId: 'C1.1',
            type: ItemType.t1BuildToTarget,
            difficulty: Difficulty.d1,
            promptKeys: const {'fr': 'Dessine.'}),
        'no diagnostic': () => Item(
            id: 'x4',
            version: 1,
            conceptId: 'C1.1',
            type: ItemType.t1BuildToTarget,
            difficulty: Difficulty.d1,
            promptKeys: _bilingual('a', 'b')),
        'generic message': () => Item(
                id: 'x5',
                version: 1,
                conceptId: 'C1.1',
                type: ItemType.t1BuildToTarget,
                difficulty: Difficulty.d1,
                promptKeys: _bilingual('a', 'b'),
                diagnostics: [
                  DiagnosticPattern(
                      when: 'wrongShape',
                      textKeys: _bilingual('Incorrect', 'Wrong'))
                ]),
        'no reference solution': () => Item(
            id: 'x6',
            version: 1,
            conceptId: 'C1.1',
            type: ItemType.t1BuildToTarget,
            difficulty: Difficulty.d1,
            promptKeys: _bilingual('a', 'b')),
        'too few wrong solutions': () {
          final base = hexagon();
          return Item(
              id: 'x7',
              version: 1,
              conceptId: base.conceptId,
              type: base.type,
              difficulty: base.difficulty,
              promptKeys: base.promptKeys,
              targetProgramSource: base.targetProgramSource,
              referenceSolutionSource: base.referenceSolutionSource,
              alternativeSolutionSources: base.alternativeSolutionSources,
              wrongSolutionSources: const ['avance 10'],
              assertions: base.assertions,
              hints: base.hints,
              diagnostics: base.diagnostics);
        },
        'a wrong solution that actually passes': () {
          final base = hexagon();
          return Item(
              id: 'x8',
              version: 1,
              conceptId: base.conceptId,
              type: base.type,
              difficulty: base.difficulty,
              promptKeys: base.promptKeys,
              targetProgramSource: base.targetProgramSource,
              referenceSolutionSource: base.referenceSolutionSource,
              alternativeSolutionSources: base.alternativeSolutionSources,
              // The reference solution, mislabelled as wrong.
              wrongSolutionSources: [
                base.referenceSolutionSource!,
                'avance 1',
                'avance 2'
              ],
              assertions: base.assertions,
              hints: base.hints,
              diagnostics: base.diagnostics);
        },
        'a choice item with two right answers': () => Item(
                id: 'x9',
                version: 1,
                conceptId: 'C2.1',
                type: ItemType.t8Explain,
                difficulty: Difficulty.d2,
                promptKeys: _bilingual('a', 'b'),
                hints: [
                  Hint(textKeys: _bilingual('a', 'b')),
                  Hint(textKeys: _bilingual('c', 'd'))
                ],
                diagnostics: [
                  DiagnosticPattern(
                      when: 'wrongChoice',
                      textKeys: _bilingual('Compte les tours encore une fois.',
                          'Count the turns once more.'))
                ],
                choices: [
                  Choice(labelKeys: _bilingual('a', 'b'), correct: true),
                  Choice(labelKeys: _bilingual('c', 'd'), correct: true),
                ]),
        'a golf item with no budget': () {
          final base = hexagon();
          return Item(
              id: 'x10',
              version: 1,
              conceptId: base.conceptId,
              type: ItemType.t7Golf,
              difficulty: base.difficulty,
              promptKeys: base.promptKeys,
              targetProgramSource: base.targetProgramSource,
              referenceSolutionSource: base.referenceSolutionSource,
              alternativeSolutionSources: base.alternativeSolutionSources,
              wrongSolutionSources: base.wrongSolutionSources,
              assertions: base.assertions,
              hints: base.hints,
              diagnostics: base.diagnostics);
        },
      };

      broken.forEach((why, build) {
        final failures = checkItem(build());
        expect(failures, isNotEmpty, reason: '"$why" should have been refused');
        expect(failures.first.rule.trim(), isNotEmpty);
      });
      expect(broken, hasLength(10));
    });

    test('a bank refuses a duplicated id', () {
      final failures = checkBank([hexagon(), hexagon()]);
      expect(failures.map((f) => f.rule), contains('duplicate-id'));
    });
  });

  group(
      'FR-M6-02 · acceptance 2 — the verdict depends on the program, not its typing',
      () {
    final item = hexagon();
    final reference = item.referenceSolutionSource!;

    test('whitespace does not change the verdict', () {
      final spaced =
          'répète   6   {\n\n\n      avance    80\n\n  tournedroite   60\n\n}\n\n';
      expect(grader.grade(item, ProgramResponse(_p(spaced))).passed, isTrue);
    });

    test('the keyword language does not change the verdict', () {
      // The same program in English keywords is the same program.
      final english = render(_p(reference), KeywordTables.en);
      final parsedEnglish = parse(english, KeywordTables.en);
      expect(parsedEnglish.errors, isEmpty);
      expect(grader.grade(item, ProgramResponse(parsedEnglish.program)).passed,
          isTrue);
    });

    test('abbreviations do not change the verdict', () {
      expect(
          grader
              .grade(
                  item, ProgramResponse(_p('répète 6 {\n  av 80\n  td 60\n}')))
              .passed,
          isTrue);
    });

    test('comments do not change the verdict', () {
      expect(
          grader
              .grade(
                  item,
                  ProgramResponse(_p(
                      '# mon hexagone\nrépète 6 {\n  avance 80\n  # tourne\n  tournedroite 60\n}')))
              .passed,
          isTrue);
    });

    test('the order of independent statements does not change the verdict', () {
      // Two pen settings before the figure, in either order.
      const a =
          'largeurcrayon 1\ncouleurcrayon 0, 0, 0\nrépète 6 {\n  avance 80\n  tournedroite 60\n}';
      const b =
          'couleurcrayon 0, 0, 0\nlargeurcrayon 1\nrépète 6 {\n  avance 80\n  tournedroite 60\n}';
      expect(grader.grade(item, ProgramResponse(_p(a))).passed,
          grader.grade(item, ProgramResponse(_p(b))).passed);
      expect(grader.grade(item, ProgramResponse(_p(a))).passed, isTrue);
    });

    test('grading never compares source strings', () {
      // The reference rendered in English shares almost no characters with the French
      // original, and must still pass. A string-comparing grader cannot survive this.
      final english = render(_p(reference), KeywordTables.en);
      expect(english, isNot(contains('répète')));
      final parsed = parse(english, KeywordTables.en);
      expect(
          grader.grade(item, ProgramResponse(parsed.program)).passed, isTrue);
    });
  });

  group('FR-M6-03 · diagnostics name the observable difference', () {
    final item = hexagon();

    test('a square instead of a hexagon is told, with both numbers', () {
      final verdict = grader.grade(item,
          ProgramResponse(_p('répète 4 {\n  avance 80\n  tournedroite 90\n}')));
      expect(verdict.passed, isFalse);
      final message = verdict.messageFor(item, 'fr')!;
      expect(message, contains('4'));
      expect(message, contains('6'));
      expect(message, contains('répète'));
      expect(message.toLowerCase(), isNot(contains('incorrect')));
    });

    test('the same item answers in English too', () {
      final verdict = grader.grade(item,
          ProgramResponse(_p('répète 4 {\n  avance 80\n  tournedroite 90\n}')));
      expect(verdict.messageFor(item, 'en'), contains('repeat'));
    });

    test(
        'a program that crashes is told that it stopped, not shown the error code',
        () {
      final verdict = grader.grade(item, ProgramResponse(_p(r'avance $rien')));
      expect(verdict.situation, DiagnosticSituation.programFailed);
      expect(verdict.runtimeError!.code, ErrorCode.undefinedVar);
      final message = verdict.messageFor(item, 'fr')!;
      expect(message, isNot(contains('E_')));
    });

    test('the right figure built without the required structure says so', () {
      // Six sides, drawn by hand. Behaviourally right, structurally not what C2.1 teaches.
      final byHand = List.filled(6, 'avance 80\ntournedroite 60').join('\n');
      final verdict = grader.grade(item, ProgramResponse(_p(byHand)));
      expect(verdict.passed, isFalse);
      expect(verdict.situation, DiagnosticSituation.structureMissing);
      expect(verdict.messageFor(item, 'fr'), contains('répète'));
    });
  });

  group('choice items and the misconception model', () {
    final item = whyItCloses();

    test('the right answer passes', () {
      expect(grader.grade(item, const ChoiceResponse(0)).passed, isTrue);
    });

    test('a wrong answer records which wrong idea it evidences', () {
      final verdict = grader.grade(item, const ChoiceResponse(1));
      expect(verdict.passed, isFalse);
      expect(verdict.misconception, 'C2.1-repeat-returns-home');
      expect(verdict.messageFor(item, 'fr'), isNotNull);
    });

    test('an out-of-range choice is a failure, not a crash', () {
      expect(grader.grade(item, const ChoiceResponse(99)).passed, isFalse);
    });
  });

  group('FR-M6-04, NFR-OFF-01 · acceptance 3 — grading is entirely offline',
      () {
    test('200 items grade with no I/O of any kind', () {
      // The package declares no dart:io and no network dependency; the traceability gate
      // enforces that for M1 and the same rule applies here. This test is the behavioural
      // half: a soak that would block on a network call if one existed.
      final item = hexagon();
      final program = _p(item.referenceSolutionSource!);
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 200; i++) {
        expect(grader.grade(item, ProgramResponse(program)).passed, isTrue);
      }
      stopwatch.stop();
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 20)));
    });
  });

  group('FR-M6-07 · acceptance 5 — an item is ready quickly', () {
    test('load-to-graded stays inside the budget at the 95th percentile', () {
      final item = hexagon();
      final program = _p(item.referenceSolutionSource!);
      grader.grade(item, ProgramResponse(program)); // warm

      final samples = <int>[];
      for (var i = 0; i < 100; i++) {
        final stopwatch = Stopwatch()..start();
        // "Load to interactive" for a graded item is: parse the target, run it, be ready
        // to grade. Grading once covers all of it.
        Grader().grade(Item.fromJson(item.toJson()), ProgramResponse(program));
        stopwatch.stop();
        samples.add(stopwatch.elapsedMicroseconds);
      }
      samples.sort();
      final p95 = samples[(samples.length * 0.95).floor()] / 1000.0;
      // The 1.2 s budget is for the reference device; CI is faster and this assertion is a
      // regression guard, not the measurement. The device figure is owed at G3.
      expect(p95, lessThan(1200));
      expect(p95, lessThan(120),
          reason: 'p95 was ${p95}ms — 10x the device budget on CI '
              'means the device will not make it');
    });
  });

  group('FR-M6-08, FR-M6-09 · acceptance 6 — attempts replay exactly', () {
    test('a stored attempt reproduces its verdict', () {
      final item = hexagon();
      final response =
          ProgramResponse(_p('répète 4 {\n  avance 80\n  tournedroite 90\n}'));
      final verdict = grader.grade(item, response);

      final attempt = Attempt(
        itemId: item.id,
        itemVersion: item.version,
        conceptId: item.conceptId,
        at: DateTime.utc(2026, 9, 18),
        passed: verdict.passed,
        response: response,
        signals: const ProcessSignals(attempts: 1, runs: 2),
        verdict: verdict,
        itemType: item.type,
        difficulty: item.difficulty,
      );

      expect(replayReproduces(attempt, item), isTrue);
    });

    test('an attempt stores the program the child actually wrote', () {
      final source = 'répète 3 {\n  avance 80\n  tournedroite 120\n}';
      final response = ProgramResponse(_p(source));
      final json = response.toJson();
      expect(json['kind'], 'program');
      expect((json['ast']! as Map<String, Object?>)['k'], 'Program');
    });

    test('replaying against a newer item version is refused, loudly', () {
      // FR-M6-09: a fix to an item must never retroactively invalidate a mastery. The way
      // that goes wrong silently is re-grading an old attempt against the new item, so
      // the store refuses rather than quietly doing it.
      final item = hexagon();
      final response = ProgramResponse(_p(item.referenceSolutionSource!));
      final attempt = Attempt(
        itemId: item.id,
        itemVersion: 1,
        conceptId: item.conceptId,
        at: DateTime.utc(2026, 9, 18),
        passed: true,
        response: response,
        signals: const ProcessSignals(),
        verdict: grader.grade(item, response),
      );
      expect(() => replayReproduces(attempt, hexagon(version: 2)),
          throwsArgumentError);
    });

    test('the store keeps attempts per concept, newest first', () async {
      final store = InMemoryAttemptStore();
      final item = hexagon();
      final response = ProgramResponse(_p(item.referenceSolutionSource!));
      for (var i = 0; i < 3; i++) {
        await store.record(Attempt(
          itemId: item.id,
          itemVersion: item.version,
          conceptId: item.conceptId,
          at: DateTime.utc(2026, 9, 18 + i),
          passed: true,
          response: response,
          signals: ProcessSignals(attempts: i + 1),
          verdict: grader.grade(item, response),
        ));
      }
      final rows = await store.forConcept('C2.1');
      expect(rows, hasLength(3));
      expect(rows.first.at.day, 20);
    });
  });

  group('§4.7 · the anti-frustration ladder', () {
    test('escalates at three, five and seven, and never punishes', () {
      expect(escalationFor(0), Escalation.none);
      expect(escalationFor(2), Escalation.none);
      expect(escalationFor(3), Escalation.hint);
      expect(escalationFor(4), Escalation.secondHint);
      expect(escalationFor(5), Escalation.guidedStep);
      expect(escalationFor(7), Escalation.doItWithMe);
      expect(escalationFor(30), Escalation.doItWithMe);
      // There is no "locked", no "failed" and no "life lost" to escalate to.
      expect(Escalation.values, hasLength(5));
    });

    test('FR-M6-05 · a hint reduces the search space without giving the answer',
        () {
      final item = hexagon();
      for (final hint in item.hints) {
        final fr = hint.textIn('fr');
        expect(fr, isNotEmpty);
        // The answer is "6"; a hint that contains the literal solution is not a hint.
        expect(fr, isNot(contains('répète 6')));
      }
    });

    test('process signals never decide a verdict', () {
      // The grader's signature cannot even see them, which is the strongest form of this
      // guarantee: it is not a rule someone has to remember.
      final item = hexagon();
      final wrong =
          ProgramResponse(_p('répète 4 {\n  avance 80\n  tournedroite 90\n}'));
      final right = ProgramResponse(_p(item.referenceSolutionSource!));
      expect(grader.grade(item, wrong).passed, isFalse);
      expect(grader.grade(item, right).passed, isTrue);
      expect(
          const ProcessSignals(attempts: 99, hintsShown: 9).isFrustrationEvent,
          isTrue);
    });
  });

  group('items are data', () {
    test('an item round-trips through JSON without losing its grading policy',
        () {
      final original = hexagon();
      final restored = Item.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.assertions, hasLength(original.assertions.length));
      expect(restored.hints, hasLength(2));
      expect(restored.diagnostics, hasLength(original.diagnostics.length));
      expect(checkItem(restored), isEmpty);

      final program = _p(original.referenceSolutionSource!);
      expect(grader.grade(restored, ProgramResponse(program)).passed, isTrue);
    });

    test('an unknown assertion kind is refused rather than ignored', () {
      expect(() => StructuralAssertion.fromJson({'kind': 'vibes'}),
          throwsArgumentError);
    });
  });

  group('the assertion language', () {
    test('bodyLength catches the one-line loop of concept C2.2', () {
      const a = BodyLength('Repeat', min: 2);
      expect(a.check(_p('répète 4 {\n  avance 10\n}')).passed, isFalse);
      expect(
          a.check(_p('répète 4 {\n  avance 10\n  tournedroite 90\n}')).passed,
          isTrue);
      // A comment is not a statement, so it cannot pad a loop body into passing.
      expect(a.check(_p('répète 4 {\n  avance 10\n  # tourne\n}')).passed,
          isFalse);
    });

    test('nestedInside catches concept C2.3', () {
      const a = NestedInside('Repeat', 'Repeat');
      expect(a.check(_p('répète 4 {\n  avance 10\n}')).passed, isFalse);
      expect(
          a
              .check(_p(
                  'répète 8 {\n  répète 4 {\n    avance 10\n  }\n  tournedroite 45\n}'))
              .passed,
          isTrue);
    });

    test('noJumpWithPenDown catches concept C3.1', () {
      const a = NoJumpWithPenDown();
      expect(a.check(_p('baissecrayon\nva 10, 10')).passed, isFalse);
      expect(a.check(_p('lèvecrayon\nva 10, 10\nbaissecrayon')).passed, isTrue);
      expect(a.check(_p('avance 10')).passed, isTrue);
    });

    test('usesOnly enforces a palette scope', () {
      const a = UsesOnly({'MOVE_FORWARD', 'TURN_RIGHT'});
      expect(a.check(_p('avance 10\ntournedroite 90')).passed, isTrue);
      expect(a.check(_p('avance 10\nlèvecrayon')).passed, isFalse);
    });

    test('blockCount powers the golf item type', () {
      const a = BlockCountWithin(max: 3);
      expect(
          a.check(_p('répète 4 {\n  avance 10\n  tournedroite 90\n}')).passed,
          isTrue);
      expect(
          a
              .check(
                  _p('avance 10\ntournedroite 90\navance 10\ntournedroite 90'))
              .passed,
          isFalse);
    });

    test('every assertion round-trips through JSON', () {
      final all = <StructuralAssertion>[
        const ContainsNode('Repeat', min: 1, max: 3),
        const BodyLength('Repeat', min: 2),
        const BlockCountWithin(max: 12),
        const UsesOnly({'MOVE_FORWARD'}),
        const UsesOpcode('TURN_LEFT', min: 2),
        const NoJumpWithPenDown(),
        const NestedInside('Repeat', 'Repeat'),
        const DefinesProcedure(),
        const UsesVariable(),
      ];
      for (final a in all) {
        final restored = StructuralAssertion.fromJson(a.toJson());
        expect(restored.kind, a.kind);
        expect(restored.toJson(), a.toJson());
      }
    });
  });
}
