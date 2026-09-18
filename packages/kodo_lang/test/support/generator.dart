/// A generator of random *valid* KodoScript programs.
///
/// Used by the round-trip, locale-swap and determinism acceptance tests. It builds ASTs
/// rather than text, so the round-trip property is stated over `render`'s own canonical
/// form and no second printer exists to disagree with the first.
library;

import 'package:kodo_lang/kodo_lang.dart';

class ProgramGenerator {
  ProgramGenerator(int seed) : _random = SeededRandom(seed);

  final SeededRandom _random;
  int _ids = 0;
  int _depth = 0;
  final List<String> _variables = [];
  final List<ProcDef> _procedures = [];

  String _id() => 'g${++_ids}';

  int _int(int maxExclusive) => _random.nextIntInclusive(0, maxExclusive - 1);

  T _pick<T>(List<T> options) => options[_int(options.length)];

  bool _chance(int percent) => _random.nextIntInclusive(1, 100) <= percent;

  static const _safeCommands = [
    Opcode.moveForward,
    Opcode.moveBack,
    Opcode.turnLeft,
    Opcode.turnRight,
    Opcode.penUp,
    Opcode.penDown,
    Opcode.center,
    Opcode.go,
    Opcode.goX,
    Opcode.goY,
    Opcode.penWidth,
    Opcode.penColor,
    Opcode.clear,
    Opcode.show,
    Opcode.hide,
  ];

  Program generate({int statements = 6}) {
    _variables.clear();
    _procedures.clear();
    final body = <AsStmt>[];
    if (_chance(25)) body.add(_procedureDefinition());
    for (var i = 0; i < statements; i++) {
      body.add(_statement());
    }
    return Program(_id(), SourceSpan.none, body);
  }

  ProcDef _procedureDefinition() {
    final name = 'bloc${_int(900) + 100}';
    final params = _chance(60) ? ['p${_int(90) + 10}'] : <String>[];
    _variables.addAll(params);
    final body = <AsStmt>[
      for (var i = 0; i < 1 + _int(2); i++) _simpleStatement()
    ];
    if (_chance(30)) {
      body.add(Return(_id(), SourceSpan.none, _numberExpression()));
    }
    final def = ProcDef(_id(), SourceSpan.none, name, params, body);
    _procedures.add(def);
    for (final p in params) {
      _variables.remove(p);
    }
    return def;
  }

  AsStmt _statement() {
    if (_depth >= 2) return _simpleStatement();
    final roll = _int(100);
    if (roll < 45) return _simpleStatement();
    if (roll < 60) return _repeat();
    if (roll < 70) return _ifStatement();
    if (roll < 78) return _forStatement();
    if (roll < 84) return _whileStatement();
    if (roll < 90) {
      return Comment(
          _id(),
          SourceSpan.none,
          ' ${_pick(const [
                'un carré',
                'tourne ici',
                'essai',
                'mon dessin',
              ])}');
    }
    return _assignment();
  }

  AsStmt _simpleStatement() {
    if (_variables.isNotEmpty && _chance(20)) return _assignment();
    if (_procedures.isNotEmpty && _chance(20)) {
      final proc = _pick(_procedures);
      return ProcCall(_id(), SourceSpan.none, proc.name,
          [for (var i = 0; i < proc.params.length; i++) _numberExpression()]);
    }
    final op = _pick(_safeCommands);
    return Command(
      _id(),
      SourceSpan.none,
      op,
      [for (var i = 0; i < op.minArgs; i++) _numberExpression()],
      form: _chance(30) ? KeywordForm.abbreviation : KeywordForm.primary,
    );
  }

  AsStmt _assignment() {
    final name = _variables.isNotEmpty && _chance(50)
        ? _pick(_variables)
        : 'v${_int(90) + 10}';
    if (!_variables.contains(name)) _variables.add(name);
    return Assign(_id(), SourceSpan.none, name, _numberExpression());
  }

  AsStmt _repeat() {
    _depth++;
    final body = [for (var i = 0; i < 1 + _int(3); i++) _statement()];
    _depth--;
    return Repeat(_id(), SourceSpan.none,
        Literal(_id(), SourceSpan.none, NumberValue(1 + _int(6))), body);
  }

  AsStmt _ifStatement() {
    _depth++;
    final then = [for (var i = 0; i < 1 + _int(2); i++) _statement()];
    final orElse = _chance(50)
        ? [for (var i = 0; i < 1 + _int(2); i++) _statement()]
        : null;
    _depth--;
    return If(_id(), SourceSpan.none, _booleanExpression(), then, orElse);
  }

  AsStmt _forStatement() {
    final name = 'i${_int(90) + 10}';
    _variables.add(name);
    _depth++;
    final body = [for (var i = 0; i < 1 + _int(2); i++) _statement()];
    _depth--;
    _variables.remove(name);
    return For(
      _id(),
      SourceSpan.none,
      name,
      Literal(_id(), SourceSpan.none, NumberValue(1 + _int(3))),
      Literal(_id(), SourceSpan.none, NumberValue(4 + _int(5))),
      _chance(40)
          ? Literal(_id(), SourceSpan.none, NumberValue(1 + _int(2)))
          : null,
      body,
    );
  }

  /// Always terminates: the counter starts above the limit, so the body never runs.
  /// The point of generating a `tantque` is to round-trip it, not to hang the fuzzer.
  AsStmt _whileStatement() {
    _depth++;
    final body = [for (var i = 0; i < 1 + _int(2); i++) _simpleStatement()];
    _depth--;
    return While(
      _id(),
      SourceSpan.none,
      BinOp(
          _id(),
          SourceSpan.none,
          '<',
          Literal(_id(), SourceSpan.none, const NumberValue(5)),
          Literal(_id(), SourceSpan.none, const NumberValue(1))),
      body,
    );
  }

  AsExpr _numberExpression() {
    final roll = _int(100);
    if (roll < 55) {
      return Literal(_id(), SourceSpan.none, NumberValue(_int(200) - 50));
    }
    if (roll < 65) {
      return Literal(
          _id(), SourceSpan.none, NumberValue((_int(1000) - 500) / 10));
    }
    if (roll < 75 && _variables.isNotEmpty) {
      return VarRef(_id(), SourceSpan.none, _pick(_variables));
    }
    if (roll < 85) {
      return BinOp(_id(), SourceSpan.none, _pick(const ['+', '-', '*']),
          _atom(), _atom());
    }
    if (roll < 92) {
      return Group(_id(), SourceSpan.none,
          BinOp(_id(), SourceSpan.none, '+', _atom(), _atom()));
    }
    if (roll < 97) {
      return UnOp(_id(), SourceSpan.none, '-', _atom());
    }
    return Command(_id(), SourceSpan.none, Opcode.random, [
      Literal(_id(), SourceSpan.none, const NumberValue(1)),
      Literal(_id(), SourceSpan.none, NumberValue(2 + _int(20))),
    ]);
  }

  AsExpr _atom() => Literal(_id(), SourceSpan.none, NumberValue(1 + _int(60)));

  AsExpr _booleanExpression() {
    final left = _atom();
    final right = _atom();
    final op = _pick(const ['<', '>', '==', '!=', '<=', '>=']);
    final comparison = BinOp(_id(), SourceSpan.none, op, left, right);
    final roll = _int(100);
    if (roll < 60) return comparison;
    if (roll < 75) return UnOp(_id(), SourceSpan.none, 'not', comparison);
    if (roll < 90) {
      return BinOp(_id(), SourceSpan.none, _pick(const ['and', 'or']),
          comparison, BinOp(_id(), SourceSpan.none, '<', _atom(), _atom()));
    }
    return Literal(_id(), SourceSpan.none, BoolValue(_chance(50)));
  }
}
