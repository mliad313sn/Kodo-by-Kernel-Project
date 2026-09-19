// Authors World 10 — "Lutins, costumes, sons" — and writes it out as a content pack.
//
//     dart tool/author_world10.dart
//
// Nine worlds of a turtle on a page, and now a stage: several characters, each with looks
// of its own, in front of a backdrop, making a noise. The five misconceptions in the
// ledger are five things a child brings from watching screens rather than making them:
//
//   C10.1  "there can be only one character"
//   C10.2  "animation needs a video"
//   C10.3  "the sound plays after the program ends"
//   C10.4  "the backdrop is a sprite"
//   C10.5  "effects are permanent"
//
// None of it leaves ink, and that is the whole difficulty of the world. A costume, a
// backdrop, a drum and a ghost effect are all invisible to a grader that compares
// drawings, so World 10 is graded on a second comparison — `StageState` — that looks at
// the five things a program can change without drawing anything. Every item below relies
// on it, and the acceptance suite checks that each concept really does move the part of
// the stage it is about.
//
// Two things an item must say, or it grades vacuously:
//
//  * **how many costumes the sprites have.** `costumesuivant` on a sprite with no
//    costumes does nothing, so an item that forgot to say would pass every answer.
//  * **which sprites are on the stage.** C10.1's whole point is that there is more than
//    one, and `lutin "chien"` needs a `chien` to select.

import 'package:kodo_content/kodo_content.dart';
import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';

import 'authoring.dart';

const conceptGraph = <String, List<String>>{
  'C10.1': ['C5.1'],
  'C10.2': ['C10.1'],
  'C10.3': ['C10.1'],
  'C10.4': ['C10.1'],
  'C10.5': ['C10.2'],
};

/// §6.3's commitment, copied from `spec/concepts.json` and checked against it by
/// `publishWorld`.
const committed = <String, int>{
  'C10.1': 20,
  'C10.2': 22,
  'C10.3': 20,
  'C10.4': 18,
  'C10.5': 20,
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
  'IF',
  'ELSE',
  'AND',
  'OR',
  'NOT',
  'TRUE',
  'FALSE',
  'LEARN',
  'SELECT_SPRITE',
  'NEXT_COSTUME',
  'SET_COSTUME',
  'COSTUME_NUMBER',
  'SET_BACKDROP',
  'SET_EFFECT',
  'CLEAR_EFFECTS',
  'SAY',
  'PLAY_SOUND',
  'PLAY_DRUM',
  'PLAY_NOTE',
];

/// The stage nearly every item in this world runs on: three characters, three costumes
/// each, three places to stand.
const troupe = StageSetup(
  sprites: ['chat', 'chien', 'oiseau'],
  costumes: 3,
  backdrops: ['nuit', 'plage', 'forêt'],
);

// ═══════════════════════════════════════════════════════════════════════════════════════
// C10.1 — Un lutin est un objet.
// Misconception: "there can be only one character".
//
// The refutation needed a word that did not exist until this world was authored: `lutin`
// chooses which character the next blocks talk to. Without it the curriculum would have
// been teaching "there can be several" on a stage where only one could be addressed —
// which is not a teaching problem, it is a false claim.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC101() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C10.1-${(++n).toString().padLeft(2, '0')}';

  /* T1 — make two characters speak, each in its own voice. The distractor that says both
     lines with one character is the misconception, and the stage comparison is what
     catches it: the two programs draw exactly the same nothing. */
  for (final entry in [
    ('chat', 'miaou', 'chien', 'ouaf'),
    ('chien', 'ouaf', 'oiseau', 'cui'),
    ('oiseau', 'cui', 'chat', 'miaou'),
    ('chat', 'bonjour', 'oiseau', 'salut'),
    ('chien', 'salut', 'chat', 'bonjour'),
  ]) {
    final first = entry.$1, firstLine = entry.$2;
    final second = entry.$3, secondLine = entry.$4;
    final solution = 'lutin "$first"\ndis "$firstLine"\n'
        'lutin "$second"\ndis "$secondLine"';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C10.1',
      difficulty: Difficulty.d2,
      solution: solution,
      stage: troupe,
      promptKeys: fillBoth(
        b('Fais dire « {a} » à {f}, puis « {b} » à {s}.',
            'Make {f} say "{a}", then {s} say "{b}".'),
        {'a': firstLine, 'b': secondLine, 'f': first, 's': second},
      ),
      wrong: [
        // One character says both lines.
        'lutin "$first"\ndis "$firstLine"\ndis "$secondLine"',
        // The lines swapped between the two.
        'lutin "$first"\ndis "$secondLine"\n'
            'lutin "$second"\ndis "$firstLine"',
        // Only the first one speaks.
        'lutin "$first"\ndis "$firstLine"',
      ],
      assertions: [const UsesOpcode('SELECT_SPRITE', min: 2)],
      alternatives: [
        '# chacun sa réplique\n$solution',
        solution.replaceFirst('lutin "$first"\n', 'lutin "$first"\n\n'),
      ],
      itemHints: hints(
        'Un bloc parle au lutin choisi.',
        'A block talks to the chosen sprite.',
        'Choisis le second avant sa réplique.',
        'Choose the second one before its line.',
      ),
      paletteScope: palette,
    ));
  }

  // T3 — who says what?
  for (final entry in [
    ('lutin "chat"\ndis "un"\nlutin "chien"\ndis "deux"', 'chien', 'chat'),
    ('lutin "chien"\ndis "un"\ndis "deux"', 'chien', 'chat'),
    ('lutin "oiseau"\ndis "un"\nlutin "chat"\ndis "deux"', 'chat', 'oiseau'),
    ('dis "un"\nlutin "chien"\ndis "deux"', 'chien', 'chat'),
  ]) {
    final source = entry.$1, sayer = entry.$2, other = entry.$3;
    items.add(predict(
      id: id(),
      conceptId: 'C10.1',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Qui dit « deux » ?\n\n{p}', 'Who says "two"?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b(sayer, sayer), correct: true),
        Choice(
            labelKeys: b(other, other),
            correct: false,
            misconception: 'C10.1-selection-does-not-stick'),
        Choice(
            labelKeys: b('les deux ensemble', 'both at once'),
            correct: false,
            misconception: 'C10.1-one-character-only'),
        Choice(
            labelKeys: b('personne', 'nobody'),
            correct: false,
            misconception: 'C10.1-say-needs-a-costume'),
      ],
      itemHints: hints(
        'Le dernier lutin choisi garde la parole.',
        'The last sprite chosen keeps the floor.',
        'Lis les lignes de haut en bas.',
        'Read the lines from top to bottom.',
      ),
      wrongChoiceFr:
          'Les blocs parlent au dernier lutin choisi, jusqu\'au choix suivant.',
      wrongChoiceEn:
          'Blocks talk to the last sprite chosen, until the next choice.',
    ));
  }

  // T4 — the hole is which character is being addressed.
  for (final entry in [
    ('chat', 'chien', 'ouaf'),
    ('chien', 'oiseau', 'cui'),
    ('oiseau', 'chat', 'miaou'),
    ('chat', 'oiseau', 'cui'),
  ]) {
    final first = entry.$1, second = entry.$2, line = entry.$3;
    final solution =
        'lutin "$first"\ndis "bonjour"\nlutin "$second"\ndis "$line"';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C10.1',
      difficulty: Difficulty.d2,
      stage: troupe,
      withHoles: 'lutin "$first"\ndis "bonjour"\n___\ndis "$line"',
      solution: solution,
      promptKeys: fillBoth(
        b('Complète pour que ce soit {s} qui dise « {l} ».',
            'Fill in the blank so it is {s} who says "{l}".'),
        {'s': second, 'l': line},
      ),
      wrong: [
        'lutin "$first"\ndis "bonjour"\nlutin "$first"\ndis "$line"',
        'lutin "$first"\ndis "bonjour"\ndis "$line"',
        'lutin "$first"\ndis "bonjour"\ncostumesuivant\ndis "$line"',
      ],
      assertions: [const UsesOpcode('SELECT_SPRITE', min: 2)],
      alternatives: [
        '# on change de lutin\n$solution',
        solution.replaceFirst('lutin "$second"', 'lutin  "$second"'),
      ],
      itemHints: hints(
        'Il faut désigner l\'autre lutin.',
        'You have to name the other sprite.',
        'Écris lutin puis son nom.',
        'Write sprite then its name.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d1,
    promptKeys: b('Combien de lutins une scène peut-elle avoir ?',
        'How many sprites can a stage have?'),
    choices: [
      Choice(labelKeys: b('Plusieurs.', 'Several.'), correct: true),
      Choice(
          labelKeys: b('Un seul.', 'Only one.'),
          correct: false,
          misconception: 'C10.1-one-character-only'),
      Choice(
          labelKeys: b('Un par arrière-plan.', 'One per backdrop.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-sprite'),
      Choice(
          labelKeys: b('Un par costume.', 'One per costume.'),
          correct: false,
          misconception: 'C10.2-costume-is-a-sprite'),
    ],
    itemHints: hints(
      'Pense à un dessin animé avec deux personnages.',
      'Think of a cartoon with two characters.',
      'Chacun a son nom sur la scène.',
      'Each has its own name on the stage.',
    ),
    wrongChoiceFr:
        'Une scène tient plusieurs lutins, et on choisit à qui l\'on parle.',
    wrongChoiceEn:
        'A stage holds several sprites, and you choose which one you address.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait lutin "chien" ?', 'What does sprite "dog" do?'),
    choices: [
      Choice(
          labelKeys: b('Il choisit à qui parlent les blocs suivants.',
              'It chooses who the next blocks talk to.'),
          correct: true),
      Choice(
          labelKeys: b('Il crée un nouveau chien.', 'It makes a new dog.'),
          correct: false,
          misconception: 'C10.1-select-creates'),
      Choice(
          labelKeys:
              b('Il efface les autres lutins.', 'It erases the other sprites.'),
          correct: false,
          misconception: 'C10.1-one-character-only'),
      Choice(
          labelKeys: b('Il fait aboyer le chien.', 'It makes the dog bark.'),
          correct: false,
          misconception: 'C10.1-select-acts'),
    ],
    itemHints: hints(
      'Le bloc ne fait rien tout seul.',
      'The block does nothing on its own.',
      'Il dit seulement à qui l\'on s\'adresse.',
      'It only says who is being addressed.',
    ),
    wrongChoiceFr:
        'Choisir un lutin ne le crée pas et ne le fait pas agir : ça le désigne.',
    wrongChoiceEn:
        'Choosing a sprite does not create it or make it act: it names it.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Tu choisis le chien, puis tu écris trois blocs. À qui parlent-ils ?',
        'You choose the dog, then write three blocks. Who do they talk to?'),
    choices: [
      Choice(
          labelKeys: b('Tous les trois au chien.', 'All three to the dog.'),
          correct: true),
      Choice(
          labelKeys: b('Le premier au chien, les autres à personne.',
              'The first to the dog, the others to nobody.'),
          correct: false,
          misconception: 'C10.1-selection-does-not-stick'),
      Choice(
          labelKeys:
              b('À tous les lutins à la fois.', 'To every sprite at once.'),
          correct: false,
          misconception: 'C10.1-one-character-only'),
      Choice(
          labelKeys: b(
              'Au premier lutin de la scène.', 'To the stage\'s first sprite.'),
          correct: false,
          misconception: 'C10.1-selection-does-not-stick'),
    ],
    itemHints: hints(
      'Le choix reste jusqu\'au choix suivant.',
      'The choice holds until the next choice.',
      'Comme lever la main pour prendre la parole.',
      'Like putting your hand up to hold the floor.',
    ),
    wrongChoiceFr:
        'Un lutin choisi le reste jusqu\'à ce qu\'on en choisisse un autre.',
    wrongChoiceEn: 'A chosen sprite stays chosen until another one is chosen.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.1',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Deux lutins peuvent-ils porter des costumes différents ?',
        'Can two sprites wear different costumes?'),
    choices: [
      Choice(
          labelKeys: b('Oui : chacun a les siens.', 'Yes: each has its own.'),
          correct: true),
      Choice(
          labelKeys: b('Non : le costume est celui de la scène.',
              'No: the costume belongs to the stage.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-sprite'),
      Choice(
          labelKeys:
              b('Non : ils changent ensemble.', 'No: they change together.'),
          correct: false,
          misconception: 'C10.1-one-character-only'),
      Choice(
          labelKeys: b('Seulement s\'ils ont le même nombre de costumes.',
              'Only if they have the same number of costumes.'),
          correct: false,
          misconception: 'C10.2-costume-is-a-sprite'),
    ],
    itemHints: hints(
      'Un lutin garde ses affaires.',
      'A sprite keeps its own things.',
      'Changer l\'un ne change pas l\'autre.',
      'Changing one does not change the other.',
    ),
    wrongChoiceFr: 'Chaque lutin a ses costumes et ses effets, rien qu\'à lui.',
    wrongChoiceEn:
        'Each sprite has its own costumes and effects, and nobody else\'s.',
  ));

  // T9 — three open builds.
  for (final entry in [
    (
      'Fais parler deux lutins chacun leur tour.',
      'Make two sprites speak one after the other.'
    ),
    (
      'Fais une petite scène avec trois personnages.',
      'Make a little scene with three characters.'
    ),
    (
      'Fais dire bonjour à chaque lutin de la scène.',
      'Make every sprite on the stage say hello.'
    ),
  ]) {
    items.add(openBuild(
      id: id(),
      conceptId: 'C10.1',
      difficulty: Difficulty.d3,
      stage: troupe,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine(
            'Tu choisis au moins deux lutins.',
            'You choose at least two sprites.',
            const UsesOpcode('SELECT_SPRITE', min: 2)),
        rubricLine('Chacun dit quelque chose.', 'Each one says something.',
            const UsesOpcode('SAY', min: 2)),
        rubricLine(
            'Ton programme tient debout tout seul.',
            'Your program stands up on its own.',
            const BlockCountWithin(min: 4)),
      ],
      itemHints: hints(
        'Choisis un lutin, fais-le parler.',
        'Choose a sprite, make it speak.',
        'Puis choisis le suivant.',
        'Then choose the next one.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C10.2 — Costumes et animation.
// Misconception: "animation needs a video".
//
// It does not. A sprite with three drawings and a loop that changes which one is showing
// is an animation, and that is the whole of it — the same idea as a flip-book, which is
// what the narration calls it. Every item here is a loop over `costumesuivant`, because
// the misconception dissolves the moment a child makes one.
//
// The items say `costumes: 3` on their stage and they must: `costumesuivant` on a sprite
// with nothing to change into does nothing at all, and an item where nothing happens
// passes every answer.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC102() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C10.2-${(++n).toString().padLeft(2, '0')}';

  /* T1 — an animation: a loop that changes the look. The count matters, because three
     costumes wrap: four changes lands on the second costume, not the fourth. */
  /* The three distractors are three different counts, not "once" and "never". Costumes
     wrap at three, so one change lands exactly where four do — the gate caught two items
     whose "he only did it once" answer was the right answer with a different story. Two
     counts either side of the target always differ, whatever the wrap. */
  for (final entry in [
    ('chat', 4),
    ('chien', 2),
    ('oiseau', 5),
    ('chat', 7),
    ('chien', 8),
  ]) {
    final who = entry.$1, times = entry.$2;
    final solution = 'lutin "$who"\nrépète $times {\n  costumesuivant\n}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C10.2',
      difficulty: Difficulty.d2,
      solution: solution,
      stage: troupe,
      promptKeys: fillBoth(
        b('Fais changer {w} de costume {t} fois de suite.',
            'Make {w} change costume {t} times in a row.'),
        {'w': who, 't': times},
      ),
      wrong: [
        'lutin "$who"\nrépète $times {\n  costume 1\n}',
        'lutin "$who"\nrépète ${times + 1} {\n  costumesuivant\n}',
        'lutin "$who"\nrépète ${times + 2} {\n  costumesuivant\n}',
      ],
      assertions: [const UsesOpcode('NEXT_COSTUME')],
      alternatives: [
        '# une image après l\'autre\n$solution',
        'lutin "$who"\n${List.filled(times, 'costumesuivant').join('\n')}',
      ],
      itemHints: hints(
        'Un costume après l\'autre fait bouger le lutin.',
        'One costume after another makes the sprite move.',
        'Mets costumesuivant dans un répète.',
        'Put nextcostume inside a repeat.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — where does the flip-book land? Three costumes, so it wraps, and the wrapping is
     the thing that has to be traced rather than guessed. */
  /* The two wrong costumes are *the other two*, worked out rather than typed: with three
     costumes there are only three answers, and a hand-written distractor list repeated
     the right one in four items out of five. The no-wrap answer is `times + 1`, which is
     why every count here is at least three — at two it would BE a costume number. */
  for (final entry in [4, 3, 5, 6, 7]) {
    final times = entry;
    final ends = (times % 3) + 1;
    final others = [1, 2, 3]..remove(ends);
    items.add(predict(
      id: id(),
      conceptId: 'C10.2',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b(
            'Le chat a trois costumes et porte le premier.\n'
                'Quel costume porte-t-il à la fin ?\n\n'
                'répète {t} {{\n  costumesuivant\n}}',
            'The cat has three costumes and is wearing the first.\n'
                'Which one is it wearing at the end?\n\n'
                'repeat {t} {{\n  nextcostume\n}}'),
        {'t': times},
      ),
      choices: [
        Choice(labelKeys: b('$ends', '$ends'), correct: true),
        Choice(
            labelKeys: b('${times + 1}', '${times + 1}'),
            correct: false,
            misconception: 'C10.2-costumes-do-not-wrap'),
        for (final other in others)
          Choice(
            labelKeys: b('$other', '$other'),
            correct: false,
            misconception: switch (other) {
              1 => 'C10.2-costume-resets',
              3 => 'C10.2-costumes-stop-at-the-last',
              _ => 'C10.2-costume-off-by-one',
            },
          ),
      ],
      itemHints: hints(
        'Après le troisième vient le premier.',
        'After the third comes the first.',
        'Compte à voix haute : 1, 2, 3, 1, 2…',
        'Count out loud: 1, 2, 3, 1, 2…',
      ),
      wrongChoiceFr:
          'Les costumes tournent en rond : après le dernier on revient au premier.',
      wrongChoiceEn:
          'Costumes go round: after the last one you come back to the first.',
    ));
  }

  // T4 — the hole is the block that changes the look.
  for (final entry in [
    ('chat', 4),
    ('chien', 3),
    ('oiseau', 5),
    ('chat', 2),
  ]) {
    final who = entry.$1, times = entry.$2;
    final solution = 'lutin "$who"\nrépète $times {\n  costumesuivant\n}';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C10.2',
      difficulty: Difficulty.d2,
      stage: troupe,
      withHoles: 'lutin "$who"\nrépète $times {\n  ___\n}',
      solution: solution,
      promptKeys: b(
          'Complète pour que le lutin change de costume à chaque tour.',
          'Fill in the blank so the sprite changes costume every turn.'),
      wrong: [
        'lutin "$who"\nrépète $times {\n  costume 1\n}',
        'lutin "$who"\nrépète $times {\n  dis "hop"\n}',
        'lutin "$who"\nrépète $times {\n  avance 10\n}',
      ],
      assertions: [const UsesOpcode('NEXT_COSTUME')],
      alternatives: [
        '# le costume change à chaque tour\n$solution',
        'lutin "$who"\n${List.filled(times, 'costumesuivant').join('\n')}',
      ],
      itemHints: hints(
        'Un bloc passe au costume d\'après.',
        'One block moves to the next costume.',
        'Il s\'appelle costumesuivant.',
        'It is called nextcostume.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d1,
    promptKeys: b('Qu\'est-ce qu\'une animation ?', 'What is an animation?'),
    choices: [
      Choice(
          labelKeys: b('Des dessins qui se remplacent vite.',
              'Drawings replacing each other quickly.'),
          correct: true),
      Choice(
          labelKeys: b('Une vidéo qu\'on ajoute au programme.',
              'A video you add to the program.'),
          correct: false,
          misconception: 'C10.2-animation-needs-video'),
      Choice(
          labelKeys: b('Un dessin qui bouge tout seul.',
              'A drawing that moves by itself.'),
          correct: false,
          misconception: 'C10.2-animation-is-magic'),
      Choice(
          labelKeys: b('Un lutin plus rapide que les autres.',
              'A sprite faster than the others.'),
          correct: false,
          misconception: 'C10.2-animation-is-speed'),
    ],
    itemHints: hints(
      'Pense à un carnet qu\'on feuillette.',
      'Think of a flip-book.',
      'Chaque page est un dessin un peu différent.',
      'Each page is a slightly different drawing.',
    ),
    wrongChoiceFr:
        'Une animation, ce sont des images qui se succèdent — pas une vidéo.',
    wrongChoiceEn:
        'An animation is pictures following one another — not a video.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait costumesuivant sur le dernier costume ?',
        'What does nextcostume do on the last costume?'),
    choices: [
      Choice(
          labelKeys: b('Il revient au premier.', 'It goes back to the first.'),
          correct: true),
      Choice(
          labelKeys: b('Il reste sur le dernier.', 'It stays on the last.'),
          correct: false,
          misconception: 'C10.2-costumes-stop-at-the-last'),
      Choice(
          labelKeys:
              b('Il crée un nouveau costume.', 'It makes a new costume.'),
          correct: false,
          misconception: 'C10.2-costumes-do-not-wrap'),
      Choice(
          labelKeys: b('Il arrête le programme.', 'It stops the program.'),
          correct: false,
          misconception: 'C10.2-costume-resets'),
    ],
    itemHints: hints(
      'Les costumes sont en rond.',
      'The costumes are in a ring.',
      'Après le dernier vient le premier.',
      'After the last one comes the first.',
    ),
    wrongChoiceFr: 'Les costumes tournent en boucle, sans fin et sans erreur.',
    wrongChoiceEn: 'Costumes go round in a ring, endlessly and without error.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(
        'Quelle est la différence entre costume 2 et costumesuivant ?',
        'What is the difference between costume 2 and nextcostume?'),
    choices: [
      Choice(
          labelKeys: b('L\'un choisit, l\'autre avance d\'un cran.',
              'One picks, the other moves along by one.'),
          correct: true),
      Choice(
          labelKeys: b('Aucune.', 'None.'),
          correct: false,
          misconception: 'C10.2-costume-blocks-are-the-same'),
      Choice(
          labelKeys: b('costume 2 est plus rapide.', 'costume 2 is faster.'),
          correct: false,
          misconception: 'C10.2-animation-is-speed'),
      Choice(
          labelKeys: b('costumesuivant ne marche qu\'une fois.',
              'nextcostume only works once.'),
          correct: false,
          misconception: 'C10.2-costumes-stop-at-the-last'),
    ],
    itemHints: hints(
      'L\'un dit lequel, l\'autre dit « le suivant ».',
      'One says which, the other says "the next one".',
      'Le premier ne dépend pas du costume porté.',
      'The first one does not depend on the costume being worn.',
    ),
    wrongChoiceFr:
        'costume choisit un numéro ; costumesuivant dépend de celui porté.',
    wrongChoiceEn:
        'costume picks a number; nextcostume depends on the one being worn.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.2',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Que faut-il pour animer un lutin ?',
        'What does it take to animate a sprite?'),
    choices: [
      Choice(
          labelKeys: b('Plusieurs costumes et une boucle.',
              'Several costumes and a loop.'),
          correct: true),
      Choice(
          labelKeys: b('Une vidéo et un lecteur.', 'A video and a player.'),
          correct: false,
          misconception: 'C10.2-animation-needs-video'),
      Choice(
          labelKeys: b('Un seul costume, mais très détaillé.',
              'One costume, but a very detailed one.'),
          correct: false,
          misconception: 'C10.2-animation-is-magic'),
      Choice(
          labelKeys: b('Un ordinateur rapide.', 'A fast computer.'),
          correct: false,
          misconception: 'C10.2-animation-is-speed'),
    ],
    itemHints: hints(
      'Il faut au moins deux images différentes.',
      'You need at least two different pictures.',
      'Et quelque chose qui les fait défiler.',
      'And something that runs through them.',
    ),
    wrongChoiceFr:
        'Des images et une boucle suffisent ; c\'est tout ce qu\'est une animation.',
    wrongChoiceEn:
        'Pictures and a loop are enough; that is all an animation is.',
  ));

  // T9 — four open builds.
  for (final entry in [
    (
      'Anime un lutin avec ses costumes.',
      'Animate a sprite using its costumes.'
    ),
    (
      'Fais marcher un lutin sur la scène.',
      'Make a sprite walk across the stage.'
    ),
    (
      'Fais une animation qui se répète dix fois.',
      'Make an animation that repeats ten times.'
    ),
    (
      'Anime deux lutins en même temps.',
      'Animate two sprites at the same time.'
    ),
  ]) {
    final twoSprites = entry.$1.startsWith('Anime deux');
    items.add(openBuild(
      id: id(),
      conceptId: 'C10.2',
      difficulty: Difficulty.d3,
      stage: troupe,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine('Ton lutin change de costume.',
            'Your sprite changes costume.', const UsesOpcode('NEXT_COSTUME')),
        rubricLine(
            'Le changement est dans une répétition.',
            'The change is inside a repeat.',
            const NestedInside('Repeat', 'Command')),
        if (twoSprites)
          rubricLine('Tu animes deux lutins.', 'You animate two sprites.',
              const UsesOpcode('SELECT_SPRITE', min: 2))
        else
          rubricLine(
              'Tu choisis le lutin à animer.',
              'You choose the sprite to animate.',
              const UsesOpcode('SELECT_SPRITE')),
      ],
      itemHints: hints(
        'Choisis un lutin d\'abord.',
        'Choose a sprite first.',
        'Mets costumesuivant dans un répète.',
        'Put nextcostume inside a repeat.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C10.3 — Sons et tambours.
// Misconception: "the sound plays after the program ends".
//
// A sound is a line like any other: it happens where it is written, between the line
// above and the line below. The misconception comes from watching things rather than
// making them — the music in a video starts when the video does — and it is answered by
// putting a drum *between* two drawn lines and letting the child see where it lands in
// the score.
//
// Grading listens to the score, never to a speaker: every sound asked for is recorded in
// order, and the order is what the comparison checks.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC103() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C10.3-${(++n).toString().padLeft(2, '0')}';

  /* T1 — a rhythm: a drum inside a loop, one beat per turn. The distractor that plays
     every drum at the end is the misconception, and the score shows the difference even
     though neither program draws anything different. */
  for (final entry in [
    (1, 4),
    (2, 3),
    (3, 5),
    (1, 6),
    (2, 2),
  ]) {
    final drum = entry.$1, times = entry.$2;
    final solution = 'répète $times {\n  tambour $drum, 1\n  avance 20\n}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C10.3',
      difficulty: Difficulty.d2,
      solution: solution,
      stage: troupe,
      promptKeys: fillBoth(
        b('Joue le tambour {d} avant chacun des {t} pas.',
            'Play drum {d} before each of the {t} steps.'),
        {'d': drum, 't': times},
      ),
      wrong: [
        // Every beat at the end: the misconception, played.
        'répète $times {\n  avance 20\n}\n'
            '${List.filled(times, 'tambour $drum, 1').join('\n')}',
        // One beat only.
        'tambour $drum, 1\nrépète $times {\n  avance 20\n}',
        // The wrong drum.
        'répète $times {\n  tambour ${drum + 1}, 1\n  avance 20\n}',
      ],
      assertions: [UsesOpcode('PLAY_DRUM', min: 1)],
      alternatives: [
        '# un coup par pas\n$solution',
        List.filled(times, 'tambour $drum, 1\navance 20').join('\n'),
      ],
      itemHints: hints(
        'Un son se joue là où il est écrit.',
        'A sound plays where it is written.',
        'Mets le tambour dans le répète.',
        'Put the drum inside the repeat.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — in what order? The answer a child who holds the misconception gives is always
     "the drawing first, then all the sound". */
  for (final entry in [
    (
      'tambour 1, 1\navance 20\ntambour 2, 1',
      'tambour, trait, tambour',
      'drum, line, drum',
      'trait, tambour, tambour',
      'line, drum, drum'
    ),
    (
      'avance 20\ntambour 1, 1\navance 20',
      'trait, tambour, trait',
      'line, drum, line',
      'trait, trait, tambour',
      'line, line, drum'
    ),
    (
      'jouson "miaou"\navance 20',
      'son, trait',
      'sound, line',
      'trait, son',
      'line, sound'
    ),
    (
      'note 60, 1\nnote 64, 1\navance 20',
      'note, note, trait',
      'note, note, line',
      'trait, note, note',
      'line, note, note'
    ),
  ]) {
    final source = entry.$1;
    items.add(predict(
      id: id(),
      conceptId: 'C10.3',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Dans quel ordre les choses se passent-elles ?\n\n{p}',
            'In what order do things happen?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b(entry.$2, entry.$3), correct: true),
        Choice(
            labelKeys: b(entry.$4, entry.$5),
            correct: false,
            misconception: 'C10.3-sound-plays-at-the-end'),
        Choice(
            labelKeys: b('tout en même temps', 'all at the same time'),
            correct: false,
            misconception: 'C10.3-sound-is-a-soundtrack'),
        Choice(
            labelKeys: b('le son d\'abord, puis le reste',
                'the sound first, then the rest'),
            correct: false,
            misconception: 'C10.3-sound-plays-first'),
      ],
      itemHints: hints(
        'Lis les lignes de haut en bas.',
        'Read the lines from top to bottom.',
        'Un son n\'attend pas la fin du programme.',
        'A sound does not wait for the end of the program.',
      ),
      wrongChoiceFr:
          'Un son se joue à sa ligne, entre celle d\'avant et celle d\'après.',
      wrongChoiceEn:
          'A sound plays at its line, between the one before and the one after.',
    ));
  }

  // T4 — the hole is the sound, in the place where it belongs.
  for (final entry in [
    (1, 4),
    (2, 3),
    (3, 5),
    (1, 2),
  ]) {
    final drum = entry.$1, times = entry.$2;
    final solution = 'répète $times {\n  tambour $drum, 1\n  avance 20\n}';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C10.3',
      difficulty: Difficulty.d2,
      stage: troupe,
      withHoles: 'répète $times {\n  ___\n  avance 20\n}',
      solution: solution,
      promptKeys: fillBoth(
        b('Complète pour jouer le tambour {d} à chaque tour.',
            'Fill in the blank to play drum {d} every turn.'),
        {'d': drum},
      ),
      wrong: [
        'répète $times {\n  tambour ${drum + 1}, 1\n  avance 20\n}',
        'répète $times {\n  note 60, 1\n  avance 20\n}',
        'répète $times {\n  dis "boum"\n  avance 20\n}',
      ],
      assertions: [const UsesOpcode('PLAY_DRUM')],
      alternatives: [
        '# un coup de tambour par tour\n$solution',
        List.filled(times, 'tambour $drum, 1\navance 20').join('\n'),
      ],
      itemHints: hints(
        'Il existe un bloc pour le tambour.',
        'There is a block for the drum.',
        'Il prend le numéro et le nombre de temps.',
        'It takes the number and how many beats.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d1,
    promptKeys: b('Quand un son se joue-t-il ?', 'When does a sound play?'),
    choices: [
      Choice(
          labelKeys: b('Quand le programme arrive à sa ligne.',
              'When the program reaches its line.'),
          correct: true),
      Choice(
          labelKeys: b('À la fin du programme.', 'At the end of the program.'),
          correct: false,
          misconception: 'C10.3-sound-plays-at-the-end'),
      Choice(
          labelKeys:
              b('Au début, comme une musique.', 'At the start, like music.'),
          correct: false,
          misconception: 'C10.3-sound-plays-first'),
      Choice(
          labelKeys:
              b('Tout le temps, en fond.', 'All the time, in the background.'),
          correct: false,
          misconception: 'C10.3-sound-is-a-soundtrack'),
    ],
    itemHints: hints(
      'Un bloc son est un bloc comme un autre.',
      'A sound block is a block like any other.',
      'Il se joue à son tour.',
      'It plays when its turn comes.',
    ),
    wrongChoiceFr: 'Un son est une instruction : il se joue quand on y arrive.',
    wrongChoiceEn: 'A sound is an instruction: it plays when you get to it.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que veut dire le second nombre de tambour 1, 2 ?',
        'What does the second number in drum 1, 2 mean?'),
    choices: [
      Choice(
          labelKeys:
              b('Combien de temps le coup dure.', 'How long the beat lasts.'),
          correct: true),
      Choice(
          labelKeys:
              b('Combien de coups on joue.', 'How many beats are played.'),
          correct: false,
          misconception: 'C10.3-beats-are-a-count'),
      Choice(
          labelKeys: b('Quel tambour on choisit.', 'Which drum is chosen.'),
          correct: false,
          misconception: 'C10.3-arguments-swapped'),
      Choice(
          labelKeys: b('À quel volume on joue.', 'How loud it plays.'),
          correct: false,
          misconception: 'C10.3-beats-are-volume'),
    ],
    itemHints: hints(
      'Le premier nombre dit lequel.',
      'The first number says which one.',
      'Le second dit combien de temps.',
      'The second says for how long.',
    ),
    wrongChoiceFr:
        'Le premier nombre choisit le tambour ; le second dit sa durée.',
    wrongChoiceEn:
        'The first number picks the drum; the second says how long it lasts.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Peut-on jouer un son dans une boucle ?',
        'Can you play a sound inside a loop?'),
    choices: [
      Choice(
          labelKeys:
              b('Oui : il se joue à chaque tour.', 'Yes: it plays every turn.'),
          correct: true),
      Choice(
          labelKeys: b('Non : un son ne se joue qu\'une fois.',
              'No: a sound only plays once.'),
          correct: false,
          misconception: 'C10.3-sound-plays-once-only'),
      Choice(
          labelKeys: b('Oui, mais il attend la fin de la boucle.',
              'Yes, but it waits for the loop to finish.'),
          correct: false,
          misconception: 'C10.3-sound-plays-at-the-end'),
      Choice(
          labelKeys: b('Seulement le premier tour.', 'Only on the first turn.'),
          correct: false,
          misconception: 'C10.3-sound-plays-once-only'),
    ],
    itemHints: hints(
      'Une boucle rejoue toutes ses lignes.',
      'A loop replays all of its lines.',
      'Le son en fait partie.',
      'The sound is one of them.',
    ),
    wrongChoiceFr:
        'Un son dans une boucle se joue une fois par tour, comme le reste.',
    wrongChoiceEn:
        'A sound inside a loop plays once per turn, like everything else.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.3',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Tu mets le tambour après avance. Qu\'est-ce qui change ?',
        'You put the drum after forward. What changes?'),
    choices: [
      Choice(
          labelKeys: b('Le trait se dessine avant le coup.',
              'The line is drawn before the beat.'),
          correct: true),
      Choice(
          labelKeys: b('Rien du tout.', 'Nothing at all.'),
          correct: false,
          misconception: 'C10.3-sound-is-a-soundtrack'),
      Choice(
          labelKeys: b('Le son devient plus fort.', 'The sound gets louder.'),
          correct: false,
          misconception: 'C10.3-beats-are-volume'),
      Choice(
          labelKeys: b('Le trait disparaît.', 'The line disappears.'),
          correct: false,
          misconception: 'C10.3-sound-replaces-drawing'),
    ],
    itemHints: hints(
      'L\'ordre des lignes est l\'ordre des choses.',
      'The order of the lines is the order of events.',
      'Le son suit maintenant le trait.',
      'The sound now follows the line.',
    ),
    wrongChoiceFr:
        'Déplacer une ligne de son change le moment où on l\'entend.',
    wrongChoiceEn: 'Moving a sound line changes the moment you hear it.',
  ));

  // T9 — four open builds.
  for (final entry in [
    (
      'Fais un rythme avec le tambour.',
      'Make a rhythm with the drum.',
      'PLAY_DRUM'
    ),
    ('Joue une petite mélodie.', 'Play a little tune.', 'PLAY_NOTE'),
    (
      'Fais un dessin qui joue un son à chaque trait.',
      'Make a drawing that plays a sound on every line.',
      'PLAY_DRUM'
    ),
    (
      'Fais parler un lutin et jouer un son.',
      'Make a sprite speak and a sound play.',
      'PLAY_SOUND'
    ),
  ]) {
    items.add(openBuild(
      id: id(),
      conceptId: 'C10.3',
      difficulty: Difficulty.d3,
      stage: troupe,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine('Ton programme joue quelque chose.',
            'Your program plays something.', UsesOpcode(entry.$3)),
        rubricLine(
            'Le son est joué plusieurs fois.',
            'The sound is played more than once.',
            UsesOpcode(entry.$3, min: 2)),
        rubricLine(
            'Ton programme fait autre chose aussi.',
            'Your program does something else too.',
            const BlockCountWithin(min: 3)),
      ],
      itemHints: hints(
        'Un son se joue à sa ligne.',
        'A sound plays at its line.',
        'Mets-le dans un répète pour l\'entendre plusieurs fois.',
        'Put it in a repeat to hear it more than once.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C10.4 — Arrière-plans.
// Misconception: "the backdrop is a sprite".
//
// It is not, and the difference is not a definition to memorise — it is a fact a child
// can check in two moves. A backdrop belongs to the stage: change it and every character
// is standing somewhere new at once. A costume belongs to a sprite: change it and only
// that one has changed. The items put those two changes side by side.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC104() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C10.4-${(++n).toString().padLeft(2, '0')}';

  // T1 — set the scene, then have someone speak in it.
  for (final entry in [
    ('nuit', 'chat', 'il fait noir'),
    ('plage', 'chien', 'il fait chaud'),
    ('forêt', 'oiseau', 'des arbres'),
    ('nuit', 'oiseau', 'bonne nuit'),
    ('plage', 'chat', 'du sable'),
  ]) {
    final place = entry.$1, who = entry.$2, line = entry.$3;
    final solution = 'arrièreplan "$place"\nlutin "$who"\ndis "$line"';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C10.4',
      difficulty: Difficulty.d2,
      solution: solution,
      stage: troupe,
      promptKeys: fillBoth(
        b('Mets l\'arrière-plan « {p} », puis fais dire « {l} » à {w}.',
            'Set the backdrop "{p}", then make {w} say "{l}".'),
        {'p': place, 'w': who, 'l': line},
      ),
      wrong: [
        // A costume instead of a backdrop: the misconception exactly.
        'lutin "$who"\ncostumesuivant\ndis "$line"',
        'arrièreplan "${place == 'nuit' ? 'plage' : 'nuit'}"\n'
            'lutin "$who"\ndis "$line"',
        'arrièreplan "$place"\nlutin "$who"',
      ],
      assertions: [const UsesOpcode('SET_BACKDROP')],
      alternatives: [
        '# le décor, puis le personnage\n$solution',
        'lutin "$who"\narrièreplan "$place"\ndis "$line"',
      ],
      itemHints: hints(
        'L\'arrière-plan est derrière tout le monde.',
        'The backdrop is behind everybody.',
        'Un seul bloc le change.',
        'One block changes it.',
      ),
      paletteScope: palette,
    ));
  }

  // T3 — who changed, the place or the character?
  for (final entry in [
    ('arrièreplan "nuit"', 'le décor', 'the scene', 'le chat', 'the cat'),
    (
      'costumesuivant',
      'le lutin choisi',
      'the chosen sprite',
      'le décor',
      'the scene'
    ),
    (
      'arrièreplan "plage"\ncostumesuivant',
      'les deux',
      'both of them',
      'le décor seulement',
      'the scene only'
    ),
    (
      'lutin "chien"\ncostumesuivant',
      'le chien',
      'the dog',
      'tous les lutins',
      'every sprite'
    ),
  ]) {
    final source = entry.$1;
    items.add(predict(
      id: id(),
      conceptId: 'C10.4',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Qu\'est-ce qui change ?\n\n{p}', 'What changes?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b(entry.$2, entry.$3), correct: true),
        Choice(
            labelKeys: b(entry.$4, entry.$5),
            correct: false,
            misconception: 'C10.4-backdrop-is-a-sprite'),
        Choice(
            labelKeys: b('rien', 'nothing'),
            correct: false,
            misconception: 'C10.4-backdrop-needs-a-sprite'),
        Choice(
            labelKeys:
                b('toute la scène disparaît', 'the whole stage disappears'),
            correct: false,
            misconception: 'C10.4-backdrop-replaces-everything'),
      ],
      itemHints: hints(
        'Le décor appartient à la scène.',
        'The scene belongs to the stage.',
        'Le costume appartient au lutin.',
        'The costume belongs to the sprite.',
      ),
      wrongChoiceFr:
          'Un arrière-plan change le fond ; un costume change un seul lutin.',
      wrongChoiceEn:
          'A backdrop changes the background; a costume changes one sprite.',
    ));
  }

  // T4 — the hole is the block that changes the place.
  for (final entry in [
    ('nuit', 'chat'),
    ('plage', 'chien'),
    ('forêt', 'oiseau'),
  ]) {
    final place = entry.$1, who = entry.$2;
    final solution = 'arrièreplan "$place"\nlutin "$who"\ndis "me voilà"';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C10.4',
      difficulty: Difficulty.d2,
      stage: troupe,
      withHoles: '___\nlutin "$who"\ndis "me voilà"',
      solution: solution,
      promptKeys: fillBoth(
        b('Complète pour que la scène se passe « {p} ».',
            'Fill in the blank so the scene happens in "{p}".'),
        {'p': place},
      ),
      wrong: [
        'costumesuivant\nlutin "$who"\ndis "me voilà"',
        'arrièreplan "${place == 'nuit' ? 'plage' : 'nuit'}"\n'
            'lutin "$who"\ndis "me voilà"',
        'lutin "$place"\nlutin "$who"\ndis "me voilà"',
      ],
      assertions: [const UsesOpcode('SET_BACKDROP')],
      alternatives: [
        '# le décor d\'abord\n$solution',
        'lutin "$who"\narrièreplan "$place"\ndis "me voilà"',
      ],
      itemHints: hints(
        'Il existe un bloc pour le fond.',
        'There is a block for the background.',
        'Il s\'appelle arrièreplan.',
        'It is called backdrop.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d1,
    promptKeys: b('À qui appartient l\'arrière-plan ?',
        'Who does the backdrop belong to?'),
    choices: [
      Choice(
          labelKeys: b(
              'À la scène, pas à un lutin.', 'To the stage, not to a sprite.'),
          correct: true),
      Choice(
          labelKeys: b('Au lutin choisi.', 'To the chosen sprite.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-sprite'),
      Choice(
          labelKeys: b(
              'Au premier lutin de la scène.', 'To the stage\'s first sprite.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-sprite'),
      Choice(
          labelKeys: b(
              'À personne : c\'est une image.', 'To nobody: it is a picture.'),
          correct: false,
          misconception: 'C10.4-backdrop-needs-a-sprite'),
    ],
    itemHints: hints(
      'Change-le et regarde tout le monde.',
      'Change it and look at everybody.',
      'Ils sont tous ailleurs d\'un coup.',
      'They are all somewhere else at once.',
    ),
    wrongChoiceFr:
        'Le fond est celui de la scène : il change pour tous les lutins à la fois.',
    wrongChoiceEn:
        'The background is the stage\'s: it changes for every sprite at once.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Faut-il choisir un lutin avant de changer l\'arrière-plan ?',
        'Do you have to choose a sprite before changing the backdrop?'),
    choices: [
      Choice(
          labelKeys: b('Non : le fond ne dépend d\'aucun lutin.',
              'No: the background depends on no sprite.'),
          correct: true),
      Choice(
          labelKeys: b(
              'Oui, sinon rien ne change.', 'Yes, otherwise nothing changes.'),
          correct: false,
          misconception: 'C10.4-backdrop-needs-a-sprite'),
      Choice(
          labelKeys: b('Oui, et seul ce lutin le voit.',
              'Yes, and only that sprite sees it.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-sprite'),
      Choice(
          labelKeys: b('Seulement s\'il y a plusieurs lutins.',
              'Only if there are several sprites.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-sprite'),
    ],
    itemHints: hints(
      'Le bloc s\'adresse à la scène.',
      'The block talks to the stage.',
      'Pas à un personnage en particulier.',
      'Not to any particular character.',
    ),
    wrongChoiceFr:
        'Le bloc arrière-plan parle à la scène, quel que soit le lutin choisi.',
    wrongChoiceEn:
        'The backdrop block talks to the stage, whichever sprite is chosen.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b(
        'Quelle est la différence entre un costume et un arrière-plan ?',
        'What is the difference between a costume and a backdrop?'),
    choices: [
      Choice(
          labelKeys: b('Le costume habille un lutin, le fond habille la scène.',
              'A costume dresses a sprite, a backdrop dresses the stage.'),
          correct: true),
      Choice(
          labelKeys: b(
              'Aucune : ce sont deux images.', 'None: they are both pictures.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-sprite'),
      Choice(
          labelKeys: b('Le fond est plus grand.', 'The backdrop is bigger.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-big-costume'),
      Choice(
          labelKeys: b('Le costume est derrière.', 'The costume is behind.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-sprite'),
    ],
    itemHints: hints(
      'Demande-toi à qui chacun appartient.',
      'Ask yourself who each one belongs to.',
      'L\'un est à un lutin, l\'autre à tout le monde.',
      'One belongs to a sprite, the other to everybody.',
    ),
    wrongChoiceFr:
        'Ce sont deux images, mais elles n\'appartiennent pas au même.',
    wrongChoiceEn:
        'Both are pictures, but they do not belong to the same thing.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.4',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b(
        'Trois lutins sont sur la scène. Tu changes l\'arrière-plan. Combien en voient un nouveau décor ?',
        'Three sprites are on the stage. You change the backdrop. How many see a new scene?'),
    choices: [
      Choice(labelKeys: b('Les trois.', 'All three.'), correct: true),
      Choice(
          labelKeys:
              b('Un seul : celui qui est choisi.', 'One: the chosen one.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-sprite'),
      Choice(
          labelKeys: b('Aucun.', 'None.'),
          correct: false,
          misconception: 'C10.4-backdrop-needs-a-sprite'),
      Choice(
          labelKeys: b('Ceux qui ont un costume.', 'The ones with a costume.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-big-costume'),
    ],
    itemHints: hints(
      'Il n\'y a qu\'un seul fond pour la scène.',
      'There is only one background for the stage.',
      'Tout le monde est devant.',
      'Everybody stands in front of it.',
    ),
    wrongChoiceFr:
        'Un seul fond, une seule scène : il change pour tout le monde.',
    wrongChoiceEn: 'One background, one stage: it changes for everybody.',
  ));

  // T9 — three open builds.
  for (final entry in [
    (
      'Fais une scène avec un décor et un personnage.',
      'Make a scene with a backdrop and a character.'
    ),
    ('Raconte une histoire en deux endroits.', 'Tell a story in two places.'),
    (
      'Fais changer de décor pendant que quelqu\'un parle.',
      'Change the scene while somebody is speaking.'
    ),
  ]) {
    final twoPlaces = entry.$1.startsWith('Raconte');
    items.add(openBuild(
      id: id(),
      conceptId: 'C10.4',
      difficulty: Difficulty.d3,
      stage: troupe,
      promptKeys: b(entry.$1, entry.$2),
      rubric: [
        rubricLine(
            twoPlaces ? 'Tu changes deux fois de décor.' : 'Tu poses un décor.',
            twoPlaces ? 'You change the scene twice.' : 'You set a scene.',
            UsesOpcode('SET_BACKDROP', min: twoPlaces ? 2 : 1)),
        rubricLine('Un lutin dit quelque chose.', 'A sprite says something.',
            const UsesOpcode('SAY')),
        rubricLine(
            'Tu choisis à qui tu parles.',
            'You choose who you are talking to.',
            const UsesOpcode('SELECT_SPRITE')),
      ],
      itemHints: hints(
        'Le décor d\'abord, les personnages ensuite.',
        'The scene first, the characters after.',
        'Un bloc suffit pour changer de lieu.',
        'One block is enough to change place.',
      ),
      paletteScope: palette,
    ));
  }

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// C10.5 — Effets graphiques.
// Misconception: "effects are permanent".
//
// They are not, and the model was built so that they cannot be: an effect is a layer over
// the costume rather than something baked into it, and `effaceeffets` takes the layer off.
// A child who believes an effect is permanent has usually got there by watching one and
// never removing it, so every item in this concept has a partner where the effect comes
// back off, and half the parameter sets end clean.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Item> conceptC105() {
  final items = <Item>[];
  var n = 0;
  String id() => 'C10.5-${(++n).toString().padLeft(2, '0')}';

  /* T1 — put an effect on, and — half the time — take it off again. The clearing sets are
     the ones that carry the concept: their stage ends exactly as it started, which is
     what "not permanent" means. */
  for (final entry in [
    ('chat', 'fantôme', 50, false),
    ('chien', 'tourbillon', 30, false),
    ('oiseau', 'couleur', 25, true),
    ('chat', 'pixel', 20, true),
    ('chien', 'luminosité', 40, true),
  ]) {
    final who = entry.$1,
        effect = entry.$2,
        value = entry.$3,
        clears = entry.$4;
    final solution = 'lutin "$who"\neffet "$effect", $value'
        '${clears ? '\neffaceeffets' : ''}';
    items.add(buildToTarget(
      id: id(),
      conceptId: 'C10.5',
      difficulty: Difficulty.d3,
      solution: solution,
      stage: troupe,
      promptKeys: fillBoth(
        b(
            clears
                ? 'Pose l\'effet « {e} » à {v} sur {w}, puis enlève-le.'
                : 'Pose l\'effet « {e} » à {v} sur {w} et laisse-le.',
            clears
                ? 'Put the "{e}" effect at {v} on {w}, then take it off.'
                : 'Put the "{e}" effect at {v} on {w} and leave it on.'),
        {'e': effect, 'v': value, 'w': who},
      ),
      /* An item that ends clean cannot be graded on what is left, because nothing is:
         "put the ghost on at fifty then take it off" finishes in exactly the state of a
         program that did nothing. So the clearing half of this concept is a structural
         claim, and its distractors are the programs that skip one of the two blocks.
         The gate caught six items whose "wrong" answers were, in the only sense it could
         see, correct. */
      wrong: clears
          ? [
              // The effect left on: the misconception, kept.
              'lutin "$who"\neffet "$effect", $value',
              // Cleared but never set: nothing put on, nothing to take off.
              'lutin "$who"\neffaceeffets',
              // Cleared first, then set: the layer is still there at the end.
              'lutin "$who"\neffaceeffets\neffet "$effect", $value',
            ]
          : [
              'lutin "$who"\neffet "$effect", $value\neffaceeffets',
              'lutin "$who"\neffet "$effect", ${value + 20}',
              'lutin "$who"\neffet "${effect == 'tourbillon' ? 'pixel' : 'tourbillon'}", $value',
            ],
      assertions: [
        const UsesOpcode('SET_EFFECT'),
        if (clears) const UsesOpcode('CLEAR_EFFECTS'),
      ],
      alternatives: [
        '# un effet posé sur le lutin\n$solution',
        solution.replaceFirst('lutin "$who"\n', 'lutin "$who"\n\n'),
      ],
      itemHints: hints(
        'Un effet se pose sur le lutin choisi.',
        'An effect goes onto the chosen sprite.',
        clears ? 'Un bloc les enlève tous.' : 'Laisse-le en place.',
        clears ? 'One block takes them all off.' : 'Leave it in place.',
      ),
      paletteScope: palette,
    ));
  }

  /* T3 — what is left at the end? The choice that says "l'effet est toujours là" is the
     misconception, and on the clearing programs it is simply false. */
  for (final entry in [
    (
      'effet "fantôme", 50\neffaceeffets',
      'rien',
      'nothing',
      'fantôme 50',
      'ghost 50'
    ),
    ('effet "fantôme", 50', 'fantôme 50', 'ghost 50', 'rien', 'nothing'),
    (
      'effet "couleur", 25\neffet "fantôme", 10',
      'les deux',
      'both of them',
      'couleur 25 seulement',
      'colour 25 only'
    ),
    (
      'effet "pixel", 20\neffaceeffets\neffet "couleur", 5',
      'couleur 5',
      'colour 5',
      'pixel 20 et couleur 5',
      'pixel 20 and colour 5'
    ),
    ('effaceeffets', 'rien', 'nothing', 'tous les effets', 'every effect'),
  ]) {
    final source = entry.$1;
    items.add(predict(
      id: id(),
      conceptId: 'C10.5',
      difficulty: Difficulty.d3,
      promptKeys: fillBoth(
        b('Quels effets restent à la fin ?\n\n{p}',
            'Which effects are left at the end?\n\n{p}'),
        {'p': source},
      ),
      choices: [
        Choice(labelKeys: b(entry.$2, entry.$3), correct: true),
        Choice(
            labelKeys: b(entry.$4, entry.$5),
            correct: false,
            misconception: 'C10.5-effects-are-permanent'),
        Choice(
            labelKeys: b('on ne peut pas savoir', 'there is no way to know'),
            correct: false,
            misconception: 'C10.5-effects-are-unpredictable'),
        Choice(
            labelKeys: b('le lutin disparaît', 'the sprite disappears'),
            correct: false,
            misconception: 'C10.5-effects-destroy'),
      ],
      itemHints: hints(
        'Un effet reste jusqu\'à ce qu\'on l\'enlève.',
        'An effect stays until it is taken off.',
        'Un bloc les enlève tous d\'un coup.',
        'One block takes them all off at once.',
      ),
      wrongChoiceFr:
          'Un effet est une couche posée sur le costume ; elle s\'enlève.',
      wrongChoiceEn: 'An effect is a layer over the costume; it comes off.',
    ));
  }

  // T4 — the hole is the block that takes the layer off.
  for (final entry in [
    ('chat', 'fantôme', 50),
    ('chien', 'tourbillon', 30),
    ('oiseau', 'couleur', 25),
    ('chat', 'pixel', 20),
    ('chien', 'luminosité', 40),
  ]) {
    final who = entry.$1, effect = entry.$2, value = entry.$3;
    final solution = 'lutin "$who"\neffet "$effect", $value\neffaceeffets';
    items.add(fillTheGap(
      id: id(),
      conceptId: 'C10.5',
      difficulty: Difficulty.d2,
      stage: troupe,
      withHoles: 'lutin "$who"\neffet "$effect", $value\n___',
      solution: solution,
      promptKeys: b('Complète pour que le lutin redevienne normal.',
          'Fill in the blank so the sprite goes back to normal.'),
      wrong: [
        'lutin "$who"\neffet "$effect", $value\neffet "$effect", 0',
        'lutin "$who"\neffet "$effect", $value\ncostumesuivant',
        'lutin "$who"\neffet "$effect", $value\ndis "voilà"',
      ],
      assertions: [const UsesOpcode('CLEAR_EFFECTS')],
      alternatives: [
        '# on enlève la couche\n$solution',
        'lutin "$who"\n\neffet "$effect", $value\neffaceeffets',
      ],
      itemHints: hints(
        'Un bloc enlève tous les effets d\'un coup.',
        'One block takes every effect off at once.',
        'Il s\'appelle effaceeffets.',
        'It is called cleareffects.',
      ),
      paletteScope: palette,
    ));
  }

  // T6 — read and answer.
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d1,
    promptKeys: b(
        'Un effet reste-t-il pour toujours ?', 'Does an effect stay for ever?'),
    choices: [
      Choice(
          labelKeys:
              b('Non : un bloc l\'enlève.', 'No: one block takes it off.'),
          correct: true),
      Choice(
          labelKeys: b('Oui, une fois posé c\'est fini.',
              'Yes, once it is on that is that.'),
          correct: false,
          misconception: 'C10.5-effects-are-permanent'),
      Choice(
          labelKeys: b('Oui, sauf si on change de costume.',
              'Yes, unless you change costume.'),
          correct: false,
          misconception: 'C10.5-costume-clears-effects'),
      Choice(
          labelKeys: b('Il s\'en va tout seul après un moment.',
              'It goes away on its own after a while.'),
          correct: false,
          misconception: 'C10.5-effects-expire'),
    ],
    itemHints: hints(
      'Un effet est posé par-dessus le costume.',
      'An effect is laid over the costume.',
      'On peut l\'enlever comme on l\'a posé.',
      'You can take it off the way you put it on.',
    ),
    wrongChoiceFr:
        'Un effet est une couche : effaceeffets la retire quand tu veux.',
    wrongChoiceEn:
        'An effect is a layer: cleareffects takes it off whenever you like.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d2,
    promptKeys: b('Que fait effaceeffets ?', 'What does cleareffects do?'),
    choices: [
      Choice(
          labelKeys: b('Il enlève tous les effets du lutin choisi.',
              'It takes every effect off the chosen sprite.'),
          correct: true),
      Choice(
          labelKeys: b('Il efface le lutin.', 'It erases the sprite.'),
          correct: false,
          misconception: 'C10.5-effects-destroy'),
      Choice(
          labelKeys: b('Il efface le dessin.', 'It erases the drawing.'),
          correct: false,
          misconception: 'C10.5-clear-erases-the-canvas'),
      Choice(
          labelKeys: b('Il enlève le dernier effet seulement.',
              'It takes off the last effect only.'),
          correct: false,
          misconception: 'C10.5-clear-removes-one'),
    ],
    itemHints: hints(
      'Le mot dit « efface les effets ».',
      'The word says "clear the effects".',
      'Pas le lutin, pas le dessin.',
      'Not the sprite, not the drawing.',
    ),
    wrongChoiceFr:
        'Il remet le lutin choisi comme il était, sans toucher au dessin.',
    wrongChoiceEn:
        'It puts the chosen sprite back as it was, leaving the drawing alone.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Tu poses un effet sur le chat. Le chien change-t-il aussi ?',
        'You put an effect on the cat. Does the dog change too?'),
    choices: [
      Choice(
          labelKeys: b('Non : l\'effet est sur le lutin choisi.',
              'No: the effect is on the chosen sprite.'),
          correct: true),
      Choice(
          labelKeys: b('Oui : les effets sont pour la scène.',
              'Yes: effects belong to the stage.'),
          correct: false,
          misconception: 'C10.4-backdrop-is-a-sprite'),
      Choice(
          labelKeys: b('Oui, s\'ils ont le même costume.',
              'Yes, if they have the same costume.'),
          correct: false,
          misconception: 'C10.2-costume-is-a-sprite'),
      Choice(
          labelKeys: b(
              'Seulement le chien, pas le chat.', 'The dog only, not the cat.'),
          correct: false,
          misconception: 'C10.1-selection-does-not-stick'),
    ],
    itemHints: hints(
      'Un effet suit le lutin, comme son costume.',
      'An effect follows the sprite, like its costume.',
      'Le fond, lui, est pour tout le monde.',
      'The background is the one for everybody.',
    ),
    wrongChoiceFr:
        'Les effets sont à un lutin ; seul l\'arrière-plan est à tous.',
    wrongChoiceEn:
        'Effects belong to a sprite; only the backdrop belongs to everybody.',
  ));
  items.add(choiceItem(
    id: id(),
    conceptId: 'C10.5',
    type: ItemType.t6ReadAndAnswer,
    difficulty: Difficulty.d3,
    promptKeys: b('Tu poses deux effets différents. Combien en restent ?',
        'You put on two different effects. How many are left?'),
    choices: [
      Choice(
          labelKeys: b('Les deux : ils s\'ajoutent.', 'Both: they add up.'),
          correct: true),
      Choice(
          labelKeys: b('Un seul : le dernier.', 'One: the last.'),
          correct: false,
          misconception: 'C10.5-effects-replace-each-other'),
      Choice(
          labelKeys: b('Un seul : le premier.', 'One: the first.'),
          correct: false,
          misconception: 'C10.5-effects-replace-each-other'),
      Choice(
          labelKeys: b('Aucun : ils s\'annulent.', 'None: they cancel out.'),
          correct: false,
          misconception: 'C10.5-effects-cancel'),
    ],
    itemHints: hints(
      'Chaque effet a son propre réglage.',
      'Each effect has its own setting.',
      'Poser l\'un ne touche pas à l\'autre.',
      'Setting one does not touch the other.',
    ),
    wrongChoiceFr:
        'Chaque effet est réglé à part : deux effets tiennent ensemble.',
    wrongChoiceEn: 'Each effect is set separately: two effects hold together.',
  ));

  // T9 — one open build, to round the concept out at twenty.
  items.add(openBuild(
    id: id(),
    conceptId: 'C10.5',
    difficulty: Difficulty.d3,
    stage: troupe,
    promptKeys: b('Fais apparaître puis disparaître un effet.',
        'Make an effect appear and then disappear.'),
    rubric: [
      rubricLine('Tu poses un effet.', 'You put an effect on.',
          const UsesOpcode('SET_EFFECT')),
      rubricLine('Tu l\'enlèves ensuite.', 'You take it off afterwards.',
          const UsesOpcode('CLEAR_EFFECTS')),
      rubricLine('Tu choisis le lutin.', 'You choose the sprite.',
          const UsesOpcode('SELECT_SPRITE')),
    ],
    itemHints: hints(
      'Pose d\'abord, enlève ensuite.',
      'Put it on first, take it off after.',
      'Un bloc fait chacune des deux choses.',
      'One block does each of the two.',
    ),
    paletteScope: palette,
  ));

  return items;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// Tutorials (§4.2: Je regarde · On fait ensemble · Je fais).
//
// A tutorial step in this world can check a block but not a sprite — `SuccessCondition`
// counts opcodes and assignments, and "did they choose the dog" is neither. So the *On
// fait ensemble* steps ask for the block that does the thing, which is the block the step
// is teaching in every case.
// ═══════════════════════════════════════════════════════════════════════════════════════

List<Tutorial> world10Tutorials() => [
      tutorialFor(
        conceptId: 'C10.1',
        conceptName: b(
            'Plusieurs lutins sur une scène.', 'Several sprites on one stage.'),
        palette: palette,
        steps: [
          watchStep(
            'C10.1',
            'Deux lutins parlent chacun leur tour.',
            'Two sprites speak one after the other.',
            'lutin "chat"\ndis "miaou"\nlutin "chien"\ndis "ouaf"',
            ideas: ['sprite', 'selection'],
          ),
          togetherStep(
            'C10.1',
            'À toi. Choisis le chien avant de parler.',
            'Your turn. Choose the dog before speaking.',
            opcodeId: 'SELECT_SPRITE',
            hintFr: 'Écris lutin puis son nom entre guillemets.',
            hintEn: 'Write sprite then its name in quotes.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C10.1',
            'Fais parler deux lutins différents.',
            'Make two different sprites speak.',
            opcodeId: 'SAY',
            hintFr: 'Choisis le lutin, puis fais-le parler.',
            hintEn: 'Choose the sprite, then make it speak.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C10.2',
        conceptName: b('Des images qui défilent font bouger.',
            'Pictures running past make things move.'),
        palette: palette,
        steps: [
          watchStep(
            'C10.2',
            'Le lutin change d\'image, encore et encore.',
            'The sprite changes picture, again and again.',
            'lutin "chat"\nrépète 6 {\n  costumesuivant\n}',
            ideas: ['costume', 'animation'],
          ),
          togetherStep(
            'C10.2',
            'Ajoute le bloc qui passe à l\'image suivante.',
            'Add the block that moves to the next picture.',
            opcodeId: 'NEXT_COSTUME',
            hintFr: 'Il s\'appelle costumesuivant.',
            hintEn: 'It is called nextcostume.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C10.2',
            'Anime un lutin avec ses images.',
            'Animate a sprite with its pictures.',
            opcodeId: 'NEXT_COSTUME',
            hintFr: 'Mets le bloc dans un répète.',
            hintEn: 'Put the block inside a repeat.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C10.3',
        conceptName:
            b('Un son se joue à sa ligne.', 'A sound plays at its line.'),
        palette: palette,
        steps: [
          watchStep(
            'C10.3',
            'Le tambour sonne avant chaque trait.',
            'The drum sounds before each line.',
            'répète 4 {\n  tambour 1, 1\n  avance 20\n}',
            ideas: ['sound', 'order'],
          ),
          togetherStep(
            'C10.3',
            'Ajoute un coup de tambour avant le trait.',
            'Add a drum beat before the line.',
            opcodeId: 'PLAY_DRUM',
            hintFr: 'Écris tambour, son numéro et sa durée.',
            hintEn: 'Write drum, its number and how long.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C10.3',
            'Fais un rythme avec le tambour.',
            'Make a rhythm with the drum.',
            opcodeId: 'PLAY_DRUM',
            hintFr: 'Un son se joue là où tu l\'écris.',
            hintEn: 'A sound plays where you write it.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C10.4',
        conceptName:
            b('Le décor est à la scène.', 'The scene belongs to the stage.'),
        palette: palette,
        steps: [
          watchStep(
            'C10.4',
            'Le fond change et tous sont ailleurs.',
            'The scene changes and they are all somewhere new.',
            'arrièreplan "nuit"\nlutin "chat"\ndis "il fait noir"',
            ideas: ['backdrop', 'stage'],
          ),
          togetherStep(
            'C10.4',
            'Pose le décor de la nuit.',
            'Set the night scene.',
            opcodeId: 'SET_BACKDROP',
            hintFr: 'Écris arrièreplan puis son nom.',
            hintEn: 'Write backdrop then its name.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C10.4',
            'Fais une scène avec un décor et quelqu\'un.',
            'Make a scene with a backdrop and somebody.',
            opcodeId: 'SET_BACKDROP',
            hintFr: 'Le décor ne demande aucun lutin.',
            hintEn: 'The scene asks for no sprite at all.',
          ),
        ],
      ),
      tutorialFor(
        conceptId: 'C10.5',
        conceptName: b('Un effet se pose et s\'enlève.',
            'An effect goes on and comes off.'),
        palette: palette,
        steps: [
          watchStep(
            'C10.5',
            'Le chat devient transparent, puis redevient normal.',
            'The cat turns see-through, then goes back to normal.',
            'lutin "chat"\neffet "fantôme", 50\neffaceeffets',
            ideas: ['effect', 'clearing'],
          ),
          togetherStep(
            'C10.5',
            'Pose l\'effet fantôme à cinquante.',
            'Put the ghost effect on at fifty.',
            opcodeId: 'SET_EFFECT',
            hintFr: 'Écris effet, son nom, puis le nombre.',
            hintEn: 'Write effect, its name, then the number.',
            action: ExpectedAction.buildProgram,
          ),
          doStep(
            'C10.5',
            'Pose un effet, puis enlève-le.',
            'Put an effect on, then take it off.',
            opcodeId: 'CLEAR_EFFECTS',
            hintFr: 'Un bloc les enlève tous d\'un coup.',
            hintEn: 'One block takes them all off at once.',
          ),
        ],
      ),
    ];

void main() {
  publishWorld(
    world: 10,
    nameKeys: b('Lutins, costumes, sons', 'Sprites, costumes, sounds'),
    conceptGraph: conceptGraph,
    committed: committed,
    items: [
      ...conceptC101(),
      ...conceptC102(),
      ...conceptC103(),
      ...conceptC104(),
      ...conceptC105(),
    ],
    tutorials: world10Tutorials(),
    assetKeys: const ['art/tika.svg', 'art/world10-lutins.svg'],
  );
}
