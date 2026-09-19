// Authors World 9 — "Mes propres blocs" — and writes it out as a content pack.
//
//     dart tool/author_world9.dart
//
// Up to here the child has used the words KODO gave them. World 9 lets them add words of
// their own, and the four misconceptions in the ledger are four ways of not yet believing
// that a name can be a thing:
//
//   C9.1  "defining a block runs it"
//   C9.2  "the parameter name is the value"
//   C9.3  "return prints the value"
//   C9.4  "a big program must be written in one piece"
//
// Three of the four are refuted by the language rather than by an explanation, and the
// items are built on those refutations:
//
//  * `apprends carré { … }` on its own draws **nothing**. A definition is a promise, not
//    an action, and the empty canvas says so louder than a sentence would.
//  * a parameter is local: `apprends c $a { avance $a }` then `écris $a` stops with
//    "je ne connais pas $a". The name lived inside the block and left with it.
//  * `retourne` hands a value back and prints nothing. `double 7` on its own line is a
//    program with no output at all, and `écris double 7` is the one that shows 14.
//
// The authoring rule that runs through the world is the one Worlds 5 to 8 each found in
// their own costume: **a procedure is invisible on the canvas.** `carré 60` draws exactly
// what its body drawn inline draws, so every item whose point is the block carries
// `DefinesProcedure`, and the inlined distractor is there to prove it fires.

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';

import 'authoring.dart';

const conceptGraph = <String, List<String>>{
  'C9.1': ['C2.3'],
  'C9.2': ['C9.1'],
  'C9.3': ['C9.2'],
  'C9.4': ['C9.2'],
};

/// §6.3's commitment, copied from `spec/concepts.json` and checked against it by
/// `publishWorld`.
const committed = <String, int>{
  'C9.1': 24,
  'C9.2': 24,
  'C9.3': 22,
  'C9.4': 22,
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
];

/// A closed figure.
String figure(int sides, int side, int turn) =>
    'répète $sides {\n  avance $side\n  tournedroite $turn\n}';

/// `apprends <name> { <body> }`, or with parameters when [params] is given.
String learn(String name, String body, {String params = ''}) =>
    'apprends $name${params.isEmpty ? '' : ' $params'} {\n'
    '${body.split('\n').map((l) => '  $l').join('\n')}\n}';

/// The body of a closed figure whose side is a parameter.
String sidedBody(int sides, String sideExpr, int turn) =>
    'répète $sides {\n  avance $sideExpr\n  tournedroite $turn\n}';

// ═══════════════════════════════════════════════════════════════════════════════════════
// C9.1 — Apprends un nouveau bloc.
// Misconception: "defining a block runs it".
//
// The refutation is an empty canvas, and it is authored as one: several distractors here
// are programs that define a block beautifully and then never call it. They draw nothing,
// the grader says "il en manque", and the child learns the difference between teaching
// Tika a word and asking her to use it.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC91() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C9.1-${(++n).toString().padLeft(2, '0')}';

  /* T1 — teach a block, then use it. Three distractors, and the first two are the two
     halves of the misconception: defined and never called, called and never defined
     (which is the body written straight out). */
  for (final entry in [
    ('carré', 4, 60, 90, 2),
    ('triangle', 3, 80, 120, 3),
    ('hexagone', 6, 45, 60, 2),
    ('losange', 4, 55, 60, 3),
    ('étoile', 5, 70, 144, 2),
    ('dent', 3, 50, 120, 4),
  ]) {
    final name = entry.$1,
        sides = entry.$2,
        side = entry.$3,
        turn = entry.$4,
        calls = entry.$5;
    final body = figure(sides, side, turn);
    final between = 'tournedroite ${360 ~/ calls}';
    final uses = List.filled(calls, name).join('\n$between\n');
    final solution = '${learn(name, body)}\n$uses';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C9.1',
      difficulty: Difficulty.d3,
      solution: solution,
      promptKeys: fillBoth(
        b(
            'Apprends à Tika un bloc appelé {n} qui dessine la figure à {k} '
                'côtés, puis sers-t\'en {c} fois.',
            'Teach Tika a block called {n} that draws the {k}-sided shape, '
                'then use it {c} times.'),
        {'n': name, 'k': sides, 'c': calls},
      ),
      wrong: [
        // Taught and never asked for: the canvas stays empty.
        learn(name, body),
        // The body written out instead, as many times as it is needed.
        List.filled(calls, body).join('\n$between\n'),
        // Used once too few.
        '${learn(name, body)}\n'
            '${List.filled(calls - 1, name).join('\n$between\n')}',
      ],
      assertions: [
        const DefinesProcedure(),
        ContainsNode('ProcCall', min: calls),
      ],
      alternatives: [
        '# un bloc appris, puis utilisé\n$solution',
        solution.replaceFirst('apprends $name {', 'apprends $name  {'),
      ],
      itemHints: hints(
        'Apprendre un bloc ne le fait pas tout de suite.',
        'Teaching a block does not run it straight away.',
        'Écris son nom pour t\'en servir.',
        'Write its name to use it.',
      ),
      paletteScope: palette,
    ));
  }

  // T4 — the hole is the line that asks for the block.
  for (final entry in [
    ('carré', 4, 60, 90),
    ('triangle', 3, 80, 120),
    ('hexagone', 6, 45, 60),
    ('losange', 4, 55, 60),
    ('dent', 3, 50, 120),
  ]) {
    final name = entry.$1, sides = entry.$2, side = entry.$3, turn = entry.$4;
    final body = figure(sides, side, turn);
    final solution = '${learn(name, body)}\n$name\ntournedroite 180\n$name';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C9.1',
      difficulty: Difficulty.d2,
      withHoles: '${learn(name, body)}\n___\ntournedroite 180\n___',
      solution: solution,
      promptKeys: fillBoth(
        b('Le bloc {n} est appris. Complète pour t\'en servir deux fois.',
            'The block {n} is taught. Fill in the blanks to use it twice.'),
        {'n': name},
      ),
      wrong: [
        '${learn(name, body)}\ntournedroite 180',
        '${learn(name, body)}\n$name\ntournedroite 180',
        '${learn(name, body)}\n$body\ntournedroite 180\n$body',
      ],
      assertions: [
        const DefinesProcedure(),
        const ContainsNode('ProcCall', min: 2),
      ],
      alternatives: [
        '# deux fois le même bloc\n$solution',
        solution.replaceFirst('apprends $name {', 'apprends $name  {'),
      ],
      itemHints: hints(
        'Pour se servir d\'un bloc, on écrit son nom.',
        'To use a block, you write its name.',
        'Écris $name sur chaque ligne vide.',
        'Write $name on each empty line.',
      ),
      paletteScope: palette,
    ));
  }

  // T5 — Parsons. The definition has to come before the first use.
  for (final entry in [
    ('carré', 4, 60, 90),
    ('triangle', 3, 80, 120),
    ('hexagone', 6, 45, 60),
    ('étoile', 5, 70, 144),
  ]) {
    final name = entry.$1, sides = entry.$2, side = entry.$3, turn = entry.$4;
    final body = figure(sides, side, turn);
    final solution = '${learn(name, body)}\n$name\ntournedroite 120\n$name';
    items.add(parsons(
      id: id(),
      conceptId: 'C9.1',
      difficulty: Difficulty.d3,
      solution: solution,
      promptKeys: fillBoth(
        b('Remets en ordre : apprends {n}, puis sers-t\'en deux fois.',
            'Put it back in order: teach {n}, then use it twice.'),
        {'n': name},
      ),
      wrong: [
        learn(name, body),
        '${learn(name, body)}\n$name\ntournedroite 120',
        '${learn(name, body)}\ntournedroite 120\n$name',
      ],
      assertions: [
        const DefinesProcedure(),
        const ContainsNode('ProcCall', min: 2),
      ],
      alternatives: [
        '# appris d\'abord, utilisé ensuite\n$solution',
        solution.replaceFirst('apprends $name {', 'apprends $name  {'),
      ],
      itemHints: hints(
        'On apprend un mot avant de s\'en servir.',
        'You learn a word before you use it.',
        'La définition monte en haut.',
        'The definition goes at the top.',
      ),
      paletteScope: palette,
    ));
  }

  /* T7 — golf, and the budget is where the block earns its keep. Three figures of three
     different sizes cannot be a `répète`, so the only way under the budget is a block
     with a number in it. */
  for (final entry in [
    ('carré', 4, 90, [30, 50, 70], 7),
    ('triangle', 3, 120, [40, 60, 80], 7),
    ('hexagone', 6, 60, [25, 40, 55], 7),
    ('losange', 4, 60, [35, 55, 75], 7),
  ]) {
    final name = entry.$1,
        sides = entry.$2,
        turn = entry.$3,
        sizes = entry.$4,
        budget = entry.$5;
    final solution = '${learn(name, sidedBody(sides, '\$c', turn), params: '\$c')}\n'
        '${sizes.map((s) => '$name $s').join('\n')}';
    items.add(golf(
      id: id(),
      conceptId: 'C9.1',
      difficulty: Difficulty.d4,
      solution: solution,
      budget: budget,
      promptKeys: fillBoth(
        b(
            'Dessine les trois figures de {a}, {b} et {c} pas en {k} blocs au maximum.',
            'Draw the three shapes of {a}, {b} and {c} steps in {k} blocks or fewer.'),
        {'a': sizes[0], 'b': sizes[1], 'c': sizes[2], 'k': budget},
      ),
      wrong: [
        // The long way: right picture, nine blocks.
        sizes.map((s) => figure(sides, s, turn)).join('\n'),
        // Under budget, wrong sizes.
        '${learn(name, sidedBody(sides, '\$c', turn), params: '\$c')}\n'
            '${sizes.map((s) => '$name ${s + 10}').join('\n')}',
        // Under budget, one figure short.
        '${learn(name, sidedBody(sides, '\$c', turn), params: '\$c')}\n'
            '${sizes.take(2).map((s) => '$name $s').join('\n')}',
      ],
      assertions: [
        const DefinesProcedure(),
        const ContainsNode('ProcCall', min: 3),
      ],
      alternatives: [
        '# un bloc, trois tailles\n$solution',
        solution.replaceFirst('apprends $name \$c {', 'apprends $name \$c  {'),
      ],
      itemHints: hints(
        'Trois figures qui se ressemblent, une seule idée.',
        'Three shapes that look alike, one idea.',
        'Apprends un bloc qui prend la taille.',
        'Teach a block that takes the size.',
      ),
      paletteScope: palette,
    ));
  }

  // T9 — five open builds.
  for (final entry in [
    ('Apprends un bloc et sers-t\'en trois fois.',
        'Teach a block and use it three times.', 3),
    ('Apprends un bloc qui dessine ta figure préférée.',
        'Teach a block that draws your favourite shape.', 2),
    ('Fais une fleur avec un bloc pétale.',
        'Make a flower with a petal block.', 4),
    ('Fais une frise avec un bloc que tu répètes.',
        'Make a border with a block you repeat.', 3),
    ('Apprends deux blocs et sers-toi des deux.',
        'Teach two blocks and use both.', 2),
  ]) {
    final minCalls = entry.$3;
    final twoBlocks = entry.$1.startsWith('Apprends deux');
    items.add(openBuild(
      id: id(),
      conceptId: 'C9.1',
      difficulty: Difficulty.d3,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine(
            twoBlocks
                ? 'Tu apprends deux blocs à Tika.'
                : 'Tu apprends un bloc à Tika.',
            twoBlocks
                ? 'You teach Tika two blocks.'
                : 'You teach Tika one block.',
            DefinesProcedure(min: twoBlocks ? 2 : 1)),
        rubricLine('Tu t\'en sers au moins $minCalls fois.',
            'You use it at least $minCalls times.',
            ContainsNode('ProcCall', min: minCalls)),
        rubricLine('Tika dessine quelque chose.', 'Tika draws something.',
            const UsesOpcode('MOVE_FORWARD')),
      ],
      itemHints: hints(
        'Commence par apprends et un nom.',
        'Start with learn and a name.',
        'Écris ensuite ce nom pour t\'en servir.',
        'Then write that name to use it.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C9.2 — Paramètres.
// Misconception: "the parameter name is the value".
//
// A parameter is a box that the *call* fills, and the language proves both halves of that
// on its own. `carré 40` then `carré 80` runs one block twice and draws two different
// squares, which is the box being refilled. And `apprends c $a { avance $a }` followed by
// `écris $a` stops with "je ne connais pas $a", which is the box going away again — the
// name lived inside the block and left with it.
//
// The structural claim needs World 6's extended `UsesVariable` with `min: 0`: a parameter
// is *read* like a box but never *assigned*, so an assertion that demands a write would
// fail every correct answer in this concept.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC92() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C9.2-${(++n).toString().padLeft(2, '0')}';

  /// Reads the parameter, never writes it. `min: 0` is the whole point.
  UsesVariable reads(String name) =>
      UsesVariable(name: name, min: 0, minReads: 1);

  /* T1 — one block, two sizes. The first distractor is the same block with the number
     baked in: two identical figures where the target has two different ones, which is the
     misconception drawn. */
  for (final entry in [
    ('carré', 'côté', 4, 90, 40, 80),
    ('triangle', 'côté', 3, 120, 50, 90),
    ('hexagone', 'taille', 6, 60, 30, 55),
    ('losange', 'bord', 4, 60, 45, 75),
    ('dent', 'long', 3, 120, 35, 70),
  ]) {
    final name = entry.$1,
        param = entry.$2,
        sides = entry.$3,
        turn = entry.$4,
        small = entry.$5,
        big = entry.$6;
    final body = sidedBody(sides, '\$$param', turn);
    final solution = '${learn(name, body, params: '\$$param')}\n'
        '$name $small\ntournedroite 180\n$name $big';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C9.2',
      difficulty: Difficulty.d3,
      solution: solution,
      promptKeys: fillBoth(
        b(
            'Apprends un bloc {n} qui prend une taille, puis dessine-le à {a} '
                'puis à {b} pas.',
            'Teach a block {n} that takes a size, then draw it at {a} and then '
                'at {b} steps.'),
        {'n': name, 'a': small, 'b': big},
      ),
      wrong: [
        // The size baked in: two identical figures.
        '${learn(name, sidedBody(sides, '$small', turn), params: '\$$param')}\n'
            '$name $small\ntournedroite 180\n$name $big',
        // The bodies written out, with no block at all.
        '${figure(sides, small, turn)}\ntournedroite 180\n'
            '${figure(sides, big, turn)}',
        // Both calls the same size.
        '${learn(name, body, params: '\$$param')}\n'
            '$name $small\ntournedroite 180\n$name $small',
      ],
      assertions: [
        const DefinesProcedure(),
        const ContainsNode('ProcCall', min: 2),
        reads(param),
      ],
      alternatives: [
        '# un bloc, deux tailles\n$solution',
        solution.replaceFirst(
            'apprends $name \$$param {', 'apprends $name \$$param  {'),
      ],
      itemHints: hints(
        'Le nombre voyage du nom vers le bloc.',
        'The number travels from the name into the block.',
        'Sers-toi de \$$param dans le corps.',
        'Use \$$param inside the body.',
      ),
      paletteScope: palette,
    ));
  }

  /* T2 — five bugs, all the same one: the block takes a size and then ignores it. The
     figures come out identical, which is what a parameter nobody reads looks like. */
  for (final entry in [
    ('carré', 'côté', 4, 90, 40, 80),
    ('triangle', 'côté', 3, 120, 50, 90),
    ('hexagone', 'taille', 6, 60, 30, 55),
    ('losange', 'bord', 4, 60, 45, 75),
    ('étoile', 'rayon', 5, 144, 40, 70),
  ]) {
    final name = entry.$1,
        param = entry.$2,
        sides = entry.$3,
        turn = entry.$4,
        small = entry.$5,
        big = entry.$6;
    final body = sidedBody(sides, '\$$param', turn);
    final calls = '$name $small\ntournedroite 180\n$name $big';
    final solution = '${learn(name, body, params: '\$$param')}\n$calls';
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C9.2',
      difficulty: Difficulty.d3,
      broken: '${learn(name, sidedBody(sides, '$small', turn), params: '\$$param')}\n$calls',
      solution: solution,
      promptKeys: fillBoth(
        b(
            'Les deux figures sortent pareilles. Le bloc reçoit la taille mais '
                'ne s\'en sert pas. La seconde doit faire {b} pas.',
            'Both shapes come out the same. The block is given the size but '
                'never uses it. The second one should be {b} steps.'),
        {'b': big},
      ),
      wrong: [
        '${learn(name, sidedBody(sides, '$big', turn), params: '\$$param')}\n$calls',
        '${figure(sides, small, turn)}\ntournedroite 180\n${figure(sides, big, turn)}',
        '${learn(name, body, params: '\$$param')}\n'
            '$name $big\ntournedroite 180\n$name $small',
      ],
      assertions: [
        const DefinesProcedure(),
        const ContainsNode('ProcCall', min: 2),
        reads(param),
      ],
      alternatives: [
        '# le bloc lit enfin sa taille\n$solution',
        solution.replaceFirst(
            'apprends $name \$$param {', 'apprends $name \$$param  {'),
      ],
      itemHints: hints(
        'Regarde ce que fait avance dans le bloc.',
        'Look at what forward does inside the block.',
        'Il devrait lire \$$param.',
        'It should read \$$param.',
      ),
      paletteScope: palette,
    ));
  }

  // T4 — the hole is where the parameter is spent.
  for (final entry in [
    ('carré', 'côté', 4, 90, 40, 80),
    ('triangle', 'côté', 3, 120, 50, 90),
    ('hexagone', 'taille', 6, 60, 30, 55),
    ('losange', 'bord', 4, 60, 45, 75),
    ('dent', 'long', 3, 120, 35, 70),
  ]) {
    final name = entry.$1,
        param = entry.$2,
        sides = entry.$3,
        turn = entry.$4,
        small = entry.$5,
        big = entry.$6;
    final body = sidedBody(sides, '\$$param', turn);
    final calls = '$name $small\ntournedroite 180\n$name $big';
    final solution = '${learn(name, body, params: '\$$param')}\n$calls';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C9.2',
      difficulty: Difficulty.d3,
      withHoles:
          '${learn(name, sidedBody(sides, '___', turn), params: '\$$param')}\n$calls',
      solution: solution,
      promptKeys: fillBoth(
        b('Complète pour que le bloc se serve de la taille qu\'on lui donne.',
            'Fill in the blank so the block uses the size it is given.'),
        {'n': name},
      ),
      wrong: [
        '${learn(name, sidedBody(sides, '$small', turn), params: '\$$param')}\n$calls',
        '${learn(name, sidedBody(sides, '$big', turn), params: '\$$param')}\n$calls',
        '${learn(name, sidedBody(sides, '\$$param * 2', turn), params: '\$$param')}\n$calls',
      ],
      assertions: [
        const DefinesProcedure(),
        const ContainsNode('ProcCall', min: 2),
        reads(param),
      ],
      alternatives: [
        '# la taille vient du nom\n$solution',
        solution.replaceFirst(
            'apprends $name \$$param {', 'apprends $name \$$param  {'),
      ],
      itemHints: hints(
        'La taille est arrivée dans une boîte.',
        'The size arrived in a box.',
        'Elle s\'appelle \$$param.',
        'It is called \$$param.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(
        'Dans apprends carré \$côté { … }, qu\'est-ce que \$côté ?',
        r'In learn square $side { … }, what is $side?'),
    choices: [
      Choice(
          labelKeys: b('Une boîte que remplit celui qui appelle le bloc.',
              'A box filled by whoever calls the block.'),
          correct: true),
      Choice(
          labelKeys: b('Le mot « côté ».', 'The word "side".'),
          correct: false,
          misconception: 'C9.2-parameter-is-its-name'),
      Choice(
          labelKeys: b('Un nombre fixé une fois pour toutes.',
              'A number fixed once and for all.'),
          correct: false,
          misconception: 'C9.2-parameter-is-a-constant'),
      Choice(
          labelKeys: b('Le nom du bloc.', 'The name of the block.'),
          correct: false,
          misconception: 'C9.2-parameter-is-the-block'),
    ],
    itemHints: hints(
      'Appelle le bloc deux fois avec deux nombres.',
      'Call the block twice with two numbers.',
      'La boîte n\'a pas le même contenu les deux fois.',
      'The box does not hold the same thing both times.',
    ),
    wrongChoiceFr:
        'Le nombre écrit à l\'appel entre dans la boîte du bloc.',
    wrongChoiceEn:
        'The number written at the call goes into the block\'s box.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        r'Après apprends c $a { avance $a } et c 50, que vaut $a dehors ?',
        r'After learn c $a { forward $a } and c 50, what is $a outside?'),
    choices: [
      Choice(
          labelKeys: b('Rien : la boîte n\'existe que dans le bloc.',
              'Nothing: the box only exists inside the block.'),
          correct: true),
      Choice(
          labelKeys: b('50', '50'),
          correct: false,
          misconception: 'C9.2-parameter-escapes'),
      Choice(
          labelKeys: b('0', '0'),
          correct: false,
          misconception: 'C6.1-box-is-empty'),
      Choice(
          labelKeys: b('Le mot « a ».', 'The word "a".'),
          correct: false,
          misconception: 'C9.2-parameter-is-its-name'),
    ],
    itemHints: hints(
      'La boîte est arrivée avec l\'appel.',
      'The box arrived with the call.',
      'Elle repart avec lui.',
      'It leaves with it too.',
    ),
    wrongChoiceFr:
        'Une boîte de bloc naît à l\'appel et disparaît à la fin du bloc.',
    wrongChoiceEn:
        'A block\'s box is born at the call and gone when the block ends.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(
        'Pourquoi donner une taille au bloc plutôt que l\'écrire dedans ?',
        r'Why give the block a size instead of writing it inside?'),
    choices: [
      Choice(
          labelKeys: b('Pour dessiner plusieurs tailles avec un seul bloc.',
              'To draw several sizes with one block.'),
          correct: true),
      Choice(
          labelKeys: b('Parce qu\'un bloc doit avoir un nombre.',
              'Because a block has to have a number.'),
          correct: false,
          misconception: 'C9.2-parameter-is-compulsory'),
      Choice(
          labelKeys: b('Pour que le bloc aille plus vite.',
              'To make the block faster.'),
          correct: false,
          misconception: 'C6.1-box-is-speed'),
      Choice(
          labelKeys: b('Ça revient au même.', 'It comes to the same thing.'),
          correct: false,
          misconception: 'C9.2-parameter-is-a-constant'),
    ],
    itemHints: hints(
      'Imagine trois carrés de trois tailles.',
      'Imagine three squares of three sizes.',
      'Un seul bloc suffit si on lui dit la taille.',
      'One block is enough if you tell it the size.',
    ),
    wrongChoiceFr:
        'Une taille donnée à l\'appel rend le bloc utile à plusieurs endroits.',
    wrongChoiceEn:
        'A size given at the call makes one block useful in several places.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        r'Le bloc prend $côté mais son corps écrit avance 60. Que se passe-t-il ?',
        r'The block takes $side but its body says forward 60. What happens?'),
    choices: [
      Choice(
          labelKeys: b('Toutes les figures font 60, quelle que soit la taille donnée.',
              'Every shape is 60, whatever size you give.'),
          correct: true),
      Choice(
          labelKeys: b('Tika refuse le programme.',
              'Tika refuses the program.'),
          correct: false,
          misconception: 'C9.2-unused-parameter-is-an-error'),
      Choice(
          labelKeys: b('Le 60 devient la taille donnée.',
              'The 60 becomes the size given.'),
          correct: false,
          misconception: 'C9.2-parameter-replaces-literals'),
      Choice(
          labelKeys: b('La première figure fait 60, les autres non.',
              'The first shape is 60, the others are not.'),
          correct: false,
          misconception: 'C9.2-parameter-is-a-constant'),
    ],
    itemHints: hints(
      'La boîte est remplie, mais personne ne l\'ouvre.',
      'The box is filled, but nobody opens it.',
      'Le corps se sert du 60 écrit à la main.',
      'The body uses the 60 typed by hand.',
    ),
    wrongChoiceFr:
        'Une boîte qu\'on ne lit pas ne change rien au dessin.',
    wrongChoiceEn:
        'A box nobody reads changes nothing in the drawing.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(r'Un bloc peut-il prendre deux nombres ?',
        r'Can a block take two numbers?'),
    choices: [
      Choice(
          labelKeys: b('Oui, séparés par une virgule.',
              'Yes, separated by a comma.'),
          correct: true),
      Choice(
          labelKeys: b('Non, un seul.', 'No, only one.'),
          correct: false,
          misconception: 'C9.2-one-parameter-only'),
      Choice(
          labelKeys: b('Oui, mais ils valent la même chose.',
              'Yes, but they hold the same thing.'),
          correct: false,
          misconception: 'C9.2-parameters-share-a-box'),
      Choice(
          labelKeys: b('Non, il faut deux blocs.', 'No, you need two blocks.'),
          correct: false,
          misconception: 'C9.2-one-parameter-only'),
    ],
    itemHints: hints(
      'Pense à un rectangle : largeur et hauteur.',
      'Think of a rectangle: width and height.',
      'Deux boîtes, deux noms, une virgule.',
      'Two boxes, two names, one comma.',
    ),
    wrongChoiceFr:
        'Un bloc peut prendre autant de boîtes qu\'il lui en faut.',
    wrongChoiceEn:
        'A block can take as many boxes as it needs.',
  ));

  // T9 — four open builds.
  for (final entry in [
    ('Apprends un bloc qui prend une taille. Sers-t\'en à trois tailles.',
        'Teach a block that takes a size. Use it at three sizes.', 1, 3),
    ('Apprends un bloc qui prend deux nombres.',
        'Teach a block that takes two numbers.', 2, 2),
    ('Fais une cible avec un bloc qui grandit.',
        'Make a target with a block that grows.', 1, 3),
    ('Fais une frise avec un bloc qui prend une taille.',
        'Make a border with a block that takes a size.', 1, 3),
  ]) {
    final params = entry.$3, minCalls = entry.$4;
    items.add(openBuild(
      id: id(),
      conceptId: 'C9.2',
      difficulty: Difficulty.d3,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine('Tu apprends un bloc à Tika.', 'You teach Tika a block.',
            const DefinesProcedure()),
        rubricLine(
            params == 2
                ? 'Le bloc lit ses deux boîtes.'
                : 'Le bloc lit la boîte qu\'on lui donne.',
            params == 2
                ? 'The block reads both its boxes.'
                : 'The block reads the box it is given.',
            UsesVariable(min: 0, minReads: params)),
        rubricLine('Tu t\'en sers au moins $minCalls fois.',
            'You use it at least $minCalls times.',
            ContainsNode('ProcCall', min: minCalls)),
        rubricLine('Tika dessine quelque chose.', 'Tika draws something.',
            const UsesOpcode('MOVE_FORWARD')),
      ],
      itemHints: hints(
        'Écris le nom de la boîte après le nom du bloc.',
        'Write the box name after the block name.',
        'Sers-t\'en dans le corps avec le \$.',
        'Use it in the body with the \$.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C9.3 — Retourne.
// Misconception: "return prints the value".
//
// `écris` shows a number to the child. `retourne` hands it back to the program. They are
// not two words for the same thing, and the difference is the difference between a block
// you can *use in a sum* and one you can only watch.
//
// The item that carries the concept is the one where a returning block is spent on the
// spot: `avance double 30` draws a line of sixty. Write `écris` in the block instead of
// `retourne` and the same program stops with "ce n'est pas une valeur" — because a block
// that prints has nothing to give. That error is authored as the bug, five times.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC93() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C9.3-${(++n).toString().padLeft(2, '0')}';

  /* T2 — five blocks that print where they should hand back. Each broken program stops
     rather than drawing something wrong, which is the cleanest way this concept can be
     shown to be about values rather than about output. */
  for (final entry in [
    ('double', 'x', '\$x * 2', 30, 60),
    ('moitié', 'x', '\$x / 2', 120, 60),
    ('plusdix', 'x', '\$x + 10', 40, 50),
    ('triple', 'x', '\$x * 3', 25, 75),
    ('moins', 'x', '\$x - 15', 80, 65),
  ]) {
    final name = entry.$1,
        param = entry.$2,
        expression = entry.$3,
        argument = entry.$4,
        result = entry.$5;
    final solution =
        '${learn(name, 'retourne $expression', params: '\$$param')}\n'
        'avance $name $argument';
    items.add(fixTheBug(
      id: id(),
      conceptId: 'C9.3',
      difficulty: Difficulty.d3,
      broken: '${learn(name, 'écris $expression', params: '\$$param')}\n'
          'avance $name $argument',
      solution: solution,
      promptKeys: fillBoth(
        b(
            'Tika dit que {n} n\'est pas une valeur. Le bloc doit rendre le '
                'nombre, pas l\'afficher. Le trait doit faire {r} pas.',
            'Tika says {n} is not a value. The block has to hand the number '
                'back, not show it. The line should be {r} steps.'),
        {'n': name, 'r': result},
      ),
      wrong: [
        'avance $result',
        '${learn(name, 'retourne \$$param', params: '\$$param')}\n'
            'avance $name $argument',
        '${learn(name, 'retourne $expression', params: '\$$param')}\n'
            'écris $name $argument',
      ],
      assertions: [
        const DefinesProcedure(),
        const ContainsNode('Return'),
      ],
      alternatives: [
        '# le bloc rend son nombre\n$solution',
        solution.replaceFirst(
            'apprends $name \$$param {', 'apprends $name \$$param  {'),
      ],
      itemHints: hints(
        'écris montre un nombre à toi.',
        'print shows a number to you.',
        'retourne le rend au programme.',
        'return hands it back to the program.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — what does the program write? The answer is "rien" more often than a child
     expects, because a block that returns and is never printed shows nothing at all. */
  for (final entry in [
    ('retourne \$x * 2', 'double 7', 'rien', 'nothing', '14', 'C9.3-return-prints'),
    ('écris \$x * 2', 'double 7', '14', '14', 'rien', 'C9.3-print-returns'),
    ('retourne \$x * 2', 'écris double 7', '14', '14', 'rien', 'C9.3-return-prints'),
    ('retourne \$x + 1', 'écris double double 3', '5', '5', '4', 'C9.3-nested-call-runs-once'),
    ('écris \$x + 1', 'double 3\ndouble 5', '4 puis 6', '4 then 6', '10', 'C9.3-print-returns'),
  ]) {
    final body = entry.$1, use = entry.$2, fr = entry.$3, en = entry.$4;
    items.add(predict(
      id: id(),
      conceptId: 'C9.3',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Qu\'est-ce que le programme écrit ?\n\napprends double \$x {{\n  {b}\n}}\n{u}',
            'What does the program write?\n\nlearn double \$x {{\n  {b}\n}}\n{u}'),
        {'b': body, 'u': use},
      ),
      choices: [
        Choice(labelKeys: b(fr, en), correct: true),
        Choice(
            labelKeys: b(entry.$5, entry.$5 == 'rien' ? 'nothing' : entry.$5),
            correct: false,
            misconception: entry.$6),
        Choice(
            labelKeys: b('le nom du bloc', 'the name of the block'),
            correct: false,
            misconception: 'C9.2-parameter-is-its-name'),
        Choice(
            labelKeys: b('une erreur', 'an error'),
            correct: false,
            misconception: 'C9.3-return-is-an-error'),
      ],
      itemHints: hints(
        'Seul écris met quelque chose à l\'écran.',
        'Only print puts something on the screen.',
        'retourne rend le nombre sans le montrer.',
        'return hands the number back without showing it.',
      ),
      wrongChoiceFr:
          'retourne rend un nombre au programme ; écris le montre à l\'enfant.',
      wrongChoiceEn:
          'return hands a number back to the program; print shows it to the child.',
    ));
  }

  // T4 — the hole is the word that hands the number back.
  for (final entry in [
    ('double', '\$x * 2', 30, 60),
    ('moitié', '\$x / 2', 120, 60),
    ('plusdix', '\$x + 10', 40, 50),
    ('triple', '\$x * 3', 25, 75),
  ]) {
    final name = entry.$1, expression = entry.$2, argument = entry.$3;
    final solution =
        '${learn(name, 'retourne $expression', params: '\$x')}\n'
        'avance $name $argument';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C9.3',
      difficulty: Difficulty.d3,
      withHoles: '${learn(name, '___ $expression', params: '\$x')}\n'
          'avance $name $argument',
      solution: solution,
      promptKeys: b('Complète pour que le bloc rende son nombre au programme.',
          'Fill in the blank so the block hands its number back to the program.'),
      wrong: [
        '${learn(name, 'écris $expression', params: '\$x')}\n'
            'avance $name $argument',
        '${learn(name, 'avance $expression', params: '\$x')}\n'
            'avance $name $argument',
        '${learn(name, 'retourne \$x', params: '\$x')}\n'
            'avance $name $argument',
      ],
      assertions: [
        const DefinesProcedure(),
        const ContainsNode('Return'),
      ],
      alternatives: [
        '# rendre, pas afficher\n$solution',
        solution.replaceFirst('apprends $name \$x {', 'apprends $name \$x  {'),
      ],
      itemHints: hints(
        'Le bloc doit donner son nombre à avance.',
        'The block has to give its number to forward.',
        'C\'est retourne.',
        'It is return.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait retourne ?', 'What does return do?'),
    choices: [
      Choice(
          labelKeys: b('Il rend un nombre à celui qui a appelé le bloc.',
              'It hands a number back to whoever called the block.'),
          correct: true),
      Choice(
          labelKeys: b('Il affiche le nombre.', 'It shows the number.'),
          correct: false,
          misconception: 'C9.3-return-prints'),
      Choice(
          labelKeys: b('Il recommence le bloc.', 'It starts the block again.'),
          correct: false,
          misconception: 'C9.3-return-restarts'),
      Choice(
          labelKeys: b('Il range le nombre dans une boîte.',
              'It puts the number in a box.'),
          correct: false,
          misconception: 'C9.3-return-assigns'),
    ],
    itemHints: hints(
      'Pense à rendre un objet à quelqu\'un.',
      'Think of handing something back to someone.',
      'Le programme peut s\'en servir ensuite.',
      'The program can then use it.',
    ),
    wrongChoiceFr:
        'retourne donne le nombre au programme, qui peut le dépenser.',
    wrongChoiceEn:
        'return gives the number to the program, which can spend it.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Quelle est la différence entre écris et retourne ?',
        'What is the difference between print and return?'),
    choices: [
      Choice(
          labelKeys: b('écris montre, retourne donne.',
              'print shows, return gives.'),
          correct: true),
      Choice(
          labelKeys: b('Aucune : les deux affichent.',
              'None: both show it.'),
          correct: false,
          misconception: 'C9.3-return-prints'),
      Choice(
          labelKeys: b('retourne est plus rapide.',
              'return is faster.'),
          correct: false,
          misconception: 'C6.1-box-is-speed'),
      Choice(
          labelKeys: b('écris ne marche pas dans un bloc.',
              'print does not work inside a block.'),
          correct: false,
          misconception: 'C9.3-print-is-banned'),
    ],
    itemHints: hints(
      'L\'un s\'adresse à toi.',
      'One of them talks to you.',
      'L\'autre s\'adresse au programme.',
      'The other talks to the program.',
    ),
    wrongChoiceFr:
        'écris est pour l\'enfant ; retourne est pour la ligne qui suit.',
    wrongChoiceEn:
        'print is for the child; return is for the line that follows.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Un bloc écrit son résultat au lieu de le rendre. Tu fais avance bloc 30. Que se passe-t-il ?',
        'A block prints its answer instead of handing it back. You write forward block 30. What happens?'),
    choices: [
      Choice(
          labelKeys: b('Tika s\'arrête : il n\'y a pas de nombre à avancer.',
              'Tika stops: there is no number to move by.'),
          correct: true),
      Choice(
          labelKeys: b('Elle avance du nombre affiché.',
              'She moves by the number shown.'),
          correct: false,
          misconception: 'C9.3-return-prints'),
      Choice(
          labelKeys: b('Elle avance de 30.', 'She moves 30.'),
          correct: false,
          misconception: 'C9.3-call-is-its-argument'),
      Choice(
          labelKeys: b('Elle avance de 0.', 'She moves 0.'),
          correct: false,
          misconception: 'C6.1-box-is-empty'),
    ],
    itemHints: hints(
      'Ce qui est affiché ne revient pas au programme.',
      'What is shown does not come back to the program.',
      'avance attend un nombre et n\'en reçoit aucun.',
      'forward wants a number and gets none.',
    ),
    wrongChoiceFr:
        'Un bloc qui affiche ne rend rien, et avance n\'a rien à dépenser.',
    wrongChoiceEn:
        'A block that shows hands nothing back, and forward has nothing to spend.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(r'Où peut-on se servir de double 7 si double retourne ?',
        r'Where can double 7 be used if double returns?'),
    choices: [
      Choice(
          labelKeys: b('Partout où l\'on peut écrire un nombre.',
              'Anywhere you could write a number.'),
          correct: true),
      Choice(
          labelKeys: b('Seulement après écris.', 'Only after print.'),
          correct: false,
          misconception: 'C9.3-return-prints'),
      Choice(
          labelKeys: b('Seulement sur sa propre ligne.',
              'Only on a line of its own.'),
          correct: false,
          misconception: 'C9.3-call-is-a-statement-only'),
      Choice(
          labelKeys: b('Seulement dans un autre bloc.',
              'Only inside another block.'),
          correct: false,
          misconception: 'C9.3-call-is-a-statement-only'),
    ],
    itemHints: hints(
      'Un bloc qui rend un nombre vaut ce nombre.',
      'A block that hands a number back is worth that number.',
      'avance, répète, un calcul : partout.',
      'forward, repeat, a sum: anywhere.',
    ),
    wrongChoiceFr:
        'Un appel qui rend un nombre s\'écrit là où un nombre s\'écrirait.',
    wrongChoiceEn:
        'A call that hands a number back goes where a number would go.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Que fait la ligne double 7 toute seule ?',
        'What does the line double 7 do on its own?'),
    choices: [
      Choice(
          labelKeys: b('Elle calcule et jette le résultat.',
              'It works the answer out and throws it away.'),
          correct: true),
      Choice(
          labelKeys: b('Elle affiche 14.', 'It shows 14.'),
          correct: false,
          misconception: 'C9.3-return-prints'),
      Choice(
          labelKeys: b('Elle range 14 quelque part.',
              'It stores 14 somewhere.'),
          correct: false,
          misconception: 'C9.3-return-assigns'),
      Choice(
          labelKeys: b('Elle provoque une erreur.', 'It causes an error.'),
          correct: false,
          misconception: 'C9.3-return-is-an-error'),
    ],
    itemHints: hints(
      'Personne n\'attrape ce que le bloc rend.',
      'Nobody catches what the block hands back.',
      'Le nombre n\'est ni montré ni rangé.',
      'The number is neither shown nor stored.',
    ),
    wrongChoiceFr:
        'Un nombre rendu que personne n\'attrape est perdu, sans erreur.',
    wrongChoiceEn:
        'A number handed back that nobody catches is lost, with no error.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.3',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Un ami dit : « retourne, c\'est comme écris ». Que réponds-tu ?',
      'A friend says: "return is just like print". What do you answer?',
    ),
    choices: [
      Choice(
          labelKeys: b('Non : avec écris on ne peut rien faire du nombre.',
              'No: with print you can do nothing with the number.'),
          correct: true),
      Choice(
          labelKeys: b('Oui, c\'est pareil.', 'Yes, it is the same.'),
          correct: false,
          misconception: 'C9.3-return-prints'),
      Choice(
          labelKeys: b('Oui, sauf dans un bloc.', 'Yes, except inside a block.'),
          correct: false,
          misconception: 'C9.3-return-prints'),
      Choice(
          labelKeys: b('Non : écris est interdit.', 'No: print is not allowed.'),
          correct: false,
          misconception: 'C9.3-print-is-banned'),
    ],
    itemHints: hints(
      'Essaie avance avec un bloc qui affiche.',
      'Try forward with a block that shows.',
      'Tika ne trouve aucun nombre.',
      'Tika finds no number.',
    ),
    wrongChoiceFr:
        'Le nombre affiché est pour toi ; le nombre rendu est pour le programme.',
    wrongChoiceEn:
        'The number shown is for you; the number handed back is for the program.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.3',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi un bloc qui rend un nombre est-il utile ?',
      'Why is a block that hands a number back useful?',
    ),
    choices: [
      Choice(
          labelKeys: b('Parce qu\'on peut s\'en servir dans un calcul.',
              'Because you can use it inside a sum.'),
          correct: true),
      Choice(
          labelKeys: b('Parce qu\'il affiche plus joliment.',
              'Because it shows things more nicely.'),
          correct: false,
          misconception: 'C9.3-return-prints'),
      Choice(
          labelKeys: b('Parce qu\'il va plus vite.', 'Because it is faster.'),
          correct: false,
          misconception: 'C6.1-box-is-speed'),
      Choice(
          labelKeys: b('Parce que tout bloc doit en rendre un.',
              'Because every block has to hand one back.'),
          correct: false,
          misconception: 'C9.3-return-is-compulsory'),
    ],
    itemHints: hints(
      'Un nombre rendu peut aller dans avance.',
      'A number handed back can go into forward.',
      'Ou dans une boîte, ou dans un autre bloc.',
      'Or into a box, or into another block.',
    ),
    wrongChoiceFr:
        'Un nombre rendu se dépense là où un nombre écrit à la main irait.',
    wrongChoiceEn:
        'A number handed back is spent where a typed number would go.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.3',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Tous les blocs doivent-ils rendre un nombre ?',
      'Does every block have to hand a number back?',
    ),
    choices: [
      Choice(
          labelKeys: b('Non : un bloc qui dessine n\'a rien à rendre.',
              'No: a block that draws has nothing to hand back.'),
          correct: true),
      Choice(
          labelKeys: b('Oui, sinon il ne sert à rien.',
              'Yes, otherwise it is useless.'),
          correct: false,
          misconception: 'C9.3-return-is-compulsory'),
      Choice(
          labelKeys: b('Oui, KODO en ajoute un tout seul.',
              'Yes, KODO adds one by itself.'),
          correct: false,
          misconception: 'C9.3-return-is-compulsory'),
      Choice(
          labelKeys: b('Non, aucun bloc ne rend de nombre.',
              'No, no block hands a number back.'),
          correct: false,
          misconception: 'C9.3-return-does-nothing'),
    ],
    itemHints: hints(
      'Pense au bloc carré des exercices d\'avant.',
      'Think of the square block from the earlier exercises.',
      'Il dessine ; il ne donne rien.',
      'It draws; it gives nothing.',
    ),
    wrongChoiceFr:
        'Un bloc rend un nombre quand la suite en a besoin, pas par principe.',
    wrongChoiceEn:
        'A block hands a number back when the next line needs one, not on principle.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C9.4 — Décomposer un problème.
// Misconception: "a big program must be written in one piece".
//
// The last concept of World 9 has no new syntax at all. Everything it needs arrived in
// C9.1 and C9.2; what it teaches is a habit — look at the drawing, find the part that
// repeats, give it a name, and the rest of the program becomes short enough to read.
//
// A habit is hard to grade, so it is graded the only honest way: by budget and by shape.
// The golf items set a budget that a single flat program cannot meet, and the open builds
// ask for two named blocks and check that both are used. Neither asks the child to like
// decomposition; they ask for a program that could not have been written without it.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC94() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C9.4-${(++n).toString().padLeft(2, '0')}';

  /// Two named parts and a program that uses both.
  String twoParts(String outerName, String outerBody, String innerName,
          String innerBody, String main) =>
      '${learn(innerName, innerBody)}\n${learn(outerName, outerBody)}\n$main';

  /* T1 — build a figure out of two named parts, where the outer one calls the inner. A
     block that calls a block is the whole idea of the concept in three lines. */
  for (final entry in [
    ('côté', 'toit', 'avance 60', 'côté\ntournedroite 90', 4),
    ('barre', 'marche', 'avance 40', 'barre\ntournedroite 90\nbarre\ntournegauche 90', 3),
    ('trait', 'branche', 'avance 50', 'trait\ntournedroite 120', 3),
    ('bord', 'coin', 'avance 45', 'bord\ntournedroite 60', 6),
  ]) {
    final inner = entry.$1,
        outer = entry.$2,
        innerBody = entry.$3,
        outerBody = entry.$4,
        times = entry.$5;
    final main = 'répète $times {\n  $outer\n}';
    final solution = twoParts(outer, outerBody, inner, innerBody, main);
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C9.4',
      difficulty: Difficulty.d4,
      solution: solution,
      promptKeys: fillBoth(
        b(
            'Apprends deux blocs : {i} pour la petite part, {o} qui s\'en sert. '
                'Puis répète {o} {t} fois.',
            'Teach two blocks: {i} for the small part, {o} that uses it. '
                'Then repeat {o} {t} times.'),
        {'i': inner, 'o': outer, 't': times},
      ),
      wrong: [
        /* One flat program: the same picture, none of the naming. `replaceAll`, not
           `replaceFirst` — an outer body that calls the inner block twice would keep the
           second call and stop with "je ne connais pas ce mot", which is a distractor
           that fails for the wrong reason. */
        'répète $times {\n${outerBody.replaceAll(inner, innerBody).split('\n').map((l) => '  $l').join('\n')}\n}',
        // Both blocks taught, neither used.
        '${learn(inner, innerBody)}\n${learn(outer, outerBody)}',
        // One turn too few.
        twoParts(outer, outerBody, inner, innerBody,
            'répète ${times - 1} {\n  $outer\n}'),
      ],
      assertions: [
        const DefinesProcedure(min: 2),
        const ContainsNode('ProcCall', min: 2),
      ],
      alternatives: [
        '# deux parts, chacune nommée\n$solution',
        solution.replaceFirst('apprends $inner {', 'apprends $inner  {'),
      ],
      itemHints: hints(
        'Cherche la plus petite part qui revient.',
        'Look for the smallest part that comes back.',
        'Donne-lui un nom, puis sers-t\'en dans l\'autre.',
        'Give it a name, then use it inside the other.',
      ),
      paletteScope: palette,
    ));
  }

  // T5 — Parsons. A block has to be taught before the block that calls it.
  for (final entry in [
    ('côté', 'toit', 'avance 60', 'côté\ntournedroite 90', 4),
    ('barre', 'marche', 'avance 40', 'barre\ntournedroite 90', 4),
    ('trait', 'branche', 'avance 50', 'trait\ntournedroite 120', 3),
    ('bord', 'coin', 'avance 45', 'bord\ntournedroite 60', 6),
  ]) {
    final inner = entry.$1,
        outer = entry.$2,
        innerBody = entry.$3,
        outerBody = entry.$4,
        times = entry.$5;
    final main = 'répète $times {\n  $outer\n}';
    final solution = twoParts(outer, outerBody, inner, innerBody, main);
    items.add(parsons(
      id: id(),
      conceptId: 'C9.4',
      difficulty: Difficulty.d4,
      solution: solution,
      promptKeys: fillBoth(
        b('Remets en ordre : {i} d\'abord, puis {o}, puis le programme.',
            'Put it back in order: {i} first, then {o}, then the program.'),
        {'i': inner, 'o': outer},
      ),
      wrong: [
        '${learn(inner, innerBody)}\n${learn(outer, outerBody)}',
        twoParts(outer, outerBody, inner, innerBody, outer),
        // One turn FEWER. One extra turn round a closed figure retraces it and leaves
        // the identical ink, which the gate said about all four of these.
        twoParts(outer, outerBody, inner, innerBody,
            'répète ${times - 1} {\n  $outer\n}'),
      ],
      assertions: [
        const DefinesProcedure(min: 2),
        const ContainsNode('ProcCall', min: 2),
      ],
      alternatives: [
        '# la petite part avant la grande\n$solution',
        solution.replaceFirst('apprends $inner {', 'apprends $inner  {'),
      ],
      itemHints: hints(
        'Un bloc doit être appris avant qu\'on s\'en serve.',
        'A block has to be taught before it is used.',
        'La plus petite part monte en haut.',
        'The smallest part goes at the top.',
      ),
      paletteScope: palette,
    ));
  }

  /* T7 — golf, and the budget is the argument. A figure made of the same part four times
     cannot be written flat under these budgets, so the child has to name the part. */
  for (final entry in [
    ('pétale', 'répète 4 {\n  avance 40\n  tournedroite 90\n}', 6, 60, 7),
    ('marche', 'avance 30\ntournedroite 90\navance 30\ntournegauche 90', 5, 0, 8),
    ('branche', 'répète 3 {\n  avance 35\n  tournedroite 120\n}', 8, 45, 7),
    ('dent', 'avance 25\ntournedroite 90\navance 25\ntournegauche 90', 6, 0, 8),
  ]) {
    final name = entry.$1,
        body = entry.$2,
        times = entry.$3,
        between = entry.$4,
        budget = entry.$5;
    final turn = between == 0 ? '' : '\n  tournedroite $between';
    final main = 'répète $times {\n  $name$turn\n}';
    final solution = '${learn(name, body)}\n$main';
    final flat =
        'répète $times {\n${body.split('\n').map((l) => '  $l').join('\n')}$turn\n}';
    items.add(golf(
      id: id(),
      conceptId: 'C9.4',
      difficulty: Difficulty.d4,
      solution: solution,
      budget: budget,
      promptKeys: fillBoth(
        b('Dessine la figure en {k} blocs au maximum. Donne un nom à la part qui revient.',
            'Draw the shape in {k} blocks or fewer. Give the part that comes back a name.'),
        {'k': budget},
      ),
      wrong: [
        flat,
        '${learn(name, body)}\nrépète ${times - 1} {\n  $name$turn\n}',
        '${learn(name, body)}\n$name',
      ],
      assertions: [
        const DefinesProcedure(),
        const ContainsNode('ProcCall'),
      ],
      alternatives: [
        '# la part porte un nom\n$solution',
        solution.replaceFirst('apprends $name {', 'apprends $name  {'),
      ],
      itemHints: hints(
        'Regarde ce qui se répète dans la figure.',
        'Look at what repeats in the shape.',
        'Un nom pour cette part, et le programme rétrécit.',
        'A name for that part, and the program shrinks.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Par où commencer un gros dessin ?',
        'Where do you start a big drawing?'),
    choices: [
      Choice(
          labelKeys: b('Par la plus petite part qui revient.',
              'With the smallest part that comes back.'),
          correct: true),
      Choice(
          labelKeys: b('Par le début, ligne par ligne, jusqu\'au bout.',
              'At the beginning, line by line, to the end.'),
          correct: false,
          misconception: 'C9.4-one-piece-only'),
      Choice(
          labelKeys: b('Par la fin.', 'At the end.'),
          correct: false,
          misconception: 'C9.4-one-piece-only'),
      Choice(
          labelKeys: b('Par la partie la plus difficile.',
              'With the hardest part.'),
          correct: false,
          misconception: 'C9.4-hardest-first'),
    ],
    itemHints: hints(
      'Regarde ce qui se ressemble dans le dessin.',
      'Look at what is alike in the drawing.',
      'Nomme cette part-là en premier.',
      'Name that part first.',
    ),
    wrongChoiceFr:
        'Un gros dessin devient court quand ses parts qui reviennent ont un nom.',
    wrongChoiceEn:
        'A big drawing gets short when its repeating parts have names.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Un bloc peut-il se servir d\'un autre bloc ?',
        'Can a block use another block?'),
    choices: [
      Choice(
          labelKeys: b('Oui, s\'il a été appris avant.',
              'Yes, if it was taught first.'),
          correct: true),
      Choice(
          labelKeys: b('Non, jamais.', 'No, never.'),
          correct: false,
          misconception: 'C9.4-blocks-cannot-nest'),
      Choice(
          labelKeys: b('Oui, mais une seule fois.', 'Yes, but only once.'),
          correct: false,
          misconception: 'C9.4-blocks-cannot-nest'),
      Choice(
          labelKeys: b('Seulement s\'il rend un nombre.',
              'Only if it hands a number back.'),
          correct: false,
          misconception: 'C9.3-return-is-compulsory'),
    ],
    itemHints: hints(
      'Un bloc est un mot que Tika connaît.',
      'A block is a word Tika knows.',
      'Elle peut s\'en servir dans un autre bloc.',
      'She can use it inside another block.',
    ),
    wrongChoiceFr:
        'Une fois appris, un bloc s\'écrit partout, y compris dans un autre bloc.',
    wrongChoiceEn:
        'Once taught, a block goes anywhere, including inside another block.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Pourquoi un programme coupé en parts est-il plus facile à réparer ?',
        'Why is a program cut into parts easier to fix?'),
    choices: [
      Choice(
          labelKeys: b('Parce que l\'erreur est dans une seule part.',
              'Because the mistake is in one part only.'),
          correct: true),
      Choice(
          labelKeys: b('Parce qu\'il est plus court à lire.',
              'Because it is shorter to read.'),
          correct: false,
          misconception: 'C9.4-shorter-is-the-point'),
      Choice(
          labelKeys: b('Parce que Tika va plus vite.',
              'Because Tika goes faster.'),
          correct: false,
          misconception: 'C6.1-box-is-speed'),
      Choice(
          labelKeys: b('Il ne l\'est pas.', 'It is not.'),
          correct: false,
          misconception: 'C9.4-one-piece-only'),
    ],
    itemHints: hints(
      'Si le pétale est faux, tous les pétales sont faux.',
      'If the petal is wrong, every petal is wrong.',
      'On le corrige à un seul endroit.',
      'You fix it in one place.',
    ),
    wrongChoiceFr:
        'Une part nommée se corrige une fois pour tous ses usages.',
    wrongChoiceEn:
        'A named part is fixed once for every place that uses it.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Quel nom donner à un bloc ?', 'What should a block be called?'),
    choices: [
      Choice(
          labelKeys: b('Ce qu\'il dessine.', 'What it draws.'),
          correct: true),
      Choice(
          labelKeys: b('Une lettre, c\'est plus court.',
              'A letter, it is shorter.'),
          correct: false,
          misconception: 'C9.4-names-do-not-matter'),
      Choice(
          labelKeys: b('Son numéro dans le programme.',
              'Its number in the program.'),
          correct: false,
          misconception: 'C9.4-names-do-not-matter'),
      Choice(
          labelKeys: b('N\'importe quoi : le nom ne compte pas.',
              'Anything: the name does not matter.'),
          correct: false,
          misconception: 'C9.4-names-do-not-matter'),
    ],
    itemHints: hints(
      'Tu reliras ce programme dans une semaine.',
      'You will read this program again in a week.',
      'Le nom doit te dire ce que la part fait.',
      'The name should tell you what the part does.',
    ),
    wrongChoiceFr:
        'Un nom qui dit ce que la part dessine évite de relire son corps.',
    wrongChoiceEn:
        'A name that says what the part draws saves re-reading its body.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C9.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Tu changes le bloc pétale. Que deviennent les six pétales du dessin ?',
        'You change the petal block. What happens to the six petals in the drawing?'),
    choices: [
      Choice(
          labelKeys: b('Les six changent.', 'All six change.'), correct: true),
      Choice(
          labelKeys: b('Seul le premier change.',
              'Only the first one changes.'),
          correct: false,
          misconception: 'C6.1-box-is-copied-once'),
      Choice(
          labelKeys: b('Aucun : le dessin est fait.',
              'None: the drawing is finished.'),
          correct: false,
          misconception: 'C6.1-box-holds-the-drawing'),
      Choice(
          labelKeys: b('Il faut les changer un par un.',
              'You have to change them one by one.'),
          correct: false,
          misconception: 'C9.4-one-piece-only'),
    ],
    itemHints: hints(
      'Les six pétales sont le même bloc.',
      'The six petals are the same block.',
      'Chacun relit son corps quand on relance.',
      'Each one reads its body again when you run it.',
    ),
    wrongChoiceFr:
        'Six appels d\'un même bloc suivent tous la dernière version de son corps.',
    wrongChoiceEn:
        'Six calls of one block all follow the latest version of its body.',
  ));

  // T9 — five open builds. Two named parts, both used.
  for (final entry in [
    ('Fais une fleur avec un bloc pétale.',
        'Make a flower with a petal block.'),
    ('Fais une maison avec un bloc mur et un bloc toit.',
        'Make a house with a wall block and a roof block.'),
    ('Fais un escalier avec un bloc marche.',
        'Make a staircase with a step block.'),
    ('Fais un arbre avec un bloc branche.',
        'Make a tree with a branch block.'),
    ('Coupe ton dessin préféré en deux blocs nommés.',
        'Cut your favourite drawing into two named blocks.'),
  ]) {
    items.add(openBuild(
      id: id(),
      conceptId: 'C9.4',
      difficulty: Difficulty.d4,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine('Tu apprends deux blocs à Tika.',
            'You teach Tika two blocks.', const DefinesProcedure(min: 2)),
        rubricLine('Tu te sers des deux.', 'You use both of them.',
            const ContainsNode('ProcCall', min: 2)),
        rubricLine('Ton programme principal tient en peu de lignes.',
            'Your main program fits in a few lines.',
            const BlockCountWithin(min: 3, max: 24)),
        rubricLine('Tika dessine quelque chose.', 'Tika draws something.',
            const UsesOpcode('MOVE_FORWARD')),
      ],
      itemHints: hints(
        'Cherche la part qui revient plusieurs fois.',
        'Look for the part that comes back several times.',
        'Nomme-la, puis nomme ce qui l\'utilise.',
        'Name it, then name what uses it.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// Tutorials (§4.2: Je regarde · On fait ensemble · Je fais).
//
// `paramètre` is on `FR-M5-03`'s jargon list, so the narration never says it. It says
// *boîte*, which World 6 taught and which is what a parameter is.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Tutorial> world9Tutorials() => [
      tutorialFor(
        conceptId: 'C9.1',
        conceptName: b('Apprendre un bloc, puis s\'en servir.',
            'Teach a block, then use it.'),
        palette: palette,
        steps: [
          watchStep(
            'C9.1',
            'Tika apprend un mot, puis on le lui demande.',
            'Tika learns a word, then we ask for it.',
            '${learn('carré', figure(4, 60, 90))}\ncarré\ntournedroite 180\ncarré',
            ideas: ['define', 'call'],
          ),
          togetherStep(
            'C9.1',
            'À toi. Écris carré pour t\'en servir.',
            'Your turn. Write square to use it.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Le nom du bloc suffit sur sa ligne.',
            hintEn: 'The block name on its own line is enough.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C9.1',
            'Apprends un bloc à Tika et sers-t\'en deux fois.',
            'Teach Tika a block and use it twice.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Apprendre ne dessine rien. Il faut écrire le nom.',
            hintEn: 'Teaching draws nothing. You have to write the name.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C9.2',
        conceptName: b('Un bloc peut recevoir un nombre.',
            'A block can be given a number.'),
        palette: palette,
        steps: [
          watchStep(
            'C9.2',
            'Le même bloc dessine deux tailles.',
            'The same block draws two sizes.',
            '${learn('carré', sidedBody(4, '\$côté', 90), params: '\$côté')}\n'
                'carré 40\ntournedroite 180\ncarré 80',
            ideas: ['parameter', 'reuse'],
          ),
          togetherStep(
            'C9.2',
            'Demande le carré à 40 pas.',
            'Ask for the square at 40 steps.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Écris carré puis le nombre.',
            hintEn: 'Write square then the number.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C9.2',
            'Fais un bloc qui prend sa taille. Sers-t\'en deux fois.',
            'Make a block that takes its size. Use it twice.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'La boîte du bloc s\'écrit après son nom.',
            hintEn: 'The block\'s box is written after its name.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C9.3',
        conceptName: b('Retourne rend un nombre.',
            'Return hands a number back.'),
        palette: palette,
        steps: [
          watchStep(
            'C9.3',
            'Le bloc rend un nombre et avance le dépense.',
            'The block hands a number back and forward spends it.',
            '${learn('double', 'retourne \$x * 2', params: '\$x')}\n'
                'avance double 30',
            ideas: ['return', 'value'],
          ),
          togetherStep(
            'C9.3',
            'Écris retourne pour rendre le nombre.',
            'Write return to hand the number back.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'retourne va devant le calcul.',
            hintEn: 'return goes in front of the sum.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C9.3',
            'Fais un bloc qui rend un nombre. Sers-t\'en.',
            'Make a block that hands a number back. Use it.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'écris montre. retourne donne.',
            hintEn: 'print shows. return gives.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C9.4',
        conceptName: b('Un gros dessin se coupe en parts.',
            'A big drawing is cut into parts.'),
        palette: palette,
        steps: [
          watchStep(
            'C9.4',
            'Une petite part nommée sert à la grande.',
            'A small named part serves the big one.',
            '${learn('côté', 'avance 60')}\n'
                '${learn('toit', 'côté\ntournedroite 90')}\n'
                'répète 4 {\n  toit\n}',
            ideas: ['decomposition', 'nesting'],
          ),
          togetherStep(
            'C9.4',
            'Apprends le petit bloc en premier.',
            'Teach the small block first.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Un bloc s\'apprend avant qu\'on s\'en serve.',
            hintEn: 'A block is taught before it is used.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C9.4',
            'Coupe ton dessin en deux blocs nommés.',
            'Cut your drawing into two named blocks.',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Cherche la part qui revient plusieurs fois.',
            hintEn: 'Look for the part that comes back several times.',
          ),
        ],
      ),
    ];

void main() {
  publishWorld(
    world: 9,
    nameKeys: b('Mes propres blocs', 'My own blocks'),
    conceptGraph: conceptGraph,
    committed: committed,
    items: [
      ...conceptC91(),
      ...conceptC92(),
      ...conceptC93(),
      ...conceptC94(),
    ],
    tutorials: world9Tutorials(),
    assetKeys: const ['art/tika.svg', 'art/world9-mesblocs.svg'],
  );
}
