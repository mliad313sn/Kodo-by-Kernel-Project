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
  Opcode.toNumber: 'float',
  /* Everything below has no turtle equivalent, so it is rendered as a plain function
     call and the header defines a stub for it. A projection whose promise is "you could
     paste this elsewhere" has to produce Python that runs; one that raises `NameError`
     on line three keeps none of that promise. The stubs do nothing, which is honest —
     `turtle` has no sprites and no drums. */
  Opcode.keyDown: 'key_down',
  Opcode.mouseX: 'mouse_x',
  Opcode.mouseY: 'mouse_y',
  Opcode.mouseDown: 'mouse_down',
  Opcode.touchingEdge: 'touching_edge',
  Opcode.touchingColour: 'touching_colour',
  Opcode.selectSprite: 'select_sprite',
  Opcode.nextCostume: 'next_costume',
  Opcode.setCostume: 'set_costume',
  Opcode.costumeNumber: 'costume_number',
  Opcode.setBackdrop: 'set_backdrop',
  Opcode.setEffect: 'set_effect',
  Opcode.clearEffects: 'clear_effects',
  Opcode.say: 'say',
  Opcode.playSound: 'play_sound',
  Opcode.playDrum: 'play_drum',
  Opcode.playNote: 'play_note',
  Opcode.whenFlag: 'on_flag',
  Opcode.whenKey: 'on_key',
  Opcode.whenClicked: 'on_click',
};

/// The opcodes `turtle` has no answer for, and the stub each one gets.
///
/// Only the ones a program actually uses are emitted, so a World 2 square still renders
/// as four lines of turtle with nothing above it.
const _stubbed = <Opcode, String>{
  Opcode.keyDown: 'def key_down(name):\\n    return False',
  Opcode.mouseX: 'def mouse_x():\\n    return 0',
  Opcode.mouseY: 'def mouse_y():\\n    return 0',
  Opcode.mouseDown: 'def mouse_down():\\n    return False',
  Opcode.touchingEdge: 'def touching_edge():\\n    return False',
  Opcode.touchingColour: 'def touching_colour(r, g, b):\\n    return False',
  Opcode.selectSprite: 'def select_sprite(name):\\n    pass',
  Opcode.nextCostume: 'def next_costume():\\n    pass',
  Opcode.setCostume: 'def set_costume(number):\\n    pass',
  Opcode.costumeNumber: 'def costume_number():\\n    return 1',
  Opcode.setBackdrop: 'def set_backdrop(name):\\n    pass',
  Opcode.setEffect: 'def set_effect(name, value):\\n    pass',
  Opcode.clearEffects: 'def clear_effects():\\n    pass',
  Opcode.say: 'def say(text):\\n    print(text)',
  Opcode.playSound: 'def play_sound(name):\\n    pass',
  Opcode.playDrum: 'def play_drum(drum, beats):\\n    pass',
  Opcode.playNote: 'def play_note(pitch, beats):\\n    pass',
  Opcode.whenFlag: 'def on_flag():\\n    pass',
  Opcode.whenKey: 'def on_key(name):\\n    pass',
  Opcode.whenClicked: 'def on_click():\\n    pass',
};

/// Renders [program] as Python. [header] adds the import preamble.
String toPython(Program program, {bool header = true}) {
  final out = StringBuffer();
  if (header) {
    out.writeln('import math');
    out.writeln('import random');
    out.writeln('import time');
    out.writeln('from turtle import *');
    out.writeln();
    // Only the stubs this program needs, in opcode order so the output is stable.
    final used = walk(program).whereType<Command>().map((c) => c.opcode).toSet()
      ..addAll(walk(program).whereType<WhenEvent>().map((w) => w.trigger));
    final needed =
        Opcode.values.where((o) => used.contains(o) && _stubbed.containsKey(o));
    if (needed.isNotEmpty) {
      out.writeln('# KODO a des lutins et des sons ; turtle n\'en a pas.');
      for (final op in needed) {
        out.writeln(_stubbed[op]);
      }
      out.writeln();
    }
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
    /* `quand drapeau { … }` becomes a function you could call. turtle has no events, so
       the projection cannot promise the body runs by itself — but it can promise the
       body is there, named after the thing that triggers it, which is what a child
       reading their own program in another language needs. */
    case WhenEvent(:final trigger, :final args, :final body):
      _pad(out, depth);
      final name = _pythonNames[trigger] ?? trigger.id.toLowerCase();
      final params = args.map(_expr).join(', ');
      out.writeln('def ${name}_script(${params.isEmpty ? '' : '_$params'}):'
          .replaceAll('"', ''));
      _writeBody(out, body, depth + 1);
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
