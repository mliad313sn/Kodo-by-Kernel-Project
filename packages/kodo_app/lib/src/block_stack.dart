/// Grabbing a stack by its top block (`FR-M2-06`).
///
/// *"Grab a stack by its top block"* — [SC p.6] — is one line of specification and the
/// whole of what makes a block editor feel like blocks. A child who drags `avance 10` out
/// of the middle of a program and gets only that one block has been handed a list widget.
/// A child who drags it and the four blocks under it come along has been handed a *stack*,
/// and from there they reorganise a program the way they think about it: in pieces.
///
/// Three rules follow from the one line, and all three are here rather than in the widget,
/// because they are the part worth testing:
///
/// 1. **A stack is the block and its later siblings, in its own body.** `avance 10` inside
///    a `répète` takes the rest of the loop's body with it and nothing outside the loop.
///    The loop is the child's bracket; a grab may not reach through it.
/// 2. **A C-block takes its mouth with it.** That falls out of the tree for free — the body
///    is a child of the node — and is exactly why this operates on the AST rather than on
///    the flattened rows the editor draws.
/// 3. **A loop may not be dropped inside itself.** The only move that can destroy a
///    program, and the one a child will try within a minute of learning the gesture.
library;

import 'package:kodo_lang/kodo_lang.dart';

/// Which of a block's mouths a drop is aimed at.
///
/// Only `si … sinon` has two, and only because the `sinon` mouth is a separate place a
/// child can drop into — a program with something in `sinon` is not the same program as
/// one with it at the end of `si`.
enum BodySlot { body, orElse }

/// A place a stack can land: a mouth, and a position in it.
class DropSite {
  const DropSite({this.ownerId, this.slot = BodySlot.body, required this.index});

  /// The C-block whose mouth this is, or null for the program's own body.
  final String? ownerId;
  final BodySlot slot;

  /// How many statements come before the drop. Zero is "above everything here".
  final int index;

  @override
  String toString() => '${ownerId ?? 'program'}/${slot.name}@$index';

  @override
  bool operator ==(Object other) =>
      other is DropSite &&
      other.ownerId == ownerId &&
      other.slot == slot &&
      other.index == index;

  @override
  int get hashCode => Object.hash(ownerId, slot, index);
}

/// Rebuilds [stmt] with each of its mouths passed through [map].
///
/// Every statement that can hold other statements goes through here, so a new one added to
/// the language is a compile error in this file rather than a block that silently cannot be
/// dragged into.
AsStmt rebuildBodies(
    AsStmt stmt, List<AsStmt> Function(List<AsStmt> body, BodySlot slot) map) {
  switch (stmt) {
    case Repeat(:final id, :final span, :final count, :final body):
      return Repeat(id, span, count, map(body, BodySlot.body));
    case While(:final id, :final span, :final condition, :final body):
      return While(id, span, condition, map(body, BodySlot.body));
    case For(
        :final id,
        :final span,
        :final variable,
        :final from,
        :final to,
        :final step,
        :final body
      ):
      return For(id, span, variable, from, to, step, map(body, BodySlot.body));
    case If(:final id, :final span, :final condition, :final then, :final orElse):
      return If(id, span, condition, map(then, BodySlot.body),
          orElse == null ? null : map(orElse, BodySlot.orElse));
    case ProcDef(:final id, :final span, :final name, :final params, :final body):
      return ProcDef(id, span, name, params, map(body, BodySlot.body));
    case WhenEvent(:final id, :final span, :final trigger, :final args, :final body):
      return WhenEvent(id, span, trigger, args, map(body, BodySlot.body));
    default:
      // A leaf: a command, an assignment, a comment. Nothing to rebuild.
      return stmt;
  }
}

/// Every statement in [program], at any depth.
Iterable<AsStmt> allStatements(Program program) sync* {
  Iterable<AsStmt> walk(List<AsStmt> body) sync* {
    for (final stmt in body) {
      yield stmt;
      for (final slot in _mouthsOf(stmt)) {
        yield* walk(slot);
      }
    }
  }

  yield* walk(program.body);
}

List<List<AsStmt>> _mouthsOf(AsStmt stmt) => switch (stmt) {
      Repeat(:final body) => [body],
      While(:final body) => [body],
      For(:final body) => [body],
      If(:final then, :final orElse) => [then, if (orElse != null) orElse],
      ProcDef(:final body) => [body],
      WhenEvent(:final body) => [body],
      _ => const [],
    };

/// The stack whose top block is [topId]: that block and every later block in its own body.
///
/// Empty when there is no such block. Rule 1 of the three: the search never leaves the body
/// the block is in, so a block inside a loop takes the rest of the loop and stops there.
List<AsStmt> stackAt(Program program, String topId) {
  List<AsStmt>? find(List<AsStmt> body) {
    final at = body.indexWhere((s) => (s as Node).id == topId);
    if (at >= 0) return body.sublist(at);
    for (final stmt in body) {
      for (final mouth in _mouthsOf(stmt)) {
        final found = find(mouth);
        if (found != null) return found;
      }
    }
    return null;
  }

  return find(program.body) ?? const [];
}

/// Where a stack's top block currently sits.
DropSite? siteOf(Program program, String topId) {
  DropSite? find(List<AsStmt> body, String? ownerId, BodySlot slot) {
    final at = body.indexWhere((s) => (s as Node).id == topId);
    if (at >= 0) return DropSite(ownerId: ownerId, slot: slot, index: at);
    for (final stmt in body) {
      if (stmt is If) {
        final inThen = find(stmt.then, stmt.id, BodySlot.body);
        if (inThen != null) return inThen;
        final orElse = stmt.orElse;
        if (orElse != null) {
          final inElse = find(orElse, stmt.id, BodySlot.orElse);
          if (inElse != null) return inElse;
        }
        continue;
      }
      for (final mouth in _mouthsOf(stmt)) {
        final found = find(mouth, (stmt as Node).id, BodySlot.body);
        if (found != null) return found;
      }
    }
    return null;
  }

  return find(program.body, null, BodySlot.body);
}

/// [program] with the stack topped by [topId] taken out of it.
Program detachStack(Program program, String topId) {
  var done = false;

  List<AsStmt> prune(List<AsStmt> body) {
    if (!done) {
      final at = body.indexWhere((s) => (s as Node).id == topId);
      if (at >= 0) {
        done = true;
        return body.sublist(0, at);
      }
    }
    return [for (final stmt in body) rebuildBodies(stmt, (b, _) => prune(b))];
  }

  return Program(program.id, program.span, prune(program.body));
}

/// [program] with [stack] inserted at [site].
///
/// A site that names a mouth the program does not have leaves the program alone: a drop
/// target that has gone away between the grab and the release is a miss, not a crash.
Program dropStack(Program program, List<AsStmt> stack, DropSite site) {
  if (stack.isEmpty) return program;

  List<AsStmt> insert(List<AsStmt> body) =>
      [...body.take(site.index), ...stack, ...body.skip(site.index)];

  if (site.ownerId == null) {
    return Program(program.id, program.span, insert(program.body));
  }

  List<AsStmt> place(List<AsStmt> body) => [
        for (final stmt in body)
          rebuildBodies(
            stmt,
            (mouth, slot) => (stmt as Node).id == site.ownerId &&
                    slot == site.slot
                ? insert(mouth)
                : place(mouth),
          ),
      ];

  return Program(program.id, program.span, place(program.body));
}

/// Whether the stack topped by [topId] may be dropped at [site].
///
/// Rule 3: a loop may not be dropped inside itself. It is the one move that turns a program
/// into a tree that cannot be drawn, and a child learning the gesture will try it — so the
/// answer is a refused drop that leaves the program exactly as it was, never an exception
/// and never a program that has quietly eaten itself.
bool canDrop(Program program, String topId, DropSite site) {
  if (site.ownerId == null) return true;
  final moving = stackAt(program, topId);
  if (moving.isEmpty) return false;
  final grabbed = Program(program.id, program.span, moving);
  return !allStatements(grabbed).any((s) => (s as Node).id == site.ownerId);
}

/// [program] with the stack topped by [topId] moved to [site].
///
/// Returns the program unchanged when the move is refused or is a move to where the stack
/// already is. The site's index is read against the program *before* the detachment, which
/// is what a child means when they point at a gap they can see.
Program moveStack(Program program, String topId, DropSite site) {
  if (!canDrop(program, topId, site)) return program;
  final stack = stackAt(program, topId);
  if (stack.isEmpty) return program;

  final from = siteOf(program, topId);
  if (from == site) return program;

  final detached = detachStack(program, topId);
  /* A stack reaches to the end of its own mouth, so taking it out leaves that mouth with
     exactly `from.index` statements — and a target the child pointed at further down is
     now past the end. Clamping here rather than letting `dropStack` run off the end is
     what keeps a downward drag inside the same loop from being a no-op with a stack
     appended twice. */
  var index = site.index;
  if (from != null &&
      from.ownerId == site.ownerId &&
      from.slot == site.slot &&
      index > from.index) {
    index = from.index;
  }
  return dropStack(detached, stack,
      DropSite(ownerId: site.ownerId, slot: site.slot, index: index));
}
