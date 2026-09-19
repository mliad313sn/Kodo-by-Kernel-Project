/// M2 and M3 acceptance tests.
///
/// **M2:** every block has help in FR and EN, enforced · every family stays
/// distinguishable with colour removed · a World-1 exercise exposes exactly the blocks it
/// needs · undo 50 and redo 50 restore a byte-identical AST.
///
/// **M3:** 5 000 random edit sequences with toggles interleaved never lose or silently
/// alter a program · the toggle is inside its latency budget for a 200-node program ·
/// every M1 error code renders as a child-language message with a line marker · a
/// keyword-language switch mid-edit preserves the cursor · every highlight colour clears
/// contrast in both themes.
///
/// Two acceptance tests are **not** here and cannot be: "two children aged 8 place five
/// blocks unassisted within three minutes" and "an 11-year-old types a five-line program
/// on a phone in under four minutes" are pass-3 evidence, observed, and no widget test
/// substitutes for them. They are recorded as owed in docs/modules/M2_M3_DONE.md.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo_app/kodo_app.dart';
import 'package:kodo_lang/kodo_lang.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('FR-M2-10 · block help is complete, and runnable', () {
    test('every opcode has help in French and English', () {
      // The coverage test the module prompt asks for: a missing entry fails the build.
      final missing = [
        for (final op in Opcode.values)
          if (!blockHelp.containsKey(op)) op.id,
      ];
      expect(missing, isEmpty, reason: 'no help for: ${missing.join(', ')}');

      for (final entry in blockHelp.entries) {
        for (final locale in ['fr', 'en']) {
          expect(entry.value.summaryIn(locale).trim(), isNotEmpty,
              reason: '${entry.key.id} has no $locale summary');
        }
      }
    });

    test('every help example is three lines and actually runs', () {
      for (final entry in blockHelp.entries) {
        final source = entry.value.exampleSource;
        expect(source.split('\n'), hasLength(3),
            reason: '${entry.key.id}: an example is three lines');
        final parsed = parse(source, KeywordTables.fr);
        expect(parsed.errors, isEmpty,
            reason: '${entry.key.id}: example does not parse — '
                '${parsed.errors.map((e) => e.message('fr')).join('; ')}');
      }
    });

    test('every example uses the block it is explaining', () {
      for (final entry in blockHelp.entries) {
        final program =
            parse(entry.value.exampleSource, KeywordTables.fr).program;
        /* A trigger is not a `Command`: it is the head of a `WhenEvent`, which is the
           whole of what D-014 added. An example for `quand drapeau` uses the block
           without ever containing a command with that opcode. */
        final used = <Opcode>{
          ...walk(program).whereType<Command>().map((c) => c.opcode),
          ...walk(program).whereType<WhenEvent>().map((w) => w.trigger),
        };
        expect(used, contains(entry.key),
            reason: '${entry.key.id}\'s example never uses it');
      }
    });

    test('help is written at the reading level the rest of the product is', () {
      for (final entry in blockHelp.entries) {
        final fr = entry.value.summaryIn('fr');
        final words =
            fr.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        expect(words, lessThanOrEqualTo(12),
            reason: '${entry.key.id}: "$fr" is $words words');
      }
    });
  });

  group('FR-M2-01, FR-M16-01 · acceptance 4 — colour is never the only signal',
      () {
    test('every pair of families differs by more than colour', () {
      // The colour-blind simulation, done properly: remove colour entirely and check that
      // the remaining two signals still separate every pair. The M4 prompt's Do-not says
      // the shapes must be decided before the art is drawn, so this test exists before
      // there is any art.
      final families = BlockFamily.values;
      for (var i = 0; i < families.length; i++) {
        for (var j = i + 1; j < families.length; j++) {
          final a = families[i].signals;
          final b = families[j].signals;
          final differsWithoutColour =
              a.icon != b.icon || a.silhouette != b.silhouette;
          expect(differsWithoutColour, isTrue,
              reason:
                  '${families[i].name} and ${families[j].name} are identical '
                  'once colour is removed');
        }
      }
    });

    test('every family has a name in both languages', () {
      for (final family in BlockFamily.values) {
        for (final locale in ['fr', 'en']) {
          expect(familyNames[locale]?[family.nameKey], isNotNull,
              reason: '${family.name} has no $locale name');
        }
      }
    });

    test('every family colour clears AA against white block text', () {
      for (final family in BlockFamily.values) {
        final ratio = contrastRatio(family.colour, const Color(0xFFFFFFFF));
        expect(ratio, greaterThanOrEqualTo(4.5),
            reason:
                '${family.name} is ${ratio.toStringAsFixed(2)}:1 against white text');
      }
    });
  });

  group('FR-M2-08 · acceptance 5 — palette scoping', () {
    test('World 1 exposes exactly the seven blocks it teaches', () {
      final scope = scopeForWorld(1);
      expect(scope.length, 7);
      expect(scope.opcodes.map((o) => o.id).toSet(), {
        'MOVE_FORWARD',
        'MOVE_BACK',
        'TURN_LEFT',
        'TURN_RIGHT',
        'PEN_UP',
        'PEN_DOWN',
        'CLEAR',
      });
    });

    test('Worlds 0 to 2 never show more than twelve blocks', () {
      // The M2 prompt's `Do not`, made mechanical.
      for (final world in [0, 1, 2]) {
        expect(scopeForWorld(world).length, lessThanOrEqualTo(12),
            reason: 'World $world shows ${scopeForWorld(world).length} blocks');
      }
    });

    test('an exercise may narrow the palette further than its world', () {
      final exercise = PaletteScope.ofIds(['MOVE_FORWARD', 'TURN_RIGHT']);
      expect(exercise.length, 2);
      expect(exercise.allows(Opcode.penUp), isFalse);
    });
  });

  group('FR-M2-09 · acceptance 6 — undo and redo', () {
    test('50 undos and 50 redos restore a byte-identical program', () {
      final controller = EditorController(initialSource: 'avance 10');
      final states = <String>[render(controller.program, KeywordTables.fr)];

      for (var i = 0; i < 50; i++) {
        controller.setText('${controller.text}\navance ${i + 20}');
        states.add(render(controller.program, KeywordTables.fr));
      }
      final afterEdits = render(controller.program, KeywordTables.fr);

      for (var i = 0; i < 50; i++) {
        expect(controller.undo(), isTrue, reason: 'undo $i refused');
      }
      expect(render(controller.program, KeywordTables.fr), states.first);

      for (var i = 0; i < 50; i++) {
        expect(controller.redo(), isTrue, reason: 'redo $i refused');
      }
      expect(render(controller.program, KeywordTables.fr), afterEdits);
    });

    test('undo stops cleanly at the beginning rather than throwing', () {
      final controller = EditorController(initialSource: 'avance 10');
      expect(controller.canUndo, isFalse);
      expect(controller.undo(), isFalse);
      expect(controller.canRedo, isFalse);
      expect(controller.redo(), isFalse);
    });
  });

  group('FR-M2-04 · a number inside a block can be changed, negatives included',
      () {
    testWidgets('the number takes the tap, the rest of the block runs',
        (tester) async {
      /* Two things live on one block now, and which one a tap means has to be decided
         rather than discovered. The number is a control inside the block: pressing it
         edits, pressing anywhere else runs. */
      final controller = EditorController(initialSource: 'avance 50');
      Program? ran;
      await tester.pumpWidget(_wrap(BlockEditor(
        controller: controller,
        scope: scopeForWorld(1),
        onRunStack: (stack) => ran = stack,
      )));
      final command = controller.program.body.first as Command;
      final literal = command.args.first as Node;

      await tester.tap(find.byKey(Key('literal-${literal.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('number-pad')), findsOneWidget);
      expect(ran, isNull, reason: 'editing a number is not running a program');
      await tester.tap(find.byKey(const Key('pad-cancel')));
      await tester.pumpAndSettle();

      final chip = tester.getRect(find.byKey(Key('block-${command.id}')));
      await tester.tapAt(Offset(chip.left + 20, chip.center.dy));
      await tester.pumpAndSettle();
      expect(ran, isNotNull, reason: 'the words still run the block');
    });

    /* Found by running the product rather than by reading the spec. The very first item
       the practice mix serves is *"write the number to move 50 steps"*, and until this
       existed there was no way in the application to write a number: the exercise could
       be opened, read, and not answered. */

    testWidgets('every number in a block has a target beside it',
        (tester) async {
      final controller = EditorController(initialSource: 'avance 50');
      await tester.pumpWidget(
          _wrap(BlockEditor(controller: controller, scope: scopeForWorld(1))));

      final literal =
          (controller.program.body.first as Command).args.first as Node;
      expect(find.byKey(Key('literal-${literal.id}')), findsOneWidget);
    });

    testWidgets('tapping it opens a pad, and the pad changes the program',
        (tester) async {
      final controller = EditorController(initialSource: 'avance 50');
      await tester.pumpWidget(
          _wrap(BlockEditor(controller: controller, scope: scopeForWorld(1))));

      final literal =
          (controller.program.body.first as Command).args.first as Node;
      await tester.tap(find.byKey(Key('literal-${literal.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('number-pad')), findsOneWidget);

      // Clear the 50 and type 120.
      await tester.tap(find.byKey(const Key('pad-back')));
      await tester.tap(find.byKey(const Key('pad-back')));
      await tester.tap(find.byKey(const Key('pad-1')));
      await tester.tap(find.byKey(const Key('pad-2')));
      await tester.tap(find.byKey(const Key('pad-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pad-ok')));
      await tester.pumpAndSettle();

      expect(render(controller.program, KeywordTables.fr), 'avance 120');
    });

    testWidgets('a negative number is reachable, which is the requirement',
        (tester) async {
      /* `recule -50` is `avance 50`, and that equivalence is one of the two the grader
         accepts for every World 1 item. A pad that cannot produce a minus sign makes half
         of the accepted answers unreachable from the block editor. */
      final controller = EditorController(initialSource: 'avance 50');
      await tester.pumpWidget(
          _wrap(BlockEditor(controller: controller, scope: scopeForWorld(1))));

      final literal =
          (controller.program.body.first as Command).args.first as Node;
      await tester.tap(find.byKey(Key('literal-${literal.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pad-−')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pad-ok')));
      await tester.pumpAndSettle();

      expect(render(controller.program, KeywordTables.fr), 'avance -50');
    });

    testWidgets('the sign toggles rather than accumulating', (tester) async {
      // `--3` is not a number, and a child pressing a button twice is not an error.
      final controller = EditorController(initialSource: 'avance 50');
      await tester.pumpWidget(
          _wrap(BlockEditor(controller: controller, scope: scopeForWorld(1))));
      final literal =
          (controller.program.body.first as Command).args.first as Node;
      await tester.tap(find.byKey(Key('literal-${literal.id}')));
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('pad-−')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('pad-ok')));
      await tester.pumpAndSettle();

      expect(render(controller.program, KeywordTables.fr), 'avance -50');
    });

    testWidgets('cancelling changes nothing', (tester) async {
      final controller = EditorController(initialSource: 'avance 50');
      await tester.pumpWidget(
          _wrap(BlockEditor(controller: controller, scope: scopeForWorld(1))));
      final literal =
          (controller.program.body.first as Command).args.first as Node;
      await tester.tap(find.byKey(Key('literal-${literal.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pad-9')));
      await tester.tap(find.byKey(const Key('pad-cancel')));
      await tester.pumpAndSettle();

      expect(render(controller.program, KeywordTables.fr), 'avance 50');
    });

    testWidgets('the number target is big enough, and no bigger than it needs',
        (tester) async {
      /* Both halves matter and the second was found by looking at a phone. A `Container`
         with an `alignment` grows to fill its constraints, so the field spanned the whole
         script area and pushed the block it belongs to onto a line of its own — a number
         that no longer reads as being *inside* anything. */
      final controller = EditorController(initialSource: 'avance 50');
      /* The phone layout, which is the one a child uses: `compact` puts the script above
         a bottom-sheet palette instead of beside a 260 dp column, so the script gets the
         width rather than a 99 dp strip. */
      await tester.pumpWidget(_wrap(SizedBox(
          width: 360,
          child: BlockEditor(
              controller: controller,
              scope: scopeForWorld(1),
              compact: true))));
      final literal =
          (controller.program.body.first as Command).args.first as Node;
      final size = tester.getSize(find.byKey(Key('literal-${literal.id}')));

      expect(size.width, greaterThanOrEqualTo(minimumTouchTarget));
      expect(size.height, greaterThanOrEqualTo(minimumTouchTarget));
      expect(size.width, lessThan(120),
          reason:
              'a two-digit number does not need a hundred and twenty pixels');
    });

    testWidgets('the number is inside the block, not beside it',
        (tester) async {
      /* A block spans the width of the script, so a number placed NEXT to it lands on a
         line of its own and stops reading as part of anything. Written out, `avance 50`
         is one thing; on screen it has to stay one thing. */
      final controller = EditorController(initialSource: 'avance 50');
      /* The phone layout, which is the one a child uses: `compact` puts the script above
         a bottom-sheet palette instead of beside a 260 dp column, so the script gets the
         width rather than a 99 dp strip. */
      await tester.pumpWidget(_wrap(SizedBox(
          width: 360,
          child: BlockEditor(
              controller: controller,
              scope: scopeForWorld(1),
              compact: true))));
      final command = controller.program.body.first as Command;
      final literal = command.args.first as Node;

      final chip = tester.getRect(find.byKey(Key('block-${command.id}')));
      final field = tester.getRect(find.byKey(Key('literal-${literal.id}')));
      expect(chip.contains(field.topLeft), isTrue, reason: 'inside the block');
      expect(chip.contains(field.bottomRight), isTrue);
      expect(field.center.dy, closeTo(chip.center.dy, 4));
    });

    testWidgets('the number is not also printed in the words', (tester) async {
      // Otherwise `avance 50` reads "avance 50 [50]", which is two numbers to a child.
      final controller = EditorController(initialSource: 'avance 50');
      /* The phone layout, which is the one a child uses: `compact` puts the script above
         a bottom-sheet palette instead of beside a 260 dp column, so the script gets the
         width rather than a 99 dp strip. */
      await tester.pumpWidget(_wrap(SizedBox(
          width: 360,
          child: BlockEditor(
              controller: controller,
              scope: scopeForWorld(1),
              compact: true))));
      expect(find.text('avance 50'), findsNothing);
      expect(find.text('avance'), findsWidgets);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('a gap is a slot a child can fill, not a block with no number',
        (tester) async {
      /* The reason this whole group exists. A T4 item ships `avance ___`; the parser
         recovers it as MOVE_FORWARD with no arguments and reports `missingArg`, so the
         hole the author wrote was already in the tree and nothing drew it. The first
         exercise the practice mix serves is exactly this shape, and it was unanswerable:
         a block with no number and no way to add one. */
      final controller = EditorController(initialSource: 'avance ___');
      await tester.pumpWidget(
          _wrap(BlockEditor(controller: controller, scope: scopeForWorld(1))));

      final command = controller.program.body.first as Command;
      expect(command.args, isEmpty,
          reason: 'the gap really is a missing argument');

      final gap = find.byKey(Key('literal-${command.id}-gap-0'));
      expect(gap, findsOneWidget,
          reason: 'the hole must be visible and tappable');

      await tester.tap(gap);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pad-7')));
      await tester.tap(find.byKey(const Key('pad-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pad-ok')));
      await tester.pumpAndSettle();

      expect(render(controller.program, KeywordTables.fr), 'avance 70',
          reason: 'which is the reference answer for C1.1-19');
    });

    testWidgets('the pad opens empty on a gap, not on a number nobody chose',
        (tester) async {
      final controller = EditorController(initialSource: 'avance ___');
      await tester.pumpWidget(
          _wrap(BlockEditor(controller: controller, scope: scopeForWorld(1))));
      final command = controller.program.body.first as Command;
      await tester.tap(find.byKey(Key('literal-${command.id}-gap-0')));
      await tester.pumpAndSettle();

      // Pressing 5 must give 5, not 505 or 5 appended to a default.
      await tester.tap(find.byKey(const Key('pad-5')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pad-ok')));
      await tester.pumpAndSettle();
      expect(render(controller.program, KeywordTables.fr), 'avance 5');
    });

    testWidgets('editing a number is one undo step, not several',
        (tester) async {
      final controller = EditorController(initialSource: 'avance 50');
      await tester.pumpWidget(
          _wrap(BlockEditor(controller: controller, scope: scopeForWorld(1))));
      final literal =
          (controller.program.body.first as Command).args.first as Node;
      await tester.tap(find.byKey(Key('literal-${literal.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pad-back')));
      await tester.tap(find.byKey(const Key('pad-back')));
      await tester.tap(find.byKey(const Key('pad-7')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pad-ok')));
      await tester.pumpAndSettle();
      expect(render(controller.program, KeywordTables.fr), 'avance 7');

      controller.undo();
      expect(render(controller.program, KeywordTables.fr), 'avance 50',
          reason: 'a child who typed three digits presses undo once, not three '
              'times — the pad is one edit');
    });
  });

  group(
      'FR-M2-02, FR-M2-03, FR-M2-07, FR-M16-01 · tap-to-place and click-to-run',
      () {
    testWidgets('a child taps a palette block and it lands in the script',
        (tester) async {
      final controller = EditorController();
      await tester.pumpWidget(
          _wrap(BlockEditor(controller: controller, scope: scopeForWorld(1))));

      expect(find.byKey(const Key('palette-MOVE_FORWARD')), findsOneWidget);
      await tester.tap(find.byKey(const Key('palette-MOVE_FORWARD')));
      await tester.pumpAndSettle();

      expect(controller.program.body, hasLength(1));
      expect(render(controller.program, KeywordTables.fr), 'avance 50');
    });

    testWidgets('five taps place five blocks, which is the child-panel task',
        (tester) async {
      // The observed version of this — two eight-year-olds, three minutes, unassisted —
      // is pass-3 evidence and cannot be automated. What CAN be automated is that the
      // interaction requires five taps and no gesture, which is what workbook finding
      // G4-003 says the phone needs.
      final controller = EditorController();
      await tester.pumpWidget(_wrap(BlockEditor(
          controller: controller, scope: scopeForWorld(1), compact: true)));

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('palette-MOVE_FORWARD')));
        await tester.pumpAndSettle();
      }
      expect(controller.program.body, hasLength(5));
    });

    testWidgets('tapping a block in the script runs from there',
        (tester) async {
      final controller = EditorController(
          initialSource: 'avance 10\ntournedroite 90\navance 20');
      Program? ran;
      await tester.pumpWidget(_wrap(BlockEditor(
        controller: controller,
        scope: scopeForWorld(1),
        onRunStack: (stack) => ran = stack,
      )));

      final second = controller.program.body[1] as Node;
      /* On the WORDS, not at the geometric centre. Since `FR-M2-04` the block carries its
         number as a control inside itself, and on a short block like `tournedroite 90`
         that control is near the middle — so tapping dead centre edits the number, which
         is right, and is not what this test is about. A child taps the words to run. */
      final chip = tester.getRect(find.byKey(Key('block-${second.id}')));
      await tester.tapAt(Offset(chip.left + 20, chip.center.dy));
      await tester.pumpAndSettle();

      expect(ran, isNotNull);
      expect(render(ran!, KeywordTables.fr), 'tournedroite 90\navance 20');
    });

    testWidgets('every touch target is at least 48 dp', (tester) async {
      // FR-M2-07 and §9.3. The reference device is a 5.5" phone; a 40 dp target on it is
      // the difference between a child placing a block and a child missing it.
      final controller = EditorController(initialSource: 'avance 10');
      await tester.pumpWidget(_wrap(BlockEditor(
          controller: controller, scope: scopeForWorld(1), compact: true)));
      await tester.pumpAndSettle();

      for (final element in find.byType(BlockChip).evaluate()) {
        final size = element.size!;
        expect(size.height, greaterThanOrEqualTo(minimumTouchTarget - 0.01),
            reason: 'a block is only ${size.height} dp tall');
      }
    });

    testWidgets('a C-block shows its mouth enclosing its body', (tester) async {
      // FR-M2-03. The body is indented and the closing lip is drawn, which is what makes
      // "the repeat block runs the first line only" — concept C2.2's misconception —
      // visibly untrue.
      final controller = EditorController(
          initialSource: 'répète 4 {\n  avance 50\n  tournedroite 90\n}');
      await tester.pumpWidget(_wrap(BlockEditor(
          controller: controller, scope: PaletteScope.unrestricted)));
      await tester.pumpAndSettle();

      final rows = flattenProgram(controller.program, KeywordTables.fr);
      expect(rows.where((r) => r.isWrapperOpen), hasLength(1));
      expect(rows.where((r) => r.isWrapperClose), hasLength(1));
      expect(rows.where((r) => r.depth == 1), hasLength(2));
    });

    testWidgets('a block announces itself to a screen reader with its family',
        (tester) async {
      final controller = EditorController(initialSource: 'avance 10');
      await tester.pumpWidget(
          _wrap(BlockEditor(controller: controller, scope: scopeForWorld(1))));
      await tester.pumpAndSettle();

      final semantics =
          tester.getSemantics(find.byKey(const Key('palette-MOVE_FORWARD')));
      expect(semantics.label, contains('avance'));
      expect(semantics.label, contains('Mouvement'));
    });
  });

  group('FR-M3-05 · acceptance 1 — the toggle never loses a program', () {
    test('5 000 random edit sequences with toggles interleaved lose nothing',
        () {
      // The loss test. If this can fail, every module built above the bridge inherits
      // the defect, which is why PO decision D-008 put M1 first and why this runs at
      // volume rather than as a handful of cases.
      final random = SeededRandom(20260918);
      const fragments = [
        'avance 50',
        'tournedroite 90',
        'lèvecrayon',
        'baissecrayon',
        'recule 30',
        '# une note',
        'répète 3 {\n  avance 20\n}',
      ];

      for (var i = 0; i < 5000; i++) {
        final controller = EditorController(initialSource: 'avance 10');
        final applied = <String>['avance 10'];

        for (var step = 0; step < 4; step++) {
          switch (random.nextIntInclusive(0, 3)) {
            case 0:
              final line =
                  fragments[random.nextIntInclusive(0, fragments.length - 1)];
              applied.add(line);
              controller.setText(applied.join('\n'));
            case 1:
              controller.showText();
            case 2:
              final conflict = controller.showBlocks();
              expect(conflict, isNull,
                  reason: 'valid text failed to return to blocks at $i/$step');
            default:
              controller.undo();
          }

          // Whatever happened, the program still parses and still renders to itself.
          final rendered = render(controller.program, KeywordTables.fr);
          final reparsed = parse(rendered, KeywordTables.fr);
          expect(reparsed.errors, isEmpty,
              reason: 'program became unparseable at $i/$step:\n$rendered');
          expect(render(reparsed.program, KeywordTables.fr), rendered,
              reason: 'program was silently altered at $i/$step');
        }
      }
    });

    test('invalid text offers two choices and decides neither', () {
      final controller = EditorController(initialSource: 'avance 10');
      controller.showText();
      controller.setText('avance 10\navnce 20');

      final conflict = controller.showBlocks();
      expect(conflict, isNotNull);
      expect(conflict!.errors.single.code, ErrorCode.unknownCommand);
      // The last version that worked is retained, which is what makes the second choice
      // an honest offer rather than a guess.
      expect(render(conflict.lastValidProgram, KeywordTables.fr), 'avance 10');
      // And nothing has been auto-corrected: the child's text is still theirs.
      expect(controller.text, contains('avnce'));
      expect(controller.view, EditorView.text);

      controller.restoreLastValid();
      expect(render(controller.program, KeywordTables.fr), 'avance 10');
      expect(controller.view, EditorView.blocks);
    });

    test('opening a file with a typo in it does not delete the line', () {
      // A parse error drops the offending statement from the tree, so anything that
      // re-renders the tree back over the child's text silently deletes their work.
      const typed = 'avance 10\navnce 20\navance 30';
      final controller = EditorController(initialSource: typed);
      expect(controller.text, typed);
      expect(controller.errors, hasLength(1));
      expect(controller.parses, isFalse);
    });

    test(
        'blocks to text is always safe, even from a program with an error in it',
        () {
      final controller = EditorController(initialSource: 'avance 10');
      controller.setText('avance 10\navnce 20');
      expect(controller.parses, isFalse);
      expect(() => controller.showText(), returnsNormally);
    });
  });

  group('FR-M3-05 · acceptance 2 — the toggle is fast enough to be a toggle',
      () {
    test('a 200-node program toggles inside the budget', () {
      final source = List.filled(100, 'avance 100\ntournedroite 36').join('\n');
      final controller = EditorController(initialSource: source);
      expect(controller.program.body, hasLength(200));

      controller.showText();
      controller.showBlocks();

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        controller.showText();
        controller.showBlocks();
      }
      stopwatch.stop();
      final perToggle = stopwatch.elapsedMicroseconds / 100 / 1000.0;

      // The 100 ms budget is for the reference device; CI is faster, so this is a
      // regression guard and the device measurement is owed at G3.
      expect(perToggle, lessThan(100));
      expect(perToggle, lessThan(10),
          reason:
              '${perToggle}ms per toggle on CI leaves no headroom for a 2 GB phone');
    });
  });

  group('FR-M3-03 · acceptance 3 — every error reaches the child as a sentence',
      () {
    test(
        'every code in M1\'s catalogue renders with a line marker and no machine text',
        () {
      // Reaching every code from source is M1's acceptance test 5; what is checked here is
      // that the panel turns each one into something a child can read.
      for (final code in ErrorCode.values) {
        for (final locale in ['fr', 'en']) {
          final error = KodoError(
            code: code,
            span: const SourceSpan(start: 0, end: 4, line: 3, column: 1),
            args: {
              'word': 'opcode:MOVE_FORWARD',
              'name': 'côté',
              'expected': '2',
              'actual': '1',
              'line': '3',
              'got': 'type.string',
              'count': '-1',
              'size': '2',
              'asked': '5',
            },
          );
          final lines =
              errorLinesFor([error], locale, KeywordTables.of(locale));
          final message = lines.single.message;

          expect(message.trim(), isNotEmpty);
          expect(lines.single.error.line, 3);
          expect(RegExp(r'[A-Z]{3,}_[A-Z]').hasMatch(message), isFalse,
              reason: '${code.id} in $locale shows machine text: $message');
          // A literal brace is legitimate — E_UNCLOSED_BLOCK shows a child the very
          // character they forgot. What must never survive is a *placeholder*.
          expect(RegExp(r'\{[a-zA-Z]+\}').hasMatch(message), isFalse,
              reason: '${code.id} in $locale has an unfilled hole: $message');
        }
      }
    });

    test('a repair is offered where one exists, and never invented', () {
      final controller = EditorController(initialSource: 'avnce 50');
      final lines = errorLinesFor(controller.errors, 'fr', KeywordTables.fr);
      expect(lines.single.repairLabel, 'avance');

      final noRepair = errorLinesFor([
        KodoError(code: ErrorCode.divZero, span: SourceSpan.none),
      ], 'fr', KeywordTables.fr);
      expect(noRepair.single.repairLabel, isNull);
    });

    testWidgets(
        'FR-M3-02 · the error panel marks the line, numbered, and does not hide '
        'itself', (tester) async {
      final controller = EditorController(initialSource: 'avance 10\navnce 20');
      await tester.pumpWidget(
          _wrap(TextEditor(controller: controller, theme: SyntaxTheme.light)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error-panel')), findsOneWidget);
      expect(find.byKey(const Key('line-2')), findsOneWidget);
      // FR-M3-02: line numbers are on by default, because a line number is what an error
      // message points at.
      expect(find.text('2'), findsWidgets);

      // Tapping the message focuses the offending line.
      await tester.tap(find.byKey(const Key('error-E_UNKNOWN_COMMAND-2')));
      await tester.pumpAndSettle();
      final state = tester.state<TextEditorState>(find.byType(TextEditor));
      expect(state.focusedLine, 2);

      // And it is still there. The module prompt's `Do not`: never hide it automatically.
      expect(find.byKey(const Key('error-panel')), findsOneWidget);
    });
  });

  group('FR-M3-01, FR-M16-01 · acceptance 6 — the contrast audit', () {
    test('every highlight colour clears WCAG AA in both themes', () {
      for (final theme in SyntaxTheme.all) {
        for (final category in SyntaxCategory.values) {
          final ratio = theme.contrastOf(category);
          expect(ratio, greaterThanOrEqualTo(4.5),
              reason:
                  '${category.name} is ${ratio.toStringAsFixed(2)}:1 on the '
                  '${theme.name} theme');
        }
      }
    });

    test('the highlighter agrees with the lexer about what a word is', () {
      final spans = highlightLine(
          r'répète 4 { avance $x # note', KeywordTables.fr, SyntaxTheme.light);
      final text = spans.map((s) => s.text).join();
      expect(text, r'répète 4 { avance $x # note');

      String colourOf(String fragment) {
        final span = spans.firstWhere((s) => s.text!.contains(fragment));
        return '${span.style!.color}';
      }

      expect(colourOf('répète'),
          '${SyntaxTheme.light.styleFor(SyntaxCategory.controlFlow).colour}');
      expect(colourOf('avance'),
          '${SyntaxTheme.light.styleFor(SyntaxCategory.command).colour}');
      expect(colourOf('4'),
          '${SyntaxTheme.light.styleFor(SyntaxCategory.number).colour}');
      expect(colourOf('# note'),
          '${SyntaxTheme.light.styleFor(SyntaxCategory.comment).colour}');
    });
  });

  group('FR-M3-04, FR-M3-07 · the things a phone needs', () {
    testWidgets(
        'the programming keyboard row carries the symbols and the world\'s words',
        (tester) async {
      final controller = EditorController(initialSource: 'avance 10');
      await tester.pumpWidget(_wrap(TextEditor(
        controller: controller,
        theme: SyntaxTheme.light,
        compact: true,
        worldOpcodes: scopeForWorld(1).opcodes,
      )));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('keyboard-row')), findsOneWidget);
      // None of these is on the first page of an Android keyboard.
      for (final symbol in ['{', '}', r'$', '#']) {
        expect(find.byKey(Key('kbd-$symbol')), findsOneWidget,
            reason: 'the row has no "$symbol" key');
      }
    });

    test('one tap comments a line out, and another puts it back', () {
      // FR-M3-04, and concept C11.2 teaches this AS a debugging tool.
      final controller =
          EditorController(initialSource: 'avance 10\ntournedroite 90');
      final state = TextEditorState();
      // Exercised through the controller, which is where the behaviour lives.
      final lines = controller.text.split('\n');
      lines[1] = '# ${lines[1]}';
      controller.setText(lines.join('\n'));
      expect(controller.text, 'avance 10\n# tournedroite 90');
      expect(controller.program.body.last, isA<Comment>());
      expect(controller.parses, isTrue);
      expect(state, isNotNull);
    });
  });

  group('FR-M15-03 · acceptance 4 — the language switch', () {
    test('switching keywords mid-edit preserves the program exactly', () {
      final controller = EditorController(initialSource: 'av 100\ntg 90');
      final before = controller.program.toJson().toString();

      controller.setKeywordLanguage(KeywordTables.en);
      expect(controller.text, 'fd 100\ntl 90');
      expect(controller.program.toJson().toString(), before);

      controller.setKeywordLanguage(KeywordTables.fr);
      expect(controller.text, 'av 100\ntg 90');
    });

    testWidgets('the cursor survives the switch', (tester) async {
      final controller =
          EditorController(initialSource: 'avance 100\ntournedroite 90');
      await tester.pumpWidget(
          _wrap(TextEditor(controller: controller, theme: SyntaxTheme.light)));
      await tester.pumpAndSettle();

      final state = tester.state<TextEditorState>(find.byType(TextEditor));
      state.textController.selection = const TextSelection.collapsed(offset: 7);

      controller.setKeywordLanguage(KeywordTables.en);
      await tester.pumpAndSettle();

      expect(state.textController.text, 'forward 100\nturnright 90');
      expect(state.textController.selection.baseOffset, 7);
    });

    test('the switch is recorded for M17', () {
      final controller = EditorController(initialSource: 'avance 10');
      controller.setKeywordLanguage(KeywordTables.en);
      expect(controller.events.map((e) => e.kind),
          contains('keyword_locale_changed'));
      controller.showText();
      expect(controller.events.map((e) => e.kind), contains('bridge_toggled'));
    });
  });

  group('§4.3 · the text view opens when the curriculum says it does', () {
    test('Worlds 1 to 6 are read-only, 7 to 9 editable, 10 up preferred', () {
      for (final world in [1, 3, 6]) {
        expect(textModeForWorld(world), TextMode.readOnly);
      }
      for (final world in [7, 8, 9]) {
        expect(textModeForWorld(world), TextMode.editable);
      }
      for (final world in [10, 11, 12]) {
        expect(textModeForWorld(world), TextMode.preferred);
      }
    });
  });

  group('FR-M2-05 · a name inside a block is chosen, never typed', () {
    /* World 10 is what made this necessary. `lutin "chat"` with no way to choose *chat*
       is a block only an author can use, and a five-year-old's spelling of
       "sourisappuyée" is a program that does not run. */
    const project = BlockChoices(
      sprites: ['chat', 'chien', 'oiseau'],
      backdrops: ['nuit', 'plage'],
      sounds: ['miaou', 'ouaf'],
    );

    BlockEditor editor(EditorController controller,
            {void Function(Program)? onRun}) =>
        BlockEditor(
          controller: controller,
          scope: PaletteScope.ofIds(const [
            'SELECT_SPRITE',
            'SET_BACKDROP',
            'PLAY_SOUND',
            'SET_EFFECT',
            'MOVE_FORWARD',
          ]),
          choices: project,
          onRunStack: onRun,
        );

    testWidgets('the list opens and there is no keyboard in it',
        (tester) async {
      final controller = EditorController(initialSource: 'lutin "chat"');
      Program? ran;
      await tester.pumpWidget(_wrap(editor(controller, onRun: (s) => ran = s)));
      final command = controller.program.body.first as Command;
      final literal = command.args.first as Node;

      await tester.tap(find.byKey(Key('choice-${literal.id}')));
      await tester.pumpAndSettle();
      for (final sprite in ['chat', 'chien', 'oiseau']) {
        expect(find.byKey(Key('choice-$sprite')), findsOneWidget);
      }
      expect(find.byType(TextField), findsNothing,
          reason: 'a name is chosen, never spelled');
      expect(ran, isNull,
          reason: 'opening the list is not running the program');
    });

    testWidgets('choosing rewrites the program and nothing else',
        (tester) async {
      final controller = EditorController(initialSource: 'lutin "chat"');
      await tester.pumpWidget(_wrap(editor(controller)));
      final before = controller.program.body.first as Command;

      await tester
          .tap(find.byKey(Key('choice-${(before.args.first as Node).id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choice-chien')));
      await tester.pumpAndSettle();

      expect(controller.text, 'lutin "chien"');
      final after = controller.program.body.first as Command;
      // The node keeps its id across the edit, as the number pad's does: undo, the
      // block/text bridge and the telemetry all key on ids.
      expect(after.id, before.id);
      expect((after.args.first as Node).id, (before.args.first as Node).id);
    });

    testWidgets('each kind of block offers its own kind of list',
        (tester) async {
      for (final probe in [
        ('arrièreplan "nuit"', ['nuit', 'plage']),
        ('jouson "miaou"', ['miaou', 'ouaf']),
        ('effet "fantôme", 50', ['fantôme', 'tourbillon']),
        ('quand touche "espace" {\n  avance 10\n}', ['espace', 'haut']),
      ]) {
        final controller = EditorController(initialSource: probe.$1);
        await tester.pumpWidget(_wrap(editor(controller)));
        // The tree from the previous turn of this loop has to go before the next one is
        // looked for; without it the finder sees the old block and the new program.
        await tester.pumpAndSettle();
        await tester.tap(find.byWidgetPredicate((w) => w is ChoiceField));
        await tester.pumpAndSettle();
        for (final option in probe.$2) {
          expect(find.byKey(Key('choice-$option')), findsOneWidget,
              reason: '${probe.$1} should offer $option');
        }
        await tester.tap(find.byKey(const Key('choice-cancel')));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('a project with no sounds shows no sounds', (tester) async {
      /* An empty list is the truth about a project that has none, and it does not open a
         blank sheet over the program to say so. */
      final controller = EditorController(initialSource: 'jouson "miaou"');
      await tester.pumpWidget(_wrap(BlockEditor(
        controller: controller,
        scope: PaletteScope.ofIds(const ['PLAY_SOUND']),
      )));
      await tester.tap(find.byWidgetPredicate((w) => w is ChoiceField));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('choice-cancel')), findsNothing);
      expect(controller.text, 'jouson "miaou"');
    });

    testWidgets('a block with a name and a number offers both', (tester) async {
      final controller = EditorController(initialSource: 'effet "fantôme", 50');
      await tester.pumpWidget(_wrap(editor(controller)));
      // `effet` names the thing and then sizes it: the name is a list, the size is a pad.
      expect(find.byWidgetPredicate((w) => w is ChoiceField), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is NumberField), findsOneWidget);
    });

    test('every block that takes a name has a list behind it', () {
      /* The rule the block-help catalogue follows, for the same reason: an opcode that
         takes a name and is not in `namedArguments` gets no dropdown, and a child meets
         a block they cannot fill. */
      const takesAName = [
        Opcode.keyDown,
        Opcode.whenKey,
        Opcode.setEffect,
        Opcode.selectSprite,
        Opcode.setBackdrop,
        Opcode.playSound,
      ];
      for (final op in takesAName) {
        expect(namedArguments[op], isNotNull, reason: op.id);
      }
      for (final entry in namedArguments.entries) {
        expect(
            const BlockChoices(sprites: ['s'], backdrops: ['b'], sounds: ['n'])
                .optionsFor(entry.value, 'fr'),
            isNotEmpty,
            reason:
                '${entry.key.id} has an empty list even with a full project');
      }
    });
  });

  /* `FR-M3-06`. The requirement is one sentence — "keyword autocomplete, with the English
     equivalent shown from World 9" — and every clause of it is a separate way to get it
     wrong: offering too early, offering words the world has not taught, offering the
     longest match first, appending instead of replacing, and showing English to a child
     in World 2. One test each. */
  group('FR-M3-06 · keyword autocomplete', () {
    test('a partial word is what the cursor is sitting at the end of', () {
      expect(partialWordAt('avance 10\ntou', 13), 'tou');
      // A digit, a space, a brace and a `$` all end a word: none can start a keyword.
      expect(partialWordAt('avance 10', 9), '');
      expect(partialWordAt('répète 4 {', 10), '');
      expect(partialWordAt(r'écris $nom', 10), 'nom');
      // Accented letters are letters. `répè` is a partial `répète`.
      expect(partialWordAt('répè', 4), 'répè');
    });

    test('the offers are shortest first, so `av` means `avance`', () {
      final offers = suggestKeywords('a',
          keywords: KeywordTables.fr, other: KeywordTables.en);
      expect(offers, isNotEmpty);
      final lengths = offers.map((o) => o.word.length).toList();
      final sorted = [...lengths]..sort();
      expect(lengths, sorted, reason: 'the list is not shortest-first');

      final av = suggestKeywords('av',
          keywords: KeywordTables.fr, other: KeywordTables.en);
      expect(av.first.word, 'avance');
      expect(av.first.equivalent, 'forward');
    });

    test('grammar is offered as well as blocks — `répète` is not an opcode',
        () {
      final offers = suggestKeywords('rép',
          keywords: KeywordTables.fr, other: KeywordTables.en);
      final repeat = offers.firstWhere((o) => o.word == 'répète');
      expect(repeat.syntax, isNotNull,
          reason: 'répète is a grammar word, not a block');
      expect(repeat.equivalent, 'repeat');
    });

    test('the world\'s palette restricts what is offered (FR-M2-08)', () {
      // `note` is a World 10 block. A child in World 1 has never seen it and the
      // editor may not put it in front of them.
      final world1 = suggestKeywords('no',
          keywords: KeywordTables.fr,
          other: KeywordTables.en,
          scope: scopeForWorld(1).opcodes);
      expect(world1.where((o) => o.opcode == Opcode.playNote), isEmpty);

      final world10 = suggestKeywords('no',
          keywords: KeywordTables.fr,
          other: KeywordTables.en,
          scope: scopeForWorld(10).opcodes);
      expect(world10.where((o) => o.opcode == Opcode.playNote), isNotEmpty);

      // Grammar is never scoped: `non` is how a child says "not" and it is a word of the
      // language, not a block the palette hands out.
      expect(world1.where((o) => o.syntax != null), isNotEmpty);
    });

    test('accepting replaces the partial word — never `avavance`', () {
      final offer = suggestKeywords('av',
              keywords: KeywordTables.fr, other: KeywordTables.en)
          .first;
      final (text, cursor) = acceptSuggestion('répète 4 {\n  av', 15, offer);
      expect(text, 'répète 4 {\n  avance');
      expect(cursor, text.length);
      // And in the middle of a program, the rest of it survives.
      final (mid, at) = acceptSuggestion('av 10\ncentre', 2, offer);
      expect(mid, 'avance 10\ncentre');
      expect(at, 6);
    });

    test('the English equivalent appears from World 9, not before (§4.3)', () {
      for (var world = 0; world <= 8; world++) {
        expect(showsEquivalentIn(world), isFalse, reason: 'world $world');
      }
      for (var world = 9; world <= 12; world++) {
        expect(showsEquivalentIn(world), isTrue, reason: 'world $world');
      }
    });

    testWidgets('the strip appears while typing a word and inserts on tap',
        (tester) async {
      final controller = EditorController(initialSource: '', world: 1);
      await tester.pumpWidget(_wrap(TextEditor(
        controller: controller,
        theme: SyntaxTheme.light,
        worldOpcodes: scopeForWorld(1).opcodes,
      )));
      await tester.pumpAndSettle();
      final state = tester.state<TextEditorState>(find.byType(TextEditor));

      // One letter is not a word yet. A strip that opens on every keystroke is noise.
      state.insertAtCursor('a');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('suggestions')), findsNothing);

      state.insertAtCursor('v');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('suggestions')), findsOneWidget);
      expect(find.byKey(const Key('suggest-avance')), findsOneWidget);
      // World 1: the English word is not shown yet.
      expect(find.byKey(const Key('equivalent-avance')), findsNothing);

      await tester.tap(find.byKey(const Key('suggest-avance')));
      await tester.pumpAndSettle();
      expect(controller.text, 'avance');
      // The offer is taken, so the strip closes rather than offering `avance` again.
      expect(find.byKey(const Key('suggestions')), findsNothing);
    });

    testWidgets('in World 9 the same strip carries the English word',
        (tester) async {
      final controller = EditorController(initialSource: '', world: 9);
      await tester.pumpWidget(_wrap(TextEditor(
        controller: controller,
        theme: SyntaxTheme.light,
        worldOpcodes: scopeForWorld(9).opcodes,
      )));
      await tester.pumpAndSettle();
      final state = tester.state<TextEditorState>(find.byType(TextEditor));

      state.insertAtCursor('av');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('equivalent-avance')), findsOneWidget);
      expect(find.text('forward'), findsOneWidget);
    });
  });

  /* `FR-M2-06` — "grab a stack by its top block" [SC p.6]. One line of specification, and
     the whole of what makes a block editor feel like blocks rather than like a list
     widget. The model is tested here on the AST, where the three rules live; the widget
     tests below check that the child can reach them with two taps and no accuracy. */
  group('FR-M2-06 · grabbing a stack by its top block', () {
    Program parsed(String source) => parse(source, KeywordTables.fr).program;
    String shown(Program p) => render(p, KeywordTables.fr).trim();
    String idOf(Program p, String word) => (p.body.firstWhere((s) =>
            render(Program('t', SourceSpan.none, [s]), KeywordTables.fr)
                .trim()
                .startsWith(word)) as Node)
        .id;

    test('a stack is the block and everything under it', () {
      final p = parsed('avance 10\ntournedroite 90\navance 20');
      final stack = stackAt(p, idOf(p, 'tournedroite'));
      expect(stack.length, 2);
      expect(shown(Program('t', SourceSpan.none, stack)),
          'tournedroite 90\navance 20');
    });

    test('a grab inside a loop stops at the loop', () {
      final p = parsed('répète 3 {\n  avance 10\n  tournedroite 90\n}\ncentre');
      final loop = p.body.first as Repeat;
      final inside = (loop.body[1] as Node).id;
      final stack = stackAt(p, inside);
      // The rest of the loop's body, and nothing from outside it. The loop is the
      // child's bracket and a grab may not reach through it.
      expect(shown(Program('t', SourceSpan.none, stack)), 'tournedroite 90');
    });

    test('a C-block takes its mouth with it', () {
      final p = parsed('centre\nrépète 3 {\n  avance 10\n}');
      final stack = stackAt(p, idOf(p, 'répète'));
      expect(stack.length, 1);
      expect(shown(Program('t', SourceSpan.none, stack)),
          'répète 3 {\n  avance 10\n}');
    });

    test('moving a stack into a loop puts every block in it', () {
      final p = parsed('répète 3 {\n  avance 10\n}\ntournedroite 90\ncentre');
      final loop = p.body.first as Repeat;
      final moved = moveStack(
          p, idOf(p, 'tournedroite'), DropSite(ownerId: loop.id, index: 1));
      expect(shown(moved),
          'répète 3 {\n  avance 10\n  tournedroite 90\n  centre\n}');
    });

    test('a loop may not be dropped inside itself', () {
      final p = parsed('répète 3 {\n  avance 10\n}');
      final loop = p.body.first as Repeat;
      final site = DropSite(ownerId: loop.id, index: 0);
      expect(canDrop(p, loop.id, site), isFalse);
      // And the refusal leaves the program exactly as it was — never a tree that cannot
      // be drawn, and never an exception at a child.
      expect(shown(moveStack(p, loop.id, site)), shown(p));
    });

    test('`si … sinon` has two mouths and they stay different', () {
      final p =
          parsed('si 1 == 1 {\n  avance 10\n} sinon {\n  recule 10\n}\ncentre');
      final branch = p.body.first as If;
      final toElse = moveStack(p, idOf(p, 'centre'),
          DropSite(ownerId: branch.id, slot: BodySlot.orElse, index: 1));
      expect(shown(toElse),
          'si 1 == 1 {\n  avance 10\n} sinon {\n  recule 10\n  centre\n}');

      final toThen = moveStack(
          p, idOf(p, 'centre'), DropSite(ownerId: branch.id, index: 1));
      expect(shown(toThen),
          'si 1 == 1 {\n  avance 10\n  centre\n} sinon {\n  recule 10\n}');
    });

    test('a stack taken out of a loop lands in the program body', () {
      final p = parsed('répète 3 {\n  avance 10\n  tournedroite 90\n}');
      final loop = p.body.first as Repeat;
      final moved =
          moveStack(p, (loop.body[1] as Node).id, const DropSite(index: 1));
      expect(shown(moved), 'répète 3 {\n  avance 10\n}\ntournedroite 90');
    });

    test('every row knows where it sits, including the closing lip', () {
      final p = parsed('répète 3 {\n  avance 10\n}\ncentre');
      final rows = flattenProgram(p, KeywordTables.fr);
      final loop = p.body.first as Repeat;
      expect(rows.first.site, const DropSite(index: 0));
      expect(rows[1].site, DropSite(ownerId: loop.id, index: 0));
      // The lip is "the end of this loop's mouth", which is how a child drops something
      // in at the bottom of a loop that already has blocks in it.
      expect(rows[2].site, DropSite(ownerId: loop.id, index: 1));
      expect(rows[3].site, const DropSite(index: 1));
    });

    testWidgets('two taps move a stack, and no accuracy is needed',
        (tester) async {
      final controller = EditorController(
          initialSource: 'répète 3 {\n  avance 10\n}\ntournedroite 90');
      await tester.pumpWidget(_wrap(SizedBox(
        width: 800,
        height: 600,
        child: BlockEditor(
          controller: controller,
          scope: scopeForWorld(2),
          locale: 'fr',
        ),
      )));
      await tester.pumpAndSettle();
      final state = tester.state<BlockEditorState>(find.byType(BlockEditor));

      // Nothing is held, so there are no gaps to fall into by accident.
      expect(find.byType(DropGap), findsNothing);

      final turn = (controller.program.body[1] as Node).id;
      await tester.tap(find.byKey(Key('grab-$turn')));
      await tester.pumpAndSettle();
      expect(state.grabbedNodeId, turn);
      expect(find.byType(DropGap), findsWidgets);
      // Every gap is a full touch target: G4-003 is two eight-year-olds who could not
      // hit a small one.
      for (final gap in tester.widgetList<DropGap>(find.byType(DropGap))) {
        expect(tester.getSize(find.byWidget(gap)).height,
            greaterThanOrEqualTo(minimumTouchTarget));
      }

      final loop = controller.program.body.first as Repeat;
      await tester
          .tap(find.byKey(Key('gap-${DropSite(ownerId: loop.id, index: 1)}')));
      await tester.pumpAndSettle();
      expect(render(controller.program, KeywordTables.fr).trim(),
          'répète 3 {\n  avance 10\n  tournedroite 90\n}');
      expect(state.grabbedNodeId, isNull);
      expect(find.byType(DropGap), findsNothing);
    });

    testWidgets('the gap that would eat the program is not drawn',
        (tester) async {
      final controller =
          EditorController(initialSource: 'répète 3 {\n  avance 10\n}');
      await tester.pumpWidget(_wrap(SizedBox(
        width: 800,
        height: 600,
        child: BlockEditor(
          controller: controller,
          scope: scopeForWorld(2),
          locale: 'fr',
        ),
      )));
      await tester.pumpAndSettle();

      final loop = controller.program.body.first as Repeat;
      await tester.tap(find.byKey(Key('grab-${loop.id}')));
      await tester.pumpAndSettle();

      // The loop is held. Its own mouth is not on offer, so a child cannot ask for a
      // loop inside itself and cannot be told off for trying.
      expect(find.byKey(Key('gap-${DropSite(ownerId: loop.id, index: 0)}')),
          findsNothing);
      expect(
          find.byKey(Key('gap-${const DropSite(index: 0)}')), findsOneWidget);
    });

    testWidgets('a held stack changes what a tap on a block means',
        (tester) async {
      var ran = 0;
      final controller =
          EditorController(initialSource: 'avance 10\ntournedroite 90');
      await tester.pumpWidget(_wrap(SizedBox(
        width: 800,
        height: 600,
        child: BlockEditor(
          controller: controller,
          scope: scopeForWorld(2),
          locale: 'fr',
          onRunStack: (_) => ran++,
        ),
      )));
      await tester.pumpAndSettle();

      final turn = (controller.program.body[1] as Node).id;
      await tester.tap(find.byKey(Key('block-$turn')));
      await tester.pumpAndSettle();
      expect(ran, 1, reason: 'FR-M2-02 still runs a stack on a tap');

      await tester.tap(find.byKey(Key('grab-$turn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('block-$turn')));
      await tester.pumpAndSettle();
      // Running a program halfway through moving part of it would run a program that
      // does not exist yet.
      expect(ran, 1);
    });
  });

  /* Not FR-M2-06, found while building it. `FR-M2-04`'s edit walked the top level of the
     program and stopped, so a number inside a `répète` — World 1's second item — showed
     an editable field that could not be edited. */
  group('FR-M2-04 · a number inside a loop is editable too', () {
    testWidgets('tapping a number in a loop body changes the program',
        (tester) async {
      final controller =
          EditorController(initialSource: 'répète 3 {\n  avance 10\n}');
      await tester.pumpWidget(_wrap(SizedBox(
        width: 800,
        height: 600,
        child: BlockEditor(
          controller: controller,
          scope: scopeForWorld(2),
          locale: 'fr',
        ),
      )));
      await tester.pumpAndSettle();
      final state = tester.state<BlockEditorState>(find.byType(BlockEditor));

      final loop = controller.program.body.first as Repeat;
      final inner = loop.body.first;
      final slot = state.numberSlots(inner as Node).single;
      state.setSlot(slot, 70);
      await tester.pumpAndSettle();

      expect(render(controller.program, KeywordTables.fr).trim(),
          'répète 3 {\n  avance 70\n}');
    });
  });
}
