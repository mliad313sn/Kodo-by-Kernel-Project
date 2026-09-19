/// AST to source text, in any keyword language.
///
/// This is the other half of the bridge. `parse` and `render` are inverses over canonical
/// text, and rendering the *same tree* through the French and the English table produces
/// the two programs a child compares in World 11 — which is not a feature, it is the
/// lesson.
library;

import 'ast.dart';
import 'keywords.dart';
import 'values.dart';

/// Renders [program] using [kw].
///
/// [indent] is the string used per nesting level. Two spaces is the canonical form and the
/// one the round-trip property is stated over.
String render(Program program, KeywordTable kw, {String indent = '  '}) {
  final buffer = StringBuffer();
  _Renderer(buffer, kw, indent).writeBody(program.body, 0);
  return buffer.toString().trimRight();
}

/// Renders one expression. Exposed for block help and for the inspector, which shows an
/// expression without its statement.
String renderExpression(AsExpr expr, KeywordTable kw) {
  final buffer = StringBuffer();
  _Renderer(buffer, kw, '  ').writeExpr(expr);
  return buffer.toString();
}

const _operatorWords = {
  'and': SyntaxWord.and,
  'or': SyntaxWord.or,
  'not': SyntaxWord.not
};

class _Renderer {
  _Renderer(this.out, this.kw, this.indent);

  final StringBuffer out;
  final KeywordTable kw;
  final String indent;

  void writeBody(List<AsStmt> body, int depth) {
    for (final stmt in body) {
      writeStmt(stmt, depth);
    }
  }

  void pad(int depth) => out.write(indent * depth);

  void writeStmt(AsStmt stmt, int depth) {
    switch (stmt) {
      case Comment(:final text):
        pad(depth);
        out.writeln('#$text');

      case Command():
        pad(depth);
        writeCall(kw.write(stmt.opcode, stmt.form), stmt.args);
        out.writeln();

      case ProcCall(:final name, :final args):
        pad(depth);
        writeCall(name, args);
        out.writeln();

      case Assign(:final variable, :final value):
        pad(depth);
        out.write('\$$variable = ');
        writeExpr(value);
        out.writeln();

      case WhenEvent(:final trigger, :final args, :final body):
        /* `quand drapeau { … }`. The trigger is written through the keyword table like
           every other word, so an English child reads `when flag` and a French one
           `quand drapeau` — the same tree, two projections, which is the rule this
           extension had to keep rather than bend. */
        pad(depth);
        out.write('${kw.writeSyntax(SyntaxWord.when_)} ${kw.write(trigger)}');
        for (var i = 0; i < args.length; i++) {
          out.write(i == 0 ? ' ' : ', ');
          writeExpr(args[i]);
        }
        writeBlock(body, depth);

      case Repeat(:final count, :final body):
        pad(depth);
        out.write('${kw.writeSyntax(SyntaxWord.repeat)} ');
        writeExpr(count);
        writeBlock(body, depth);

      case While(:final condition, :final body):
        pad(depth);
        out.write('${kw.writeSyntax(SyntaxWord.while_)} ');
        writeExpr(condition);
        writeBlock(body, depth);

      case For(
          :final variable,
          :final from,
          :final to,
          :final step,
          :final body
        ):
        pad(depth);
        out.write('${kw.writeSyntax(SyntaxWord.for_)} \$$variable = ');
        writeExpr(from);
        out.write(' ${kw.writeSyntax(SyntaxWord.to)} ');
        writeExpr(to);
        if (step != null) {
          out.write(' ${kw.writeSyntax(SyntaxWord.step)} ');
          writeExpr(step);
        }
        writeBlock(body, depth);

      case If():
        writeIf(stmt, depth);

      case ProcDef(:final name, :final params, :final body):
        pad(depth);
        out.write('${kw.writeSyntax(SyntaxWord.learn)} $name');
        for (var i = 0; i < params.length; i++) {
          out.write(i == 0 ? ' ' : ', ');
          out.write('\$${params[i]}');
        }
        writeBlock(body, depth);

      case Return(:final value):
        pad(depth);
        out.write(kw.writeSyntax(SyntaxWord.return_));
        if (value != null) {
          out.write(' ');
          writeExpr(value);
        }
        out.writeln();

      case Break():
        pad(depth);
        out.writeln(kw.writeSyntax(SyntaxWord.break_));

      case Exit():
        pad(depth);
        out.writeln(kw.writeSyntax(SyntaxWord.exit));

      default:
        throw StateError('renderer has no case for ${(stmt as Node).kind}');
    }
  }

  void writeIf(If node, int depth) {
    pad(depth);
    out.write('${kw.writeSyntax(SyntaxWord.if_)} ');
    writeExpr(node.condition);
    out.writeln(' {');
    writeBody(node.then, depth + 1);
    pad(depth);
    final orElse = node.orElse;
    if (orElse == null) {
      out.writeln('}');
      return;
    }
    out.write('} ${kw.writeSyntax(SyntaxWord.else_)} ');
    // `sinon si` renders as a chain rather than as a nested block, because that is how the
    // child wrote it and the toggle must not restructure their program.
    if (orElse.length == 1 && orElse.first is If) {
      final buffer = StringBuffer();
      _Renderer(buffer, kw, indent).writeIf(orElse.first as If, depth);
      out.write(buffer.toString().trimLeft());
      return;
    }
    out.writeln('{');
    writeBody(orElse, depth + 1);
    pad(depth);
    out.writeln('}');
  }

  void writeBlock(List<AsStmt> body, int depth) {
    out.writeln(' {');
    writeBody(body, depth + 1);
    pad(depth);
    out.writeln('}');
  }

  void writeCall(String word, List<AsExpr> args) {
    out.write(word);
    for (var i = 0; i < args.length; i++) {
      out.write(i == 0 ? ' ' : ', ');
      writeExpr(args[i]);
    }
  }

  void writeExpr(AsExpr expr) {
    switch (expr) {
      case Literal(:final value):
        if (value is BoolValue) {
          out.write(kw
              .writeSyntax(value.value ? SyntaxWord.true_ : SyntaxWord.false_));
        } else {
          out.write(value.source);
        }
      case VarRef(:final name):
        out.write('\$$name');
      case Group(:final inner):
        out.write('(');
        writeExpr(inner);
        out.write(')');
      case BinOp(:final op, :final left, :final right):
        writeExpr(left);
        final word = _operatorWords[op];
        out.write(' ${word == null ? op : kw.writeSyntax(word)} ');
        writeExpr(right);
      case UnOp(:final op, :final operand):
        if (op == 'not') {
          out.write('${kw.writeSyntax(SyntaxWord.not)} ');
        } else {
          out.write(op);
        }
        writeExpr(operand);
      case Command():
        writeCall(kw.write(expr.opcode, expr.form), expr.args);
      case ProcCall(:final name, :final args):
        writeCall(name, args);
      case ListLiteral(:final items):
        out.write('[');
        for (var i = 0; i < items.length; i++) {
          if (i > 0) out.write(', ');
          writeExpr(items[i]);
        }
        out.write(']');
      case IndexOf(:final target, :final index):
        writeExpr(target);
        out.write('[');
        writeExpr(index);
        out.write(']');
      default:
        throw StateError('renderer has no case for ${(expr as Node).kind}');
    }
  }
}
