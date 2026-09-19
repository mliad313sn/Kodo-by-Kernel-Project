/// `FR-M14-03` — resumable Wi-Fi download, sideload from a teacher's device or an SD card.
///
/// Two clauses in the requirement and one path in the code, which is the design decision
/// worth testing: a classroom with no Wi-Fi is the case this programme exists for, so the
/// sideload may not be the branch nobody exercised. Every test below runs against the same
/// [PackTransfer]; only the [ChunkSource] changes.
///
/// The requirement's own verification is a field test, and no repository closes that. What
/// is here is everything a field test would otherwise discover the hard way.
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:kodo_content/kodo_content.dart';
import 'package:test/test.dart';

/// A source that hands over a little and then dies, the way a borrowed phone does.
class FlakySource implements ChunkSource {
  FlakySource(this.bytes, {required this.diesAfter});
  final Uint8List bytes;

  /// How many reads it answers before it starts returning nothing.
  final int diesAfter;
  int reads = 0;

  @override
  int? get totalBytes => bytes.length;

  @override
  bool get supportsRanges => true;

  @override
  Future<Uint8List> read(int offset, int length) async {
    if (reads++ >= diesAfter) return Uint8List(0);
    if (offset >= bytes.length) return Uint8List(0);
    final end = (offset + length).clamp(0, bytes.length);
    return Uint8List.sublistView(bytes, offset, end);
  }
}

/// A source that will not seek: a stream, not a file.
class StreamOnlySource implements ChunkSource {
  StreamOnlySource(this.bytes);
  final Uint8List bytes;
  int served = 0;

  @override
  int? get totalBytes => bytes.length;

  @override
  bool get supportsRanges => false;

  @override
  Future<Uint8List> read(int offset, int length) async {
    if (offset >= bytes.length) return Uint8List(0);
    final end = (offset + length).clamp(0, bytes.length);
    served++;
    return Uint8List.sublistView(bytes, offset, end);
  }
}

void main() {
  /// A pack's worth of bytes: big enough to need several chunks.
  final payload = Uint8List.fromList(
      List.generate(10000, (i) => (i * 7 + 3) % 256));
  final manifest = PackManifest(
    world: 1,
    version: 1,
    contentHash: sha256.convert(payload).toString(),
  );

  TransferState freshState({int chunkBytes = 1024}) => TransferState(
        world: manifest.world,
        version: manifest.version,
        contentHash: manifest.contentHash,
        chunkBytes: chunkBytes,
      );

  group('FR-M14-03 · the download finishes what it started', () {
    test('a whole transfer arrives and is verified', () async {
      final store = MemoryPartialStore();
      final result = await PackTransfer(
        source: BytesSource(payload),
        store: store,
        manifest: manifest,
      ).run(state: freshState());

      expect(result.outcome, TransferOutcome.complete);
      expect(result.bytes, payload);
      // Nothing is left behind once it has arrived.
      expect((await store.read(1)).length, 0);
    });

    test('a transfer that stops picks up where it stopped', () async {
      final store = MemoryPartialStore();
      final transfer = PackTransfer(
          source: BytesSource(payload), store: store, manifest: manifest);

      final first = await transfer.run(state: freshState(), maxChunks: 3);
      expect(first.outcome, TransferOutcome.paused);
      expect(first.state!.received, 3 * 1024);

      /* The state goes through JSON, because the run that matters is the one where the
         app was closed in between. A resume that only worked in memory would not help
         the child on a borrowed phone who comes back tomorrow. */
      final saved = TransferState.decode(first.state!.encode());
      final second = await transfer.run(state: saved);
      expect(second.outcome, TransferOutcome.complete);
      expect(second.bytes, payload);
    });

    test('nothing is fetched twice', () async {
      final store = MemoryPartialStore();
      final counted = _CountingSource(payload);
      final transfer =
          PackTransfer(source: counted, store: store, manifest: manifest);

      final paused = await transfer.run(state: freshState(), maxChunks: 4);
      expect(counted.bytesServed, 4 * 1024);

      await transfer.run(state: paused.state);
      /* The whole point of resuming: the second run fetched what was left and not one
         byte more. A resume that quietly starts again is the bug this requirement is
         about, and on a metered connection it is the child's money. */
      expect(counted.bytesServed, payload.length);
    });

    test('a connection that dies mid-transfer is a pause, not a loss', () async {
      final store = MemoryPartialStore();
      final flaky = FlakySource(payload, diesAfter: 2);
      final first = await PackTransfer(
              source: flaky, store: store, manifest: manifest)
          .run(state: freshState());
      // Two empty reads running is a stall, and what arrived before it is kept.
      expect(first.outcome, TransferOutcome.stalled);
      expect(first.state!.received, 2 * 1024);

      final second = await PackTransfer(
              source: BytesSource(payload), store: store, manifest: manifest)
          .run(state: first.state);
      expect(second.outcome, TransferOutcome.complete);
      expect(second.bytes, payload);
    });

    test('bytes are believed, bookkeeping is not', () async {
      /* The write was interrupted, so the state says more arrived than actually did.
         Trusting the number would produce a pack with a hole in the middle that only
         showed up as a missing item weeks later. */
      final store = MemoryPartialStore();
      await store.write(1, Uint8List.sublistView(payload, 0, 500));
      final lying = TransferState(
        world: 1,
        version: 1,
        contentHash: manifest.contentHash,
        received: 4096,
        chunkBytes: 1024,
      );
      final result = await PackTransfer(
              source: BytesSource(payload), store: store, manifest: manifest)
          .run(state: lying);
      expect(result.outcome, TransferOutcome.complete);
      expect(result.bytes, payload);
    });

    test('a pack that changed underneath a resume is restarted, never spliced',
        () async {
      final store = MemoryPartialStore();
      final transfer = PackTransfer(
          source: BytesSource(payload), store: store, manifest: manifest);
      final paused = await transfer.run(state: freshState(), maxChunks: 2);

      // Same world, same version number, different bytes: a publisher who rebuilt a pack
      // without bumping it. The hash catches what the version number does not.
      final rebuilt = Uint8List.fromList(payload.reversed.toList());
      final newManifest = PackManifest(
        world: 1,
        version: 1,
        contentHash: sha256.convert(rebuilt).toString(),
      );
      final result = await PackTransfer(
              source: BytesSource(rebuilt), store: store, manifest: newManifest)
          .run(state: paused.state);
      expect(result.outcome, TransferOutcome.sourceChanged);
      expect(result.state!.received, 0);

      final again = await PackTransfer(
              source: BytesSource(rebuilt), store: store, manifest: newManifest)
          .run(state: result.state);
      expect(again.bytes, rebuilt);
    });

    test('a corrupted transfer is caught before anything is installed', () async {
      final store = MemoryPartialStore();
      final damaged = Uint8List.fromList(payload)..[500] = 0;
      final result = await PackTransfer(
              source: BytesSource(damaged), store: store, manifest: manifest)
          .run(state: freshState());
      expect(result.outcome, TransferOutcome.corrupted);
      expect(result.bytes, isNull);
      // And the bad bytes are gone, so the next attempt is not a resume of rubbish.
      expect((await store.read(1)).length, 0);
    });

    test('a source that cannot seek is restarted rather than pretended at',
        () async {
      final store = MemoryPartialStore();
      await store.write(1, Uint8List.sublistView(payload, 0, 2048));
      final partial = TransferState(
        world: 1,
        version: 1,
        contentHash: manifest.contentHash,
        received: 2048,
        chunkBytes: 1024,
      );
      final result = await PackTransfer(
              source: StreamOnlySource(payload),
              store: store,
              manifest: manifest)
          .run(state: partial);
      // Pretending would produce a file with a hole in it. Starting again is honest and
      // is what the child would want: a complete world.
      expect(result.outcome, TransferOutcome.complete);
      expect(result.bytes, payload);
    });
  });

  group('FR-M14-03 · the sideload is the same path', () {
    test('an SD card and a download go through one transfer', () async {
      /* The design decision worth a test: a school with no Wi-Fi uses the code that has
         been exercised, not the branch nobody ran. Both of these are `ChunkSource`s and
         the transfer cannot tell them apart. */
      for (final source in <ChunkSource>[
        BytesSource(payload),
        _CountingSource(payload),
      ]) {
        final result = await PackTransfer(
                source: source,
                store: MemoryPartialStore(),
                manifest: manifest)
            .run(state: freshState());
        expect(result.outcome, TransferOutcome.complete);
        expect(result.bytes, payload);
      }
    });

    test('a sideloaded pack still faces the installer', () async {
      /* The transfer produces bytes and installs nothing. `NFR-OFF-01` holds because the
         learning path has no way to fetch, and this file adds none: an SD card is not a
         back door into `InstalledContent`. */
      final result = await PackTransfer(
              source: BytesSource(payload),
              store: MemoryPartialStore(),
              manifest: manifest)
          .run(state: freshState());
      expect(result.bytes, isNotNull);
      // There is no `install` on a transfer, by design: the bytes still have to face
      // ContentLibrary, which verifies the manifest before anything reaches a child.
      expect(PackTransfer(
              source: BytesSource(payload),
              store: MemoryPartialStore(),
              manifest: manifest),
          isNot(isA<ContentLibrary>()));
    });
  });
}

/// A source that remembers how much it was asked for.
class _CountingSource implements ChunkSource {
  _CountingSource(this.bytes);
  final Uint8List bytes;
  int bytesServed = 0;

  @override
  int? get totalBytes => bytes.length;

  @override
  bool get supportsRanges => true;

  @override
  Future<Uint8List> read(int offset, int length) async {
    if (offset >= bytes.length) return Uint8List(0);
    final end = (offset + length).clamp(0, bytes.length);
    bytesServed += end - offset;
    return Uint8List.sublistView(bytes, offset, end);
  }
}
