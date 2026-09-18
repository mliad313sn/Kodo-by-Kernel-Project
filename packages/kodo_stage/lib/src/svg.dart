/// SVG export (FR-M4-02).
///
/// Vector, because `KT §5` makes the canvas zoomable and because a child who draws a
/// rosette should be able to print it without it turning to mush. The output is
/// deterministic to the last character: the same program produces the same file, which is
/// what makes "an exported drawing reopens identically" a test rather than an opinion.
library;

import 'package:kodo_lang/kodo_lang.dart';

String _hex(int packed) => '#${packed.toRadixString(16).padLeft(6, '0')}';

/// Trims a double to at most one decimal, without a trailing `.0`.
///
/// Canvas coordinates come from trigonometry, so they carry seventeen digits of noise that
/// bloat the file and break byte-equality across platforms for no visible gain.
String _n(double v) {
  final rounded = (v * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return rounded.toInt().toString();
  return rounded.toString();
}

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// Renders [canvas] as a standalone SVG document.
///
/// [title] and [description] become `<title>` and `<desc>`, which is not decoration: a
/// screen reader announces them, and `FR-M16-04` requires every canvas state to be
/// narratable. An exported drawing that cannot be described is an accessibility regression
/// that leaves the product in a file.
String toSvg(
  HeadlessCanvas canvas, {
  String title = 'KODO',
  String? description,
}) {
  final out = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<svg xmlns="http://www.w3.org/2000/svg" '
        'width="${_n(canvas.width)}" height="${_n(canvas.height)}" '
        'viewBox="0 0 ${_n(canvas.width)} ${_n(canvas.height)}">')
    ..writeln('  <title>${_escape(title)}</title>');
  if (description != null) {
    out.writeln('  <desc>${_escape(description)}</desc>');
  }
  out.writeln('  <rect width="100%" height="100%" '
      'fill="${_hex(canvas.canvasBackground)}"/>');

  for (final s in canvas.segments) {
    out.writeln('  <line x1="${_n(s.x1)}" y1="${_n(s.y1)}" '
        'x2="${_n(s.x2)}" y2="${_n(s.y2)}" '
        'stroke="${_hex(s.color)}" stroke-width="${_n(s.width)}" '
        'stroke-linecap="round"/>');
  }
  for (final t in canvas.texts) {
    out.writeln('  <text x="${_n(t.x)}" y="${_n(t.y)}" '
        'font-family="sans-serif" font-size="${_n(t.size)}" '
        'fill="${_hex(t.color)}">${_escape(t.text)}</text>');
  }

  out.writeln('</svg>');
  return out.toString();
}

/// A one-line description of what is on the canvas, in the child's language.
///
/// Used by the screen-reader label for the canvas (`FR-M16-04`) and by the SVG `<desc>`.
/// It says how many lines and how many colours, because that is what a child asked "what
/// is on your canvas?" actually says back.
String describeCanvas(HeadlessCanvas canvas, {String locale = 'fr'}) {
  final lines = canvas.segmentCount;
  final colours = canvas.segments.map((s) => s.color).toSet().length;
  final labels = canvas.texts.length;

  if (locale == 'en') {
    if (lines == 0 && labels == 0) return 'The canvas is empty.';
    final parts = <String>[
      if (lines > 0) '$lines line${lines == 1 ? '' : 's'}',
      if (colours > 1) 'in $colours colours',
      if (labels > 0) 'and $labels label${labels == 1 ? '' : 's'}',
    ];
    return 'Your drawing has ${parts.join(' ')}.';
  }
  if (lines == 0 && labels == 0) return 'Le canevas est vide.';
  final parts = <String>[
    if (lines > 0) '$lines trait${lines == 1 ? '' : 's'}',
    if (colours > 1) 'de $colours couleurs',
    if (labels > 0) 'et $labels mot${labels == 1 ? '' : 's'}',
  ];
  return 'Ton dessin a ${parts.join(' ')}.';
}
