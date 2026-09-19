/// Parsing a program without first asking which words it was typed with (`FR-M15-03`).
///
/// World 11's fourth concept is *mots-clés en anglais*, and its misconception is that
/// English code is a new language to relearn. KODO's answer is that it is not: the two
/// keyword tables are two spellings of one language, `répète 4` and `repeat 4` parse to
/// the same tree, and M15's editor already swaps between them mid-edit without altering
/// the program.
///
/// The grader did not know that. It parsed every source with the French table, so a
/// perfectly good English program was "does not parse" — which would have made C11.4's
/// items ungradable and, worse, would have made the product contradict the lesson.
///
/// So a program is parsed with the table it says it uses and, failing that, with the
/// other one. That is not a lenient fallback: **a program that parses under either table
/// is a program**, which is precisely the claim the concept teaches. When neither works
/// the error from the item's own language is the one reported, because that is the
/// language the child was writing in.
library;

import 'package:kodo_lang/kodo_lang.dart';

KeywordTable tableFor(String locale) =>
    locale == 'en' ? KeywordTables.en : KeywordTables.fr;

/// The other spelling of the same language.
KeywordTable otherTable(String locale) =>
    locale == 'en' ? KeywordTables.fr : KeywordTables.en;

/// Parses [source] in the item's keyword language, or the other one.
ParseResult parseEither(String source, {String locale = 'fr'}) {
  final mine = parse(source, tableFor(locale));
  if (mine.errors.isEmpty) return mine;
  final theirs = parse(source, otherTable(locale));
  return theirs.errors.isEmpty ? theirs : mine;
}
