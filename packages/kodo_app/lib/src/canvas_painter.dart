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
    this.zoom = 1.0,
    this.pan = Offset.zero,
  });

  final VectorCanvas canvas;
  final bool showTurtle;

  /// `FR-M4-02`. How much the child has magnified the drawing.
  ///
  /// It goes into the transform the figure is *painted* through, never onto a picture
  /// already painted. That is the difference between a vector rendering that is zoomable
  /// and a bitmap that is scalable: at ×4 a child looking for the gap in their square has
  /// to see a line, not four pixels of one.
  final double zoom;

  /// Where the magnified drawing has been dragged to, in canvas units.
  final Offset pan;

  /// During slow and step execution the segment about to be drawn is ghosted
  /// (`FR-M4-08`). The render budget turns it off on a small device (`FR-M4-09`).
  final bool highlightLastSegment;

  @override
  void paint(Canvas target, Size size) {
    final fit = (size.width / canvas.width)
        .clamp(0.0, size.height / canvas.height)
        .toDouble();
    target.save();

    /* The paper is painted at the fitted size and the drawing on top of it at the zoomed
       one, so magnifying the figure does not magnify the sheet it is on. Clipped, because
       a zoomed drawing runs off the edge of the paper and a line crossing the frame reads
       as a bug in the child's program rather than as the edge of a window. */
    target.drawRect(
      Rect.fromLTWH(0, 0, canvas.width * fit, canvas.height * fit),
      Paint()..color = Color(0xFF000000 | canvas.canvasBackground),
    );
    target.clipRect(
        Rect.fromLTWH(0, 0, canvas.width * fit, canvas.height * fit));

    /* Zooming about the middle of the paper, not its corner. A child who magnifies a
       figure expects the thing they were looking at to stay where it was. */
    final centre = Offset(canvas.width / 2, canvas.height / 2) * fit;
    target.translate(centre.dx, centre.dy);
    target.scale(zoom);
    target.translate(-centre.dx, -centre.dy);
    target.translate(pan.dx * fit, pan.dy * fit);
    target.scale(fit);

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
      old.showTurtle != showTurtle ||
      old.zoom != zoom ||
      old.pan != pan;
}

/// How far in a child may magnify their drawing, and in what jumps.
///
/// Four steps rather than a continuous range, and they are powers of two, because the
/// button is what a child will actually use and a button needs somewhere to land. ×4 is
/// where a 400-unit canvas shows a 100-unit detail full width, which is as close as
/// anything in this curriculum needs looking at.
const List<double> canvasZoomSteps = [1.0, 1.5, 2.0, 3.0, 4.0];

/// The canvas, with the screen-reader description `FR-M16-04` requires.
///
/// `FR-M4-02`: zoomable. Pinching works, and so do two buttons — because pinch is a
/// two-finger gesture and workbook finding `G4-003` is eight-year-olds who could not
/// manage a one-finger one on a five-inch screen. The buttons are the path that is
/// tested; the pinch is offered on top of it.
class TurtleCanvasView extends StatefulWidget {
  const TurtleCanvasView({
    super.key,
    required this.canvas,
    this.locale = 'fr',
    this.showTurtle = true,
    this.zoomable = true,
  });

  final VectorCanvas canvas;
  final String locale;
  final bool showTurtle;

  /// False where the drawing is an illustration rather than the child's own work — a
  /// worked example in the reference, say, which nobody needs to inspect.
  final bool zoomable;

  @override
  State<TurtleCanvasView> createState() => TurtleCanvasViewState();
}

class TurtleCanvasViewState extends State<TurtleCanvasView> {
  int _step = 0;
  Offset _pan = Offset.zero;
  Offset _panAtGestureStart = Offset.zero;
  double _zoomAtGestureStart = 1;

  double get zoom => canvasZoomSteps[_step];
  Offset get pan => _pan;
  bool get canZoomIn => _step < canvasZoomSteps.length - 1;
  bool get canZoomOut => _step > 0;

  void zoomIn() {
    if (!canZoomIn) return;
    setState(() => _step++);
  }

  /// Zooming back out pulls the drawing back to the middle as it goes, so a child who has
  /// dragged a magnified figure off to one side and then zoomed out never ends up looking
  /// at blank paper wondering where their square went.
  void zoomOut() {
    if (!canZoomOut) return;
    setState(() {
      _step--;
      if (_step == 0) _pan = Offset.zero;
    });
  }

  void resetZoom() => setState(() {
        _step = 0;
        _pan = Offset.zero;
      });

  String _label(String fr, String en) => widget.locale == 'en' ? en : fr;

  @override
  Widget build(BuildContext context) {
    final drawing = Semantics(
      label: widget.canvas.describe(locale: widget.locale),
      image: true,
      child: CustomPaint(
        key: const Key('turtle-canvas'),
        painter: TurtleCanvasPainter(
          canvas: widget.canvas,
          showTurtle: widget.showTurtle,
          zoom: zoom,
          pan: _pan,
        ),
        child: const SizedBox.expand(),
      ),
    );

    if (!widget.zoomable) return drawing;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onScaleStart: (_) {
              _zoomAtGestureStart = zoom;
              _panAtGestureStart = _pan;
            },
            onScaleUpdate: (details) {
              final wanted = _zoomAtGestureStart * details.scale;
              var nearest = 0;
              for (var i = 0; i < canvasZoomSteps.length; i++) {
                if ((canvasZoomSteps[i] - wanted).abs() <
                    (canvasZoomSteps[nearest] - wanted).abs()) {
                  nearest = i;
                }
              }
              setState(() {
                _step = nearest;
                _pan = _step == 0
                    ? Offset.zero
                    : _panAtGestureStart +
                        details.focalPointDelta / (zoom * 2);
              });
            },
            child: drawing,
          ),
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomButton(
                id: 'zoom-in',
                icon: Icons.add,
                label: _label('Agrandir le dessin', 'Make the drawing bigger'),
                onPressed: canZoomIn ? zoomIn : null,
              ),
              const SizedBox(height: 4),
              _ZoomButton(
                id: 'zoom-out',
                icon: Icons.remove,
                label: _label('Réduire le dessin', 'Make the drawing smaller'),
                onPressed: canZoomOut ? zoomOut : null,
              ),
              if (_step != 0) ...[
                const SizedBox(height: 4),
                _ZoomButton(
                  id: 'zoom-reset',
                  icon: Icons.fit_screen,
                  label: _label('Voir tout le dessin', 'See the whole drawing'),
                  onPressed: resetZoom,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.id,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String id;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      child: SizedBox(
        // §9.3's floor, not a compact icon button's 40 dp.
        width: 48,
        height: 48,
        child: Material(
          color: Colors.white.withValues(alpha: onPressed == null ? 0.4 : 0.85),
          shape: const CircleBorder(),
          child: InkWell(
            key: Key(id),
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: ExcludeSemantics(
              child: Icon(icon,
                  size: 22,
                  color: onPressed == null ? Colors.black26 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
