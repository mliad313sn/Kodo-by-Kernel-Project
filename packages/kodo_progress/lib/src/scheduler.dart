/// The scheduler (§5.3, FR-M7-02, FR-M7-03).
///
/// It decides what a child does next, and it has three jobs that pull against each other:
/// keep the current concept moving, interleave older concepts so they are not forgotten,
/// and never leave a child stuck. The last one is not a nice-to-have — §4.7 forbids a
/// locked path, and the M7 prompt's `Do not` forbids producing a session with zero
/// achievable items.
library;

import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';

import 'mastery.dart';

/// The daily mix of `FR-M7-02`.
class MixRatios {
  const MixRatios(
      {this.current = 0.6, this.interleaved = 0.2, this.decayed = 0.2});
  final double current;
  final double interleaved;
  final double decayed;
}

/// §5.3's difficulty curve. The share of each difficulty shifts as mastery rises.
class DifficultyCurve {
  const DifficultyCurve._(this.shares);
  final Map<Difficulty, double> shares;

  /// At the start of a concept.
  static const atStart = DifficultyCurve._({
    Difficulty.d1: 0.45,
    Difficulty.d2: 0.30,
    Difficulty.d3: 0.15,
    Difficulty.d4: 0.08,
    Difficulty.d5: 0.02,
  });

  /// Approaching mastery.
  static const atMastery = DifficultyCurve._({
    Difficulty.d1: 0.05,
    Difficulty.d2: 0.15,
    Difficulty.d3: 0.30,
    Difficulty.d4: 0.30,
    Difficulty.d5: 0.20,
  });

  /// Linear interpolation on [progress], 0 at the start and 1 at mastery.
  static DifficultyCurve at(double progress) {
    final t = progress.clamp(0.0, 1.0);
    return DifficultyCurve._({
      for (final d in Difficulty.values)
        d: atStart.shares[d]! + (atMastery.shares[d]! - atStart.shares[d]!) * t,
    });
  }

  /// The difficulty to aim for next, given a deterministic roll in [0,1).
  Difficulty pick(double roll) {
    var cumulative = 0.0;
    for (final d in Difficulty.values) {
      cumulative += shares[d]!;
      if (roll < cumulative) return d;
    }
    return Difficulty.d1;
  }
}

/// Why the scheduler chose this item. Shown to a teacher, never to a child.
enum SelectionReason {
  currentConcept,
  interleaved,
  decayedReview,

  /// The hard floor of `FR-M7-03`: two consecutive failures forces a D1 of the same
  /// concept. A child who has failed twice is not offered a third thing they cannot do.
  recoveryFloor,

  /// The concept has met criteria 1-3 and is only waiting out the 72-hour retention
  /// window. It is practised lightly rather than drilled.
  retentionHold,

  /// Nothing else was achievable, so the easiest available item was chosen. The scheduler
  /// says so rather than returning nothing.
  fallback,
}

class ScheduledItem {
  const ScheduledItem(this.item, this.reason);
  final Item item;
  final SelectionReason reason;
}

/// Picks the next item, and the day's mix.
class Scheduler {
  Scheduler({
    required this.bank,
    this.ratios = const MixRatios(),
    this.noRepeatWindow = 20,
    int seed = 1,
  }) : _random = SeededRandom(seed);

  /// Every item available offline. The scheduler never fetches.
  final List<Item> bank;
  final MixRatios ratios;

  /// The M7 acceptance test: the same item is never presented twice within this many
  /// items. A child who sees the same question twice in a row stops believing the mix is
  /// about them.
  final int noRepeatWindow;

  final SeededRandom _random;
  final List<String> _recent = [];

  List<String> get recentlyShown => List.unmodifiable(_recent);

  void markShown(String itemId) {
    _recent.add(itemId);
    if (_recent.length > noRepeatWindow) _recent.removeAt(0);
  }

  bool _tooRecent(Item item) => _recent.contains(item.id);

  /// The next item for a child working on [currentConceptId].
  ///
  /// [consecutiveFailures] drives the floor of `FR-M7-03`. [states] is the child's mastery
  /// across every concept, and [unlocked] the concepts whose prerequisites are met.
  ScheduledItem? next({
    required String currentConceptId,
    required Map<String, MasteryState> states,
    required Set<String> unlocked,
    int consecutiveFailures = 0,
  }) {
    // --- the floor comes first, because it exists to override everything else -----------
    if (consecutiveFailures >= 2) {
      final easy = _candidates(currentConceptId)
          .where((i) => i.difficulty == Difficulty.d1)
          .toList();
      final pick = _choose(easy);
      if (pick != null)
        return ScheduledItem(pick, SelectionReason.recoveryFloor);
    }

    // A concept that is only waiting for its retention window drops out of the 60 % band.
    // Continuing to drill something the child has already demonstrated wastes the bank and
    // bores them; the simulation measured the cost at roughly 50 items against a bank of
    // 22. It still comes back a few times a day, which is what makes the retention check
    // land on time.
    final currentState = states[currentConceptId];
    final holding = currentState?.awaitingRetention ?? false;
    final currentShare = holding ? 0.2 : ratios.current;

    final decayedConcepts = states.values
        .where((s) => s.state == ConceptState.aRevoir)
        .map((s) => s.conceptId)
        .where(unlocked.contains)
        .toList();
    final earlierConcepts = states.values
        .where((s) =>
            s.conceptId != currentConceptId &&
            (s.state == ConceptState.maitrise ||
                s.state == ConceptState.enCours))
        .map((s) => s.conceptId)
        .where(unlocked.contains)
        .toList();

    // 60 % current, 20 % interleaved, 20 % decayed.
    //
    // The current concept's share is FIXED; what is left is divided between the other two
    // bands in proportion, among whichever of them has anything to offer. Normalising all
    // three together would be wrong in the case that matters: with no decayed work due,
    // the missing 20 % would flow back to the current concept and a concept deliberately
    // demoted to 20 % would quietly be served half the time. That is not a rounding
    // difference — it is the demotion failing to happen.
    final others = <SelectionReason, double>{
      if (earlierConcepts.isNotEmpty)
        SelectionReason.interleaved: ratios.interleaved,
      if (decayedConcepts.isNotEmpty)
        SelectionReason.decayedReview: ratios.decayed,
    };
    final hasCurrent = _candidates(currentConceptId).isNotEmpty;
    final bands = <SelectionReason, double>{};
    if (hasCurrent) {
      bands[holding
              ? SelectionReason.retentionHold
              : SelectionReason.currentConcept] =
          others.isEmpty ? 1.0 : currentShare;
    }
    if (others.isNotEmpty) {
      final remaining = hasCurrent ? 1.0 - currentShare : 1.0;
      final weight = others.values.fold(0.0, (a, b) => a + b);
      for (final e in others.entries) {
        bands[e.key] = remaining * (e.value / weight);
      }
    }

    if (bands.isNotEmpty) {
      final total = bands.values.fold(0.0, (a, b) => a + b);
      var roll = _random.nextDouble() * total;
      for (final band in bands.entries) {
        roll -= band.value;
        if (roll > 0) continue;
        final pick = switch (band.key) {
          SelectionReason.interleaved => _pickForConcept(
              earlierConcepts[
                  _random.nextIntInclusive(0, earlierConcepts.length - 1)],
              states),
          SelectionReason.decayedReview => _pickForConcept(
              decayedConcepts[
                  _random.nextIntInclusive(0, decayedConcepts.length - 1)],
              states),
          _ => _pickForConcept(currentConceptId, states),
        };
        if (pick != null) return ScheduledItem(pick, band.key);
        break;
      }
    }

    // --- never return nothing while anything is achievable ------------------------------
    final anything = _choose(
      bank
          .where((i) => unlocked.contains(i.conceptId) && !_tooRecent(i))
          .toList(),
    );
    if (anything != null)
      return ScheduledItem(anything, SelectionReason.fallback);

    // Everything unlocked has been shown inside the no-repeat window. Rather than return
    // null and leave a child with an empty screen, the window is the thing that gives way.
    final repeatable =
        bank.where((i) => unlocked.contains(i.conceptId)).toList();
    final pick = _choose(repeatable);
    return pick == null ? null : ScheduledItem(pick, SelectionReason.fallback);
  }

  /// A whole session, ordered.
  List<ScheduledItem> session({
    required String currentConceptId,
    required Map<String, MasteryState> states,
    required Set<String> unlocked,
    int length = 15,
  }) {
    final out = <ScheduledItem>[];
    for (var i = 0; i < length; i++) {
      final next = this.next(
        currentConceptId: currentConceptId,
        states: states,
        unlocked: unlocked,
      );
      if (next == null) break;
      out.add(next);
      markShown(next.item.id);
    }
    return out;
  }

  List<Item> _candidates(String conceptId) =>
      bank.where((i) => i.conceptId == conceptId && !_tooRecent(i)).toList();

  Item? _pickForConcept(String conceptId, Map<String, MasteryState> states) {
    final state = states[conceptId];
    final candidates = _candidates(conceptId);
    if (candidates.isEmpty) return null;

    final progress = state == null
        ? 0.0
        : (state.evidence.itemsPassed / 10).clamp(0.0, 1.0).toDouble();
    final wanted = DifficultyCurve.at(progress).pick(_random.nextDouble());

    final exact = candidates.where((i) => i.difficulty == wanted).toList();
    if (exact.isNotEmpty) return _choose(exact);

    // No item at the wanted difficulty: step outwards rather than giving up, because an
    // empty session is worse than a slightly-off one.
    final order = Difficulty.values.toList()
      ..sort((a, b) => (a.index - wanted.index)
          .abs()
          .compareTo((b.index - wanted.index).abs()));
    for (final d in order) {
      final near = candidates.where((i) => i.difficulty == d).toList();
      if (near.isNotEmpty) return _choose(near);
    }
    return null;
  }

  Item? _choose(List<Item> from) {
    if (from.isEmpty) return null;
    return from[_random.nextIntInclusive(0, from.length - 1)];
  }
}

/// The placement check of `FR-M7-04`.
///
/// Six adaptive items at first launch, proposing a start world — **always overridable by
/// the child or the teacher**. It is a suggestion, not a gate, and the type says so by
/// returning a proposal rather than setting anything.
class PlacementCheck {
  PlacementCheck({required this.bank, int seed = 7})
      : _random = SeededRandom(seed);

  final List<Item> bank;
  final SeededRandom _random;

  static const questions = 6;

  /// Picks the next placement item given how many have been answered correctly so far.
  ///
  /// Adaptive in the simplest honest way: right answers climb, wrong answers descend. Six
  /// items cannot support anything more elaborate, and pretending otherwise would be a
  /// measurement claim we could not defend at G4.
  Item? nextQuestion({required int asked, required int correct}) {
    if (asked >= questions) return null;
    final level = (correct - (asked - correct)).clamp(-2, 3);
    final targetWorld = (2 + level).clamp(0, 12);
    final candidates =
        bank.where((i) => _worldOf(i.conceptId) == targetWorld).toList();
    if (candidates.isEmpty) {
      final any = bank.where((i) => i.difficulty == Difficulty.d2).toList();
      return any.isEmpty
          ? null
          : any[_random.nextIntInclusive(0, any.length - 1)];
    }
    return candidates[_random.nextIntInclusive(0, candidates.length - 1)];
  }

  /// The world to propose. Never applied automatically.
  int proposedWorld({required int correct}) => switch (correct) {
        0 || 1 => 0,
        2 => 1,
        3 => 2,
        4 => 3,
        5 => 4,
        _ => 5,
      };

  static int _worldOf(String conceptId) {
    final digits = RegExp(r'^C(\d+)').firstMatch(conceptId);
    return digits == null ? 0 : int.parse(digits.group(1)!);
  }
}
