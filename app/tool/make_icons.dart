/// Generates KODO's launcher icons from the art package.
///
/// Run it, commit what it writes. The icons are generated rather than exported by hand so
/// that the thing a child taps on their home screen is the character in `kodo_art` — and
/// stays that character when the art changes. It shipped as Flutter's template logo,
/// byte-identical in every mipmap bucket, because nobody ever replaced a binary blob.
///
///     dart run tool/make_icons.dart
library;

import 'dart:io';

import 'package:kodo_art/kodo_art.dart';
import 'package:kodo_stage/kodo_stage.dart';

/// Android's launcher buckets, and the two the web manifest asks for.
const _android = <String, int>{
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

/// Sand, which is the colour Tika is drawn against everywhere else in the product.
const _background = 0xF2E4CE;

void main() {
  var written = 0, bytes = 0;

  void write(String path, int size, {bool maskable = false}) {
    /* A maskable icon is cropped to whatever shape the launcher wants, so the drawing is
       inset to keep Tika inside the safe zone rather than losing her flippers to a
       circle. */
    final pixels = drawingToRgb(
      maskable ? _inset(tikaPortrait, 0.72) : tikaPortrait,
      size: size,
      background: _background,
    );
    final png = encodePng(size, size, pixels);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(png);
    written++;
    bytes += png.length;
    stdout.writeln('  ${png.length.toString().padLeft(8)}  $path');
  }

  for (final entry in _android.entries) {
    write('android/app/src/main/res/${entry.key}/ic_launcher.png', entry.value);
  }
  write('web/icons/Icon-192.png', 192);
  write('web/icons/Icon-maskable-192.png', 192, maskable: true);
  write('web/favicon.png', 32);

  /* No 512 PNG. The encoder writes stored zlib blocks — an honest trade explained in
     `png.dart` — so a 512 square costs 768 KB whatever is in it, and the browsers that
     want a large icon take the vector instead. It is three kilobytes and sharp at any
     size a launcher asks for. */
  final svg = drawingToSvg(tikaPortrait);
  File('web/icons/kodo.svg').writeAsStringSync(svg);
  stdout.writeln('  ${svg.length.toString().padLeft(8)}  web/icons/kodo.svg');

  stdout.writeln('$written icons, ${(bytes / 1024).round()} KB total');
}

/// The same drawing, scaled about its centre — for a maskable icon's safe zone.
Drawing _inset(Drawing drawing, double factor) {
  P at(P p) => P(50 + (p.x - 50) * factor, 50 + (p.y - 50) * factor);
  return Drawing(
    id: '${drawing.id}-inset',
    describeFr: drawing.describeFr,
    describeEn: drawing.describeEn,
    shapes: [
      for (final shape in drawing.shapes)
        switch (shape) {
          Circle(:final ink, :final centre, :final r) =>
            Circle(ink, at(centre), r * factor),
          Oval(:final ink, :final centre, :final rx, :final ry) =>
            Oval(ink, at(centre), rx * factor, ry * factor),
          Poly(:final ink, :final points, :final closed) =>
            Poly(ink, [for (final p in points) at(p)], closed: closed),
          Box(:final ink, :final topLeft, :final bottomRight, :final radius) =>
            Box(ink, at(topLeft), at(bottomRight), radius: radius * factor),
          Stroke(:final ink, :final points, :final width, :final round) =>
            Stroke(ink, [for (final p in points) at(p)],
                width: width * factor, round: round),
        },
    ],
  );
}
