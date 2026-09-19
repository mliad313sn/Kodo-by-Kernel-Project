/// Drawings, as data.
///
/// A drawing here is a list of shapes with coordinates, not an SVG string and not a PNG.
/// Two projections render it: a Flutter `CustomPainter` in the app, and an SVG emitter for
/// the asset files the content packs name. **One geometry, two projections** — the same
/// rule the language follows, and for the same reason: two copies of a drawing drift, and
/// the one that drifts is the one fewer people look at.
///
/// It is vector because `R4` says so — *"per-world budget; audio in Opus, art as vector"*.
/// A raster world illustration eats the pack budget a child's narration needs.
library;

/// A point in the drawing's own coordinate space, which is always 0–100 on both axes.
///
/// Unitless on purpose: a drawing is scaled to wherever it lands, and an illustration
/// authored in pixels is an illustration that is wrong on the next screen size.
class P {
  const P(this.x, this.y);
  final double x;
  final double y;
}

/// A named colour role, resolved by the palette at paint time.
///
/// Shapes never carry a hex value. A drawing that hard-codes its colours cannot follow a
/// high-contrast preference, cannot be recoloured per world, and quietly becomes the one
/// place the palette does not reach.
enum Tint {
  shell,
  shellDark,
  skin,
  skinDark,
  eye,
  highlight,
  sand,
  sea,
  seaDeep,
  sky,
  sun,
  mango,
  leaf,
  leafDark,
  bark,
  night,
  outline,

  /* Roles the world places needed. They are named for what they DO, not for the colour
     they happen to resolve to — that is the whole point of a role: high contrast can move
     `sandLine` without moving `sand`, and the ruling on a grid stays a ruling. */
  sandLine,
  inkLine,
  mangoDeep,
  hibiscusInk,
}

/// One shape.
sealed class Shape {
  const Shape(this.ink);
  final Tint ink;
}

class Circle extends Shape {
  const Circle(super.ink, this.centre, this.r);
  final P centre;
  final double r;
}

/// An axis-aligned ellipse. Enough for a shell, a pebble, a cloud.
class Oval extends Shape {
  const Oval(super.ink, this.centre, this.rx, this.ry);
  final P centre;
  final double rx, ry;
}

class Poly extends Shape {
  const Poly(super.ink, this.points, {this.closed = true});
  final List<P> points;
  final bool closed;
}

/// A rounded rectangle, given by two corners.
class Box extends Shape {
  const Box(super.ink, this.topLeft, this.bottomRight, {this.radius = 0});
  final P topLeft, bottomRight;
  final double radius;
}

/// A stroked path — a smile, a horizon, a wave.
class Stroke extends Shape {
  const Stroke(super.ink, this.points, {this.width = 2, this.round = true});
  final List<P> points;
  final double width;
  final bool round;
}

/// A drawing: a name, its shapes, and what it is for.
class Drawing {
  const Drawing({
    required this.id,
    required this.shapes,
    required this.describeFr,
    required this.describeEn,
  });

  final String id;
  final List<Shape> shapes;

  /// What a screen reader says (`FR-M16-04`). Authored, never generated from the shape
  /// list — "seventeen circles" is not a description.
  final String describeFr;
  final String describeEn;

  String describeIn(String locale) => locale == 'en' ? describeEn : describeFr;
}
