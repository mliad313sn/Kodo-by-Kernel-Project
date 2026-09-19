/// The canevas (FR-M4-01, FR-M4-02).
///
/// It **extends** M1's turtle model rather than reimplementing it. That is the whole point:
/// the geometry a child watches and the geometry the grader judges are the same object, so
/// they cannot drift. What M4 adds on top is export, rasterisation and the rendering
/// budget — never a second opinion about where the turtle is.
library;

import 'dart:typed_data';

import 'package:kodo_lang/kodo_lang.dart';

import 'png.dart';
import 'raster.dart';
import 'sensing.dart';
import 'svg.dart' as svg;

/// How much the renderer is allowed to do (FR-M4-09, PO decision D-004).
///
/// *Mode léger* is a rendering budget, not a second code path, and — this is the part that
/// matters — **it may never change a grading result**. Everything it turns off is visual.
class RenderBudget {
  const RenderBudget({
    this.ghostPreview = true,
    this.blockShadows = true,
    this.motion = true,
    this.maxSegmentsDrawn = 10000,
  });

  /// The budget for a device under 3 GB of RAM.
  const RenderBudget.leger()
      : ghostPreview = false,
        blockShadows = false,
        motion = false,
        maxSegmentsDrawn = 4000;

  /// The ghosted future-path overlay of `FR-M4-08`.
  final bool ghostPreview;
  final bool blockShadows;

  /// Reduced motion. Also set by the accessibility preference of `FR-M16-03`, which is why
  /// it is one flag and not two.
  final bool motion;

  final int maxSegmentsDrawn;

  /// Chooses a budget from the device's reported memory.
  static RenderBudget forDevice({required int ramMegabytes}) =>
      ramMegabytes < 3072 ? const RenderBudget.leger() : const RenderBudget();
}

/// The drawing surface, with everything a renderer and a grader need.
///
/// It senses, which it did not until World 8 asked it to. `touchebord` and `touchecouleur`
/// are the turtle against the page and the turtle against its own ink — geometry this
/// class already holds — so answering them needed no stage, only the admission that the
/// question was never about sprites. See `sensing.dart`.
class VectorCanvas extends HeadlessCanvas with TurtleSensing {
  VectorCanvas({
    super.width,
    super.height,
    this.budget = const RenderBudget(),
  });

  final RenderBudget budget;

  /// SVG, ready to write to a file or hand to a share sheet.
  String toSvg({String title = 'KODO', String? description}) =>
      svg.toSvg(this, title: title, description: description ?? describe());

  /// A PNG at [scale] times canvas resolution.
  ///
  /// Two colours, because the canvas is line art; a full-colour encoder is M4's Flutter
  /// layer's job, where `dart:ui` can do it properly. This one exists so that grading
  /// diagnostics and tests have a picture without a graphics stack.
  Uint8List toPng({double scale = 1.0}) =>
      bitmapToPng(rasterise(this, scale: scale));

  /// The occupancy grid the grader compares.
  Bitmap toBitmap({double scale = 1.0}) => rasterise(this, scale: scale);

  /// A stable fingerprint of the pixels. Exact, so never used to decide a verdict on its
  /// own — see [compareRaster] for the comparison that honours the ±2 px tolerance.
  String rasterHash({double scale = 1.0}) => toBitmap(scale: scale).hash();

  /// A sentence a screen reader can read, and the SVG `<desc>` (`FR-M16-04`).
  String describe({String locale = 'fr'}) =>
      svg.describeCanvas(this, locale: locale);

  /// The segments a renderer should actually paint under the current budget.
  ///
  /// When a drawing exceeds the budget the *oldest* segments are dropped, not the newest:
  /// a child watching their program run must keep seeing what it is doing now. The
  /// underlying [segments] list is untouched, so the grader still sees everything.
  Iterable<Segment> get visibleSegments {
    if (segments.length <= budget.maxSegmentsDrawn) return segments;
    return segments.skip(segments.length - budget.maxSegmentsDrawn);
  }

  /// True when the budget is hiding part of the drawing, so the interface can say so
  /// rather than letting a child think their program stopped working.
  bool get isTruncatedByBudget => segments.length > budget.maxSegmentsDrawn;
}

/// The two execution surfaces a project can choose between (FR-M4-01).
enum SurfaceKind {
  /// Turtle geometry, origin top-left, size settable.
  canevas,

  /// Sprite stage, centre origin, backdrops.
  scene,
}
