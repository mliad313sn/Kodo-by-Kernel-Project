/// `FR-M4-02` — vector rendering, zoomable.
///
/// The PNG and SVG halves of the requirement were built and tested with M4; this is the
/// zoom. The point it has to make is that zooming a *vector* rendering is not the same as
/// scaling a picture: at ×4 a child looking for the gap in their square has to see a line,
/// not four pixels of one — so the magnification goes into the transform the figure is
/// painted through, and the test asserts that it is the painter that knows about it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo_app/kodo_app.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';

Widget _wrap(Widget child) => MaterialApp(
    home: Scaffold(
        body: Center(child: SizedBox(width: 400, height: 400, child: child))));

VectorCanvas _square() {
  final canvas = VectorCanvas();
  Interpreter(
          parse('répète 4 {\n  avance 60\n  tournedroite 90\n}',
                  KeywordTables.fr)
              .program,
          canvas)
      .run();
  return canvas;
}

void main() {
  group('FR-M4-02 · the drawing zooms', () {
    testWidgets('two buttons, both big enough for an eight-year-old',
        (tester) async {
      await tester.pumpWidget(_wrap(TurtleCanvasView(canvas: _square())));
      await tester.pumpAndSettle();

      for (final id in ['zoom-in', 'zoom-out']) {
        expect(find.byKey(Key(id)), findsOneWidget);
        final size = tester.getSize(find.byKey(Key(id)));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      // Pinch is a two-finger gesture; G4-003 is children who could not manage a
      // one-finger one. The buttons are the path, not the fallback.
    });

    testWidgets('zooming in magnifies what is painted, not a painted picture',
        (tester) async {
      await tester.pumpWidget(_wrap(TurtleCanvasView(canvas: _square())));
      await tester.pumpAndSettle();
      final state =
          tester.state<TurtleCanvasViewState>(find.byType(TurtleCanvasView));

      TurtleCanvasPainter painter() => tester
          .widget<CustomPaint>(find.byKey(const Key('turtle-canvas')))
          .painter! as TurtleCanvasPainter;

      expect(painter().zoom, 1.0);
      await tester.tap(find.byKey(const Key('zoom-in')));
      await tester.pumpAndSettle();
      expect(state.zoom, greaterThan(1.0));
      // The magnification reached the painter. Had it been a Transform around the
      // CustomPaint, the figure would be a bitmap blown up and this would still read 1.
      expect(painter().zoom, state.zoom);
    });

    testWidgets('the steps stop where they should, at both ends',
        (tester) async {
      await tester.pumpWidget(_wrap(TurtleCanvasView(canvas: _square())));
      await tester.pumpAndSettle();
      final state =
          tester.state<TurtleCanvasViewState>(find.byType(TurtleCanvasView));

      expect(state.canZoomOut, isFalse,
          reason: 'the whole drawing is the floor');
      for (var i = 0; i < canvasZoomSteps.length + 3; i++) {
        state.zoomIn();
      }
      await tester.pumpAndSettle();
      expect(state.zoom, canvasZoomSteps.last);
      expect(state.canZoomIn, isFalse);
    });

    testWidgets(
        'a magnified drawing can be dragged, and coming back out recentres it',
        (tester) async {
      await tester.pumpWidget(_wrap(TurtleCanvasView(canvas: _square())));
      await tester.pumpAndSettle();
      final state =
          tester.state<TurtleCanvasViewState>(find.byType(TurtleCanvasView));

      await tester.tap(find.byKey(const Key('zoom-in')));
      await tester.pumpAndSettle();
      await tester.drag(
          find.byKey(const Key('turtle-canvas')), const Offset(40, 20));
      await tester.pumpAndSettle();
      expect(state.pan, isNot(Offset.zero));

      // Zooming all the way back out pulls it home: a child who dragged a magnified
      // figure off to one side must never end up looking at blank paper.
      while (state.canZoomOut) {
        await tester.tap(find.byKey(const Key('zoom-out')));
        await tester.pumpAndSettle();
      }
      expect(state.pan, Offset.zero);
      expect(state.zoom, 1.0);
    });

    testWidgets('one button puts the whole drawing back', (tester) async {
      await tester.pumpWidget(_wrap(TurtleCanvasView(canvas: _square())));
      await tester.pumpAndSettle();
      final state =
          tester.state<TurtleCanvasViewState>(find.byType(TurtleCanvasView));

      // It is not offered when there is nothing to undo — a button that does nothing is
      // a button a child stops trusting.
      expect(find.byKey(const Key('zoom-reset')), findsNothing);
      await tester.tap(find.byKey(const Key('zoom-in')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('zoom-reset')), findsOneWidget);

      await tester.tap(find.byKey(const Key('zoom-reset')));
      await tester.pumpAndSettle();
      expect(state.zoom, 1.0);
      expect(state.pan, Offset.zero);
      expect(find.byKey(const Key('zoom-reset')), findsNothing);
    });

    testWidgets('an illustration is not something to inspect', (tester) async {
      await tester.pumpWidget(
          _wrap(TurtleCanvasView(canvas: _square(), zoomable: false)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('zoom-in')), findsNothing);
      expect(find.byKey(const Key('turtle-canvas')), findsOneWidget);
    });

    testWidgets('the screen-reader description survives the zoom (FR-M16-04)',
        (tester) async {
      final canvas = _square();
      await tester.pumpWidget(_wrap(TurtleCanvasView(canvas: canvas)));
      await tester.pumpAndSettle();
      expect(
          find.bySemanticsLabel(canvas.describe(locale: 'fr')), findsOneWidget);
      await tester.tap(find.byKey(const Key('zoom-in')));
      await tester.pumpAndSettle();
      // Magnifying a drawing does not change what is drawn, so it may not change what a
      // child who cannot see it is told.
      expect(
          find.bySemanticsLabel(canvas.describe(locale: 'fr')), findsOneWidget);
    });
  });
}
