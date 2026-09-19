/// Turning a [Drawing] into pixels (`FR-M9-03`, and the launcher icon).
///
/// **Why this exists.** The art committee drew Tika, and the icon a child taps on their
/// home screen was the Flutter template's logo — byte-identical to it, in every mipmap
/// bucket, with the web icons and the favicon to match. A brand that never reaches the
/// launcher is a brand nobody sees. Android needs PNGs at five sizes, so the character had
/// to become pixels somewhere, and "somewhere" is either a designer's export that nobody
/// can reproduce or forty lines of scanline filling that regenerate from the source of
/// truth. This is the second.
///
/// It is small on purpose and it is not a graphics library: filled circles, ovals, boxes
/// and polygons, and stroked paths with round caps. That is every shape `geometry.dart`
/// has, which is the only contract it owes.
///
/// **Anti-aliased by supersampling** rather than by coverage maths. A 48 dp launcher icon
/// with hard edges looks like 2008, and averaging a 4×4 grid is four lines of code against
/// a page of analytic coverage — on an asset generated once at build time, the slower one
/// is free.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'geometry.dart';
import 'palette.dart';

/// [drawing] as `size × size` RGB pixels, over [background].
///
/// The drawing's own coordinate space is 0–100 in both directions, as `geometry.dart`
/// defines it.
Uint8List drawingToRgb(
  Drawing drawing, {
  required int size,
  int background = 0xFDF7EC,
  bool highContrast = false,
  int supersample = 4,
}) {
  final big = size * supersample;
  final pixels = Uint8List(big * big * 3);
  for (var i = 0; i < big * big; i++) {
    pixels[i * 3] = (background >> 16) & 0xFF;
    pixels[i * 3 + 1] = (background >> 8) & 0xFF;
    pixels[i * 3 + 2] = background & 0xFF;
  }

  final scale = big / 100.0;
  void plot(int x, int y, int colour) {
    if (x < 0 || y < 0 || x >= big || y >= big) return;
    final i = (y * big + x) * 3;
    pixels[i] = (colour >> 16) & 0xFF;
    pixels[i + 1] = (colour >> 8) & 0xFF;
    pixels[i + 2] = colour & 0xFF;
  }

  void fillEllipse(double cx, double cy, double rx, double ry, int colour) {
    if (rx <= 0 || ry <= 0) return;
    final top = ((cy - ry) * scale).floor();
    final bottom = ((cy + ry) * scale).ceil();
    for (var py = top; py <= bottom; py++) {
      final dy = (py + 0.5) / scale - cy;
      final inside = 1 - (dy * dy) / (ry * ry);
      if (inside <= 0) continue;
      final halfWidth = rx * math.sqrt(inside);
      final left = ((cx - halfWidth) * scale).floor();
      final right = ((cx + halfWidth) * scale).ceil();
      for (var px = left; px <= right; px++) {
        plot(px, py, colour);
      }
    }
  }

  void fillPolygon(List<P> points, int colour) {
    if (points.length < 3) return;
    var minY = points.first.y, maxY = points.first.y;
    for (final p in points) {
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
    for (var py = (minY * scale).floor(); py <= (maxY * scale).ceil(); py++) {
      final y = (py + 0.5) / scale;
      /* Crossings, sorted, filled in pairs — the even-odd rule. It is the one fill rule
         that needs no winding bookkeeping, and no drawing in this package is
         self-intersecting. */
      final crossings = <double>[];
      for (var i = 0; i < points.length; i++) {
        final a = points[i];
        final b = points[(i + 1) % points.length];
        if ((a.y <= y && b.y > y) || (b.y <= y && a.y > y)) {
          crossings.add(a.x + (y - a.y) / (b.y - a.y) * (b.x - a.x));
        }
      }
      crossings.sort();
      for (var i = 0; i + 1 < crossings.length; i += 2) {
        final left = (crossings[i] * scale).floor();
        final right = (crossings[i + 1] * scale).ceil();
        for (var px = left; px <= right; px++) {
          plot(px, py, colour);
        }
      }
    }
  }

  void strokePath(List<P> points, double width, int colour, bool round) {
    final radius = width / 2;
    for (var i = 0; i + 1 < points.length; i++) {
      final a = points[i];
      final b = points[i + 1];
      final steps =
          (math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2)) * scale)
                  .ceil() +
              1;
      for (var s = 0; s <= steps; s++) {
        final t = s / steps;
        fillEllipse(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, radius,
            radius, colour);
      }
    }
    if (round && points.isNotEmpty) {
      fillEllipse(points.first.x, points.first.y, radius, radius, colour);
      fillEllipse(points.last.x, points.last.y, radius, radius, colour);
    }
  }

  for (final shape in drawing.shapes) {
    final swatch = KodoPalette.resolve(shape.ink, highContrast: highContrast);
    final colour = (swatch.r << 16) | (swatch.g << 8) | swatch.b;
    switch (shape) {
      case Circle(:final centre, :final r):
        fillEllipse(centre.x, centre.y, r, r, colour);
      case Oval(:final centre, :final rx, :final ry):
        fillEllipse(centre.x, centre.y, rx, ry, colour);
      case Poly(:final points, :final closed):
        if (closed) {
          fillPolygon(points, colour);
        } else {
          strokePath(points, 2, colour, true);
        }
      case Box(:final topLeft, :final bottomRight):
        fillPolygon([
          topLeft,
          P(bottomRight.x, topLeft.y),
          bottomRight,
          P(topLeft.x, bottomRight.y),
        ], colour);
      case Stroke(:final points, :final width, :final round):
        strokePath(points, width, colour, round);
    }
  }

  if (supersample == 1) return pixels;

  // Average each supersample × supersample block down into one pixel.
  final out = Uint8List(size * size * 3);
  final samples = supersample * supersample;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      var r = 0, g = 0, b = 0;
      for (var sy = 0; sy < supersample; sy++) {
        for (var sx = 0; sx < supersample; sx++) {
          final i = ((y * supersample + sy) * big + x * supersample + sx) * 3;
          r += pixels[i];
          g += pixels[i + 1];
          b += pixels[i + 2];
        }
      }
      final o = (y * size + x) * 3;
      out[o] = (r / samples).round();
      out[o + 1] = (g / samples).round();
      out[o + 2] = (b / samples).round();
    }
  }
  return out;
}
