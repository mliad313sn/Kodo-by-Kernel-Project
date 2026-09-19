// Authors World 6 — "Mes variables" — and writes it out as a content pack.
//
//     dart tool/author_world6.dart
//
// A variable is the first thing in KODO that a child cannot see. Up to here every idea
// had a picture: a line, a turn, a colour, a place on the page. A box with a number in it
// has none, which is why the five misconceptions in the ledger are all about *where the
// number is*:
//
//   C6.1  "the variable holds the whole program"
//   C6.2  "$x = $x / 3 is a false equation"
//   C6.3  "operations always run left to right"
//   C6.4  "I cannot see what is inside a variable"
//   C6.5  "random means unpredictable therefore untestable"
//
// The fourth and fifth are the interesting ones, and they are answered by the product
// rather than by words: `écris` shows what is inside, and `hasard` runs off a seeded
// generator, so a random program is graded like any other. A child who believes
// randomness cannot be tested is holding a belief this world can simply disprove — and
// every expected value below was read off the real interpreter, not reasoned about.
//
// One authoring rule runs through the whole world and is worth stating once: **a box is
// invisible on the canvas.** `$côté = 60` then `avance $côté` draws exactly what
// `avance 60` draws, so an item that only compares pictures cannot tell a child who used
// a variable from one who did not. Every item whose point is the box therefore carries a
// `UsesVariable` assertion naming it, and the "wrote the number out instead" distractor
// is there to prove the assertion fires.

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';

import 'authoring.dart';

const conceptGraph = <String, List<String>>{
  'C6.1': ['C4.3'],
  'C6.2': ['C6.1'],
  'C6.3': ['C6.2'],
  'C6.4': ['C6.2'],
  'C6.5': ['C6.3'],
};

/// §6.3's commitment, copied from `spec/concepts.json` and checked against it by
/// `publishWorld`.
const committed = <String, int>{
  'C6.1': 24,
  'C6.2': 24,
  'C6.3': 22,
  'C6.4': 18,
  'C6.5': 20,
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
  'POSITION_X',
  'POSITION_Y',
];

/// The two alternatives an output-only item needs.
///
/// `equivalentsOf` rewrites `avance` and `tourne` lines, so a program that only prints
/// gets one alternative out of it and the gate's "at least two" rule fails. These two are
/// real: a comment is not a statement, and a blank line is not a statement. Both prove the
/// grader is comparing trees rather than text — which is the same claim `FR-M6-02` makes.
List<String> printedAlternatives(String solution) => [
      '# une autre façon d\'écrire la même chose\n$solution',
      solution.replaceFirst('\n', '\n\n'),
    ];

// ═══════════════════════════════════════════════════════════════════════════════════════
// C6.1 — Une variable, une boîte.
// Misconception: "the variable holds the whole program".
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC61() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C6.1-${(++n).toString().padLeft(2, '0')}';

  /* T1 — put a number in a box, then use the box. The whole concept in three lines, and
     the proof is that the figure changes when the box changes and nowhere else. */
  for (final entry in [
    ('côté', 60, 4, 90),
    ('taille', 80, 3, 120),
    ('pas', 40, 6, 60),
    ('long', 50, 5, 72),
    ('bord', 70, 4, 90),
    ('mesure', 45, 6, 60),
  ]) {
    final name = entry.$1, value = entry.$2, sides = entry.$3, turn = entry.$4;
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C6.1',
      difficulty: sides == 4 ? Difficulty.d1 : Difficulty.d2,
      solution: '\$$name = $value\n'
          'répète $sides {\n  avance \$$name\n  tournedroite $turn\n}',
      promptKeys: fillBoth(
        b(
            'Mets {v} dans une boîte appelée \${n}, puis dessine la figure à '
                '{k} côtés en te servant de la boîte.',
            'Put {v} in a box called \${n}, then draw the {k}-sided shape '
                'using the box.'),
        {'v': value, 'n': name, 'k': sides},
      ),
      wrong: [
        // The number written out: the figure is right and the box is not there.
        'répète $sides {\n  avance $value\n  tournedroite $turn\n}',
        // A box with the wrong number in it.
        '\$$name = ${value + 20}\n'
            'répète $sides {\n  avance \$$name\n  tournedroite $turn\n}',
        // The box used for the turn instead of the side.
        '\$$name = $value\n'
            'répète $sides {\n  avance $turn\n  tournedroite \$$name\n}',
      ],
      /* The box is invisible in the drawing, so the claim is checked structurally: the
         first distractor draws the right figure and must still fail. Reading it once is
         part of the claim — a box that is filled and never spent is not a variable, it is
         a line of dead code. */
      assertions: [UsesVariable(name: name, minReads: 1)],
      itemHints: hints(
        'Une boîte a un nom et garde un nombre.',
        'A box has a name and keeps a number.',
        'Écris \$$name = $value, puis sers-toi de \$$name.',
        'Write \$$name = $value, then use \$$name.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — what is in the box at the end? Six traces, each aimed at one wrong idea about
     where the number lives. The last is the sharpest: copying a box takes a snapshot, it
     does not tie the two boxes together. */
  for (final entry in [
    (
      r'$a = 7',
      'a',
      '7',
      '0',
      'C6.1-box-is-empty',
      'a',
      'C6.1-box-holds-its-name',
      '1',
      'C6.1-box-holds-position'
    ),
    (
      r'$a = 7' '\n' r'$b = 3',
      'b',
      '3',
      '7',
      'C6.1-box-holds-another',
      '10',
      'C6.1-boxes-add-up',
      '0',
      'C6.1-box-is-empty'
    ),
    (
      r'$a = 7' '\n' r'$a = 9',
      'a',
      '9',
      '7',
      'C6.1-first-value-wins',
      '16',
      'C6.1-boxes-add-up',
      '79',
      'C6.1-box-holds-history'
    ),
    (
      r'$a = 7' '\n' r'$b = $a',
      'b',
      '7',
      '0',
      'C6.1-box-is-empty',
      'a',
      'C6.1-box-holds-its-name',
      '14',
      'C6.1-boxes-add-up'
    ),
    (
      r'$a = 5' '\n' r'$b = 2' '\n' r'$a = $b',
      'a',
      '2',
      '5',
      'C6.1-first-value-wins',
      '7',
      'C6.1-boxes-add-up',
      '52',
      'C6.1-box-holds-history'
    ),
    (
      r'$a = 4' '\n' r'$b = $a' '\n' r'$a = 9',
      'b',
      '4',
      '9',
      'C6.1-copy-follows-original',
      '13',
      'C6.1-boxes-add-up',
      '0',
      'C6.1-box-is-empty'
    ),
  ]) {
    final source = entry.$1, box = entry.$2, value = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C6.1',
      difficulty: Difficulty.d2,
      promptKeys: fillBoth(
        b('Qu\'y a-t-il dans la boîte \${b} à la fin ?\n\n{p}',
            'What is in the box \${b} at the end?\n\n{p}'),
        {'b': box, 'p': source},
      ),
      choices: [
        Choice(labelKeys: b(value, value), correct: true),
        Choice(
            labelKeys: b(entry.$4, entry.$4),
            correct: false,
            misconception: entry.$5),
        Choice(
            labelKeys: b(entry.$6, entry.$6),
            correct: false,
            misconception: entry.$7),
        Choice(
            labelKeys: b(entry.$8, entry.$8),
            correct: false,
            misconception: entry.$9),
      ],
      itemHints: hints(
        'Lis les lignes une par une, de haut en bas.',
        'Read the lines one at a time, top to bottom.',
        'La dernière ligne qui écrit dans cette boîte gagne.',
        'The last line that writes into that box wins.',
      ),
      wrongChoiceFr:
          'Une boîte garde un nombre, celui qu\'on y a mis en dernier.',
      wrongChoiceEn: 'A box keeps one number: the last one put into it.',
    ));
  }

  // T4 — fill the gap: four holes where the number goes.
  for (final entry in [
    ('côté', 50),
    ('taille', 70),
    ('pas', 35),
    ('rayon', 90),
  ]) {
    final name = entry.$1, value = entry.$2;
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C6.1',
      difficulty: Difficulty.d1,
      withHoles: '\$$name = ___\n'
          'répète 4 {\n  avance \$$name\n  tournedroite 90\n}',
      solution: '\$$name = $value\n'
          'répète 4 {\n  avance \$$name\n  tournedroite 90\n}',
      promptKeys: fillBoth(
        b('Complète pour que le carré fasse {v} pas de côté.',
            'Fill in the blank so the square has sides of {v} steps.'),
        {'v': value},
      ),
      wrong: [
        '\$$name = ${value + 30}\n'
            'répète 4 {\n  avance \$$name\n  tournedroite 90\n}',
        '\$$name = ${value - 20}\n'
            'répète 4 {\n  avance \$$name\n  tournedroite 90\n}',
        // Half of it. A fixed number here would collide with whichever parameter set
        // happens to use that number, which is exactly how C6.1-16 shipped a "wrong"
        // answer that was right.
        '\$$name = ${(value / 2).round()}\n'
            'répète 4 {\n  avance \$$name\n  tournedroite 90\n}',
      ],
      assertions: [UsesVariable(name: name, minReads: 1)],
      itemHints: hints(
        'Le nombre va dans la boîte.',
        'The number goes into the box.',
        'C\'est $value.',
        'It is $value.',
      ),
      paletteScope: palette,
    ));
  }

  /* Two more holes, in the other place: the box is already filled and what is missing is
     *spending* it. The distractor that writes the number out draws the identical square,
     so these two items only work because of the assertion. */
  for (final entry in [('côté', 50), ('rayon', 80)]) {
    final name = entry.$1, value = entry.$2;
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C6.1',
      difficulty: Difficulty.d2,
      withHoles: '\$$name = $value\n'
          'répète 4 {\n  ___\n  tournedroite 90\n}',
      solution: '\$$name = $value\n'
          'répète 4 {\n  avance \$$name\n  tournedroite 90\n}',
      promptKeys: b(
          'La boîte est déjà remplie. Complète pour que Tika s\'en serve.',
          'The box is already filled. Fill in the blank so Tika uses it.'),
      wrong: [
        // Draws exactly the right square, and never opens the box.
        '\$$name = $value\n'
            'répète 4 {\n  avance $value\n  tournedroite 90\n}',
        '\$$name = $value\n'
            'répète 4 {\n  avance 90\n  tournedroite 90\n}',
        '\$$name = $value\n'
            'répète 4 {\n  avance \$$name * 2\n  tournedroite 90\n}',
      ],
      assertions: [UsesVariable(name: name, minReads: 1)],
      itemHints: hints(
        'Pour ouvrir la boîte, écris son nom avec le \$.',
        'To open the box, write its name with the \$.',
        'Écris avance \$$name.',
        'Write forward \$$name.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys:
        b('Qu\'est-ce qu\'il y a dans une boîte ?', 'What is inside a box?'),
    choices: [
      Choice(
          labelKeys: b('Un seul nombre à la fois.', 'One number at a time.'),
          correct: true),
      Choice(
          labelKeys: b('Tout le programme.', 'The whole program.'),
          correct: false,
          misconception: 'C6.1-box-holds-the-program'),
      Choice(
          labelKeys: b('Tous les nombres qu\'on y a mis.',
              'Every number ever put in it.'),
          correct: false,
          misconception: 'C6.1-box-holds-history'),
      Choice(
          labelKeys: b('Le dessin qu\'on a fait.', 'The drawing you made.'),
          correct: false,
          misconception: 'C6.1-box-holds-the-drawing'),
    ],
    itemHints: hints(
      'Pense à une vraie boîte, avec une seule chose dedans.',
      'Think of a real box, with one thing inside.',
      'Si on y met autre chose, le premier s\'en va.',
      'If you put something else in, the first one goes.',
    ),
    wrongChoiceFr:
        'Une boîte garde un nombre, et le nouveau remplace l\'ancien.',
    wrongChoiceEn: 'A box keeps one number, and a new one replaces the old.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys:
        b('À quoi sert le nom d\'une boîte ?', 'What is a box\'s name for?'),
    choices: [
      Choice(
          labelKeys: b('À la retrouver pour s\'en servir plus loin.',
              'To find it again and use it further down.'),
          correct: true),
      Choice(
          labelKeys: b('À décorer le programme.', 'To decorate the program.'),
          correct: false,
          misconception: 'C6.1-name-is-cosmetic'),
      Choice(
          labelKeys: b('À dire ce que la boîte va faire.',
              'To say what the box will do.'),
          correct: false,
          misconception: 'C6.1-box-does-something'),
      Choice(
          labelKeys: b('À rien : le nom est obligatoire, c\'est tout.',
              'Nothing: a name is just compulsory.'),
          correct: false,
          misconception: 'C6.1-name-is-cosmetic'),
    ],
    itemHints: hints(
      'Imagine deux boîtes sur une table.',
      'Imagine two boxes on a table.',
      'Sans nom, on ne sait pas laquelle on demande.',
      'Without a name you cannot say which one you mean.',
    ),
    wrongChoiceFr: 'Le nom sert à désigner cette boîte-là et pas une autre.',
    wrongChoiceEn: 'The name is how you point at that box and not another.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        r'Tu écris $côté = 50 puis avance $côté. Que voit Tika comme nombre ?',
        r'You write $side = 50 then forward $side. What number does Tika see?'),
    choices: [
      Choice(labelKeys: b('50', '50'), correct: true),
      Choice(
          labelKeys: b('le mot « côté »', 'the word "side"'),
          correct: false,
          misconception: 'C6.1-box-holds-its-name'),
      Choice(
          labelKeys: b('0', '0'),
          correct: false,
          misconception: 'C6.1-box-is-empty'),
      Choice(
          labelKeys: b('le numéro de la ligne, c\'est-à-dire 2',
              'the line number, which is 2'),
          correct: false,
          misconception: 'C6.1-box-holds-position'),
    ],
    itemHints: hints(
      'Remplace la boîte par ce qu\'il y a dedans.',
      'Replace the box with what is inside it.',
      'Tika lit 50.',
      'Tika reads 50.',
    ),
    wrongChoiceFr: 'Une boîte vaut son contenu : ici, 50.',
    wrongChoiceEn: 'A box is worth its contents: here, 50.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        r'Une boîte $taille sert à trois endroits du programme. Tu changes le nombre dedans. Que se passe-t-il ?',
        r'A box $size is used in three places. You change the number inside it. What happens?'),
    choices: [
      Choice(
          labelKeys:
              b('Les trois endroits changent.', 'All three places change.'),
          correct: true),
      Choice(
          labelKeys:
              b('Seul le premier change.', 'Only the first one changes.'),
          correct: false,
          misconception: 'C6.1-box-is-copied-once'),
      Choice(
          labelKeys: b('Rien ne change, c\'est déjà dessiné.',
              'Nothing changes, it is already drawn.'),
          correct: false,
          misconception: 'C6.1-box-holds-the-drawing'),
      Choice(
          labelKeys: b('Le programme s\'arrête.', 'The program stops.'),
          correct: false,
          misconception: 'C6.1-changing-a-box-is-an-error'),
    ],
    itemHints: hints(
      'Chaque endroit va rouvrir la boîte quand on relance.',
      'Each place opens the box again when you run it.',
      'Ils y trouvent tous le nouveau nombre.',
      'They all find the new number there.',
    ),
    wrongChoiceFr:
        'Chaque \$taille relit la boîte : un seul changement les touche tous.',
    wrongChoiceEn:
        'Every \$size re-reads the box, so one change reaches all of them.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.1',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi mettre 60 dans une boîte plutôt que d\'écrire 60 partout ?',
      'Why put 60 in a box instead of writing 60 everywhere?',
    ),
    choices: [
      Choice(
          labelKeys: b('Pour changer la figure en changeant un seul nombre.',
              'To change the shape by changing one number.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que 60 est trop long à écrire.',
              'Because 60 takes too long to write.'),
          correct: false,
          misconception: 'C6.1-box-is-shorthand'),
      Choice(
          labelKeys: b('Parce que Tika va plus vite avec une boîte.',
              'Because Tika goes faster with a box.'),
          correct: false,
          misconception: 'C6.1-box-is-speed'),
      Choice(
          labelKeys: b('Parce qu\'il faut toujours une boîte.',
              'Because you always need a box.'),
          correct: false,
          misconception: 'C6.1-box-is-compulsory'),
    ],
    itemHints: hints(
      'Imagine que tu veuilles essayer 80, puis 100.',
      'Imagine trying 80, then 100.',
      'Avec une boîte, tu changes une seule ligne.',
      'With a box you change one line.',
    ),
    wrongChoiceFr:
        'La boîte rassemble en un seul endroit un nombre utilisé partout.',
    wrongChoiceEn: 'The box gathers into one place a number used all over.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.1',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Un ami dit : « la boîte garde tout mon programme ». Que lui réponds-tu ?',
      'A friend says: "the box keeps my whole program". What do you answer?',
    ),
    choices: [
      Choice(
          labelKeys: b('Elle garde un nombre, pas des instructions.',
              'It keeps a number, not instructions.'),
          correct: true),
      Choice(
          labelKeys: b(
              'Oui, et on peut la relancer.', 'Yes, and you can run it again.'),
          correct: false,
          misconception: 'C6.1-box-holds-the-program'),
      Choice(
          labelKeys: b('Oui, si le programme est court.',
              'Yes, if the program is short.'),
          correct: false,
          misconception: 'C6.1-box-holds-the-program'),
      Choice(
          labelKeys:
              b('Elle garde le dessin fini.', 'It keeps the finished drawing.'),
          correct: false,
          misconception: 'C6.1-box-holds-the-drawing'),
    ],
    itemHints: hints(
      'Regarde ce qu\'on met dans la boîte : un nombre.',
      'Look at what goes into the box: a number.',
      'Les instructions restent sur les lignes du programme.',
      'The instructions stay on the program\'s lines.',
    ),
    wrongChoiceFr:
        'Une boîte contient une valeur ; les instructions restent dans le programme.',
    wrongChoiceEn: 'A box holds a value; the instructions stay in the program.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C6.2 — Affecter une valeur.
// Misconception: "$x = $x / 3 is a false equation".
//
// This is the hardest single line in the world, and it is hard for a good reason: at
// school `=` means "is the same as", and `$x = $x + 5` is then plainly false. KODO's `=`
// is an *arrow*: read the right-hand side, then put the answer in the box. The items
// below never argue the point — they trace it, one line at a time, until the child has
// watched a box change six times.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC62() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C6.2-${(++n).toString().padLeft(2, '0')}';

  /* T2 — six bugs, and every one of them is a bug about *when* the box is written.
     Order is the whole subject: a box read before it is filled is an error, a box
     refilled inside the loop never grows, and a box grown into the wrong name grows
     nothing. */

  // 1. Read before filled. The broken program does not draw a wrong picture — it stops.
  items.add(fixTheBug(
    id: id(),
    conceptId: 'C6.2',
    difficulty: Difficulty.d2,
    broken: 'répète 4 {\n  avance \$côté\n  tournedroite 90\n}\n\$côté = 60',
    solution: '\$côté = 60\nrépète 4 {\n  avance \$côté\n  tournedroite 90\n}',
    promptKeys: b(
        'Tika s\'arrête et dit qu\'elle ne connaît pas \$côté. Remets la ligne au bon endroit.',
        'Tika stops and says she does not know \$side. Move the line to the right place.'),
    wrong: [
      // Draws the square perfectly and never opens the box.
      'répète 4 {\n  avance 60\n  tournedroite 90\n}\n\$côté = 60',
      '\$côté = 85\nrépète 4 {\n  avance \$côté\n  tournedroite 90\n}',
      '\$côté = 60\nrépète 3 {\n  avance \$côté\n  tournedroite 90\n}',
    ],
    assertions: [UsesVariable(name: 'côté', minReads: 1)],
    itemHints: hints(
      'Tika lit les lignes de haut en bas.',
      'Tika reads the lines from top to bottom.',
      'Il faut remplir la boîte avant de s\'en servir.',
      'The box has to be filled before it is used.',
    ),
    paletteScope: palette,
  ));

  // 2. The box is refilled at the top of every turn, so the spiral never grows.
  items.add(fixTheBug(
    id: id(),
    conceptId: 'C6.2',
    difficulty: Difficulty.d3,
    broken: '\$c = 20\nrépète 6 {\n  \$c = 20\n  avance \$c\n'
        '  tournedroite 60\n  \$c = \$c + 10\n}',
    solution: '\$c = 20\nrépète 6 {\n  avance \$c\n'
        '  tournedroite 60\n  \$c = \$c + 10\n}',
    promptKeys: b(
        'La spirale devrait grandir à chaque tour, mais elle tourne en rond. Enlève la ligne de trop.',
        'The spiral should grow every turn, but it goes round and round. Remove the extra line.'),
    wrong: [
      '\$c = 20\nrépète 6 {\n  \$c = \$c + 10\n  avance \$c\n  tournedroite 60\n}',
      '\$c = 20\nrépète 6 {\n  avance \$c\n  tournedroite 60\n  \$c = \$c - 10\n}',
      '\$c = 20\nrépète 6 {\n  avance \$c\n  tournedroite 60\n  \$c = 10 + 10\n}',
    ],
    assertions: [const UsesVariable(name: 'c', min: 2, minReads: 2)],
    itemHints: hints(
      'Regarde ce que vaut \$c au début de chaque tour.',
      'Look at what \$c holds at the start of each turn.',
      'Une ligne remet 20 dans la boîte à chaque fois.',
      'One line puts 20 back into the box every time.',
    ),
    paletteScope: palette,
  ));

  // 3. The growth is written into a box nobody reads.
  items.add(fixTheBug(
    id: id(),
    conceptId: 'C6.2',
    difficulty: Difficulty.d3,
    broken: '\$c = 20\nrépète 6 {\n  avance \$c\n'
        '  tournedroite 60\n  \$d = \$c + 10\n}',
    solution: '\$c = 20\nrépète 6 {\n  avance \$c\n'
        '  tournedroite 60\n  \$c = \$c + 10\n}',
    promptKeys: b(
        'La spirale ne grandit pas. Le nombre grandit, mais pas dans la bonne boîte.',
        'The spiral does not grow. The number grows, but not in the right box.'),
    wrong: [
      '\$c = 20\nrépète 6 {\n  avance \$d\n  tournedroite 60\n  \$d = \$c + 10\n}',
      '\$c = 20\nrépète 6 {\n  avance \$c\n  tournedroite 60\n  \$c = \$c + 20\n}',
      '\$c = 20\nrépète 6 {\n  avance \$c\n  tournedroite 60\n  \$c = 10 + \$c * 2\n}',
    ],
    assertions: [const UsesVariable(name: 'c', min: 2, minReads: 2)],
    itemHints: hints(
      'Quelle boîte est lue par avance ?',
      'Which box does forward read?',
      'C\'est \$c qu\'il faut faire grandir.',
      'It is \$c that has to grow.',
    ),
    paletteScope: palette,
  ));

  // 4. Two boxes, and the wrong one is spent.
  items.add(fixTheBug(
    id: id(),
    conceptId: 'C6.2',
    difficulty: Difficulty.d2,
    broken: '\$large = 80\n\$haut = 40\nrépète 2 {\n  avance \$haut\n'
        '  tournedroite 90\n  avance \$haut\n  tournedroite 90\n}',
    solution: '\$large = 80\n\$haut = 40\nrépète 2 {\n  avance \$haut\n'
        '  tournedroite 90\n  avance \$large\n  tournedroite 90\n}',
    promptKeys: b(
        'Le rectangle est devenu un carré. Une ligne se sert de la mauvaise boîte.',
        'The rectangle turned into a square. One line spends the wrong box.'),
    wrong: [
      '\$large = 80\n\$haut = 40\nrépète 2 {\n  avance \$large\n'
          '  tournedroite 90\n  avance \$large\n  tournedroite 90\n}',
      '\$large = 80\n\$haut = 40\nrépète 2 {\n  avance \$large\n'
          '  tournedroite 90\n  avance \$haut\n  tournedroite 90\n}',
      '\$large = 80\n\$haut = 40\nrépète 2 {\n  avance \$haut\n'
          '  tournedroite 90\n  avance 40\n  tournedroite 90\n}',
    ],
    assertions: [
      const UsesVariable(name: 'large', minReads: 1),
      const UsesVariable(name: 'haut', minReads: 1),
    ],
    itemHints: hints(
      'Deux boîtes, deux nombres différents.',
      'Two boxes, two different numbers.',
      'Le côté long doit lire \$large.',
      'The long side has to read \$wide.',
    ),
    paletteScope: palette,
  ));

  // 5. Doubling written as halving. The arrow points the right way; the sum does not.
  items.add(fixTheBug(
    id: id(),
    conceptId: 'C6.2',
    difficulty: Difficulty.d3,
    broken: '\$c = 10\nrépète 5 {\n  avance \$c\n'
        '  tournedroite 90\n  \$c = \$c / 2\n}',
    solution: '\$c = 10\nrépète 5 {\n  avance \$c\n'
        '  tournedroite 90\n  \$c = \$c * 2\n}',
    promptKeys: b('Le carré devait doubler à chaque tour. Corrige le calcul.',
        'The square was supposed to double every turn. Fix the sum.'),
    wrong: [
      '\$c = 10\nrépète 5 {\n  avance \$c\n  tournedroite 90\n  \$c = \$c + 2\n}',
      '\$c = 10\nrépète 5 {\n  avance \$c\n  tournedroite 90\n  \$c = 2 * 2\n}',
      '\$c = 10\nrépète 5 {\n  avance \$c\n  tournedroite 90\n  \$c = \$c * 3\n}',
    ],
    assertions: [const UsesVariable(name: 'c', min: 2, minReads: 2)],
    itemHints: hints(
      'Doubler, c\'est multiplier par 2.',
      'Doubling means multiplying by 2.',
      'Remplace / par *.',
      'Replace / with *.',
    ),
    paletteScope: palette,
  ));

  // 6. The total is emptied instead of being carried forward.
  items.add(fixTheBug(
    id: id(),
    conceptId: 'C6.2',
    difficulty: Difficulty.d3,
    broken: '\$total = 0\nrépète 4 {\n  \$total = 25\n  avance \$total\n'
        '  tournedroite 90\n}',
    solution: '\$total = 0\nrépète 4 {\n  \$total = \$total + 25\n'
        '  avance \$total\n  tournedroite 90\n}',
    promptKeys: b(
        'Chaque trait devait être plus long que le précédent. Fais grandir le total.',
        'Each line was meant to be longer than the last. Make the total grow.'),
    wrong: [
      '\$total = 0\nrépète 4 {\n  \$total = 25 + 25\n  avance \$total\n  tournedroite 90\n}',
      '\$total = 0\nrépète 4 {\n  \$total = \$total + 10\n  avance \$total\n  tournedroite 90\n}',
      '\$total = 0\nrépète 4 {\n  avance \$total + 25\n  tournedroite 90\n}',
    ],
    assertions: [const UsesVariable(name: 'total', min: 2, minReads: 2)],
    itemHints: hints(
      'Le total doit se souvenir de ce qu\'il avait déjà.',
      'The total has to remember what it already had.',
      'Écris \$total = \$total + 25.',
      'Write \$total = \$total + 25.',
    ),
    paletteScope: palette,
  ));

  /* T3 — trace the box. The second distractor in most of these is the misconception
     itself, worded the way a child says it: "you cannot, x is not x plus five". */
  for (final entry in [
    (
      r'$x = 10' '\n' r'$x = $x + 5',
      'x',
      '15',
      '10',
      'C6.2-assignment-does-nothing',
      '5',
      'C6.2-right-side-only',
      '105',
      'C6.1-box-holds-history'
    ),
    (
      r'$x = 10' '\n' r'$x = $x + 5' '\n' r'$x = $x * 2',
      'x',
      '30',
      '25',
      'C6.2-operations-left-to-right',
      '20',
      'C6.2-assignment-does-nothing',
      '15',
      'C6.2-last-line-ignored'
    ),
    (
      r'$x = 12' '\n' r'$x = $x / 3',
      'x',
      '4',
      '12',
      'C6.2-false-equation',
      '36',
      'C6.2-arrow-points-backwards',
      '3',
      'C6.2-right-side-only'
    ),
    (
      r'$a = 3' '\n' r'$b = $a + 1' '\n' r'$a = 10',
      'b',
      '4',
      '11',
      'C6.1-copy-follows-original',
      '10',
      'C6.2-last-line-wins-everywhere',
      '3',
      'C6.2-right-side-only'
    ),
    (
      r'$t = 0' '\n' r'$t = $t + 10' '\n' r'$t = $t + 10' '\n' r'$t = $t + 10',
      't',
      '30',
      '10',
      'C6.2-assignment-does-nothing',
      '0',
      'C6.2-false-equation',
      '101010',
      'C6.1-box-holds-history'
    ),
    (
      r'$p = 8' '\n' r'$p = $p - 3' '\n' r'$p = $p - 3',
      'p',
      '2',
      '5',
      'C6.2-last-line-ignored',
      '8',
      'C6.2-assignment-does-nothing',
      '-6',
      'C6.2-right-side-only'
    ),
  ]) {
    final source = entry.$1, box = entry.$2, value = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C6.2',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Suis les lignes. Que vaut \${b} à la fin ?\n\n{p}',
            'Follow the lines. What is \${b} at the end?\n\n{p}'),
        {'b': box, 'p': source},
      ),
      choices: [
        Choice(labelKeys: b(value, value), correct: true),
        Choice(
            labelKeys: b(entry.$4, entry.$4),
            correct: false,
            misconception: entry.$5),
        Choice(
            labelKeys: b(entry.$6, entry.$6),
            correct: false,
            misconception: entry.$7),
        Choice(
            labelKeys: b(entry.$8, entry.$8),
            correct: false,
            misconception: entry.$9),
      ],
      itemHints: hints(
        'À droite du =, calcule d\'abord.',
        'On the right of the =, work it out first.',
        'Puis range le résultat dans la boîte.',
        'Then put the answer into the box.',
      ),
      wrongChoiceFr:
          'Le = range dans la boîte : on calcule la droite, puis on la remplit.',
      wrongChoiceEn:
          'The = puts into the box: work out the right side, then fill it.',
    ));
  }

  // T4 — the hole is the line that makes the box grow.
  for (final entry in [
    (20, 5, 72, 15, 'plus grand', 'bigger'),
    (15, 6, 60, 10, 'plus grand', 'bigger'),
    (90, 5, 72, -15, 'plus petit', 'smaller'),
    (10, 4, 90, 20, 'plus grand', 'bigger'),
    (30, 6, 60, 12, 'plus grand', 'bigger'),
  ]) {
    final start = entry.$1,
        turns = entry.$2,
        turn = entry.$3,
        step = entry.$4,
        wayFr = entry.$5,
        wayEn = entry.$6;
    final sign = step < 0 ? '-' : '+';
    final size = step.abs();
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C6.2',
      difficulty: Difficulty.d3,
      withHoles: '\$c = $start\nrépète $turns {\n  avance \$c\n'
          '  tournedroite $turn\n  ___\n}',
      solution: '\$c = $start\nrépète $turns {\n  avance \$c\n'
          '  tournedroite $turn\n  \$c = \$c $sign $size\n}',
      /* The two languages put the adjective in different places, so this one is filled
         per language rather than once: "plus grand de 15 pas" against "15 steps bigger".
         A single template with a shared hole would have produced English word order in
         French, which `FR-M15-01` treats as a translation bug, not a style one. */
      promptKeys: b(
        fill(
            'Complète pour que chaque trait soit {w} de {s} pas que le précédent.',
            {'w': wayFr, 's': size}),
        fill('Fill in the blank so each line is {s} steps {w} than the last.',
            {'w': wayEn, 's': size}),
      ),
      wrong: [
        '\$c = $start\nrépète $turns {\n  avance \$c\n'
            '  tournedroite $turn\n  \$c = $size\n}',
        '\$c = $start\nrépète $turns {\n  avance \$c\n'
            '  tournedroite $turn\n  \$c = \$c ${step < 0 ? '+' : '-'} $size\n}',
        '\$c = $start\nrépète $turns {\n  avance \$c\n'
            '  tournedroite $turn\n  \$c = \$c * $size\n}',
      ],
      assertions: [const UsesVariable(name: 'c', min: 2, minReads: 2)],
      itemHints: hints(
        'La boîte doit se souvenir de ce qu\'elle avait.',
        'The box has to remember what it had.',
        'Commence par \$c = \$c …',
        'Start with \$c = \$c …',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — what the equals sign does.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(r'Que veut dire le = dans $x = 7 ?',
        r'What does the = mean in $x = 7?'),
    choices: [
      Choice(
          labelKeys: b('Range 7 dans la boîte \$x.', 'Put 7 into the box \$x.'),
          correct: true),
      Choice(
          labelKeys: b('\$x et 7 sont pareils pour toujours.',
              '\$x and 7 are the same for ever.'),
          correct: false,
          misconception: 'C6.2-equals-is-a-fact'),
      Choice(
          labelKeys: b('Compare \$x avec 7.', 'Compare \$x with 7.'),
          correct: false,
          misconception: 'C6.2-equals-is-a-test'),
      Choice(
          labelKeys: b('Range \$x dans la boîte 7.', 'Put \$x into the box 7.'),
          correct: false,
          misconception: 'C6.2-arrow-points-backwards'),
    ],
    itemHints: hints(
      'Imagine une flèche qui part de la droite vers la gauche.',
      'Imagine an arrow going from the right to the left.',
      'Le nombre voyage vers la boîte.',
      'The number travels into the box.',
    ),
    wrongChoiceFr:
        'Le = range : la droite est calculée, la gauche est remplie.',
    wrongChoiceEn:
        'The = puts: the right side is worked out, the left side is filled.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(r'Dans quel ordre Tika lit-elle $x = $x + 1 ?',
        r'In what order does Tika read $x = $x + 1?'),
    choices: [
      Choice(
          labelKeys: b('Elle calcule \$x + 1, puis elle range le résultat.',
              'She works out \$x + 1, then puts the answer in.'),
          correct: true),
      Choice(
          labelKeys: b('Elle vide \$x, puis elle ajoute 1.',
              'She empties \$x, then adds 1.'),
          correct: false,
          misconception: 'C6.2-box-is-emptied-first'),
      Choice(
          labelKeys: b('Elle refuse : c\'est impossible.',
              'She refuses: it is impossible.'),
          correct: false,
          misconception: 'C6.2-false-equation'),
      Choice(
          labelKeys:
              b('Elle range \$x dans \$x + 1.', 'She puts \$x into \$x + 1.'),
          correct: false,
          misconception: 'C6.2-arrow-points-backwards'),
    ],
    itemHints: hints(
      'La droite d\'abord.',
      'The right side first.',
      'Le vieux nombre sert à calculer le nouveau.',
      'The old number is what the new one is worked out from.',
    ),
    wrongChoiceFr:
        'Tika lit la droite avec le vieux nombre, puis remplit la boîte.',
    wrongChoiceEn:
        'Tika reads the right side using the old number, then fills the box.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(
        r'$a = 4 puis $a = 9. Combien de nombres la boîte $a garde-t-elle ?',
        r'$a = 4 then $a = 9. How many numbers does the box $a keep?'),
    choices: [
      Choice(labelKeys: b('Un seul : 9.', 'Just one: 9.'), correct: true),
      Choice(
          labelKeys: b('Deux : 4 et 9.', 'Two: 4 and 9.'),
          correct: false,
          misconception: 'C6.1-box-holds-history'),
      Choice(
          labelKeys: b('Un seul : 4.', 'Just one: 4.'),
          correct: false,
          misconception: 'C6.1-first-value-wins'),
      Choice(
          labelKeys:
              b('Aucun : les deux s\'annulent.', 'None: the two cancel out.'),
          correct: false,
          misconception: 'C6.2-assignment-does-nothing'),
    ],
    itemHints: hints(
      'Une boîte a une seule place.',
      'A box has one space in it.',
      'Le deuxième nombre pousse le premier dehors.',
      'The second number pushes the first one out.',
    ),
    wrongChoiceFr: 'Ranger un nombre remplace celui qui était là.',
    wrongChoiceEn: 'Putting a number in replaces the one that was there.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(r'Tu écris avance $c avant la ligne $c = 40. Que fait Tika ?',
        r'You write forward $c before the line $c = 40. What does Tika do?'),
    choices: [
      Choice(
          labelKeys: b('Elle s\'arrête : la boîte est encore vide.',
              'She stops: the box is still empty.'),
          correct: true),
      Choice(
          labelKeys: b('Elle avance de 40 quand même.', 'She moves 40 anyway.'),
          correct: false,
          misconception: 'C6.2-lines-are-read-out-of-order'),
      Choice(
          labelKeys: b('Elle avance de 0.', 'She moves 0.'),
          correct: false,
          misconception: 'C6.1-box-is-empty'),
      Choice(
          labelKeys: b('Elle descend chercher la ligne plus bas.',
              'She jumps down to find the line below.'),
          correct: false,
          misconception: 'C6.2-lines-are-read-out-of-order'),
    ],
    itemHints: hints(
      'Tika lit une ligne après l\'autre.',
      'Tika reads one line after another.',
      'Une boîte qu\'on n\'a pas remplie n\'existe pas encore.',
      'A box that has not been filled does not exist yet.',
    ),
    wrongChoiceFr:
        'Tika lit de haut en bas : la boîte doit être remplie avant.',
    wrongChoiceEn: 'Tika reads top to bottom: the box has to be filled first.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      r'À l’école, $x = $x / 3 serait faux. Pourquoi est-ce correct en KODO ?',
      r'At school, $x = $x / 3 would be false. Why is it fine in KODO?',
    ),
    choices: [
      Choice(
          labelKeys: b('Parce que le = range un résultat, il ne compare pas.',
              'Because the = puts a result in, it does not compare.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que KODO se trompe exprès.',
              'Because KODO gets it wrong on purpose.'),
          correct: false,
          misconception: 'C6.2-false-equation'),
      Choice(
          labelKeys: b('Parce que \$x vaut zéro.', 'Because \$x is zero.'),
          correct: false,
          misconception: 'C6.1-box-is-empty'),
      Choice(
          labelKeys: b('Parce qu\'on ne divise jamais vraiment.',
              'Because nothing is really divided.'),
          correct: false,
          misconception: 'C6.2-assignment-does-nothing'),
    ],
    itemHints: hints(
      'En maths, = dit « c\'est pareil ».',
      'In maths, = says "these are the same".',
      'En KODO, = dit « mets ça là ».',
      'In KODO, = says "put this there".',
    ),
    wrongChoiceFr:
        'Les deux = ne disent pas la même chose : celui de KODO range.',
    wrongChoiceEn: 'The two = do not say the same thing: KODO\'s one puts.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi faut-il remplir la boîte avant la boucle et non dedans ?',
      'Why does the box have to be filled before the loop, not inside it?',
    ),
    choices: [
      Choice(
          labelKeys: b('Dedans, elle repart du même nombre à chaque tour.',
              'Inside, it starts from the same number every turn.'),
          correct: true),
      Choice(
          labelKeys: b('Dedans, la boucle tourne moins vite.',
              'Inside, the loop runs slower.'),
          correct: false,
          misconception: 'C6.1-box-is-speed'),
      Choice(
          labelKeys: b('Dedans, Tika ne voit pas la boîte.',
              'Inside, Tika cannot see the box.'),
          correct: false,
          misconception: 'C6.4-box-is-invisible'),
      Choice(
          labelKeys: b('Ça ne change rien.', 'It makes no difference.'),
          correct: false,
          misconception: 'C6.2-assignment-does-nothing'),
    ],
    itemHints: hints(
      'Une ligne dans la boucle est jouée à chaque tour.',
      'A line inside the loop is played every turn.',
      'Elle efface ce que le tour d\'avant avait ajouté.',
      'It wipes out what the last turn had added.',
    ),
    wrongChoiceFr: 'Remplir dans la boucle efface la valeur du tour précédent.',
    wrongChoiceEn:
        'Filling it inside the loop wipes out the previous turn\'s value.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.2',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      r'Pourquoi $total = $total + 25 est-il utile ?',
      r'Why is $total = $total + 25 useful?',
    ),
    choices: [
      Choice(
          labelKeys: b('La boîte garde ce qu\'elle avait et y ajoute 25.',
              'The box keeps what it had and adds 25 to it.'),
          correct: true),
      Choice(
          labelKeys: b('Ça remet la boîte à 25.', 'It resets the box to 25.'),
          correct: false,
          misconception: 'C6.2-right-side-only'),
      Choice(
          labelKeys: b('Ça crée une deuxième boîte.', 'It makes a second box.'),
          correct: false,
          misconception: 'C6.2-assignment-makes-a-new-box'),
      Choice(
          labelKeys: b(
              'Ça compare le total avec 25.', 'It compares the total with 25.'),
          correct: false,
          misconception: 'C6.2-equals-is-a-test'),
    ],
    itemHints: hints(
      'Le vieux total est du côté droit.',
      'The old total is on the right side.',
      'Il sert à calculer le nouveau.',
      'It is what the new one is worked out from.',
    ),
    wrongChoiceFr:
        'Le vieux nombre sert au calcul, puis le nouveau prend sa place.',
    wrongChoiceEn:
        'The old number is used in the sum, then the new one takes its place.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C6.3 — Opérateurs mathématiques.
// Misconception: "operations always run left to right".
//
// A calculator with no brackets reads left to right, and most children have used one. The
// answer is not a rule recited but a pair: the same three numbers, with and without
// brackets, giving two different figures on the canvas. `2 + 3 * 4` is 14 and `(2 + 3) * 4`
// is 20, and a square of 14 next to a square of 20 is an argument a child can see.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC63() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C6.3-${(++n).toString().padLeft(2, '0')}';

  /* T1 — the side of the figure is a sum, not a number. Every distractor list carries the
     same three shapes of mistake: the box was never opened, the sum was read left to
     right, or the figure has the wrong number of sides. */
  for (final entry in [
    ('c', '20 * 3', 60, '20 + 3', 4, 90),
    ('côté', '100 / 2', 50, '100 - 2', 3, 120),
    ('pas', '15 + 15 + 15', 45, '15 + 15', 6, 60),
    ('long', '2 * 20 + 10', 50, '2 * 30', 5, 72),
    ('mesure', '90 - 20 * 2', 50, '70 * 2', 4, 90),
  ]) {
    final name = entry.$1,
        sum = entry.$2,
        value = entry.$3,
        wrongSum = entry.$4,
        sides = entry.$5,
        turn = entry.$6;
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C6.3',
      difficulty: Difficulty.d3,
      solution: '\$$name = $sum\n'
          'répète $sides {\n  avance \$$name\n  tournedroite $turn\n}',
      promptKeys: fillBoth(
        b(
            'Mets le résultat de {s} dans la boîte \${n}, puis dessine la '
                'figure à {k} côtés avec.',
            'Put the answer to {s} into the box \${n}, then draw the '
                '{k}-sided shape with it.'),
        {'s': sum, 'n': name, 'k': sides},
      ),
      wrong: [
        // The answer, written straight out: right figure, no box.
        'répète $sides {\n  avance $value\n  tournedroite $turn\n}',
        // The sum read the way a pocket calculator reads it.
        '\$$name = $wrongSum\n'
            'répète $sides {\n  avance \$$name\n  tournedroite $turn\n}',
        /* One side SHORT, not one long: an extra turn round a closed figure retraces
           the first side and leaves the ink identical, so "répète 5" on a square is a
           wrong answer that draws the right picture. The gate caught all five. */
        '\$$name = $sum\n'
            'répète ${sides - 1} {\n  avance \$$name\n  tournedroite $turn\n}',
      ],
      assertions: [UsesVariable(name: name, minReads: 1)],
      itemHints: hints(
        'Calcule d\'abord, range ensuite.',
        'Work it out first, then put it away.',
        '× et ÷ passent avant + et −.',
        '× and ÷ go before + and −.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — the same six sums a calculator would get wrong. The first distractor is always
     the left-to-right answer, which is the misconception stated as a number. */
  for (final entry in [
    ('2 + 3 * 4', '14', '20', '9', '24'),
    ('10 - 2 * 3', '4', '24', '6', '30'),
    ('100 / 4 + 5', '30', 'environ 11', '25', '105'),
    ('2 * 3 + 4 * 5', '26', '50', '70', '120'),
    ('(2 + 3) * 4', '20', '14', '9', '24'),
    ('3 + 4 * 2 - 1', '10', '13', '11', '7'),
  ]) {
    final sum = entry.$1, value = entry.$2;
    // "environ 11" is the only label that differs between the languages, because the
    // number itself does not: 100 / (4 + 5) is 11.111…, and a child is owed a readable
    // wrong answer rather than a row of decimals.
    final l2r = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C6.3',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Que va écrire Tika ?\n\nécris {s}',
            'What will Tika print?\n\nprint {s}'),
        {'s': sum},
      ),
      choices: [
        Choice(labelKeys: b(value, value), correct: true),
        Choice(
            labelKeys: b(l2r, l2r == 'environ 11' ? 'about 11' : l2r),
            correct: false,
            misconception: 'C6.3-left-to-right'),
        Choice(
            labelKeys: b(entry.$4, entry.$4),
            correct: false,
            misconception: 'C6.3-wrong-operator-first'),
        Choice(
            labelKeys: b(entry.$5, entry.$5),
            correct: false,
            misconception: 'C6.3-everything-multiplied'),
      ],
      itemHints: hints(
        'Cherche d\'abord les × et les ÷.',
        'Look for the × and ÷ first.',
        'Les parenthèses passent avant tout le reste.',
        'Brackets go before everything else.',
      ),
      wrongChoiceFr:
          'Tika fait les × et les ÷ avant les + et les −, et les parenthèses avant tout.',
      wrongChoiceEn:
          'Tika does × and ÷ before + and −, and brackets before anything else.',
    ));
  }

  /* T4 — the hole is the operator. Four signs, one figure: the child has to work out
     which sign lands on the right length rather than recognise a number. */
  for (final entry in [
    (20, '*', 3, 60, 4, 90, ['20 + 3', '20 - 3', '20 / 3']),
    (15, '*', 4, 60, 6, 60, ['15 + 4', '15 - 4', '15 / 4']),
    (90, '-', 30, 60, 3, 120, ['90 + 30', '90 / 30', '30 - 90']),
    (180, '/', 3, 60, 5, 72, ['180 - 3', '180 + 3', '3 / 180']),
    (20, '+', 40, 60, 4, 90, ['20 - 40', '20 * 40', '20 / 40']),
  ]) {
    final left = entry.$1,
        op = entry.$2,
        right = entry.$3,
        value = entry.$4,
        sides = entry.$5,
        turn = entry.$6,
        wrongSums = entry.$7;
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C6.3',
      difficulty: Difficulty.d3,
      withHoles: '\$c = $left ___ $right\n'
          'répète $sides {\n  avance \$c\n  tournedroite $turn\n}',
      solution: '\$c = $left $op $right\n'
          'répète $sides {\n  avance \$c\n  tournedroite $turn\n}',
      promptKeys: fillBoth(
        b('Quel signe donne un côté de {v} pas ?',
            'Which sign gives a side of {v} steps?'),
        {'v': value},
      ),
      wrong: [
        for (final sum in wrongSums)
          '\$c = $sum\nrépète $sides {\n  avance \$c\n  tournedroite $turn\n}',
      ],
      assertions: [const UsesVariable(name: 'c', minReads: 1)],
      itemHints: hints(
        'Essaie les quatre signes dans ta tête.',
        'Try the four signs in your head.',
        'Il faut arriver à $value.',
        'You need to land on $value.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Dans 2 + 3 × 4, que fait Tika en premier ?',
        'In 2 + 3 × 4, what does Tika do first?'),
    choices: [
      Choice(labelKeys: b('3 × 4', '3 × 4'), correct: true),
      Choice(
          labelKeys: b('2 + 3', '2 + 3'),
          correct: false,
          misconception: 'C6.3-left-to-right'),
      Choice(
          labelKeys: b('2 × 4', '2 × 4'),
          correct: false,
          misconception: 'C6.3-ends-first'),
      Choice(
          labelKeys: b('Tout en même temps.', 'All of it at once.'),
          correct: false,
          misconception: 'C6.3-no-order'),
    ],
    itemHints: hints(
      'Une multiplication est plus pressée qu\'une addition.',
      'A multiplication is in more of a hurry than an addition.',
      'Elle fait 3 × 4, puis elle ajoute 2.',
      'She does 3 × 4, then adds 2.',
    ),
    wrongChoiceFr: 'Tika fait la multiplication avant l\'addition.',
    wrongChoiceEn: 'Tika does the multiplication before the addition.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('À quoi servent les parenthèses ?', 'What are brackets for?'),
    choices: [
      Choice(
          labelKeys: b('À dire ce qui se calcule en premier.',
              'To say what is worked out first.'),
          correct: true),
      Choice(
          labelKeys:
              b('À rendre le calcul plus joli.', 'To make the sum look nicer.'),
          correct: false,
          misconception: 'C6.3-brackets-are-decoration'),
      Choice(
          labelKeys: b('À multiplier ce qu\'elles entourent.',
              'To multiply whatever is inside them.'),
          correct: false,
          misconception: 'C6.3-brackets-multiply'),
      Choice(
          labelKeys: b('À rien : le résultat est le même.',
              'Nothing: the answer is the same.'),
          correct: false,
          misconception: 'C6.3-brackets-are-decoration'),
    ],
    itemHints: hints(
      'Compare 2 + 3 × 4 et (2 + 3) × 4.',
      'Compare 2 + 3 × 4 with (2 + 3) × 4.',
      'L\'un fait 14, l\'autre 20.',
      'One is 14, the other is 20.',
    ),
    wrongChoiceFr: 'Les parenthèses changent l\'ordre, donc le résultat.',
    wrongChoiceEn: 'Brackets change the order, and so the answer.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(r'Que vaut $c après $c = 12 / 4 / 3 ?',
        r'What is $c after $c = 12 / 4 / 3?'),
    choices: [
      Choice(labelKeys: b('1', '1'), correct: true),
      Choice(
          labelKeys: b('9', '9'),
          correct: false,
          misconception: 'C6.3-right-to-left'),
      Choice(
          labelKeys: b('16', '16'),
          correct: false,
          misconception: 'C6.3-wrong-operator-first'),
      Choice(
          labelKeys: b('12', '12'),
          correct: false,
          misconception: 'C6.2-assignment-does-nothing'),
    ],
    itemHints: hints(
      'Deux divisions de suite : par où commencer ?',
      'Two divisions in a row: where do you start?',
      'À signes égaux, Tika va de gauche à droite : 12 ÷ 4 = 3, puis 3 ÷ 3.',
      'With equal signs Tika goes left to right: 12 ÷ 4 = 3, then 3 ÷ 3.',
    ),
    wrongChoiceFr:
        'Quand les signes sont de même force, Tika lit de gauche à droite.',
    wrongChoiceEn:
        'When the signs are equally strong, Tika reads left to right.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(r'Que fait mod 17, 5 ?', r'What does mod 17, 5 do?'),
    choices: [
      Choice(
          labelKeys: b('Il donne le reste : 2.', 'It gives the remainder: 2.'),
          correct: true),
      Choice(
          labelKeys:
              b('Il donne 17 ÷ 5, soit 3,4.', 'It gives 17 ÷ 5, which is 3.4.'),
          correct: false,
          misconception: 'C6.3-mod-is-division'),
      Choice(
          labelKeys:
              b('Il donne 3, la part entière.', 'It gives 3, the whole part.'),
          correct: false,
          misconception: 'C6.3-mod-is-division'),
      Choice(
          labelKeys: b('Il donne 12.', 'It gives 12.'),
          correct: false,
          misconception: 'C6.3-mod-is-subtraction'),
    ],
    itemHints: hints(
      'Partage 17 en paquets de 5.',
      'Share 17 out in packets of 5.',
      'Il reste 2 qui ne rentrent nulle part.',
      'There are 2 left over that fit nowhere.',
    ),
    wrongChoiceFr: 'mod donne ce qui reste après le partage, pas le partage.',
    wrongChoiceEn: 'mod gives what is left after sharing, not the share.',
  ));

  /* T7 — golf. Both budgets are four blocks, and four blocks is exactly enough for
     "fill a box, then loop". Writing the figure out side by side takes eight, so the
     budget is what forces the arithmetic rather than a sentence telling the child to
     use it. */
  items.add(golf(
    id: id(),
    conceptId: 'C6.3',
    difficulty: Difficulty.d3,
    solution: '\$c = 20 * 3\nrépète 4 {\n  avance \$c\n  tournedroite 90\n}',
    budget: 4,
    promptKeys: b('Dessine le carré de 60 pas en 4 blocs au maximum.',
        'Draw the 60-step square in 4 blocks or fewer.'),
    wrong: [
      // The long way: right picture, eight blocks.
      'avance 60\ntournedroite 90\navance 60\ntournedroite 90\n'
          'avance 60\ntournedroite 90\navance 60\ntournedroite 90',
      '\$c = 20 + 3\nrépète 4 {\n  avance \$c\n  tournedroite 90\n}',
      '\$c = 20 * 3\nrépète 3 {\n  avance \$c\n  tournedroite 90\n}',
    ],
    assertions: [const UsesVariable(name: 'c', minReads: 1)],
    itemHints: hints(
      'Une boîte et une boucle, ça fait déjà beaucoup.',
      'One box and one loop already does a lot.',
      '60, c\'est 20 × 3.',
      '60 is 20 × 3.',
    ),
    paletteScope: palette,
  ));
  items.add(golf(
    id: id(),
    conceptId: 'C6.3',
    difficulty: Difficulty.d3,
    solution: '\$a = 360 / 12\nrépète 12 {\n  avance 30\n  tournedroite \$a\n}',
    budget: 4,
    promptKeys: b(
        'Dessine la figure à 12 côtés de 30 pas en 4 blocs au maximum. Trouve l\'angle avec un calcul.',
        'Draw the 12-sided shape with 30-step sides in 4 blocks or fewer. Work the angle out with a sum.'),
    wrong: [
      '\$a = 360 / 12\nrépète 12 {\n  avance 30\n  tournedroite 12\n}',
      '\$a = 12 / 360\nrépète 12 {\n  avance 30\n  tournedroite \$a\n}',
      '\$a = 360 - 12\nrépète 12 {\n  avance 30\n  tournedroite \$a\n}',
    ],
    assertions: [const UsesVariable(name: 'a', minReads: 1)],
    itemHints: hints(
      'Un tour complet fait 360°.',
      'A full turn is 360°.',
      'Partage 360 en 12.',
      'Share 360 into 12.',
    ),
    paletteScope: palette,
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C6.4 — Utiliser l'inspecteur.
// Misconception: "I cannot see what is inside a variable".
//
// The inspector is M4's, and it shows every box and its value while the program runs. An
// item cannot drive the inspector, so what these items train is the same habit in the
// form the grader can see: **print the box, do not retype the number you think is in it.**
// That is why nearly every item here carries a `UsesVariable` assertion with a read count.
// The distractor that prints the right number as a literal is the misconception — a child
// who believes the box is invisible will always answer by guessing its contents aloud.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC64() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C6.4-${(++n).toString().padLeft(2, '0')}';

  // T2 — four programs that look in the wrong place, or at the wrong moment.

  // 1. Looking in the wrong box.
  items.add(fixTheBug(
    id: id(),
    conceptId: 'C6.4',
    difficulty: Difficulty.d2,
    broken: '\$a = 3\n\$b = 8\nécris \$a',
    solution: '\$a = 3\n\$b = 8\nécris \$b',
    promptKeys: b(
        'Tu veux voir ce qu\'il y a dans \$b. Corrige la dernière ligne.',
        'You want to see what is inside \$b. Fix the last line.'),
    wrong: [
      // Says 8 without ever opening the box. Right answer, wrong habit.
      '\$a = 3\n\$b = 8\nécris 8',
      '\$a = 3\n\$b = 8\nécris \$a + \$b',
      '\$a = 3\n\$b = 8\nécris \$b + 1',
    ],
    assertions: [UsesVariable(name: 'b', minReads: 1)],
    alternatives: printedAlternatives('\$a = 3\n\$b = 8\nécris \$b'),
    itemHints: hints(
      'Deux boîtes, deux noms.',
      'Two boxes, two names.',
      'Celle que tu veux voir s\'appelle \$b.',
      'The one you want to see is called \$b.',
    ),
    paletteScope: palette,
  ));

  // 2. Looking before there is anything to look at.
  items.add(fixTheBug(
    id: id(),
    conceptId: 'C6.4',
    difficulty: Difficulty.d2,
    broken: 'écris \$t\n\$t = 5',
    solution: '\$t = 5\nécris \$t',
    promptKeys: b('Tika s\'arrête. Mets les deux lignes dans le bon ordre.',
        'Tika stops. Put the two lines in the right order.'),
    wrong: [
      '\$t = 5\nécris 5',
      '\$t = 5\nécris \$t + 1',
      '\$t = 5\nécris \$t * 2',
    ],
    assertions: [UsesVariable(name: 't', minReads: 1)],
    alternatives: printedAlternatives('\$t = 5\nécris \$t'),
    itemHints: hints(
      'On ne peut pas regarder dans une boîte qui n\'existe pas.',
      'You cannot look inside a box that does not exist.',
      'Remplis-la d\'abord.',
      'Fill it first.',
    ),
    paletteScope: palette,
  ));

  // 3. Looking every turn instead of once at the end.
  items.add(fixTheBug(
    id: id(),
    conceptId: 'C6.4',
    difficulty: Difficulty.d3,
    broken: '\$t = 0\nrépète 3 {\n  \$t = \$t + 10\n  écris \$t\n}',
    solution: '\$t = 0\nrépète 3 {\n  \$t = \$t + 10\n}\nécris \$t',
    promptKeys: b('Tu ne veux voir le total qu\'une fois, à la fin.',
        'You only want to see the total once, at the end.'),
    wrong: [
      '\$t = 0\nrépète 3 {\n  \$t = \$t + 10\n}\nécris 30',
      '\$t = 0\nécris \$t\nrépète 3 {\n  \$t = \$t + 10\n}',
      '\$t = 0\nrépète 3 {\n  \$t = \$t + 10\n}\nécris \$t * 2',
    ],
    assertions: [UsesVariable(name: 't', minReads: 2)],
    alternatives: printedAlternatives(
        '\$t = 0\nrépète 3 {\n  \$t = \$t + 10\n}\nécris \$t'),
    itemHints: hints(
      'Une ligne dans la boucle est jouée à chaque tour.',
      'A line inside the loop is played every turn.',
      'Sors le écris de la boucle.',
      'Move the print out of the loop.',
    ),
    paletteScope: palette,
  ));

  // 4. Looking before the change instead of after it.
  items.add(fixTheBug(
    id: id(),
    conceptId: 'C6.4',
    difficulty: Difficulty.d3,
    broken: '\$c = 10\nécris \$c\n\$c = \$c * 4',
    solution: '\$c = 10\n\$c = \$c * 4\nécris \$c',
    promptKeys: b('Tu veux voir la boîte après le calcul, pas avant.',
        'You want to see the box after the sum, not before it.'),
    wrong: [
      '\$c = 10\n\$c = \$c * 4\nécris 40',
      '\$c = 10\n\$c = \$c * 4\nécris \$c + 4',
      '\$c = 10\n\$c = \$c + 4\nécris \$c',
    ],
    assertions: [UsesVariable(name: 'c', minReads: 2)],
    alternatives: printedAlternatives('\$c = 10\n\$c = \$c * 4\nécris \$c'),
    itemHints: hints(
      'L\'inspecteur montre la boîte au moment où on regarde.',
      'The inspector shows the box at the moment you look.',
      'Regarde après la ligne du calcul.',
      'Look after the line with the sum.',
    ),
    paletteScope: palette,
  ));

  /* T3 — five snapshots. The question is always "at this exact line, what does the
     inspector show", because the answer to "is the box visible" is a habit of looking at
     a moment, not a fact to memorise. */
  for (final entry in [
    (
      r'$a = 2' '\n' r'$a = $a * 5' '\n' '← ici',
      'a',
      '10',
      '2',
      'C6.2-assignment-does-nothing',
      '7',
      'C6.3-wrong-operator-first',
      'on ne peut pas savoir',
      'C6.4-box-is-invisible'
    ),
    (
      r'$n = 6' '\n' '← ici\n' r'$n = 1',
      'n',
      '6',
      '1',
      'C6.4-inspector-shows-the-end',
      '7',
      'C6.1-boxes-add-up',
      'on ne peut pas savoir',
      'C6.4-box-is-invisible'
    ),
    (
      r'$x = 4' '\n' r'$y = $x' '\n' r'$x = 0' '\n' '← ici',
      'y',
      '4',
      '0',
      'C6.1-copy-follows-original',
      '4 et 0',
      'C6.1-box-holds-history',
      'on ne peut pas savoir',
      'C6.4-box-is-invisible'
    ),
    (
      r'$t = 0' '\n' 'répète 2 {\n' r'  $t = $t + 7' '\n}\n← ici',
      't',
      '14',
      '7',
      'C6.2-loop-runs-once',
      '0',
      'C6.2-assignment-does-nothing',
      'on ne peut pas savoir',
      'C6.4-box-is-invisible'
    ),
    (
      r'$p = 20' '\n' r'$q = 3' '\n' r'$p = $p / $q' '\n' '← ici',
      'q',
      '3',
      '6',
      'C6.4-inspector-shows-the-wrong-box',
      '20',
      'C6.4-inspector-shows-the-wrong-box',
      'on ne peut pas savoir',
      'C6.4-box-is-invisible'
    ),
  ]) {
    final source = entry.$1, box = entry.$2, value = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C6.4',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('À la flèche, que montre l\'inspecteur pour \${b} ?\n\n{p}',
            'At the arrow, what does the inspector show for \${b}?\n\n{p}'),
        {'b': box, 'p': source},
      ),
      choices: [
        Choice(labelKeys: b(value, value), correct: true),
        Choice(
            labelKeys: b(entry.$4, entry.$4),
            correct: false,
            misconception: entry.$5),
        Choice(
            labelKeys: b(entry.$6, entry.$6 == '4 et 0' ? '4 and 0' : entry.$6),
            correct: false,
            misconception: entry.$7),
        Choice(
            labelKeys: b('on ne peut pas savoir', 'there is no way to know'),
            correct: false,
            misconception: 'C6.4-box-is-invisible'),
      ],
      itemHints: hints(
        'Arrête-toi exactement à la flèche.',
        'Stop exactly at the arrow.',
        'L\'inspecteur montre ce qu\'il y a à ce moment-là.',
        'The inspector shows what is there at that moment.',
      ),
      wrongChoiceFr:
          'L\'inspecteur montre le contenu de chaque boîte, à la ligne où tu t\'arrêtes.',
      wrongChoiceEn:
          'The inspector shows each box\'s contents, at the line you stop on.',
    ));
  }

  // T4 — the hole is which box to look into.
  for (final entry in [
    ('\$a = 6\n\$b = 9', 'b', '9', ['\$a', '9', '\$a + \$b']),
    ('\$prix = 12\n\$nb = 4', 'prix', '12', ['\$nb', '12', '\$prix * \$nb']),
    ('\$g = 5\n\$g = \$g + 5', 'g', '10', ['5', '\$g + 5', '\$g * 2']),
  ]) {
    final setup = entry.$1, box = entry.$2, value = entry.$3, wrongs = entry.$4;
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C6.4',
      difficulty: Difficulty.d2,
      withHoles: '$setup\nécris ___',
      solution: '$setup\nécris \$$box',
      promptKeys: fillBoth(
        b('Complète pour voir ce qu\'il y a dans \${b}.',
            'Fill in the blank to see what is inside \${b}.'),
        {'b': box},
      ),
      wrong: [for (final w in wrongs) '$setup\nécris $w'],
      assertions: [
        UsesVariable(name: box, minReads: box == 'g' ? 2 : 1),
      ],
      alternatives: printedAlternatives('$setup\nécris \$$box'),
      itemHints: hints(
        'Le \$ ouvre la boîte.',
        'The \$ opens the box.',
        'Écris \$$box, et pas $value.',
        'Write \$$box, not $value.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d1,
    promptKeys:
        b('Que montre l\'inspecteur ?', 'What does the inspector show?'),
    choices: [
      Choice(
          labelKeys: b('Le contenu de chaque boîte pendant que ça tourne.',
              'What is in each box while the program runs.'),
          correct: true),
      Choice(
          labelKeys: b('Rien : une boîte est invisible.',
              'Nothing: a box is invisible.'),
          correct: false,
          misconception: 'C6.4-box-is-invisible'),
      Choice(
          labelKeys: b('Le dessin en plus grand.', 'The drawing, bigger.'),
          correct: false,
          misconception: 'C6.4-inspector-is-a-zoom'),
      Choice(
          labelKeys: b('La liste des blocs du programme.',
              'The list of the program\'s blocks.'),
          correct: false,
          misconception: 'C6.4-inspector-is-the-code'),
    ],
    itemHints: hints(
      'Regarde le panneau à côté du dessin.',
      'Look at the panel next to the drawing.',
      'Les noms des boîtes y sont, avec leur nombre.',
      'The box names are there, with their numbers.',
    ),
    wrongChoiceFr:
        'L\'inspecteur affiche chaque boîte et le nombre qu\'elle contient.',
    wrongChoiceEn: 'The inspector lists each box and the number inside it.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Ta spirale ne grandit pas. Que fais-tu en premier ?',
        'Your spiral does not grow. What do you do first?'),
    choices: [
      Choice(
          labelKeys: b('Je regarde la boîte dans l\'inspecteur.',
              'I look at the box in the inspector.'),
          correct: true),
      Choice(
          labelKeys: b('Je recommence tout le programme.',
              'I start the whole program again.'),
          correct: false,
          misconception: 'C6.4-debug-by-rewriting'),
      Choice(
          labelKeys: b('Je change les nombres au hasard.',
              'I change the numbers at random.'),
          correct: false,
          misconception: 'C6.4-debug-by-guessing'),
      Choice(
          labelKeys: b('J\'attends : ça va peut-être marcher.',
              'I wait: maybe it will work.'),
          correct: false,
          misconception: 'C6.4-debug-by-waiting'),
    ],
    itemHints: hints(
      'La spirale grandit si la boîte grandit.',
      'The spiral grows if the box grows.',
      'Va vérifier si elle grandit vraiment.',
      'Go and check whether it really grows.',
    ),
    wrongChoiceFr:
        'Regarder la boîte dit tout de suite si elle grandit ou non.',
    wrongChoiceEn:
        'Looking at the box says straight away whether it grows or not.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(
        'L\'inspecteur affiche \$c : 20 pendant toute la boucle. Qu\'est-ce que ça t\'apprend ?',
        'The inspector shows \$c: 20 for the whole loop. What does that tell you?'),
    choices: [
      Choice(
          labelKeys: b('La boîte n\'est jamais changée dans la boucle.',
              'The box is never changed inside the loop.'),
          correct: true),
      Choice(
          labelKeys: b('L\'inspecteur est cassé.', 'The inspector is broken.'),
          correct: false,
          misconception: 'C6.4-inspector-is-unreliable'),
      Choice(
          labelKeys: b(
              'La boucle ne tourne qu\'une fois.', 'The loop only runs once.'),
          correct: false,
          misconception: 'C6.2-loop-runs-once'),
      Choice(
          labelKeys: b('C\'est normal : une boîte ne change jamais.',
              'That is normal: a box never changes.'),
          correct: false,
          misconception: 'C6.2-assignment-does-nothing'),
    ],
    itemHints: hints(
      'Une boîte change seulement quand une ligne la remplit.',
      'A box only changes when a line fills it.',
      'Cherche la ligne qui manque dans la boucle.',
      'Look for the line missing from the loop.',
    ),
    wrongChoiceFr:
        'Un nombre qui ne bouge pas veut dire qu\'aucune ligne ne le range.',
    wrongChoiceEn:
        'A number that does not move means no line is putting into it.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Pourquoi écrire \$b plutôt que le nombre que tu crois qu\'il y a dedans ?',
        'Why print \$b rather than the number you think is inside it?'),
    choices: [
      Choice(
          labelKeys: b('Parce que la boîte dit la vérité, pas toi.',
              'Because the box tells the truth, and you might not.'),
          correct: true),
      Choice(
          labelKeys:
              b('Parce que c\'est plus court.', 'Because it is shorter.'),
          correct: false,
          misconception: 'C6.1-box-is-shorthand'),
      Choice(
          labelKeys: b('Parce que les nombres sont interdits.',
              'Because numbers are not allowed.'),
          correct: false,
          misconception: 'C6.4-literals-are-forbidden'),
      Choice(
          labelKeys: b('Ça revient exactement au même.',
              'It comes to exactly the same thing.'),
          correct: false,
          misconception: 'C6.4-box-is-invisible'),
    ],
    itemHints: hints(
      'Si tu te trompes, le nombre écrit ne te le dira pas.',
      'If you are wrong, the typed number will not tell you.',
      'La boîte, elle, montre ce qui y est vraiment.',
      'The box shows what is really there.',
    ),
    wrongChoiceFr:
        'Écrire le nombre à la main cache justement l\'erreur que tu cherches.',
    wrongChoiceEn:
        'Typing the number by hand hides the very mistake you are hunting.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.4',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Un ami dit : « on ne peut pas savoir ce qu\'il y a dans une boîte ». Que réponds-tu ?',
      'A friend says: "there is no way to know what is inside a box". What do you answer?',
    ),
    choices: [
      Choice(
          labelKeys: b('On peut : l\'inspecteur le montre, ou on l\'écrit.',
              'You can: the inspector shows it, or you print it.'),
          correct: true),
      Choice(
          labelKeys:
              b('C\'est vrai, il faut deviner.', 'True, you have to guess.'),
          correct: false,
          misconception: 'C6.4-box-is-invisible'),
      Choice(
          labelKeys: b('C\'est vrai, sauf pour la première boîte.',
              'True, except for the first box.'),
          correct: false,
          misconception: 'C6.4-box-is-invisible'),
      Choice(
          labelKeys:
              b('On le voit dans le dessin.', 'You can see it in the drawing.'),
          correct: false,
          misconception: 'C6.1-box-holds-the-drawing'),
    ],
    itemHints: hints(
      'Il y a un panneau qui liste les boîtes.',
      'There is a panel that lists the boxes.',
      'Et une instruction qui les affiche : écris.',
      'And an instruction that shows them: print.',
    ),
    wrongChoiceFr:
        'Deux moyens de voir dedans : le panneau de l\'inspecteur, et écris.',
    wrongChoiceEn: 'Two ways to see inside: the inspector panel, and print.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.4',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi regarder dans la boîte avant de changer le programme ?',
      'Why look inside the box before changing the program?',
    ),
    choices: [
      Choice(
          labelKeys: b('Pour savoir où est l\'erreur avant de toucher à tout.',
              'To know where the mistake is before changing everything.'),
          correct: true),
      Choice(
          labelKeys: b('Parce qu\'il faut toujours regarder avant.',
              'Because you always have to look first.'),
          correct: false,
          misconception: 'C6.4-inspector-is-a-ritual'),
      Choice(
          labelKeys: b('Pour que le programme aille plus vite.',
              'To make the program run faster.'),
          correct: false,
          misconception: 'C6.1-box-is-speed'),
      Choice(
          labelKeys: b('Ça ne sert à rien, autant tout réécrire.',
              'It is pointless, you may as well rewrite it.'),
          correct: false,
          misconception: 'C6.4-debug-by-rewriting'),
    ],
    itemHints: hints(
      'Réécrire au hasard peut casser ce qui marchait.',
      'Rewriting at random can break what was working.',
      'Regarder d\'abord dit quelle ligne est en cause.',
      'Looking first says which line is at fault.',
    ),
    wrongChoiceFr:
        'Regarder d\'abord montre la ligne fautive ; réécrire en cache d\'autres.',
    wrongChoiceEn:
        'Looking first shows the faulty line; rewriting hides new ones.',
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C6.5 — Hasard.
// Misconception: "random means unpredictable therefore untestable".
//
// This is the one misconception in KODO that the *product* refutes rather than the
// content. `hasard` runs off a seeded generator, so the same program on the same item
// gives the same number every time — which is why an item here can have a right answer
// at all. Every expected value below was read off the interpreter at the item seed, and
// the distractor a child who holds the misconception reaches for is always there, worded
// the way they would word it: "on ne peut pas savoir".
//
// What this must not teach is that `hasard` is fake. It is a real draw; it is the *seed*
// that is fixed while an exercise is being marked, exactly as a class all rolling the
// same dice would.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC65() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C6.5-${(++n).toString().padLeft(2, '0')}';

  /* T1 — a figure whose size or sides come from a draw. The distractor that matters is
     the third: it puts the drawn number straight into the box and draws the identical
     figure. Only `UsesOpcode('RANDOM')` can tell the two apart, which is the point — a
     child who "gets the right picture" by copying the number has not used the dice. */
  for (final entry in [
    ('t', 'hasard 30, 60', 48, 4, 90, 'hasard 20, 80'),
    ('t', 'hasard 40, 70', 58, 3, 120, 'hasard 30, 90'),
    ('t', 'hasard 10, 50', 25, 6, 60, 'hasard 5, 15'),
    ('c', 'hasard 25, 75', 43, 5, 72, 'hasard 1, 100'),
  ]) {
    final name = entry.$1,
        draw = entry.$2,
        value = entry.$3,
        sides = entry.$4,
        turn = entry.$5,
        otherDraw = entry.$6;
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C6.5',
      difficulty: Difficulty.d3,
      solution: '\$$name = $draw\n'
          'répète $sides {\n  avance \$$name\n  tournedroite $turn\n}',
      promptKeys: fillBoth(
        b(
            'Tire un nombre avec {d}, range-le dans \${n}, puis dessine la '
                'figure à {k} côtés.',
            'Draw a number with {d}, put it in \${n}, then draw the '
                '{k}-sided shape.'),
        {'d': draw, 'n': name, 'k': sides},
      ),
      wrong: [
        'répète $sides {\n  avance $value\n  tournedroite $turn\n}',
        '\$$name = $otherDraw\n'
            'répète $sides {\n  avance \$$name\n  tournedroite $turn\n}',
        // The right picture, obtained by copying the number instead of drawing it.
        '\$$name = $value\n'
            'répète $sides {\n  avance \$$name\n  tournedroite $turn\n}',
      ],
      assertions: [
        const UsesOpcode('RANDOM'),
        UsesVariable(name: name, minReads: 1),
      ],
      itemHints: hints(
        'Le dé choisit, toi tu ranges.',
        'The dice chooses, you put it away.',
        'Écris \$$name = $draw.',
        'Write \$$name = $draw.',
      ),
      paletteScope: palette,
    ));
  }
  // A fifth, where the draw decides how many sides rather than how long they are.
  items.add(buildToTarget(
    id: id(),
    conceptId: 'C6.5',
    difficulty: Difficulty.d3,
    solution:
        '\$n = hasard 3, 6\nrépète \$n {\n  avance 60\n  tournedroite 90\n}',
    promptKeys: b(
        'Tire un nombre avec hasard 3, 6 et fais autant de côtés de 60 pas.',
        'Draw a number with random 3, 6 and make that many 60-step sides.'),
    wrong: [
      'répète 4 {\n  avance 60\n  tournedroite 90\n}',
      '\$n = hasard 1, 3\nrépète \$n {\n  avance 60\n  tournedroite 90\n}',
      '\$n = 4\nrépète \$n {\n  avance 60\n  tournedroite 90\n}',
    ],
    assertions: [
      const UsesOpcode('RANDOM'),
      UsesVariable(name: 'n', minReads: 1),
    ],
    itemHints: hints(
      'Le nombre tiré sert à compter les tours.',
      'The number drawn is what counts the turns.',
      'Mets \$n juste après répète.',
      'Put \$n right after repeat.',
    ),
    paletteScope: palette,
  ));

  /* T3 — the items that do the refuting. Each has a right answer, and "on ne peut pas
     savoir" sitting next to it as a choice a child may pick and be shown to be wrong. */
  for (final entry in [
    ('hasard 1, 6', '4', '1', '6'),
    ('hasard 1, 10', '10', '1', '5'),
    ('hasard 2, 5', '3', '2', '5'),
    ('hasard 1, 4', '2', '1', '4'),
    ('hasard 3, 8', '6', '3', '8'),
  ]) {
    final draw = entry.$1, value = entry.$2;
    items.add(predict(
      id: id(),
      conceptId: 'C6.5',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Dans cet exercice, le dé de Tika est toujours lancé pareil. Que va-t-elle écrire ?\n\nécris {d}',
            'In this exercise Tika\'s dice is always thrown the same way. What will she print?\n\nprint {d}'),
        {'d': draw},
      ),
      choices: [
        Choice(labelKeys: b(value, value), correct: true),
        Choice(
            labelKeys: b('on ne peut pas savoir', 'there is no way to know'),
            correct: false,
            misconception: 'C6.5-random-is-untestable'),
        Choice(
            labelKeys: b(entry.$3, entry.$3),
            correct: false,
            misconception: 'C6.5-always-the-smallest'),
        Choice(
            labelKeys: b(entry.$4, entry.$4),
            correct: false,
            misconception: 'C6.5-always-the-largest'),
      ],
      itemHints: hints(
        'Relance le programme : tu retrouves le même nombre.',
        'Run the program again: the same number comes back.',
        'Ici le dé est réglé, donc la réponse est sûre.',
        'Here the dice is set, so the answer is certain.',
      ),
      wrongChoiceFr:
          'Le dé de l\'exercice est réglé : le même programme donne le même nombre.',
      wrongChoiceEn:
          'The exercise\'s dice is set: the same program gives the same number.',
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d1,
    promptKeys: b('Que fait hasard 1, 6 ?', 'What does random 1, 6 do?'),
    choices: [
      Choice(
          labelKeys: b('Il tire un nombre entre 1 et 6.',
              'It draws a number between 1 and 6.'),
          correct: true),
      Choice(
          labelKeys: b('Il écrit 1 et 6.', 'It prints 1 and 6.'),
          correct: false,
          misconception: 'C6.5-random-prints-its-arguments'),
      Choice(
          labelKeys: b('Il compte de 1 à 6.', 'It counts from 1 to 6.'),
          correct: false,
          misconception: 'C6.5-random-is-a-loop'),
      Choice(
          labelKeys: b('Il donne toujours 6.', 'It always gives 6.'),
          correct: false,
          misconception: 'C6.5-always-the-largest'),
    ],
    itemHints: hints(
      'Pense à un dé à six faces.',
      'Think of a six-sided dice.',
      'Il rend un seul nombre, pas une liste.',
      'It gives back one number, not a list.',
    ),
    wrongChoiceFr: 'hasard rend un seul nombre, tiré entre les deux bornes.',
    wrongChoiceEn: 'random gives back one number, drawn between the two ends.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('hasard 1, 6 peut-il donner 6 ?', 'Can random 1, 6 give 6?'),
    choices: [
      Choice(
          labelKeys: b('Oui : les deux bouts sont compris.',
              'Yes: both ends are included.'),
          correct: true),
      Choice(
          labelKeys: b('Non : il s\'arrête à 5.', 'No: it stops at 5.'),
          correct: false,
          misconception: 'C6.5-upper-bound-excluded'),
      Choice(
          labelKeys: b('Non : il ne donne jamais les bouts.',
              'No: it never gives the ends.'),
          correct: false,
          misconception: 'C6.5-bounds-excluded'),
      Choice(
          labelKeys: b('Seulement si on le lance beaucoup.',
              'Only if you throw it a lot.'),
          correct: false,
          misconception: 'C6.5-bounds-are-rare'),
    ],
    itemHints: hints(
      'Un dé à six faces peut tomber sur 6.',
      'A six-sided dice can land on 6.',
      'hasard 1, 6 est ce dé-là.',
      'random 1, 6 is that dice.',
    ),
    wrongChoiceFr: 'hasard peut donner le plus petit comme le plus grand.',
    wrongChoiceEn: 'random can give the smallest and the largest.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Tu lances deux fois hasard 1, 6 dans le même programme. Les deux nombres sont-ils forcément pareils ?',
        'You use random 1, 6 twice in one program. Must the two numbers be the same?'),
    choices: [
      Choice(
          labelKeys: b('Non : chaque lancer tire son nombre.',
              'No: each throw draws its own number.'),
          correct: true),
      Choice(
          labelKeys: b('Oui : le dé est réglé.', 'Yes: the dice is set.'),
          correct: false,
          misconception: 'C6.5-seed-freezes-the-value'),
      Choice(
          labelKeys:
              b('Oui : c\'est la même ligne.', 'Yes: it is the same line.'),
          correct: false,
          misconception: 'C6.5-seed-freezes-the-value'),
      Choice(
          labelKeys: b('On ne peut pas savoir.', 'There is no way to know.'),
          correct: false,
          misconception: 'C6.5-random-is-untestable'),
    ],
    itemHints: hints(
      'Un dé réglé donne toujours la même suite.',
      'A set dice always gives the same run of numbers.',
      'Une suite, ce n\'est pas le même nombre partout.',
      'A run of numbers is not the same number everywhere.',
    ),
    wrongChoiceFr:
        'Le dé réglé rend la même suite de nombres, pas un nombre unique.',
    wrongChoiceEn:
        'A set dice gives back the same run of numbers, not one number.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(
        r'Pourquoi ranger le tirage dans une boîte : $t = hasard 1, 6 ?',
        r'Why put the draw into a box: $t = random 1, 6?'),
    choices: [
      Choice(
          labelKeys: b('Pour se resservir du même nombre plus loin.',
              'To use the same number again further down.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que hasard ne marche pas tout seul.',
              'Because random does not work on its own.'),
          correct: false,
          misconception: 'C6.5-random-needs-a-box'),
      Choice(
          labelKeys: b('Pour que le tirage soit plus juste.',
              'To make the draw fairer.'),
          correct: false,
          misconception: 'C6.5-box-changes-the-draw'),
      Choice(
          labelKeys: b('Ça ne sert à rien.', 'It serves no purpose.'),
          correct: false,
          misconception: 'C6.5-box-changes-the-draw'),
    ],
    itemHints: hints(
      'Sans boîte, il faudrait relancer le dé.',
      'Without a box you would have to throw again.',
      'Et le deuxième lancer donnerait autre chose.',
      'And the second throw would give something else.',
    ),
    wrongChoiceFr:
        'La boîte garde le nombre tiré pour toutes les lignes qui suivent.',
    wrongChoiceEn:
        'The box keeps the number drawn for every line that follows.',
  ));

  // T8 — explain.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.5',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Un ami dit : « avec le hasard, on ne peut rien vérifier ». Que réponds-tu ?',
      'A friend says: "with random, nothing can be checked". What do you answer?',
    ),
    choices: [
      Choice(
          labelKeys: b('Si on règle le dé, le programme refait la même chose.',
              'If the dice is set, the program does the same thing again.'),
          correct: true),
      Choice(
          labelKeys: b('C\'est vrai, il faut essayer au hasard.',
              'True, you just have to try at random.'),
          correct: false,
          misconception: 'C6.5-random-is-untestable'),
      Choice(
          labelKeys: b('C\'est vrai, sauf le premier lancer.',
              'True, except for the first throw.'),
          correct: false,
          misconception: 'C6.5-random-is-untestable'),
      Choice(
          labelKeys: b('Il faut enlever le hasard pour vérifier.',
              'You have to take the random out to check.'),
          correct: false,
          misconception: 'C6.5-testing-needs-no-random'),
    ],
    itemHints: hints(
      'Ici le même exercice donne toujours le même dessin.',
      'Here the same exercise always gives the same drawing.',
      'C\'est parce que le dé est réglé.',
      'That is because the dice is set.',
    ),
    wrongChoiceFr: 'Un dé réglé rend le hasard répétable, donc vérifiable.',
    wrongChoiceEn: 'A set dice makes randomness repeatable, and so checkable.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.5',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi un jeu se sert-il du hasard ?',
      'Why does a game use random?',
    ),
    choices: [
      Choice(
          labelKeys: b('Pour que ce ne soit pas pareil à chaque partie.',
              'So it is not the same every game.'),
          correct: true),
      Choice(
          labelKeys: b(
              'Pour que le jeu soit plus rapide.', 'To make the game faster.'),
          correct: false,
          misconception: 'C6.1-box-is-speed'),
      Choice(
          labelKeys: b('Pour cacher les erreurs.', 'To hide mistakes.'),
          correct: false,
          misconception: 'C6.5-random-hides-bugs'),
      Choice(
          labelKeys:
              b('Parce que c\'est obligatoire.', 'Because it is compulsory.'),
          correct: false,
          misconception: 'C6.1-box-is-compulsory'),
    ],
    itemHints: hints(
      'Pense à un jeu de dés que tu connais.',
      'Think of a dice game you know.',
      'Chaque partie est différente.',
      'Every game is different.',
    ),
    wrongChoiceFr:
        'Le hasard change la partie, il ne la répare pas et ne l\'accélère pas.',
    wrongChoiceEn:
        'Random changes the game; it does not fix it or speed it up.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C6.5',
    type: ItemType.t8Explain,
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Pourquoi ton exercice donne-t-il le même dessin à chaque essai ?',
      'Why does your exercise give the same drawing every try?',
    ),
    choices: [
      Choice(
          labelKeys: b('Parce que le dé part du même réglage.',
              'Because the dice starts from the same setting.'),
          correct: true),
      Choice(
          labelKeys: b('Parce que hasard ne tire rien du tout.',
              'Because random draws nothing at all.'),
          correct: false,
          misconception: 'C6.5-random-is-fake'),
      Choice(
          labelKeys: b('Parce que le dessin est enregistré.',
              'Because the drawing is saved.'),
          correct: false,
          misconception: 'C6.1-box-holds-the-drawing'),
      Choice(
          labelKeys:
              b('Parce que tu as de la chance.', 'Because you are lucky.'),
          correct: false,
          misconception: 'C6.5-random-is-untestable'),
    ],
    itemHints: hints(
      'Un dé réglé repart toujours du même point.',
      'A set dice always starts from the same point.',
      'Donc il redonne la même suite.',
      'So it gives back the same run.',
    ),
    wrongChoiceFr:
        'Le tirage est réel ; c\'est son point de départ qui est fixé.',
    wrongChoiceEn: 'The draw is real; it is its starting point that is fixed.',
  ));

  /* T9 — three open builds. The rubric is the item: there is no target picture, and the
     three lines say exactly what "done" means before the child starts (`FR-M6-06`). */
  items.add(openBuild(
    id: id(),
    conceptId: 'C6.5',
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Fais un dessin dont la taille est tirée au hasard.',
      'Make a drawing whose size is drawn at random.',
    ),
    rubric: [
      rubricLine('Ton programme tire un nombre au hasard.',
          'Your program draws a number at random.', const UsesOpcode('RANDOM')),
      rubricLine('Tu ranges ce nombre dans une boîte.',
          'You put that number into a box.', const UsesVariable(minReads: 1)),
      rubricLine('Ton dessin répète quelque chose.',
          'Your drawing repeats something.', const ContainsNode('Repeat')),
    ],
    itemHints: hints(
      'Commence par \$t = hasard 20, 80.',
      'Start with \$t = random 20, 80.',
      'Puis sers-toi de \$t dans un répète.',
      'Then use \$t inside a repeat.',
    ),
    paletteScope: palette,
  ));
  items.add(openBuild(
    id: id(),
    conceptId: 'C6.5',
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Fais une figure dont le nombre de côtés est tiré au hasard.',
      'Make a shape whose number of sides is drawn at random.',
    ),
    rubric: [
      rubricLine('Ton programme tire un nombre au hasard.',
          'Your program draws a number at random.', const UsesOpcode('RANDOM')),
      rubricLine(
          'Le nombre tiré compte les tours.',
          'The number drawn counts the turns.',
          const UsesVariable(minReads: 1)),
      rubricLine('Tu te sers d\'un répète.', 'You use a repeat.',
          const ContainsNode('Repeat')),
      rubricLine('Tika avance et tourne.', 'Tika moves and turns.',
          const UsesOpcode('MOVE_FORWARD')),
    ],
    itemHints: hints(
      'Tire d\'abord, range ensuite.',
      'Draw first, put it away after.',
      'Mets la boîte juste après répète.',
      'Put the box right after repeat.',
    ),
    paletteScope: palette,
  ));
  items.add(openBuild(
    id: id(),
    conceptId: 'C6.5',
    difficulty: Difficulty.d3,
    promptKeys: b(
      'Fais un dessin qui change de couleur au hasard.',
      'Make a drawing that changes colour at random.',
    ),
    rubric: [
      rubricLine(
          'Ton programme tire des nombres au hasard.',
          'Your program draws numbers at random.',
          const UsesOpcode('RANDOM', min: 1)),
      rubricLine('Tu changes la couleur du crayon.',
          'You change the pen colour.', const UsesOpcode('PEN_COLOR')),
      rubricLine(
          'Tu ranges au moins un tirage dans une boîte.',
          'You put at least one draw into a box.',
          const UsesVariable(minReads: 1)),
      rubricLine('Ton dessin répète quelque chose.',
          'Your drawing repeats something.', const ContainsNode('Repeat')),
    ],
    itemHints: hints(
      'couleurcrayon veut trois nombres.',
      'pencolor wants three numbers.',
      'Chacun peut venir d\'un hasard 0, 255.',
      'Each one can come from a random 0, 255.',
    ),
    paletteScope: palette,
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// Tutorials (§4.2: Je regarde · On fait ensemble · Je fais).
//
// The narration never says *variable*: `FR-M5-03`'s jargon list forbids it, and World 6 is
// where the idea is taught rather than the word. A box is a box until the closing line,
// which names the concept once, in the child's own words (`FR-M5-06`).
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Tutorial> world6Tutorials() => [
      tutorialFor(
        conceptId: 'C6.1',
        conceptName: b('Une boîte garde un nombre.', 'A box keeps a number.'),
        palette: palette,
        steps: [
          watchStep(
            'C6.1',
            'Tika range un nombre dans une boîte.',
            'Tika puts a number into a box.',
            '\$côté = 60\nrépète 4 {\n  avance \$côté\n  tournedroite 90\n}',
            ideas: ['box', 'box-name'],
          ),
          togetherStep(
            'C6.1',
            'À toi. Mets 60 dans la boîte \$côté.',
            'Your turn. Put 60 into the box \$side.',
            assigns: 'côté',
            hintFr: 'Écris \$côté = 60 sur la première ligne.',
            hintEn: 'Write \$side = 60 on the first line.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C6.1',
            'Fais un carré qui se sert de ta boîte.',
            'Make a square that uses your box.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Remplis une boîte. Écris ensuite avance avec son nom.',
            hintEn: 'Fill a box. Then write forward with its name.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C6.2',
        conceptName:
            b('Le signe = range un nombre.', 'The = sign puts a number in.'),
        palette: palette,
        steps: [
          watchStep(
            'C6.2',
            'La boîte grandit de dix à chaque tour.',
            'The box grows by ten each turn.',
            '\$c = 20\nrépète 6 {\n  avance \$c\n  tournedroite 60\n  \$c = \$c + 10\n}',
            ideas: ['reassignment', 'accumulator'],
          ),
          togetherStep(
            'C6.2',
            'Ajoute dix à la boîte \$c.',
            'Add ten to the box \$c.',
            assigns: 'c',
            hintFr: 'Écris \$c = \$c + 10.',
            hintEn: 'Write \$c = \$c + 10.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C6.2',
            'Fais une figure dont les traits grandissent.',
            'Make a shape whose lines grow.',
            assigns: '*',
            opcodeId: 'MOVE_FORWARD',
            hintFr: 'Remplis la boîte avant le répète.',
            hintEn: 'Fill the box before the repeat.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C6.3',
        conceptName:
            b('Les fois passent avant les plus.', 'Times comes before plus.'),
        palette: palette,
        steps: [
          watchStep(
            'C6.3',
            'Tika calcule le côté avant de dessiner.',
            'Tika works the side out before drawing.',
            '\$c = 20 * 3\nrépète 4 {\n  avance \$c\n  tournedroite 90\n}',
            ideas: ['arithmetic', 'precedence'],
          ),
          togetherStep(
            'C6.3',
            'Mets le résultat de 20 fois 3 dans \$c.',
            'Put the answer to 20 times 3 into \$c.',
            assigns: 'c',
            hintFr: 'Écris \$c = 20 * 3.',
            hintEn: 'Write \$c = 20 * 3.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C6.3',
            'Trouve l\'angle avec un calcul. Fais la figure.',
            'Work the angle out with a sum. Make the shape.',
            assigns: '*',
            opcodeId: 'TURN_RIGHT',
            hintFr: 'Un tour complet fait 360 degrés. Partage-le.',
            hintEn: 'A full turn is 360 degrees. Share it out.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C6.4',
        conceptName:
            b('On peut voir dans une boîte.', 'You can see inside a box.'),
        palette: palette,
        steps: [
          watchStep(
            'C6.4',
            'Tika montre ce qu\'il y a dans la boîte.',
            'Tika shows what is inside the box.',
            '\$c = 10\n\$c = \$c * 4\nécris \$c',
            ideas: ['inspector', 'print'],
            spotlight: SpotlightTarget.inspector,
          ),
          togetherStep(
            'C6.4',
            'Demande à voir la boîte \$c.',
            'Ask to see the box \$c.',
            opcodeId: 'PRINT',
            hintFr: 'Écris le mot écris puis \$c.',
            hintEn: 'Write the word print then \$c.',
            action: ExpectedAction.buildProgram,
            spotlight: SpotlightTarget.inspector,
          ),
          doStep(
            'C6.4',
            'Remplis une boîte. Montre ce qu\'elle garde.',
            'Fill a box. Show what it keeps.',
            assigns: '*',
            opcodeId: 'PRINT',
            hintFr: 'Range un nombre. Écris ensuite le nom de la boîte.',
            hintEn: 'Put a number in. Then print the box name.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C6.5',
        conceptName: b('Le hasard tire un nombre.', 'Random draws a number.'),
        palette: palette,
        steps: [
          watchStep(
            'C6.5',
            'Tika lance un dé et garde le nombre.',
            'Tika throws a dice and keeps the number.',
            '\$t = hasard 30, 60\nrépète 4 {\n  avance \$t\n  tournedroite 90\n}',
            ideas: ['random', 'seeded'],
          ),
          togetherStep(
            'C6.5',
            'Range un tirage entre 30 et 60 dans \$t.',
            'Put a draw between 30 and 60 into \$t.',
            assigns: 't',
            hintFr: 'Écris \$t = hasard 30, 60.',
            hintEn: 'Write \$t = random 30, 60.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C6.5',
            'Fais un dessin dont la taille est tirée au sort.',
            'Make a drawing whose size is drawn by lot.',
            assigns: '*',
            opcodeId: 'RANDOM',
            hintFr: 'Range le tirage. Sers-t\'en dans un répète.',
            hintEn: 'Put the draw away. Use it inside a repeat.',
          ),
        ],
      ),
    ];

void main() {
  publishWorld(
    world: 6,
    nameKeys: b('Mes variables', 'My variables'),
    conceptGraph: conceptGraph,
    committed: committed,
    items: [
      ...conceptC61(),
      ...conceptC62(),
      ...conceptC63(),
      ...conceptC64(),
      ...conceptC65(),
    ],
    tutorials: world6Tutorials(),
    assetKeys: const ['art/tika.svg', 'art/world6-variables.svg'],
  );
}
