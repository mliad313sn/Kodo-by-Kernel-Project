/// The step-resumable interpreter (FR-M1-07, FR-M1-08, FR-M1-09, FR-M1-11, FR-M1-12).
///
/// Written as an explicit continuation stack rather than as recursive `execute()` calls,
/// because the child-facing requirement is that a run can be *watched*: slowed, paused,
/// resumed and stepped, mid-flight, with the speed changed while it runs. A recursive
/// tree-walker cannot be suspended between two statements without a thread, and a thread
/// on a 2 GB Android phone is not a design, it is a bill.
///
/// The same machine runs headless for grading. There is no second interpreter — that rule
/// is in §11.2 of the cahier des charges and in the `Do not` of the M1 prompt, and it is
/// the reason a child can trust that what they watched is what was judged.
library;

import 'dart:math' as math;

import 'ast.dart';
import 'errors.dart';
import 'opcodes.dart';
import 'rng.dart';
import 'span.dart';
import 'surface.dart';
import 'values.dart';

/// Playback speed (FR-M1-07). Changing it takes effect on the next step, mid-run.
enum RunSpeed {
  full(0),
  slow(120),
  slower(350),
  slowest(800),

  /// The child drives each step themselves.
  step(-1);

  const RunSpeed(this.delayMs);

  /// What a host should wait between steps. `-1` means "wait for the child".
  final int delayMs;
}

enum RunStatus { ready, running, paused, awaitingInput, finished, failed }

enum EventKind {
  statementStarted,
  statementFinished,
  procedureEntered,
  procedureExited,
  loopIteration,
  outputWritten,
  programFinished,
  errorRaised,
}

/// What the editors highlight and what the inspector redraws.
class ExecutionEvent {
  ExecutionEvent(this.kind, this.nodeId, {this.varsSnapshot, this.text});

  final EventKind kind;
  final String nodeId;

  /// Present only when variable snapshots are enabled. Taking one on every step costs more
  /// than the inspector is worth on the reference device, so the host asks for it.
  final Map<String, KodoValue>? varsSnapshot;

  final String? text;
}

/// Hard ceilings (FR-M1-12).
class RunLimits {
  const RunLimits({
    this.stepsPerSecond = 50000,
    this.seconds = 30,
    this.maxSegments = 10000,
    this.maxDepth = 200,
  });

  final int stepsPerSecond;
  final int seconds;
  final int maxSegments;
  final int maxDepth;

  /// The total work a run may do.
  ///
  /// Expressed in steps rather than in wall-clock time *on purpose*: a grading verdict may
  /// not depend on how fast the device is. A slow phone and a fast desktop must fail the
  /// same infinite loop at the same place, or `FR-M6-09` ("a fix to an item never
  /// retroactively invalidates a child's mastery") is quietly untrue.
  int get maxSteps => stepsPerSecond * seconds;
}

/// A procedure the child taught the turtle with `apprends`.
class _Procedure {
  _Procedure(this.node);
  final ProcDef node;
  String get name => node.name.toLowerCase();
  List<String> get params => node.params;
  List<AsStmt> get body => node.body;
}

class _Frame {
  _Frame(this.name, this.locals);
  final String name;
  final Map<String, KodoValue> locals;
}

// ---------------------------------------------------------------------------------------
// Continuations
// ---------------------------------------------------------------------------------------

sealed class _K {
  const _K();
}

class _Seq extends _K {
  _Seq(this.body, this.index);
  final List<AsStmt> body;
  int index;
}

class _RunStmt extends _K {
  const _RunStmt(this.stmt);
  final AsStmt stmt;
}

class _EvalExpr extends _K {
  const _EvalExpr(this.expr);
  final AsExpr expr;
}

class _Discard extends _K {
  const _Discard();
}

class _ApplyCall extends _K {
  const _ApplyCall(this.node, this.argCount);
  final Node node;
  final int argCount;
}

class _ApplyAssign extends _K {
  const _ApplyAssign(this.node);
  final Assign node;
}

class _ApplyBin extends _K {
  const _ApplyBin(this.node);
  final BinOp node;
}

class _ApplyUn extends _K {
  const _ApplyUn(this.node);
  final UnOp node;
}

class _ApplyList extends _K {
  const _ApplyList(this.node, this.count);
  final ListLiteral node;
  final int count;
}

class _ApplyIndex extends _K {
  const _ApplyIndex(this.node);
  final IndexOf node;
}

/// Short-circuit for `et` / `ou`: the right side is only evaluated if it can change the
/// answer. Concept C7.5's misconception is "or means both must be true"; an implementation
/// that evaluated both sides regardless would make that harder to see, not easier.
class _ShortCircuit extends _K {
  const _ShortCircuit(this.node, this.isAnd);
  final BinOp node;
  final bool isAnd;
}

class _CoerceBool extends _K {
  const _CoerceBool(this.node);
  final Node node;
}

class _RepeatStart extends _K {
  const _RepeatStart(this.node);
  final Repeat node;
}

class _RepeatLoop extends _K {
  _RepeatLoop(this.node, this.remaining);
  final Repeat node;
  int remaining;
}

class _WhileTest extends _K {
  const _WhileTest(this.node);
  final While node;
}

class _WhileLoop extends _K {
  const _WhileLoop(this.node);
  final While node;
}

class _ForStart extends _K {
  const _ForStart(this.node, this.hasStep);
  final For node;
  final bool hasStep;
}

class _ForLoop extends _K {
  _ForLoop(this.node, this.current, this.limit, this.stride);
  final For node;
  num current;
  final num limit;
  final num stride;
}

class _IfTest extends _K {
  const _IfTest(this.node);
  final If node;
}

class _PopFrame extends _K {
  const _PopFrame(this.node, this.wantsValue);
  final Node node;
  final bool wantsValue;
}

class _ApplyReturn extends _K {
  const _ApplyReturn(this.node, this.hasValue);
  final Return node;
  final bool hasValue;
}

// ---------------------------------------------------------------------------------------
// The machine
// ---------------------------------------------------------------------------------------

class Interpreter {
  Interpreter(
    this.program,
    this.surface, {
    int seed = 1,
    this.limits = const RunLimits(),
    this.emitVariableSnapshots = false,
    this.inputs = const [],
  }) : random = SeededRandom(seed) {
    _hoistProcedures(program);
    _k.add(_Seq(program.body, 0));
  }

  final Program program;
  final Surface surface;
  final RunLimits limits;
  final SeededRandom random;

  /// Costly on the reference device; the inspector turns it on, grading leaves it off.
  final bool emitVariableSnapshots;

  /// Scripted answers for `demande`, so an item that asks a question can still be graded
  /// headlessly. When they run out the run suspends on [RunStatus.awaitingInput].
  final List<String> inputs;

  final List<_K> _k = [];
  final List<KodoValue> _values = [];
  final Map<String, KodoValue> _globals = {};
  final List<_Frame> _frames = [];
  final Map<String, _Procedure> _procedures = {};
  final List<ExecutionEvent> events = [];

  int _inputCursor = 0;
  int _steps = 0;
  int _completed = 0;
  RunSpeed _speed = RunSpeed.full;
  RunStatus _status = RunStatus.ready;
  KodoError? _error;
  KodoValue? _pendingReturn;

  /// Virtual, in milliseconds. `attends` advances this instead of sleeping, which is what
  /// makes a stepped run and a full-speed run draw the same figure (acceptance test 4).
  /// A host that wants a real pause reads [RunSpeed.delayMs] and waits itself.
  int virtualClockMs = 0;

  RunStatus get status => _status;
  KodoError? get error => _error;
  RunSpeed get speed => _speed;
  int get stepsExecuted => _steps;
  int get statementsCompleted => _completed;
  bool get isDone =>
      _status == RunStatus.finished || _status == RunStatus.failed;

  Map<String, KodoValue> get variables => {
        ..._globals,
        if (_frames.isNotEmpty) ..._frames.last.locals,
      };

  /// Procedures the child defined, for the inspector (FR-M4-06).
  Iterable<String> get procedureNames =>
      _procedures.values.map((p) => p.node.name);

  void setSpeed(RunSpeed speed) => _speed = speed;

  void pause() {
    if (_status == RunStatus.running || _status == RunStatus.ready) {
      _status = RunStatus.paused;
    }
  }

  void resume() {
    if (_status == RunStatus.paused) _status = RunStatus.running;
  }

  void stop() {
    _k.clear();
    _values.clear();
    if (!isDone) _status = RunStatus.finished;
  }

  /// Supplies an answer to a waiting `demande`.
  void provideInput(String value) {
    if (_status != RunStatus.awaitingInput) return;
    _values.add(StringValue(value));
    _status = RunStatus.running;
  }

  /// Advances by one statement. Returns false when the run has stopped or is waiting.
  ///
  /// "One statement" and not "one continuation" because a step is a thing a child watches:
  /// the highlight moves, one visible consequence happens.
  bool step() {
    if (isDone || _status == RunStatus.awaitingInput) return false;
    _status = RunStatus.running;
    final target = _completed;
    while (_completed == target) {
      if (!_micro()) return false;
    }
    return true;
  }

  /// Runs to completion, or until paused, or until input is needed.
  void run() {
    if (isDone) return;
    _status = RunStatus.running;
    while (_status == RunStatus.running) {
      if (!_micro()) break;
    }
  }

  /// Runs until a node in [breakpoints] is about to execute.
  void runUntilBreakpoint(Set<String> breakpoints) {
    if (isDone) return;
    _status = RunStatus.running;
    while (_status == RunStatus.running) {
      final next = _k.isEmpty ? null : _k.last;
      if (next is _RunStmt && breakpoints.contains((next.stmt as Node).id)) {
        _status = RunStatus.paused;
        return;
      }
      if (!_micro()) break;
    }
  }

  // -------------------------------------------------------------------------------------

  void _hoistProcedures(Node root) {
    for (final node in walk(root)) {
      if (node is ProcDef) {
        _procedures.putIfAbsent(
            node.name.toLowerCase(), () => _Procedure(node));
      }
    }
  }

  void _emit(EventKind kind, String nodeId, {String? text}) {
    events.add(ExecutionEvent(
      kind,
      nodeId,
      varsSnapshot: emitVariableSnapshots ? Map.of(variables) : null,
      text: text,
    ));
  }

  Never _never() => throw StateError('unreachable');

  /// Records a catalogued failure and stops. Nothing is thrown across the boundary.
  bool _fail(ErrorCode code, Node node,
      {Map<String, String> args = const {},
      SuggestedRepair repair = const SuggestedRepair.none()}) {
    _error = KodoError(
      code: code,
      span: node.span,
      nodeId: node.id,
      args: args,
      repair: repair,
    );
    _emit(EventKind.errorRaised, node.id);
    _status = RunStatus.failed;
    _k.clear();
    return false;
  }

  KodoValue _pop() => _values.removeLast();

  void _push(KodoValue v) => _values.add(v);

  KodoValue? _lookup(String name) {
    if (_frames.isNotEmpty) {
      final local = _frames.last.locals[name];
      if (local != null) return local;
    }
    return _globals[name];
  }

  void _assign(String name, KodoValue value) {
    if (_frames.isNotEmpty && _frames.last.locals.containsKey(name)) {
      _frames.last.locals[name] = value;
    } else {
      _globals[name] = value;
    }
  }

  /// One continuation. Returns false when the machine has stopped or is waiting.
  bool _micro() {
    if (_status == RunStatus.paused || _status == RunStatus.awaitingInput) {
      return false;
    }

    if (_k.isEmpty) {
      _status = RunStatus.finished;
      _emit(EventKind.programFinished, program.id);
      return false;
    }

    if (++_steps > limits.maxSteps) {
      return _fail(ErrorCode.timeout, program);
    }
    if (surface.segmentCount > limits.maxSegments) {
      return _fail(ErrorCode.segmentLimit, program);
    }

    final k = _k.removeLast();
    switch (k) {
      case _Seq():
        if (k.index >= k.body.length) return true;
        final stmt = k.body[k.index++];
        _k.add(k);
        _k.add(_RunStmt(stmt));
        return true;

      case _RunStmt(:final stmt):
        return _runStatement(stmt);

      case _EvalExpr(:final expr):
        return _evalExpression(expr);

      case _Discard():
        _pop();
        _completed++;
        return true;

      case _ApplyAssign(:final node):
        final assigned = _pop();
        if (assigned is VoidValue) {
          return _fail(ErrorCode.notAValue, node,
              args: {'word': _describe(node.value)});
        }
        _assign(node.variable, assigned);
        _emit(EventKind.statementFinished, node.id);
        _completed++;
        return true;

      case _ApplyCall(:final node, :final argCount):
        return _applyCall(node, argCount);

      case _ApplyBin(:final node):
        return _applyBinary(node);

      case _ApplyUn(:final node):
        return _applyUnary(node);

      case _ShortCircuit(:final node, :final isAnd):
        final left = _pop();
        if (left is! BoolValue) {
          return _fail(ErrorCode.type, node, args: {
            'word': isAnd ? 'syntax:and' : 'syntax:or',
            'got': left.typeKey,
            'expected': 'type.boolean',
          });
        }
        if (left.value == isAnd) {
          _k.add(_CoerceBool(node));
          _k.add(_EvalExpr(node.right));
        } else {
          _push(left);
        }
        return true;

      case _CoerceBool(:final node):
        final v = _pop();
        if (v is! BoolValue) {
          return _fail(ErrorCode.type, node, args: {
            'word': 'syntax:and',
            'got': v.typeKey,
            'expected': 'type.boolean'
          });
        }
        _push(v);
        return true;

      case _ApplyList(:final count):
        final items = <KodoValue>[];
        for (var i = 0; i < count; i++) {
          items.insert(0, _pop());
        }
        _push(ListValue(items));
        return true;

      case _ApplyIndex(:final node):
        final idx = _pop();
        final target = _pop();
        if (target is! ListValue) {
          return _fail(ErrorCode.type, node, args: {
            'word': '[]',
            'got': target.typeKey,
            'expected': 'type.list'
          });
        }
        if (idx is! NumberValue) {
          return _fail(ErrorCode.type, node, args: {
            'word': '[]',
            'got': idx.typeKey,
            'expected': 'type.number'
          });
        }
        // 1-based: a child's first item is item one, and the "off by one" error is not a
        // lesson we chose to teach at age nine.
        final at = idx.value.round();
        if (at < 1 || at > target.items.length) {
          return _fail(ErrorCode.badIndex, node,
              args: {'size': '${target.items.length}', 'asked': '$at'});
        }
        _push(target.items[at - 1]);
        return true;

      case _RepeatStart(:final node):
        final count = _pop();
        if (count is! NumberValue) {
          return _fail(ErrorCode.type, node, args: {
            'word': 'syntax:repeat',
            'got': count.typeKey,
            'expected': 'type.number',
          });
        }
        final times = count.value.round();
        if (times < 0) {
          return _fail(ErrorCode.negativeCount, node,
              args: {'count': '$times'});
        }
        _completed++;
        if (times == 0) return true;
        _k.add(_RepeatLoop(node, times));
        return true;

      case _RepeatLoop():
        if (k.remaining <= 0) return true;
        k.remaining--;
        _k.add(k);
        _k.add(_Seq(k.node.body, 0));
        _emit(EventKind.loopIteration, k.node.id);
        return true;

      case _WhileTest(:final node):
        _k.add(_WhileLoop(node));
        _k.add(_EvalExpr(node.condition));
        return true;

      case _WhileLoop(:final node):
        final cond = _pop();
        if (cond is! BoolValue) {
          return _fail(ErrorCode.type, node, args: {
            'word': 'syntax:while_',
            'got': cond.typeKey,
            'expected': 'type.boolean',
          });
        }
        _completed++;
        if (!cond.value) return true;
        _k.add(_WhileTest(node));
        _k.add(_Seq(node.body, 0));
        _emit(EventKind.loopIteration, node.id);
        return true;

      case _ForStart(:final node, :final hasStep):
        final stride = hasStep ? _pop() : const NumberValue(1);
        final limit = _pop();
        final from = _pop();
        if (from is! NumberValue ||
            limit is! NumberValue ||
            stride is! NumberValue) {
          return _fail(ErrorCode.type, node, args: {
            'word': 'syntax:for_',
            'got': (from is! NumberValue ? from : limit).typeKey,
            'expected': 'type.number',
          });
        }
        _completed++;
        if (stride.value == 0) {
          return _fail(ErrorCode.negativeCount, node, args: {'count': '0'});
        }
        _k.add(_ForLoop(node, from.value, limit.value, stride.value));
        return true;

      case _ForLoop():
        final goingUp = k.stride > 0;
        if (goingUp ? k.current > k.limit : k.current < k.limit) return true;
        _assign(k.node.variable, NumberValue(k.current));
        k.current += k.stride;
        _k.add(k);
        _k.add(_Seq(k.node.body, 0));
        _emit(EventKind.loopIteration, k.node.id);
        return true;

      case _IfTest(:final node):
        final cond = _pop();
        if (cond is! BoolValue) {
          return _fail(ErrorCode.type, node, args: {
            'word': 'syntax:if_',
            'got': cond.typeKey,
            'expected': 'type.boolean',
          });
        }
        _completed++;
        if (cond.value) {
          _k.add(_Seq(node.then, 0));
        } else if (node.orElse != null) {
          _k.add(_Seq(node.orElse!, 0));
        }
        return true;

      case _ApplyReturn(:final node, :final hasValue):
        _pendingReturn = hasValue ? _pop() : VoidValue.instance;
        _completed++;
        return _unwindToFrame(node);

      case _PopFrame(:final wantsValue):
        _frames.removeLast();
        _emit(EventKind.procedureExited, k.node.id);
        final value = _pendingReturn ?? VoidValue.instance;
        _pendingReturn = null;
        if (wantsValue) _push(value);
        return true;
    }
  }

  // -------------------------------------------------------------------------------------
  // Statements
  // -------------------------------------------------------------------------------------

  bool _runStatement(AsStmt stmt) {
    switch (stmt) {
      case Comment():
        return true;

      case ProcDef():
        return true; // hoisted before the run

      case Command():
        _emit(EventKind.statementStarted, stmt.id);
        _k.add(const _Discard());
        _k.add(_ApplyCall(stmt, stmt.args.length));
        for (var i = stmt.args.length - 1; i >= 0; i--) {
          _k.add(_EvalExpr(stmt.args[i]));
        }
        return true;

      case ProcCall():
        _emit(EventKind.statementStarted, stmt.id);
        _k.add(const _Discard());
        _k.add(_ApplyCall(stmt, stmt.args.length));
        for (var i = stmt.args.length - 1; i >= 0; i--) {
          _k.add(_EvalExpr(stmt.args[i]));
        }
        return true;

      case Assign():
        _emit(EventKind.statementStarted, stmt.id);
        _k.add(_ApplyAssign(stmt));
        _k.add(_EvalExpr(stmt.value));
        return true;

      case Repeat():
        _emit(EventKind.statementStarted, stmt.id);
        _k.add(_RepeatStart(stmt));
        _k.add(_EvalExpr(stmt.count));
        return true;

      case While():
        _emit(EventKind.statementStarted, stmt.id);
        _k.add(_WhileTest(stmt));
        return true;

      case For():
        _emit(EventKind.statementStarted, stmt.id);
        _k.add(_ForStart(stmt, stmt.step != null));
        if (stmt.step != null) _k.add(_EvalExpr(stmt.step!));
        _k.add(_EvalExpr(stmt.to));
        _k.add(_EvalExpr(stmt.from));
        return true;

      case If():
        _emit(EventKind.statementStarted, stmt.id);
        _k.add(_IfTest(stmt));
        _k.add(_EvalExpr(stmt.condition));
        return true;

      case Return():
        _emit(EventKind.statementStarted, stmt.id);
        _k.add(_ApplyReturn(stmt, stmt.value != null));
        if (stmt.value != null) _k.add(_EvalExpr(stmt.value!));
        return true;

      case Break():
        _emit(EventKind.statementStarted, stmt.id);
        _completed++;
        return _unwindToLoop(stmt);

      case Exit():
        _emit(EventKind.statementStarted, stmt.id);
        _completed++;
        _k.clear();
        _status = RunStatus.finished;
        _emit(EventKind.programFinished, program.id);
        return false;

      default:
        _never();
    }
  }

  /// `coupure` — drop everything up to and including the innermost loop.
  ///
  /// Stops at a procedure boundary: a break inside a procedure leaves that procedure's
  /// loop, not the caller's. Concept C8.4's misconception is "break ends the whole
  /// program", and a language that half-agreed would be worse than one that did.
  bool _unwindToLoop(Node at) {
    while (_k.isNotEmpty) {
      final top = _k.removeLast();
      if (top is _RepeatLoop ||
          top is _WhileLoop ||
          top is _WhileTest ||
          top is _ForLoop) {
        return true;
      }
      if (top is _PopFrame) {
        _k.add(top);
        return _fail(ErrorCode.breakOutsideLoop, at);
      }
    }
    return _fail(ErrorCode.breakOutsideLoop, at);
  }

  bool _unwindToFrame(Node at) {
    while (_k.isNotEmpty) {
      final top = _k.removeLast();
      if (top is _PopFrame) {
        _k.add(top);
        return true;
      }
    }
    return _fail(ErrorCode.returnOutsideProc, at);
  }

  // -------------------------------------------------------------------------------------
  // Expressions
  // -------------------------------------------------------------------------------------

  bool _evalExpression(AsExpr expr) {
    switch (expr) {
      case Literal(:final value):
        _push(value);
        return true;

      case VarRef(:final name):
        final v = _lookup(name);
        if (v == null) {
          return _fail(ErrorCode.undefinedVar, expr,
              args: {'name': name},
              repair: const SuggestedRepair(RepairKind.defineVariable));
        }
        _push(v);
        return true;

      case Group(:final inner):
        _k.add(_EvalExpr(inner));
        return true;

      case BinOp(:final op, :final left):
        if (op == 'and' || op == 'or') {
          _k.add(_ShortCircuit(expr, op == 'and'));
          _k.add(_EvalExpr(left));
          return true;
        }
        _k.add(_ApplyBin(expr));
        _k.add(_EvalExpr(expr.right));
        _k.add(_EvalExpr(left));
        return true;

      case UnOp(:final operand):
        _k.add(_ApplyUn(expr));
        _k.add(_EvalExpr(operand));
        return true;

      case Command():
        _k.add(_ApplyCall(expr, expr.args.length));
        for (var i = expr.args.length - 1; i >= 0; i--) {
          _k.add(_EvalExpr(expr.args[i]));
        }
        return true;

      case ProcCall():
        _k.add(_ApplyCall(expr, expr.args.length));
        for (var i = expr.args.length - 1; i >= 0; i--) {
          _k.add(_EvalExpr(expr.args[i]));
        }
        return true;

      case ListLiteral(:final items):
        _k.add(_ApplyList(expr, items.length));
        for (var i = items.length - 1; i >= 0; i--) {
          _k.add(_EvalExpr(items[i]));
        }
        return true;

      case IndexOf(:final target, :final index):
        _k.add(_ApplyIndex(expr));
        _k.add(_EvalExpr(index));
        _k.add(_EvalExpr(target));
        return true;

      default:
        _never();
    }
  }

  bool _applyCall(Node node, int argCount) {
    final args = <KodoValue>[];
    for (var i = 0; i < argCount; i++) {
      args.insert(0, _pop());
    }
    if (node is ProcCall) return _callProcedure(node, args);
    return _callBuiltin(node as Command, args);
  }

  bool _callProcedure(ProcCall node, List<KodoValue> args) {
    final proc = _procedures[node.name.toLowerCase()];
    if (proc == null) {
      return _fail(ErrorCode.undefinedProc, node, args: {'name': node.name});
    }
    if (_frames.length >= limits.maxDepth) {
      return _fail(ErrorCode.depth, node, args: {'name': node.name});
    }
    if (args.length != proc.params.length) {
      return _fail(ErrorCode.argCount, node, args: {
        'word': node.name,
        'expected': '${proc.params.length}',
        'actual': '${args.length}',
      });
    }
    final locals = <String, KodoValue>{};
    for (var i = 0; i < proc.params.length; i++) {
      locals[proc.params[i]] = args[i];
    }
    _frames.add(_Frame(proc.name, locals));
    _emit(EventKind.procedureEntered, node.id);
    _k.add(_PopFrame(node, true));
    _k.add(_Seq(proc.body, 0));
    return true;
  }

  num? _asNumber(KodoValue v) => v is NumberValue ? v.value : null;

  bool _callBuiltin(Command node, List<KodoValue> args) {
    final op = node.opcode;

    if (args.length != op.minArgs) {
      return _fail(ErrorCode.argCount, node, args: {
        'word': 'opcode:${op.id}',
        'expected': '${op.minArgs}',
        'actual': '${args.length}',
      });
    }

    // Every opcode below `message` takes numbers only; check once rather than in each case.
    const takesText = {
      Opcode.print,
      Opcode.message,
      Opcode.ask,
      Opcode.toNumber,
    };
    if (!takesText.contains(op)) {
      for (final a in args) {
        if (a is VoidValue) {
          return _fail(ErrorCode.notAValue, node,
              args: {'word': 'opcode:${op.id}'});
        }
        if (a is! NumberValue) {
          return _fail(ErrorCode.type, node, args: {
            'word': 'opcode:${op.id}',
            'got': a.typeKey,
            'expected': 'type.number',
          });
        }
      }
    }

    num n(int i) => _asNumber(args[i])!;

    switch (op) {
      case Opcode.moveForward:
        surface.forward(n(0));
      case Opcode.moveBack:
        surface.back(n(0));
      case Opcode.turnLeft:
        surface.turnLeft(n(0));
      case Opcode.turnRight:
        surface.turnRight(n(0));
      case Opcode.setDirection:
        surface.setDirection(n(0));
      case Opcode.getDirection:
        _push(NumberValue(surface.direction));
        return true;
      case Opcode.center:
        surface.center();
      case Opcode.go:
        surface.go(n(0), n(1));
      case Opcode.goX:
        surface.goX(n(0));
      case Opcode.goY:
        surface.goY(n(0));
      case Opcode.positionX:
        _push(NumberValue(surface.positionX));
        return true;
      case Opcode.positionY:
        _push(NumberValue(surface.positionY));
        return true;
      case Opcode.penUp:
        surface.penUp();
      case Opcode.penDown:
        surface.penDown();
      case Opcode.penWidth:
        surface.penWidth(n(0));
      case Opcode.penColor:
        surface.penColor(n(0), n(1), n(2));
      case Opcode.canvasSize:
        surface.canvasSize(n(0), n(1));
      case Opcode.canvasColor:
        surface.canvasColor(n(0), n(1), n(2));
      case Opcode.clear:
        surface.clear();
      case Opcode.reset:
        surface.reset();
      case Opcode.show:
        surface.show();
      case Opcode.hide:
        surface.hide();
      case Opcode.print:
        surface.write(_asText(args[0]));
        _emit(EventKind.outputWritten, node.id, text: _asText(args[0]));
      case Opcode.fontSize:
        surface.fontSize(n(0));
      case Opcode.message:
        surface.message(_asText(args[0]));
      case Opcode.ask:
        if (_inputCursor < inputs.length) {
          _push(StringValue(inputs[_inputCursor++]));
          return true;
        }
        // No scripted answer: suspend and wait for the child. The continuation is already
        // gone, so re-push nothing — provideInput() supplies the value directly.
        _status = RunStatus.awaitingInput;
        return false;
      case Opcode.wait:
        virtualClockMs += (n(0) * 1000).round();
      case Opcode.assertion:
        final v = args[0];
        if (v is! BoolValue) {
          return _fail(ErrorCode.type, node, args: {
            'word': 'opcode:${op.id}',
            'got': v.typeKey,
            'expected': 'type.boolean'
          });
        }
      case Opcode.toNumber:
        final text = _asText(args[0]).trim().replaceAll(',', '.');
        final parsed = num.tryParse(text);
        if (parsed == null) {
          // Not a silent zero. A child who typed "trois" has to be told, or the game
          // scores nothing and nothing says why.
          return _fail(ErrorCode.type, node, args: {
            'word': 'opcode:${op.id}',
            'got': 'type.text',
            'expected': 'type.number',
          });
        }
        _push(NumberValue(parsed));
        return true;
      case Opcode.round:
        _push(NumberValue(n(0).round()));
        return true;
      case Opcode.random:
        _push(NumberValue(random.nextIntInclusive(n(0).round(), n(1).round())));
        return true;
      case Opcode.mod:
        if (n(1) == 0) return _fail(ErrorCode.divZero, node);
        _push(NumberValue(n(0) % n(1)));
        return true;
      case Opcode.sqrt:
        if (n(0) < 0) {
          return _fail(ErrorCode.type, node, args: {
            'word': 'opcode:${op.id}',
            'got': 'type.number',
            'expected': 'type.number',
          });
        }
        _push(NumberValue(math.sqrt(n(0))));
        return true;
      case Opcode.pi:
        _push(const NumberValue(math.pi));
        return true;
      case Opcode.sin:
        _push(NumberValue(math.sin(n(0) * math.pi / 180)));
        return true;
      case Opcode.cos:
        _push(NumberValue(math.cos(n(0) * math.pi / 180)));
        return true;
      case Opcode.tan:
        _push(NumberValue(math.tan(n(0) * math.pi / 180)));
        return true;
      case Opcode.arcsin:
        _push(NumberValue(math.asin(n(0)) * 180 / math.pi));
        return true;
      case Opcode.arccos:
        _push(NumberValue(math.acos(n(0)) * 180 / math.pi));
        return true;
      case Opcode.arctan:
        _push(NumberValue(math.atan(n(0)) * 180 / math.pi));
        return true;
    }

    // Reached only by commands: they act, and yield nothing to keep.
    _push(VoidValue.instance);
    return true;
  }

  /// A child-readable reference to whatever expression produced a value, for the moments
  /// when the message has to name the thing that went wrong.
  String _describe(AsExpr expr) => switch (expr) {
        Command() => 'opcode:${expr.opcode.id}',
        ProcCall(:final name) => name,
        VarRef(:final name) => '\$$name',
        _ => '?',
      };

  String _asText(KodoValue v) => switch (v) {
        StringValue(:final value) => value,
        NumberValue() => v.source,
        BoolValue(:final value) => value ? 'true' : 'false',
        ListValue(:final items) => items.map((e) => e.source).join(', '),
        VoidValue() => '',
      };

  bool _applyBinary(BinOp node) {
    final right = _pop();
    final left = _pop();

    if (left is VoidValue || right is VoidValue) {
      return _fail(ErrorCode.notAValue, node, args: {
        'word': _describe(left is VoidValue ? node.left : node.right)
      });
    }

    if (node.op == '==' || node.op == '!=') {
      // Cross-type equality is false, not an error. A child comparing a name to a number
      // has made a mistake of thinking, and an error message here would hide the answer
      // that teaches it.
      final equal = _equals(left, right);
      _push(BoolValue(node.op == '==' ? equal : !equal));
      return true;
    }

    if (left is NumberValue && right is NumberValue) {
      final a = left.value;
      final b = right.value;
      switch (node.op) {
        case '+':
          _push(NumberValue(a + b));
        case '-':
          _push(NumberValue(a - b));
        case '*':
          _push(NumberValue(a * b));
        case '/':
          if (b == 0) return _fail(ErrorCode.divZero, node);
          _push(NumberValue(a / b));
        case '^':
          _push(NumberValue(math.pow(a, b)));
        case '<':
          _push(BoolValue(a < b));
        case '>':
          _push(BoolValue(a > b));
        case '<=':
          _push(BoolValue(a <= b));
        case '>=':
          _push(BoolValue(a >= b));
        default:
          _never();
      }
      return true;
    }

    if (node.op == '+' && left is StringValue && right is StringValue) {
      _push(StringValue(left.value + right.value));
      return true;
    }
    if (node.op == '+' && left is ListValue && right is ListValue) {
      _push(ListValue([...left.items, ...right.items]));
      return true;
    }
    if (left is StringValue && right is StringValue) {
      final c = left.value.compareTo(right.value);
      switch (node.op) {
        case '<':
          _push(BoolValue(c < 0));
          return true;
        case '>':
          _push(BoolValue(c > 0));
          return true;
        case '<=':
          _push(BoolValue(c <= 0));
          return true;
        case '>=':
          _push(BoolValue(c >= 0));
          return true;
      }
    }

    return _fail(ErrorCode.type, node, args: {
      'word': node.op,
      'got': left is NumberValue ? right.typeKey : left.typeKey,
      'expected': 'type.number',
    });
  }

  bool _equals(KodoValue a, KodoValue b) {
    if (a is NumberValue && b is NumberValue) return a.value == b.value;
    if (a is StringValue && b is StringValue) return a.value == b.value;
    if (a is BoolValue && b is BoolValue) return a.value == b.value;
    if (a is ListValue && b is ListValue) {
      if (a.items.length != b.items.length) return false;
      for (var i = 0; i < a.items.length; i++) {
        if (!_equals(a.items[i], b.items[i])) return false;
      }
      return true;
    }
    return false;
  }

  bool _applyUnary(UnOp node) {
    final v = _pop();
    if (v is VoidValue) {
      return _fail(ErrorCode.notAValue, node,
          args: {'word': _describe(node.operand)});
    }
    if (node.op == '-') {
      if (v is! NumberValue) {
        return _fail(ErrorCode.type, node,
            args: {'word': '-', 'got': v.typeKey, 'expected': 'type.number'});
      }
      _push(NumberValue(-v.value));
      return true;
    }
    if (v is! BoolValue) {
      return _fail(ErrorCode.type, node, args: {
        'word': 'syntax:not',
        'got': v.typeKey,
        'expected': 'type.boolean'
      });
    }
    _push(BoolValue(!v.value));
    return true;
  }
}

/// Convenience: parse-free execution of an already-built tree, to completion.
///
/// This is the entry point M6 grades with. It never throws: a failed run comes back as an
/// error on the interpreter, which the caller renders in the child's language.
Interpreter runProgram(
  Program program,
  Surface surface, {
  int seed = 1,
  RunLimits limits = const RunLimits(),
  List<String> inputs = const [],
}) {
  final interpreter =
      Interpreter(program, surface, seed: seed, limits: limits, inputs: inputs);
  interpreter.run();
  return interpreter;
}

/// A span for nodes the interpreter invents. Never shown; kept so `_fail` always has one.
const SourceSpan syntheticSpan = SourceSpan.none;
