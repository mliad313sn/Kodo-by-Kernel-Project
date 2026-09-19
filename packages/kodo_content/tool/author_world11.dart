// Authors World 11 — "Je passe au texte" — and writes it out as a content pack.
//
//     dart tool/author_world11.dart
//
// Eleven worlds of dragging blocks, and now a keyboard. The four misconceptions in the
// ledger are four versions of one fear — that the thing on the screen has changed into
// something harder:
//
//   C11.1  "text code is a different language"
//   C11.2  "comments are executed"
//   C11.3  "an error means I broke the computer"
//   C11.4  "English code is a new language to relearn"
//
// The first and the last are the same claim twice, and KODO can refute both by
// construction rather than by reassurance. **Blocks and text are two projections of one
// tree** — that is the rule the whole product is built on — and the two keyword tables
// are two spellings of the same language. So this world's items are graded by a grader
// that does not care which words a program was typed with: an item written in English
// accepts the French version as a correct alternative, and passes it, because it is the
// same program.
//
// C11.3 is different in kind. It is not about syntax at all; it is about what to do when
// the screen goes red. Its items are mostly read-and-answer, and their subject is the
// sentence KODO printed — because a child who can read "il manque un nombre après avance"
// has a next move, and a child who reads "error" has only a feeling.

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';

import 'authoring.dart';

const conceptGraph = <String, List<String>>{
  'C11.1': ['C9.3'],
  'C11.2': ['C11.1'],
  'C11.3': ['C11.1'],
  'C11.4': ['C11.1'],
};

/// §6.3's commitment, copied from `spec/concepts.json` and checked against it by
/// `publishWorld`.
const committed = <String, int>{
  'C11.1': 24,
  'C11.2': 20,
  'C11.3': 24,
  'C11.4': 22,
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
  'LEARN',
  'RETURN',
  'BREAK',
];

/// A closed figure in French words.
String figureFr(int sides, int side, int turn) =>
    'répète $sides {\n  avance $side\n  tournedroite $turn\n}';

/// The same figure in English words. The same program — that is C11.4's whole point, and
/// the grader proves it by accepting either as the other's alternative.
String figureEn(int sides, int side, int turn) =>
    'repeat $sides {\n  forward $side\n  turnright $turn\n}';

// ═══════════════════════════════════════════════════════════════════════════════════════
// C11.1 — Écrire son programme.
// Misconception: "text code is a different language".
//
// It is not: it is the same blocks with the mouse put away. Every item here is a figure
// the child has already built in an earlier world, typed out — and the distractors are
// the four things that actually go wrong at a keyboard, which are all punctuation and
// none of them meaning: a missing brace, a missing number, a word run together, an
// argument in the wrong place.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC111() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C11.1-${(++n).toString().padLeft(2, '0')}';

  // T1 — type out a figure from an earlier world.
  for (final entry in [
    (4, 60, 90),
    (3, 80, 120),
    (6, 45, 60),
    (5, 55, 72),
    (8, 40, 45),
    (4, 75, 90),
  ]) {
    final sides = entry.$1, side = entry.$2, turn = entry.$3;
    final solution = figureFr(sides, side, turn);
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C11.1',
      difficulty: Difficulty.d2,
      solution: solution,
      promptKeys: fillBoth(
        b('Écris au clavier la figure à {k} côtés de {s} pas.',
            'Type the {k}-sided shape with {s}-step sides.'),
        {'k': sides, 's': side},
      ),
      wrong: [
        figureFr(sides - 1, side, turn),
        figureFr(sides, side + 20, turn),
        figureFr(sides, side, turn + 15),
      ],
      alternatives: [
        // The same program with the words of the other language, and with the spacing a
        // child actually types. Both parse to the same tree, which is the point.
        figureEn(sides, side, turn),
        'répète $sides {\n  avance $side\n  tournedroite $turn\n}\n# fini',
      ],
      itemHints: hints(
        'Les mêmes blocs, écrits au clavier.',
        'The same blocks, typed on the keyboard.',
        'L\'accolade ouvre et referme la répétition.',
        'The bracket opens and closes the repeat.',
      ),
      paletteScope: palette,
    ));
  }

  /* T2 — five keyboard bugs. Every one of them parses, because a wrong answer has to be
     gradable: the mistakes here are the ones that produce a program that runs and draws
     the wrong thing, which is the harder half of learning to type. */
  for (final entry in [
    (4, 60, 90, 'extra-turn'),
    (3, 80, 120, 'wrong-count'),
    (6, 45, 60, 'wrong-side'),
    (5, 55, 72, 'extra-turn'),
    (4, 50, 90, 'wrong-count'),
  ]) {
    final sides = entry.$1, side = entry.$2, turn = entry.$3, bug = entry.$4;
    final solution = figureFr(sides, side, turn);
    final broken = switch (bug) {
      'extra-turn' => figureFr(sides, side, turn + 30),
      // One side SHORT. Two extra turns round a closed figure retrace it and leave the
      // identical ink, which the gate said about two of these.
      'wrong-count' => figureFr(sides - 1, side, turn),
      _ => figureFr(sides, side * 2, turn),
    };
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C11.1',
      difficulty: Difficulty.d2,
      broken: broken,
      solution: solution,
      promptKeys: fillBoth(
        b('La figure devait avoir {k} côtés de {s} pas. Corrige le texte.',
            'The shape should have {k} sides of {s} steps. Fix the text.'),
        {'k': sides, 's': side},
      ),
      wrong: [
        figureFr(sides, side, turn + 10),
        figureFr(sides - 1, side, turn),
        figureFr(sides, side - 15, turn),
      ],
      alternatives: [
        figureEn(sides, side, turn),
        '# corrigé\n$solution',
      ],
      itemHints: hints(
        'Compare chaque nombre avec l\'énoncé.',
        'Compare each number with the question.',
        'Un seul est faux.',
        'Only one of them is wrong.',
      ),
      paletteScope: palette,
    ));
  }

  // T4 — the hole is a piece of punctuation or a number.
  for (final entry in [
    (4, 60, 90),
    (3, 80, 120),
    (6, 45, 60),
    (5, 55, 72),
    (8, 40, 45),
  ]) {
    final sides = entry.$1, side = entry.$2, turn = entry.$3;
    final solution = figureFr(sides, side, turn);
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C11.1',
      difficulty: Difficulty.d1,
      withHoles: 'répète $sides {\n  avance ___\n  tournedroite $turn\n}',
      solution: solution,
      promptKeys: fillBoth(
        b('Complète pour que chaque côté fasse {s} pas.',
            'Fill in the blank so each side is {s} steps.'),
        {'s': side},
      ),
      wrong: [
        figureFr(sides, side + 20, turn),
        figureFr(sides, side - 15, turn),
        figureFr(sides, turn, turn),
      ],
      alternatives: [
        figureEn(sides, side, turn),
        '$solution\n# fini',
      ],
      itemHints: hints(
        'Le nombre va après avance.',
        'The number goes after forward.',
        'C\'est $side.',
        'It is $side.',
      ),
      paletteScope: palette,
    ));
  }

  // T5 — Parsons, over typed lines.
  for (final entry in [
    (4, 60, 90),
    (3, 80, 120),
    (6, 45, 60),
    (5, 55, 72),
  ]) {
    final sides = entry.$1, side = entry.$2, turn = entry.$3;
    final solution = figureFr(sides, side, turn);
    items.add(parsons(
      id: id(),
      conceptId: 'C11.1',
      difficulty: Difficulty.d2,
      solution: solution,
      promptKeys: fillBoth(
        b('Remets les lignes dans l\'ordre pour dessiner la figure à {k} côtés.',
            'Put the lines back in order to draw the {k}-sided shape.'),
        {'k': sides},
      ),
      wrong: [
        'répète $sides {\n  tournedroite $turn\n  avance $side\n}\navance $side',
        'avance $side\nrépète $sides {\n  tournedroite $turn\n}',
        'répète ${sides - 1} {\n  avance $side\n  tournedroite $turn\n}',
      ],
      alternatives: [
        figureEn(sides, side, turn),
        '# remis en ordre\n$solution',
      ],
      itemHints: hints(
        'La répétition ouvre avant ce qu\'elle répète.',
        'The repeat opens before what it repeats.',
        'L\'accolade se referme à la fin.',
        'The bracket closes at the end.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C11.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d1,
    promptKeys: b('Le texte et les blocs, est-ce le même langage ?',
        'Are the text and the blocks the same language?'),
    choices: [
      Choice(
          labelKeys: b('Oui : deux façons d\'écrire la même chose.',
              'Yes: two ways of writing the same thing.'),
          correct: true),
      Choice(
          labelKeys: b('Non : le texte est un autre langage.',
              'No: the text is another language.'),
          correct: false,
          misconception: 'C11.1-text-is-another-language'),
      Choice(
          labelKeys: b('Non : le texte est plus puissant.',
              'No: the text is more powerful.'),
          correct: false,
          misconception: 'C11.1-text-is-stronger'),
      Choice(
          labelKeys: b('Oui, mais seulement pour les petits programmes.',
              'Yes, but only for small programs.'),
          correct: false,
          misconception: 'C11.1-text-is-another-language'),
    ],
    itemHints: hints(
      'Passe de l\'un à l\'autre et regarde.',
      'Switch from one to the other and look.',
      'Le programme ne change pas.',
      'The program does not change.',
    ),
    wrongChoiceFr:
        'Les blocs et le texte montrent le même programme de deux façons.',
    wrongChoiceEn:
        'Blocks and text show the same program in two ways.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C11.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('À quoi servent les accolades { } ?',
        'What are the brackets { } for?'),
    choices: [
      Choice(
          labelKeys: b('À dire où commence et finit un bloc.',
              'To say where a block starts and ends.'),
          correct: true),
      Choice(
          labelKeys: b('À décorer le programme.', 'To decorate the program.'),
          correct: false,
          misconception: 'C11.1-braces-are-decoration'),
      Choice(
          labelKeys: b('À séparer les nombres.', 'To separate the numbers.'),
          correct: false,
          misconception: 'C11.1-braces-separate-arguments'),
      Choice(
          labelKeys: b('À rien : on peut les oublier.',
              'Nothing: you can leave them out.'),
          correct: false,
          misconception: 'C11.1-braces-are-decoration'),
    ],
    itemHints: hints(
      'Dans les blocs, c\'est la forme du bloc qui le dit.',
      'With blocks, the shape of the block says it.',
      'Au clavier, ce sont les accolades.',
      'On the keyboard, it is the brackets.',
    ),
    wrongChoiceFr:
        'Les accolades font au clavier ce que la forme du bloc fait à l\'écran.',
    wrongChoiceEn:
        'Brackets do on the keyboard what the block\'s shape does on screen.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C11.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Où va le nombre dans avance 50 ?',
        'Where does the number go in forward 50?'),
    choices: [
      Choice(
          labelKeys: b('Après le mot, séparé par une espace.',
              'After the word, with a space between.'),
          correct: true),
      Choice(
          labelKeys: b('Avant le mot.', 'Before the word.'),
          correct: false,
          misconception: 'C11.1-argument-order'),
      Choice(
          labelKeys: b('Entre accolades.', 'Between brackets.'),
          correct: false,
          misconception: 'C11.1-braces-separate-arguments'),
      Choice(
          labelKeys: b('Collé au mot.', 'Stuck to the word.'),
          correct: false,
          misconception: 'C11.1-no-spaces-needed'),
    ],
    itemHints: hints(
      'Le bloc a une case à sa droite.',
      'The block has a slot on its right.',
      'Au clavier, c\'est la même place.',
      'On the keyboard it is the same place.',
    ),
    wrongChoiceFr:
        'Le nombre suit le mot, comme la case suit le bloc.',
    wrongChoiceEn:
        'The number follows the word, as the slot follows the block.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C11.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Tu écris ton programme au clavier puis tu repasses aux blocs. Que se passe-t-il ?',
        'You type your program then switch back to blocks. What happens?'),
    choices: [
      Choice(
          labelKeys: b('Tu retrouves tes blocs, à l\'identique.',
              'You get your blocks back, exactly as they were.'),
          correct: true),
      Choice(
          labelKeys: b('Le programme est perdu.', 'The program is lost.'),
          correct: false,
          misconception: 'C11.1-switching-loses-work'),
      Choice(
          labelKeys: b('Il faut tout retaper.', 'You have to type it all again.'),
          correct: false,
          misconception: 'C11.1-text-is-another-language'),
      Choice(
          labelKeys: b('Les blocs changent d\'ordre.',
              'The blocks change order.'),
          correct: false,
          misconception: 'C11.1-switching-loses-work'),
    ],
    itemHints: hints(
      'Il n\'y a qu\'un seul programme derrière.',
      'There is only one program underneath.',
      'Les deux vues le montrent autrement.',
      'The two views show it differently.',
    ),
    wrongChoiceFr:
        'Une seule chose est enregistrée ; blocs et texte la montrent tous deux.',
    wrongChoiceEn:
        'One thing is stored; blocks and text both show it.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C11.2 — Commentaires #.
// Misconception: "comments are executed".
//
// The proof is a pair of programs: one with a line of drawing commented out and one with
// the same line deleted. They draw the same figure, and they draw a *different* figure
// from the version where the # is missing. A child who believes a comment runs is holding
// a belief the canvas settles in one click.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC112() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C11.2-${(++n).toString().padLeft(2, '0')}';

  /* T2 — five programs where a line that should have been commented out is not, so it
     runs and spoils the figure. */
  for (final entry in [
    (4, 60, 90, 'avance 200'),
    (3, 80, 120, 'tournedroite 37'),
    (6, 45, 60, 'recule 150'),
    (5, 55, 72, 'avance 180'),
    (4, 70, 90, 'tournegauche 53'),
  ]) {
    final sides = entry.$1, side = entry.$2, turn = entry.$3, stray = entry.$4;
    final solution = '# $stray\n${figureFr(sides, side, turn)}';
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C11.2',
      difficulty: Difficulty.d2,
      broken: '$stray\n${figureFr(sides, side, turn)}',
      solution: solution,
      promptKeys: fillBoth(
        b('La ligne « {l} » ne devait pas se jouer. Mets-la en commentaire.',
            'The line "{l}" was not meant to run. Turn it into a comment.'),
        {'l': stray},
      ),
      wrong: [
        '$stray\n# ${figureFr(sides, side, turn).split('\n').first}',
        '$stray\n${figureFr(sides - 1, side, turn)}',
        '$stray\n${figureFr(sides, side, turn)}\n# fini',
      ],
      alternatives: [
        // A comment is not a statement: deleting the line does exactly the same thing.
        figureFr(sides, side, turn),
        '${figureFr(sides, side, turn)}\n# $stray',
      ],
      itemHints: hints(
        'Un # au début d\'une ligne la met de côté.',
        'A # at the start of a line puts it aside.',
        'Tika saute cette ligne.',
        'Tika skips that line.',
      ),
      paletteScope: palette,
    ));
  }

  // T3 — what does the program do?
  for (final entry in [
    ('# écris 1\nécris 2', '2', '1 puis 2', '1 then 2'),
    ('écris 1\n# écris 2', '1', '1 puis 2', '1 then 2'),
    ('écris 1 # écris 2', '1', '1 puis 2', '1 then 2'),
    ('# écris 1\n# écris 2\nécris 3', '3', '1, 2 puis 3', '1, 2 then 3'),
  ]) {
    final source = entry.$1, answer = entry.$2;
    items.add(predict(
      id: id(),
      conceptId: 'C11.2',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Qu\'est-ce que Tika écrit ?\n\n{p}', 'What does Tika write?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b(answer, answer), correct: true),
        Choice(
            labelKeys: b(entry.$3, entry.$4),
            correct: false,
            misconception: 'C11.2-comments-run'),
        Choice(
            labelKeys: b('rien', 'nothing'),
            correct: false,
            misconception: 'C11.2-comment-stops-the-program'),
        Choice(
            labelKeys: b('une erreur', 'an error'),
            correct: false,
            misconception: 'C11.2-comment-is-an-error'),
      ],
      itemHints: hints(
        'Tout ce qui suit un # est sauté.',
        'Everything after a # is skipped.',
        'Le reste se joue normalement.',
        'The rest plays as usual.',
      ),
      wrongChoiceFr:
          'Un commentaire est pour toi, pas pour Tika : elle ne le lit pas.',
      wrongChoiceEn:
          'A comment is for you, not for Tika: she does not read it.',
    ));
  }

  // T4 — the hole is the # itself.
  for (final entry in [
    (4, 60, 90, 'avance 200'),
    (3, 80, 120, 'tournedroite 37'),
    (6, 45, 60, 'recule 150'),
    (5, 55, 72, 'avance 180'),
  ]) {
    final sides = entry.$1, side = entry.$2, turn = entry.$3, stray = entry.$4;
    final solution = '# $stray\n${figureFr(sides, side, turn)}';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C11.2',
      difficulty: Difficulty.d1,
      withHoles: '___ $stray\n${figureFr(sides, side, turn)}',
      solution: solution,
      promptKeys: fillBoth(
        b('Complète pour que « {l} » ne se joue pas.',
            'Fill in the blank so "{l}" does not run.'),
        {'l': stray},
      ),
      wrong: [
        '$stray\n${figureFr(sides, side, turn)}',
        'recule $stray\n${figureFr(sides, side, turn)}',
        '$stray\n${figureFr(sides, side + 25, turn)}',
      ],
      alternatives: [
        figureFr(sides, side, turn),
        '${figureFr(sides, side, turn)}\n# $stray',
      ],
      itemHints: hints(
        'Un seul caractère met une ligne de côté.',
        'One character puts a line aside.',
        'C\'est le dièse.',
        'It is the hash.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C11.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d1,
    promptKeys: b('À qui s\'adresse un commentaire ?',
        'Who is a comment for?'),
    choices: [
      Choice(
          labelKeys: b('À toi, et à qui lira ton programme.',
              'You, and whoever reads your program.'),
          correct: true),
      Choice(
          labelKeys: b('À Tika, pour lui expliquer.',
              'Tika, to explain things to her.'),
          correct: false,
          misconception: 'C11.2-comments-run'),
      Choice(
          labelKeys: b('À personne.', 'Nobody.'),
          correct: false,
          misconception: 'C11.2-comments-are-useless'),
      Choice(
          labelKeys: b('À l\'ordinateur.', 'The computer.'),
          correct: false,
          misconception: 'C11.2-comments-run'),
    ],
    itemHints: hints(
      'Tika saute ces lignes sans les lire.',
      'Tika skips those lines without reading them.',
      'Il reste quelqu\'un pour les lire.',
      'Somebody is still there to read them.',
    ),
    wrongChoiceFr:
        'Un commentaire explique le programme aux gens, pas à la machine.',
    wrongChoiceEn:
        'A comment explains the program to people, not to the machine.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C11.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait Tika quand elle voit un # ?',
        'What does Tika do when she sees a #?'),
    choices: [
      Choice(
          labelKeys: b('Elle saute la fin de la ligne.',
              'She skips the rest of the line.'),
          correct: true),
      Choice(
          labelKeys: b('Elle s\'arrête là.', 'She stops there.'),
          correct: false,
          misconception: 'C11.2-comment-stops-the-program'),
      Choice(
          labelKeys: b('Elle joue la ligne quand même.',
              'She plays the line anyway.'),
          correct: false,
          misconception: 'C11.2-comments-run'),
      Choice(
          labelKeys: b('Elle saute tout le programme.',
              'She skips the whole program.'),
          correct: false,
          misconception: 'C11.2-comment-stops-the-program'),
    ],
    itemHints: hints(
      'Le # vaut jusqu\'au bout de la ligne.',
      'The # holds until the end of the line.',
      'La ligne suivante se joue normalement.',
      'The next line plays as usual.',
    ),
    wrongChoiceFr:
        'Le # cache la fin de sa ligne, et rien de plus.',
    wrongChoiceEn:
        'The # hides the rest of its line, and nothing more.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C11.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Un commentaire ralentit-il le programme ?',
        'Does a comment slow the program down?'),
    choices: [
      Choice(
          labelKeys: b('Non : il n\'est jamais joué.',
              'No: it is never played.'),
          correct: true),
      Choice(
          labelKeys: b('Oui, un peu.', 'Yes, a little.'),
          correct: false,
          misconception: 'C11.2-comments-run'),
      Choice(
          labelKeys: b('Oui, s\'il est long.', 'Yes, if it is long.'),
          correct: false,
          misconception: 'C11.2-comments-run'),
      Choice(
          labelKeys: b('Il accélère le programme.',
              'It speeds the program up.'),
          correct: false,
          misconception: 'C11.2-comments-are-useless'),
    ],
    itemHints: hints(
      'Une ligne sautée ne coûte rien.',
      'A skipped line costs nothing.',
      'Tika ne fait rien avec.',
      'Tika does nothing with it.',
    ),
    wrongChoiceFr:
        'Une ligne que personne ne joue ne prend aucun temps.',
    wrongChoiceEn:
        'A line nobody plays takes no time at all.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C11.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Tu mets une ligne de dessin en commentaire. Que devient la figure ?',
        'You comment out a drawing line. What happens to the shape?'),
    choices: [
      Choice(
          labelKeys: b('Elle est dessinée sans cette ligne.',
              'It is drawn without that line.'),
          correct: true),
      Choice(
          labelKeys: b('Elle est dessinée pareil.', 'It is drawn the same.'),
          correct: false,
          misconception: 'C11.2-comments-run'),
      Choice(
          labelKeys: b('Rien n\'est dessiné.', 'Nothing is drawn.'),
          correct: false,
          misconception: 'C11.2-comment-stops-the-program'),
      Choice(
          labelKeys: b('La ligne devient grise.',
              'The line turns grey.'),
          correct: false,
          misconception: 'C11.2-comment-changes-colour'),
    ],
    itemHints: hints(
      'Commenter revient à enlever la ligne.',
      'Commenting out is the same as removing the line.',
      'Mais on peut la remettre facilement.',
      'But you can put it back easily.',
    ),
    wrongChoiceFr:
        'Commenter une ligne, c\'est l\'enlever sans la perdre.',
    wrongChoiceEn:
        'Commenting a line out removes it without losing it.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C11.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b('Pourquoi écrire des commentaires ?',
        'Why write comments?'),
    choices: [
      Choice(
          labelKeys: b('Pour se rappeler ce que fait chaque part.',
              'To remember what each part does.'),
          correct: true),
      Choice(
          labelKeys: b('Pour aider Tika à comprendre.',
              'To help Tika understand.'),
          correct: false,
          misconception: 'C11.2-comments-run'),
      Choice(
          labelKeys: b('Pour rendre le programme plus long.',
              'To make the program longer.'),
          correct: false,
          misconception: 'C11.2-comments-are-useless'),
      Choice(
          labelKeys: b('Il ne faut pas en écrire.',
              'You should not write any.'),
          correct: false,
          misconception: 'C11.2-comments-are-useless'),
    ],
    itemHints: hints(
      'Tu reliras ce programme dans un mois.',
      'You will read this program again in a month.',
      'Tu auras oublié pourquoi.',
      'You will have forgotten why.',
    ),
    wrongChoiceFr:
        'Un commentaire garde une explication que le code ne dit pas.',
    wrongChoiceEn:
        'A comment keeps an explanation the code does not give.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C11.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi mettre une ligne en commentaire plutôt que de l\'effacer ?',
      'Why comment a line out rather than delete it?',
    ),
    choices: [
      Choice(
          labelKeys: b('Pour la remettre si elle manque.',
              'To put it back if it turns out to be missing.'),
          correct: true),
      Choice(
          labelKeys: b('Parce qu\'effacer est interdit.',
              'Because deleting is not allowed.'),
          correct: false,
          misconception: 'C11.2-delete-is-forbidden'),
      Choice(
          labelKeys: b('Parce que c\'est plus rapide à jouer.',
              'Because it plays faster.'),
          correct: false,
          misconception: 'C11.2-comments-run'),
      Choice(
          labelKeys: b('Ça revient exactement au même.',
              'It comes to exactly the same thing.'),
          correct: false,
          misconception: 'C11.2-comments-are-useless'),
    ],
    itemHints: hints(
      'Tu cherches d\'où vient un problème.',
      'You are hunting where a problem comes from.',
      'Tu veux essayer sans cette ligne.',
      'You want to try without that line.',
    ),
    wrongChoiceFr:
        'Le programme tourne sans la ligne, et la ligne est encore là.',
    wrongChoiceEn:
        'The program runs without the line, and the line is still there.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C11.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Un ami dit : « Tika lit mes commentaires ». Que réponds-tu ?',
      'A friend says: "Tika reads my comments". What do you answer?',
    ),
    choices: [
      Choice(
          labelKeys: b('Non : elle saute tout ce qui suit un #.',
              'No: she skips everything after a #.'),
          correct: true),
      Choice(
          labelKeys: b('Oui, et elle obéit.', 'Yes, and she obeys them.'),
          correct: false,
          misconception: 'C11.2-comments-run'),
      Choice(
          labelKeys: b('Oui, mais seulement les courts.',
              'Yes, but only the short ones.'),
          correct: false,
          misconception: 'C11.2-comments-run'),
      Choice(
          labelKeys: b('Oui, elle s\'arrête en les voyant.',
              'Yes, she stops when she sees them.'),
          correct: false,
          misconception: 'C11.2-comment-stops-the-program'),
    ],
    itemHints: hints(
      'Essaie : mets avance 500 en commentaire.',
      'Try it: comment out forward 500.',
      'Rien ne bouge.',
      'Nothing moves.',
    ),
    wrongChoiceFr:
        'Commente une instruction et regarde : elle ne se joue plus.',
    wrongChoiceEn:
        'Comment an instruction out and look: it no longer plays.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C11.3 — Lire une erreur.
// Misconception: "an error means I broke the computer".
//
// The only concept in KODO whose subject is a feeling, and the one place where the
// product's own choices are the lesson: M1's error catalogue says what happened, where,
// and what to try, in the child's language, and never uses the word *error* as a verdict.
// A child who can read "il manque un nombre après avance" has a next move. A child who
// reads "syntax error at line 1" has only a fright.
//
// The items are mostly read-and-answer, with the error's own sentence as the subject, and
// that is deliberate rather than a shortcut: the skill being taught is reading. The five
// T2 items use runtime failures rather than typing mistakes, because a wrong answer has
// to parse to be gradable — which is itself worth knowing: a program that does not parse
// never runs at all.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC113() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C11.3-${(++n).toString().padLeft(2, '0')}';

  /* T2 — five programs that parse and then stop. Each earns `programFailed` and an
     authored sentence, which is the thing this concept is about. */
  for (final entry in [
    // (broken, fixed, what the child is told)
    (
      'avance \$côté\n\$côté = 60',
      '\$côté = 60\navance \$côté',
      'Tika ne connaît pas encore \$côté.',
      'Tika does not know \$côté yet.',
    ),
    (
      '\$n = 0\ntantque \$n < 4 {\n  avance 50\n  tournedroite 90\n}',
      '\$n = 0\ntantque \$n < 4 {\n  avance 50\n  tournedroite 90\n  \$n = \$n + 1\n}',
      'Le programme ne s\'arrête plus.',
      'The program never stops.',
    ),
    (
      'avance "beaucoup"',
      'avance 60',
      'avance attend un nombre.',
      'forward wants a number.',
    ),
    (
      'écris \$total',
      '\$total = 5\nécris \$total',
      'La boîte \$total n\'a jamais été remplie.',
      'The box \$total was never filled.',
    ),
    (
      'répète 4 {\n  avance \$pas\n  tournedroite 90\n}',
      '\$pas = 50\nrépète 4 {\n  avance \$pas\n  tournedroite 90\n}',
      'Tika ne connaît pas \$pas.',
      'Tika does not know \$pas.',
    ),
  ]) {
    final broken = entry.$1, fixed = entry.$2;
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C11.3',
      difficulty: Difficulty.d3,
      broken: broken,
      solution: fixed,
      promptKeys: fillBoth(
        b('Tika s\'est arrêtée. Elle dit : « {m} » Répare le programme.',
            'Tika stopped. She says: "{m}" Fix the program.'),
        {'m': entry.$3},
      )..['en'] = fill('Tika stopped. She says: "{m}" Fix the program.',
          {'m': entry.$4}),
      wrong: [
        broken,
        /* Every line commented out, not just the first: `'# $broken'` hashes line one
           and leaves the rest of a multi-line program dangling, which does not parse —
           and a wrong answer that does not parse is a broken item, not a wrong answer.
           This is also the better distractor: "I made the error go away" is exactly what
           a child tries. */
        broken.split('\n').map((l) => '# $l').join('\n'),
        'avance 0',
      ],
      alternatives: [
        '# réparé\n$fixed',
        fixed.replaceFirst('\n', '\n\n'),
      ],
      itemHints: hints(
        'Lis la phrase : elle dit quoi et où.',
        'Read the sentence: it says what and where.',
        'Une erreur n\'a rien cassé.',
        'An error has broken nothing.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — what did the message actually say? Reading it is the skill; every distractor is
     a way of not reading it. */
  for (final entry in [
    (
      'Il manque un nombre après « avance ». Par exemple : avance 100.',
      'It needs a number after "forward". For example: forward 100.',
      'ajouter un nombre après avance',
      'add a number after forward',
      'effacer la ligne',
      'delete the line',
    ),
    (
      'Tu as ouvert une accolade { et tu ne l\'as pas refermée. Ajoute } à la fin.',
      'You opened a bracket { and did not close it. Add } at the end.',
      'ajouter une accolade fermante',
      'add a closing bracket',
      'enlever l\'accolade ouvrante',
      'remove the opening bracket',
    ),
    (
      'Je ne connais pas le mot « avancee ». Vérifie comment il s\'écrit.',
      'I do not know the word "forwardd". Check how it is spelled.',
      'corriger l\'orthographe du mot',
      'fix the spelling of the word',
      'apprendre ce mot à Tika',
      'teach Tika that word',
    ),
    (
      'Je ne comprends pas « , » à cet endroit. Regarde la ligne 3.',
      'I do not understand "," here. Look at line 3.',
      'regarder la ligne 3',
      'look at line 3',
      'regarder tout le programme',
      'look at the whole program',
    ),
    (
      'Ton programme s\'est arrêté avant la fin. Regarde la ligne en rouge.',
      'Your program stopped before the end. Look at the red line.',
      'regarder la ligne en rouge',
      'look at the red line',
      'tout réécrire',
      'rewrite everything',
    ),
  ]) {
    items.add(predict(
      id: id(),
      conceptId: 'C11.3',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Tika dit : « {m} »\n\nQue fais-tu ?', 'Tika says: "{m}"\n\nWhat do you do?'),
        {'m': entry.$1},
      )..['en'] = fill('Tika says: "{m}"\n\nWhat do you do?', {'m': entry.$2}),
      choices: [
        Choice(labelKeys: b(entry.$3, entry.$4), correct: true),
        Choice(
            labelKeys: b(entry.$5, entry.$6),
            correct: false,
            misconception: 'C11.3-errors-mean-start-again'),
        Choice(
            labelKeys: b('éteindre l\'appareil', 'turn the device off'),
            correct: false,
            misconception: 'C11.3-error-means-broken'),
        Choice(
            labelKeys: b('appeler quelqu\'un tout de suite',
                'call somebody straight away'),
            correct: false,
            misconception: 'C11.3-error-means-broken'),
      ],
      itemHints: hints(
        'La phrase dit ce qui manque.',
        'The sentence says what is missing.',
        'Et souvent à quelle ligne.',
        'And often on which line.',
      ),
      wrongChoiceFr:
          'Le message dit quoi faire ; il suffit de faire ce qu\'il dit.',
      wrongChoiceEn:
          'The message says what to do; doing what it says is enough.',
    ));
  }

  /* T4 — the hole is the thing the message asked for.

     The three wrong numbers are authored rather than computed from the right one. On the
     repeat-count item every multiple of three retraces the triangle exactly, so
     `value + 30` and `value + 15` were both the right answer with a different label. */
  for (final entry in [
    ('avance ___', 'avance 60', 60, [90, 45, 30]),
    ('répète 4 {\n  avance 50\n  tournedroite ___\n}',
        'répète 4 {\n  avance 50\n  tournedroite 90\n}', 90, [120, 60, 45]),
    ('\$c = ___\nrépète 4 {\n  avance \$c\n  tournedroite 90\n}',
        '\$c = 45\nrépète 4 {\n  avance \$c\n  tournedroite 90\n}', 45, [75, 30, 20]),
    /* A hundred degrees, not a hundred and twenty. On a figure that closes, every
       count at or above the number of sides retraces it and leaves the identical ink —
       so only counts BELOW the answer could ever be wrong, and there are not three of
       those. An angle that does not divide 360 keeps adding new lines, which is what
       lets this item have three wrong answers either side of the right one. */
    ('répète ___ {\n  avance 60\n  tournedroite 100\n}',
        'répète 3 {\n  avance 60\n  tournedroite 100\n}', 3, [2, 4, 5]),
  ]) {
    final holes = entry.$1,
        solution = entry.$2,
        value = entry.$3,
        wrongValues = entry.$4;
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C11.3',
      difficulty: Difficulty.d1,
      withHoles: holes,
      solution: solution,
      promptKeys: fillBoth(
        b('Tika dit qu\'il manque un nombre. Mets {v}.',
            'Tika says a number is missing. Put {v}.'),
        {'v': value},
      ),
      wrong: [
        for (final bad in wrongValues) solution.replaceFirst('$value', '$bad'),
      ],
      alternatives: [
        '# complété\n$solution',
        solution.replaceFirst('\n', '\n\n'),
      ],
      itemHints: hints(
        'Le message dit où le nombre manque.',
        'The message says where the number is missing.',
        'C\'est $value.',
        'It is $value.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  for (final entry in [
    (
      'Qu\'est-ce qu\'une erreur en programmation ?',
      'What is an error in programming?',
      'Un message qui dit ce qui manque.',
      'A message saying what is missing.',
      'Une preuve qu\'on a cassé quelque chose.',
      'Proof that you broke something.',
      'C11.3-error-means-broken',
    ),
    (
      'Une erreur peut-elle abîmer l\'appareil ?',
      'Can an error damage the device?',
      'Non : rien n\'est cassé.',
      'No: nothing is broken.',
      'Oui, un peu à chaque fois.',
      'Yes, a little each time.',
      'C11.3-error-means-broken',
    ),
    (
      'Que faut-il faire en premier devant une erreur ?',
      'What is the first thing to do when you see an error?',
      'La lire jusqu\'au bout.',
      'Read it all the way through.',
      'Tout effacer et recommencer.',
      'Delete everything and start again.',
      'C11.3-errors-mean-start-again',
    ),
    (
      'Pourquoi le message indique-t-il une ligne ?',
      'Why does the message name a line?',
      'Pour dire où regarder.',
      'To say where to look.',
      'Pour dire qui a fait la faute.',
      'To say whose fault it was.',
      'C11.3-error-is-a-judgement',
    ),
    (
      'Les grandes personnes qui programment ont-elles des erreurs ?',
      'Do grown-ups who program get errors?',
      'Oui, tous les jours.',
      'Yes, every day.',
      'Non, elles savent déjà.',
      'No, they already know how.',
      'C11.3-errors-are-for-beginners',
    ),
    (
      'Un programme qui ne se lit pas se joue-t-il quand même ?',
      'Does a program that cannot be read run anyway?',
      'Non : rien ne se passe du tout.',
      'No: nothing happens at all.',
      'Oui, jusqu\'à l\'erreur.',
      'Yes, up to the error.',
      'C11.3-broken-programs-half-run',
    ),
  ]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C11.3',
      type: ItemType.t6ReadAndAnswer,
      difficulty: Difficulty.d2,
      promptKeys: b(entry.$1, entry.$2),
      choices: [
        Choice(labelKeys: b(entry.$3, entry.$4), correct: true),
        Choice(
            labelKeys: b(entry.$5, entry.$6),
            correct: false,
            misconception: entry.$7),
        Choice(
            labelKeys: b('Ça dépend de l\'appareil.',
                'It depends on the device.'),
            correct: false,
            misconception: 'C11.3-error-means-broken'),
        Choice(
            labelKeys: b('Il faut appeler un adulte.',
                'You have to call a grown-up.'),
            correct: false,
            misconception: 'C11.3-errors-mean-start-again'),
      ],
      itemHints: hints(
        'Une erreur est une phrase, pas une punition.',
        'An error is a sentence, not a punishment.',
        'Elle dit quoi faire ensuite.',
        'It says what to do next.',
      ),
      wrongChoiceFr:
          'Une erreur est un message qui aide : elle n\'a rien cassé.',
      wrongChoiceEn:
          'An error is a message that helps: it has broken nothing.',
    ));
  }

  // T8 — explain.
  for (final entry in [
    (
      'Un ami dit : « j\'ai cassé l\'ordinateur ». Que réponds-tu ?',
      'A friend says: "I broke the computer". What do you answer?',
      'Rien n\'est cassé : Tika te dit ce qui manque.',
      'Nothing is broken: Tika is telling you what is missing.',
      'C\'est vrai, il faut le réparer.',
      'True, it needs fixing.',
      'C11.3-error-means-broken',
    ),
    (
      'Pourquoi une erreur est-elle utile ?',
      'Why is an error useful?',
      'Elle dit où chercher.',
      'It says where to look.',
      'Elle ne sert à rien.',
      'It serves no purpose.',
      'C11.3-error-is-a-judgement',
    ),
    (
      'Pourquoi ne pas tout effacer quand ça ne marche pas ?',
      'Why not delete everything when it does not work?',
      'Parce que presque tout était déjà juste.',
      'Because nearly all of it was already right.',
      'Parce qu\'effacer est interdit.',
      'Because deleting is not allowed.',
      'C11.3-errors-mean-start-again',
    ),
    (
      'Que veut dire « regarde la ligne 3 » ?',
      'What does "look at line 3" mean?',
      'Que le problème est visible à cet endroit.',
      'That the problem can be seen there.',
      'Que les trois premières lignes sont fausses.',
      'That the first three lines are wrong.',
      'C11.3-error-blames-everything',
    ),
  ]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C11.3',
      type: ItemType.t8Explain,
      difficulty: Difficulty.d3,
      promptKeys: b(entry.$1, entry.$2),
      choices: [
        Choice(labelKeys: b(entry.$3, entry.$4), correct: true),
        Choice(
            labelKeys: b(entry.$5, entry.$6),
            correct: false,
            misconception: entry.$7),
        Choice(
            labelKeys: b('Que le programme est perdu.',
                'That the program is lost.'),
            correct: false,
            misconception: 'C11.3-errors-mean-start-again'),
        Choice(
            labelKeys: b('Que Tika est fâchée.', 'That Tika is cross.'),
            correct: false,
            misconception: 'C11.3-error-is-a-judgement'),
      ],
      itemHints: hints(
        'Relis la phrase mot à mot.',
        'Read the sentence word by word.',
        'Elle décrit, elle ne juge pas.',
        'It describes; it does not judge.',
      ),
      wrongChoiceFr:
          'Le message décrit ce qui manque et où : c\'est une aide, pas un verdict.',
      wrongChoiceEn:
          'The message describes what is missing and where: it helps, it does not judge.',
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C11.4 — Mots-clés en anglais.
// Misconception: "English code is a new language to relearn".
//
// The best answer this world can give is not a sentence — it is the grader accepting the
// French version of an English program as a correct alternative, and passing it, because
// the two parse to the same tree. Every item here does exactly that, so the claim is not
// asserted anywhere; it is *demonstrated* on every single attempt.
//
// The items are written in English keywords (`keywords: 'en'`) and their alternatives are
// the French ones. A child who translates back and forth is right both times, which is
// what "the same language in different words" means.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC114() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C11.4-${(++n).toString().padLeft(2, '0')}';

  // T1 — build it with English words.
  for (final entry in [
    (4, 60, 90),
    (3, 80, 120),
    (6, 45, 60),
    (5, 55, 72),
    (8, 40, 45),
  ]) {
    final sides = entry.$1, side = entry.$2, turn = entry.$3;
    final solution = figureEn(sides, side, turn);
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C11.4',
      difficulty: Difficulty.d2,
      keywords: 'en',
      solution: solution,
      promptKeys: fillBoth(
        b('Écris la figure à {k} côtés avec les mots anglais.',
            'Write the {k}-sided shape using the English words.'),
        {'k': sides},
      ),
      wrong: [
        figureEn(sides - 1, side, turn),
        figureEn(sides, side + 20, turn),
        figureEn(sides, side, turn + 15),
      ],
      alternatives: [
        // The same program in French. It passes, and that is the concept.
        figureFr(sides, side, turn),
        '# the same thing\n$solution',
      ],
      itemHints: hints(
        'répète devient repeat.',
        'répète becomes repeat.',
        'avance devient forward, tournedroite devient turnright.',
        'avance becomes forward, tournedroite becomes turnright.',
      ),
      paletteScope: palette,
    ));
  }

  // T3 — which French word is it?
  for (final entry in [
    ('repeat', 'répète', 'avance', 'si'),
    ('forward', 'avance', 'répète', 'recule'),
    ('turnright', 'tournedroite', 'tournegauche', 'direction'),
    ('print', 'écris', 'demande', 'message'),
  ]) {
    final english = entry.$1, french = entry.$2;
    items.add(predict(
      id: id(),
      conceptId: 'C11.4',
      difficulty: Difficulty.d1,
      promptKeys: fillBoth(
        b('Quel mot français correspond à « {e} » ?',
            'Which French word matches "{e}"?'),
        {'e': english},
      ),
      choices: [
        Choice(labelKeys: b(french, french), correct: true),
        Choice(
            labelKeys: b(entry.$3, entry.$3),
            correct: false,
            misconception: 'C11.4-words-are-guessed'),
        Choice(
            labelKeys: b(entry.$4, entry.$4),
            correct: false,
            misconception: 'C11.4-words-are-guessed'),
        Choice(
            labelKeys: b('aucun : c\'est un autre langage',
                'none: it is another language'),
            correct: false,
            misconception: 'C11.4-english-is-a-new-language'),
      ],
      itemHints: hints(
        'Les deux mots font la même chose.',
        'The two words do the same thing.',
        'Seule l\'orthographe change.',
        'Only the spelling changes.',
      ),
      wrongChoiceFr:
          'Chaque bloc a deux noms : un français et un anglais, pour le même bloc.',
      wrongChoiceEn:
          'Every block has two names, one French and one English, for the same block.',
    ));
  }

  // T4 — translate one word inside a working program.
  for (final entry in [
    (4, 60, 90, 'repeat'),
    (3, 80, 120, 'forward'),
    (6, 45, 60, 'turnright'),
    (5, 55, 72, 'repeat'),
    (8, 40, 45, 'forward'),
  ]) {
    final sides = entry.$1, side = entry.$2, turn = entry.$3, word = entry.$4;
    final solution = figureEn(sides, side, turn);
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C11.4',
      difficulty: Difficulty.d2,
      keywords: 'en',
      withHoles: solution.replaceFirst(word, '___'),
      solution: solution,
      promptKeys: fillBoth(
        b('Complète avec le mot anglais qui manque.',
            'Fill in the missing English word.'),
        {'w': word},
      ),
      wrong: [
        figureEn(sides, side + 25, turn),
        figureEn(sides - 1, side, turn),
        figureEn(sides, side, turn + 20),
      ],
      alternatives: [
        figureFr(sides, side, turn),
        '# the missing word\n$solution',
      ],
      itemHints: hints(
        'Regarde ce que le bloc fait.',
        'Look at what the block does.',
        'Écris son nom anglais.',
        'Write its English name.',
      ),
      paletteScope: palette,
    ));
  }

  // T5 — Parsons, with English lines.
  for (final entry in [
    (4, 60, 90),
    (3, 80, 120),
    (6, 45, 60),
    (5, 55, 72),
  ]) {
    final sides = entry.$1, side = entry.$2, turn = entry.$3;
    final solution = figureEn(sides, side, turn);
    items.add(parsons(
      id: id(),
      conceptId: 'C11.4',
      difficulty: Difficulty.d2,
      keywords: 'en',
      solution: solution,
      promptKeys: fillBoth(
        b('Remets les lignes anglaises en ordre pour la figure à {k} côtés.',
            'Put the English lines back in order for the {k}-sided shape.'),
        {'k': sides},
      ),
      wrong: [
        'repeat $sides {\n  turnright $turn\n  forward $side\n}\nforward $side',
        'forward $side\nrepeat $sides {\n  turnright $turn\n}',
        figureEn(sides - 1, side, turn),
      ],
      alternatives: [
        figureFr(sides, side, turn),
        '# back in order\n$solution',
      ],
      itemHints: hints(
        'C\'est l\'ordre que tu connais déjà.',
        'It is the order you already know.',
        'Seuls les mots ont changé.',
        'Only the words have changed.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  for (final entry in [
    (
      'Les mots anglais font-ils autre chose que les français ?',
      'Do the English words do anything different from the French ones?',
      'Non : ce sont les mêmes blocs.',
      'No: they are the same blocks.',
      'Oui : c\'est un autre langage.',
      'Yes: it is another language.',
      'C11.4-english-is-a-new-language',
    ),
    (
      'Peut-on changer de mots au milieu d\'un programme écrit ?',
      'Can you switch words in the middle of a written program?',
      'Oui : le programme ne change pas.',
      'Yes: the program does not change.',
      'Non : il faut tout retaper.',
      'No: you have to retype it all.',
      'C11.4-switching-retypes',
    ),
    (
      'Pourquoi apprendre les mots anglais ?',
      'Why learn the English words?',
      'Parce que la plupart des programmes du monde s\'écrivent ainsi.',
      'Because most programs in the world are written that way.',
      'Parce que le français ne marche plus après.',
      'Because French stops working afterwards.',
      'C11.4-french-stops-working',
    ),
    (
      'Combien de langages KODO a-t-il ?',
      'How many languages does KODO have?',
      'Un seul, avec deux jeux de mots.',
      'One, with two sets of words.',
      'Deux, un par jeu de mots.',
      'Two, one per set of words.',
      'C11.4-english-is-a-new-language',
    ),
  ]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C11.4',
      type: ItemType.t6ReadAndAnswer,
      difficulty: Difficulty.d2,
      promptKeys: b(entry.$1, entry.$2),
      choices: [
        Choice(labelKeys: b(entry.$3, entry.$4), correct: true),
        Choice(
            labelKeys: b(entry.$5, entry.$6),
            correct: false,
            misconception: entry.$7),
        Choice(
            labelKeys: b('Ça dépend du programme.',
                'It depends on the program.'),
            correct: false,
            misconception: 'C11.4-words-are-guessed'),
        Choice(
            labelKeys: b('Seulement pour les blocs simples.',
                'Only for the simple blocks.'),
            correct: false,
            misconception: 'C11.4-english-is-a-new-language'),
      ],
      itemHints: hints(
        'Change les mots et relance le programme.',
        'Switch the words and run the program again.',
        'Le dessin est exactement le même.',
        'The drawing is exactly the same.',
      ),
      wrongChoiceFr:
          'Un seul langage, deux façons d\'écrire ses mots : le programme est le même.',
      wrongChoiceEn:
          'One language, two ways of spelling its words: the program is the same.',
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// Tutorials (§4.2: Je regarde · On fait ensemble · Je fais).
//
// The narration says *texte*, *clavier*, *dièse* and *mot anglais*, and never *syntaxe*
// — which is on `FR-M5-03`'s jargon list, and is in any case the thing World 11 exists to
// make unremarkable rather than to name.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Tutorial> world11Tutorials() => [
      tutorialFor(
        conceptId: 'C11.1',
        conceptName: b('Les blocs et le texte disent pareil.',
            'Blocks and text say the same thing.'),
        palette: palette,
        steps: [
          watchStep(
            'C11.1',
            'Le même carré, écrit au clavier.',
            'The same square, typed on the keyboard.',
            figureFr(4, 60, 90),
            ideas: ['text', 'braces'],
          ),
          togetherStep(
            'C11.1',
            'À toi. Écris avance 60 sur une ligne.',
            'Your turn. Type forward 60 on one line.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Le mot, une espace, puis le nombre.',
            hintEn: 'The word, a space, then the number.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C11.1',
            'Écris au clavier un carré de 60 pas.',
            'Type a square of 60 steps.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'L\'accolade ouvre et referme la répétition.',
            hintEn: 'The bracket opens and closes the repeat.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C11.2',
        conceptName: b('Le dièse met une ligne de côté.',
            'The hash puts a line aside.'),
        palette: palette,
        steps: [
          watchStep(
            'C11.2',
            'La ligne avec un dièse ne se joue pas.',
            'The line with a hash does not play.',
            '# avance 200\n${figureFr(4, 60, 90)}',
            ideas: ['comment', 'skipping'],
          ),
          togetherStep(
            'C11.2',
            'Mets un dièse devant la première ligne.',
            'Put a hash in front of the first line.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Le dièse s\'écrit tout au début.',
            hintEn: 'The hash goes right at the start.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C11.2',
            'Écris un dessin et une ligne mise de côté.',
            'Write a drawing and one line put aside.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Tika saute tout ce qui suit le dièse.',
            hintEn: 'Tika skips everything after the hash.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C11.3',
        conceptName: b('Une erreur dit ce qui manque.',
            'An error says what is missing.'),
        palette: palette,
        steps: [
          watchStep(
            'C11.3',
            'Tika s\'arrête et explique ce qui manque.',
            'Tika stops and explains what is missing.',
            '\$côté = 60\n${figureFr(4, 60, 90)}',
            ideas: ['error', 'reading'],
          ),
          togetherStep(
            'C11.3',
            'Remplis la boîte avant de t\'en servir.',
            'Fill the box before you use it.',
            assigns: 'côté',
            hintFr: 'Écris \$côté = 60 sur la première ligne.',
            hintEn: 'Write \$côté = 60 on the first line.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C11.3',
            'Répare un programme en lisant ce que Tika dit.',
            'Fix a program by reading what Tika says.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'La phrase dit quoi et souvent où.',
            hintEn: 'The sentence says what, and often where.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C11.4',
        conceptName: b('Les mêmes blocs, en mots anglais.',
            'The same blocks, in English words.'),
        palette: palette,
        steps: [
          watchStep(
            'C11.4',
            'Le même carré, avec des mots anglais.',
            'The same square, with English words.',
            figureEn(4, 60, 90),
            ideas: ['english', 'same-program'],
          ),
          togetherStep(
            'C11.4',
            'Écris forward 60 à la place d\'avance 60.',
            'Type forward 60 in place of avance 60.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'avance et forward sont le même bloc.',
            hintEn: 'avance and forward are the same block.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C11.4',
            'Écris un carré avec les mots anglais.',
            'Write a square with the English words.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'répète devient repeat, avance devient forward.',
            hintEn: 'répète becomes repeat, avance becomes forward.',
          ),
        ],
      ),
    ];

void main() {
  publishWorld(
    world: 11,
    nameKeys: b('Je passe au texte', 'Moving to text'),
    conceptGraph: conceptGraph,
    committed: committed,
    items: [
      ...conceptC111(),
      ...conceptC112(),
      ...conceptC113(),
      ...conceptC114(),
    ],
    tutorials: world11Tutorials(),
    assetKeys: const ['art/tika.svg', 'art/world11-texte.svg'],
  );
}
