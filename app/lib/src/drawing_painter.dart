/// The first projection: a [Drawing] painted by Flutter.
///
/// The other one is `drawingToSvg` in `kodo_art`. Same geometry, two renderers — so the
/// asset file on disk and the thing a child sees cannot drift, which is the rule the whole
/// product is built on.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kodo_art/kodo_art.dart';

/// Paints a drawing into whatever box it is given, preserving its aspect.
class DrawingPainter extends CustomPainter {
  const DrawingPainter(this.drawing, {this.highContrast = false, this.turn = 0});

  final Drawing drawing;
  final bool highContrast;

  /// Heading, in degrees clockwise from up. Only the stage turtle uses it; everything else
  /// leaves it at zero.
  final double turn;

  Color _colour(Tint ink) {
    final s = KodoPalette.resolve(ink, highContrast: highContrast);
    return Color.fromARGB(255, s.r, s.g, s.b);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100.0;
    canvas.save();
    canvas.translate(
        (size.width - 100 * scale) / 2, (size.height - 100 * scale) / 2);
    canvas.scale(scale);
    if (turn != 0) {
      canvas
        ..translate(50, 50)
        ..rotate(turn * math.pi / 180)
        ..translate(-50, -50);
    }

    for (final shape in drawing.shapes) {
      final paint = Paint()
        ..color = _colour(shape.ink)
        ..isAntiAlias = true;
      switch (shape) {
        case Circle(:final centre, :final r):
          canvas.drawCircle(Offset(centre.x, centre.y), r, paint);
        case Oval(:final centre, :final rx, :final ry):
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(centre.x, centre.y),
                  width: rx * 2,
                  height: ry * 2),
              paint);
        case Poly(:final points, :final closed):
          final path = Path()..moveTo(points.first.x, points.first.y);
          for (final p in points.skip(1)) {
            path.lineTo(p.x, p.y);
          }
          if (closed) path.close();
          canvas.drawPath(path, paint);
        case Box(:final topLeft, :final bottomRight, :final radius):
          final rect = Rect.fromLTRB(
              topLeft.x, topLeft.y, bottomRight.x, bottomRight.y);
          radius > 0
              ? canvas.drawRRect(
                  RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint)
              : canvas.drawRect(rect, paint);
        case Stroke(:final points, :final width, :final round):
          final path = Path()..moveTo(points.first.x, points.first.y);
          for (final p in points.skip(1)) {
            path.lineTo(p.x, p.y);
          }
          canvas.drawPath(
              path,
              paint
                ..style = PaintingStyle.stroke
                ..strokeWidth = width
                ..strokeCap = round ? StrokeCap.round : StrokeCap.butt
                ..strokeJoin = round ? StrokeJoin.round : StrokeJoin.miter);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DrawingPainter old) =>
      old.drawing.id != drawing.id ||
      old.highContrast != highContrast ||
      old.turn != turn;
}

/// A drawing on screen, with the sentence a screen reader speaks (`FR-M16-04`).
class Art extends StatelessWidget {
  const Art(this.drawing,
      {super.key,
      this.size = 48,
      this.highContrast = false,
      this.turn = 0,
      this.locale = 'fr'});

  final Drawing drawing;
  final double size;
  final bool highContrast;
  final double turn;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: drawing.describeIn(locale),
      image: true,
      child: CustomPaint(
        size: Size(size, size),
        painter: DrawingPainter(drawing,
            highContrast: highContrast, turn: turn),
      ),
    );
  }
}
