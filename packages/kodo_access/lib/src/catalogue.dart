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
      context: 'The main button under the editor. A child presses it to run their '
          'program. Not "execute".'),
  _s('button.stop', 'Arrêter', 'Stop',
      context: 'Stops a running program. Appears in place of the run button while a '
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
      context: 'Switches the editor from blocks to text. The child is not converting '
          'anything; they are looking at the same program differently. A button, so it '
          'must stay short enough not to wrap.'),
  _s('button.block_view', 'Blocs', 'Blocks',
      context: 'Switches back from text to blocks. A button, so it must stay short '
          'enough not to wrap.'),
  _s('menu.recettes', 'Recettes', 'Recipes',
      context: 'The Studio panel of copy-a-pattern examples. Keep the cooking metaphor: a '
          'recipe is something you follow and then change.'),
  _s('tab.mouvement', 'Bouger', 'Move',
      context: 'A block family tab. Verbs, not nouns: these are things the turtle does.'),
  _s('tab.controle', 'Répéter', 'Repeat',
      context: 'The control-flow block family tab.'),
  _s('label.class_code', 'Code de la classe', 'Class code',
      context: 'Above the six-character code a teacher reads aloud to the class.'),

  // --- the editor -----------------------------------------------------------------------
  _s('editor.empty_script',
      'Glisse un bloc ici, ou appuie sur un bloc à gauche.',
      'Drag a block here, or tap a block on the left.',
      context: 'Shown in the empty script area before a child has placed anything. Must '
          'name both ways of placing a block, because tapping is the primary one on a '
          'phone.'),
  _s('editor.running', 'Ça tourne…', 'Running…',
      context: 'Status line while a program runs.'),
  _s('editor.finished', 'C\'est fini.', 'All done.',
      context: 'Status line when a program ends normally. Neutral, not congratulatory — '
          'the program ran, that is all.'),
  _s('editor.stopped', 'Tu as arrêté le programme.', 'You stopped the program.',
      context: 'Status line after the child pressed stop. Says who did it, so the child '
          'does not think it crashed.'),
  _s('editor.too_long',
      'Ton programme tourne depuis longtemps. Je l\'ai arrêté.',
      'Your program has been running a long time. I stopped it.',
      context: 'Shown when the run limit is reached — usually an infinite loop. Says what '
          'happened and who did it, and does not call the child wrong.'),

  // --- the language switch ---------------------------------------------------------------
  _s('label.interface_language', 'Langue de l\'écran', 'Screen language',
      context: 'Setting label. The language of the interface, which is separate from the '
          'language of the keywords — see the next string.'),
  _s('label.keyword_language', 'Langue des mots de code', 'Code word language',
      context: 'Setting label. The language the blocks and text use — avance or forward. '
          'A child may read French screens and write English keywords.'),
  _s('language.switch_kept',
      'Ton programme n\'a pas changé. Seuls les mots ont changé.',
      'Your program has not changed. Only the words have changed.',
      context: 'Shown after a keyword-language switch. The reassurance is the point: the '
          'child just watched every word on screen change.'),

  // --- narration and accessibility ---------------------------------------------------------
  _s('a11y.block_label',
      '{keyword}, famille {family}, bloc {position} sur {total}.',
      '{keyword}, {family} family, block {position} of {total}.',
      context: 'Screen-reader label for one block in the script. Read in order, so the '
          'position comes last. Keep it one sentence.',
      placeholders: ['keyword', 'family', 'position', 'total']),
  _s('a11y.family_tab', 'Famille {family}.', '{family} family.',
      context: 'Screen-reader label for a block-family tab in the palette. The visible '
          'label is just the family name; this says what kind of thing it is.',
      placeholders: ['family']),
  _s('a11y.canvas_focus', 'Le dessin. Appuie sur Ctrl et D pour l\'écouter.',
      'The drawing. Press Ctrl and D to hear it.',
      context: 'Screen-reader label for the canvas itself. Names the key that describes '
          'what is drawn, because a canvas is otherwise silent.'),
  _s('a11y.narration_on', 'La voix lit les consignes.',
      'The voice reads the instructions.',
      context: 'Setting description for narration. Present tense, describing what happens '
          'when it is on.'),
  _s('a11y.text_size', 'Taille du texte : {percent} %.', 'Text size: {percent} %.',
      context: 'Setting label with the current value, 100 to 200.',
      placeholders: ['percent']),
  _s('a11y.reduced_motion', 'Les animations sont plus calmes.',
      'Animations are calmer.',
      context: 'Setting description for reduced motion. Avoid "disabled": something still '
          'happens, it just moves less.'),
  _s('a11y.dyslexia_font', 'Une police plus facile à lire.',
      'A font that is easier to read.',
      context: 'Setting description for the dyslexia-friendly font. Does not name '
          'dyslexia to the child; the parent space does.'),

  // --- sharing ---------------------------------------------------------------------------
  _s('share.off',
      'Le partage est éteint. Un adulte peut l\'allumer.',
      'Sharing is off. A grown-up can turn it on.',
      context: 'Shown to a child who presses share without guardian consent. Names who '
          'can change it, so the child asks the right person.'),
  _s('share.waiting',
      'Un adulte va lire ton titre avant que la classe le voie.',
      'A grown-up will read your title before the class sees it.',
      context: 'Shown after a child shares, while the text is in the review queue. Says '
          'what is being checked and why the wait exists.'),
  _s('share.name_rolled', 'Ton nom de partage est {name}.',
      'Your sharing name is {name}.',
      context: 'Shown after a display name is generated or re-rolled. The child cannot '
          'type one, so the sentence states rather than asks.',
      placeholders: ['name']),

  // --- the classroom -----------------------------------------------------------------------
  _s('class.join_prompt', 'Écris ton prénom et le code de la classe.',
      'Write your first name and the class code.',
      context: 'The whole of the join form. Asks for exactly the two things, because '
          'there is nothing else to ask for.'),
  _s('class.seeding', 'On installe les mondes. Garde la tablette allumée.',
      'Installing the worlds. Keep the tablet switched on.',
      context: 'Shown on a pupil device during offline seeding from the teacher device. '
          'Says the one thing the child must do.'),
  _s('class.seed_done', 'Tout est installé. Tu peux commencer.',
      'Everything is installed. You can start.',
      context: 'Shown on a pupil device when seeding finishes.'),
]);
