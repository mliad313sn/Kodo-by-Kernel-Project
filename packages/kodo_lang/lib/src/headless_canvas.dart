/// A [Surface] with geometry but no pixels.
///
/// This is what the grader runs a child's program against (`FR-M6-04` — grading is fully
/// on device, and fully offline). It is deliberately *not* a renderer: it holds the turtle
/// model, which is language semantics, and stops there. Rasterisation, zoom, SVG export
/// and the sprite stage are M4's, built on the same model so the two can never disagree.
library;

import 'dart:math' as math;

import 'surface.dart';

class HeadlessCanvas implements Surface {
  HeadlessCanvas({this.width = 400, this.height = 400}) {
    _applyReset();
  }

  double width;
  double height;

  final List<Segment> segments = [];
  final List<CanvasText> _texts = [];
  final List<TurtlePose> _trace = [];
  final List<String> output = [];
  final List<String> messages = [];

  late double _x;
  late double _y;
  late double _heading;
  late bool _penDown;
  late double _penWidth;
  late int _penColor;
  int canvasBackground = 0xFFFFFF;
  bool visible = true;
  double fontPointSize = 12;

  void _applyReset() {
    _x = width / 2;
    _y = height / 2;
    _heading = 0;
    _penDown = true;
    _penWidth = 1;
    _penColor = 0x000000;
    visible = true;
    _recordPose();
  }

  void _recordPose() => _trace.add(TurtlePose(_x, _y, _heading, _penDown));

  static int _channel(num v) => v.round().clamp(0, 255);

  void _lineTo(double nx, double ny) {
    // A zero-length move leaves no mark, so it records no segment.
    //
    // This is a grading rule, not a rendering nicety: if `avance 0` added a segment, a
    // child's program and the reference solution could differ by an invisible stroke and
    // the path signature would disagree. `FR-M6-02` says a pass must never depend on
    // something the child cannot see.
    if (_penDown && (nx != _x || ny != _y)) {
      segments.add(Segment(_x, _y, nx, ny, _penWidth, _penColor));
    }
    _x = nx;
    _y = ny;
    _recordPose();
  }

  /// Heading 0 points up (towards smaller y) and grows clockwise.
  void _move(num distance) {
    final radians = _heading * math.pi / 180.0;
    _lineTo(
        _x + distance * math.sin(radians), _y - distance * math.cos(radians));
  }

  @override
  void forward(num distance) => _move(distance);

  @override
  void back(num distance) => _move(-distance);

  @override
  void turnLeft(num degrees) {
    _heading = _normalise(_heading - degrees.toDouble());
    _recordPose();
  }

  @override
  void turnRight(num degrees) {
    _heading = _normalise(_heading + degrees.toDouble());
    _recordPose();
  }

  @override
  void setDirection(num degrees) {
    _heading = _normalise(degrees.toDouble());
    _recordPose();
  }

  static double _normalise(double d) {
    final m = d % 360.0;
    return m < 0 ? m + 360.0 : m;
  }

  @override
  num get direction => _heading;

  // --- Jumps. None of these draw, ever. -------------------------------------------------

  void _jumpTo(double nx, double ny) {
    _x = nx;
    _y = ny;
    _recordPose();
  }

  @override
  void center() => _jumpTo(width / 2, height / 2);

  @override
  void go(num x, num y) => _jumpTo(x.toDouble(), y.toDouble());

  @override
  void goX(num x) => _jumpTo(x.toDouble(), _y);

  @override
  void goY(num y) => _jumpTo(_x, y.toDouble());

  @override
  num get positionX => _x;

  @override
  num get positionY => _y;

  @override
  void penUp() {
    _penDown = false;
    _recordPose();
  }

  @override
  void penDown() {
    _penDown = true;
    _recordPose();
  }

  @override
  void penWidth(num width) => _penWidth = width.toDouble();

  @override
  void penColor(num r, num g, num b) =>
      _penColor = (_channel(r) << 16) | (_channel(g) << 8) | _channel(b);

  @override
  void canvasSize(num width, num height) {
    this.width = width.toDouble();
    this.height = height.toDouble();
  }

  @override
  void canvasColor(num r, num g, num b) =>
      canvasBackground = (_channel(r) << 16) | (_channel(g) << 8) | _channel(b);

  @override
  void clear() {
    segments.clear();
    _texts.clear();
  }

  @override
  void reset() {
    segments.clear();
    _texts.clear();
    _trace.clear();
    canvasBackground = 0xFFFFFF;
    _applyReset();
  }

  @override
  void show() => visible = true;

  @override
  void hide() => visible = false;

  @override
  void write(String text) {
    output.add(text);
    _texts.add(CanvasText(_x, _y, text, fontPointSize, _penColor));
  }

  @override
  List<CanvasText> get texts => List.unmodifiable(_texts);

  @override
  void fontSize(num size) => fontPointSize = size.toDouble();

  @override
  void message(String text) => messages.add(text);

  @override
  int get segmentCount => segments.length;

  @override
  List<TurtlePose> get trace => List.unmodifiable(_trace);

  /// A stable, order-insensitive fingerprint of what was drawn.
  ///
  /// Segments are rounded to a tenth of a pixel, written in a canonical direction and then
  /// sorted, so a square drawn clockwise from the top-left and one drawn anticlockwise from
  /// the bottom-right produce the same signature. That is `FR-M6-02` made mechanical: a
  /// correct figure drawn in a different but valid order passes.
  String pathSignature() {
    String canonical(Segment s) {
      String p(double v) => (v * 10).round().toString();
      final a = '${p(s.x1)},${p(s.y1)}';
      final b = '${p(s.x2)},${p(s.y2)}';
      final ordered = a.compareTo(b) <= 0 ? '$a>$b' : '$b>$a';
      return '$ordered|${(s.width * 10).round()}|${s.color}';
    }

    final lines = segments.map(canonical).toList()..sort();
    final labels = _texts
        .map((t) => 'T${(t.x * 10).round()},${(t.y * 10).round()}:${t.text}')
        .toList()
      ..sort();
    return [...lines, ...labels].join(';');
  }

  /// The drawing in the order it was made. Used by tutorials that replay a figure and by
  /// the "animated target preview" of `IMP-005`.
  String orderedSignature() => segments
      .map((s) => '${s.x1.toStringAsFixed(1)},${s.y1.toStringAsFixed(1)}>'
          '${s.x2.toStringAsFixed(1)},${s.y2.toStringAsFixed(1)}')
      .join(';');
}
