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

  /// Ordered poses after every command that moved the turtle.
  ///
  /// The grader normalises this into a path signature so that a square drawn starting from
  /// a different corner still passes — `FR-M6-02`, and G4 finding `G4-001` in the workbook
  /// is exactly what happens when a grader forgets it.
  List<TurtlePose> get trace;
}
