/// KODO — M1, the language core.
///
/// The interface contract frozen at Gate G2. Everything the rest of KODO may rely on is
/// exported here; anything under `src/` is an implementation detail and may change without
/// a specification change.
///
/// ```dart
/// final result = parse('répète 4 { avance 100 tournegauche 90 }', KeywordTables.fr);
/// final canvas = HeadlessCanvas();
/// runProgram(result.program, canvas);
/// print(canvas.pathSignature());
/// print(render(result.program, KeywordTables.en)); // the same program, in English
/// ```
library;

export 'src/ast.dart';
export 'src/errors.dart';
export 'src/headless_canvas.dart';
export 'src/interpreter.dart';
export 'src/keywords.dart';
export 'src/lexer.dart' show Token, TokenType, tokenize;
export 'src/opcodes.dart';
export 'src/parser.dart';
export 'src/python_projection.dart';
export 'src/renderer.dart';
export 'src/rng.dart';
export 'src/span.dart';
export 'src/surface.dart';
export 'src/values.dart';
