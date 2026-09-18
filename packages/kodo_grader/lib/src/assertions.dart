/// The structural assertion language (FR-M6-01, §6.2).
///
/// Assertions are **authored per item, never inferred**. That rule is in the M6 prompt and
/// it is the difference between a grader that checks what the author meant and one that
/// overfits to whatever the reference solution happened to do.
///
/// They are data, because items are authored in M18 by people who are not engineers, and
/// because an item stored in a content pack has to carry its own grading policy.
library;

import 'package:kodo_lang/kodo_lang.dart';

/// What an assertion concluded, and what to say if it failed.
class AssertionResult {
  const AssertionResult(this.assertion, this.passed,
      {this.actual, this.expected});

  final StructuralAssertion assertion;
  final bool passed;

  /// The number the child's program actually had, for the diagnostic message.
  final Object? actual;
  final Object? expected;

  Map<String, String> get messageArgs => {
        if (actual != null) 'actual': '$actual',
        if (expected != null) 'expected': '$expected',
      };
}

/// One authored claim about the shape of a correct program.
abstract class StructuralAssertion {
  const StructuralAssertion();

  /// A stable identifier, used as the message key suffix so every assertion type has an
  /// authored sentence behind it rather than a generated one.
  String get kind;

  AssertionResult check(Program program);

  Map<String, Object?> toJson();

  static StructuralAssertion fromJson(Map<String, Object?> json) {
    final kind = json['kind']! as String;
    return switch (kind) {
      'contains' => ContainsNode(json['node']! as String,
          min: (json['min'] as int?) ?? 1, max: json['max'] as int?),
      'bodyLength' => BodyLength(json['node']! as String,
          min: (json['min'] as int?) ?? 1, max: json['max'] as int?),
      'blockCount' => BlockCountWithin(
          min: (json['min'] as int?) ?? 0, max: json['max'] as int?),
      'usesOnly' =>
        UsesOnly(((json['opcodes']! as List<Object?>).cast<String>()).toSet()),
      'usesOpcode' => UsesOpcode(json['opcode']! as String,
          min: (json['min'] as int?) ?? 1, max: json['max'] as int?),
      'noJumpWithPenDown' => const NoJumpWithPenDown(),
      'nestedInside' =>
        NestedInside(json['outer']! as String, json['inner']! as String),
      'definesProcedure' => DefinesProcedure(min: (json['min'] as int?) ?? 1),
      'usesVariable' => const UsesVariable(),
      _ => throw ArgumentError('unknown structural assertion "$kind"'),
    };
  }
}

int _countKind(Program program, String kind) =>
    walk(program).where((n) => n.kind == kind).length;

/// `contains(Repeat)`, optionally bounded.
class ContainsNode extends StructuralAssertion {
  const ContainsNode(this.node, {this.min = 1, this.max});
  final String node;
  final int min;
  final int? max;

  @override
  String get kind => 'contains';

  @override
  AssertionResult check(Program program) {
    final n = _countKind(program, node);
    final ok = n >= min && (max == null || n <= max!);
    return AssertionResult(this, ok,
        actual: n, expected: max == null ? min : '$min-$max');
  }

  @override
  Map<String, Object?> toJson() =>
      {'kind': kind, 'node': node, 'min': min, if (max != null) 'max': max};
}

/// `bodyLength(Repeat) >= 2` — the repair for concept C2.2, whose misconception is that
/// only the first line of a loop repeats.
class BodyLength extends StructuralAssertion {
  const BodyLength(this.node, {this.min = 1, this.max});
  final String node;
  final int min;
  final int? max;

  @override
  String get kind => 'bodyLength';

  @override
  AssertionResult check(Program program) {
    var best = 0;
    for (final n in walk(program)) {
      final body = switch (n) {
        Repeat(:final body) => body,
        While(:final body) => body,
        For(:final body) => body,
        ProcDef(:final body) => body,
        _ => null,
      };
      if (body == null || n.kind != node) continue;
      final real = body.where((s) => s is! Comment).length;
      if (real > best) best = real;
    }
    final ok = best >= min && (max == null || best <= max!);
    return AssertionResult(this, ok,
        actual: best, expected: max == null ? min : '$min-$max');
  }

  @override
  Map<String, Object?> toJson() =>
      {'kind': kind, 'node': node, 'min': min, if (max != null) 'max': max};
}

/// `blockCount <= 12`. The engine behind the T7 "le plus court" item type.
class BlockCountWithin extends StructuralAssertion {
  const BlockCountWithin({this.min = 0, this.max});
  final int min;
  final int? max;

  @override
  String get kind => 'blockCount';

  @override
  AssertionResult check(Program program) {
    final n = blockCount(program);
    final ok = n >= min && (max == null || n <= max!);
    return AssertionResult(this, ok, actual: n, expected: max ?? min);
  }

  @override
  Map<String, Object?> toJson() =>
      {'kind': kind, 'min': min, if (max != null) 'max': max};
}

/// `usesOnly([...])` — the structural half of palette scoping (`FR-M2-08`).
class UsesOnly extends StructuralAssertion {
  const UsesOnly(this.opcodeIds);
  final Set<String> opcodeIds;

  @override
  String get kind => 'usesOnly';

  @override
  AssertionResult check(Program program) {
    final used = <String>{};
    for (final n in walk(program)) {
      if (n is Command) used.add(n.opcode.id);
    }
    final extra = used.difference(opcodeIds);
    return AssertionResult(this, extra.isEmpty,
        actual: extra.length, expected: 0);
  }

  @override
  Map<String, Object?> toJson() =>
      {'kind': kind, 'opcodes': opcodeIds.toList()..sort()};
}

class UsesOpcode extends StructuralAssertion {
  const UsesOpcode(this.opcodeId, {this.min = 1, this.max});
  final String opcodeId;
  final int min;
  final int? max;

  @override
  String get kind => 'usesOpcode';

  @override
  AssertionResult check(Program program) {
    final n = walk(program)
        .whereType<Command>()
        .where((c) => c.opcode.id == opcodeId)
        .length;
    final ok = n >= min && (max == null || n <= max!);
    return AssertionResult(this, ok,
        actual: n, expected: max == null ? min : '$min-$max');
  }

  @override
  Map<String, Object?> toJson() => {
        'kind': kind,
        'opcode': opcodeId,
        'min': min,
        if (max != null) 'max': max,
      };
}

/// `noJumpWithPenDown` — concept C3.1's misconception, checked structurally rather than
/// behaviourally so the item can say *why* the figure is wrong, not merely that it is.
class NoJumpWithPenDown extends StructuralAssertion {
  const NoJumpWithPenDown();

  static const _jumps = {'GO', 'GO_X', 'GO_Y', 'CENTER'};

  @override
  String get kind => 'noJumpWithPenDown';

  @override
  AssertionResult check(Program program) {
    // A linear walk of the statements, tracking pen state. It does not follow branches,
    // and it says so: a heuristic that is honest about its scope is better than one that
    // pretends to be a simulator. The behavioural signal catches what this misses.
    var penDown = true;
    var offences = 0;
    for (final n in walk(program)) {
      if (n is! Command) continue;
      switch (n.opcode.id) {
        case 'PEN_UP':
          penDown = false;
        case 'PEN_DOWN':
          penDown = true;
        default:
          if (penDown && _jumps.contains(n.opcode.id)) offences++;
      }
    }
    return AssertionResult(this, offences == 0, actual: offences, expected: 0);
  }

  @override
  Map<String, Object?> toJson() => {'kind': kind};
}

/// `nestedInside(Repeat, Repeat)` — concept C2.3, nested loops.
class NestedInside extends StructuralAssertion {
  const NestedInside(this.outer, this.inner);
  final String outer;
  final String inner;

  @override
  String get kind => 'nestedInside';

  @override
  AssertionResult check(Program program) {
    var found = 0;
    void descend(Node node, bool insideOuter) {
      final isOuter = node.kind == outer;
      if (insideOuter && node.kind == inner) found++;
      for (final child in node.children) {
        descend(child, insideOuter || isOuter);
      }
    }

    descend(program, false);
    return AssertionResult(this, found >= 1, actual: found, expected: 1);
  }

  @override
  Map<String, Object?> toJson() =>
      {'kind': kind, 'outer': outer, 'inner': inner};
}

class DefinesProcedure extends StructuralAssertion {
  const DefinesProcedure({this.min = 1});
  final int min;

  @override
  String get kind => 'definesProcedure';

  @override
  AssertionResult check(Program program) {
    final n = _countKind(program, 'ProcDef');
    return AssertionResult(this, n >= min, actual: n, expected: min);
  }

  @override
  Map<String, Object?> toJson() => {'kind': kind, 'min': min};
}

class UsesVariable extends StructuralAssertion {
  const UsesVariable();

  @override
  String get kind => 'usesVariable';

  @override
  AssertionResult check(Program program) {
    final n = _countKind(program, 'Assign');
    return AssertionResult(this, n >= 1, actual: n, expected: 1);
  }

  @override
  Map<String, Object?> toJson() => {'kind': kind};
}
