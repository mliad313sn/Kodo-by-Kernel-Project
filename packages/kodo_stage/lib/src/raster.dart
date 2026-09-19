/// Turning a vector drawing into pixels, deterministically, and comparing two of them.
///
/// This exists for one reason: `FR-M6-01` grades a child's figure against a target by
/// raster comparison with a **±2 px tolerance**, and a tolerance cannot be expressed as an
/// equal-hash check. So the comparison is done properly — rasterise both, then ask whether
/// every mark in each is within the tolerance of some mark in the other.
///
/// It is deliberately free of anti-aliasing and of floating-point accumulation. A grading
/// verdict must not depend on the rounding behaviour of a particular device's graphics
/// stack, so this rasteriser uses integer Bresenham lines and nothing else.
library;

import 'dart:typed_data';

import 'package:kodo_lang/kodo_lang.dart';

/// A one-bit-per-pixel occupancy grid: was anything drawn here.
class Bitmap {
  Bitmap(this.width, this.height) : bits = Uint8List(width * height);

  final int width;
  final int height;
  final Uint8List bits;

  bool at(int x, int y) =>
      x >= 0 && y >= 0 && x < width && y < height && bits[y * width + x] != 0;

  void set(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    bits[y * width + x] = 1;
  }

  int get inkCount {
    var n = 0;
    for (final b in bits) {
      if (b != 0) n++;
    }
    return n;
  }

  /// Grows every mark by [radius] pixels, in the Chebyshev sense.
  ///
  /// Two passes of a separable dilation rather than one square kernel: same result, and
  /// linear in the radius instead of quadratic, which matters because the grader runs this
  /// on every attempt on a 2 GB phone.
  Bitmap dilate(int radius) {
    if (radius <= 0) return this;
    final horizontal = Bitmap(width, height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (!at(x, y)) continue;
        for (var d = -radius; d <= radius; d++) {
          horizontal.set(x + d, y);
        }
      }
    }
    final out = Bitmap(width, height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (!horizontal.at(x, y)) continue;
        for (var d = -radius; d <= radius; d++) {
          out.set(x, y + d);
        }
      }
    }
    return out;
  }

  /// The share of this bitmap's ink that falls inside [other].
  double coverageBy(Bitmap other) {
    var ink = 0, covered = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (!at(x, y)) continue;
        ink++;
        if (other.at(x, y)) covered++;
      }
    }
    return ink == 0 ? 1.0 : covered / ink;
  }

  /// A stable fingerprint. Used for storage and for spotting an exact match cheaply;
  /// never for deciding a verdict, because equality is not what the tolerance means.
  String hash() {
    // FNV-1a over the packed rows. Small, stable, and identical on every platform.
    var h = 0x811c9dc5;
    for (final b in bits) {
      h ^= b;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return '${width}x$height:${h.toRadixString(16).padLeft(8, '0')}';
  }
}

/// How two drawings compared.
class RasterMatch {
  const RasterMatch({
    required this.matches,
    required this.attemptCoverage,
    required this.targetCoverage,
    required this.attemptInk,
    required this.targetInk,
    this.planeCoverage = const {},
    this.extraColours = const {},
    this.missingColours = const {},
    this.extraWidths = const {},
    this.missingWidths = const {},
    this.backgroundMatches = true,
    this.sizeMatches = true,
  });

  final bool matches;

  /// The share of the child's ink that lands on the target, within tolerance.
  final double attemptCoverage;

  /// The share of the target's ink the child reached, within tolerance.
  final double targetCoverage;

  final int attemptInk;
  final int targetInk;

  /// Which pens the two drawings used, and whether each pen landed where the target put
  /// it.
  ///
  /// Added while authoring World 3, which is *about* colour: `couleurcrayon` was a command
  /// the child could run and the grader could not see, so a square drawn in blue graded
  /// identically to the same square in red. A world that teaches colour cannot be marked
  /// by a monochrome comparison — the drawing really is different, and the grader has to
  /// look at what the canvas shows rather than at a convenient projection of it.
  /// A *pen* is a colour and a width together, because that is what a child sets and what
  /// a stroke carries. Comparing them separately would let a thick red line stand in for a
  /// thin red one and a thick blue one at the same time.
  final Map<(int, double), double> planeCoverage;

  /// Colours the child used that the target does not have, and the other way round.
  final Set<int> extraColours;
  final Set<int> missingColours;

  /// The same, for pen widths. A width difference survives the shape tolerance only
  /// because it is checked here: at grading resolution a six-pixel line dilated by the
  /// positional tolerance swallows a one-pixel line whole, which is how `largeurcrayon`
  /// came to be a command a child could run and a grader could not mark.
  final Set<double> extraWidths;
  final Set<double> missingWidths;

  bool get colourMatches => extraColours.isEmpty && missingColours.isEmpty;
  bool get widthMatches => extraWidths.isEmpty && missingWidths.isEmpty;

  /// Every pen landed where the target put it.
  bool get penMatches => colourMatches && widthMatches &&
      planeCoverage.values.every((c) => c >= 0.98);

  /// Everything about the drawing that is not its geometry: the pens, the paper colour and
  /// the page size.
  ///
  /// This is what the path signature may **not** rescue. A different-but-valid drawing
  /// ORDER is a correct answer (`FR-M6-02`) and the signature exists to let it pass; a
  /// different colour is a different drawing, and letting the signature wave it through is
  /// how World 3 would have shipped with no gradable item in it.
  bool get pageMatches => penMatches && backgroundMatches && sizeMatches;

  /// Whether the two canvases are the same colour, and the same size.
  ///
  /// The second half of the World 3 defect. `couleurcanevas` and `taillecanevas` both
  /// change what a child sees and neither reached the grader: the background was recorded
  /// on the canvas and never read, and the attempt was rasterised into the TARGET's
  /// dimensions, so a wrong canvas size was silently squashed to the right one. A world
  /// whose fourth concept is the canvas cannot be marked by a comparison that ignores it.
  final bool backgroundMatches;
  final bool sizeMatches;

  /// True when the child drew the target and then kept going — a different mistake from
  /// missing part of it, and the diagnostic message should say so.
  bool get drewTooMuch => targetCoverage >= 0.98 && attemptCoverage < 0.98;

  /// True when the child drew part of the target and stopped.
  bool get drewTooLittle => attemptCoverage >= 0.98 && targetCoverage < 0.98;
}

/// Rasterises the ink of [canvas] into a [Bitmap] at canvas resolution.
///
/// [scale] downsamples for speed; the grader's tolerance is expressed in canvas pixels and
/// converted, so a scaled comparison means the same thing as an unscaled one.
Bitmap rasterise(HeadlessCanvas canvas,
    {double scale = 1.0,
    int? width,
    int? height,
    int? onlyColour,
    double? onlyPenWidth}) {
  final w = width ?? (canvas.width * scale).round().clamp(1, 4096);
  final h = height ?? (canvas.height * scale).round().clamp(1, 4096);
  final bitmap = Bitmap(w, h);

  int px(double v) => (v * scale).round();

  for (final s in canvas.segments) {
    /* One colour plane at a time, when asked. The segments keep their order and their
       width; only the filter changes, so a plane is exactly the drawing a child would see
       if every other pen had been lifted. */
    if (onlyColour != null && s.color != onlyColour) continue;
    if (onlyPenWidth != null && s.width != onlyPenWidth) continue;
    _line(bitmap, px(s.x1), px(s.y1), px(s.x2), px(s.y2),
        (s.width * scale).round().clamp(1, 64));
  }
  // A plane is ink only: text has no pen, so it belongs to the whole-drawing comparison.
  if (onlyColour != null || onlyPenWidth != null) return bitmap;
  // Text is ink too. It is marked as a filled box of the right size rather than glyph
  // shapes: the grader must notice that a label is there and roughly how big, and must not
  // depend on which font a device happened to load.
  for (final t in canvas.texts) {
    final boxWidth = px(t.size * 0.6 * t.text.length);
    final boxHeight = px(t.size);
    for (var dy = 0; dy < boxHeight; dy++) {
      for (var dx = 0; dx < boxWidth; dx++) {
        bitmap.set(px(t.x) + dx, px(t.y) - boxHeight + dy);
      }
    }
  }
  return bitmap;
}

/// Integer Bresenham, thickened by a square brush. No anti-aliasing, on purpose.
void _line(Bitmap bitmap, int x0, int y0, int x1, int y1, int thickness) {
  final dx = (x1 - x0).abs();
  final dy = -(y1 - y0).abs();
  final sx = x0 < x1 ? 1 : -1;
  final sy = y0 < y1 ? 1 : -1;
  var err = dx + dy;
  var x = x0, y = y0;
  final half = (thickness - 1) ~/ 2;

  while (true) {
    for (var by = -half; by <= half; by++) {
      for (var bx = -half; bx <= half; bx++) {
        bitmap.set(x + bx, y + by);
      }
    }
    if (x == x1 && y == y1) break;
    final e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      x += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y += sy;
    }
  }
}

/// Compares a child's drawing with a target, with a real pixel tolerance.
///
/// The verdict is symmetric on purpose. A figure that covers the target but adds an extra
/// stroke is wrong, and a figure that is a subset of the target is wrong, and they are
/// wrong in different ways that the failure message has to be able to tell apart
/// (`FR-M6-03` forbids a generic message).
RasterMatch compareRaster(
  HeadlessCanvas attempt,
  HeadlessCanvas target, {
  int tolerancePx = 2,
  double scale = 1.0,
  double requiredCoverage = 0.98,
}) {
  final w = (target.width * scale).round().clamp(1, 4096);
  final h = (target.height * scale).round().clamp(1, 4096);
  final a = rasterise(attempt, scale: scale, width: w, height: h);
  final b = rasterise(target, scale: scale, width: w, height: h);
  final radius = (tolerancePx * scale).round().clamp(0, 64);

  final attemptCoverage = a.coverageBy(b.dilate(radius));
  final targetCoverage = b.coverageBy(a.dilate(radius));

  /* Colour, plane by plane. The overall ink comparison above answers "is it the same
     shape"; this answers "is it the same drawing", and for World 3 those are different
     questions. Each plane is compared with the same tolerance as the whole, so a colour
     does not have to be more accurate than a line. */
  final attemptColours = attempt.segments.map((s) => s.color).toSet();
  final targetColours = target.segments.map((s) => s.color).toSet();
  final attemptWidths = attempt.segments.map((s) => s.width).toSet();
  final targetWidths = target.segments.map((s) => s.width).toSet();
  final targetPens =
      target.segments.map((s) => (s.color, s.width)).toSet();

  final coverage = <(int, double), double>{};
  for (final pen in targetPens) {
    final ap = rasterise(attempt,
        scale: scale, width: w, height: h, onlyColour: pen.$1, onlyPenWidth: pen.$2);
    final bp = rasterise(target,
        scale: scale, width: w, height: h, onlyColour: pen.$1, onlyPenWidth: pen.$2);
    if (bp.inkCount == 0) continue;
    coverage[pen] = bp.coverageBy(ap.dilate(radius));
  }
  final extra = attemptColours.difference(targetColours);
  final missing = targetColours.difference(attemptColours);
  final extraW = attemptWidths.difference(targetWidths);
  final missingW = targetWidths.difference(attemptWidths);
  final penOk = extra.isEmpty && missing.isEmpty &&
      extraW.isEmpty && missingW.isEmpty &&
      coverage.values.every((c) => c >= requiredCoverage);

  final backgroundOk = attempt.canvasBackground == target.canvasBackground;
  final sizeOk = attempt.width == target.width && attempt.height == target.height;

  return RasterMatch(
    matches: attemptCoverage >= requiredCoverage &&
        targetCoverage >= requiredCoverage &&
        penOk && backgroundOk && sizeOk,
    attemptCoverage: attemptCoverage,
    targetCoverage: targetCoverage,
    attemptInk: a.inkCount,
    targetInk: b.inkCount,
    planeCoverage: coverage,
    extraColours: extra,
    missingColours: missing,
    extraWidths: extraW,
    missingWidths: missingW,
    backgroundMatches: backgroundOk,
    sizeMatches: sizeOk,
  );
}
