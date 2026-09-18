/// The interface string catalogue (M15).
///
/// `FR-M15-01` names three layers that are localised **independently**: interface,
/// keywords, content. This file is the first of them. The keyword layer is M1's
/// `KeywordTable`; the content layer is the item and tutorial text in the packs. Keeping
/// them apart is what lets a child read the interface in French while writing English
/// keywords, which §6 asks for and which one merged string table would make impossible.
///
/// `FR-M15-04` is the rule this file exists to enforce: *"content authoring forbids
/// concatenated sentence fragments; every string is a full sentence with context notes for
/// translators."* A fragment cannot be translated (word order differs), cannot be narrated
/// (`FR-M16-02`), and cannot be read aloud by a screen reader in an order that makes sense.
library;

/// The locales the interface ships in.
///
/// French is the reference and English is at full parity at v1 (`FR-M15-02`). Wolof is a
/// **committed v1.2 target for interface and narration**, with the keyword set explicitly
/// research and not a commitment — PO decision `D-002`.
enum UiLocale {
  fr('fr', 'Français', shipsInV1: true),
  en('en', 'English', shipsInV1: true),
  wo('wo', 'Wolof', shipsInV1: false);

  const UiLocale(this.code, this.endonym, {required this.shipsInV1});

  final String code;

  /// Shown in the language picker, so it is in its own language.
  final String endonym;

  final bool shipsInV1;

  static List<UiLocale> get v1 => [
        for (final l in UiLocale.values)
          if (l.shipsInV1) l
      ];

  static UiLocale byCode(String code) =>
      UiLocale.values.firstWhere((l) => l.code == code,
          orElse: () => throw ArgumentError('no locale "$code"'));
}

/// One interface string.
class UiString {
  const UiString({
    required this.key,
    required this.texts,
    required this.context,
    this.placeholders = const [],
  });

  /// A dotted key, e.g. `editor.run_button`. Never the English text as the key: an English
  /// key makes English the source of truth and quietly demotes the reference language.
  final String key;

  /// locale code → the whole sentence.
  final Map<String, String> texts;

  /// What a translator needs to know and cannot see: who says this, to whom, and where it
  /// appears. `FR-M15-04` requires it, and a string without one is refused below.
  final String context;

  /// Named placeholders, e.g. `count`. A placeholder is a *value* in a sentence, which is
  /// translatable; a fragment is a *piece of a sentence*, which is not.
  final List<String> placeholders;

  String textIn(UiLocale locale) => texts[locale.code] ?? texts['fr'] ?? '';

  /// Fills the placeholders. Missing values are an error, not an empty space.
  String render(UiLocale locale, [Map<String, String> args = const {}]) {
    var out = textIn(locale);
    for (final name in placeholders) {
      final value = args[name];
      if (value == null) {
        throw ArgumentError('$key needs a value for "$name"');
      }
      out = out.replaceAll('{$name}', value);
    }
    return out;
  }
}

/// Why a string may not ship.
class StringFault {
  const StringFault(this.key, this.rule, this.detail);
  final String key;
  final String rule;
  final String detail;

  @override
  String toString() => '$key: [$rule] $detail';
}

/// Sentence-final punctuation in the languages KODO ships. A string ending in anything
/// else is very likely a fragment somebody intends to glue to another one.
const _terminators = ['.', '!', '?', '…', ':', '»'];

/// Words that, at the end of a string, mean the sentence continues somewhere else.
const _danglingFr = [
  'et',
  'ou',
  'de',
  'à',
  'le',
  'la',
  'les',
  'du',
  'des',
  'en',
  'pour'
];
const _danglingEn = [
  'and',
  'or',
  'of',
  'to',
  'the',
  'a',
  'an',
  'in',
  'for',
  'with'
];

/// Labels short enough to be a button or a menu item, where a full stop would be wrong.
///
/// The fragment rule is about *sentences a child reads*, not about the word on a button.
/// `Run`, `Effacer`, `Aide` are complete utterances; refusing them would push authors into
/// writing "Run." on a button, which is worse.
bool _isLabel(String key) =>
    key.startsWith('button.') ||
    key.startsWith('menu.') ||
    key.startsWith('tab.') ||
    key.startsWith('label.');

/// The M15 lint. An empty list means the catalogue may ship.
List<StringFault> lintCatalogue(Iterable<UiString> strings) {
  final faults = <StringFault>[];
  final seen = <String>{};

  for (final string in strings) {
    void fail(String rule, String detail) =>
        faults.add(StringFault(string.key, rule, detail));

    if (!seen.add(string.key)) fail('duplicate-key', 'appears twice');
    if (string.key != string.key.toLowerCase() || !string.key.contains('.')) {
      fail('key-shape',
          'a key is lowercase and dotted, e.g. "editor.run_button"');
    }
    if (string.context.trim().length < 12) {
      fail('context-note',
          'FR-M15-04 requires a context note a translator can act on');
    }

    // 100 % coverage in the v1 locales, enforced here and in CI.
    for (final locale in UiLocale.v1) {
      final text = (string.texts[locale.code] ?? '').trim();
      if (text.isEmpty) {
        fail('coverage', 'no text in "${locale.code}"');
        continue;
      }
      if (!_isLabel(string.key)) {
        if (!_terminators.any(text.endsWith)) {
          fail('fragment', '"${locale.code}" does not end a sentence: "$text"');
        }
        final lastWord = text
            .replaceAll(RegExp(r'[^\wÀ-ÿ\s]'), '')
            .trim()
            .split(RegExp(r'\s+'))
            .last
            .toLowerCase();
        final dangling = locale == UiLocale.fr ? _danglingFr : _danglingEn;
        if (dangling.contains(lastWord)) {
          fail('fragment', '"${locale.code}" ends on "$lastWord"');
        }
      }
      // A string that is only a placeholder is a fragment wearing a costume.
      if (RegExp(r'^\{\w+\}$').hasMatch(text)) {
        fail('fragment', '"${locale.code}" is only a placeholder');
      }
      for (final name in string.placeholders) {
        if (!text.contains('{$name}')) {
          fail('placeholder-missing',
              '"${locale.code}" never uses {$name}, so the value is lost');
        }
      }
      for (final match in RegExp(r'\{(\w+)\}').allMatches(text)) {
        if (!string.placeholders.contains(match.group(1))) {
          fail('placeholder-undeclared',
              '"${locale.code}" uses {${match.group(1)}}, which is not declared');
        }
      }
    }
  }
  return faults;
}

/// The catalogue.
class StringCatalogue {
  StringCatalogue(Iterable<UiString> strings)
      : _byKey = {for (final s in strings) s.key: s};

  final Map<String, UiString> _byKey;

  List<UiString> get all {
    final keys = _byKey.keys.toList()..sort();
    return [for (final key in keys) _byKey[key]!];
  }

  int get length => _byKey.length;

  UiString? operator [](String key) => _byKey[key];

  /// The string, or a loud failure. Never a silent fallback to the key: a screen showing
  /// `editor.run_button` to a child is a bug that must be impossible to miss.
  String render(String key, UiLocale locale,
      [Map<String, String> args = const {}]) {
    final string = _byKey[key];
    if (string == null) throw ArgumentError('no string "$key"');
    return string.render(locale, args);
  }

  /// Coverage per locale, as a fraction. `FR-M15-02` requires 1.0 in FR and EN.
  double coverageOf(UiLocale locale) {
    if (_byKey.isEmpty) return 1;
    final present = _byKey.values
        .where((s) => (s.texts[locale.code] ?? '').trim().isNotEmpty)
        .length;
    return present / _byKey.length;
  }

  /// Keys missing from [locale]. What a translator is handed.
  List<String> missingIn(UiLocale locale) => [
        for (final string in all)
          if ((string.texts[locale.code] ?? '').trim().isEmpty) string.key,
      ];
}
