// Authors World 2 — "Encore et encore" — and writes it out as a content pack.
//
//     dart tool/author_world2.dart
//
// Same pipeline as World 1: authored strings, parameterised numbers, every item through
// M6's publish gate before anything is written. World 2 is the loop, which is the first
// place a KODO child writes a program that is shorter than what it does — and the four
// misconceptions in the ledger are all about exactly that.

import 'dart:convert';
import 'dart:io';

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';


Map<String, String> b(String fr, String en) => {'fr': fr, 'en': en};

/// The four concepts of World 2, from the concept ledger.
const conceptGraph = <String, List<String>>{
  'C2.1': ['C1.2'],
  'C2.2': ['C2.1'],
  'C2.3': ['C2.2'],
  'C2.4': ['C2.1'],
};

const palette = [
  'MOVE_FORWARD',
  'MOVE_BACK',
  'TURN_LEFT',
  'TURN_RIGHT',
  'PEN_UP',
  'PEN_DOWN',
  'CLEAR',
];

/// A regular polygon, written out the long way. What the loop replaces.
String unrolled(int sides, int side) => [
      for (var i = 0; i < sides; i++)
        'avance $side\ntournedroite ${360 ~/ sides}',
    ].join('\n');

String looped(int sides, int side) =>
    'répète $sides {\n  avance $side\n  tournedroite ${360 ~/ sides}\n}';

// ---------------------------------------------------------------------------------------
// C2.1 — Répète n fois. Misconception: "repeat 4 always means 4 sides".
// ---------------------------------------------------------------------------------------

List<Item> conceptC21() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C2.1-${(++n).toString().padLeft(2, '0')}';

  // D1 — a dashed line. The count is not the number of sides of anything, which is the
  // whole misconception.
  //
  // It is dashes and not a plain `répète n { avance }` because a loop of forwards draws one
  // long straight line: three dashes and five dashes would be *the same picture* at
  // different lengths, the count would be invisible to the child and to the grader, and at
  // the canvas edge it would clip and make two different counts identical. The publish gate
  // caught exactly that.
  for (final pair in [
    [3, 40],
    [4, 30],
    [5, 25],
    [6, 20],
    [8, 15],
  ]) {
    final times = pair[0], step = pair[1];
    final dash = 'répète $times {\n  baissecrayon\n  avance $step\n'
        '  lèvecrayon\n  avance ${step ~/ 2}\n}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C2.1',
      difficulty: Difficulty.d1,
      solution: dash,
      promptKeys: fillBoth(
        b('Dessine {n} traits séparés, de {s} pas chacun.',
            'Draw {n} separate dashes, {s} steps each.'),
        {'s': step, 'n': times},
      ),
      wrong: [
        'baissecrayon\navance $step',
        'répète ${times + 1} {\n  baissecrayon\n  avance $step\n'
            '  lèvecrayon\n  avance ${step ~/ 2}\n}',
        'répète $times {\n  avance $step\n  avance ${step ~/ 2}\n}',
      ],
      alternatives: [
        '# une autre façon\n$dash',
        [
          for (var i = 0; i < times; i++)
            'baissecrayon\navance $step\nlèvecrayon\navance ${step ~/ 2}'
        ].join('\n'),
      ],
      itemHints: hints(
        'Le bloc répète refait ce qui est dedans, plusieurs fois.',
        'The repeat block does what is inside it again, several times.',
        'Le nombre dit combien de fois, pas combien de côtés.',
        'The number says how many times, not how many sides.',
        spotlight: 'MOVE_FORWARD',
      ),
      paletteScope: palette,
      requireFinalPose: true,
      lookAtFr: 'Compte les traits.',
      lookAtEn: 'Count the dashes.',
    ));
  }

  // D2 — a square and its friends: now the count and the shape are related, and the child
  // has already met a loop where they were not.
  for (final pair in [
    [4, 60],
    [3, 80],
    [6, 40],
    [5, 70],
  ]) {
    final sides = pair[0], side = pair[1];
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C2.1',
      difficulty: Difficulty.d2,
      solution: looped(sides, side),
      promptKeys: fillBoth(
        b('Dessine une figure à {n} côtés de {s} pas.',
            'Draw a shape with {n} sides of {s} steps.'),
        {'n': sides, 's': side},
      ),
      wrong: [
        looped(sides, side ~/ 2),
        looped(sides + 1, side),
        'répète $sides {\n  avance $side\n}',
      ],
      alternatives: [
        unrolled(sides, side),
        '# une autre façon\n${looped(sides, side)}'
      ],
      itemHints: hints(
        'Une figure fermée tourne en tout de 360 degrés.',
        'A closed shape turns 360 degrees in total.',
        'Divise 360 par le nombre de côtés.',
        'Divide 360 by the number of sides.',
        spotlight: 'TURN_RIGHT',
      ),
      paletteScope: palette,
      lookAtFr: 'Compte les côtés de ta figure.',
      lookAtEn: 'Count the sides of your shape.',
    ));
  }

  // T2 — the off-by-one and the wrong-angle bugs, which is what a child's first loop does.
  for (final pair in [
    [4, 60],
    [3, 70],
    [6, 45],
  ]) {
    final sides = pair[0], side = pair[1];
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C2.1',
      difficulty: Difficulty.d2,
      broken:
          'répète ${sides + 1} {\n  avance $side\n  tournedroite ${360 ~/ sides}\n}',
      solution: looped(sides, side),
      promptKeys: fillBoth(
        b('Ce programme devrait faire {n} côtés. Répare-le.',
            'This program should make {n} sides. Fix it.'),
        {'n': sides},
      ),
      wrong: [
        looped(sides + 2, side),
        'répète $sides {\n  avance $side\n}',
      ],
      itemHints: hints(
        'Compte combien de fois le bloc répète tourne.',
        'Count how many times the repeat block runs.',
        'Le nombre dans répète doit être le nombre de côtés.',
        'The number in repeat has to be the number of sides.',
        spotlight: 'TURN_RIGHT',
      ),
      paletteScope: palette,
      // One turn too many round a closed shape retraces the first side: the drawing is
      // *identical* and only the turtle's final pose differs. Without this the off-by-one
      // this item is about would be ungradable — which is what the gate reported.
      requireFinalPose: true,
      lookAtFr: 'Regarde où Tika s\'arrête.',
      lookAtEn: 'Look at where Tika stops.',
    ));
  }

  // T3 — predict. The misconception is the wrong choice, named as a misconception.
  for (final times in [3, 5, 6]) {
    items.add(predict(
      id: id(),
      conceptId: 'C2.1',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Combien de traits ce programme dessine-t-il ? répète {n} avec un avance dedans.',
            'How many lines does this program draw? repeat {n} with one forward inside.'),
        {'n': times},
      ),
      choices: [
        Choice(labelKeys: b('$times traits', '$times lines'), correct: true),
        Choice(
            labelKeys: b('1 trait', '1 line'),
            correct: false,
            misconception: 'the body runs once whatever the count says'),
        Choice(
            labelKeys: b('4 traits, comme un carré', '4 lines, like a square'),
            correct: false,
            misconception: 'repeat 4 always means 4 sides'),
      ],
      itemHints: hints(
        'Le bloc répète relance ce qui est dedans.',
        'The repeat block runs what is inside it again.',
        'Compte : une fois par tour.',
        'Count: once each time round.',
      ),
      wrongChoiceFr:
          'Compte un trait par tour de boucle. Le nombre dans répète dit combien de tours.',
      wrongChoiceEn:
          'Count one line for each time round. The number in repeat says how many times.',
    ));
  }

  // T4 — fill the gap.
  for (final pair in [
    [4, 50],
    [6, 35],
    [8, 30],
  ]) {
    final sides = pair[0], side = pair[1];
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C2.1',
      difficulty: Difficulty.d2,
      withHoles: 'répète ___ {\n  avance $side\n  tournedroite ___\n}',
      solution: looped(sides, side),
      promptKeys: fillBoth(
        b('Remplis les trous pour faire une figure à {n} côtés.',
            'Fill the gaps to make a shape with {n} sides.'),
        {'n': sides},
      ),
      wrong: [
        looped(sides, side ~/ 2),
        // Not `tournedroite 90`: that is the *right* answer when sides is 4, and asserting
        // it wrong would teach the grader to fail a correct child.
        'répète $sides {\n  avance $side\n  tournedroite ${360 ~/ sides + 15}\n}',
        'répète $sides {\n  avance $side\n}',
      ],
      itemHints: hints(
        'Le premier trou est le nombre de côtés.',
        'The first gap is the number of sides.',
        'Le second trou est 360 divisé par le nombre de côtés.',
        'The second gap is 360 divided by the number of sides.',
      ),
      paletteScope: palette,
    ));
  }

  // T5 — Parsons.
  for (final pair in [
    [4, 60],
    [5, 50],
  ]) {
    items.add(parsons(
      id: id(),
      conceptId: 'C2.1',
      difficulty: Difficulty.d2,
      solution: looped(pair[0], pair[1]),
      promptKeys: fillBoth(
        b('Remets les lignes dans le bon ordre pour dessiner une figure à {n} côtés.',
            'Put the lines back in order to draw a shape with {n} sides.'),
        {'n': pair[0]},
      ),
      wrong: [
        'avance ${pair[1]}\nrépète ${pair[0]} {\n  tournedroite ${360 ~/ pair[0]}\n}',
        'répète ${pair[0]} {\n  tournedroite ${360 ~/ pair[0]}\n}',
        'répète ${pair[0]} {\n  avance ${pair[1]}\n}',
      ],
      itemHints: hints(
        'Le bloc répète vient en premier.',
        'The repeat block comes first.',
        'Avance puis tourne, à chaque tour.',
        'Go forward then turn, each time round.',
      ),
      paletteScope: palette,
    ));
  }

  // T7 — golf. The budget is the point of the concept: fewer blocks, same drawing.
  for (final pair in [
    [6, 40],
    [8, 30],
    [12, 20],
    [4, 90],
  ]) {
    final sides = pair[0], side = pair[1];
    items.add(golf(
      id: id(),
      conceptId: 'C2.1',
      difficulty: Difficulty.d3,
      solution: looped(sides, side),
      budget: 3,
      promptKeys: fillBoth(
        b('Dessine une figure à {n} côtés avec au plus 3 blocs.',
            'Draw a shape with {n} sides using at most 3 blocks.'),
        {'n': sides},
      ),
      wrong: [
        unrolled(sides, side),
        looped(sides, side ~/ 2),
        looped(sides + 2, side),
      ],
      itemHints: hints(
        'Écrire la même chose {n} fois marche, mais coûte trop de blocs.',
        'Writing the same thing {n} times works, but costs too many blocks.',
        'Mets ce qui se répète dans un bloc répète.',
        'Put what repeats inside a repeat block.',
        spotlight: 'MOVE_FORWARD',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ---------------------------------------------------------------------------------------
// C2.2 — Le corps de la boucle. Misconception: "only the first line repeats".
// ---------------------------------------------------------------------------------------

List<Item> conceptC22() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C2.2-${(++n).toString().padLeft(2, '0')}';

  // D2 — three instructions in the body. If only the first line repeated, none of these
  // would draw what the prompt asks for.
  for (final pair in [
    [4, 50],
    [3, 70],
    [6, 40],
    [5, 60],
  ]) {
    final sides = pair[0], side = pair[1];
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C2.2',
      difficulty: Difficulty.d2,
      // A zigzag, not "out and back": a line drawn and then retraced leaves the same
      // pixels and the same pose, so the extra body lines this item is *about* would be
      // invisible to the grader. The gate caught it; the fix is a body whose every line
      // goes somewhere new.
      solution:
          'répète $sides {\n  avance $side\n  tournedroite ${360 ~/ sides}\n'
          '  avance ${side ~/ 2}\n  tournegauche ${360 ~/ sides}\n}',
      promptKeys: fillBoth(
        b('À chaque tour : avance {s}, tourne, avance {h}, retourne-toi. Fais-le {n} fois.',
            'Each time round: forward {s}, turn, forward {h}, turn back. Do it {n} times.'),
        {'s': side, 'h': side ~/ 2, 'n': sides},
      ),
      wrong: [
        'répète $sides {\n  avance $side\n}\ntournedroite ${360 ~/ sides}',
        'répète $sides {\n  avance $side\n  tournedroite ${360 ~/ sides}\n}',
        'avance $side\ntournedroite ${360 ~/ sides}\navance ${side ~/ 2}'
            '\ntournegauche ${360 ~/ sides}',
      ],
      itemHints: hints(
        'Tout ce qui est dans le bloc répète se refait, pas seulement la première ligne.',
        'Everything inside the repeat block happens again, not only the first line.',
        'Compte les lignes entre les accolades.',
        'Count the lines between the braces.',
        spotlight: 'MOVE_FORWARD',
      ),
      paletteScope: palette,
      lookAtFr: 'Regarde ce qui est dans le bloc répète.',
      lookAtEn: 'Look at what is inside the repeat block.',
    ));
  }

  // T2 — the line that fell out of the loop. This is the misconception, written as a bug.
  for (final pair in [
    [4, 60],
    [6, 40],
    [3, 80],
    [8, 30],
    [5, 55],
    [12, 20],
  ]) {
    final sides = pair[0], side = pair[1];
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C2.2',
      difficulty: Difficulty.d2,
      broken:
          'répète $sides {\n  avance $side\n}\ntournedroite ${360 ~/ sides}',
      solution: looped(sides, side),
      promptKeys: b(
          'Ce programme devrait dessiner une figure fermée. Répare-le.',
          'This program should draw a closed shape. Fix it.'),
      wrong: [
        'répète $sides {\n  tournedroite ${360 ~/ sides}\n}\navance $side',
        looped(sides + 1, side),
      ],
      itemHints: hints(
        'Le bloc tourner est tombé hors du bloc répète.',
        'The turn block has fallen outside the repeat block.',
        'Pour tourner à chaque tour, il doit être entre les accolades.',
        'To turn each time round, it has to be between the braces.',
        spotlight: 'TURN_RIGHT',
      ),
      paletteScope: palette,
      lookAtFr: 'Regarde où se termine le bloc répète.',
      lookAtEn: 'Look at where the repeat block ends.',
    ));
  }

  // T3 — predict, with the misconception as a named distractor.
  for (final pair in [
    [3, 2],
    [4, 3],
    [5, 2],
  ]) {
    final times = pair[0], linesInBody = pair[1];
    items.add(predict(
      id: id(),
      conceptId: 'C2.2',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Un bloc répète {n} contient {k} blocs avance. Combien de traits en tout ?',
            'A repeat {n} block contains {k} forward blocks. How many lines in total?'),
        {'n': times, 'k': linesInBody},
      ),
      choices: [
        Choice(
            labelKeys: b('${times * linesInBody} traits',
                '${times * linesInBody} lines'),
            correct: true),
        Choice(
            labelKeys: b('$times traits', '$times lines'),
            correct: false,
            misconception: 'only the first line repeats'),
        Choice(
            labelKeys: b('$linesInBody traits', '$linesInBody lines'),
            correct: false,
            misconception: 'the body runs once in total'),
      ],
      itemHints: hints(
        'Chaque tour refait tout le corps de la boucle.',
        'Each time round does the whole body of the loop again.',
        'Multiplie le nombre de tours par le nombre de blocs dedans.',
        'Multiply the number of times by the number of blocks inside.',
      ),
      wrongChoiceFr:
          'Tout le corps se refait à chaque tour. Compte les blocs dedans, puis multiplie.',
      wrongChoiceEn:
          'The whole body happens again each time round. Count the blocks inside, then multiply.',
    ));
  }

  // T4 — fill the gap: the braces themselves.
  for (final pair in [
    [5, 50],
    [6, 45],
    [4, 70],
    [3, 90],
  ]) {
    final sides = pair[0], side = pair[1];
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C2.2',
      difficulty: Difficulty.d2,
      withHoles: 'répète $sides {\n  avance $side\n  ___\n}',
      solution: looped(sides, side),
      promptKeys: fillBoth(
        b('Remplis le trou pour fermer la figure à {n} côtés.',
            'Fill the gap to close the shape with {n} sides.'),
        {'n': sides},
      ),
      wrong: [
        // Not `tournedroite 90`: for a four-sided shape that is the right answer.
        'répète $sides {\n  avance $side\n  tournedroite ${360 ~/ sides + 20}\n}',
        'répète $sides {\n  avance $side\n}',
        looped(sides, side ~/ 2),
      ],
      itemHints: hints(
        'Il manque le bloc qui fait tourner Tika.',
        'The block that turns Tika is missing.',
        'Une figure fermée tourne 360 degrés en tout.',
        'A closed shape turns 360 degrees in total.',
        spotlight: 'TURN_RIGHT',
      ),
      paletteScope: palette,
    ));
  }

  // T5 — Parsons with a multi-line body.
  for (final sides in [4, 6, 3]) {
    items.add(parsons(
      id: id(),
      conceptId: 'C2.2',
      difficulty: Difficulty.d3,
      solution: 'répète $sides {\n  baissecrayon\n  avance 50\n  lèvecrayon\n'
          '  avance 20\n  tournedroite ${360 ~/ sides}\n}',
      promptKeys: b(
          'Remets les lignes en ordre : un trait, un espace, puis on tourne.',
          'Put the lines in order: a line, a gap, then a turn.'),
      wrong: [
        'répète $sides {\n  avance 50\n  tournedroite ${360 ~/ sides}\n}',
        'baissecrayon\navance 50\nlèvecrayon\navance 20\ntournedroite ${360 ~/ sides}',
        'répète $sides {\n  lèvecrayon\n  avance 50\n  tournedroite ${360 ~/ sides}\n}',
      ],
      itemHints: hints(
        'Tout se passe à chaque tour, dans le même ordre.',
        'Everything happens each time round, in the same order.',
        'Baisse le crayon avant de dessiner, lève-le avant le trou.',
        'Put the pen down before drawing, lift it before the gap.',
        spotlight: 'PEN_DOWN',
      ),
      paletteScope: palette,
    ));
  }

  // T8 — explain, in child words.
  for (final sides in [4, 8]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C2.2',
      type: ItemType.t8Explain,
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Explique ce que fait le corps d\'un bloc répète {n}.',
            'Explain what the body of a repeat {n} block does.'),
        {'n': sides},
      ),
      choices: [
        Choice(
            labelKeys: b(
                'Tout ce qui est entre les accolades se refait à chaque tour.',
                'Everything between the braces happens again each time round.'),
            correct: true),
        Choice(
            labelKeys: b('Seule la première ligne se refait.',
                'Only the first line happens again.'),
            correct: false,
            misconception: 'only the first line repeats'),
        Choice(
            labelKeys: b('Les lignes se font toutes en même temps.',
                'The lines all happen at the same time.'),
            correct: false,
            misconception: 'blocks run all at once'),
      ],
      itemHints: hints(
        'Regarde ce qui est entre les accolades.',
        'Look at what is between the braces.',
        'Le corps, c\'est tout ce qui est dedans.',
        'The body is everything inside.',
      ),
      wrongChoiceFr:
          'Le corps est tout ce qui est entre les accolades, et il se refait en entier à chaque tour.',
      wrongChoiceEn:
          'The body is everything between the braces, and all of it happens again each time round.',
    ));
  }

  return items;
}

// ---------------------------------------------------------------------------------------
// C2.3 — Boucles imbriquées. Misconception: "the inner loop runs once in total".
// ---------------------------------------------------------------------------------------

List<Item> conceptC23() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C2.3-${(++n).toString().padLeft(2, '0')}';

  String rosace(int petals, int sides, int side) =>
      'répète $petals {\n  répète $sides {\n    avance $side\n'
      '    tournedroite ${360 ~/ sides}\n  }\n  tournedroite ${360 ~/ petals}\n}';

  // D3 — the rosace of [KT §2], which is the example the ledger cites.
  for (final triple in [
    [6, 4, 40],
    [8, 4, 30],
    [4, 3, 50],
    [12, 4, 20],
    [5, 6, 30],
    [9, 4, 25],
    [10, 3, 30],
  ]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C2.3',
      difficulty: Difficulty.d3,
      solution: rosace(triple[0], triple[1], triple[2]),
      promptKeys: fillBoth(
        b('Dessine {p} figures à {c} côtés, en tournant entre chacune.',
            'Draw {p} shapes with {c} sides, turning between each one.'),
        {'p': triple[0], 'c': triple[1]},
      ),
      wrong: [
        looped(triple[1], triple[2]),
        'répète ${triple[0]} {\n  avance ${triple[2]}\n  tournedroite ${360 ~/ triple[0]}\n}',
        rosace(triple[0], triple[1], triple[2] ~/ 2),
      ],
      alternatives: [
        '# une autre façon\n${rosace(triple[0], triple[1], triple[2])}',
        [
          for (var i = 0; i < triple[0]; i++)
            '${looped(triple[1], triple[2])}\ntournedroite ${360 ~/ triple[0]}'
        ].join('\n'),
      ],
      itemHints: hints(
        'La boucle du dedans dessine une figure entière.',
        'The inside loop draws one whole shape.',
        'La boucle du dehors recommence la figure, un peu tournée.',
        'The outside loop starts the shape again, turned a little.',
        spotlight: 'TURN_RIGHT',
      ),
      paletteScope: palette,
      lookAtFr: 'Compte les figures autour du centre.',
      lookAtEn: 'Count the shapes around the centre.',
    ));
  }

  // T2 — the inner loop that lost its braces.
  for (final pair in [
    [6, 4],
    [8, 3],
    [4, 6],
    [5, 4],
    [3, 5],
    [12, 3],
  ]) {
    final petals = pair[0], sides = pair[1];
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C2.3',
      difficulty: Difficulty.d3,
      broken: 'répète $petals {\n  avance 40\n  tournedroite ${360 ~/ sides}\n'
          '  tournedroite ${360 ~/ petals}\n}',
      solution: rosace(petals, sides, 40),
      promptKeys: fillBoth(
        b('Ce programme devrait dessiner {p} figures à {c} côtés. Répare-le.',
            'This program should draw {p} shapes with {c} sides. Fix it.'),
        {'p': petals, 'c': sides},
      ),
      wrong: [
        looped(sides, 40),
        rosace(petals, sides + 1, 40),
      ],
      itemHints: hints(
        'Il manque la boucle du dedans, celle qui fait une figure.',
        'The inside loop is missing — the one that makes one shape.',
        'Mets un bloc répète autour de avance et tourner.',
        'Put a repeat block around forward and turn.',
      ),
      paletteScope: palette,
      lookAtFr: 'Compte les figures.',
      lookAtEn: 'Count the shapes.',
    ));
  }

  // T3 — how many lines does a nested loop draw? The misconception is a named choice.
  for (final pair in [
    [3, 4],
    [5, 3],
    [6, 4],
    [4, 5],
  ]) {
    final outer = pair[0], inner = pair[1];
    items.add(predict(
      id: id(),
      conceptId: 'C2.3',
      difficulty: Difficulty.d4,
      promptKeys: fillBoth(
        b('Un répète {a} contient un répète {b} avec un avance dedans. Combien de traits ?',
            'A repeat {a} contains a repeat {b} with one forward inside. How many lines?'),
        {'a': outer, 'b': inner},
      ),
      choices: [
        Choice(
            labelKeys: b('${outer * inner} traits', '${outer * inner} lines'),
            correct: true),
        Choice(
            labelKeys: b('${outer + inner} traits', '${outer + inner} lines'),
            correct: false,
            misconception: 'nested loops add instead of multiplying'),
        Choice(
            labelKeys: b('$inner traits', '$inner lines'),
            correct: false,
            misconception: 'the inner loop runs once in total'),
      ],
      itemHints: hints(
        'La boucle du dedans se refait à chaque tour de celle du dehors.',
        'The inside loop happens again each time round the outside one.',
        'Multiplie les deux nombres.',
        'Multiply the two numbers.',
      ),
      wrongChoiceFr:
          'La boucle du dedans repart en entier à chaque tour du dehors. Multiplie les deux nombres.',
      wrongChoiceEn:
          'The inside loop starts over completely each time round the outside one. Multiply the two numbers.',
    ));
  }

  // T7 — golf: the rosace in five blocks.
  for (final triple in [
    [6, 4, 35],
    [8, 4, 25],
    [4, 4, 60],
  ]) {
    items.add(golf(
      id: id(),
      conceptId: 'C2.3',
      difficulty: Difficulty.d4,
      solution: rosace(triple[0], triple[1], triple[2]),
      budget: 5,
      promptKeys: fillBoth(
        b('Dessine {p} figures à {c} côtés avec au plus 5 blocs.',
            'Draw {p} shapes with {c} sides using at most 5 blocks.'),
        {'p': triple[0], 'c': triple[1]},
      ),
      wrong: [
        [
          for (var i = 0; i < triple[0]; i++)
            '${looped(triple[1], triple[2])}\ntournedroite ${360 ~/ triple[0]}'
        ].join('\n'),
        looped(triple[1], triple[2]),
        rosace(triple[0], triple[1], triple[2] * 2),
      ],
      itemHints: hints(
        'Répéter la figure entière coûte beaucoup de blocs.',
        'Repeating the whole shape costs a lot of blocks.',
        'Mets un bloc répète autour du bloc répète.',
        'Put a repeat block around the repeat block.',
      ),
      paletteScope: palette,
    ));
  }

  // T9 — an open build, judged on a rubric the child reads first.
  for (final petals in [6, 8]) {
    items.add(Item(
      id: id(),
      version: 1,
      conceptId: 'C2.3',
      type: ItemType.t9OpenBuild,
      difficulty: Difficulty.d4,
      promptKeys: fillBoth(
        b('Invente une rosace à {p} branches. Tu choisis la figure.',
            'Invent a rosette with {p} arms. You choose the shape.'),
        {'p': petals},
      ),
      referenceSolutionSource: rosace(petals, 4, 35),
      alternativeSolutionSources: [
        rosace(petals, 3, 40),
        rosace(petals, 6, 25),
      ],
      wrongSolutionSources: [
        looped(4, 35),
        'répète $petals {\n  avance 35\n  tournedroite ${360 ~/ petals}\n}',
        'avance 35',
      ],
      rubric: [
        RubricLine(
          textKeys: b('Il y a une boucle dans une boucle.',
              'There is a loop inside a loop.'),
          assertion: const NestedInside('Repeat', 'Repeat'),
        ),
        RubricLine(
          textKeys: b('Il y a au moins deux figures autour du centre.',
              'There are at least two shapes around the centre.'),
          assertion: const ContainsNode('Repeat', min: 2),
        ),
        RubricLine(
          textKeys: b('Chaque tour fait avancer et tourner.',
              'Each time round goes forward and turns.'),
          assertion: const BodyLength('Repeat', min: 2),
        ),
      ],
      hints: hints(
        'Commence par une figure qui se ferme.',
        'Start with a shape that closes.',
        'Puis mets-la dans un bloc répète, et tourne un peu entre chaque.',
        'Then put it in a repeat block, and turn a little between each one.',
      ),
      diagnostics: drawingDiagnostics(
        lookAtFr: 'Compte les branches autour du centre.',
        lookAtEn: 'Count the arms around the centre.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ---------------------------------------------------------------------------------------
// C2.4 — Boucle ou copier-coller ? Misconception: "a longer program is a better program".
// ---------------------------------------------------------------------------------------

List<Item> conceptC24() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C2.4-${(++n).toString().padLeft(2, '0')}';

  // T7 — the whole concept in one item type: the same drawing, fewer blocks.
  for (final pair in [
    [5, 50],
    [6, 40],
    [8, 30],
    [10, 25],
    [12, 20],
    [3, 90],
  ]) {
    final sides = pair[0], side = pair[1];
    items.add(golf(
      id: id(),
      conceptId: 'C2.4',
      difficulty: Difficulty.d3,
      solution: looped(sides, side),
      budget: 3,
      promptKeys: fillBoth(
        b('Fais le même dessin que {k} lignes copiées, avec au plus 3 blocs.',
            'Make the same drawing as {k} copied lines, with at most 3 blocks.'),
        {'k': sides * 2},
      ),
      wrong: [
        unrolled(sides, side),
        looped(sides, side + 10),
        looped(sides - 1, side),
      ],
      itemHints: hints(
        'Copier-coller marche, mais tu vas manquer de place.',
        'Copy-paste works, but you will run out of room.',
        'Ce qui se répète tient dans un seul bloc répète.',
        'What repeats fits inside one repeat block.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read a program and answer. The long one and the short one draw the same thing.
  for (final sides in [4, 6, 8]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C2.4',
      type: ItemType.t6ReadAndAnswer,
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Un programme a {k} lignes copiées. Un autre a un répète {n}. Que dessinent-ils ?',
            'One program has {k} copied lines. Another has a repeat {n}. What do they draw?'),
        {'k': sides * 2, 'n': sides},
      ),
      choices: [
        Choice(
            labelKeys:
                b('Exactement le même dessin.', 'Exactly the same drawing.'),
            correct: true),
        Choice(
            labelKeys: b('Le plus long fait un plus grand dessin.',
                'The longer one makes a bigger drawing.'),
            correct: false,
            misconception: 'a longer program is a better program'),
        Choice(
            labelKeys:
                b('Le répète en fait moins.', 'The repeat one does less.'),
            correct: false,
            misconception: 'a loop does the body fewer times than the copies'),
      ],
      itemHints: hints(
        'Compte ce que chaque programme fait faire à Tika.',
        'Count what each program makes Tika do.',
        'Le bloc répète refait exactement les mêmes lignes.',
        'The repeat block does exactly the same lines again.',
      ),
      wrongChoiceFr:
          'Les deux font faire les mêmes pas à Tika. Un programme plus long ne dessine pas plus.',
      wrongChoiceEn:
          'Both make Tika take the same steps. A longer program does not draw more.',
    ));
  }

  // T8 — explain the choice.
  for (final sides in [6, 12]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C2.4',
      type: ItemType.t8Explain,
      difficulty: Difficulty.d4,
      promptKeys: fillBoth(
        b('Pourquoi écrire répète {n} plutôt que {k} lignes copiées ?',
            'Why write repeat {n} rather than {k} copied lines?'),
        {'n': sides, 'k': sides * 2},
      ),
      choices: [
        Choice(
            labelKeys: b(
                'Parce que si je change un nombre, je ne le change qu\'une fois.',
                'Because if I change a number, I only change it once.'),
            correct: true),
        Choice(
            labelKeys: b('Parce que le dessin sera plus beau.',
                'Because the drawing will be nicer.'),
            correct: false,
            misconception: 'a loop changes what is drawn'),
        Choice(
            labelKeys: b('Parce que le programme ira plus vite.',
                'Because the program will run faster.'),
            correct: false,
            misconception: 'a loop is faster than the same lines written out'),
      ],
      itemHints: hints(
        'Pense à ce qui se passe quand tu veux changer la taille.',
        'Think about what happens when you want to change the size.',
        'Avec des copies, il faut changer chaque copie.',
        'With copies, you have to change every copy.',
      ),
      wrongChoiceFr:
          'Le dessin est le même et la vitesse aussi. Ce qui change, c\'est le travail quand tu veux modifier quelque chose.',
      wrongChoiceEn:
          'The drawing is the same and so is the speed. What changes is the work when you want to alter something.',
    ));
  }

  // T5 — Parsons: turn the copies into a loop.
  for (final sides in [4, 5, 6]) {
    items.add(parsons(
      id: id(),
      conceptId: 'C2.4',
      difficulty: Difficulty.d3,
      solution: looped(sides, 60),
      promptKeys: fillBoth(
        b('Remets ces trois lignes en ordre pour remplacer {k} lignes copiées.',
            'Put these three lines in order to replace {k} copied lines.'),
        {'k': sides * 2},
      ),
      wrong: [
        'avance 60\nrépète $sides {\n  tournedroite ${360 ~/ sides}\n}',
        'répète $sides {\n  tournedroite ${360 ~/ sides}\n  avance 60\n}\navance 60',
        'répète $sides {\n  avance 60\n}',
      ],
      itemHints: hints(
        'Le bloc répète va autour, pas au milieu.',
        'The repeat block goes around, not in the middle.',
        'Dedans : avance, puis tourne.',
        'Inside: forward, then turn.',
      ),
      paletteScope: palette,
    ));
  }

  // T2 — a copy-paste program with one copy wrong. The reason loops exist.
  for (final sides in [5, 6, 4, 8]) {
    final broken = [
      for (var i = 0; i < sides; i++)
        'avance ${i == 2 ? 70 : 60}\ntournedroite ${360 ~/ sides}',
    ].join('\n');
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C2.4',
      difficulty: Difficulty.d3,
      broken: broken,
      solution: looped(sides, 60),
      promptKeys: b(
          'Une des copies a été mal recopiée. Répare la figure, avec ou sans boucle.',
          'One of the copies was mistyped. Fix the shape, with or without a loop.'),
      wrong: [
        looped(sides, 70),
        looped(sides - 1, 60),
      ],
      itemHints: hints(
        'Un côté n\'a pas la même longueur que les autres.',
        'One side is not the same length as the others.',
        'Avec un bloc répète, il n\'y a qu\'un seul nombre à écrire.',
        'With a repeat block, there is only one number to write.',
      ),
      paletteScope: palette,
      lookAtFr: 'Compare les côtés entre eux.',
      lookAtEn: 'Compare the sides with each other.',
    ));
  }

  return items;
}

// ---------------------------------------------------------------------------------------
// Tutorials
// ---------------------------------------------------------------------------------------

Tutorial tutorialFor({
  required String conceptId,
  required Map<String, String> conceptName,
  required List<TutorialStep> steps,
}) =>
    Tutorial(
      id: 'tut-$conceptId',
      conceptId: conceptId,
      steps: steps,
      closingConceptNameKeys: conceptName,
      paletteScope: palette,
    );

List<Tutorial> world2Tutorials() => [
      tutorialFor(
        conceptId: 'C2.1',
        conceptName: b('Répéter plusieurs fois', 'Repeating several times'),
        steps: [
          TutorialStep(
            id: 'C2.1-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b('Regarde. Trois lignes font quatre côtés.',
                'Watch. Three lines make four sides.'),
            audioKeys: b('audio/fr/C2.1-s1.opus', 'audio/en/C2.1-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.canvas,
            demoProgramSource: 'répète 4 {\n  avance 60\n  tournedroite 90\n}',
            newIdeas: ['répète'],
          ),
          TutorialStep(
            id: 'C2.1-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b('À toi. Mets un bloc répète autour de avance.',
                'Your turn. Put a repeat block around forward.'),
            audioKeys: b('audio/fr/C2.1-s2.opus', 'audio/en/C2.1-s2.opus'),
            expectedAction: ExpectedAction.placeBlock,
            spotlight: SpotlightTarget.paletteFamilyControl,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b('Le bloc répète est dans la famille Contrôle.',
                'The repeat block is in the Control family.'),
          ),
          TutorialStep(
            id: 'C2.1-s3',
            beat: Beat.jeFais,
            narrationKeys: b(
                'Fais un triangle. Trois côtés, et on tourne à chaque fois.',
                'Make a triangle. Three sides, and we turn each time.'),
            audioKeys: b('audio/fr/C2.1-s3.opus', 'audio/en/C2.1-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'TURN_RIGHT'),
            retryHintKeys: b('Trois côtés : 360 divisé par 3, cela fait 120.',
                'Three sides: 360 divided by 3 is 120.'),
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C2.2',
        conceptName: b('Le corps de la boucle', 'The body of the loop'),
        steps: [
          TutorialStep(
            id: 'C2.2-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b('Regarde. Tout ce qui est dedans se refait.',
                'Watch. Everything inside happens again.'),
            audioKeys: b('audio/fr/C2.2-s1.opus', 'audio/en/C2.2-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.scriptArea,
            demoProgramSource:
                'répète 4 {\n  avance 50\n  tournedroite 90\n  avance 25\n  recule 25\n}',
            newIdeas: ['corps de la boucle'],
          ),
          TutorialStep(
            id: 'C2.2-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b(
                'Ajoute une ligne dans le bloc répète. Elle aussi se refera.',
                'Add a line inside the repeat block. It will happen again too.'),
            audioKeys: b('audio/fr/C2.2-s2.opus', 'audio/en/C2.2-s2.opus'),
            expectedAction: ExpectedAction.placeBlock,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_BACK'),
            retryHintKeys: b('Le nouveau bloc doit être entre les accolades.',
                'The new block has to be between the braces.'),
          ),
          TutorialStep(
            id: 'C2.2-s3',
            beat: Beat.jeFais,
            narrationKeys: b(
                'Sors le bloc tourner des accolades. Regarde ce qui change.',
                'Take the turn block out of the braces. Watch what changes.'),
            audioKeys: b('audio/fr/C2.2-s3.opus', 'audio/en/C2.2-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'TURN_RIGHT'),
            retryHintKeys: b(
                'Fais glisser le bloc tourner sous l\'accolade fermante.',
                'Drag the turn block below the closing brace.'),
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C2.3',
        conceptName: b('Une boucle dans une boucle', 'A loop inside a loop'),
        steps: [
          TutorialStep(
            id: 'C2.3-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b(
                'Regarde. Un carré. Puis on tourne un peu et on recommence.',
                'Watch. A square. Then we turn a little and start again.'),
            audioKeys: b('audio/fr/C2.3-s1.opus', 'audio/en/C2.3-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.canvas,
            demoProgramSource:
                'répète 6 {\n  répète 4 {\n    avance 40\n    tournedroite 90\n  }\n  tournedroite 60\n}',
            newIdeas: ['boucle dans une boucle'],
          ),
          TutorialStep(
            id: 'C2.3-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b('À toi. Mets un bloc répète autour de ton carré.',
                'Your turn. Put a repeat block around your square.'),
            audioKeys: b('audio/fr/C2.3-s2.opus', 'audio/en/C2.3-s2.opus'),
            expectedAction: ExpectedAction.placeBlock,
            spotlight: SpotlightTarget.paletteFamilyControl,
            successCondition:
                const SuccessCondition(opcodeId: 'TURN_RIGHT', minCount: 2),
            retryHintKeys: b(
                'Le carré entier va à l\'intérieur du nouveau bloc.',
                'The whole square goes inside the new block.'),
          ),
          TutorialStep(
            id: 'C2.3-s3',
            beat: Beat.jeFais,
            narrationKeys: b('Fais une rosace à huit branches.',
                'Make a rosette with eight arms.'),
            audioKeys: b('audio/fr/C2.3-s3.opus', 'audio/en/C2.3-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b(
                'Huit branches : tourne de 45 degrés entre chacune.',
                'Eight arms: turn 45 degrees between each one.'),
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C2.4',
        conceptName: b('Boucle ou copier-coller', 'Loop or copy-paste'),
        steps: [
          TutorialStep(
            id: 'C2.4-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b(
                'Regarde ces deux programmes. Ils dessinent la même chose.',
                'Look at these two programs. They draw the same thing.'),
            audioKeys: b('audio/fr/C2.4-s1.opus', 'audio/en/C2.4-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.scriptArea,
            demoProgramSource: 'répète 6 {\n  avance 50\n  tournedroite 60\n}',
            newIdeas: ['plus court, même dessin'],
          ),
          TutorialStep(
            id: 'C2.4-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b(
                'Change la longueur. Il y a un seul nombre à changer.',
                'Change the length. There is only one number to change.'),
            audioKeys: b('audio/fr/C2.4-s2.opus', 'audio/en/C2.4-s2.opus'),
            expectedAction: ExpectedAction.editNumber,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b('Appuie sur le nombre dans le bloc avance.',
                'Tap the number in the forward block.'),
          ),
          TutorialStep(
            id: 'C2.4-s3',
            beat: Beat.jeFais,
            narrationKeys: b('Écris la figure la plus courte que tu peux.',
                'Write the shortest shape you can.'),
            audioKeys: b('audio/fr/C2.4-s3.opus', 'audio/en/C2.4-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b('Trois blocs suffisent : répète, avance, tourner.',
                'Three blocks is enough: repeat, forward, turn.'),
          ),
        ],
      ),
    ];

// ---------------------------------------------------------------------------------------

void main() {
  final items = [
    ...conceptC21(),
    ...conceptC22(),
    ...conceptC23(),
    ...conceptC24(),
  ];
  final tutorials = world2Tutorials();

  stdout.writeln(
      'World 2 — authored ${items.length} items, ${tutorials.length} tutorials');

  final itemFailures = checkBank(items);
  final tutorialFailures = [for (final t in tutorials) ...checkTutorial(t)];

  if (itemFailures.isNotEmpty || tutorialFailures.isNotEmpty) {
    stderr.writeln('\nREFUSED — the pack was not written.\n');
    for (final f in itemFailures) {
      stderr.writeln('  $f');
    }
    for (final f in tutorialFailures) {
      stderr.writeln('  $f');
    }
    stderr.writeln(
        '\n${itemFailures.length + tutorialFailures.length} failure(s)');
    exit(1);
  }

  const committed = {'C2.1': 22, 'C2.2': 22, 'C2.3': 22, 'C2.4': 18};
  for (final concept in conceptGraph.keys) {
    final mine = items.where((i) => i.conceptId == concept).toList();
    final types = mine.map((i) => i.type).toSet();
    stdout.writeln('  $concept: ${mine.length} items, ${types.length} types '
        '(${(types.toList()..sort((a, b) => a.code.compareTo(b.code))).map((t) => t.code).join(' ')})');
    if (types.length < 5) {
      stderr.writeln(
          'REFUSED: §6.1 requires at least five item types per concept; '
          '$concept has ${types.length}');
      exit(1);
    }
    if (mine.length < committed[concept]!) {
      stderr.writeln(
          'REFUSED: §6.3 commits ${committed[concept]} items for $concept; '
          'this pack has ${mine.length}');
      exit(1);
    }
  }

  final pack = ContentPack(
    world: 2,
    version: 1,
    nameKeys: b('Encore et encore', 'Again and again'),
    concepts: conceptGraph,
    tutorials: tutorials,
    items: items,
    itemAudioKeys: {
      for (final item in items)
        item.id: {
          for (final locale in requiredLocales)
            locale: 'audio/$locale/${item.id}.opus',
        },
    },
    audioKeys: [
      for (final t in tutorials)
        for (final s in t.steps) ...s.audioKeys.values,
      for (final item in items)
        for (final locale in requiredLocales) 'audio/$locale/${item.id}.opus',
    ],
    assetKeys: const ['art/tika.svg', 'art/world2-rosace.svg'],
  );

  final encoded = const JsonEncoder.withIndent('  ').convert(pack.toJson());
  final sized = ContentPack.fromJson({
    ...pack.toJson(),
    'sizeBytes': utf8.encode(encoded).length,
  });
  final manifest = PackManifest.of(sized);

  final dir = Directory('../../content');
  dir.createSync(recursive: true);
  File('${dir.path}/world2.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sized.toJson())}\n');
  File('${dir.path}/world2.manifest.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n');

  stdout.writeln('\nPublished content/world2.json');
  stdout.writeln(
      '  ${sized.sizeBytes} bytes of ${ContentPack.worldBudgetBytes} budget '
      '(${(sized.sizeBytes / ContentPack.worldBudgetBytes * 100).toStringAsFixed(1)} %)');
  stdout.writeln('  sha256 ${manifest.contentHash.substring(0, 16)}…');
  stdout.writeln('  audio keys: ${sized.audioKeys.length}');
}
