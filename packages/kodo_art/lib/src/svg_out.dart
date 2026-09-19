/// The second projection: a [Drawing] as an SVG file.
///
/// The content packs already name `art/tika.svg`, `art/world0-plage.svg` and the rest.
/// This is what writes them — from the same geometry the app paints, so the file on disk
/// and the thing on screen cannot drift. There is no second drawing.
library;

import 'geometry.dart';
import 'palette.dart';

String _n(double v) {
  final r = (v * 100).round() / 100;
  return r == r.roundToDouble() ? r.toInt().toString() : r.toString();
}

String _fill(Tint ink, bool highContrast) =>
    KodoPalette.resolve(ink, highContrast: highContrast).hex;

/// Emits [drawing] as a standalone SVG.
///
/// `<title>` and `<desc>` carry the authored description, so the same sentence a screen
/// reader speaks in the app is in the file — `FR-M16-04` does not stop at the app boundary.
String drawingToSvg(Drawing drawing,
    {String locale = 'fr', bool highContrast = false}) {
  final out = StringBuffer()
    ..writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" '
        'width="100" height="100" role="img">')
    ..writeln('  <title>${_escape(drawing.id)}</title>')
    ..writeln('  <desc>${_escape(drawing.describeIn(locale))}</desc>');

  for (final shape in drawing.shapes) {
    final colour = _fill(shape.ink, highContrast);
    switch (shape) {
      case Circle(:final centre, :final r):
        out.writeln('  <circle cx="${_n(centre.x)}" cy="${_n(centre.y)}" '
            'r="${_n(r)}" fill="$colour"/>');
      case Oval(:final centre, :final rx, :final ry):
        out.writeln('  <ellipse cx="${_n(centre.x)}" cy="${_n(centre.y)}" '
            'rx="${_n(rx)}" ry="${_n(ry)}" fill="$colour"/>');
      case Poly(:final points, :final closed):
        final d = points.map((p) => '${_n(p.x)},${_n(p.y)}').join(' ');
        out.writeln(closed
            ? '  <polygon points="$d" fill="$colour"/>'
            : '  <polyline points="$d" fill="none" stroke="$colour"/>');
      case Box(:final topLeft, :final bottomRight, :final radius):
        out.writeln('  <rect x="${_n(topLeft.x)}" y="${_n(topLeft.y)}" '
            'width="${_n(bottomRight.x - topLeft.x)}" '
            'height="${_n(bottomRight.y - topLeft.y)}" '
            '${radius > 0 ? 'rx="${_n(radius)}" ' : ''}fill="$colour"/>');
      case Stroke(:final points, :final width, :final round):
        final d = points.map((p) => '${_n(p.x)},${_n(p.y)}').join(' ');
        out.writeln('  <polyline points="$d" fill="none" stroke="$colour" '
            'stroke-width="${_n(width)}"'
            '${round ? ' stroke-linecap="round" stroke-linejoin="round"' : ''}/>');
    }
  }

  out.writeln('</svg>');
  return out.toString();
}

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
