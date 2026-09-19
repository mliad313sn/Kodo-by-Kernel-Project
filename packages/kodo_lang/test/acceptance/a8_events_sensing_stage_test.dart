/// Acceptance test 8 — events, sensing and a stage (`FR-M21-01` … `FR-M21-05`).
///
/// D-014's claim is that the language can now say what the curriculum teaches. Three of
/// the thirteen worlds were unwritable before this: World 5 is *"green flag; key pressed;
/// click on sprite; two scripts at once"*, World 8 needs *"sensing (touching, key,
/// mouse)"*, and the whole of World 10 is sprites, costumes, sounds and backdrops.
///
/// The hard part is not the opcodes. It is that a program stops being one script and
/// becomes a set of them, without breaking the eleven hundred items written against the
/// old model and without making a stepped run draw something different from a full-speed
/// one.
library;

import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

Program parsed(String source) {
  final result = parse(source, KeywordTables.fr);
  expect(result.errors, isEmpty,
      reason: result.errors.map((e) => e.message('fr')).join('\n'));
  return result.program;
}

HeadlessCanvas run(String source, {RunTrigger trigger = const FlagClicked()}) {
  final canvas = HeadlessCanvas();
  final machine = Interpreter(parsed(source), canvas, trigger: trigger)..run();
  expect(machine.error, isNull, reason: machine.error?.message('fr') ?? '');
  return canvas;
}

void main() {
  curriculumIsExpressibleTests();
  group('FR-M21-01 · a program is a set of scripts', () {
    test('a program with no events still runs exactly as it always did', () {
      // The eleven hundred items already authored depend on this and nothing else.
      final canvas = run('avance 50\ntournedroite 90\navance 50');
      expect(canvas.segments, hasLength(2));
      expect(canvas.positionX, 250);
    });

    test('the green flag runs the flag script and leaves the others alone', () {
      final canvas = run(
        'quand drapeau {\n  avance 50\n}\n'
        'quand touche "espace" {\n  avance 200\n}',
      );
      expect(canvas.segments, hasLength(1));
      expect(canvas.positionY, 150, reason: 'only the flag script ran');
    });

    test('a key press runs that key\'s script and not another key\'s', () {
      final canvas = run(
        'quand touche "espace" {\n  avance 50\n}\n'
        'quand touche "a" {\n  avance 200\n}',
        trigger: const KeyPressed('espace'),
      );
      expect(canvas.segments, hasLength(1));
      expect(canvas.positionY, 150);
    });

    test('a click runs the click script', () {
      final canvas = run(
        'quand clic {\n  avance 40\n}\nquand drapeau {\n  avance 200\n}',
        trigger: const Clicked(),
      );
      expect(canvas.positionY, 160);
    });

    test('statements outside every script are the main script and always run',
        () {
      final canvas = run('avance 30\nquand touche "a" {\n  avance 200\n}');
      expect(canvas.positionY, 170, reason: 'the loose statement ran');
      expect(canvas.segments, hasLength(1));
    });
  });

  group('C5.4 · two scripts at once', () {
    test('two flag scripts interleave rather than run one after the other', () {
      /* The point of the concept, and the reason this could not be faked by running the
         scripts in sequence: a child watching has to SEE them take turns. The proof is
         the order the marks appear in, which sequential execution cannot produce. */
      final canvas = HeadlessCanvas();
      final machine = Interpreter(
        parsed('quand drapeau {\n  écris "A1"\n  écris "A2"\n}\n'
            'quand drapeau {\n  écris "B1"\n  écris "B2"\n}'),
        canvas,
      )..run();

      expect(machine.error, isNull);
      expect(canvas.output, ['A1', 'B1', 'A2', 'B2'],
          reason: 'sequential execution would give A1 A2 B1 B2');
    });

    test('two scripts share their variables, because that is the lesson', () {
      final canvas = HeadlessCanvas();
      Interpreter(
        parsed(r'quand drapeau {'
            '\n'
            r'  $score = 0'
            '\n'
            r'  $score = $score + 1'
            '\n'
            '}\n'
            r'quand drapeau {'
            '\n'
            r'  attends 1'
            '\n'
            r'  $score = $score + 10'
            '\n'
            r'  écris $score'
            '\n'
            '}'),
        canvas,
      ).run();
      expect(canvas.output, ['11'],
          reason: 'one box, two scripts — a per-script table would give 10');
    });

    test('the program is not finished while any script still has work', () {
      final canvas = HeadlessCanvas();
      final machine = Interpreter(
        parsed('quand drapeau {\n  avance 10\n}\n'
            'quand drapeau {\n  répète 20 {\n    avance 1\n  }\n}'),
        canvas,
      )..run();
      expect(machine.status, RunStatus.finished);
      expect(canvas.segments, hasLength(21),
          reason: 'the short script finishing must not end the long one');
    });

    test('sortie ends every script, not only its own', () {
      final canvas = HeadlessCanvas();
      Interpreter(
        parsed('quand drapeau {\n  sortie\n}\n'
            'quand drapeau {\n  répète 50 {\n    avance 1\n  }\n}'),
        canvas,
      ).run();
      expect(canvas.segments.length, lessThan(5),
          reason: 'a child who says stop has stopped the program');
    });

    test('a stepped run draws what a full-speed run draws, with two scripts',
        () {
      // FR-M1-05, which concurrency is the obvious way to break.
      const source = 'quand drapeau {\n  répète 6 {\n    avance 10\n'
          '    tournedroite 60\n  }\n}\n'
          'quand drapeau {\n  répète 4 {\n    recule 8\n'
          '    tournegauche 90\n  }\n}';

      final full = HeadlessCanvas();
      Interpreter(parsed(source), full).run();

      final stepped = HeadlessCanvas();
      final machine = Interpreter(parsed(source), stepped);
      while (machine.step()) {}

      expect(stepped.pathSignature(), full.pathSignature());
    });
  });

  group('FR-M21-01 · a trigger is not a step', () {
    test('a quand inside a loop is refused, in a sentence', () {
      final result = parse(
          'répète 2 {\n  quand drapeau {\n    avance 10\n  }\n}',
          KeywordTables.fr);
      expect(result.errors.map((e) => e.code), contains(ErrorCode.eventNested));
      final message = result.errors.first.message('fr');
      expect(message, isNot(contains('WHEN_')));
      expect(message.toLowerCase(), contains('quand'));
    });

    test('quand with no trigger says which words are triggers', () {
      final result = parse('quand {\n  avance 10\n}', KeywordTables.fr);
      expect(result.errors.map((e) => e.code),
          contains(ErrorCode.expectedTrigger));
      expect(result.errors.first.message('fr'), contains('drapeau'));
    });
  });

  group('FR-M21-02 · one tree, two projections — events included', () {
    test('an event script round-trips through the renderer', () {
      const source = 'quand touche "espace" {\n  avance 50\n}';
      final once = parsed(source);
      final written = render(once, KeywordTables.fr);
      expect(written.trim(), source);
      // And again, to catch a renderer that is only right the first time.
      expect(render(parsed(written), KeywordTables.fr).trim(), source);
    });

    test('the same tree reads in English', () {
      final tree = parsed('quand drapeau {\n  avance 50\n}');
      expect(render(tree, KeywordTables.en).trim(),
          'when flag {\n  forward 50\n}');
    });

    test('a French child and an English child write the same program', () {
      final fr = parsed('quand touche "espace" {\n  avance 50\n}');
      final en = parse('when key "espace" {\n  forward 50\n}', KeywordTables.en)
          .program;
      expect(render(en, KeywordTables.fr).trim(),
          render(fr, KeywordTables.fr).trim());
    });
  });

  group('FR-M21-03, FR-M21-04 · a canvas is not a stage', () {
    test('a sensing block on a plain canvas is refused with a sentence', () {
      final canvas = HeadlessCanvas();
      final machine = Interpreter(
          parsed('si touchepressée "espace" {\n  avance 10\n}'), canvas)
        ..run();
      expect(machine.error?.code, ErrorCode.needsStage);
      final message = machine.error!.message('fr');
      expect(message, isNot(contains('KEY_DOWN')));
      expect(message, isNot(contains('null')));
    });

    test('a costume block on a plain canvas is refused too', () {
      final canvas = HeadlessCanvas();
      final machine = Interpreter(parsed('costumesuivant'), canvas)..run();
      expect(machine.error?.code, ErrorCode.needsStage);
      expect(machine.error!.message('en'), contains('stage'));
    });

    test('every existing Surface implementer still compiles and runs', () {
      // The test of whether the extension was designed or bolted on.
      final canvas = HeadlessCanvas();
      expect(() => Interpreter(parsed('avance 10'), canvas).run(),
          returnsNormally);
    });
  });
}

/// `FR-M21-06` — the gate that would have caught D-014 before it happened.
///
/// The check itself lives in `tools/trace_check.dart` and runs in CI, because it compares
/// two files that belong to different packages. What belongs here is the claim it rests
/// on: every word the concept ledger uses for World 5, 8 and 10 now has a block behind it.
void curriculumIsExpressibleTests() {
  group('FR-M21-06 · the language can say what the curriculum teaches', () {
    test('every trigger, sensor and stage block the ledger names exists', () {
      const required = [
        'WHEN_FLAG', 'WHEN_KEY', 'WHEN_CLICKED', // World 5
        'KEY_DOWN', 'MOUSE_X', 'MOUSE_Y', 'MOUSE_DOWN',
        'TOUCHING_EDGE', 'TOUCHING_COLOUR', // World 8
        'NEXT_COSTUME', 'SET_COSTUME', 'COSTUME_NUMBER', 'SET_BACKDROP',
        'SET_EFFECT', 'CLEAR_EFFECTS', 'PLAY_SOUND', 'PLAY_DRUM',
        'PLAY_NOTE', 'SAY', // World 10
      ];
      for (final id in required) {
        expect(Opcode.byId(id), isNotNull,
            reason:
                '$id is named by the curriculum and missing from the language');
      }
    });

    test('every opcode is written in both shipped languages', () {
      // A block a French child can write and an English child cannot is half a block.
      for (final opcode in Opcode.values) {
        expect(KeywordTables.fr.write(opcode), isNotEmpty, reason: opcode.id);
        expect(KeywordTables.en.write(opcode), isNotEmpty, reason: opcode.id);
      }
    });

    test('every syntax word is written in both shipped languages', () {
      for (final word in SyntaxWord.values) {
        expect(KeywordTables.fr.writeSyntax(word), isNotEmpty,
            reason: word.name);
        expect(KeywordTables.en.writeSyntax(word), isNotEmpty,
            reason: word.name);
      }
    });

    test('a trigger is the only kind of opcode that cannot be a step', () {
      final events =
          Opcode.values.where((o) => o.kind == OpcodeKind.event).toList();
      expect(events, hasLength(3),
          reason: '§5.2 commits World 5 to three triggers');
      for (final e in events) {
        expect(e.family, OpcodeFamily.evenements);
      }
    });
  });
}
