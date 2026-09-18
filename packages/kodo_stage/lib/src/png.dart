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
  _chunk(out, 'IDAT', _zlibStored(raw));
  _chunk(out, 'IEND', const []);
  return out.toBytes();
}

/// Renders a [Bitmap] as a two-colour PNG. Used for grading diagnostics and for the
/// "here is your figure next to the target" panel of the failure message.
Uint8List bitmapToPng(Bitmap bitmap,
    {int ink = 0x000000, int paper = 0xFFFFFF}) {
  final pixels = Uint8List(bitmap.width * bitmap.height * 3);
  for (var y = 0; y < bitmap.height; y++) {
    for (var x = 0; x < bitmap.width; x++) {
      final colour = bitmap.at(x, y) ? ink : paper;
      final i = (y * bitmap.width + x) * 3;
      pixels[i] = (colour >> 16) & 0xFF;
      pixels[i + 1] = (colour >> 8) & 0xFF;
      pixels[i + 2] = colour & 0xFF;
    }
  }
  return encodePng(bitmap.width, bitmap.height, pixels);
}
