/// A third, one-way projection of the same tree (FR-M3-09, PO decision D-005).
///
/// World 12 offers a child *"regarde ton programme en Python"*. What they get is their own
/// program, rendered as Python they could paste elsewhere — with a `turtle` preamble, their
/// comments preserved, and their variable names intact.
///
/// It is read-only and it is one-way. No Python is parsed and no Python is executed: that
/// would be a second parser and a second interpreter, which §11.2 and the M1 prompt both
/// forbid, and it would put the grader's honesty at risk. This file is here to keep that
/// line visible — it is a *renderer*, and it is under 150 lines because that is all a third
/// projection of an existing AST costs.
library;

import 'ast.dart';
import 'opcodes.dart';
import 'values.dart';

const _pythonNames = <Opcode, String>{
  Opcode.moveForward: 'forward',
  Opcode.moveBack: 'backward',
  Opcode.turnLeft: 'left',
  Opcode.turnRight: 'right',
  Opcode.setDirection: 'setheading',
  Opcode.getDirection: 'heading',
  Opcode.center: 'home',
  Opcode.go: 'goto',
  Opcode.goX: 'setx',
  Opcode.goY: 'sety',
  Opcode.positionX: 'xcor',
  Opcode.positionY: 'ycor',
  Opcode.penUp: 'penup',
  Opcode.penDown: 'pendown',
  Opcode.penWidth: 'width',
  Opcode.penColor: 'pencolor',
  Opcode.canvasSize: 'screensize',
  Opcode.canvasColor: 'bgcolor',
  Opcode.clear: 'clear',
  Opcode.reset: 'reset',
  Opcode.show: 'showturtle',
  Opcode.hide: 'hideturtle',
  Opcode.print: 'write',
  Opcode.round: 'round',
  Opcode.sqrt: 'math.sqrt',
  Opcode.pi: 'math.pi',
  Opcode.sin: 'math.sin',
  Opcode.cos: 'math.cos',
  Opcode.tan: 'math.tan',
  Opcode.arcsin: 'math.asin',
  Opcode.arccos: 'math.acos',
  Opcode.arctan: 'math.atan',
};

/// Renders [program] as Python. [header] adds the import preamble.
String toPython(Program program, {bool header = true}) {
  final out = StringBuffer();
  if (header) {
    out.writeln('import math');
    out.writeln('import random');
    out.writeln('from turtle import *');
    out.writeln();
  }
  _writeBody(out, program.body, 0);
  return out.toString().trimRight();
}

void _pad(StringBuffer out, int depth) => out.write('    ' * depth);

void _writeBody(StringBuffer out, List<AsStmt> body, int depth) {
  var wroteStatement = false;
  for (final s in body) {
    _writeStmt(out, s, depth);
    if (s is! Comment) wroteStatement = true;
  }
  if (!wroteStatement) {
    _pad(out, depth);
    out.writeln('pass');
  }
}

void _writeStmt(StringBuffer out, AsStmt stmt, int depth) {
  switch (stmt) {
    case Comment(:final text):
      _pad(out, depth);
      out.writeln('#$text');
    case Command():
      _pad(out, depth);
      out.writeln(_expr(stmt));
    case ProcCall():
      _pad(out, depth);
      out.writeln(_expr(stmt));
    case Assign(:final variable, :final value):
      _pad(out, depth);
      out.writeln('$variable = ${_expr(value)}');
    case Repeat(:final count, :final body):
      _pad(out, depth);
      out.writeln('for _ in range(int(${_expr(count)})):');
      _writeBody(out, body, depth + 1);
    case While(:final condition, :final body):
      _pad(out, depth);
      out.writeln('while ${_expr(condition)}:');
      _writeBody(out, body, depth + 1);
    case For(:final variable, :final from, :final to, :final step, :final body):
      _pad(out, depth);
      final stride = step == null ? '1' : _expr(step);
      out.writeln('for $variable in range(int(${_expr(from)}), '
          'int(${_expr(to)}) + 1, int($stride)):');
      _writeBody(out, body, depth + 1);
    case If(:final condition, :final then, :final orElse):
      _pad(out, depth);
      out.writeln('if ${_expr(condition)}:');
      _writeBody(out, then, depth + 1);
      if (orElse != null) {
        _pad(out, depth);
        out.writeln('else:');
        _writeBody(out, orElse, depth + 1);
      }
    case ProcDef(:final name, :final params, :final body):
      _pad(out, depth);
      out.writeln('def $name(${params.join(', ')}):');
      _writeBody(out, body, depth + 1);
    case Return(:final value):
      _pad(out, depth);
      out.writeln(value == null ? 'return' : 'return ${_expr(value)}');
    case Break():
      _pad(out, depth);
      out.writeln('break');
    case Exit():
      _pad(out, depth);
      out.writeln('raise SystemExit');
    default:
      throw StateError('no Python for ${(stmt as Node).kind}');
  }
}

String _expr(AsExpr e) => switch (e) {
      Literal(:final value) => switch (value) {
          BoolValue(:final value) => value ? 'True' : 'False',
          _ => value.source,
        },
      VarRef(:final name) => name,
      Group(:final inner) => '(${_expr(inner)})',
      BinOp(:final op, :final left, :final right) =>
        '${_expr(left)} ${_pythonOperator(op)} ${_expr(right)}',
      UnOp(:final op, :final operand) =>
        op == 'not' ? 'not ${_expr(operand)}' : '-${_expr(operand)}',
      ListLiteral(:final items) => '[${items.map(_expr).join(', ')}]',
      IndexOf(:final target, :final index) =>
        '${_expr(target)}[${_expr(index)} - 1]',
      ProcCall(:final name, :final args) =>
        '$name(${args.map(_expr).join(', ')})',
      Command() => _builtin(e),
      _ => throw StateError('no Python for ${(e as Node).kind}'),
    };

String _builtin(Command c) {
  final args = c.args.map(_expr).join(', ');
  return switch (c.opcode) {
    Opcode.random => 'random.randint($args)',
    Opcode.mod => '(${c.args.map(_expr).join(' % ')})',
    Opcode.wait => 'time.sleep($args)',
    Opcode.message => 'print($args)',
    Opcode.ask => 'input($args)',
    Opcode.assertion => 'assert $args',
    Opcode.fontSize => 'pass  # taillepolice',
    final op => '${_pythonNames[op] ?? op.id.toLowerCase()}($args)',
  };
}

String _pythonOperator(String op) => switch (op) {
      'and' => 'and',
      'or' => 'or',
      '^' => '**',
      _ => op,
    };
