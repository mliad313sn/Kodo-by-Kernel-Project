/// The consent gate (FR-M4-04, FR-M4-05, §13, PO decisions D-007 and D-003).
///
/// §13 is owned by seat 13 and carries a blocking veto. Two rules here are absolute:
///
/// * **The camera does not exist in v1.** Not disabled by a flag — absent. PO decision
///   D-007 promoted `IMP-009` (S1, confidence 1.0) from a backlog item to a scope
///   decision, on the grounds that a moderation surface we cannot staff is not a feature.
/// * **Nothing about the learning path requires consent.** A child with no guardian
///   present must be able to complete World 12. Consent gates the microphone, the gallery
///   and sharing; it never gates a concept.
library;

/// A capability that a guardian may or may not have allowed.
enum Capability {
  /// Recording a sound with the device microphone.
  microphone,

  /// Importing an image from the device's own gallery.
  imageImport,

  /// Publishing a project to the class gallery.
  sharing,

  /// Uploading telemetry. Queued locally either way (`FR-M14-04`).
  telemetryUpload,

  /// Capturing from the camera.
  ///
  /// Present in the enum and permanently unreachable, so that a future contributor who
  /// adds a camera button discovers the refusal at the gate rather than at G4.
  camera,
}

/// Why a capability is unavailable, in terms a parent screen can render.
enum ConsentState {
  /// A guardian has allowed it.
  granted,

  /// No guardian has answered yet.
  notAsked,

  /// A guardian said no.
  refused,

  /// Not available in this version, whatever anybody says.
  notInThisVersion,
}

/// The gate. Ask it; never ask a setting directly.
class ConsentGate {
  ConsentGate({Map<Capability, bool> granted = const {}})
      : _granted = {...granted};

  final Map<Capability, bool> _granted;

  /// Capabilities that no consent can unlock in v1.
  ///
  /// The test that matters is not that this set contains the camera; it is that
  /// [allows] consults it *before* anything else, so no code path can route around it.
  static const Set<Capability> removedFromV1 = {Capability.camera};

  ConsentState stateOf(Capability capability) {
    if (removedFromV1.contains(capability)) {
      return ConsentState.notInThisVersion;
    }
    final answer = _granted[capability];
    if (answer == null) return ConsentState.notAsked;
    return answer ? ConsentState.granted : ConsentState.refused;
  }

  bool allows(Capability capability) =>
      stateOf(capability) == ConsentState.granted;

  /// Records a guardian's answer. Called only from the parent space (`FR-M11-01`), which
  /// is PIN- or biometric-gated; a child cannot reach this.
  ///
  /// Returns false when the capability is not grantable at all, so a caller cannot
  /// mistakenly believe it succeeded.
  bool setByGuardian(Capability capability, {required bool allowed}) {
    if (removedFromV1.contains(capability)) return false;
    _granted[capability] = allowed;
    return true;
  }

  Map<String, bool> toJson() =>
      {for (final e in _granted.entries) e.key.name: e.value};

  static ConsentGate fromJson(Map<String, Object?> json) => ConsentGate(
        granted: {
          for (final e in json.entries)
            if (Capability.values.any((c) => c.name == e.key) &&
                e.value is bool)
              Capability.values.firstWhere((c) => c.name == e.key):
                  e.value! as bool,
        },
      );
}

/// Thrown by nothing. Kept as a type so that a capability refusal is representable in a
/// result rather than as an exception — M4 follows M1's rule that failures are values.
class CapabilityRefused {
  const CapabilityRefused(this.capability, this.state);
  final Capability capability;
  final ConsentState state;

  /// Message key for the child-facing sentence. Never the reason text itself: the words
  /// live in the localisation layer with everything else (`FR-M15-04`).
  String get messageKey => 'consent.${capability.name}.${state.name}';
}
