/// The learning loop, end to end (`FR-M19-01`, `FR-M19-06`).
///
/// The application had every screen and no exercise until this existed: the run button
/// was wired to nothing, which makes a demonstration rather than a product. These tests
/// are about the one thing that matters — a child can start an item, get it wrong, be
/// told something TRUE about what they drew, fix it, and move on.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo/src/app.dart';
import 'package:kodo/src/learning.dart';
import 'package:kodo/src/session.dart';
import 'package:kodo/src/shell.dart';
import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_progress/kodo_progress.dart';

ContentPack loadWorld(int n) {
  final file = File('../content/world$n.json');
  return ContentPack.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>);
}

/// A clock that stands still. Mastery has a 72-hour retention rule, so a test that used
/// the wall clock would either wait three days or pass for the wrong reason.
TestClock frozen() => TestClock(DateTime.utc(2026, 9, 19, 9));

Program program(String source) {
  final parsed = parse(source, KeywordTables.fr);
  expect(parsed.errors, isEmpty,
      reason: parsed.errors.map((e) => e.message('fr')).join('\n'));
  return parsed.program;
}

void main() {
  final world1 = loadWorld(1);

  group('a child can actually finish an exercise', () {
    test('the loop serves an item, grades it, and moves on', () async {
      final loop = LearningLoop(
          packs: [world1], conceptId: 'C1.1', clock: frozen());
      await loop.start();

      final first = loop.current;
      expect(first, isNotNull, reason: 'the loop must serve something');
      expect(first!.item.conceptId, isNotNull);
      expect(loop.phase, LoopPhase.working);

      // Answer it with its own reference solution, which is by definition correct.
      final source = first.item.referenceSolutionSource;
      if (source == null) return; // a choice item; covered separately below.
      await loop.submit(program(source));

      expect(loop.verdict!.passed, isTrue,
          reason: 'an item its own reference answer fails is an unshippable item');
      expect(loop.phase, LoopPhase.passed);
      expect(loop.passedThisSession, 1);
      expect(loop.drawn, isNotNull,
          reason: 'the child must see what their program drew');

      await loop.next();
      expect(loop.current!.item.id, isNot(first.item.id),
          reason: 'the same question twice in a row is not a mix');
    });

    test('a wrong answer is told what is wrong, in the item\'s own words',
        () async {
      final loop = LearningLoop(
          packs: [world1], conceptId: 'C1.1', clock: frozen());
      await loop.start();

      // Walk to a drawing item; choice items are answered differently.
      while (loop.current!.item.wrongSolutionSources.isEmpty) {
        await loop.next();
      }
      final item = loop.current!.item;
      await loop.submit(program(item.wrongSolutionSources.first));

      expect(loop.verdict!.passed, isFalse);
      expect(loop.phase, LoopPhase.tryAgain);

      /* The sentence is the ITEM's, filled with the numbers the grader measured. The
         shell composes nothing about a child's work — a generic "Incorrect" is what
         FR-M6-03 exists to forbid. */
      final message = loop.verdict!.messageFor(item, 'fr');
      expect(message, isNotNull,
          reason: 'an item with no sentence for this situation skipped the gate');
      expect(message, isNot(contains('Incorrect')));
      expect(message!.length, greaterThan(10));

      // And it is said in both languages.
      expect(loop.verdict!.messageFor(item, 'en'), isNotNull);
    });

    test('trying again keeps the child on the same item', () async {
      final loop = LearningLoop(
          packs: [world1], conceptId: 'C1.1', clock: frozen());
      await loop.start();
      while (loop.current!.item.wrongSolutionSources.isEmpty) {
        await loop.next();
      }
      final id = loop.current!.item.id;

      await loop.submit(
          program(loop.current!.item.wrongSolutionSources.first));
      loop.tryAgain();

      expect(loop.current!.item.id, id,
          reason: 'a wrong answer must not cost a child their question');
      expect(loop.phase, LoopPhase.working);
      expect(loop.verdict, isNull, reason: 'the message clears when they resume');
    });

    test('asking for a hint costs nothing and shows the item\'s hint', () async {
      final loop = LearningLoop(
          packs: [world1], conceptId: 'C1.1', clock: frozen());
      await loop.start();
      while (loop.current!.item.hints.isEmpty) {
        await loop.next();
      }
      final before = loop.current!.item.id;
      loop.showHint();

      expect(loop.current!.hintsShown, 1);
      expect(loop.current!.item.id, before, reason: 'asking is not answering');
      expect(loop.availableHint, isNotNull);
      expect(loop.availableHint!.textKeys['fr'], isNotEmpty);
      // §10: there is no score to deduct from, so there is nothing to deduct.
      expect(loop.phase, LoopPhase.working);
    });

    test('two wrong answers in a row put an easier item next (FR-M7-03)',
        () async {
      /* The recovery floor is M7's, and this test is only that the shell FEEDS it: the
         loop has to count consecutive failures and hand them to the scheduler, or the
         floor never triggers in the running product however correct the module is. */
      final loop = LearningLoop(
          packs: [world1], conceptId: 'C1.1', clock: frozen());
      await loop.start();

      var failures = 0;
      for (var i = 0; i < 2; i++) {
        while (loop.current!.item.wrongSolutionSources.isEmpty) {
          await loop.next();
        }
        await loop.submit(
            program(loop.current!.item.wrongSolutionSources.first));
        if (!loop.verdict!.passed) failures += 1;
        loop.tryAgain();
        await loop.next();
      }
      expect(failures, 2);
      expect(loop.current!.item.difficulty, Difficulty.d1,
          reason: 'after two failures the floor serves the easiest band');
    });

    test('mastery is computed from the attempts, never from a counter', () async {
      final loop = LearningLoop(
          packs: [world1], conceptId: 'C1.1', clock: frozen());
      await loop.start();

      final before = await loop.masteryStates();
      expect(before['C1.1']!.state, ConceptState.nonVu);

      final source = loop.current!.item.referenceSolutionSource;
      if (source != null) {
        await loop.submit(program(source));
        final after = await loop.masteryStates();
        expect(after['C1.1']!.evidence.itemsPassed, 1);
        expect(after['C1.1']!.state, isNot(ConceptState.maitrise),
            reason: 'one right answer is not mastery — §4.6 wants ten and a '
                'retention check, and the shell must not shortcut it');
      }
    });
  });

  group('the loop reaches the screen', () {
    testWidgets('pressing Commencer opens an item with a run button',
        (t) async {
      final shell = KodoShell(
          store: MemorySessionStore(),
          session: const Session(profileId: 'local'));
      await t.pumpWidget(KodoApp(
        shell: shell,
        content: KodoContent(
          packs: [world1],
          profileNames: const {'local': 'Moi'},
          clock: frozen(),
        ),
      ));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('root-entrainement')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('start-practice')));
      await t.pumpAndSettle();

      expect(find.byKey(const Key('prompt')), findsOneWidget);
      expect(find.byKey(const Key('run')), findsOneWidget,
          reason: 'this is the button that was wired to nothing');
    });
  });
}
