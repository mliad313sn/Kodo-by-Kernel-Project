/// The inspector (FR-M4-06, FR-M4-07).
///
/// *"a variable is a box with something in it"* is concept C6.1, and its misconception is
/// *"I cannot see what is inside a variable"*. The inspector is the repair. It is a model
/// rather than a widget so that the claim — that it updates within one frame of the
/// assignment executing — is testable without a screen.
library;

import 'package:kodo_lang/kodo_lang.dart';

/// One row of the variables panel.
class InspectedVariable {
  const InspectedVariable(this.name, this.value, this.changed);

  final String name;
  final KodoValue value;

  /// True when this is the variable the last executed statement wrote.
  ///
  /// The panel highlights it. Without this a child watching a program with six variables
  /// cannot tell which box just changed, which is the entire point of watching.
  final bool changed;

  /// What the child reads in the value column.
  String get display => value.source;

  /// The type, in the child's language. Locale-resolved by the interface; this is the key.
  String get typeKey => value.typeKey;
}

/// A frame of the execution tree.
class ExecutionFrame {
  const ExecutionFrame(this.nodeId, this.label, this.depth);
  final String nodeId;

  /// A procedure name, or the kind of block. Never a class name.
  final String label;
  final int depth;
}

/// Everything the inspector shows at one instant.
class InspectorSnapshot {
  const InspectorSnapshot({
    required this.variables,
    required this.procedures,
    required this.stack,
    required this.currentNodeId,
    required this.stepsExecuted,
  });

  final List<InspectedVariable> variables;
  final List<String> procedures;
  final List<ExecutionFrame> stack;

  /// The node to highlight — in the block editor *and* on the corresponding text line.
  /// `FR-M4-07` requires both at once, from one source of truth, which is this field.
  final String? currentNodeId;

  final int stepsExecuted;

  bool get isEmpty => variables.isEmpty && stack.isEmpty;
}

/// Watches an [Interpreter] and produces [InspectorSnapshot]s.
///
/// It reads the interpreter rather than being fed by it, so that turning the inspector on
/// costs nothing when it is off — `emitVariableSnapshots` is expensive on the reference
/// device and the inspector is not always open.
class Inspector {
  Inspector(this.interpreter);

  final Interpreter interpreter;
  Map<String, KodoValue> _previous = const {};
  String? _currentNodeId;
  int _consumedEvents = 0;

  /// Consumes any interpreter events since the last call and returns the current state.
  InspectorSnapshot sample() {
    final events = interpreter.events;
    for (var i = _consumedEvents; i < events.length; i++) {
      final e = events[i];
      if (e.kind == EventKind.statementStarted ||
          e.kind == EventKind.loopIteration) {
        _currentNodeId = e.nodeId;
      }
    }
    _consumedEvents = events.length;

    final now = interpreter.variables;
    final rows = <InspectedVariable>[];
    for (final entry in now.entries) {
      final before = _previous[entry.key];
      final changed = before == null || before != entry.value;
      rows.add(InspectedVariable(entry.key, entry.value, changed));
    }
    rows.sort((a, b) => a.name.compareTo(b.name));
    _previous = Map.of(now);

    return InspectorSnapshot(
      variables: rows,
      procedures: interpreter.procedureNames.toList()..sort(),
      stack: _stack(),
      currentNodeId: _currentNodeId,
      stepsExecuted: interpreter.stepsExecuted,
    );
  }

  List<ExecutionFrame> _stack() {
    // The interpreter reports procedure entry and exit as events; the tree is rebuilt from
    // them rather than exposing the continuation stack, which is an implementation detail
    // M1 is entitled to change.
    final frames = <ExecutionFrame>[];
    for (final e in interpreter.events) {
      if (e.kind == EventKind.procedureEntered) {
        frames.add(ExecutionFrame(e.nodeId, 'proc', frames.length));
      } else if (e.kind == EventKind.procedureExited && frames.isNotEmpty) {
        frames.removeLast();
      }
    }
    return frames;
  }
}
