/// Scaffolding the authoring tools share (§12).
///
/// It lives in `tool/` rather than `lib/` and that is not tidiness. It reads and writes
/// files, so it imports `dart:io` — and `NFR-OFF-01`'s gate forbids that anywhere on the
/// learning path, because a package that can open a socket eventually will. Authoring
/// runs on a laptop before anything ships; the app never sees this file.
///
/// Every world's tool was repeating the same eighty lines: a bilingual string helper, a
/// tutorial wrapper, three step builders and a publish routine that checks the bank,
/// counts the types, compares against the ledger and writes the pack. Eight copies of a
/// thing is eight places for it to drift, and the publish routine in particular is a
/// *gate* — a gate that exists in eight versions is not a gate.
///
/// What is deliberately NOT here: anything about a particular world. The items, the
/// prompts, the misconceptions and the distractors are authored per world, by hand, and
/// reviewed. This file is the machinery around them.
library;

import 'dart:convert';
import 'dart:io';

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';

/// A bilingual pair. The v1 locales, and a test keeps them the v1 locales.
Map<String, String> b(String fr, String en) => {'fr': fr, 'en': en};

/// A tutorial with the world's palette, and the closing name the child sees.
Tutorial tutorialFor({
  required String conceptId,
  required Map<String, String> conceptName,
  required List<TutorialStep> steps,
  required List<String> palette,
}) =>
    Tutorial(
      id: 'tut-$conceptId',
      conceptId: conceptId,
      steps: steps,
      closingConceptNameKeys: conceptName,
      paletteScope: palette,
    );

/// *Je regarde* — Tika does it, the child watches (§7.2).
TutorialStep watchStep(
  String conceptId,
  String fr,
  String en,
  String demo, {
  required List<String> ideas,
  SpotlightTarget spotlight = SpotlightTarget.canvas,
}) =>
    TutorialStep(
      id: '$conceptId-s1',
      beat: Beat.jeRegarde,
      narrationKeys: b(fr, en),
      audioKeys: b('audio/fr/$conceptId-s1.opus', 'audio/en/$conceptId-s1.opus'),
      expectedAction: ExpectedAction.watch,
      spotlight: spotlight,
      demoProgramSource: demo,
      newIdeas: ideas,
    );

/// *On fait ensemble* — one hole, unambiguous, impossible to get wrong twice.
TutorialStep togetherStep(
  String conceptId,
  String fr,
  String en, {
  String? opcodeId,
  String? assigns,
  required String hintFr,
  required String hintEn,
  ExpectedAction action = ExpectedAction.placeBlock,
  SpotlightTarget spotlight = SpotlightTarget.scriptArea,
}) =>
    TutorialStep(
      id: '$conceptId-s2',
      beat: Beat.onFaitEnsemble,
      narrationKeys: b(fr, en),
      audioKeys: b('audio/fr/$conceptId-s2.opus', 'audio/en/$conceptId-s2.opus'),
      expectedAction: action,
      spotlight: spotlight,
      successCondition:
          SuccessCondition(opcodeId: opcodeId, assignsVariable: assigns),
      retryHintKeys: b(hintFr, hintEn),
    );

/// *Je fais* — the child builds from zero, graded.
///
/// [assigns] names a box the child must fill, for the worlds whose subject is not a
/// block: from World 6 on, "did they place `avance`" is no longer the question.
TutorialStep doStep(
  String conceptId,
  String fr,
  String en, {
  String? opcodeId,
  String? assigns,
  required String hintFr,
  required String hintEn,
}) =>
    TutorialStep(
      id: '$conceptId-s3',
      beat: Beat.jeFais,
      narrationKeys: b(fr, en),
      audioKeys: b('audio/fr/$conceptId-s3.opus', 'audio/en/$conceptId-s3.opus'),
      expectedAction: ExpectedAction.buildProgram,
      spotlight: SpotlightTarget.scriptArea,
      successCondition:
          SuccessCondition(opcodeId: opcodeId, assignsVariable: assigns),
      retryHintKeys: b(hintFr, hintEn),
    );

/// Checks a world and writes it out, or refuses and writes nothing.
///
/// The order matters and is the whole point: **nothing is written until everything
/// passes.** A pack that is half-written because the gate failed on item sixty is worse
/// than no pack, because the next run compares against it.
///
/// Three gates, in this order:
///
///  1. M6's publish gate over every item, and M5's over every tutorial;
///  2. §6.1 — at least five item types per concept, so a child cannot mistake one
///     question shape for the concept itself;
///  3. §6.3 — the item volume the curriculum committed to, per concept.
void publishWorld({
  required int world,
  required Map<String, String> nameKeys,
  required Map<String, List<String>> conceptGraph,
  required Map<String, int> committed,
  required List<Item> items,
  required List<Tutorial> tutorials,
  required List<String> assetKeys,
}) {
  stdout.writeln('World $world — authored ${items.length} items, '
      '${tutorials.length} tutorials');

  final itemFailures = checkBank(items);
  final tutorialFailures = [for (final t in tutorials) ...checkTutorial(t)];

  if (itemFailures.isNotEmpty || tutorialFailures.isNotEmpty) {
    stderr.writeln('\nREFUSED — the pack was not written.\n');
    for (final f in itemFailures) {
      stderr.writeln('  $f');
    }
    for (final f in tutorialFailures) {
      stderr.writeln('  $f');
    }
    stderr.writeln(
        '\n${itemFailures.length + tutorialFailures.length} failure(s)');
    exit(1);
  }

  for (final concept in conceptGraph.keys) {
    final mine = items.where((i) => i.conceptId == concept).toList();
    final types = mine.map((i) => i.type).toSet();
    stdout.writeln('  $concept: ${mine.length} items, ${types.length} types '
        '(${(types.toList()..sort((a, b) => a.code.compareTo(b.code))).map((t) => t.code).join(' ')})');
    if (types.length < 5) {
      stderr.writeln('REFUSED: §6.1 requires at least five item types per '
          'concept; $concept has ${types.length}');
      exit(1);
    }
    final owed = committed[concept];
    if (owed == null) {
      stderr.writeln('REFUSED: $concept is not in the committed table');
      exit(1);
    }
    if (mine.length < owed) {
      stderr.writeln('REFUSED: §6.3 commits $owed items for $concept; '
          'this pack has ${mine.length}');
      exit(1);
    }
  }

  final ids = items.map((i) => i.id).toList();
  if (ids.toSet().length != ids.length) {
    stderr.writeln('REFUSED: two items share an id');
    exit(1);
  }

  final pack = ContentPack(
    world: world,
    version: 1,
    nameKeys: nameKeys,
    concepts: conceptGraph,
    tutorials: tutorials,
    items: items,
    /* `FR-M18-02` — a prompt recording is a condition of publication, not a nice-to-have:
       a child who cannot yet read the prompt cannot start the item. */
    itemAudioKeys: {
      for (final item in items)
        item.id: {
          for (final locale in requiredLocales)
            locale: 'audio/$locale/${item.id}.opus',
        },
    },
    audioKeys: [
      for (final t in tutorials)
        for (final s in t.steps) ...s.audioKeys.values,
      for (final item in items)
        for (final locale in requiredLocales) 'audio/$locale/${item.id}.opus',
    ],
    assetKeys: assetKeys,
  );

  final encoded = const JsonEncoder.withIndent('  ').convert(pack.toJson());
  final sized = ContentPack.fromJson({
    ...pack.toJson(),
    'sizeBytes': utf8.encode(encoded).length,
  });
  final manifest = PackManifest.of(sized);

  final dir = Directory('../../content');
  dir.createSync(recursive: true);
  File('${dir.path}/world$world.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sized.toJson())}\n');
  File('${dir.path}/world$world.manifest.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n');

  stdout.writeln('\nPublished content/world$world.json');
  stdout.writeln(
      '  ${sized.sizeBytes} bytes of ${ContentPack.worldBudgetBytes} budget '
      '(${(sized.sizeBytes / ContentPack.worldBudgetBytes * 100).toStringAsFixed(1)} %)');
  stdout.writeln('  sha256 ${manifest.contentHash.substring(0, 16)}…');
  stdout.writeln('  audio keys: ${sized.audioKeys.length}');
}
