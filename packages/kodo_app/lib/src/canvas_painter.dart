/// Drawing the canvas on screen (M4's Flutter layer).
///
/// It adds pixels and nothing else. Every coordinate comes from [VectorCanvas], which is
/// M1's turtle model, so the figure a child watches and the figure the grader judges are
/// produced by one implementation — the M4 prompt's `Do not`, made structural.
library;

import 'package:flutter/material.dart';
import 'package:kodo_stage/kodo_stage.dart';

class TurtleCanvasPainter extends CustomPainter {
  TurtleCanvasPainter({
    required this.canvas,
    required this.showTurtle,
    this.highlightLastSegment = false,
  });

  final VectorCanvas canvas;
  final bool showTurtle;

  /// During slow and step execution the segment about to be drawn is ghosted
  /// (`FR-M4-08`). The render budget turns it off on a small device (`FR-M4-09`).
  final bool highlightLastSegment;

  @override
  void paint(Canvas target, Size size) {
    final scale = (size.width / canvas.width)
        .clamp(0.0, size.height / canvas.height)
        .toDouble();
    target.save();
    target.scale(scale);

    target.drawRect(
      Rect.fromLTWH(0, 0, canvas.width, canvas.height),
      Paint()..color = Color(0xFF000000 | canvas.canvasBackground),
    );

    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // visibleSegments, not segments: the budget of FR-M4-09 decides how much is painted,
    // and it may never decide what is graded.
    for (final segment in canvas.visibleSegments) {
      paint
        ..color = Color(0xFF000000 | segment.color)
        ..strokeWidth = segment.width;
      target.drawLine(
        Offset(segment.x1, segment.y1),
        Offset(segment.x2, segment.y2),
        paint,
      );
    }

    for (final text in canvas.texts) {
      final painter = TextPainter(
        text: TextSpan(
          text: text.text,
          style: TextStyle(
            color: Color(0xFF000000 | text.color),
            fontSize: text.size,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(target, Offset(text.x, text.y - text.size));
    }

    if (showTurtle && canvas.visible) {
      _paintTurtle(target);
    }
    target.restore();
  }

  void _paintTurtle(Canvas target) {
    target.save();
    target.translate(canvas.positionX.toDouble(), canvas.positionY.toDouble());
    // Heading 0 points up and grows clockwise, which is the canvas convention of M4 and
    // the one World 1's protractor art is drawn against.
    target.rotate(canvas.direction * 3.1415926535897932 / 180.0);
    final body = Path()
      ..moveTo(0, -12)
      ..lineTo(8, 8)
      ..lineTo(0, 4)
      ..lineTo(-8, 8)
      ..close();
    target.drawPath(body, Paint()..color = const Color(0xFF0B6E5E));
    target.drawPath(
      body,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    target.restore();
  }

  @override
  bool shouldRepaint(TurtleCanvasPainter old) =>
      old.canvas.segmentCount != canvas.segmentCount ||
      old.canvas.positionX != canvas.positionX ||
      old.canvas.positionY != canvas.positionY ||
      old.canvas.direction != canvas.direction ||
      old.showTurtle != showTurtle;
}

/// The canvas, with the screen-reader description `FR-M16-04` requires.
class TurtleCanvasView extends StatelessWidget {
  const TurtleCanvasView({
    super.key,
    required this.canvas,
    this.locale = 'fr',
    this.showTurtle = true,
  });

  final VectorCanvas canvas;
  final String locale;
  final bool showTurtle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: canvas.describe(locale: locale),
      image: true,
      child: CustomPaint(
        key: const Key('turtle-canvas'),
        painter: TurtleCanvasPainter(canvas: canvas, showTurtle: showTurtle),
        child: const SizedBox.expand(),
      ),
    );
  }
}
