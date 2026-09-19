// Authors World 12 — "Mon application" — and writes it out as a content pack.
//
//     dart tool/author_world12.dart
//
// The last world, and the only one whose subject is not a feature of the language. Two of
// its four concepts have no new syntax at all; what they teach is what to do before you
// type and what to do after it runs. The four misconceptions are four habits:
//
//   C12.1  "you start by coding"
//   C12.2  "a list is one variable with a long name"
//   C12.3  "an app is one screen"
//   C12.4  "a project is finished when it runs once"
//
// **A screen is not a thing KODO has**, and that is deliberate rather than a gap. An app
// with three screens is a box holding which one is showing and a `si` that calls the block
// for it — decomposition from World 9 and a test from World 7, put together. C12.3's items
// build exactly that, because it is what an app *is*, and because a child who has built
// one has built an app rather than learned a word for one.
//
// C12.2 is the one concept here with real syntax behind it, and the language earns it:
// lists are one-indexed, so `$notes[0]` stops with "ce numéro n'existe pas" — which makes
// the off-by-one a thing a child meets once and remembers, rather than a silent zero.

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';

import 'authoring.dart';

const conceptGraph = <String, List<String>>{
  'C12.1': ['C9.4'],
  'C12.2': ['C6.2'],
  'C12.3': ['C7.3'],
  'C12.4': ['C12.3'],
};

/// §6.3's commitment, copied from `spec/concepts.json` and checked against it by
/// `publishWorld`.
const committed = <String, int>{
  'C12.1': 20,
  'C12.2': 24,
  'C12.3': 22,
  'C12.4': 20,
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

String figure(int sides, int side, int turn) =>
    'répète $sides {\n  avance $side\n  tournedroite $turn\n}';

String learn(String name, String body) =>
    'apprends $name {\n${body.split('\n').map((l) => '  $l').join('\n')}\n}';

/// Four choices where only the first is right, for the process concepts.
List<Choice> processChoices(
        (String, String) right, List<(String, String, String)> wrong) =>
    [
      Choice(labelKeys: b(right.$1, right.$2), correct: true),
      for (final w in wrong)
        Choice(labelKeys: b(w.$1, w.$2), correct: false, misconception: w.$3),
    ];

// ═══════════════════════════════════════════════════════════════════════════════════════
// C12.1 — Planifier un projet.
// Misconception: "you start by coding".
//
// You start by saying what it should do, and the cheapest way to find out you were wrong
// is to find out before you have typed anything. That is a claim about people, not about
// KODO, so most of these items are read-and-answer — and the three that are programs are
// Parsons items over a decomposed project, because "what is the plan" and "what order do
// the parts go in" are the same question asked twice.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC121() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C12.1-${(++n).toString().padLeft(2, '0')}';

  // T6 — read and answer.
  for (final entry in [
    (
      'Par quoi commence un projet ?',
      'What does a project start with?',
      ('Par dire ce qu\'il doit faire.', 'By saying what it should do.'),
      [
        (
          'Par écrire le programme.',
          'By writing the program.',
          'C12.1-start-by-coding'
        ),
        (
          'Par choisir les couleurs.',
          'By choosing the colours.',
          'C12.1-start-with-looks'
        ),
        (
          'Par le nom du projet.',
          'By the project name.',
          'C12.1-start-with-a-name'
        ),
      ],
    ),
    (
      'À quoi sert un plan ?',
      'What is a plan for?',
      ('À savoir quoi faire ensuite.', 'To know what to do next.'),
      [
        (
          'À faire plaisir au maître.',
          'To please the teacher.',
          'C12.1-plan-is-homework'
        ),
        (
          'À rendre le programme plus rapide.',
          'To make the program faster.',
          'C6.1-box-is-speed'
        ),
        (
          'À rien : on voit en avançant.',
          'Nothing: you see as you go.',
          'C12.1-start-by-coding'
        ),
      ],
    ),
    (
      'Combien de parts un projet doit-il avoir ?',
      'How many parts should a project have?',
      (
        'Autant que de choses qu\'il sait faire.',
        'As many as the things it can do.'
      ),
      [
        (
          'Une seule, sinon c\'est compliqué.',
          'One, otherwise it gets complicated.',
          'C9.4-one-piece-only'
        ),
        (
          'Le plus possible.',
          'As many as possible.',
          'C12.1-more-parts-is-better'
        ),
        ('Trois, toujours.', 'Three, always.', 'C12.1-plans-have-a-shape'),
      ],
    ),
    (
      'Que fais-tu si ton plan ne marche pas ?',
      'What do you do if your plan does not work?',
      (
        'Je le change : c\'est à ça qu\'il sert.',
        'I change it: that is what it is for.'
      ),
      [
        (
          'Je continue quand même.',
          'I carry on anyway.',
          'C12.1-plans-are-promises'
        ),
        (
          'J\'abandonne le projet.',
          'I give up on the project.',
          'C12.1-plans-are-promises'
        ),
        (
          'Je recommence tout de zéro.',
          'I start everything again.',
          'C11.3-errors-mean-start-again'
        ),
      ],
    ),
    (
      'Quelle est la première question à se poser ?',
      'What is the first question to ask?',
      (
        'Qui va s\'en servir, et pour quoi faire ?',
        'Who will use it, and what for?'
      ),
      [
        (
          'Quels blocs vais-je utiliser ?',
          'Which blocks will I use?',
          'C12.1-start-by-coding'
        ),
        (
          'Combien de lignes ça fera ?',
          'How many lines will it be?',
          'C12.1-size-first'
        ),
        (
          'Quel nom je vais lui donner ?',
          'What shall I call it?',
          'C12.1-start-with-a-name'
        ),
      ],
    ),
    (
      'Faut-il tout planifier avant d\'écrire ?',
      'Should everything be planned before writing?',
      (
        'Non : assez pour commencer la première part.',
        'No: enough to start the first part.'
      ),
      [
        (
          'Oui, jusqu\'à la dernière ligne.',
          'Yes, down to the last line.',
          'C12.1-plans-are-promises'
        ),
        (
          'Non : on n\'a jamais besoin de plan.',
          'No: you never need a plan.',
          'C12.1-start-by-coding'
        ),
        (
          'Ça dépend de la longueur du projet.',
          'It depends how long the project is.',
          'C12.1-size-first'
        ),
      ],
    ),
  ]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C12.1',
      type: ItemType.t6ReadAndAnswer,
      difficulty: Difficulty.d2,
      promptKeys: b(entry.$1, entry.$2),
      choices: processChoices(entry.$3, entry.$4),
      itemHints: hints(
        'Pense à ce que tu fais avant de dessiner.',
        'Think about what you do before you draw.',
        'On sait d\'abord ce qu\'on veut.',
        'You know what you want first.',
      ),
      wrongChoiceFr:
          'Un projet commence par ce qu\'il doit faire, pas par les blocs.',
      wrongChoiceEn:
          'A project starts with what it should do, not with the blocks.',
    ));
  }

  /* T3 — the order of the work. Choice items, because there is no canvas that could show
     the difference between planning first and planning never. */
  for (final entry in [
    (
      'Tu veux faire un jeu de dés. Que fais-tu en premier ?',
      'You want to make a dice game. What do you do first?',
      ('Écrire les règles du jeu.', 'Write the rules of the game.'),
      [
        ('Écrire le programme.', 'Write the program.', 'C12.1-start-by-coding'),
        ('Dessiner les dés.', 'Draw the dice.', 'C12.1-start-with-looks'),
        ('Choisir le titre.', 'Pick the title.', 'C12.1-start-with-a-name'),
      ],
    ),
    (
      'Ton projet a trois parts. Par laquelle commencer ?',
      'Your project has three parts. Which one do you start with?',
      (
        'Par la plus petite qui marche toute seule.',
        'The smallest one that works on its own.'
      ),
      [
        ('Par la plus jolie.', 'The prettiest one.', 'C12.1-start-with-looks'),
        ('Par la plus difficile.', 'The hardest one.', 'C9.4-hardest-first'),
        (
          'Par les trois en même temps.',
          'All three at once.',
          'C9.4-one-piece-only'
        ),
      ],
    ),
    (
      'Tu as écrit la moitié et tu changes d\'avis. Que fais-tu ?',
      'You have written half of it and you change your mind. What do you do?',
      ('Je change le plan et je continue.', 'I change the plan and carry on.'),
      [
        (
          'Je finis comme prévu.',
          'I finish as planned.',
          'C12.1-plans-are-promises'
        ),
        (
          'J\'efface tout.',
          'I delete everything.',
          'C11.3-errors-mean-start-again'
        ),
        (
          'J\'arrête le projet.',
          'I stop the project.',
          'C12.1-plans-are-promises'
        ),
      ],
    ),
  ]) {
    items.add(predict(
      id: id(),
      conceptId: 'C12.1',
      difficulty: Difficulty.d2,
      promptKeys: b(entry.$1, entry.$2),
      choices: processChoices(entry.$3, entry.$4),
      itemHints: hints(
        'Une part qui marche vaut mieux qu\'un tout qui attend.',
        'One working part beats a whole that is waiting.',
        'Commence par ce que tu peux finir.',
        'Start with what you can finish.',
      ),
      wrongChoiceFr:
          'On avance par petites parts finies, et le plan suit ce qu\'on apprend.',
      wrongChoiceEn:
          'You go in small finished parts, and the plan follows what you learn.',
    ));
  }

  /* T5 and T4 — the plan, as a program. "What is the plan" and "what order do the parts
     go in" are the same question, and this is the half of it a canvas can answer. */
  for (final entry in [
    ('titre', 'corps', 4, 50, 90, 3, 60, 120),
    ('cadre', 'motif', 6, 40, 60, 4, 45, 90),
    ('fond', 'dessus', 3, 70, 120, 5, 40, 72),
  ]) {
    final first = entry.$1, second = entry.$2;
    final firstBody = figure(entry.$3, entry.$4, entry.$5);
    final secondBody = figure(entry.$6, entry.$7, entry.$8);
    final solution =
        '${learn(first, firstBody)}\n${learn(second, secondBody)}\n'
        '$first\ntournedroite 180\n$second';
    items.add(parsons(
      id: id(),
      conceptId: 'C12.1',
      difficulty: Difficulty.d3,
      solution: solution,
      promptKeys: fillBoth(
        b('Le plan : apprendre {a}, apprendre {b}, puis les jouer dans l\'ordre.',
            'The plan: teach {a}, teach {b}, then run them in order.'),
        {'a': first, 'b': second},
      ),
      wrong: [
        '${learn(first, firstBody)}\n${learn(second, secondBody)}',
        '${learn(first, firstBody)}\n${learn(second, secondBody)}\n'
            '$second\ntournedroite 180\n$first',
        '${learn(first, firstBody)}\n${learn(second, secondBody)}\n$first',
      ],
      assertions: [
        const DefinesProcedure(min: 2),
        const ContainsNode('ProcCall', min: 2),
      ],
      alternatives: [
        '# le plan, dans l\'ordre\n$solution',
        solution.replaceFirst('apprends $first {', 'apprends $first  {'),
      ],
      itemHints: hints(
        'Chaque part s\'apprend avant d\'être jouée.',
        'Each part is taught before it is played.',
        'Le plan dit dans quel ordre les jouer.',
        'The plan says what order to play them in.',
      ),
      paletteScope: palette,
    ));
  }

  for (final entry in [
    ('titre', 4, 50, 90),
    ('cadre', 6, 40, 60),
    ('fond', 3, 70, 120),
  ]) {
    final name = entry.$1;
    final body = figure(entry.$2, entry.$3, entry.$4);
    final solution = '${learn(name, body)}\n$name\ntournedroite 180\n$name';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C12.1',
      difficulty: Difficulty.d2,
      withHoles: '${learn(name, body)}\n___\ntournedroite 180\n___',
      solution: solution,
      promptKeys: fillBoth(
        b('La part {n} est prête. Complète le plan pour la jouer deux fois.',
            'The part {n} is ready. Fill the plan in to play it twice.'),
        {'n': name},
      ),
      wrong: [
        learn(name, body),
        '${learn(name, body)}\n$name',
        '${learn(name, body)}\n$body\ntournedroite 180\n$body',
      ],
      assertions: [
        const DefinesProcedure(),
        const ContainsNode('ProcCall', min: 2),
      ],
      alternatives: [
        '# deux fois la même part\n$solution',
        solution.replaceFirst('apprends $name {', 'apprends $name  {'),
      ],
      itemHints: hints(
        'Une part se joue en écrivant son nom.',
        'A part is played by writing its name.',
        'Écris $name sur chaque ligne vide.',
        'Write $name on each empty line.',
      ),
      paletteScope: palette,
    ));
  }

  // T9 — five open builds. The plan is the deliverable.
  for (final entry in [
    (
      'Fais un projet en deux parts nommées.',
      'Make a project in two named parts.'
    ),
    ('Fais une carte d\'anniversaire.', 'Make a birthday card.'),
    ('Fais un motif qui se répète.', 'Make a pattern that repeats.'),
    ('Fais une affiche pour ta classe.', 'Make a poster for your class.'),
    (
      'Reprends ton dessin préféré et coupe-le en parts.',
      'Take your favourite drawing and cut it into parts.'
    ),
  ]) {
    items.add(openBuild(
      id: id(),
      conceptId: 'C12.1',
      difficulty: Difficulty.d4,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine(
            'Ton projet a au moins deux parts nommées.',
            'Your project has at least two named parts.',
            const DefinesProcedure(min: 2)),
        rubricLine(
            'Le programme principal joue les parts.',
            'The main program plays the parts.',
            const ContainsNode('ProcCall', min: 2)),
        rubricLine('Tika dessine quelque chose.', 'Tika draws something.',
            const UsesOpcode('MOVE_FORWARD')),
        rubricLine(
            'Le programme principal reste court.',
            'The main program stays short.',
            const BlockCountWithin(min: 4, max: 40)),
      ],
      itemHints: hints(
        'Dis d\'abord ce que ça doit faire.',
        'Say first what it should do.',
        'Puis coupe-le en parts que tu peux finir.',
        'Then cut it into parts you can finish.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C12.2 — Listes.
// Misconception: "a list is one variable with a long name".
//
// It is not: it is many boxes with one name and a number each, and the difference shows
// the moment a loop walks it. `$tailles[$i]` inside a `pour` draws three different sides
// from one line — and three separate boxes would need three lines.
//
// KODO counts from one, so `$notes[0]` stops with "ce numéro n'existe pas". That is an
// authored choice (§4.3) and it is worth an item of its own: a language that answered
// zero silently would teach the off-by-one by letting a child get the wrong answer
// quietly, which is the worst way to learn anything.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC122() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C12.2-${(++n).toString().padLeft(2, '0')}';

  /// A list literal written the way a child writes one.
  String list(List<int> values) => '[${values.join(', ')}]';

  /// Walk a list of side lengths, one per turn.
  String walk(List<int> sides, int turn) => '\$tailles = ${list(sides)}\n'
      'pour \$i = 1 à ${sides.length} {\n'
      '  avance \$tailles[\$i]\n  tournedroite $turn\n}';

  /* T2 — five bugs, and three of them are the off-by-one in its three costumes: starting
     at zero, ending one past the end, and counting the list rather than its places. */
  for (final entry in [
    ([30, 50, 70], 90, 'from-zero'),
    ([40, 60, 80], 120, 'past-the-end'),
    ([25, 45, 65, 85], 90, 'from-zero'),
    ([35, 55, 75], 60, 'past-the-end'),
    ([20, 40, 60, 80], 72, 'from-zero'),
  ]) {
    final sides = entry.$1, turn = entry.$2, bug = entry.$3;
    final solution = walk(sides, turn);
    final broken = bug == 'from-zero'
        ? solution.replaceFirst('pour \$i = 1 à', 'pour \$i = 0 à')
        : solution.replaceFirst(
            'à ${sides.length} {', 'à ${sides.length + 1} {');
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C12.2',
      difficulty: Difficulty.d3,
      broken: broken,
      solution: solution,
      promptKeys: fillBoth(
        b(
            'Tika dit que ce numéro n\'existe pas. La liste a {k} places, '
                'numérotées de 1 à {k}.',
            'Tika says that number does not exist. The list has {k} places, '
                'numbered 1 to {k}.'),
        {'k': sides.length},
      ),
      wrong: [
        broken,
        // The other half of the off-by-one.
        bug == 'from-zero'
            ? solution.replaceFirst(
                'à ${sides.length} {', 'à ${sides.length + 1} {')
            : solution.replaceFirst('pour \$i = 1 à', 'pour \$i = 0 à'),
        // One place short: it runs, and draws the wrong figure.
        solution.replaceFirst('à ${sides.length} {', 'à ${sides.length - 1} {'),
      ],
      assertions: [const UsesVariable(name: 'tailles', minReads: 1)],
      alternatives: [
        '# de 1 à ${sides.length}\n$solution',
        solution.replaceFirst('\n', '\n\n'),
      ],
      itemHints: hints(
        'La première place porte le numéro 1.',
        'The first place is numbered 1.',
        'La dernière porte le numéro ${sides.length}.',
        'The last one is numbered ${sides.length}.',
      ),
      paletteScope: palette,
    ));
  }

  // T3 — what is in that place?
  for (final entry in [
    ('[3, 1, 2]', 1, '3', '1', '2'),
    ('[3, 1, 2]', 3, '2', '3', '1'),
    ('[10, 20, 30]', 2, '20', '10', '30'),
    ('[10, 20, 30]', 1, '10', '20', '30'),
    ('[5, 8]', 2, '8', '5', '13'),
    ('[7, 4, 9, 2]', 4, '2', '9', '7'),
  ]) {
    final source = entry.$1, place = entry.$2, value = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C12.2',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Que va écrire Tika ?\n\n\$l = {p}\nécris \$l[{i}]',
            'What will Tika print?\n\n\$l = {p}\nprint \$l[{i}]'),
        {'p': source, 'i': place},
      ),
      choices: [
        Choice(labelKeys: b(value, value), correct: true),
        Choice(
            labelKeys: b(entry.$4, entry.$4),
            correct: false,
            misconception: 'C12.2-counts-from-zero'),
        Choice(
            labelKeys: b(entry.$5, entry.$5),
            correct: false,
            misconception: 'C12.2-wrong-place'),
        Choice(
            labelKeys: b('toute la liste', 'the whole list'),
            correct: false,
            misconception: 'C12.2-list-is-one-variable'),
      ],
      itemHints: hints(
        'Compte les places à partir de un.',
        'Count the places starting from one.',
        'Le numéro est entre les crochets.',
        'The number is inside the square brackets.',
      ),
      wrongChoiceFr:
          'Une liste a des places numérotées à partir de 1, et chacune garde un nombre.',
      wrongChoiceEn:
          'A list has places numbered from 1, and each one keeps a number.',
    ));
  }

  // T4 — the hole is the place number, or the list itself.
  for (final entry in [
    ([30, 50, 70], 90),
    ([40, 60, 80], 120),
    ([25, 45, 65, 85], 90),
    ([35, 55, 75], 60),
    ([20, 40, 60, 80], 72),
  ]) {
    final sides = entry.$1, turn = entry.$2;
    final solution = walk(sides, turn);
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C12.2',
      difficulty: Difficulty.d2,
      withHoles: solution.replaceFirst('à ${sides.length} {', 'à ___ {'),
      solution: solution,
      promptKeys: b('Complète pour parcourir toutes les places de la liste.',
          'Fill in the blank to walk every place in the list.'),
      wrong: [
        solution.replaceFirst('à ${sides.length} {', 'à ${sides.length - 1} {'),
        solution.replaceFirst('à ${sides.length} {', 'à ${sides.length - 2} {'),
        solution.replaceFirst('à ${sides.length} {', 'à 1 {'),
      ],
      assertions: [const UsesVariable(name: 'tailles', minReads: 1)],
      alternatives: [
        '# toutes les places\n$solution',
        solution.replaceFirst('\n', '\n\n'),
      ],
      itemHints: hints(
        'Compte les nombres entre les crochets.',
        'Count the numbers inside the square brackets.',
        'Il y en a ${sides.length}.',
        'There are ${sides.length}.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  for (final entry in [
    (
      'Qu\'est-ce qu\'une liste ?',
      'What is a list?',
      ('Plusieurs places sous un seul nom.', 'Several places under one name.'),
      [
        (
          'Une boîte avec un nom très long.',
          'A box with a very long name.',
          'C12.2-list-is-one-variable'
        ),
        (
          'Un programme rangé dans une boîte.',
          'A program stored in a box.',
          'C6.1-box-holds-the-program'
        ),
        (
          'Un dessin fait de plusieurs traits.',
          'A drawing made of several lines.',
          'C6.1-box-holds-the-drawing'
        ),
      ],
    ),
    (
      'Quel est le numéro de la première place ?',
      'What number is the first place?',
      ('1', '1'),
      [
        ('0', '0', 'C12.2-counts-from-zero'),
        (
          'Ça dépend de la liste.',
          'It depends on the list.',
          'C12.2-wrong-place'
        ),
        (
          'La première n\'a pas de numéro.',
          'The first one has no number.',
          'C12.2-list-is-one-variable'
        ),
      ],
    ),
    (
      r'Que fait Tika devant $l[0] ?',
      r'What does Tika do with $l[0]?',
      (
        'Elle s\'arrête et dit que ce numéro n\'existe pas.',
        'She stops and says that number does not exist.'
      ),
      [
        (
          'Elle rend la première place.',
          'She gives the first place.',
          'C12.2-counts-from-zero'
        ),
        ('Elle rend zéro.', 'She gives back zero.', 'C6.1-box-is-empty'),
        (
          'Elle rend toute la liste.',
          'She gives the whole list.',
          'C12.2-list-is-one-variable'
        ),
      ],
    ),
    (
      'Pourquoi une liste plutôt que trois boîtes ?',
      'Why a list rather than three boxes?',
      (
        'Parce qu\'une boucle peut les parcourir toutes.',
        'Because a loop can walk all of them.'
      ),
      [
        (
          'Parce que c\'est plus joli.',
          'Because it looks nicer.',
          'C12.2-list-is-decoration'
        ),
        (
          'Parce que trois boîtes, c\'est interdit.',
          'Because three boxes is not allowed.',
          'C12.2-list-is-compulsory'
        ),
        (
          'Ça revient au même.',
          'It comes to the same thing.',
          'C12.2-list-is-one-variable'
        ),
      ],
    ),
    (
      'Combien de nombres une place peut-elle garder ?',
      'How many numbers can one place keep?',
      ('Un seul, comme une boîte.', 'One, like a box.'),
      [
        (
          'Autant qu\'on veut.',
          'As many as you like.',
          'C12.2-list-is-one-variable'
        ),
        (
          'Aucun : la liste les garde toutes.',
          'None: the list keeps them all.',
          'C12.2-list-is-one-variable'
        ),
        (
          'Deux : le numéro et le nombre.',
          'Two: the number and the value.',
          'C12.2-wrong-place'
        ),
      ],
    ),
  ]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C12.2',
      type: ItemType.t6ReadAndAnswer,
      difficulty: Difficulty.d2,
      promptKeys: b(entry.$1, entry.$2),
      choices: processChoices(entry.$3, entry.$4),
      itemHints: hints(
        'Pense à des casiers numérotés.',
        'Think of numbered pigeonholes.',
        'Un nom pour le meuble, un numéro par casier.',
        'One name for the unit, one number per hole.',
      ),
      wrongChoiceFr:
          'Une liste est un meuble à casiers : un nom, des places numérotées.',
      wrongChoiceEn:
          'A list is a set of pigeonholes: one name, numbered places.',
    ));
  }

  // T9 — three open builds.
  for (final entry in [
    (
      'Dessine une figure dont les côtés viennent d\'une liste.',
      'Draw a shape whose sides come from a list.'
    ),
    (
      'Fais un escalier avec une liste de hauteurs.',
      'Make a staircase from a list of heights.'
    ),
    (
      'Écris toutes les places d\'une liste, une par une.',
      'Print every place in a list, one at a time.'
    ),
  ]) {
    final prints = entry.$1.startsWith('Écris');
    items.add(openBuild(
      id: id(),
      conceptId: 'C12.2',
      difficulty: Difficulty.d3,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine('Tu ranges une liste dans une boîte.',
            'You put a list into a box.', const UsesVariable(minReads: 1)),
        rubricLine('Une boucle parcourt les places.',
            'A loop walks the places.', const ContainsNode('For')),
        rubricLine(
            'Tu lis chaque place par son numéro.',
            'You read each place by its number.',
            const ContainsNode('IndexOf')),
        if (prints)
          rubricLine('Tika écrit ce qu\'elle trouve.',
              'Tika prints what she finds.', const UsesOpcode('PRINT'))
        else
          rubricLine('Tika dessine avec.', 'Tika draws with it.',
              const UsesOpcode('MOVE_FORWARD')),
      ],
      itemHints: hints(
        'Écris la liste entre crochets.',
        'Write the list inside square brackets.',
        'Parcours-la de 1 au nombre de places.',
        'Walk it from 1 to the number of places.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C12.3 — Écrans et navigation.
// Misconception: "an app is one screen".
//
// KODO has no screen block, and this concept is the reason that is not a gap. An app with
// three screens is a box holding which one is showing and a `si` that calls the block for
// it: World 9's decomposition and World 7's test, put together. A child who builds that
// has built an app — not learned the word for one — and everything they need arrived two
// worlds ago.
//
// So every item here is the same shape: a box called `$écran`, one named block per screen,
// and a test that picks. The distractor that draws every screen at once is the
// misconception, and it is exactly what a program without the test does.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC123() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C12.3-${(++n).toString().padLeft(2, '0')}';

  /// Two screens, one showing.
  String app(int showing, String first, String second, String bodyA,
          String bodyB) =>
      '\$écran = $showing\n${learn(first, bodyA)}\n${learn(second, bodyB)}\n'
      'si \$écran == 1 {\n  $first\n}\nsinon {\n  $second\n}';

  // T1 — build the app.
  for (final entry in [
    (1, 'accueil', 'jeu', 4, 50, 90, 3, 60, 120),
    (2, 'accueil', 'jeu', 4, 50, 90, 3, 60, 120),
    (1, 'menu', 'scores', 6, 40, 60, 5, 45, 72),
    (2, 'menu', 'scores', 6, 40, 60, 5, 45, 72),
    (1, 'titre', 'aide', 3, 70, 120, 4, 45, 90),
  ]) {
    final showing = entry.$1, first = entry.$2, second = entry.$3;
    final bodyA = figure(entry.$4, entry.$5, entry.$6);
    final bodyB = figure(entry.$7, entry.$8, entry.$9);
    final solution = app(showing, first, second, bodyA, bodyB);
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C12.3',
      difficulty: Difficulty.d4,
      solution: solution,
      promptKeys: fillBoth(
        b(
            'Fais une application à deux écrans, {first} et {b}. La boîte \$écran '
                'garde {s}, et un seul écran s\'affiche.',
            'Make first two-screen app, {first} and {b}. The box \$screen holds {s}, '
                'and only one screen shows.'),
        {'first': first, 'b': second, 's': showing},
      ),
      wrong: [
        // Every screen at once: the misconception, drawn.
        '\$écran = $showing\n${learn(first, bodyA)}\n${learn(second, bodyB)}\n$first\n$second',
        // The other screen showing.
        app(showing == 1 ? 2 : 1, first, second, bodyA, bodyB),
        // Only one screen exists at all.
        '\$écran = $showing\n${learn(first, bodyA)}\n$first',
      ],
      assertions: [
        const DefinesProcedure(min: 2),
        const ContainsNode('If'),
        const UsesVariable(name: 'écran', minReads: 1),
      ],
      alternatives: [
        '# une application à deux écrans\n$solution',
        solution.replaceFirst('si \$écran == 1', 'si (\$écran == 1)'),
      ],
      itemHints: hints(
        'Chaque écran est une part nommée.',
        'Each screen is first named part.',
        'La boîte dit laquelle on montre.',
        'The box says which one is showing.',
      ),
      paletteScope: palette,
    ));
  }

  // T3 — which screen shows?
  for (final entry in [
    (1, 'accueil', 'jeu'),
    (2, 'accueil', 'jeu'),
    (3, 'menu', 'scores'),
    (1, 'titre', 'aide'),
  ]) {
    final showing = entry.$1, first = entry.$2, second = entry.$3;
    final shown = showing == 1 ? first : second;
    items.add(predict(
      id: id(),
      conceptId: 'C12.3',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b(
            'Quel écran s\'affiche ?\n\n\$écran = {s}\nsi \$écran == 1 {{\n  {un}\n}}\n'
                'sinon {{\n  {deux}\n}}',
            'Which screen shows?\n\n\$screen = {s}\nif \$screen == 1 {{\n  {un}\n}}\n'
                'else {{\n  {deux}\n}}'),
        {'s': showing, 'un': first, 'deux': second},
      ),
      choices: [
        Choice(labelKeys: b(shown, shown), correct: true),
        Choice(
            labelKeys:
                b(showing == 1 ? second : first, showing == 1 ? second : first),
            correct: false,
            misconception: 'C12.3-wrong-branch'),
        Choice(
            labelKeys: b('les deux', 'both of them'),
            correct: false,
            misconception: 'C12.3-app-is-one-screen'),
        Choice(
            labelKeys: b('aucun', 'neither'),
            correct: false,
            misconception: 'C7.3-false-stops-everything'),
      ],
      itemHints: hints(
        'Réponds d\'abord au test.',
        'Answer the test first.',
        'Un seul chemin est pris.',
        'Only one path is taken.',
      ),
      wrongChoiceFr:
          'La boîte \$écran choisit le chemin, et un seul écran se dessine.',
      wrongChoiceEn:
          'The box \$screen picks the path, and one screen only is drawn.',
    ));
  }

  // T4 — the hole is the screen the test picks, or the box that decides.
  for (final entry in [
    (1, 'accueil', 'jeu', 4, 50, 90, 3, 60, 120),
    (2, 'accueil', 'jeu', 4, 50, 90, 3, 60, 120),
    (1, 'menu', 'scores', 6, 40, 60, 5, 45, 72),
    (2, 'menu', 'scores', 6, 40, 60, 5, 45, 72),
    (1, 'titre', 'aide', 3, 70, 120, 4, 45, 90),
  ]) {
    final showing = entry.$1, first = entry.$2, second = entry.$3;
    final bodyA = figure(entry.$4, entry.$5, entry.$6);
    final bodyB = figure(entry.$7, entry.$8, entry.$9);
    final solution = app(showing, first, second, bodyA, bodyB);
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C12.3',
      difficulty: Difficulty.d3,
      withHoles: solution.replaceFirst('\$écran = $showing', '\$écran = ___'),
      solution: solution,
      promptKeys: fillBoth(
        b('Complète pour afficher l\'écran {w}.',
            'Fill in the blank to show the {w} screen.'),
        {'w': showing == 1 ? first : b},
      ),
      wrong: [
        app(showing == 1 ? 2 : 1, first, second, bodyA, bodyB),
        '\$écran = $showing\n${learn(first, bodyA)}\n${learn(second, bodyB)}\n$first\n$second',
        '\$écran = $showing\n${learn(first, bodyA)}\n${learn(second, bodyB)}',
      ],
      assertions: [
        const DefinesProcedure(min: 2),
        const ContainsNode('If'),
        const UsesVariable(name: 'écran', minReads: 1),
      ],
      alternatives: [
        '# l\'écran choisi\n$solution',
        solution.replaceFirst('si \$écran == 1', 'si (\$écran == 1)'),
      ],
      itemHints: hints(
        'Le test compare la boîte avec 1.',
        'The test compares the box with 1.',
        showing == 1 ? 'Mets 1.' : 'Mets autre chose que 1.',
        showing == 1 ? 'Put 1.' : 'Put something other than 1.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  for (final entry in [
    (
      'Qu\'est-ce qu\'un écran dans une application ?',
      'What is first screen in an app?',
      (
        'Une part nommée qu\'on affiche quand il faut.',
        'A named part shown when it is wanted.'
      ),
      [
        (
          'Un bloc spécial de KODO.',
          'A special KODO block.',
          'C12.3-screens-are-first-feature'
        ),
        ('Toute l\'application.', 'The whole app.', 'C12.3-app-is-one-screen'),
        ('Un arrière-plan.', 'A backdrop.', 'C10.4-backdrop-is-first-sprite'),
      ],
    ),
    (
      'Comment sait-on quel écran afficher ?',
      'How do you know which screen to show?',
      (
        'Une boîte garde le numéro de l\'écran.',
        'A box keeps the screen\'s number.'
      ),
      [
        ('KODO le décide.', 'KODO decides.', 'C12.3-screens-are-first-feature'),
        (
          'C\'est toujours le premier.',
          'It is always the first one.',
          'C12.3-app-is-one-screen'
        ),
        (
          'On les affiche tous.',
          'You show them all.',
          'C12.3-app-is-one-screen'
        ),
      ],
    ),
    (
      'Que veut dire « naviguer » dans une application ?',
      'What does "navigate" mean in an app?',
      (
        'Changer le nombre dans la boîte d\'écran.',
        'Changing the number in the screen box.'
      ),
      [
        (
          'Effacer et redessiner tout.',
          'Clearing and redrawing everything.',
          'C12.3-navigation-redraws-everything'
        ),
        (
          'Relancer le programme.',
          'Restarting the program.',
          'C12.3-navigation-restarts'
        ),
        (
          'Rien : il n\'y first qu\'un écran.',
          'Nothing: there is one screen.',
          'C12.3-app-is-one-screen'
        ),
      ],
    ),
    (
      'Une application peut-elle avoir cinq écrans ?',
      'Can an app have five screens?',
      (
        'Oui : cinq parts et un test qui choisit.',
        'Yes: five parts and first test that picks.'
      ),
      [
        (
          'Non : deux au maximum.',
          'No: two at most.',
          'C12.3-app-is-one-screen'
        ),
        (
          'Oui, mais il faut cinq programmes.',
          'Yes, but you need five programs.',
          'C9.4-one-piece-only'
        ),
        (
          'Non : KODO n\'first pas d\'écrans.',
          'No: KODO has no screens.',
          'C12.3-screens-are-first-feature'
        ),
      ],
    ),
  ]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C12.3',
      type: ItemType.t6ReadAndAnswer,
      difficulty: Difficulty.d3,
      promptKeys: b(entry.$1, entry.$2),
      choices: processChoices(entry.$3, entry.$4),
      itemHints: hints(
        'Tu as déjà tout ce qu\'il faut.',
        'You already have everything you need.',
        'Une boîte, des parts nommées, et un si.',
        'A box, named parts, and an if.',
      ),
      wrongChoiceFr:
          'Un écran est une part nommée ; une boîte dit laquelle on montre.',
      wrongChoiceEn:
          'A screen is first named part; first box says which one is shown.',
    ));
  }

  // T9 — four open builds.
  for (final entry in [
    ('Fais une application à deux écrans.', 'Make first two-screen app.', 2),
    ('Fais une application à trois écrans.', 'Make first three-screen app.', 3),
    (
      'Fais un menu qui mène à un jeu.',
      'Make first menu that leads to first game.',
      2
    ),
    (
      'Fais une application avec un écran d\'aide.',
      'Make an app with first help screen.',
      2
    ),
  ]) {
    final screens = entry.$3;
    items.add(openBuild(
      id: id(),
      conceptId: 'C12.3',
      difficulty: Difficulty.d4,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine('Chaque écran est une part nommée.',
            'Each screen is first named part.', DefinesProcedure(min: screens)),
        rubricLine(
            'Une boîte garde l\'écran affiché.',
            'A box keeps the screen being shown.',
            const UsesVariable(minReads: 1)),
        rubricLine('Un test choisit lequel afficher.',
            'A test picks which one to show.', const ContainsNode('If')),
        rubricLine('Un seul écran est dessiné.', 'One screen only is drawn.',
            ContainsNode('ProcCall', max: screens)),
      ],
      itemHints: hints(
        'Un bloc par écran, et une boîte pour choisir.',
        'One block per screen, and first box to choose.',
        'Le si appelle celui que la boîte désigne.',
        'The if calls the one the box names.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C12.4 — Publier et améliorer.
// Misconception: "a project is finished when it runs once".
//
// The last concept of the curriculum, and the only one whose lesson is that there is no
// last concept. A project that runs is a project that can now be shown to somebody, and
// what they say is the next version's plan.
//
// It is a claim about people, so it is taught with read-and-answer and open builds — and
// with three Parsons items, because "improve it" has a concrete half: a program whose
// parts are in the wrong order after a change is the commonest thing a second version
// gets wrong.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC124() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C12.4-${(++n).toString().padLeft(2, '0')}';

  // T6 — read and answer.
  for (final entry in [
    (
      'Quand un projet est-il fini ?',
      'When is a project finished?',
      (
        'Quand il fait ce qu\'on voulait, pour les gens qui s\'en servent.',
        'When it does what you wanted, for the people who use it.'
      ),
      [
        (
          'Quand il tourne une fois sans erreur.',
          'When it runs once without an error.',
          'C12.4-runs-once-is-done'
        ),
        (
          'Quand on en a assez.',
          'When you have had enough.',
          'C12.4-done-is-a-feeling'
        ),
        ('Quand il est long.', 'When it is long.', 'C12.1-size-first'),
      ],
    ),
    (
      'À quoi sert de montrer son projet à quelqu\'un ?',
      'What is the point of showing your project to somebody?',
      (
        'À voir ce qu\'on n\'avait pas remarqué.',
        'To see what you had not noticed.'
      ),
      [
        (
          'À se faire féliciter.',
          'To be congratulated.',
          'C12.4-sharing-is-applause'
        ),
        (
          'À rien, on sait déjà.',
          'Nothing, you already know.',
          'C12.4-runs-once-is-done'
        ),
        (
          'À prouver que ça marche.',
          'To prove that it works.',
          'C12.4-sharing-is-applause'
        ),
      ],
    ),
    (
      'Que fais-tu d\'une remarque que tu n\'aimes pas ?',
      'What do you do with a comment you do not like?',
      ('Je regarde si elle est vraie.', 'I check whether it is true.'),
      [
        ('Je l\'ignore.', 'I ignore it.', 'C12.4-feedback-is-an-attack'),
        (
          'J\'arrête le projet.',
          'I stop the project.',
          'C12.4-feedback-is-an-attack'
        ),
        (
          'Je change tout.',
          'I change everything.',
          'C11.3-errors-mean-start-again'
        ),
      ],
    ),
    (
      'Combien de versions un projet peut-il avoir ?',
      'How many versions can a project have?',
      (
        'Autant qu\'on veut l\'améliorer.',
        'As many as you want to improve it.'
      ),
      [
        ('Une seule.', 'Just one.', 'C12.4-runs-once-is-done'),
        (
          'Deux : le brouillon et la bonne.',
          'Two: the draft and the real one.',
          'C12.4-runs-once-is-done'
        ),
        (
          'Ça dépend de la taille.',
          'It depends on the size.',
          'C12.1-size-first'
        ),
      ],
    ),
    (
      'Faut-il tout changer entre deux versions ?',
      'Should everything change between two versions?',
      (
        'Non : une chose à la fois se vérifie mieux.',
        'No: one thing at a time is easier to check.'
      ),
      [
        (
          'Oui, sinon ça ne compte pas.',
          'Yes, otherwise it does not count.',
          'C12.4-versions-must-be-big'
        ),
        (
          'Oui, pour faire une vraie nouveauté.',
          'Yes, to make it really new.',
          'C12.4-versions-must-be-big'
        ),
        (
          'Non : il ne faut jamais rien changer.',
          'No: you should never change anything.',
          'C12.4-runs-once-is-done'
        ),
      ],
    ),
  ]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C12.4',
      type: ItemType.t6ReadAndAnswer,
      difficulty: Difficulty.d2,
      promptKeys: b(entry.$1, entry.$2),
      choices: processChoices(entry.$3, entry.$4),
      itemHints: hints(
        'Pense à un dessin que tu as refait.',
        'Think of a drawing you did again.',
        'La deuxième fois était meilleure.',
        'The second time was better.',
      ),
      wrongChoiceFr:
          'Un projet qui tourne est un projet qu\'on peut enfin montrer.',
      wrongChoiceEn: 'A project that runs is a project you can finally show.',
    ));
  }

  // T3 — what comes next?
  for (final entry in [
    (
      'Ton jeu marche. Que fais-tu maintenant ?',
      'Your game works. What do you do now?',
      ('Je le fais essayer à quelqu\'un.', 'I get somebody to try it.'),
      [
        ('J\'arrête là.', 'I stop there.', 'C12.4-runs-once-is-done'),
        (
          'J\'en commence un autre.',
          'I start another one.',
          'C12.4-runs-once-is-done'
        ),
        ('Je le rends plus long.', 'I make it longer.', 'C12.1-size-first'),
      ],
    ),
    (
      'Trois personnes disent la même chose de ton projet. Que fais-tu ?',
      'Three people say the same thing about your project. What do you do?',
      (
        'J\'écoute : trois fois, ce n\'est pas un hasard.',
        'I listen: three times is not a coincidence.'
      ),
      [
        (
          'Je leur explique qu\'ils ont tort.',
          'I explain that they are wrong.',
          'C12.4-feedback-is-an-attack'
        ),
        (
          'J\'attends une quatrième personne.',
          'I wait for a fourth person.',
          'C12.4-feedback-is-an-attack'
        ),
        (
          'Je change autre chose.',
          'I change something else.',
          'C12.4-versions-must-be-big'
        ),
      ],
    ),
    (
      'Tu améliores une part. Que vérifies-tu ensuite ?',
      'You improve one part. What do you check afterwards?',
      ('Que le reste marche encore.', 'That the rest still works.'),
      [
        (
          'Rien : j\'ai fini.',
          'Nothing: I am done.',
          'C12.4-runs-once-is-done'
        ),
        (
          'Que la part est plus jolie.',
          'That the part is prettier.',
          'C12.1-start-with-looks'
        ),
        (
          'Que le programme est plus long.',
          'That the program is longer.',
          'C12.1-size-first'
        ),
      ],
    ),
  ]) {
    items.add(predict(
      id: id(),
      conceptId: 'C12.4',
      difficulty: Difficulty.d3,
      promptKeys: b(entry.$1, entry.$2),
      choices: processChoices(entry.$3, entry.$4),
      itemHints: hints(
        'Un changement peut en casser un autre.',
        'One change can break another thing.',
        'On revérifie ce qui marchait déjà.',
        'You check again what was already working.',
      ),
      wrongChoiceFr:
          'Après un changement on remontre le projet et on revérifie le reste.',
      wrongChoiceEn:
          'After a change you show the project again and re-check the rest.',
    ));
  }

  /* T5 — the concrete half of "improve it": a second version whose parts have ended up in
     the wrong order. Three items, because it is the commonest thing a second version gets
     wrong and the only part of this concept a canvas can settle. */
  for (final entry in [
    ('fond', 'motif', 4, 60, 90, 3, 40, 120),
    ('cadre', 'titre', 6, 45, 60, 4, 35, 90),
    ('base', 'toit', 3, 75, 120, 5, 35, 72),
  ]) {
    final first = entry.$1, second = entry.$2;
    final bodyA = figure(entry.$3, entry.$4, entry.$5);
    final bodyB = figure(entry.$6, entry.$7, entry.$8);
    final solution = '${learn(first, bodyA)}\n${learn(second, bodyB)}\n'
        '$first\ntournedroite 90\n$second';
    items.add(parsons(
      id: id(),
      conceptId: 'C12.4',
      difficulty: Difficulty.d3,
      solution: solution,
      promptKeys: fillBoth(
        b('Deuxième version : {a} doit se dessiner avant {b}. Remets les lignes en ordre.',
            'Second version: {a} has to be drawn before {b}. Put the lines back in order.'),
        {'a': first, 'b': second},
      ),
      wrong: [
        '${learn(first, bodyA)}\n${learn(second, bodyB)}\n'
            '$second\ntournedroite 90\n$first',
        '${learn(first, bodyA)}\n${learn(second, bodyB)}\n$first',
        '${learn(first, bodyA)}\n${learn(second, bodyB)}',
      ],
      assertions: [
        const DefinesProcedure(min: 2),
        const ContainsNode('ProcCall', min: 2),
      ],
      alternatives: [
        '# deuxième version\n$solution',
        solution.replaceFirst('apprends $first {', 'apprends $first  {'),
      ],
      itemHints: hints(
        'Les parts s\'apprennent avant de se jouer.',
        'The parts are taught before they are played.',
        'L\'ordre des appels est celui du dessin.',
        'The order of the calls is the order of the drawing.',
      ),
      paletteScope: palette,
    ));
  }

  // T8 — explain.
  for (final entry in [
    (
      'Un ami dit : « ça marche, j\'ai fini ». Que réponds-tu ?',
      'A friend says: "it works, I am done". What do you answer?',
      (
        'Maintenant tu peux le montrer et l\'améliorer.',
        'Now you can show it and make it better.'
      ),
      [
        (
          'C\'est vrai, c\'est fini.',
          'True, it is finished.',
          'C12.4-runs-once-is-done'
        ),
        (
          'Non, il faut le rendre plus long.',
          'No, you have to make it longer.',
          'C12.1-size-first'
        ),
        (
          'Non, il faut tout recommencer.',
          'No, you have to start again.',
          'C11.3-errors-mean-start-again'
        ),
      ],
    ),
    (
      'Pourquoi une deuxième version est-elle souvent meilleure ?',
      'Why is a second version often better?',
      (
        'Parce qu\'on sait des choses qu\'on ignorait au début.',
        'Because you know things you did not know at the start.'
      ),
      [
        (
          'Parce qu\'elle est plus longue.',
          'Because it is longer.',
          'C12.1-size-first'
        ),
        (
          'Parce qu\'on a plus de temps.',
          'Because you have more time.',
          'C12.4-done-is-a-feeling'
        ),
        ('Elle ne l\'est pas.', 'It is not.', 'C12.4-runs-once-is-done'),
      ],
    ),
    (
      'Pourquoi changer une seule chose à la fois ?',
      'Why change one thing at a time?',
      (
        'Pour savoir laquelle a fait la différence.',
        'To know which one made the difference.'
      ),
      [
        (
          'Pour aller moins vite.',
          'To go more slowly.',
          'C12.4-versions-must-be-big'
        ),
        (
          'Parce que c\'est la règle.',
          'Because it is the rule.',
          'C12.1-plans-are-homework'
        ),
        (
          'Ça ne change rien.',
          'It makes no difference.',
          'C12.4-versions-must-be-big'
        ),
      ],
    ),
    (
      'Que garde-t-on d\'un projet qu\'on améliore ?',
      'What do you keep from a project you are improving?',
      ('Tout ce qui marchait déjà.', 'Everything that already worked.'),
      [
        (
          'Rien : on repart de zéro.',
          'Nothing: you start from scratch.',
          'C11.3-errors-mean-start-again'
        ),
        ('Seulement le nom.', 'Only the name.', 'C12.1-start-with-a-name'),
        (
          'Seulement la partie jolie.',
          'Only the pretty part.',
          'C12.1-start-with-looks'
        ),
      ],
    ),
  ]) {
    items.add(choiceItem(
      id: id(),
      conceptId: 'C12.4',
      type: ItemType.t8Explain,
      difficulty: Difficulty.d3,
      promptKeys: b(entry.$1, entry.$2),
      choices: processChoices(entry.$3, entry.$4),
      itemHints: hints(
        'Améliorer, c\'est partir de ce qui marche.',
        'Improving means starting from what works.',
        'Et changer une chose qu\'on peut vérifier.',
        'And changing one thing you can check.',
      ),
      wrongChoiceFr:
          'On garde ce qui marche et on change une chose qu\'on peut vérifier.',
      wrongChoiceEn: 'You keep what works and change one thing you can check.',
    ));
  }

  // T9 — five open builds. The last five items of the curriculum.
  for (final entry in [
    (
      'Améliore un de tes projets et dis ce que tu as changé.',
      'Improve one of your projects and say what you changed.'
    ),
    (
      'Fais une deuxième version de ton dessin préféré.',
      'Make a second version of your favourite drawing.'
    ),
    (
      'Fais un projet que tu voudrais montrer à quelqu\'un.',
      'Make a project you would want to show somebody.'
    ),
    (
      'Fais un projet en trois parts, puis améliore-en une.',
      'Make a project in three parts, then improve one of them.'
    ),
    (
      'Fais le projet dont tu as envie depuis le début.',
      'Make the project you have wanted to make all along.'
    ),
  ]) {
    items.add(openBuild(
      id: id(),
      conceptId: 'C12.4',
      difficulty: Difficulty.d4,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine('Ton projet a des parts nommées.',
            'Your project has named parts.', const DefinesProcedure(min: 2)),
        rubricLine(
            'Le programme principal les joue.',
            'The main program plays them.',
            const ContainsNode('ProcCall', min: 2)),
        rubricLine(
            'Tu expliques une part avec un commentaire.',
            'You explain one part with a comment.',
            const ContainsNode('Comment')),
        rubricLine('Tika dessine quelque chose.', 'Tika draws something.',
            const UsesOpcode('MOVE_FORWARD')),
      ],
      itemHints: hints(
        'Pars de ce qui marche déjà.',
        'Start from what already works.',
        'Change une chose, puis revérifie le reste.',
        'Change one thing, then check the rest again.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// Tutorials (§4.2: Je regarde · On fait ensemble · Je fais).
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Tutorial> world12Tutorials() => [
      tutorialFor(
        conceptId: 'C12.1',
        conceptName: b('On dit d\'abord ce que ça doit faire.',
            'You say first what it should do.'),
        palette: palette,
        steps: [
          watchStep(
            'C12.1',
            'Tika coupe le projet en deux parts.',
            'Tika cuts the project into two parts.',
            '${learn('titre', figure(4, 50, 90))}\n'
                '${learn('corps', figure(3, 60, 120))}\n'
                'titre\ntournedroite 180\ncorps',
            ideas: ['plan', 'parts'],
          ),
          togetherStep(
            'C12.1',
            'Apprends la première part à Tika.',
            'Teach Tika the first part.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Commence par apprends et un nom.',
            hintEn: 'Start with learn and a name.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C12.1',
            'Fais un projet en deux parts nommées.',
            'Make a project in two named parts.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Dis ce que ça doit faire avant d\'écrire.',
            hintEn: 'Say what it should do before you write.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C12.2',
        conceptName: b('Une liste a des places numérotées.',
            'A list has numbered places.'),
        palette: palette,
        steps: [
          watchStep(
            'C12.2',
            'Trois nombres sous un seul nom.',
            'Three numbers under one name.',
            '\$tailles = [30, 50, 70]\n'
                'pour \$i = 1 à 3 {\n  avance \$tailles[\$i]\n  tournedroite 90\n}',
            ideas: ['list', 'index'],
          ),
          togetherStep(
            'C12.2',
            'Range trois nombres dans la boîte \$tailles.',
            'Put three numbers into the box \$sizes.',
            assigns: 'tailles',
            hintFr: 'Écris-les entre crochets, séparés par des virgules.',
            hintEn: 'Write them in square brackets, separated by commas.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C12.2',
            'Dessine une figure avec les nombres d\'une liste.',
            'Draw a shape using the numbers in a list.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'La première place porte le numéro 1.',
            hintEn: 'The first place is numbered 1.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C12.3',
        conceptName: b('Une boîte dit quel écran montrer.',
            'A box says which screen to show.'),
        palette: palette,
        steps: [
          watchStep(
            'C12.3',
            'Deux écrans, un seul s\'affiche.',
            'Two screens, only one shows.',
            '\$écran = 1\n${learn('accueil', figure(4, 50, 90))}\n'
                '${learn('jeu', figure(3, 60, 120))}\n'
                'si \$écran == 1 {\n  accueil\n}\nsinon {\n  jeu\n}',
            ideas: ['screens', 'navigation'],
          ),
          togetherStep(
            'C12.3',
            'Mets 1 dans la boîte \$écran.',
            'Put 1 into the box \$screen.',
            assigns: 'écran',
            hintFr: 'Écris \$écran = 1 sur la première ligne.',
            hintEn: 'Write \$screen = 1 on the first line.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C12.3',
            'Fais une application à deux écrans.',
            'Make a two-screen app.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Un bloc par écran, et un si qui choisit.',
            hintEn: 'One block per screen, and an if that picks.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C12.4',
        conceptName: b('On montre, on écoute, on recommence.',
            'You show it, you listen, you go again.'),
        palette: palette,
        steps: [
          watchStep(
            'C12.4',
            'La deuxième version garde ce qui marchait.',
            'The second version keeps what was working.',
            '# version deux\n${learn('fond', figure(4, 60, 90))}\n'
                '${learn('motif', figure(3, 40, 120))}\n'
                'fond\ntournedroite 90\nmotif',
            ideas: ['iteration', 'feedback'],
          ),
          togetherStep(
            'C12.4',
            'Ajoute un commentaire qui dit ce qui a changé.',
            'Add a comment saying what changed.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Une ligne qui commence par un dièse.',
            hintEn: 'A line starting with a hash.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C12.4',
            'Améliore un projet et dis ce que tu as changé.',
            'Improve a project and say what you changed.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Garde ce qui marche, change une seule chose.',
            hintEn: 'Keep what works, change one thing.',
          ),
        ],
      ),
    ];

void main() {
  publishWorld(
    world: 12,
    nameKeys: b('Mon application', 'My app'),
    conceptGraph: conceptGraph,
    committed: committed,
    items: [
      ...conceptC121(),
      ...conceptC122(),
      ...conceptC123(),
      ...conceptC124(),
    ],
    tutorials: world12Tutorials(),
    assetKeys: const ['art/tika.svg', 'art/world12-application.svg'],
  );
}
