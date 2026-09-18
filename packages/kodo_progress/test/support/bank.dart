/// A synthetic item bank and learner, for the M7 simulation.
///
/// The simulation is the module prompt's first acceptance test, and it is the only way to
/// find out whether a mastery rule is *reachable* before spending 10.9 weeks authoring
/// against it. A rule nobody can satisfy and a rule everybody satisfies are both failures,
/// and both look fine in a unit test.
library;

import 'dart:math' as math;

import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';

Map<String, String> bilingual(String fr, String en) => {'fr': fr, 'en': en};

/// Builds a bank with [perConcept] items for each concept, spanning all nine types and
/// all five difficulties, the way a real world's bank is sized in §6.3.
List<Item> syntheticBank(List<String> conceptIds, {int perConcept = 22}) {
  final items = <Item>[];
  for (final concept in conceptIds) {
    for (var i = 0; i < perConcept; i++) {
      final type = ItemType.values[i % ItemType.values.length];
      // Difficulty follows §5.3's starting mix rather than a flat spread, so the
      // simulation meets the same shape of bank a child will.
      final difficulty = switch (i % 10) {
        0 || 1 || 2 || 3 => Difficulty.d1,
        4 || 5 || 6 => Difficulty.d2,
        7 || 8 => Difficulty.d3,
        _ => Difficulty.d4,
      };
      items.add(Item(
        id: '$concept-${i.toString().padLeft(2, '0')}',
        version: 1,
        conceptId: concept,
        type: type,
        difficulty: difficulty,
        promptKeys: bilingual('Question $i', 'Question $i'),
      ));
    }
  }
  return items;
}

/// A learner who *learns*.
///
/// The first version of this model had a fixed ability, and the simulation duly reported
/// that a middling child needed 32 items to satisfy a criterion that asks for 80 % success
/// over the last eight. That was not a finding about the rule; it was a finding about the
/// model. A child practising a concept gets better at it, and a simulation of a learning
/// system that omits learning measures nothing but variance.
///
/// [aptitude] is the ceiling the child approaches on this concept, not their skill today.
/// Skill starts low and rises with practice, fastest at the beginning — which is the shape
/// every learning curve in the literature has, and the shape §5.3's difficulty ramp
/// assumes.
class SyntheticLearner {
  SyntheticLearner({required this.aptitude, required int seed})
      : _random = SeededRandom(seed);

  /// 0 to 1. Where this child's first-attempt success rate on this concept ends up.
  final double aptitude;
  final SeededRandom _random;

  int _practised = 0;

  /// Where they are now.
  double get skill =>
      aptitude - (aptitude - 0.25) * math.exp(-_practised / 5.0);

  /// True when this learner passes [item] on this attempt.
  bool passes(Item item, {required int attemptNumber}) {
    const penalty = {
      Difficulty.d1: 0.00,
      Difficulty.d2: 0.08,
      Difficulty.d3: 0.18,
      Difficulty.d4: 0.28,
      Difficulty.d5: 0.38,
    };
    // Trying again helps, because a child who tries again has usually read the hint that
    // §4.7 offered them.
    final boost = (attemptNumber - 1) * 0.15;
    final chance = (skill - penalty[item.difficulty]! + boost).clamp(0.0, 0.98);
    return _random.nextDouble() < chance;
  }

  /// Practice counts whether or not it succeeded — failing and being shown why is how a
  /// child learns, which is §4.7's entire premise.
  void practised() => _practised++;
}
