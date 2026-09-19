/// Worlds 0, 2 and 3, as shipped.
///
/// The gate runs at authoring time in `tool/author_world0.dart` and
/// `tool/author_world2.dart` and `tool/author_world3.dart`. It runs again here, over the JSON that actually shipped,
/// because the thing that ships and the thing that was checked have to be the same thing.
///
/// Also the prerequisite edges: with Worlds 0, 1 and 2 present, the concept graph the
/// scheduler walks can be checked for real rather than one world at a time.
library;

import 'dart:convert';
import 'dart:io';

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

ContentPack load(int world) {
  final file = File('../../content/world$world.json');
  if (!file.existsSync()) {
    fail('content/world$world.json is missing — run '
        '`dart run tool/author_world$world.dart` in packages/kodo_content');
  }
  return ContentPack.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, Object?>);
}

PackManifest manifestOf(int world) => PackManifest.fromJson(jsonDecode(
        File('../../content/world$world.manifest.json').readAsStringSync())
    as Map<String, Object?>);

void main() {
  final world0 = load(0);
  final world1 = load(1);
  final world2 = load(2);
  final world3 = load(3);
  final world4 = load(4);
  final world5 = load(5);
  final worlds = {
    0: world0,
    1: world1,
    2: world2,
    3: world3,
    4: world4,
    5: world5,
  };

  group('§6.3 · the shipped worlds carry the committed item volume', () {
    const committed = {
      'C0.1': 18,
      'C0.2': 20,
      'C0.3': 18,
      'C0.4': 18,
      'C1.1': 22,
      'C1.2': 22,
      'C1.3': 20,
      'C1.4': 18,
      'C1.5': 18,
      'C2.1': 22,
      'C2.2': 22,
      'C2.3': 22,
      'C2.4': 18,
      'C3.1': 20,
      'C3.2': 18,
      'C3.3': 22,
      'C3.4': 20,
      'C3.5': 18,
      'C4.1': 22,
      'C4.2': 18,
      'C4.3': 18,
      'C4.4': 22,
      'C4.5': 18,
      'C5.1': 22,
      'C5.2': 22,
      'C5.3': 18,
      'C5.4': 22,
    };

    test('every concept meets or beats the ledger', () {
      for (final entry in committed.entries) {
        final world = int.parse(entry.key.substring(1, 2));
        final n =
            worlds[world]!.items.where((i) => i.conceptId == entry.key).length;
        expect(n, greaterThanOrEqualTo(entry.value),
            reason:
                '${entry.key} has $n items, the ledger commits ${entry.value}');
      }
    });

    test('the six worlds ship 562 items between them', () {
      expect(world0.items, hasLength(80));
      expect(world1.items, hasLength(100));
      expect(world2.items, hasLength(86));
      expect(world3.items, hasLength(100));
      expect(world4.items, hasLength(106));
      expect(world5.items, hasLength(90));
      // 46 % of the 1 214 the curriculum commits across all thirteen worlds.
      expect(worlds.values.fold<int>(0, (n, p) => n + p.items.length), 562);
    });

    test('§6.1 · every concept uses at least five item types', () {
      for (final pack in worlds.values) {
        for (final concept in pack.concepts.keys) {
          final types = pack.items
              .where((i) => i.conceptId == concept)
              .map((i) => i.type)
              .toSet();
          expect(types.length, greaterThanOrEqualTo(5),
              reason: '$concept uses only ${types.length} item types');
        }
      }
    });

    test('item ids are unique across every shipped world', () {
      final ids = [
        for (final pack in worlds.values) ...pack.items.map((i) => i.id)
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('every shipped item passes the publish gate', () {
    for (final entry in {
      0: 'World 0',
      2: 'World 2',
      3: 'World 3',
      4: 'World 4',
      5: 'World 5',
    }.entries) {
      test('${entry.value}, over the JSON that shipped', () {
        final failures = checkBank(worlds[entry.key]!.items);
        expect(failures, isEmpty, reason: failures.take(8).join('\n'));
      });
    }

    test('and every tutorial passes the content gate', () {
      for (final pack in [world0, world2]) {
        final failures = [for (final t in pack.tutorials) ...checkTutorial(t)];
        expect(failures, isEmpty, reason: failures.join('\n'));
      }
    });
  });

  group('the concept graph holds across worlds', () {
    test('every prerequisite names a concept that exists and comes earlier',
        () {
      final known = <String>{
        for (final pack in worlds.values) ...pack.concepts.keys,
      };
      for (final pack in worlds.values) {
        for (final entry in pack.concepts.entries) {
          for (final prerequisite in entry.value) {
            expect(known, contains(prerequisite),
                reason:
                    '${entry.key} needs $prerequisite, which no shipped world has');
            // A prerequisite is in the same world or an earlier one. A forward edge would
            // let the scheduler offer a concept before the thing it is built on.
            final mine = int.parse(entry.key.substring(1, 2));
            final theirs = int.parse(prerequisite.substring(1, 2));
            expect(theirs, lessThanOrEqualTo(mine),
                reason: '${entry.key} depends forwards on $prerequisite');
          }
        }
      }
    });

    test('World 0 has a root, and everything else is reachable from it', () {
      final graph = <String, List<String>>{
        for (final pack in worlds.values) ...pack.concepts,
      };
      final roots = [
        for (final entry in graph.entries)
          if (entry.value.isEmpty) entry.key
      ];
      expect(roots, ['C0.1'],
          reason: 'a curriculum with two starting points has no first lesson');

      final reached = <String>{'C0.1'};
      var changed = true;
      while (changed) {
        changed = false;
        for (final entry in graph.entries) {
          if (reached.contains(entry.key)) continue;
          if (entry.value.every(reached.contains)) {
            reached.add(entry.key);
            changed = true;
          }
        }
      }
      expect(reached, hasLength(graph.length),
          reason: 'unreachable: ${graph.keys.toSet().difference(reached)}');
    });
  });

  group('FR-M14-01 · each world is usable with no network', () {
    for (final entry in worlds.entries) {
      test('World ${entry.key} installs and carries everything it names', () {
        final pack = entry.value;
        final refusal = ContentLibrary().install(pack, manifestOf(entry.key));
        expect(refusal, isNull, reason: refusal?.reason.name);

        // Nothing in a pack may refer to something that has to resolve at run time.
        final serialised = jsonEncode(pack.toJson());
        expect(serialised, isNot(contains('http://')));
        expect(serialised, isNot(contains('https://')));

        // Every tutorial names a concept the pack carries, and every item too.
        for (final tutorial in pack.tutorials) {
          expect(pack.concepts.containsKey(tutorial.conceptId), isTrue);
        }
        for (final item in pack.items) {
          expect(pack.concepts.containsKey(item.conceptId), isTrue,
              reason: '${item.id} names ${item.conceptId}');
        }
      });
    }

    test('FR-M18-02 · every item prompt has a recording key in both languages',
        () {
      for (final pack in worlds.values) {
        for (final item in pack.items) {
          for (final locale in requiredLocales) {
            final key = pack.itemAudioKeys[item.id]?[locale];
            expect(key, isNotNull,
                reason: '${item.id} has no $locale recording');
            expect(pack.audioKeys, contains(key));
          }
        }
      }
    });

    test('FR-M14-02 · each world is inside its 12 MB budget once audio arrives',
        () {
      for (final entry in worlds.entries) {
        final pack = entry.value;
        final withAudio = pack.sizeBytes + pack.audioKeys.length * 40 * 1024;
        expect(withAudio, lessThan(ContentPack.worldBudgetBytes),
            reason: 'World ${entry.key} with audio would be $withAudio bytes');
      }
    });
  });

  group('World 0 teaches what World 0 is for', () {
    test('the palette is five blocks, and no item reaches outside it', () {
      for (final item in world0.items) {
        if (item.paletteScope.isEmpty) continue;
        expect(item.paletteScope, hasLength(5),
            reason: '${item.id} offers ${item.paletteScope.length} blocks');
      }
    });

    test('every prompt is short enough for a six-year-old to be read to', () {
      for (final item in world0.items) {
        for (final locale in requiredLocales) {
          final prompt = item.promptIn(locale);
          // §4.2's twelve-word rule, applied per sentence: a two-sentence prompt is fine,
          // a twenty-word sentence is not.
          for (final sentence in prompt.split(RegExp(r'[.!?]'))) {
            if (sentence.trim().isEmpty) continue;
            final words = sentence.trim().split(RegExp(r'\s+'));
            expect(words.length, lessThanOrEqualTo(Readability.maxWords),
                reason: '${item.id} ($locale): "${sentence.trim()}"');
          }
        }
      }
    });

    test('every reference solution runs and draws something', () {
      for (final item in world0.items) {
        final source = item.referenceSolutionSource;
        if (source == null) continue;
        final parsed = parse(source, KeywordTables.fr);
        expect(parsed.errors, isEmpty, reason: '${item.id}: $source');
        final canvas = HeadlessCanvas();
        final interpreter = Interpreter(parsed.program, canvas)..run();
        expect(interpreter.status, RunStatus.finished, reason: item.id);
        expect(canvas.segments, isNotEmpty,
            reason: '${item.id} draws nothing a child can see');
      }
    });
  });

  maintenanceTests(world0, world2);

  group('World 2 teaches the loop', () {
    test('every concept has items that actually contain a loop', () {
      for (final concept in world2.concepts.keys) {
        final withLoop = world2.items.where((i) {
          if (i.conceptId != concept) return false;
          final source = i.referenceSolutionSource;
          return source != null && source.contains('répète');
        }).length;
        expect(withLoop, greaterThan(0),
            reason: '$concept has no item whose solution uses a loop');
      }
    });

    test('C2.3 is nested loops, so every C2.3 solution nests one', () {
      final withProgram = world2.items
          .where((i) => i.conceptId == 'C2.3')
          .where((i) => (i.referenceSolutionSource ?? '').isNotEmpty)
          .toList();
      // The other four C2.3 items are T3 predictions, which have choices rather than a
      // program — so the claim is about every item that has a solution at all, not a
      // count somebody picked.
      expect(withProgram, hasLength(18));
      for (final item in withProgram) {
        expect('répète'.allMatches(item.referenceSolutionSource!).length,
            greaterThanOrEqualTo(2),
            reason:
                '${item.id} is a C2.3 item whose solution has no nested loop');
      }
    });

    test(
        'C2.4 is the shorter program, so every golf budget is smaller than the '
        'unrolled version', () {
      final golfItems =
          world2.items.where((i) => i.type == ItemType.t7Golf).toList();
      expect(golfItems, isNotEmpty);
      for (final item in golfItems) {
        expect(item.blockBudget, isNotNull, reason: item.id);
        final unrolled = item.wrongSolutionSources.first.split('\n').length;
        expect(item.blockBudget!, lessThan(unrolled),
            reason:
                '${item.id}: a budget of ${item.blockBudget} is not a constraint '
                'against $unrolled lines');
      }
    });

    test('the loop items really do draw what their prompts claim', () {
      for (final item in world2.items) {
        final source = item.referenceSolutionSource;
        if (source == null) continue;
        final parsed = parse(source, KeywordTables.fr);
        expect(parsed.errors, isEmpty, reason: '${item.id}: $source');
        final canvas = HeadlessCanvas();
        final interpreter = Interpreter(parsed.program, canvas)..run();
        expect(interpreter.status, RunStatus.finished,
            reason: '${item.id}: ${interpreter.error?.message('fr')}');
        expect(canvas.segments, isNotEmpty, reason: item.id);
      }
    });
  });

  group('World 5 teaches events, which the language could not say before', () {
    /* The first world KODO was unable to write. D-014 gave the language `quand`, three
       triggers and scripts that take turns; these are the tests that the content really
       uses them and that the grader can tell one answer from another. */

    test('every item declares the trigger it is graded under', () {
      /* Without this every World 5 item grades vacuously: a `quand touche "espace"`
         script never fires under the green flag, so the target and every answer draw
         nothing and all of them pass. */
      for (final item in world5.items.where((i) => i.type.wantsProgram)) {
        if (item.conceptId == 'C5.2') {
          expect(item.runTrigger, startsWith('key:'), reason: item.id);
        } else if (item.conceptId == 'C5.3') {
          expect(item.runTrigger, 'clicked', reason: item.id);
        }
      }
    });

    test('a missing trigger is caught structurally, not behaviourally', () {
      /* A program with no `quand` at all still runs under the flag — it has to, or every
         item in Worlds 0 to 4 stops working — so "you forgot the trigger" draws exactly
         the right picture. The claim is structural and is checked that way. */
      final item = world5.items.firstWhere(
          (i) => i.conceptId == 'C5.1' && i.type == ItemType.t1BuildToTarget);
      expect(item.assertions, isNotEmpty,
          reason: 'the trigger is invisible in the drawing');

      final withoutTrigger = item.referenceSolutionSource!
          .replaceAll(RegExp(r'quand drapeau \{\n'), '')
          .replaceAll(RegExp(r'\n\}$'), '')
          .split('\n')
          .map((l) => l.startsWith('  ') ? l.substring(2) : l)
          .join('\n');
      final verdict = Grader().grade(
          item, ProgramResponse(parse(withoutTrigger, KeywordTables.fr).program));
      expect(verdict.passed, isFalse);
      expect(verdict.situation, DiagnosticSituation.structureMissing,
          reason: 'the figure is right; the way of getting there is not');
    });

    test('C5.4 is about interleaving, so its items run every script', () {
      for (final item in world5.items
          .where((i) => i.conceptId == 'C5.4' && i.type.wantsProgram)) {
        expect(item.runTrigger, 'any', reason: item.id);
      }
    });

    test('every open build shows its rubric before the child starts', () {
      // FR-M6-06. An open build with nothing to meet is a guessing game.
      final builds =
          world5.items.where((i) => i.type == ItemType.t9OpenBuild).toList();
      expect(builds, isNotEmpty);
      for (final item in builds) {
        expect(item.rubric.length, greaterThanOrEqualTo(3), reason: item.id);
        for (final line in item.rubric) {
          expect(line.textKeys['fr'], isNotEmpty, reason: item.id);
          expect(line.textKeys['en'], isNotEmpty, reason: item.id);
        }
      }
    });
  });

  group('World 4 teaches the plane, and a jump is not a move', () {
    /* Authoring this world found two things, and both were in the GRADER rather than in
       the content. The first was structural and is recorded in the items themselves: in
       World 4 every movement command is a JUMP, so the pen is irrelevant — a distractor
       that "forgets pen up" is not a wrong answer here, it is the same answer written
       longer, and the publish gate refused thirty of them. The second is below. */

    test('a jump never draws, so no C4 item depends on the pen', () {
      for (final item in world4.items) {
        for (final source in [
          item.referenceSolutionSource,
          ...item.wrongSolutionSources,
        ]) {
          if (source == null) continue;
          expect(source, isNot(contains('lèvecrayon')),
              reason: '${item.id} handles a pen in a world of jumps');
        }
      }
    });

    test('the grader can see what a program printed', () {
      /* `écris` puts nothing on the canvas. Until the grader compared output, every C4.3
         item graded vacuously: printing the two numbers in the wrong order passed, and so
         did printing only one of them. A world whose third concept is "a position is a
         value" cannot be marked by a comparison that only looks at ink. */
      final item = world4.items.firstWhere((i) =>
          i.conceptId == 'C4.3' && i.type == ItemType.t1BuildToTarget);
      final reference = item.referenceSolutionSource!;
      expect(reference, contains('écris'));

      final grader = Grader();
      expect(
          grader
              .grade(item, ProgramResponse(parse(reference, KeywordTables.fr).program))
              .passed,
          isTrue);

      // The same program printing one number instead of two.
      final truncated =
          reference.split('\n').take(reference.split('\n').length - 1).join('\n');
      final verdict = grader.grade(
          item, ProgramResponse(parse(truncated, KeywordTables.fr).program));
      expect(verdict.passed, isFalse);
      expect(verdict.situation, DiagnosticSituation.wrongOutput);
      expect(verdict.messageFor(item, 'fr'), isNotNull);
    });

    test('C4.1 items pin the pose, because a jump leaves no ink to compare', () {
      for (final item in world4.items.where(
          (i) => i.conceptId == 'C4.1' && i.targetProgramSource != null)) {
        expect(item.requireFinalPose, isTrue, reason: item.id);
      }
    });

    test('every C4.4 solution sets a bearing rather than turning', () {
      for (final item in world4.items.where((i) => i.conceptId == 'C4.4')) {
        final source = item.referenceSolutionSource;
        if (source == null) continue;
        expect(source, contains('direction'),
            reason: '${item.id} teaches absolute heading without using it');
      }
    });
  });

  group('World 3 teaches the pen, and the grader can see it', () {
    /* This world is the reason `compareRaster` learned about colour, pen width, canvas
       colour and canvas size. Before that, every one of its five concepts was a command a
       child could run and a grader could not mark: a blue square graded identically to a
       red one, and the publish gate said so on the first run by refusing thirty-odd items
       whose "wrong" answers passed. These tests are the line holding that fix in place. */

    test('a right shape in the wrong colour does not pass', () {
      final item = world3.items.firstWhere((i) => i.conceptId == 'C3.3' &&
          i.type == ItemType.t1BuildToTarget);
      final reference = item.referenceSolutionSource!;
      // The same program, one channel changed. Nothing else about it moves.
      final recoloured = reference.replaceFirst(
          RegExp(r'couleurcrayon [\d, ]+'), 'couleurcrayon 12, 34, 56');
      expect(recoloured, isNot(reference), reason: 'the substitution must bite');

      final grader = Grader();
      expect(
          grader
              .grade(item, ProgramResponse(parse(reference, KeywordTables.fr).program))
              .passed,
          isTrue);
      expect(
          grader
              .grade(item, ProgramResponse(parse(recoloured, KeywordTables.fr).program))
              .passed,
          isFalse,
          reason: 'a blue square is not a red square');
    });

    test('the message names the colour rather than the shape', () {
      final item = world3.items.firstWhere((i) => i.conceptId == 'C3.3' &&
          i.type == ItemType.t1BuildToTarget);
      final recoloured = item.referenceSolutionSource!.replaceFirst(
          RegExp(r'couleurcrayon [\d, ]+'), 'couleurcrayon 12, 34, 56');
      final verdict =
          Grader().grade(item, ProgramResponse(parse(recoloured, KeywordTables.fr).program));
      expect(verdict.situation, DiagnosticSituation.wrongColour,
          reason: 'telling a child their correct shape is wrong sends them '
              'back to redraw something that was already right');
    });

    test('every C3.3 reference solution actually sets a colour', () {
      for (final item in world3.items.where((i) => i.conceptId == 'C3.3')) {
        final source = item.referenceSolutionSource;
        if (source == null) continue;
        expect(source, contains('couleurcrayon'),
            reason: '${item.id} is a colour item that never sets a colour');
      }
    });

    test('C3.1 is the pen, so every drawing item lifts it', () {
      for (final item in world3.items.where((i) => i.conceptId == 'C3.1')) {
        final source = item.referenceSolutionSource;
        if (source == null) continue;
        expect(source, contains('lèvecrayon'),
            reason: '${item.id} teaches pen up without using it');
      }
    });

    test('C3.5 items pin the pose, because that is the whole difference', () {
      /* `nettoietout` and `initialise` differ only in where Tika ends up. Without
         `requireFinalPose` the grader would accept either one wherever the surviving
         marks happen to coincide, and the concept would be untestable. */
      for (final item in world3.items.where((i) =>
          i.conceptId == 'C3.5' && i.targetProgramSource != null)) {
        expect(item.requireFinalPose, isTrue, reason: item.id);
      }
    });
  });
}

/// `NFR-MAINT-01` — *"adding a world requires no app release"*.
///
/// The claim is now testable rather than architectural, because two worlds were added
/// after every package was built. World 0 and World 2 are content: no `lib/` file in any
/// package changed to make them work, and this test proves the runtime consequence — a
/// pack the code has never seen installs, and its items run, on the shipped engine.
void maintenanceTests(ContentPack world0, ContentPack world2) {
  group('NFR-MAINT-01 · a new world needs no app release', () {
    test('a pack the engine has never seen installs and its items run', () {
      final library = ContentLibrary();
      // Install World 2 into a library that has never held anything.
      final refusal = library.install(world2, manifestOf(2));
      expect(refusal, isNull);

      // And an item out of it grades, on the same grader the app ships.
      const grader = Grader();
      var graded = 0;
      for (final item in world2.items.take(20)) {
        final source = item.referenceSolutionSource;
        if (source == null) continue;
        final parsed = parse(source, KeywordTables.fr);
        expect(parsed.errors, isEmpty);
        expect(
            grader.grade(item, ProgramResponse(parsed.program)).passed, isTrue,
            reason: '${item.id} does not pass on the shipped engine');
        graded++;
      }
      expect(graded, greaterThan(10));
    });

    test('nothing in a pack names a version of the app', () {
      for (final pack in [world0, world2]) {
        final serialised = jsonEncode(pack.toJson());
        // A pack that names an app version is a pack that needs an app release.
        expect(serialised, isNot(contains('appVersion')));
        expect(serialised, isNot(contains('minSdk')));
        expect(serialised, isNot(contains('requiresApp')));
      }
    });

    test('every opcode the packs use is one the shipped engine already has',
        () {
      for (final pack in [world0, world2]) {
        for (final item in pack.items) {
          for (final opcodeId in item.paletteScope) {
            expect(Opcode.byId(opcodeId), isNotNull,
                reason:
                    '${item.id} offers "$opcodeId", which the engine does not have');
          }
        }
      }
    });
  });

}
