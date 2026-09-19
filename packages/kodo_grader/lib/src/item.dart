/// The item model (§6.1, FR-M6-05, FR-M6-06, FR-M6-09, FR-M18-02).
///
/// An item is data. It carries its own grading policy, its own two hints, its own
/// diagnostic messages and its own reference solutions, because a content pack has to be
/// gradable offline with no app release (`NFR-MAINT-01`) and because the publish gate of
/// `FR-M18-02` has to be able to refuse an incomplete one.
library;

import 'package:kodo_lang/kodo_lang.dart';

import 'assertions.dart';

/// The nine types of §6.1.
enum ItemType {
  /// Construire vers la cible.
  t1BuildToTarget('T1'),

  /// Trouve le bug.
  t2FixTheBug('T2'),

  /// Devine le résultat.
  t3Predict('T3'),

  /// Complète.
  t4FillTheGap('T4'),

  /// Remets dans l'ordre.
  t5Parsons('T5'),

  /// Lis le code.
  t6ReadAndAnswer('T6'),

  /// Le plus court.
  t7Golf('T7'),

  /// Explique.
  t8Explain('T8'),

  /// Défi libre.
  t9OpenBuild('T9');

  const ItemType(this.code);
  final String code;

  static ItemType byCode(String code) =>
      ItemType.values.firstWhere((t) => t.code == code,
          orElse: () => throw ArgumentError('unknown item type "$code"'));

  /// True when the child answers by writing a program rather than by choosing.
  bool get wantsProgram => switch (this) {
        ItemType.t3Predict ||
        ItemType.t6ReadAndAnswer ||
        ItemType.t8Explain =>
          false,
        _ => true,
      };
}

/// D1–D5 of §5.3.
enum Difficulty {
  d1('D1'),
  d2('D2'),
  d3('D3'),
  d4('D4'),
  d5('D5');

  const Difficulty(this.code);
  final String code;

  static Difficulty byCode(String code) =>
      Difficulty.values.firstWhere((d) => d.code == code);
}

/// A hint. Two per item, and neither reveals the answer (`FR-M6-05`).
class Hint {
  const Hint({required this.textKeys, this.spotlightOpcodeId});

  /// Localisation keys — one per shipped language, keyed by locale. Never a raw string:
  /// `FR-M15-04` forbids child-facing text that is not authored and reviewed as content.
  final Map<String, String> textKeys;

  /// A block to make glow, per §4.7's three-failure escalation.
  final String? spotlightOpcodeId;

  String textIn(String locale) => textKeys[locale] ?? textKeys['fr'] ?? '';

  Map<String, Object?> toJson() => {
        'text': textKeys,
        if (spotlightOpcodeId != null) 'spotlight': spotlightOpcodeId
      };

  static Hint fromJson(Map<String, Object?> j) => Hint(
        textKeys: (j['text']! as Map<String, Object?>).cast<String, String>(),
        spotlightOpcodeId: j['spotlight'] as String?,
      );
}

/// An authored failure message, and the condition that selects it.
///
/// `FR-M6-03` requires the message to name the *observable difference* — "Ta figure a
/// 4 côtés, la cible en a 6" — so a pattern is bound to a named situation the grader can
/// actually detect, and a generic fallback is a build error rather than a default.
class DiagnosticPattern {
  const DiagnosticPattern({required this.when, required this.textKeys});

  /// One of the [DiagnosticSituation] names.
  final String when;
  final Map<String, String> textKeys;

  String textIn(String locale, Map<String, String> args) {
    var text = textKeys[locale] ?? textKeys['fr'] ?? '';
    for (final e in args.entries) {
      text = text.replaceAll('{${e.key}}', e.value);
    }
    return text;
  }

  Map<String, Object?> toJson() => {'when': when, 'text': textKeys};

  static DiagnosticPattern fromJson(Map<String, Object?> j) =>
      DiagnosticPattern(
        when: j['when']! as String,
        textKeys: (j['text']! as Map<String, Object?>).cast<String, String>(),
      );
}

/// The situations an author may write a message for.
///
/// A closed list, so that the publish gate can tell an author which ones they have not
/// covered, and so that "the item has a diagnostic" means something checkable.
enum DiagnosticSituation {
  /// The program did not run at all.
  programFailed,

  /// The figure is a subset of the target.
  drewTooLittle,

  /// The figure covers the target and adds more.
  drewTooMuch,

  /// The figure is somewhere else entirely.
  wrongShape,

  /// The drawing is right but the required structure is not there.
  structureMissing,

  /// Over the block budget of a T7 item.
  tooManyBlocks,

  /// A choice item answered wrongly.
  wrongChoice,

  /// The marks are right but the turtle did not end up where it should.
  endedElsewhere,

  /* World 3's three. "Wrong shape" is the wrong sentence for a right shape in the wrong
     colour, and `FR-M6-03` forbids a message that does not name the observable
     difference — a child who drew the square perfectly and picked the wrong red should be
     told about the red. */

  /// The figure is in the right place and the wrong colour.
  wrongColour,

  /// The figure is in the right place and drawn with the wrong pen width.
  wrongWidth,

  /* World 10's five. A costume leaves no ink, so none of the situations above can name
     what went wrong on a stage — and `wrongShape` for a sprite wearing the wrong costume
     is the sentence `FR-M6-03` exists to forbid. */

  /// The sprite is wearing a different costume from the target's.
  wrongCostume,

  /// The stage is showing a different backdrop.
  wrongBackdrop,

  /// The sounds asked for, or their order, are not the target's.
  wrongSound,

  /// What the sprite said is not what the target said.
  wrongSpeech,

  /// A graphic effect is set differently — or was left on when it should have been
  /// cleared, which is concept C10.5's misconception exactly.
  wrongEffect,

  /// The drawing is right and the program printed the wrong thing — or printed nothing.
  ///
  /// World 4's third concept is `positionx` / `positiony`, and the only way to show a
  /// child that a position is a *value* is to print it. `écris` puts nothing on the
  /// canvas, so until this existed every one of those items graded vacuously: printing
  /// the two numbers in the wrong order, or printing only one of them, passed.
  wrongOutput,

  /// The drawing is right and the paper is the wrong colour.
  wrongBackground,

  /// The drawing is right and the canvas is the wrong size.
  wrongCanvasSize;

  static DiagnosticSituation? byName(String name) {
    for (final s in DiagnosticSituation.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// One candidate answer for a choice item (T3, T6, T8).
class Choice {
  const Choice(
      {required this.labelKeys, required this.correct, this.misconception});

  final Map<String, String> labelKeys;
  final bool correct;

  /// The misconception this wrong answer indicates, e.g. `C2.2-body-scope`.
  ///
  /// `FR-M6-01`'s process signals feed the misconception model, and a wrong answer that
  /// does not say *which* wrong idea it evidences is a lost measurement (§4.5).
  final String? misconception;

  Map<String, Object?> toJson() => {
        'label': labelKeys,
        'correct': correct,
        if (misconception != null) 'misconception': misconception,
      };

  static Choice fromJson(Map<String, Object?> j) => Choice(
        labelKeys: (j['label']! as Map<String, Object?>).cast<String, String>(),
        correct: j['correct']! as bool,
        misconception: j['misconception'] as String?,
      );
}

/// One rubric line of a T9 open build, shown to the child *before* they start
/// (`FR-M6-06`).
class RubricLine {
  const RubricLine({required this.textKeys, required this.assertion});
  final Map<String, String> textKeys;
  final StructuralAssertion assertion;

  Map<String, Object?> toJson() =>
      {'text': textKeys, 'check': assertion.toJson()};

  static RubricLine fromJson(Map<String, Object?> j) => RubricLine(
        textKeys: (j['text']! as Map<String, Object?>).cast<String, String>(),
        assertion:
            StructuralAssertion.fromJson(j['check']! as Map<String, Object?>),
      );
}

/// A graded exercise.
class Item {
  const Item({
    required this.id,
    required this.version,
    required this.conceptId,
    required this.type,
    required this.difficulty,
    required this.promptKeys,
    this.targetProgramSource,
    this.startingProgramSource,
    this.referenceSolutionSource,
    this.wrongSolutionSources = const [],
    this.alternativeSolutionSources = const [],
    this.assertions = const [],
    this.hints = const [],
    this.diagnostics = const [],
    this.choices = const [],
    this.rubric = const [],
    this.paletteScope = const [],
    this.blockBudget,
    this.seed = 1,
    this.inputs = const [],
    this.sensing = SensingScene.empty,
    this.stage,
    this.keywords = 'fr',
    this.runTrigger = 'flag',
    this.requireFinalPose = false,
  });

  final String id;

  /// Bumped when the item is corrected. A stored attempt keeps the version it was graded
  /// under, so a fix never retroactively invalidates a child's mastery (`FR-M6-09`).
  final int version;

  final String conceptId;
  final ItemType type;
  final Difficulty difficulty;

  /// The question, per locale.
  final Map<String, String> promptKeys;

  /// The program that draws the target. Rendered once to produce the goal image; the
  /// child never sees its source.
  final String? targetProgramSource;

  /// What the child starts with — the broken program of a T2, the holes of a T4, the
  /// shuffled blocks of a T5.
  final String? startingProgramSource;

  /// One program the author asserts is correct. The publish gate runs it.
  final String? referenceSolutionSource;

  /// At least three programs the author asserts are wrong (`FR-M6` acceptance 1).
  final List<String> wrongSolutionSources;

  /// At least two *different* correct programs. This is the list that stops a grader
  /// overfitting to one shape, and it is the reason a child who solves it their own way
  /// passes.
  final List<String> alternativeSolutionSources;

  final List<StructuralAssertion> assertions;
  final List<Hint> hints;
  final List<DiagnosticPattern> diagnostics;
  final List<Choice> choices;
  final List<RubricLine> rubric;

  /// Opcodes the palette may show (`FR-M2-08`).
  final List<String> paletteScope;

  /// The budget of a T7 item.
  final int? blockBudget;

  /// Seeded so `hasard` is reproducible for grading (`FR-M1-09`).
  final int seed;

  /// Scripted answers for `demande`, so an asking item can still be graded headlessly.
  final List<String> inputs;

  /// What the keyboard and the pointer are doing while this item is graded.
  ///
  /// The same idea as [seed] and [inputs], for the same reason: World 8's sensing concept
  /// asks `touchepressée "espace"`, and a key nobody is holding makes every answer draw
  /// nothing and all of them pass. `touchebord` and `touchecouleur` need none of this —
  /// they are geometry, and the canvas computes them.
  final SensingScene sensing;

  /// The stage this item is graded on, or null for the plain canvas of Worlds 0 to 9.
  ///
  /// Setting it does two things at once, and both are necessary. It puts the item on a
  /// `SpriteStage` rather than a `VectorCanvas`, so `costumesuivant` and `jouson` are
  /// answered rather than refused; and it says what is already there, because
  /// `costumesuivant` on a sprite with no costumes does nothing and an item where
  /// nothing happens passes every answer.
  final StageSetup? stage;

  /// Which keyword language this item's programs are written in.
  ///
  /// `fr` by default, because that is what a child sees first. World 11's fourth concept
  /// is that English keywords are the same language in different words, so its items are
  /// written in `en` — and both tables are tried when parsing, because a program that
  /// parses under either is a program. See `keyword_agnostic.dart`.
  final String keywords;

  /// Which trigger this item's programs run under (`FR-M21-01`).
  ///
  /// `flag` (the default), `clicked`, `key:<name>`, or `any`. Without it every World 5
  /// item would grade vacuously: a `quand touche "espace"` script never fires under the
  /// green flag, so the target and every answer would draw nothing and all of them would
  /// pass. An item about events has to be able to say which event.
  ///
  /// `any` fires every script whatever its trigger, which is what a *"two scripts at
  /// once"* item wants: the question is how they interleave, not which one starts.
  final String runTrigger;

  /// Whether the turtle must finish where the target's turtle finished.
  ///
  /// Raster comparison cannot see this, and neither can a path signature over segments:
  /// `avance 50` and `avance 50 / recule 50` leave **identical marks**. World 1 asks a
  /// child to "come back exactly to the start", which is a claim about the turtle and not
  /// about the drawing, so the item has to be able to say so.
  ///
  /// It is authored per item, never inferred, for the same reason the structural
  /// assertions are: most items are about a figure, and demanding a final pose on those
  /// would fail a child who drew the right shape from the other end.
  ///
  /// Found by the publish gate while authoring World 1 — thirteen items whose "wrong"
  /// solutions all passed.
  final bool requireFinalPose;

  String promptIn(String locale) =>
      promptKeys[locale] ?? promptKeys['fr'] ?? '';

  DiagnosticPattern? diagnosticFor(DiagnosticSituation situation) {
    for (final d in diagnostics) {
      if (d.when == situation.name) return d;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'version': version,
        'concept': conceptId,
        'type': type.code,
        'difficulty': difficulty.code,
        'prompt': promptKeys,
        if (targetProgramSource != null) 'target': targetProgramSource,
        if (startingProgramSource != null) 'start': startingProgramSource,
        if (referenceSolutionSource != null)
          'reference': referenceSolutionSource,
        'wrong': wrongSolutionSources,
        'alternatives': alternativeSolutionSources,
        'assertions': [for (final a in assertions) a.toJson()],
        'hints': [for (final h in hints) h.toJson()],
        'diagnostics': [for (final d in diagnostics) d.toJson()],
        'choices': [for (final c in choices) c.toJson()],
        'rubric': [for (final r in rubric) r.toJson()],
        'palette': paletteScope,
        if (blockBudget != null) 'budget': blockBudget,
        'seed': seed,
        if (runTrigger != 'flag') 'trigger': runTrigger,
        if (inputs.isNotEmpty) 'inputs': inputs,
        if (!sensing.isDefault) 'sensing': sensing.toJson(),
        if (stage != null) 'stage': stage!.toJson(),
        if (keywords != 'fr') 'keywords': keywords,
        if (requireFinalPose) 'requireFinalPose': true,
      };

  static Item fromJson(Map<String, Object?> j) => Item(
        id: j['id']! as String,
        version: j['version']! as int,
        conceptId: j['concept']! as String,
        type: ItemType.byCode(j['type']! as String),
        difficulty: Difficulty.byCode(j['difficulty']! as String),
        promptKeys:
            (j['prompt']! as Map<String, Object?>).cast<String, String>(),
        targetProgramSource: j['target'] as String?,
        startingProgramSource: j['start'] as String?,
        referenceSolutionSource: j['reference'] as String?,
        wrongSolutionSources:
            ((j['wrong'] as List<Object?>?) ?? const []).cast<String>(),
        alternativeSolutionSources:
            ((j['alternatives'] as List<Object?>?) ?? const []).cast<String>(),
        assertions: [
          for (final a in (j['assertions'] as List<Object?>?) ?? const [])
            StructuralAssertion.fromJson(a! as Map<String, Object?>),
        ],
        hints: [
          for (final h in (j['hints'] as List<Object?>?) ?? const [])
            Hint.fromJson(h! as Map<String, Object?>),
        ],
        diagnostics: [
          for (final d in (j['diagnostics'] as List<Object?>?) ?? const [])
            DiagnosticPattern.fromJson(d! as Map<String, Object?>),
        ],
        choices: [
          for (final c in (j['choices'] as List<Object?>?) ?? const [])
            Choice.fromJson(c! as Map<String, Object?>),
        ],
        rubric: [
          for (final r in (j['rubric'] as List<Object?>?) ?? const [])
            RubricLine.fromJson(r! as Map<String, Object?>),
        ],
        paletteScope:
            ((j['palette'] as List<Object?>?) ?? const []).cast<String>(),
        blockBudget: j['budget'] as int?,
        seed: (j['seed'] as int?) ?? 1,
        runTrigger: (j['trigger'] as String?) ?? 'flag',
        inputs: ((j['inputs'] as List<Object?>?) ?? const []).cast<String>(),
        sensing: j['sensing'] == null
            ? SensingScene.empty
            : SensingScene.fromJson(j['sensing']! as Map<String, Object?>),
        stage: j['stage'] == null
            ? null
            : StageSetup.fromJson(j['stage']! as Map<String, Object?>),
        keywords: (j['keywords'] as String?) ?? 'fr',
        requireFinalPose: (j['requireFinalPose'] as bool?) ?? false,
      );
}

/// What a child submitted.
sealed class Response {
  const Response();
  Map<String, Object?> toJson();
}

/// A program, from the block editor or the text editor — they are the same tree.
class ProgramResponse extends Response {
  const ProgramResponse(this.program);
  final Program program;

  @override
  Map<String, Object?> toJson() => {'kind': 'program', 'ast': program.toJson()};
}

/// A choice from T3, T6 or T8.
class ChoiceResponse extends Response {
  const ChoiceResponse(this.index);
  final int index;

  @override
  Map<String, Object?> toJson() => {'kind': 'choice', 'index': index};
}

/// A number, for the numeric variant of T6.
class NumericResponse extends Response {
  const NumericResponse(this.value);
  final num value;

  @override
  Map<String, Object?> toJson() => {'kind': 'numeric', 'value': value};
}
