/// Locale-correct numbers and keyword pronunciation (M15).
///
/// `FR-M15-05`: *"Number format, decimal separator display, and voice-over pronunciation
/// are locale-specific; the language's own decimal convention is shown even though the
/// parser accepts `.`"*
///
/// The split matters and is easy to get wrong in the other direction. The **parser** takes
/// `1.5` in every language, because a program must mean the same thing everywhere and a
/// program that parses differently in French is a different language, not a translation.
/// The **display** shows `1,5` to a French child, because that is what their maths lesson
/// says. One value, two faces — exactly like the keyword tables.
library;

import 'strings.dart';

/// How a locale writes numbers.
class NumberConvention {
  const NumberConvention({
    required this.decimalSeparator,
    required this.groupSeparator,
    required this.groupSize,
  });

  final String decimalSeparator;

  /// French uses a narrow no-break space, not a comma: `1 000` — and a comma would read as
  /// a decimal point to the child who has just been taught the convention above.
  final String groupSeparator;

  final int groupSize;

  static const forLocale = {
    'fr': NumberConvention(
        decimalSeparator: ',', groupSeparator: ' ', groupSize: 3),
    'en': NumberConvention(
        decimalSeparator: '.', groupSeparator: ',', groupSize: 3),
    // Wolof is written with French conventions in Senegal (`D-002` ships the interface at
    // v1.2; the convention is known now and costs nothing to record).
    'wo': NumberConvention(
        decimalSeparator: ',', groupSeparator: ' ', groupSize: 3),
  };

  static NumberConvention of(UiLocale locale) => forLocale[locale.code]!;
}

/// Formats a number the way [locale] writes it.
///
/// Grouping starts at five digits, not four: `1000` is written without a space in French
/// typography and `10 000` with one, and a nine-year-old reading `1 000` as two numbers is
/// a real hesitation.
String formatNumber(num value, UiLocale locale, {int? decimals}) {
  final convention = NumberConvention.of(locale);
  final negative = value < 0;
  final magnitude = value.abs();

  final fixed = decimals != null
      ? magnitude.toStringAsFixed(decimals)
      : (magnitude == magnitude.roundToDouble()
          ? magnitude.round().toString()
          : magnitude.toString());

  final parts = fixed.split('.');
  var whole = parts[0];
  if (whole.length > 4) {
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % convention.groupSize == 0) {
        buffer.write(convention.groupSeparator);
      }
      buffer.write(whole[i]);
    }
    whole = buffer.toString();
  }

  final out = parts.length > 1
      ? '$whole${convention.decimalSeparator}${parts[1]}'
      : whole;
  return negative ? '-$out' : out;
}

/// Parses what a child typed into a *display* field, accepting their own convention.
///
/// Not the program parser — that stays `.` everywhere by design. This is for the places a
/// number is data rather than code: a pen width slider's text field, a project's list.
num? parseLocalNumber(String text, UiLocale locale) {
  final convention = NumberConvention.of(locale);
  final cleaned = text
      .replaceAll(convention.groupSeparator, '')
      .replaceAll(' ', '')
      .replaceAll(convention.decimalSeparator, '.');
  return num.tryParse(cleaned);
}

// ---------------------------------------------------------------------------------------
// Pronunciation
// ---------------------------------------------------------------------------------------

/// How the voice-over says a keyword.
///
/// The keywords are written as one word — `tournedroite`, `lèvecrayon` — because a child
/// types them and a space would be a syntax error. Read aloud that way they are noise, and
/// `FR-M16-02` narrates *every* instruction. So each keyword carries a spoken form, and the
/// spoken form is separated because it is the thing a voice actor records.
class Pronunciation {
  const Pronunciation(this.spoken, {this.note});

  /// What the narrator says, with the word breaks a listener needs.
  final String spoken;

  /// A direction for the voice actor, where the written form is misleading.
  final String? note;
}

/// Spoken forms for the keywords whose written form is not what a narrator should say.
///
/// Keywords not listed are read as written — `avance`, `montre`, `mod` — and a test asserts
/// that every multi-word keyword is listed, so a new compound keyword cannot ship mute.
const Map<String, Map<String, Pronunciation>> keywordPronunciation = {
  'fr': {
    'tournegauche': Pronunciation('tourne gauche'),
    'tournedroite': Pronunciation('tourne droite'),
    'obtenirdirection': Pronunciation('obtenir direction'),
    'lèvecrayon': Pronunciation('lève crayon'),
    'baissecrayon': Pronunciation('baisse crayon'),
    'largeurcrayon': Pronunciation('largeur crayon'),
    'couleurcrayon': Pronunciation('couleur crayon'),
    'taillecanevas': Pronunciation('taille canevas'),
    'couleurcanevas': Pronunciation('couleur canevas'),
    'nettoietout': Pronunciation('nettoie tout'),
    'taillepolice': Pronunciation('taille police'),
    'positionx': Pronunciation('position x', note: 'the letter, "iks"'),
    'positiony': Pronunciation('position y', note: 'the letter, "i grec"'),
    'vax': Pronunciation('va x', note: 'the letter, "iks"'),
    'vay': Pronunciation('va y', note: 'the letter, "i grec"'),
    'tantque': Pronunciation('tant que'),
  },
  'en': {
    'turnleft': Pronunciation('turn left'),
    'turnright': Pronunciation('turn right'),
    'getdirection': Pronunciation('get direction'),
    'penup': Pronunciation('pen up'),
    'pendown': Pronunciation('pen down'),
    'penwidth': Pronunciation('pen width'),
    'pencolor': Pronunciation('pen colour', note: 'spelled US, said UK'),
    'canvassize': Pronunciation('canvas size'),
    'canvascolor': Pronunciation('canvas colour', note: 'spelled US, said UK'),
    'fontsize': Pronunciation('font size'),
    'positionx': Pronunciation('position x'),
    'positiony': Pronunciation('position y'),
    'gox': Pronunciation('go x'),
    'goy': Pronunciation('go y'),
  },
};

/// What the narrator says for [keyword] in [locale].
String pronounce(String keyword, UiLocale locale) =>
    keywordPronunciation[locale.code]?[keyword.toLowerCase()]?.spoken ?? keyword;
