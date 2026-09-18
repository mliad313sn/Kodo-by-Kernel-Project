/// Reading level (FR-M5-03, and the M5 prompt's "readability check in CI").
///
/// The target is CE2/CM1 — roughly eight to nine years old — and the concrete rule the
/// specification gives is **≤ 12 words per line**. That is checkable, so it is checked,
/// and a narration line that breaks it fails the build rather than reaching a child who
/// cannot read it.
///
/// Everything beyond the word count is a proxy and is labelled as one. A real readability
/// score for French needs a validated instrument and a corpus; what is here catches the
/// three things that actually go wrong when an adult writes for a nine-year-old — long
/// sentences, long words, and subordinate clauses.
library;

/// The result of reading one line the way a child would.
class Readability {
  const Readability({
    required this.words,
    required this.longWords,
    required this.clauses,
    required this.line,
  });

  final int words;

  /// Words of four syllables or more. In French these are almost always the abstract
  /// nouns an adult reaches for: *conditionnelle*, *initialisation*, *représentation*.
  final int longWords;

  /// Commas and subordinating conjunctions. A nine-year-old reading slowly loses the
  /// thread of a sentence that turns twice.
  final int clauses;

  final String line;

  /// §4.2 and `FR-M5-03`: no instruction line longer than twelve words.
  static const maxWords = 12;
  static const maxLongWords = 1;
  static const maxClauses = 1;

  bool get passes =>
      words <= maxWords && longWords <= maxLongWords && clauses <= maxClauses;

  List<String> get problems => [
        if (words > maxWords) 'too long: $words words, limit $maxWords',
        if (longWords > maxLongWords) 'too many long words: $longWords',
        if (clauses > maxClauses) 'too many clauses: $clauses',
      ];
}

const _subordinators = {
  // French
  'parce', 'lorsque', 'puisque', 'quoique', 'afin', 'bien', 'tandis', 'pendant',
  // English
  'because', 'although', 'whereas', 'while', 'unless', 'whenever',
};

/// A vowel-group count. Crude, and adequate for spotting a four-syllable word.
int syllablesOf(String word) {
  const vowels = 'aeiouyàâäéèêëîïôöùûü';
  var count = 0;
  var inVowelGroup = false;
  for (final rune in word.toLowerCase().runes) {
    final isVowel = vowels.contains(String.fromCharCode(rune));
    if (isVowel && !inVowelGroup) count++;
    inVowelGroup = isVowel;
  }
  return count == 0 ? 1 : count;
}

Readability readabilityOf(String line) {
  final words = line
      .split(RegExp(r"[^\w'’àâäéèêëîïôöùûüçÀÂÄÉÈÊËÎÏÔÖÙÛÜÇ-]+"))
      .where((w) => w.trim().isNotEmpty)
      .toList();
  final longWords = words.where((w) => syllablesOf(w) >= 4).length;
  final commas = ','.allMatches(line).length;
  final subordinators =
      words.where((w) => _subordinators.contains(w.toLowerCase())).length;
  return Readability(
    words: words.length,
    longWords: longWords,
    clauses: commas + subordinators,
    line: line,
  );
}

/// Words that must never appear in child-facing text without an explanation beside them.
///
/// `FR-M11-04` forbids them unexplained in the parent summary; the same list is worth
/// applying to narration, because a tutorial that says *"variable"* before World 6 has
/// taught a word rather than an idea. Annex D gives the child-language replacements.
const jargonNeedingExplanation = {
  'variable',
  'boucle',
  'conditionnelle',
  'itération',
  'paramètre',
  'récursion',
  'loop',
  'conditional',
  'iteration',
  'parameter',
  'recursion',
  'algorithm',
  'algorithme',
  'syntaxe',
  'syntax',
  'compilateur',
  'compiler',
};

/// Jargon found in [line], lowercased.
Set<String> jargonIn(String line) {
  final words = line
      .toLowerCase()
      .split(RegExp(r"[^\w'’àâäéèêëîïôöùûüç-]+"))
      .where((w) => w.isNotEmpty);
  return words.where(jargonNeedingExplanation.contains).toSet();
}
