// Authors World 3 — "Couleurs et crayon" — and writes it out as a content pack.
//
//     dart tool/author_world3.dart
//
// Same pipeline as Worlds 0, 1 and 2: authored strings, parameterised numbers, every item
// through M6's publish gate before anything is written.
//
// World 3 is the first world whose subject the grader could not originally see. Authoring
// it found three defects in the comparison — pen colour, canvas colour and canvas size
// were all recorded on the canvas and never read — and they were fixed in `kodo_stage`
// before a single item was written. That order matters: an item nobody can fail is worse
// than no item, because it teaches a child that guessing works.

import 'dart:convert';
import 'dart:io';

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';

Map<String, String> b(String fr, String en) => {'fr': fr, 'en': en};

/// The five concepts of World 3, from the concept ledger.
const conceptGraph = <String, List<String>>{
  'C3.1': ['C1.4'],
  'C3.2': ['C3.1'],
  'C3.3': ['C3.1'],
  'C3.4': ['C3.3'],
  'C3.5': ['C3.4'],
};

const palette = [
  'MOVE_FORWARD',
  'MOVE_BACK',
  'TURN_LEFT',
  'TURN_RIGHT',
  'PEN_UP',
  'PEN_DOWN',
  'PEN_WIDTH',
  'PEN_COLOR',
  'CANVAS_COLOR',
  'CANVAS_SIZE',
  'CLEAR',
  'RESET',
  'REPEAT',
  'GO',
];

/// Annex C's reference row, as a child reads it off the card. Authored here rather than
/// imported so the numbers in a prompt and the numbers on the card are the same literal
/// text — a picker that rounds and a card that does not is exactly how "RGB is
/// percentages" survives a whole world.
const rouge = '255, 0, 0';
const vert = '0, 255, 0';
const bleu = '0, 0, 255';
const jaune = '255, 255, 0';
const rose = '255, 0, 255';
const noir = '0, 0, 0';

// ═══════════════════════════════════════════════════════════════════════════════════════
// C3.1 — Lève / baisse le crayon. Misconception: "va draws a line".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC31() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C3.1-${(++n).toString().padLeft(2, '0')}';

  /* T1 — a dashed line. The pen goes up between the dashes, which is the only way to
     leave a gap: a child who has only met `avance` cannot draw one at all. */
  for (final pair in [
    [3, 40, 20],
    [4, 30, 15],
    [5, 24, 12],
    [6, 20, 10],
  ]) {
    final times = pair[0], dash = pair[1], gap = pair[2];
    final solution = 'répète $times {\n  baissecrayon\n  avance $dash\n'
        '  lèvecrayon\n  avance $gap\n}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C3.1',
      difficulty: times <= 4 ? Difficulty.d1 : Difficulty.d2,
      solution: solution,
      promptKeys: fillBoth(
        b('Dessine {n} traits de {d} pas, avec {g} pas de vide entre eux.',
            'Draw {n} dashes of {d} steps, with a {g}-step gap between them.'),
        {'n': times, 'd': dash, 'g': gap},
      ),
      wrong: [
        // Pen never lifted: one long line instead of dashes.
        'répète $times {\n  avance $dash\n  avance $gap\n}',
        // Lifted and never put back: nothing is drawn at all after the first.
        'répète $times {\n  lèvecrayon\n  avance $dash\n  avance $gap\n}',
        // The gap and the dash swapped: the marks land in the wrong places.
        'répète $times {\n  lèvecrayon\n  avance $dash\n'
            '  baissecrayon\n  avance $gap\n}',
      ],
      itemHints: hints(
        'Pour laisser un vide, il faut lever le crayon avant d\'avancer.',
        'To leave a gap, lift the pen before moving.',
        'Lève le crayon, avance, baisse le crayon : le vide est entre les deux.',
        'Pen up, move, pen down: the gap is in between.',
        spotlight: 'PEN_UP',
      ),
      lookAtFr: 'Regarde les vides entre les traits.',
      lookAtEn: 'Look at the gaps between the dashes.',
      paletteScope: palette,
    ));
  }

  /* T1 — two separate squares. This is the item the concept exists for: without the pen
     you cannot draw two things, only one thing with a line joining them. */
  for (final pair in [
    [40, 90],
    [50, 110],
    [30, 80],
  ]) {
    final side = pair[0], apart = pair[1];
    const square = 'répète 4 {\n  avance SIDE\n  tournedroite 90\n}';
    final solution = '${square.replaceAll('SIDE', '$side')}\n'
        'lèvecrayon\ntournedroite 90\navance $apart\ntournegauche 90\n'
        'baissecrayon\n${square.replaceAll('SIDE', '$side')}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C3.1',
      difficulty: Difficulty.d2,
      solution: solution,
      promptKeys: fillBoth(
        b('Dessine deux carrés de {s} pas, séparés de {a} pas, sans trait entre eux.',
            'Draw two squares of {s} steps, {a} steps apart, with no line between them.'),
        {'s': side, 'a': apart},
      ),
      wrong: [
        // The joining line a child draws when the pen never lifts.
        '${square.replaceAll('SIDE', '$side')}\ntournedroite 90\navance $apart\n'
            'tournegauche 90\n${square.replaceAll('SIDE', '$side')}',
        // One square only.
        square.replaceAll('SIDE', '$side'),
        // Pen lifted and never lowered: the second square never appears.
        '${square.replaceAll('SIDE', '$side')}\nlèvecrayon\ntournedroite 90\n'
            'avance $apart\ntournegauche 90\n${square.replaceAll('SIDE', '$side')}',
      ],
      itemHints: hints(
        'Entre les deux carrés, le crayon ne doit pas toucher la feuille.',
        'Between the two squares, the pen must not touch the paper.',
        'Lève le crayon pour te déplacer, puis baisse-le pour dessiner.',
        'Lift the pen to travel, then put it down to draw.',
        spotlight: 'PEN_UP',
      ),
      lookAtFr: 'Regarde s\'il y a un trait entre les deux carrés.',
      lookAtEn: 'Look for a line between the two squares.',
      paletteScope: palette,
    ));
  }

  /* T2 — the bug is always the same bug, because it is always the same misconception:
     the child moved without lifting. */
  for (final pair in [
    [50, 70],
    [40, 60],
    [60, 100],
    [35, 55],
  ]) {
    final side = pair[0], apart = pair[1];
    final broken = 'avance $side\ntournedroite 90\navance $apart\n'
        'tournedroite 90\navance $side';
    final solution = 'avance $side\nlèvecrayon\ntournedroite 90\navance $apart\n'
        'tournedroite 90\nbaissecrayon\navance $side';
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C3.1',
      difficulty: Difficulty.d2,
      broken: broken,
      solution: solution,
      promptKeys: fillBoth(
        b('Il doit y avoir deux traits de {s} pas et rien entre les deux. Répare.',
            'There should be two lines of {s} steps and nothing in between. Fix it.'),
        {'s': side},
      ),
      wrong: [
        'lèvecrayon\navance $side\ntournedroite 90\navance $apart\n'
            'tournedroite 90\navance $side',
        'avance $side\nlèvecrayon\ntournedroite 90\navance $apart\n'
            'tournedroite 90\navance $side',
      ],
      itemHints: hints(
        'Le trait du milieu ne devrait pas être là.',
        'The middle line should not be there.',
        'Lève le crayon juste avant ce déplacement, et baisse-le juste après.',
        'Lift the pen just before that move, and lower it just after.',
        spotlight: 'PEN_UP',
      ),
      paletteScope: palette,
    ));
  }

  // T3 — predict. The misconception, asked directly.
  /* The fourth choice is authored per set rather than fixed at zero. "Zéro trait" is the
     right answer to the third program, and a fixed zero made it appear twice — once as
     the answer and once as a mistake. Where it is not the answer it stays, because
     "the pen never came down" is a real thing a child thinks. */
  for (final entry in [
    ('lèvecrayon\navance 60\nbaissecrayon\navance 60', 1, 60, 0,
        'C3.1-pen-never-down'),
    ('avance 40\nlèvecrayon\navance 40\nbaissecrayon\navance 40', 2, 40, 0,
        'C3.1-pen-never-down'),
    // Four: every `avance` in the program, counted as if the pen never lifted.
    ('lèvecrayon\nrépète 3 {\n  avance 30\n}\navance 30', 0, 30, 4,
        'C3.1-pen-ignored'),
  ]) {
    final source = entry.$1, marks = entry.$2;
    items.add(predict(
      id: id(),
      conceptId: 'C3.1',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Combien de traits ce programme laisse-t-il ?\n\n{p}',
            'How many marks does this program leave?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b('$marks', '$marks'), correct: true),
        Choice(
            labelKeys: b('${marks + 1}', '${marks + 1}'),
            correct: false,
            misconception: 'C3.1-pen-ignored'),
        Choice(
            labelKeys: b('${marks + 2}', '${marks + 2}'),
            correct: false,
            misconception: 'C3.1-pen-ignored'),
        Choice(
            labelKeys: b('${entry.$4}', '${entry.$4}'),
            correct: false,
            misconception: entry.$5),
      ],
      itemHints: hints(
        'Un trait n\'apparaît que si le crayon est baissé.',
        'A mark only appears when the pen is down.',
        'Suis le programme ligne par ligne et note quand le crayon est baissé.',
        'Follow the program line by line and note when the pen is down.',
      ),
      wrongChoiceFr: 'Compte seulement les avancées faites crayon baissé.',
      wrongChoiceEn: 'Count only the moves made with the pen down.',
    ));
  }

  // T4 — fill the gap. One hole, and it is the whole concept.
  for (final side in [40, 60, 80]) {
    final solution = 'avance $side\nlèvecrayon\navance $side\n'
        'baissecrayon\navance $side';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C3.1',
      difficulty: Difficulty.d1,
      withHoles: 'avance $side\n___\navance $side\nbaissecrayon\navance $side',
      solution: solution,
      promptKeys: fillBoth(
        b('Complète pour que le trait du milieu disparaisse.',
            'Fill in the blank so the middle line disappears.'),
        {'s': side},
      ),
      wrong: [
        'avance $side\nbaissecrayon\navance $side\nbaissecrayon\navance $side',
        'avance $side\nnettoietout\navance $side\nbaissecrayon\navance $side',
        'lèvecrayon\navance $side\navance $side\nbaissecrayon\navance $side',
      ],
      itemHints: hints(
        'Il faut empêcher le crayon de marquer pendant ce déplacement.',
        'You need to stop the pen from marking during that move.',
        'C\'est lèvecrayon.',
        'It is pen up.',
        spotlight: 'PEN_UP',
      ),
      paletteScope: palette,
    ));
  }

  // T5 — Parsons. Same lines, and the order decides where the gap falls.
  for (final side in [45, 55, 65]) {
    items.add(parsons(
      id: id(),
      conceptId: 'C3.1',
      difficulty: Difficulty.d2,
      solution: 'lèvecrayon\navance $side\nbaissecrayon\navance $side',
      promptKeys: fillBoth(
        b('Remets les lignes dans l\'ordre : d\'abord un vide, puis un trait.',
            'Put the lines back in order: a gap first, then a mark.'),
        {'s': side},
      ),
      wrong: [
        'avance $side\nlèvecrayon\navance $side\nbaissecrayon',
        'baissecrayon\navance $side\nlèvecrayon\navance $side',
        'lèvecrayon\nbaissecrayon\navance $side\navance $side',
      ],
      itemHints: hints(
        'Le crayon doit être levé avant le premier déplacement.',
        'The pen must be up before the first move.',
        'lèvecrayon, avance, baissecrayon, avance.',
        'Pen up, move, pen down, move.',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C3.2 — Largeur du crayon. Misconception: "width changes only the next line".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC32() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C3.2-${(++n).toString().padLeft(2, '0')}';

  // T1 — one width, several lines. The width stays until it is changed: that is the
  // misconception, stated as a drawing.
  for (final pair in [
    [6, 60],
    [10, 50],
    [4, 80],
    [14, 40],
  ]) {
    final width = pair[0], side = pair[1];
    final solution = 'largeurcrayon $width\n'
        'répète 4 {\n  avance $side\n  tournedroite 90\n}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C3.2',
      difficulty: width <= 6 ? Difficulty.d1 : Difficulty.d2,
      solution: solution,
      promptKeys: fillBoth(
        b('Dessine un carré de {s} pas avec un crayon de {w} d\'épaisseur.',
            'Draw a square of {s} steps with a pen {w} thick.'),
        {'s': side, 'w': width},
      ),
      wrong: [
        // Width set and then reset: only the first side is thick.
        'largeurcrayon $width\navance $side\ntournedroite 90\n'
            'largeurcrayon 1\nrépète 3 {\n  avance $side\n  tournedroite 90\n}',
        'répète 4 {\n  avance $side\n  tournedroite 90\n}',
        'largeurcrayon ${width * 2}\n'
            'répète 4 {\n  avance $side\n  tournedroite 90\n}',
      ],
      itemHints: hints(
        'L\'épaisseur se règle une fois, avant de dessiner.',
        'The thickness is set once, before you draw.',
        'largeurcrayon reste en place jusqu\'à ce que tu le changes.',
        'Pen width stays set until you change it.',
        spotlight: 'PEN_WIDTH',
      ),
      lookAtFr: 'Regarde l\'épaisseur de chaque côté.',
      lookAtEn: 'Look at how thick each side is.',
      paletteScope: palette,
    ));
  }

  // T1 — two widths in one drawing. Proof the setting is a state and not an argument.
  for (final trio in [
    [2, 12, 60],
    [3, 9, 50],
    [1, 14, 70],
  ]) {
    final thin = trio[0], thick = trio[1], side = trio[2];
    final solution = 'largeurcrayon $thin\navance $side\ntournedroite 90\n'
        'largeurcrayon $thick\navance $side';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C3.2',
      difficulty: Difficulty.d3,
      solution: solution,
      promptKeys: fillBoth(
        b('Dessine un trait fin ({f}) puis, après un quart de tour à droite, '
            'un trait épais ({e}). Les deux font {s} pas.',
            'Draw a thin line ({f}), then, after a quarter turn right, a thick '
            'line ({e}). Both are {s} steps.'),
        {'f': thin, 'e': thick, 's': side},
      ),
      wrong: [
        'largeurcrayon $thin\navance $side\ntournedroite 90\navance $side',
        'largeurcrayon $thick\navance $side\ntournedroite 90\n'
            'largeurcrayon $thin\navance $side',
        'largeurcrayon $thick\navance $side\ntournedroite 90\navance $side',
      ],
      itemHints: hints(
        'Change l\'épaisseur entre les deux traits.',
        'Change the thickness between the two lines.',
        'Un largeurcrayon avant chaque trait.',
        'One pen-width command before each line.',
        spotlight: 'PEN_WIDTH',
      ),
      paletteScope: palette,
    ));
  }

  // T2 — the bug is the misconception: the child set the width after the first move.
  for (final pair in [
    [8, 50],
    [12, 40],
    [5, 70],
  ]) {
    final width = pair[0], side = pair[1];
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C3.2',
      difficulty: Difficulty.d2,
      broken: 'avance $side\nlargeurcrayon $width\ntournedroite 90\navance $side',
      solution:
          'largeurcrayon $width\navance $side\ntournedroite 90\navance $side',
      promptKeys: fillBoth(
        b('Les deux traits doivent être épais de {w}. Répare.',
            'Both lines should be {w} thick. Fix it.'),
        {'w': width},
      ),
      wrong: [
        'avance $side\nlargeurcrayon $width\ntournedroite 90\navance $side',
        'largeurcrayon 1\navance $side\ntournedroite 90\navance $side',
        'largeurcrayon $width\navance $side\ntournedroite 90\n'
            'largeurcrayon 1\navance $side',
      ],
      itemHints: hints(
        'Le premier trait est encore fin.',
        'The first line is still thin.',
        'Règle l\'épaisseur avant de commencer à dessiner.',
        'Set the thickness before you start drawing.',
        spotlight: 'PEN_WIDTH',
      ),
      paletteScope: palette,
    ));
  }

  // T3 — predict.
  for (final entry in [
    ('largeurcrayon 10\navance 40\ntournedroite 90\navance 40', 2),
    ('avance 40\nlargeurcrayon 10\ntournedroite 90\navance 40', 1),
    ('largeurcrayon 10\navance 40\nlargeurcrayon 1\ntournedroite 90\navance 40', 1),
  ]) {
    final source = entry.$1, thickCount = entry.$2;
    items.add(predict(
      id: id(),
      conceptId: 'C3.2',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Combien de traits épais ce programme dessine-t-il ?\n\n{p}',
            'How many thick lines does this program draw?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b('$thickCount', '$thickCount'), correct: true),
        Choice(
            labelKeys: b('${thickCount == 2 ? 1 : 2}', '${thickCount == 2 ? 1 : 2}'),
            correct: false,
            misconception: 'C3.2-width-is-one-shot'),
        Choice(
            labelKeys: b('0', '0'),
            correct: false,
            misconception: 'C3.2-width-is-one-shot'),
        Choice(
            labelKeys: b('4', '4'),
            correct: false,
            misconception: 'C3.2-width-counts-sides'),
      ],
      itemHints: hints(
        'L\'épaisseur s\'applique à tout ce qui vient après.',
        'The thickness applies to everything that comes after it.',
        'Regarde où largeurcrayon est écrit dans le programme.',
        'Look at where the pen-width command sits in the program.',
      ),
      wrongChoiceFr: 'largeurcrayon vaut pour tous les traits suivants, pas seulement le premier.',
      wrongChoiceEn: 'Pen width applies to every line after it, not only the next one.',
    ));
  }

  // T4 — fill the gap.
  for (final width in [6, 9, 12]) {
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C3.2',
      difficulty: Difficulty.d1,
      withHoles: '___\nrépète 3 {\n  avance 50\n  tournedroite 120\n}',
      solution:
          'largeurcrayon $width\nrépète 3 {\n  avance 50\n  tournedroite 120\n}',
      promptKeys: fillBoth(
        b('Complète pour que le triangle soit tracé avec un crayon de {w}.',
            'Fill in the blank so the triangle is drawn with a pen {w} thick.'),
        {'w': width},
      ),
      wrong: [
        'largeurcrayon 1\nrépète 3 {\n  avance 50\n  tournedroite 120\n}',
        'baissecrayon\nrépète 3 {\n  avance 50\n  tournedroite 120\n}',
        'largeurcrayon ${width * 2}\n'
            'répète 3 {\n  avance 50\n  tournedroite 120\n}',
      ],
      itemHints: hints(
        'Il faut régler l\'épaisseur du crayon.',
        'You need to set the pen thickness.',
        'largeurcrayon $width.',
        'Pen width $width.',
        spotlight: 'PEN_WIDTH',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(
      'Tu écris largeurcrayon 8 au début de ton programme. '
          'Qu\'est-ce que cela change ?',
      'You write pen width 8 at the start of your program. What does it change?',
    ),
    choices: [
      Choice(
          labelKeys: b('Tous les traits qui suivent sont épais de 8.',
              'Every line after it is 8 thick.'),
          correct: true),
      Choice(
          labelKeys: b('Seulement le premier trait est épais de 8.',
              'Only the first line is 8 thick.'),
          correct: false,
          misconception: 'C3.2-width-is-one-shot'),
      Choice(
          labelKeys: b('Le crayon avance de 8 pas.', 'The pen moves 8 steps.'),
          correct: false,
          misconception: 'C3.2-width-is-distance'),
      Choice(
          labelKeys: b('Les traits déjà dessinés deviennent épais.',
              'The lines already drawn become thick.'),
          correct: false,
          misconception: 'C3.2-width-repaints'),
    ],
    itemHints: hints(
      'C\'est un réglage, pas un déplacement.',
      'It is a setting, not a move.',
      'Un réglage reste en place jusqu\'à ce qu\'on le change.',
      'A setting stays until you change it.',
    ),
    wrongChoiceFr: 'largeurcrayon règle l\'épaisseur du trait, et le réglage reste.',
    wrongChoiceEn: 'Pen width sets how thick the line is, and the setting stays.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Tu veux un carré dont un seul côté est épais. Où mets-tu largeurcrayon ?',
      'You want a square with only one thick side. Where do you put pen width?',
    ),
    choices: [
      Choice(
          labelKeys: b(
              'Avant le côté épais, et je remets une petite largeur juste après.',
              'Before the thick side, and I set a small width right after it.'),
          correct: true),
      Choice(
          labelKeys: b('Au tout début du programme.',
              'At the very start of the program.'),
          correct: false,
          misconception: 'C3.2-width-is-one-shot'),
      Choice(
          labelKeys: b('À la fin du programme.', 'At the end of the program.'),
          correct: false,
          misconception: 'C3.2-width-is-one-shot'),
      Choice(
          labelKeys: b('Nulle part : il faut quatre programmes.',
              'Nowhere: you need four separate programs.'),
          correct: false,
          misconception: 'C3.2-no-state'),
    ],
    itemHints: hints(
      'Le réglage vaut pour tout ce qui suit.',
      'The setting applies to everything after it.',
      'Il faut donc le changer deux fois : avant, et après.',
      'So you have to change it twice: before, and after.',
    ),
    wrongChoiceFr: 'Un réglage posé au début vaut pour les quatre côtés.',
    wrongChoiceEn: 'A setting placed at the start applies to all four sides.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait largeurcrayon 1 après un largeurcrayon 10 ?',
        'What does pen width 1 do after a pen width 10?'),
    choices: [
      Choice(
          labelKeys: b('Les traits suivants redeviennent fins.',
              'The lines after it become thin again.'),
          correct: true),
      Choice(
          labelKeys: b('Cela efface les traits épais déjà dessinés.',
              'It erases the thick lines already drawn.'),
          correct: false,
          misconception: 'C3.2-width-repaints'),
      Choice(
          labelKeys: b('Cela ne change rien.', 'It changes nothing.'),
          correct: false,
          misconception: 'C3.2-width-is-one-shot'),
      Choice(
          labelKeys: b('Cela lève le crayon.', 'It lifts the pen.'),
          correct: false,
          misconception: 'C3.2-width-is-pen-state'),
    ],
    itemHints: hints(
      'Ce qui est déjà dessiné ne bouge plus.',
      'What is already drawn does not move.',
      'Un réglage change la suite, jamais le passé.',
      'A setting changes what follows, never the past.',
    ),
    wrongChoiceFr: 'Un réglage vaut pour la suite, et n\'efface rien.',
    wrongChoiceEn: 'A setting applies to what follows, and erases nothing.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C3.3 — Couleur RVB du crayon. Misconception: "RGB values are percentages".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC33() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C3.3-${(++n).toString().padLeft(2, '0')}';

  /* T1 — draw it in a named colour off the Annex C card. The wrong answers are the
     misconception made concrete: 100 for "100 % red" gives a dark red, and the grader
     now sees the difference, which it could not do before this world was authored. */
  for (final entry in [
    (rouge, 'rouge', 'red', 60, 4, 90),
    (bleu, 'bleu', 'blue', 50, 3, 120),
    (vert, 'vert', 'green', 70, 4, 90),
    (jaune, 'jaune', 'yellow', 45, 6, 60),
    (rose, 'rose', 'pink', 55, 3, 120),
  ]) {
    final rgb = entry.$1, fr = entry.$2, en = entry.$3;
    final side = entry.$4, sides = entry.$5, turn = entry.$6;
    final solution = 'couleurcrayon $rgb\n'
        'répète $sides {\n  avance $side\n  tournedroite $turn\n}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C3.3',
      difficulty: Difficulty.d1,
      solution: solution,
      /* Two holes, not one. `fillBoth` fills both languages from the same map, so a
         single `{c}` would put the French colour name into the English prompt — which is
         exactly the class of defect the M15 audit caught elsewhere, and it is invisible
         until somebody reads the English. */
      promptKeys: fillBoth(
        b('Dessine la figure à {k} côtés de {s} pas, en {cfr}. '
            'Sur la carte des couleurs : {rgb}.',
            'Draw the {k}-sided shape of {s} steps, in {cen}. '
            'On the colour card: {rgb}.'),
        {'k': sides, 's': side, 'cfr': fr, 'cen': en, 'rgb': rgb},
      ),
      wrong: [
        // The misconception: the numbers read as percentages.
        'couleurcrayon ${rgb.split(', ').map((v) => v == '255' ? '100' : v).join(', ')}\n'
            'répète $sides {\n  avance $side\n  tournedroite $turn\n}',
        // No colour set at all: black.
        'répète $sides {\n  avance $side\n  tournedroite $turn\n}',
        /* Right idea, wrong channel order — EXCEPT that some of the card's colours are
           palindromes: green is 0,255,0 and pink is 255,0,255, and reversing them changes
           nothing. The publish gate caught a "wrong" answer that was the right answer,
           which is the single most damaging authoring fault there is, so the fallback is
           a neighbouring colour instead. */
        'couleurcrayon ${rgb.split(', ').reversed.join(', ') == rgb ? '128, 128, 128' : rgb.split(', ').reversed.join(', ')}\n'
            'répète $sides {\n  avance $side\n  tournedroite $turn\n}',
      ],
      itemHints: hints(
        'Les trois nombres sont le rouge, le vert et le bleu, dans cet ordre.',
        'The three numbers are red, green and blue, in that order.',
        'Ils vont de 0 à 255, pas de 0 à 100.',
        'They go from 0 to 255, not from 0 to 100.',
        spotlight: 'PEN_COLOR',
      ),
      lookAtFr: 'Regarde la couleur du trait.',
      lookAtEn: 'Look at the colour of the line.',
      paletteScope: palette,
    ));
  }

  // T1 — two colours in one figure. The setting is a state, here too.
  for (final entry in [
    (rouge, bleu, 60),
    (vert, rose, 50),
  ]) {
    final first = entry.$1, second = entry.$2, side = entry.$3;
    final solution = 'couleurcrayon $first\navance $side\ntournedroite 90\n'
        'avance $side\ncouleurcrayon $second\ntournedroite 90\n'
        'avance $side\ntournedroite 90\navance $side';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C3.3',
      difficulty: Difficulty.d3,
      solution: solution,
      promptKeys: fillBoth(
        b('Dessine un carré de {s} pas : les deux premiers côtés en {a}, '
            'les deux derniers en {b}.',
            'Draw a square of {s} steps: the first two sides in {a}, '
            'the last two in {b}.'),
        {'s': side, 'a': first, 'b': second},
      ),
      wrong: [
        'couleurcrayon $first\nrépète 4 {\n  avance $side\n  tournedroite 90\n}',
        'couleurcrayon $second\nrépète 4 {\n  avance $side\n  tournedroite 90\n}',
        // The two colours, the right way round but a side too early.
        'couleurcrayon $first\navance $side\ncouleurcrayon $second\n'
            'tournedroite 90\navance $side\ntournedroite 90\navance $side\n'
            'tournedroite 90\navance $side',
      ],
      itemHints: hints(
        'Change la couleur au milieu du carré.',
        'Change the colour halfway round the square.',
        'Un couleurcrayon avant les deux premiers côtés, un autre avant les deux derniers.',
        'One pen-colour before the first two sides, another before the last two.',
        spotlight: 'PEN_COLOR',
      ),
      paletteScope: palette,
    ));
  }

  // T2 — the bug is always the percentage.
  for (final entry in [
    (rouge, 'rouge', 'red', 60),
    (bleu, 'bleu', 'blue', 50),
    (vert, 'vert', 'green', 70),
    (jaune, 'jaune', 'yellow', 40),
  ]) {
    final rgb = entry.$1, nameFr = entry.$2, nameEn = entry.$3, side = entry.$4;
    final wrongRgb = rgb.split(', ').map((v) => v == '255' ? '100' : v).join(', ');
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C3.3',
      difficulty: Difficulty.d2,
      broken: 'couleurcrayon $wrongRgb\n'
          'répète 4 {\n  avance $side\n  tournedroite 90\n}',
      solution: 'couleurcrayon $rgb\n'
          'répète 4 {\n  avance $side\n  tournedroite 90\n}',
      promptKeys: fillBoth(
        b('Le carré doit être {cfr} vif. Il est trop sombre. Répare.',
            'The square should be bright {cen}. It is too dark. Fix it.'),
        {'cfr': nameFr, 'cen': nameEn},
      ),
      wrong: [
        'couleurcrayon $wrongRgb\n'
            'répète 4 {\n  avance $side\n  tournedroite 90\n}',
        'couleurcrayon $noir\n'
            'répète 4 {\n  avance $side\n  tournedroite 90\n}',
        'couleurcrayon 128, 128, 128\n'
            'répète 4 {\n  avance $side\n  tournedroite 90\n}',
      ],
      itemHints: hints(
        'Le nombre le plus fort n\'est pas 100.',
        'The strongest number is not 100.',
        'Le maximum est 255.',
        'The maximum is 255.',
        spotlight: 'PEN_COLOR',
      ),
      paletteScope: palette,
    ));
  }

  // T3 — predict, on the card.
  for (final entry in [
    (rouge, 'rouge', 'red', 'jaune', 'yellow'),
    (bleu, 'bleu', 'blue', 'vert', 'green'),
    (jaune, 'jaune', 'yellow', 'rouge', 'red'),
    (rose, 'rose', 'pink', 'bleu', 'blue'),
  ]) {
    final rgb = entry.$1, fr = entry.$2, en = entry.$3;
    final otherFr = entry.$4, otherEn = entry.$5;
    items.add(predict(
      id: id(),
      conceptId: 'C3.3',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('De quelle couleur sera le trait ?\n\ncouleurcrayon {rgb}\navance 60',
            'What colour will the line be?\n\npen colour {rgb}\nforward 60'),
        {'rgb': rgb},
      ),
      choices: [
        Choice(labelKeys: b(fr, en), correct: true),
        Choice(
            labelKeys: b(otherFr, otherEn),
            correct: false,
            misconception: 'C3.3-channel-order'),
        Choice(
            labelKeys: b('noir', 'black'),
            correct: false,
            misconception: 'C3.3-rgb-unread'),
        Choice(
            labelKeys: b('blanc', 'white'),
            correct: false,
            misconception: 'C3.3-zero-is-white'),
      ],
      itemHints: hints(
        'Rouge, vert, bleu — dans cet ordre.',
        'Red, green, blue — in that order.',
        'Regarde la carte des couleurs.',
        'Look at the colour card.',
      ),
      wrongChoiceFr: 'Le premier nombre est le rouge, le deuxième le vert, le troisième le bleu.',
      wrongChoiceEn: 'The first number is red, the second green, the third blue.',
    ));
  }

  // T4 — fill the gap.
  for (final entry in [
    (rouge, 'rouge', 'red'),
    (bleu, 'bleu', 'blue'),
    (vert, 'vert', 'green'),
  ]) {
    final rgb = entry.$1, fr = entry.$2, en = entry.$3;
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C3.3',
      difficulty: Difficulty.d1,
      withHoles: '___\nrépète 4 {\n  avance 50\n  tournedroite 90\n}',
      solution:
          'couleurcrayon $rgb\nrépète 4 {\n  avance 50\n  tournedroite 90\n}',
      promptKeys: fillBoth(
        b('Complète pour que le carré soit {cfr}.',
            'Fill in the blank so the square is {cen}.'),
        {'cfr': fr, 'cen': en},
      ),
      wrong: [
        'couleurcrayon $noir\nrépète 4 {\n  avance 50\n  tournedroite 90\n}',
        'largeurcrayon 3\nrépète 4 {\n  avance 50\n  tournedroite 90\n}',
        'couleurcanevas $rgb\nrépète 4 {\n  avance 50\n  tournedroite 90\n}',
      ],
      itemHints: hints(
        'Il faut choisir la couleur du crayon.',
        'You need to choose the pen colour.',
        'couleurcrayon $rgb.',
        'Pen colour $rgb.',
        spotlight: 'PEN_COLOR',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Quel est le nombre le plus grand qu\'on peut écrire dans couleurcrayon ?',
        'What is the largest number you can write in pen colour?'),
    choices: [
      Choice(labelKeys: b('255', '255'), correct: true),
      Choice(
          labelKeys: b('100', '100'),
          correct: false,
          misconception: 'C3.3-rgb-is-percent'),
      Choice(
          labelKeys: b('10', '10'),
          correct: false,
          misconception: 'C3.3-rgb-is-percent'),
      Choice(
          labelKeys: b('1', '1'),
          correct: false,
          misconception: 'C3.3-rgb-is-fraction'),
    ],
    itemHints: hints(
      'Regarde la plus grande valeur sur la carte des couleurs.',
      'Look at the biggest value on the colour card.',
      'Le rouge vif s\'écrit 255, 0, 0.',
      'Bright red is written 255, 0, 0.',
    ),
    wrongChoiceFr: 'Ce ne sont pas des pourcentages : chaque nombre va de 0 à 255.',
    wrongChoiceEn: 'They are not percentages: each number goes from 0 to 255.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('couleurcrayon 0, 0, 0 donne quelle couleur ?',
        'What colour does pen colour 0, 0, 0 give?'),
    choices: [
      Choice(labelKeys: b('noir', 'black'), correct: true),
      Choice(
          labelKeys: b('blanc', 'white'),
          correct: false,
          misconception: 'C3.3-zero-is-white'),
      Choice(
          labelKeys: b('rien du tout : le crayon ne dessine plus.',
              'nothing at all: the pen stops drawing.'),
          correct: false,
          misconception: 'C3.3-zero-is-pen-up'),
      Choice(
          labelKeys: b('la couleur du fond.', 'the background colour.'),
          correct: false,
          misconception: 'C3.3-pen-is-canvas'),
    ],
    itemHints: hints(
      'Zéro veut dire « pas de lumière ».',
      'Zero means "no light".',
      'Pas de rouge, pas de vert, pas de bleu : c\'est noir.',
      'No red, no green, no blue: that is black.',
    ),
    wrongChoiceFr: 'Zéro partout, c\'est le noir ; 255 partout, c\'est le blanc.',
    wrongChoiceEn: 'Zero everywhere is black; 255 everywhere is white.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Tu veux du jaune. Quels nombres écris-tu ?',
        'You want yellow. Which numbers do you write?'),
    choices: [
      Choice(labelKeys: b('255, 255, 0', '255, 255, 0'), correct: true),
      Choice(
          labelKeys: b('0, 0, 255', '0, 0, 255'),
          correct: false,
          misconception: 'C3.3-channel-order'),
      Choice(
          labelKeys: b('255, 0, 255', '255, 0, 255'),
          correct: false,
          misconception: 'C3.3-channel-order'),
      Choice(
          labelKeys: b('100, 100, 0', '100, 100, 0'),
          correct: false,
          misconception: 'C3.3-rgb-is-percent'),
    ],
    itemHints: hints(
      'Le jaune, c\'est du rouge et du vert ensemble.',
      'Yellow is red and green together.',
      'Rouge à fond, vert à fond, pas de bleu.',
      'Red full, green full, no blue.',
    ),
    wrongChoiceFr: 'Le troisième nombre est le bleu, et le jaune n\'en a pas.',
    wrongChoiceEn: 'The third number is blue, and yellow has none.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.3',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Amina écrit couleurcrayon 100, 0, 0 et trouve son rouge terne. Pourquoi ?',
      'Amina writes pen colour 100, 0, 0 and finds her red dull. Why?',
    ),
    choices: [
      Choice(
          labelKeys: b('100 n\'est pas le maximum : le rouge vif, c\'est 255.',
              '100 is not the maximum: bright red is 255.'),
          correct: true),
      Choice(
          labelKeys: b('Elle a oublié de baisser le crayon.',
              'She forgot to put the pen down.'),
          correct: false,
          misconception: 'C3.3-blame-the-pen'),
      Choice(
          labelKeys: b('Le crayon est trop fin.', 'The pen is too thin.'),
          correct: false,
          misconception: 'C3.3-blame-the-width'),
      Choice(
          labelKeys: b('Le fond est trop clair.', 'The background is too light.'),
          correct: false,
          misconception: 'C3.3-blame-the-canvas'),
    ],
    itemHints: hints(
      'Son programme marche : c\'est la couleur qui n\'est pas celle qu\'elle voulait.',
      'Her program runs: it is the colour that is not the one she wanted.',
      'Compare 100 et 255.',
      'Compare 100 and 255.',
    ),
    wrongChoiceFr: 'Le trait est bien là : seul le nombre du rouge est trop petit.',
    wrongChoiceEn: 'The line is there: only the red number is too small.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.3',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Deux programmes dessinent le même carré, l\'un en rouge et l\'autre en bleu. '
          'Sont-ils le même programme ?',
      'Two programs draw the same square, one red and one blue. '
          'Are they the same program?',
    ),
    choices: [
      Choice(
          labelKeys: b('Non : le dessin n\'est pas le même, la couleur en fait partie.',
              'No: the drawing is not the same, the colour is part of it.'),
          correct: true),
      Choice(
          labelKeys: b('Oui : la forme est la même.', 'Yes: the shape is the same.'),
          correct: false,
          misconception: 'C3.3-colour-is-decoration'),
      Choice(
          labelKeys: b('Oui : la couleur ne se voit pas à l\'impression.',
              'Yes: the colour does not show when printed.'),
          correct: false,
          misconception: 'C3.3-colour-is-decoration'),
      Choice(
          labelKeys: b('On ne peut pas savoir sans les faire tourner.',
              'There is no way to tell without running them.'),
          correct: false,
          misconception: 'C3.3-cannot-read-a-program'),
    ],
    itemHints: hints(
      'Regarde les deux dessins côte à côte.',
      'Look at the two drawings side by side.',
      'Si tu vois une différence, les programmes sont différents.',
      'If you can see a difference, the programs are different.',
    ),
    wrongChoiceFr: 'Ce qu\'on voit sur la feuille fait partie du dessin, couleur comprise.',
    wrongChoiceEn: 'What you see on the paper is part of the drawing, colour included.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C3.4 — Couleur et taille du canevas. Misconception: "the canvas is the screen".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC34() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C3.4-${(++n).toString().padLeft(2, '0')}';

  // T1 — a drawing on coloured paper.
  for (final entry in [
    ('20, 30, 60', 'bleu nuit', 'night blue', jaune, 60, 4, 90),
    ('250, 240, 210', 'sable', 'sand', rouge, 50, 3, 120),
    ('10, 60, 40', 'vert forêt', 'forest green', jaune, 45, 6, 60),
  ]) {
    final bg = entry.$1, bgFr = entry.$2, bgEn = entry.$3;
    final pen = entry.$4, side = entry.$5, sides = entry.$6, turn = entry.$7;
    final solution = 'couleurcanevas $bg\ncouleurcrayon $pen\n'
        'répète $sides {\n  avance $side\n  tournedroite $turn\n}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C3.4',
      difficulty: Difficulty.d2,
      solution: solution,
      promptKeys: fillBoth(
        b('Mets le fond en {ffr} ({bg}) et dessine la figure à {k} côtés par-dessus.',
            'Make the background {fen} ({bg}) and draw the {k}-sided shape on top.'),
        {'ffr': bgFr, 'fen': bgEn, 'bg': bg, 'k': sides},
      ),
      wrong: [
        // The pen coloured instead of the paper: the classic swap.
        'couleurcrayon $bg\nrépète $sides {\n  avance $side\n  tournedroite $turn\n}',
        // Paper left white.
        'couleurcrayon $pen\n'
            'répète $sides {\n  avance $side\n  tournedroite $turn\n}',
        // Paper coloured and the pen left black.
        'couleurcanevas $bg\n'
            'répète $sides {\n  avance $side\n  tournedroite $turn\n}',
      ],
      itemHints: hints(
        'Le fond et le crayon sont deux réglages différents.',
        'The background and the pen are two different settings.',
        'couleurcanevas change la feuille, couleurcrayon change le trait.',
        'Canvas colour changes the paper, pen colour changes the line.',
        spotlight: 'CANVAS_COLOR',
      ),
      lookAtFr: 'Regarde la couleur du fond.',
      lookAtEn: 'Look at the background colour.',
      paletteScope: palette,
    ));
  }

  // T1 — a smaller sheet. The canvas is not the screen: it has a size you choose.
  for (final entry in [
    (300, 200, 50),
    // Not 200 × 200: a square sheet makes the "width and height swapped" wrong answer
    // identical to the right one, and the gate refuses it — correctly.
    (240, 200, 40),
    (360, 240, 60),
  ]) {
    final w = entry.$1, h = entry.$2, side = entry.$3;
    final solution = 'taillecanevas $w, $h\n'
        'répète 4 {\n  avance $side\n  tournedroite 90\n}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C3.4',
      difficulty: Difficulty.d2,
      solution: solution,
      promptKeys: fillBoth(
        b('Prends une feuille de {w} sur {h} et dessine un carré de {s} pas au milieu.',
            'Take a {w} by {h} sheet and draw a square of {s} steps in the middle.'),
        {'w': w, 'h': h, 's': side},
      ),
      wrong: [
        'répète 4 {\n  avance $side\n  tournedroite 90\n}',
        'taillecanevas $h, $w\nrépète 4 {\n  avance $side\n  tournedroite 90\n}',
        'taillecanevas ${w ~/ 2}, ${h ~/ 2}\n'
            'répète 4 {\n  avance $side\n  tournedroite 90\n}',
      ],
      itemHints: hints(
        'La feuille a une largeur et une hauteur, dans cet ordre.',
        'The sheet has a width and a height, in that order.',
        'taillecanevas $w, $h.',
        'Canvas size $w, $h.',
        spotlight: 'CANVAS_SIZE',
      ),
      paletteScope: palette,
    ));
  }

  // T2 — the swap, as a bug to find.
  for (final entry in [
    ('20, 30, 60', rouge, 50),
    ('250, 240, 210', bleu, 60),
    ('10, 60, 40', jaune, 45),
    ('60, 20, 50', vert, 55),
  ]) {
    final bg = entry.$1, pen = entry.$2, side = entry.$3;
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C3.4',
      difficulty: Difficulty.d2,
      broken: 'couleurcrayon $bg\ncouleurcanevas $pen\n'
          'répète 4 {\n  avance $side\n  tournedroite 90\n}',
      solution: 'couleurcanevas $bg\ncouleurcrayon $pen\n'
          'répète 4 {\n  avance $side\n  tournedroite 90\n}',
      promptKeys: fillBoth(
        b('Le fond devait être {bg} et le trait {p}. C\'est l\'inverse. Répare.',
            'The background should be {bg} and the line {p}. It is the other way '
            'round. Fix it.'),
        {'bg': bg, 'p': pen},
      ),
      wrong: [
        'couleurcanevas $bg\n'
            'répète 4 {\n  avance $side\n  tournedroite 90\n}',
        'couleurcrayon $pen\n'
            'répète 4 {\n  avance $side\n  tournedroite 90\n}',
        'couleurcrayon $bg\ncouleurcanevas $pen\n'
            'répète 4 {\n  avance $side\n  tournedroite 90\n}',
      ],
      itemHints: hints(
        'Les deux réglages ont été échangés.',
        'The two settings have been swapped.',
        'couleurcanevas pour la feuille, couleurcrayon pour le trait.',
        'Canvas colour for the paper, pen colour for the line.',
        spotlight: 'CANVAS_COLOR',
      ),
      paletteScope: palette,
    ));
  }

  // T3 — predict.
  for (final entry in [
    ('couleurcanevas 20, 30, 60\navance 60', 'le fond devient bleu nuit, le trait reste noir',
        'the background turns night blue, the line stays black'),
    ('couleurcrayon 20, 30, 60\navance 60', 'le trait devient bleu nuit, le fond reste blanc',
        'the line turns night blue, the background stays white'),
    ('taillecanevas 200, 200\navance 60', 'la feuille devient plus petite, le trait ne change pas',
        'the sheet becomes smaller, the line does not change'),
    ('couleurcanevas 255, 255, 255\navance 60', 'rien ne change à l\'œil : le fond était déjà blanc',
        'nothing looks different: the background was already white'),
  ]) {
    final source = entry.$1, rightFr = entry.$2, rightEn = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C3.4',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Que voit-on après ce programme ?\n\n{p}',
            'What do you see after this program?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b(rightFr, rightEn), correct: true),
        Choice(
            labelKeys: b('le trait et le fond changent tous les deux',
                'both the line and the background change'),
            correct: false,
            misconception: 'C3.4-canvas-is-pen'),
        Choice(
            labelKeys: b('le dessin est effacé', 'the drawing is erased'),
            correct: false,
            misconception: 'C3.4-setting-erases'),
        Choice(
            labelKeys: b('Tika revient au centre', 'Tika goes back to the centre'),
            correct: false,
            misconception: 'C3.4-setting-moves-turtle'),
      ],
      itemHints: hints(
        'Un réglage ne touche qu\'une chose à la fois.',
        'A setting only touches one thing at a time.',
        'Lis le nom de la commande : canevas, ou crayon ?',
        'Read the command name: canvas, or pen?',
      ),
      wrongChoiceFr: 'Le nom de la commande dit ce qu\'elle change : le canevas ou le crayon.',
      wrongChoiceEn: 'The command name says what it changes: the canvas or the pen.',
    ));
  }

  // T4 — fill the gap.
  for (final entry in [
    ('20, 30, 60', 'bleu nuit', 'night blue'),
    ('250, 240, 210', 'sable', 'sand'),
    ('10, 60, 40', 'vert forêt', 'forest green'),
  ]) {
    final bg = entry.$1, fr = entry.$2, en = entry.$3;
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C3.4',
      difficulty: Difficulty.d1,
      withHoles: '___\ncouleurcrayon $jaune\n'
          'répète 4 {\n  avance 50\n  tournedroite 90\n}',
      solution: 'couleurcanevas $bg\ncouleurcrayon $jaune\n'
          'répète 4 {\n  avance 50\n  tournedroite 90\n}',
      promptKeys: fillBoth(
        b('Complète pour que le fond soit {ffr}. Le trait reste jaune.',
            'Fill in the blank so the background is {fen}. The line stays yellow.'),
        {'ffr': fr, 'fen': en},
      ),
      wrong: [
        'couleurcrayon $bg\ncouleurcrayon $jaune\n'
            'répète 4 {\n  avance 50\n  tournedroite 90\n}',
        'largeurcrayon 4\ncouleurcrayon $jaune\n'
            'répète 4 {\n  avance 50\n  tournedroite 90\n}',
        'taillecanevas 200, 300\ncouleurcrayon $jaune\n'
            'répète 4 {\n  avance 50\n  tournedroite 90\n}',
      ],
      itemHints: hints(
        'C\'est la feuille qu\'il faut colorer, pas le crayon.',
        'It is the paper you need to colour, not the pen.',
        'couleurcanevas $bg.',
        'Canvas colour $bg.',
        spotlight: 'CANVAS_COLOR',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Quelle est la différence entre couleurcanevas et couleurcrayon ?',
        'What is the difference between canvas colour and pen colour?'),
    choices: [
      Choice(
          labelKeys: b('L\'un colore la feuille, l\'autre le trait.',
              'One colours the paper, the other the line.'),
          correct: true),
      Choice(
          labelKeys: b('Aucune : les deux colorent le dessin.',
              'None: they both colour the drawing.'),
          correct: false,
          misconception: 'C3.4-canvas-is-pen'),
      Choice(
          labelKeys: b('couleurcanevas efface le dessin d\'abord.',
              'Canvas colour erases the drawing first.'),
          correct: false,
          misconception: 'C3.4-setting-erases'),
      Choice(
          labelKeys: b('couleurcanevas change la couleur de l\'écran du téléphone.',
              'Canvas colour changes the phone screen colour.'),
          correct: false,
          misconception: 'C3.4-canvas-is-screen'),
    ],
    itemHints: hints(
      'Pense à une feuille et à un crayon posés dessus.',
      'Think of a sheet of paper and a pen resting on it.',
      'Le canevas, c\'est la feuille.',
      'The canvas is the paper.',
    ),
    wrongChoiceFr: 'Le canevas est la feuille ; le crayon écrit dessus.',
    wrongChoiceEn: 'The canvas is the paper; the pen writes on it.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Tu changes la taille du canevas. Qu\'arrive-t-il à ton dessin ?',
        'You change the canvas size. What happens to your drawing?'),
    choices: [
      Choice(
          labelKeys: b('La feuille change de taille ; ce qui est dessiné reste où il est.',
              'The sheet changes size; what is drawn stays where it is.'),
          correct: true),
      Choice(
          labelKeys: b('Le dessin grandit avec la feuille.',
              'The drawing grows with the sheet.'),
          correct: false,
          misconception: 'C3.4-canvas-scales-drawing'),
      Choice(
          labelKeys: b('L\'écran du téléphone change de taille.',
              'The phone screen changes size.'),
          correct: false,
          misconception: 'C3.4-canvas-is-screen'),
      Choice(
          labelKeys: b('Le dessin est effacé.', 'The drawing is erased.'),
          correct: false,
          misconception: 'C3.4-setting-erases'),
    ],
    itemHints: hints(
      'Le canevas n\'est pas l\'écran.',
      'The canvas is not the screen.',
      'C\'est la feuille sur laquelle Tika dessine.',
      'It is the sheet Tika draws on.',
    ),
    wrongChoiceFr: 'Le canevas est la feuille, pas l\'écran, et il ne redimensionne pas le dessin.',
    wrongChoiceEn: 'The canvas is the paper, not the screen, and it does not resize the drawing.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Où faut-il écrire couleurcanevas dans un programme ?',
        'Where should canvas colour go in a program?'),
    choices: [
      Choice(
          labelKeys: b('N\'importe où : la feuille change, le dessin reste.',
              'Anywhere: the paper changes, the drawing stays.'),
          correct: true),
      Choice(
          labelKeys: b('Seulement tout à la fin.', 'Only right at the end.'),
          correct: false,
          misconception: 'C3.4-canvas-paints-over'),
      Choice(
          labelKeys: b('Seulement tout au début, sinon le dessin est effacé.',
              'Only right at the start, otherwise the drawing is erased.'),
          correct: false,
          misconception: 'C3.4-setting-erases'),
      Choice(
          labelKeys: b('Juste après chaque trait.', 'Just after every line.'),
          correct: false,
          misconception: 'C3.4-canvas-paints-over'),
    ],
    itemHints: hints(
      'La feuille est derrière le dessin.',
      'The paper is behind the drawing.',
      'Changer sa couleur ne recouvre rien.',
      'Changing its colour covers nothing up.',
    ),
    wrongChoiceFr: 'La feuille est derrière : la recolorer ne cache pas les traits.',
    wrongChoiceEn: 'The paper is behind: recolouring it does not hide the lines.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C3.5 — Nettoie / initialise.
// Misconception: "nettoietout also moves the turtle home".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC35() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C3.5-${(++n).toString().padLeft(2, '0')}';

  /* T1 — erase and carry on from where you are. The two commands differ only in what
     happens to Tika, so `requireFinalPose` is on: without it the grader would accept
     `initialise` for `nettoietout` on the items where the marks happen to coincide, and
     the whole concept would be untestable. */
  for (final pair in [
    [60, 40],
    [50, 30],
    [70, 50],
    [45, 35],
  ]) {
    final first = pair[0], second = pair[1];
    final solution = 'avance $first\nnettoietout\ntournedroite 90\navance $second';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C3.5',
      difficulty: Difficulty.d2,
      solution: solution,
      promptKeys: fillBoth(
        b('Avance de {a}, efface tout, puis tourne à droite et avance de {b}. '
            'Il ne doit rester qu\'un trait.',
            'Move {a}, erase everything, then turn right and move {b}. '
            'Only one line should be left.'),
        {'a': first, 'b': second},
      ),
      wrong: [
        // `initialise` sends Tika home, so the surviving line is somewhere else.
        'avance $first\ninitialise\ntournedroite 90\navance $second',
        'avance $first\ntournedroite 90\navance $second',
        'nettoietout\navance $first\ntournedroite 90\navance $second',
      ],
      itemHints: hints(
        'Effacer ne déplace pas Tika.',
        'Erasing does not move Tika.',
        'nettoietout efface la feuille et laisse Tika sur place.',
        'Clear wipes the paper and leaves Tika where she is.',
        spotlight: 'CLEAR',
      ),
      lookAtFr: 'Regarde d\'où part le trait qui reste.',
      lookAtEn: 'Look at where the remaining line starts.',
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T2 — the child used the wrong one of the two.
  for (final pair in [
    [60, 40],
    [50, 60],
    [80, 30],
    [40, 70],
    [55, 45],
  ]) {
    final first = pair[0], second = pair[1];
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C3.5',
      difficulty: Difficulty.d2,
      broken: 'avance $first\ninitialise\navance $second',
      solution: 'avance $first\nnettoietout\navance $second',
      promptKeys: fillBoth(
        b('Le trait qui reste doit commencer là où Tika s\'était arrêtée. Répare.',
            'The remaining line should start where Tika had stopped. Fix it.'),
        {'a': first, 'b': second},
      ),
      wrong: [
        'avance $first\ninitialise\navance $second',
        'avance $first\navance $second',
        'nettoietout\navance $first\navance $second',
      ],
      itemHints: hints(
        'Une des deux commandes ramène Tika au centre.',
        'One of the two commands sends Tika back to the centre.',
        'initialise remet tout à zéro ; nettoietout efface seulement la feuille.',
        'Reset puts everything back; clear only wipes the paper.',
        spotlight: 'CLEAR',
      ),
      paletteScope: palette,
      requireFinalPose: true,
    ));
  }

  // T3 — predict.
  for (final entry in [
    ('avance 60\nnettoietout\navance 60',
        'un trait, qui part de là où Tika s\'était arrêtée',
        'one line, starting where Tika had stopped'),
    ('avance 60\ninitialise\navance 60',
        'un trait, qui part du centre',
        'one line, starting from the centre'),
    ('avance 60\ntournedroite 90\nnettoietout\navance 60',
        'un trait, qui part de là où Tika s\'était arrêtée, vers la droite',
        'one line, starting where Tika had stopped, heading right'),
    ('couleurcrayon 255, 0, 0\navance 60\ninitialise\navance 60',
        'un trait noir, qui part du centre',
        'one black line, starting from the centre'),
  ]) {
    final source = entry.$1, rightFr = entry.$2, rightEn = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C3.5',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Que reste-t-il sur la feuille ?\n\n{p}',
            'What is left on the paper?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b(rightFr, rightEn), correct: true),
        Choice(
            labelKeys: b('deux traits', 'two lines'),
            correct: false,
            misconception: 'C3.5-clear-does-nothing'),
        Choice(
            labelKeys: b('rien du tout', 'nothing at all'),
            correct: false,
            misconception: 'C3.5-clear-stops-the-program'),
        Choice(
            labelKeys: b('un trait, qui part du bord de la feuille',
                'one line, starting from the edge of the paper'),
            correct: false,
            misconception: 'C3.5-clear-moves-home'),
      ],
      itemHints: hints(
        'Ce qui est effacé, c\'est ce qui était dessiné AVANT.',
        'What gets erased is what was drawn BEFORE.',
        'Le programme continue après avoir effacé.',
        'The program carries on after erasing.',
      ),
      wrongChoiceFr: 'Effacer enlève ce qui précède et laisse le programme continuer.',
      wrongChoiceEn: 'Erasing removes what came before and lets the program carry on.',
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait nettoietout ?', 'What does clear do?'),
    choices: [
      Choice(
          labelKeys: b('Il efface la feuille et laisse Tika où elle est.',
              'It wipes the paper and leaves Tika where she is.'),
          correct: true),
      Choice(
          labelKeys: b('Il efface la feuille et ramène Tika au centre.',
              'It wipes the paper and sends Tika back to the centre.'),
          correct: false,
          misconception: 'C3.5-clear-moves-home'),
      Choice(
          labelKeys: b('Il arrête le programme.', 'It stops the program.'),
          correct: false,
          misconception: 'C3.5-clear-stops-the-program'),
      Choice(
          labelKeys: b('Il remet aussi le crayon en noir et fin.',
              'It also puts the pen back to thin and black.'),
          correct: false,
          misconception: 'C3.5-clear-equals-reset'),
    ],
    itemHints: hints(
      'Regarde d\'où repart le trait suivant.',
      'Look at where the next line starts from.',
      'Si Tika avait bougé, le trait suivant partirait du centre.',
      'If Tika had moved, the next line would start from the centre.',
    ),
    wrongChoiceFr: 'nettoietout efface la feuille, rien d\'autre.',
    wrongChoiceEn: 'Clear wipes the paper, and nothing else.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Et initialise ?', 'And what about reset?'),
    choices: [
      Choice(
          labelKeys: b(
              'Il remet tout comme au début : feuille vide, Tika au centre, '
                  'crayon noir et fin.',
              'It puts everything back to the start: empty paper, Tika in the '
                  'centre, a thin black pen.'),
          correct: true),
      Choice(
          labelKeys: b('Il fait exactement la même chose que nettoietout.',
              'It does exactly the same thing as clear.'),
          correct: false,
          misconception: 'C3.5-clear-equals-reset'),
      Choice(
          labelKeys: b('Il garde les réglages du crayon.',
              'It keeps the pen settings.'),
          correct: false,
          misconception: 'C3.5-reset-keeps-pen'),
      Choice(
          labelKeys: b('Il efface le programme.', 'It erases the program.'),
          correct: false,
          misconception: 'C3.5-reset-erases-code'),
    ],
    itemHints: hints(
      'Initialiser, c\'est repartir de zéro.',
      'Resetting means starting from nothing.',
      'De zéro veut dire les réglages aussi.',
      'From nothing means the settings too.',
    ),
    wrongChoiceFr: 'initialise remet la feuille, la position ET les réglages du crayon.',
    wrongChoiceEn: 'Reset restores the paper, the position AND the pen settings.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Tu as mis le fond en bleu, puis tu écris initialise. Le fond reste-t-il bleu ?',
      'You made the background blue, then you write reset. Does the background stay blue?',
    ),
    choices: [
      Choice(
          labelKeys: b('Non : le fond redevient blanc, comme au début.',
              'No: the background goes back to white, as at the start.'),
          correct: true),
      Choice(
          labelKeys: b('Oui : le fond n\'est pas un dessin.',
              'Yes: the background is not a drawing.'),
          correct: false,
          misconception: 'C3.5-reset-keeps-pen'),
      Choice(
          labelKeys: b('Oui, mais seulement si Tika est au centre.',
              'Yes, but only if Tika is in the centre.'),
          correct: false,
          misconception: 'C3.5-clear-equals-reset'),
      Choice(
          labelKeys: b('Oui : initialise ne touche qu\'à Tika.',
              'Yes: reset only touches Tika.'),
          correct: false,
          misconception: 'C3.5-reset-keeps-pen'),
    ],
    itemHints: hints(
      'Initialise remet TOUT comme au début.',
      'Reset puts EVERYTHING back as it was at the start.',
      'Le fond est un réglage, et les réglages reviennent aussi.',
      'The background is a setting, and settings come back too.',
    ),
    wrongChoiceFr: 'initialise remet aussi la couleur du fond.',
    wrongChoiceEn: 'Reset restores the background colour as well.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.5',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d4,
    promptKeys: b(
      'Kofi veut effacer son brouillon et continuer son dessin là où il en était. '
          'Quelle commande choisit-il, et pourquoi ?',
      'Kofi wants to erase his rough draft and carry on drawing from where he was. '
          'Which command does he pick, and why?',
    ),
    choices: [
      Choice(
          labelKeys: b(
              'nettoietout, parce qu\'il veut garder la position de Tika.',
              'Clear, because he wants to keep Tika where she is.'),
          correct: true),
      Choice(
          labelKeys: b('initialise, parce que c\'est plus propre.',
              'Reset, because it is tidier.'),
          correct: false,
          misconception: 'C3.5-clear-equals-reset'),
      Choice(
          labelKeys: b('Les deux marchent pareil ici.',
              'Either one works the same here.'),
          correct: false,
          misconception: 'C3.5-clear-equals-reset'),
      Choice(
          labelKeys: b('Ni l\'un ni l\'autre : il doit tout réécrire.',
              'Neither: he has to write it all again.'),
          correct: false,
          misconception: 'C3.5-no-erase'),
    ],
    itemHints: hints(
      'Ce qu\'il veut garder, c\'est où il en était.',
      'What he wants to keep is where he had got to.',
      'Une des deux commandes le ramènerait au centre.',
      'One of the two would send him back to the centre.',
    ),
    wrongChoiceFr: 'initialise ramènerait Tika au centre, et il perdrait sa place.',
    wrongChoiceEn: 'Reset would send Tika back to the centre, and he would lose his place.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C3.5',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d4,
    promptKeys: b(
      'Pourquoi deux commandes pour effacer, au lieu d\'une seule ?',
      'Why two commands for erasing, instead of just one?',
    ),
    choices: [
      Choice(
          labelKeys: b(
              'Parce que « effacer la feuille » et « tout remettre à zéro » '
                  'ne sont pas la même chose.',
              'Because "wipe the paper" and "put everything back" are not the '
                  'same thing.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que l\'une est plus rapide que l\'autre.',
              'Because one is faster than the other.'),
          correct: false,
          misconception: 'C3.5-clear-equals-reset'),
      Choice(
          labelKeys: b('Parce que l\'une marche en blocs et l\'autre en texte.',
              'Because one works in blocks and the other in text.'),
          correct: false,
          misconception: 'C3.5-two-languages'),
      Choice(
          labelKeys: b('Parce que l\'une est pour les enfants et l\'autre pour les grands.',
              'Because one is for children and the other for grown-ups.'),
          correct: false,
          misconception: 'C3.5-two-languages'),
    ],
    itemHints: hints(
      'Compare ce que chacune laisse derrière elle.',
      'Compare what each one leaves behind.',
      'L\'une laisse Tika et ses réglages, l\'autre non.',
      'One leaves Tika and her settings alone, the other does not.',
    ),
    wrongChoiceFr: 'Elles ne laissent pas le même état derrière elles.',
    wrongChoiceEn: 'They do not leave the same state behind them.',
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

TutorialStep watchStep(
  String conceptId,
  String fr,
  String en,
  String demo, {
  required List<String> ideas,
  SpotlightTarget spotlight = SpotlightTarget.canvas,
}) =>
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

TutorialStep togetherStep(
  String conceptId,
  String fr,
  String en, {
  required String opcodeId,
  required String hintFr,
  required String hintEn,
  ExpectedAction action = ExpectedAction.placeBlock,
}) =>
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

TutorialStep doStep(
  String conceptId,
  String fr,
  String en, {
  required String opcodeId,
  required String hintFr,
  required String hintEn,
}) =>
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

List<Tutorial> world3Tutorials() => [
      tutorialFor(
        conceptId: 'C3.1',
        conceptName: b('Lever et baisser le crayon', 'Lifting and lowering the pen'),
        steps: [
          watchStep(
            'C3.1',
            'Regarde. Tika avance deux fois. Un seul trait apparaît.',
            'Watch. Tika moves twice. Only one line appears.',
            'avance 60\nlèvecrayon\navance 40\nbaissecrayon\navance 60',
            ideas: ['le crayon se lève', 'un déplacement sans trace'],
          ),
          togetherStep(
            'C3.1',
            'À toi : place le bloc qui lève le crayon.',
            'Your turn: place the block that lifts the pen.',
            opcodeId: 'PEN_UP',
            hintFr: 'Cherche le bloc « lève le crayon » dans la famille Stylo.',
            hintEn: 'Look for the "pen up" block in the Pen family.',
          ),
          doStep(
            'C3.1',
            'Dessine deux traits séparés.',
            'Draw two separate lines.',
            opcodeId: 'PEN_DOWN',
            hintFr: 'Lève le crayon pour te déplacer, baisse-le pour dessiner.',
            hintEn: 'Lift the pen to travel, lower it to draw.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C3.2',
        conceptName: b('Choisir l\'épaisseur', 'Choosing the thickness'),
        steps: [
          watchStep(
            'C3.2',
            'Un seul réglage. Les quatre côtés sont épais.',
            'One setting. All four sides are thick.',
            'largeurcrayon 10\nrépète 4 {\n  avance 60\n  tournedroite 90\n}',
            ideas: ['un réglage qui reste'],
          ),
          togetherStep(
            'C3.2',
            'Change le nombre pour rendre le trait plus fin.',
            'Change the number to make the line thinner.',
            opcodeId: 'PEN_WIDTH',
            action: ExpectedAction.editNumber,
            hintFr: 'Appuie sur le nombre dans le bloc d\'épaisseur.',
            hintEn: 'Tap the number in the thickness block.',
          ),
          doStep(
            'C3.2',
            'Dessine un triangle avec un crayon épais.',
            'Draw a triangle with a thick pen.',
            opcodeId: 'PEN_WIDTH',
            hintFr: 'Règle l\'épaisseur AVANT de commencer le triangle.',
            hintEn: 'Set the thickness BEFORE you start the triangle.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C3.3',
        conceptName: b('Trois nombres pour une couleur', 'Three numbers for a colour'),
        steps: [
          watchStep(
            'C3.3',
            'Rouge puis vert puis bleu. Trois nombres font une couleur.',
            'Red then green then blue. Three numbers make one colour.',
            'couleurcrayon 255, 0, 0\navance 60\n'
                'couleurcrayon 0, 0, 255\ntournedroite 90\navance 60',
            ideas: ['rouge vert bleu', '0 à 255'],
          ),
          togetherStep(
            'C3.3',
            'Mets le premier nombre à 255 pour avoir un rouge vif.',
            'Set the first number to 255 for a bright red.',
            opcodeId: 'PEN_COLOR',
            action: ExpectedAction.editNumber,
            hintFr: 'Le premier des trois nombres, c\'est le rouge.',
            hintEn: 'The first of the three numbers is red.',
          ),
          doStep(
            'C3.3',
            'Dessine un carré de la couleur que tu veux.',
            'Draw a square in any colour you like.',
            opcodeId: 'PEN_COLOR',
            hintFr: 'Choisis la couleur avant de dessiner le carré.',
            hintEn: 'Choose the colour before you draw the square.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C3.4',
        conceptName: b('La feuille et le crayon', 'The paper and the pen'),
        steps: [
          watchStep(
            'C3.4',
            'La feuille a sa couleur. Le crayon a la sienne.',
            'The paper has its colour. The pen has its own.',
            'couleurcanevas 20, 30, 60\ncouleurcrayon 255, 255, 0\n'
                'répète 4 {\n  avance 60\n  tournedroite 90\n}',
            ideas: ['la feuille a une couleur', 'la feuille a une taille'],
          ),
          togetherStep(
            'C3.4',
            'Colore la feuille, pas le trait.',
            'Colour the paper, not the line.',
            opcodeId: 'CANVAS_COLOR',
            hintFr: 'Le bloc qui commence par « canevas » agit sur la feuille.',
            hintEn: 'The block that starts with "canvas" acts on the paper.',
          ),
          doStep(
            'C3.4',
            'Dessine une figure claire sur un fond sombre.',
            'Draw a light shape on a dark background.',
            opcodeId: 'CANVAS_COLOR',
            hintFr: 'Un couleurcanevas sombre, puis un couleurcrayon clair.',
            hintEn: 'A dark canvas colour, then a light pen colour.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C3.5',
        conceptName: b('Effacer, ou tout remettre', 'Erasing, or putting it all back'),
        steps: [
          watchStep(
            'C3.5',
            'Regarde où repart le trait. Tika n\'a pas bougé.',
            'Watch where the line starts. Tika has not moved.',
            'avance 60\ntournedroite 90\nnettoietout\navance 60',
            ideas: ['effacer ne déplace pas'],
          ),
          togetherStep(
            'C3.5',
            'Efface la feuille sans déplacer Tika.',
            'Wipe the paper without moving Tika.',
            opcodeId: 'CLEAR',
            hintFr: 'Une des deux commandes ramène Tika au centre. Prends l\'autre.',
            hintEn: 'One of the two sends Tika back to the centre. Take the other one.',
          ),
          doStep(
            'C3.5',
            'Efface ton brouillon. Continue ton dessin sur place.',
            'Erase your sketch. Carry on drawing where you are.',
            opcodeId: 'CLEAR',
            hintFr: 'nettoietout efface la feuille et rien d\'autre.',
            hintEn: 'Clear wipes the paper and nothing else.',
          ),
        ],
      ),
    ];

// ═══════════════════════════════════════════════════════════════════════════════════════

void main() {
  final items = [
    ...conceptC31(),
    ...conceptC32(),
    ...conceptC33(),
    ...conceptC34(),
    ...conceptC35(),
  ];
  final tutorials = world3Tutorials();

  stdout.writeln(
      'World 3 — authored ${items.length} items, ${tutorials.length} tutorials');

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
    'C3.1': 20,
    'C3.2': 18,
    'C3.3': 22,
    'C3.4': 20,
    'C3.5': 18,
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
    world: 3,
    version: 1,
    nameKeys: b('Couleurs et crayon', 'Colours and pen'),
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
    assetKeys: const ['art/tika.svg', 'art/world3-crayon.svg'],
  );

  final encoded = const JsonEncoder.withIndent('  ').convert(pack.toJson());
  final sized = ContentPack.fromJson({
    ...pack.toJson(),
    'sizeBytes': utf8.encode(encoded).length,
  });
  final manifest = PackManifest.of(sized);

  final dir = Directory('../../content');
  dir.createSync(recursive: true);
  File('${dir.path}/world3.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sized.toJson())}\n');
  File('${dir.path}/world3.manifest.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n');

  stdout.writeln('\nPublished content/world3.json');
  stdout.writeln(
      '  ${sized.sizeBytes} bytes of ${ContentPack.worldBudgetBytes} budget '
      '(${(sized.sizeBytes / ContentPack.worldBudgetBytes * 100).toStringAsFixed(1)} %)');
  stdout.writeln('  sha256 ${manifest.contentHash.substring(0, 16)}…');
  stdout.writeln('  audio keys: ${sized.audioKeys.length}');
}
