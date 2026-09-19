import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';

void run(String src, {StageSetup? setup}) {
  final p = parse(src, KeywordTables.fr);
  if (p.errors.isNotEmpty) {
    print('${src.replaceAll('\n', ' ; ')}\n  PARSE ERROR: ${p.errors.first.message('fr')}');
    return;
  }
  final s = setup == null ? SpriteStage() : SpriteStage.from(setup);
  final r = runProgram(p.program, s, seed: 1);
  final st = s.state;
  print('${src.replaceAll('\n', ' ; ')}\n  err=${r.error?.code} n=${s.segmentCount} '
      'costume=${st.costumeNumber} backdrop=${st.backdropId} score=${st.score} '
      'said=${st.said} effects=${st.effects}');
}

void main() {
  const three = StageSetup(costumes: 3, backdrops: ['nuit', 'plage']);
  for (final src in [
    'costumesuivant',
    'costumesuivant\ncostumesuivant',
    'costume 3',
    'répète 4 {\n  costumesuivant\n}',
    'arrièreplan "nuit"',
    'arrièreplan "plage"',
    'jouson "miaou"',
    'tambour 2, 1',
    'note 60, 1',
    'dis "bonjour"',
    'effet "ghost", 50',
    'effet "ghost", 50\neffaceeffets',
    'effet "couleur", 25\neffet "ghost", 10',
    'avance 40\ncostumesuivant',
    'numérocostume',
    'écris numérocostume',
    'costumesuivant\nécris numérocostume',
  ]) {
    run(src, setup: three);
  }
  print('--- with no costumes at all ---');
  run('costumesuivant\nécris numérocostume');
}
