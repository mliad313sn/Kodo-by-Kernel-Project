/// KODO's interface strings (M15).
///
/// The catalogue itself. Every string here is a whole sentence with a context note, and
/// `lintCatalogue` is run over it by the acceptance tests, so a fragment cannot be added
/// without the build saying so.
///
/// This is the interface layer only. Error messages live in M1's catalogue (they are part
/// of the language), item and tutorial text lives in the content packs, and keywords are
/// `KeywordTable` — three layers, localised independently, per `FR-M15-01`.
library;

import 'strings.dart';

UiString _s(
  String key,
  String fr,
  String en, {
  required String context,
  List<String> placeholders = const [],
}) =>
    UiString(
      key: key,
      texts: {'fr': fr, 'en': en},
      context: context,
      placeholders: placeholders,
    );

/// The v1 interface catalogue.
final StringCatalogue uiStrings = StringCatalogue([
  // --- buttons and menus ---------------------------------------------------------------
  _s('button.run', 'Essayer', 'Try it',
      context:
          'The main button under the editor. A child presses it to run their '
          'program. Not "execute".'),
  _s('button.stop', 'Arrêter', 'Stop',
      context:
          'Stops a running program. Appears in place of the run button while a '
          'program runs.'),
  _s('button.step', 'Pas à pas', 'Step',
      context: 'Runs one instruction at a time so the child can watch.'),
  _s('button.undo', 'Annuler', 'Undo',
      context: 'Undoes the last edit in the editor toolbar.'),
  _s('button.redo', 'Refaire', 'Redo',
      context: 'Redoes an undone edit in the editor toolbar.'),
  _s('button.help', 'Aide', 'Help',
      context: 'Opens the help card for the block the child is looking at.'),
  // Two words, not four. A button cannot wrap, and these have to stay inside 18
  // characters at 140 % — which is also what keeps them legible at 200 % text scale.
  _s('button.text_view', 'Texte', 'Text',
      context:
          'Switches the editor from blocks to text. The child is not converting '
          'anything; they are looking at the same program differently. A button, so it '
          'must stay short enough not to wrap.'),
  _s('button.block_view', 'Blocs', 'Blocks',
      context:
          'Switches back from text to blocks. A button, so it must stay short '
          'enough not to wrap.'),
  _s('menu.recettes', 'Recettes', 'Recipes',
      context:
          'The Studio panel of copy-a-pattern examples. Keep the cooking metaphor: a '
          'recipe is something you follow and then change.'),
  /* §9.1's five root destinations. They are the only five words a child sees on every
     screen, so they are the five that matter most: each one is what the child would call
     the place, not what the architecture calls it. "Entraînement" is deliberately not
     "Exercices" — §10 forbids the vocabulary of testing. */
  _s('root.carte', 'Carte', 'Map',
      context:
          'Bottom tab 1 of 5. The world map, the single entry point to learning. '
          'One word; it sits under a small icon on a phone.'),
  /* Measured, not guessed. Five tabs across a 360 dp phone give each label about ten
     characters a line, and the pseudo-locale run grows every string by 40 % to stand in
     for a worse translation. "Entraînement" is twelve characters before that, so it broke
     as "Entraîneme / nt" — not a word in any language — and a soft hyphen only moved the
     problem. §9.1 names the DESTINATION Entraînement, and it still does: `KodoScreen
     .entrainement` is its route. This is the child-facing LABEL, which is a different
     thing and is allowed to be a different word in each language. See PO decision D-013.
     "Défis" is play framing; §10 forbids the vocabulary of assessment, so no "test",
     "quiz", "exam" or "évaluation" may ever appear here. */
  _s('root.entrainement', 'Défis', 'Practice',
      context:
          'Bottom tab 2 of 5: today\'s mix of exercises, behind one button. MUST fit '
          'about ten characters — it is a tab on a phone. Never "test", "quiz" or '
          '"exam": children are never told they are being assessed.'),
  /* `FR-M6-06`. The heading over an open build's rubric, shown BEFORE the child starts.
     Not "critères" and not "barème": §10 forbids the vocabulary of assessment, and a
     child reading "what a good one has" is being told how to succeed rather than how
     they will be marked. */
  _s('rubric.title', 'Ce qu\'il faut dans ton dessin :',
      'What your drawing needs:',
      context:
          'Heading over the list of things an open build has to have. It is shown from '
          'the first frame, while the child works, never after. About thirty characters; '
          'never "test", "note", "barème" or any word of assessment.'),
  _s('root.studio', 'Studio', 'Studio',
      context:
          'Bottom tab 3 of 5. Where a child\'s own projects live. The word is kept '
          'in both languages on purpose — children already know it.'),
  _s('root.galerie', 'Galerie', 'Gallery',
      context:
          'Bottom tab 4 of 5. Projects shared by the class, when a teacher has '
          'enabled sharing. It is a place to look, not a feed to scroll.'),
  _s('root.moi', 'Moi', 'Me',
      context:
          'Bottom tab 5 of 5. Avatar, badges, stars and settings. First person, '
          'because it is the child\'s own corner of the app.'),
  /* The loop's four words. §10 rules the wording as much as the mechanics: the button
     after a right answer says "continue", never "next level"; the one after a wrong
     answer says "again", never "retry" or "failed"; and asking for a hint is offered
     rather than charged for. */
  _s('button.keep_going', 'Continuer', 'Keep going',
      context:
          'The button after a correct answer. It moves to the next exercise. '
          'Never celebratory, never a level-up: the child decides when to go on.'),
  _s('button.again', 'Encore', 'Again',
      context:
          'The button after a wrong answer. It clears the message and lets the '
          'child keep working on the SAME exercise. Never "retry", "failed" or '
          'anything that names the attempt as a loss.'),
  _s('feedback.correct', 'C\'est ça.', 'That is it.',
      context:
          'Shown when an answer is right. One short sentence. Not "Well done!", '
          'not "Perfect!" — the programme praises the work, never the child, and '
          'never with exclamation marks.'),
  _s('feedback.session_done', 'Tu as fini pour aujourd\'hui.',
      'You are done for today.',
      context:
          'Shown when the practice mix has no more exercises. It is an ending, '
          'not a reward screen, and nothing about it should push for more.'),
  _s('feedback.count_passed', 'Tu as réussi {count} exercices.',
      'You got {count} exercises right.',
      context:
          'A count of what went right in this session. It never shows what went '
          'wrong: §10 forbids showing a child a failure tally.',
      placeholders: ['count']),
  _s('button.ok', 'D\'accord', 'OK',
      context:
          'Confirms the number a child has just typed on the pad. A short word; '
          'it sits on a small button beside "Annuler".'),
  /* M5's tutorial screen. §7.2's three beats are content, not interface, so the only
     interface words the tutorial needs are the ones that are the same in every one of
     them: what the screen is called, and the two sentences that end it. The call to
     action itself comes from the step, because it names the one thing this step asks. */
  _s('root.tutoriel', 'On apprend', 'Let us learn',
      context:
          'The title of the tutorial screen. First person plural on purpose: the '
          'tutorial does it WITH the child, which is the whole of the three beats. '
          'Never "Lesson" or "Course".'),
  _s('tutorial.learned', 'Tu sais faire : {concept}.',
      'You can do this now: {concept}.',
      context:
          'The closing line of a tutorial. {concept} is the concept named in the '
          'child\'s own words, from the content pack. It states a fact about what '
          'they can do, never praise.',
      placeholders: ['concept']),
  _s('button.to_exercises', 'À moi', 'My turn',
      context:
          'The button that leaves a finished tutorial for the exercises. It names '
          'what happens next from the child\'s side, not the app\'s. A button, so it '
          'must stay short enough not to wrap.'),
  /* The controls M2 and M4 grew after the first audit. Each one is an icon on a button,
     so the catalogue entry IS what a screen reader says — there is no visible label to
     fall back on, and a wordless button is a button only a sighted child has. */
  _s('a11y.zoom_in', 'Agrandir le dessin.', 'Make the drawing bigger.',
      context:
          'The + button over the canvas (`FR-M4-02`). It magnifies the drawing so a '
          'child can look closely at part of it.'),
  _s('a11y.zoom_out', 'Réduire le dessin.', 'Make the drawing smaller.',
      context: 'The − button over the canvas. The opposite of a11y.zoom_in.'),
  _s('a11y.zoom_all', 'Voir tout le dessin.', 'See the whole drawing.',
      context:
          'The button that puts a magnified canvas back to showing everything. '
          'Only offered when the drawing is magnified.'),
  _s('a11y.grab_stack', 'Prendre ce bloc et ceux du dessous.',
      'Pick up this block and the ones below.',
      context:
          'The handle beside a block in the script (`FR-M2-06`). It says what will '
          'move, which is the whole difference between a block editor and a list.'),
  _s('a11y.drop_here', 'Poser les blocs ici.', 'Put the blocks here.',
      context:
          'A place a held stack of blocks can be put down. Every gap on screen says '
          'this, so a child using a screen reader can place a stack without seeing '
          'where the gaps are.'),
  _s('a11y.keep_program', 'Garder mon programme.', 'Keep my program.',
      context: 'The button that exports the program as text and as a picture '
          '(`FR-M3-08`). "Keep", not "export": a child is saving something they made.'),
  _s('a11y.block_level', 'Il est au niveau {level}.', 'It is at level {level}.',
      context:
          'Appended to a block\'s screen-reader label when the block is inside '
          'another one. A child who cannot see the indentation has no other way to '
          'know a block is inside a loop.',
      placeholders: ['level']),
  _s('a11y.spotlight', 'Regarde ici.', 'Look here.',
      context:
          'What a screen reader says for the highlighted area during a tutorial '
          'step. A child who cannot see the spotlight still has to be told where '
          'the tutorial is pointing.'),
  _s('a11y.number_field', 'Le nombre {value}. Appuie pour le changer.',
      'The number {value}. Press to change it.',
      context:
          'What a screen reader says for an editable number inside a block. The '
          'second sentence matters: a number that reads as decoration is a number '
          'nobody edits.',
      placeholders: ['value']),
  _s('a11y.number_gap', 'Un nombre à écrire. Appuie pour le remplir.',
      'A number to write. Press to write it.',
      context:
          'What a screen reader says for an EMPTY number slot in a block — the '
          'gap a fill-in exercise leaves. Different from a number that is already '
          'there: a child needs to know there is something missing.'),
  /* `FR-M2-05`. The dropdown twins of the two above: a named argument reads as a name
     that can be changed, and an empty one as something still to choose. A block whose
     name reads as decoration is a block nobody opens. */
  _s('a11y.choice_field', 'Le mot {value}. Appuie pour en choisir un autre.',
      'The word {value}. Press to choose another.',
      context:
          'What a screen reader says for a chosen name inside a block — a key, an '
          'effect, a sprite, a sound. Never typed, always chosen from a list.',
      placeholders: ['value']),
  _s('a11y.choice_gap', 'Un mot à choisir. Appuie pour ouvrir la liste.',
      'A word to choose. Press to open the list.',
      context:
          'What a screen reader says for an EMPTY name slot in a block. A child '
          'needs to know there is a list behind it, not a keyboard.'),
  _s('button.practice_start', 'Commencer', 'Start',
      context:
          'The single large button on the Practice screen. It starts today\'s mix; '
          'a child never has to choose what to practise.'),
  _s('galerie.empty', 'Rien n\'est partagé pour le moment.',
      'Nothing is shared just yet.',
      context:
          'Shown on the Gallery screen when sharing is off or the class has posted '
          'nothing. It must not sound like a failure or an error.'),
  _s('moi.stars', 'Tu as {count} étoiles.', 'You have {count} stars.',
      context:
          'On the Me screen, under the avatar. Stars are earned, never lost — do not '
          'translate as a score or a total that can go down.',
      placeholders: ['count']),
  _s('carte.locked', 'Ce monde s\'ouvrira bientôt.', 'This world opens soon.',
      context:
          'Shown when a child taps a world they have not reached. It says when, not '
          'no: nothing in KODO is refused to a child, only not yet arrived.'),
  _s('profiles.who', 'Qui joue ?', 'Who is playing?',
      context:
          'The question above the list of children on the first screen. It replaces '
          'a login: nobody signs in, somebody says it is them.'),
  _s('label.parent_space', 'Espace des parents', 'Parent space',
      context:
          'A row in the child\'s Me screen that opens the adult area behind a gate. '
          'It is named for the adult, not for the child: a child reading it should '
          'understand it is not for them.'),
  _s('tab.mouvement', 'Bouger', 'Move',
      context:
          'A block family tab. Verbs, not nouns: these are things the turtle does.'),
  _s('tab.controle', 'Répéter', 'Repeat',
      context: 'The control-flow block family tab.'),
  _s('label.class_code', 'Code de la classe', 'Class code',
      context:
          'Above the six-character code a teacher reads aloud to the class.'),

  // --- the editor -----------------------------------------------------------------------
  _s(
      'editor.empty_script',
      'Glisse un bloc ici, ou appuie sur un bloc à gauche.',
      'Drag a block here, or tap a block on the left.',
      context:
          'Shown in the empty script area before a child has placed anything. Must '
          'name both ways of placing a block, because tapping is the primary one on a '
          'phone.'),
  _s('editor.running', 'Ça tourne…', 'Running…',
      context: 'Status line while a program runs.'),
  _s('editor.finished', 'C\'est fini.', 'All done.',
      context:
          'Status line when a program ends normally. Neutral, not congratulatory — '
          'the program ran, that is all.'),
  _s('editor.stopped', 'Tu as arrêté le programme.', 'You stopped the program.',
      context:
          'Status line after the child pressed stop. Says who did it, so the child '
          'does not think it crashed.'),
  _s(
      'editor.too_long',
      'Ton programme tourne depuis longtemps. Je l\'ai arrêté.',
      'Your program has been running a long time. I stopped it.',
      context:
          'Shown when the run limit is reached — usually an infinite loop. Says what '
          'happened and who did it, and does not call the child wrong.'),

  // --- the language switch ---------------------------------------------------------------
  _s('label.interface_language', 'Langue de l\'écran', 'Screen language',
      context:
          'Setting label. The language of the interface, which is separate from the '
          'language of the keywords — see the next string.'),
  _s('label.keyword_language', 'Langue des mots de code', 'Code word language',
      context:
          'Setting label. The language the blocks and text use — avance or forward. '
          'A child may read French screens and write English keywords.'),
  _s(
      'language.switch_kept',
      'Ton programme n\'a pas changé. Seuls les mots ont changé.',
      'Your program has not changed. Only the words have changed.',
      context:
          'Shown after a keyword-language switch. The reassurance is the point: the '
          'child just watched every word on screen change.'),

  // --- narration and accessibility ---------------------------------------------------------
  _s(
      'a11y.block_label',
      '{keyword}, famille {family}, bloc {position} sur {total}.',
      '{keyword}, {family} family, block {position} of {total}.',
      context:
          'Screen-reader label for one block in the script. Read in order, so the '
          'position comes last. Keep it one sentence.',
      placeholders: ['keyword', 'family', 'position', 'total']),
  _s('a11y.family_tab', 'Famille {family}.', '{family} family.',
      context:
          'Screen-reader label for a block-family tab in the palette. The visible '
          'label is just the family name; this says what kind of thing it is.',
      placeholders: ['family']),
  _s('a11y.canvas_focus', 'Le dessin. Appuie sur Ctrl et D pour l\'écouter.',
      'The drawing. Press Ctrl and D to hear it.',
      context:
          'Screen-reader label for the canvas itself. Names the key that describes '
          'what is drawn, because a canvas is otherwise silent.'),
  _s('a11y.narration_on', 'La voix lit les consignes.',
      'The voice reads the instructions.',
      context:
          'Setting description for narration. Present tense, describing what happens '
          'when it is on.'),
  _s('a11y.text_size', 'Taille du texte : {percent} %.',
      'Text size: {percent} %.',
      context: 'Setting label with the current value, 100 to 200.',
      placeholders: ['percent']),
  _s('a11y.reduced_motion', 'Les animations sont plus calmes.',
      'Animations are calmer.',
      context:
          'Setting description for reduced motion. Avoid "disabled": something still '
          'happens, it just moves less.'),
  _s('a11y.dyslexia_font', 'Une police plus facile à lire.',
      'A font that is easier to read.',
      context:
          'Setting description for the dyslexia-friendly font. Does not name '
          'dyslexia to the child; the parent space does.'),

  // --- sharing ---------------------------------------------------------------------------
  _s('share.off', 'Le partage est éteint. Un adulte peut l\'allumer.',
      'Sharing is off. A grown-up can turn it on.',
      context:
          'Shown to a child who presses share without guardian consent. Names who '
          'can change it, so the child asks the right person.'),
  _s(
      'share.waiting',
      'Un adulte va lire ton titre avant que la classe le voie.',
      'A grown-up will read your title before the class sees it.',
      context:
          'Shown after a child shares, while the text is in the review queue. Says '
          'what is being checked and why the wait exists.'),
  _s('share.name_rolled', 'Ton nom de partage est {name}.',
      'Your sharing name is {name}.',
      context:
          'Shown after a display name is generated or re-rolled. The child cannot '
          'type one, so the sentence states rather than asks.',
      placeholders: ['name']),

  // --- the classroom -----------------------------------------------------------------------
  _s('class.join_prompt', 'Écris ton prénom et le code de la classe.',
      'Write your first name and the class code.',
      context:
          'The whole of the join form. Asks for exactly the two things, because '
          'there is nothing else to ask for.'),
  _s('class.seeding', 'On installe les mondes. Garde la tablette allumée.',
      'Installing the worlds. Keep the tablet switched on.',
      context:
          'Shown on a pupil device during offline seeding from the teacher device. '
          'Says the one thing the child must do.'),
  _s('class.seed_done', 'Tout est installé. Tu peux commencer.',
      'Everything is installed. You can start.',
      context: 'Shown on a pupil device when seeding finishes.'),
]);
