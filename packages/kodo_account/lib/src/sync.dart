/// Sync, export and deletion (FR-M13-04, FR-M13-05).
///
/// *"Sync is last-write-wins per project with conflict copies, **never a silent
/// overwrite**."* That is the whole design, and the reason for it is that a child who loses
/// an afternoon's work to a sync stops trusting the product in a way no feature recovers.
///
/// Mastery is not synced as a value. It is recomputed from attempts, and attempts are an
/// append-only set, so merging two devices is a set union and cannot double-count. That is
/// how the M7 acceptance test — *30 days offline, then synced, with no loss and no
/// double-counting* — is true by construction rather than by careful merging.
library;

import 'package:kodo_grader/kodo_grader.dart';

/// A thing that syncs.
class SyncedProject {
  const SyncedProject({
    required this.id,
    required this.profileId,
    required this.name,
    required this.source,
    required this.updatedAt,
    required this.deviceId,
  });

  final String id;
  final String profileId;
  final String name;
  final String source;
  final DateTime updatedAt;
  final String deviceId;

  SyncedProject copyWith({String? id, String? name}) => SyncedProject(
        id: id ?? this.id,
        profileId: profileId,
        name: name ?? this.name,
        source: source,
        updatedAt: updatedAt,
        deviceId: deviceId,
      );
}

/// What happened to one project during a merge.
enum MergeOutcome {
  /// Only one side had it.
  copied,

  /// Both sides had it and they were identical.
  identical,

  /// Both sides changed it, so both were kept and one was renamed.
  conflictCopyCreated,

  /// One side was strictly newer and the other had not changed since.
  fastForward,
}

class MergeResult {
  const MergeResult(this.projects, this.attempts, this.outcomes);
  final List<SyncedProject> projects;
  final List<Attempt> attempts;
  final Map<String, MergeOutcome> outcomes;

  int get conflictCopies => outcomes.values
      .where((o) => o == MergeOutcome.conflictCopyCreated)
      .length;
}

/// Merges two devices' state.
///
/// [ancestorSources] is what each project looked like the last time the two sides agreed.
/// Without it, "both changed" cannot be told from "one changed", and a tool that cannot
/// tell them apart either overwrites or creates a conflict copy every single sync.
MergeResult mergeDevices({
  required List<SyncedProject> local,
  required List<SyncedProject> remote,
  required List<Attempt> localAttempts,
  required List<Attempt> remoteAttempts,
  Map<String, String> ancestorSources = const {},
}) {
  final byId = <String, SyncedProject>{};
  final outcomes = <String, MergeOutcome>{};
  final extras = <SyncedProject>[];

  for (final project in local) {
    byId[project.id] = project;
    outcomes[project.id] = MergeOutcome.copied;
  }

  for (final incoming in remote) {
    final mine = byId[incoming.id];
    if (mine == null) {
      byId[incoming.id] = incoming;
      outcomes[incoming.id] = MergeOutcome.copied;
      continue;
    }
    if (mine.source == incoming.source) {
      outcomes[incoming.id] = MergeOutcome.identical;
      continue;
    }

    final ancestor = ancestorSources[incoming.id];
    final mineChanged = ancestor == null || mine.source != ancestor;
    final theirsChanged = ancestor == null || incoming.source != ancestor;

    if (mineChanged && !theirsChanged) {
      outcomes[incoming.id] = MergeOutcome.fastForward;
      continue;
    }
    if (theirsChanged && !mineChanged) {
      byId[incoming.id] = incoming;
      outcomes[incoming.id] = MergeOutcome.fastForward;
      continue;
    }

    // Both changed. Keep BOTH — never a silent overwrite. The newer one keeps the name
    // the child knows; the older gets a copy name, because losing the version you were
    // just looking at is the failure a child notices.
    final newer = incoming.updatedAt.isAfter(mine.updatedAt) ? incoming : mine;
    final older = identical(newer, incoming) ? mine : incoming;
    byId[incoming.id] = newer;
    extras.add(older.copyWith(
      id: '${older.id}-copie-${older.deviceId}',
      name: '${older.name} (copie)',
    ));
    outcomes[incoming.id] = MergeOutcome.conflictCopyCreated;
  }

  // Attempts are append-only and identified by (item, version, time, concept), so the
  // union is idempotent. Syncing twice cannot double-count, which is what makes mastery
  // safe to recompute rather than merge.
  final seen = <String>{};
  final attempts = <Attempt>[];
  for (final attempt in [...localAttempts, ...remoteAttempts]) {
    final key = '${attempt.itemId}|${attempt.itemVersion}|'
        '${attempt.at.toUtc().toIso8601String()}|${attempt.conceptId}|${attempt.passed}';
    if (seen.add(key)) attempts.add(attempt);
  }
  attempts.sort((a, b) => a.at.compareTo(b.at));

  return MergeResult([...byId.values, ...extras], attempts, outcomes);
}

/// Everything held about one child, for the export of `FR-M13-05`.
class DataExport {
  const DataExport({
    required this.profile,
    required this.projects,
    required this.attempts,
    required this.generatedAt,
  });

  final Map<String, Object?> profile;
  final List<Map<String, Object?>> projects;
  final List<Map<String, Object?>> attempts;
  final DateTime generatedAt;

  Map<String, Object?> toJson() => {
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'profile': profile,
        'projects': projects,
        'attempts': attempts,
      };
}

/// The stores a deletion has to reach.
///
/// Named explicitly rather than left to a `deleteEverything()` call, because the way a
/// deletion fails is that somebody adds a seventh store and nobody updates the sixth-store
/// function. A test asserts that every store a device declares is covered.
enum DataStore {
  profile,
  projects,
  attempts,
  mastery,
  telemetryQueue,
  sharedItems
}

/// The result of a deletion request (`FR-M13-05`).
class DeletionReceipt {
  const DeletionReceipt({
    required this.profileId,
    required this.requestedAt,
    required this.completedAt,
    required this.storesCleared,
    required this.recordsRemaining,
  });

  final String profileId;
  final DateTime requestedAt;
  final DateTime completedAt;
  final Set<DataStore> storesCleared;

  /// Verified by an independent query after the deletion, per the M13 acceptance test.
  /// Anything other than zero is a failed deletion, not a partial one.
  final int recordsRemaining;

  static const promisedWindow = Duration(days: 30);

  bool get isComplete =>
      recordsRemaining == 0 && storesCleared.length == DataStore.values.length;

  bool get isWithinPromisedWindow =>
      completedAt.difference(requestedAt) <= promisedWindow;
}
