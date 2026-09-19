/// Slow and step, highlighting the block and the text line at once (`FR-M4-07`).
///
/// The requirement is *"slow/step highlights both the block and the text line"*, and the
/// word doing the work is **both**. Two highlights that agree are the block/text bridge
/// proving itself every second of a slow run: a child watching `répète` light up while the
/// second line of their program lights up too has been shown that the blocks and the words
/// are one program, without anyone saying so.
///
/// Which means the two highlights may not be computed separately. There is one cursor, it
/// holds a node id — the interpreter's own currency — and the line is derived from it. A
/// second computation that agreed most of the time would be the same mistake the "one AST"
/// rule exists to prevent, one layer up.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';

import 'block_stack.dart';

/// Which line of the rendered program each statement occupies.
///
/// A program the child typed already knows: every node carries the span it was parsed
/// from. A program the child *built* does not — a block placed by hand has no text origin
/// until the program is rendered — so the map is recovered by rendering and reading the
/// result back. That is the round trip `FR-M1-01` already guarantees, used rather than
/// re-implemented: a second layout calculation that walked the tree counting newlines
/// would be a copy of the renderer that drifts the first time the renderer changes.
Map<String, int> statementLines(Program program, KeywordTable keywords) {
  final mine = allStatements(program).cast<Node>().toList();
  if (mine.isEmpty) return const {};
  if (mine.every((node) => !node.span.isNone)) {
    return {for (final node in mine) node.id: node.span.line};
  }

  final reparsed = parse(render(program, keywords), keywords);
  if (reparsed.errors.isNotEmpty) return const {};
  final theirs = allStatements(reparsed.program).cast<Node>().toList();
  /* Different lengths mean the round trip did not hold, which is a bug in the renderer or
     the parser rather than in this file. An empty map costs a highlight; a wrong map moves
     it to someone else's line, which teaches a child something false. */
  if (theirs.length != mine.length) return const {};
  return {
    for (var i = 0; i < mine.length; i++) mine[i].id: theirs[i].span.line,
  };
}

/// A program being watched: the run, and where it has got to.
///
/// Owns the [Interpreter] rather than being owned by it, because slow and step are about
/// *when* the next statement happens and that is a question about the host's clock, not
/// about the language. The interpreter has been step-resumable since `FR-M1-05`; this is
/// that property with a timer on it.
class RunCursor extends ChangeNotifier {
  RunCursor({
    required Program program,
    required Surface surface,
    required KeywordTable keywords,
    int seed = 1,
    this.speed = RunSpeed.slow,
  })  : _program = program,
        _lines = statementLines(program, keywords),
        _seed = seed,
        _interpreter = Interpreter(program, surface, seed: seed);

  final Program _program;
  final Map<String, int> _lines;
  int _seed;
  Interpreter _interpreter;
  Timer? _timer;
  String? _nodeId;
  int _seen = 0;
  int _steps = 0;

  /// How many statements have run. The ghost preview counts from here.
  int get steps => _steps;

  /// How fast an unattended run advances. `RunSpeed.step` waits for the child.
  RunSpeed speed;

  Program get program => _program;
  Interpreter get interpreter => _interpreter;

  /// The statement the run is on, or null before the first step and after the last.
  String? get nodeId => _nodeId;

  /// The line that statement occupies in the text view. The same cursor, read the other
  /// way — never a second calculation.
  int? get line => _nodeId == null ? null : _lines[_nodeId!];

  RunStatus get status => _interpreter.status;
  bool get isRunning => _timer != null;
  bool get isDone => _interpreter.isDone;

  /// Advances one statement and moves the highlight. Returns false when the run is over.
  ///
  /// The highlight lands on the statement that just *started*, not the one that finished:
  /// a child stepping through a program is asking "what is about to happen", and a
  /// highlight on the statement already done answers a question nobody asked.
  bool step() {
    if (_interpreter.isDone) {
      _land(null);
      return false;
    }
    final moved = _interpreter.step();
    if (moved) _steps++;
    _land(_latestStart());
    if (!moved) stop();
    return moved;
  }

  String? _latestStart() {
    final events = _interpreter.events;
    String? started;
    for (var i = _seen; i < events.length; i++) {
      if (events[i].kind == EventKind.statementStarted ||
          events[i].kind == EventKind.errorRaised) {
        started = events[i].nodeId;
      }
    }
    _seen = events.length;
    return started ?? _nodeId;
  }

  /// What the next [lookahead] statements will draw, if anything (`FR-M4-08`).
  ///
  /// *"Ghosted future-path overlay in step mode"* is one sentence and the most useful
  /// sentence in M4: a child stepping through a square sees, before they press the button,
  /// where the next `avance` is going to go. That turns stepping from "watch it happen" —
  /// which is only slightly better than running it — into "predict, then check", which is
  /// the whole of debugging.
  ///
  /// It is computed by running the program again from the beginning on a scratch canvas,
  /// not by reaching into the interpreter's state. That costs a re-run per step, which on
  /// a child's program at a step a second is nothing, and it buys the guarantee that
  /// matters: the ghost is what will *actually* happen, produced by the same interpreter,
  /// not a prediction by a second implementation that could disagree with the real thing
  /// at exactly the moment a child is using it to learn.
  ///
  /// Empty when the render budget has turned the preview off (`FR-M4-09`), which is the
  /// one case where nothing is shown rather than something cheaper.
  List<Segment> ghost({int lookahead = 1}) {
    if (_interpreter.isDone || _steps < 0) return const [];
    final live = _interpreter.surface;
    // `FR-M4-09`: the device's own budget decides, not this file's opinion of the cost.
    if (live is VectorCanvas && !live.budget.ghostPreview) return const [];
    final drawnNow = live.segmentCount;
    final scratch = VectorCanvas();
    final ahead = Interpreter(_program, scratch, seed: _seed);
    for (var i = 0; i < _steps + lookahead; i++) {
      if (!ahead.step()) break;
    }
    if (scratch.segments.length <= drawnNow) return const [];
    return scratch.segments.sublist(drawnNow);
  }

  void _land(String? nodeId) {
    _nodeId = nodeId;
    notifyListeners();
  }

  /// Starts an unattended run at [speed]. `RunSpeed.step` starts nothing — that speed *is*
  /// the child pressing the button.
  void play() {
    if (speed == RunSpeed.step || _interpreter.isDone) return;
    /* Full speed has nothing to watch, so it is a run and not an animation. Driving it
       through a zero-millisecond timer would hand the program back to the event loop
       between every statement and make the fastest speed the slowest one. */
    if (speed == RunSpeed.full) {
      _interpreter.run();
      _seen = _interpreter.events.length;
      _steps = -1;
      _land(null);
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: speed.delayMs), (_) {
      if (!step()) stop();
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Puts the run back to the beginning on a fresh surface.
  void restart(Surface surface, {int seed = 1}) {
    stop();
    _interpreter = Interpreter(_program, surface, seed: seed);
    _seen = 0;
    _steps = 0;
    _seed = seed;
    _land(null);
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
