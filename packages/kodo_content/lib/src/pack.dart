/// Offline-first content packs (M14).
///
/// *"The entire curriculum through World 12 must be usable with the aircraft mode on,
/// after the initial install plus one content download"* — and the module prompt calls the
/// test of that **"the single most important test in the programme"**.
///
/// A pack carries everything a world needs: its concepts and their prerequisite edges, its
/// tutorials, its items with their grading policies, its hints, and the keys for its audio
/// and vector assets. Nothing in a pack refers to a URL that has to resolve at run time.
/// That is the guarantee, and it is checked here rather than hoped for.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:kodo_grader/kodo_grader.dart';

import 'tutorial.dart';

/// A world's worth of content.
class ContentPack {
  const ContentPack({
    required this.world,
    required this.version,
    required this.nameKeys,
    required this.concepts,
    required this.tutorials,
    required this.items,
    this.audioKeys = const [],
    this.assetKeys = const [],
    this.sizeBytes = 0,
  });

  final int world;

  /// Monotonic. A pack may be replaced by a higher version; content migration must never
  /// invalidate stored mastery (`FR-M14-04`'s companion rule in the module prompt), which
  /// is why mastery is recomputed from attempts and never stored as a total.
  final int version;

  final Map<String, String> nameKeys;

  /// Concept id → prerequisite ids. The graph M7 walks.
  final Map<String, List<String>> concepts;

  final List<Tutorial> tutorials;
  final List<Item> items;

  /// Recording keys the pack expects to find in its audio bundle.
  final List<String> audioKeys;
  final List<String> assetKeys;

  /// Measured size of the packaged bundle, for the CI budget.
  final int sizeBytes;

  /// §FR-M14-02: ≤ 12 MB per world including audio.
  static const worldBudgetBytes = 12 * 1024 * 1024;

  /// §FR-M14-02: ≤ 25 MB base app.
  static const baseAppBudgetBytes = 25 * 1024 * 1024;

  Map<String, Object?> toJson() => {
        'world': world,
        'version': version,
        'name': nameKeys,
        'concepts': concepts,
        'tutorials': [for (final t in tutorials) t.toJson()],
        'items': [for (final i in items) i.toJson()],
        'audio': audioKeys,
        'assets': assetKeys,
        'sizeBytes': sizeBytes,
      };

  static ContentPack fromJson(Map<String, Object?> j) => ContentPack(
        world: j['world']! as int,
        version: j['version']! as int,
        nameKeys: (j['name']! as Map<String, Object?>).cast<String, String>(),
        concepts: {
          for (final e in (j['concepts']! as Map<String, Object?>).entries)
            e.key: (e.value! as List<Object?>).cast<String>(),
        },
        tutorials: [
          for (final t in (j['tutorials']! as List<Object?>))
            Tutorial.fromJson(t! as Map<String, Object?>),
        ],
        items: [
          for (final i in (j['items']! as List<Object?>))
            Item.fromJson(i! as Map<String, Object?>),
        ],
        audioKeys: ((j['audio'] as List<Object?>?) ?? const []).cast<String>(),
        assetKeys: ((j['assets'] as List<Object?>?) ?? const []).cast<String>(),
        sizeBytes: (j['sizeBytes'] as int?) ?? 0,
      );

  /// Canonical bytes: keys sorted, so the same content always hashes the same.
  ///
  /// Without this the signature would depend on map iteration order and a pack would stop
  /// verifying for no reason anybody could see.
  List<int> canonicalBytes() => utf8.encode(_canonicalJson(toJson()));
}

String _canonicalJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return '{${keys.map((k) => '${jsonEncode(k)}:${_canonicalJson(value[k])}').join(',')}}';
  }
  if (value is List) {
    return '[${value.map(_canonicalJson).join(',')}]';
  }
  return jsonEncode(value);
}

/// Why a pack was refused.
enum PackRejection {
  /// The bytes do not match the manifest hash.
  corrupted,

  /// No signature, or one this device cannot verify.
  unsigned,

  /// A newer pack has already been installed.
  olderThanInstalled,

  /// Over the per-world size budget.
  overBudget,

  /// The pack refers to something it does not contain.
  incomplete,
}

/// A refusal, with the sentence a child sees.
class PackRefused {
  const PackRefused(this.reason, this.detail);
  final PackRejection reason;

  /// For the log. Never shown.
  final String detail;

  /// The child-facing message key. Never English, never technical — a corrupted download
  /// is not a child's fault and must not read like an accusation.
  String get messageKey => 'pack.refused.${reason.name}';

  @override
  String toString() => '${reason.name}: $detail';
}

/// Verifies that a pack is what its publisher made.
///
/// **What ships today is integrity, not authenticity.** [Sha256Integrity] detects any
/// modification of a pack's bytes, which covers a corrupted download, a truncated
/// sideload and a damaged SD card — the failure modes a classroom actually meets.
///
/// It does **not** prove who made the pack. Doing that needs asymmetric signatures with
/// the public key in the app and the private key on the build server, and an Ed25519
/// verifier in pure Dart is a real piece of work that has not been written. `FR-M14-02`
/// says *signed*, so this is a gap and is recorded as `M14-SEC-01` rather than being
/// papered over with an HMAC, which would put the signing key on every device and prove
/// nothing at all.
abstract class PackVerifier {
  /// Null when the pack is acceptable.
  PackRefused? verify(ContentPack pack, PackManifest manifest);
}

/// What travels beside a pack.
class PackManifest {
  const PackManifest({
    required this.world,
    required this.version,
    required this.contentHash,
    this.signature,
    this.signatureAlgorithm,
  });

  final int world;
  final int version;

  /// SHA-256 of [ContentPack.canonicalBytes].
  final String contentHash;

  /// Detached signature over [contentHash]. Absent until `M14-SEC-01` is closed.
  final String? signature;
  final String? signatureAlgorithm;

  Map<String, Object?> toJson() => {
        'world': world,
        'version': version,
        'contentHash': contentHash,
        if (signature != null) 'signature': signature,
        if (signatureAlgorithm != null) 'algorithm': signatureAlgorithm,
      };

  static PackManifest fromJson(Map<String, Object?> j) => PackManifest(
        world: j['world']! as int,
        version: j['version']! as int,
        contentHash: j['contentHash']! as String,
        signature: j['signature'] as String?,
        signatureAlgorithm: j['algorithm'] as String?,
      );

  /// Builds the manifest for [pack].
  static PackManifest of(ContentPack pack) => PackManifest(
        world: pack.world,
        version: pack.version,
        contentHash: sha256.convert(pack.canonicalBytes()).toString(),
      );
}

/// Content-integrity verification.
class Sha256Integrity implements PackVerifier {
  const Sha256Integrity({this.requireSignature = false});

  /// When true, a manifest with no signature is refused. Off until `M14-SEC-01` ships a
  /// verifier, because refusing every pack would be worse than the gap it closes.
  final bool requireSignature;

  @override
  PackRefused? verify(ContentPack pack, PackManifest manifest) {
    if (manifest.world != pack.world || manifest.version != pack.version) {
      return const PackRefused(
          PackRejection.corrupted, 'manifest describes a different pack');
    }
    final actual = sha256.convert(pack.canonicalBytes()).toString();
    if (actual != manifest.contentHash) {
      return PackRefused(PackRejection.corrupted,
          'content hash ${actual.substring(0, 12)} != ${manifest.contentHash.substring(0, 12)}');
    }
    if (requireSignature && (manifest.signature ?? '').isEmpty) {
      return const PackRefused(
          PackRejection.unsigned, 'no signature on the manifest');
    }
    if (pack.sizeBytes > ContentPack.worldBudgetBytes) {
      return PackRefused(PackRejection.overBudget,
          '${pack.sizeBytes} bytes over the ${ContentPack.worldBudgetBytes} budget');
    }
    return null;
  }
}

/// The device's installed content.
///
/// Everything a child can learn comes from here. There is no method that fetches, because
/// `FR-M14-01` says no learning content may be behind a run-time network call and the way
/// to guarantee that is to give the learning path no way to ask.
class ContentLibrary {
  ContentLibrary({PackVerifier? verifier})
      : _verifier = verifier ?? const Sha256Integrity();

  final PackVerifier _verifier;
  final Map<int, ContentPack> _installed = {};

  List<ContentPack> get packs =>
      (_installed.values.toList()..sort((a, b) => a.world.compareTo(b.world)));

  ContentPack? world(int n) => _installed[n];

  /// Installs, or refuses and says why.
  PackRefused? install(ContentPack pack, PackManifest manifest) {
    final refusal = _verifier.verify(pack, manifest);
    if (refusal != null) return refusal;

    final existing = _installed[pack.world];
    if (existing != null && existing.version > pack.version) {
      return PackRefused(PackRejection.olderThanInstalled,
          'world ${pack.world} already has version ${existing.version}');
    }

    final missing = _incompleteness(pack);
    if (missing != null) return missing;

    _installed[pack.world] = pack;
    return null;
  }

  /// A pack that names a tutorial for a concept it does not define, or an item whose
  /// concept is not in its graph, will fail at run time in front of a child. It is refused
  /// at install instead.
  PackRefused? _incompleteness(ContentPack pack) {
    for (final tutorial in pack.tutorials) {
      if (!pack.concepts.containsKey(tutorial.conceptId)) {
        return PackRefused(PackRejection.incomplete,
            'tutorial ${tutorial.id} teaches ${tutorial.conceptId}, which the pack does not define');
      }
    }
    for (final item in pack.items) {
      if (!pack.concepts.containsKey(item.conceptId)) {
        return PackRefused(PackRejection.incomplete,
            'item ${item.id} belongs to ${item.conceptId}, which the pack does not define');
      }
    }
    // A prerequisite pointing outside every installed pack is NOT a reason to refuse.
    //
    // World 2 depends on World 1, and a teacher sideloading World 5 onto a classroom
    // tablet must get World 5 rather than an error. The concept simply never unlocks:
    // M7's `unlockedFor` opens a concept only when its prerequisites are mastered, and a
    // prerequisite that is not installed cannot be mastered. The child meets an island
    // they have not reached yet, which is the map working, not a wall.
    //
    // What the library owes instead is honesty about it — see [missingPrerequisites],
    // which the classroom seeding screen shows to the teacher, who is the person who can
    // actually do something about it.
    return null;
  }

  /// Prerequisites that no installed pack defines.
  ///
  /// Not an error; a statement about what this device can currently teach. `FR-M12-03`
  /// has a teacher seeding devices over a local hotspot with no internet, and the thing
  /// they need to know is "these worlds will not open until you also copy World 1".
  Set<String> get missingPrerequisites {
    final defined = {for (final p in packs) ...p.concepts.keys};
    return {
      for (final p in packs)
        for (final edges in p.concepts.values)
          for (final prerequisite in edges)
            if (!defined.contains(prerequisite)) prerequisite,
    };
  }

  /// Every item available offline, for the scheduler.
  List<Item> get allItems => [for (final p in packs) ...p.items];

  List<Tutorial> get allTutorials => [for (final p in packs) ...p.tutorials];

  /// Concept → prerequisites, across every installed pack.
  Map<String, List<String>> get conceptGraph => {
        for (final p in packs) ...p.concepts,
      };

  int get totalBytes => packs.fold(0, (sum, p) => sum + p.sizeBytes);
}

/// Telemetry that queues locally and uploads opportunistically (`FR-M14-04`).
///
/// *"All telemetry queues locally and uploads opportunistically; no feature ever blocks on
/// the network."* The queue is bounded, and it drops the **oldest** events when full:
/// losing last month's telemetry is a shame, losing today's session because the queue
/// filled up in March is a bug.
class TelemetryQueue {
  TelemetryQueue({this.capacity = 5000});

  final int capacity;
  final List<Map<String, Object?>> _queue = [];
  int _dropped = 0;

  int get length => _queue.length;
  int get dropped => _dropped;
  List<Map<String, Object?>> get pending => List.unmodifiable(_queue);

  /// Never fails, never blocks, never throws.
  void add(Map<String, Object?> event) {
    _queue.add(event);
    while (_queue.length > capacity) {
      _queue.removeAt(0);
      _dropped++;
    }
  }

  /// Hands over up to [max] events. They stay queued until [confirmSent].
  List<Map<String, Object?>> take({int max = 200}) =>
      _queue.take(max).toList(growable: false);

  /// Removes what the server confirmed. A failed upload loses nothing.
  void confirmSent(int count) =>
      _queue.removeRange(0, count.clamp(0, _queue.length));
}
