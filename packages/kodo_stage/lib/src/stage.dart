/// The scène (FR-M4-01, FR-M4-03, FR-M4-04, FR-M4-05).
///
/// A sprite stage with a centre origin, implementing the same [Surface] contract as the
/// canvas so that one interpreter drives both. The `Do not` of the M4 prompt is explicit:
/// the stage and the canvas may not diverge into two code paths for the same primitive —
/// so movement, pen state and the jump commands are inherited from the shared turtle model
/// and only the coordinate frame and the sprite model are new here.
library;


import 'package:kodo_lang/kodo_lang.dart';

import 'consent.dart';
import 'sensing.dart';

/// One of a sprite's looks.
class Costume {
  const Costume(this.id, this.nameKey, {this.widthPx = 64, this.heightPx = 64});
  final String id;

  /// A localisation key, never a display string (`FR-M15-04`).
  final String nameKey;
  final int widthPx;
  final int heightPx;
}

/// The graphic effects of `SC p.7`.
///
/// Concept C10.5's misconception is *"effects are permanent"*, so the model keeps them as
/// a separate, clearable layer over the costume rather than baking them in.
class GraphicEffects {
  GraphicEffects({
    this.colour = 0,
    this.fisheye = 0,
    this.whirl = 0,
    this.pixelate = 0,
    this.brightness = 0,
    this.ghost = 0,
  });

  double colour, fisheye, whirl, pixelate, brightness, ghost;

  bool get isClear =>
      colour == 0 &&
      fisheye == 0 &&
      whirl == 0 &&
      pixelate == 0 &&
      brightness == 0 &&
      ghost == 0;

  /// What `initialise` does to the effects, and what the "clear effects" block does.
  void clear() {
    colour = fisheye = whirl = pixelate = brightness = ghost = 0;
  }

  Map<String, double> toJson() => {
        'colour': colour,
        'fisheye': fisheye,
        'whirl': whirl,
        'pixelate': pixelate,
        'brightness': brightness,
        'ghost': ghost,
      };
}

/// A lutin. Concept C10.1: *a sprite is an object*, and its misconception is *"there can be
/// only one character"* — which is why the stage holds a list and never a singleton.
class Sprite {
  Sprite({
    required this.id,
    required this.nameKey,
    List<Costume>? costumes,
    this.x = 0,
    this.y = 0,
    this.heading = 90,
    this.size = 100,
    this.visible = true,
      /* Growable, and a copy. The default was `const []`, which meant the stage's own
         Tika could never be given a costume — a sprite whose looks cannot change makes
         World 10 unusable, and the failure was an "unmodifiable list" a child would never
         see and an author could not explain. */
  }) : costumes = List<Costume>.of(costumes ?? const []);

  final String id;
  final String nameKey;
  final List<Costume> costumes;

  /// Centre-origin coordinates: 0,0 is the middle of the stage (`SC p.9`).
  double x, y;

  /// Degrees. On the stage, 90 points right — the convention of the block tradition, and
  /// deliberately *not* the canvas's 0-is-up, because a child on the stage reads a
  /// direction dial, not a protractor.
  double heading;

  /// Percentage.
  double size;
  bool visible;

  int costumeIndex = 0;
  final GraphicEffects effects = GraphicEffects();

  Costume? get costume =>
      costumes.isEmpty ? null : costumes[costumeIndex % costumes.length];

  /// Concept C10.2 — animation is switching costumes, not playing a video.
  void nextCostume() {
    if (costumes.isEmpty) return;
    costumeIndex = (costumeIndex + 1) % costumes.length;
  }

  void switchCostume(String id) {
    final i = costumes.indexWhere((c) => c.id == id);
    if (i >= 0) costumeIndex = i;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': nameKey,
        'x': x,
        'y': y,
        'heading': heading,
        'size': size,
        'visible': visible,
        'costume': costume?.id,
        'effects': effects.toJson(),
      };
}

/// A stage backdrop. Concept C10.4's misconception is *"the backdrop is a sprite"*, so it
/// is a distinct type with no position and no heading — the model itself teaches it.
class Backdrop {
  const Backdrop(this.id, this.nameKey, {this.imported = false});
  final String id;
  final String nameKey;

  /// True when a guardian allowed an import from the device gallery. Camera capture is
  /// absent from v1 entirely (`ConsentGate.removedFromV1`, PO decision D-007).
  final bool imported;
}

/// A sound the project can play.
class SoundAsset {
  const SoundAsset(this.id, this.nameKey, {this.recorded = false});
  final String id;
  final String nameKey;

  /// True when it came from the microphone, which requires guardian consent.
  final bool recorded;
}

/// The scène.
///
/// Implements [Surface] so the same interpreter runs here. Movement is delegated to the
/// selected sprite; the pen draws onto the stage in the same segment model the canvas
/// uses, so `pathSignature` means the same thing on both surfaces and the grader needs no
/// special case.
/// One thing the score recorded: a drum hit or a note, and how long it lasted.
///
/// Recorded rather than played. Grading listens to the score and never to a speaker: a
/// world that teaches *"sounds & drums"* has to be markable on a device with the volume
/// off, in a classroom, with thirty children in it.
class SoundEvent {
  const SoundEvent(this.kind, this.value, this.beats);

  /// `sound`, `drum` or `note`.
  final String kind;

  /// The sound's name, the drum's number, or the note's pitch.
  final Object value;
  final num beats;

  @override
  String toString() => '$kind:$value×$beats';

  @override
  bool operator ==(Object other) =>
      other is SoundEvent &&
      other.kind == kind &&
      other.value == value &&
      other.beats == beats;

  @override
  int get hashCode => Object.hash(kind, value, beats);
}

/// What the child said, and when. A speech bubble is a drawing a grader can read.
class SaidLine {
  const SaidLine(this.spriteId, this.text);
  final String spriteId;
  final String text;

  @override
  String toString() => '$spriteId: $text';
}

class SpriteStage extends HeadlessCanvas
    with TurtleSensing
    implements StageSurface {
  SpriteStage({
    super.width = 480,
    super.height = 360,
    ConsentGate? consent,
  }) : consent = consent ?? ConsentGate() {
    final tika = Sprite(id: 'tika', nameKey: 'sprite.tika');
    sprites.add(tika);
    _selected = tika;
    // Centre origin: the turtle model's own reset puts it at width/2, height/2, which IS
    // the centre. The stage simply reads coordinates relative to it.
    center();
  }

  final ConsentGate consent;
  final List<Sprite> sprites = [];
  final List<Backdrop> backdrops = [const Backdrop('blank', 'backdrop.blank')];
  final List<SoundAsset> sounds = [];
  final List<String> playedSounds = [];

  /// The score, in order (`FR-M21-04`).
  final List<SoundEvent> score = [];

  /// Speech bubbles, in order.
  final List<SaidLine> saidLines = [];

  int backdropIndex = 0;
  late Sprite _selected;

  Sprite get selected => _selected;

  Backdrop get backdrop => backdrops[backdropIndex % backdrops.length];

  /// The stage reduced to what an item compares (`FR-M21-04`).
  ///
  /// A costume leaves no ink, so the grader's raster comparison cannot see it. This is
  /// the second signal, read off the selected sprite and the stage itself.
  StageState get state => StageState(
        costumeNumber: costumeNumber,
        backdropId: backdrop.id,
        score: [for (final event in score) event.toString()],
        said: [for (final line in saidLines) line.text],
        effects: {
          for (final e in _selected.effects.toJson().entries)
            if (e.value != 0) e.key: e.value,
        },
      );

  /// Builds the stage an item asked for (`StageSetup`).
  ///
  /// Sprites with no costumes cannot change their look, so a costume item that did not
  /// say how many it wanted would be graded on a stage where `costumesuivant` does
  /// nothing — and every answer, right or wrong, would pass.
  static SpriteStage from(StageSetup setup) {
    final stage = SpriteStage();
    stage.sprites.clear();
    for (final id in setup.sprites) {
      stage.addSprite(id, 'sprite.$id', costumes: [
        for (var i = 1; i <= setup.costumes; i++)
          Costume('$id-$i', 'costume.$id.$i'),
      ]);
    }
    stage.select(setup.sprites.first);
    for (final id in setup.backdrops) {
      stage.backdrops.add(Backdrop(id, 'backdrop.$id'));
    }
    return stage;
  }

  @override
  void selectSprite(String id) => select(id);

  void select(String spriteId) {
    final s = sprites.where((s) => s.id == spriteId);
    if (s.isNotEmpty) _selected = s.first;
  }

  Sprite addSprite(String id, String nameKey, {List<Costume>? costumes}) {
    final sprite = Sprite(id: id, nameKey: nameKey, costumes: costumes);
    sprites.add(sprite);
    return sprite;
  }

  /// Stage coordinates for the selected sprite: centre origin, y upwards.
  ///
  /// The turtle model underneath keeps top-left origin with y downwards, because that is
  /// what the canvas teaches in World 4. Converting here rather than forking the model is
  /// what keeps the two surfaces one implementation.
  double get stageX => positionX - width / 2;
  double get stageY => height / 2 - positionY;

  void goToStage(num x, num y) => go(x + width / 2, height / 2 - y);

  /// Import a backdrop from the device gallery. Refused without guardian consent.
  CapabilityRefused? importBackdrop(String id, String nameKey) {
    if (!consent.allows(Capability.imageImport)) {
      return CapabilityRefused(
          Capability.imageImport, consent.stateOf(Capability.imageImport));
    }
    backdrops.add(Backdrop(id, nameKey, imported: true));
    return null;
  }

  /// Record a sound. Refused without guardian consent.
  CapabilityRefused? recordSound(String id, String nameKey) {
    if (!consent.allows(Capability.microphone)) {
      return CapabilityRefused(
          Capability.microphone, consent.stateOf(Capability.microphone));
    }
    sounds.add(SoundAsset(id, nameKey, recorded: true));
    return null;
  }

  /// Capture from the camera.
  ///
  /// Always refused. There is no consent that unlocks it in v1 and no parameter that
  /// changes that — the refusal is the implementation (PO decision D-007).
  CapabilityRefused captureFromCamera() =>
      CapabilityRefused(Capability.camera, consent.stateOf(Capability.camera));

  /// Concept C10.3's misconception is *"the sound plays after the program ends"*, so a
  /// play is recorded at the moment it executes, in order, and the test asserts the order.
  @override
  void playSound(String id) {
    playedSounds.add(id);
    score.add(SoundEvent('sound', id, 0));
  }

  // --- the rest of StageSurface (D-014 / FR-M21-04) -------------------------------------

  @override
  void nextCostume() {
    final costumes = _selected.costumes;
    if (costumes.isEmpty) return;
    _selected.costumeIndex = (_selected.costumeIndex + 1) % costumes.length;
  }

  @override
  void setCostume(int number) {
    final costumes = _selected.costumes;
    if (costumes.isEmpty) return;
    /* One-based, because a child counts from one and the costume picker shows 1, 2, 3.
       Out of range wraps rather than failing: "costume 7" of three costumes is a child
       exploring, not a child making a mistake worth an error message. */
    final zero = (number - 1) % costumes.length;
    _selected.costumeIndex = zero < 0 ? zero + costumes.length : zero;
  }

  @override
  int get costumeNumber => _selected.costumeIndex + 1;

  @override
  void setBackdrop(String name) => switchBackdrop(name);

  @override
  void setEffect(String name, num value) {
    final v = value.toDouble();
    switch (name.toLowerCase()) {
      case 'couleur':
      case 'colour':
      case 'color':
        _selected.effects.colour = v;
      case 'oeildepoisson':
      case 'fisheye':
        _selected.effects.fisheye = v;
      case 'tourbillon':
      case 'whirl':
        _selected.effects.whirl = v;
      case 'pixel':
      case 'pixelate':
        _selected.effects.pixelate = v;
      case 'luminosité':
      case 'luminosite':
      case 'brightness':
        _selected.effects.brightness = v;
      case 'fantôme':
      case 'fantome':
      case 'ghost':
        _selected.effects.ghost = v;
      // An effect nobody has heard of is ignored rather than fatal: the names are content
      // and a pack may ship its own, so an unknown one is a missing asset, not a bug.
    }
  }

  @override
  void clearEffects() => _selected.effects.clear();

  @override
  void say(String text) => saidLines.add(SaidLine(_selected.id, text));

  @override
  void playDrum(int drum, num beats) =>
      score.add(SoundEvent('drum', drum, beats));

  @override
  void playNote(num pitch, num beats) =>
      score.add(SoundEvent('note', pitch, beats));

  /* SensingSurface (`FR-M21-03`) comes from `TurtleSensing`, and used to live here.
     World 8 needed `touchebord` under the grader's canvas, which is not a stage — and the
     answer turned out not to need one, because the sensor was geometry all along. Two
     copies of that geometry would be two answers to the same question, which the M4
     prompt forbids, so there is one and both surfaces mix it in. Keys and the pointer are
     fields of the mixin; a Studio stage writes them from the real keyboard and mouse, and
     an item writes them with `applyScene`. */

  void switchBackdrop(String id) {
    final i = backdrops.indexWhere((b) => b.id == id);
    if (i >= 0) backdropIndex = i;
  }

  @override
  void reset() {
    super.reset();
    for (final s in sprites) {
      s.effects.clear();
      s.costumeIndex = 0;
      s.visible = true;
    }
    backdropIndex = 0;
    playedSounds.clear();
  }

  Map<String, Object?> toJson() => {
        'width': width,
        'height': height,
        'backdrop': backdrop.id,
        'sprites': [for (final s in sprites) s.toJson()],
        'sounds': [for (final s in sounds) s.id],
      };
}
