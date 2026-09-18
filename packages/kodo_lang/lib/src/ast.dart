/// The one AST (FR-M1-01).
///
/// Blocks and text are two projections of this tree. There is no second representation
/// anywhere in KODO: the block editor (M2) edits these nodes, the text editor (M3) renders
/// and parses them, the grader (M6) asserts over them, and a stored attempt (`FR-M6-08`)
/// is one of these serialised. If you are about to add a parallel model, that is a
/// specification change and it goes back to G1.
library;

import 'keywords.dart';
import 'opcodes.dart';
import 'span.dart';
import 'values.dart';

/// Base of every node.
abstract class Node {
  Node(this.id, this.span);

  /// Stable within a parse and preserved across serialisation.
  ///
  /// The interpreter reports it on every [ExecutionEvent], the grader stores it against an
  /// error, and both editors use it to highlight. It is assigned in document order, so the
  /// same source always yields the same ids — which is what makes a stored attempt
  /// replayable to an identical verdict.
  final String id;
  final SourceSpan span;

  String get kind;

  /// Children in evaluation order. Used by the fuzzer, the structural grader and the
  /// inspector's execution tree, so no visitor has to know every node type.
  List<Node> get children;

  Map<String, Object?> toJson();
}

/// A node that may stand as a statement.
mixin AsStmt on Node {}

/// A node that may stand in a value position.
mixin AsExpr on Node {}

// ---------------------------------------------------------------------------------------
// Program
// ---------------------------------------------------------------------------------------

class Program extends Node {
  Program(super.id, super.span, this.body);
  final List<AsStmt> body;

  @override
  String get kind => 'Program';

  @override
  List<Node> get children => body.cast<Node>();

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'body': [for (final s in body) (s as Node).toJson()],
      };
}

// ---------------------------------------------------------------------------------------
// Statements
// ---------------------------------------------------------------------------------------

/// A built-in call. Valid as a statement and as a value; `hasard 1 10` is both.
///
/// A command used in a value position raises `E_NOT_A_VALUE` at runtime rather than
/// yielding nothing quietly, because `$x = avance 100` is a sentence a child writes and it
/// deserves an answer.
class Command extends Node with AsStmt, AsExpr {
  Command(super.id, super.span, this.opcode, this.args,
      {this.form = KeywordForm.primary});
  final Opcode opcode;
  final List<AsExpr> args;

  /// Which written form the program used: `avance` or `av`.
  ///
  /// Not the lexeme — the *form*. A child who typed `av` reads `av` after a block
  /// round-trip and `fd` after switching to English keywords. Storing the string instead
  /// would pin the program to one language and break `FR-M15-03`.
  final KeywordForm form;

  @override
  String get kind => 'Command';

  @override
  List<Node> get children => args.cast<Node>();

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'op': opcode.id,
        'form': form.name,
        'args': [for (final a in args) (a as Node).toJson()],
      };
}

class Repeat extends Node with AsStmt {
  Repeat(super.id, super.span, this.count, this.body);
  final AsExpr count;
  final List<AsStmt> body;

  @override
  String get kind => 'Repeat';

  @override
  List<Node> get children => [count as Node, ...body.cast<Node>()];

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'count': (count as Node).toJson(),
        'body': [for (final s in body) (s as Node).toJson()],
      };
}

class While extends Node with AsStmt {
  While(super.id, super.span, this.condition, this.body);
  final AsExpr condition;
  final List<AsStmt> body;

  @override
  String get kind => 'While';

  @override
  List<Node> get children => [condition as Node, ...body.cast<Node>()];

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'cond': (condition as Node).toJson(),
        'body': [for (final s in body) (s as Node).toJson()],
      };
}

class For extends Node with AsStmt {
  For(super.id, super.span, this.variable, this.from, this.to, this.step,
      this.body);
  final String variable;
  final AsExpr from;
  final AsExpr to;

  /// `null` when the program wrote no `pas` clause. Defaults to 1 at run time; kept null in
  /// the tree so that `render(parse(x)) == x` does not invent a clause the child never typed.
  final AsExpr? step;
  final List<AsStmt> body;

  @override
  String get kind => 'For';

  @override
  List<Node> get children => [
        from as Node,
        to as Node,
        if (step != null) step! as Node,
        ...body.cast<Node>(),
      ];

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'var': variable,
        'from': (from as Node).toJson(),
        'to': (to as Node).toJson(),
        'step': step == null ? null : (step! as Node).toJson(),
        'body': [for (final s in body) (s as Node).toJson()],
      };
}

class If extends Node with AsStmt {
  If(super.id, super.span, this.condition, this.then, this.orElse);
  final AsExpr condition;
  final List<AsStmt> then;
  final List<AsStmt>? orElse;

  @override
  String get kind => 'If';

  @override
  List<Node> get children => [
        condition as Node,
        ...then.cast<Node>(),
        ...?orElse?.cast<Node>(),
      ];

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'cond': (condition as Node).toJson(),
        'then': [for (final s in then) (s as Node).toJson()],
        'else': orElse == null
            ? null
            : [for (final s in orElse!) (s as Node).toJson()],
      };
}

class Assign extends Node with AsStmt {
  Assign(super.id, super.span, this.variable, this.value);
  final String variable;
  final AsExpr value;

  @override
  String get kind => 'Assign';

  @override
  List<Node> get children => [value as Node];

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'var': variable,
        'value': (value as Node).toJson(),
      };
}

class ProcDef extends Node with AsStmt {
  ProcDef(super.id, super.span, this.name, this.params, this.body);
  final String name;
  final List<String> params;
  final List<AsStmt> body;

  @override
  String get kind => 'ProcDef';

  @override
  List<Node> get children => body.cast<Node>();

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'name': name,
        'params': params,
        'body': [for (final s in body) (s as Node).toJson()],
      };
}

/// A call to a procedure the child defined with `apprends`. Statement or value.
class ProcCall extends Node with AsStmt, AsExpr {
  ProcCall(super.id, super.span, this.name, this.args);
  final String name;
  final List<AsExpr> args;

  @override
  String get kind => 'ProcCall';

  @override
  List<Node> get children => args.cast<Node>();

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'name': name,
        'args': [for (final a in args) (a as Node).toJson()],
      };
}

class Return extends Node with AsStmt {
  Return(super.id, super.span, this.value);
  final AsExpr? value;

  @override
  String get kind => 'Return';

  @override
  List<Node> get children => [if (value != null) value! as Node];

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'value': value == null ? null : (value! as Node).toJson(),
      };
}

/// `coupure` — leave the innermost loop.
class Break extends Node with AsStmt {
  Break(super.id, super.span);

  @override
  String get kind => 'Break';

  @override
  List<Node> get children => const [];

  @override
  Map<String, Object?> toJson() => {'k': kind, 'id': id, 'sp': span.toJson()};
}

/// `sortie` — end the program.
class Exit extends Node with AsStmt {
  Exit(super.id, super.span);

  @override
  String get kind => 'Exit';

  @override
  List<Node> get children => const [];

  @override
  Map<String, Object?> toJson() => {'k': kind, 'id': id, 'sp': span.toJson()};
}

/// A `#` comment, kept in the tree.
///
/// Comments are nodes and not trivia because World 11 teaches commenting a line out as a
/// *debugging tool* (`FR-M3-04`, concept C11.2). A tree that discards comments cannot
/// round-trip that lesson, and a child who loses their note when they toggle to blocks has
/// been taught that the toggle is unsafe.
class Comment extends Node with AsStmt {
  Comment(super.id, super.span, this.text);

  /// The text after `#`, verbatim, without the marker.
  final String text;

  @override
  String get kind => 'Comment';

  @override
  List<Node> get children => const [];

  @override
  Map<String, Object?> toJson() =>
      {'k': kind, 'id': id, 'sp': span.toJson(), 'text': text};
}

// ---------------------------------------------------------------------------------------
// Expressions
// ---------------------------------------------------------------------------------------

class Literal extends Node with AsExpr {
  Literal(super.id, super.span, this.value);
  final KodoValue value;

  @override
  String get kind => 'Literal';

  @override
  List<Node> get children => const [];

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'type': value.typeKey,
        'v': switch (value) {
          NumberValue(:final value) => value,
          StringValue(:final value) => value,
          BoolValue(:final value) => value,
          ListValue(:final items) => [for (final i in items) i.source],
          VoidValue() => null,
        },
      };
}

class VarRef extends Node with AsExpr {
  VarRef(super.id, super.span, this.name);

  /// Without the `$` sigil; the sigil is syntax, not part of the name.
  final String name;

  @override
  String get kind => 'VarRef';

  @override
  List<Node> get children => const [];

  @override
  Map<String, Object?> toJson() =>
      {'k': kind, 'id': id, 'sp': span.toJson(), 'name': name};
}

/// Binary operator. [op] is canonical (`+`, `==`, `and`), never the displayed keyword —
/// `et` and `and` are one operator with two costumes, exactly as `avance` and `forward`
/// are one opcode with two costumes.
class BinOp extends Node with AsExpr {
  BinOp(super.id, super.span, this.op, this.left, this.right);
  final String op;
  final AsExpr left;
  final AsExpr right;

  @override
  String get kind => 'BinOp';

  @override
  List<Node> get children => [left as Node, right as Node];

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'op': op,
        'l': (left as Node).toJson(),
        'r': (right as Node).toJson(),
      };
}

/// Unary operator: `-` or canonical `not`.
class UnOp extends Node with AsExpr {
  UnOp(super.id, super.span, this.op, this.operand);
  final String op;
  final AsExpr operand;

  @override
  String get kind => 'UnOp';

  @override
  List<Node> get children => [operand as Node];

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'op': op,
        'x': (operand as Node).toJson(),
      };
}

/// A parenthesised expression, preserved so that `render(parse(x)) == x`.
///
/// Dropping redundant parentheses would be mathematically harmless and pedagogically
/// destructive: concept C6.3's misconception is *"operations always run left to right"*,
/// and the repair is a child adding brackets and watching the answer change. If the editor
/// silently removed them, the lesson would delete itself.
class Group extends Node with AsExpr {
  Group(super.id, super.span, this.inner);
  final AsExpr inner;

  @override
  String get kind => 'Group';

  @override
  List<Node> get children => [inner as Node];

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'inner': (inner as Node).toJson()
      };
}

/// A list literal: `[1, 2, 3]`. World 12, concept C12.2.
class ListLiteral extends Node with AsExpr {
  ListLiteral(super.id, super.span, this.items);
  final List<AsExpr> items;

  @override
  String get kind => 'ListLiteral';

  @override
  List<Node> get children => items.cast<Node>();

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        'items': [for (final i in items) (i as Node).toJson()],
      };
}

/// Indexing: `$liste[2]`.
class IndexOf extends Node with AsExpr {
  IndexOf(super.id, super.span, this.target, this.index);
  final AsExpr target;
  final AsExpr index;

  @override
  String get kind => 'IndexOf';

  @override
  List<Node> get children => [target as Node, index as Node];

  @override
  Map<String, Object?> toJson() => {
        'k': kind,
        'id': id,
        'sp': span.toJson(),
        't': (target as Node).toJson(),
        'i': (index as Node).toJson(),
      };
}

// ---------------------------------------------------------------------------------------
// Walking
// ---------------------------------------------------------------------------------------

/// Every node of [root] in document order, itself first.
Iterable<Node> walk(Node root) sync* {
  yield root;
  for (final c in root.children) {
    yield* walk(c);
  }
}

/// Counts nodes a child would recognise as blocks, for `blockCount <= n` assertions in the
/// M6 structural grader and for the World-2 "le plus court" (T7) item type.
///
/// Comments are not blocks and literals are not blocks; a child counting the blocks on
/// their screen counts neither.
int blockCount(Node root) => walk(root)
    .where((n) => n is AsStmt && n is! Comment && n is! Program)
    .length;
