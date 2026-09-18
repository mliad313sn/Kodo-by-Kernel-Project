/// The mastery rule (§4.6, FR-M7-01, FR-M7-05).
///
/// A concept is `Maîtrisé` when **all four** hold:
///
/// 1. ≥ 10 items passed in that concept, spanning ≥ 4 item types;
/// 2. ≥ 80 % first-attempt success over the child's last 8 items;
/// 3. at least one item passed that was **not structurally similar to the tutorial
///    example**;
/// 4. one retention check passed **≥ 72 h after** criteria 1–3 were met.
///
/// The fourth is the one that makes the claim worth making, and it is the one every
/// competitor omits: without it, "mastered" means "got it right this afternoon".
library;

import 'package:kodo_grader/kodo_grader.dart';

import 'clock.dart';

/// The concept state machine of `FR-M7-05`.
enum ConceptState {
  /// Never offered.
  nonVu,

  /// Seen in a tutorial, not yet practised.
  decouvert,

  /// Being practised.
  enCours,

  /// All four criteria met.
  maitrise,

  /// Was mastered, untouched for 21 days.
  aRevoir;

  /// Stars on the progress map (`FR-M7-06`), 0 to 3.
  int get stars => switch (this) {
        ConceptState.nonVu || ConceptState.decouvert => 0,
        ConceptState.enCours => 1,
        ConceptState.aRevoir => 2,
        ConceptState.maitrise => 3,
      };
}

/// Which of the four criteria hold, and why.
///
/// Returned rather than a bare boolean because the parent summary (`FR-M11-02`) and the
/// teacher grid (`FR-M12-02`) both have to explain *what is still missing*, and because a
/// mastery claim nobody can interrogate is the thing §4.1 was written against.
class MasteryEvidence {
  const MasteryEvidence({
    required this.itemsPassed,
    required this.typesSpanned,
    required this.firstAttemptRate,
    required this.passedDissimilar,
    required this.criteriaOneToThreeMetAt,
    required this.retentionPassedAt,
  });

  final int itemsPassed;
  final int typesSpanned;

  /// Over the last 8 items attempted in this concept.
  final double firstAttemptRate;

  final bool passedDissimilar;

  /// When criteria 1–3 first all held. Null until they do.
  final DateTime? criteriaOneToThreeMetAt;

  /// When a retention check was passed at least 72 h after that. Null until it is.
  final DateTime? retentionPassedAt;

  bool get criterionVolume => itemsPassed >= 10 && typesSpanned >= 4;
  bool get criterionAccuracy => firstAttemptRate >= 0.8;
  bool get criterionTransfer => passedDissimilar;
  bool get criterionRetention => retentionPassedAt != null;

  bool get allFour =>
      criterionVolume &&
      criterionAccuracy &&
      criterionTransfer &&
      criterionRetention;

  /// The child has done everything except wait.
  ///
  /// Found by the 10 000-learner simulation, which is what it is for. §4.6 says that
  /// until all four criteria hold the concept stays `En cours` and *"the scheduler keeps
  /// injecting its items"* — and with the 60 % current-concept mix that is 72 hours of
  /// drilling a concept the child has already demonstrated. A capable learner needed
  /// **50 items** on one concept, against a bank of 22.
  ///
  /// So the scheduler demotes a concept in this state to the interleaved band. The child
  /// moves on; the concept comes back a few times a day; the retention check lands when
  /// it is due. Nothing about the rule changes — only how loudly it is practised while it
  /// waits.
  bool get awaitingRetentionOnly =>
      criterionVolume &&
      criterionAccuracy &&
      criterionTransfer &&
      !criterionRetention;

  /// The earliest instant a retention check could count.
  DateTime? get retentionEligibleFrom =>
      criteriaOneToThreeMetAt?.add(retentionDelay);

  /// What is still missing, as message keys. Never a sentence: the words live in the
  /// localisation layer with everything else.
  List<String> get outstanding => [
        if (!criterionVolume) 'mastery.needs.volume',
        if (!criterionAccuracy) 'mastery.needs.accuracy',
        if (!criterionTransfer) 'mastery.needs.transfer',
        if (!criterionRetention) 'mastery.needs.retention',
      ];

  Map<String, Object?> toJson() => {
        'itemsPassed': itemsPassed,
        'typesSpanned': typesSpanned,
        'firstAttemptRate': firstAttemptRate,
        'passedDissimilar': passedDissimilar,
        'criteriaMetAt': criteriaOneToThreeMetAt?.toIso8601String(),
        'retentionPassedAt': retentionPassedAt?.toIso8601String(),
      };
}

/// §4.6's fourth criterion.
const retentionDelay = Duration(hours: 72);

/// §4.6's decay schedule.
const decayAfter = Duration(days: 21);

/// The window of criterion 2, as §4.6 specifies it.
///
/// It is a constant with a name because the 10 000-learner simulation measures the cost of
/// changing it (finding M7-SIM-01): the window governs how noisy the criterion is, and
/// therefore how many items a child needs before a qualifying window happens to occur.
const specAccuracyWindow = 8;

/// A concept's state for one child, and the evidence behind it.
class MasteryState {
  const MasteryState({
    required this.conceptId,
    required this.state,
    required this.evidence,
    required this.lastTouchedAt,
    this.masteredAt,
  });

  final String conceptId;
  final ConceptState state;
  final MasteryEvidence evidence;
  final DateTime? lastTouchedAt;
  final DateTime? masteredAt;

  int get stars => state.stars;

  /// See [MasteryEvidence.awaitingRetentionOnly].
  bool get awaitingRetention =>
      state == ConceptState.enCours && evidence.awaitingRetentionOnly;

  Map<String, Object?> toJson() => {
        'concept': conceptId,
        'state': state.name,
        'evidence': evidence.toJson(),
        'lastTouchedAt': lastTouchedAt?.toIso8601String(),
        'masteredAt': masteredAt?.toIso8601String(),
      };
}

/// Computes mastery from attempts. Pure, on device, no network (`FR-M7-01`).
class MasteryCalculator {
  const MasteryCalculator({this.accuracyWindow = specAccuracyWindow});

  /// How many recent items criterion 2 is measured over. §4.6 says eight; it is a
  /// parameter so that the simulation can price a change rather than argue about one.
  final int accuracyWindow;

  /// [attempts] may be in any order; they are sorted here.
  ///
  /// Criterion 3 — *"at least one item passed that was not structurally similar to the
  /// tutorial example"* — is read off the difficulty tag rather than by comparing shapes.
  /// §5.3 defines D3 as *"Recombination; the shape differs from the example"*, so the
  /// curriculum has already made this judgement, per item, by hand, and reviewed it. A
  /// second automated similarity metric would be a different claim wearing the same name.
  MasteryState evaluate({
    required String conceptId,
    required List<Attempt> attempts,
    required Clock clock,
    DateTime? previouslyMasteredAt,
  }) {
    final mine = attempts.where((a) => a.conceptId == conceptId).toList()
      ..sort((a, b) => a.at.compareTo(b.at));

    if (mine.isEmpty) {
      return MasteryState(
        conceptId: conceptId,
        state: ConceptState.nonVu,
        evidence: const MasteryEvidence(
          itemsPassed: 0,
          typesSpanned: 0,
          firstAttemptRate: 0,
          passedDissimilar: false,
          criteriaOneToThreeMetAt: null,
          retentionPassedAt: null,
        ),
        lastTouchedAt: null,
      );
    }

    final now = clock.nowUtc();
    final lastTouched = mine.last.at;

    // --- walk forward, so "when did criteria 1-3 first hold" is an observed instant
    //     rather than a recomputation against today's totals.
    final passedItems = <String>{};
    final passedTypes = <ItemType>{};
    var dissimilar = false;
    DateTime? criteriaMetAt;
    DateTime? retentionAt;
    final window = <Attempt>[];

    for (final attempt in mine) {
      window.add(attempt);
      if (window.length > accuracyWindow) window.removeAt(0);

      if (attempt.passed) {
        passedItems.add(attempt.itemId);
        if (attempt.itemType != null) passedTypes.add(attempt.itemType!);
        if (attempt.difficulty == Difficulty.d3 ||
            attempt.difficulty == Difficulty.d4 ||
            attempt.difficulty == Difficulty.d5) {
          dissimilar = true;
        }
      }

      final rate = _firstAttemptRate(window);
      final volumeOk = passedItems.length >= 10 && passedTypes.length >= 4;

      if (criteriaMetAt == null && volumeOk && rate >= 0.8 && dissimilar) {
        criteriaMetAt = attempt.at;
        continue;
      }
      if (criteriaMetAt != null &&
          retentionAt == null &&
          attempt.passed &&
          !attempt.at.isBefore(criteriaMetAt.add(retentionDelay))) {
        retentionAt = attempt.at;
      }
    }

    final evidence = MasteryEvidence(
      itemsPassed: passedItems.length,
      typesSpanned: passedTypes.length,
      firstAttemptRate: _firstAttemptRate(window),
      passedDissimilar: dissimilar,
      criteriaOneToThreeMetAt: criteriaMetAt,
      retentionPassedAt: retentionAt,
    );

    var state = ConceptState.enCours;
    DateTime? masteredAt = previouslyMasteredAt;
    if (evidence.allFour) {
      state = ConceptState.maitrise;
      masteredAt ??= retentionAt;
    } else if (mine.every((a) => !a.passed) && mine.length <= 1) {
      state = ConceptState.decouvert;
    }

    // --- decay. A concept untouched for 21 days drops to "à revoir" and re-enters the
    //     daily mix at low volume. It never drops below that: work already done is not
    //     taken away, which is §10's rule about never punishing absence.
    if (state == ConceptState.maitrise &&
        now.difference(lastTouched) >= decayAfter) {
      state = ConceptState.aRevoir;
    }

    return MasteryState(
      conceptId: conceptId,
      state: state,
      evidence: evidence,
      lastTouchedAt: lastTouched,
      masteredAt: masteredAt,
    );
  }

  double _firstAttemptRate(List<Attempt> window) {
    if (window.isEmpty) return 0;
    final firstTry = window.where((a) => a.passed && a.firstAttempt).length;
    return firstTry / window.length;
  }
}
