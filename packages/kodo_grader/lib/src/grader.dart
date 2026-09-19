/// The grader (§6.2, FR-M6-01 … FR-M6-04).
///
/// Three independent signals, combined by a per-item policy:
///
/// * **behavioural** — run the child's program headlessly in M1 against an M4 headless
///   surface, compare the raster at a ±2 px tolerance *and* the normalised path signature,
///   so a figure drawn in a different but valid order passes;
/// * **structural** — the authored AST assertions;
/// * **process** — attempts, runs, hints, time to first run. **Never** used to pass or
///   fail; they feed M7 and the dashboards.
///
/// Two rules from the `Do not` of the M6 prompt are load-bearing here and are each covered
/// by a test: grading never compares source strings, and a process signal never decides.
library;

import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';

import 'assertions.dart';
import 'item.dart';

/// The signals that do not decide anything (§6.2).
class ProcessSignals {
  const ProcessSignals({
    this.attempts = 1,
    this.runs = 0,
    this.hintsShown = 0,
    this.millisecondsToFirstRun,
    this.millisecondsOnItem,
  });

  final int attempts;
  final int runs;
  final int hintsShown;
  final int? millisecondsToFirstRun;
  final int? millisecondsOnItem;

  /// §4.7: three consecutive failures is a frustration event, and M8 instruments it as
  /// wellbeing telemetry rather than as a funnel metric.
  bool get isFrustrationEvent => attempts >= 3;

  Map<String, Object?> toJson() => {
        'attempts': attempts,
        'runs': runs,
        'hints': hintsShown,
        if (millisecondsToFirstRun != null)
          'toFirstRun': millisecondsToFirstRun,
        if (millisecondsOnItem != null) 'onItem': millisecondsOnItem,
      };

  static ProcessSignals fromJson(Map<String, Object?> j) => ProcessSignals(
        attempts: (j['attempts'] as int?) ?? 1,
        runs: (j['runs'] as int?) ?? 0,
        hintsShown: (j['hints'] as int?) ?? 0,
        millisecondsToFirstRun: j['toFirstRun'] as int?,
        millisecondsOnItem: j['onItem'] as int?,
      );
}

/// What the grader concluded, and everything needed to explain it to a child.
class Verdict {
  const Verdict({
    required this.passed,
    required this.itemId,
    required this.itemVersion,
    this.situation,
    this.messageArgs = const {},
    this.failedAssertions = const [],
    this.behavioural,
    this.runtimeError,
    this.misconception,
  });

  final bool passed;
  final String itemId;
  final int itemVersion;

  /// Which authored diagnostic applies. Null on a pass.
  final DiagnosticSituation? situation;

  /// Values to substitute into the authored message — the numbers that make it name an
  /// observable difference rather than a feeling.
  final Map<String, String> messageArgs;

  final List<AssertionResult> failedAssertions;
  final RasterMatch? behavioural;

  /// Set when the child's program could not run at all.
  final KodoError? runtimeError;

  /// The misconception a wrong choice evidenced, for §4.5's model.
  final String? misconception;

  /// The child-facing sentence, from the item's authored patterns.
  ///
  /// Returns null when the author has not covered this situation — which the publish gate
  /// of `FR-M18-02` refuses, so at run time it can only mean an item that skipped the
  /// gate. The caller shows nothing rather than inventing "Incorrect".
  String? messageFor(Item item, String locale) {
    if (passed || situation == null) return null;
    final pattern = item.diagnosticFor(situation!);
    if (pattern == null) return null;
    return pattern.textIn(locale, messageArgs);
  }

  Map<String, Object?> toJson() => {
        'passed': passed,
        'item': itemId,
        'itemVersion': itemVersion,
        if (situation != null) 'situation': situation!.name,
        'args': messageArgs,
        'failedAssertions': [
          for (final a in failedAssertions) a.assertion.kind
        ],
        if (misconception != null) 'misconception': misconception,
        if (runtimeError != null) 'error': runtimeError!.code.id,
      };
}

/// Grades one submission against one item, entirely on device (`FR-M6-04`).
class Grader {
  const Grader({this.tolerancePx = 2, this.rasterScale = 0.5});

  /// §6.1: canvas raster diff, tolerance ±2 px.
  final int tolerancePx;

  /// Grading rasterises at half resolution by default. The tolerance is scaled with it, so
  /// the verdict means the same thing; what changes is that a 2 GB phone does a quarter of
  /// the work.
  final double rasterScale;

  Verdict grade(Item item, Response response, {String locale = 'fr'}) {
    return switch (response) {
      ChoiceResponse(:final index) => _gradeChoice(item, index),
      NumericResponse(:final value) => _gradeNumeric(item, value),
      ProgramResponse(:final program) => _gradeProgram(item, program),
    };
  }

  // -------------------------------------------------------------------------------------

  Verdict _gradeChoice(Item item, int index) {
    if (index < 0 || index >= item.choices.length) {
      return Verdict(
        passed: false,
        itemId: item.id,
        itemVersion: item.version,
        situation: DiagnosticSituation.wrongChoice,
      );
    }
    final chosen = item.choices[index];
    return Verdict(
      passed: chosen.correct,
      itemId: item.id,
      itemVersion: item.version,
      situation: chosen.correct ? null : DiagnosticSituation.wrongChoice,
      misconception: chosen.correct ? null : chosen.misconception,
    );
  }

  Verdict _gradeNumeric(Item item, num value) {
    // A numeric T6 states its answer as the single correct choice's label, so that the
    // answer is authored content and is reviewed like every other string.
    final correct = item.choices.where((c) => c.correct);
    final expected = correct.isEmpty
        ? null
        : num.tryParse(correct.first.labelKeys['fr'] ?? '');
    final passed = expected != null && expected == value;
    return Verdict(
      passed: passed,
      itemId: item.id,
      itemVersion: item.version,
      situation: passed ? null : DiagnosticSituation.wrongChoice,
      messageArgs: {
        'actual': '$value',
        if (expected != null) 'expected': '$expected'
      },
    );
  }

  Verdict _gradeProgram(Item item, Program program) {
    // --- structural first: it is cheap, and it explains better ---------------------------
    final failed = <AssertionResult>[];
    for (final a in item.assertions) {
      final result = a.check(program);
      if (!result.passed) failed.add(result);
    }

    if (item.blockBudget != null) {
      final n = blockCount(program);
      if (n > item.blockBudget!) {
        return Verdict(
          passed: false,
          itemId: item.id,
          itemVersion: item.version,
          situation: DiagnosticSituation.tooManyBlocks,
          messageArgs: {'actual': '$n', 'expected': '${item.blockBudget}'},
        );
      }
    }

    // --- behavioural ---------------------------------------------------------------------
    RasterMatch? behavioural;
    if (item.targetProgramSource != null) {
      final attemptCanvas = VectorCanvas();
      final trigger = _triggerFor(item.runTrigger);
      final run = runProgram(program, attemptCanvas,
          seed: item.seed, inputs: item.inputs, trigger: trigger);
      if (run.error != null) {
        return Verdict(
          passed: false,
          itemId: item.id,
          itemVersion: item.version,
          situation: DiagnosticSituation.programFailed,
          runtimeError: run.error,
        );
      }

      final targetCanvas = VectorCanvas();
      final targetProgram =
          parse(item.targetProgramSource!, KeywordTables.fr).program;
      runProgram(targetProgram, targetCanvas,
          seed: item.seed, inputs: item.inputs, trigger: trigger);

      behavioural = compareRaster(attemptCanvas, targetCanvas,
          tolerancePx: tolerancePx, scale: rasterScale);

      /* What the program PRINTED, which the canvas does not draw and the rasteriser
         therefore cannot see. Checked only when the target prints something: an item
         about a drawing must not start failing because a child added a message. */
      if (targetCanvas.output.isNotEmpty &&
          !_sameOutput(attemptCanvas.output, targetCanvas.output)) {
        return Verdict(
          passed: false,
          itemId: item.id,
          itemVersion: item.version,
          situation: DiagnosticSituation.wrongOutput,
          behavioural: behavioural,
          messageArgs: {
            'actual': attemptCanvas.output.join(', '),
            'expected': targetCanvas.output.join(', '),
            'actualCount': '${attemptCanvas.output.length}',
            'expectedCount': '${targetCanvas.output.length}',
          },
        );
      }

      // The path signature is the second behavioural signal, and the one that makes a
      // different-but-valid drawing order pass. It is already order-insensitive in M4.
      final samePath =
          attemptCanvas.pathSignature() == targetCanvas.pathSignature();

      // The turtle's own final position and heading, when the item asks for it. Checked
      // before the marks, because "you drew it right but did not come home" is a different
      // sentence from "your figure is wrong" and the child deserves the right one.
      if (item.requireFinalPose) {
        const tolerance = 0.5;
        final offBy = (attemptCanvas.positionX - targetCanvas.positionX).abs() +
            (attemptCanvas.positionY - targetCanvas.positionY).abs();
        final headingOff =
            (attemptCanvas.direction - targetCanvas.direction).abs() % 360;
        if (offBy > tolerance ||
            (headingOff > tolerance && headingOff < 360 - tolerance)) {
          return Verdict(
            passed: false,
            itemId: item.id,
            itemVersion: item.version,
            situation: DiagnosticSituation.endedElsewhere,
            behavioural: behavioural,
            messageArgs: _shapeArgs(attemptCanvas, targetCanvas),
          );
        }
      }

      /* The path signature rescues a different-but-valid drawing ORDER (`FR-M6-02`) and
         nothing else. It is geometry only, so on its own it also waved through a right
         shape in the wrong colour, the wrong pen width, the wrong paper and the wrong
         page size — every one of World 3's five concepts. It may now rescue the ink and
         only the ink. */
      if (!behavioural.matches && !(samePath && behavioural.pageMatches)) {
        return Verdict(
          passed: false,
          itemId: item.id,
          itemVersion: item.version,
          situation: _situationFor(behavioural),
          behavioural: behavioural,
          messageArgs: _shapeArgs(attemptCanvas, targetCanvas),
        );
      }
    }

    if (failed.isNotEmpty) {
      return Verdict(
        passed: false,
        itemId: item.id,
        itemVersion: item.version,
        situation: DiagnosticSituation.structureMissing,
        failedAssertions: failed,
        behavioural: behavioural,
        messageArgs: failed.first.messageArgs,
      );
    }

    // --- rubric (T9) ---------------------------------------------------------------------
    if (item.type == ItemType.t9OpenBuild) {
      final unmet = <AssertionResult>[];
      for (final line in item.rubric) {
        final result = line.assertion.check(program);
        if (!result.passed) unmet.add(result);
      }
      if (unmet.isNotEmpty) {
        return Verdict(
          passed: false,
          itemId: item.id,
          itemVersion: item.version,
          situation: DiagnosticSituation.structureMissing,
          failedAssertions: unmet,
          messageArgs: unmet.first.messageArgs,
        );
      }
    }

    return Verdict(
        passed: true,
        itemId: item.id,
        itemVersion: item.version,
        behavioural: behavioural);
  }

  /// The item's trigger, as the authoring tools write it.
  ///
  /// A string in the pack rather than an object, because a content pack is JSON and a
  /// sealed class does not survive a round trip through a file a teacher can sideload.
  RunTrigger _triggerFor(String spec) {
    if (spec == 'any') return const AnyTrigger();
    if (spec == 'clicked') return const Clicked();
    if (spec.startsWith('key:')) return KeyPressed(spec.substring(4));
    return const FlagClicked();
  }

  /// Printed lines, compared as a sequence.
  ///
  /// Order matters: "write your across number then your down number" is the whole of the
  /// instruction, and a child who prints them the other way round has not done it. The
  /// texts are trimmed because trailing space is not a mistake anybody meant to make.
  bool _sameOutput(List<String> attempt, List<String> target) {
    if (attempt.length != target.length) return false;
    for (var i = 0; i < target.length; i++) {
      if (attempt[i].trim() != target[i].trim()) return false;
    }
    return true;
  }

  DiagnosticSituation _situationFor(RasterMatch m) {
    /* Order matters, and it is the order a child would notice things in. The ink is
       checked first: if the figure is not where the target is, saying "wrong colour"
       would be true and useless. Once the ink lands, the remaining differences are the
       pen, the paper and the page, and each gets its own sentence. */
    if (m.drewTooLittle) return DiagnosticSituation.drewTooLittle;
    if (m.drewTooMuch) return DiagnosticSituation.drewTooMuch;
    final inkIsRight = m.attemptCoverage >= 0.98 && m.targetCoverage >= 0.98;
    if (inkIsRight && !m.sizeMatches) return DiagnosticSituation.wrongCanvasSize;
    if (inkIsRight && !m.backgroundMatches) {
      return DiagnosticSituation.wrongBackground;
    }
    if (inkIsRight && !m.widthMatches) return DiagnosticSituation.wrongWidth;
    if (inkIsRight && !m.penMatches) return DiagnosticSituation.wrongColour;
    return DiagnosticSituation.wrongShape;
  }

  /// The numbers that let an authored message name the observable difference.
  ///
  /// "Ta figure a 4 côtés, la cible en a 6" is only possible because the grader counts
  /// both. A grader that returned a boolean would force every author to write "Incorrect".
  Map<String, String> _shapeArgs(VectorCanvas attempt, VectorCanvas target) => {
        'actual': '${attempt.segmentCount}',
        'expected': '${target.segmentCount}',
        'actualColours':
            '${attempt.segments.map((s) => s.color).toSet().length}',
        'expectedColours':
            '${target.segments.map((s) => s.color).toSet().length}',
      };
}
