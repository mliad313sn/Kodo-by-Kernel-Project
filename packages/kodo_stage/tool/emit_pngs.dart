/// Writes the PNGs that `tools/png_check.py` inflates with somebody else's zlib.
///
/// Four drawings, chosen for the shapes a compressor gets wrong: an empty page (one long
/// run), a small figure (a few runs in a sea of background), a dense figure (many short
/// runs), and a rosette (repetition at a distance, which is what LZ77 is for).
library;

import 'dart:io';

import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';

const _drawings = <String, String>{
  'blank': 'lèvecrayon\navance 10',
  'square': 'répète 4 {\n  avance 80\n  tournedroite 90\n}',
  'dense': 'répète 180 {\n  avance 90\n  tournedroite 178\n}',
  'rosette':
      'répète 36 {\n  répète 4 {\n    avance 60\n    tournedroite 90\n  }\n  tournedroite 10\n}',
};

void main(List<String> args) {
  final out = Directory(args.isEmpty ? 'build/png-check' : args.first)
    ..createSync(recursive: true);
  for (final entry in _drawings.entries) {
    final canvas = VectorCanvas();
    Interpreter(parse(entry.value, KeywordTables.fr).program, canvas).run();
    final png = canvas.toPng();
    File('${out.path}/${entry.key}.png').writeAsBytesSync(png);
    stdout.writeln('  ${entry.key.padRight(10)} ${png.length} bytes');
  }
}
