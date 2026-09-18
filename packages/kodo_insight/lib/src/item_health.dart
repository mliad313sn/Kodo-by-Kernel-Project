/// Item health and the weekly curriculum report (FR-M17-03, FR-M17-04).
///
/// *"Any item with pass rate < 35 % or > 97 % is flagged for rewrite"*, and the report
/// *"is the evidence base for the improvement loop"* of §16.
///
/// The flag is not a deletion. `FR-M17-03`'s companion in §12 is explicit: flagged items
/// are **rewritten in the next content sprint, never silently deleted** — because deleting
/// an item a child has already passed is how a mastery quietly stops being supported.
library;

import 'package:kodo_grader/kodo_grader.dart';

/// Why an item is flagged.
enum HealthFlag {
  /// Almost nobody passes it. Either it is testing something not taught, or it is unclear.
  tooHard,

  /// Almost everybody passes it first time. It is not measuring anything.
  tooEasy,

  /// Children start it and leave.
  abandoned,

  /// Passing it does not predict passing the rest of the concept — the item is measuring
  /// something other than the concept it is filed under.
  poorDiscrimination,

  /// Not enough attempts to say anything. Reported so that "no flag" never silently means
  /// "no data".
  insufficientData,
}

/// One item's measured behaviour.
class ItemHealth {
  const ItemHealth({
    required this.itemId,
    required this.conceptId,
    required this.attempts,
    required this.passRate,
    required this.firstAttemptPassRate,
    required this.meanAttempts,
    required this.abandonRate,
    required this.discrimination,
    required this.flags,
  });

  final String itemId;
  final String conceptId;
  final int attempts;

  /// The p-value of §FR-M17-03.
  final double passRate;

  final double firstAttemptPassRate;
  final double meanAttempts;
  final double abandonRate;

  /// Correlation between passing this item and mastering its concept, roughly. Positive
  /// is healthy; near zero means the item is not about the concept.
  final double discrimination;

  final Set<HealthFlag> flags;

  bool get needsRewrite =>
      flags.isNotEmpty && !flags.contains(HealthFlag.insufficientData);

  Map<String, Object?> toJson() => {
        'item': itemId,
        'concept': conceptId,
        'attempts': attempts,
        'passRate': passRate,
        'firstAttemptPassRate': firstAttemptPassRate,
        'meanAttempts': meanAttempts,
        'abandonRate': abandonRate,
        'discrimination': discrimination,
        'flags': [for (final f in flags) f.name],
      };
}

/// §FR-M17-03's band.
const healthyPassRateFloor = 0.35;
const healthyPassRateCeiling = 0.97;

/// Below this many attempts, the numbers are noise and the item is reported as
/// `insufficientData` rather than flagged.
const minimumAttemptsToJudge = 30;

/// One child's encounter with one item, as the cohort statistics see it.
///
/// Item health is a **cohort** statistic and cannot be computed from attempts alone: an
/// `Attempt` belongs to one child on one device, and discrimination asks whether the
/// children who passed an item went on to master its concept while the children who failed
/// it did not. That question needs a learner key, so the health computation takes
/// observations rather than raw attempts.
///
/// The learner key is a [pseudonymFor] pseudonym, never anything that identifies a child.
class HealthObservation {
  const HealthObservation({
    required this.attempt,
    required this.learnerPseudonym,
    required this.masteredTheConcept,
    this.abandoned = false,
  });

  final Attempt attempt;
  final String learnerPseudonym;

  /// Whether this learner reached `Maîtrisé` on this item's concept.
  final bool masteredTheConcept;

  /// Whether this learner left the item without passing it.
  final bool abandoned;
}

/// Computes item health from a cohort's observations.
///
/// Pure and on-device-capable: the same computation runs in the classroom (`FR-M12-02`)
/// and in the weekly Committee report, so a teacher and the Committee are never looking at
/// two different numbers.
List<ItemHealth> computeItemHealth(List<HealthObservation> observations) {
  final byItem = <String, List<HealthObservation>>{};
  for (final observation in observations) {
    byItem.putIfAbsent(observation.attempt.itemId, () => []).add(observation);
  }

  final out = <ItemHealth>[];
  byItem.forEach((itemId, rows) {
    final passes = rows.where((o) => o.attempt.passed).length;
    final firstTry =
        rows.where((o) => o.attempt.passed && o.attempt.firstAttempt).length;
    final passRate = passes / rows.length;
    final meanAttempts =
        rows.fold<int>(0, (sum, o) => sum + o.attempt.signals.attempts) /
            rows.length;
    final abandoned = rows.where((o) => o.abandoned).length;

    // Discrimination: among the learners who passed this item, the share who mastered the
    // concept, minus the same share among those who failed it. An item everybody passes
    // discriminates at zero by construction, which is exactly what it should report.
    double masteredShare(Iterable<HealthObservation> group) {
      final learners = <String, bool>{};
      for (final o in group) {
        learners[o.learnerPseudonym] = o.masteredTheConcept;
      }
      if (learners.isEmpty) return 0;
      return learners.values.where((m) => m).length / learners.length;
    }

    final discrimination = masteredShare(rows.where((o) => o.attempt.passed)) -
        masteredShare(rows.where((o) => !o.attempt.passed));

    final flags = <HealthFlag>{};
    if (rows.length < minimumAttemptsToJudge) {
      flags.add(HealthFlag.insufficientData);
    } else {
      if (passRate < healthyPassRateFloor) flags.add(HealthFlag.tooHard);
      if (passRate > healthyPassRateCeiling) flags.add(HealthFlag.tooEasy);
      if (abandoned / rows.length > 0.15) flags.add(HealthFlag.abandoned);
      if (discrimination < 0.05 && passRate <= healthyPassRateCeiling) {
        flags.add(HealthFlag.poorDiscrimination);
      }
    }

    out.add(ItemHealth(
      itemId: itemId,
      conceptId: rows.first.attempt.conceptId,
      attempts: rows.length,
      passRate: passRate,
      firstAttemptPassRate: firstTry / rows.length,
      meanAttempts: meanAttempts,
      abandonRate: abandoned / rows.length,
      discrimination: discrimination,
      flags: flags,
    ));
  });

  out.sort((a, b) => a.itemId.compareTo(b.itemId));
  return out;
}

/// The weekly report the Committee reads (FR-M17-04).
class CurriculumHealthReport {
  const CurriculumHealthReport({
    required this.weekEnding,
    required this.items,
    required this.wellbeing,
    required this.learnersActive,
  });

  final DateTime weekEnding;
  final List<ItemHealth> items;

  /// The wellbeing counters of §10. They lead the report rather than trailing it, because
  /// *"a rise in these is treated as a defect of the same severity as a crash"* and a
  /// number at the bottom of page four is not treated as anything.
  final Map<EventKindSummary, int> wellbeing;

  final int learnersActive;

  List<ItemHealth> get needingRewrite =>
      items.where((i) => i.needsRewrite).toList();

  List<ItemHealth> get unjudgeable => items
      .where((i) => i.flags.contains(HealthFlag.insufficientData))
      .toList();

  Map<String, Object?> toJson() => {
        'weekEnding': weekEnding.toUtc().toIso8601String(),
        'learnersActive': learnersActive,
        'wellbeing': {for (final e in wellbeing.entries) e.key.name: e.value},
        'itemsMeasured': items.length,
        'needingRewrite': [for (final i in needingRewrite) i.toJson()],
        'unjudgeable': unjudgeable.length,
      };

  /// A plain-text summary, in French, for the minutes.
  String render() {
    final buffer = StringBuffer()
      ..writeln('Santé du curriculum — semaine du '
          '${weekEnding.toUtc().toIso8601String().substring(0, 10)}')
      ..writeln('Enfants actifs : $learnersActive')
      ..writeln()
      ..writeln('Bien-être (§10) :');
    for (final entry in wellbeing.entries) {
      buffer.writeln('  ${entry.key.label} : ${entry.value}');
    }
    buffer
      ..writeln()
      ..writeln('Items mesurés : ${items.length}')
      ..writeln('À réécrire : ${needingRewrite.length}')
      ..writeln('Pas assez de données : ${unjudgeable.length}');
    for (final item in needingRewrite) {
      buffer.writeln('  ${item.itemId} — réussite '
          '${(item.passRate * 100).round()} % — '
          '${item.flags.map((f) => f.name).join(', ')}');
    }
    return buffer.toString();
  }
}

/// The wellbeing counters, named for the report.
enum EventKindSummary {
  frustration('Frustrations (3 échecs de suite)'),
  lateNight('Sessions après 20 h'),
  goalOverrun('Dépassements du objectif choisi'),
  abandonedAfterFailure('Abandons après un échec'),
  stoppedAtOwnGoal('Arrêts à l\'objectif atteint');

  const EventKindSummary(this.label);
  final String label;
}
