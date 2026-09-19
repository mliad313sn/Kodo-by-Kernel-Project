/// The pseudo-locale, and the hard-coded-string scan (M15).
///
/// The acceptance test is *"a pseudo-locale run reveals zero hard-coded strings and zero
/// truncation at 140 % string length"*. Both halves are here: a transform that makes a
/// string obviously translated and reliably longer, and a scan that finds the strings
/// which never went through the catalogue at all — because those are exactly the ones a
/// pseudo-locale run cannot change, which is how it reveals them.
library;

import 'strings.dart';

/// How much longer a translation may plausibly get.
///
/// 140 % is the figure in the module prompt. French is typically 15–25 % longer than
/// English; German and Wolof compounds go further; the number exists so a layout is built
/// with room rather than measured against the shortest language.
const growthFactor = 1.4;

/// Turns a string into its pseudo-locale form.
///
/// Three properties, each doing a job:
/// * **accented substitutions** — a string that looks unchanged did not come from the
///   catalogue;
/// * **padding to [growthFactor]** — the layout is tested at the length it must survive;
/// * **brackets** — truncation is visible, because a missing `]` is a clipped string.
///
/// Placeholders are left alone. Mangling `{count}` would only prove that a broken
/// pseudo-locale breaks the app.
String pseudo(String text) {
  const map = {
    'a': 'á',
    'e': 'é',
    'i': 'í',
    'o': 'ó',
    'u': 'ú',
    'A': 'Á',
    'E': 'É',
    'I': 'Í',
    'O': 'Ó',
    'U': 'Ú',
  };
  final buffer = StringBuffer('[');
  var index = 0;
  while (index < text.length) {
    if (text[index] == '{') {
      final close = text.indexOf('}', index);
      if (close > index) {
        buffer.write(text.substring(index, close + 1));
        index = close + 1;
        continue;
      }
    }
    buffer.write(map[text[index]] ?? text[index]);
    index++;
  }
  // Pad to the growth factor with a run that cannot be mistaken for content.
  final target = (text.length * growthFactor).ceil();
  final padding = target - text.length;
  if (padding > 0) buffer.write(' ${'~' * padding}');
  buffer.write(']');
  return buffer.toString();
}

/// A place a string has to fit.
class LayoutSlot {
  const LayoutSlot({
    required this.name,
    required this.characters,
    required this.lines,
  });

  final String name;

  /// How many characters fit on one line at the child font size.
  final int characters;

  /// How many lines the slot shows before it clips or scrolls.
  final int lines;

  int get capacity => characters * lines;
}

/// A string that will not fit its slot at 140 %.
class Truncation {
  const Truncation(this.key, this.slot, this.needed, this.available);
  final String key;
  final String slot;
  final int needed;
  final int available;

  @override
  String toString() =>
      '$key in "$slot": needs $needed characters, slot holds $available';
}

/// Runs the pseudo-locale over a catalogue and reports what would clip.
///
/// [slots] maps a key prefix to the place strings with that prefix appear. A key with no
/// slot is not checked, and [unslottedKeys] says which those were — an unchecked string is
/// not a passing string, and a report that hides that is worse than no report.
class PseudoLocaleRun {
  PseudoLocaleRun(this.catalogue, this.slots);

  final StringCatalogue catalogue;
  final Map<String, LayoutSlot> slots;

  LayoutSlot? slotFor(String key) {
    String? best;
    for (final prefix in slots.keys) {
      if (key.startsWith(prefix) &&
          (best == null || prefix.length > best.length)) {
        best = prefix;
      }
    }
    return best == null ? null : slots[best];
  }

  List<String> get unslottedKeys => [
        for (final s in catalogue.all)
          if (slotFor(s.key) == null) s.key
      ];

  /// Every string that would clip, in either shipping locale.
  List<Truncation> truncations() {
    final found = <Truncation>[];
    for (final string in catalogue.all) {
      final slot = slotFor(string.key);
      if (slot == null) continue;
      for (final locale in UiLocale.v1) {
        final grown = pseudo(string.textIn(locale));
        if (grown.length > slot.capacity) {
          found.add(
              Truncation(string.key, slot.name, grown.length, slot.capacity));
        }
      }
    }
    return found;
  }
}

// ---------------------------------------------------------------------------------------
// The hard-coded-string scan
// ---------------------------------------------------------------------------------------

/// A string literal in source that a child could end up reading.
class HardCodedString {
  const HardCodedString(this.file, this.line, this.text);
  final String file;
  final int line;
  final String text;

  @override
  String toString() => '$file:$line  "$text"';
}

/// Widget constructors that put text on a screen.
const _textSinks = [
  'Text(',
  'SelectableText(',
  'Tooltip(',
  'semanticsLabel:',
  'label:'
];

/// Finds string literals handed to a text sink.
///
/// Deliberately narrow. A scanner that flags every literal in a Dart file reports hundreds
/// of keys, asset paths and opcode ids, and a report nobody reads is not a control. What
/// matters is the literal that reaches a widget, because that is the one a translator can
/// never touch.
List<HardCodedString> scanForHardCodedStrings(String file, String source) {
  final found = <HardCodedString>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
    if (!_textSinks.any(lines[i].contains)) continue;

    /* The sink and the two lines under it, because a formatter wraps
       `label: 'Poser les blocs ici'` onto its own line as soon as it is nested a few
       levels deep — and a scanner that only reads the line the sink is on stops seeing
       exactly the strings that are furthest inside a widget tree. Three real ones hid
       there until this counted them. */
    final line = [
      lines[i],
      for (var j = i + 1; j < lines.length && j <= i + 2; j++)
        if (!lines[j].trimLeft().startsWith('//')) lines[j],
    ].join(' ');

    for (final match
        in RegExp(r"""(['"])((?:\\.|(?!\1).)*)\1""").allMatches(line)) {
      final text = match.group(2)!;
      if (text.isEmpty) continue;
      // Strip interpolations before deciding. `'#$text'` and `'${line.error.line}'` are
      // strings whose content comes from a variable — the identifier inside the braces is
      // not something a translator can touch, and counting it as prose makes the scanner
      // cry wolf until nobody reads it.
      final literal = text
          .replaceAll(RegExp(r'\$\{[^}]*\}'), '')
          .replaceAll(RegExp(r'\$\w+'), '')
          .replaceAll(RegExp(r'\\[nrt]'), '');
      // A key, an asset path or a format string is not child-facing text either.
      if (RegExp(r'^[\w./:-]*$').hasMatch(literal)) continue;
      if (!RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(literal)) continue;
      found.add(HardCodedString(file, i + 1, text));
    }
  }
  return found;
}
