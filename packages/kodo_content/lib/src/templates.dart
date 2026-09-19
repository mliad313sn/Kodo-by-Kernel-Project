/// Item templates (§12).
///
/// *"Each of the nine types has a parameterised template; a large share of D1–D2 items are
/// generated from parameter sets and then human-reviewed, not hand-built from zero."*
///
/// This is the content pipeline, and it is the answer to `R1` — the register's
/// joint-highest risk, that authoring under-delivers and mastery becomes a claim. The
/// **strings are authored by hand, once per template, in both languages**; the parameters
/// vary the numbers. What a template may never do is generate a failure message: those
/// carry the numbers the grader measured, which is why they are patterns with holes rather
/// than sentences with blanks.
///
/// Every item a template produces still goes through M6's publish gate. A template that
/// produces an ungradable item is a bug in the template, and it is caught before a child
/// ever sees it.
library;

import 'package:kodo_grader/kodo_grader.dart';

Map<String, String> _b(String fr, String en) => {'fr': fr, 'en': en};

/// Substitutes `{name}` holes in an authored string.
String fill(String template, Map<String, Object?> values) {
  var out = template;
  for (final e in values.entries) {
    out = out.replaceAll('{${e.key}}', '${e.value}');
  }
  return out;
}

Map<String, String> fillBoth(
        Map<String, String> keys, Map<String, Object?> values) =>
    {for (final e in keys.entries) e.key: fill(e.value, values)};

/// The diagnostic patterns every drawing item shares.
///
/// Authored once because the *shape* of the sentence is the same wherever a figure is
/// compared with a target — and authored with holes the grader fills, so the message names
/// the observable difference (`FR-M6-03`) rather than a feeling.
List<DiagnosticPattern> drawingDiagnostics(
    {String? lookAtFr, String? lookAtEn}) {
  final tailFr = lookAtFr == null ? '' : ' $lookAtFr';
  final tailEn = lookAtEn == null ? '' : ' $lookAtEn';
  return [
    DiagnosticPattern(
      when: 'drewTooLittle',
      textKeys: _b(
        'Ta figure a {actual} traits, la cible en a {expected}. Il en manque.$tailFr',
        'Your shape has {actual} lines, the target has {expected}. Some are missing.$tailEn',
      ),
    ),
    DiagnosticPattern(
      when: 'drewTooMuch',
      textKeys: _b(
        'Ta figure a {actual} traits, la cible en a {expected}. Tu en as dessiné trop.$tailFr',
        'Your shape has {actual} lines, the target has {expected}. You drew too many.$tailEn',
      ),
    ),
    DiagnosticPattern(
      when: 'wrongShape',
      textKeys: _b(
        'Ta figure a {actual} traits, la cible en a {expected}. '
            'Elle ne va pas au même endroit.$tailFr',
        'Your shape has {actual} lines, the target has {expected}. '
            'It does not go to the same place.$tailEn',
      ),
    ),
    /* World 3. A right shape in the wrong colour is not a wrong shape, and telling a
       child it is sends them back to redraw something that was already correct. The
       numbers are the ones the grader counted, so the sentence names what it saw. */
    DiagnosticPattern(
      when: 'wrongColour',
      textKeys: _b(
        'La figure est au bon endroit, mais pas de la bonne couleur : tu en as '
            'utilisé {actualColours}, la cible en a {expectedColours}.$tailFr',
        'The shape is in the right place, but not in the right colour: you used '
            '{actualColours}, the target has {expectedColours}.$tailEn',
      ),
    ),
    DiagnosticPattern(
      when: 'wrongWidth',
      textKeys: _b(
        'La figure est au bon endroit, mais le crayon n\'a pas la bonne '
            'épaisseur.$tailFr',
        'The shape is in the right place, but the pen is not the right '
            'thickness.$tailEn',
      ),
    ),
    /* What the program wrote out. The numbers are the ones the grader counted, so the
       sentence can name the difference rather than say "incorrect". */
    DiagnosticPattern(
      when: 'wrongOutput',
      textKeys: _b(
        'Ton programme a écrit {actualCount} nombre(s) : {actual}. '
            'Il fallait écrire : {expected}.$tailFr',
        'Your program wrote {actualCount} number(s): {actual}. '
            'It should have written: {expected}.$tailEn',
      ),
    ),
    DiagnosticPattern(
      when: 'wrongBackground',
      textKeys: _b(
        'Le dessin est bon. C\'est la couleur du fond qui n\'est pas la bonne.$tailFr',
        'The drawing is right. It is the background colour that is not.$tailEn',
      ),
    ),
    DiagnosticPattern(
      when: 'wrongCanvasSize',
      textKeys: _b(
        'Le dessin est bon, mais la feuille n\'a pas la bonne taille.$tailFr',
        'The drawing is right, but the sheet is not the right size.$tailEn',
      ),
    ),
    DiagnosticPattern(
      when: 'structureMissing',
      textKeys: _b(
        'Le dessin ressemble à la cible, mais il faut y arriver comme on vient de '
            'l\'apprendre.',
        'The drawing looks like the target, but you need to get there the way we '
            'just learned.',
      ),
    ),
    DiagnosticPattern(
      when: 'programFailed',
      textKeys: _b(
        'Ton programme s\'est arrêté avant la fin. Regarde la ligne en rouge.',
        'Your program stopped before the end. Look at the red line.',
      ),
    ),
    DiagnosticPattern(
      when: 'endedElsewhere',
      textKeys: _b(
        'Le dessin est bon, mais Tika ne finit pas au bon endroit.',
        'The drawing is right, but Tika does not end up in the right place.',
      ),
    ),
    DiagnosticPattern(
      when: 'tooManyBlocks',
      textKeys: _b(
        'Tu as utilisé {actual} blocs. Il en faut {expected} au maximum.',
        'You used {actual} blocks. The most you may use is {expected}.',
      ),
    ),
  ];
}

/// The choice diagnostic, for T3, T6 and T8.
DiagnosticPattern choiceDiagnostic(String fr, String en) =>
    DiagnosticPattern(when: 'wrongChoice', textKeys: _b(fr, en));

/// A hand-authored hint pair.
List<Hint> hints(String fr1, String en1, String fr2, String en2,
        {String? spotlight}) =>
    [
      Hint(textKeys: _b(fr1, en1), spotlightOpcodeId: spotlight),
      Hint(textKeys: _b(fr2, en2)),
    ];

/// **T1 — build to target.** The child draws a figure that matches.
///
/// Its two alternative correct solutions come from the language, not from invention:
/// `recule -n` is `avance n`, and `tournegauche 360-a` is `tournedroite a`. Those are real
/// equivalences a child discovers, and using them as the alternatives means the grader is
/// tested against the exact reasoning World 1 teaches.
Item buildToTarget({
  required String id,
  required String conceptId,
  required Difficulty difficulty,
  required String solution,
  required Map<String, String> promptKeys,
  required List<String> wrong,
  required List<Hint> itemHints,
  List<String>? alternatives,
  List<StructuralAssertion> assertions = const [],
  List<String> paletteScope = const [],
  String? lookAtFr,
  String? lookAtEn,
  bool requireFinalPose = false,
  /// Which trigger this item's programs run under (`FR-M21-01`). World 5's
  /// items are graded under their own event, or a `quand touche` script never
  /// fires and every answer draws nothing.
  String runTrigger = 'flag',
  int version = 1,
}) =>
    Item(
      id: id,
      version: version,
      conceptId: conceptId,
      type: ItemType.t1BuildToTarget,
      difficulty: difficulty,
      promptKeys: promptKeys,
      targetProgramSource: solution,
      referenceSolutionSource: solution,
      alternativeSolutionSources: alternatives ?? equivalentsOf(solution),
      wrongSolutionSources: wrong,
      assertions: assertions,
      hints: itemHints,
      diagnostics: drawingDiagnostics(lookAtFr: lookAtFr, lookAtEn: lookAtEn),
      paletteScope: paletteScope,
      requireFinalPose: requireFinalPose,
      runTrigger: runTrigger,
    );

/// Two programs that draw exactly what [solution] draws, written differently.
///
/// Generated from the source rather than authored, because these equivalences are
/// *properties of the language* and a human authoring them by hand would eventually get
/// one wrong — which is how a correct child answer comes to be marked wrong.
List<String> equivalentsOf(String solution) {
  final viaReverse = solution.split('\n').map((line) {
    final move = RegExp(r'^(\s*)avance (-?\d+(?:\.\d+)?)$').firstMatch(line);
    if (move != null) return '${move.group(1)}recule -${move.group(2)}';
    return line;
  }).join('\n');

  final viaOppositeTurn = solution.split('\n').map((line) {
    final turn =
        RegExp(r'^(\s*)tournedroite (\d+(?:\.\d+)?)$').firstMatch(line);
    if (turn != null) {
      final degrees = double.parse(turn.group(2)!);
      final other = 360 - degrees;
      final text = other == other.roundToDouble() ? other.toInt() : other;
      return '${turn.group(1)}tournegauche $text';
    }
    final left =
        RegExp(r'^(\s*)tournegauche (\d+(?:\.\d+)?)$').firstMatch(line);
    if (left != null) {
      final degrees = double.parse(left.group(2)!);
      final other = 360 - degrees;
      final text = other == other.roundToDouble() ? other.toInt() : other;
      return '${left.group(1)}tournedroite $text';
    }
    return line;
  }).join('\n');

  final out = <String>{};
  if (viaReverse != solution) out.add(viaReverse);
  if (viaOppositeTurn != solution) out.add(viaOppositeTurn);
  // A trailing comment changes the text and not the program: proof that the grader is
  // looking at the tree.
  out.add('# une autre façon\n$solution');
  return out.take(2).toList();
}

/// **T3 — predict.** The child is shown a program and picks the canvas it draws.
Item predict({
  required String id,
  required String conceptId,
  required Difficulty difficulty,
  required Map<String, String> promptKeys,
  required List<Choice> choices,
  required List<Hint> itemHints,
  required String wrongChoiceFr,
  required String wrongChoiceEn,
  int version = 1,
}) =>
    Item(
      id: id,
      version: version,
      conceptId: conceptId,
      type: ItemType.t3Predict,
      difficulty: difficulty,
      promptKeys: promptKeys,
      choices: choices,
      hints: itemHints,
      diagnostics: [choiceDiagnostic(wrongChoiceFr, wrongChoiceEn)],
    );

/// **T6 — read and answer**, and **T8 — explain**. Same shape, different question.
Item choiceItem({
  required String id,
  required String conceptId,
  required ItemType type,
  required Difficulty difficulty,
  required Map<String, String> promptKeys,
  required List<Choice> choices,
  required List<Hint> itemHints,
  required String wrongChoiceFr,
  required String wrongChoiceEn,
  int version = 1,
}) =>
    Item(
      id: id,
      version: version,
      conceptId: conceptId,
      type: type,
      difficulty: difficulty,
      promptKeys: promptKeys,
      choices: choices,
      hints: itemHints,
      diagnostics: [choiceDiagnostic(wrongChoiceFr, wrongChoiceEn)],
    );

/// **T2 — fix the bug.** The child is given a program that draws the wrong thing.
Item fixTheBug({
  required String id,
  required String conceptId,
  required Difficulty difficulty,
  required String broken,
  required String solution,
  required Map<String, String> promptKeys,
  required List<String> wrong,
  required List<Hint> itemHints,
  List<String> paletteScope = const [],
  String? lookAtFr,
  String? lookAtEn,
  bool requireFinalPose = false,
  /// Which trigger this item's programs run under (`FR-M21-01`). World 5's
  /// items are graded under their own event, or a `quand touche` script never
  /// fires and every answer draws nothing.
  /// Structural checks the drawing cannot make.
  ///
  /// World 5 needs these: a program with no `quand` at all still runs under the
  /// green flag — it has to, or every item in Worlds 0 to 4 stops working — so
  /// "you forgot the trigger" is a wrong answer that draws the right picture.
  List<StructuralAssertion> assertions = const [],
  /// Two programs that are also right, authored when the language cannot
  /// generate them: `equivalentsOf` rewrites `avance` and `tourne` lines and
  /// nothing else, so a body made of `recule` or `direction` yields one.
  List<String>? alternatives,
  String runTrigger = 'flag',
  int version = 1,
}) =>
    Item(
      id: id,
      version: version,
      conceptId: conceptId,
      type: ItemType.t2FixTheBug,
      difficulty: difficulty,
      promptKeys: promptKeys,
      startingProgramSource: broken,
      targetProgramSource: solution,
      referenceSolutionSource: solution,
      alternativeSolutionSources:
          alternatives ?? equivalentsOf(solution),
      wrongSolutionSources: [broken, ...wrong],
      hints: itemHints,
      diagnostics: drawingDiagnostics(lookAtFr: lookAtFr, lookAtEn: lookAtEn),
      paletteScope: paletteScope,
      requireFinalPose: requireFinalPose,
      runTrigger: runTrigger,
      assertions: assertions,
    );

/// **T4 — fill the gap.** Same grading as a build, a different thing on screen.
Item fillTheGap({
  required String id,
  required String conceptId,
  required Difficulty difficulty,
  required String withHoles,
  required String solution,
  required Map<String, String> promptKeys,
  required List<String> wrong,
  required List<Hint> itemHints,
  List<String> paletteScope = const [],

  /// Needed wherever the marks coincide and only the pose differs — World 4's jumps do
  /// this constantly, because a jump leaves no ink to tell two answers apart.
  bool requireFinalPose = false,
  /// Which trigger this item's programs run under (`FR-M21-01`). World 5's
  /// items are graded under their own event, or a `quand touche` script never
  /// fires and every answer draws nothing.
  /// Structural checks the drawing cannot make.
  ///
  /// World 5 needs these: a program with no `quand` at all still runs under the
  /// green flag — it has to, or every item in Worlds 0 to 4 stops working — so
  /// "you forgot the trigger" is a wrong answer that draws the right picture.
  List<StructuralAssertion> assertions = const [],
  /// Two programs that are also right, authored when the language cannot
  /// generate them: `equivalentsOf` rewrites `avance` and `tourne` lines and
  /// nothing else, so a body made of `recule` or `direction` yields one.
  List<String>? alternatives,
  String runTrigger = 'flag',
  int version = 1,
}) =>
    Item(
      id: id,
      version: version,
      conceptId: conceptId,
      type: ItemType.t4FillTheGap,
      difficulty: difficulty,
      promptKeys: promptKeys,
      startingProgramSource: withHoles,
      targetProgramSource: solution,
      referenceSolutionSource: solution,
      alternativeSolutionSources:
          alternatives ?? equivalentsOf(solution),
      wrongSolutionSources: wrong,
      hints: itemHints,
      diagnostics: drawingDiagnostics(),
      paletteScope: paletteScope,
      requireFinalPose: requireFinalPose,
      runTrigger: runTrigger,
      assertions: assertions,
    );

/// **T5 — Parsons.** Shuffled lines to put back in order. Graded on what it draws, so a
/// correct alternative ordering passes (`FR-M6-02`).
Item parsons({
  required String id,
  required String conceptId,
  required Difficulty difficulty,
  required String solution,
  required Map<String, String> promptKeys,
  required List<String> wrong,
  required List<Hint> itemHints,
  List<String> paletteScope = const [],

  /// Needed whenever a wrong ordering retraces the right one: a staircase assembled in the
  /// wrong order can leave exactly the same pixels and only a different final pose.
  bool requireFinalPose = false,
  /// Which trigger this item's programs run under (`FR-M21-01`). World 5's
  /// items are graded under their own event, or a `quand touche` script never
  /// fires and every answer draws nothing.
  /// Structural checks the drawing cannot make.
  ///
  /// World 5 needs these: a program with no `quand` at all still runs under the
  /// green flag — it has to, or every item in Worlds 0 to 4 stops working — so
  /// "you forgot the trigger" is a wrong answer that draws the right picture.
  List<StructuralAssertion> assertions = const [],
  /// Two programs that are also right, authored when the language cannot
  /// generate them: `equivalentsOf` rewrites `avance` and `tourne` lines and
  /// nothing else, so a body made of `recule` or `direction` yields one.
  List<String>? alternatives,
  String runTrigger = 'flag',
  int version = 1,
}) =>
    Item(
      id: id,
      version: version,
      conceptId: conceptId,
      type: ItemType.t5Parsons,
      difficulty: difficulty,
      promptKeys: promptKeys,
      targetProgramSource: solution,
      referenceSolutionSource: solution,
      alternativeSolutionSources:
          alternatives ?? equivalentsOf(solution),
      wrongSolutionSources: wrong,
      hints: itemHints,
      diagnostics: drawingDiagnostics(),
      paletteScope: paletteScope,
      requireFinalPose: requireFinalPose,
      runTrigger: runTrigger,
      assertions: assertions,
    );

/// **T9 — open build.** A brief, a rubric, and no single right answer.
///
/// The rubric is shown to the child **before they start** (`FR-M6-06`), which is the whole
/// difference between an open build and a guessing game: a child who does not know what
/// "good" means can only produce something and hope. Each line is one plain sentence and
/// one structural check, so the feedback can say which line is not met yet rather than
/// giving a mark.
///
/// There is no target drawing. An open build that compares pixels is a build-to-target
/// wearing a different name.
Item openBuild({
  required String id,
  required String conceptId,
  required Difficulty difficulty,
  required Map<String, String> promptKeys,
  required List<RubricLine> rubric,
  required List<Hint> itemHints,
  List<String> paletteScope = const [],
  String runTrigger = 'flag',
  int version = 1,
}) =>
    Item(
      id: id,
      version: version,
      conceptId: conceptId,
      type: ItemType.t9OpenBuild,
      difficulty: difficulty,
      promptKeys: promptKeys,
      rubric: rubric,
      hints: itemHints,
      diagnostics: drawingDiagnostics(),
      paletteScope: paletteScope,
      runTrigger: runTrigger,
    );

/// One line of a rubric: what it says to the child, and what it checks.
RubricLine rubricLine(String fr, String en, StructuralAssertion check) =>
    RubricLine(textKeys: _b(fr, en), assertion: check);

/// **T7 — golf.** A target and a block budget.
Item golf({
  required String id,
  required String conceptId,
  required Difficulty difficulty,
  required String solution,
  required int budget,
  required Map<String, String> promptKeys,
  required List<String> wrong,
  required List<Hint> itemHints,
  List<String> paletteScope = const [],
  /// Structural checks the block budget cannot make.
  ///
  /// A budget bounds how *much* a program may be; it says nothing about what it is made
  /// of. World 6's golf items are about reaching a number by arithmetic, and a child who
  /// types the answer meets the budget with room to spare — so the claim about the box
  /// has to be made here, as it is on every other item type.
  List<StructuralAssertion> assertions = const [],
  /// Which trigger this item's programs run under (`FR-M21-01`). World 5's
  /// items are graded under their own event, or a `quand touche` script never
  /// fires and every answer draws nothing.
  /// Two programs that are also right, authored when the language cannot
  /// generate them: `equivalentsOf` rewrites `avance` and `tourne` lines and
  /// nothing else, so a body made of `recule` or `direction` yields one.
  List<String>? alternatives,
  String runTrigger = 'flag',
  int version = 1,
}) =>
    Item(
      id: id,
      version: version,
      conceptId: conceptId,
      type: ItemType.t7Golf,
      difficulty: difficulty,
      promptKeys: promptKeys,
      targetProgramSource: solution,
      referenceSolutionSource: solution,
      alternativeSolutionSources:
          alternatives ?? equivalentsOf(solution),
      wrongSolutionSources: wrong,
      blockBudget: budget,
      hints: itemHints,
      diagnostics: drawingDiagnostics(),
      paletteScope: paletteScope,
      runTrigger: runTrigger,
      assertions: assertions,
    );
