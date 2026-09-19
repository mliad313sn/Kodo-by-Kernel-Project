/// Language semantics: FR-M1-03 (types), FR-M1-04 (operators), FR-M1-05 (control flow),
/// FR-M1-06 (procedures and recursion).
///
/// Several of these tests exist because a *misconception* in the concept ledger depends on
/// the language behaving a particular way. Those are marked with the concept id: if one
/// fails, an item in that concept is now teaching something untrue, which is a Severity-2
/// finding under §14.2 and not merely a red test.
library;

import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

Interpreter _run(String source, {List<String> inputs = const []}) {
  final parsed = parse(source, KeywordTables.fr);
  expect(parsed.errors, isEmpty,
      reason: parsed.errors.map((e) => e.message('fr')).join('\n'));
  return runProgram(parsed.program, HeadlessCanvas(), inputs: inputs);
}

List<String> _output(String source, {List<String> inputs = const []}) {
  final parsed = parse(source, KeywordTables.fr);
  expect(parsed.errors, isEmpty,
      reason: parsed.errors.map((e) => e.message('fr')).join('\n'));
  final canvas = HeadlessCanvas();
  runProgram(parsed.program, canvas, inputs: inputs);
  return canvas.output;
}

void main() {
  group('FR-M1-03 types', () {
    test('numbers keep integer and decimal forms', () {
      expect(_output(r'$a = 3' '\n' r'écris $a'), ['3']);
      expect(_output(r'$a = 3.5' '\n' r'écris $a'), ['3.5']);
      expect(_output(r'écris 10 / 4'), ['2.5']);
    });

    test('strings concatenate with +', () {
      expect(_output(r'écris "bon" + "jour"'), ['bonjour']);
    });

    test('lists are 1-indexed, because a child\'s first item is item one', () {
      expect(_output(r'$l = [10, 20, 30]' '\n' r'écris $l[1]'), ['10']);
      expect(_output(r'$l = [10, 20, 30]' '\n' r'écris $l[3]'), ['30']);
    });

    test('a number is never silently true — concept C7.1', () {
      // The misconception is "true/false are just words". A language where `si 1` worked
      // would confirm it.
      final run = _run('si 1 {\n  avance 10\n}');
      expect(run.error!.code, ErrorCode.type);
    });
  });

  group('FR-M1-04 operators', () {
    test('arithmetic follows precedence, not left-to-right — concept C6.3', () {
      expect(_output(r'écris 2 + 3 * 4'), ['14']);
      expect(_output(r'écris (2 + 3) * 4'), ['20']);
      expect(_output(r'écris 2 ^ 3 ^ 2'), ['512']); // right associative
    });

    test('comparison and assignment are different — concept C7.2', () {
      expect(_output(r'$x = 5' '\n' r'écris $x == 5'), ['true']);
      expect(_output(r'$x = 5' '\n' r'$x = 6' '\n' r'écris $x'), ['6']);
    });

    test('or does not mean both — concept C7.5', () {
      expect(_output(r'écris 1 < 2 ou 5 < 2'), ['true']);
      expect(_output(r'écris 1 < 2 et 5 < 2'), ['false']);
      expect(_output(r'écris non 1 < 2'), ['false']);
    });

    test('and / or short-circuit', () {
      // The right side would raise E_UNDEFINED_VAR if it were evaluated.
      expect(_output(r'écris 1 > 2 et $jamais == 1'), ['false']);
      expect(_output(r'écris 1 < 2 ou $jamais == 1'), ['true']);
    });

    test('comparing across types is false, not an error', () {
      expect(_output(r'écris 5 == "5"'), ['false']);
      expect(_output(r'écris 5 != "5"'), ['true']);
    });

    test('negative numbers are values, not errors — concept C1.5', () {
      final canvas = HeadlessCanvas();
      runProgram(parse('avance -10', KeywordTables.fr).program, canvas);
      expect(canvas.segmentCount, 1);
    });
  });

  group('FR-M1-05 control flow', () {
    test('the whole loop body repeats, not just the first line — concept C2.2',
        () {
      expect(_output('répète 3 {\n  écris "a"\n  écris "b"\n}'),
          ['a', 'b', 'a', 'b', 'a', 'b']);
    });

    test('repeat 4 does not have to mean four sides — concept C2.1', () {
      final canvas = HeadlessCanvas();
      runProgram(
          parse('répète 4 {\n  avance 50\n  tournedroite 120\n}',
                  KeywordTables.fr)
              .program,
          canvas);
      expect(canvas.segmentCount,
          4); // four sides drawn, a triangle traced and overdrawn
    });

    test('nested loops multiply — concept C2.3', () {
      expect(_output('répète 3 {\n  répète 2 {\n    écris "x"\n  }\n}'),
          List.filled(6, 'x'));
    });

    test('for counts inclusively and honours its step', () {
      expect(_output(r'pour $i = 1 à 5 {' '\n' r'  écris $i' '\n}'),
          ['1', '2', '3', '4', '5']);
      expect(_output(r'pour $i = 1 à 10 pas 3 {' '\n' r'  écris $i' '\n}'),
          ['1', '4', '7', '10']);
      expect(_output(r'pour $i = 3 à 1 pas -1 {' '\n' r'  écris $i' '\n}'),
          ['3', '2', '1']);
    });

    test('else runs instead of if, not as well as — concept C7.4', () {
      expect(_output('si 1 < 2 {\n  écris "oui"\n} sinon {\n  écris "non"\n}'),
          ['oui']);
      expect(_output('si 2 < 1 {\n  écris "oui"\n} sinon {\n  écris "non"\n}'),
          ['non']);
    });

    test('while checks before each pass, unlike if — concept C8.1', () {
      expect(
          _output(r'$i = 0'
              '\n'
              r'tantque $i < 3 {'
              '\n'
              r'  écris $i'
              '\n'
              r'  $i = $i + 1'
              '\n}'),
          ['0', '1', '2']);
    });

    test('break leaves the loop, not the program — concept C8.4', () {
      expect(_output('répète 5 {\n  écris "a"\n  coupure\n}\nécris "après"'),
          ['a', 'après']);
    });

    test('break inside a procedure leaves that procedure\'s loop only', () {
      expect(
          _output(
              'apprends compte {\n  répète 5 {\n    écris "x"\n    coupure\n  }\n}\n'
              'compte\nécris "fin"'),
          ['x', 'fin']);
    });

    test('exit ends the whole program', () {
      expect(_output('écris "a"\nsortie\nécris "b"'), ['a']);
    });

    test('repeat 0 runs nothing and is not an error', () {
      final run = _run('répète 0 {\n  avance 10\n}');
      expect(run.status, RunStatus.finished);
    });
  });

  group('FR-M1-06 procedures', () {
    test('defining a block does not run it — concept C9.1', () {
      expect(_output('apprends salut {\n  écris "coucou"\n}\nécris "avant"'),
          ['avant']);
    });

    test('a parameter carries a value, not its name — concept C9.2', () {
      expect(
          _output(r'apprends double $n {'
              '\n'
              r'  écris $n * 2'
              '\n}'
              '\ndouble 21'),
          ['42']);
    });

    test('return gives a value back, it does not print it — concept C9.3', () {
      expect(
          _output(r'apprends plus $a, $b {'
              '\n'
              r'  retourne $a + $b'
              '\n}'
              '\n'
              r'écris plus 2, 3'),
          ['5']);
    });

    test('a procedure may be called before it is defined', () {
      expect(
          _output('salut\napprends salut {\n  écris "coucou"\n}'), ['coucou']);
    });

    test('recursion works and terminates with a base case', () {
      expect(
          _output(r'apprends compte $n {'
              '\n'
              r'  si $n > 0 {'
              '\n'
              r'    écris $n'
              '\n'
              r'    compte $n - 1'
              '\n  }\n}'
              '\ncompte 3'),
          ['3', '2', '1']);
    });

    test('a parameter is local; the caller\'s variables are untouched', () {
      expect(
          _output(r'$n = 100'
              '\n'
              r'apprends f $n {'
              '\n'
              r'  $n = 5'
              '\n}'
              '\nf 1'
              '\n'
              r'écris $n'),
          ['100']);
    });
  });

  group('surface semantics', () {
    test('jumps never draw, whatever the pen — concept C3.1', () {
      final canvas = HeadlessCanvas();
      runProgram(
          parse('baissecrayon\nva 10, 10\nvax 50\nvay 60\ncentre',
                  KeywordTables.fr)
              .program,
          canvas);
      expect(canvas.segmentCount, 0);
    });

    test('nettoietout erases the drawing and leaves the turtle — concept C3.5',
        () {
      final canvas = HeadlessCanvas();
      runProgram(
          parse('avance 100\ntournedroite 90\nnettoietout', KeywordTables.fr)
              .program,
          canvas);
      expect(canvas.segmentCount, 0);
      expect(canvas.direction, 90);
      expect(canvas.positionY, isNot(200));
    });

    test('initialise puts everything back — concept C3.5', () {
      final canvas = HeadlessCanvas();
      runProgram(
          parse('avance 100\ntournedroite 90\ninitialise', KeywordTables.fr)
              .program,
          canvas);
      expect(canvas.segmentCount, 0);
      expect(canvas.direction, 0);
      expect(canvas.positionX, 200);
      expect(canvas.positionY, 200);
    });

    test(
        'pen up stops the drawing without stopping the movement — concept C1.4',
        () {
      final canvas = HeadlessCanvas();
      runProgram(
          parse('avance 50\nlèvecrayon\navance 50\nbaissecrayon\navance 50',
                  KeywordTables.fr)
              .program,
          canvas);
      expect(canvas.segmentCount, 2);
    });

    test('demande suspends when there is no answer, and resumes when given one',
        () {
      final parsed = parse(
          r'$n = demande "Quel âge ?"' '\n' r'écris $n', KeywordTables.fr);
      final canvas = HeadlessCanvas();
      final interpreter = Interpreter(parsed.program, canvas);
      interpreter.run();
      expect(interpreter.status, RunStatus.awaitingInput);

      interpreter.provideInput('9');
      interpreter.run();
      expect(interpreter.status, RunStatus.finished);
      expect(canvas.output, ['9']);
    });

    test('scripted answers let an asking item be graded headlessly', () {
      expect(_output(r'écris demande "âge ?"', inputs: ['9']), ['9']);
    });
  });

  group('the Python projection (FR-M3-09, PO decision D-005)', () {
    test('renders a child\'s program as Python from the same tree', () {
      final program = parse('''
# mon carré
répète 4 {
  avance 100
  tournedroite 90
}''', KeywordTables.fr).program;
      final python = toPython(program, header: false);
      expect(python, '''
# mon carré
for _ in range(int(4)):
    forward(100)
    right(90)''');
    });

    test('keeps procedures, parameters and returns', () {
      final program = parse(
              r'apprends plus $a, $b {'
              '\n'
              r'  retourne $a + $b'
              '\n}'
              '\n'
              r'écris plus 2, 3',
              KeywordTables.fr)
          .program;
      final python = toPython(program, header: false);
      expect(python, contains('def plus(a, b):'));
      expect(python, contains('return a + b'));
      expect(python, contains('write(plus(2, 3))'));
    });

    test('every opcode has a Python name', () {
      /* The same rule the block-help catalogue follows, and for the same reason: an
         opcode added without a name here renders as its own id in a program a child was
         told they could paste elsewhere. Adding `lutin` for World 10 is exactly the kind
         of change that would have slipped through. */
      final unnamed = <String>[];
      for (final op in Opcode.values) {
        final program = parse(_sampleFor(op) ?? '', KeywordTables.fr);
        if (_sampleFor(op) == null) continue;
        expect(program.errors, isEmpty, reason: '${op.id}: ${_sampleFor(op)}');
        final python = toPython(program.program, header: false);
        if (python.contains(op.id)) unnamed.add(op.id);
      }
      expect(unnamed, isEmpty,
          reason: 'these render as their own id: ${unnamed.join(', ')}');
    });

    test('a program using sprites still renders as runnable Python', () {
      /* turtle has no sprites and no drums, so the projection defines a stub for each
         thing it borrows. A rendering that raises NameError on line three does not keep
         the promise the requirement makes — "your program, that you could paste
         elsewhere". */
      final program = parse(
              'lutin "chat"\ndis "miaou"\ncostumesuivant\ntambour 1, 1',
              KeywordTables.fr)
          .program;
      final python = toPython(program);
      for (final stub in [
        'def select_sprite(name):',
        'def say(text):',
        'def next_costume():',
        'def play_drum(drum, beats):',
      ]) {
        expect(python, contains(stub));
      }
      expect(python, contains('select_sprite("chat")'));
      // And nothing is stubbed that the program never used.
      expect(python, isNot(contains('def set_backdrop')));
    });

    test('an event script becomes a function, not a promise', () {
      final program =
          parse('quand drapeau {\n  avance 50\n}', KeywordTables.fr).program;
      final python = toPython(program, header: false);
      expect(python, contains('def on_flag_script():'));
      expect(python, contains('forward(50)'));
    });
  });
}

/// The smallest program that uses [op], or null when it cannot stand alone.
String? _sampleFor(Opcode op) => switch (op) {
      Opcode.moveForward => 'avance 10',
      Opcode.moveBack => 'recule 10',
      Opcode.turnLeft => 'tournegauche 10',
      Opcode.turnRight => 'tournedroite 10',
      Opcode.setDirection => 'direction 90',
      Opcode.getDirection => r'écris obtenirdirection',
      Opcode.center => 'centre',
      Opcode.go => 'va 10, 10',
      Opcode.goX => 'vax 10',
      Opcode.goY => 'vay 10',
      Opcode.positionX => 'écris positionx',
      Opcode.positionY => 'écris positiony',
      Opcode.penUp => 'lèvecrayon',
      Opcode.penDown => 'baissecrayon',
      Opcode.penWidth => 'largeurcrayon 2',
      Opcode.penColor => 'couleurcrayon 1, 2, 3',
      Opcode.canvasSize => 'taillecanevas 10, 10',
      Opcode.canvasColor => 'couleurcanevas 1, 2, 3',
      Opcode.clear => 'nettoietout',
      Opcode.reset => 'initialise',
      Opcode.show => 'montre',
      Opcode.hide => 'cache',
      Opcode.print => 'écris 1',
      Opcode.fontSize => 'taillepolice 12',
      Opcode.round => 'écris arrondi 1.5',
      Opcode.random => 'écris hasard 1, 6',
      Opcode.mod => 'écris mod 7, 3',
      Opcode.sqrt => 'écris racine 9',
      Opcode.pi => 'écris pi',
      Opcode.sin => 'écris sin 0',
      Opcode.cos => 'écris cos 0',
      Opcode.tan => 'écris tan 0',
      Opcode.arcsin => 'écris arcsin 0',
      Opcode.arccos => 'écris arccos 1',
      Opcode.arctan => 'écris arctan 0',
      Opcode.message => 'message "salut"',
      Opcode.ask => 'écris demande "nom ?"',
      Opcode.toNumber => 'écris nombre "7"',
      Opcode.wait => 'attends 1',
      Opcode.assertion => 'assertion 1 == 1',
      Opcode.whenFlag => 'quand drapeau {\n  avance 10\n}',
      Opcode.whenKey => 'quand touche "a" {\n  avance 10\n}',
      Opcode.whenClicked => 'quand clic {\n  avance 10\n}',
      Opcode.keyDown => r'écris touchepressée "a"',
      Opcode.mouseX => 'écris sourisx',
      Opcode.mouseY => 'écris sourisy',
      Opcode.mouseDown => 'écris sourisappuyée',
      Opcode.touchingEdge => 'écris touchebord',
      Opcode.touchingColour => 'écris touchecouleur 1, 2, 3',
      Opcode.selectSprite => 'lutin "chat"',
      Opcode.nextCostume => 'costumesuivant',
      Opcode.setCostume => 'costume 1',
      Opcode.costumeNumber => 'écris numérocostume',
      Opcode.setBackdrop => 'arrièreplan "nuit"',
      Opcode.setEffect => 'effet "fantôme", 50',
      Opcode.clearEffects => 'effaceeffets',
      Opcode.say => 'dis "salut"',
      Opcode.playSound => 'jouson "miaou"',
      Opcode.playDrum => 'tambour 1, 1',
      Opcode.playNote => 'note 60, 1',
    };
