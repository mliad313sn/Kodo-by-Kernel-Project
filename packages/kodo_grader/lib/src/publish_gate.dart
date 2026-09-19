/// The publish gate (FR-M18-02, and the M6 prompt's first acceptance test).
///
/// *"for every shipped item, at least three wrong reference programs must fail it, and at
/// least two alternative correct programs must pass it"* — and an item without a concept
/// link, a difficulty tag, two hints, a diagnostic message, FR and EN text and a passing
/// reference solution cannot be published at all.
///
/// It lives in M6 rather than in M18 because it has to *run the grader*. M18 is a web tool
/// that calls this; the rule itself belongs next to the thing it is a rule about, and CI
/// can then run it over every content pack without starting a CMS.
library;

import 'dart:convert';

import 'package:kodo_lang/kodo_lang.dart';

import 'choice_order.dart';
import 'grader.dart';
import 'item.dart';
import 'keyword_agnostic.dart';

/// One reason an item may not ship.
class PublishFailure {
  const PublishFailure(this.itemId, this.rule, this.detail);
  final String itemId;

  /// A stable rule name, so a CI failure can be grepped and an author can be told which
  /// rule they tripped rather than being handed a paragraph.
  final String rule;
  final String detail;

  @override
  String toString() => '$itemId: [$rule] $detail';
}

/// Languages every child-facing string must exist in at v1 (PO decision D-002).
const requiredLocales = ['fr', 'en'];

/// Phrases that mean an author gave up. A failure message must name the observable
/// difference (`FR-M6-03`); these are what gets typed instead when nobody is checking.
const _genericPhrases = [
  'incorrect',
  'wrong',
  'faux',
  'essaie encore',
  'try again',
  'error',
  'erreur',
  'raté',
  'non',
  'oops',
];

/// Checks one item. An empty list means it may ship.
List<PublishFailure> checkItem(Item item, {Grader grader = const Grader()}) {
  final failures = <PublishFailure>[];

  void fail(String rule, String detail) =>
      failures.add(PublishFailure(item.id, rule, detail));

  // --- completeness (FR-M18-02) ----------------------------------------------------------
  if (item.conceptId.trim().isEmpty) fail('concept-link', 'no concept');
  for (final locale in requiredLocales) {
    if ((item.promptKeys[locale] ?? '').trim().isEmpty) {
      fail('prompt-localised', 'no prompt in "$locale"');
    }
  }
  if (item.hints.length < 2) {
    fail('two-hints', 'has ${item.hints.length} hint(s), needs 2');
  }
  for (final hint in item.hints) {
    for (final locale in requiredLocales) {
      if ((hint.textKeys[locale] ?? '').trim().isEmpty) {
        fail('hint-localised', 'a hint has no "$locale" text');
      }
    }
  }
  if (item.diagnostics.isEmpty) {
    fail('diagnostic-message', 'no authored failure message');
  }
  for (final d in item.diagnostics) {
    if (DiagnosticSituation.byName(d.when) == null) {
      fail('diagnostic-situation',
          '"${d.when}" is not a situation the grader detects');
    }
    for (final locale in requiredLocales) {
      final text = (d.textKeys[locale] ?? '').trim();
      if (text.isEmpty) {
        fail('diagnostic-localised',
            'the "${d.when}" message has no "$locale" text');
        continue;
      }
      final lower = text.toLowerCase();
      // The generic-string gate. A message of five words that is only a verdict is the
      // thing FR-M6-03 forbids, so short *and* generic fails; a long sentence that happens
      // to contain "non" does not.
      final words = lower.split(RegExp(r'[^\wàâäéèêëîïôöùûüç]+'))
        ..removeWhere((w) => w.isEmpty);
      if (words.length <= 3 && words.any(_genericPhrases.contains)) {
        fail('generic-message',
            'the "${d.when}" message in "$locale" says only "$text"');
      }
    }
  }

  /* A T9 open build has no single right answer — that is what "open" means — so it is
     judged by its rubric and exempted from the reference/alternatives/wrongs checks that
     every other program item must pass. What it is NOT exempt from is having a rubric at
     all: an open build with nothing to meet is a guessing game, and `FR-M6-06` requires
     the rubric to be shown to the child before they start. */
  final isOpenBuild = item.type == ItemType.t9OpenBuild;
  if (isOpenBuild) {
    if (item.rubric.isEmpty) {
      fail(
          'open-build-rubric',
          'an open build needs a rubric; without one a child cannot know what '
              'good looks like before they start');
    }
    for (var i = 0; i < item.rubric.length; i++) {
      for (final locale in requiredLocales) {
        if ((item.rubric[i].textKeys[locale] ?? '').trim().isEmpty) {
          fail('open-build-rubric',
              'rubric line #${i + 1} has no "$locale" text');
        }
      }
    }
  }

  // --- the item has to be gradable -------------------------------------------------------
  if (item.type.wantsProgram && !isOpenBuild) {
    if ((item.referenceSolutionSource ?? '').trim().isEmpty) {
      fail('reference-solution', 'no reference solution');
    }
  } else if (!isOpenBuild) {
    /* An open build is neither: the child writes a program and there is no single right
       answer to compare it with. It is judged by its rubric, checked above. */
    if (item.choices.length < 2) {
      fail('choices', 'a choice item needs at least two candidates');
    }
    if (item.choices.where((c) => c.correct).length != 1) {
      fail('one-correct-choice',
          'has ${item.choices.where((c) => c.correct).length} correct choices, needs exactly 1');
    }
    for (final c in item.choices) {
      for (final locale in requiredLocales) {
        if ((c.labelKeys[locale] ?? '').trim().isEmpty) {
          fail('choice-localised', 'a choice has no "$locale" label');
        }
      }
      if (!c.correct && (c.misconception ?? '').isEmpty) {
        fail('misconception-tag',
            'a wrong choice does not say which misconception it evidences');
      }
    }
    /* Two choices reading the same thing make an item that cannot be answered: a child
       who picks the second "7" is marked wrong for choosing the right answer. It happens
       when distractors are computed rather than typed — World 7 generated a "the block
       ran anyway" distractor that equalled the correct count on every set whose test was
       true — so it is checked per language, where the collision actually reaches a child. */
    for (final locale in requiredLocales) {
      final labels = [
        for (final c in item.choices) (c.labelKeys[locale] ?? '').trim()
      ]..removeWhere((l) => l.isEmpty);
      final seen = <String>{};
      for (final label in labels) {
        if (!seen.add(label)) {
          fail('choices-distinct',
              'two choices both read "$label" in "$locale"');
        }
      }
    }
  }
  if (item.type == ItemType.t9OpenBuild) {
    if (item.rubric.length < 3 || item.rubric.length > 5) {
      fail('rubric-size',
          'an open build needs 3 to 5 rubric lines, has ${item.rubric.length}');
    }
  }
  if (item.type == ItemType.t7Golf && item.blockBudget == null) {
    fail('block-budget', 'a golf item needs a block budget');
  }

  // --- negative testing (the M6 prompt's acceptance test 1) -------------------------------
  if (item.type.wantsProgram && !isOpenBuild) {
    if (item.wrongSolutionSources.length < 3) {
      fail('three-wrong',
          'has ${item.wrongSolutionSources.length} wrong solutions, needs 3');
    }
    if (item.alternativeSolutionSources.length < 2) {
      fail('two-alternatives',
          'has ${item.alternativeSolutionSources.length} alternative correct solutions, needs 2');
    }

    Program? compile(String source, String rule) {
      final parsed = parseEither(source, locale: item.keywords);
      if (parsed.errors.isNotEmpty) {
        fail(rule, 'does not parse: ${parsed.errors.first.message('fr')}');
        return null;
      }
      return parsed.program;
    }

    final reference = item.referenceSolutionSource == null
        ? null
        : compile(item.referenceSolutionSource!, 'reference-parses');
    if (reference != null &&
        !grader.grade(item, ProgramResponse(reference)).passed) {
      fail('reference-passes',
          'the reference solution does not pass its own item');
    }

    for (var i = 0; i < item.alternativeSolutionSources.length; i++) {
      final program =
          compile(item.alternativeSolutionSources[i], 'alternative-parses');
      if (program == null) continue;
      if (!grader.grade(item, ProgramResponse(program)).passed) {
        fail('alternative-passes',
            'alternative solution #${i + 1} is asserted correct but fails');
      }
    }

    for (var i = 0; i < item.wrongSolutionSources.length; i++) {
      final program = compile(item.wrongSolutionSources[i], 'wrong-parses');
      if (program == null) continue;
      final verdict = grader.grade(item, ProgramResponse(program));
      if (verdict.passed) {
        fail('wrong-fails',
            'wrong solution #${i + 1} is asserted wrong but passes');
        continue;
      }
      // A wrong solution that fails for a situation the author has not written a message
      // for would show a child a blank panel.
      if (verdict.situation != null &&
          item.diagnosticFor(verdict.situation!) == null) {
        fail(
            'diagnostic-covers-failure',
            'wrong solution #${i + 1} fails as "${verdict.situation!.name}", '
                'which has no authored message');
      }
    }
  }

  return failures;
}

/// Checks a whole bank. Returns every failure, not the first — an author fixing content
/// wants the list, not a game of whack-a-mole.
List<PublishFailure> checkBank(Iterable<Item> items,
    {Grader grader = const Grader()}) {
  final failures = <PublishFailure>[];
  final seen = <String>{};
  final fingerprints = <String, String>{};
  final slotsByConcept = <String, Map<int, List<String>>>{};
  final promptOwners = <String, (String conceptId, String itemId)>{};

  for (final item in items) {
    if (!seen.add(item.id)) {
      failures.add(
          PublishFailure(item.id, 'duplicate-id', 'appears twice in the bank'));
    }
    failures.addAll(checkItem(item, grader: grader));

    /* Two items that differ only in their id are one item served twice, and the
       scheduler's "never the same item twice in N" rule cannot see it — it compares ids.
       Three byte-identical questions shipped in World 0 this way, which is the first
       world an eight-year-old ever opens. */
    final fingerprint = _fingerprintOf(item);
    final twin = fingerprints[fingerprint];
    if (twin != null) {
      failures.add(PublishFailure(
          item.id, 'duplicate-item', 'is the same question as $twin'));
    } else {
      fingerprints[fingerprint] = item.id;
    }

    /* One instruction, one bar. The same words in two concepts mean two different
       rubrics behind one prompt, and a child cannot tell which one they are being held
       to: "Fais une fleur avec un bloc pétale" appeared in C9.1, where one named block
       was the whole task, and again in C9.4, whose rubric demanded two. */
    final prompt = (item.promptKeys['fr'] ?? '').trim();
    if (prompt.isNotEmpty) {
      final owner = promptOwners[prompt];
      if (owner == null) {
        promptOwners[prompt] = (item.conceptId, item.id);
      } else if (owner.$1 != item.conceptId) {
        failures.add(PublishFailure(item.id, 'prompt-crosses-concepts',
            'asks what ${owner.$2} asks, under a different concept'));
      }
    }

    if (item.choices.length >= 2) {
      final at = presentedCorrectIndex(item);
      ((slotsByConcept[item.conceptId] ??= {})[at] ??= []).add(item.id);
    }
  }

  /* `choice-position`. Every item in this curriculum is authored with the right answer
     written first, which is the readable way to author one and would have been a
     catastrophe to deliver: a child who taps the top answer every time passes every
     choice item there is, and an eight-year-old finds that out faster than any adult
     expects. `choiceOrder` moves it; this proves it moved. Measured on the PRESENTED
     order, because that is the only order a child can see. */
  for (final entry in slotsByConcept.entries) {
    final total = entry.value.values.fold<int>(0, (a, ids) => a + ids.length);
    if (total < 6) continue;
    final biggest = entry.value.entries
        .reduce((a, b) => a.value.length >= b.value.length ? a : b);
    if (entry.value.length < 2) {
      failures.add(PublishFailure(entry.key, 'choice-position',
          'every right answer in this concept sits in slot ${biggest.key}'));
    } else if (biggest.value.length / total > 0.8) {
      failures.add(PublishFailure(
          entry.key,
          'choice-position',
          '${biggest.value.length} of $total right answers sit in '
              'slot ${biggest.key}'));
    }
  }
  return failures;
}

/// What makes two items the same question: the words, the choices, and what is graded.
///
/// Deliberately not the id, the seed or the hints. An author who copies an item and gives
/// it a new id has made a duplicate, whatever else they changed around it.
String _fingerprintOf(Item item) => jsonEncode({
      'prompt': item.promptKeys,
      'target': item.targetProgramSource,
      'reference': item.referenceSolutionSource,
      'choices': [for (final c in item.choices) c.toJson()],
      'rubric': [for (final r in item.rubric) r.textKeys],
    });
