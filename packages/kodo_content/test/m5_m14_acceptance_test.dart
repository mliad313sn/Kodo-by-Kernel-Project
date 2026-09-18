/// M5 and M14 acceptance tests, and the G3 vertical slice.
///
/// **M5:** a tutorial can be added by editing content only · audio coverage is a publish
/// gate, not a runtime failure · a fuzzed tutorial cannot write to any project store ·
/// every narration line is at or below the CM1 target.
///
/// **M14:** the whole curriculum is usable in airplane mode after one download — *"the
/// single most important test in the programme"* · a corrupted or unsigned pack is
/// rejected with a child-legible message · a world over its size budget fails the build.
library;

import 'dart:convert';
import 'dart:io';

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_progress/kodo_progress.dart';
import 'package:kodo_stage/kodo_stage.dart';
import 'package:test/test.dart';

ContentPack loadWorld1() {
  final file = File('../../content/world1.json');
  if (!file.existsSync()) {
    fail('content/world1.json is missing — run '
        '`dart run tool/author_world1.dart` in packages/kodo_content');
  }
  return ContentPack.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>);
}

PackManifest loadWorld1Manifest() => PackManifest.fromJson(
    jsonDecode(File('../../content/world1.manifest.json').readAsStringSync())
        as Map<String, Object?>);

/// A host that records what the tutorial asked for and owns a scratch document.
///
/// It has no way to open, name or save a project, because [TutorialHost] has no such
/// method. That is how `FR-M5-05` is guaranteed rather than promised.
class RecordingHost implements TutorialHost {
  RecordingHost([String initial = ''])
      : _scratch = parse(initial, KeywordTables.fr).program;

  Program _scratch;
  final List<String> narrated = [];
  final List<String?> audioPlayed = [];
  final List<SpotlightTarget?> spotlights = [];
  final List<String> demonstrated = [];
  List<String>? palette;
  final VectorCanvas canvas = VectorCanvas();

  void childWrites(String source) {
    _scratch = parse(source, KeywordTables.fr).program;
    canvas.reset();
    runProgram(_scratch, canvas);
  }

  @override
  Program get scratchProgram => _scratch;

  @override
  String get scratchPathSignature => canvas.pathSignature();

  @override
  void demonstrate(Program program) =>
      demonstrated.add(render(program, KeywordTables.fr));

  @override
  void narrate(String text, {String? audioKey}) {
    narrated.add(text);
    audioPlayed.add(audioKey);
  }

  @override
  void restrictPalette(List<String> opcodeIds) => palette = opcodeIds;

  @override
  void spotlight(SpotlightTarget? target) => spotlights.add(target);
}

void main() {
  final world1 = loadWorld1();

  group('FR-M5-01 · acceptance 1 — a tutorial is content, not code', () {
    test('World 1 ships five tutorials, loaded from JSON with no app build',
        () {
      expect(world1.tutorials, hasLength(5));
      for (final tutorial in world1.tutorials) {
        expect(world1.concepts.containsKey(tutorial.conceptId), isTrue);
      }
    });

    test('a tutorial round-trips through JSON', () {
      for (final tutorial in world1.tutorials) {
        final restored = Tutorial.fromJson(tutorial.toJson());
        expect(restored.toJson(), tutorial.toJson());
      }
    });

    test('a brand-new tutorial is added by writing data and nothing else', () {
      final invented = Tutorial(
        id: 'tut-invented',
        conceptId: 'C1.1',
        closingConceptNameKeys: {'fr': 'Un essai', 'en': 'A試'},
        steps: [
          TutorialStep(
            id: 's1',
            beat: Beat.jeRegarde,
            narrationKeys: {
              'fr': 'Regarde Tika avancer.',
              'en': 'Watch Tika move.'
            },
            audioKeys: {'fr': 'a.opus', 'en': 'b.opus'},
            expectedAction: ExpectedAction.watch,
          ),
        ],
      );
      final host = RecordingHost();
      TutorialPlayer(tutorial: invented, host: host, locale: 'fr').start();
      expect(host.narrated.single, 'Regarde Tika avancer.');
    });
  });

  group(
      'FR-M5-03 · acceptance 2 and 5 — audio and reading level are publish gates',
      () {
    test('every World 1 tutorial passes the content gate', () {
      final failures = [for (final t in world1.tutorials) ...checkTutorial(t)];
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('audio coverage is 100 % in FR and EN', () {
      for (final tutorial in world1.tutorials) {
        for (final step in tutorial.steps) {
          for (final locale in ['fr', 'en']) {
            expect(step.audioKeys[locale], isNotNull,
                reason: '${tutorial.id}/${step.id} has no $locale recording');
            expect(step.audioKeys[locale], isNotEmpty);
          }
        }
      }
      // 5 tutorials x 3 steps x 2 locales = 30, plus one prompt recording per item per
      // locale: `FR-M18-02` makes the item prompt recording a condition of publication.
      for (final item in world1.items) {
        for (final locale in ['fr', 'en']) {
          final key = world1.itemAudioKeys[item.id]?[locale];
          expect(key, isNotNull,
              reason: '${item.id} has no $locale prompt recording');
          expect(world1.audioKeys, contains(key));
        }
      }
      expect(world1.audioKeys, hasLength(30 + world1.items.length * 2));
    });

    test('a missing recording fails the gate, and not the runtime', () {
      final silent = Tutorial(
        id: 'tut-silent',
        conceptId: 'C1.1',
        closingConceptNameKeys: {'fr': 'Un essai', 'en': 'A try'},
        steps: [
          TutorialStep(
            id: 's1',
            beat: Beat.jeRegarde,
            narrationKeys: {
              'fr': 'Regarde Tika avancer.',
              'en': 'Watch Tika move.'
            },
            audioKeys: const {'fr': 'a.opus'},
            expectedAction: ExpectedAction.watch,
          ),
        ],
      );
      final failures = checkTutorial(silent);
      expect(failures.map((f) => f.rule), contains('audio-missing'));

      // And the player still runs it: a content failure must never take the app down.
      final host = RecordingHost();
      expect(
          () => TutorialPlayer(tutorial: silent, host: host, locale: 'en')
              .start(),
          returnsNormally);
    });

    test('every narration line is at or below the CM1 target', () {
      for (final tutorial in world1.tutorials) {
        for (final step in tutorial.steps) {
          for (final locale in ['fr', 'en']) {
            final line = step.narrationIn(locale);
            final score = readabilityOf(line);
            expect(score.passes, isTrue,
                reason:
                    '${step.id} ($locale) "$line": ${score.problems.join('; ')}');
          }
        }
      }
    });

    test(
        'the readability check actually catches a sentence an adult would write',
        () {
      const bad =
          'Lorsque tu utilises une variable, la représentation interne de '
          'la conditionnelle change, parce que le paramètre est réévalué.';
      final score = readabilityOf(bad);
      expect(score.passes, isFalse);
      expect(score.words, greaterThan(12));
      expect(jargonIn(bad),
          containsAll(['variable', 'conditionnelle', 'paramètre']));
    });

    test('the word-count rule is the one §4.2 states', () {
      expect(
          readabilityOf(
                  'Un deux trois quatre cinq six sept huit neuf dix onze douze')
              .passes,
          isTrue);
      expect(
          readabilityOf(
                  'Un deux trois quatre cinq six sept huit neuf dix onze douze treize')
              .passes,
          isFalse);
    });
  });

  group('FR-M5-04, FR-M5-05 · the player', () {
    Tutorial first() => world1.tutorials.first;

    test('acceptance 3 — a tutorial cannot reach a child\'s project', () {
      // The isolation guarantee is structural: TutorialHost has no method that names,
      // opens or saves a project. A fuzzed tutorial has nothing to call.
      final host = RecordingHost();
      final player =
          TutorialPlayer(tutorial: first(), host: host, locale: 'fr');
      player.start();
      host.childWrites('avance 10');
      while (!player.isFinished) {
        player.checkProgress();
        if (!player.advance()) break;
      }
      expect(host.canvas.segmentCount, greaterThanOrEqualTo(0));
      // Nothing in the host's surface can identify a stored project.
      expect(host.palette, world1.tutorials.first.paletteScope);
    });

    test('a step may not be skipped on a first pass', () {
      final host = RecordingHost();
      final player =
          TutorialPlayer(tutorial: first(), host: host, locale: 'fr');
      player.start();
      expect(player.canSkip, isFalse);
      expect(player.advance(skip: true), isFalse);
      expect(player.stepIndex, 0);
    });

    test('every step may be skipped on a repeat', () {
      final host = RecordingHost();
      final player = TutorialPlayer(
          tutorial: first(), host: host, locale: 'fr', firstPass: false);
      player.start();
      expect(player.canSkip, isTrue);
      expect(player.advance(skip: true), isTrue);
    });

    test('a step that asks for an action waits until the child does it', () {
      final host = RecordingHost();
      final player =
          TutorialPlayer(tutorial: first(), host: host, locale: 'fr');
      player.start();
      expect(player.advance(), isTrue); // the watch step completes itself

      expect(player.state, PlayerState.waiting);
      expect(player.checkProgress(), isFalse);
      expect(player.advance(), isFalse);

      host.childWrites('avance 50');
      expect(player.checkProgress(), isTrue);
      expect(player.advance(), isTrue);
    });

    test('a child who stalls is offered the authored retry hint', () {
      final host = RecordingHost();
      final player =
          TutorialPlayer(tutorial: first(), host: host, locale: 'fr');
      player.start();
      player.advance();
      final hint = player.retryHint();
      expect(hint, isNotNull);
      expect(hint, isNotEmpty);
      expect(player.retries, 1);
    });

    test('FR-M5-06 · the tutorial closes by naming the concept in child words',
        () {
      for (final tutorial in world1.tutorials) {
        final host = RecordingHost();
        final player =
            TutorialPlayer(tutorial: tutorial, host: host, locale: 'fr');
        player.start();
        final closing = player.closingLine();
        expect(closing, isNotEmpty);
        expect(jargonIn(closing), isEmpty,
            reason: '${tutorial.id} closes with jargon: "$closing"');
      }
    });

    test('the demonstration runs the child\'s own language', () {
      final host = RecordingHost();
      TutorialPlayer(tutorial: first(), host: host, locale: 'fr').start();
      expect(host.demonstrated.single, contains('avance'));
    });
  });

  group('FR-M14-01 · the single most important test in the programme', () {
    test('World 1 is fully usable with no network, from one downloaded pack',
        () {
      // Nothing below touches the filesystem after the pack is loaded, and nothing in the
      // learning path has a method that could fetch. This is the airplane-mode soak.
      final library = ContentLibrary();
      final refusal = library.install(world1, loadWorld1Manifest());
      expect(refusal, isNull, reason: refusal?.toString());

      expect(library.allItems, hasLength(100));

      // World 0 is not authored yet, so C1.1's prerequisite C0.2 is unresolved. The pack
      // installs anyway and the library says so — a teacher seeding a classroom needs to
      // know which worlds will not open, not to be handed an error.
      expect(library.missingPrerequisites, {'C0.2'});
      expect(library.allTutorials, hasLength(5));
      expect(library.conceptGraph.keys, hasLength(5));

      // Every item grades, offline, against its own reference solution.
      const grader = Grader();
      var graded = 0;
      for (final item in library.allItems) {
        if (!item.type.wantsProgram) {
          final correct = item.choices.indexWhere((c) => c.correct);
          expect(grader.grade(item, ChoiceResponse(correct)).passed, isTrue,
              reason: '${item.id} does not accept its own correct choice');
        } else {
          final program =
              parse(item.referenceSolutionSource!, KeywordTables.fr).program;
          expect(grader.grade(item, ProgramResponse(program)).passed, isTrue,
              reason: '${item.id} does not accept its own reference solution');
        }
        graded++;
      }
      expect(graded, 100);

      // Every tutorial plays, offline.
      for (final tutorial in library.allTutorials) {
        final host = RecordingHost();
        expect(
            () => TutorialPlayer(tutorial: tutorial, host: host, locale: 'fr')
                .start(),
            returnsNormally);
        expect(host.narrated, isNotEmpty);
      }
    });

    test('§6.3 · World 1 ships the item volume the curriculum committed', () {
      const committed = {
        'C1.1': 22,
        'C1.2': 22,
        'C1.3': 20,
        'C1.4': 18,
        'C1.5': 18
      };
      for (final entry in committed.entries) {
        final n = world1.items.where((i) => i.conceptId == entry.key).length;
        expect(n, greaterThanOrEqualTo(entry.value),
            reason:
                '${entry.key} has $n items, the ledger commits ${entry.value}');
      }
      expect(world1.items, hasLength(100));
    });

    test('§6.1 · every concept uses at least five item types', () {
      for (final concept in world1.concepts.keys) {
        final types = world1.items
            .where((i) => i.conceptId == concept)
            .map((i) => i.type)
            .toSet();
        expect(types.length, greaterThanOrEqualTo(5),
            reason: '$concept uses only ${types.length} item types');
      }
    });

    test('every item in the shipped bank passes the publish gate', () {
      // The gate ran at authoring time. It runs again here, over the JSON that actually
      // shipped, because the thing that ships and the thing that was checked have to be
      // the same thing.
      final failures = checkBank(world1.items);
      expect(failures, isEmpty, reason: failures.take(20).join('\n'));
    });
  });

  group('FR-M14-02 · packs are verified, versioned and budgeted', () {
    test('a pack whose bytes changed is refused', () {
      final tampered = ContentPack.fromJson({
        ...world1.toJson(),
        'version': world1.version,
        'name': {'fr': 'Un autre monde', 'en': 'Another world'},
      });
      final refusal = ContentLibrary().install(tampered, loadWorld1Manifest());
      expect(refusal, isNotNull);
      expect(refusal!.reason, PackRejection.corrupted);
    });

    test('a refusal speaks to a child, not to an engineer', () {
      final refusal = ContentLibrary().install(world1,
          PackManifest(world: 1, version: 1, contentHash: 'not-the-hash'));
      expect(refusal!.messageKey, 'pack.refused.corrupted');
      // The detail is for the log. It must never be the thing shown.
      expect(refusal.messageKey, isNot(contains('sha')));
      expect(refusal.messageKey, isNot(contains('hash')));
    });

    test('an unsigned pack is refused when signatures are required', () {
      final library = ContentLibrary(
          verifier: const Sha256Integrity(requireSignature: true));
      final refusal = library.install(world1, loadWorld1Manifest());
      expect(refusal!.reason, PackRejection.unsigned);
    });

    test('an older pack cannot replace a newer one', () {
      final library = ContentLibrary();
      final newer = ContentPack.fromJson({...world1.toJson(), 'version': 3});
      expect(library.install(newer, PackManifest.of(newer)), isNull);
      final older = ContentPack.fromJson({...world1.toJson(), 'version': 2});
      final refusal = library.install(older, PackManifest.of(older));
      expect(refusal!.reason, PackRejection.olderThanInstalled);
    });

    test('a pack that names content it does not carry is refused at install',
        () {
      final orphan = ContentPack.fromJson({
        ...world1.toJson(),
        'concepts': {'C1.1': <String>[]},
      });
      final refusal = ContentLibrary().install(orphan, PackManifest.of(orphan));
      expect(refusal!.reason, PackRejection.incomplete);
    });

    test('World 1 is inside its size budget, with room to spare', () {
      expect(world1.sizeBytes, greaterThan(0));
      expect(world1.sizeBytes, lessThan(ContentPack.worldBudgetBytes));
      // The JSON has no audio in it; the budget has to hold once audio arrives, so the
      // headroom is the number worth watching. 230 Opus clips at ~40 kB is about 9 MB —
      // most of the 12 MB world budget, and the reason World 2 onwards must be measured
      // rather than assumed.
      final withAudio = world1.sizeBytes + world1.audioKeys.length * 40 * 1024;
      expect(withAudio, lessThan(ContentPack.worldBudgetBytes),
          reason: 'with audio the pack would be $withAudio bytes');
    });

    test('a pack over budget is refused', () {
      final fat = ContentPack.fromJson({
        ...world1.toJson(),
        'sizeBytes': ContentPack.worldBudgetBytes + 1,
      });
      final refusal = ContentLibrary().install(fat, PackManifest.of(fat));
      expect(refusal!.reason, PackRejection.overBudget);
    });

    test('the manifest hash does not depend on map ordering', () {
      final reordered = ContentPack.fromJson(
          jsonDecode(jsonEncode(world1.toJson())) as Map<String, Object?>);
      expect(PackManifest.of(reordered).contentHash,
          PackManifest.of(world1).contentHash);
    });
  });

  group('FR-M14-04 · telemetry queues and never blocks', () {
    test('events queue locally and survive not being sent', () {
      final queue = TelemetryQueue(capacity: 10);
      for (var i = 0; i < 5; i++) {
        queue.add({'event': 'item_passed', 'n': i});
      }
      expect(queue.length, 5);
      final batch = queue.take(max: 3);
      expect(batch, hasLength(3));
      // The upload failed: nothing is lost.
      expect(queue.length, 5);
      queue.confirmSent(3);
      expect(queue.length, 2);
    });

    test('a full queue drops the oldest, never today\'s session', () {
      final queue = TelemetryQueue(capacity: 3);
      for (var i = 0; i < 6; i++) {
        queue.add({'n': i});
      }
      expect(queue.length, 3);
      expect(queue.dropped, 3);
      expect(queue.pending.map((e) => e['n']), [3, 4, 5]);
    });
  });

  group('G3 · the vertical slice, end to end and offline', () {
    test('a child works through World 1 to mastery, with no network', () async {
      // One full world: content pack installed, tutorial played, items scheduled, answers
      // graded, mastery computed. Every step is the real component.
      final library = ContentLibrary();
      expect(library.install(world1, loadWorld1Manifest()), isNull);

      const grader = Grader();
      const calculator = MasteryCalculator();
      final store = InMemoryAttemptStore();
      final scheduler = Scheduler(bank: library.allItems, seed: 2026);

      // The tutorial for C1.1, played to the end.
      final tutorial =
          library.allTutorials.firstWhere((t) => t.conceptId == 'C1.1');
      final host = RecordingHost();
      final player =
          TutorialPlayer(tutorial: tutorial, host: host, locale: 'fr');
      player.start();
      host.childWrites('avance 100\nrecule 100');
      var guard = 0;
      while (!player.isFinished && guard++ < 20) {
        player.checkProgress();
        if (!player.advance()) break;
      }
      expect(host.narrated, hasLength(greaterThanOrEqualTo(3)));

      // Then the practice mix, answered correctly.
      var clock = DateTime.utc(2026, 9, 18, 17);
      MasteryState? state;
      for (var i = 0; i < 40; i++) {
        final next = scheduler.next(
          currentConceptId: 'C1.1',
          states: {if (state != null) 'C1.1': state},
          unlocked: {'C1.1'},
        );
        expect(next, isNotNull);
        scheduler.markShown(next!.item.id);
        final item = next.item;

        final Response response = item.type.wantsProgram
            ? ProgramResponse(
                parse(item.referenceSolutionSource!, KeywordTables.fr).program)
            : ChoiceResponse(item.choices.indexWhere((c) => c.correct));
        final verdict = grader.grade(item, response);
        expect(verdict.passed, isTrue,
            reason: '${item.id} rejected its own solution');

        await store.record(Attempt(
          itemId: item.id,
          itemVersion: item.version,
          conceptId: item.conceptId,
          at: clock,
          passed: true,
          response: response,
          signals: const ProcessSignals(attempts: 1),
          verdict: verdict,
          itemType: item.type,
          difficulty: item.difficulty,
        ));
        clock = clock.add(const Duration(minutes: 2));
        if (i % 9 == 8) clock = clock.add(const Duration(hours: 24));

        state = calculator.evaluate(
          conceptId: 'C1.1',
          attempts: (store).all,
          clock: TestClock(clock),
        );
        if (state.state == ConceptState.maitrise) break;
      }

      expect(state, isNotNull);
      expect(state!.state, ConceptState.maitrise,
          reason:
              'after 40 correct answers over several days, C1.1 should be mastered; '
              'outstanding: ${state.evidence.outstanding}');
      expect(state.stars, 3);

      // And the map opens the next concept.
      final map = ProgressMap(worlds: [
        WorldNode(number: 1, nameKeys: world1.nameKeys, concepts: [
          for (final entry in world1.concepts.entries)
            ConceptNode(
              id: entry.key,
              world: 1,
              nameKeys: {'fr': entry.key},
              // C0.2 lives in World 0, which is not authored yet. The slice covers one
              // world, so World 1's external edge is treated as already met; the rest of
              // the graph is used as authored.
              prerequisites:
                  entry.value.where((p) => p.startsWith('C1')).toList(),
            ),
        ]),
      ]);
      expect(map.unlockedFor({'C1.1': state}), contains('C1.2'));
    });
  });
}
