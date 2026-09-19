/// Every shipped world, as shipped.
///
/// The publish gate runs at authoring time in `tool/author_world<N>.dart`. It runs again
/// here, over the JSON that actually shipped, because the thing that ships and the thing
/// that was checked have to be the same thing.
///
/// Two rules keep this file from rotting as worlds land, and both were learned the hard
/// way — the first version of it named World 5 in eleven places and quietly stopped
/// checking World 1's publish gate and every tutorial after World 2:
///
///  1. **`shippedWorlds` is the only list.** Every cross-world group iterates it. Adding
///     a world is adding a number.
///  2. **The committed volumes come from `spec/concepts.json`, not from a copy.** §6.3 is
///     a claim about the specification, so the test reads the specification. A table
///     retyped here could agree with itself while disagreeing with the ledger.
///
/// Also the prerequisite edges: with every world present, the concept graph the scheduler
/// walks can be checked for real rather than one world at a time.
library;

import 'dart:convert';
import 'dart:io';

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';
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

/// The ledger, read from the specification rather than retyped beside it.
///
/// Returns concept id → committed minimum, for the concepts of [onlyWorlds].
Map<String, int> ledgerFor(Set<int> onlyWorlds) {
  final file = File('../../spec/concepts.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final concepts = (json['concepts']! as List<Object?>).cast<Map<String, Object?>>();
  return {
    for (final concept in concepts)
      if (onlyWorlds.contains(concept['world'] as int))
        concept['id']! as String: concept['itemsMin']! as int,
  };
}

/// The worlds that have been authored and shipped. **The one list.**
const shippedWorlds = [0, 1, 2, 3, 4, 5, 6, 7, 8];

void main() {
  final worlds = {for (final n in shippedWorlds) n: load(n)};
  final world0 = worlds[0]!;
  final world1 = worlds[1]!;
  final world2 = worlds[2]!;
  final world3 = worlds[3]!;
  final world4 = worlds[4]!;
  final world5 = worlds[5]!;
  final world6 = worlds[6]!;
  final world7 = worlds[7]!;
  final world8 = worlds[8]!;

  group('§6.3 · the shipped worlds carry the committed item volume', () {
    final committed = ledgerFor(shippedWorlds.toSet());

    test('the ledger covers every concept every shipped world declares', () {
      final declared = {
        for (final pack in worlds.values) ...pack.concepts.keys,
      };
      expect(declared.difference(committed.keys.toSet()), isEmpty,
          reason: 'shipped concepts the ledger has never heard of');
      expect(committed.keys.toSet().difference(declared), isEmpty,
          reason: 'concepts the ledger commits that no shipped world carries');
    });

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

    test('the shipped worlds carry 870 items between them', () {
      expect(world0.items, hasLength(80));
      expect(world1.items, hasLength(100));
      expect(world2.items, hasLength(86));
      expect(world3.items, hasLength(100));
      expect(world4.items, hasLength(106));
      expect(world5.items, hasLength(90));
      expect(world6.items, hasLength(108));
      expect(world7.items, hasLength(114));
      expect(world8.items, hasLength(86));
      // 72 % of the 1 214 the curriculum commits across all thirteen worlds.
      expect(worlds.values.fold<int>(0, (n, p) => n + p.items.length), 870);
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
    for (final n in shippedWorlds) {
      test('World $n, over the JSON that shipped', () {
        final failures = checkBank(worlds[n]!.items);
        expect(failures, isEmpty, reason: failures.take(8).join('\n'));
      });

      test('World $n\'s tutorials pass the content gate', () {
        final failures = [
          for (final t in worlds[n]!.tutorials) ...checkTutorial(t)
        ];
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
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

  maintenanceTests(worlds);

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

  /* Three worlds in a row found the same hole in three costumes. World 5: a program with
     no `quand` still runs under the flag, so "you forgot the trigger" drew the right
     picture. World 6: a box is invisible, so "you typed the number" drew the right
     picture. World 7: a test that passes changes nothing, so "you deleted the test" drew
     the right picture.

     Remembering it a fourth time is not a plan, so it is a rule now, checked for every
     world that ships — and for every world that ever will. */
  /* Three worlds in a row found the same hole in three costumes. World 5: a program with
     no `quand` still runs under the flag, so "you forgot the trigger" drew the right
     picture. World 6: a box is invisible, so "you typed the number" drew the right
     picture. World 7: a test that passes changes nothing, so "you deleted the test" drew
     the right picture.

     Remembering it a fourth time is not a plan, so it is a rule now, checked for every
     world that ships — and for every world that ever will. */
  group('a world whose subject the canvas cannot show says so structurally', () {
    for (final n in [5, 6, 7, 8]) {
      test('World $n\'s drawing items carry a structural claim', () {
        final items = worlds[n]!.items.where((i) =>
            i.type.wantsProgram &&
            i.type != ItemType.t9OpenBuild &&
            i.targetProgramSource != null);
        expect(items, isNotEmpty);
        final bare = items.where((i) => i.assertions.isEmpty).toList();
        // Not every item: a world has plenty whose whole content IS the picture. But the
        // majority, because the majority of these three worlds is not the picture.
        expect(bare.length, lessThan(items.length / 2),
            reason: '${bare.length} of ${items.length} items in World $n are '
                'graded on the drawing alone');
      });

      test('World $n\'s structural claims are each disproved by a distractor', () {
        /* An assertion nobody can fail is decoration: if no wrong answer trips it,
           deleting it would change nothing and nothing would notice.

           T4 is excluded, and the reason is not a concession. In a fill-the-gap the
           child is given the program and writes only the hole, so every distractor is
           the same program with a different number in it — the assertion there is a
           guard against a submission that is not the template at all, not a claim any
           authored distractor could disprove. Everywhere the child writes the whole
           program, the claim has to be earned. */
        var proved = 0;
        var claimed = 0;
        for (final item in worlds[n]!.items) {
          if (item.assertions.isEmpty) continue;
          if (item.type == ItemType.t4FillTheGap) continue;
          claimed++;
          for (final source in item.wrongSolutionSources) {
            final parsed = parse(source, KeywordTables.fr);
            if (parsed.errors.isNotEmpty) continue;
            if (item.assertions.any((a) => !a.check(parsed.program).passed)) {
              proved++;
              break;
            }
          }
        }
        expect(claimed, greaterThan(10));
        expect(proved, claimed,
            reason: 'only $proved of $claimed items in World $n prove their '
                'own structural claim');
      });
    }
  });

  group('World 8 teaches the loop that watches', () {
    test('C8.2 ships programs that do not finish, and grades them as such', () {
      /* The one concept in KODO whose best item is a program that runs away. If the
         broken programs all ended politely with a wrong picture, the child would never
         see that not stopping is a way to be wrong. */
      final runaways = world8.items.where((item) {
        if (item.conceptId != 'C8.2' || item.startingProgramSource == null) {
          return false;
        }
        final broken = parse(item.startingProgramSource!, KeywordTables.fr);
        if (broken.errors.isNotEmpty) return false;
        final canvas = VectorCanvas();
        final run = runProgram(broken.program, canvas, seed: item.seed);
        return run.error != null;
      });
      expect(runaways, hasLength(6),
          reason: 'C8.2 has ${runaways.length} broken programs that run away');
      // And the message a child sees when one does is authored, not generated.
      for (final item in runaways) {
        expect(item.diagnosticFor(DiagnosticSituation.programFailed), isNotNull,
            reason: '${item.id} would show a blank panel');
      }
    });

    test('C8.3 senses rather than counts', () {
      /* On a canvas whose size is known, "walk until the edge" and "walk ten steps" draw
         the identical path. Only the assertion tells them apart, so every C8.3 program
         item has to make it — and the counted distractor has to be there to be caught. */
      final sensing = world8.items.where((i) =>
          i.conceptId == 'C8.3' &&
          i.type.wantsProgram &&
          i.type != ItemType.t9OpenBuild);
      expect(sensing, isNotEmpty);
      for (final item in sensing) {
        expect(
            item.assertions.whereType<UsesOpcode>().any(
                (a) => a.opcodeId == 'TOUCHING_EDGE' || a.opcodeId == 'KEY_DOWN'),
            isTrue,
            reason: '${item.id} can be passed by counting the steps');
      }
    });

    test('C8.4 draws something after the loop, or the word does not matter', () {
      /* `coupure` and `sortie` produce the identical picture unless the program has
         something left to do. Every C8.4 program item therefore has to draw after the
         loop closes, and the proof is that swapping the word changes the drawing. */
      final items = world8.items.where((i) =>
          i.conceptId == 'C8.4' &&
          i.type.wantsProgram &&
          (i.referenceSolutionSource ?? '').contains('coupure'));
      expect(items, isNotEmpty);
      for (final item in items) {
        final withBreak = VectorCanvas();
        final withQuit = VectorCanvas();
        final a = parse(item.referenceSolutionSource!, KeywordTables.fr);
        final b = parse(
            item.referenceSolutionSource!.replaceFirst('coupure', 'sortie'),
            KeywordTables.fr);
        expect(a.errors, isEmpty);
        expect(b.errors, isEmpty);
        runProgram(a.program, withBreak, seed: item.seed);
        runProgram(b.program, withQuit, seed: item.seed);
        expect(withQuit.segmentCount, isNot(withBreak.segmentCount),
            reason: '${item.id} draws the same with sortie as with coupure');
      }
    });

    test('no narration in World 8 says the word it is teaching', () {
      for (final tutorial in world8.tutorials) {
        for (final step in tutorial.steps) {
          for (final line in step.narrationKeys.values) {
            expect(jargonIn(line), isEmpty, reason: '"$line"');
          }
        }
      }
    });
  });

  group('World 7 teaches the test, which a true answer hides', () {
    /// What [item] would draw if every branch ran, or null if that cannot be asked.
    int? unguardedSegments(Item item) {
      final source = item.referenceSolutionSource;
      if (source == null || !source.contains('si ')) return null;
      final stripped = parse(
          source
              .replaceAll(RegExp(r'si [^{]*\{'), 'répète 1 {')
              .replaceAll('sinon {', 'répète 1 {'),
          KeywordTables.fr);
      if (stripped.errors.isNotEmpty) return null;
      final canvas = VectorCanvas();
      runProgram(stripped.program, canvas, seed: item.seed);
      return canvas.segmentCount;
    }

    int guardedSegments(Item item) {
      final program = parse(item.referenceSolutionSource!, KeywordTables.fr);
      expect(program.errors, isEmpty);
      final canvas = VectorCanvas();
      runProgram(program.program, canvas, seed: item.seed);
      return canvas.segmentCount;
    }

    test('no item can be passed with the test deleted', () {
      /* Two ways an item may survive having its `si` thrown away, and it has to have
         one: either the drawing changes, or an assertion notices. An item with neither
         is a World 1 item in World 7 clothing. */
      final drawing = world7.items.where((i) =>
          i.type.wantsProgram &&
          i.type != ItemType.t9OpenBuild &&
          i.targetProgramSource != null);
      expect(drawing, isNotEmpty);
      for (final item in drawing) {
        final without = unguardedSegments(item);
        final differs = without != null && without != guardedSegments(item);
        final claims = item.assertions.whereType<ContainsNode>().any((a) =>
            a.node == 'If');
        expect(differs || claims, isTrue,
            reason: '${item.id} grades the same with the si removed');
      }
    });

    test('the branch is really skipped somewhere in C7.3, C7.4 and C7.5', () {
      /* These three concepts ARE the branch, so for each of them at least one shipped
         item has to withhold something — otherwise the whole concept is taught on
         programs whose test always passes, which teaches the test away. C7.1 and C7.2
         are not in this list on purpose: their subject is the value and the comparison,
         and their programs are meant to draw. */
      for (final concept in ['C7.3', 'C7.4', 'C7.5']) {
        final withheld = world7.items.where((i) {
          if (!i.type.wantsProgram ||
              i.type == ItemType.t9OpenBuild ||
              i.conceptId != concept) {
            return false;
          }
          final without = unguardedSegments(i);
          return without != null && without > guardedSegments(i);
        });
        expect(withheld, isNotEmpty,
            reason: '$concept never withholds anything: every one of its items '
                'would draw the same with the si deleted');
      }
    });

    test('C7.5 items sit on the row that tells et from ou', () {
      /* When both halves are true, `et` and `ou` agree, and so do they when both are
         false. The only row that discriminates is the one with exactly one half true, so
         every C7.5 program item has to be on it. */
      final joined = world7.items.where((i) =>
          i.conceptId == 'C7.5' &&
          i.type.wantsProgram &&
          (i.referenceSolutionSource ?? '').contains(' ou '));
      expect(joined, isNotEmpty);
      for (final item in joined) {
        final source = item.referenceSolutionSource!;
        final swapped = source.replaceAll(' ou ', ' et ');
        final asOr = VectorCanvas();
        final asAnd = VectorCanvas();
        final orProgram = parse(source, KeywordTables.fr);
        final andProgram = parse(swapped, KeywordTables.fr);
        expect(orProgram.errors, isEmpty);
        expect(andProgram.errors, isEmpty);
        runProgram(orProgram.program, asOr, seed: item.seed);
        runProgram(andProgram.program, asAnd, seed: item.seed);
        expect(asAnd.segmentCount, isNot(asOr.segmentCount),
            reason: '${item.id} draws the same with et as with ou, so it '
                'cannot tell a child which one they needed');
      }
    });

    test('a choice item never offers the same answer twice', () {
      // The publish gate enforces this now; this is the claim stated where a reader of
      // the worlds will see it. It found real items in Worlds 3, 4, 5 and 7.
      for (final pack in worlds.values) {
        for (final item in pack.items) {
          for (final locale in requiredLocales) {
            final labels = [for (final c in item.choices) c.labelKeys[locale]];
            expect(labels.toSet(), hasLength(labels.length),
                reason: '${item.id} repeats a choice in "$locale"');
          }
        }
      }
    });

    test('no narration in World 7 says the word it is teaching', () {
      for (final tutorial in world7.tutorials) {
        for (final step in tutorial.steps) {
          for (final line in step.narrationKeys.values) {
            expect(jargonIn(line), isEmpty, reason: '"$line"');
          }
        }
      }
    });
  });

  group('World 6 teaches the box, which the picture cannot show', () {
    /* The whole risk of World 6 in one test. `$côté = 60` then `avance $côté` draws
       exactly what `avance 60` draws, so an item that only compares pictures grades
       vacuously: the child who never used a box passes. Every drawing item in this world
       therefore has to say so structurally. */
    test('every drawing item names the box it is about', () {
      final drawing = world6.items.where((i) =>
          i.type.wantsProgram &&
          i.type != ItemType.t9OpenBuild &&
          (i.referenceSolutionSource ?? '').contains(r'$'));
      expect(drawing, isNotEmpty);
      for (final item in drawing) {
        final names = item.assertions.whereType<UsesVariable>();
        expect(names, isNotEmpty,
            reason: '${item.id} can be passed without ever filling a box');
      }
    });

    test('and the distractor that proves it is there', () {
      /* For every item asserting a read, at least one wrong answer must fail on the
         assertion rather than on the drawing — otherwise the assertion is decoration and
         nothing would notice if it were deleted. */
      var proved = 0;
      for (final item in world6.items) {
        final reads = item.assertions.whereType<UsesVariable>();
        if (reads.isEmpty) continue;
        for (final source in item.wrongSolutionSources) {
          final parsed = parse(source, KeywordTables.fr);
          if (parsed.errors.isNotEmpty) continue;
          if (reads.any((a) => !a.check(parsed.program).passed)) {
            proved++;
            break;
          }
        }
      }
      expect(proved, greaterThanOrEqualTo(20),
          reason: 'only $proved items prove their own structural claim');
    });

    test('C6.5 is seeded, so a random item has one right answer', () {
      final random = world6.items.where((i) =>
          i.conceptId == 'C6.5' &&
          i.type.wantsProgram &&
          (i.referenceSolutionSource ?? '').contains('hasard'));
      expect(random, isNotEmpty);
      for (final item in random) {
        final program = parse(item.referenceSolutionSource!, KeywordTables.fr);
        expect(program.errors, isEmpty);
        // Twice, from scratch: the same seed has to give the same drawing, or the
        // "random means untestable" misconception would be correct.
        final first = VectorCanvas();
        final second = VectorCanvas();
        runProgram(program.program, first, seed: item.seed);
        runProgram(program.program, second, seed: item.seed);
        expect(second.pathSignature(), first.pathSignature(),
            reason: '${item.id} draws differently on the same seed');
        expect(first.segmentCount, greaterThan(0));
      }
    });

    test('C6.5 offers the misconception as a choice a child can be shown wrong',
        () {
      final predicts = world6.items.where(
          (i) => i.conceptId == 'C6.5' && i.type == ItemType.t3Predict);
      expect(predicts, hasLength(5));
      for (final item in predicts) {
        expect(
            item.choices.any((c) =>
                !c.correct && c.misconception == 'C6.5-random-is-untestable'),
            isTrue,
            reason: '${item.id} never lets the belief be picked');
      }
    });

    test('no narration in World 6 says the word it is teaching', () {
      // `FR-M5-03`: "variable" is on the jargon list. World 6 is where the idea arrives,
      // and a tutorial that leads with the word has taught a word.
      for (final tutorial in world6.tutorials) {
        for (final step in tutorial.steps) {
          for (final line in step.narrationKeys.values) {
            expect(jargonIn(line), isEmpty, reason: '"$line"');
          }
        }
      }
    });

    test('the tutorials check the box, not just the block beside it', () {
      /* Before World 6 a success condition could only count opcodes, so a step teaching
         assignment could only check that a `avance` had been placed. Every acting step
         here has to check the thing it teaches. */
      final acting = [
        for (final tutorial in world6.tutorials)
          for (final step in tutorial.steps)
            if (step.expectedAction != ExpectedAction.watch) step,
      ];
      expect(acting, hasLength(10));
      final boxed =
          acting.where((s) => s.successCondition?.assignsVariable != null);
      expect(boxed.length, greaterThanOrEqualTo(8),
          reason: 'only ${boxed.length} of 10 acting steps check a box');
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
void maintenanceTests(Map<int, ContentPack> worlds) {
  final world0 = worlds[0]!;
  final world2 = worlds[2]!;
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

    test('every palette entry names something the shipped engine has', () {
      /* A palette mixes opcodes with grammar — `répète` is as much a thing a child
         reaches for as `avance` — so both are accepted and neither is taken on trust.
         Until World 6 this ran over two worlds only, and a syntax word in a palette
         would have failed it, which is presumably why. */
      for (final pack in worlds.values) {
        for (final item in pack.items) {
          for (final id in item.paletteScope) {
            expect(Opcode.byId(id) != null || syntaxPaletteIds.contains(id), isTrue,
                reason: '${item.id} offers "$id", which the engine does not have');
          }
        }
        for (final tutorial in pack.tutorials) {
          for (final id in tutorial.paletteScope) {
            expect(Opcode.byId(id) != null || syntaxPaletteIds.contains(id), isTrue,
                reason: '${tutorial.id} offers "$id", which the engine does not have');
          }
        }
      }
    });
  });

}
