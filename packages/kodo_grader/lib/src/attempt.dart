/// Attempt persistence (FR-M6-08, FR-M6-09).
///
/// Every attempt stores the program the child actually wrote, not merely whether they
/// passed — *"so that a teacher or parent can see what the child actually wrote"*. It also
/// stores the item version it was graded under, which is what makes `FR-M6-09` true: a
/// corrected item never retroactively invalidates a mastery a child already earned.
library;

import 'grader.dart';
import 'item.dart';

class Attempt {
  const Attempt({
    required this.itemId,
    required this.itemVersion,
    required this.conceptId,
    required this.at,
    required this.passed,
    required this.response,
    required this.signals,
    required this.verdict,
    this.itemType,
    this.difficulty,
  });

  final String itemId;
  final int itemVersion;
  final String conceptId;
  final DateTime at;
  final bool passed;

  /// What the child submitted — an AST snapshot for a program answer.
  final Response response;

  final ProcessSignals signals;
  final Verdict verdict;
  final ItemType? itemType;
  final Difficulty? difficulty;

  /// True when this was the child's first try at this item in this sitting.
  bool get firstAttempt => signals.attempts == 1;

  Map<String, Object?> toJson() => {
        'item': itemId,
        'itemVersion': itemVersion,
        'concept': conceptId,
        'at': at.toUtc().toIso8601String(),
        'passed': passed,
        'response': response.toJson(),
        'signals': signals.toJson(),
        'verdict': verdict.toJson(),
        if (itemType != null) 'type': itemType!.code,
        if (difficulty != null) 'difficulty': difficulty!.code,
      };
}

/// Replays a stored attempt and checks the verdict still comes out the same.
///
/// This is the M6 acceptance test *"a replayed attempt from stored AST reproduces the
/// original verdict exactly"*, and it is also the thing a teacher relies on when they open
/// a child's work three weeks later. It grades against the item **version the attempt was
/// taken under**, which is the whole point of storing it.
bool replayReproduces(Attempt attempt, Item itemAtThatVersion,
    {Grader grader = const Grader()}) {
  if (itemAtThatVersion.version != attempt.itemVersion) {
    throw ArgumentError(
      'replay needs item ${attempt.itemId} at version ${attempt.itemVersion}, '
      'not version ${itemAtThatVersion.version} — grading an old attempt against a new '
      'item is exactly what FR-M6-09 forbids',
    );
  }
  final replayed = grader.grade(itemAtThatVersion, attempt.response);
  return replayed.passed == attempt.passed &&
      replayed.situation == attempt.verdict.situation;
}

/// An append-only local store of attempts.
///
/// In the shipped product this is SQLite (§11.1). The interface is here so that M7 and the
/// dashboards can be written and tested before the database exists, and so that the
/// offline guarantee — every attempt is written locally, nothing waits for a network — is
/// a property of the type rather than of a deployment.
abstract class AttemptStore {
  Future<void> record(Attempt attempt);

  /// Most recent first.
  Future<List<Attempt>> forConcept(String conceptId, {int limit = 100});

  Future<List<Attempt>> forItem(String itemId);

  Future<List<Attempt>> recent({int limit = 100});
}

/// An in-memory store. Used by the M7 simulation and by tests; also the right thing for a
/// tutorial's scratch document, which must never write to a child's real record.
class InMemoryAttemptStore implements AttemptStore {
  final List<Attempt> _attempts = [];

  List<Attempt> get all => List.unmodifiable(_attempts);

  @override
  Future<void> record(Attempt attempt) async => _attempts.add(attempt);

  @override
  Future<List<Attempt>> forConcept(String conceptId, {int limit = 100}) async =>
      _attempts.reversed
          .where((a) => a.conceptId == conceptId)
          .take(limit)
          .toList();

  @override
  Future<List<Attempt>> forItem(String itemId) async =>
      _attempts.where((a) => a.itemId == itemId).toList();

  @override
  Future<List<Attempt>> recent({int limit = 100}) async =>
      _attempts.reversed.take(limit).toList();
}

/// The anti-frustration ladder of §4.7.
///
/// Three failures → a hint. Five → a guided step-through that stops at the divergence
/// point. Seven → do-it-with-me. Never a locked path, never a life system, never a
/// countdown, never a "you failed" screen.
enum Escalation {
  /// Keep going; nothing is offered.
  none,

  /// The relevant block glows. The first authored hint.
  hint,

  /// The second hint.
  secondHint,

  /// Run slowly and stop where the child's program diverges from the target.
  guidedStep,

  /// The tutorial rebuilds the first half and the child finishes.
  doItWithMe,
}

/// What to offer after [consecutiveFailures] failures on one item.
Escalation escalationFor(int consecutiveFailures) {
  if (consecutiveFailures >= 7) return Escalation.doItWithMe;
  if (consecutiveFailures >= 5) return Escalation.guidedStep;
  if (consecutiveFailures >= 4) return Escalation.secondHint;
  if (consecutiveFailures >= 3) return Escalation.hint;
  return Escalation.none;
}
