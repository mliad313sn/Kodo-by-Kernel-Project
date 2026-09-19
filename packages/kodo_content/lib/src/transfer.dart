/// Getting a pack onto a device, and finishing what was started (`FR-M14-03`).
///
/// *"Resumable Wi-Fi download; sideload from teacher device or SD."* Two clauses, and the
/// design decision is that they are **one** path. A classroom with no Wi-Fi is the case
/// this programme exists for, so the sideload may not be the branch nobody tested: a
/// school's shared laptop, a teacher's phone over the local network and an SD card are all
/// [ChunkSource]s, and the transfer, the resume and the verification are the same code for
/// all three.
///
/// **Resumable means resumable across a dead app, not across a lost packet.** A child on a
/// borrowed phone loses the connection, closes KODO, and comes back tomorrow; a transfer
/// that only survived a socket timeout would not help them. So the state that says where
/// we got to is a small serialisable thing, written down, and the transfer is driven from
/// it rather than from anything held in memory.
///
/// **Nothing here is on the learning path.** `NFR-OFF-01` is kept structurally by
/// `InstalledContent` having no method that fetches; this file adds none either. It
/// produces *bytes*, and installing them is still the installer's decision, made against
/// the manifest.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'pack.dart';

/// Where a pack's bytes come from.
///
/// One interface for Wi-Fi, for a teacher's device and for an SD card, because the thing
/// that differs between them is how a range of bytes is read and nothing else. A source
/// that cannot serve a range cannot be resumed from, and says so.
abstract class ChunkSource {
  /// The total size, or null when the source will not say until it has finished.
  int? get totalBytes;

  /// Whether the source can start from an offset. A plain file and an HTTP server that
  /// honours `Range` can; a stream cannot.
  bool get supportsRanges;

  /// Reads at most [length] bytes from [offset]. Fewer is not an error — a short read is
  /// how a flaky connection presents itself, and the transfer treats it as progress
  /// rather than as failure.
  Future<Uint8List> read(int offset, int length);
}

/// Why a transfer stopped.
enum TransferOutcome {
  /// Every byte arrived and the hash matched.
  complete,

  /// Progress was made and there is more to come. Resume with the same state.
  paused,

  /// The source has moved on to a different version. The state was discarded.
  sourceChanged,

  /// Every byte arrived and the hash did not match.
  corrupted,

  /// The source returned nothing at all, twice running.
  stalled,
}

/// Where a transfer got to, small enough to write down after every chunk.
///
/// Serialisable on purpose: a resume that only worked while the app was running would not
/// help the child this requirement is about, who closes KODO on a borrowed phone and comes
/// back tomorrow.
class TransferState {
  const TransferState({
    required this.world,
    required this.version,
    required this.contentHash,
    this.received = 0,
    this.chunkBytes = 64 * 1024,
  });

  final int world;
  final int version;

  /// The hash the finished bytes must have. Carried in the state as well as in the
  /// manifest so that a resume can tell "the same pack, continued" from "a different pack
  /// at the same address" without trusting the version number alone.
  final String contentHash;

  /// Bytes already on disk. Only whole chunks are counted, so a half-written chunk is
  /// fetched again rather than spliced.
  final int received;

  final int chunkBytes;

  TransferState advanced(int bytes) => TransferState(
        world: world,
        version: version,
        contentHash: contentHash,
        received: received + bytes,
        chunkBytes: chunkBytes,
      );

  Map<String, Object?> toJson() => {
        'world': world,
        'version': version,
        'contentHash': contentHash,
        'received': received,
        'chunk': chunkBytes,
      };

  static TransferState fromJson(Map<String, Object?> j) => TransferState(
        world: j['world']! as int,
        version: j['version']! as int,
        contentHash: j['contentHash']! as String,
        received: (j['received'] as int?) ?? 0,
        chunkBytes: (j['chunk'] as int?) ?? 64 * 1024,
      );

  static TransferState startingFrom(PackManifest manifest) => TransferState(
        world: manifest.world,
        version: manifest.version,
        contentHash: manifest.contentHash,
      );

  String encode() => jsonEncode(toJson());

  static TransferState decode(String text) =>
      fromJson(jsonDecode(text) as Map<String, Object?>);
}

/// The result of one run of a transfer.
class TransferResult {
  const TransferResult(this.outcome, this.state, {this.bytes});
  final TransferOutcome outcome;

  /// Where to resume from. Null once there is nothing left to resume.
  final TransferState? state;

  /// The complete pack, only when [outcome] is [TransferOutcome.complete].
  final Uint8List? bytes;

  bool get isDone => outcome == TransferOutcome.complete;
}

/// Somewhere to keep the bytes that have arrived so far.
///
/// An interface rather than a file, because the same transfer has to work against a
/// device's storage, against a test's memory, and — on the web — against whatever the
/// browser gives. None of that belongs in the transfer.
abstract class PartialStore {
  Future<Uint8List> read(int world);
  Future<void> write(int world, Uint8List bytes);
  Future<void> discard(int world);
}

/// A [PartialStore] that keeps everything in memory. Used by the tests, and by any host
/// that would rather hold a small pack than write one.
class MemoryPartialStore implements PartialStore {
  final Map<int, Uint8List> _parts = {};

  @override
  Future<Uint8List> read(int world) async => _parts[world] ?? Uint8List(0);

  @override
  Future<void> write(int world, Uint8List bytes) async => _parts[world] = bytes;

  @override
  Future<void> discard(int world) async => _parts.remove(world);
}

/// Moves a pack onto the device, a chunk at a time, and can be stopped at any point.
class PackTransfer {
  PackTransfer({
    required this.source,
    required this.store,
    required this.manifest,
  });

  final ChunkSource source;
  final PartialStore store;
  final PackManifest manifest;

  /// Continues [state], or starts one when it is null.
  ///
  /// [maxChunks] bounds one run so a host can do a little work and come back — which is
  /// what makes "resumable" usable rather than merely possible on a phone that may be put
  /// in a pocket at any moment.
  Future<TransferResult> run(
      {TransferState? state, int maxChunks = 1 << 30}) async {
    var current = state ?? TransferState.startingFrom(manifest);

    /* A resume whose source has moved on must not splice two versions together. The
       version AND the hash are both checked: a publisher who rebuilt a pack without
       bumping its version would otherwise hand a child half of yesterday's world and half
       of today's, and the corruption would only show up as a missing item. */
    if (current.world != manifest.world ||
        current.version != manifest.version ||
        current.contentHash != manifest.contentHash) {
      await store.discard(current.world);
      return TransferResult(
          TransferOutcome.sourceChanged, TransferState.startingFrom(manifest));
    }

    /* A source that cannot serve a range cannot be resumed from — so the honest thing is
       to start it again from nothing rather than to pretend, which would silently produce
       a file with a hole in the middle of it. */
    if (!source.supportsRanges && current.received > 0) {
      await store.discard(current.world);
      current = TransferState.startingFrom(manifest);
    }

    var got = await store.read(current.world);
    if (got.length != current.received) {
      /* The state and the bytes disagree, which means something interrupted the write
         itself. Trust the bytes, never the bookkeeping: bytes are what will be hashed. */
      current = TransferState(
        world: current.world,
        version: current.version,
        contentHash: current.contentHash,
        received: got.length,
        chunkBytes: current.chunkBytes,
      );
    }

    var emptyReads = 0;
    for (var chunk = 0; chunk < maxChunks; chunk++) {
      final total = source.totalBytes;
      if (total != null && current.received >= total) break;

      final piece = await source.read(current.received, current.chunkBytes);
      if (piece.isEmpty) {
        emptyReads++;
        /* Twice is a stall, not a hiccup. Once can be a connection dropping mid-chunk,
           which the next run picks up from exactly where this one stopped. */
        if (emptyReads >= 2) {
          return TransferResult(TransferOutcome.stalled, current);
        }
        continue;
      }
      emptyReads = 0;

      final grown = Uint8List(got.length + piece.length)
        ..setAll(0, got)
        ..setAll(got.length, piece);
      got = grown;
      current = current.advanced(piece.length);
      /* Written after every chunk, not at the end. The whole requirement is about the
         run that does NOT reach the end. */
      await store.write(current.world, got);

      if (total != null && current.received >= total) break;
    }

    final total = source.totalBytes;
    if (total == null || current.received < total) {
      return TransferResult(TransferOutcome.paused, current);
    }

    /* Verified here rather than at install, so a corrupted transfer is discarded while
       the bytes are still the transfer's problem. An installer that is handed bad bytes
       refuses them correctly; a child who has to download a world twice because nobody
       checked until the end has paid for the bytes twice. */
    if (sha256.convert(got).toString() != manifest.contentHash) {
      await store.discard(current.world);
      return TransferResult(
          TransferOutcome.corrupted, TransferState.startingFrom(manifest));
    }

    await store.discard(current.world);
    return TransferResult(TransferOutcome.complete, null, bytes: got);
  }
}

/// A pack sitting in memory: an SD card's file, or what a teacher's device handed over.
///
/// The sideload of `FR-M14-03`, and deliberately the *same* [ChunkSource] as a download —
/// so the classroom with no Wi-Fi, which is the case this programme exists for, uses the
/// path that is tested rather than the branch nobody exercised.
class BytesSource implements ChunkSource {
  BytesSource(this.bytes);
  final Uint8List bytes;

  @override
  int? get totalBytes => bytes.length;

  @override
  bool get supportsRanges => true;

  @override
  Future<Uint8List> read(int offset, int length) async {
    if (offset >= bytes.length) return Uint8List(0);
    final end = (offset + length).clamp(0, bytes.length);
    return Uint8List.sublistView(bytes, offset, end);
  }
}
