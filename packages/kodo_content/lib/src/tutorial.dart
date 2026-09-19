/// The tutorial engine (M5).
///
/// *"You are building the teacher's voice: 90-to-180-second guided steps that a child can
/// follow without being able to read well."*
///
/// A tutorial is **data** (`FR-M5-01`). The player below drives the editors through a
/// narrow host interface and can spotlight, demonstrate, wait and detect success — and it
/// can do none of those things to a child's own project, because it is structurally
/// incapable of touching one (`FR-M5-05`).
library;

import 'package:kodo_lang/kodo_lang.dart';

import 'readability.dart';

/// The three beats of §4.2. Every step is one of them, and they run in this order.
enum Beat {
  /// *Je regarde.* Tika executes 2–6 blocks; the child watches. Never more than two new
  /// ideas in one step.
  jeRegarde,

  /// *On fait ensemble.* The child completes a partly built program — one hole,
  /// unambiguous, impossible to get wrong twice.
  onFaitEnsemble,

  /// *Je fais.* The child builds from zero against a target, graded.
  jeFais,
}

/// What the child has to do for the step to complete.
enum ExpectedAction {
  /// Nothing; the step demonstrates and moves on when the demonstration ends.
  watch,

  /// Place a specific block.
  placeBlock,

  /// Change a number inside a block.
  editNumber,

  /// Press run.
  runProgram,

  /// Build a program that satisfies [TutorialStep.successCondition].
  buildProgram,

  /// Flip the block/text toggle.
  toggleView,
}

/// A UI element a step can spotlight. A closed list, because "spotlight whatever you like"
/// is how a tutorial ends up pointing at a button that moved.
enum SpotlightTarget {
  palette,
  scriptArea,
  runButton,
  stopButton,
  speedControl,
  canvas,
  inspector,
  blockTextToggle,
  paletteFamilyMovement,
  paletteFamilyControl,
  paletteFamilyPen,
}

/// How a demonstration lands (`FR-M5-02`).
///
/// A demo that simply appears is a magic trick: blocks were somewhere else, now they are
/// here, and a child has learned that the computer did it. Ghosted first and real after is
/// a demonstration — *this is what is about to happen*, then it happens — and it is the
/// same idea as `FR-M4-08`'s ghosted path, one layer up.
enum DemoPhase { ghosted, real }

/// What a step asks the child to do, in their own words (`FR-M5-02`).
///
/// One per [ExpectedAction], because the requirement is a *single* call to action and the
/// surest way to have one is to have nowhere to put a second. An author may override the
/// words; they may not add a second button.
const Map<ExpectedAction, Map<String, String>> defaultCallsToAction = {
  ExpectedAction.watch: {'fr': 'Continuer', 'en': 'Next'},
  ExpectedAction.placeBlock: {'fr': 'Pose le bloc', 'en': 'Put the block'},
  ExpectedAction.editNumber: {'fr': 'Écris le nombre', 'en': 'Write the number'},
  ExpectedAction.runProgram: {'fr': 'Appuie sur le vert', 'en': 'Press green'},
  ExpectedAction.buildProgram: {'fr': 'À toi', 'en': 'Your turn'},
  ExpectedAction.toggleView: {'fr': 'Change de vue', 'en': 'Switch the view'},
};

/// One 90-to-180-second step.
class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.beat,
    required this.narrationKeys,
    required this.audioKeys,
    required this.expectedAction,
    this.spotlight,
    this.demoProgramSource,
    this.successCondition,
    this.retryHintKeys = const {},
    this.newIdeas = const [],
    this.callToActionKeys = const {},
  });

  final String id;
  final Beat beat;

  /// The words, per locale. Text is **always visible** even when the audio plays
  /// (`FR-M5-03`), so this is never optional.
  final Map<String, String> narrationKeys;

  /// The recording, per locale. A missing recording fails the content publish gate, not
  /// the runtime (`FR-M5-03` and the M5 prompt's acceptance test 2).
  final Map<String, String> audioKeys;

  final ExpectedAction expectedAction;
  final SpotlightTarget? spotlight;

  /// Blocks Tika animates into place, as source. Ghosted, then real.
  final String? demoProgramSource;

  /// How the player knows the child did it. Required for anything but [ExpectedAction.watch]
  /// — the M5 prompt's `Do not` is explicit: no step that says *"maintenant, essaie"*
  /// without a defined success condition.
  final SuccessCondition? successCondition;

  final Map<String, String> retryHintKeys;

  /// The concepts this step introduces. §4.2 caps a *Je regarde* beat at two new ideas.
  final List<String> newIdeas;

  /// The words on the one thing the child can press (`FR-M5-02`). Empty takes the default
  /// for [expectedAction].
  final Map<String, String> callToActionKeys;

  String narrationIn(String locale) =>
      narrationKeys[locale] ?? narrationKeys['fr'] ?? '';

  /// The single call to action, in [locale].
  ///
  /// A string and never a list, which is how "single" is guaranteed rather than reviewed:
  /// there is no shape in this class that can hold a second button.
  String callToActionIn(String locale) {
    final authored = callToActionKeys[locale] ?? callToActionKeys['fr'];
    if (authored != null && authored.trim().isNotEmpty) return authored;
    final fallback = defaultCallsToAction[expectedAction]!;
    return fallback[locale] ?? fallback['fr']!;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'beat': beat.name,
        'narration': narrationKeys,
        'audio': audioKeys,
        'action': expectedAction.name,
        if (spotlight != null) 'spotlight': spotlight!.name,
        if (demoProgramSource != null) 'demo': demoProgramSource,
        if (successCondition != null) 'success': successCondition!.toJson(),
        if (retryHintKeys.isNotEmpty) 'retry': retryHintKeys,
        if (newIdeas.isNotEmpty) 'newIdeas': newIdeas,
        'cta': {for (final l in const ['fr', 'en']) l: callToActionIn(l)},
      };

  static TutorialStep fromJson(Map<String, Object?> j) => TutorialStep(
        id: j['id']! as String,
        beat: Beat.values.byName(j['beat']! as String),
        narrationKeys:
            (j['narration']! as Map<String, Object?>).cast<String, String>(),
        audioKeys: (j['audio']! as Map<String, Object?>).cast<String, String>(),
        expectedAction: ExpectedAction.values.byName(j['action']! as String),
        spotlight: j['spotlight'] == null
            ? null
            : SpotlightTarget.values.byName(j['spotlight']! as String),
        demoProgramSource: j['demo'] as String?,
        successCondition: j['success'] == null
            ? null
            : SuccessCondition.fromJson(j['success']! as Map<String, Object?>),
        retryHintKeys: ((j['retry'] as Map<String, Object?>?) ?? const {})
            .cast<String, String>(),
        newIdeas:
            ((j['newIdeas'] as List<Object?>?) ?? const []).cast<String>(),
        callToActionKeys: ((j['cta'] as Map<String, Object?>?) ?? const {})
            .cast<String, String>(),
      );
}

/// How a step decides the child did the thing.
class SuccessCondition {
  const SuccessCondition(
      {this.opcodeId,
      this.minCount = 1,
      this.pathSignature,
      this.assignsVariable});

  /// The opcode the child must have placed or run.
  final String? opcodeId;

  /// How many of whichever checks are set. It is shared deliberately: a step that asks
  /// for two of something means two, whether the something is a block or a box.
  final int minCount;

  /// The drawing the child's program must produce.
  final String? pathSignature;

  /// A box the child must have filled — its name without the `$`, or `*` for any box.
  ///
  /// World 6 is the first world whose whole subject is not an opcode. `$côté = 60` is an
  /// assignment, and until this existed a *On fait ensemble* step could only check that
  /// the child had placed a `avance` — which is to say, it could check everything about
  /// the step except the thing the step was teaching. The same gap `D-014` recorded for
  /// the language, in the tutorial engine.
  final String? assignsVariable;

  /// Whether this condition checks anything at all.
  ///
  /// `SuccessCondition()` with every field left out is met by the empty program, so a
  /// step carrying one asks the child to act and then congratulates them for not acting.
  /// The gate below treats that as the same failure as having no condition, because to a
  /// child it is the same failure.
  bool get checksSomething =>
      opcodeId != null || pathSignature != null || assignsVariable != null;

  bool isMetBy(Program program, {String? producedSignature}) {
    if (opcodeId != null) {
      final n = walk(program)
          .whereType<Command>()
          .where((c) => c.opcode.id == opcodeId)
          .length;
      if (n < minCount) return false;
    }
    if (assignsVariable != null) {
      final n = walk(program)
          .whereType<Assign>()
          .where((a) => assignsVariable == '*' || a.variable == assignsVariable)
          .length;
      if (n < minCount) return false;
    }
    if (pathSignature != null && producedSignature != pathSignature) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() => {
        if (opcodeId != null) 'opcode': opcodeId,
        'minCount': minCount,
        if (pathSignature != null) 'path': pathSignature,
        if (assignsVariable != null) 'assigns': assignsVariable,
      };

  static SuccessCondition fromJson(Map<String, Object?> j) => SuccessCondition(
        opcodeId: j['opcode'] as String?,
        minCount: (j['minCount'] as int?) ?? 1,
        pathSignature: j['path'] as String?,
        assignsVariable: j['assigns'] as String?,
      );
}

/// A tutorial: an ordered list of steps for one concept.
class Tutorial {
  const Tutorial({
    required this.id,
    required this.conceptId,
    required this.steps,
    required this.closingConceptNameKeys,
    this.paletteScope = const [],
  });

  final String id;
  final String conceptId;
  final List<TutorialStep> steps;

  /// *"Every tutorial ends by naming the concept in words the child can repeat"*
  /// (`FR-M5-06`) — and this exact string is what later appears on the progress map and
  /// in the parent's weekly summary, so it is authored once and reused, never re-written.
  final Map<String, String> closingConceptNameKeys;

  final List<String> paletteScope;

  String conceptNameIn(String locale) =>
      closingConceptNameKeys[locale] ??
      closingConceptNameKeys['fr'] ??
      conceptId;

  Map<String, Object?> toJson() => {
        'id': id,
        'concept': conceptId,
        'steps': [for (final s in steps) s.toJson()],
        'conceptName': closingConceptNameKeys,
        'palette': paletteScope,
      };

  static Tutorial fromJson(Map<String, Object?> j) => Tutorial(
        id: j['id']! as String,
        conceptId: j['concept']! as String,
        steps: [
          for (final s in (j['steps']! as List<Object?>))
            TutorialStep.fromJson(s! as Map<String, Object?>),
        ],
        closingConceptNameKeys:
            (j['conceptName']! as Map<String, Object?>).cast<String, String>(),
        paletteScope:
            ((j['palette'] as List<Object?>?) ?? const []).cast<String>(),
      );
}

/// What the player asks of the editors. Deliberately narrow.
///
/// M5 drives M2, M3 and M4 through this and nothing else. The interface has no method for
/// opening, saving or naming a project — which is how `FR-M5-05` is guaranteed rather than
/// promised. A tutorial cannot modify a child's saved project because it has no way to
/// name one.
abstract class TutorialHost {
  void spotlight(SpotlightTarget? target);

  /// Animates ghost blocks into the scratch document, then lands them (`FR-M5-02`).
  ///
  /// Called twice per demo, once per [DemoPhase]. A host that ignores the ghosted phase
  /// still works; a host that never gets told about it cannot draw one.
  void demonstrate(Program program, DemoPhase phase);

  /// The program currently in the scratch document.
  Program get scratchProgram;

  /// The drawing the scratch document currently shows.
  String get scratchPathSignature;

  void narrate(String text, {String? audioKey});

  void restrictPalette(List<String> opcodeIds);
}

/// Where the player is.
enum PlayerState { notStarted, showing, waiting, stepComplete, finished }

/// Runs a [Tutorial] against a [TutorialHost].
class TutorialPlayer {
  TutorialPlayer({
    required this.tutorial,
    required this.host,
    required this.locale,
    this.firstPass = true,
  });

  final Tutorial tutorial;
  final TutorialHost host;
  final String locale;

  /// `FR-M5-04`: no step may be skipped on a first pass; all steps are skippable on a
  /// repeat. The flag is set by M7 from whether the concept has been seen, so a child
  /// revisiting a tutorial is not made to sit through it.
  final bool firstPass;

  int _index = 0;
  PlayerState _state = PlayerState.notStarted;
  int _retries = 0;

  int get stepIndex => _index;
  PlayerState get state => _state;
  bool get isFinished => _state == PlayerState.finished;
  TutorialStep? get current =>
      _index < tutorial.steps.length ? tutorial.steps[_index] : null;

  /// True when the child may skip. Never on a first pass.
  bool get canSkip => !firstPass;

  void start() {
    if (tutorial.paletteScope.isNotEmpty) {
      host.restrictPalette(tutorial.paletteScope);
    }
    _index = 0;
    _present();
  }

  void _present() {
    final step = current;
    if (step == null) {
      _state = PlayerState.finished;
      return;
    }
    _retries = 0;
    _state = PlayerState.showing;
    host.spotlight(step.spotlight);
    host.narrate(step.narrationIn(locale), audioKey: step.audioKeys[locale]);
    if (step.demoProgramSource != null) {
      final parsed = parse(step.demoProgramSource!,
          KeywordTables.of(locale == 'en' ? 'en' : 'fr'));
      host.demonstrate(parsed.program, DemoPhase.ghosted);
      host.demonstrate(parsed.program, DemoPhase.real);
    }
    _state = step.expectedAction == ExpectedAction.watch
        ? PlayerState.stepComplete
        : PlayerState.waiting;
  }

  /// Offers the retry hint after a wrong move. Returns null when there is nothing to say.
  String? retryHint() {
    final step = current;
    if (step == null) return null;
    _retries++;
    return step.retryHintKeys[locale] ?? step.retryHintKeys['fr'];
  }

  int get retries => _retries;

  /// Checks whether the child has done what the step asked.
  bool checkProgress() {
    final step = current;
    if (step == null) return false;
    if (step.expectedAction == ExpectedAction.watch) return true;
    final condition = step.successCondition;
    if (condition == null) return false;
    final met = condition.isMetBy(host.scratchProgram,
        producedSignature: host.scratchPathSignature);
    if (met) _state = PlayerState.stepComplete;
    return met;
  }

  /// Moves on. Refuses to skip an incomplete step on a first pass (`FR-M5-04`).
  bool advance({bool skip = false}) {
    if (skip && !canSkip) return false;
    if (!skip && _state != PlayerState.stepComplete) return false;
    _index++;
    _present();
    return true;
  }

  /// The one thing the child is asked to do right now (`FR-M5-02`).
  ///
  /// Null when the tutorial is over. Never a list: a step that offered two things would
  /// be a menu, and the whole point of the beat structure is that there is never a choice
  /// to make about what to do next.
  String? callToAction() => current?.callToActionIn(locale);

  /// The closing line: the concept, named in the child's own words (`FR-M5-06`).
  String closingLine() => tutorial.conceptNameIn(locale);
}

/// The publish gate for tutorials, mirroring M6's for items.
///
/// The M5 prompt's acceptance test 2 says a missing recording must fail the **content
/// publish gate, not the runtime**. That distinction is the whole design: content fails
/// loudly at authoring time, never quietly in front of a child.
class TutorialFailure {
  const TutorialFailure(this.tutorialId, this.stepId, this.rule, this.detail);
  final String tutorialId;
  final String? stepId;
  final String rule;
  final String detail;

  @override
  String toString() =>
      '$tutorialId${stepId == null ? '' : '/$stepId'}: [$rule] $detail';
}

List<TutorialFailure> checkTutorial(Tutorial tutorial,
    {List<String> locales = const ['fr', 'en']}) {
  final failures = <TutorialFailure>[];
  void fail(String? step, String rule, String detail) =>
      failures.add(TutorialFailure(tutorial.id, step, rule, detail));

  if (tutorial.steps.isEmpty) {
    fail(null, 'no-steps', 'a tutorial with no steps');
  }
  for (final locale in locales) {
    if ((tutorial.closingConceptNameKeys[locale] ?? '').trim().isEmpty) {
      fail(null, 'concept-name', 'no closing concept name in "$locale"');
    }
  }

  // §4.2: the three beats, in order, and a tutorial is three steps.
  final beats = tutorial.steps.map((s) => s.beat).toList();
  for (var i = 1; i < beats.length; i++) {
    if (beats[i].index < beats[i - 1].index) {
      fail(tutorial.steps[i].id, 'beat-order',
          'a ${beats[i].name} step follows a ${beats[i - 1].name} step');
    }
  }

  for (final step in tutorial.steps) {
    for (final locale in locales) {
      final line = (step.narrationKeys[locale] ?? '').trim();
      if (line.isEmpty) {
        fail(step.id, 'narration-localised', 'no narration in "$locale"');
        continue;
      }
      final readability = readabilityOf(line);
      if (!readability.passes) {
        fail(step.id, 'readability',
            '"$locale" narration ${readability.problems.join('; ')}');
      }
      final jargon = jargonIn(line);
      if (jargon.isNotEmpty) {
        fail(step.id, 'jargon',
            '"$locale" narration uses ${jargon.join(', ')} with no explanation');
      }
      if ((step.audioKeys[locale] ?? '').trim().isEmpty) {
        fail(step.id, 'audio-missing', 'no "$locale" recording');
      }
    }

    // The M5 prompt's Do-not, made mechanical.
    if (step.expectedAction != ExpectedAction.watch &&
        !(step.successCondition?.checksSomething ?? false)) {
      fail(step.id, 'no-success-condition',
          'asks the child to act with no way to tell whether they did');
    }
    if (step.expectedAction != ExpectedAction.watch &&
        step.retryHintKeys.isEmpty) {
      fail(step.id, 'no-retry-hint',
          'asks the child to act with nothing to say if they stall');
    }
    /* `FR-M5-02`, made mechanical. Three rules, and each one is a way a tutorial stops
       being a tutorial: a step with nothing to press, a step whose button is a paragraph,
       and a step that says "now you try" without pointing anywhere. */
    for (final locale in locales) {
      final cta = step.callToActionIn(locale).trim();
      if (cta.isEmpty) {
        fail(step.id, 'single-call-to-action', 'no call to action in "$locale"');
      } else if (cta.split(RegExp(r'\s+')).length > 4) {
        fail(step.id, 'call-to-action-length',
            '"$locale" call to action is ${cta.split(RegExp(r'\s+')).length} words; a button is four');
      }
    }
    if (step.expectedAction != ExpectedAction.watch && step.spotlight == null) {
      fail(step.id, 'spotlight-required',
          'asks the child to act without pointing at where');
    }
    if (step.beat == Beat.jeRegarde && step.newIdeas.length > 2) {
      fail(step.id, 'too-many-ideas',
          '${step.newIdeas.length} new ideas in one Je regarde step; §4.2 allows two');
    }
  }

  return failures;
}
