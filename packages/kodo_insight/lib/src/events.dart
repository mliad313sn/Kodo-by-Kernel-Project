/// The event taxonomy (FR-M17-01, FR-M17-02).
///
/// *"Event taxonomy fixed at design time"*, and the module prompt's `Do not`: **do not add
/// an event because it might be interesting later.** So the taxonomy is a closed enum with
/// a declared schema per event, and a schema test rejects anything undeclared — which is
/// the only version of "fixed at design time" that survives contact with a sprint.
library;

import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Every event KODO emits.
enum EventKind {
  // --- learning (FR-M17-01) -------------------------------------------------------------
  itemStarted('item_started'),
  run('run'),
  errorRaised('error_raised'),
  hintShown('hint_shown'),
  itemPassed('item_passed'),
  itemFailed('item_failed'),
  conceptMastered('concept_mastered'),
  projectSaved('project_saved'),
  sessionEnd('session_end'),

  // --- wellbeing (M8, §10) --------------------------------------------------------------
  //
  // §10: *"We instrument for wellbeing, not only for retention… A rise in these is treated
  // as a defect of the same severity as a crash."* They are in the same taxonomy as the
  // learning events on purpose: a separate, optional wellbeing pipeline is one that gets
  // switched off.
  frustration('frustration'),
  lateNightSession('late_night_session'),
  goalOverrun('goal_overrun'),
  abandonedAfterFailure('abandoned_after_failure'),
  stoppedAtOwnGoal('stopped_at_own_goal');

  const EventKind(this.wireName);
  final String wireName;

  static EventKind? byWireName(String name) {
    for (final k in EventKind.values) {
      if (k.wireName == name) return k;
    }
    return null;
  }

  bool get isWellbeing => switch (this) {
        EventKind.frustration ||
        EventKind.lateNightSession ||
        EventKind.goalOverrun ||
        EventKind.abandonedAfterFailure ||
        EventKind.stoppedAtOwnGoal =>
          true,
        _ => false,
      };
}

/// The fields an event may carry.
///
/// A closed list, and deliberately short. `FR-M17-02` requires the stream to be
/// pseudonymous *by construction*, and the way that fails is one well-meaning field at a
/// time — a display name here, a device id there.
enum EventField {
  conceptId,
  itemId,
  itemVersion,
  itemType,
  difficulty,
  errorCode,
  attemptNumber,
  hintLevel,
  durationMs,
  world,
  localHour,
  goalMinutes,
  actualMinutes,
}

/// What each event is allowed to carry.
const eventSchema = <EventKind, Set<EventField>>{
  EventKind.itemStarted: {
    EventField.itemId,
    EventField.itemVersion,
    EventField.conceptId,
    EventField.itemType,
    EventField.difficulty
  },
  EventKind.run: {EventField.itemId, EventField.durationMs},
  EventKind.errorRaised: {EventField.itemId, EventField.errorCode},
  EventKind.hintShown: {EventField.itemId, EventField.hintLevel},
  EventKind.itemPassed: {
    EventField.itemId,
    EventField.itemVersion,
    EventField.conceptId,
    EventField.itemType,
    EventField.difficulty,
    EventField.attemptNumber,
    EventField.durationMs
  },
  EventKind.itemFailed: {
    EventField.itemId,
    EventField.itemVersion,
    EventField.conceptId,
    EventField.itemType,
    EventField.difficulty,
    EventField.attemptNumber,
    EventField.durationMs
  },
  EventKind.conceptMastered: {EventField.conceptId, EventField.world},
  EventKind.projectSaved: {EventField.durationMs},
  EventKind.sessionEnd: {EventField.durationMs, EventField.localHour},
  EventKind.frustration: {
    EventField.conceptId,
    EventField.itemId,
    EventField.attemptNumber
  },
  EventKind.lateNightSession: {EventField.localHour, EventField.durationMs},
  EventKind.goalOverrun: {EventField.goalMinutes, EventField.actualMinutes},
  EventKind.abandonedAfterFailure: {
    EventField.itemId,
    EventField.conceptId,
    EventField.attemptNumber
  },
  EventKind.stoppedAtOwnGoal: {
    EventField.goalMinutes,
    EventField.actualMinutes
  },
};

/// Why an event was refused.
class EventRejected implements Exception {
  const EventRejected(this.reason);
  final String reason;

  @override
  String toString() => 'EventRejected: $reason';
}

/// One telemetry record.
///
/// There is no name, no email, no device identifier and no advertising id, because there
/// is nowhere to put one. `FR-M17-02` is enforced by the type rather than by review.
class LearningEvent {
  LearningEvent({
    required this.kind,
    required this.pseudonym,
    required this.at,
    Map<EventField, Object?> fields = const {},
  }) : fields = Map.unmodifiable(fields) {
    final allowed = eventSchema[kind]!;
    final extra = fields.keys.toSet().difference(allowed);
    if (extra.isNotEmpty) {
      throw EventRejected(
          '${kind.wireName} may not carry ${extra.map((f) => f.name).join(', ')}');
    }
  }

  final EventKind kind;

  /// A per-profile pseudonym. See [pseudonymFor].
  final String pseudonym;
  final DateTime at;
  final Map<EventField, Object?> fields;

  Map<String, Object?> toJson() => {
        'event': kind.wireName,
        'who': pseudonym,
        'at': at.toUtc().toIso8601String(),
        for (final e in fields.entries) e.key.name: e.value,
      };

  /// Parses a record off the wire, refusing anything the schema does not declare.
  ///
  /// This is the schema test of the M17 acceptance criteria, and it runs at the boundary
  /// rather than only in CI: a pack or a partner integration cannot inject an event that
  /// nobody agreed to collect.
  static LearningEvent fromJson(Map<String, Object?> json) {
    final kind = EventKind.byWireName(json['event'] as String? ?? '');
    if (kind == null) {
      throw EventRejected('unknown event "${json['event']}"');
    }
    final fields = <EventField, Object?>{};
    for (final entry in json.entries) {
      if (const {'event', 'who', 'at'}.contains(entry.key)) continue;
      final field = EventField.values.where((f) => f.name == entry.key);
      if (field.isEmpty) {
        throw EventRejected('unknown field "${entry.key}" on ${kind.wireName}');
      }
      fields[field.first] = entry.value;
    }
    return LearningEvent(
      kind: kind,
      pseudonym: json['who'] as String? ?? '',
      at: DateTime.parse(json['at']! as String),
      fields: fields,
    );
  }
}

/// A stable pseudonym for a local profile.
///
/// A salted hash of the profile's local id. The salt never leaves the device, so the same
/// child on two devices is two pseudonyms — which loses a little analytic precision and
/// gains the property that the stream cannot be joined back to a person.
String pseudonymFor(String localProfileId, String deviceSalt) => sha256
    .convert(utf8.encode('$deviceSalt::$localProfileId'))
    .toString()
    .substring(0, 24);
