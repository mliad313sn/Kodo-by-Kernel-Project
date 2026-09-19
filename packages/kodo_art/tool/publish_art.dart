// Writes the SVG files the content packs name.
//
//     dart run tool/publish_art.dart
//
// The packs have referenced `art/tika.svg`, `art/world0-plage.svg` and the rest since
// they were authored; until now nothing wrote them. This does, from the same geometry the
// app paints — so the file and the screen cannot drift, and a pack that names a drawing
// gets the drawing that actually ships.

import 'dart:io';

import 'package:kodo_art/kodo_art.dart';

void main() {
  final dir = Directory('../../art');
  dir.createSync(recursive: true);

  var bytes = 0;
  final written = <String>[];
  for (final drawing in [...tikaPoses.values, ...worldPlaces.values]) {
    for (final (suffix, contrast) in [('', false), ('-contrast', true)]) {
      final svg = drawingToSvg(drawing, highContrast: contrast);
      final file = File('${dir.path}/${drawing.id}$suffix.svg');
      file.writeAsStringSync(svg);
      written.add('${drawing.id}$suffix.svg');
      bytes += svg.length;
    }
  }

  stdout.writeln('Published ${written.length} drawings to art/');
  for (final name in written) {
    stdout.writeln('  $name');
  }
  stdout.writeln(
      '\n  $bytes bytes in total — R4 asks for vector, and this is why.');
}
