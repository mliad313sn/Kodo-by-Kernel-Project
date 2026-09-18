/// Accessibility (M16).
///
/// *"Do not treat accessibility as a phase-four task; the block-family shapes must be
/// decided before the art is drawn."* They were: `BlockFamily` in M2 carries a colour, an
/// icon and a silhouette, and M2's tests assert all 45 family pairs stay distinguishable
/// with colour removed. This file holds what the other modules could not: the preference
/// model, the layout budget at 200 % text, the keyboard map, and the screen-reader labels
/// for a canvas.
library;

import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';

import 'strings.dart';

// ---------------------------------------------------------------------------------------
// Preferences (FR-M16-03)
// ---------------------------------------------------------------------------------------

/// A reading font.
enum ReadingFont {
  /// The default. A humanist sans with unambiguous `l`, `I` and `1`.
  standard('Atkinson Hyperlegible'),

  /// `FR-M16-03`'s dyslexia-friendly option: weighted bottoms, wider spacing,
  /// distinguishable mirror pairs (b/d, p/q).
  dyslexiaFriendly('OpenDyslexic');

  const ReadingFont(this.family);
  final String family;
}

/// What a child or their guardian has set.
class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.textScale = 1.0,
    this.font = ReadingFont.standard,
    this.reducedMotion = false,
    this.narrationOn = true,
    this.highContrast = false,
  });

  /// `FR-M16-03`: 100 % to 200 %.
  final double textScale;

  static const minimumTextScale = 1.0;
  static const maximumTextScale = 2.0;

  final ReadingFont font;

  /// Reduced motion. The same flag M4's `RenderBudget` reads, so a child who sets it once
  /// gets it on the canvas as well as in the interface.
  final bool reducedMotion;

  /// `FR-M16-02` narrates every instruction, question and error. A child may turn the
  /// voice off; the **recordings still have to exist**, which is a publish gate, not a
  /// preference.
  final bool narrationOn;

  final bool highContrast;

  bool get textScaleIsSupported =>
      textScale >= minimumTextScale && textScale <= maximumTextScale;

  AccessibilityPreferences copyWith({
    double? textScale,
    ReadingFont? font,
    bool? reducedMotion,
    bool? narrationOn,
    bool? highContrast,
  }) =>
      AccessibilityPreferences(
        textScale: textScale ?? this.textScale,
        font: font ?? this.font,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        narrationOn: narrationOn ?? this.narrationOn,
        highContrast: highContrast ?? this.highContrast,
      );
}

// ---------------------------------------------------------------------------------------
// Layout at 200 % (FR-M16-03)
// ---------------------------------------------------------------------------------------

/// A box on a screen that has to survive text scaling.
class ScalableBox {
  const ScalableBox({
    required this.name,
    required this.baseFontDp,
    required this.heightDp,
    required this.widthDp,
    required this.lines,
    this.scrollsVertically = false,
  });

  final String name;
  final double baseFontDp;
  final double heightDp;
  final double widthDp;

  /// How many lines of text the box is designed to hold.
  final int lines;

  /// A box that scrolls cannot clip; it can only get longer. §9.3's rule is that the
  /// *controls* never scroll and the *reading* may.
  final bool scrollsVertically;

  /// Line height as a multiple of font size — 1.4 is the readable floor for a child.
  static const lineHeightFactor = 1.4;

  double requiredHeightAt(double scale) =>
      baseFontDp * scale * lineHeightFactor * lines;

  bool survivesAt(double scale) =>
      scrollsVertically || requiredHeightAt(scale) <= heightDp;
}

/// A box that breaks when text is scaled up.
class LayoutBreak {
  const LayoutBreak(this.box, this.scale, this.needed, this.available);
  final String box;
  final double scale;
  final double needed;
  final double available;

  @override
  String toString() => '$box at ${(scale * 100).round()} %: needs '
      '${needed.toStringAsFixed(0)} dp, has ${available.toStringAsFixed(0)} dp';
}

/// Checks every box from 100 % to 200 %, the range `FR-M16-03` commits to.
List<LayoutBreak> checkTextScaling(Iterable<ScalableBox> boxes) {
  final breaks = <LayoutBreak>[];
  for (final box in boxes) {
    for (var step = 0; step <= 10; step++) {
      final scale = AccessibilityPreferences.minimumTextScale +
          step *
              (AccessibilityPreferences.maximumTextScale -
                  AccessibilityPreferences.minimumTextScale) /
              10;
      if (!box.survivesAt(scale)) {
        breaks.add(LayoutBreak(
            box.name, scale, box.requiredHeightAt(scale), box.heightDp));
        break; // one report per box: the first scale that breaks it is the finding
      }
    }
  }
  return breaks;
}

// ---------------------------------------------------------------------------------------
// Keyboard operation (FR-M16-04)
// ---------------------------------------------------------------------------------------

/// Everything a child can do in the editor.
///
/// `FR-M16-04` requires **complete** keyboard operation on desktop, *"including block
/// placement"* — the one usually left out, because placing a block is thought of as a
/// drag. A test asserts that every action here has a key, which is what makes "complete"
/// checkable rather than aspirational.
enum EditorAction {
  focusPalette,
  focusScript,
  nextBlock,
  previousBlock,
  nextFamily,
  previousFamily,
  placeBlock,
  deleteBlock,
  moveBlockUp,
  moveBlockDown,
  indentBlock,
  outdentBlock,
  editArgument,
  run,
  stop,
  stepOnce,
  undo,
  redo,
  toggleTextView,
  openHelp,
  announceCanvas,
}

/// A key, as a screen would print it.
class KeyBinding {
  const KeyBinding(this.keys, {this.note});

  /// e.g. `['Ctrl', 'Enter']`.
  final List<String> keys;
  final String? note;

  String get printed => keys.join(' + ');
}

/// The desktop keyboard map.
///
/// Arrow keys move, Enter places, Space runs the thing under focus. Nothing here needs a
/// chord a child cannot reach one-handed, because a child who is using the keyboard is
/// often using it *because* two hands is not an option.
const Map<EditorAction, KeyBinding> desktopKeyMap = {
  EditorAction.focusPalette: KeyBinding(['F6']),
  EditorAction.focusScript: KeyBinding(['F7']),
  EditorAction.nextBlock: KeyBinding(['↓']),
  EditorAction.previousBlock: KeyBinding(['↑']),
  EditorAction.nextFamily: KeyBinding(['→']),
  EditorAction.previousFamily: KeyBinding(['←']),
  EditorAction.placeBlock:
      KeyBinding(['Enter'], note: 'places the focused block after the caret'),
  EditorAction.deleteBlock: KeyBinding(['Delete']),
  EditorAction.moveBlockUp: KeyBinding(['Alt', '↑']),
  EditorAction.moveBlockDown: KeyBinding(['Alt', '↓']),
  EditorAction.indentBlock: KeyBinding(['Tab']),
  EditorAction.outdentBlock: KeyBinding(['Shift', 'Tab']),
  EditorAction.editArgument: KeyBinding(['F2']),
  EditorAction.run: KeyBinding(['Ctrl', 'Enter']),
  EditorAction.stop: KeyBinding(['Escape']),
  EditorAction.stepOnce: KeyBinding(['F10']),
  EditorAction.undo: KeyBinding(['Ctrl', 'Z']),
  EditorAction.redo: KeyBinding(['Ctrl', 'Y']),
  EditorAction.toggleTextView: KeyBinding(['Ctrl', 'T']),
  EditorAction.openHelp: KeyBinding(['F1']),
  EditorAction.announceCanvas: KeyBinding(['Ctrl', 'D']),
};

// ---------------------------------------------------------------------------------------
// Screen-reader labels (FR-M16-04)
// ---------------------------------------------------------------------------------------

/// What a screen reader says about the canvas.
///
/// M4 already produces this sentence — `describeCanvas` — because the canvas description
/// also feeds the SVG `<desc>` and the grading diagnostics. There is no second describer
/// here for the same reason there is no second parser: two descriptions of one picture
/// drift, and the one that drifts is always the one only blind children read.
String canvasAnnouncement(HeadlessCanvas canvas,
        {UiLocale locale = UiLocale.fr}) =>
    describeCanvas(canvas, locale: locale.code);

/// The label for one block, built from the catalogue rather than from the block's own
/// English name.
String blockLabel({
  required StringCatalogue catalogue,
  required String familyKey,
  required String keyword,
  required int position,
  required int total,
  UiLocale locale = UiLocale.fr,
}) =>
    catalogue.render('a11y.block_label', locale, {
      'keyword': keyword,
      'family': catalogue.render(familyKey, locale),
      'position': '$position',
      'total': '$total',
    });

// ---------------------------------------------------------------------------------------
// Contrast (FR-M16-01)
// ---------------------------------------------------------------------------------------

/// A pair that fails WCAG 2.2 AA.
class ContrastFailure {
  const ContrastFailure(this.what, this.ratio, this.required_);
  final String what;
  final double ratio;
  final double required_;

  @override
  String toString() =>
      '$what: ${ratio.toStringAsFixed(2)}:1, needs ${required_.toStringAsFixed(1)}:1';
}

/// WCAG 2.2 AA floors.
const bodyTextContrast = 4.5;
const largeTextContrast = 3.0;
const nonTextContrast = 3.0;

/// Audits foreground/background pairs.
List<ContrastFailure> auditContrast(
    Map<String, (NamedColour, NamedColour)> pairs,
    {double floor = bodyTextContrast}) {
  final failures = <ContrastFailure>[];
  for (final entry in pairs.entries) {
    final (foreground, background) = entry.value;
    final ratio = foreground.contrastAgainst(background);
    if (ratio < floor) {
      failures.add(ContrastFailure(entry.key, ratio, floor));
    }
  }
  return failures;
}
