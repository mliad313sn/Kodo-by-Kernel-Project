import 'package:kodo_grader/kodo_grader.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';

void run(String src) {
  final p = parseEither(src);
  if (p.errors.isNotEmpty) {
    print(
        '${src.replaceAll('\n', ' ; ')}\n  PARSE ERROR: ${p.errors.first.message('fr')}');
    return;
  }
  final s = VectorCanvas();
  final r = runProgram(p.program, s, seed: 1);
  print(
      '${src.replaceAll('\n', ' ; ')}\n  out=${s.output} err=${r.error?.code} n=${s.segmentCount}');
}

void main() {
  for (final src in [
    r'''$l = [3, 1, 2]
écris $l''',
    r'''$l = [3, 1, 2]
écris $l[1]''',
    r'''$l = [3, 1, 2]
écris $l[3]''',
    r'''$l = [3, 1, 2]
écris $l[0]''',
    r'''$l = [3, 1, 2]
écris $l[4]''',
    r'''$l = [30, 50, 70]
pour $i = 1 à 3 {
  avance $l[$i]
  tournedroite 90
}''',
    r'''$l = [30, 50, 70]
$l[2] = 90
écris $l[2]''',
    r'''$l = []
écris $l''',
    r'''$l = [1, 2, 3]
écris longueur $l''',
    r'''$l = [1, 2, 3]
écris taille $l''',
    r'''$l = [1, 2, 3]
écris nombre $l''',
    r'''$a = 5
$b = 7
écris $a
écris $b''',
    r'''$écran = 1
apprends accueil {
  répète 4 {
    avance 50
    tournedroite 90
  }
}
apprends jeu {
  répète 3 {
    avance 60
    tournedroite 120
  }
}
si $écran == 1 {
  accueil
}
sinon {
  jeu
}''',
  ]) {
    run(src);
  }
}
