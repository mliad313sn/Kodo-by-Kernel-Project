/// Sensing, shared by every surface that has a turtle and some ink (`FR-M21-03`).
///
/// This started life inside `SpriteStage`, which was the only surface anyone expected to
/// need it: sensing is about keys and a pointer, and a headless canvas has neither. World
/// 8 proved that wrong. `tantque non touchebord { avance 10 }` is its second concept, and
/// the grader runs every item on a [VectorCanvas] — which answered `touchebord` with
/// "this surface is not a stage" and failed the item before it drew anything.
///
/// So the sensors split into two kinds, and only one of them ever needed a stage:
///
///  * **Geometry.** `touchebord` is the turtle's position against the canvas bounds, and
///    `touchecouleur` is the turtle's position against ink already on the page. Both are
///    computable by anything that knows where the turtle is and what it has drawn, which
///    is every surface KODO has. They are exact under grading, not approximated.
///  * **The world outside.** Keys and the pointer have no value of their own during a
///    graded run, so they are *authored*, the way `seed` and `inputs` already are: an item
///    says which keys are held and where the pointer is, and every run of that item sees
///    the same thing. Unset, nothing is pressed and the pointer sits at the origin.
///
/// The geometry is lifted here verbatim rather than rewritten, because the M4 prompt's
/// `Do not` says the stage and the canvas may not grow two answers to the same question.
library;

import 'dart:math' as math;

import 'package:kodo_lang/kodo_lang.dart';

/// The sensors, for any surface built on M1's turtle model.
mixin TurtleSensing on HeadlessCanvas implements SensingSurface {
  /// Keys currently held. A live surface adds and removes; a graded one is handed a scene.
  final Set<String> keysDown = {};
  double mousePointerX = 0;
  double mousePointerY = 0;
  bool mouseIsDown = false;

  /// Applies an authored scene, replacing whatever was there.
  void applyScene(SensingScene scene) {
    keysDown
      ..clear()
      ..addAll(scene.keysDown.map((k) => k.toLowerCase()));
    mousePointerX = scene.pointerX.toDouble();
    mousePointerY = scene.pointerY.toDouble();
    mouseIsDown = scene.pointerDown;
  }

  @override
  bool isKeyDown(String key) => keysDown.contains(key.toLowerCase());

  @override
  num get mouseX => mousePointerX;

  @override
  num get mouseY => mousePointerY;

  @override
  bool get isMouseDown => mouseIsDown;

  @override
  bool get touchingEdge =>
      positionX <= 0 ||
      positionY <= 0 ||
      positionX >= width ||
      positionY >= height;

  @override
  bool touchingColour(num r, num g, num b) {
    /* "Standing on ink of that colour" — read from the segments already drawn rather than
       from a rasterised frame, because the canvas is vectors and rasterising on every
       sensor read would cost more than the whole program. A segment counts when the
       turtle is within its width of it. */
    final wanted = ((r.round() & 0xFF) << 16) |
        ((g.round() & 0xFF) << 8) |
        (b.round() & 0xFF);
    for (final s in segments) {
      if (s.color != wanted) continue;
      if (distanceToSegment(positionX.toDouble(), positionY.toDouble(), s) <=
          s.width / 2 + 1) {
        return true;
      }
    }
    return false;
  }

  /// Shortest distance from a point to a drawn segment.
  static double distanceToSegment(double px, double py, Segment s) {
    final dx = s.x2 - s.x1;
    final dy = s.y2 - s.y1;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) {
      return math.sqrt((px - s.x1) * (px - s.x1) + (py - s.y1) * (py - s.y1));
    }
    var t = ((px - s.x1) * dx + (py - s.y1) * dy) / lengthSquared;
    t = t.clamp(0.0, 1.0);
    final cx = s.x1 + t * dx;
    final cy = s.y1 + t * dy;
    return math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
  }
}

/// What a stage looked like after a program ran, reduced to the things an item compares.
///
/// The grader compares drawings by rasterising them, and a costume is not a drawing. So
/// World 10 needed a second comparison, and this is the value it runs on: the state a
/// program can change that leaves no ink.
///
/// **Every sprite, not the selected one.** The first version read the costume and the
/// effects off whichever sprite happened to be selected when the program finished, which
/// meant a program that dressed the wrong sprite and then selected the right one looked
/// identical to a correct one. A cursor is not an outcome, so the cursor is not compared
/// and everything it could have pointed at is.
class StageState {
  const StageState({
    required this.costumes,
    required this.backdropId,
    required this.score,
    required this.said,
    required this.effects,
  });

  /// sprite id → costume number, one-based as the child counts.
  final Map<String, int> costumes;

  final String backdropId;

  /// Sounds, drums and notes in the order they were asked for.
  final List<String> score;

  /// Speech bubbles, in order.
  final List<String> said;

  /// sprite id → effect name → value, for effects that are not at zero.
  final Map<String, Map<String, double>> effects;

  bool get isPlain =>
      costumes.values.every((c) => c == 1) &&
      backdropId == 'blank' &&
      score.isEmpty &&
      said.isEmpty &&
      effects.isEmpty;

  /// Which of the five differs first, in the order a child would notice.
  ///
  /// Null when the two match. The order is deliberate and the same rule the drawing
  /// comparison follows: name the thing that is most visible, because a message about an
  /// effect on a sprite wearing the wrong costume is true and useless.
  String? firstDifference(StageState other) {
    if (!_sameCostumes(costumes, other.costumes)) return 'costume';
    if (backdropId != other.backdropId) return 'backdrop';
    if (!_sameList(said, other.said)) return 'speech';
    if (!_sameList(score, other.score)) return 'sound';
    if (!_sameEffects(effects, other.effects)) return 'effect';
    return null;
  }

  /// How the difference reads in a message: "chat 2, chien 1".
  String describe(String difference) => switch (difference) {
        'costume' =>
          costumes.entries.map((e) => '${e.key} ${e.value}').join(', '),
        'backdrop' => backdropId,
        'sound' => score.isEmpty ? '—' : score.join(', '),
        'speech' => said.isEmpty ? '—' : said.join(' / '),
        _ => effects.isEmpty
            ? '—'
            : effects.entries
                .map((s) =>
                    '${s.key}: ${s.value.entries.map((e) => '${e.key} ${e.value}').join(' ')}')
                .join(', '),
      };

  static bool _sameCostumes(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _sameEffects(
      Map<String, Map<String, double>> a, Map<String, Map<String, double>> b) {
    if (a.length != b.length) return false;
    for (final sprite in a.entries) {
      final theirs = b[sprite.key];
      if (theirs == null || theirs.length != sprite.value.length) return false;
      for (final e in sprite.value.entries) {
        /* The key first, then the number. `(x ?? nan - v).abs() > 0.1` reads like a
           missing key failing the check, and does the opposite: every comparison with
           NaN is false, so an effect the other side had never heard of matched. The gate
           caught it on two items whose wrong answer set a completely different effect. */
        final mine = theirs[e.key];
        if (mine == null) return false;
        // A tenth of a percent. Effects are authored as whole numbers; the tolerance is
        // there so a value arrived at by arithmetic is not failed for its last digit.
        if ((mine - e.value).abs() > 0.1) return false;
      }
    }
    return true;
  }
}
