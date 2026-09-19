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

    test('the cursor lands on the statement about to happen, not the last one', () {
      final program = parsed('avance 10\ntournedroite 90\navance 20');
      final cursor = RunCursor(
          program: program,
          surface: VectorCanvas(),
          keywords: KeywordTables.fr,
          speed: RunSpeed.step);
      final ids = program.body.cast<Node>().map((n) => n.id).toList();

      expect(cursor.nodeId, isNull, reason: 'nothing runs before the first step');
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
}
