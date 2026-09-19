/// Keyword autocomplete, with the English equivalent from World 9 (`FR-M3-06`).
///
/// A child typing at a keyboard has two problems the block palette never gave them: they
/// have to remember the word, and they have to spell it. Autocomplete answers both, and
/// KODO's version answers a third — *what is this called in the other language* — because
/// World 11's fourth concept is that English keywords are the same language in different
/// words, and a child who sees `répète · repeat` every time they type has met that idea
/// long before the lesson names it.
///
/// The equivalent appears **from World 9**, which is §4.3's ruling and not this file's.
/// Before then a child has enough to hold; after it, they are about to meet English code
/// and the editor can start introducing it quietly.
///
/// This is deliberately a pure function over strings. The suggestion list is the part
/// worth testing — which words, in what order, with which equivalent — and a widget test
/// is a poor place to ask those questions.
library;

import 'package:kodo_lang/kodo_lang.dart';

/// One offer: the word to insert, and what it is called in the other language.
class KeywordSuggestion {
  const KeywordSuggestion({
    required this.word,
    required this.equivalent,
    this.opcode,
    this.syntax,
  });

  /// The word in the child's own keyword language — what gets inserted.
  final String word;

  /// The same block's word in the other language. Shown from World 9 (`FR-M3-06`).
  final String equivalent;

  final Opcode? opcode;
  final SyntaxWord? syntax;

  @override
  String toString() => '$word · $equivalent';
}

/// The partial word the cursor is sitting at the end of, or empty.
///
/// A word is letters and the accented letters French keywords use. Anything else — a
/// space, a brace, a digit, a `$` — ends it, because none of those can start a keyword.
String partialWordAt(String text, int cursor) {
  final end = cursor.clamp(0, text.length);
  var start = end;
  while (start > 0 && _isWordCharacter(text[start - 1])) {
    start--;
  }
  return text.substring(start, end);
}

bool _isWordCharacter(String c) =>
    RegExp(r"[A-Za-zÀ-ÿ_']").hasMatch(c);

/// What to offer for the word being typed.
///
/// [scope] is the world's palette: a child in World 2 is not offered `note`, for the
/// same reason the block palette does not show it (`FR-M2-08`). An empty scope means no
/// restriction, which is what the Studio wants. Grammar words are never scoped — see
/// below.
List<KeywordSuggestion> suggestKeywords(
  String partial, {
  required KeywordTable keywords,
  required KeywordTable other,
  List<Opcode> scope = const [],
  int limit = 6,
}) {
  if (partial.isEmpty) return const [];
  final needle = partial.toLowerCase();
  final offers = <KeywordSuggestion>[];

  for (final opcode in Opcode.values) {
    if (scope.isNotEmpty && !scope.contains(opcode)) continue;
    final mine = keywords.write(opcode);
    if (!mine.toLowerCase().startsWith(needle)) continue;
    offers.add(KeywordSuggestion(
      word: mine,
      equivalent: other.write(opcode),
      opcode: opcode,
    ));
  }

  /* Grammar as well as blocks. `répète` is the word a child reaches for most and it is
     not an opcode, so a suggestion list built from the opcode table alone would leave out
     exactly the word autocomplete exists for. Syntax words are never scoped: a world that
     teaches `si` has it in the palette as grammar, not as a block. */
  for (final word in SyntaxWord.values) {
    final mine = keywords.writeSyntax(word);
    if (!mine.toLowerCase().startsWith(needle)) continue;
    offers.add(KeywordSuggestion(
      word: mine,
      equivalent: other.writeSyntax(word),
      syntax: word,
    ));
  }

  /* Shortest first. A child who has typed `av` wants `avance`, not `avancerapidement`,
     and the word they are most likely to mean is the one closest to what they typed.
     Alphabetical within a length so the list does not reshuffle as they type. */
  offers.sort((a, b) {
    final byLength = a.word.length.compareTo(b.word.length);
    return byLength != 0 ? byLength : a.word.compareTo(b.word);
  });
  return offers.take(limit).toList();
}

/// Whether the other language's word is shown beside each offer.
///
/// §4.3: from World 9. Before that a child has enough to carry; from there they are two
/// worlds away from meeting English code, and the editor can start saying it quietly.
bool showsEquivalentIn(int world) => world >= 9;

/// The text after accepting [suggestion], and where the cursor lands.
///
/// Replaces the partial word rather than appending to it — the commonest autocomplete
/// bug, and the one that turns `av` plus `avance` into `avavance`.
(String, int) acceptSuggestion(
    String text, int cursor, KeywordSuggestion suggestion) {
  final partial = partialWordAt(text, cursor);
  final start = cursor.clamp(0, text.length) - partial.length;
  final updated =
      text.replaceRange(start, cursor.clamp(0, text.length), suggestion.word);
  return (updated, start + suggestion.word.length);
}
