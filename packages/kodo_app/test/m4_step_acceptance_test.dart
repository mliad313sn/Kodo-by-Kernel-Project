/// `FR-M4-07` — slow and step highlight both the block and the text line.
///
/// The word the requirement turns on is **both**, so most of these tests are about the two
/// highlights agreeing rather than about either one existing. A child watching `répète`
/// light up while the second line of their program lights up too has been shown that the
/// blocks and the words are one program, and has been shown it without being told.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo_app/kodo_app.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  Program parsed(String source) => parse(source, KeywordTables.fr).program;

  group('FR-M4-07 · one cursor, two highlights', () {
    test('every statement knows its line in the text', () {
      const source = 'avance 10\nrépète 3 {\n  tournedroite 90\n}\ncentre';
      final program = parsed(source);
      final lines = statementLines(program, KeywordTables.fr);
      final ids = allStatements(program).cast<Node>().toList();
      expect(lines[ids[0].id], 1);
      expect(lines[ids[1].id], 2);
      expect(lines[ids[2].id], 3);
      expect(lines[ids[3].id], 5);
    });

    test('a program built from blocks knows its lines too', () {
      /* The hard half. A block placed by hand has no text origin at all, so the map is
         recovered through the render/parse round trip rather than by a second layout
         calculation that would drift from the renderer. */
      final program = Program('p', SourceSpan.none, [
        Command('a', SourceSpan.none, Opcode.moveForward,
            [Literal('a0', SourceSpan.none, const NumberValue(10))]),
        Repeat('r', SourceSpan.none,
            Literal('r0', SourceSpan.none, const NumberValue(3)), [
          Command('b', SourceSpan.none, Opcode.turnRight,
              [Literal('b0', SourceSpan.none, const NumberValue(90))]),
        ]),
      ]);
      final lines = statementLines(program, KeywordTables.fr);
      expect(lines['a'], 1);
      expect(lines['r'], 2);
      expect(lines['b'], 3);
    });

    test('the cursor lands on the statement about to happen, not the last one',
        () {
      final program = parsed('avance 10\ntournedroite 90\navance 20');
      final cursor = RunCursor(
          program: program,
          surface: VectorCanvas(),
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);
      final ids = program.body.cast<Node>().map((n) => n.id).toList();

      expect(cursor.nodeId, isNull,
          reason: 'nothing runs before the first step');
      cursor.step();
      expect(cursor.nodeId, ids[0]);
      expect(cursor.line, 1);
      cursor.step();
      expect(cursor.nodeId, ids[1]);
      expect(cursor.line, 2);
      cursor.step();
      expect(cursor.nodeId, ids[2]);
      expect(cursor.line, 3);
      cursor.dispose();
    });

    test('a step draws exactly what a full run draws (FR-M1-05, still)', () {
      final program = parsed('répète 4 {\n  avance 50\n  tournedroite 90\n}');
      final whole = VectorCanvas();
      Interpreter(program, whole).run();

      final stepped = VectorCanvas();
      final cursor = RunCursor(
          program: program,
          surface: stepped,
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);
      var guard = 0;
      while (cursor.step() && guard++ < 1000) {}
      expect(stepped.segmentCount, whole.segmentCount);
      expect(stepped.trace.last.x, closeTo(whole.trace.last.x, 0.001));
      expect(stepped.trace.last.y, closeTo(whole.trace.last.y, 0.001));
      cursor.dispose();
    });

    test('the highlight follows a loop back to its head', () {
      final program = parsed('répète 2 {\n  avance 10\n}');
      final loop = program.body.first as Repeat;
      final inner = (loop.body.first as Node).id;
      final cursor = RunCursor(
          program: program,
          surface: VectorCanvas(),
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);
      final seen = <String?>[];
      var guard = 0;
      while (cursor.step() && guard++ < 100) {
        seen.add(cursor.nodeId);
      }
      // The body runs twice, and both times the child sees the same block light up.
      expect(seen.where((id) => id == inner).length, 2);
      cursor.dispose();
    });

    test('restarting puts the run back to the beginning', () {
      final program = parsed('avance 10\navance 20');
      final cursor = RunCursor(
          program: program,
          surface: VectorCanvas(),
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);
      cursor.step();
      cursor.step();
      final fresh = VectorCanvas();
      cursor.restart(fresh);
      expect(cursor.nodeId, isNull);
      expect(fresh.segmentCount, 0);
      cursor.step();
      expect(cursor.nodeId, (program.body.first as Node).id);
      cursor.dispose();
    });
  });

  group('FR-M4-07 · what the child sees', () {
    testWidgets('the block and the line light up together', (tester) async {
      const source = 'avance 10\nrépète 2 {\n  tournedroite 90\n}';
      final program = parsed(source);
      final cursor = RunCursor(
          program: program,
          surface: VectorCanvas(),
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);
      final controller = EditorController(initialSource: source, world: 8);

      await tester.pumpWidget(_wrap(ListenableBuilder(
        listenable: cursor,
        builder: (context, _) => Column(children: [
          SizedBox(
            height: 300,
            child: BlockEditor(
              controller: controller,
              scope: scopeForWorld(3),
              locale: 'fr',
              highlightedNodeId: cursor.nodeId,
            ),
          ),
          Expanded(
            child: TextEditor(
              controller: controller,
              theme: SyntaxTheme.light,
              highlightedLine: cursor.line,
            ),
          ),
        ]),
      )));
      await tester.pumpAndSettle();

      // Nothing is running, so nothing is lit.
      expect(find.byKey(const Key('running-block')), findsNothing);
      expect(find.byKey(const Key('running-line')), findsNothing);

      cursor.step();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('running-block')), findsOneWidget);
      expect(find.byKey(const Key('running-line')), findsOneWidget);
      expect(cursor.line, 1);

      cursor.step();
      await tester.pumpAndSettle();
      // The loop head, and its line — one cursor read two ways, never two calculations.
      expect(cursor.nodeId, (program.body[1] as Node).id);
      expect(cursor.line, 2);
      expect(find.byKey(const Key('running-block')), findsOneWidget);
      expect(find.byKey(const Key('running-line')), findsOneWidget);

      cursor.dispose();
    });

    testWidgets('a slow run advances by itself and stops at the end',
        (tester) async {
      final program = parsed('avance 10\navance 20\navance 30');
      final cursor = RunCursor(
          program: program,
          surface: VectorCanvas(),
          keywords: KeywordTables.fr,
          speed: RunSpeed.slow);
      addTearDown(cursor.dispose);

      await tester.pumpWidget(_wrap(ListenableBuilder(
        listenable: cursor,
        builder: (context, _) => Text('line ${cursor.line ?? 0}'),
      )));

      cursor.play();
      await tester.pump(const Duration(milliseconds: 130));
      expect(find.text('line 1'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 130));
      expect(find.text('line 2'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 130));
      expect(find.text('line 3'), findsOneWidget);
      // And it lets go of the clock rather than ticking forever on a finished program.
      await tester.pump(const Duration(milliseconds: 260));
      expect(cursor.isRunning, isFalse);
      expect(cursor.isDone, isTrue);
    });
  });

  /* `FR-M4-08` — "ghosted future-path overlay in step mode". One sentence, and the most
     useful one in M4: a child stepping through a square sees, BEFORE they press the
     button, where the next `avance` is going to go. That turns stepping from "watch it
     happen" — barely better than running it — into "predict, then check", which is the
     whole of debugging. */
  group('FR-M4-08 · the ghosted future path', () {
    test('the ghost is the line the next step will draw', () {
      final program = parsed('avance 50\ntournedroite 90\navance 30');
      final canvas = VectorCanvas();
      final cursor = RunCursor(
          program: program,
          surface: canvas,
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);

      final preview = cursor.ghost();
      expect(preview.length, 1,
          reason: 'the first `avance` has not happened yet');
      cursor.step();
      // And what it drew is exactly what was promised — the same interpreter, so the
      // ghost cannot disagree with what actually happens.
      final drawn = canvas.segments.single;
      expect(drawn.x2, closeTo(preview.single.x2, 0.001));
      expect(drawn.y2, closeTo(preview.single.y2, 0.001));
      cursor.dispose();
    });

    test('a step that draws nothing promises nothing', () {
      final program = parsed('avance 50\ntournedroite 90\navance 30');
      final cursor = RunCursor(
          program: program,
          surface: VectorCanvas(),
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);
      cursor.step(); // avance 50
      // The turn is next, and a turn leaves no ink. Ghosting something there would
      // teach a child that `tournedroite` draws.
      expect(cursor.ghost(), isEmpty);
      cursor.step();
      expect(cursor.ghost().length, 1);
      cursor.dispose();
    });

    test('it can look further than one step ahead', () {
      final program = parsed('répète 3 {\n  avance 50\n  tournedroite 120\n}');
      final cursor = RunCursor(
          program: program,
          surface: VectorCanvas(),
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);
      expect(cursor.ghost(lookahead: 12).length, 3,
          reason: 'the whole triangle, before a single step');
      cursor.dispose();
    });

    test('nothing is promised once the program is over', () {
      final program = parsed('avance 50');
      final cursor = RunCursor(
          program: program,
          surface: VectorCanvas(),
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);
      while (cursor.step()) {}
      expect(cursor.ghost(), isEmpty);
      cursor.dispose();
    });

    test(
        'a small device is shown nothing rather than something cheaper (FR-M4-09)',
        () {
      final program = parsed('avance 50');
      final cursor = RunCursor(
          program: program,
          surface: VectorCanvas(budget: const RenderBudget.leger()),
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);
      expect(cursor.ghost(), isEmpty);
      cursor.dispose();
    });

    testWidgets('the canvas paints what it was given, never a guess',
        (tester) async {
      final program = parsed('avance 50\ntournedroite 90\navance 50');
      final canvas = VectorCanvas();
      final cursor = RunCursor(
          program: program,
          surface: canvas,
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);
      addTearDown(cursor.dispose);

      await tester.pumpWidget(_wrap(ListenableBuilder(
        listenable: cursor,
        builder: (context, _) => SizedBox(
          width: 400,
          height: 400,
          child: TurtleCanvasView(canvas: canvas, ghost: cursor.ghost()),
        ),
      )));
      await tester.pumpAndSettle();

      TurtleCanvasPainter painter() => tester
          .widget<CustomPaint>(find.byKey(const Key('turtle-canvas')))
          .painter! as TurtleCanvasPainter;
      expect(painter().ghost.length, 1);

      cursor.step();
      await tester.pumpAndSettle();
      // The turn comes next and draws nothing, so the overlay empties rather than
      // leaving a stale promise on the paper.
      expect(painter().ghost, isEmpty);
    });
  });
}
