// Authors World 7 — "Si… sinon" — and writes it out as a content pack.
//
//     dart tool/author_world7.dart
//
// World 6 gave the child a box. World 7 gives the box a second kind of thing to hold: a
// yes or a no. The five misconceptions in the ledger are all versions of one confusion,
// that a test is a sentence about the world rather than a value the program computes:
//
//   C7.1  "true/false are just words"
//   C7.2  "the single = and the double == are the same"
//   C7.3  "the if block runs every time"
//   C7.4  "else runs as well as if"
//   C7.5  "or means both must be true"
//
// Two authoring rules run through the world, and both come from the grader rather than
// from taste.
//
// **A true condition is invisible.** `si $x > 3 { avance 50 }` with `$x = 5` draws exactly
// what `avance 50` draws, so the child who deleted the test passes on the picture. Every
// item whose point is the test therefore carries `ContainsNode('If')`, and the "no test at
// all" distractor is there to prove the assertion fires. This is the same finding World 5
// made about triggers and World 6 made about boxes, for the third time — which is why it
// is now checked for every world by the acceptance suite rather than remembered.
//
// **The false branch is where the learning is.** An item whose condition is always true
// teaches nothing about `si`: it is a straight line with extra words. So the parameter
// sets below always carry both — one value that takes the branch and one that does not.

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';

import 'authoring.dart';

const conceptGraph = <String, List<String>>{
  'C7.1': ['C6.2'],
  'C7.2': ['C7.1'],
  'C7.3': ['C7.2'],
  'C7.4': ['C7.3'],
  'C7.5': ['C7.2'],
};

/// §6.3's commitment, copied from `spec/concepts.json` and checked against it by
/// `publishWorld`.
const committed = <String, int>{
  'C7.1': 22,
  'C7.2': 24,
  'C7.3': 24,
  'C7.4': 22,
  'C7.5': 22,
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
];

/// The two alternatives an item that only prints needs.
///
/// `equivalentsOf` rewrites `avance` and `tourne` lines, so a program with neither gets
/// one alternative out of it and the gate's "at least two" rule fails. Both of these are
/// real rewrites that change the text and not the tree, which is the claim `FR-M6-02`
/// makes about the grader.
List<String> printedAlternatives(String solution) => [
      '# une autre façon d\'écrire la même chose\n$solution',
      solution.replaceFirst('\n', '\n\n'),
    ];

/// `si <test> { <then> }`, written the way a child writes it.
String ifThen(String test, String then) =>
    'si $test {\n${then.split('\n').map((l) => '  $l').join('\n')}\n}';

/// `si <test> { <then> } sinon { <otherwise> }`.
String ifElse(String test, String then, String otherwise) =>
    '${ifThen(test, then)}\nsinon {\n'
    '${otherwise.split('\n').map((l) => '  $l').join('\n')}\n}';

/// A closed figure, for the branch bodies. Two lines, so it reads as one thing.
String figure(int sides, int side, int turn) =>
    'répète $sides {\n  avance $side\n  tournedroite $turn\n}';

// ═══════════════════════════════════════════════════════════════════════════════════════
// C7.1 — Vrai / faux.
// Misconception: "true/false are just words".
//
// The refutation is the box from World 6: `$ok = vrai` puts a yes into a box exactly the
// way `$côté = 60` puts a number in, and `si $ok` spends it. A word cannot be put in a
// box and spent. Half the items here are deliberately the *same shape* as a World 6 item
// with a yes where the number was, because that is the argument.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC71() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C7.1-${(++n).toString().padLeft(2, '0')}';

  Choice yes({bool correct = false, String? misconception}) => Choice(
      labelKeys: b('vrai', 'true'),
      correct: correct,
      misconception: misconception);
  Choice no({bool correct = false, String? misconception}) => Choice(
      labelKeys: b('faux', 'false'),
      correct: correct,
      misconception: misconception);

  // T3 — what does the program print? A yes and a no are values, so they print.
  for (final entry in [
    (
      r'$ok = vrai' '\n' r'écris $ok',
      true,
      ('le mot « ok »', 'the word "ok"'),
      'C7.1-box-holds-its-name',
      ('1', '1'),
      'C7.1-yes-is-a-number'
    ),
    (
      r'$ok = 3 > 1' '\n' r'écris $ok',
      true,
      ('3 > 1', '3 > 1'),
      'C7.1-test-is-just-words',
      ('3', '3'),
      'C7.1-test-keeps-its-numbers'
    ),
    (
      r'$ok = faux' '\n' r'$ok = vrai' '\n' r'écris $ok',
      true,
      ('vrai et faux', 'true and false'),
      'C6.1-box-holds-history',
      ('rien', 'nothing'),
      'C7.1-yes-cancels-no'
    ),
    (
      r'écris 2 > 5',
      false,
      ('2', '2'),
      'C7.1-test-keeps-its-numbers',
      ('2 > 5', '2 > 5'),
      'C7.1-test-is-just-words'
    ),
    (
      r'$a = 4' '\n' r'$b = 4' '\n' r'écris $a == $b',
      true,
      ('4', '4'),
      'C7.1-test-keeps-its-numbers',
      ('8', '8'),
      'C7.1-equality-adds-up'
    ),
    (
      r'$a = vrai' '\n' r'$b = faux' '\n' r'écris $b',
      false,
      ('les deux', 'both of them'),
      'C6.1-box-holds-history',
      ('rien', 'nothing'),
      'C7.1-no-is-nothing'
    ),
  ]) {
    final source = entry.$1, answer = entry.$2;
    items.add(predict(
      id: id(),
      conceptId: 'C7.1',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Que va écrire Tika ?\n\n{p}', 'What will Tika print?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        if (answer) yes(correct: true) else no(correct: true),
        if (answer)
          no(misconception: 'C7.1-yes-and-no-are-the-same')
        else
          yes(misconception: 'C7.1-yes-and-no-are-the-same'),
        Choice(
            labelKeys: b(entry.$3.$1, entry.$3.$2),
            correct: false,
            misconception: entry.$4),
        Choice(
            labelKeys: b(entry.$5.$1, entry.$5.$2),
            correct: false,
            misconception: entry.$6),
      ],
      itemHints: hints(
        'Un oui ou un non est une valeur, comme un nombre.',
        'A yes or a no is a value, like a number.',
        'Tika l\'écrit comme elle écrirait 7.',
        'Tika prints it the way she would print 7.',
      ),
      wrongChoiceFr:
          'vrai et faux sont deux valeurs : on les range et on les écrit.',
      wrongChoiceEn:
          'true and false are two values: you store them and you print them.',
    ));
  }

  /* T4 — the hole is the yes. The same shape as World 6's "fill the box" item, with a
     yes where the number was, which is the whole argument of the concept. */
  for (final entry in [
    (4, 60, 90),
    (3, 80, 120),
    (6, 45, 60),
    (5, 55, 72),
    (4, 70, 90),
  ]) {
    final sides = entry.$1, side = entry.$2, turn = entry.$3;
    final body = figure(sides, side, turn);
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C7.1',
      difficulty: Difficulty.d2,
      withHoles: '\$ok = ___\n${ifThen('\$ok', body)}',
      solution: '\$ok = vrai\n${ifThen('\$ok', body)}',
      promptKeys: fillBoth(
        b('Complète pour que la figure à {k} côtés soit dessinée.',
            'Fill in the blank so the {k}-sided shape gets drawn.'),
        {'k': sides},
      ),
      wrong: [
        '\$ok = faux\n${ifThen('\$ok', body)}',
        '\$ok = 2 > 9\n${ifThen('\$ok', body)}',
        '\$ok = non vrai\n${ifThen('\$ok', body)}',
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'ok', minReads: 1),
      ],
      itemHints: hints(
        'La boîte garde un oui ou un non.',
        'The box keeps a yes or a no.',
        'Pour dessiner, il faut un oui.',
        'To draw, it has to be a yes.',
      ),
      paletteScope: palette,
    ));
  }

  /* T2 — three bugs, all of them a no where a yes belonged. The distractor that draws the
     right figure with the test deleted is in every list: without the assertion it would
     pass, and an item World 7 can pass without a test is not a World 7 item. */
  for (final entry in [
    (4, 60, 90, 'faux', '2 > 9'),
    (6, 50, 60, 'non vrai', '1 == 2'),
    (3, 90, 120, '5 < 1', 'faux'),
  ]) {
    final sides = entry.$1, side = entry.$2, turn = entry.$3;
    final body = figure(sides, side, turn);
    final brokenTest = entry.$4, otherFalse = entry.$5;
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C7.1',
      difficulty: Difficulty.d2,
      broken: '\$ok = $brokenTest\n${ifThen('\$ok', body)}',
      solution: '\$ok = vrai\n${ifThen('\$ok', body)}',
      promptKeys: b('Rien ne se dessine. Mets un oui dans la boîte.',
          'Nothing is drawn. Put a yes into the box.'),
      wrong: [
        // The figure, with the test thrown away. Right picture, no test.
        body,
        '\$ok = $otherFalse\n${ifThen('\$ok', body)}',
        '\$ok = vrai\n${ifThen('non \$ok', body)}',
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'ok', minReads: 1),
      ],
      alternatives: [
        '# un oui dans la boîte\n\$ok = vrai\n${ifThen('\$ok', body)}',
        '\$ok = 1 < 2\n${ifThen('\$ok', body)}',
      ],
      itemHints: hints(
        'Regarde ce qu\'il y a dans la boîte.',
        'Look at what is in the box.',
        'C\'est un non. Il faut un oui.',
        'It is a no. It needs a yes.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d1,
    promptKeys: b('Combien de réponses vrai ou faux existe-t-il ?',
        'How many true-or-false answers are there?'),
    choices: [
      Choice(labelKeys: b('Deux.', 'Two.'), correct: true),
      Choice(
          labelKeys: b('Une seule.', 'Only one.'),
          correct: false,
          misconception: 'C7.1-only-yes-exists'),
      Choice(
          labelKeys: b('Autant qu\'on veut.', 'As many as you like.'),
          correct: false,
          misconception: 'C7.1-test-is-just-words'),
      Choice(
          labelKeys: b('Aucune : ce sont des mots.', 'None: they are words.'),
          correct: false,
          misconception: 'C7.1-test-is-just-words'),
    ],
    itemHints: hints(
      'Pense à une question à laquelle on répond oui ou non.',
      'Think of a question you answer yes or no to.',
      'Il n\'y a pas de troisième réponse.',
      'There is no third answer.',
    ),
    wrongChoiceFr: 'Un test rend toujours l\'un des deux : vrai ou faux.',
    wrongChoiceEn: 'A test always gives back one of the two: true or false.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(r'Que peut-on mettre dans une boîte ?',
        r'What can you put into a box?'),
    choices: [
      Choice(
          labelKeys: b('Un nombre, ou un vrai, ou un faux.',
              'A number, or a true, or a false.'),
          correct: true),
      Choice(
          labelKeys: b('Seulement des nombres.', 'Only numbers.'),
          correct: false,
          misconception: 'C7.1-boxes-hold-numbers-only'),
      Choice(
          labelKeys: b('Des instructions.', 'Instructions.'),
          correct: false,
          misconception: 'C6.1-box-holds-the-program'),
      Choice(
          labelKeys: b('Des dessins.', 'Drawings.'),
          correct: false,
          misconception: 'C6.1-box-holds-the-drawing'),
    ],
    itemHints: hints(
      'Tu as déjà rangé des nombres.',
      'You have already stored numbers.',
      'Un oui se range pareil.',
      'A yes is stored the same way.',
    ),
    wrongChoiceFr:
        'Une boîte garde une valeur : un nombre, un vrai ou un faux.',
    wrongChoiceEn: 'A box keeps a value: a number, a true or a false.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(r'Que vaut 7 > 2 ?', r'What is 7 > 2 worth?'),
    choices: [
      yes(correct: true),
      no(misconception: 'C7.1-yes-and-no-are-the-same'),
      Choice(
          labelKeys: b('5', '5'),
          correct: false,
          misconception: 'C7.1-test-keeps-its-numbers'),
      Choice(
          labelKeys: b('7 et 2', '7 and 2'),
          correct: false,
          misconception: 'C7.1-test-keeps-its-numbers'),
    ],
    itemHints: hints(
      'Pose-toi la question : sept est-il plus grand que deux ?',
      'Ask yourself: is seven bigger than two?',
      'La réponse est oui.',
      'The answer is yes.',
    ),
    wrongChoiceFr: 'Un test rend un oui ou un non, pas les nombres testés.',
    wrongChoiceEn: 'A test gives a yes or a no, not the numbers it tested.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(r'$ok = 4 > 9. Que garde la boîte ?',
        r'$ok = 4 > 9. What does the box keep?'),
    choices: [
      no(correct: true),
      yes(misconception: 'C7.1-yes-and-no-are-the-same'),
      Choice(
          labelKeys: b('le test 4 > 9', 'the test 4 > 9'),
          correct: false,
          misconception: 'C7.1-box-holds-the-test'),
      Choice(
          labelKeys: b('4', '4'),
          correct: false,
          misconception: 'C7.1-test-keeps-its-numbers'),
    ],
    itemHints: hints(
      'Tika calcule d\'abord la droite du =.',
      'Tika works out the right of the = first.',
      'Quatre n\'est pas plus grand que neuf.',
      'Four is not bigger than nine.',
    ),
    wrongChoiceFr: 'Le test est calculé, et c\'est sa réponse qui est rangée.',
    wrongChoiceEn:
        'The test is worked out, and it is its answer that is stored.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(r'Que fait si $ok { … } quand $ok garde un faux ?',
        r'What does if $ok { … } do when $ok keeps a false?'),
    choices: [
      Choice(
          labelKeys:
              b('Elle saute ce qu\'il y a dedans.', 'It skips what is inside.'),
          correct: true),
      Choice(
          labelKeys: b('Elle fait quand même ce qu\'il y a dedans.',
              'It does what is inside anyway.'),
          correct: false,
          misconception: 'C7.3-if-always-runs'),
      Choice(
          labelKeys: b('Elle arrête le programme.', 'It stops the program.'),
          correct: false,
          misconception: 'C7.3-false-stops-everything'),
      Choice(
          labelKeys: b('Elle efface le dessin.', 'It clears the drawing.'),
          correct: false,
          misconception: 'C7.3-false-clears'),
    ],
    itemHints: hints(
      'Un non veut dire « pas cette fois ».',
      'A no means "not this time".',
      'Tika continue après l\'accolade.',
      'Tika carries on after the bracket.',
    ),
    wrongChoiceFr:
        'Sur un faux Tika saute le bloc et continue la ligne d\'après.',
    wrongChoiceEn:
        'On a false Tika skips the block and carries on with the next line.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.1',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Un ami dit : « vrai et faux, ce sont juste des mots ». Que réponds-tu ?',
      'A friend says: "true and false are just words". What do you answer?',
    ),
    choices: [
      Choice(
          labelKeys: b('Ce sont des valeurs : on les range dans une boîte.',
              'They are values: you can put them in a box.'),
          correct: true),
      Choice(
          labelKeys: b('C\'est vrai, Tika ne les lit pas.',
              'True, Tika does not read them.'),
          correct: false,
          misconception: 'C7.1-test-is-just-words'),
      Choice(
          labelKeys: b(
              'Ce sont des nombres déguisés.', 'They are numbers in disguise.'),
          correct: false,
          misconception: 'C7.1-yes-is-a-number'),
      Choice(
          labelKeys: b('Ce sont des noms de boîtes.', 'They are box names.'),
          correct: false,
          misconception: 'C6.1-box-holds-its-name'),
    ],
    itemHints: hints(
      'Essaie de ranger le mot « bonjour » dans un si.',
      'Try putting the word "hello" into an if.',
      'Un oui se range et se dépense comme un nombre.',
      'A yes is stored and spent like a number.',
    ),
    wrongChoiceFr:
        'On range un vrai comme un nombre, et un si sait le dépenser.',
    wrongChoiceEn:
        'A true is stored like a number, and an if knows how to spend it.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.1',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi ranger un test dans une boîte plutôt que de le réécrire ?',
      'Why put a test into a box instead of writing it out again?',
    ),
    choices: [
      Choice(
          labelKeys: b('Pour le réutiliser sans le recalculer.',
              'To reuse it without working it out again.'),
          correct: true),
      Choice(
          labelKeys: b('Parce qu\'un si a besoin d\'une boîte.',
              'Because an if needs a box.'),
          correct: false,
          misconception: 'C7.1-if-needs-a-box'),
      Choice(
          labelKeys:
              b('Pour que le test soit plus vrai.', 'To make the test truer.'),
          correct: false,
          misconception: 'C7.1-box-changes-the-answer'),
      Choice(
          labelKeys: b('Ça ne sert à rien.', 'It serves no purpose.'),
          correct: false,
          misconception: 'C7.1-test-is-just-words'),
    ],
    itemHints: hints(
      'Un test peut servir à deux endroits.',
      'A test can be useful in two places.',
      'La boîte garde sa réponse.',
      'The box keeps its answer.',
    ),
    wrongChoiceFr:
        'La boîte garde la réponse du test pour toutes les lignes suivantes.',
    wrongChoiceEn:
        'The box keeps the test\'s answer for every line that follows.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.1',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      r'Pourquoi $ok = 3 > 1 ne range-t-il pas « 3 > 1 » dans la boîte ?',
      r'Why does $ok = 3 > 1 not store "3 > 1" in the box?',
    ),
    choices: [
      Choice(
          labelKeys: b('Parce que Tika calcule la droite avant de ranger.',
              'Because Tika works the right side out before storing.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que les tests sont interdits dans les boîtes.',
              'Because tests are not allowed in boxes.'),
          correct: false,
          misconception: 'C7.1-boxes-hold-numbers-only'),
      Choice(
          labelKeys: b('Parce que 3 et 1 sont trop petits.',
              'Because 3 and 1 are too small.'),
          correct: false,
          misconception: 'C7.1-test-keeps-its-numbers'),
      Choice(
          labelKeys: b('Mais si, c\'est ce qu\'elle range.',
              'It does: that is what it stores.'),
          correct: false,
          misconception: 'C7.1-box-holds-the-test'),
    ],
    itemHints: hints(
      'C\'est la même règle qu\'avec les nombres.',
      'It is the same rule as with numbers.',
      'La droite est calculée, puis rangée.',
      'The right side is worked out, then stored.',
    ),
    wrongChoiceFr:
        'Le = range toujours une réponse, jamais le calcul qui l\'a donnée.',
    wrongChoiceEn: 'The = always stores an answer, never the sum that gave it.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C7.2 — Comparer.
// Misconception: "the single = and the double == are the same".
//
// KODO answers this one at the door: `si $x = 5` does not parse, and the child is told so
// in their own language rather than shipped a program that quietly assigns. That has a
// consequence for the items — a wrong answer has to *parse* to be gradable, so the single
// `=` cannot appear as a distractor program. It appears instead where it belongs, in the
// read-and-answer items, as the thing Tika refuses to understand.
//
// The comparison items lean on something the language gives for free: `>=` and `<=` and
// `==` overlap. `$x = 5` makes `>= 5` and `<= 5` and `== 5` all true, so an item can have
// two *real* alternative right answers rather than a reworded one.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC72() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C7.2-${(++n).toString().padLeft(2, '0')}';

  Choice yes({bool correct = false, String? misconception}) => Choice(
      labelKeys: b('vrai', 'true'),
      correct: correct,
      misconception: misconception);
  Choice no({bool correct = false, String? misconception}) => Choice(
      labelKeys: b('faux', 'false'),
      correct: correct,
      misconception: misconception);

  // T3 — six comparisons, chosen so the edges are where the mistakes live.
  for (final entry in [
    (r'écris 5 >= 5', true, 'C7.2-strict-and-loose-are-the-same'),
    (r'écris 5 != 5', false, 'C7.2-not-equal-means-equal'),
    (r'écris 4 < 4', false, 'C7.2-strict-and-loose-are-the-same'),
    (r'$x = 3' '\n' r'écris $x == 3', true, 'C7.2-double-equals-assigns'),
    (
      r'$a = 7' '\n' r'$b = 2' '\n' r'écris $a <= $b',
      false,
      'C7.2-comparison-reads-backwards'
    ),
    (r'$a = 6' '\n' r'écris $a != 6', false, 'C7.2-not-equal-means-equal'),
  ]) {
    final source = entry.$1, answer = entry.$2, slip = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C7.2',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Que va écrire Tika ?\n\n{p}', 'What will Tika print?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        if (answer) yes(correct: true) else no(correct: true),
        if (answer) no(misconception: slip) else yes(misconception: slip),
        Choice(
            labelKeys: b('le test lui-même', 'the test itself'),
            correct: false,
            misconception: 'C7.1-box-holds-the-test'),
        Choice(
            labelKeys: b('rien', 'nothing'),
            correct: false,
            misconception: 'C7.2-comparison-prints-nothing'),
      ],
      itemHints: hints(
        'Lis le test comme une question.',
        'Read the test like a question.',
        'La réponse est un oui ou un non.',
        'The answer is a yes or a no.',
      ),
      wrongChoiceFr: 'Un test compare deux nombres et rend vrai ou faux.',
      wrongChoiceEn:
          'A test compares two numbers and gives back true or false.',
    ));
  }

  /* T2 — five bugs, all of them the wrong comparison. The edge cases are deliberate:
     `>` against `>=` at the exact boundary is the mistake a child makes once and then
     never forgets, because nothing at all gets drawn. */
  for (final entry in [
    (5, '> 5', '>= 5', '< 5', '== 6', 4, 60, 90),
    (3, '< 3', '<= 3', '> 3', '!= 3', 6, 45, 60),
    (2, '> 5', '< 5', '>= 5', '== 5', 3, 85, 120),
    (4, '!= 4', '== 4', '> 4', '< 4', 5, 55, 72),
    (9, '< 3', '> 3', '<= 3', '== 3', 4, 65, 90),
  ]) {
    final value = entry.$1,
        brokenTest = entry.$2,
        goodTest = entry.$3,
        wrong1 = entry.$4,
        wrong2 = entry.$5;
    final body = figure(entry.$6, entry.$7, entry.$8);
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C7.2',
      difficulty: Difficulty.d3,
      broken: '\$x = $value\n${ifThen('\$x $brokenTest', body)}',
      solution: '\$x = $value\n${ifThen('\$x $goodTest', body)}',
      promptKeys: fillBoth(
        b('La boîte garde {v} et rien ne se dessine. Corrige le test.',
            'The box holds {v} and nothing is drawn. Fix the test.'),
        {'v': value},
      ),
      wrong: [
        // The figure with the test deleted: right picture, no test.
        body,
        '\$x = $value\n${ifThen('\$x $wrong1', body)}',
        '\$x = $value\n${ifThen('\$x $wrong2', body)}',
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'x', minReads: 1),
      ],
      alternatives: [
        '# le même test autrement\n\$x = $value\n'
            '${ifThen('\$x $goodTest', body)}',
        '\$x = $value\n${ifThen('non (non (\$x $goodTest))', body)}',
      ],
      itemHints: hints(
        'Le test doit être vrai pour ce nombre-là.',
        'The test has to be true for that number.',
        'Essaie le test à la main avec $value.',
        'Try the test by hand with $value.',
      ),
      paletteScope: palette,
    ));
  }

  /* T4 — the hole is the comparison sign. Every set has two right answers that are not
     rewordings: at 5, both `>= 5` and `<= 5` are true, and so is `== 5`. */
  for (final entry in [
    (5, 5, '>=', ['<=', '=='], ['>', '<', '!='], 4, 60, 90),
    (7, 5, '>', ['>=', '!='], ['<', '<=', '=='], 3, 80, 120),
    (2, 5, '<', ['<=', '!='], ['>', '>=', '=='], 6, 45, 60),
    (4, 4, '==', ['>=', '<='], ['>', '<', '!='], 5, 55, 72),
    (9, 3, '!=', ['>', '>='], ['<', '<=', '=='], 4, 70, 90),
  ]) {
    final value = entry.$1,
        against = entry.$2,
        op = entry.$3,
        alsoRight = entry.$4,
        alsoWrong = entry.$5;
    final body = figure(entry.$6, entry.$7, entry.$8);
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C7.2',
      difficulty: Difficulty.d3,
      withHoles: '\$x = $value\n${ifThen('\$x ___ $against', body)}',
      solution: '\$x = $value\n${ifThen('\$x $op $against', body)}',
      promptKeys: fillBoth(
        b('La boîte garde {v}. Quel signe fait dessiner la figure ?',
            'The box holds {v}. Which sign makes the shape get drawn?'),
        {'v': value},
      ),
      wrong: [
        for (final bad in alsoWrong)
          '\$x = $value\n${ifThen('\$x $bad $against', body)}',
      ],
      alternatives: [
        for (final good in alsoRight)
          '\$x = $value\n${ifThen('\$x $good $against', body)}',
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'x', minReads: 1),
      ],
      itemHints: hints(
        'Essaie chaque signe avec $value et $against.',
        'Try each sign with $value and $against.',
        'Le bon signe rend vrai.',
        'The right sign gives true.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer, and here is where the single = lives.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(r'Que se passe-t-il si tu écris si $x = 5 { … } ?',
        r'What happens if you write if $x = 5 { … }?'),
    choices: [
      Choice(
          labelKeys: b('Tika ne comprend pas la ligne et le dit.',
              'Tika does not understand the line and says so.'),
          correct: true),
      Choice(
          labelKeys: b('C\'est pareil que ==.', 'It is the same as ==.'),
          correct: false,
          misconception: 'C7.2-single-equals-compares'),
      Choice(
          labelKeys: b('Ça range 5 dans \$x puis teste.',
              'It puts 5 into \$x and then tests.'),
          correct: false,
          misconception: 'C7.2-single-equals-compares'),
      Choice(
          labelKeys: b('Ça teste toujours faux.', 'It always tests false.'),
          correct: false,
          misconception: 'C7.2-single-equals-compares'),
    ],
    itemHints: hints(
      'Un seul = sert à ranger.',
      'One = is for putting in.',
      'Un test a besoin des deux ==.',
      'A test needs the two ==.',
    ),
    wrongChoiceFr:
        'Un seul = range ; pour comparer il en faut deux, et Tika le signale.',
    wrongChoiceEn: 'One = puts in; comparing needs two, and Tika says so.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Quelle est la différence entre = et == ?',
        'What is the difference between = and ==?'),
    choices: [
      Choice(
          labelKeys: b('= range un nombre, == pose une question.',
              '= puts a number in, == asks a question.'),
          correct: true),
      Choice(
          labelKeys: b('Aucune : c\'est la même chose.',
              'None: they are the same thing.'),
          correct: false,
          misconception: 'C7.2-single-equals-compares'),
      Choice(
          labelKeys: b(
              '== est la version rapide de =.', '== is the fast version of =.'),
          correct: false,
          misconception: 'C7.2-single-equals-compares'),
      Choice(
          labelKeys: b('== range deux nombres à la fois.',
              '== puts two numbers in at once.'),
          correct: false,
          misconception: 'C7.2-double-equals-assigns'),
    ],
    itemHints: hints(
      'L\'un sert à remplir une boîte.',
      'One of them fills a box.',
      'L\'autre rend un oui ou un non.',
      'The other gives back a yes or a no.',
    ),
    wrongChoiceFr: '= remplit une boîte ; == rend vrai ou faux.',
    wrongChoiceEn: '= fills a box; == gives back true or false.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(r'Quand 5 >= 5 est-il vrai ?', r'When is 5 >= 5 true?'),
    choices: [
      Choice(
          labelKeys: b(
              'Toujours : cinq est égal à cinq.', 'Always: five equals five.'),
          correct: true),
      Choice(
          labelKeys: b('Jamais : il faut être plus grand.',
              'Never: it has to be bigger.'),
          correct: false,
          misconception: 'C7.2-strict-and-loose-are-the-same'),
      Choice(
          labelKeys: b('Seulement la première fois.', 'Only the first time.'),
          correct: false,
          misconception: 'C7.2-comparison-wears-out'),
      Choice(
          labelKeys: b('Ça dépend de la boîte.', 'It depends on the box.'),
          correct: false,
          misconception: 'C7.2-comparison-reads-backwards'),
    ],
    itemHints: hints(
      'Le signe se lit « plus grand ou égal ».',
      'The sign reads "bigger than or equal to".',
      'Égal suffit.',
      'Equal is enough.',
    ),
    wrongChoiceFr: '>= accepte aussi le cas où les deux nombres sont égaux.',
    wrongChoiceEn: '>= also accepts the case where both numbers are equal.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(r'Comment se lit $a != $b ?', r'How do you read $a != $b?'),
    choices: [
      Choice(
          labelKeys:
              b('\$a est différent de \$b.', '\$a is different from \$b.'),
          correct: true),
      Choice(
          labelKeys: b('\$a est égal à \$b.', '\$a equals \$b.'),
          correct: false,
          misconception: 'C7.2-not-equal-means-equal'),
      Choice(
          labelKeys:
              b('\$a est plus petit que \$b.', '\$a is smaller than \$b.'),
          correct: false,
          misconception: 'C7.2-comparison-reads-backwards'),
      Choice(
          labelKeys: b('\$a n\'existe pas.', '\$a does not exist.'),
          correct: false,
          misconception: 'C6.1-box-is-empty'),
    ],
    itemHints: hints(
      'Le point d\'exclamation veut dire « pas ».',
      'The exclamation mark means "not".',
      'Donc : pas égal.',
      'So: not equal.',
    ),
    wrongChoiceFr: 'Le ! renverse le test : != veut dire « pas égal ».',
    wrongChoiceEn: 'The ! flips the test: != means "not equal".',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(r'$a = 3 et $b = 3. Lequel de ces tests est faux ?',
        r'$a = 3 and $b = 3. Which of these tests is false?'),
    choices: [
      Choice(labelKeys: b(r'$a > $b', r'$a > $b'), correct: true),
      Choice(
          labelKeys: b(r'$a >= $b', r'$a >= $b'),
          correct: false,
          misconception: 'C7.2-strict-and-loose-are-the-same'),
      Choice(
          labelKeys: b(r'$a == $b', r'$a == $b'),
          correct: false,
          misconception: 'C7.2-double-equals-assigns'),
      Choice(
          labelKeys: b(r'$a <= $b', r'$a <= $b'),
          correct: false,
          misconception: 'C7.2-strict-and-loose-are-the-same'),
    ],
    itemHints: hints(
      'Les deux boîtes gardent le même nombre.',
      'Both boxes keep the same number.',
      'Trois n\'est pas plus grand que trois.',
      'Three is not bigger than three.',
    ),
    wrongChoiceFr:
        'À nombres égaux seul le signe strict échoue : > demande plus grand.',
    wrongChoiceEn:
        'With equal numbers only the strict sign fails: > wants bigger.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi deux signes = pour comparer et un seul pour ranger ?',
      'Why two = signs to compare and only one to put in?',
    ),
    choices: [
      Choice(
          labelKeys: b('Pour que Tika sache lequel des deux tu veux.',
              'So Tika knows which of the two you mean.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que comparer prend plus de temps.',
              'Because comparing takes longer.'),
          correct: false,
          misconception: 'C6.1-box-is-speed'),
      Choice(
          labelKeys: b(
              'Parce que deux, c\'est plus joli.', 'Because two looks nicer.'),
          correct: false,
          misconception: 'C7.2-single-equals-compares'),
      Choice(
          labelKeys: b('Il n\'y a pas de raison.', 'There is no reason.'),
          correct: false,
          misconception: 'C7.2-single-equals-compares'),
    ],
    itemHints: hints(
      'Ranger et comparer sont deux gestes différents.',
      'Putting in and comparing are two different actions.',
      'Un signe pour chacun évite de se tromper.',
      'One sign each means no mixing them up.',
    ),
    wrongChoiceFr: 'Deux gestes différents veulent deux signes différents.',
    wrongChoiceEn: 'Two different actions want two different signs.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi ton carré ne se dessine pas avec si \$x > 5 quand \$x garde 5 ?',
      'Why does your square not get drawn with if \$x > 5 when \$x holds 5?',
    ),
    choices: [
      Choice(
          labelKeys: b('Parce que 5 n\'est pas plus grand que 5.',
              'Because 5 is not bigger than 5.'),
          correct: true),
      Choice(
          labelKeys:
              b('Parce que le si est cassé.', 'Because the if is broken.'),
          correct: false,
          misconception: 'C7.3-if-is-unreliable'),
      Choice(
          labelKeys:
              b('Parce que la boîte est vide.', 'Because the box is empty.'),
          correct: false,
          misconception: 'C6.1-box-is-empty'),
      Choice(
          labelKeys: b('Parce qu\'il faut toujours un sinon.',
              'Because you always need an else.'),
          correct: false,
          misconception: 'C7.4-if-needs-else'),
    ],
    itemHints: hints(
      'Regarde le signe de très près.',
      'Look very closely at the sign.',
      'Il demande strictement plus grand.',
      'It asks for strictly bigger.',
    ),
    wrongChoiceFr: 'Le signe > refuse l\'égalité ; >= l\'accepte.',
    wrongChoiceEn: 'The > sign refuses equality; >= accepts it.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Un ami écrit si \$age = 8. Que lui expliques-tu ?',
      'A friend writes if \$age = 8. What do you explain?',
    ),
    choices: [
      Choice(
          labelKeys: b('Qu\'un test se compare avec ==, pas avec =.',
              'That a test compares with ==, not with =.'),
          correct: true),
      Choice(
          labelKeys: b('Qu\'il faut écrire 8 avant \$age.',
              'That 8 has to come before \$age.'),
          correct: false,
          misconception: 'C7.2-comparison-reads-backwards'),
      Choice(
          labelKeys:
              b('Que \$age est un mauvais nom.', 'That \$age is a bad name.'),
          correct: false,
          misconception: 'C6.1-name-is-cosmetic'),
      Choice(
          labelKeys: b('Que ça marche quand même.', 'That it works anyway.'),
          correct: false,
          misconception: 'C7.2-single-equals-compares'),
    ],
    itemHints: hints(
      'Dans un si, on pose une question.',
      'Inside an if, you ask a question.',
      'Poser une question demande ==.',
      'Asking a question needs ==.',
    ),
    wrongChoiceFr: 'Dans un si on compare, et comparer s\'écrit avec deux =.',
    wrongChoiceEn:
        'Inside an if you compare, and comparing is written with two =.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C7.3 — Si.
// Misconception: "the if block runs every time".
//
// The shape of nearly every item here is the same and it is chosen to make the
// misconception *visible on the canvas*: draw one figure always, and a second one only if
// the test passes. A child who believes the block always runs draws two figures where the
// target has one, and the grader can say "tu en as dessiné trop" — which is a sentence
// about what they see rather than a verdict.
//
// Half the parameter sets take the branch and half do not. An item whose test is always
// true is a straight line with extra words.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC73() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C7.3-${(++n).toString().padLeft(2, '0')}';

  /// Always draw [always]; draw [maybe] only when the test holds.
  String guarded(int value, String test, String always, String maybe) =>
      '\$x = $value\n$always\n${ifThen('\$x $test', maybe)}';

  // T1 — build it. Five sets: three where the second figure appears, two where it does not.
  for (final entry in [
    (7, '> 5', true, 4, 50, 90, 3, 50, 120),
    (3, '> 5', false, 4, 50, 90, 3, 50, 120),
    (2, '< 5', true, 6, 40, 60, 4, 40, 90),
    (8, '< 5', false, 6, 40, 60, 4, 40, 90),
    (4, '== 4', true, 3, 60, 120, 5, 40, 72),
  ]) {
    final value = entry.$1, test = entry.$2, taken = entry.$3;
    final always = figure(entry.$4, entry.$5, entry.$6);
    final maybe = figure(entry.$7, entry.$8, entry.$9);
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C7.3',
      difficulty: Difficulty.d3,
      solution: guarded(value, test, always, maybe),
      promptKeys: fillBoth(
        b(
            'Mets {v} dans \$x. Dessine la première figure toujours, et la '
                'seconde seulement si \$x {t}.',
            'Put {v} into \$x. Draw the first shape always, and the second '
                'only if \$x {t}.'),
        {'v': value, 't': test},
      ),
      wrong: [
        // Both figures, unconditionally: the misconception, drawn.
        '\$x = $value\n$always\n$maybe',
        // The first figure only, with no test at all.
        '\$x = $value\n$always',
        // The test inverted.
        guarded(value, test, always, maybe)
            .replaceFirst('si \$x $test', 'si non (\$x $test)'),
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'x', minReads: 1),
      ],
      alternatives: [
        '# la seconde figure est sous condition\n'
            '${guarded(value, test, always, maybe)}',
        guarded(value, test, always, maybe)
            .replaceFirst('si \$x $test', 'si (\$x $test)'),
      ],
      itemHints: hints(
        taken
            ? 'Le test est vrai pour $value.'
            : 'Le test est faux pour $value.',
        taken
            ? 'The test is true for $value.'
            : 'The test is false for $value.',
        'Mets la seconde figure dans le si.',
        'Put the second shape inside the if.',
      ),
      paletteScope: palette,
    ));
  }

  /* T2 — four bugs about *where the accolade is*. Each broken program draws the second
     figure unconditionally, which is the misconception written out. */
  for (final entry in [
    (3, '> 5', 4, 50, 90, 3, 50, 120),
    (9, '< 4', 6, 40, 60, 4, 45, 90),
    (5, '== 2', 3, 70, 120, 4, 45, 90),
    (1, '>= 6', 5, 45, 72, 3, 60, 120),
  ]) {
    final value = entry.$1, test = entry.$2;
    final always = figure(entry.$3, entry.$4, entry.$5);
    final maybe = figure(entry.$6, entry.$7, entry.$8);
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C7.3',
      difficulty: Difficulty.d3,
      broken: '\$x = $value\n$always\n$maybe',
      solution: guarded(value, test, always, maybe),
      promptKeys: fillBoth(
        b(
            'La seconde figure est dessinée alors que \$x garde {v}. '
                'Mets-la sous le test \$x {t}.',
            'The second shape is drawn even though \$x holds {v}. '
                'Put it under the test \$x {t}.'),
        {'v': value, 't': test},
      ),
      wrong: [
        '\$x = $value\n${ifThen('\$x $test', always)}\n$maybe',
        '\$x = $value\n$maybe\n${ifThen('\$x $test', always)}',
        guarded(value, test, always, maybe)
            .replaceFirst('si \$x $test', 'si non (\$x $test)'),
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'x', minReads: 1),
      ],
      alternatives: [
        '# la seconde figure passe sous le test\n'
            '${guarded(value, test, always, maybe)}',
        guarded(value, test, always, maybe)
            .replaceFirst('si \$x $test', 'si (\$x $test)'),
      ],
      itemHints: hints(
        'Regarde quelles lignes sont dans les accolades.',
        'Look at which lines are inside the brackets.',
        'La seconde figure doit y entrer.',
        'The second shape has to go in.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — how many lines does Tika draw? A number, because a number is what the two
     mistakes about `si` get wrong, in opposite directions: one adds the guarded figure
     when it was skipped, the other drops it when it ran.

     Which mistake is on offer therefore depends on the set, and it has to: a "the block
     ran anyway" distractor on a set whose test is *true* is the right answer with a
     different label. The first version of these items shipped exactly that on three sets
     out of five, and nothing noticed until the publish gate learned to compare choices
     with each other. */
  for (final entry in [
    (7, '> 5', 4, 3),
    (3, '> 5', 4, 3),
    (2, '< 5', 6, 4),
    (8, '< 5', 6, 4),
    (4, '== 4', 3, 5),
  ]) {
    final value = entry.$1,
        test = entry.$2,
        alwaysSides = entry.$3,
        maybeSides = entry.$4;
    final taken = switch (test) {
      '> 5' => value > 5,
      '< 5' => value < 5,
      _ => value == 4,
    };
    final drawn = taken ? alwaysSides + maybeSides : alwaysSides;
    // The mistake that is possible here, and only that one.
    final wrongCount = taken ? alwaysSides : alwaysSides + maybeSides;
    final wrongTag = taken ? 'C7.3-if-never-runs' : 'C7.3-if-always-runs';
    items.add(predict(
      id: id(),
      conceptId: 'C7.3',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b(
            'Combien de traits Tika dessine-t-elle ?\n\n'
                '\$x = {v}\n{a}\nsi \$x {t} {{\n{m}\n}}',
            'How many lines does Tika draw?\n\n'
                '\$x = {v}\n{a}\nif \$x {t} {{\n{m}\n}}'),
        {
          'v': value,
          't': test,
          'a': 'répète $alwaysSides { … }',
          'm': '  répète $maybeSides { … }',
        },
      ),
      choices: [
        Choice(labelKeys: b('$drawn', '$drawn'), correct: true),
        Choice(
            labelKeys: b('$wrongCount', '$wrongCount'),
            correct: false,
            misconception: wrongTag),
        Choice(
            labelKeys: b('$maybeSides', '$maybeSides'),
            correct: false,
            misconception: 'C7.3-if-replaces-what-came-before'),
        Choice(
            labelKeys: b('0', '0'),
            correct: false,
            misconception: 'C7.3-false-stops-everything'),
      ],
      itemHints: hints(
        'La première figure est dessinée dans tous les cas.',
        'The first shape is drawn whatever happens.',
        taken
            ? 'Le test est vrai, donc la seconde aussi.'
            : 'Le test est faux, donc la seconde est sautée.',
        taken
            ? 'The test is true, so the second one too.'
            : 'The test is false, so the second is skipped.',
      ),
      wrongChoiceFr:
          'Le bloc du si n\'est dessiné que si le test est vrai ; le reste l\'est toujours.',
      wrongChoiceEn:
          'The if block is drawn only when the test is true; the rest always is.',
    ));
  }

  // T4 — the hole is the test.
  for (final entry in [
    (7, '> 5', ['>= 7', '!= 2'], ['< 5', '== 2', '> 9'], 4, 50, 90, 3, 50, 120),
    (2, '< 5', ['<= 2', '!= 9'], ['> 5', '== 9', '>= 4'], 6, 40, 60, 4, 45, 90),
    (
      4,
      '== 4',
      ['>= 4', '<= 4'],
      ['> 4', '< 4', '!= 4'],
      3,
      70,
      120,
      5,
      40,
      72
    ),
    (9, '>= 9', ['> 8', '!= 1'], ['< 9', '== 1', '> 9'], 5, 45, 72, 4, 55, 90),
  ]) {
    final value = entry.$1, test = entry.$2;
    final alsoRight = entry.$3, alsoWrong = entry.$4;
    final always = figure(entry.$5, entry.$6, entry.$7);
    final maybe = figure(entry.$8, entry.$9, entry.$10);
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C7.3',
      difficulty: Difficulty.d3,
      withHoles: '\$x = $value\n$always\n${ifThen('\$x ___', maybe)}',
      solution: guarded(value, test, always, maybe),
      promptKeys: fillBoth(
        b('La boîte garde {v}. Complète le test pour que la seconde figure soit dessinée.',
            'The box holds {v}. Fill in the test so the second shape gets drawn.'),
        {'v': value},
      ),
      wrong: [
        for (final bad in alsoWrong) guarded(value, bad, always, maybe),
      ],
      alternatives: [
        for (final good in alsoRight) guarded(value, good, always, maybe),
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'x', minReads: 1),
      ],
      itemHints: hints(
        'Le test doit être vrai pour $value.',
        'The test has to be true for $value.',
        'Essaie-le à la main avant d\'écrire.',
        'Try it by hand before you write it.',
      ),
      paletteScope: palette,
    ));
  }

  /* T5 — Parsons. The lines are all there; only the accolades decide what is conditional,
     so putting them back in the wrong order changes what is drawn. */
  /* Every set here fails its test, and that is not a preference. When the test passes,
     moving a line into or out of the accolades changes nothing on the canvas — the gate
     caught all three of these as "wrong solutions that pass". A Parsons item about where
     the accolades go only has an answer when the branch is skipped. */
  for (final entry in [
    (3, '> 5', 4, 50, 90, 3, 50, 120),
    (8, '< 5', 6, 40, 60, 4, 45, 90),
    (2, '== 4', 3, 70, 120, 5, 40, 72),
  ]) {
    final value = entry.$1, test = entry.$2;
    final always = figure(entry.$3, entry.$4, entry.$5);
    final maybe = figure(entry.$6, entry.$7, entry.$8);
    items.add(parsons(
      id: id(),
      conceptId: 'C7.3',
      difficulty: Difficulty.d3,
      solution: guarded(value, test, always, maybe),
      promptKeys: fillBoth(
        b('Remets le programme en ordre : la seconde figure ne se dessine que si \$x {t}.',
            'Put the program back in order: the second shape is drawn only if \$x {t}.'),
        {'t': test},
      ),
      wrong: [
        '\$x = $value\n$always\n$maybe',
        '\$x = $value\n${ifThen('\$x $test', always)}\n$maybe',
        '\$x = $value\n${ifThen('\$x $test', '$always\n$maybe')}',
      ],
      alternatives: [
        '# la seconde figure est sous condition\n'
            '${guarded(value, test, always, maybe)}',
        guarded(value, test, always, maybe)
            .replaceFirst('si \$x $test', 'si (\$x $test)'),
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'x', minReads: 1),
      ],
      itemHints: hints(
        'La boîte se remplit en premier.',
        'The box is filled first.',
        'Seule la seconde figure entre dans les accolades.',
        'Only the second shape goes inside the brackets.',
      ),
      paletteScope: palette,
    ));
  }

  // T9 — three open builds, judged by a rubric shown before the child starts.
  items.add(openBuild(
    id: id(),
    conceptId: 'C7.3',
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Fais un dessin qui change selon ce qu\'il y a dans une boîte.',
      'Make a drawing that changes with what is in a box.',
    ),
    rubric: [
      rubricLine('Tu remplis une boîte.', 'You fill a box.',
          const UsesVariable(minReads: 1)),
      rubricLine('Ton programme pose une question avec si.',
          'Your program asks a question with if.', const ContainsNode('If')),
      rubricLine('Tika dessine quelque chose.', 'Tika draws something.',
          const UsesOpcode('MOVE_FORWARD')),
    ],
    itemHints: hints(
      'Commence par remplir une boîte.',
      'Start by filling a box.',
      'Mets ensuite un dessin dans un si.',
      'Then put a drawing inside an if.',
    ),
    paletteScope: palette,
  ));
  items.add(openBuild(
    id: id(),
    conceptId: 'C7.3',
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Fais un dessin qui ajoute une figure seulement parfois.',
      'Make a drawing that adds a shape only sometimes.',
    ),
    rubric: [
      rubricLine(
          'Une figure est dessinée dans tous les cas.',
          'One shape is drawn whatever happens.',
          const ContainsNode('Repeat', min: 2)),
      rubricLine('Une autre est sous un si.', 'Another one is under an if.',
          const NestedInside('If', 'Repeat')),
      rubricLine('Le test lit une boîte.', 'The test reads a box.',
          const UsesVariable(minReads: 1)),
      rubricLine('Le hasard choisit ce qu\'il y a dans la boîte.',
          'Random chooses what goes in the box.', const UsesOpcode('RANDOM')),
    ],
    itemHints: hints(
      'Tire un nombre et range-le.',
      'Draw a number and store it.',
      'Sers-t\'en dans le test du si.',
      'Use it in the if\'s test.',
    ),
    paletteScope: palette,
  ));
  items.add(openBuild(
    id: id(),
    conceptId: 'C7.3',
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Fais un dessin dont la couleur dépend d\'un test.',
      'Make a drawing whose colour depends on a test.',
    ),
    rubric: [
      rubricLine('Ton programme pose une question avec si.',
          'Your program asks a question with if.', const ContainsNode('If')),
      rubricLine('Tu changes la couleur du crayon.',
          'You change the pen colour.', const UsesOpcode('PEN_COLOR')),
      rubricLine('Le test lit une boîte.', 'The test reads a box.',
          const UsesVariable(minReads: 1)),
    ],
    itemHints: hints(
      'Range un nombre dans une boîte.',
      'Store a number in a box.',
      'Mets couleurcrayon dans le si.',
      'Put pencolor inside the if.',
    ),
    paletteScope: palette,
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C7.4 — Sinon.
// Misconception: "else runs as well as if".
//
// `sinon` is the first thing in KODO that is defined by what it does *not* do. Two figures
// sit in the program and exactly one is drawn, which makes the misconception cost a
// picture: a child who thinks both branches run draws both and is told they drew too much.
// The parameter sets alternate which branch is taken, so neither figure is ever the safe
// guess.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC74() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C7.4-${(++n).toString().padLeft(2, '0')}';

  String branch(int value, String test, String then, String otherwise) =>
      '\$x = $value\n${ifElse('\$x $test', then, otherwise)}';

  /* T2 — five bugs. The broken program always draws both branches, one way or another:
     that is the misconception, and it is the only bug this concept has. */
  /* Every set here *takes* the first branch, and that is forced rather than chosen. The
     bug is "both bodies ran"; when the test fails, only the second body runs, which is
     exactly what the fixed program does — so the broken program would be a wrong answer
     that draws the right picture. The gate said so about two of them. The skipped branch
     is covered by the T3, T4 and T5 items below, which do not have this shape. */
  for (final entry in [
    (7, '> 5', 4, 50, 90, 3, 60, 120),
    (9, '> 6', 6, 40, 60, 5, 45, 72),
    (1, '< 4', 3, 70, 120, 4, 45, 90),
    (2, '<= 2', 5, 50, 72, 6, 40, 60),
    (4, '== 4', 4, 65, 90, 3, 55, 120),
  ]) {
    final value = entry.$1, test = entry.$2;
    final then = figure(entry.$3, entry.$4, entry.$5);
    final otherwise = figure(entry.$6, entry.$7, entry.$8);
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C7.4',
      difficulty: Difficulty.d3,
      // Two separate tests: both bodies can run, and here both do.
      broken: '\$x = $value\n${ifThen('\$x $test', then)}\n'
          '${ifThen('vrai', otherwise)}',
      solution: branch(value, test, then, otherwise),
      promptKeys: b(
          'Les deux figures sont dessinées. Il n\'en faut qu\'une : sers-toi de sinon.',
          'Both shapes are drawn. Only one should be: use else.'),
      wrong: [
        '\$x = $value\n$then\n$otherwise',
        branch(value, test, otherwise, then),
        '\$x = $value\n${ifThen('\$x $test', '$then\n$otherwise')}',
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'x', minReads: 1),
      ],
      alternatives: [
        '# une seule des deux figures\n${branch(value, test, then, otherwise)}',
        branch(value, test, then, otherwise)
            .replaceFirst('si \$x $test', 'si (\$x $test)'),
      ],
      itemHints: hints(
        'Un sinon garde l\'autre chemin.',
        'An else keeps the other path.',
        'Tika n\'en prend qu\'un seul.',
        'Tika takes only one of them.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — how many lines? The "both branches" answer is always on offer, and it is always
     the sum of the two, so picking it is picking the misconception. */
  for (final entry in [
    (7, '> 5', 4, 3),
    (2, '> 5', 4, 3),
    (8, '< 4', 6, 5),
    (1, '< 4', 6, 5),
    (4, '== 4', 3, 4),
  ]) {
    final value = entry.$1,
        test = entry.$2,
        thenSides = entry.$3,
        elseSides = entry.$4;
    final taken = switch (test) {
      '> 5' => value > 5,
      '< 4' => value < 4,
      _ => value == 4,
    };
    final drawn = taken ? thenSides : elseSides;
    final other = taken ? elseSides : thenSides;
    items.add(predict(
      id: id(),
      conceptId: 'C7.4',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b(
            'Combien de traits Tika dessine-t-elle ?\n\n'
                '\$x = {v}\nsi \$x {t} {{\n  répète {a} {{ … }}\n}}\n'
                'sinon {{\n  répète {b} {{ … }}\n}}',
            'How many lines does Tika draw?\n\n'
                '\$x = {v}\nif \$x {t} {{\n  repeat {a} {{ … }}\n}}\n'
                'else {{\n  repeat {b} {{ … }}\n}}'),
        {'v': value, 't': test, 'a': thenSides, 'b': elseSides},
      ),
      choices: [
        Choice(labelKeys: b('$drawn', '$drawn'), correct: true),
        Choice(
            labelKeys:
                b('${thenSides + elseSides}', '${thenSides + elseSides}'),
            correct: false,
            misconception: 'C7.4-else-runs-too'),
        Choice(
            labelKeys: b('$other', '$other'),
            correct: false,
            misconception: 'C7.4-wrong-branch-taken'),
        Choice(
            labelKeys: b('0', '0'),
            correct: false,
            misconception: 'C7.3-false-stops-everything'),
      ],
      itemHints: hints(
        'Commence par répondre au test.',
        'Start by answering the test.',
        'Un seul des deux blocs est joué.',
        'Only one of the two blocks is played.',
      ),
      wrongChoiceFr:
          'Avec un sinon, Tika joue un bloc ou l\'autre, jamais les deux.',
      wrongChoiceEn:
          'With an else, Tika plays one block or the other, never both.',
    ));
  }

  // T4 — the hole is the word that makes the second block the *other* path.
  for (final entry in [
    (7, '> 5', 4, 50, 90, 3, 60, 120),
    (2, '> 5', 4, 50, 90, 3, 60, 120),
    (8, '< 4', 6, 40, 60, 5, 45, 72),
    (4, '== 4', 3, 70, 120, 4, 45, 90),
  ]) {
    final value = entry.$1, test = entry.$2;
    final then = figure(entry.$3, entry.$4, entry.$5);
    final otherwise = figure(entry.$6, entry.$7, entry.$8);
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C7.4',
      difficulty: Difficulty.d3,
      withHoles: '\$x = $value\n${ifThen('\$x $test', then)}\n'
          '___ {\n${otherwise.split('\n').map((l) => '  $l').join('\n')}\n}',
      solution: branch(value, test, then, otherwise),
      promptKeys: b(
          'Complète pour qu\'une seule des deux figures soit dessinée.',
          'Fill in the blank so only one of the two shapes is drawn.'),
      wrong: [
        /* Both figures, with no test between them. A version that guards only the first
           and leaves the second bare draws the right picture whenever the test fails,
           which is half these sets — so it is not used. */
        '\$x = $value\n$then\n$otherwise',
        '\$x = $value\n${ifThen('\$x $test', then)}\n'
            '${ifThen('\$x $test', otherwise)}',
        branch(value, test, otherwise, then),
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'x', minReads: 1),
      ],
      alternatives: [
        '# l\'autre chemin\n${branch(value, test, then, otherwise)}',
        branch(value, test, then, otherwise)
            .replaceFirst('si \$x $test', 'si (\$x $test)'),
      ],
      itemHints: hints(
        'Il manque le mot qui dit « l\'autre chemin ».',
        'The word that says "the other path" is missing.',
        'C\'est sinon.',
        'It is else.',
      ),
      paletteScope: palette,
    ));
  }

  // T5 — Parsons, over the two branches.
  for (final entry in [
    (7, '> 5', 4, 50, 90, 3, 60, 120),
    (2, '> 5', 4, 50, 90, 3, 60, 120),
    (8, '< 4', 6, 40, 60, 5, 45, 72),
    (4, '== 4', 3, 70, 120, 4, 45, 90),
  ]) {
    final value = entry.$1, test = entry.$2;
    final then = figure(entry.$3, entry.$4, entry.$5);
    final otherwise = figure(entry.$6, entry.$7, entry.$8);
    items.add(parsons(
      id: id(),
      conceptId: 'C7.4',
      difficulty: Difficulty.d3,
      solution: branch(value, test, then, otherwise),
      promptKeys: fillBoth(
        b('Remets en ordre : la première figure si \$x {t}, la seconde sinon.',
            'Put it back in order: the first shape if \$x {t}, the second otherwise.'),
        {'t': test},
      ),
      wrong: [
        branch(value, test, otherwise, then),
        '\$x = $value\n$then\n$otherwise',
        '\$x = $value\n${ifThen('\$x $test', '$then\n$otherwise')}',
      ],
      alternatives: [
        '# une seule des deux\n${branch(value, test, then, otherwise)}',
        branch(value, test, then, otherwise)
            .replaceFirst('si \$x $test', 'si (\$x $test)'),
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'x', minReads: 1),
      ],
      itemHints: hints(
        'La boîte se remplit avant le test.',
        'The box is filled before the test.',
        'Le sinon vient après l\'accolade fermée.',
        'The else comes after the closing bracket.',
      ),
      paletteScope: palette,
    ));
  }

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.4',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Un ami dit : « le sinon se fait aussi ». Que réponds-tu ?',
      'A friend says: "the else happens as well". What do you answer?',
    ),
    choices: [
      Choice(
          labelKeys: b('Non : un seul des deux chemins est pris.',
              'No: only one of the two paths is taken.'),
          correct: true),
      Choice(
          labelKeys:
              b('Oui, l\'un après l\'autre.', 'Yes, one after the other.'),
          correct: false,
          misconception: 'C7.4-else-runs-too'),
      Choice(
          labelKeys:
              b('Oui, si le test est vrai.', 'Yes, if the test is true.'),
          correct: false,
          misconception: 'C7.4-else-runs-too'),
      Choice(
          labelKeys: b('Le sinon ne sert jamais.', 'The else is never used.'),
          correct: false,
          misconception: 'C7.4-else-never-runs'),
    ],
    itemHints: hints(
      'Pense à deux portes dans un couloir.',
      'Think of two doors in a corridor.',
      'On ne peut en passer qu\'une.',
      'You can only go through one.',
    ),
    wrongChoiceFr:
        'Le sinon est l\'autre chemin : il se joue quand le si ne se joue pas.',
    wrongChoiceEn: 'The else is the other path: it plays when the if does not.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.4',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d2,
    promptKeys: b(
      'Quelle est la différence entre deux si et un si… sinon ?',
      'What is the difference between two ifs and one if… else?',
    ),
    choices: [
      Choice(
          labelKeys: b('Avec deux si, les deux blocs peuvent se jouer.',
              'With two ifs, both blocks can play.'),
          correct: true),
      Choice(
          labelKeys: b('Aucune différence.', 'No difference.'),
          correct: false,
          misconception: 'C7.4-else-is-a-second-if'),
      Choice(
          labelKeys: b('Deux si vont plus vite.', 'Two ifs are faster.'),
          correct: false,
          misconception: 'C6.1-box-is-speed'),
      Choice(
          labelKeys:
              b('Un sinon a besoin de deux tests.', 'An else needs two tests.'),
          correct: false,
          misconception: 'C7.4-else-needs-its-own-test'),
    ],
    itemHints: hints(
      'Deux si posent deux questions séparées.',
      'Two ifs ask two separate questions.',
      'Un sinon partage la même question.',
      'An else shares the one question.',
    ),
    wrongChoiceFr:
        'Un sinon partage le test du si ; deux si sont deux questions.',
    wrongChoiceEn: 'An else shares the if\'s test; two ifs are two questions.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.4',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi un sinon n\'a-t-il pas son propre test ?',
      'Why does an else have no test of its own?',
    ),
    choices: [
      Choice(
          labelKeys: b('Parce qu\'il couvre tous les autres cas.',
              'Because it covers every other case.'),
          correct: true),
      Choice(
          labelKeys: b('Parce qu\'on a oublié de l\'écrire.',
              'Because we forgot to write it.'),
          correct: false,
          misconception: 'C7.4-else-needs-its-own-test'),
      Choice(
          labelKeys: b(
              'Parce qu\'il est toujours vrai.', 'Because it is always true.'),
          correct: false,
          misconception: 'C7.4-else-runs-too'),
      Choice(
          labelKeys: b(
              'Parce qu\'il est toujours faux.', 'Because it is always false.'),
          correct: false,
          misconception: 'C7.4-else-never-runs'),
    ],
    itemHints: hints(
      'Le si a déjà posé la question.',
      'The if has already asked the question.',
      'Le sinon prend tout le reste.',
      'The else takes everything else.',
    ),
    wrongChoiceFr: 'Le sinon est le reste de la question que le si a posée.',
    wrongChoiceEn: 'The else is the rest of the question the if asked.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.4',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d2,
    promptKeys: b(
      'À quoi sert un sinon dans un jeu ?',
      'What is an else for in a game?',
    ),
    choices: [
      Choice(
          labelKeys: b('À dire ce qui arrive quand on rate.',
              'To say what happens when you miss.'),
          correct: true),
      Choice(
          labelKeys: b('À recommencer le jeu.', 'To restart the game.'),
          correct: false,
          misconception: 'C7.3-false-stops-everything'),
      Choice(
          labelKeys:
              b('À rendre le jeu plus difficile.', 'To make the game harder.'),
          correct: false,
          misconception: 'C7.4-else-is-decoration'),
      Choice(
          labelKeys: b('À rien : on peut toujours s\'en passer.',
              'Nothing: you can always do without it.'),
          correct: false,
          misconception: 'C7.4-else-never-runs'),
    ],
    itemHints: hints(
      'Un jeu a deux réponses possibles.',
      'A game has two possible answers.',
      'Gagné d\'un côté, raté de l\'autre.',
      'Won on one side, missed on the other.',
    ),
    wrongChoiceFr:
        'Le sinon écrit le second cas : ce qui se passe quand le test échoue.',
    wrongChoiceEn:
        'The else writes the second case: what happens when the test fails.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C7.5 — Et / ou / non.
// Misconception: "or means both must be true".
//
// Everyday French and English are against us here. *"Prends un fruit ou un gâteau"* means
// one, not both, and *"il faut être grand et avoir huit ans"* is the only one of the two
// that a child hears as strict. So the items never define the words — they run them, on
// the four combinations, and let the canvas answer. The four-row truth table is the
// concept, and every `ou` item below includes the row where exactly one side is true,
// because that is the row the misconception gets wrong.
//
// `et` binds tighter than `ou`, and `non` tighter than both. That is checked rather than
// assumed: `faux et vrai ou vrai` is true on the real interpreter, which only holds if
// `et` goes first.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC75() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C7.5-${(++n).toString().padLeft(2, '0')}';

  Choice yes({bool correct = false, String? misconception}) => Choice(
      labelKeys: b('vrai', 'true'),
      correct: correct,
      misconception: misconception);
  Choice no({bool correct = false, String? misconception}) => Choice(
      labelKeys: b('faux', 'false'),
      correct: correct,
      misconception: misconception);

  /* T3 — six rows of the table, read off the interpreter. The third and fourth are the
     ones that carry the concept: exactly one side true, under `ou` and under `et`. */
  for (final entry in [
    ('vrai et vrai', true, 'C7.5-and-means-or'),
    ('vrai et faux', false, 'C7.5-and-means-or'),
    ('vrai ou faux', true, 'C7.5-or-needs-both'),
    ('faux ou faux', false, 'C7.5-or-is-always-true'),
    ('non vrai', false, 'C7.5-not-does-nothing'),
    ('non (2 > 7)', true, 'C7.5-not-does-nothing'),
  ]) {
    final expression = entry.$1, answer = entry.$2, slip = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C7.5',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Que va écrire Tika ?\n\nécris {e}',
            'What will Tika print?\n\nprint {e}'),
        {'e': expression},
      ),
      choices: [
        if (answer) yes(correct: true) else no(correct: true),
        if (answer) no(misconception: slip) else yes(misconception: slip),
        Choice(
            labelKeys: b('les deux', 'both of them'),
            correct: false,
            misconception: 'C7.5-answer-is-two-values'),
        Choice(
            labelKeys: b('rien', 'nothing'),
            correct: false,
            misconception: 'C7.2-comparison-prints-nothing'),
      ],
      itemHints: hints(
        'Réponds d\'abord à chaque morceau.',
        'Answer each piece first.',
        'Puis mets les deux réponses ensemble.',
        'Then put the two answers together.',
      ),
      wrongChoiceFr:
          'et demande les deux ; ou se contente d\'un seul ; non renverse.',
      wrongChoiceEn: 'and wants both; or is happy with one; not flips it over.',
    ));
  }

  /* T4 and T2 — the joining word, on the only row that can tell `et` from `ou`.
     
     This took a rewrite, and the gate is what forced it. When both halves of a test are
     true, `et` and `ou` give the same answer, and a hole with two right answers is not a
     hole. When both are false they agree again. **The single discriminating row is the
     one where exactly one half is true**, so every set below is that row — and it is used
     twice, because on that row `ou` draws and `et` does not.

     Which means the figure cannot be the whole program. One figure is drawn always and a
     second one only under the test, so "the triangle should be left out" is a target a
     child can see, and `et` gets to be a right answer rather than only a distractor. */
  for (final entry in [
    (
      7,
      2,
      r'$a > 5',
      r'$b > 5',
      'ou',
      'et',
      [
        r'$a > 5 et $b > 5',
        r'non ($a > 5 ou $b > 5)',
        r'non ($a > 5) ou $b > 5'
      ],
      4,
      50,
      90,
      3,
      55,
      120
    ),
    (
      7,
      2,
      r'$a > 5',
      r'$b > 5',
      'et',
      'ou',
      [r'$a > 5 ou $b > 5', r'non ($a > 5 et $b > 5)', r'non ($b > 5)'],
      4,
      50,
      90,
      3,
      55,
      120
    ),
    (
      1,
      9,
      r'$a < 5',
      r'$b < 5',
      'ou',
      'et',
      [
        r'$a < 5 et $b < 5',
        r'non ($a < 5 ou $b < 5)',
        r'non ($a < 5) ou $b < 5'
      ],
      6,
      40,
      60,
      4,
      50,
      90
    ),
    (
      1,
      9,
      r'$a < 5',
      r'$b < 5',
      'et',
      'ou',
      [r'$a < 5 ou $b < 5', r'non ($a < 5 et $b < 5)', r'non ($b < 5)'],
      6,
      40,
      60,
      4,
      50,
      90
    ),
    (
      4,
      9,
      r'$a == 4',
      r'$b == 4',
      'ou',
      'et',
      [
        r'$a == 4 et $b == 4',
        r'non ($a == 4 ou $b == 4)',
        r'non ($a == 4) ou $b == 4'
      ],
      3,
      70,
      120,
      5,
      45,
      72
    ),
  ]) {
    final a = entry.$1,
        bb = entry.$2,
        left = entry.$3,
        right = entry.$4,
        good = entry.$5,
        bad = entry.$6,
        wrongTests = entry.$7;
    final always = figure(entry.$8, entry.$9, entry.$10);
    final maybe = figure(entry.$11, entry.$12, entry.$13);
    final setup = '\$a = $a\n\$b = $bb\n$always';
    final draws = good == 'ou';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C7.5',
      difficulty: Difficulty.d3,
      withHoles: '$setup\n${ifThen('$left ___ $right', maybe)}',
      solution: '$setup\n${ifThen('$left $good $right', maybe)}',
      promptKeys: fillBoth(
        b('\$a garde {a} et \$b garde {b}. Quel mot {w} la seconde figure ?',
            '\$a holds {a} and \$b holds {b}. Which word {w} the second shape?'),
        {
          'a': a,
          'b': bb,
          'w': draws ? 'fait dessiner' : 'laisse de côté',
        },
      )..['en'] = fill(
          '\$a holds {a} and \$b holds {b}. Which word {w} the second shape?',
          {'a': a, 'b': bb, 'w': draws ? 'draws' : 'leaves out'}),
      wrong: [
        for (final test in wrongTests) '$setup\n${ifThen(test, maybe)}',
      ],
      alternatives: [
        '$setup\n${ifThen('($left) $good ($right)', maybe)}',
        '$setup\n${ifThen('non (non ($left $good $right))', maybe)}',
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'a', minReads: 1),
        const UsesVariable(name: 'b', minReads: 1),
      ],
      itemHints: hints(
        'Réponds à chaque moitié du test.',
        'Answer each half of the test.',
        'Une seule moitié est vraie.',
        'Only one half is true.',
      ),
      paletteScope: palette,
    ));
    // The distractor `bad` is never unused: it is the first of the three wrong tests.
    assert(wrongTests.first.contains(bad));
  }

  /* T2 — the same row, as a bug. `et` is written where `ou` belongs, one half is true,
     and the second figure never appears. */
  for (final entry in [
    (7, 2, r'$a > 5', r'$b > 5', 4, 50, 90, 3, 55, 120),
    (1, 9, r'$a < 5', r'$b < 5', 6, 40, 60, 4, 50, 90),
    (4, 9, r'$a == 4', r'$b == 4', 3, 70, 120, 5, 45, 72),
  ]) {
    final a = entry.$1, bb = entry.$2, left = entry.$3, right = entry.$4;
    final always = figure(entry.$5, entry.$6, entry.$7);
    final maybe = figure(entry.$8, entry.$9, entry.$10);
    final setup = '\$a = $a\n\$b = $bb\n$always';
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C7.5',
      difficulty: Difficulty.d3,
      broken: '$setup\n${ifThen('$left et $right', maybe)}',
      solution: '$setup\n${ifThen('$left ou $right', maybe)}',
      promptKeys: b(
          'Une seule moitié du test est vraie, et la seconde figure manque. Change le mot qui les relie.',
          'Only one half of the test is true, and the second shape is missing. Change the word joining them.'),
      wrong: [
        // No test at all: the figure comes back, and the claim is not made.
        setup,
        '$setup\n${ifThen('non ($left ou $right)', maybe)}',
        '$setup\n${ifThen('non ($left) ou ($right)', maybe)}',
      ],
      assertions: [
        const ContainsNode('If'),
        const UsesVariable(name: 'a', minReads: 1),
        const UsesVariable(name: 'b', minReads: 1),
      ],
      alternatives: [
        '# ou se contente d\'une moitié\n$setup\n'
            '${ifThen('($left) ou ($right)', maybe)}',
        '$setup\n${ifThen('$right ou $left', maybe)}',
      ],
      itemHints: hints(
        'et exige les deux moitiés.',
        'and demands both halves.',
        'Ici une seule est vraie.',
        'Here only one is true.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Quand « A ou B » est-il vrai ?', 'When is "A or B" true?'),
    choices: [
      Choice(
          labelKeys: b('Dès qu\'au moins un des deux est vrai.',
              'As soon as at least one of them is true.'),
          correct: true),
      Choice(
          labelKeys:
              b('Seulement si les deux sont vrais.', 'Only if both are true.'),
          correct: false,
          misconception: 'C7.5-or-needs-both'),
      Choice(
          labelKeys: b(
              'Seulement si un seul est vrai.', 'Only if exactly one is true.'),
          correct: false,
          misconception: 'C7.5-or-is-exclusive'),
      Choice(
          labelKeys: b('Toujours.', 'Always.'),
          correct: false,
          misconception: 'C7.5-or-is-always-true'),
    ],
    itemHints: hints(
      'Essaie les quatre cas possibles.',
      'Try the four possible cases.',
      'Un seul vrai suffit déjà.',
      'One true is already enough.',
    ),
    wrongChoiceFr:
        'ou est vrai dès qu\'une moitié l\'est, et aussi si les deux le sont.',
    wrongChoiceEn: 'or is true as soon as one half is, and also when both are.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Quand « A et B » est-il vrai ?', 'When is "A and B" true?'),
    choices: [
      Choice(
          labelKeys:
              b('Seulement si les deux sont vrais.', 'Only if both are true.'),
          correct: true),
      Choice(
          labelKeys: b('Dès qu\'un des deux est vrai.',
              'As soon as one of them is true.'),
          correct: false,
          misconception: 'C7.5-and-means-or'),
      Choice(
          labelKeys:
              b('Seulement si les deux sont faux.', 'Only if both are false.'),
          correct: false,
          misconception: 'C7.5-and-is-inverted'),
      Choice(
          labelKeys: b('Jamais.', 'Never.'),
          correct: false,
          misconception: 'C7.5-and-is-impossible'),
    ],
    itemHints: hints(
      'Pense à deux conditions pour entrer quelque part.',
      'Think of two conditions for getting in somewhere.',
      'Il faut remplir les deux.',
      'You have to meet both.',
    ),
    wrongChoiceFr: 'et n\'est vrai que si les deux moitiés le sont.',
    wrongChoiceEn: 'and is true only when both halves are.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait non ?', 'What does not do?'),
    choices: [
      Choice(
          labelKeys: b('Il renverse la réponse.', 'It flips the answer over.'),
          correct: true),
      Choice(
          labelKeys: b('Il rend toujours faux.', 'It always gives false.'),
          correct: false,
          misconception: 'C7.5-not-always-false'),
      Choice(
          labelKeys: b('Il efface le test.', 'It deletes the test.'),
          correct: false,
          misconception: 'C7.5-not-does-nothing'),
      Choice(
          labelKeys: b('Il change les nombres.', 'It changes the numbers.'),
          correct: false,
          misconception: 'C7.5-not-changes-numbers'),
    ],
    itemHints: hints(
      'Pense à répondre le contraire.',
      'Think of answering the opposite.',
      'Un oui devient un non.',
      'A yes becomes a no.',
    ),
    wrongChoiceFr: 'non échange les deux réponses : vrai devient faux.',
    wrongChoiceEn: 'not swaps the two answers: true becomes false.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(r'$a = 7 et $b = 2. Que vaut $a > 5 ou $b > 5 ?',
        r'$a = 7 and $b = 2. What is $a > 5 or $b > 5?'),
    choices: [
      yes(correct: true),
      no(misconception: 'C7.5-or-needs-both'),
      Choice(
          labelKeys: b('7 et 2', '7 and 2'),
          correct: false,
          misconception: 'C7.1-test-keeps-its-numbers'),
      Choice(
          labelKeys: b('on ne peut pas savoir', 'there is no way to know'),
          correct: false,
          misconception: 'C7.1-test-is-just-words'),
    ],
    itemHints: hints(
      'Sept est plus grand que cinq.',
      'Seven is bigger than five.',
      'Une moitié vraie suffit pour ou.',
      'One true half is enough for or.',
    ),
    wrongChoiceFr: 'La première moitié est vraie, donc le ou est vrai.',
    wrongChoiceEn: 'The first half is true, so the or is true.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Dans faux et vrai ou vrai, que fait Tika en premier ?',
        'In false and true or true, what does Tika do first?'),
    choices: [
      Choice(labelKeys: b('faux et vrai', 'false and true'), correct: true),
      Choice(
          labelKeys: b('vrai ou vrai', 'true or true'),
          correct: false,
          misconception: 'C7.5-or-binds-tighter'),
      Choice(
          labelKeys: b('Tout en même temps.', 'All of it at once.'),
          correct: false,
          misconception: 'C6.3-no-order'),
      Choice(
          labelKeys:
              b('Elle lit de droite à gauche.', 'She reads right to left.'),
          correct: false,
          misconception: 'C6.3-right-to-left'),
    ],
    itemHints: hints(
      'et est plus pressé que ou.',
      'and is in more of a hurry than or.',
      'C\'est la même règle qu\'avec × et +.',
      'It is the same rule as with × and +.',
    ),
    wrongChoiceFr: 'et passe avant ou, comme × passe avant +.',
    wrongChoiceEn: 'and goes before or, the way × goes before +.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.5',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Un ami dit : « ou veut dire que les deux doivent être vrais ». Que réponds-tu ?',
      'A friend says: "or means both have to be true". What do you answer?',
    ),
    choices: [
      Choice(
          labelKeys: b('Non : un seul suffit, et les deux vont aussi.',
              'No: one is enough, and both works too.'),
          correct: true),
      Choice(
          labelKeys: b('Oui, c\'est ça.', 'Yes, that is it.'),
          correct: false,
          misconception: 'C7.5-or-needs-both'),
      Choice(
          labelKeys: b('Non : il en faut exactement un.',
              'No: it has to be exactly one.'),
          correct: false,
          misconception: 'C7.5-or-is-exclusive'),
      Choice(
          labelKeys: b('Non : ou est toujours vrai.', 'No: or is always true.'),
          correct: false,
          misconception: 'C7.5-or-is-always-true'),
    ],
    itemHints: hints(
      'C\'est le mot et qui exige les deux.',
      'It is the word and that demands both.',
      'ou se contente d\'une moitié.',
      'or is happy with one half.',
    ),
    wrongChoiceFr:
        'ou est vrai avec une moitié vraie, et reste vrai avec les deux.',
    wrongChoiceEn: 'or is true with one half true, and stays true with both.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.5',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi le ou de KODO n\'est-il pas celui de « un fruit ou un gâteau » ?',
      'Why is KODO\'s or not the one in "a fruit or a cake"?',
    ),
    choices: [
      Choice(
          labelKeys: b('Parce qu\'en KODO les deux à la fois restent vrais.',
              'Because in KODO both at once is still true.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que KODO ne connaît pas les gâteaux.',
              'Because KODO does not know about cakes.'),
          correct: false,
          misconception: 'C7.5-or-is-exclusive'),
      Choice(
          labelKeys: b('Parce que le ou de KODO est plus strict.',
              'Because KODO\'s or is stricter.'),
          correct: false,
          misconception: 'C7.5-or-needs-both'),
      Choice(
          labelKeys: b('C\'est le même.', 'It is the same one.'),
          correct: false,
          misconception: 'C7.5-or-is-exclusive'),
    ],
    itemHints: hints(
      'À table, ou veut dire « choisis-en un ».',
      'At the table, or means "pick one".',
      'En KODO, les deux passent aussi.',
      'In KODO, both gets through as well.',
    ),
    wrongChoiceFr:
        'Le ou de KODO accepte une moitié vraie, et accepte aussi les deux.',
    wrongChoiceEn:
        'KODO\'s or accepts one true half, and accepts both as well.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C7.5',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi écrire non (\$x > 5) plutôt que \$x < 5 ?',
      'Why write not (\$x > 5) rather than \$x < 5?',
    ),
    choices: [
      Choice(
          labelKeys: b('Parce que le cas égal change de côté.',
              'Because the equal case changes sides.'),
          correct: true),
      Choice(
          labelKeys:
              b('Parce que c\'est plus rapide.', 'Because it is faster.'),
          correct: false,
          misconception: 'C6.1-box-is-speed'),
      Choice(
          labelKeys:
              b('Parce que non est obligatoire.', 'Because not is compulsory.'),
          correct: false,
          misconception: 'C6.1-box-is-compulsory'),
      Choice(
          labelKeys: b('C\'est exactement pareil.', 'It is exactly the same.'),
          correct: false,
          misconception: 'C7.2-strict-and-loose-are-the-same'),
    ],
    itemHints: hints(
      'Essaie les deux avec \$x qui garde 5.',
      'Try both with \$x holding 5.',
      'L\'un est vrai, l\'autre non.',
      'One is true, the other is not.',
    ),
    wrongChoiceFr:
        'Le contraire de « plus grand » est « plus petit ou égal », pas « plus petit ».',
    wrongChoiceEn:
        'The opposite of "bigger" is "smaller or equal", not "smaller".',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// Tutorials (§4.2: Je regarde · On fait ensemble · Je fais).
//
// Narration never says *conditionnelle* — `FR-M5-03`'s jargon list forbids it and the
// child would learn a word instead of an idea. It says *question*, *oui*, *non* and
// *chemin*, and the closing line names the concept the way a child can repeat it.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Tutorial> world7Tutorials() => [
      tutorialFor(
        conceptId: 'C7.1',
        conceptName: b(
            'Une boîte garde un oui ou un non.', 'A box keeps a yes or a no.'),
        palette: palette,
        steps: [
          watchStep(
            'C7.1',
            'Tika range un oui dans une boîte.',
            'Tika puts a yes into a box.',
            '\$ok = vrai\n${ifThen('\$ok', figure(4, 60, 90))}',
            ideas: ['boolean', 'guard'],
          ),
          togetherStep(
            'C7.1',
            'À toi. Mets vrai dans la boîte \$ok.',
            'Your turn. Put true into the box \$ok.',
            assigns: 'ok',
            hintFr: 'Écris \$ok = vrai sur la première ligne.',
            hintEn: 'Write \$ok = true on the first line.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C7.1',
            'Range un oui. Dessine si la boîte dit oui.',
            'Store a yes. Draw if the box says yes.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Remplis la boîte. Mets le dessin dans un si.',
            hintEn: 'Fill the box. Put the drawing inside an if.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C7.2',
        conceptName: b('Comparer rend un oui ou un non.',
            'Comparing gives back a yes or a no.'),
        palette: palette,
        steps: [
          watchStep(
            'C7.2',
            'Tika compare deux nombres et répond.',
            'Tika compares two numbers and answers.',
            '\$x = 5\n${ifThen('\$x >= 5', figure(4, 60, 90))}',
            ideas: ['comparison', 'boundary'],
          ),
          togetherStep(
            'C7.2',
            'Mets 5 dans \$x. Le test doit dire oui.',
            'Put 5 into \$x. The test has to say yes.',
            assigns: 'x',
            hintFr: 'Écris \$x = 5 puis un test avec >=.',
            hintEn: 'Write \$x = 5 then a test with >=.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C7.2',
            'Fais un dessin qui teste ta boîte.',
            'Make a drawing that tests your box.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Un seul = range. Pour comparer il en faut deux.',
            hintEn: 'One = puts in. Comparing needs two.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C7.3',
        conceptName: b('Si pose une question avant de faire.',
            'If asks a question before doing.'),
        palette: palette,
        steps: [
          watchStep(
            'C7.3',
            'Tika saute le bloc quand la réponse est non.',
            'Tika skips the block when the answer is no.',
            '\$x = 3\n${figure(4, 50, 90)}\n'
                '${ifThen('\$x > 5', figure(3, 50, 120))}',
            ideas: ['guard', 'skip'],
          ),
          togetherStep(
            'C7.3',
            'Mets 3 dans \$x. Le triangle doit être sauté.',
            'Put 3 into \$x. The triangle has to be skipped.',
            assigns: 'x',
            hintFr: 'Écris \$x = 3 sur la première ligne.',
            hintEn: 'Write \$x = 3 on the first line.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C7.3',
            'Dessine une figure toujours. Ajoute-en une parfois.',
            'Draw one shape always. Add another sometimes.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'La seconde figure va dans les accolades du si.',
            hintEn: 'The second shape goes inside the if brackets.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C7.4',
        conceptName:
            b('Sinon garde l\'autre chemin.', 'Else keeps the other path.'),
        palette: palette,
        steps: [
          watchStep(
            'C7.4',
            'Tika prend un chemin ou l\'autre.',
            'Tika takes one path or the other.',
            '\$x = 2\n${ifElse('\$x > 5', figure(4, 50, 90), figure(3, 60, 120))}',
            ideas: ['else', 'one-path'],
          ),
          togetherStep(
            'C7.4',
            'Mets 2 dans \$x. Le triangle doit gagner.',
            'Put 2 into \$x. The triangle has to win.',
            assigns: 'x',
            hintFr: 'Écris \$x = 2. Le test sera faux.',
            hintEn: 'Write \$x = 2. The test will be false.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C7.4',
            'Fais deux figures. Une seule doit sortir.',
            'Make two shapes. Only one may come out.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Mets la seconde après le mot sinon.',
            hintEn: 'Put the second one after the word else.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C7.5',
        conceptName: b('Et veut les deux. Ou se contente d\'un.',
            'And wants both. Or takes one.'),
        palette: palette,
        steps: [
          watchStep(
            'C7.5',
            'Une seule moitié est vraie et ou suffit.',
            'Only one half is true and or is enough.',
            '\$a = 7\n\$b = 2\n'
                '${ifThen('\$a > 5 ou \$b > 5', figure(4, 55, 90))}',
            ideas: ['or', 'and'],
          ),
          togetherStep(
            'C7.5',
            'Mets 7 dans \$a et 2 dans \$b.',
            'Put 7 into \$a and 2 into \$b.',
            assigns: 'a',
            hintFr: 'Écris \$a = 7 puis \$b = 2.',
            hintEn: 'Write \$a = 7 then \$b = 2.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C7.5',
            'Fais un test à deux moitiés. Dessine si oui.',
            'Make a test with two halves. Draw if yes.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'et exige les deux. ou se contente d\'une.',
            hintEn: 'and demands both. or takes one.',
          ),
        ],
      ),
    ];

void main() {
  publishWorld(
    world: 7,
    nameKeys: b('Si… sinon', 'If… else'),
    conceptGraph: conceptGraph,
    committed: committed,
    items: [
      ...conceptC71(),
      ...conceptC72(),
      ...conceptC73(),
      ...conceptC74(),
      ...conceptC75(),
    ],
    tutorials: world7Tutorials(),
    assetKeys: const ['art/tika.svg', 'art/world7-si.svg'],
  );
}
