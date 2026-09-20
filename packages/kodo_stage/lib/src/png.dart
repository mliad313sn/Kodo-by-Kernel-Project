/// PNG export (FR-M4-02), in pure Dart and with no dependency.
///
/// The compressed stream uses zlib's *stored* blocks rather than a real deflate. That is a
/// deliberate trade: a PNG of a child's line drawing is small either way, and a hand-rolled
/// deflate would be a compression bug waiting to corrupt a child's saved artwork. Stored
/// blocks are three lines of framing and cannot be wrong.
///
/// Everything here is byte-deterministic, so an exported PNG is comparable across
/// platforms — which the grader does not need, but the visual-regression tests of M2 do.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'raster.dart';

const int _maxStoredBlock = 65535;

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

int _adler32(List<int> bytes) {
  var a = 1, b = 0;
  for (final byte in bytes) {
    a = (a + byte) % 65521;
    b = (b + a) % 65521;
  }
  return (b << 16) | a;
}

void _u32(BytesBuilder out, int v) => out.add([
      (v >> 24) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 8) & 0xFF,
      v & 0xFF,
    ]);

void _chunk(BytesBuilder out, String type, List<int> data) {
  _u32(out, data.length);
  final body = <int>[...ascii.encode(type), ...data];
  out.add(body);
  _u32(out, _crc32(body));
}

/// Wraps [raw] in a zlib stream, deflated.
///
/// **Why this is written out here.** A KODO drawing is a few thousand dark pixels on four
/// hundred thousand light ones, and stored blocks — which is what this used to emit —
/// charge a child a byte for every one of them: 480 KB for a square, whatever the square
/// looked like. An indexed palette took that to 160 KB. The rest is compression, and there
/// is no compressor in the SDK that a pure-Dart, dependency-free package may call.
///
/// So: LZ77 with a hash chain, then RFC 1951's *fixed* Huffman tables. Fixed rather than
/// dynamic because the win here is repetition, not symbol frequency — a run of identical
/// background pixels is a single length/distance pair either way — and a dynamic table is
/// another few hundred lines with another few hundred ways to be subtly wrong. The output
/// is checked against an independent inflater in the tests, which is the only way to
/// believe a compressor.
///
/// If the deflated form ever comes out larger than the input, the stored form is used
/// instead, so this can never make a file worse.
Uint8List _zlib(Uint8List raw) {
  final deflated = _deflateFixed(raw);
  final stored = _zlibStored(raw);
  return deflated.length < stored.length ? deflated : stored;
}

/// Writes bits least-significant-first, which is how deflate packs a stream.
class _BitWriter {
  final BytesBuilder _out = BytesBuilder();
  int _bits = 0;
  int _count = 0;

  /// [value]'s low [width] bits, LSB first. Used for the extra bits and the block header.
  void write(int value, int width) {
    for (var i = 0; i < width; i++) {
      _bits |= ((value >> i) & 1) << _count;
      if (++_count == 8) {
        _out.addByte(_bits);
        _bits = 0;
        _count = 0;
      }
    }
  }

  /// A Huffman code: its bits run most-significant first, inside an LSB-first stream.
  void writeCode(int code, int width) {
    for (var i = width - 1; i >= 0; i--) {
      write((code >> i) & 1, 1);
    }
  }

  Uint8List finish() {
    if (_count > 0) _out.addByte(_bits);
    return _out.toBytes();
  }
}

/* RFC 1951 §3.2.5. The length and distance ladders, written out because they are data. */
const _lengthBase = [
  3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59,
  67, //
  83, 99, 115, 131, 163, 195, 227, 258
];
const _lengthExtra = [
  0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, //
  5, 5, 5, 0
];
const _distanceBase = [
  1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, //
  769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577
];
const _distanceExtra = [
  0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, //
  11, 11, 12, 12, 13, 13
];

const _windowSize = 32768;
const _maxMatch = 258;
const _minMatch = 3;

/// The literal/length symbol [symbol], in RFC 1951's fixed Huffman table (§3.2.6).
void _writeFixedLiteral(_BitWriter bits, int symbol) {
  if (symbol < 144) {
    bits.writeCode(0x30 + symbol, 8);
  } else if (symbol < 256) {
    bits.writeCode(0x190 + symbol - 144, 9);
  } else if (symbol < 280) {
    bits.writeCode(symbol - 256, 7);
  } else {
    bits.writeCode(0xC0 + symbol - 280, 8);
  }
}

/// A zlib stream holding one fixed-Huffman deflate block.
Uint8List _deflateFixed(Uint8List raw) {
  final bits = _BitWriter()
    ..write(1, 1) // final block
    ..write(1, 2); // fixed Huffman

  /* A hash of three bytes to the most recent position that started with them, and a chain
     back through earlier ones. `_chainLimit` bounds the search: a longer chain finds
     slightly better matches for a lot more time, and this runs on a phone. */
  const chainLimit = 64;
  final head = Int32List(1 << 15)..fillRange(0, 1 << 15, -1);
  final prev = Int32List(raw.length);

  int hash(int at) =>
      ((raw[at] << 10) ^ (raw[at + 1] << 5) ^ raw[at + 2]) & 0x7FFF;

  var at = 0;
  while (at < raw.length) {
    var bestLength = 0;
    var bestDistance = 0;

    if (at + _minMatch <= raw.length) {
      final key = hash(at);
      var candidate = head[key];
      var tries = 0;
      while (candidate >= 0 &&
          at - candidate <= _windowSize &&
          tries++ < chainLimit) {
        var length = 0;
        final limit = (raw.length - at).clamp(0, _maxMatch);
        while (length < limit && raw[candidate + length] == raw[at + length]) {
          length++;
        }
        if (length > bestLength) {
          bestLength = length;
          bestDistance = at - candidate;
          if (length >= _maxMatch) break;
        }
        candidate = prev[candidate];
      }
      prev[at] = head[key];
      head[key] = at;
    }

    if (bestLength >= _minMatch) {
      var code = 0;
      while (code < _lengthBase.length - 1 &&
          _lengthBase[code + 1] <= bestLength) {
        code++;
      }
      _writeFixedLiteral(bits, 257 + code);
      bits.write(bestLength - _lengthBase[code], _lengthExtra[code]);

      var dcode = 0;
      while (dcode < _distanceBase.length - 1 &&
          _distanceBase[dcode + 1] <= bestDistance) {
        dcode++;
      }
      bits.writeCode(dcode, 5);
      bits.write(bestDistance - _distanceBase[dcode], _distanceExtra[dcode]);

      /* Every position inside the match still has to enter the hash table, or the next
         match cannot see back past it. */
      for (var i = 1; i < bestLength; i++) {
        final j = at + i;
        if (j + _minMatch <= raw.length) {
          final key = hash(j);
          prev[j] = head[key];
          head[key] = j;
        }
      }
      at += bestLength;
    } else {
      _writeFixedLiteral(bits, raw[at]);
      at++;
    }
  }

  _writeFixedLiteral(bits, 256); // end of block

  final out = BytesBuilder()
    ..add([0x78, 0x01])
    ..add(bits.finish());
  _u32(out, _adler32(raw));
  return out.toBytes();
}

/// Wraps [raw] in a zlib stream using stored (uncompressed) blocks.
Uint8List _zlibStored(Uint8List raw) {
  final out = BytesBuilder()
    ..add([0x78, 0x01]); // CM=deflate, no preset dict, fastest
  var offset = 0;
  if (raw.isEmpty) {
    out.add([0x01, 0x00, 0x00, 0xFF, 0xFF]);
  }
  while (offset < raw.length) {
    final take = (raw.length - offset).clamp(0, _maxStoredBlock);
    final last = offset + take >= raw.length ? 1 : 0;
    out.add([
      last,
      take & 0xFF,
      (take >> 8) & 0xFF,
      ~take & 0xFF,
      (~take >> 8) & 0xFF
    ]);
    out.add(raw.sublist(offset, offset + take));
    offset += take;
  }
  _u32(out, _adler32(raw));
  return out.toBytes();
}

/// Encodes an RGB image. [pixels] is `width * height * 3` bytes.
Uint8List encodePng(int width, int height, Uint8List pixels) {
  assert(
      pixels.length == width * height * 3, 'pixels must be RGB, 3 bytes each');

  // PNG scanlines each begin with a filter byte; filter 0 is "none", which keeps the
  // encoder honest and the output reproducible.
  final raw = Uint8List(height * (width * 3 + 1));
  for (var y = 0; y < height; y++) {
    final rowStart = y * (width * 3 + 1);
    raw[rowStart] = 0;
    raw.setRange(rowStart + 1, rowStart + 1 + width * 3, pixels, y * width * 3);
  }

  final out = BytesBuilder()
    ..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final header = BytesBuilder();
  _u32(header, width);
  _u32(header, height);
  header.add([8, 2, 0, 0, 0]); // 8-bit, truecolour RGB, no interlace
  _chunk(out, 'IHDR', header.toBytes());
  _chunk(out, 'IDAT', _zlib(raw));
  _chunk(out, 'IEND', const []);
  return out.toBytes();
}

/// Encodes an image whose pixels are indices into [palette] (PNG colour type 3).
///
/// One byte per pixel instead of three, which matters here more than it usually would:
/// the stream is *stored* rather than deflated, so the file is exactly the size of the
/// pixels. A child's drawing exported as truecolour came to 480 KB whatever they drew —
/// on a 2 GB phone, a dozen saved pictures for the sake of a few thousand black ones.
/// The same drawing as a two-entry palette is 160 KB, and a real deflate would take it to
/// a few thousand bytes if one is ever worth writing.
///
/// [palette] holds at most 256 packed `0xRRGGBB` colours.
Uint8List encodeIndexedPng(
    int width, int height, Uint8List indices, List<int> palette) {
  assert(indices.length == width * height, 'one index per pixel');
  assert(palette.isNotEmpty && palette.length <= 256, '1 to 256 colours');

  final raw = Uint8List(height * (width + 1));
  for (var y = 0; y < height; y++) {
    final rowStart = y * (width + 1);
    raw[rowStart] = 0; // filter 0: none, so the output stays reproducible.
    raw.setRange(rowStart + 1, rowStart + 1 + width, indices, y * width);
  }

  final out = BytesBuilder()
    ..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final header = BytesBuilder();
  _u32(header, width);
  _u32(header, height);
  header.add([8, 3, 0, 0, 0]); // 8-bit, indexed colour, no interlace
  _chunk(out, 'IHDR', header.toBytes());
  _chunk(out, 'PLTE', [
    for (final colour in palette) ...[
      (colour >> 16) & 0xFF,
      (colour >> 8) & 0xFF,
      colour & 0xFF,
    ],
  ]);
  _chunk(out, 'IDAT', _zlib(raw));
  _chunk(out, 'IEND', const []);
  return out.toBytes();
}

/// Renders a [Bitmap] as a two-colour PNG. Used for grading diagnostics and for the
/// "here is your figure next to the target" panel of the failure message.
///
/// Indexed, because two colours do not need three bytes each.
Uint8List bitmapToPng(Bitmap bitmap,
    {int ink = 0x000000, int paper = 0xFFFFFF}) {
  final indices = Uint8List(bitmap.width * bitmap.height);
  for (var y = 0; y < bitmap.height; y++) {
    for (var x = 0; x < bitmap.width; x++) {
      indices[y * bitmap.width + x] = bitmap.at(x, y) ? 1 : 0;
    }
  }
  return encodeIndexedPng(bitmap.width, bitmap.height, indices, [paper, ink]);
}
