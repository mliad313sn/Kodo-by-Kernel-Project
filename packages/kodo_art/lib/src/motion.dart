/// Motion.
///
/// §9.2: *"Motion is meaningful (it shows causality) and always interruptible."* Both
/// halves are requirements, and both are easy to lose — the first to decoration, the
/// second to a nice easing curve nobody thought to cancel.
///
/// Every animation here declares a **reason** and a **reduced form**. `FR-M16-03`'s
/// reduced-motion preference does not mean *nothing happens*: a child who turns it on
/// still needs to know the block landed. It means the change is instant, or a fade, rather
/// than a journey across the screen.
library;

/// Why an animation exists. If a new one does not fit here, it is decoration.
enum MotionReason {
  /// Shows that one thing caused another — the block ran, so the turtle moved.
  causality,

  /// Shows where something went, so a child can find it again.
  continuity,

  /// Confirms a touch landed. The smallest and the most important.
  feedback,
}

/// One animation.
class Motion {
  const Motion({
    required this.id,
    required this.reason,
    required this.milliseconds,
    required this.reduced,
    required this.describe,
  });

  final String id;
  final MotionReason reason;
  final int milliseconds;

  /// What happens instead when reduced motion is on. Never `null`, never zero-and-nothing.
  final ReducedMotion reduced;

  final String describe;

  /// How long it runs, honouring the preference.
  Duration durationFor({required bool reducedMotion}) => Duration(
      milliseconds: reducedMotion ? reduced.milliseconds : milliseconds);
}

/// The reduced form of an animation.
class ReducedMotion {
  const ReducedMotion(this.kind, this.milliseconds);

  /// `fade`, `instant`, or `shorten`.
  final String kind;
  final int milliseconds;

  static const instant = ReducedMotion('instant', 0);
  static const quickFade = ReducedMotion('fade', 120);
}

/// Everything that moves.
///
/// A short list on purpose. §9.2's rule and `R2`'s performance budget point the same way:
/// on a 2 GB phone every animation is a frame somebody else needed.
const motions = <Motion>[
  Motion(
    id: 'block.place',
    reason: MotionReason.feedback,
    milliseconds: 140,
    reduced: ReducedMotion.quickFade,
    describe:
        'A placed block settles into the script, so the tap is confirmed.',
  ),
  Motion(
    id: 'turtle.step',
    reason: MotionReason.causality,
    milliseconds: 260,
    reduced: ReducedMotion.instant,
    describe:
        'Tika travels the segment she is drawing, so the line has a cause. '
        'Reduced: the line appears complete, because the point is the line.',
  ),
  Motion(
    id: 'highlight.advance',
    reason: MotionReason.causality,
    milliseconds: 180,
    reduced: ReducedMotion.instant,
    describe:
        'The executing block lights up as the previous one dims — this is what '
        'teaches that blocks run one after another (C0.3).',
  ),
  Motion(
    id: 'screen.push',
    reason: MotionReason.continuity,
    milliseconds: 220,
    reduced: ReducedMotion.quickFade,
    describe:
        'A new screen slides in from the side it can be dismissed toward, so the '
        'way back is learned rather than explained.',
  ),
  Motion(
    id: 'star.earn',
    reason: MotionReason.feedback,
    milliseconds: 320,
    reduced: ReducedMotion.quickFade,
    describe:
        'A star settles onto the map at the concept just mastered. It does not '
        'burst, spin or chime: §10 forbids a reward that outshines the work.',
  ),
];

/// The ceiling any single animation may take.
///
/// 320 ms is about the point at which a child starts tapping again because they think it
/// did not work — which is how an animation becomes a double action.
const motionCeilingMs = 320;
