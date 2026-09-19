// Authors World 4 — "Le plan" — and writes it out as a content pack.
//
//     dart tool/author_world4.dart
//
// World 4 is the first world in which Tika stops being steered and starts being SENT. Up
// to here a child says "go forward, turn right"; from here they say "be at 300, 120".
// That is the whole of the world and it is also the whole of its difficulty: a coordinate
// is not a movement, and the four misconceptions in the ledger are four ways of hearing it
// as one.
//
// The canvas is 400 x 400, the centre is (200, 200), and y grows DOWNWARD — which is what
// every screen does and what no school graph does. Nothing here hides that; the items
// teach it by making the child land on a named spot and look.

import 'dart:convert';
import 'dart:io';

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';


Map<String, String> b(String fr, String en) => {'fr': fr, 'en': en};

/// The five concepts of World 4, from the concept ledger.
const conceptGraph = <String, List<String>>{
  'C4.1': ['C3.1'],
  'C4.2': ['C4.1'],
  'C4.3': ['C4.1'],
  'C4.4': ['C1.3'],
  'C4.5': ['C4.1'],
};

const palette = [
  'MOVE_FORWARD',
  'MOVE_BACK',
  'TURN_LEFT',
  'TURN_RIGHT',
  'SET_DIRECTION',
  'GET_DIRECTION',
  'CENTER',
  'GO',
  'GO_X',
  'GO_Y',
  'POSITION_X',
  'POSITION_Y',
  'PEN_UP',
  'PEN_DOWN',
  'CLEAR',
  'REPEAT',
  'PRINT',
];

/// A short mark at a named place.
///
/// **No pen handling, and that is the point.** The first draft of this world wrapped every
/// jump in `lèvecrayon` / `baissecrayon` out of habit from World 3, and the publish gate
/// refused thirty items whose "wrong" answers passed — because `va`, `vax`, `vay` and
/// `centre` are JUMPS and a jump never draws, pen or no pen. A distractor that forgets the
/// pen is not a wrong answer here; it is the same answer, written longer.
///
/// So World 4's distractors are all geometric: wrong coordinates, swapped axes, a relative
/// move where an absolute one was asked for, a missing mark. Ink is the only thing that
/// can differ, so ink is the only thing the wrong answers differ in.
String markAt(int x, int y, {int size = 30}) => 'va $x, $y\navance $size';

// ═══════════════════════════════════════════════════════════════════════════════════════
// C4.1 — Aller à x, y. Misconception: "x,y is counted from the turtle".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC41() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C4.1-${(++n).toString().padLeft(2, '0')}';

  // T1 — land on a named spot and make one mark there.
  for (final spot in [
    [300, 120],
    [100, 300],
    [340, 340],
    [60, 60],
    [200, 340],
    [320, 200],
  ]) {
    final x = spot[0], y = spot[1];
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C4.1',
      difficulty: (x - 200).abs() + (y - 200).abs() < 150
          ? Difficulty.d1
          : Difficulty.d2,
      solution: markAt(x, y),
      promptKeys: fillBoth(
        b('Va au point ({x} ; {y}), puis fais une marque de 30 pas.',
            'Go to the point ({x}, {y}), then make a 30-step mark.'),
        {'x': x, 'y': y},
      ),
      wrong: [
        /* The misconception itself: the child reads (x, y) as "x to the right and y down
           from where I am" and moves by that much instead of going there. */
        'avance $y\ntournedroite 90\navance $x\navance 30',
        // On the spot, but the mark drawn the wrong way round.
        'va $x, $y\ntournedroite 90\navance 30',
        /* The two numbers swapped — except on the diagonal, where swapping them changes
           nothing at all and the "wrong" answer would be the right one. */
        if (x != y) markAt(y, x) else markAt(x, y - 80),
      ],
      itemHints: hints(
        'Le premier nombre est la distance depuis le bord gauche.',
        'The first number is the distance from the left edge.',
        'Le deuxième est la distance depuis le haut. Le point ne dépend pas '
            'de l\'endroit où Tika se trouve.',
        'The second is the distance from the top. The point does not depend on '
            'where Tika happens to be.',
        spotlight: 'GO',
      ),
      lookAtFr: 'Regarde où la marque commence.',
      lookAtEn: 'Look at where the mark starts.',
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T1 — two marks, so the child sees the destination does not depend on the departure.
  for (final pair in [
    [
      [120, 120],
      [280, 280]
    ],
    [
      [300, 100],
      [100, 300]
    ],
    [
      [80, 200],
      [320, 200]
    ],
  ]) {
    final a = pair[0], c = pair[1];
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C4.1',
      difficulty: Difficulty.d3,
      solution: '${markAt(a[0], a[1])}\n${markAt(c[0], c[1])}',
      promptKeys: fillBoth(
        b('Fais une marque de 30 pas en ({ax} ; {ay}), puis une autre en '
            '({cx} ; {cy}).',
            'Make a 30-step mark at ({ax}, {ay}), then another at ({cx}, {cy}).'),
        {'ax': a[0], 'ay': a[1], 'cx': c[0], 'cy': c[1]},
      ),
      wrong: [
        // One mark instead of two.
        markAt(a[0], a[1]),
        /* The second mark on the wrong spot. Swapping its axes is the natural distractor
           and it is void on the diagonal, where the swap changes nothing — so a shifted
           point is used there instead. */
        c[0] == c[1]
            ? '${markAt(a[0], a[1])}\n${markAt(c[0], c[1] - 80)}'
            : '${markAt(a[0], a[1])}\n${markAt(c[1], c[0])}',
        // Both marks in the same place.
        '${markAt(a[0], a[1])}\n${markAt(a[0], a[1])}',
      ],
      itemHints: hints(
        'Chaque marque part de son propre point.',
        'Each mark starts from its own point.',
        'Deux blocs va, un par marque.',
        'Two go-to blocks, one per mark.',
        spotlight: 'GO',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T2 — the bug is the misconception, written out.
  for (final spot in [
    [300, 120],
    [120, 280],
    [340, 60],
    [60, 340],
  ]) {
    final x = spot[0], y = spot[1];
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C4.1',
      difficulty: Difficulty.d2,
      broken: 'avance $y\ntournedroite 90\navance $x\navance 30',
      solution: markAt(x, y),
      promptKeys: fillBoth(
        b('La marque doit commencer exactement en ({x} ; {y}). Répare.',
            'The mark must start exactly at ({x}, {y}). Fix it.'),
        {'x': x, 'y': y},
      ),
      wrong: [
        'avance $y\ntournedroite 90\navance $x\navance 30',
        if (x != y) markAt(y, x) else markAt(x + 60, y),
        markAt(x, y + 50),
      ],
      itemHints: hints(
        'Avancer et tourner ne mène pas à un point nommé.',
        'Moving and turning does not lead to a named point.',
        'Il y a un bloc qui va DIRECTEMENT à un point.',
        'There is a block that goes STRAIGHT to a point.',
        spotlight: 'GO',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  /* T3 — predict where Tika ends up.
     
     Every set has x different from y, and that is a rule rather than a coincidence: the
     first distractor is the point with its axes swapped, and on a point like (350 ; 350)
     the swap is the right answer wearing the wrong label. Two of these sets shipped that
     way until the publish gate learned to compare an item's choices with each other. */
  for (final entry in [
    ('va 300, 100', 300, 100),
    ('avance 50\nva 120, 260', 120, 260),
    ('va 50, 50\nva 350, 120', 350, 120),
    ('va 200, 200\ntournedroite 90\nva 300, 80', 300, 80),
  ]) {
    final source = entry.$1, x = entry.$2, y = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C4.1',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Où Tika se trouve-t-elle à la fin ?\n\n{p}',
            'Where does Tika end up?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b('($x ; $y)', '($x, $y)'), correct: true),
        Choice(
            labelKeys: b('($y ; $x)', '($y, $x)'),
            correct: false,
            misconception: 'C4.1-axes-swapped'),
        Choice(
            labelKeys: b('(${200 + x} ; ${200 + y})', '(${200 + x}, ${200 + y})'),
            correct: false,
            misconception: 'C4.1-relative-to-turtle'),
        Choice(
            labelKeys: b('(200 ; 200)', '(200, 200)'),
            correct: false,
            misconception: 'C4.1-go-does-nothing'),
      ],
      itemHints: hints(
        'Le dernier « va » décide.',
        'The last "go to" decides.',
        'Un point est un endroit de la feuille, pas une distance.',
        'A point is a place on the paper, not a distance.',
      ),
      wrongChoiceFr: 'Aller à un point mène à ce point, d\'où qu\'on parte.',
      wrongChoiceEn: 'Going to a point lands on that point, wherever you started.',
    ));
  }

  // T4 — fill the gap.
  for (final spot in [
    [300, 120],
    [100, 320],
    [260, 60],
    [340, 240],
  ]) {
    final x = spot[0], y = spot[1];
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C4.1',
      difficulty: Difficulty.d1,
      withHoles: 'va ___, ___\navance 30',
      solution: markAt(x, y),
      promptKeys: fillBoth(
        b('Complète pour que la marque commence en ({x} ; {y}).',
            'Fill in the blanks so the mark starts at ({x}, {y}).'),
        {'x': x, 'y': y},
      ),
      wrong: [
        if (x != y) markAt(y, x) else markAt(x, y + 40),
        markAt(x, y + 40),
        markAt(x - 40, y),
      ],
      itemHints: hints(
        'D\'abord le nombre horizontal, ensuite le vertical.',
        'The across number first, the down number second.',
        'va $x, $y.',
        'Go to $x, $y.',
        spotlight: 'GO',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T5 — Parsons: the same four lines, and only one order puts the mark in the right place.
  for (final spot in [
    [300, 120],
    [120, 300],
    [260, 300],
  ]) {
    final x = spot[0], y = spot[1];
    items.add(parsons(
      id: id(),
      conceptId: 'C4.1',
      difficulty: Difficulty.d2,
      solution: 'va $x, $y\ndirection 90\navance 30\ntournedroite 90\n'
          'avance 30',
      promptKeys: fillBoth(
        b('Remets dans l\'ordre : depuis ({x} ; {y}), un trait de 30 pas vers '
            'la droite, puis un de 30 pas vers le bas.',
            'Put these in order: from ({x}, {y}), a 30-step line to the right, '
            'then a 30-step line downwards.'),
        {'x': x, 'y': y},
      ),
      wrong: [
        // The jump last: the corner is drawn from wherever Tika started.
        'direction 90\navance 30\ntournedroite 90\navance 30\nva $x, $y',
        // The turn before the first line: both lines go downwards.
        'va $x, $y\ndirection 90\ntournedroite 90\navance 30\navance 30',
        // The two lines the other way round.
        'va $x, $y\ndirection 180\navance 30\ntournegauche 90\navance 30',
      ],
      itemHints: hints(
        'Il faut d\'abord arriver au point.',
        'You have to get to the point first.',
        'Va, pose le cap, trace, tourne, trace.',
        'Go, set the bearing, draw, turn, draw.',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C4.2 — vax / vay. Misconception: "vax also changes y".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC42() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C4.2-${(++n).toString().padLeft(2, '0')}';

  /* T1 — slide sideways and mark. Only x changes, and the proof is that the mark lands on
     the same height as the one before it. */
  for (final entry in [
    (120, 300, 40),
    (320, 100, 30),
    (60, 240, 50),
    (340, 160, 30),
    (260, 320, 40),
  ]) {
    final startX = entry.$1, y = entry.$2, slide = entry.$3;
    final solution = 'va $startX, $y\nvax ${startX + slide}\navance 30';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C4.2',
      difficulty: Difficulty.d2,
      solution: solution,
      promptKeys: fillBoth(
        b('Va en ({x} ; {y}), glisse de {d} vers la droite sans changer de '
            'hauteur, puis fais une marque de 30 pas.',
            'Go to ({x}, {y}), slide {d} to the right without changing height, '
            'then make a 30-step mark.'),
        {'x': startX, 'y': y, 'd': slide},
      ),
      wrong: [
        // The misconception: the slide moved the height too.
        'va $startX, $y\nva ${startX + slide}, ${y + slide}\navance 30',
        'va $startX, $y\nvay ${y + slide}\navance 30',
        'va $startX, $y\navance 30',
      ],
      itemHints: hints(
        'Glisser sur le côté ne change pas la hauteur.',
        'Sliding sideways does not change the height.',
        'vax ne touche qu\'au premier nombre.',
        'Go-x only touches the first number.',
        spotlight: 'GO_X',
      ),
      lookAtFr: 'Regarde la hauteur des deux points.',
      lookAtEn: 'Look at the height of the two points.',
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T1 — the same, vertically.
  for (final entry in [
    (200, 100, 120),
    (120, 320, 60),
    (300, 80, 200),
  ]) {
    final x = entry.$1, startY = entry.$2, target = entry.$3;
    final solution = 'va $x, $startY\nvay $target\navance 30';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C4.2',
      difficulty: Difficulty.d2,
      solution: solution,
      promptKeys: fillBoth(
        b('Va en ({x} ; {y}), monte ou descends jusqu\'à la hauteur {t} sans '
            'changer de côté, puis fais une marque de 30 pas.',
            'Go to ({x}, {y}), move up or down to height {t} without changing '
            'side, then make a 30-step mark.'),
        {'x': x, 'y': startY, 't': target},
      ),
      wrong: [
        'va $x, $startY\nvax $target\navance 30',
        'va $target, $startY\navance 30',
        'va $x, $startY\navance 30',
      ],
      itemHints: hints(
        'vay ne touche qu\'au deuxième nombre.',
        'Go-y only touches the second number.',
        'Le côté reste le même.',
        'The side stays the same.',
        spotlight: 'GO_Y',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  /* T2 — the bug is the misconception, written out: the child used a full `va` where one
     axis was meant, and dragged the other number along with it. */
  for (final entry in [
    (100, 200, 320),
    (300, 120, 80),
    (160, 300, 60),
  ]) {
    final x = entry.$1, y = entry.$2, target = entry.$3;
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C4.2',
      difficulty: Difficulty.d3,
      broken: 'va $x, $y\nva $target, $target\navance 30',
      solution: 'va $x, $y\nvax $target\navance 30',
      promptKeys: fillBoth(
        b('La marque doit rester à la hauteur {y}. Répare.',
            'The mark must stay at height {y}. Fix it.'),
        {'y': y},
      ),
      wrong: [
        'va $x, $y\nva $target, $target\navance 30',
        'va $x, $y\nvay $target\navance 30',
        'va $target, $y\nvay $target\navance 30',
      ],
      itemHints: hints(
        'La hauteur a changé alors qu\'elle ne devait pas.',
        'The height changed when it should not have.',
        'Un bloc ne touche qu\'au premier nombre.',
        'One block touches only the first number.',
        spotlight: 'GO_X',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  /* T3 — predict. Same rule as C4.1's: x and y always differ, because both distractors
     are built by repeating or swapping a coordinate and a point on the diagonal makes all
     three choices read the same. */
  for (final entry in [
    ('va 100, 100\nvax 300', 300, 100),
    ('va 100, 100\nvay 300', 100, 300),
    ('va 250, 250\nvax 50\nvay 350', 50, 350),
    ('va 200, 200\nvay 60\nvax 140', 140, 60),
  ]) {
    final source = entry.$1, x = entry.$2, y = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C4.2',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Où Tika se trouve-t-elle à la fin ?\n\n{p}',
            'Where does Tika end up?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b('($x ; $y)', '($x, $y)'), correct: true),
        Choice(
            labelKeys: b('($x ; $x)', '($x, $x)'),
            correct: false,
            misconception: 'C4.2-one-axis-moves-both'),
        Choice(
            labelKeys: b('($y ; $x)', '($y, $x)'),
            correct: false,
            misconception: 'C4.2-axes-swapped'),
        Choice(
            labelKeys: b('(200 ; 200)', '(200, 200)'),
            correct: false,
            misconception: 'C4.2-go-does-nothing'),
      ],
      itemHints: hints(
        'Chaque bloc ne change qu\'un seul nombre.',
        'Each block changes only one number.',
        'Suis les deux nombres séparément.',
        'Follow the two numbers separately.',
      ),
      wrongChoiceFr: 'vax change le nombre horizontal, vay le nombre vertical.',
      wrongChoiceEn: 'Go-x changes the across number, go-y the down number.',
    ));
  }

  // T4 — fill the gap.
  for (final entry in [
    (300, 'vax'),
    (80, 'vax'),
    (320, 'vay'),
    (60, 'vay'),
  ]) {
    final target = entry.$1, op = entry.$2;
    final solution = 'va 200, 200\n$op $target\navance 30';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C4.2',
      difficulty: Difficulty.d1,
      withHoles: 'va 200, 200\n___ $target\navance 30',
      solution: solution,
      promptKeys: fillBoth(
        op == 'vax'
            ? b('Complète : Tika doit glisser sur le côté jusqu\'à {t}, '
                'sans changer de hauteur.',
                'Fill in the blank: Tika slides sideways to {t}, without '
                'changing height.')
            : b('Complète : Tika doit monter ou descendre jusqu\'à {t}, '
                'sans changer de côté.',
                'Fill in the blank: Tika moves up or down to {t}, without '
                'changing side.'),
        {'t': target},
      ),
      wrong: [
        'va 200, 200\n${op == 'vax' ? 'vay' : 'vax'} $target\navance 30',
        'va 200, 200\nva $target, $target\navance 30',
        'va 200, 200\navance $target\navance 30',
      ],
      itemHints: hints(
        'Un seul des deux nombres doit changer.',
        'Only one of the two numbers should change.',
        op == 'vax' ? 'C\'est vax.' : 'C\'est vay.',
        op == 'vax' ? 'It is go-x.' : 'It is go-y.',
        spotlight: op == 'vax' ? 'GO_X' : 'GO_Y',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Tika est en (100 ; 250). Tu écris vax 400. Où est-elle ?',
        'Tika is at (100, 250). You write go-x 400. Where is she?'),
    choices: [
      Choice(labelKeys: b('(400 ; 250)', '(400, 250)'), correct: true),
      Choice(
          labelKeys: b('(400 ; 400)', '(400, 400)'),
          correct: false,
          misconception: 'C4.2-one-axis-moves-both'),
      Choice(
          labelKeys: b('(500 ; 250)', '(500, 250)'),
          correct: false,
          misconception: 'C4.2-go-is-relative'),
      Choice(
          labelKeys: b('(100 ; 400)', '(100, 400)'),
          correct: false,
          misconception: 'C4.2-axes-swapped'),
    ],
    itemHints: hints(
      'La hauteur ne bouge pas.',
      'The height does not move.',
      '250 reste 250.',
      '250 stays 250.',
    ),
    wrongChoiceFr: 'vax remplace le nombre horizontal et laisse l\'autre tel quel.',
    wrongChoiceEn: 'Go-x replaces the across number and leaves the other alone.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Quelle paire de blocs fait la même chose que va 80, 320 ?',
        'Which pair of blocks does the same thing as go to 80, 320?'),
    choices: [
      Choice(labelKeys: b('vax 80 puis vay 320', 'go-x 80 then go-y 320'),
          correct: true),
      Choice(
          labelKeys: b('vax 80 puis vax 320', 'go-x 80 then go-x 320'),
          correct: false,
          misconception: 'C4.2-one-axis-does-both'),
      Choice(
          labelKeys: b('avance 80 puis avance 320', 'forward 80 then forward 320'),
          correct: false,
          misconception: 'C4.2-go-is-move'),
      Choice(
          labelKeys: b('vay 80 puis vax 320', 'go-y 80 then go-x 320'),
          correct: false,
          misconception: 'C4.2-axes-swapped'),
    ],
    itemHints: hints(
      'Il faut poser les deux nombres, un par un.',
      'You have to set both numbers, one at a time.',
      'Le premier nombre est l\'horizontal.',
      'The first number is the across one.',
    ),
    wrongChoiceFr: 'Il faut un bloc pour chaque nombre, et dans le bon ordre.',
    wrongChoiceEn: 'One block per number, and the right number in each.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('vay laisse-t-il une trace ?', 'Does go-y leave a line?'),
    choices: [
      Choice(
          labelKeys: b('Non : c\'est un saut, comme va.',
              'No: it is a jump, like go to.'),
          correct: true),
      Choice(
          labelKeys: b('Oui, si le crayon est baissé.',
              'Yes, if the pen is down.'),
          correct: false,
          misconception: 'C4.2-jump-draws'),
      Choice(
          labelKeys: b('Oui, toujours.', 'Yes, always.'),
          correct: false,
          misconception: 'C4.2-jump-draws'),
      Choice(
          labelKeys: b('Seulement vers le bas.', 'Only downwards.'),
          correct: false,
          misconception: 'C4.2-jump-draws'),
    ],
    itemHints: hints(
      'Compare avec avance.',
      'Compare it with forward.',
      'Un saut ne dessine jamais.',
      'A jump never draws.',
    ),
    wrongChoiceFr: 'Les sauts ne dessinent jamais, même crayon baissé.',
    wrongChoiceEn: 'Jumps never draw, even with the pen down.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C4.3 — positionx / positiony.
// Misconception: "position is a command, not a value".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC43() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C4.3-${(++n).toString().padLeft(2, '0')}';

  /* T1 — write the position out. `écris positionx` is the smallest possible proof that a
     position is a VALUE: you can print it, and you cannot print a command. */
  for (final spot in [
    [300, 120],
    [80, 260],
    [240, 340],
    [160, 60],
  ]) {
    final x = spot[0], y = spot[1];
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C4.3',
      difficulty: Difficulty.d2,
      solution: 'va $x, $y\nécris positionx\nécris positiony',
      alternatives: [
        // The same two numbers set one axis at a time: same position, same output.
        'vax $x\nvay $y\nécris positionx\nécris positiony',
        '# une autre façon\nva $x, $y\nécris positionx\nécris positiony',
      ],
      promptKeys: fillBoth(
        b('Va en ({x} ; {y}) et écris les deux nombres de ta position, '
            'l\'horizontal puis le vertical.',
            'Go to ({x}, {y}) and write out both numbers of your position, '
            'across then down.'),
        {'x': x, 'y': y},
      ),
      wrong: [
        // The misconception: treating the reporter as if it were an order.
        'va $x, $y\nécris 0\nécris 0',
        'va $x, $y\nécris positiony\nécris positionx',
        'va $x, $y\nécris positionx',
      ],
      itemHints: hints(
        'positionx est un nombre, pas un ordre.',
        'Position-x is a number, not an order.',
        'Un nombre se met DANS un autre bloc — ici dans écris.',
        'A number goes INSIDE another block — here, inside write.',
        spotlight: 'POSITION_X',
      ),
      paletteScope: palette,
    ));
  }

  // T1 — use the position as a value: go back to the height you are already at.
  for (final entry in [
    (300, 120, 80),
    (100, 260, 320),
    (220, 60, 340),
  ]) {
    final x = entry.$1, y = entry.$2, otherX = entry.$3;
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C4.3',
      difficulty: Difficulty.d4,
      solution: 'va $x, $y\nva $otherX, positiony\navance 30',
      alternatives: [
        'va $x, $y\nvax $otherX\navance 30',
        '# une autre façon\nva $x, $y\nva $otherX, positiony\navance 30',
      ],
      promptKeys: fillBoth(
        b('Va en ({x} ; {y}). Puis va en {o} sur l\'horizontale, en gardant '
            'exactement la même hauteur — sans réécrire le nombre. '
            'Fais une marque de 30 pas.',
            'Go to ({x}, {y}). Then go across to {o}, keeping exactly the same '
            'height — without writing the number again. Make a 30-step mark.'),
        {'x': x, 'y': y, 'o': otherX},
      ),
      wrong: [
        'va $x, $y\nva $otherX, positionx\navance 30',
        'va $x, $y\nva $otherX, 200\navance 30',
        'va $x, $y\navance 30',
      ],
      itemHints: hints(
        'La hauteur actuelle a un nom.',
        'The current height has a name.',
        'positiony peut se mettre à la place d\'un nombre.',
        'Position-y can go wherever a number goes.',
        spotlight: 'POSITION_Y',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T4 — fill the gap.
  for (final entry in [
    ('positionx', 300),
    ('positiony', 120),
    ('positionx', 80),
  ]) {
    final op = entry.$1, other = entry.$2;
    final solution = op == 'positionx'
        ? 'va 260, 140\nva positionx, $other\navance 30'
        : 'va 260, 140\nva $other, positiony\navance 30';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C4.3',
      difficulty: Difficulty.d3,
      withHoles: op == 'positionx'
          ? 'va 260, 140\nva ___, $other\navance 30'
          : 'va 260, 140\nva $other, ___\navance 30',
      solution: solution,
      promptKeys: fillBoth(
        op == 'positionx'
            ? b('Complète : Tika garde le même côté et descend à {o}.',
                'Fill in the blank: Tika keeps the same side and moves to {o}.')
            : b('Complète : Tika garde la même hauteur et va à {o}.',
                'Fill in the blank: Tika keeps the same height and goes to {o}.'),
        {'o': other},
      ),
      wrong: [
        op == 'positionx'
            ? 'va 260, 140\nva positiony, $other\navance 30'
            : 'va 260, 140\nva $other, positionx\navance 30',
        'va 260, 140\nva 200, $other\navance 30',
        'va 260, 140\nva $other, $other\navance 30',
      ],
      itemHints: hints(
        'Il faut réutiliser un nombre que Tika connaît déjà.',
        'You need to reuse a number Tika already knows.',
        op == 'positionx' ? 'C\'est positionx.' : 'C\'est positiony.',
        op == 'positionx' ? 'It is position-x.' : 'It is position-y.',
        spotlight: op == 'positionx' ? 'POSITION_X' : 'POSITION_Y',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T3 — predict what gets written out.
  for (final entry in [
    ('va 300, 120\nécris positionx', '300'),
    ('va 300, 120\nécris positiony', '120'),
    ('va 80, 260\nvax 200\nécris positionx', '200'),
    ('va 80, 260\navance 60\nécris positiony', '200'),
  ]) {
    final source = entry.$1, answer = entry.$2;
    items.add(predict(
      id: id(),
      conceptId: 'C4.3',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Quel nombre ce programme écrit-il ?\n\n{p}',
            'Which number does this program write?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b(answer, answer), correct: true),
        Choice(
            labelKeys: b('0', '0'),
            correct: false,
            misconception: 'C4.3-reporter-is-zero'),
        /* The centre's number, as the "it is always 200" distractor — but not when the
           right answer IS 200, because then it would be a second correct choice. The
           publish gate caught exactly that on two items. */
        Choice(
            labelKeys: answer == '200' ? b('260', '260') : b('200', '200'),
            correct: false,
            misconception: 'C4.3-always-the-centre'),
        Choice(
            labelKeys: b('rien du tout', 'nothing at all'),
            correct: false,
            misconception: 'C4.3-reporter-is-command'),
      ],
      itemHints: hints(
        'Suis Tika jusqu\'à la dernière ligne.',
        'Follow Tika down to the last line.',
        'Puis lis le nombre qu\'on lui demande.',
        'Then read the number it asks her for.',
      ),
      wrongChoiceFr: 'positionx et positiony donnent la position au moment où on les lit.',
      wrongChoiceEn: 'Position-x and position-y give the position at the moment they are read.',
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait positionx tout seul, sur sa propre ligne ?',
        'What does position-x do on its own, on its own line?'),
    choices: [
      Choice(
          labelKeys: b('Rien de visible : c\'est un nombre, pas un ordre.',
              'Nothing you can see: it is a number, not an order.'),
          correct: true),
      Choice(
          labelKeys: b('Il déplace Tika sur l\'horizontale.',
              'It moves Tika across.'),
          correct: false,
          misconception: 'C4.3-reporter-is-command'),
      Choice(
          labelKeys: b('Il écrit le nombre sur la feuille.',
              'It writes the number on the paper.'),
          correct: false,
          misconception: 'C4.3-reporter-prints'),
      Choice(
          labelKeys: b('Il remet Tika au centre.', 'It sends Tika to the centre.'),
          correct: false,
          misconception: 'C4.3-reporter-is-command'),
    ],
    itemHints: hints(
      'Compare avec le nombre 50 écrit tout seul.',
      'Compare it with the number 50 written on its own.',
      'Un nombre ne fait rien : il sert à quelque chose d\'autre.',
      'A number does nothing: it is used by something else.',
    ),
    wrongChoiceFr: 'positionx donne un nombre ; il faut un bloc qui s\'en serve.',
    wrongChoiceEn: 'Position-x gives a number; something else has to use it.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Tika est en (120 ; 300). Que fait va positionx, 50 ?',
        'Tika is at (120, 300). What does go to position-x, 50 do?'),
    choices: [
      Choice(labelKeys: b('Elle va en (120 ; 50).', 'She goes to (120, 50).'),
          correct: true),
      Choice(
          labelKeys: b('Elle va en (50 ; 50).', 'She goes to (50, 50).'),
          correct: false,
          misconception: 'C4.3-reporter-unread'),
      Choice(
          labelKeys: b('Elle ne bouge pas.', 'She does not move.'),
          correct: false,
          misconception: 'C4.3-reporter-is-command'),
      Choice(
          labelKeys: b('Elle va en (300 ; 50).', 'She goes to (300, 50).'),
          correct: false,
          misconception: 'C4.3-axes-swapped'),
    ],
    itemHints: hints(
      'Remplace positionx par le nombre qu\'il vaut.',
      'Replace position-x with the number it stands for.',
      'Il vaut 120.',
      'It is 120.',
    ),
    wrongChoiceFr: 'positionx vaut le nombre horizontal actuel : 120.',
    wrongChoiceEn: 'Position-x is the current across number: 120.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Pourquoi écrire va 300, positiony plutôt que va 300, 140 ?',
        'Why write go to 300, position-y instead of go to 300, 140?'),
    choices: [
      Choice(
          labelKeys: b('Parce que ça marche où que Tika se trouve.',
              'Because it works wherever Tika happens to be.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que c\'est plus rapide.', 'Because it is faster.'),
          correct: false,
          misconception: 'C4.3-speed'),
      Choice(
          labelKeys: b('Parce que 140 est interdit.', 'Because 140 is not allowed.'),
          correct: false,
          misconception: 'C4.3-reporter-required'),
      Choice(
          labelKeys: b('Il n\'y a pas de différence.', 'There is no difference.'),
          correct: false,
          misconception: 'C4.3-reporter-is-decoration'),
    ],
    itemHints: hints(
      'Imagine que Tika soit ailleurs au départ.',
      'Imagine Tika starting somewhere else.',
      'Un nombre écrit à la main ne suit pas.',
      'A number written by hand does not follow.',
    ),
    wrongChoiceFr: 'Un nombre écrit à la main ne vaut que pour un seul départ.',
    wrongChoiceEn: 'A hand-written number is only right for one starting place.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.3',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d4,
    promptKeys: b(
      'Fatou veut un trait horizontal qui parte de là où Tika est déjà. '
          'Que met-elle comme deuxième nombre ?',
      'Fatou wants a horizontal line starting from wherever Tika already is. '
          'What does she put as the second number?',
    ),
    choices: [
      Choice(
          labelKeys: b('positiony, pour garder la hauteur actuelle.',
              'Position-y, to keep the current height.'),
          correct: true),
      Choice(
          labelKeys: b('200, parce que c\'est le milieu.',
              '200, because that is the middle.'),
          correct: false,
          misconception: 'C4.3-guess-the-number'),
      Choice(
          labelKeys: b('positionx, parce que c\'est horizontal.',
              'Position-x, because the line is horizontal.'),
          correct: false,
          misconception: 'C4.3-axes-swapped'),
      Choice(
          labelKeys: b('0, pour ne rien changer.', '0, to change nothing.'),
          correct: false,
          misconception: 'C4.3-zero-means-unchanged'),
    ],
    itemHints: hints(
      'Un trait horizontal garde la même hauteur.',
      'A horizontal line keeps the same height.',
      'La hauteur actuelle, c\'est positiony.',
      'The current height is position-y.',
    ),
    wrongChoiceFr: 'Le deuxième nombre est la hauteur, et la hauteur actuelle est positiony.',
    wrongChoiceEn: 'The second number is the height, and the current height is position-y.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.3',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d4,
    promptKeys: b(
      'Pourquoi peut-on écrire va positionx, positiony sans que rien ne bouge ?',
      'Why can you write go to position-x, position-y and nothing moves?',
    ),
    choices: [
      Choice(
          labelKeys: b('Parce qu\'on lui demande d\'aller là où elle est déjà.',
              'Because you are asking her to go where she already is.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que les deux blocs s\'annulent.',
              'Because the two blocks cancel each other out.'),
          correct: false,
          misconception: 'C4.3-reporters-cancel'),
      Choice(
          labelKeys: b('Parce que va refuse deux nombres identiques.',
              'Because go to refuses two identical numbers.'),
          correct: false,
          misconception: 'C4.3-go-validates'),
      Choice(
          labelKeys: b('Parce que positionx vaut toujours zéro.',
              'Because position-x is always zero.'),
          correct: false,
          misconception: 'C4.3-reporter-is-zero'),
    ],
    itemHints: hints(
      'Remplace les deux blocs par leurs nombres.',
      'Replace both blocks with the numbers they stand for.',
      'Tu obtiens la position actuelle.',
      'You get the current position.',
    ),
    wrongChoiceFr: 'Les deux blocs donnent la position actuelle : la destination est le départ.',
    wrongChoiceEn: 'The two blocks give the current position: the destination is the start.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C4.4 — Direction absolue.
// Misconception: "direction and tournedroite are the same".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC44() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C4.4-${(++n).toString().padLeft(2, '0')}';

  /* T1 — point a fixed way, twice, from different headings. Absolute heading means the
     second answer is identical to the first, which a turn can never promise. */
  for (final entry in [
    (90, 60),
    (180, 60),
    (270, 60),
    (0, 60),
    (45, 50),
    (135, 50),
  ]) {
    final heading = entry.$1, length = entry.$2;
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C4.4',
      difficulty: heading % 90 == 0 ? Difficulty.d1 : Difficulty.d3,
      solution: 'tournedroite 30\ndirection $heading\navance $length',
      promptKeys: fillBoth(
        b('Tourne de 30 vers la droite, puis pointe vers {h} degrés et avance '
            'de {l}. Le trait doit être le même quoi qu\'il arrive avant.',
            'Turn 30 to the right, then point at {h} degrees and move {l}. '
            'The line must be the same whatever came before.'),
        {'h': heading, 'l': length},
      ),
      wrong: [
        // The misconception: a turn where an absolute heading was asked for.
        'tournedroite 30\ntournedroite $heading\navance $length',
        'direction $heading\navance $length\ntournedroite 30',
        'tournedroite 30\ndirection ${(heading + 90) % 360}\navance $length',
      ],
      itemHints: hints(
        'Tourner dépend d\'où on regarde déjà.',
        'Turning depends on where you are already looking.',
        'direction pose le cap, quel que soit le cap précédent.',
        'Heading sets the bearing, whatever the previous one was.',
        spotlight: 'SET_DIRECTION',
      ),
      lookAtFr: 'Regarde dans quel sens part le trait.',
      lookAtEn: 'Look at which way the line goes.',
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T1 — a cross, which only comes out right with absolute headings.
  for (final arm in [60, 80]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C4.4',
      difficulty: Difficulty.d3,
      solution: 'direction 0\navance $arm\ncentre\n'
          'direction 90\navance $arm\ncentre\n'
          'direction 180\navance $arm\ncentre\n'
          'direction 270\navance $arm',
      promptKeys: fillBoth(
        b('Depuis le centre, trace quatre branches de {a} pas : vers le haut, '
            'la droite, le bas et la gauche.',
            'From the centre, draw four arms of {a} steps: up, right, down and '
            'left.'),
        {'a': arm},
      ),
      wrong: [
        'répète 4 {\n  avance $arm\n  tournedroite 90\n}',
        'direction 0\navance $arm\ndirection 90\navance $arm\n'
            'direction 180\navance $arm\ndirection 270\navance $arm',
        'direction 0\navance $arm\ncentre\ndirection 90\navance $arm',
      ],
      itemHints: hints(
        'Chaque branche repart du centre.',
        'Each arm starts again from the centre.',
        '0 en haut, 90 à droite, 180 en bas, 270 à gauche.',
        '0 is up, 90 right, 180 down, 270 left.',
        spotlight: 'SET_DIRECTION',
      ),
      paletteScope: palette,
    ));
  }

  // T2 — a turn used where a heading was needed.
  for (final heading in [90, 180, 270, 45]) {
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C4.4',
      difficulty: Difficulty.d3,
      broken: 'tournedroite 40\ntournedroite $heading\navance 60',
      solution: 'tournedroite 40\ndirection $heading\navance 60',
      promptKeys: fillBoth(
        b('Le trait doit partir vers {h} degrés, quel que soit le tour '
            'd\'avant. Répare.',
            'The line must head at {h} degrees, whatever turn came before. '
            'Fix it.'),
        {'h': heading},
      ),
      wrong: [
        'tournedroite 40\ntournedroite $heading\navance 60',
        'direction 40\ndirection $heading\navance 60\ntournedroite 40',
        'tournedroite 40\ntournegauche $heading\navance 60',
      ],
      itemHints: hints(
        'Le tour d\'avant a décalé le cap.',
        'The turn before pushed the bearing off.',
        'Il faut poser le cap, pas en ajouter un.',
        'You need to set the bearing, not add one.',
        spotlight: 'SET_DIRECTION',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  /* T4 — fill the gap. The bearing is the hole, because a bearing is the one number in
     this world a child can reason out from the picture alone. */
  for (final entry in [
    (0, 'vers le haut', 'upwards'),
    (90, 'vers la droite', 'to the right'),
    (180, 'vers le bas', 'downwards'),
    (270, 'vers la gauche', 'to the left'),
  ]) {
    final heading = entry.$1, fr = entry.$2, en = entry.$3;
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C4.4',
      difficulty: Difficulty.d1,
      withHoles: 'tournedroite 30\ndirection ___\navance 70',
      solution: 'tournedroite 30\ndirection $heading\navance 70',
      promptKeys: fillBoth(
        b('Complète : le trait doit partir {d}.',
            'Fill in the blank: the line must go {e}.'),
        {'d': fr, 'e': en},
      ),
      wrong: [
        'tournedroite 30\ndirection ${(heading + 90) % 360}\navance 70',
        'tournedroite 30\ndirection ${(heading + 180) % 360}\navance 70',
        'tournedroite 30\ntournedroite $heading\navance 70',
      ],
      itemHints: hints(
        '0 regarde en haut, puis on tourne dans le sens des aiguilles.',
        '0 looks up, and the numbers go round clockwise.',
        '0, 90, 180, 270 : haut, droite, bas, gauche.',
        '0, 90, 180, 270: up, right, down, left.',
        spotlight: 'SET_DIRECTION',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T3 — predict the final heading.
  for (final entry in [
    ('direction 90\ntournedroite 90', 180),
    ('tournedroite 90\ndirection 90', 90),
    ('direction 270\ntournegauche 90', 180),
    ('tournedroite 45\ntournedroite 45\ndirection 0', 0),
  ]) {
    final source = entry.$1, heading = entry.$2;
    items.add(predict(
      id: id(),
      conceptId: 'C4.4',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Vers quel cap Tika regarde-t-elle à la fin ?\n\n{p}',
            'Which bearing is Tika facing at the end?\n\n{p}'),
        {'p': source},
      ),
      /* The three other quarter-turns, rather than two of them and a literal 0. A fixed
         0 collides with the answer whenever the program ends facing up, and with the
         opposite bearing whenever it ends facing down — which was true of three of these
         four sets. Every bearing here is a multiple of 90, so the three rotations are
         always distinct from each other and from the answer. */
      choices: [
        Choice(labelKeys: b('$heading', '$heading'), correct: true),
        Choice(
            labelKeys: b('${(heading + 90) % 360}', '${(heading + 90) % 360}'),
            correct: false,
            misconception: 'C4.4-heading-is-a-turn'),
        Choice(
            labelKeys: b('${(heading + 180) % 360}', '${(heading + 180) % 360}'),
            correct: false,
            misconception: 'C4.4-heading-is-opposite'),
        Choice(
            labelKeys: b('${(heading + 270) % 360}', '${(heading + 270) % 360}'),
            correct: false,
            misconception: 'C4.4-heading-turns-the-other-way'),
      ],
      itemHints: hints(
        'Un cap posé efface tout ce qui précède.',
        'A bearing that is set wipes out what came before.',
        'Un tour s\'ajoute à ce qu\'il y avait.',
        'A turn adds to what was there.',
      ),
      wrongChoiceFr: 'direction pose le cap ; tournedroite l\'augmente.',
      wrongChoiceEn: 'Heading sets the bearing; turn right adds to it.',
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Quelle est la différence entre direction 90 et tournedroite 90 ?',
        'What is the difference between heading 90 and turn right 90?'),
    choices: [
      Choice(
          labelKeys: b('L\'un pose le cap, l\'autre l\'ajoute à celui d\'avant.',
              'One sets the bearing, the other adds to the one before.'),
          correct: true),
      Choice(
          labelKeys: b('Aucune : les deux tournent de 90.',
              'None: both turn by 90.'),
          correct: false,
          misconception: 'C4.4-heading-is-a-turn'),
      Choice(
          labelKeys: b('L\'un tourne à droite, l\'autre à gauche.',
              'One turns right, the other left.'),
          correct: false,
          misconception: 'C4.4-heading-is-left'),
      Choice(
          labelKeys: b('L\'un déplace Tika, l\'autre non.',
              'One moves Tika, the other does not.'),
          correct: false,
          misconception: 'C4.4-heading-moves'),
    ],
    itemHints: hints(
      'Pense à une boussole et à un demi-tour.',
      'Think of a compass and of turning on the spot.',
      'Une boussole ne dépend pas d\'où tu regardais avant.',
      'A compass does not depend on where you were looking before.',
    ),
    wrongChoiceFr: 'Ils ne donnent le même résultat que si Tika regardait déjà vers 0.',
    wrongChoiceEn: 'They only agree when Tika was already facing 0.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Quel cap regarde vers le bas de la feuille ?',
        'Which bearing looks towards the bottom of the paper?'),
    choices: [
      Choice(labelKeys: b('180', '180'), correct: true),
      Choice(
          labelKeys: b('0', '0'),
          correct: false,
          misconception: 'C4.4-zero-is-down'),
      Choice(
          labelKeys: b('90', '90'),
          correct: false,
          misconception: 'C4.4-quarter-turns'),
      Choice(
          labelKeys: b('270', '270'),
          correct: false,
          misconception: 'C4.4-quarter-turns'),
    ],
    itemHints: hints(
      '0 regarde vers le haut.',
      '0 looks up.',
      'Le bas est à l\'opposé du haut.',
      'Down is the opposite of up.',
    ),
    wrongChoiceFr: '0 en haut, 90 à droite, 180 en bas, 270 à gauche.',
    wrongChoiceEn: '0 up, 90 right, 180 down, 270 left.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.4',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d4,
    promptKeys: b(
      'Pourquoi un dessin fait avec direction se refait pareil, même si on '
          'ajoute un tour au début ?',
      'Why does a drawing made with heading come out the same, even if you add '
          'a turn at the start?',
    ),
    choices: [
      Choice(
          labelKeys: b('Parce que chaque cap est posé, pas ajouté.',
              'Because each bearing is set, not added.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que direction remet Tika au centre.',
              'Because heading sends Tika back to the centre.'),
          correct: false,
          misconception: 'C4.4-heading-moves'),
      Choice(
          labelKeys: b('Parce que les tours sont ignorés.',
              'Because turns are ignored.'),
          correct: false,
          misconception: 'C4.4-turns-ignored'),
      Choice(
          labelKeys: b('Parce que le dessin est enregistré.',
              'Because the drawing is saved.'),
          correct: false,
          misconception: 'C4.4-magic'),
    ],
    itemHints: hints(
      'Essaie d\'ajouter un tour au début et regarde.',
      'Try adding a turn at the start and look.',
      'Le premier direction efface ce tour.',
      'The first heading wipes that turn out.',
    ),
    wrongChoiceFr: 'Le premier cap posé remplace tout tour qui précède.',
    wrongChoiceEn: 'The first bearing that is set replaces any turn before it.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C4.5 — Centre. Misconception: "centre erases the drawing".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC45() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C4.5-${(++n).toString().padLeft(2, '0')}';

  /* T1 — a star from the middle. Every arm goes back to the centre, and the drawing that
     is already there survives — which is the concept and its misconception at once. */
  for (final entry in [
    (3, 120, 60),
    (4, 90, 70),
    (6, 60, 50),
    (5, 72, 60),
  ]) {
    final arms = entry.$1, step = entry.$2, length = entry.$3;
    final solution = [
      for (var i = 0; i < arms; i++)
        'direction ${i * step}\navance $length\ncentre',
    ].join('\n');
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C4.5',
      difficulty: Difficulty.d3,
      solution: solution,
      promptKeys: fillBoth(
        b('Trace {n} branches de {l} pas qui partent toutes du centre.',
            'Draw {n} arms of {l} steps, all starting from the centre.'),
        {'n': arms, 'l': length},
      ),
      wrong: [
        // Turning instead of returning: a many-sided figure, not a star.
        'répète $arms {\n  avance $length\n  tournedroite $step\n}',
        // One arm short.
        [
          for (var i = 0; i < arms - 1; i++)
            'direction ${i * step}\navance $length\ncentre',
        ].join('\n'),
        /* No return between arms: each one starts where the last ended, so the figure
           walks away from the centre instead of radiating from it. */
        [
          for (var i = 0; i < arms; i++)
            'direction ${i * step}\navance $length',
        ].join('\n'),
      ],
      itemHints: hints(
        'Il faut revenir au centre entre deux branches.',
        'You have to come back to the centre between arms.',
        'centre est un saut : il ne laisse pas de trait de retour.',
        'Centre is a jump: it leaves no line on the way back.',
        spotlight: 'CENTER',
      ),
      lookAtFr: 'Regarde s\'il y a des traits en double.',
      lookAtEn: 'Look for doubled lines.',
      paletteScope: palette,
    ));
  }

  // T1 — the drawing survives going home.
  for (final side in [60, 80]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C4.5',
      difficulty: Difficulty.d2,
      solution: 'va 300, 300\n'
          'répète 4 {\n  avance $side\n  tournedroite 90\n}\n'
          'centre\navance 40',
      promptKeys: fillBoth(
        b('Dessine un carré de {s} pas en (300 ; 300), reviens au centre, puis '
            'fais une marque de 40 pas. Le carré doit rester.',
            'Draw a square of {s} steps at (300, 300), come back to the centre, '
            'then make a 40-step mark. The square must stay.'),
        {'s': side},
      ),
      wrong: [
        // `initialise` wipes the square, which is the misconception made visible.
        'va 300, 300\n'
            'répète 4 {\n  avance $side\n  tournedroite 90\n}\n'
            'initialise\navance 40',
        // The mark without the square.
        'centre\navance 40',
        // The square without coming back.
        'va 300, 300\n'
            'répète 4 {\n  avance $side\n  tournedroite 90\n}\navance 40',
      ],
      itemHints: hints(
        'Revenir au centre n\'efface rien.',
        'Going back to the centre erases nothing.',
        'Une des deux commandes remet tout à zéro. Ce n\'est pas centre.',
        'One of the two puts everything back. It is not centre.',
        spotlight: 'CENTER',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T3 — predict.
  for (final entry in [
    ('avance 60\ncentre\navance 40', 2, true),
    ('avance 60\nlèvecrayon\ncentre\nbaissecrayon\navance 40', 2, true),
    ('avance 60\ninitialise\navance 40', 1, false),
    ('va 300, 300\navance 60\ncentre', 2, true),
  ]) {
    final source = entry.$1, keeps = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C4.5',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Qu\'y a-t-il sur la feuille à la fin ?\n\n{p}',
            'What is on the paper at the end?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(
            labelKeys: keeps
                ? b('Tout ce qui a été dessiné est encore là.',
                    'Everything that was drawn is still there.')
                : b('Seul le dernier trait est là : tout a été remis à zéro.',
                    'Only the last line is there: everything was reset.'),
            correct: true),
        Choice(
            labelKeys: b('La feuille est vide.', 'The paper is empty.'),
            correct: false,
            misconception: 'C4.5-centre-erases'),
        Choice(
            labelKeys: b('Il ne reste que le premier trait.',
                'Only the first line is left.'),
            correct: false,
            misconception: 'C4.5-centre-erases'),
        Choice(
            labelKeys: b('Rien n\'a été dessiné du tout.',
                'Nothing was drawn at all.'),
            correct: false,
            misconception: 'C4.5-centre-stops'),
      ],
      itemHints: hints(
        'centre déplace Tika ; il ne touche pas à la feuille.',
        'Centre moves Tika; it does not touch the paper.',
        'Une des deux commandes remet tout à zéro. Ce n\'est pas centre.',
        'One of the two puts everything back. It is not centre.',
      ),
      wrongChoiceFr: 'centre est un déplacement ; il n\'efface rien.',
      wrongChoiceEn: 'Centre is a move; it erases nothing.',
    ));
  }

  // T4 — fill the gap.
  for (final length in [50, 70, 90]) {
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C4.5',
      difficulty: Difficulty.d2,
      withHoles: 'direction 90\navance $length\n___\n'
          'direction 180\navance $length',
      solution: 'direction 90\navance $length\ncentre\n'
          'direction 180\navance $length',
      promptKeys: fillBoth(
        b('Complète : les deux branches de {l} pas doivent partir du même '
            'point de départ.',
            'Fill in the blank: both {l}-step arms must start from the same '
            'starting point.'),
        {'l': length},
      ),
      wrong: [
        'direction 90\navance $length\ninitialise\n'
            'direction 180\navance $length',
        'direction 90\navance $length\nnettoietout\n'
            'direction 180\navance $length',
        'direction 90\navance $length\ndirection 180\navance $length',
      ],
      itemHints: hints(
        'Il faut revenir au point de départ.',
        'You need to go back to the starting point.',
        'Un seul bloc y va directement.',
        'One block goes straight there.',
        spotlight: 'CENTER',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  /* T2 — `initialise` where `centre` was meant. The two look alike and differ in exactly
     one way that matters: one of them takes the drawing with it. */
  for (final entry in [
    (60, 90),
    (80, 120),
    (50, 70),
  ]) {
    final first = entry.$1, second = entry.$2;
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C4.5',
      difficulty: Difficulty.d3,
      broken: 'direction 90\navance $first\ninitialise\n'
          'direction 180\navance $second',
      solution: 'direction 90\navance $first\ncentre\n'
          'direction 180\navance $second',
      promptKeys: fillBoth(
        b('Les deux branches doivent rester toutes les deux. Répare.',
            'Both arms must still be there at the end. Fix it.'),
        {'a': first, 'b': second},
      ),
      wrong: [
        'direction 90\navance $first\ninitialise\n'
            'direction 180\navance $second',
        'direction 90\navance $first\nnettoietout\n'
            'direction 180\navance $second',
        'direction 90\navance $first\ndirection 180\navance $second',
      ],
      itemHints: hints(
        'La première branche a disparu.',
        'The first arm has gone.',
        'Une des deux commandes efface la feuille. Prends l\'autre.',
        'One of the two wipes the paper. Take the other one.',
        spotlight: 'CENTER',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait centre ?', 'What does centre do?'),
    choices: [
      Choice(
          labelKeys: b('Il ramène Tika au milieu de la feuille.',
              'It brings Tika back to the middle of the paper.'),
          correct: true),
      Choice(
          labelKeys: b('Il efface le dessin et ramène Tika au milieu.',
              'It erases the drawing and brings Tika back to the middle.'),
          correct: false,
          misconception: 'C4.5-centre-erases'),
      Choice(
          labelKeys: b('Il remet aussi le cap à 0.',
              'It also sets the bearing back to 0.'),
          correct: false,
          misconception: 'C4.5-centre-resets-heading'),
      Choice(
          labelKeys: b('Il met le dessin au milieu de la feuille.',
              'It moves the drawing to the middle of the paper.'),
          correct: false,
          misconception: 'C4.5-centre-moves-drawing'),
    ],
    itemHints: hints(
      'Compare avec va 200, 200.',
      'Compare it with go to 200, 200.',
      'C\'est la même chose, en plus court.',
      'It is the same thing, written shorter.',
    ),
    wrongChoiceFr: 'centre fait exactement va 200, 200 : un déplacement, rien d\'autre.',
    wrongChoiceEn: 'Centre does exactly go to 200, 200: a move, and nothing else.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C4.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('centre laisse-t-il un trait si le crayon est baissé ?',
        'Does centre leave a line if the pen is down?'),
    choices: [
      Choice(
          labelKeys: b('Non : les sauts ne dessinent jamais.',
              'No: jumps never draw.'),
          correct: true),
      Choice(
          labelKeys: b('Oui, un trait jusqu\'au milieu.',
              'Yes, a line back to the middle.'),
          correct: false,
          misconception: 'C4.5-jump-draws'),
      Choice(
          labelKeys: b('Oui, mais seulement la première fois.',
              'Yes, but only the first time.'),
          correct: false,
          misconception: 'C4.5-jump-draws'),
      Choice(
          labelKeys: b('Cela dépend de la couleur du crayon.',
              'It depends on the pen colour.'),
          correct: false,
          misconception: 'C4.5-colour-decides'),
    ],
    itemHints: hints(
      'C\'est la même règle que va, vax et vay.',
      'It is the same rule as go to, go-x and go-y.',
      'Aucun d\'eux ne dessine.',
      'None of them draws.',
    ),
    wrongChoiceFr: 'Un saut ne dessine jamais, quel que soit l\'état du crayon.',
    wrongChoiceEn: 'A jump never draws, whatever the pen is doing.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// Tutorials — three steps each, one per beat (§7.2).
// ═══════════════════════════════════════════════════════════════════════════════════════

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

TutorialStep watchStep(String conceptId, String fr, String en, String demo,
        {required List<String> ideas,
        SpotlightTarget spotlight = SpotlightTarget.canvas}) =>
    TutorialStep(
      id: '$conceptId-s1',
      beat: Beat.jeRegarde,
      narrationKeys: b(fr, en),
      audioKeys: b('audio/fr/$conceptId-s1.opus', 'audio/en/$conceptId-s1.opus'),
      expectedAction: ExpectedAction.watch,
      spotlight: spotlight,
      demoProgramSource: demo,
      newIdeas: ideas,
    );

TutorialStep togetherStep(String conceptId, String fr, String en,
        {required String opcodeId,
        required String hintFr,
        required String hintEn,
        ExpectedAction action = ExpectedAction.placeBlock}) =>
    TutorialStep(
      id: '$conceptId-s2',
      beat: Beat.onFaitEnsemble,
      narrationKeys: b(fr, en),
      audioKeys: b('audio/fr/$conceptId-s2.opus', 'audio/en/$conceptId-s2.opus'),
      expectedAction: action,
      spotlight: SpotlightTarget.scriptArea,
      successCondition: SuccessCondition(opcodeId: opcodeId),
      retryHintKeys: b(hintFr, hintEn),
    );

TutorialStep doStep(String conceptId, String fr, String en,
        {required String opcodeId,
        required String hintFr,
        required String hintEn}) =>
    TutorialStep(
      id: '$conceptId-s3',
      beat: Beat.jeFais,
      narrationKeys: b(fr, en),
      audioKeys: b('audio/fr/$conceptId-s3.opus', 'audio/en/$conceptId-s3.opus'),
      expectedAction: ExpectedAction.buildProgram,
      spotlight: SpotlightTarget.scriptArea,
      successCondition: SuccessCondition(opcodeId: opcodeId),
      retryHintKeys: b(hintFr, hintEn),
    );

List<Tutorial> world4Tutorials() => [
      tutorialFor(
        conceptId: 'C4.1',
        conceptName: b('Aller à un point', 'Going to a point'),
        steps: [
          watchStep(
            'C4.1',
            'Regarde. Deux nombres. Tika arrive pile à cet endroit.',
            'Watch. Two numbers. Tika lands exactly on that spot.',
            'va 300, 120\navance 30',
            ideas: ['un point a deux nombres'],
          ),
          togetherStep(
            'C4.1',
            'Change le premier nombre. Tika glisse sur le côté.',
            'Change the first number. Tika slides sideways.',
            opcodeId: 'GO',
            action: ExpectedAction.editNumber,
            hintFr: 'Appuie sur le premier nombre du bloc va.',
            hintEn: 'Press the first number in the go-to block.',
          ),
          doStep(
            'C4.1',
            'Fais une marque dans un coin de la feuille.',
            'Make a mark in one corner of the paper.',
            opcodeId: 'GO',
            hintFr: 'Va au point, puis avance. Le saut ne dessine pas.',
            hintEn: 'Go to the point, then move. The jump does not draw.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C4.2',
        conceptName: b('Un nombre à la fois', 'One number at a time'),
        steps: [
          watchStep(
            'C4.2',
            'Regarde. Tika glisse sur le côté. La hauteur ne bouge pas.',
            'Watch. Tika slides sideways. The height does not move.',
            'va 100, 200\nvax 300\navance 30',
            ideas: ['un seul nombre change'],
          ),
          togetherStep(
            'C4.2',
            'À toi : place le bloc qui ne change que la hauteur.',
            'Your turn: place the block that only changes the height.',
            opcodeId: 'GO_Y',
            hintFr: 'Cherche vay dans la famille Mouvement.',
            hintEn: 'Look for go-y in the Motion family.',
          ),
          doStep(
            'C4.2',
            'Fais deux marques à la même hauteur.',
            'Make two marks at the same height.',
            opcodeId: 'GO_X',
            hintFr: 'Utilise vax pour la deuxième : la hauteur reste.',
            hintEn: 'Use go-x for the second one: the height stays.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C4.3',
        conceptName: b('Savoir où l\'on est', 'Knowing where you are'),
        steps: [
          watchStep(
            'C4.3',
            'Regarde. Tika sait où elle est. Elle peut l\'écrire.',
            'Watch. Tika knows where she is. She can write it out.',
            'va 260, 140\nécris positionx\nécris positiony',
            ideas: ['la position est un nombre'],
            spotlight: SpotlightTarget.inspector,
          ),
          togetherStep(
            'C4.3',
            'Mets positiony à la place du deuxième nombre.',
            'Put position-y where the second number goes.',
            opcodeId: 'POSITION_Y',
            hintFr: 'positiony se glisse dans le bloc va.',
            hintEn: 'Position-y slots into the go-to block.',
          ),
          doStep(
            'C4.3',
            'Trace un trait horizontal depuis là où Tika est déjà.',
            'Draw a horizontal line from wherever Tika already is.',
            opcodeId: 'POSITION_Y',
            hintFr: 'Garde la hauteur avec positiony.',
            hintEn: 'Keep the height with position-y.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C4.4',
        conceptName: b('Poser un cap', 'Setting a bearing'),
        steps: [
          watchStep(
            'C4.4',
            'Regarde. Zéro regarde en haut. Quatre-vingt-dix regarde à droite.',
            'Watch. Zero looks up. Ninety looks right.',
            'direction 0\navance 60\ncentre\ndirection 90\navance 60',
            ideas: ['le cap est absolu'],
          ),
          togetherStep(
            'C4.4',
            'Change le cap. Le trait change de sens.',
            'Change the bearing. The line changes direction.',
            opcodeId: 'SET_DIRECTION',
            action: ExpectedAction.editNumber,
            hintFr: 'Appuie sur le nombre du bloc direction.',
            hintEn: 'Press the number in the heading block.',
          ),
          doStep(
            'C4.4',
            'Trace une croix depuis le centre.',
            'Draw a cross from the centre.',
            opcodeId: 'SET_DIRECTION',
            hintFr: 'Quatre caps : 0, 90, 180, 270.',
            hintEn: 'Four bearings: 0, 90, 180, 270.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C4.5',
        conceptName: b('Revenir au milieu', 'Going back to the middle'),
        steps: [
          watchStep(
            'C4.5',
            'Regarde. Le carré reste. Tika est revenue au milieu.',
            'Watch. The square stays. Tika has come back to the middle.',
            'va 300, 300\n'
                'répète 4 {\n  avance 60\n  tournedroite 90\n}\n'
                'centre\navance 40',
            ideas: ['revenir n\'efface pas'],
          ),
          togetherStep(
            'C4.5',
            'Place le bloc qui ramène Tika au milieu.',
            'Place the block that brings Tika back to the middle.',
            opcodeId: 'CENTER',
            hintFr: 'Il s\'appelle centre.',
            hintEn: 'It is called centre.',
          ),
          doStep(
            'C4.5',
            'Trace une étoile à trois branches depuis le milieu.',
            'Draw a three-armed star from the middle.',
            opcodeId: 'CENTER',
            hintFr: 'Reviens au centre entre chaque branche.',
            hintEn: 'Come back to the centre between the arms.',
          ),
        ],
      ),
    ];

// ═══════════════════════════════════════════════════════════════════════════════════════

void main() {
  final items = [
    ...conceptC41(),
    ...conceptC42(),
    ...conceptC43(),
    ...conceptC44(),
    ...conceptC45(),
  ];
  final tutorials = world4Tutorials();

  stdout.writeln(
      'World 4 — authored ${items.length} items, ${tutorials.length} tutorials');

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

  const committed = {
    'C4.1': 22,
    'C4.2': 18,
    'C4.3': 18,
    'C4.4': 22,
    'C4.5': 18,
  };
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
    world: 4,
    version: 1,
    nameKeys: b('Le plan', 'The grid'),
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
    assetKeys: const ['art/tika.svg', 'art/world4-plan.svg'],
  );

  final encoded = const JsonEncoder.withIndent('  ').convert(pack.toJson());
  final sized = ContentPack.fromJson({
    ...pack.toJson(),
    'sizeBytes': utf8.encode(encoded).length,
  });
  final manifest = PackManifest.of(sized);

  final dir = Directory('../../content');
  dir.createSync(recursive: true);
  File('${dir.path}/world4.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sized.toJson())}\n');
  File('${dir.path}/world4.manifest.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n');

  stdout.writeln('\nPublished content/world4.json');
  stdout.writeln(
      '  ${sized.sizeBytes} bytes of ${ContentPack.worldBudgetBytes} budget '
      '(${(sized.sizeBytes / ContentPack.worldBudgetBytes * 100).toStringAsFixed(1)} %)');
  stdout.writeln('  sha256 ${manifest.contentHash.substring(0, 16)}…');
  stdout.writeln('  audio keys: ${sized.audioKeys.length}');
}
