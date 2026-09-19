/// The one contract between the language core and everything that can be seen.
///
/// M1 drives a [Surface]; it never learns how a line is drawn. M4 implements this over a
/// vector canvas and over the sprite stage, and the grader implements it headlessly. The
/// rule that keeps `FR-M6-01` honest is that all three go through this interface: the
/// program a child sees running and the program the grader judges are the same execution
/// against different sinks, never two implementations that agree most of the time.
library;

/// A single drawn line, in canvas coordinates.
class Segment {
  const Segment(this.x1, this.y1, this.x2, this.y2, this.width, this.color);
  final double x1, y1, x2, y2;
  final double width;

  /// Packed 0xRRGGBB.
  final int color;
}

/// Text written onto the surface by `écris`.
///
/// It carries a position because it is part of the drawing, not part of a console: a child
/// who writes a label on their figure has drawn something, and the grader has to see it.
class CanvasText {
  const CanvasText(this.x, this.y, this.text, this.size, this.color);
  final double x, y;
  final String text;
  final double size;
  final int color;
}

/// Turtle pose, used by the inspector and by the grader's path signature.
class TurtlePose {
  const TurtlePose(this.x, this.y, this.heading, this.penDown);
  final double x, y;

  /// Degrees, 0 = up, increasing clockwise — the convention of the source tradition, and
  /// the one World 1's protractor art is drawn against.
  final double heading;
  final bool penDown;
}

/// What a program can do to the world.
abstract class Surface {
  void forward(num distance);
  void back(num distance);
  void turnLeft(num degrees);
  void turnRight(num degrees);
  void setDirection(num degrees);
  num get direction;

  /// Jump commands. These never draw, whatever the pen state — the distinction `va`
  /// makes against `avance` is concept C3.1 and its misconception is exactly "va draws a
  /// line", so the implementation may not blur it.
  void center();
  void go(num x, num y);
  void goX(num x);
  void goY(num y);
  num get positionX;
  num get positionY;

  void penUp();
  void penDown();
  void penWidth(num width);
  void penColor(num r, num g, num b);

  void canvasSize(num width, num height);
  void canvasColor(num r, num g, num b);

  /// Erases the drawing and leaves the turtle where it is.
  void clear();

  /// Erases the drawing *and* puts everything back to how it started. World 3 teaches the
  /// difference between this and [clear]; they may not share an implementation.
  void reset();

  void show();
  void hide();

  void write(String text);
  void fontSize(num size);
  void message(String text);

  /// How many segments have been drawn. The interpreter's 10 000-segment guard reads this.
  int get segmentCount;

  /// Text drawn onto the surface, in order.
  List<CanvasText> get texts;

  /// Ordered poses after every command that moved the turtle.
  ///
  /// The grader normalises this into a path signature so that a square drawn starting from
  /// a different corner still passes — `FR-M6-02`, and G4 finding `G4-001` in the workbook
  /// is exactly what happens when a grader forgets it.
  List<TurtlePose> get trace;
}

/// What a program can ask the world (`FR-M21-03`).
///
/// Separate from [Surface] and optional, because a sensor is a *question* and a canvas
/// has no answers. A surface that does not implement this gets the sensing blocks refused
/// with a sentence rather than silently answering zero — a sensor that always says "no"
/// is worse than one that is missing, because a child debugs their own program for an
/// hour before suspecting the world.
///
/// **Deterministic when grading.** Every answer comes from the item's scripted inputs, the
/// same way `demande` already works. A question the grader cannot answer the same way
/// twice is not an exercise.
abstract class SensingSurface {
  /// Whether the named key is held. The name is a child's word: `espace`, `a`, `haut`.
  bool isKeyDown(String key);

  num get mouseX;
  num get mouseY;
  bool get isMouseDown;

  /// Whether the turtle is at or past the edge of the canvas.
  bool get touchingEdge;

  /// Whether the turtle stands on ink of that colour.
  bool touchingColour(num r, num g, num b);
}

/// What a program can do to a stage: sprites, costumes, sounds, backdrops, effects
/// (`FR-M21-04`).
///
/// A capability, not a bigger [Surface]. The canvas of Worlds 0–9 is not a stage, every
/// existing implementer of `Surface` keeps working unchanged, and a program that asks a
/// canvas for a costume is told so in a sentence. That is the test of whether an extension
/// was designed or bolted on.
abstract class StageSurface implements Surface {
  /// Advances to the next costume, wrapping. World 10's animation is this in a loop.
  void nextCostume();

  /// One-based, because a child counts from one and the costume picker shows 1, 2, 3.
  void setCostume(int number);
  int get costumeNumber;

  void setBackdrop(String name);

  /// `effet <nom> <valeur>`. The names are content, not code: a pack may ship its own.
  void setEffect(String name, num value);
  void clearEffects();

  /// A speech bubble. Not [Surface.message], which is the system talking to the child.
  void say(String text);

  void playSound(String name);

  /// `tambour <numéro> <temps>` and `note <hauteur> <temps>`. Both are recorded rather
  /// than played here: grading listens to the score, never to a speaker.
  void playDrum(int drum, num beats);
  void playNote(num pitch, num beats);
}
