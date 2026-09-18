// Authors World 0 — "Bonjour Tika" — and writes it out as a content pack.
//
//     dart tool/author_world0.dart
//
// World 0 is first contact. The child may be six and may not read yet, so every prompt is
// short, every picture is unambiguous, and the palette is five blocks. The four concepts
// are not about drawing; they are about the four things a child has to believe before any
// of the rest works: that *I* make it run, that order matters, that the blocks happen one
// after another, and that a mistake can be undone.

import 'dart:convert';
import 'dart:io';

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';

Map<String, String> b(String fr, String en) => {'fr': fr, 'en': en};

/// The four concepts of World 0, from the concept ledger.
const conceptGraph = <String, List<String>>{
  'C0.1': <String>[],
  'C0.2': ['C0.1'],
  'C0.3': ['C0.2'],
  'C0.4': ['C0.1'],
};

/// Five blocks. A first palette that fits on one screen at 48 dp with room to miss.
const palette = [
  'MOVE_FORWARD',
  'TURN_RIGHT',
  'TURN_LEFT',
  'PEN_UP',
  'PEN_DOWN',
];

// ---------------------------------------------------------------------------------------
// C0.1 — Lancer un programme.
// Misconception: "the program runs only if I press something magic".
// ---------------------------------------------------------------------------------------

List<Item> conceptC01() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C0.1-${(++n).toString().padLeft(2, '0')}';

  // D1 — one block, one line. The smallest possible whole program, which is the point:
  // a program is a thing you wrote, and pressing the button runs *yours*.
  for (final length in [40, 50, 60, 70, 80, 30]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C0.1',
      difficulty: Difficulty.d1,
      solution: 'avance $length',
      promptKeys: fillBoth(
        b('Fais avancer Tika de {n} pas. Appuie sur le bouton vert.',
            'Make Tika go forward {n} steps. Press the green button.'),
        {'n': length},
      ),
      wrong: [
        'avance ${length ~/ 2}',
        'avance ${length + 30}',
        'tournedroite 90',
      ],
      itemHints: hints(
        'Mets un bloc avance dans ton programme.',
        'Put a forward block in your program.',
        'Le bouton vert fait partir ton programme.',
        'The green button starts your program.',
        spotlight: 'MOVE_FORWARD',
      ),
      paletteScope: palette,
      lookAtFr: 'Regarde le nombre dans le bloc.',
      lookAtEn: 'Look at the number in the block.',
    ));
  }

  // T3 — predict. The misconception is the named wrong answer.
  for (final length in [50, 70, 40]) {
    items.add(predict(
      id: id(),
      conceptId: 'C0.1',
      difficulty: Difficulty.d1,
      promptKeys: fillBoth(
        b('Ton programme dit : avance {n}. Que se passe-t-il ?',
            'Your program says: forward {n}. What happens?'),
        {'n': length},
      ),
      choices: [
        Choice(
            labelKeys: b('Tika avance et laisse un trait.',
                'Tika goes forward and leaves a line.'),
            correct: true),
        Choice(
            labelKeys: b('Rien, il manque un bloc magique.',
                'Nothing, a magic block is missing.'),
            correct: false,
            misconception: 'the program runs only if I press something magic'),
        Choice(
            labelKeys: b('Tika tourne sur place.', 'Tika turns on the spot.'),
            correct: false,
            misconception: 'forward and turn are the same block'),
      ],
      itemHints: hints(
        'Le bloc avance fait avancer Tika.',
        'The forward block makes Tika go forward.',
        'Il n\'y a rien d\'autre à ajouter.',
        'There is nothing else to add.',
      ),
      wrongChoiceFr:
          'Un programme est juste la liste de tes blocs. Le bouton vert la fait faire, du premier au dernier.',
      wrongChoiceEn:
          'A program is just your list of blocks. The green button makes it happen, first to last.',
    ));
  }

  // T5 — Parsons, on two blocks. Even here, the order is the child's choice.
  for (final length in [60, 40, 80]) {
    items.add(parsons(
      id: id(),
      conceptId: 'C0.1',
      difficulty: Difficulty.d1,
      solution: 'baissecrayon\navance $length',
      promptKeys: b('Remets les deux blocs en ordre. Il faut un trait.',
          'Put the two blocks back in order. A line is needed.'),
      wrong: [
        'lèvecrayon\navance $length',
        'baissecrayon\navance ${length ~/ 2}',
        'tournedroite 90\navance $length',
      ],
      itemHints: hints(
        'Le crayon doit toucher le papier avant de bouger.',
        'The pen has to touch the paper before moving.',
        'Baisse le crayon d\'abord.',
        'Put the pen down first.',
        spotlight: 'PEN_DOWN',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T6 — read and answer. What a program *is*.
  for (final pair in [
    ['avance 50', 1],
    ['avance 50\navance 30', 2],
    ['avance 50\ntournedroite 90\navance 50', 3],
  ]) {
    final blocks = pair[1] as int;
    items.add(choiceItem(
      id: id(),
      conceptId: 'C0.1',
      type: ItemType.t6ReadAndAnswer,
      difficulty: Difficulty.d1,
      promptKeys: fillBoth(
        b('Ce programme a {k} blocs. Combien Tika en fait-elle ?',
            'This program has {k} blocks. How many does Tika do?'),
        {'k': blocks},
      ),
      choices: [
        Choice(
            labelKeys: b('Tous les $blocks.', 'All $blocks of them.'),
            correct: true),
        Choice(
            labelKeys: b('Un seul, le premier.', 'Only one, the first.'),
            correct: false,
            misconception: 'pressing run does one block'),
        Choice(
            labelKeys: b('Aucun sans un bloc « départ ».',
                'None without a "start" block.'),
            correct: false,
            misconception: 'the program runs only if I press something magic'),
      ],
      itemHints: hints(
        'Le bouton vert fait tout ton programme.',
        'The green button does your whole program.',
        'Compte les blocs que tu as posés.',
        'Count the blocks you put down.',
      ),
      wrongChoiceFr:
          'Le bouton vert fait tous tes blocs, du premier jusqu\'au dernier. Compte-les.',
      wrongChoiceEn:
          'The green button does all your blocks, from the first to the last. Count them.',
    ));
  }

  // T4 — fill the gap. Small, and the answer is one number.
  for (final length in [50, 70, 60]) {
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C0.1',
      difficulty: Difficulty.d1,
      withHoles: 'avance ___',
      solution: 'avance $length',
      promptKeys: fillBoth(
        b('Écris le nombre pour avancer de {n} pas.',
            'Write the number to go {n} steps.'),
        {'n': length},
      ),
      wrong: [
        'avance ${length ~/ 2}',
        'avance ${length + 40}',
        'recule $length',
      ],
      itemHints: hints(
        'Le nombre dit combien de pas.',
        'The number says how many steps.',
        'Regarde le nombre dans la question.',
        'Look at the number in the question.',
        spotlight: 'MOVE_FORWARD',
      ),
      paletteScope: palette,
    ));
  }

  // T2 — fix the bug. The first one a child meets: a number, not a structure.
  for (final length in [60, 40, 80]) {
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C0.1',
      difficulty: Difficulty.d2,
      broken: 'avance ${length ~/ 2}',
      solution: 'avance $length',
      promptKeys: fillBoth(
        b('Le trait est trop court. Il doit faire {n} pas.',
            'The line is too short. It should be {n} steps.'),
        {'n': length},
      ),
      wrong: [
        'avance ${length + 40}',
        'tournedroite 90\navance $length',
      ],
      itemHints: hints(
        'Change le nombre dans le bloc.',
        'Change the number in the block.',
        'Appuie sur le nombre pour l\'écrire.',
        'Tap the number to type it.',
        spotlight: 'MOVE_FORWARD',
      ),
      paletteScope: palette,
      lookAtFr: 'Compare la longueur du trait.',
      lookAtEn: 'Compare how long the line is.',
    ));
  }

  return items;
}

// ---------------------------------------------------------------------------------------
// C0.2 — Séquence. Misconception: "order does not matter".
// ---------------------------------------------------------------------------------------

List<Item> conceptC02() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C0.2-${(++n).toString().padLeft(2, '0')}';

  /// An L: go, turn, go. Reversing the first two blocks draws a different L.
  String elbow(int first, int second, int angle) =>
      'avance $first\ntournedroite $angle\navance $second';

  // D1/D2 — two lines and a corner. The picture is the argument: swap the blocks and the
  // corner moves.
  for (final triple in [
    [60, 40, 90],
    [50, 70, 90],
    [40, 55, 120],
    [70, 30, 60],
    [80, 50, 90],
    [30, 60, 120],
  ]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C0.2',
      difficulty: Difficulty.d2,
      solution: elbow(triple[0], triple[1], triple[2]),
      promptKeys: fillBoth(
        b('Avance de {a} pas, tourne, puis avance de {b} pas.',
            'Go {a} steps, turn, then go {b} steps.'),
        {'a': triple[0], 'b': triple[1]},
      ),
      wrong: [
        elbow(triple[1], triple[0], triple[2]),
        'tournedroite ${triple[2]}\navance ${triple[0]}\navance ${triple[1]}',
        'avance ${triple[0]}\navance ${triple[1]}',
      ],
      itemHints: hints(
        'Pose les blocs de haut en bas, dans l\'ordre.',
        'Put the blocks down from top to bottom, in order.',
        'Le premier bloc se fait en premier.',
        'The first block happens first.',
        spotlight: 'MOVE_FORWARD',
      ),
      paletteScope: palette,
      requireFinalPose: true,
      lookAtFr: 'Regarde où se trouve le coin.',
      lookAtEn: 'Look at where the corner is.',
    ));
  }

  // T5 — Parsons. The whole concept, as an activity.
  for (final triple in [
    [60, 40, 90],
    [50, 75, 120],
    [70, 40, 90],
    [40, 70, 60],
  ]) {
    items.add(parsons(
      id: id(),
      conceptId: 'C0.2',
      difficulty: Difficulty.d2,
      solution: elbow(triple[0], triple[1], triple[2]),
      promptKeys: fillBoth(
        b('Remets en ordre : {a} pas, un tour, {b} pas.',
            'Put in order: {a} steps, a turn, {b} steps.'),
        {'a': triple[0], 'b': triple[1]},
      ),
      wrong: [
        elbow(triple[1], triple[0], triple[2]),
        'tournedroite ${triple[2]}\navance ${triple[0]}\navance ${triple[1]}',
        'avance ${triple[0]}\navance ${triple[1]}\ntournedroite ${triple[2]}',
      ],
      itemHints: hints(
        'Commence par le bloc qui se fait en premier.',
        'Start with the block that happens first.',
        'Le tour est au milieu.',
        'The turn is in the middle.',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T4 — fill the gap, where the gap is a whole block.
  for (final triple in [
    [60, 40, 90],
    [50, 60, 120],
    [70, 70, 90],
  ]) {
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C0.2',
      difficulty: Difficulty.d2,
      withHoles: 'avance ${triple[0]}\n___\navance ${triple[1]}',
      solution: elbow(triple[0], triple[1], triple[2]),
      promptKeys: fillBoth(
        b('Mets le bloc qui manque. Le coin fait {d} degrés.',
            'Put in the missing block. The corner is {d} degrees.'),
        {'d': triple[2]},
      ),
      wrong: [
        'avance ${triple[0]}\navance ${triple[1]}',
        'avance ${triple[0]}\ntournedroite ${triple[2] + 30}\navance ${triple[1]}',
        'tournedroite ${triple[2]}\navance ${triple[0]}\navance ${triple[1]}',
      ],
      itemHints: hints(
        'Il manque le bloc qui fait tourner Tika.',
        'The block that turns Tika is missing.',
        'Il se met entre les deux avance.',
        'It goes between the two forwards.',
        spotlight: 'TURN_RIGHT',
      ),
      paletteScope: palette,
    ));
  }

  // T3 — predict. Two programs, same blocks, different order.
  for (final triple in [
    [60, 40, 90],
    [70, 30, 120],
    [50, 80, 90],
  ]) {
    items.add(predict(
      id: id(),
      conceptId: 'C0.2',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Mêmes blocs, autre ordre. Que dessinent les deux programmes ?',
            'Same blocks, different order. What do the two programs draw?'),
        {'a': triple[0], 'b': triple[1]},
      ),
      choices: [
        Choice(
            labelKeys: b('Deux dessins différents.', 'Two different drawings.'),
            correct: true),
        Choice(
            labelKeys: b('Le même dessin.', 'The same drawing.'),
            correct: false,
            misconception: 'order does not matter'),
        Choice(
            labelKeys: b('Rien du tout.', 'Nothing at all.'),
            correct: false,
            misconception: 'a reordered program is broken'),
      ],
      itemHints: hints(
        'Essaie les deux et regarde le dessin.',
        'Try both and look at the drawing.',
        'Le premier bloc se fait en premier, à chaque fois.',
        'The first block happens first, every time.',
      ),
      wrongChoiceFr:
          'Les blocs se font dans l\'ordre où tu les as posés. Change l\'ordre, et le dessin change.',
      wrongChoiceEn:
          'The blocks happen in the order you put them. Change the order, and the drawing changes.',
    ));
  }

  // T6 — read and answer.
  for (final angle in [90, 120, 60]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C0.2',
      type: ItemType.t6ReadAndAnswer,
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Un programme fait : avance, tourne, avance. Quel bloc est le dernier ?',
            'A program does: forward, turn, forward. Which block is the last?'),
        {'d': angle},
      ),
      choices: [
        Choice(
            labelKeys: b('Le deuxième avance.', 'The second forward.'),
            correct: true),
        Choice(
            labelKeys: b('Le bloc tourner.', 'The turn block.'),
            correct: false,
            misconception: 'the turn is what finishes a program'),
        Choice(
            labelKeys:
                b('Ils se font tous ensemble.', 'They all happen together.'),
            correct: false,
            misconception: 'blocks run all at once'),
      ],
      itemHints: hints(
        'Lis les blocs de haut en bas.',
        'Read the blocks from top to bottom.',
        'Le dernier de la liste se fait en dernier.',
        'The last one in the list happens last.',
      ),
      wrongChoiceFr:
          'Les blocs se font l\'un après l\'autre, de haut en bas. Le dernier bloc est le dernier fait.',
      wrongChoiceEn:
          'The blocks happen one after another, top to bottom. The last block is the last done.',
    ));
  }

  // T2 — fix the bug: two blocks the wrong way round.
  for (final triple in [
    [60, 40, 90],
    [80, 30, 120],
    [50, 70, 90],
    [40, 60, 60],
  ]) {
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C0.2',
      difficulty: Difficulty.d2,
      broken: elbow(triple[1], triple[0], triple[2]),
      solution: elbow(triple[0], triple[1], triple[2]),
      promptKeys: fillBoth(
        b('Le coin est mal placé. Le premier trait fait {a} pas.',
            'The corner is misplaced. The first line is {a} steps.'),
        {'a': triple[0]},
      ),
      wrong: [
        'avance ${triple[0]}\navance ${triple[1]}',
        'tournedroite ${triple[2]}\navance ${triple[0]}\navance ${triple[1]}',
      ],
      itemHints: hints(
        'Les deux nombres ont changé de place.',
        'The two numbers have swapped places.',
        'Le premier trait est le plus long ici.',
        'The first line is the longer one here.',
      ),
      paletteScope: palette,
      requireFinalPose: true,
      lookAtFr: 'Compare les deux traits.',
      lookAtEn: 'Compare the two lines.',
    ));
  }

  return items;
}

// ---------------------------------------------------------------------------------------
// C0.3 — Ordre des instructions. Misconception: "blocks run all at once".
// ---------------------------------------------------------------------------------------

List<Item> conceptC03() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C0.3-${(++n).toString().padLeft(2, '0')}';

  /// A staircase. Every step depends on the one before it, so "all at once" draws
  /// nothing that looks like this.
  String stair(int steps, int side) => [
        for (var i = 0; i < steps; i++)
          'avance $side\ntournedroite 90\navance $side\ntournegauche 90',
      ].join('\n');

  // T5 — Parsons on a staircase. The activity *is* the concept.
  for (final pair in [
    [2, 30],
    [3, 25],
    [2, 40],
    [3, 30],
    [4, 20],
  ]) {
    items.add(parsons(
      id: id(),
      conceptId: 'C0.3',
      difficulty: Difficulty.d2,
      solution: stair(pair[0], pair[1]),
      promptKeys: fillBoth(
        b('Remets les blocs en ordre pour monter {n} marches.',
            'Put the blocks in order to climb {n} steps.'),
        {'n': pair[0]},
      ),
      wrong: [
        stair(pair[0] + 1, pair[1]),
        'avance ${pair[1]}\ntournedroite 90\navance ${pair[1]}',
        [for (var i = 0; i < pair[0]; i++) 'avance ${pair[1]}'].join('\n'),
      ],
      itemHints: hints(
        'Une marche, c\'est monter puis avancer.',
        'One step is going up then going along.',
        'Fais la première marche en entier avant la suivante.',
        'Do the whole first step before the next one.',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T2 — fix the bug: a block in the wrong place changes everything after it.
  for (final pair in [
    [2, 35],
    [3, 25],
    [2, 45],
    [3, 30],
  ]) {
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C0.3',
      difficulty: Difficulty.d3,
      broken: 'tournedroite 90\n${stair(pair[0], pair[1])}',
      solution: stair(pair[0], pair[1]),
      promptKeys: fillBoth(
        b('L\'escalier part du mauvais côté. Enlève le bloc en trop.',
            'The staircase starts the wrong way. Take out the extra block.'),
        {'n': pair[0]},
      ),
      wrong: [
        stair(pair[0] + 1, pair[1]),
        'tournegauche 90\n${stair(pair[0], pair[1])}',
      ],
      itemHints: hints(
        'Regarde le tout premier bloc.',
        'Look at the very first block.',
        'Il fait tourner Tika avant qu\'elle commence.',
        'It turns Tika before she starts.',
        spotlight: 'TURN_RIGHT',
      ),
      paletteScope: palette,
      requireFinalPose: true,
      lookAtFr: 'Regarde dans quelle direction part l\'escalier.',
      lookAtEn: 'Look at which way the staircase goes.',
    ));
  }

  // T3 — predict, with "all at once" as the named misconception.
  for (final steps in [2, 3, 4]) {
    items.add(predict(
      id: id(),
      conceptId: 'C0.3',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Tu appuies sur le vert. Comment les {k} blocs se font-ils ?',
            'You press the green one. How do the {k} blocks happen?'),
        {'k': steps * 4},
      ),
      choices: [
        Choice(
            labelKeys: b('L\'un après l\'autre, de haut en bas.',
                'One after another, from top to bottom.'),
            correct: true),
        Choice(
            labelKeys: b('Tous en même temps.', 'All at the same time.'),
            correct: false,
            misconception: 'blocks run all at once'),
        Choice(
            labelKeys: b('Dans n\'importe quel ordre.', 'In any order at all.'),
            correct: false,
            misconception: 'order does not matter'),
      ],
      itemHints: hints(
        'Regarde le bloc qui s\'allume pendant que ça tourne.',
        'Watch the block that lights up while it runs.',
        'Il descend, un bloc à la fois.',
        'It goes down, one block at a time.',
      ),
      wrongChoiceFr:
          'Le bloc allumé descend un par un pendant que le programme tourne. Regarde-le et compte.',
      wrongChoiceEn:
          'The lit block moves down one at a time while the program runs. Watch it and count.',
    ));
  }

  // T6 — read and answer: what changes if one block moves.
  for (final pair in [
    [2, 40],
    [3, 30],
    [2, 30],
  ]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C0.3',
      type: ItemType.t6ReadAndAnswer,
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Tu montes un bloc tourner plus haut. Qu\'est-ce qui change ?',
            'You move a turn block higher up. What changes?'),
        {'n': pair[0]},
      ),
      choices: [
        Choice(
            labelKeys: b(
                'Tout ce qui vient après.', 'Everything that comes after it.'),
            correct: true),
        Choice(
            labelKeys: b('Rien, c\'est le même programme.',
                'Nothing, it is the same program.'),
            correct: false,
            misconception: 'order does not matter'),
        Choice(
            labelKeys: b('Seulement ce bloc-là.', 'Only that one block.'),
            correct: false,
            misconception: 'a block only affects itself'),
      ],
      itemHints: hints(
        'Tika garde la direction que le bloc lui a donnée.',
        'Tika keeps the direction the block gave her.',
        'Les blocs suivants partent de là.',
        'The blocks after it start from there.',
      ),
      wrongChoiceFr:
          'Chaque bloc part de là où Tika est arrivée. Bouger un bloc change tous les suivants.',
      wrongChoiceEn:
          'Each block starts from where Tika got to. Moving a block changes every one after it.',
    ));
  }

  // T1 — build it, having seen why.
  for (final pair in [
    [2, 40],
    [3, 30],
    [4, 25],
  ]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C0.3',
      difficulty: Difficulty.d3,
      solution: stair(pair[0], pair[1]),
      promptKeys: fillBoth(
        b('Fais monter Tika de {n} marches de {s} pas.',
            'Make Tika climb {n} steps of {s}.'),
        {'n': pair[0], 's': pair[1]},
      ),
      wrong: [
        stair(pair[0] + 1, pair[1]),
        stair(pair[0], pair[1] + 15),
        [for (var i = 0; i < pair[0]; i++) 'avance ${pair[1]}'].join('\n'),
      ],
      itemHints: hints(
        'Une marche : monte, tourne, avance, retourne-toi.',
        'One step: up, turn, along, turn back.',
        'Refais la même chose pour la marche suivante.',
        'Do the same thing again for the next step.',
        spotlight: 'TURN_RIGHT',
      ),
      paletteScope: palette,
      requireFinalPose: true,
      lookAtFr: 'Compte les marches.',
      lookAtEn: 'Count the steps.',
    ));
  }

  return items;
}

// ---------------------------------------------------------------------------------------
// C0.4 — Annuler / recommencer. Misconception: "a mistake ruins the project".
// ---------------------------------------------------------------------------------------

List<Item> conceptC04() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C0.4-${(++n).toString().padLeft(2, '0')}';

  // T2 — the whole concept: a program with one block too many. Taking it out is undo.
  for (final pair in [
    [60, 90],
    [40, 120],
    [70, 90],
    [50, 60],
    [80, 90],
  ]) {
    final side = pair[0], angle = pair[1];
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C0.4',
      difficulty: Difficulty.d1,
      broken:
          'avance $side\ntournedroite $angle\navance $side\navance ${side ~/ 2}',
      solution: 'avance $side\ntournedroite $angle\navance $side',
      promptKeys: fillBoth(
        b('Il y a un bloc de trop. Enlève-le. Rien n\'est cassé.',
            'There is one block too many. Take it out. Nothing is broken.'),
        {'a': side},
      ),
      wrong: [
        'avance $side\ntournedroite $angle',
        'avance $side\navance $side',
      ],
      itemHints: hints(
        'Le dernier bloc est en trop.',
        'The last block is the extra one.',
        'Enlève-le, et ton programme revient comme avant.',
        'Take it out, and your program comes back as it was.',
        spotlight: 'MOVE_FORWARD',
      ),
      paletteScope: palette,
      requireFinalPose: true,
      lookAtFr: 'Compare la longueur du deuxième trait.',
      lookAtEn: 'Compare how long the second line is.',
    ));
  }

  // T1 — start over from a target. "Recommencer" as a thing you may do on purpose.
  for (final pair in [
    [50, 90],
    [60, 120],
    [40, 90],
    [70, 60],
  ]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C0.4',
      difficulty: Difficulty.d2,
      solution: 'avance ${pair[0]}\ntournedroite ${pair[1]}\navance ${pair[0]}',
      promptKeys: fillBoth(
        b('Efface tout. Refais deux traits de {a} pas.',
            'Clear everything. Draw two lines of {a} steps again.'),
        {'a': pair[0]},
      ),
      wrong: [
        'avance ${pair[0]}',
        'avance ${pair[0]}\ntournedroite ${pair[1]}',
        'avance ${pair[0]}\navance ${pair[0]}',
      ],
      itemHints: hints(
        'Recommencer ne casse rien : tu peux repartir de zéro.',
        'Starting over breaks nothing: you can begin again.',
        'Deux traits, avec un tour entre les deux.',
        'Two lines, with one turn between them.',
      ),
      paletteScope: palette,
      requireFinalPose: true,
      lookAtFr: 'Compte les traits.',
      lookAtEn: 'Count the lines.',
    ));
  }

  // T4 — fill the gap: put back the block that was removed.
  for (final pair in [
    [60, 90],
    [50, 120],
    [70, 60],
  ]) {
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C0.4',
      difficulty: Difficulty.d2,
      withHoles: 'avance ${pair[0]}\n___\navance ${pair[0]}',
      solution: 'avance ${pair[0]}\ntournedroite ${pair[1]}\navance ${pair[0]}',
      promptKeys: fillBoth(
        b('Un bloc a été enlevé. Remets celui qui tourne de {d} degrés.',
            'A block was taken out. Put back the one that turns {d} degrees.'),
        {'d': pair[1]},
      ),
      wrong: [
        'avance ${pair[0]}\navance ${pair[0]}',
        'avance ${pair[0]}\ntournedroite ${pair[1] + 30}\navance ${pair[0]}',
        'avance ${pair[0]}\ntournegauche ${pair[1] + 45}\navance ${pair[0]}',
      ],
      itemHints: hints(
        'Il manque le bloc du milieu.',
        'The middle block is missing.',
        'C\'est celui qui fait tourner Tika.',
        'It is the one that turns Tika.',
        spotlight: 'TURN_RIGHT',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer. The misconception, named and answered.
  for (final what in [
    'un bloc en trop',
    'un mauvais nombre',
    'un bloc enlevé'
  ]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C0.4',
      type: ItemType.t6ReadAndAnswer,
      difficulty: Difficulty.d1,
      promptKeys: b(
          'Tu as fait une erreur dans ton programme. Que peux-tu faire ?',
          'You made a mistake in your program. What can you do?'),
      choices: [
        Choice(
            labelKeys: b('Annuler, et réessayer.', 'Undo it, and try again.'),
            correct: true),
        Choice(
            labelKeys: b('Rien, le projet est fichu.',
                'Nothing, the project is ruined.'),
            correct: false,
            misconception: 'a mistake ruins the project'),
        Choice(
            labelKeys: b('Tout recommencer depuis le début, à chaque fois.',
                'Start everything from the beginning, every time.'),
            correct: false,
            misconception: 'the only repair is starting over'),
      ],
      itemHints: hints(
        'La flèche qui recule annule le dernier bloc.',
        'The back arrow undoes the last block.',
        'Tu peux l\'appuyer plusieurs fois.',
        'You can press it several times.',
      ),
      wrongChoiceFr:
          'Rien n\'est cassé. La flèche qui recule enlève ton dernier bloc, autant de fois que tu veux.',
      wrongChoiceEn:
          'Nothing is broken. The back arrow removes your last block, as many times as you like.',
      version: 1,
    ));
    if (what.isEmpty) break;
  }

  // T5 — Parsons, rebuilding after a reset.
  for (final pair in [
    [60, 90],
    [40, 120],
    [70, 90],
  ]) {
    items.add(parsons(
      id: id(),
      conceptId: 'C0.4',
      difficulty: Difficulty.d2,
      solution:
          'baissecrayon\navance ${pair[0]}\ntournedroite ${pair[1]}\navance ${pair[0]}',
      promptKeys: fillBoth(
        b('Tu as tout effacé. Remets les blocs en ordre.',
            'You cleared everything. Put the blocks back in order.'),
        {'a': pair[0]},
      ),
      wrong: [
        'lèvecrayon\navance ${pair[0]}\nbaissecrayon\ntournedroite ${pair[1]}'
            '\navance ${pair[0]}',
        'baissecrayon\navance ${pair[0]}\navance ${pair[0]}',
        'baissecrayon\ntournedroite ${pair[1]}\navance ${pair[0]}',
      ],
      itemHints: hints(
        'Baisse le crayon avant de bouger.',
        'Put the pen down before moving.',
        'Puis avance, tourne, avance.',
        'Then forward, turn, forward.',
        spotlight: 'PEN_DOWN',
      ),
      paletteScope: palette,
      requireFinalPose: true,
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

List<Tutorial> world0Tutorials() => [
      tutorialFor(
        conceptId: 'C0.1',
        conceptName: b('Faire partir un programme', 'Starting a program'),
        steps: [
          TutorialStep(
            id: 'C0.1-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b('Voici Tika. Regarde-la avancer.',
                'This is Tika. Watch her go forward.'),
            audioKeys: b('audio/fr/C0.1-s1.opus', 'audio/en/C0.1-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.canvas,
            demoProgramSource: 'avance 60',
            newIdeas: ['avance'],
          ),
          TutorialStep(
            id: 'C0.1-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b('À toi. Prends un bloc avance et pose-le.',
                'Your turn. Take a forward block and put it down.'),
            audioKeys: b('audio/fr/C0.1-s2.opus', 'audio/en/C0.1-s2.opus'),
            expectedAction: ExpectedAction.placeBlock,
            spotlight: SpotlightTarget.paletteFamilyMovement,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b('Le bloc avance est le premier de la liste.',
                'The forward block is the first one in the list.'),
          ),
          TutorialStep(
            id: 'C0.1-s3',
            beat: Beat.jeFais,
            narrationKeys: b(
                'Appuie sur le bouton vert. C\'est toi qui fais partir Tika.',
                'Press the green button. You are the one who starts Tika.'),
            audioKeys: b('audio/fr/C0.1-s3.opus', 'audio/en/C0.1-s3.opus'),
            expectedAction: ExpectedAction.runProgram,
            spotlight: SpotlightTarget.runButton,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b('Le bouton vert est en bas de l\'écran.',
                'The green button is at the bottom of the screen.'),
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C0.2',
        conceptName: b('Les blocs ont un ordre', 'Blocks have an order'),
        steps: [
          TutorialStep(
            id: 'C0.2-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b('Regarde. Avance puis tourne puis avance encore.',
                'Watch. Forward then turn then forward again.'),
            audioKeys: b('audio/fr/C0.2-s1.opus', 'audio/en/C0.2-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.canvas,
            demoProgramSource: 'avance 60\ntournedroite 90\navance 40',
            newIdeas: ['ordre'],
          ),
          TutorialStep(
            id: 'C0.2-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b(
                'À toi. Pose un bloc tourner entre les deux avance.',
                'Your turn. Put a turn block between the two forwards.'),
            audioKeys: b('audio/fr/C0.2-s2.opus', 'audio/en/C0.2-s2.opus'),
            expectedAction: ExpectedAction.placeBlock,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'TURN_RIGHT'),
            retryHintKeys: b('Pose-le entre les deux blocs avance.',
                'Put it between the two forward blocks.'),
          ),
          TutorialStep(
            id: 'C0.2-s3',
            beat: Beat.jeFais,
            narrationKeys: b(
                'Échange les deux premiers blocs. Regarde le coin bouger.',
                'Swap the first two blocks. Watch the corner move.'),
            audioKeys: b('audio/fr/C0.2-s3.opus', 'audio/en/C0.2-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition:
                const SuccessCondition(opcodeId: 'MOVE_FORWARD', minCount: 2),
            retryHintKeys: b('Fais glisser le bloc du haut vers le bas.',
                'Drag the top block down.'),
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C0.3',
        conceptName: b('Un bloc après l\'autre', 'One block after another'),
        steps: [
          TutorialStep(
            id: 'C0.3-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b('Regarde le bloc allumé. Il descend, un par un.',
                'Watch the lit block. It goes down, one by one.'),
            audioKeys: b('audio/fr/C0.3-s1.opus', 'audio/en/C0.3-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.scriptArea,
            demoProgramSource:
                'avance 40\ntournedroite 90\navance 40\ntournegauche 90',
            newIdeas: ['un après l\'autre'],
          ),
          TutorialStep(
            id: 'C0.3-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b('Appuie sur pas à pas. Un bloc à chaque appui.',
                'Press step. One block each press.'),
            audioKeys: b('audio/fr/C0.3-s2.opus', 'audio/en/C0.3-s2.opus'),
            expectedAction: ExpectedAction.runProgram,
            spotlight: SpotlightTarget.runButton,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b('Le bouton pas à pas est à côté du vert.',
                'The step button is next to the green one.'),
          ),
          TutorialStep(
            id: 'C0.3-s3',
            beat: Beat.jeFais,
            narrationKeys: b('Fais monter Tika de deux marches.',
                'Make Tika climb two steps.'),
            audioKeys: b('audio/fr/C0.3-s3.opus', 'audio/en/C0.3-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'TURN_LEFT'),
            retryHintKeys: b(
                'Une marche : monte, tourne, avance, retourne-toi.',
                'One step: up, turn, along, turn back.'),
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C0.4',
        conceptName: b('On peut toujours annuler', 'You can always undo'),
        steps: [
          TutorialStep(
            id: 'C0.4-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b('Regarde. Un bloc de trop. Puis il s\'en va.',
                'Watch. One block too many. Then it goes away.'),
            audioKeys: b('audio/fr/C0.4-s1.opus', 'audio/en/C0.4-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.scriptArea,
            demoProgramSource: 'avance 60\ntournedroite 90\navance 60',
            newIdeas: ['annuler'],
          ),
          TutorialStep(
            id: 'C0.4-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b(
                'Pose un bloc, puis appuie sur la flèche qui recule.',
                'Put a block down, then press the back arrow.'),
            audioKeys: b('audio/fr/C0.4-s2.opus', 'audio/en/C0.4-s2.opus'),
            expectedAction: ExpectedAction.placeBlock,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b('La flèche qui recule est en haut.',
                'The back arrow is at the top.'),
          ),
          TutorialStep(
            id: 'C0.4-s3',
            beat: Beat.jeFais,
            narrationKeys: b('Fais une erreur exprès. Puis annule-la.',
                'Make a mistake on purpose. Then undo it.'),
            audioKeys: b('audio/fr/C0.4-s3.opus', 'audio/en/C0.4-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b('Tu peux appuyer sur la flèche plusieurs fois.',
                'You can press the arrow several times.'),
          ),
        ],
      ),
    ];

// ---------------------------------------------------------------------------------------

void main() {
  final items = [
    ...conceptC01(),
    ...conceptC02(),
    ...conceptC03(),
    ...conceptC04(),
  ];
  final tutorials = world0Tutorials();

  stdout.writeln(
      'World 0 — authored ${items.length} items, ${tutorials.length} tutorials');

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

  const committed = {'C0.1': 18, 'C0.2': 20, 'C0.3': 18, 'C0.4': 18};
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
    world: 0,
    version: 1,
    nameKeys: b('Bonjour Tika', 'Hello Tika'),
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
    assetKeys: const ['art/tika.svg', 'art/world0-plage.svg'],
  );

  final encoded = const JsonEncoder.withIndent('  ').convert(pack.toJson());
  final sized = ContentPack.fromJson({
    ...pack.toJson(),
    'sizeBytes': utf8.encode(encoded).length,
  });
  final manifest = PackManifest.of(sized);

  final dir = Directory('../../content');
  dir.createSync(recursive: true);
  File('${dir.path}/world0.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sized.toJson())}\n');
  File('${dir.path}/world0.manifest.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n');

  stdout.writeln('\nPublished content/world0.json');
  stdout.writeln(
      '  ${sized.sizeBytes} bytes of ${ContentPack.worldBudgetBytes} budget '
      '(${(sized.sizeBytes / ContentPack.worldBudgetBytes * 100).toStringAsFixed(1)} %)');
  stdout.writeln('  sha256 ${manifest.contentHash.substring(0, 16)}…');
  stdout.writeln('  audio keys: ${sized.audioKeys.length}');
}
