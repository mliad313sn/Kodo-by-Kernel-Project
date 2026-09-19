// Authors World 8 — "Tant que" — and writes it out as a content pack.
//
//     dart tool/author_world8.dart
//
// World 2 gave the child a loop that counts: `répète 4` does four turns and stops. World 8
// gives them a loop that *watches*, and the four misconceptions in the ledger are four
// ways of not believing that:
//
//   C8.1  "while and if behave the same"
//   C8.2  "a loop always ends by itself"
//   C8.3  "touching is checked only once"
//   C8.4  "break ends the whole program"
//
// The first and third are the same confusion seen twice: that a test is asked once, at the
// top, and the answer is then kept. `si` really does work that way, which is why a child
// who has just finished World 7 arrives holding it.
//
// This world has something no other world has: **a wrong answer that does not finish.** A
// `tantque` whose test never turns false runs until the interpreter's ten-thousand-segment
// guard stops it, and the child is told the program stopped rather than shown a wrong
// picture. That is the single best item C8.2 could have, and it is authored as one: the
// runaway loop is the broken program, and `programFailed` is the verdict it earns.

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';

import 'authoring.dart';

const conceptGraph = <String, List<String>>{
  'C8.1': ['C7.3'],
  'C8.2': ['C8.1'],
  'C8.3': ['C8.1'],
  'C8.4': ['C8.2'],
};

/// §6.3's commitment, copied from `spec/concepts.json` and checked against it by
/// `publishWorld`.
const committed = <String, int>{
  'C8.1': 24,
  'C8.2': 22,
  'C8.3': 22,
  'C8.4': 18,
};

const palette = [
  'MOVE_FORWARD',
  'MOVE_BACK',
  'TURN_LEFT',
  'TURN_RIGHT',
  'SET_DIRECTION',
  'GO',
  'CENTER',
  'PEN_UP',
  'PEN_DOWN',
  'PEN_COLOR',
  'CLEAR',
  'REPEAT',
  'WHILE',
  'PRINT',
  'RANDOM',
  'ROUND',
  'MOD',
  'IF',
  'ELSE',
  'AND',
  'OR',
  'NOT',
  'TRUE',
  'FALSE',
  'BREAK',
  'KEY_DOWN',
  'TOUCHING_EDGE',
  'TOUCHING_COLOUR',
  'MOUSE_X',
  'MOUSE_Y',
  'MOUSE_DOWN',
];

/// A closed figure, for the loop bodies.
String figure(int sides, int side, int turn) =>
    'répète $sides {\n  avance $side\n  tournedroite $turn\n}';

/// `tantque <test> { <body> }`.
String whileDo(String test, String body) =>
    'tantque $test {\n${body.split('\n').map((l) => '  $l').join('\n')}\n}';

/// `si <test> { <body> }`.
String ifThen(String test, String body) =>
    'si $test {\n${body.split('\n').map((l) => '  $l').join('\n')}\n}';

/// The counted loop every C8.1 and C8.2 item is built from: fill a box, draw one side,
/// step the box.
String counted(int start, String test, String step, int side, int turn) =>
    '\$i = $start\n${whileDo('\$i $test', 'avance $side\ntournedroite $turn\n\$i = \$i $step')}';

// ═══════════════════════════════════════════════════════════════════════════════════════
// C8.1 — Tant que.
// Misconception: "while and if behave the same".
//
// They look the same and they read almost the same, and on the first pass they *do* the
// same: both check a test and both run the body when it holds. The difference is what
// happens next, and it is a difference a canvas shows plainly — one side of a square
// against four. So every item here has a `si` version of itself among its distractors,
// and the picture is the argument.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC81() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C8.1-${(++n).toString().padLeft(2, '0')}';

  /* T1 — five counted loops. The first distractor is always the same program with `si`
     where `tantque` belongs: it draws one side and stops, which is the misconception
     with a picture attached. */
  for (final entry in [
    (0, '< 4', '+ 1', 4, 60, 90),
    (0, '< 3', '+ 1', 3, 80, 120),
    (0, '< 6', '+ 1', 6, 45, 60),
    (5, '> 0', '- 1', 5, 55, 72),
    (0, '< 8', '+ 2', 4, 65, 90),
  ]) {
    final start = entry.$1,
        test = entry.$2,
        step = entry.$3,
        sides = entry.$4,
        side = entry.$5,
        turn = entry.$6;
    final solution = counted(start, test, step, side, turn);
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C8.1',
      difficulty: Difficulty.d3,
      solution: solution,
      promptKeys: fillBoth(
        b(
            'Dessine la figure à {k} côtés avec un tantque. La boîte \$i part de '
                '{s} et va {step} à chaque tour.',
            'Draw the {k}-sided shape with a while. The box \$i starts at {s} '
                'and goes {step} each turn.'),
        {'k': sides, 's': start, 'step': step},
      ),
      wrong: [
        // The same program with `si`: one side, then nothing.
        solution.replaceFirst('tantque', 'si'),
        // The box never moves, so the loop never ends and Tika stops.
        solution.replaceFirst('\n  \$i = \$i $step', ''),
        // The right figure, drawn without a test at all.
        figure(sides, side, turn),
      ],
      assertions: [
        const ContainsNode('While'),
        const UsesVariable(name: 'i', min: 2, minReads: 2),
      ],
      alternatives: [
        '# un tantque qui compte\n$solution',
        solution.replaceFirst('tantque \$i $test', 'tantque (\$i $test)'),
      ],
      itemHints: hints(
        'Un tantque repose la question à chaque tour.',
        'A while asks the question again every turn.',
        'La boîte doit bouger, sinon ça ne s\'arrête pas.',
        'The box has to move, or it never stops.',
      ),
      paletteScope: palette,
    ));
  }

  /* T2 — four bugs, all `si` written where `tantque` belongs. One side of a figure is a
     picture a child recognises immediately, which is why this bug is worth four items. */
  for (final entry in [
    (0, '< 4', '+ 1', 4, 60, 90),
    (0, '< 5', '+ 1', 5, 50, 72),
    (6, '> 0', '- 1', 6, 40, 60),
    (0, '< 6', '+ 2', 3, 75, 120),
  ]) {
    final start = entry.$1,
        test = entry.$2,
        step = entry.$3,
        sides = entry.$4,
        side = entry.$5,
        turn = entry.$6;
    final solution = counted(start, test, step, side, turn);
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C8.1',
      difficulty: Difficulty.d3,
      broken: solution.replaceFirst('tantque', 'si'),
      solution: solution,
      promptKeys: fillBoth(
        b('Tika ne dessine qu\'un seul côté. Il en faut {k}.',
            'Tika draws only one side. There should be {k}.'),
        {'k': sides},
      ),
      wrong: [
        figure(sides, side, turn),
        solution.replaceFirst('\n  \$i = \$i $step', ''),
        counted(start, test, step, side, turn + 10),
      ],
      assertions: [
        const ContainsNode('While'),
        const UsesVariable(name: 'i', min: 2, minReads: 2),
      ],
      alternatives: [
        '# tant que, pas si\n$solution',
        solution.replaceFirst('tantque \$i $test', 'tantque (\$i $test)'),
      ],
      itemHints: hints(
        'si ne pose la question qu\'une fois.',
        'if only asks the question once.',
        'tantque la repose à chaque tour.',
        'while asks it again every turn.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — how many sides? The `si` answer is always on offer and it is always one, which
     is the misconception counted rather than described. */
  for (final entry in [
    (0, 4, 1, '< 4'),
    (0, 6, 1, '< 6'),
    (0, 4, 2, '< 8'),
    (5, 5, 1, '> 0'),
    (0, 3, 1, '< 3'),
  ]) {
    final start = entry.$1, turns = entry.$2, step = entry.$3, test = entry.$4;
    items.add(predict(
      id: id(),
      conceptId: 'C8.1',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b(
            'Combien de traits Tika dessine-t-elle ?\n\n'
                '\$i = {s}\ntantque \$i {t} {{\n  avance 50\n  tournedroite 60\n'
                '  \$i = \$i {step}\n}}',
            'How many lines does Tika draw?\n\n'
                '\$i = {s}\nwhile \$i {t} {{\n  forward 50\n  right 60\n'
                '  \$i = \$i {step}\n}}'),
        {
          's': start,
          't': test,
          'step': test.startsWith('>') ? '- $step' : '+ $step',
        },
      ),
      choices: [
        Choice(labelKeys: b('$turns', '$turns'), correct: true),
        Choice(
            labelKeys: b('1', '1'),
            correct: false,
            misconception: 'C8.1-while-is-if'),
        Choice(
            labelKeys: b('${turns + 1}', '${turns + 1}'),
            correct: false,
            misconception: 'C8.1-off-by-one'),
        Choice(
            labelKeys: b('0', '0'),
            correct: false,
            misconception: 'C8.1-while-never-runs'),
      ],
      itemHints: hints(
        'Compte les tours à la main.',
        'Count the turns by hand.',
        'Arrête-toi quand le test devient faux.',
        'Stop when the test turns false.',
      ),
      wrongChoiceFr:
          'Un tantque repose la question après chaque tour, et recommence tant qu\'elle est vraie.',
      wrongChoiceEn:
          'A while asks the question again after every turn, and goes round while it holds.',
    ));
  }

  // T4 — the hole is the word at the top of the loop.
  for (final entry in [
    (0, '< 4', '+ 1', 4, 60, 90),
    (0, '< 5', '+ 1', 5, 50, 72),
    (6, '> 0', '- 1', 6, 40, 60),
    (0, '< 3', '+ 1', 3, 80, 120),
    (0, '< 8', '+ 2', 4, 65, 90),
  ]) {
    final start = entry.$1,
        test = entry.$2,
        step = entry.$3,
        sides = entry.$4,
        side = entry.$5,
        turn = entry.$6;
    final solution = counted(start, test, step, side, turn);
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C8.1',
      difficulty: Difficulty.d2,
      withHoles: solution.replaceFirst('tantque', '___'),
      solution: solution,
      promptKeys: fillBoth(
        b('Complète pour que la figure ait ses {k} côtés.',
            'Fill in the blank so the shape gets all {k} sides.'),
        {'k': sides},
      ),
      wrong: [
        solution.replaceFirst('tantque', 'si'),
        figure(sides, side, turn),
        counted(start, test, step, side + 20, turn),
      ],
      assertions: [
        const ContainsNode('While'),
        const UsesVariable(name: 'i', min: 2, minReads: 2),
      ],
      alternatives: [
        '# tant que la boîte est encore petite\n$solution',
        solution.replaceFirst('tantque \$i $test', 'tantque (\$i $test)'),
      ],
      itemHints: hints(
        'Il faut un mot qui repose la question.',
        'You need a word that asks the question again.',
        'C\'est tantque.',
        'It is while.',
      ),
      paletteScope: palette,
    ));
  }

  // T9 — five open builds. No target picture, a rubric shown before the child starts.
  for (final entry in [
    (
      'Fais une figure avec un tantque qui compte.',
      'Make a shape with a while that counts.',
      'MOVE_FORWARD',
    ),
    (
      'Fais un escalier avec un tantque.',
      'Make a staircase with a while.',
      'MOVE_FORWARD',
    ),
    (
      'Fais une spirale avec un tantque.',
      'Make a spiral with a while.',
      'MOVE_FORWARD',
    ),
    (
      'Fais un dessin dont le nombre de tours est tiré au sort.',
      'Make a drawing whose number of turns is drawn by lot.',
      'RANDOM',
    ),
    (
      'Fais un dessin qui change de couleur à chaque tour.',
      'Make a drawing that changes colour every turn.',
      'PEN_COLOR',
    ),
  ]) {
    /* The third rubric line is named by the brief rather than derived from the item
       number: `id()` increments as it is called, so a switch on the counter reads the
       previous item's number and every brief would have got the wrong line. */
    final extra = switch (entry.$3) {
      'RANDOM' => rubricLine('Le hasard choisit le nombre de tours.',
          'Random chooses the number of turns.', const UsesOpcode('RANDOM')),
      'PEN_COLOR' => rubricLine('Tu changes la couleur du crayon.',
          'You change the pen colour.', const UsesOpcode('PEN_COLOR')),
      _ => rubricLine('Tika avance.', 'Tika moves forward.',
          const UsesOpcode('MOVE_FORWARD')),
    };
    items.add(openBuild(
      id: id(),
      conceptId: 'C8.1',
      difficulty: Difficulty.d3,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine('Ton programme se sert d\'un tantque.',
            'Your program uses a while.', const ContainsNode('While')),
        rubricLine('Une boîte compte les tours.', 'A box counts the turns.',
            const UsesVariable(min: 2, minReads: 2)),
        extra,
      ],
      itemHints: hints(
        'Remplis une boîte avant la boucle.',
        'Fill a box before the loop.',
        'Fais-la bouger dedans, sinon ça ne s\'arrête pas.',
        'Move it inside, or it never stops.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C8.2 — Arrêter la boucle.
// Misconception: "a loop always ends by itself".
//
// This is the one concept in KODO whose best item is a program that does not finish. A
// `tantque` whose test never turns false runs until the interpreter's ten-thousand-segment
// guard stops it, and the child is shown "ton programme s'est arrêté avant la fin" rather
// than a wrong picture. Nothing else in the curriculum teaches that a program can fail by
// *not stopping*, and no amount of explaining does what watching it does.
//
// So the runaway loop is authored as the broken program, three ways: the counter that
// never moves, the counter that moves away from the test, and the test that was already
// false of the starting value in the wrong direction.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC82() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C8.2-${(++n).toString().padLeft(2, '0')}';

  /* T2 — six runaway loops to bring home. Each broken program earns `programFailed`
     rather than a wrong drawing, which is the whole point of the concept. */
  /* `shortTest` is authored rather than computed, and it always means *fewer* turns. A
     loop that goes round a closed figure one extra time retraces it and leaves exactly
     the same ink — the gate caught four of these when the distractor added turns instead
     of dropping one. Fewer turns is always an open part of the figure, so it always
     differs. */
  for (final entry in [
    // (start, test, shortTest, step, sides, side, turn, whichBug)
    (0, '< 4', '< 3', '+ 1', 4, 60, 90, 'no-step'),
    (0, '< 5', '< 4', '+ 1', 5, 50, 72, 'wrong-way'),
    (6, '> 0', '> 2', '- 1', 6, 40, 60, 'no-step'),
    (0, '< 3', '< 2', '+ 1', 3, 80, 120, 'wrong-way'),
    (0, '< 6', '< 4', '+ 1', 6, 45, 60, 'no-step'),
    (8, '> 0', '> 4', '- 2', 4, 65, 90, 'wrong-way'),
  ]) {
    final start = entry.$1,
        test = entry.$2,
        shortTest = entry.$3,
        step = entry.$4,
        sides = entry.$5,
        side = entry.$6,
        turn = entry.$7,
        bug = entry.$8;
    final solution = counted(start, test, step, side, turn);
    final away = step.startsWith('+') ? '- ${step.substring(2)}' : '+ ${step.substring(2)}';
    final broken = bug == 'no-step'
        ? solution.replaceFirst('\n  \$i = \$i $step', '')
        : solution.replaceFirst('\$i = \$i $step', '\$i = \$i $away');
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C8.2',
      difficulty: Difficulty.d4,
      broken: broken,
      solution: solution,
      promptKeys: fillBoth(
        b(
            'Le programme ne s\'arrête plus. Fais en sorte que la boîte \$i finisse '
                'par rendre le test faux, après {k} tours.',
            'The program never stops. Make the box \$i end up turning the test '
                'false, after {k} turns.'),
        {'k': sides},
      ),
      wrong: [
        // The other runaway: also never finishes, for the other reason.
        bug == 'no-step'
            ? solution.replaceFirst('\$i = \$i $step', '\$i = \$i $away')
            : solution.replaceFirst('\n  \$i = \$i $step', ''),
        // Stops, but one turn early.
        counted(start, shortTest, step, side, turn),
        // Stops immediately: the test is false before the first turn.
        counted(start, test, step, side, turn)
            .replaceFirst('\$i = $start', '\$i = ${test.startsWith('<') ? 99 : -99}'),
      ],
      assertions: [
        const ContainsNode('While'),
        const UsesVariable(name: 'i', min: 2, minReads: 2),
      ],
      alternatives: [
        '# la boîte finit par rendre le test faux\n$solution',
        solution.replaceFirst('tantque \$i $test', 'tantque (\$i $test)'),
      ],
      itemHints: hints(
        'Regarde \$i à la fin de chaque tour.',
        'Look at \$i at the end of every turn.',
        'Elle doit s\'approcher de la sortie, pas s\'en éloigner.',
        'It has to move towards the way out, not away from it.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — does it stop? Five programs, three of which do not, and the choice that says
     "oui, toute boucle finit par s'arrêter" is the misconception spelled out. */
  for (final entry in [
    ('\$i = 0', '\$i < 4', '\$i = \$i + 1', true, 'C8.2-loops-always-end'),
    ('\$i = 0', '\$i < 4', '', false, 'C8.2-loops-always-end'),
    ('\$i = 0', '\$i < 4', '\$i = \$i - 1', false, 'C8.2-loops-always-end'),
    ('\$i = 9', '\$i > 0', '\$i = \$i - 3', true, 'C8.2-only-plus-one-ends'),
    ('\$i = 1', 'vrai', '\$i = \$i + 1', false, 'C8.2-loops-always-end'),
  ]) {
    final setup = entry.$1, test = entry.$2, step = entry.$3, stops = entry.$4;
    final body = step.isEmpty ? '  avance 20' : '  avance 20\n  $step';
    items.add(predict(
      id: id(),
      conceptId: 'C8.2',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Ce programme s\'arrête-t-il tout seul ?\n\n{s}\ntantque {t} {{\n{b}\n}}',
            'Does this program stop on its own?\n\n{s}\nwhile {t} {{\n{b}\n}}'),
        {'s': setup, 't': test, 'b': body},
      ),
      choices: [
        Choice(
            labelKeys: stops
                ? b('Oui, après quelques tours.', 'Yes, after a few turns.')
                : b('Non, il tourne sans fin.', 'No, it goes round for ever.'),
            correct: true),
        Choice(
            labelKeys: stops
                ? b('Non, il tourne sans fin.', 'No, it goes round for ever.')
                : b('Oui, toute boucle finit par s\'arrêter.',
                    'Yes, every loop stops in the end.'),
            correct: false,
            misconception: entry.$5),
        Choice(
            labelKeys: b('Il ne fait aucun tour.', 'It does no turns at all.'),
            correct: false,
            misconception: 'C8.1-while-never-runs'),
        Choice(
            labelKeys: b('Il fait exactement un tour.', 'It does exactly one turn.'),
            correct: false,
            misconception: 'C8.1-while-is-if'),
      ],
      itemHints: hints(
        'Suis \$i tour après tour.',
        'Follow \$i turn by turn.',
        'Se rapproche-t-elle du moment où le test devient faux ?',
        'Is it getting closer to the test turning false?',
      ),
      wrongChoiceFr:
          'Une boucle s\'arrête seulement si quelque chose dedans rend son test faux.',
      wrongChoiceEn:
          'A loop stops only if something inside it turns its test false.',
    ));
  }

  // T4 — the hole is the line that moves the box towards the exit.
  for (final entry in [
    (0, '< 4', '+ 1', '- 1', 4, 60, 90),
    (0, '< 6', '+ 1', '- 1', 6, 45, 60),
    (6, '> 0', '- 1', '+ 1', 6, 40, 60),
    (0, '< 8', '+ 2', '- 2', 4, 65, 90),
    (5, '> 0', '- 1', '+ 1', 5, 55, 72),
  ]) {
    final start = entry.$1,
        test = entry.$2,
        step = entry.$3,
        away = entry.$4,
        sides = entry.$5,
        side = entry.$6,
        turn = entry.$7;
    final solution = counted(start, test, step, side, turn);
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C8.2',
      difficulty: Difficulty.d3,
      withHoles: solution.replaceFirst('\$i = \$i $step', '___'),
      solution: solution,
      promptKeys: fillBoth(
        b('Complète pour que la boucle s\'arrête après {k} tours.',
            'Fill in the blank so the loop stops after {k} turns.'),
        {'k': sides},
      ),
      wrong: [
        solution.replaceFirst('\$i = \$i $step', '\$i = \$i $away'),
        solution.replaceFirst('\$i = \$i $step', '\$i = $start'),
        solution.replaceFirst('\$i = \$i $step',
            '\$i = \$i ${step.startsWith('+') ? '+' : '-'} ${int.parse(step.substring(2)) * 4}'),
      ],
      assertions: [
        const ContainsNode('While'),
        const UsesVariable(name: 'i', min: 2, minReads: 2),
      ],
      alternatives: [
        '# la boîte avance vers la sortie\n$solution',
        solution.replaceFirst('tantque \$i $test', 'tantque (\$i $test)'),
      ],
      itemHints: hints(
        'La boîte doit changer à chaque tour.',
        'The box has to change every turn.',
        'Et changer du bon côté.',
        'And change in the right direction.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Qu\'est-ce qui arrête un tantque ?',
        'What stops a while?'),
    choices: [
      Choice(
          labelKeys: b('Son test qui devient faux.',
              'Its test turning false.'),
          correct: true),
      Choice(
          labelKeys: b('Rien : il s\'arrête tout seul.',
              'Nothing: it stops by itself.'),
          correct: false,
          misconception: 'C8.2-loops-always-end'),
      Choice(
          labelKeys: b('La fin du programme.', 'The end of the program.'),
          correct: false,
          misconception: 'C8.2-loops-end-with-the-program'),
      Choice(
          labelKeys: b('Le nombre de traits sur la feuille.',
              'The number of lines on the paper.'),
          correct: false,
          misconception: 'C8.2-loops-end-when-full'),
    ],
    itemHints: hints(
      'La question est reposée après chaque tour.',
      'The question is asked again after every turn.',
      'Le jour où la réponse est non, ça sort.',
      'The day the answer is no, it comes out.',
    ),
    wrongChoiceFr:
        'Un tantque sort le jour où son test répond non, et pas avant.',
    wrongChoiceEn:
        'A while comes out the day its test answers no, and not before.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(r'Que se passe-t-il si $i ne change jamais dans la boucle ?',
        r'What happens if $i never changes inside the loop?'),
    choices: [
      Choice(
          labelKeys: b('La boucle tourne sans fin et Tika s\'arrête.',
              'The loop goes round for ever and Tika stops.'),
          correct: true),
      Choice(
          labelKeys: b('La boucle fait un seul tour.',
              'The loop does one turn.'),
          correct: false,
          misconception: 'C8.1-while-is-if'),
      Choice(
          labelKeys: b('KODO ajoute le changement pour toi.',
              'KODO adds the change for you.'),
          correct: false,
          misconception: 'C8.2-loops-always-end'),
      Choice(
          labelKeys: b('La boucle saute directement à la fin.',
              'The loop jumps straight to the end.'),
          correct: false,
          misconception: 'C8.2-loops-always-end'),
    ],
    itemHints: hints(
      'Le test regarde toujours le même nombre.',
      'The test keeps looking at the same number.',
      'Sa réponse ne changera donc jamais.',
      'So its answer will never change.',
    ),
    wrongChoiceFr:
        'Un test qui regarde un nombre immobile répond toujours pareil.',
    wrongChoiceEn:
        'A test looking at a number that never moves always answers the same.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        r'$i part de 0, le test est $i < 4, et la boucle fait $i = $i - 1. Que se passe-t-il ?',
        r'$i starts at 0, the test is $i < 4, and the loop does $i = $i - 1. What happens?'),
    choices: [
      Choice(
          labelKeys: b('Elle s\'éloigne de la sortie et ça ne finit pas.',
              'It moves away from the way out and never finishes.'),
          correct: true),
      Choice(
          labelKeys: b('Elle fait quatre tours quand même.',
              'It does four turns anyway.'),
          correct: false,
          misconception: 'C8.2-loops-always-end'),
      Choice(
          labelKeys: b('Elle s\'arrête tout de suite.',
              'It stops straight away.'),
          correct: false,
          misconception: 'C8.1-while-never-runs'),
      Choice(
          labelKeys: b('KODO remet le − en +.', 'KODO turns the − into a +.'),
          correct: false,
          misconception: 'C8.2-loops-always-end'),
    ],
    itemHints: hints(
      'Écris les valeurs : 0, puis −1, puis −2.',
      'Write the values down: 0, then −1, then −2.',
      'Est-ce que ça monte vers 4 ?',
      'Is that going up towards 4?',
    ),
    wrongChoiceFr:
        'Une boîte qui descend ne franchira jamais un test qui demande plus grand.',
    wrongChoiceEn:
        'A box going down will never pass a test that asks for bigger.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Un ami dit : « une boucle finit toujours par s\'arrêter ». Que réponds-tu ?',
      'A friend says: "a loop always stops in the end". What do you answer?',
    ),
    choices: [
      Choice(
          labelKeys: b('Seulement si quelque chose rend son test faux.',
              'Only if something turns its test false.'),
          correct: true),
      Choice(
          labelKeys: b('Oui, au bout d\'un moment.',
              'Yes, after a while.'),
          correct: false,
          misconception: 'C8.2-loops-always-end'),
      Choice(
          labelKeys: b('Oui, quand la feuille est pleine.',
              'Yes, when the paper is full.'),
          correct: false,
          misconception: 'C8.2-loops-end-when-full'),
      Choice(
          labelKeys: b('Non, aucune boucle ne s\'arrête.',
              'No, no loop ever stops.'),
          correct: false,
          misconception: 'C8.2-loops-never-end'),
    ],
    itemHints: hints(
      'Pense à la boucle qui ne bouge pas sa boîte.',
      'Think of the loop that never moves its box.',
      'Rien ne la fera sortir.',
      'Nothing will ever get it out.',
    ),
    wrongChoiceFr:
        'C\'est le programme qui fait sortir la boucle, pas le temps qui passe.',
    wrongChoiceEn:
        'It is the program that gets the loop out, not time passing.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi Tika s\'arrête-t-elle d\'elle-même sur une boucle sans fin ?',
      'Why does Tika stop by herself on a loop with no end?',
    ),
    choices: [
      Choice(
          labelKeys: b('Pour te prévenir plutôt que dessiner sans fin.',
              'To warn you rather than draw for ever.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que la boucle était correcte.',
              'Because the loop was correct.'),
          correct: false,
          misconception: 'C8.2-loops-always-end'),
      Choice(
          labelKeys: b('Parce qu\'elle est fatiguée.',
              'Because she is tired.'),
          correct: false,
          misconception: 'C8.2-loops-end-when-full'),
      Choice(
          labelKeys: b('Parce que le dessin était fini.',
              'Because the drawing was finished.'),
          correct: false,
          misconception: 'C8.2-loops-end-when-full'),
    ],
    itemHints: hints(
      'Elle compte les traits qu\'elle dessine.',
      'She counts the lines she draws.',
      'Passé un seuil, elle préfère te le dire.',
      'Past a certain point she would rather tell you.',
    ),
    wrongChoiceFr:
        'L\'arrêt est un avertissement : la boucle n\'avait pas de sortie.',
    wrongChoiceEn:
        'The stop is a warning: the loop had no way out.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Que faut-il vérifier avant de lancer un tantque ?',
      'What should you check before running a while?',
    ),
    choices: [
      Choice(
          labelKeys: b('Qu\'une ligne dedans rapproche de la sortie.',
              'That a line inside moves towards the way out.'),
          correct: true),
      Choice(
          labelKeys: b('Que la boîte part de zéro.',
              'That the box starts at zero.'),
          correct: false,
          misconception: 'C8.2-only-zero-works'),
      Choice(
          labelKeys: b('Que le test se sert de <.',
              'That the test uses <.'),
          correct: false,
          misconception: 'C8.2-only-plus-one-ends'),
      Choice(
          labelKeys: b('Rien de spécial.', 'Nothing in particular.'),
          correct: false,
          misconception: 'C8.2-loops-always-end'),
    ],
    itemHints: hints(
      'Le départ compte moins que le mouvement.',
      'The starting point matters less than the movement.',
      'Demande-toi ce qui rendra le test faux.',
      'Ask yourself what will turn the test false.',
    ),
    wrongChoiceFr:
        'Une boucle est sûre quand on peut dire ce qui rendra son test faux.',
    wrongChoiceEn:
        'A loop is safe when you can name what will turn its test false.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C8.3 — Capteurs.
// Misconception: "touching is checked only once".
//
// A sensor is not a fact, it is a question, and the difference only shows inside a loop:
// `tantque non touchebord` asks again after every step and stops on the step that arrives;
// `si non touchebord` asks once and walks straight past the edge. That is the same shape
// as C8.1's confusion, which is why this concept sits beside it rather than after it.
//
// `touchebord` and `touchecouleur` are geometry — the turtle against the page, and the
// turtle against its own ink — so they are exact under grading. A key is not: nobody is
// holding one while an item is marked, so the items that use `touchepressée` carry an
// authored scene saying which key is down, the same way a `hasard` item carries a seed.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC83() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C8.3-${(++n).toString().padLeft(2, '0')}';

  /* T1 — walk until something. Every distractor list carries the `si` version, because
     "asked once" is the misconception and one step is what it draws. The fixed-count
     version is in there too: on a canvas whose size the child knows it draws the identical
     path, so only `UsesOpcode('TOUCHING_EDGE')` tells them apart — which is the concept. */
  for (final entry in [
    (90, 20, 10),
    (0, 25, 8),
    (180, 40, 5),
    (270, 50, 4),
    (90, 10, 20),
  ]) {
    final heading = entry.$1, step = entry.$2, steps = entry.$3;
    final solution = 'direction $heading\n'
        '${whileDo('non touchebord', 'avance $step')}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C8.3',
      difficulty: Difficulty.d3,
      solution: solution,
      promptKeys: fillBoth(
        b('Pars vers le cap {d} et avance de {s} pas jusqu\'au bord.',
            'Head off on bearing {d} and move {s} steps at a time until the edge.'),
        {'d': heading, 's': step},
      ),
      wrong: [
        // Asked once: one step, then out.
        'direction $heading\n${ifThen('non touchebord', 'avance $step')}',
        // The right path, counted rather than sensed.
        'direction $heading\nrépète $steps {\n  avance $step\n}',
        // The test the wrong way round: Tika is not at the edge, so nothing happens.
        'direction $heading\n${whileDo('touchebord', 'avance $step')}',
      ],
      assertions: [
        const ContainsNode('While'),
        const UsesOpcode('TOUCHING_EDGE'),
      ],
      alternatives: [
        '# avance tant que le bord n\'est pas là\n$solution',
        'direction $heading\n${whileDo('non (touchebord)', 'avance $step')}',
      ],
      itemHints: hints(
        'Le capteur répond à chaque tour.',
        'The sensor answers on every turn.',
        'Continue tant que la réponse est non.',
        'Keep going while the answer is no.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — how many steps does it take? Geometry, so it has an exact answer: the canvas is
     400 wide, Tika starts in the middle, and the edge is 200 away. */
  for (final entry in [
    (90, 20, 10),
    (0, 25, 8),
    (180, 40, 5),
    (270, 50, 4),
    (90, 10, 20),
  ]) {
    final heading = entry.$1, step = entry.$2, steps = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C8.3',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b(
            'La feuille fait 400 sur 400 et Tika part du milieu.\n'
                'Combien de traits dessine-t-elle ?\n\n'
                'direction {d}\ntantque non touchebord {{\n  avance {s}\n}}',
            'The sheet is 400 by 400 and Tika starts in the middle.\n'
                'How many lines does she draw?\n\n'
                'direction {d}\nwhile not touchingedge {{\n  forward {s}\n}}'),
        {'d': heading, 's': step},
      ),
      choices: [
        Choice(labelKeys: b('$steps', '$steps'), correct: true),
        Choice(
            labelKeys: b('1', '1'),
            correct: false,
            misconception: 'C8.3-sensor-asked-once'),
        Choice(
            labelKeys: b('${steps * 2}', '${steps * 2}'),
            correct: false,
            misconception: 'C8.3-edge-is-the-far-side'),
        Choice(
            labelKeys: b('0', '0'),
            correct: false,
            misconception: 'C8.3-sensor-always-true'),
      ],
      itemHints: hints(
        'Du milieu au bord, il y a 200.',
        'From the middle to the edge is 200.',
        'Partage 200 par la longueur d\'un pas.',
        'Share 200 out by the length of one step.',
      ),
      wrongChoiceFr:
          'Le capteur est relu à chaque tour, et Tika sort au tour où il dit oui.',
      wrongChoiceEn:
          'The sensor is read again every turn, and Tika leaves on the turn it says yes.',
    ));
  }

  // T4 — the hole is the sensor.
  for (final entry in [
    (90, 20),
    (0, 25),
    (180, 40),
    (270, 50),
  ]) {
    final heading = entry.$1, step = entry.$2;
    final solution = 'direction $heading\n'
        '${whileDo('non touchebord', 'avance $step')}';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C8.3',
      difficulty: Difficulty.d3,
      withHoles: 'direction $heading\n${whileDo('non ___', 'avance $step')}',
      solution: solution,
      promptKeys: b('Complète pour que Tika s\'arrête au bord de la feuille.',
          'Fill in the blank so Tika stops at the edge of the sheet.'),
      wrong: [
        'direction $heading\n${whileDo('non vrai', 'avance $step')}',
        'direction $heading\n${whileDo('non faux', 'avance $step')}',
        'direction $heading\n'
            '${whileDo('non touchecouleur 255, 0, 0', 'avance $step')}',
      ],
      assertions: [
        const ContainsNode('While'),
        const UsesOpcode('TOUCHING_EDGE'),
      ],
      alternatives: [
        '# jusqu\'au bord\n$solution',
        'direction $heading\n${whileDo('non (touchebord)', 'avance $step')}',
      ],
      itemHints: hints(
        'Il existe un capteur pour le bord.',
        'There is a sensor for the edge.',
        'Il s\'appelle touchebord.',
        'It is called touchingedge.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Combien de fois un capteur est-il lu dans un tantque ?',
        'How many times is a sensor read inside a while?'),
    choices: [
      Choice(
          labelKeys: b('Une fois par tour.', 'Once every turn.'),
          correct: true),
      Choice(
          labelKeys: b('Une seule fois, au début.',
              'Once only, at the start.'),
          correct: false,
          misconception: 'C8.3-sensor-asked-once'),
      Choice(
          labelKeys: b('Une seule fois, à la fin.',
              'Once only, at the end.'),
          correct: false,
          misconception: 'C8.3-sensor-asked-once'),
      Choice(
          labelKeys: b('Jamais : c\'est le programme qui décide.',
              'Never: the program decides.'),
          correct: false,
          misconception: 'C8.3-sensor-is-a-setting'),
    ],
    itemHints: hints(
      'Le test d\'un tantque est reposé à chaque tour.',
      'A while\'s test is asked again every turn.',
      'Le capteur est dans ce test.',
      'The sensor is in that test.',
    ),
    wrongChoiceFr:
        'Le capteur est dans le test, donc il est relu à chaque tour.',
    wrongChoiceEn:
        'The sensor is in the test, so it is read again every turn.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que répond touchebord ?', 'What does touchingedge answer?'),
    choices: [
      Choice(
          labelKeys: b('Vrai ou faux, selon où est Tika.',
              'True or false, depending on where Tika is.'),
          correct: true),
      Choice(
          labelKeys: b('La distance jusqu\'au bord.',
              'The distance to the edge.'),
          correct: false,
          misconception: 'C8.3-sensor-returns-a-number'),
      Choice(
          labelKeys: b('Le nom du bord touché.',
              'The name of the edge touched.'),
          correct: false,
          misconception: 'C8.3-sensor-returns-a-name'),
      Choice(
          labelKeys: b('Toujours vrai.', 'Always true.'),
          correct: false,
          misconception: 'C8.3-sensor-always-true'),
    ],
    itemHints: hints(
      'C\'est une question, pas une mesure.',
      'It is a question, not a measurement.',
      'On y répond par oui ou par non.',
      'You answer it yes or no.',
    ),
    wrongChoiceFr: 'Un capteur rend un oui ou un non, comme un test.',
    wrongChoiceEn: 'A sensor gives back a yes or a no, like a test.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Tu écris si non touchebord { avance 20 } au lieu de tantque. Que fait Tika ?',
        'You write if not touchingedge { forward 20 } instead of while. What does Tika do?'),
    choices: [
      Choice(
          labelKeys: b('Elle fait un seul pas.', 'She takes one step.'),
          correct: true),
      Choice(
          labelKeys: b('Elle va jusqu\'au bord quand même.',
              'She goes to the edge anyway.'),
          correct: false,
          misconception: 'C8.1-while-is-if'),
      Choice(
          labelKeys: b('Elle ne bouge pas.', 'She does not move.'),
          correct: false,
          misconception: 'C8.3-sensor-always-true'),
      Choice(
          labelKeys: b('Elle traverse la feuille.',
              'She goes off the sheet.'),
          correct: false,
          misconception: 'C8.3-sensor-asked-once'),
    ],
    itemHints: hints(
      'si ne repose jamais sa question.',
      'if never asks its question again.',
      'Un seul passage dans le bloc.',
      'One trip through the block.',
    ),
    wrongChoiceFr:
        'si passe une fois dans le bloc ; tantque y revient tant que c\'est vrai.',
    wrongChoiceEn:
        'if goes through the block once; while comes back while it is true.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Que fait touchecouleur 255, 0, 0 ?',
        'What does touchingcolour 255, 0, 0 do?'),
    choices: [
      Choice(
          labelKeys: b('Il dit si Tika est sur un trait rouge.',
              'It says whether Tika is on a red line.'),
          correct: true),
      Choice(
          labelKeys: b('Il met le crayon en rouge.',
              'It makes the pen red.'),
          correct: false,
          misconception: 'C8.3-sensor-sets-instead-of-asks'),
      Choice(
          labelKeys: b('Il compte les traits rouges.',
              'It counts the red lines.'),
          correct: false,
          misconception: 'C8.3-sensor-returns-a-number'),
      Choice(
          labelKeys: b('Il efface les traits rouges.',
              'It erases the red lines.'),
          correct: false,
          misconception: 'C8.3-sensor-sets-instead-of-asks'),
    ],
    itemHints: hints(
      'Un capteur ne change rien au dessin.',
      'A sensor changes nothing in the drawing.',
      'Il regarde et il répond.',
      'It looks and it answers.',
    ),
    wrongChoiceFr:
        'Un capteur pose une question sur le dessin ; il ne le modifie pas.',
    wrongChoiceEn:
        'A sensor asks a question about the drawing; it does not change it.',
  ));

  /* T9 — open builds. Two of them are about a key, and a key is the one sensor that is
     authored rather than computed: the scene says `espace` is held, so the program can be
     run and the rubric checked. */
  for (final entry in [
    (
      'Fais avancer Tika jusqu\'au bord de la feuille.',
      'Make Tika walk to the edge of the sheet.',
      'TOUCHING_EDGE',
      false,
    ),
    (
      'Fais un dessin qui s\'arrête quand Tika touche le bord.',
      'Make a drawing that stops when Tika touches the edge.',
      'TOUCHING_EDGE',
      false,
    ),
    (
      'Fais un dessin qui attend la touche espace.',
      'Make a drawing that waits for the space key.',
      'KEY_DOWN',
      true,
    ),
    (
      'Fais un dessin qui change quand on appuie sur espace.',
      'Make a drawing that changes when space is pressed.',
      'KEY_DOWN',
      true,
    ),
  ]) {
    items.add(openBuild(
      id: id(),
      conceptId: 'C8.3',
      difficulty: Difficulty.d3,
      promptKeys: b(entry.$1, entry.$2),
      sensing: entry.$4
          ? const SensingScene(keysDown: ['espace'])
          : SensingScene.empty,
      rubric: [
        rubricLine('Ton programme se sert d\'un tantque.',
            'Your program uses a while.', const ContainsNode('While')),
        rubricLine(
            entry.$3 == 'KEY_DOWN'
                ? 'Le test demande si une touche est appuyée.'
                : 'Le test demande si Tika touche le bord.',
            entry.$3 == 'KEY_DOWN'
                ? 'The test asks whether a key is down.'
                : 'The test asks whether Tika touches the edge.',
            UsesOpcode(entry.$3)),
        rubricLine('Tika avance.', 'Tika moves forward.',
            const UsesOpcode('MOVE_FORWARD')),
      ],
      itemHints: hints(
        'Le capteur va dans le test du tantque.',
        'The sensor goes in the while\'s test.',
        'Mets non devant pour continuer tant que c\'est non.',
        'Put not in front to keep going while it is no.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C8.4 — Coupure.
// Misconception: "break ends the whole program".
//
// KODO has both words, which is lucky, because the misconception is *the other word*.
// `coupure` leaves the loop and the program carries on; `sortie` ends everything. A child
// who believes the first does the second has written a program that stops early, and the
// difference is visible: one figure on the page instead of two.
//
// So every item here draws something after the loop. Without that second figure the two
// words produce the identical picture and the concept has nothing to show.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC84() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C8.4-${(++n).toString().padLeft(2, '0')}';

  /// The loop body, with or without the line that gets out of it.
  ///
  /// Built rather than edited: the first version of the "no way out" distractor was a
  /// `replaceFirst` over a re-indented block, which matched nothing, changed nothing, and
  /// shipped a wrong answer identical to the right one. The gate caught all four.
  String loopBody(int side, int turn, int? stop) =>
      'avance $side\ntournedroite $turn\n\$i = \$i + 1'
      '${stop == null ? '' : '\n${ifThen('\$i == $stop', 'coupure')}'}';

  /// A loop that would never end, cut short on the [stop]th turn, then a second figure.
  String cutShort(int stop, int side, int turn, String after) =>
      '\$i = 0\n${whileDo('vrai', loopBody(side, turn, stop))}\n$after';

  /// The same loop with nothing to get it out: it runs until Tika stops it.
  String runaway(int side, int turn, String after) =>
      '\$i = 0\n${whileDo('vrai', loopBody(side, turn, null))}\n$after';

  // T1 — build it, with the second figure that makes the word matter.
  for (final entry in [
    (5, 40, 72, 4, 30, 90),
    (4, 50, 90, 3, 35, 120),
    (6, 35, 60, 4, 40, 90),
    (3, 60, 120, 6, 25, 60),
  ]) {
    final stop = entry.$1, side = entry.$2, turn = entry.$3;
    final after = 'centre\n${figure(entry.$4, entry.$5, entry.$6)}';
    final solution = cutShort(stop, side, turn, after);
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C8.4',
      difficulty: Difficulty.d4,
      solution: solution,
      promptKeys: fillBoth(
        b(
            'Le tantque ne s\'arrête jamais tout seul. Sors-en après {k} tours, '
                'puis dessine la seconde figure.',
            'The while never stops on its own. Leave it after {k} turns, then '
                'draw the second shape.'),
        {'k': stop},
      ),
      wrong: [
        // `sortie` ends the program: the second figure never happens.
        solution.replaceFirst('coupure', 'sortie'),
        // No way out at all: the loop runs away and Tika stops it.
        runaway(side, turn, after),
        // Out one turn early. Early, not late: one extra turn round a closed figure
        // retraces it and leaves the identical ink.
        cutShort(stop - 1, side, turn, after),
      ],
      assertions: [
        const ContainsNode('While'),
        const ContainsNode('Break'),
      ],
      alternatives: [
        '# on sort de la boucle, pas du programme\n$solution',
        cutShort(stop, side, turn, after)
            .replaceFirst('si \$i == $stop', 'si (\$i == $stop)'),
      ],
      itemHints: hints(
        'Il y a un mot pour sortir de la boucle.',
        'There is a word for leaving the loop.',
        'Et un autre pour quitter tout le programme.',
        'And another for quitting the whole program.',
      ),
      paletteScope: palette,
    ));
  }

  // T2 — five bugs, all of them `sortie` written where `coupure` belongs.
  for (final entry in [
    (5, 40, 72, 4, 30, 90),
    (4, 50, 90, 3, 35, 120),
    (6, 35, 60, 4, 40, 90),
    (3, 60, 120, 6, 25, 60),
    (8, 30, 45, 3, 45, 120),
  ]) {
    final stop = entry.$1, side = entry.$2, turn = entry.$3;
    final after = 'centre\n${figure(entry.$4, entry.$5, entry.$6)}';
    final solution = cutShort(stop, side, turn, after);
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C8.4',
      difficulty: Difficulty.d3,
      broken: solution.replaceFirst('coupure', 'sortie'),
      solution: solution,
      promptKeys: b(
          'La seconde figure ne se dessine plus. Sors de la boucle sans quitter le programme.',
          'The second shape is not drawn any more. Leave the loop without quitting the program.'),
      wrong: [
        // The loop left, and the second figure left out too.
        solution.replaceFirst('\n$after', ''),
        cutShort(stop - 1, side, turn, after),
        solution.replaceFirst('coupure', 'sortie').replaceFirst('\n$after', ''),
      ],
      assertions: [
        const ContainsNode('While'),
        const ContainsNode('Break'),
      ],
      alternatives: [
        '# coupure sort de la boucle seulement\n$solution',
        cutShort(stop, side, turn, after)
            .replaceFirst('si \$i == $stop', 'si (\$i == $stop)'),
      ],
      itemHints: hints(
        'Un des deux mots arrête tout.',
        'One of the two words stops everything.',
        'L\'autre ne quitte que la boucle.',
        'The other one only leaves the loop.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — how many lines? The `sortie` answer is always the loop's figure alone, and it is
     always on offer, because that is what the misconception draws. */
  for (final entry in [
    (5, 4),
    (4, 3),
    (6, 4),
    (3, 6),
  ]) {
    final stop = entry.$1, afterSides = entry.$2;
    items.add(predict(
      id: id(),
      conceptId: 'C8.4',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b(
            'Combien de traits Tika dessine-t-elle ?\n\n'
                '\$i = 0\ntantque vrai {{\n  avance 40\n  tournedroite 72\n'
                '  \$i = \$i + 1\n  si \$i == {k} {{\n    coupure\n  }}\n}}\n'
                'centre\nrépète {a} {{\n  avance 30\n  tournedroite 90\n}}',
            'How many lines does Tika draw?\n\n'
                '\$i = 0\nwhile true {{\n  forward 40\n  right 72\n'
                '  \$i = \$i + 1\n  if \$i == {k} {{\n    break\n  }}\n}}\n'
                'center\nrepeat {a} {{\n  forward 30\n  right 90\n}}'),
        {'k': stop, 'a': afterSides},
      ),
      choices: [
        Choice(
            labelKeys: b('${stop + afterSides}', '${stop + afterSides}'),
            correct: true),
        Choice(
            labelKeys: b('$stop', '$stop'),
            correct: false,
            misconception: 'C8.4-break-ends-the-program'),
        Choice(
            labelKeys: b('$afterSides', '$afterSides'),
            correct: false,
            misconception: 'C8.4-break-skips-the-loop'),
        Choice(
            labelKeys: b('0', '0'),
            correct: false,
            misconception: 'C8.2-loops-never-end'),
      ],
      itemHints: hints(
        'La boucle fait ses tours puis s\'arrête.',
        'The loop does its turns and then stops.',
        'Le programme continue après l\'accolade.',
        'The program carries on after the bracket.',
      ),
      wrongChoiceFr:
          'coupure quitte la boucle ; les lignes d\'après se jouent quand même.',
      wrongChoiceEn:
          'break leaves the loop; the lines after it still play.',
    ));
  }

  // T4 — the hole is which of the two words.
  for (final entry in [
    (5, 40, 72, 4, 30, 90),
    (4, 50, 90, 3, 35, 120),
    (6, 35, 60, 4, 40, 90),
  ]) {
    final stop = entry.$1, side = entry.$2, turn = entry.$3;
    final after = 'centre\n${figure(entry.$4, entry.$5, entry.$6)}';
    final solution = cutShort(stop, side, turn, after);
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C8.4',
      difficulty: Difficulty.d3,
      withHoles: solution.replaceFirst('coupure', '___'),
      solution: solution,
      promptKeys: b(
          'Complète pour sortir de la boucle en gardant la seconde figure.',
          'Fill in the blank to leave the loop and keep the second shape.'),
      wrong: [
        solution.replaceFirst('coupure', 'sortie'),
        solution.replaceFirst('coupure', 'centre'),
        solution.replaceFirst('coupure', 'nettoietout'),
      ],
      assertions: [
        const ContainsNode('While'),
        const ContainsNode('Break'),
      ],
      alternatives: [
        '# sortir de la boucle\n$solution',
        cutShort(stop, side, turn, after)
            .replaceFirst('si \$i == $stop', 'si (\$i == $stop)'),
      ],
      itemHints: hints(
        'Il faut quitter la boucle, pas le programme.',
        'You have to leave the loop, not the program.',
        'C\'est coupure.',
        'It is break.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait coupure ?', 'What does break do?'),
    choices: [
      Choice(
          labelKeys: b('Elle quitte la boucle et continue après.',
              'It leaves the loop and carries on after it.'),
          correct: true),
      Choice(
          labelKeys: b('Elle arrête tout le programme.',
              'It stops the whole program.'),
          correct: false,
          misconception: 'C8.4-break-ends-the-program'),
      Choice(
          labelKeys: b('Elle saute un tour de boucle.',
              'It skips one turn of the loop.'),
          correct: false,
          misconception: 'C8.4-break-skips-one-turn'),
      Choice(
          labelKeys: b('Elle recommence la boucle.',
              'It starts the loop again.'),
          correct: false,
          misconception: 'C8.4-break-restarts'),
    ],
    itemHints: hints(
      'Pense à sortir d\'une pièce, pas de la maison.',
      'Think of leaving a room, not the house.',
      'Le programme est encore là après.',
      'The program is still there afterwards.',
    ),
    wrongChoiceFr:
        'coupure sort de la boucle ; la ligne d\'après le bloc se joue ensuite.',
    wrongChoiceEn:
        'break leaves the loop; the line after the block plays next.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C8.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Quelle est la différence entre coupure et sortie ?',
        'What is the difference between break and quit?'),
    choices: [
      Choice(
          labelKeys: b('coupure quitte la boucle, sortie quitte tout.',
              'break leaves the loop, quit leaves everything.'),
          correct: true),
      Choice(
          labelKeys: b('Aucune : les deux arrêtent la boucle.',
              'None: both stop the loop.'),
          correct: false,
          misconception: 'C8.4-break-ends-the-program'),
      Choice(
          labelKeys: b('sortie est la version rapide de coupure.',
              'quit is the fast version of break.'),
          correct: false,
          misconception: 'C8.4-break-ends-the-program'),
      Choice(
          labelKeys: b('coupure ne marche que dans un répète.',
              'break only works inside a repeat.'),
          correct: false,
          misconception: 'C8.4-break-is-for-repeat-only'),
    ],
    itemHints: hints(
      'Regarde ce qui se dessine après la boucle.',
      'Look at what gets drawn after the loop.',
      'Avec l\'un, il ne reste rien à dessiner.',
      'With one of them there is nothing left to draw.',
    ),
    wrongChoiceFr:
        'La seconde figure dit lequel des deux tu as écrit.',
    wrongChoiceEn:
        'The second shape tells you which of the two you wrote.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// Tutorials (§4.2: Je regarde · On fait ensemble · Je fais).
//
// The narration never says *boucle* — `FR-M5-03`'s jargon list forbids it, and World 2
// taught the idea with *répète* rather than the word. Here it is *tant que*, which is the
// instruction and a phrase a child already uses.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Tutorial> world8Tutorials() => [
      tutorialFor(
        conceptId: 'C8.1',
        conceptName: b('Tant que repose la question.',
            'While asks the question again.'),
        palette: palette,
        steps: [
          watchStep(
            'C8.1',
            'Tika repose la question après chaque tour.',
            'Tika asks the question again after each turn.',
            counted(0, '< 4', '+ 1', 60, 90),
            ideas: ['while', 'counter'],
          ),
          togetherStep(
            'C8.1',
            'À toi. Mets 0 dans la boîte \$i.',
            'Your turn. Put 0 into the box \$i.',
            assigns: 'i',
            hintFr: 'Écris \$i = 0 avant la boucle.',
            hintEn: 'Write \$i = 0 before the loop.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C8.1',
            'Dessine un carré avec un tantque qui compte.',
            'Draw a square with a while that counts.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'La boîte doit bouger dans la boucle.',
            hintEn: 'The box has to move inside the loop.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C8.2',
        conceptName: b('Une boucle a besoin d\'une sortie.',
            'A loop needs a way out.'),
        palette: palette,
        steps: [
          watchStep(
            'C8.2',
            'Sans changement la question dit toujours oui.',
            'With no change the question always says yes.',
            counted(0, '< 4', '+ 1', 60, 90),
            ideas: ['termination', 'runaway'],
          ),
          togetherStep(
            'C8.2',
            'Ajoute la ligne qui fait grandir \$i.',
            'Add the line that makes \$i grow.',
            assigns: 'i',
            hintFr: 'Écris \$i = \$i + 1 dans la boucle.',
            hintEn: 'Write \$i = \$i + 1 inside the loop.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C8.2',
            'Fais un tantque qui s\'arrête après six tours.',
            'Make a while that stops after six turns.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Demande-toi ce qui rendra le test faux.',
            hintEn: 'Ask yourself what will turn the test false.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C8.3',
        conceptName: b('Un capteur répond à chaque tour.',
            'A sensor answers on every turn.'),
        palette: palette,
        steps: [
          watchStep(
            'C8.3',
            'Tika avance jusqu\'au bord de la feuille.',
            'Tika walks to the edge of the sheet.',
            'direction 90\n${whileDo('non touchebord', 'avance 20')}',
            ideas: ['sensor', 'edge'],
          ),
          togetherStep(
            'C8.3',
            'Mets le capteur du bord dans le test.',
            'Put the edge sensor into the test.',
            opcodeId: 'TOUCHING_EDGE',
            hintFr: 'Le capteur s\'appelle touchebord.',
            hintEn: 'The sensor is called touchingedge.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C8.3',
            'Fais avancer Tika jusqu\'au bord.',
            'Make Tika walk to the edge.',
            opcodeId: 'TOUCHING_EDGE',
            hintFr: 'Mets non devant pour avancer tant que c\'est non.',
            hintEn: 'Put not in front to keep going while it is no.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C8.4',
        conceptName: b('Coupure sort de la boucle.',
            'Break leaves the loop.'),
        palette: palette,
        steps: [
          watchStep(
            'C8.4',
            'Tika sort du tantque et continue après.',
            'Tika leaves the while and carries on after it.',
            '\$i = 0\n'
                '${whileDo('vrai', 'avance 40\ntournedroite 72\n\$i = \$i + 1\n'
                    '${ifThen('\$i == 5', 'coupure')}')}\n'
                'centre\n${figure(4, 30, 90)}',
            ideas: ['break', 'after-the-loop'],
          ),
          togetherStep(
            'C8.4',
            'Compte les tours dans la boîte \$i.',
            'Count the turns in the box \$i.',
            assigns: 'i',
            hintFr: 'Écris \$i = \$i + 1 dans la boucle.',
            hintEn: 'Write \$i = \$i + 1 inside the loop.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C8.4',
            'Sors du tantque et dessine encore une figure.',
            'Leave the while and draw one more shape.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'coupure quitte la boucle. sortie quitte tout.',
            hintEn: 'break leaves the loop. quit leaves everything.',
          ),
        ],
      ),
    ];

void main() {
  publishWorld(
    world: 8,
    nameKeys: b('Tant que', 'While'),
    conceptGraph: conceptGraph,
    committed: committed,
    items: [
      ...conceptC81(),
      ...conceptC82(),
      ...conceptC83(),
      ...conceptC84(),
    ],
    tutorials: world8Tutorials(),
    assetKeys: const ['art/tika.svg', 'art/world8-tantque.svg'],
  );
}
