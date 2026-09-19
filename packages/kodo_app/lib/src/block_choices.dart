/// Dropdown parameters (`FR-M2-05`).
///
/// Some blocks take a *name* rather than a number: which key, which effect, which sprite,
/// which sound, which backdrop. A child cannot be asked to type `"sourisappuyée"` into a
/// block — and before World 10 there was nothing to type it into, which is why this
/// arrived late. Authoring that world is what made it necessary: `lutin "chat"` with no
/// way to choose *chat* is a block that only an author can use.
///
/// Two kinds of list, and the difference matters:
///
///   * **The language's own** — keys and graphic effects. Fixed, small, the same in every
///     project, and listed here because they are what the interpreter answers to.
///   * **The project's** — sprites, backdrops and sounds. These are content. They are
///     handed in, never guessed, and an empty list is an honest empty dropdown rather
///     than a made-up one.
library;

import 'package:kodo_lang/kodo_lang.dart';

/// What a named argument is choosing between.
enum ChoiceKind {
  /// A key on the keyboard, in the child's words.
  key,

  /// One of the six graphic effects the stage implements.
  effect,

  /// A sprite on the stage.
  sprite,

  /// A backdrop the project carries.
  backdrop,

  /// A sound the project carries.
  sound,
}

/// Which argument of which block is a name, and what kind of name it is.
///
/// Only the first argument of each, because that is where every one of them puts it:
/// `effet "fantôme", 50` chooses a name and then a number, and the number is the number
/// pad's business.
const namedArguments = <Opcode, ChoiceKind>{
  Opcode.keyDown: ChoiceKind.key,
  Opcode.whenKey: ChoiceKind.key,
  Opcode.setEffect: ChoiceKind.effect,
  Opcode.selectSprite: ChoiceKind.sprite,
  Opcode.setBackdrop: ChoiceKind.backdrop,
  Opcode.playSound: ChoiceKind.sound,
};

/// The keys a child can name, in their own words.
///
/// The arrow keys and space first, because those are what a game uses; then the letters,
/// because those are what a child reaches for next. `FR-M15-04`: these are the strings the
/// interpreter compares against, so they are content in the keyword sense — the French
/// spelling is what a French-keyword program writes.
const keyNamesFr = [
  'espace',
  'haut',
  'bas',
  'gauche',
  'droite',
  'entrée',
  'a',
  'b',
  'c',
  'd',
  'e',
  'w',
  'x',
  'y',
  'z',
];

const keyNamesEn = [
  'space',
  'up',
  'down',
  'left',
  'right',
  'enter',
  'a',
  'b',
  'c',
  'd',
  'e',
  'w',
  'x',
  'y',
  'z',
];

/// The six the stage implements, in the order the effects panel shows them.
const effectNamesFr = [
  'couleur',
  'fantôme',
  'luminosité',
  'tourbillon',
  'pixel',
  'oeildepoisson',
];

const effectNamesEn = [
  'color',
  'ghost',
  'brightness',
  'whirl',
  'pixelate',
  'fisheye',
];

/// What the dropdowns in this project offer.
///
/// The language's lists come with it; the project's are handed in. A `BlockChoices` with
/// no sprites shows an empty sprite dropdown, which is the truth about a project with no
/// sprites — and better than a dropdown of names that do not exist.
class BlockChoices {
  const BlockChoices({
    this.sprites = const [],
    this.backdrops = const [],
    this.sounds = const [],
  });

  final List<String> sprites;
  final List<String> backdrops;
  final List<String> sounds;

  /// The options for [kind], in [locale]'s keyword spelling.
  List<String> optionsFor(ChoiceKind kind, String locale) => switch (kind) {
        ChoiceKind.key => locale == 'en' ? keyNamesEn : keyNamesFr,
        ChoiceKind.effect => locale == 'en' ? effectNamesEn : effectNamesFr,
        ChoiceKind.sprite => sprites,
        ChoiceKind.backdrop => backdrops,
        ChoiceKind.sound => sounds,
      };

  static const empty = BlockChoices();
}
