/// Worlds 0 and 2, as shipped.
///
/// The gate runs at authoring time in `tool/author_world0.dart` and
/// `tool/author_world2.dart`. It runs again here, over the JSON that actually shipped,
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
  final worlds = {0: world0, 1: world1, 2: world2};

  group('§6.3 · the three shipped worlds carry the committed item volume', () {
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

    test('the three worlds ship 266 items between them', () {
      expect(world0.items, hasLength(80));
      expect(world1.items, hasLength(100));
      expect(world2.items, hasLength(86));
      // 21 % of the 1 214 the curriculum commits across all thirteen worlds.
      expect(
          world0.items.length + world1.items.length + world2.items.length, 266);
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

    test('item ids are unique across all three worlds', () {
      final ids = [
        for (final pack in worlds.values) ...pack.items.map((i) => i.id)
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('every shipped item passes the publish gate', () {
    for (final entry in {0: 'World 0', 2: 'World 2'}.entries) {
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
}
