/// Exporting a program as text and as a code image (`FR-M3-08`, `KT §2.5.1`).
///
/// Two exports, and they are not the same thing for the same reason a drawing has both a
/// PNG and an SVG. The text is the program: it goes back into KODO, into a message, into
/// a file a teacher collects. The image is the program *as the child sees it*, colours and
/// all — the thing that goes on a wall, into a school newsletter, next to the drawing it
/// makes. A child who has written their first working program has made something, and
/// "copy the text out" is not a way to show it to anybody.
///
/// The image is SVG rather than PNG, for the same reasons the drawing export is: it
/// prints at any size, it is one deterministic string so "the same program exports the
/// same file" is a test rather than an opinion, and it needs no rasteriser and no fonts
/// shipped in the package — which is what keeps this on the right side of `NFR-OFF-01`.
///
/// The colours come from the editor's own theme and the categories from the editor's own
/// lexer pass. An exporter that highlighted the code itself would drift from the editor,
/// and a child would print a program that is not the one on their screen.
library;

import 'package:kodo_lang/kodo_lang.dart';

import 'syntax_theme.dart';

/// One run of characters and what the lexer called it.
typedef HighlightSpan = ({String text, SyntaxCategory category});

/// Splits a line into categorised runs (`FR-M3-01`).
///
/// From the **lexer**, never from a regular expression, so a word is coloured as what the
/// parser will actually call it. Both the editor and the export read this one function: a
/// highlighter with its own idea of the language eventually disagrees with the error
/// panel, and then a child is looking at a word that is blue and underlined in red.
List<HighlightSpan> highlightSpans(String line, KeywordTable keywords) {
  final spans = <HighlightSpan>[];
  final tokens = tokenize(line).tokens;
  var cursor = 0;

  void emit(String text, SyntaxCategory category) {
    if (text.isEmpty) return;
    spans.add((text: text, category: category));
  }

  for (final token in tokens) {
    if (token.type == TokenType.eof) break;
    if (token.span.start > cursor) {
      emit(line.substring(cursor, token.span.start), SyntaxCategory.command);
    }
    emit(line.substring(token.span.start, token.span.end),
        categoryOfToken(token, keywords));
    cursor = token.span.end;
  }
  if (cursor < line.length) {
    emit(line.substring(cursor), SyntaxCategory.command);
  }
  return spans;
}

/// What the highlighter and the export both call this token.
SyntaxCategory categoryOfToken(Token token, KeywordTable keywords) {
  switch (token.type) {
    case TokenType.comment:
      return SyntaxCategory.comment;
    case TokenType.string:
      return SyntaxCategory.string;
    case TokenType.number:
      return SyntaxCategory.number;
    case TokenType.variable:
      return SyntaxCategory.variable;
    case TokenType.lbrace:
    case TokenType.rbrace:
      return SyntaxCategory.brace;
    case TokenType.operator:
      return const {'==', '!=', '<', '>', '<=', '>='}.contains(token.text)
          ? SyntaxCategory.comparisonOperator
          : SyntaxCategory.mathOperator;
    case TokenType.assign:
      return SyntaxCategory.mathOperator;
    case TokenType.word:
      final lookup = keywords.resolve(token.text);
      if (lookup == null) return SyntaxCategory.command;
      final syntax = lookup.syntax;
      if (syntax == null) return SyntaxCategory.command;
      return switch (syntax) {
        SyntaxWord.true_ || SyntaxWord.false_ => SyntaxCategory.boolean,
        SyntaxWord.and ||
        SyntaxWord.or ||
        SyntaxWord.not =>
          SyntaxCategory.booleanOperator,
        SyntaxWord.learn => SyntaxCategory.learn,
        _ => SyntaxCategory.controlFlow,
      };
    default:
      return SyntaxCategory.command;
  }
}

/// A program, ready to be handed to whatever the platform does with a file.
class CodeExport {
  const CodeExport({required this.text, required this.svg, required this.name});

  /// The program itself, in the child's keyword language.
  final String text;

  /// The same program as a picture, colours and line numbers included.
  final String svg;

  /// A filename stem, without an extension.
  final String name;

  String get textFileName => '$name.kodo';
  String get imageFileName => '$name.svg';
}

/// `FR-M3-08`. Renders [program] both ways.
///
/// [keywords] decides the language the export is written in, which is the child's own
/// rather than a canonical one: a program exported in English from a French child's
/// screen is not the program they wrote.
CodeExport exportProgram(
  Program program,
  KeywordTable keywords,
  SyntaxTheme theme, {
  String name = 'programme',
  String? title,
}) {
  final text = render(program, keywords);
  return CodeExport(
    name: name,
    text: text,
    svg: codeToSvg(text, keywords, theme, title: title ?? name),
  );
}

String _hex(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// A picture of [source], highlighted exactly as the editor highlights it.
///
/// Monospace and laid out by character count rather than by measuring glyphs, because
/// measuring needs a font engine and this has to work with no display attached — the same
/// constraint that decided SVG over PNG. In a monospace face the two answers agree.
String codeToSvg(
  String source,
  KeywordTable keywords,
  SyntaxTheme theme, {
  String title = 'KODO',
  double fontSize = 16,
  bool lineNumbers = true,
}) {
  const charWidth = 0.6; // of the font size, which is the monospace ratio.
  const padding = 16.0;
  final lineHeight = fontSize * 1.45;
  final lines = source.split('\n');
  /* A trailing newline is how `render` ends a program, and an empty last line would put a
     band of blank paper under every exported picture. */
  if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
  if (lines.isEmpty) lines.add('');

  final gutter = lineNumbers
      ? (lines.length.toString().length + 1) * fontSize * charWidth
      : 0.0;
  final widest = lines.fold<int>(0, (m, l) => l.length > m ? l.length : m);
  final width = padding * 2 + gutter + widest * fontSize * charWidth;
  final height = padding * 2 + lines.length * lineHeight;

  String n(double v) {
    final rounded = (v * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }

  final out = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<svg xmlns="http://www.w3.org/2000/svg" '
        'width="${n(width)}" height="${n(height)}" '
        'viewBox="0 0 ${n(width)} ${n(height)}">')
    /* A title, because a screen reader announces it and `FR-M16-04` does not stop at the
       edge of the application. An exported program nobody can have read to them is an
       accessibility regression that leaves the product in a file. */
    ..writeln('  <title>${_escape(title)}</title>')
    ..writeln('  <desc>${_escape(source.trim())}</desc>')
    ..writeln('  <rect width="${n(width)}" height="${n(height)}" '
        'fill="${_hex(theme.background.toARGB32())}"/>');

  final gutterStyle = theme.styleFor(SyntaxCategory.comment);
  for (var i = 0; i < lines.length; i++) {
    final y = padding + (i + 1) * lineHeight - fontSize * 0.25;
    if (lineNumbers) {
      out.writeln('  <text x="${n(padding)}" y="${n(y)}" '
          'font-family="monospace" font-size="${n(fontSize)}" '
          'fill="${_hex(gutterStyle.colour.toARGB32())}">${i + 1}</text>');
    }
    final spans = highlightSpans(lines[i], keywords);
    if (spans.isEmpty) continue;
    out.write('  <text x="${n(padding + gutter)}" y="${n(y)}" '
        'font-family="monospace" font-size="${n(fontSize)}" '
        'xml:space="preserve">');
    for (final span in spans) {
      final style = theme.styleFor(span.category);
      out.write('<tspan fill="${_hex(style.colour.toARGB32())}"'
          '${style.bold ? ' font-weight="bold"' : ''}'
          '${style.italic ? ' font-style="italic"' : ''}'
          '>${_escape(span.text)}</tspan>');
    }
    out.writeln('</text>');
  }

  out.writeln('</svg>');
  return out.toString();
}
