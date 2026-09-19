/// The learning loop, composed (`FR-M19-06`).
///
/// This is the part of M19 that makes the rest of the programme reachable: a child picks
/// an item, writes a program, presses *Essayer*, and is told something true about what
/// they drew. Until this existed the application had every screen and no exercise — the
/// run button was wired to nothing, which is a demonstration rather than a product.
///
/// Every judgement here belongs to somebody else and is called, never re-implemented:
///
/// * **which item comes next** is M7's `Scheduler`;
/// * **whether an answer is right** is M6's `Grader`;
/// * **what the child is told when it is wrong** is the *item's own* authored diagnostic,
///   rendered by `Verdict.messageFor` — the shell never composes a sentence about a
///   child's work;
/// * **what counts as mastered** is M7's `MasteryCalculator`, over the attempts M6 records.
///
/// What is genuinely this file's is the bookkeeping between them: how many attempts the
/// child has made at this item, how long they have been on it, and when to ask the
/// scheduler for another one. That is session state, not learning logic.
library;

import 'package:flutter/foundation.dart';
import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_progress/kodo_progress.dart';
import 'package:kodo_stage/kodo_stage.dart';

/// What the item screen is currently showing.
enum LoopPhase {
  /// The child is working. No verdict on screen.
  working,

  /// The last run was wrong, and the item's own sentence is on screen.
  tryAgain,

  /// The last run was right.
  passed,

  /// There is nothing left to serve.
  finished,
}

/// One item, in flight.
///
/// [attempts] and [runs] feed M6's `ProcessSignals`, which is what M8 reads for the
/// frustration event of §4.7 — three consecutive failures is a wellbeing signal, not a
/// funnel metric, and it can only exist if somebody counts.
class ItemInFlight {
  ItemInFlight(this.item, {required this.startedAt});

  final Item item;
  final DateTime startedAt;

  int attempts = 0;
  int runs = 0;
  int hintsShown = 0;
  DateTime? firstRunAt;
}

/// The loop itself.
///
/// A `ChangeNotifier` so the screens rebuild from it, exactly as they rebuild from the
/// session: there is one source of truth for what a child is looking at.
class LearningLoop extends ChangeNotifier {
  LearningLoop({
    required this.packs,
    required this.conceptId,
    required Clock clock,
    AttemptStore? attempts,
    int seed = 1,
  })  : _clock = clock,
        _attempts = attempts ?? InMemoryAttemptStore(),
        _scheduler = Scheduler(
          bank: [for (final pack in packs) ...pack.items],
          seed: seed,
        );

  final List<ContentPack> packs;

  /// Where the child is working. The scheduler may serve from elsewhere — an earlier
  /// concept for the recovery floor, a decayed one for retention — and that is its
  /// decision, not this one's.
  final String conceptId;

  final Clock _clock;
  final AttemptStore _attempts;
  final Scheduler _scheduler;
  final Grader _grader = const Grader();
  final MasteryCalculator _mastery = const MasteryCalculator();

  ItemInFlight? _current;
  Verdict? _verdict;
  VectorCanvas? _drawn;
  LoopPhase _phase = LoopPhase.working;
  int _consecutiveFailures = 0;
  int _passedThisSession = 0;

  ItemInFlight? get current => _current;
  Verdict? get verdict => _verdict;
  VectorCanvas? get drawn => _drawn;
  LoopPhase get phase => _phase;
  int get passedThisSession => _passedThisSession;

  /// Which hint to show, if the child asks. The item authored them; this only counts.
  Hint? get availableHint {
    final flight = _current;
    if (flight == null) return null;
    final hints = flight.item.hints;
    if (hints.isEmpty) return null;
    return hints[flight.hintsShown.clamp(0, hints.length - 1)];
  }

  /// Every concept's state, recomputed from the attempts. Never stored as a total:
  /// `Do not equate completion with mastery` is M7's rule and it holds here too.
  Future<Map<String, MasteryState>> masteryStates() async {
    final all = await _attempts.recent(limit: 500);
    return {
      for (final pack in packs)
        for (final concept in pack.concepts.keys)
          concept: _mastery.evaluate(
            conceptId: concept,
            attempts: all,
            clock: _clock,
          ),
    };
  }

  /// Serves the first item. Call once, before showing the screen.
  Future<void> start() async {
    await _serveNext();
  }

  Future<void> _serveNext() async {
    final states = await masteryStates();
    final next = _scheduler.next(
      currentConceptId: conceptId,
      states: states,
      /* Everything installed is available to the scheduler here. The gate that decides
         what a child may OPEN is the map's, built from prerequisites and mastery
         (`ProgressMap.unlockedFor`); once they are inside a concept, narrowing the mix
         further would be a second progression rule. */
      unlocked: states.keys.toSet(),
      consecutiveFailures: _consecutiveFailures,
    );

    if (next == null) {
      _current = null;
      _phase = LoopPhase.finished;
      notifyListeners();
      return;
    }
    _scheduler.markShown(next.item.id);
    _current = ItemInFlight(next.item, startedAt: _clock.nowUtc());
    _verdict = null;
    _drawn = null;
    _phase = LoopPhase.working;
    notifyListeners();
  }

  /// The child pressed *Essayer*.
  ///
  /// Runs the program for the drawing the child sees, hands it to M6, records the attempt,
  /// and stops. It does not advance: a verdict a child never reads is a verdict that did
  /// not happen, so moving on is [next] and it is the child's press.
  Future<void> submit(Program program) async {
    final flight = _current;
    if (flight == null) return;

    flight.attempts += 1;
    flight.runs += 1;
    flight.firstRunAt ??= _clock.nowUtc();

    // The canvas the child is shown is the canvas that ran. One execution, not two.
    final canvas = VectorCanvas();
    runProgram(program, canvas, seed: flight.item.seed, inputs: flight.item.inputs);
    _drawn = canvas;

    final verdict = _grader.grade(flight.item, ProgramResponse(program));
    _verdict = verdict;

    await _attempts.record(Attempt(
      itemId: flight.item.id,
      itemVersion: flight.item.version,
      conceptId: flight.item.conceptId,
      at: _clock.nowUtc(),
      passed: verdict.passed,
      response: ProgramResponse(program),
      itemType: flight.item.type,
      difficulty: flight.item.difficulty,
      signals: ProcessSignals(
        attempts: flight.attempts,
        runs: flight.runs,
        hintsShown: flight.hintsShown,
        millisecondsToFirstRun: flight.firstRunAt!
            .difference(flight.startedAt)
            .inMilliseconds,
        millisecondsOnItem:
            _clock.nowUtc().difference(flight.startedAt).inMilliseconds,
      ),
      verdict: verdict,
    ));

    if (verdict.passed) {
      _consecutiveFailures = 0;
      _passedThisSession += 1;
      _phase = LoopPhase.passed;
    } else {
      _consecutiveFailures += 1;
      _phase = LoopPhase.tryAgain;
    }
    notifyListeners();
  }

  /// The child answered a choice item.
  Future<void> choose(int index) async {
    final flight = _current;
    if (flight == null) return;
    flight.attempts += 1;

    final verdict = _grader.grade(flight.item, ChoiceResponse(index));
    _verdict = verdict;
    _drawn = null;

    await _attempts.record(Attempt(
      itemId: flight.item.id,
      itemVersion: flight.item.version,
      conceptId: flight.item.conceptId,
      at: _clock.nowUtc(),
      passed: verdict.passed,
      response: ChoiceResponse(index),
      itemType: flight.item.type,
      difficulty: flight.item.difficulty,
      signals: ProcessSignals(attempts: flight.attempts),
      verdict: verdict,
    ));

    if (verdict.passed) {
      _consecutiveFailures = 0;
      _passedThisSession += 1;
      _phase = LoopPhase.passed;
    } else {
      _consecutiveFailures += 1;
      _phase = LoopPhase.tryAgain;
    }
    notifyListeners();
  }

  /// The child asked for a hint. Costs nothing: §10 forbids a penalty for asking.
  void showHint() {
    final flight = _current;
    if (flight == null) return;
    flight.hintsShown += 1;
    notifyListeners();
  }

  /// The child pressed *encore* after a wrong answer, and stays on this item.
  void tryAgain() {
    if (_current == null) return;
    _verdict = null;
    _phase = LoopPhase.working;
    notifyListeners();
  }

  /// The child pressed *continuer* after a right answer.
  Future<void> next() => _serveNext();
}
