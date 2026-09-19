// Authors World 5 — "Quand…" — and writes it out as a content pack.
//
//     dart tool/author_world5.dart
//
// The first world KODO could not say. D-014 gave the language `quand`, three triggers and
// scripts that take turns; this is the curriculum that needed them.
//
// World 5 is where a program stops being a list and becomes a thing that waits. The four
// misconceptions in the ledger are four ways of not believing that:
//
//   C5.1  "the script needs me to click the blocks"
//   C5.2  "the key works only once"
//   C5.3  "any click anywhere triggers it"
//   C5.4  "programs can only do one thing at a time"
//
// Every item declares the trigger it runs under. Without that they would all grade
// vacuously: a `quand touche` script never fires under the green flag, so the target and
// every answer would draw nothing and all of them would pass.

import 'dart:convert';
import 'dart:io';

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';


Map<String, String> b(String fr, String en) => {'fr': fr, 'en': en};

const conceptGraph = <String, List<String>>{
  'C5.1': ['C0.1'],
  'C5.2': ['C5.1'],
  'C5.3': ['C5.1'],
  'C5.4': ['C5.2'],
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
  'PRINT',
  'WHEN_FLAG',
  'WHEN_KEY',
  'WHEN_CLICKED',
];

/// A script, written the way a child writes one.
String script(String trigger, String body) =>
    'quand $trigger {\n${body.split('\n').map((l) => '  $l').join('\n')}\n}';

// ═══════════════════════════════════════════════════════════════════════════════════════
// C5.1 — Quand le drapeau vert est cliqué.
// Misconception: "the script needs me to click the blocks".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC51() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C5.1-${(++n).toString().padLeft(2, '0')}';

  // T1 — put a figure under the flag.
  for (final entry in [
    (4, 90, 60),
    (3, 120, 70),
    (6, 60, 40),
    (5, 72, 50),
    (8, 45, 35),
    (4, 90, 90),
    (3, 120, 50),
    (12, 30, 25),
  ]) {
    final sides = entry.$1, turn = entry.$2, side = entry.$3;
    final figure = 'répète $sides {\n  avance $side\n  tournedroite $turn\n}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C5.1',
      difficulty: sides <= 4 ? Difficulty.d1 : Difficulty.d2,
      solution: script('drapeau', figure),
      promptKeys: fillBoth(
        b('Fais en sorte que la figure à {k} côtés se dessine toute seule '
            'quand on appuie sur le drapeau vert.',
            'Make the {k}-sided shape draw itself when the green flag is '
            'pressed.'),
        {'k': sides, 's': side},
      ),
      wrong: [
        // The misconception: the figure is there, but nothing says when.
        figure,
        // Under the wrong trigger: nothing happens when the flag is pressed.
        script('clic', figure),
        script('touche "espace"', figure),
      ],
      /* The trigger cannot be seen in the drawing. A program with no `quand` at all
         still runs under the green flag — it has to, or every item in Worlds 0 to 4 stops
         working — so "you forgot the trigger" draws exactly the right picture. The claim
         is structural, so it is checked structurally, and the child is told they got
         there the wrong way rather than that their figure is wrong. */
      assertions: const [UsesOpcode('WHEN_FLAG')],
      itemHints: hints(
        'Il faut dire QUAND la figure se dessine.',
        'You have to say WHEN the shape gets drawn.',
        'Mets la figure dans un bloc « quand drapeau ».',
        'Put the shape inside a "when flag" block.',
        spotlight: 'WHEN_FLAG',
      ),
      lookAtFr: 'Appuie sur le drapeau et regarde.',
      lookAtEn: 'Press the flag and look.',
      paletteScope: palette,
    ));
  }

  // T3 — predict which script runs.
  for (final entry in [
    ('quand drapeau {\n  avance 50\n}', 'la figure se dessine',
        'the shape gets drawn'),
    ('avance 50', 'la figure se dessine', 'the shape gets drawn'),
    ('quand clic {\n  avance 50\n}', 'rien ne se passe', 'nothing happens'),
    ('quand touche "a" {\n  avance 50\n}', 'rien ne se passe',
        'nothing happens'),
  ]) {
    final source = entry.$1, rightFr = entry.$2, rightEn = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C5.1',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('On appuie sur le drapeau vert. Que se passe-t-il ?\n\n{p}',
            'The green flag is pressed. What happens?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b(rightFr, rightEn), correct: true),
        Choice(
            labelKeys: rightFr == 'rien ne se passe'
                ? b('la figure se dessine', 'the shape gets drawn')
                : b('rien ne se passe', 'nothing happens'),
            correct: false,
            misconception: 'C5.1-trigger-ignored'),
        Choice(
            labelKeys: b('il faut cliquer sur les blocs',
                'you have to click the blocks'),
            correct: false,
            misconception: 'C5.1-click-the-blocks'),
        Choice(
            labelKeys: b('le programme s\'efface', 'the program is erased'),
            correct: false,
            misconception: 'C5.1-flag-clears'),
      ],
      itemHints: hints(
        'Regarde ce qui est écrit après « quand ».',
        'Look at what comes after "when".',
        'Un script ne part que sur SON déclencheur.',
        'A script only starts on ITS OWN trigger.',
      ),
      wrongChoiceFr: 'Un script part tout seul, et seulement sur son déclencheur.',
      wrongChoiceEn: 'A script starts on its own, and only on its own trigger.',
    ));
  }

  // T4 — fill the gap.
  for (final side in [40, 60, 80, 50, 30, 70]) {
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C5.1',
      difficulty: Difficulty.d1,
      withHoles: 'quand ___ {\n  avance $side\n}',
      solution: 'quand drapeau {\n  avance $side\n}',
      promptKeys: fillBoth(
        b('Complète : le trait de {s} pas doit se dessiner quand on appuie '
            'sur le drapeau vert.',
            'Fill in the blank: the {s}-step line must be drawn when the green '
            'flag is pressed.'),
        {'s': side},
      ),
      wrong: [
        'quand clic {\n  avance $side\n}',
        'quand touche "espace" {\n  avance $side\n}',
        'avance $side',
      ],
      assertions: const [UsesOpcode('WHEN_FLAG')],
      itemHints: hints(
        'Le drapeau vert a un nom dans le bloc.',
        'The green flag has a name inside the block.',
        'C\'est « drapeau ».',
        'It is "flag".',
        spotlight: 'WHEN_FLAG',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C5.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('À quoi sert le bloc « quand drapeau » ?',
        'What is the "when flag" block for?'),
    choices: [
      Choice(
          labelKeys: b('À dire quand le programme doit partir.',
              'To say when the program should start.'),
          correct: true),
      Choice(
          labelKeys: b('À dessiner un drapeau.', 'To draw a flag.'),
          correct: false,
          misconception: 'C5.1-flag-is-a-drawing'),
      Choice(
          labelKeys: b('À rendre le programme plus rapide.',
              'To make the program faster.'),
          correct: false,
          misconception: 'C5.1-flag-is-speed'),
      Choice(
          labelKeys: b('À effacer la feuille avant de commencer.',
              'To wipe the paper before starting.'),
          correct: false,
          misconception: 'C5.1-flag-clears'),
    ],
    itemHints: hints(
      'Le bloc ne dessine rien lui-même.',
      'The block does not draw anything itself.',
      'Il dit QUAND ce qui est dedans se fait.',
      'It says WHEN what is inside happens.',
    ),
    wrongChoiceFr: 'C\'est un déclencheur : il dit quand, pas quoi.',
    wrongChoiceEn: 'It is a trigger: it says when, not what.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C5.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Ton programme a un bloc « quand drapeau ». Faut-il cliquer sur les '
            'blocs pour qu\'il parte ?',
        'Your program has a "when flag" block. Do you have to click the blocks '
            'to make it go?'),
    choices: [
      Choice(
          labelKeys: b('Non : il part quand on appuie sur le drapeau vert.',
              'No: it goes when the green flag is pressed.'),
          correct: true),
      Choice(
          labelKeys: b('Oui, sur chaque bloc, dans l\'ordre.',
              'Yes, on each block, in order.'),
          correct: false,
          misconception: 'C5.1-click-the-blocks'),
      Choice(
          labelKeys: b('Oui, sur le premier bloc seulement.',
              'Yes, on the first block only.'),
          correct: false,
          misconception: 'C5.1-click-the-blocks'),
      Choice(
          labelKeys: b('Seulement la première fois.', 'Only the first time.'),
          correct: false,
          misconception: 'C5.1-runs-once'),
    ],
    itemHints: hints(
      'C\'est le drapeau qui déclenche.',
      'The flag is what sets it off.',
      'Les blocs se lisent tout seuls, du haut vers le bas.',
      'The blocks read themselves, from the top down.',
    ),
    wrongChoiceFr: 'Le déclencheur fait partir le script tout entier, tout seul.',
    wrongChoiceEn: 'The trigger starts the whole script, by itself.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C5.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Peut-on appuyer deux fois sur le drapeau vert ?',
        'Can you press the green flag twice?'),
    choices: [
      Choice(
          labelKeys: b('Oui : le script repart depuis le début à chaque fois.',
              'Yes: the script runs again from the start each time.'),
          correct: true),
      Choice(
          labelKeys: b('Non : un script ne part qu\'une fois.',
              'No: a script only runs once.'),
          correct: false,
          misconception: 'C5.1-runs-once'),
      Choice(
          labelKeys: b('Oui, mais il continue où il s\'était arrêté.',
              'Yes, but it carries on where it stopped.'),
          correct: false,
          misconception: 'C5.1-resumes'),
      Choice(
          labelKeys: b('Seulement si on efface la feuille avant.',
              'Only if you wipe the paper first.'),
          correct: false,
          misconception: 'C5.1-flag-clears'),
    ],
    itemHints: hints(
      'Essaie : appuie, puis appuie encore.',
      'Try it: press, then press again.',
      'Le déclencheur peut se produire autant de fois qu\'on veut.',
      'The trigger can happen as many times as you like.',
    ),
    wrongChoiceFr: 'Un déclencheur se produit autant de fois qu\'on le déclenche.',
    wrongChoiceEn: 'A trigger happens as many times as you set it off.',
  ));

  // T9 — open build, with the rubric shown first (FR-M6-06).
  for (final entry in [
    ('un dessin qui part tout seul', 'a drawing that starts on its own'),
    ('ton initiale, tracée au drapeau', 'your initial, drawn on the flag'),
  ]) {
    final fr = entry.$1, en = entry.$2;
    items.add(openBuild(
      id: id(),
      conceptId: 'C5.1',
      difficulty: Difficulty.d3,
      promptKeys: b(
        'Fais $fr. Voici ce qu\'il faut, et tu le sais avant de commencer :',
        'Make $en. Here is what it needs, and you know it before you start:',
      ),
      rubric: [
        rubricLine('Il y a un bloc « quand drapeau ».',
            'There is a "when flag" block.', const UsesOpcode('WHEN_FLAG')),
        rubricLine('Le dessin est à l\'intérieur du bloc.',
            'The drawing is inside the block.',
            const UsesOpcode('MOVE_FORWARD', min: 2)),
        rubricLine('Tika tourne au moins une fois.',
            'Tika turns at least once.', const UsesOpcode('TURN_RIGHT')),
      ],
      itemHints: hints(
        'Commence par le bloc « quand drapeau ».',
        'Start with the "when flag" block.',
        'Puis mets ton dessin dedans.',
        'Then put your drawing inside it.',
        spotlight: 'WHEN_FLAG',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C5.2 — Quand une touche est pressée. Misconception: "the key works only once".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC52() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C5.2-${(++n).toString().padLeft(2, '0')}';

  // T1 — a script on a named key. Graded under that key, or it grades nothing.
  for (final entry in [
    ('espace', 'avance 60'),
    ('a', 'tournegauche 90\navance 50'),
    ('d', 'tournedroite 90\navance 50'),
    ('haut', 'direction 0\navance 60'),
    ('bas', 'direction 180\navance 60'),
    ('gauche', 'direction 270\navance 60'),
    ('droite', 'direction 90\navance 60'),
    ('w', 'avance 40\ntournedroite 45'),
  ]) {
    final key = entry.$1, body = entry.$2;
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C5.2',
      difficulty: key == 'espace' ? Difficulty.d1 : Difficulty.d2,
      solution: script('touche "$key"', body),
      promptKeys: fillBoth(
        b('Fais en sorte que cela se passe quand on appuie sur la touche {k}.',
            'Make this happen when the {k} key is pressed.'),
        {'k': key},
      ),
      wrong: [
        // No trigger: nothing waits for the key.
        body,
        // The wrong key: it waits for something that will not happen.
        script('touche "${key == 'espace' ? 'z' : 'espace'}"', body),
        // The flag instead of the key.
        script('drapeau', body),
      ],
      assertions: const [UsesOpcode('WHEN_KEY')],
      itemHints: hints(
        'Il faut nommer la touche dans le bloc.',
        'You have to name the key inside the block.',
        'quand touche "$key".',
        'When key "$key".',
        spotlight: 'WHEN_KEY',
      ),
      paletteScope: palette,
      // The item runs under the key it is about. Under the flag, nothing fires at all
      // and every answer would be indistinguishable from every other.
      runTrigger: 'key:$key',
    ));
  }

  // T2 — the bug is the wrong key, or a missing one.
  for (final entry in [
    ('espace', 'z', 'avance 60'),
    ('a', 'q', 'tournegauche 90\navance 40'),
    ('haut', 'bas', 'direction 0\navance 50'),
    ('droite', 'gauche', 'direction 90\navance 50'),
  ]) {
    final wanted = entry.$1, typed = entry.$2, body = entry.$3;
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C5.2',
      difficulty: Difficulty.d2,
      broken: script('touche "$typed"', body),
      solution: script('touche "$wanted"', body),
      promptKeys: fillBoth(
        b('Rien ne se passe quand on appuie sur {k}. Répare.',
            'Nothing happens when {k} is pressed. Fix it.'),
        {'k': wanted},
      ),
      wrong: [
        script('touche "$typed"', body),
        script('drapeau', body),
        body,
      ],
      assertions: const [UsesOpcode('WHEN_KEY')],
      itemHints: hints(
        'Le script attend une autre touche.',
        'The script is waiting for a different key.',
        'Change le nom de la touche.',
        'Change the key\'s name.',
        spotlight: 'WHEN_KEY',
      ),
      paletteScope: palette,
      runTrigger: 'key:$wanted',
    ));
  }

  // T3 — predict.
  for (final entry in [
    ('quand touche "espace" {\n  avance 50\n}', 'espace', true),
    ('quand touche "a" {\n  avance 50\n}', 'espace', false),
    ('quand drapeau {\n  avance 50\n}', 'espace', false),
    ('quand touche "espace" {\n  avance 50\n}', 'a', false),
  ]) {
    final source = entry.$1, pressed = entry.$2, fires = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C5.2',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('On appuie sur la touche {k}. Que se passe-t-il ?\n\n{p}',
            'The {k} key is pressed. What happens?\n\n{p}'),
        {'k': pressed, 'p': source},
      ),
      choices: [
        Choice(
            labelKeys: fires
                ? b('Tika avance.', 'Tika moves.')
                : b('Rien ne se passe.', 'Nothing happens.'),
            correct: true),
        Choice(
            labelKeys: fires
                ? b('Rien ne se passe.', 'Nothing happens.')
                : b('Tika avance.', 'Tika moves.'),
            correct: false,
            misconception: 'C5.2-any-key'),
        Choice(
            labelKeys: b('Tika avance, mais une seule fois pour toujours.',
                'Tika moves, but only once ever.'),
            correct: false,
            misconception: 'C5.2-key-works-once'),
        Choice(
            labelKeys: b('Le programme s\'arrête.', 'The program stops.'),
            correct: false,
            misconception: 'C5.2-key-stops'),
      ],
      itemHints: hints(
        'Compare la touche appuyée et la touche écrite.',
        'Compare the key pressed with the key written.',
        'Un script n\'écoute que sa propre touche.',
        'A script only listens for its own key.',
      ),
      wrongChoiceFr: 'Chaque script écoute une seule touche, et autant de fois qu\'on l\'appuie.',
      wrongChoiceEn: 'Each script listens for one key, as many times as it is pressed.',
    ));
  }

  // T4 — fill the gap.
  for (final key in ['espace', 'a', 'haut', 'd', 'bas', 'gauche']) {
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C5.2',
      difficulty: Difficulty.d1,
      withHoles: 'quand touche ___ {\n  avance 50\n}',
      solution: 'quand touche "$key" {\n  avance 50\n}',
      promptKeys: fillBoth(
        b('Complète : Tika doit avancer quand on appuie sur {k}.',
            'Fill in the blank: Tika must move when {k} is pressed.'),
        {'k': key},
      ),
      wrong: [
        'quand touche "${key == 'espace' ? 'z' : 'espace'}" {\n  avance 50\n}',
        'quand drapeau {\n  avance 50\n}',
        'avance 50',
      ],
      assertions: const [UsesOpcode('WHEN_KEY')],
      itemHints: hints(
        'Le nom de la touche s\'écrit entre guillemets.',
        'The key\'s name goes in quotes.',
        '"$key".',
        '"$key".',
        spotlight: 'WHEN_KEY',
      ),
      paletteScope: palette,
      runTrigger: 'key:$key',
    ));
  }

  // T9 — open build.
  for (final entry in [
    ('espace', 'un trait', 'a line'),
    ('a', 'un virage', 'a turn'),
  ]) {
    final key = entry.$1, fr = entry.$2, en = entry.$3;
    items.add(openBuild(
      id: id(),
      conceptId: 'C5.2',
      difficulty: Difficulty.d3,
      promptKeys: b(
        'Fais $fr qui se dessine quand on appuie sur $key. Voici ce qu\'il '
            'faut, et tu le sais avant de commencer :',
        'Make $en that gets drawn when $key is pressed. Here is what it needs, '
            'and you know it before you start:',
      ),
      rubric: [
        rubricLine('Il y a un bloc « quand touche ».',
            'There is a "when key" block.', const UsesOpcode('WHEN_KEY')),
        rubricLine('Tika avance à l\'intérieur.', 'Tika moves inside it.',
            const UsesOpcode('MOVE_FORWARD')),
        rubricLine('Tout tient en dix blocs ou moins.',
            'It all fits in ten blocks or fewer.',
            const BlockCountWithin(max: 10)),
      ],
      itemHints: hints(
        'Commence par le bloc « quand touche ».',
        'Start with the "when key" block.',
        'Écris le nom de la touche entre guillemets.',
        'Write the key\'s name in quotes.',
        spotlight: 'WHEN_KEY',
      ),
      paletteScope: palette,
      runTrigger: 'key:$key',
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C5.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Combien de fois une touche peut-elle déclencher son script ?',
        'How many times can a key set off its script?'),
    choices: [
      Choice(
          labelKeys: b('Autant de fois qu\'on appuie dessus.',
              'As many times as you press it.'),
          correct: true),
      Choice(
          labelKeys: b('Une seule fois.', 'Once only.'),
          correct: false,
          misconception: 'C5.2-key-works-once'),
      Choice(
          labelKeys: b('Une fois par appui sur le drapeau vert.',
              'Once per press of the green flag.'),
          correct: false,
          misconception: 'C5.2-flag-resets-keys'),
      Choice(
          labelKeys: b('Trois fois au maximum.', 'Three times at most.'),
          correct: false,
          misconception: 'C5.2-key-works-once'),
    ],
    itemHints: hints(
      'Essaie : appuie plusieurs fois de suite.',
      'Try it: press it several times in a row.',
      'Le script repart à chaque appui.',
      'The script starts again on every press.',
    ),
    wrongChoiceFr: 'Une touche déclenche son script à chaque fois qu\'on l\'appuie.',
    wrongChoiceEn: 'A key sets off its script every time it is pressed.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C5.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Tu veux qu\'une touche fasse avancer et une autre fasse tourner. '
            'Combien de scripts ?',
        'You want one key to move and another to turn. How many scripts?'),
    choices: [
      Choice(
          labelKeys: b('Deux : un par touche.', 'Two: one per key.'),
          correct: true),
      Choice(
          labelKeys: b('Un seul, avec les deux touches dedans.',
              'One, with both keys inside it.'),
          correct: false,
          misconception: 'C5.2-one-script-many-keys'),
      Choice(
          labelKeys: b('Un seul, et Tika choisit.',
              'One, and Tika decides.'),
          correct: false,
          misconception: 'C5.2-turtle-chooses'),
      Choice(
          labelKeys: b('Trois : deux touches et le drapeau.',
              'Three: two keys and the flag.'),
          correct: false,
          misconception: 'C5.2-flag-required'),
    ],
    itemHints: hints(
      'Un bloc « quand » ne nomme qu\'une touche.',
      'A "when" block names one key.',
      'Deux touches, deux blocs.',
      'Two keys, two blocks.',
    ),
    wrongChoiceFr: 'Chaque bloc « quand touche » nomme une seule touche.',
    wrongChoiceEn: 'Each "when key" block names exactly one key.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C5.3 — Quand on clique sur le lutin. Misconception: "any click anywhere triggers it".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC53() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C5.3-${(++n).toString().padLeft(2, '0')}';

  // T1.
  for (final entry in [
    ('tournedroite 90', 'tourne d\'un quart de tour', 'turns a quarter turn'),
    ('avance 40\nrecule 40', 'fait un aller-retour', 'goes there and back'),
    ('couleurcrayon 255, 0, 0\navance 50', 'trace un trait rouge',
        'draws a red line'),
    ('répète 3 {\n  avance 30\n  tournedroite 120\n}', 'trace un triangle',
        'draws a triangle'),
    ('répète 4 {\n  avance 35\n  tournedroite 90\n}', 'trace un carré',
        'draws a square'),
    ('direction 180\navance 50', 'descend', 'goes down'),
    ('couleurcrayon 0, 0, 255\nrépète 6 {\n  avance 20\n'
        '  tournedroite 60\n}', 'trace un hexagone bleu',
        'draws a blue hexagon'),
  ]) {
    final body = entry.$1, fr = entry.$2, en = entry.$3;
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C5.3',
      difficulty: Difficulty.d2,
      solution: script('clic', body),
      /* `equivalentsOf` only rewrites `avance`/`tourne` lines, and a body that has
         neither — `recule 40`, `direction 180` — produces one alternative instead of
         two. The second is authored: the same script with its lines written the long way
         round, which is a real thing a child does. */
      alternatives: [
        '# une autre façon\n${script('clic', body)}',
        script('clic', '$body\n# fini'),
      ],
      promptKeys: b('Fais en sorte que Tika $fr quand on clique sur elle.',
          'Make Tika $en when she is clicked.'),
      wrong: [
        body,
        script('drapeau', body),
        script('touche "espace"', body),
      ],
      assertions: const [UsesOpcode('WHEN_CLICKED')],
      itemHints: hints(
        'Le déclencheur est le clic sur Tika.',
        'The trigger is a click on Tika.',
        'quand clic.',
        'When clicked.',
        spotlight: 'WHEN_CLICKED',
      ),
      paletteScope: palette,
      runTrigger: 'clicked',
    ));
  }

  // T4 — fill the gap.
  for (final body in [
    'tournedroite 90',
    'avance 50',
    'couleurcrayon 0, 0, 255\navance 40',
    'recule 40',
    'direction 90\navance 30',
  ]) {
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C5.3',
      difficulty: Difficulty.d1,
      withHoles: 'quand ___ {\n${body.split('\n').map((l) => '  $l').join('\n')}\n}',
      solution: script('clic', body),
      alternatives: [
        '# une autre façon\n${script('clic', body)}',
        script('clic', '$body\n# fini'),
      ],
      promptKeys: b('Complète : cela doit se passer quand on clique sur Tika.',
          'Fill in the blank: this must happen when Tika is clicked.'),
      wrong: [
        script('drapeau', body),
        script('touche "espace"', body),
        body,
      ],
      assertions: const [UsesOpcode('WHEN_CLICKED')],
      itemHints: hints(
        'Le mot du bloc est court.',
        'The block\'s word is short.',
        'C\'est « clic ».',
        'It is "clicked".',
        spotlight: 'WHEN_CLICKED',
      ),
      paletteScope: palette,
      runTrigger: 'clicked',
    ));
  }

  // T3 — predict which trigger fires.
  for (final entry in [
    ('quand clic {\n  avance 50\n}', 'on clique sur Tika', 'Tika is clicked',
        true),
    ('quand clic {\n  avance 50\n}', 'on appuie sur le drapeau',
        'the flag is pressed', false),
    ('quand drapeau {\n  avance 50\n}', 'on clique sur Tika',
        'Tika is clicked', false),
    ('quand clic {\n  avance 50\n}', 'on appuie sur espace',
        'space is pressed', false),
  ]) {
    final source = entry.$1, whatFr = entry.$2, whatEn = entry.$3;
    final fires = entry.$4;
    items.add(predict(
      id: id(),
      conceptId: 'C5.3',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Que se passe-t-il si {w} ?\n\n{p}',
            'What happens if {e}?\n\n{p}'),
        {'w': whatFr, 'e': whatEn, 'p': source},
      ),
      choices: [
        Choice(
            labelKeys: fires
                ? b('Tika avance.', 'Tika moves.')
                : b('Rien ne se passe.', 'Nothing happens.'),
            correct: true),
        Choice(
            labelKeys: fires
                ? b('Rien ne se passe.', 'Nothing happens.')
                : b('Tika avance.', 'Tika moves.'),
            correct: false,
            misconception: 'C5.3-any-click'),
        Choice(
            labelKeys: b('Tika avance deux fois.', 'Tika moves twice.'),
            correct: false,
            misconception: 'C5.3-double-fire'),
        Choice(
            labelKeys: b('Le programme s\'efface.', 'The program is erased.'),
            correct: false,
            misconception: 'C5.3-click-stops'),
      ],
      itemHints: hints(
        'Compare ce qu\'on fait et ce que le bloc attend.',
        'Compare what you do with what the block is waiting for.',
        'Un script n\'écoute que son propre déclencheur.',
        'A script only listens for its own trigger.',
      ),
      wrongChoiceFr: 'Chaque script attend un déclencheur précis, et rien d\'autre.',
      wrongChoiceEn: 'Each script waits for one particular trigger, and nothing else.',
    ));
  }

  // T6.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C5.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Tu cliques à côté de Tika, sur le fond. Que se passe-t-il ?',
        'You click next to Tika, on the background. What happens?'),
    choices: [
      Choice(
          labelKeys: b('Rien : il faut cliquer sur Tika elle-même.',
              'Nothing: you have to click Tika herself.'),
          correct: true),
      Choice(
          labelKeys: b('Le script part quand même.',
              'The script runs anyway.'),
          correct: false,
          misconception: 'C5.3-any-click'),
      Choice(
          labelKeys: b('Tika se déplace là où on a cliqué.',
              'Tika moves to where you clicked.'),
          correct: false,
          misconception: 'C5.3-click-moves'),
      Choice(
          labelKeys: b('Le programme s\'arrête.', 'The program stops.'),
          correct: false,
          misconception: 'C5.3-click-stops'),
    ],
    itemHints: hints(
      'Lis le nom du bloc en entier.',
      'Read the whole name of the block.',
      'C\'est un clic SUR Tika.',
      'It is a click ON Tika.',
    ),
    wrongChoiceFr: 'Le déclencheur est un clic sur Tika, pas un clic n\'importe où.',
    wrongChoiceEn: 'The trigger is a click on Tika, not a click anywhere.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C5.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Peut-on avoir un « quand clic » ET un « quand drapeau » ?',
        'Can you have a "when clicked" AND a "when flag"?'),
    choices: [
      Choice(
          labelKeys: b('Oui : chacun part sur son propre déclencheur.',
              'Yes: each one starts on its own trigger.'),
          correct: true),
      Choice(
          labelKeys: b('Non : un programme n\'a qu\'un déclencheur.',
              'No: a program has only one trigger.'),
          correct: false,
          misconception: 'C5.3-one-trigger-only'),
      Choice(
          labelKeys: b('Oui, mais le deuxième ne marche jamais.',
              'Yes, but the second never works.'),
          correct: false,
          misconception: 'C5.3-first-wins'),
      Choice(
          labelKeys: b('Seulement si on clique avant d\'appuyer sur le drapeau.',
              'Only if you click before pressing the flag.'),
          correct: false,
          misconception: 'C5.3-order-matters'),
    ],
    itemHints: hints(
      'Chaque script a sa propre porte d\'entrée.',
      'Each script has its own way in.',
      'Ils n\'attendent pas la même chose.',
      'They are not waiting for the same thing.',
    ),
    wrongChoiceFr: 'Un programme peut avoir autant de scripts que de déclencheurs.',
    wrongChoiceEn: 'A program can have as many scripts as it has triggers.',
  ));

  // T9.
  items.add(openBuild(
    id: id(),
    conceptId: 'C5.3',
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Fais un bouton : quand on clique sur Tika, il se passe quelque chose. '
          'Voici ce qu\'il faut, et tu le sais avant de commencer :',
      'Make a button: when Tika is clicked, something happens. Here is what it '
          'needs, and you know it before you start:',
    ),
    rubric: [
      rubricLine('Il y a un bloc « quand clic ».',
          'There is a "when clicked" block.',
          const UsesOpcode('WHEN_CLICKED')),
      rubricLine('Quelque chose se dessine à l\'intérieur.',
          'Something gets drawn inside it.',
          const UsesOpcode('MOVE_FORWARD')),
      rubricLine('Tika tourne au moins une fois.',
          'Tika turns at least once.', const UsesOpcode('TURN_RIGHT')),
    ],
    itemHints: hints(
      'Commence par « quand clic ».',
      'Start with "when clicked".',
      'Mets ton dessin dedans.',
      'Put your drawing inside.',
      spotlight: 'WHEN_CLICKED',
    ),
    paletteScope: palette,
    runTrigger: 'clicked',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C5.4 — Deux scripts en même temps.
// Misconception: "programs can only do one thing at a time".
//
// The concept D-014 exists for. Every item here runs under `any`, because the question is
// never which script starts — it is what happens when both do.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC54() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C5.4-${(++n).toString().padLeft(2, '0')}';

  /* T3 — predict the interleaving. The output order IS the concept: a child who believes
     programs do one thing at a time predicts A A B B, and the canvas says otherwise. */
  for (final entry in [
    (
      'quand drapeau {\n  écris "A1"\n  écris "A2"\n}\n'
          'quand drapeau {\n  écris "B1"\n  écris "B2"\n}',
      'A1 B1 A2 B2',
      'A1 A2 B1 B2',
    ),
    (
      'quand drapeau {\n  écris "1"\n  écris "3"\n}\n'
          'quand drapeau {\n  écris "2"\n  écris "4"\n}',
      '1 2 3 4',
      '1 3 2 4',
    ),
    (
      'quand drapeau {\n  écris "haut"\n  écris "bas"\n}\n'
          'quand drapeau {\n  écris "gauche"\n  écris "droite"\n}',
      'haut gauche bas droite',
      'haut bas gauche droite',
    ),
    (
      'quand drapeau {\n  écris "x"\n}\n'
          'quand drapeau {\n  écris "y"\n  écris "z"\n}',
      'x y z',
      'x y z, mais le deuxième script attend',
    ),
    (
      'quand drapeau {\n  écris "un"\n  écris "trois"\n  écris "cinq"\n}\n'
          'quand drapeau {\n  écris "deux"\n  écris "quatre"\n}',
      'un deux trois quatre cinq',
      'un trois cinq deux quatre',
    ),
  ]) {
    final source = entry.$1, right = entry.$2, wrong = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C5.4',
      difficulty: Difficulty.d4,
      promptKeys: fillBoth(
        b('Dans quel ordre les mots s\'écrivent-ils ?\n\n{p}',
            'In which order do the words get written?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b(right, right), correct: true),
        Choice(
            labelKeys: b(wrong, wrong),
            correct: false,
            misconception: 'C5.4-one-at-a-time'),
        Choice(
            labelKeys: b('seulement le premier script s\'écrit',
                'only the first script writes anything'),
            correct: false,
            misconception: 'C5.4-first-wins'),
        Choice(
            labelKeys: b('l\'ordre change à chaque fois',
                'the order changes every time'),
            correct: false,
            misconception: 'C5.4-nondeterministic'),
      ],
      itemHints: hints(
        'Les deux scripts partent ensemble.',
        'Both scripts start together.',
        'Ils avancent chacun leur tour, une ligne à la fois.',
        'They take turns, one line each.',
      ),
      wrongChoiceFr: 'Les scripts avancent chacun leur tour, pas l\'un après l\'autre.',
      wrongChoiceEn: 'The scripts take turns; they do not run one after the other.',
    ));
  }

  // T2 — one script where two were meant.
  for (final entry in [
    ('avance 60', 'tournedroite 90\navance 60'),
    ('couleurcrayon 255, 0, 0\navance 50', 'direction 90\navance 50'),
    ('répète 3 {\n  avance 20\n}', 'direction 180\navance 40'),
    ('avance 40', 'direction 270\navance 40'),
    ('répète 4 {\n  avance 15\n  tournedroite 90\n}',
        'direction 45\navance 50'),
    ('couleurcrayon 0, 0, 255\navance 30', 'direction 135\navance 30'),
  ]) {
    final first = entry.$1, second = entry.$2;
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C5.4',
      difficulty: Difficulty.d3,
      broken: script('drapeau', '$first\n$second'),
      solution: '${script('drapeau', first)}\n${script('drapeau', second)}',
      promptKeys: b(
        'Il doit y avoir DEUX scripts qui partent ensemble, pas un seul long. '
            'Répare.',
        'There must be TWO scripts starting together, not one long one. Fix it.',
      ),
      wrong: [
        script('drapeau', '$first\n$second'),
        script('drapeau', first),
        '${script('drapeau', first)}\n${script('touche "espace"', second)}',
      ],
      assertions: const [UsesOpcode('WHEN_FLAG', min: 2)],
      itemHints: hints(
        'Un seul bloc « quand » ne fait qu\'un script.',
        'One "when" block makes one script.',
        'Il en faut deux, l\'un sous l\'autre.',
        'You need two, one below the other.',
        spotlight: 'WHEN_FLAG',
      ),
      paletteScope: palette,
      runTrigger: 'any',
    ));
  }

  /* T3 — count what is on the paper. Two scripts drawing at once is the only way to get
     these figures, and the count is a thing a child can check by looking. */
  /* Each set carries the count the *first script alone* would leave, because that is what
     "one at a time" means here and it is not always one. The last set is the one that
     proves the point: only one of its two scripts starts on the flag, so the right answer
     IS one — and a fixed "1" distractor made that item unanswerable. */
  for (final entry in [
    (
      'quand drapeau {\n  avance 40\n}\n'
          'quand drapeau {\n  direction 90\n  avance 40\n}',
      2,
      1,
    ),
    (
      'quand drapeau {\n  répète 3 {\n    avance 20\n  }\n}\n'
          'quand drapeau {\n  direction 180\n  avance 30\n}',
      4,
      3,
    ),
    (
      'quand drapeau {\n  avance 30\n}\n'
          'quand drapeau {\n  avance 30\n}',
      2,
      1,
    ),
    (
      'quand drapeau {\n  avance 25\n}\n'
          'quand touche "a" {\n  avance 25\n}',
      1,
      // Both scripts counted, which is the mistake this set is for.
      2,
    ),
  ]) {
    final source = entry.$1, marks = entry.$2, firstOnly = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C5.4',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('On appuie sur le drapeau. Combien de traits sur la feuille ?\n\n{p}',
            'The flag is pressed. How many lines are on the paper?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b('$marks', '$marks'), correct: true),
        Choice(
            labelKeys: b('${marks + firstOnly + 1}', '${marks + firstOnly + 1}'),
            correct: false,
            misconception: 'C5.4-counts-every-script'),
        Choice(
            labelKeys: b('$firstOnly', '$firstOnly'),
            correct: false,
            misconception: marks == 1
                ? 'C5.4-counts-every-script'
                : 'C5.4-one-at-a-time'),
        Choice(
            labelKeys: b('0', '0'),
            correct: false,
            misconception: 'C5.4-nothing-runs'),
      ],
      itemHints: hints(
        'Les deux scripts dessinent, chacun son tour.',
        'Both scripts draw, each in its turn.',
        'Vérifie que le deuxième part bien sur le drapeau.',
        'Check that the second one really starts on the flag.',
      ),
      wrongChoiceFr: 'Compte les traits des scripts qui partent sur CE déclencheur.',
      wrongChoiceEn: 'Count the lines from the scripts that start on THIS trigger.',
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C5.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Deux scripts partent sur le drapeau vert. Lequel finit en premier ?',
        'Two scripts start on the green flag. Which one finishes first?'),
    choices: [
      Choice(
          labelKeys: b('Le plus court, parce qu\'il a moins à faire.',
              'The shorter one, because it has less to do.'),
          correct: true),
      Choice(
          labelKeys: b('Celui du haut, toujours.', 'The top one, always.'),
          correct: false,
          misconception: 'C5.4-one-at-a-time'),
      Choice(
          labelKeys: b('Celui du bas, toujours.', 'The bottom one, always.'),
          correct: false,
          misconception: 'C5.4-one-at-a-time'),
      Choice(
          labelKeys: b('Ils finissent forcément ensemble.',
              'They always finish together.'),
          correct: false,
          misconception: 'C5.4-lockstep'),
    ],
    itemHints: hints(
      'Ils avancent chacun leur tour, d\'une ligne.',
      'They take turns, one line each.',
      'Celui qui a le moins de lignes arrive au bout avant.',
      'The one with fewer lines reaches the end sooner.',
    ),
    wrongChoiceFr: 'Chacun avance d\'une ligne à son tour : le plus court finit avant.',
    wrongChoiceEn: 'Each advances one line per turn: the shorter one ends sooner.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C5.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d4,
    promptKeys: b(
        'Deux scripts changent la même boîte \$score. Est-ce possible ?',
        'Two scripts change the same box \$score. Is that possible?'),
    choices: [
      Choice(
          labelKeys: b('Oui : c\'est la même boîte pour les deux.',
              'Yes: it is the same box for both of them.'),
          correct: true),
      Choice(
          labelKeys: b('Non : chaque script a sa propre boîte.',
              'No: each script has its own box.'),
          correct: false,
          misconception: 'C5.4-separate-boxes'),
      Choice(
          labelKeys: b('Oui, mais seulement le premier script compte.',
              'Yes, but only the first script counts.'),
          correct: false,
          misconception: 'C5.4-first-wins'),
      Choice(
          labelKeys: b('Non : la boîte s\'efface entre les deux.',
              'No: the box is wiped in between.'),
          correct: false,
          misconception: 'C5.4-box-resets'),
    ],
    itemHints: hints(
      'Une boîte a un nom, et le nom est le même.',
      'A box has a name, and the name is the same.',
      'Les deux scripts écrivent dedans à tour de rôle.',
      'Both scripts write into it, each in its turn.',
    ),
    wrongChoiceFr: 'Une boîte est partagée : les deux scripts écrivent dans la même.',
    wrongChoiceEn: 'A box is shared: both scripts write into the same one.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C5.4',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d4,
    promptKeys: b(
      'Pourquoi écrire deux scripts plutôt qu\'un seul long ?',
      'Why write two scripts instead of one long one?',
    ),
    choices: [
      Choice(
          labelKeys: b('Parce que les deux choses se passent en même temps.',
              'Because the two things happen at the same time.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que c\'est plus joli à lire.',
              'Because it looks tidier.'),
          correct: false,
          misconception: 'C5.4-cosmetic'),
      Choice(
          labelKeys: b('Parce qu\'un script ne peut pas être long.',
              'Because a script cannot be long.'),
          correct: false,
          misconception: 'C5.4-length-limit'),
      Choice(
          labelKeys: b('Parce que ça va plus vite.',
              'Because it is faster.'),
          correct: false,
          misconception: 'C5.4-speed'),
    ],
    itemHints: hints(
      'Pense à deux choses qui doivent bouger ensemble.',
      'Think of two things that have to move together.',
      'Un seul script les ferait l\'une après l\'autre.',
      'One script would do them one after the other.',
    ),
    wrongChoiceFr: 'Deux scripts avancent ensemble ; un seul les met à la queue leu leu.',
    wrongChoiceEn: 'Two scripts advance together; one would queue them up.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C5.4',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d5,
    promptKeys: b(
      'Un script dessine un carré, l\'autre écrit un mot. Le carré est-il '
          'dessiné avant que le mot soit écrit ?',
      'One script draws a square, the other writes a word. Is the square '
          'finished before the word is written?',
    ),
    choices: [
      Choice(
          labelKeys: b('Non : le mot s\'écrit pendant que le carré se dessine.',
              'No: the word gets written while the square is being drawn.'),
          correct: true),
      Choice(
          labelKeys: b('Oui : le premier script finit d\'abord.',
              'Yes: the first script finishes first.'),
          correct: false,
          misconception: 'C5.4-one-at-a-time'),
      Choice(
          labelKeys: b('Oui, si le carré est en haut.',
              'Yes, if the square is the top one.'),
          correct: false,
          misconception: 'C5.4-one-at-a-time'),
      Choice(
          labelKeys: b('On ne peut pas savoir.', 'There is no way to tell.'),
          correct: false,
          misconception: 'C5.4-nondeterministic'),
    ],
    itemHints: hints(
      'Regarde la feuille pendant que ça tourne.',
      'Watch the paper while it runs.',
      'Les deux avancent chacun leur tour.',
      'Both advance, each in its turn.',
    ),
    wrongChoiceFr: 'Les deux scripts avancent en même temps, une ligne chacun à tour de rôle.',
    wrongChoiceEn: 'Both scripts advance together, one line each in turn.',
  ));

  // T9 — open build: the world's own ending.
  for (final entry in [
    ('deux choses qui bougent ensemble', 'two things moving together'),
    ('un dessin et un compteur', 'a drawing and a counter'),
    ('deux dessins de couleurs différentes', 'two drawings in different colours'),
  ]) {
    final fr = entry.$1, en = entry.$2;
    items.add(openBuild(
      id: id(),
      conceptId: 'C5.4',
      difficulty: Difficulty.d4,
      promptKeys: b(
        'Fais $fr avec deux scripts. Voici ce qu\'il faut, et tu le sais avant '
            'de commencer :',
        'Make $en with two scripts. Here is what it needs, and you know it '
            'before you start:',
      ),
      rubric: [
        rubricLine('Il y a deux blocs « quand drapeau ».',
            'There are two "when flag" blocks.',
            const UsesOpcode('WHEN_FLAG', min: 2)),
        rubricLine('Chacun fait quelque chose de différent.',
            'Each one does something different.',
            const UsesOpcode('MOVE_FORWARD', min: 2)),
        rubricLine('Tout tient en quinze blocs ou moins.',
            'It all fits in fifteen blocks or fewer.',
            const BlockCountWithin(max: 15)),
      ],
      itemHints: hints(
        'Deux blocs « quand drapeau », l\'un sous l\'autre.',
        'Two "when flag" blocks, one below the other.',
        'Mets une chose différente dans chacun.',
        'Put something different inside each one.',
        spotlight: 'WHEN_FLAG',
      ),
      paletteScope: palette,
      runTrigger: 'any',
    ));
  }

  return items;
}

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

List<Tutorial> world5Tutorials() => [
      tutorialFor(
        conceptId: 'C5.1',
        conceptName: b('Partir tout seul', 'Starting on its own'),
        steps: [
          watchStep(
            'C5.1',
            'Regarde. Personne ne touche aux blocs. Le drapeau suffit.',
            'Watch. Nobody touches the blocks. The flag is enough.',
            'quand drapeau {\n  répète 4 {\n    avance 60\n'
                '    tournedroite 90\n  }\n}',
            ideas: ['un déclencheur'],
          ),
          togetherStep(
            'C5.1',
            'Place le bloc qui dit « quand le drapeau ».',
            'Place the block that says "when the flag".',
            opcodeId: 'WHEN_FLAG',
            hintFr: 'Cherche-le dans la famille Événements.',
            hintEn: 'Look for it in the Events family.',
          ),
          doStep(
            'C5.1',
            'Fais un dessin qui part quand on appuie sur le drapeau.',
            'Make a drawing that starts when the flag is pressed.',
            opcodeId: 'WHEN_FLAG',
            hintFr: 'Mets ton dessin à l\'intérieur du bloc.',
            hintEn: 'Put your drawing inside the block.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C5.2',
        conceptName: b('Une touche, un script', 'One key, one script'),
        steps: [
          watchStep(
            'C5.2',
            'Chaque touche a son script. Appuie autant de fois que tu veux.',
            'Each key has its script. Press as often as you like.',
            'quand touche "a" {\n  tournegauche 90\n}\n'
                'quand touche "d" {\n  tournedroite 90\n}',
            ideas: ['une touche déclenche'],
          ),
          togetherStep(
            'C5.2',
            'Écris le nom de la touche entre guillemets.',
            'Write the key\'s name in quotes.',
            opcodeId: 'WHEN_KEY',
            action: ExpectedAction.editNumber,
            hintFr: 'Appuie sur le mot dans le bloc.',
            hintEn: 'Press the word inside the block.',
          ),
          doStep(
            'C5.2',
            'Fais avancer Tika avec la touche espace.',
            'Make Tika move with the space key.',
            opcodeId: 'WHEN_KEY',
            hintFr: 'quand touche "espace", puis avance.',
            hintEn: 'When key "espace", then forward.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C5.3',
        conceptName: b('Cliquer sur Tika', 'Clicking on Tika'),
        steps: [
          watchStep(
            'C5.3',
            'Regarde. On clique sur Tika, pas à côté.',
            'Watch. You click on Tika, not next to her.',
            'quand clic {\n  tournedroite 45\n  avance 40\n}',
            ideas: ['un clic sur le lutin'],
          ),
          togetherStep(
            'C5.3',
            'Place le bloc « quand clic ».',
            'Place the "when clicked" block.',
            opcodeId: 'WHEN_CLICKED',
            hintFr: 'Il est dans la famille Événements.',
            hintEn: 'It is in the Events family.',
          ),
          doStep(
            'C5.3',
            'Fais un bouton : clique sur Tika, il se passe quelque chose.',
            'Make a button: click Tika, something happens.',
            opcodeId: 'WHEN_CLICKED',
            hintFr: 'Mets ce qui doit arriver dans le bloc.',
            hintEn: 'Put what should happen inside the block.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C5.4',
        conceptName: b('Deux à la fois', 'Two at a time'),
        steps: [
          watchStep(
            'C5.4',
            'Regarde les deux scripts. Ils avancent chacun leur tour.',
            'Watch the two scripts. They take turns.',
            'quand drapeau {\n  écris "A"\n  écris "A"\n}\n'
                'quand drapeau {\n  écris "B"\n  écris "B"\n}',
            ideas: ['deux scripts ensemble'],
          ),
          togetherStep(
            'C5.4',
            'Ajoute un deuxième bloc « quand drapeau ».',
            'Add a second "when flag" block.',
            opcodeId: 'WHEN_FLAG',
            hintFr: 'Mets-le sous le premier, pas dedans.',
            hintEn: 'Put it below the first one, not inside it.',
          ),
          doStep(
            'C5.4',
            'Fais deux choses qui se passent en même temps.',
            'Make two things happen at the same time.',
            opcodeId: 'WHEN_FLAG',
            hintFr: 'Deux blocs « quand drapeau », l\'un sous l\'autre.',
            hintEn: 'Two "when flag" blocks, one below the other.',
          ),
        ],
      ),
    ];

void main() {
  final items = [
    ...conceptC51(),
    ...conceptC52(),
    ...conceptC53(),
    ...conceptC54(),
  ];
  final tutorials = world5Tutorials();

  stdout.writeln(
      'World 5 — authored ${items.length} items, ${tutorials.length} tutorials');

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

  const committed = {'C5.1': 22, 'C5.2': 22, 'C5.3': 18, 'C5.4': 22};
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
    world: 5,
    version: 1,
    nameKeys: b('Quand…', 'When…'),
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
    assetKeys: const ['art/tika.svg', 'art/world5-quand.svg'],
  );

  final encoded = const JsonEncoder.withIndent('  ').convert(pack.toJson());
  final sized = ContentPack.fromJson({
    ...pack.toJson(),
    'sizeBytes': utf8.encode(encoded).length,
  });
  final manifest = PackManifest.of(sized);

  final dir = Directory('../../content');
  dir.createSync(recursive: true);
  File('${dir.path}/world5.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sized.toJson())}\n');
  File('${dir.path}/world5.manifest.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n');

  stdout.writeln('\nPublished content/world5.json');
  stdout.writeln(
      '  ${sized.sizeBytes} bytes of ${ContentPack.worldBudgetBytes} budget '
      '(${(sized.sizeBytes / ContentPack.worldBudgetBytes * 100).toStringAsFixed(1)} %)');
  stdout.writeln('  audio keys: ${sized.audioKeys.length}');
}
