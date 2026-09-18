// Authors World 1 — "La tortue bouge" — and writes it out as a signed content pack.
//
// This is the content pipeline of §12 in miniature: authored strings, parameterised
// numbers, and every item through M6's publish gate before it is written. Run it with
//
//     dart tool/author_world1.dart
//
// and it either produces content/world1.json or tells you which item is not publishable.
// It never writes a pack that would fail the gate, because a bank that fails the gate at
// run time fails it in front of a child.

import 'dart:convert';
import 'dart:io';

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';

Map<String, String> b(String fr, String en) => {'fr': fr, 'en': en};

/// The five concepts of World 1, from the concept ledger.
const conceptGraph = <String, List<String>>{
  'C1.1': ['C0.2'],
  'C1.2': ['C1.1'],
  'C1.3': ['C1.2'],
  'C1.4': ['C1.1'],
  'C1.5': ['C1.1'],
};

const palette = [
  'MOVE_FORWARD',
  'MOVE_BACK',
  'TURN_LEFT',
  'TURN_RIGHT',
  'PEN_UP',
  'PEN_DOWN',
  'CLEAR'
];

// ---------------------------------------------------------------------------------------
// C1.1 — Avance et recule. Misconception: "recule turns around first".
// ---------------------------------------------------------------------------------------

List<Item> conceptC11() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C1.1-${(++n).toString().padLeft(2, '0')}';

  // D1 — one straight line, several lengths. The parameter is the length; the words are
  // authored once.
  for (final length in [50, 80, 100, 120, 150, 60, 90, 110, 140]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C1.1',
      difficulty: Difficulty.d1,
      solution: 'avance $length',
      promptKeys: fillBoth(
        b('Fais avancer Tika de {n} pas.', 'Make Tika go forward {n} steps.'),
        {'n': length},
      ),
      wrong: [
        'avance ${length ~/ 2}',
        'recule $length',
        'avance ${length + 40}'
      ],
      itemHints: hints(
        'Le bloc avance fait avancer Tika tout droit.',
        'The forward block makes Tika go straight ahead.',
        'Le nombre dans le bloc dit combien de pas.',
        'The number in the block says how many steps.',
        spotlight: 'MOVE_FORWARD',
      ),
      paletteScope: palette,
      lookAtFr: 'Regarde le nombre.',
      lookAtEn: 'Look at the number.',
    ));
  }

  // D2 — out and back. This is where "recule turns around first" shows itself: if it did,
  // the turtle would not come home.
  for (final length in [60, 90, 120, 100]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C1.1',
      difficulty: Difficulty.d2,
      solution: 'avance $length\nrecule $length',
      promptKeys: fillBoth(
        b('Fais avancer Tika de {n} pas, puis reviens exactement au départ.',
            'Move Tika forward {n} steps, then come back exactly to the start.'),
        {'n': length},
      ),
      wrong: [
        'avance $length',
        'avance $length\nrecule ${length ~/ 2}',
        'avance $length\ntournedroite 180\navance $length',
      ],
      itemHints: hints(
        'Recule ramène Tika en arrière, sans la faire tourner.',
        'Back moves Tika backwards, without turning her around.',
        'Pour revenir au départ, recule du même nombre de pas.',
        'To get back to the start, go back the same number of steps.',
        spotlight: 'MOVE_BACK',
      ),
      paletteScope: palette,
      requireFinalPose: true,
      lookAtFr: 'Tika doit revenir au même endroit.',
      lookAtEn: 'Tika has to end up in the same place.',
    ));
  }

  // D2/D3 — two lines of different lengths in one direction.
  for (final pair in [
    [40, 60],
    [70, 30],
    [100, 50]
  ]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C1.1',
      difficulty: Difficulty.d3,
      solution: 'avance ${pair[0]}\navance ${pair[1]}',
      promptKeys: fillBoth(
        b('Dessine un trait de {a} pas, puis encore {b} pas.',
            'Draw a line of {a} steps, then {b} more steps.'),
        {'a': pair[0], 'b': pair[1]},
      ),
      wrong: [
        'avance ${pair[0]}',
        'avance ${pair[1]}',
        'avance ${pair[0]}\nrecule ${pair[1]}',
      ],
      requireFinalPose: true,
      itemHints: hints(
        'Deux blocs avance l\'un après l\'autre font un seul long trait.',
        'Two forward blocks one after the other make one long line.',
        'Additionne les deux nombres pour savoir la longueur.',
        'Add the two numbers to know the length.',
      ),
      paletteScope: palette,
    ));
  }

  // T3 predict, T6 read, T8 explain — the misconception, stated three ways.
  items.add(predict(
    id: id(),
    conceptId: 'C1.1',
    difficulty: Difficulty.d2,
    promptKeys: b('Où est Tika après avance 50 puis recule 50 ?',
        'Where is Tika after forward 50 then back 50?'),
    choices: [
      Choice(
          labelKeys: b('Au point de départ.', 'At the starting point.'),
          correct: true),
      Choice(
          labelKeys: b('À 100 pas du départ.', '100 steps from the start.'),
          correct: false,
          misconception: 'C1.1-back-turns-around'),
      Choice(
          labelKeys: b('À 50 pas du départ.', '50 steps from the start.'),
          correct: false,
          misconception: 'C1.1-back-does-nothing'),
    ],
    itemHints: hints(
      'Recule fait le chemin en arrière.',
      'Back retraces the path in reverse.',
      'Si tu avances puis recules d\'autant, tu reviens.',
      'If you go forward then back the same amount, you return.',
    ),
    wrongChoiceFr: 'Pas encore. Recule ne fait pas tourner Tika.',
    wrongChoiceEn: 'Not yet. Back does not turn Tika around.',
  ));

  items.add(choiceItem(
    id: id(),
    conceptId: 'C1.1',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b('Pourquoi recule 50 ne fait pas tourner Tika ?',
        'Why does back 50 not turn Tika around?'),
    choices: [
      Choice(
          labelKeys: b('Parce que recule change la place, pas la direction.',
              'Because back changes the place, not the direction.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que recule fait un demi-tour d\'abord.',
              'Because back does a half turn first.'),
          correct: false,
          misconception: 'C1.1-back-turns-around'),
      Choice(
          labelKeys: b(
              'Parce que recule ne marche pas.', 'Because back does not work.'),
          correct: false,
          misconception: 'C1.1-back-does-nothing'),
    ],
    itemHints: hints(
      'Regarde le nez de Tika avant et après.',
      'Look at where Tika is pointing before and after.',
      'Deux choses peuvent changer : la place et la direction.',
      'Two things can change: the place and the direction.',
    ),
    wrongChoiceFr:
        'Regarde encore : dans quelle direction pointe Tika à la fin ?',
    wrongChoiceEn: 'Look again: which way is Tika pointing at the end?',
  ));

  // T4, T5, T7 to reach five types, which is what §6.1 asks of every concept.
  items.add(fillTheGap(
    id: id(),
    conceptId: 'C1.1',
    difficulty: Difficulty.d1,
    withHoles: 'avance ___',
    solution: 'avance 70',
    promptKeys: b('Complète : Tika doit avancer de 70 pas.',
        'Fill it in: Tika must go forward 70 steps.'),
    wrong: ['avance 7', 'avance 700', 'recule 70'],
    itemHints: hints(
      'Le trou attend un nombre.',
      'The gap is waiting for a number.',
      'Le nombre est écrit dans la question.',
      'The number is written in the question.',
    ),
    paletteScope: palette,
  ));

  items.add(parsons(
    id: id(),
    conceptId: 'C1.1',
    difficulty: Difficulty.d2,
    solution: 'avance 40\nrecule 40\navance 80',
    promptKeys: b('Remets les blocs dans l\'ordre pour faire ce dessin.',
        'Put the blocks back in order to make this drawing.'),
    wrong: [
      'recule 40\navance 40\navance 80',
      'avance 80\navance 40\nrecule 40',
      'avance 40\navance 40\navance 80',
    ],
    itemHints: hints(
      'Commence par le bloc qui part du départ.',
      'Start with the block that leaves from the start.',
      'Tika avance, revient, puis repart plus loin.',
      'Tika goes, comes back, then goes further.',
    ),
    paletteScope: palette,
  ));

  items.add(golf(
    id: id(),
    conceptId: 'C1.1',
    difficulty: Difficulty.d4,
    solution: 'avance 120',
    budget: 1,
    promptKeys: b('Fais ce trait avec un seul bloc.',
        'Make this line with one block only.'),
    wrong: [
      'avance 60\navance 60',
      'avance 100\navance 20',
      'avance 40\navance 40\navance 40',
    ],
    itemHints: hints(
      'Un seul bloc avance suffit.',
      'One forward block is enough.',
      'Additionne les nombres que tu utilisais avant.',
      'Add up the numbers you were using before.',
    ),
    paletteScope: palette,
  ));

  items.add(fixTheBug(
    id: id(),
    conceptId: 'C1.1',
    difficulty: Difficulty.d3,
    broken: 'avance 50\navance 50',
    solution: 'avance 50\nrecule 50',
    promptKeys: b('Tika doit revenir au départ, mais elle continue. Répare.',
        'Tika should come back to the start, but she keeps going. Fix it.'),
    wrong: ['avance 50', 'recule 50\nrecule 50', 'avance 100'],
    itemHints: hints(
      'Un des deux blocs n\'est pas le bon.',
      'One of the two blocks is not the right one.',
      'Pour revenir, il faut reculer.',
      'To come back, you need to go backwards.',
      spotlight: 'MOVE_BACK',
    ),
    paletteScope: palette,
    requireFinalPose: true,
    lookAtFr: 'Tika doit finir au départ.',
    lookAtEn: 'Tika must finish at the start.',
  ));

  return items;
}

// ---------------------------------------------------------------------------------------
// C1.2 — Tourner. Misconception: "tournegauche moves the turtle".
// ---------------------------------------------------------------------------------------

List<Item> conceptC12() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C1.2-${(++n).toString().padLeft(2, '0')}';

  for (final entry in [
    [80, 90],
    [60, 90],
    [100, 90],
    [70, 90],
    [50, 90],
    [90, 90],
    [110, 90],
    [40, 90]
  ]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C1.2',
      difficulty: Difficulty.d1,
      solution:
          'avance ${entry[0]}\ntournedroite ${entry[1]}\navance ${entry[0]}',
      promptKeys: fillBoth(
        b('Dessine un coin : {n} pas, un quart de tour à droite, {n} pas.',
            'Draw a corner: {n} steps, a quarter turn right, {n} steps.'),
        {'n': entry[0]},
      ),
      wrong: [
        'avance ${entry[0]}\navance ${entry[0]}',
        'avance ${entry[0]}\ntournegauche 90\navance ${entry[0]}',
        'avance ${entry[0]}\ntournedroite 45\navance ${entry[0]}',
      ],
      itemHints: hints(
        'Tourner ne déplace pas Tika : elle pivote sur place.',
        'Turning does not move Tika: she spins where she is.',
        'Un quart de tour, c\'est 90 degrés.',
        'A quarter turn is 90 degrees.',
        spotlight: 'TURN_RIGHT',
      ),
      paletteScope: palette,
      lookAtFr: 'Regarde de quel côté ça tourne.',
      lookAtEn: 'Look at which way it turns.',
    ));
  }

  // The square, by hand. World 2 will replace this with répète, and the child will feel it.
  for (final side in [60, 80, 100, 50, 120, 90, 70, 110]) {
    final square = List.filled(4, 'avance $side\ntournedroite 90').join('\n');
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C1.2',
      difficulty: Difficulty.d3,
      solution: square,
      promptKeys: fillBoth(
        b('Dessine un carré de {n} pas de côté.',
            'Draw a square with sides of {n} steps.'),
        {'n': side},
      ),
      wrong: [
        List.filled(3, 'avance $side\ntournedroite 90').join('\n'),
        List.filled(4, 'avance $side\ntournedroite 60').join('\n'),
        List.filled(4, 'avance $side').join('\n'),
      ],
      itemHints: hints(
        'Un carré a quatre côtés égaux et quatre coins.',
        'A square has four equal sides and four corners.',
        'À chaque coin, tourne d\'un quart de tour.',
        'At every corner, turn a quarter turn.',
      ),
      paletteScope: palette,
      lookAtFr: 'Compte les côtés.',
      lookAtEn: 'Count the sides.',
    ));
  }

  items.add(predict(
    id: id(),
    conceptId: 'C1.2',
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait tournegauche 90 toute seule ?',
        'What does turnleft 90 do on its own?'),
    choices: [
      Choice(
          labelKeys: b('Tika pivote sur place. Rien n\'est dessiné.',
              'Tika spins where she is. Nothing is drawn.'),
          correct: true),
      Choice(
          labelKeys: b('Tika se déplace de 90 pas à gauche.',
              'Tika moves 90 steps to the left.'),
          correct: false,
          misconception: 'C1.2-turn-moves'),
      Choice(
          labelKeys: b('Tika dessine un trait vers la gauche.',
              'Tika draws a line to the left.'),
          correct: false,
          misconception: 'C1.2-turn-draws'),
    ],
    itemHints: hints(
      'Regarde si Tika change de place ou de direction.',
      'Look at whether Tika changes place or direction.',
      'Un seul bloc tourne : il ne fait qu\'une chose.',
      'A single turn block does only one thing.',
    ),
    wrongChoiceFr: 'Presque. Tourner change la direction, pas la place.',
    wrongChoiceEn: 'Almost. Turning changes the direction, not the place.',
  ));

  items.add(choiceItem(
    id: id(),
    conceptId: 'C1.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(
        'Combien de traits dessine ce programme : avance 50, tournedroite 90 ?',
        'How many lines does this program draw: forward 50, turnright 90?'),
    choices: [
      Choice(labelKeys: b('Un seul.', 'Just one.'), correct: true),
      Choice(
          labelKeys: b('Deux.', 'Two.'),
          correct: false,
          misconception: 'C1.2-turn-draws'),
      Choice(
          labelKeys: b('Aucun.', 'None.'),
          correct: false,
          misconception: 'C1.2-forward-does-not-draw'),
    ],
    itemHints: hints(
      'Seuls les blocs qui déplacent Tika dessinent.',
      'Only the blocks that move Tika draw.',
      'Compte les blocs avance.',
      'Count the forward blocks.',
    ),
    wrongChoiceFr: 'Compte encore : quels blocs déplacent Tika ?',
    wrongChoiceEn: 'Count again: which blocks move Tika?',
  ));

  items.add(fixTheBug(
    id: id(),
    conceptId: 'C1.2',
    difficulty: Difficulty.d3,
    broken: 'avance 80\ntournegauche 90\navance 80',
    solution: 'avance 80\ntournedroite 90\navance 80',
    promptKeys: b('Le coin part du mauvais côté. Répare.',
        'The corner goes the wrong way. Fix it.'),
    wrong: [
      'avance 80\ntournegauche 90\navance 80',
      'avance 80\navance 80',
      'avance 80\ntournedroite 180\navance 80',
    ],
    itemHints: hints(
      'Il y a deux blocs pour tourner : à gauche et à droite.',
      'There are two turn blocks: left and right.',
      'Compare avec la cible : de quel côté va le deuxième trait ?',
      'Compare with the target: which way does the second line go?',
      spotlight: 'TURN_RIGHT',
    ),
    paletteScope: palette,
  ));

  items.add(fillTheGap(
    id: id(),
    conceptId: 'C1.2',
    difficulty: Difficulty.d1,
    withHoles: 'avance 60\ntournedroite ___\navance 60',
    solution: 'avance 60\ntournedroite 90\navance 60',
    promptKeys: b('Complète pour faire un coin bien droit.',
        'Fill it in to make a square corner.'),
    wrong: [
      'avance 60\ntournedroite 45\navance 60',
      'avance 60\ntournedroite 180\navance 60',
      'avance 60\ntournedroite 30\navance 60',
    ],
    itemHints: hints(
      'Un coin bien droit, c\'est un quart de tour.',
      'A square corner is a quarter turn.',
      'Un tour complet fait 360. Un quart, c\'est 90.',
      'A full turn is 360. A quarter is 90.',
    ),
    paletteScope: palette,
  ));

  items.add(parsons(
    id: id(),
    conceptId: 'C1.2',
    difficulty: Difficulty.d2,
    solution:
        'avance 50\ntournedroite 90\navance 50\ntournedroite 90\navance 50',
    promptKeys: b('Remets dans l\'ordre pour dessiner trois côtés.',
        'Put them in order to draw three sides.'),
    wrong: [
      'tournedroite 90\navance 50\navance 50\ntournedroite 90\navance 50',
      'avance 50\navance 50\navance 50\ntournedroite 90\ntournedroite 90',
      'avance 50\ntournegauche 90\navance 50\ntournegauche 90\navance 50',
    ],
    itemHints: hints(
      'Un trait, un coin, un trait, un coin, un trait.',
      'A line, a corner, a line, a corner, a line.',
      'Chaque coin sépare deux traits.',
      'Each corner separates two lines.',
    ),
    paletteScope: palette,
  ));

  items.add(golf(
    id: id(),
    conceptId: 'C1.2',
    difficulty: Difficulty.d4,
    solution: 'avance 60\ntournedroite 90\navance 60',
    budget: 3,
    promptKeys: b('Fais ce coin avec trois blocs au maximum.',
        'Make this corner with three blocks at most.'),
    wrong: [
      'avance 30\navance 30\ntournedroite 90\navance 60',
      'avance 60\ntournedroite 45\ntournedroite 45\navance 60',
      'avance 60\ntournedroite 90\navance 30\navance 30',
    ],
    itemHints: hints(
      'Un trait se fait avec un seul bloc.',
      'One line is made with one block.',
      'Deux tours de 45 font un tour de 90 : un seul bloc suffit.',
      'Two 45 turns make one 90 turn: one block is enough.',
    ),
    paletteScope: palette,
  ));

  return items;
}

// ---------------------------------------------------------------------------------------
// C1.3 — Les degrés. Misconception: "90 degrees is a half turn".
// ---------------------------------------------------------------------------------------

List<Item> conceptC13() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C1.3-${(++n).toString().padLeft(2, '0')}';

  for (final degrees in [
    90,
    45,
    180,
    120,
    60,
    30,
    135,
    72,
    150,
    20,
    100,
    144,
    80,
    110,
    160
  ]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C1.3',
      difficulty: degrees == 90 ? Difficulty.d1 : Difficulty.d2,
      solution: 'avance 70\ntournedroite $degrees\navance 70',
      promptKeys: fillBoth(
        b('Dessine deux traits avec un tour de {d} degrés entre les deux.',
            'Draw two lines with a turn of {d} degrees between them.'),
        {'d': degrees},
      ),
      wrong: [
        'avance 70\ntournedroite ${degrees == 180 ? 90 : degrees * 2}\navance 70',
        'avance 70\ntournedroite ${(degrees / 2).round()}\navance 70',
        'avance 70\navance 70',
      ],
      itemHints: hints(
        'Un tour complet fait 360 degrés.',
        'A full turn is 360 degrees.',
        'La moitié d\'un tour fait 180 degrés, le quart fait 90.',
        'Half a turn is 180 degrees, a quarter is 90.',
      ),
      paletteScope: palette,
      lookAtFr: 'Regarde l\'angle entre les deux traits.',
      lookAtEn: 'Look at the angle between the two lines.',
    ));
  }

  items.add(choiceItem(
    id: id(),
    conceptId: 'C1.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Combien de degrés fait un demi-tour ?',
        'How many degrees is a half turn?'),
    choices: [
      Choice(labelKeys: b('180 degrés.', '180 degrees.'), correct: true),
      Choice(
          labelKeys: b('90 degrés.', '90 degrees.'),
          correct: false,
          misconception: 'C1.3-ninety-is-half'),
      Choice(
          labelKeys: b('360 degrés.', '360 degrees.'),
          correct: false,
          misconception: 'C1.3-full-is-half'),
    ],
    itemHints: hints(
      'Un tour complet fait 360 degrés.',
      'A full turn is 360 degrees.',
      'La moitié de 360, c\'est la moitié du tour.',
      'Half of 360 is half of the turn.',
    ),
    wrongChoiceFr:
        'Presque. Un tour entier fait 360, alors la moitié fait combien ?',
    wrongChoiceEn: 'Almost. A whole turn is 360, so half of it is how much?',
  ));

  items.add(choiceItem(
    id: id(),
    conceptId: 'C1.3',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b('Pourquoi tournedroite 90 fait un coin bien droit ?',
        'Why does turnright 90 make a square corner?'),
    choices: [
      Choice(
          labelKeys: b('Parce que 90 est le quart de 360.',
              'Because 90 is a quarter of 360.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que 90 est la moitié du tour.',
              'Because 90 is half of the turn.'),
          correct: false,
          misconception: 'C1.3-ninety-is-half'),
      Choice(
          labelKeys: b('Parce que 90 est un grand nombre.',
              'Because 90 is a big number.'),
          correct: false,
          misconception: 'C1.3-degrees-are-arbitrary'),
    ],
    itemHints: hints(
      'Combien de coins droits pour faire un tour complet ?',
      'How many square corners make a full turn?',
      'Quatre coins droits font un tour : 4 fois 90 font 360.',
      'Four square corners make a turn: 4 times 90 is 360.',
    ),
    wrongChoiceFr: 'Compte : quatre coins droits font un tour complet.',
    wrongChoiceEn: 'Count: four square corners make one full turn.',
  ));

  items.add(predict(
    id: id(),
    conceptId: 'C1.3',
    difficulty: Difficulty.d3,
    promptKeys: b('Après tournedroite 180, où pointe Tika ?',
        'After turnright 180, where is Tika pointing?'),
    choices: [
      Choice(
          labelKeys: b('Exactement à l\'opposé.', 'Exactly the opposite way.'),
          correct: true),
      Choice(
          labelKeys: b('Sur le côté.', 'To the side.'),
          correct: false,
          misconception: 'C1.3-ninety-is-half'),
      Choice(
          labelKeys: b('Au même endroit qu\'avant.', 'The same way as before.'),
          correct: false,
          misconception: 'C1.3-full-is-half'),
    ],
    itemHints: hints(
      '180, c\'est la moitié de 360.',
      '180 is half of 360.',
      'La moitié d\'un tour te met dos à où tu allais.',
      'Half a turn puts your back to where you were going.',
    ),
    wrongChoiceFr: 'Fais le tour avec ton doigt : la moitié, c\'est où ?',
    wrongChoiceEn: 'Trace the turn with your finger: where is halfway?',
  ));

  items.add(fillTheGap(
    id: id(),
    conceptId: 'C1.3',
    difficulty: Difficulty.d2,
    withHoles: 'avance 70\ntournedroite ___\navance 70',
    solution: 'avance 70\ntournedroite 45\navance 70',
    promptKeys: b(
        'Complète pour faire un demi-coin, la moitié d\'un coin droit.',
        'Fill it in to make half a square corner.'),
    wrong: [
      'avance 70\ntournedroite 90\navance 70',
      'avance 70\ntournedroite 180\navance 70',
      'avance 70\ntournedroite 22\navance 70',
    ],
    itemHints: hints(
      'Un coin droit fait 90 degrés.',
      'A square corner is 90 degrees.',
      'La moitié de 90, c\'est 45.',
      'Half of 90 is 45.',
    ),
    paletteScope: palette,
  ));

  items.add(parsons(
    id: id(),
    conceptId: 'C1.3',
    difficulty: Difficulty.d3,
    solution:
        'avance 60\ntournedroite 120\navance 60\ntournedroite 120\navance 60',
    promptKeys: b('Remets dans l\'ordre pour dessiner un triangle.',
        'Put them in order to draw a triangle.'),
    wrong: [
      'tournedroite 120\navance 60\ntournedroite 120\navance 60\navance 60',
      'avance 60\ntournedroite 90\navance 60\ntournedroite 90\navance 60',
      'avance 60\navance 60\navance 60\ntournedroite 120\ntournedroite 120',
    ],
    itemHints: hints(
      'Un triangle a trois côtés et deux coins entre eux.',
      'A triangle has three sides and two corners between them.',
      'Trois fois 120 font 360 : le tour est complet.',
      'Three times 120 is 360: the turn is complete.',
    ),
    paletteScope: palette,
  ));

  return items;
}

// ---------------------------------------------------------------------------------------
// C1.4 — Le crayon dessine. Misconception: "the turtle always draws".
// ---------------------------------------------------------------------------------------

List<Item> conceptC14() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C1.4-${(++n).toString().padLeft(2, '0')}';

  for (final gap in [40, 60, 30, 50, 70, 20, 35, 45, 55, 65, 25, 80, 90]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C1.4',
      difficulty: Difficulty.d2,
      solution: 'avance 50\nlèvecrayon\navance $gap\nbaissecrayon\navance 50',
      promptKeys: fillBoth(
        b('Dessine deux traits avec un trou de {n} pas entre les deux.',
            'Draw two lines with a gap of {n} steps between them.'),
        {'n': gap},
      ),
      wrong: [
        'avance 50\navance $gap\navance 50',
        'avance 50\nlèvecrayon\navance $gap\navance 50',
        'lèvecrayon\navance 50\navance $gap\navance 50',
      ],
      itemHints: hints(
        'Lève le crayon pour que Tika avance sans dessiner.',
        'Lift the pen so Tika moves without drawing.',
        'N\'oublie pas de rebaisser le crayon après le trou.',
        'Do not forget to put the pen back down after the gap.',
        spotlight: 'PEN_UP',
      ),
      paletteScope: palette,
      lookAtFr: 'Compte les traits, et regarde le trou.',
      lookAtEn: 'Count the lines, and look at the gap.',
    ));
  }

  items.add(predict(
    id: id(),
    conceptId: 'C1.4',
    difficulty: Difficulty.d1,
    promptKeys: b('Que dessine avance 50 quand le crayon est levé ?',
        'What does forward 50 draw when the pen is up?'),
    choices: [
      Choice(labelKeys: b('Rien du tout.', 'Nothing at all.'), correct: true),
      Choice(
          labelKeys: b('Un trait, comme d\'habitude.', 'A line, as usual.'),
          correct: false,
          misconception: 'C1.4-always-draws'),
      Choice(
          labelKeys: b('Un trait en pointillés.', 'A dotted line.'),
          correct: false,
          misconception: 'C1.4-penup-dots'),
    ],
    itemHints: hints(
      'Le crayon levé ne touche pas la feuille.',
      'A lifted pen does not touch the paper.',
      'Tika bouge toujours, mais elle ne laisse pas de trace.',
      'Tika still moves, but she leaves no mark.',
    ),
    wrongChoiceFr: 'Pense à un vrai crayon levé au-dessus de la feuille.',
    wrongChoiceEn: 'Think of a real pen held above the paper.',
  ));

  items.add(choiceItem(
    id: id(),
    conceptId: 'C1.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Tika bouge-t-elle quand le crayon est levé ?',
        'Does Tika move when the pen is up?'),
    choices: [
      Choice(
          labelKeys: b('Oui, mais sans laisser de trace.',
              'Yes, but without leaving a mark.'),
          correct: true),
      Choice(
          labelKeys:
              b('Non, elle reste sur place.', 'No, she stays where she is.'),
          correct: false,
          misconception: 'C1.4-penup-stops'),
      Choice(
          labelKeys: b(
              'Oui, et elle dessine quand même.', 'Yes, and she draws anyway.'),
          correct: false,
          misconception: 'C1.4-always-draws'),
    ],
    itemHints: hints(
      'Lever le crayon change le dessin, pas le déplacement.',
      'Lifting the pen changes the drawing, not the moving.',
      'Regarde où est Tika à la fin.',
      'Look at where Tika is at the end.',
    ),
    wrongChoiceFr: 'Regarde où Tika se trouve après, pas ce qui est dessiné.',
    wrongChoiceEn: 'Look at where Tika ends up, not at what was drawn.',
  ));

  items.add(fixTheBug(
    id: id(),
    conceptId: 'C1.4',
    difficulty: Difficulty.d3,
    broken: 'avance 50\nlèvecrayon\navance 40\navance 50',
    solution: 'avance 50\nlèvecrayon\navance 40\nbaissecrayon\navance 50',
    promptKeys: b('Le deuxième trait ne se dessine pas. Répare.',
        'The second line does not get drawn. Fix it.'),
    wrong: [
      'avance 50\nlèvecrayon\navance 40\navance 50',
      'avance 50\navance 40\navance 50',
      'lèvecrayon\navance 50\navance 40\nbaissecrayon\navance 50',
    ],
    itemHints: hints(
      'Le crayon est resté levé.',
      'The pen stayed up.',
      'Il faut le baisser avant le dernier trait.',
      'You need to put it down before the last line.',
      spotlight: 'PEN_DOWN',
    ),
    paletteScope: palette,
  ));

  items.add(fillTheGap(
    id: id(),
    conceptId: 'C1.4',
    difficulty: Difficulty.d1,
    withHoles: 'avance 50\n___\navance 40\nbaissecrayon\navance 50',
    solution: 'avance 50\nlèvecrayon\navance 40\nbaissecrayon\navance 50',
    promptKeys: b('Complète pour laisser un trou au milieu.',
        'Fill it in to leave a gap in the middle.'),
    wrong: [
      'avance 50\nbaissecrayon\navance 40\nbaissecrayon\navance 50',
      'avance 50\navance 40\nbaissecrayon\navance 50',
      'avance 50\nnettoietout\navance 40\nbaissecrayon\navance 50',
    ],
    itemHints: hints(
      'Pour faire un trou, il faut lever le crayon.',
      'To make a gap, you have to lift the pen.',
      'Le bloc s\'appelle lèvecrayon.',
      'The block is called penup.',
    ),
    paletteScope: palette,
  ));

  items.add(parsons(
    id: id(),
    conceptId: 'C1.4',
    difficulty: Difficulty.d3,
    solution: 'avance 30\nlèvecrayon\navance 30\nbaissecrayon\navance 30',
    promptKeys: b('Remets dans l\'ordre pour faire un trait en pointillés.',
        'Put them in order to make a dashed line.'),
    wrong: [
      'lèvecrayon\navance 30\navance 30\nbaissecrayon\navance 30',
      'avance 30\navance 30\navance 30\nlèvecrayon\nbaissecrayon',
      'avance 30\nbaissecrayon\navance 30\nlèvecrayon\navance 30',
    ],
    itemHints: hints(
      'Un pointillé, c\'est trait, trou, trait.',
      'A dash is line, gap, line.',
      'Le crayon se lève avant le trou et se baisse après.',
      'The pen lifts before the gap and comes down after.',
    ),
    paletteScope: palette,
  ));

  return items;
}

// ---------------------------------------------------------------------------------------
// C1.5 — Nombres négatifs. Misconception: "avance -10 is an error".
// ---------------------------------------------------------------------------------------

List<Item> conceptC15() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C1.5-${(++n).toString().padLeft(2, '0')}';

  for (final length in [30, 50, 80, 40, 60, 70, 90, 100, 25, 45, 55, 65, 75]) {
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C1.5',
      difficulty: Difficulty.d2,
      solution: 'avance -$length',
      promptKeys: fillBoth(
        b('Fais reculer Tika de {n} pas, en utilisant le bloc avance.',
            'Make Tika go backwards {n} steps, using the forward block.'),
        {'n': length},
      ),
      wrong: ['avance $length', 'recule -$length', 'avance ${-length ~/ 2}'],
      itemHints: hints(
        'Un nombre négatif marche dans le bloc avance.',
        'A negative number works in the forward block.',
        'Avance moins dix fait reculer Tika de dix pas.',
        'Forward minus ten makes Tika go back ten steps.',
        spotlight: 'MOVE_FORWARD',
      ),
      alternatives: [
        'recule $length',
        '# avec un nombre négatif\navance -$length'
      ],
      paletteScope: palette,
      lookAtFr: 'Regarde de quel côté Tika part.',
      lookAtEn: 'Look at which way Tika goes.',
    ));
  }

  items.add(predict(
    id: id(),
    conceptId: 'C1.5',
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait avance -10 ?', 'What does forward -10 do?'),
    choices: [
      Choice(
          labelKeys: b('Tika recule de 10 pas.', 'Tika goes back 10 steps.'),
          correct: true),
      Choice(
          labelKeys: b('C\'est une erreur, rien ne se passe.',
              'It is an error, nothing happens.'),
          correct: false,
          misconception: 'C1.5-negative-is-error'),
      Choice(
          labelKeys: b('Tika avance de 10 pas.', 'Tika goes forward 10 steps.'),
          correct: false,
          misconception: 'C1.5-negative-ignored'),
    ],
    itemHints: hints(
      'Le signe moins change la direction.',
      'The minus sign changes the direction.',
      'Essaie-le : Tika part de l\'autre côté.',
      'Try it: Tika goes the other way.',
    ),
    wrongChoiceFr:
        'Un nombre négatif n\'est pas une erreur. Essaie-le pour voir.',
    wrongChoiceEn: 'A negative number is not an error. Try it and see.',
  ));

  items.add(choiceItem(
    id: id(),
    conceptId: 'C1.5',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d4,
    promptKeys: b('Pourquoi avance -50 et recule 50 font la même chose ?',
        'Why do forward -50 and back 50 do the same thing?'),
    choices: [
      Choice(
          labelKeys: b('Parce que le signe moins retourne la direction.',
              'Because the minus sign flips the direction.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que les deux blocs sont le même bloc.',
              'Because the two blocks are the same block.'),
          correct: false,
          misconception: 'C1.5-blocks-identical'),
      Choice(
          labelKeys: b('Parce que Tika fait un demi-tour d\'abord.',
              'Because Tika turns around first.'),
          correct: false,
          misconception: 'C1.1-back-turns-around'),
    ],
    itemHints: hints(
      'Regarde la direction du nez de Tika dans les deux cas.',
      'Look at which way Tika is pointing in both cases.',
      'Le nez ne bouge pas : seule la place change.',
      'Her nose does not move: only the place changes.',
    ),
    wrongChoiceFr: 'Regarde encore : le nez de Tika bouge-t-il ?',
    wrongChoiceEn: 'Look again: does Tika turn at all?',
  ));

  items.add(fillTheGap(
    id: id(),
    conceptId: 'C1.5',
    difficulty: Difficulty.d2,
    withHoles: 'avance ___',
    solution: 'avance -40',
    promptKeys: b('Complète pour faire reculer Tika de 40 pas.',
        'Fill it in to make Tika go back 40 steps.'),
    wrong: ['avance 40', 'avance 0', 'avance -4'],
    itemHints: hints(
      'Un nombre peut être négatif.',
      'A number can be negative.',
      'Écris le signe moins devant le nombre.',
      'Write the minus sign in front of the number.',
    ),
    paletteScope: palette,
  ));

  items.add(fixTheBug(
    id: id(),
    conceptId: 'C1.5',
    difficulty: Difficulty.d3,
    broken: 'avance 40',
    solution: 'avance -40',
    promptKeys: b('Tika part du mauvais côté. Change le nombre.',
        'Tika goes the wrong way. Change the number.'),
    wrong: ['avance 40', 'avance 0', 'avance 400'],
    itemHints: hints(
      'Le nombre est bon, mais pas son signe.',
      'The number is right, but not its sign.',
      'Mets un moins devant.',
      'Put a minus in front.',
    ),
    paletteScope: palette,
  ));

  items.add(parsons(
    id: id(),
    conceptId: 'C1.5',
    difficulty: Difficulty.d3,
    solution: 'avance 60\navance -30\ntournedroite 90\navance 60',
    promptKeys: b('Remets dans l\'ordre pour faire ce dessin.',
        'Put them in order to make this drawing.'),
    wrong: [
      'avance -30\navance 60\ntournedroite 90\navance 60',
      'avance 60\navance 30\ntournedroite 90\navance 60',
      'tournedroite 90\navance 60\navance -30\navance 60',
    ],
    itemHints: hints(
      'Tika avance, revient un peu, puis tourne.',
      'Tika goes forward, comes back a little, then turns.',
      'Le nombre négatif est le deuxième bloc.',
      'The negative number is the second block.',
    ),
    paletteScope: palette,
  ));

  return items;
}

// ---------------------------------------------------------------------------------------
// Tutorials — three steps each, the three beats of §4.2.
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

List<Tutorial> world1Tutorials() => [
      tutorialFor(
        conceptId: 'C1.1',
        conceptName: b('Avancer et reculer', 'Going forward and back'),
        steps: [
          TutorialStep(
            id: 'C1.1-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b('Regarde. Tika avance et laisse un trait.',
                'Watch. Tika moves forward and leaves a line.'),
            audioKeys: b('audio/fr/C1.1-s1.opus', 'audio/en/C1.1-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.canvas,
            demoProgramSource: 'avance 100',
            newIdeas: ['avance'],
          ),
          TutorialStep(
            id: 'C1.1-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b(
                'À toi. Mets un bloc avance et appuie sur le vert.',
                'Your turn. Add a forward block and press the green button.'),
            audioKeys: b('audio/fr/C1.1-s2.opus', 'audio/en/C1.1-s2.opus'),
            expectedAction: ExpectedAction.placeBlock,
            spotlight: SpotlightTarget.paletteFamilyMovement,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b('Le bloc avance est en haut de la palette.',
                'The forward block is at the top of the palette.'),
          ),
          TutorialStep(
            id: 'C1.1-s3',
            beat: Beat.jeFais,
            narrationKeys: b(
                'Fais avancer Tika, puis fais-la revenir au départ.',
                'Make Tika go forward, then bring her back to the start.'),
            audioKeys: b('audio/fr/C1.1-s3.opus', 'audio/en/C1.1-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_BACK'),
            retryHintKeys: b('Cherche le bloc recule, juste sous avance.',
                'Look for the back block, just under forward.'),
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C1.2',
        conceptName:
            b('Tourner à gauche et à droite', 'Turning left and right'),
        steps: [
          TutorialStep(
            id: 'C1.2-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b(
                'Regarde. Tika tourne sur place. Elle ne bouge pas.',
                'Watch. Tika turns where she is. She does not move.'),
            audioKeys: b('audio/fr/C1.2-s1.opus', 'audio/en/C1.2-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.canvas,
            demoProgramSource: 'avance 80\ntournedroite 90\navance 80',
            newIdeas: ['tournedroite'],
          ),
          TutorialStep(
            id: 'C1.2-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b('Ajoute un bloc tourne entre les deux traits.',
                'Add a turn block between the two lines.'),
            audioKeys: b('audio/fr/C1.2-s2.opus', 'audio/en/C1.2-s2.opus'),
            expectedAction: ExpectedAction.placeBlock,
            spotlight: SpotlightTarget.paletteFamilyMovement,
            successCondition: const SuccessCondition(opcodeId: 'TURN_RIGHT'),
            retryHintKeys: b('Le bloc tourne a une flèche qui fait le tour.',
                'The turn block has an arrow that goes around.'),
          ),
          TutorialStep(
            id: 'C1.2-s3',
            beat: Beat.jeFais,
            narrationKeys: b('Dessine un carré. Quatre traits, quatre coins.',
                'Draw a square. Four lines, four corners.'),
            audioKeys: b('audio/fr/C1.2-s3.opus', 'audio/en/C1.2-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition:
                const SuccessCondition(opcodeId: 'TURN_RIGHT', minCount: 4),
            retryHintKeys: b('Après chaque trait, tourne d\'un quart de tour.',
                'After each line, turn a quarter turn.'),
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C1.3',
        conceptName: b('Les degrés', 'Degrees'),
        steps: [
          TutorialStep(
            id: 'C1.3-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b('Regarde. Un tour complet fait 360 degrés.',
                'Watch. A full turn is 360 degrees.'),
            audioKeys: b('audio/fr/C1.3-s1.opus', 'audio/en/C1.3-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.canvas,
            demoProgramSource:
                'tournedroite 90\ntournedroite 90\ntournedroite 90\ntournedroite 90',
            newIdeas: ['degrés'],
          ),
          TutorialStep(
            id: 'C1.3-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b('Change le nombre pour faire un demi-tour.',
                'Change the number to make a half turn.'),
            audioKeys: b('audio/fr/C1.3-s2.opus', 'audio/en/C1.3-s2.opus'),
            expectedAction: ExpectedAction.editNumber,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'TURN_RIGHT'),
            retryHintKeys:
                b('La moitié de 360, c\'est 180.', 'Half of 360 is 180.'),
          ),
          TutorialStep(
            id: 'C1.3-s3',
            beat: Beat.jeFais,
            narrationKeys: b(
                'Dessine un triangle. Chaque coin fait 120 degrés.',
                'Draw a triangle. Each corner is 120 degrees.'),
            audioKeys: b('audio/fr/C1.3-s3.opus', 'audio/en/C1.3-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition:
                const SuccessCondition(opcodeId: 'TURN_RIGHT', minCount: 2),
            retryHintKeys: b('Trois fois 120 font 360 : le tour est complet.',
                'Three times 120 is 360: the turn is complete.'),
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C1.4',
        conceptName:
            b('Lever et baisser le crayon', 'Lifting and lowering the pen'),
        steps: [
          TutorialStep(
            id: 'C1.4-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b(
                'Regarde. Le crayon est levé. Tika ne dessine plus.',
                'Watch. The pen is up. Tika stops drawing.'),
            audioKeys: b('audio/fr/C1.4-s1.opus', 'audio/en/C1.4-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.canvas,
            demoProgramSource:
                'avance 50\nlèvecrayon\navance 50\nbaissecrayon\navance 50',
            newIdeas: ['lèvecrayon', 'baissecrayon'],
          ),
          TutorialStep(
            id: 'C1.4-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b('Mets le bloc qui lève le crayon.',
                'Add the block that lifts the pen.'),
            audioKeys: b('audio/fr/C1.4-s2.opus', 'audio/en/C1.4-s2.opus'),
            expectedAction: ExpectedAction.placeBlock,
            spotlight: SpotlightTarget.paletteFamilyPen,
            successCondition: const SuccessCondition(opcodeId: 'PEN_UP'),
            retryHintKeys: b('Les blocs du crayon sont dans la famille Stylo.',
                'The pen blocks are in the Pen family.'),
          ),
          TutorialStep(
            id: 'C1.4-s3',
            beat: Beat.jeFais,
            narrationKeys: b('Dessine deux traits avec un trou entre les deux.',
                'Draw two lines with a gap between them.'),
            audioKeys: b('audio/fr/C1.4-s3.opus', 'audio/en/C1.4-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'PEN_DOWN'),
            retryHintKeys: b('Après le trou, rebaisse le crayon.',
                'After the gap, put the pen back down.'),
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C1.5',
        conceptName: b('Les nombres négatifs', 'Negative numbers'),
        steps: [
          TutorialStep(
            id: 'C1.5-s1',
            beat: Beat.jeRegarde,
            narrationKeys: b(
                'Regarde. Avance moins cinquante fait reculer Tika.',
                'Watch. Forward minus fifty makes Tika go backwards.'),
            audioKeys: b('audio/fr/C1.5-s1.opus', 'audio/en/C1.5-s1.opus'),
            expectedAction: ExpectedAction.watch,
            spotlight: SpotlightTarget.canvas,
            demoProgramSource: 'avance -50',
            newIdeas: ['nombre négatif'],
          ),
          TutorialStep(
            id: 'C1.5-s2',
            beat: Beat.onFaitEnsemble,
            narrationKeys: b('Mets un moins devant le nombre, puis lance.',
                'Put a minus in front of the number, then run it.'),
            audioKeys: b('audio/fr/C1.5-s2.opus', 'audio/en/C1.5-s2.opus'),
            expectedAction: ExpectedAction.editNumber,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b('Le moins s\'écrit juste devant le chiffre.',
                'The minus goes right in front of the number.'),
          ),
          TutorialStep(
            id: 'C1.5-s3',
            beat: Beat.jeFais,
            narrationKeys: b('Fais reculer Tika sans utiliser le bloc recule.',
                'Make Tika go backwards without using the back block.'),
            audioKeys: b('audio/fr/C1.5-s3.opus', 'audio/en/C1.5-s3.opus'),
            expectedAction: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.scriptArea,
            successCondition: const SuccessCondition(opcodeId: 'MOVE_FORWARD'),
            retryHintKeys: b('Un nombre négatif dans avance fait reculer.',
                'A negative number in forward goes backwards.'),
          ),
        ],
      ),
    ];

// ---------------------------------------------------------------------------------------

void main() {
  final items = [
    ...conceptC11(),
    ...conceptC12(),
    ...conceptC13(),
    ...conceptC14(),
    ...conceptC15(),
  ];
  final tutorials = world1Tutorials();

  stdout.writeln(
      'World 1 — authored ${items.length} items, ${tutorials.length} tutorials');

  // ---- the publish gate, before anything is written ------------------------------------
  final itemFailures = checkBank(items);
  final tutorialFailures = [
    for (final t in tutorials) ...checkTutorial(t),
  ];

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

  // ---- coverage the curriculum commits to ----------------------------------------------
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
  }

  final pack = ContentPack(
    world: 1,
    version: 1,
    nameKeys: b('La tortue bouge', 'The turtle moves'),
    concepts: conceptGraph,
    tutorials: tutorials,
    items: items,
    // Every item prompt is recorded in both languages. `FR-M18-02` makes this a publish
    // gate, and a seven-year-old at the start of World 1 is still reading slowly enough
    // that a prompt they can only see is a prompt they may skip.
    itemAudioKeys: {
      for (final item in items)
        item.id: {
          for (final locale in requiredLocales) locale: 'audio/$locale/${item.id}.opus',
        },
    },
    audioKeys: [
      for (final t in tutorials)
        for (final s in t.steps) ...s.audioKeys.values,
      for (final item in items)
        for (final locale in requiredLocales) 'audio/$locale/${item.id}.opus',
    ],
    assetKeys: const ['art/tika.svg', 'art/world1-island.svg'],
  );

  final encoded = const JsonEncoder.withIndent('  ').convert(pack.toJson());
  final sized = ContentPack.fromJson({
    ...pack.toJson(),
    'sizeBytes': utf8.encode(encoded).length,
  });
  final manifest = PackManifest.of(sized);

  final dir = Directory('../../content');
  dir.createSync(recursive: true);
  File('${dir.path}/world1.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sized.toJson())}\n');
  File('${dir.path}/world1.manifest.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n');

  stdout.writeln('\nPublished content/world1.json');
  stdout.writeln(
      '  ${sized.sizeBytes} bytes of ${ContentPack.worldBudgetBytes} budget '
      '(${(sized.sizeBytes / ContentPack.worldBudgetBytes * 100).toStringAsFixed(1)} %)');
  stdout.writeln('  sha256 ${manifest.contentHash.substring(0, 16)}…');
  stdout.writeln('  audio keys: ${sized.audioKeys.length}');
}
