/// Source text to AST.
///
/// Two properties matter more than anything else here, because three other modules are
/// built on them:
///
/// * **It never throws.** Malformed input yields catalogued errors with spans. A fuzzer
///   throwing 10 000 broken programs at this must get 10 000 answers, not one crash.
/// * **It never guesses.** The parser does not repair a child's program. It reports what
///   it found and attaches a [SuggestedRepair] the editor may *offer*; the child decides.
library;

import 'ast.dart';
import 'errors.dart';
import 'keywords.dart';
import 'lexer.dart';
import 'opcodes.dart';
import 'span.dart';
import 'values.dart';

class ParseResult {
  ParseResult(this.program, this.errors);

  /// Always present, even when [errors] is non-empty: the parser recovers and keeps going
  /// so the editor can mark several mistakes at once instead of one per run.
  final Program program;
  final List<KodoError> errors;

  bool get ok => errors.isEmpty;
}

ParseResult parse(String source, KeywordTable kw) =>
    _Parser(source, kw).parseProgram();

class _Parser {
  _Parser(this.source, this.kw) {
    final lexed = tokenize(source);
    tokens = lexed.tokens;
    errors.addAll(lexed.errors);
    _prescanProcedures();
  }

  final String source;
  final KeywordTable kw;
  late final List<Token> tokens;
  final List<KodoError> errors = [];
  final Map<String, int> _procArity = {};
  int pos = 0;
  int _nextId = 0;

  String _id() => 'n${++_nextId}';

  /// Always in range. The end-of-file token is sticky: reading past it returns it again.
  ///
  /// Found by the hostility fuzzer (acceptance test 6), which produced a malformed program
  /// where error recovery consumed the end-of-file token and the next read walked off the
  /// list. A parser that throws is a parser that takes the app down in front of a child,
  /// and `FR-M1-10` says no stack trace is ever shown — so the parser must not be able to
  /// produce one.
  Token get current => tokens[pos < tokens.length ? pos : tokens.length - 1];

  Token get previous => tokens[pos > 0 ? pos - 1 : 0];

  bool get atEnd => current.type == TokenType.eof;

  Token advance() {
    final token = current;
    if (pos < tokens.length - 1) pos++;
    return token;
  }

  bool check(TokenType t) => current.type == t;

  bool matchType(TokenType t) {
    if (!check(t)) return false;
    advance();
    return true;
  }

  SyntaxWord? syntaxAt(int at) {
    final t = tokens[at];
    if (t.type != TokenType.word) return null;
    return kw.resolve(t.text)?.syntax;
  }

  bool matchSyntax(SyntaxWord w) {
    if (syntaxAt(pos) != w) return false;
    advance();
    return true;
  }

  /// Procedures are collected before the main pass so that a call may precede its
  /// definition, and so that a procedure may call itself — recursion is `FR-M1-06`, and
  /// World 9 teaches it.
  void _prescanProcedures() {
    for (var i = 0; i < tokens.length; i++) {
      if (syntaxAt(i) != SyntaxWord.learn) continue;
      if (i + 1 >= tokens.length || tokens[i + 1].type != TokenType.word) {
        continue;
      }
      final name = tokens[i + 1].text.toLowerCase();
      var j = i + 2;
      var arity = 0;
      while (j < tokens.length && tokens[j].type == TokenType.variable) {
        arity++;
        j++;
        if (j < tokens.length && tokens[j].type == TokenType.comma) j++;
      }
      _procArity.putIfAbsent(name, () => arity);
    }
  }

  // -------------------------------------------------------------------------------------
  // Program and statements
  // -------------------------------------------------------------------------------------

  ParseResult parseProgram() {
    final body = <AsStmt>[];
    while (!atEnd) {
      final before = pos;
      final stmt = parseStatement(topLevel: true);
      if (stmt != null) body.add(stmt);
      if (pos == before) {
        if (atEnd) break; // end-of-file is sticky; nothing left to skip
        advance(); // recovery must always make progress
      }
    }
    final program = Program(
      _id(),
      SourceSpan(start: 0, end: source.length, line: 1, column: 1),
      body,
    );
    return ParseResult(program, errors);
  }

  List<AsStmt> parseBlock() {
    final body = <AsStmt>[];
    final open = previous.span;
    while (!atEnd && !check(TokenType.rbrace)) {
      final before = pos;
      final stmt = parseStatement();
      if (stmt != null) body.add(stmt);
      if (pos == before) {
        if (atEnd) break;
        advance();
      }
    }
    if (!matchType(TokenType.rbrace)) {
      errors.add(KodoError(
        code: ErrorCode.unclosedBlock,
        span: open,
        repair: const SuggestedRepair(RepairKind.closeBlock, insert: '}'),
      ));
    }
    return body;
  }

  /// Consumes `{ … }`. Reports the mistake and parses a single statement as the body when
  /// the brace is missing, because "you forgot the braces" should not also cost the child
  /// every error underneath it.
  List<AsStmt> expectBlock() {
    if (matchType(TokenType.lbrace)) return parseBlock();
    if (atEnd) {
      errors.add(KodoError(
        code: ErrorCode.unclosedBlock,
        span: current.span,
        repair: const SuggestedRepair(RepairKind.closeBlock, insert: '{'),
      ));
      return <AsStmt>[];
    }
    errors.add(KodoError(
      code: ErrorCode.unexpectedToken,
      span: current.span,
      args: {'word': current.text, 'line': '${current.span.line}'},
      repair: const SuggestedRepair(RepairKind.closeBlock, insert: '{'),
    ));
    final one = parseStatement();
    return one == null ? <AsStmt>[] : <AsStmt>[one];
  }

  /// [topLevel] is false everywhere inside a block.
  ///
  /// Only `quand` cares: a trigger inside a loop would be asking "when the flag is
  /// clicked" four times, which means nothing, so the parser refuses it with a sentence
  /// rather than letting it through to puzzle a child at run time (`FR-M21-01`).
  AsStmt? parseStatement({bool topLevel = false}) {
    if (check(TokenType.comment)) {
      final t = advance();
      return Comment(_id(), t.span, t.stringValue!);
    }

    if (check(TokenType.variable)) return parseAssign();

    if (check(TokenType.word)) {
      final lookup = kw.resolve(current.text);
      final syntax = lookup?.syntax;
      if (syntax != null) {
        switch (syntax) {
          case SyntaxWord.when_:
            return parseWhenEvent(topLevel: topLevel);
          case SyntaxWord.repeat:
            return parseRepeat();
          case SyntaxWord.while_:
            return parseWhile();
          case SyntaxWord.for_:
            return parseFor();
          case SyntaxWord.if_:
            return parseIf();
          case SyntaxWord.learn:
            return parseProcDef();
          case SyntaxWord.return_:
            final t = advance();
            final value = _startsExpression() ? parseExpression() : null;
            return Return(_id(), t.span, value);
          case SyntaxWord.break_:
            final t = advance();
            return Break(_id(), t.span);
          case SyntaxWord.exit:
            final t = advance();
            return Exit(_id(), t.span);
          case SyntaxWord.to:
          case SyntaxWord.step:
          case SyntaxWord.else_:
          case SyntaxWord.and:
          case SyntaxWord.or:
          case SyntaxWord.not:
          case SyntaxWord.true_:
          case SyntaxWord.false_:
            // A grammar word with nothing to attach to. `sinon` alone is the common one.
            final t = advance();
            errors.add(KodoError(
              code: ErrorCode.unexpectedToken,
              span: t.span,
              args: {'word': t.text, 'line': '${t.span.line}'},
            ));
            return null;
        }
      }
      if (lookup?.opcode != null) {
        return parseCommand(lookup!.opcode!, lookup.form) as AsStmt;
      }
      return parseProcCallStatement();
    }

    final t = advance();
    errors.add(KodoError(
      code: ErrorCode.unexpectedToken,
      span: t.span,
      args: {'word': t.text, 'line': '${t.span.line}'},
    ));
    return null;
  }

  AsStmt parseAssign() {
    final t = advance();
    if (!matchType(TokenType.assign)) {
      errors.add(KodoError(
        code: ErrorCode.unexpectedToken,
        span: current.span,
        args: {'word': current.text, 'line': '${current.span.line}'},
      ));
      return Assign(
          _id(), t.span, t.text, Literal(_id(), t.span, const NumberValue(0)));
    }
    final value = parseExpression();
    return Assign(_id(), t.span, t.text, value);
  }

  /// `quand <déclencheur> [argument] { … }`.
  AsStmt parseWhenEvent({required bool topLevel}) {
    final t = advance();
    if (!topLevel) {
      errors.add(KodoError(code: ErrorCode.eventNested, span: t.span));
    }

    /* The trigger is an ordinary word the keyword table resolves, so a Wolof table adds
       triggers the same way it adds everything else: as data. */
    Opcode? trigger;
    if (check(TokenType.word)) {
      final lookup = kw.resolve(current.text);
      if (lookup?.opcode?.kind == OpcodeKind.event) {
        trigger = lookup!.opcode;
        advance();
      }
    }
    if (trigger == null) {
      errors
          .add(KodoError(code: ErrorCode.expectedTrigger, span: current.span));
      // Recover as a flag script: the child meant "when something", and the body is still
      // worth parsing so the rest of their program does not disappear behind one word.
      trigger = Opcode.whenFlag;
    }

    final args = <AsExpr>[];
    for (var i = 0; i < trigger.minArgs; i++) {
      args.add(parseExpression());
      if (i + 1 < trigger.minArgs) matchType(TokenType.comma);
    }
    return WhenEvent(_id(), t.span, trigger, args, expectBlock());
  }

  AsStmt parseRepeat() {
    final t = advance();
    final count = parseExpression();
    return Repeat(_id(), t.span, count, expectBlock());
  }

  AsStmt parseWhile() {
    final t = advance();
    final cond = parseExpression();
    return While(_id(), t.span, cond, expectBlock());
  }

  AsStmt parseFor() {
    final t = advance();
    if (!check(TokenType.variable)) {
      errors
          .add(KodoError(code: ErrorCode.expectedVariable, span: current.span));
      return For(
          _id(),
          t.span,
          '_',
          Literal(_id(), t.span, const NumberValue(0)),
          Literal(_id(), t.span, const NumberValue(0)),
          null,
          expectBlock());
    }
    final name = advance().text;
    if (!matchType(TokenType.assign)) {
      errors.add(KodoError(
        code: ErrorCode.unexpectedToken,
        span: current.span,
        args: {'word': current.text, 'line': '${current.span.line}'},
      ));
    }
    final from = parseExpression();
    if (!matchSyntax(SyntaxWord.to)) {
      errors.add(KodoError(
        code: ErrorCode.unexpectedToken,
        span: current.span,
        args: {'word': current.text, 'line': '${current.span.line}'},
      ));
    }
    final to = parseExpression();
    final step = matchSyntax(SyntaxWord.step) ? parseExpression() : null;
    return For(_id(), t.span, name, from, to, step, expectBlock());
  }

  AsStmt parseIf() {
    final t = advance();
    final cond = parseExpression();
    final then = expectBlock();
    List<AsStmt>? orElse;
    if (matchSyntax(SyntaxWord.else_)) {
      // `sinon si …` chains, because a child who has learned `si` will write it.
      if (syntaxAt(pos) == SyntaxWord.if_) {
        orElse = [parseIf()];
      } else {
        orElse = expectBlock();
      }
    }
    return If(_id(), t.span, cond, then, orElse);
  }

  AsStmt parseProcDef() {
    final t = advance();
    if (!check(TokenType.word)) {
      errors.add(KodoError(code: ErrorCode.expectedName, span: current.span));
      return ProcDef(_id(), t.span, '_', const [], expectBlock());
    }
    final nameToken = advance();
    final name = nameToken.text;
    if (kw.resolve(name) != null) {
      // Naming a block `avance` would make the child's own word unreachable.
      errors.add(KodoError(
        code: ErrorCode.duplicateProc,
        span: nameToken.span,
        args: {'name': name},
      ));
    }
    final params = <String>[];
    while (check(TokenType.variable)) {
      params.add(advance().text);
      matchType(TokenType.comma);
    }
    _procArity[name.toLowerCase()] = params.length;
    return ProcDef(_id(), t.span, name, params, expectBlock());
  }

  AsStmt? parseProcCallStatement() {
    final t = current;
    final name = t.text.toLowerCase();
    if (!_procArity.containsKey(name)) {
      advance();
      errors.add(KodoError(
        code: ErrorCode.unknownCommand,
        span: t.span,
        args: {'word': t.text},
        repair: _didYouMean(t.text),
      ));
      _skipOrphanArguments();
      return null;
    }
    advance();
    final args = parseArgs(_procArity[name]!, t.text, t.span);
    return ProcCall(_id(), t.span, t.text, args);
  }

  /// Swallows the arguments of a command we could not recognise.
  ///
  /// Without this, `avnce 50` produces two red marks — one for the misspelling and one for
  /// the orphaned `50` — and a child who made a single typo is told they made two
  /// mistakes. One mistake, one mark.
  ///
  /// Only values and separators are consumed, never a word: a word could be the next real
  /// statement, and eating it would hide a second, genuine error.
  void _skipOrphanArguments() {
    while (!atEnd) {
      switch (current.type) {
        case TokenType.number:
        case TokenType.string:
        case TokenType.variable:
        case TokenType.comma:
        case TokenType.operator:
          advance();
        default:
          return;
      }
    }
  }

  // -------------------------------------------------------------------------------------
  // Calls
  // -------------------------------------------------------------------------------------

  /// Exactly [count] comma-separated expressions.
  ///
  /// Commas are required between arguments and are not decoration: without them `va 10 -5`
  /// is genuinely ambiguous between two coordinates and one subtraction, and a language for
  /// children must not have a rule whose failure looks like the program working.
  List<AsExpr> parseArgs(int count, String word, SourceSpan span) {
    final args = <AsExpr>[];
    for (var n = 0; n < count; n++) {
      if (n > 0 && !matchType(TokenType.comma)) {
        errors.add(KodoError(
          code: args.isEmpty ? ErrorCode.missingArg : ErrorCode.argCount,
          span: span,
          args: {
            'word': word,
            'expected': '$count',
            'actual': '${args.length}'
          },
          repair: SuggestedRepair(RepairKind.addArgument,
              count: count - args.length),
        ));
        break;
      }
      if (!_startsExpression()) {
        errors.add(KodoError(
          code: args.isEmpty ? ErrorCode.missingArg : ErrorCode.argCount,
          span: span,
          args: {
            'word': word,
            'expected': '$count',
            'actual': '${args.length}'
          },
          repair: SuggestedRepair(RepairKind.addArgument,
              count: count - args.length),
        ));
        break;
      }
      args.add(parseExpression());
    }
    return args;
  }

  AsExpr parseCommand(Opcode op, KeywordForm form) {
    final t = advance();
    final args = parseArgs(op.minArgs, t.text, t.span);
    return Command(_id(), t.span, op, args, form: form);
  }

  // -------------------------------------------------------------------------------------
  // Expressions
  // -------------------------------------------------------------------------------------

  bool _startsExpression() {
    switch (current.type) {
      case TokenType.number:
      case TokenType.string:
      case TokenType.variable:
      case TokenType.lparen:
      case TokenType.lbracket:
        return true;
      case TokenType.operator:
        return current.text == '-';
      case TokenType.word:
        final l = kw.resolve(current.text);
        if (l == null) {
          return _procArity.containsKey(current.text.toLowerCase());
        }
        if (l.opcode != null) return true;
        return l.syntax == SyntaxWord.not ||
            l.syntax == SyntaxWord.true_ ||
            l.syntax == SyntaxWord.false_;
      default:
        return false;
    }
  }

  AsExpr parseExpression() => parseOr();

  AsExpr parseOr() {
    var left = parseAnd();
    while (syntaxAt(pos) == SyntaxWord.or) {
      final t = advance();
      final right = parseAnd();
      left = BinOp(_id(), t.span, 'or', left, right);
    }
    return left;
  }

  AsExpr parseAnd() {
    var left = parseNot();
    while (syntaxAt(pos) == SyntaxWord.and) {
      final t = advance();
      final right = parseNot();
      left = BinOp(_id(), t.span, 'and', left, right);
    }
    return left;
  }

  AsExpr parseNot() {
    if (syntaxAt(pos) == SyntaxWord.not) {
      final t = advance();
      return UnOp(_id(), t.span, 'not', parseNot());
    }
    return parseComparison();
  }

  static const _comparisons = {'==', '!=', '<', '>', '<=', '>='};

  AsExpr parseComparison() {
    var left = parseAdditive();
    while (check(TokenType.operator) && _comparisons.contains(current.text)) {
      final t = advance();
      final right = parseAdditive();
      left = BinOp(_id(), t.span, t.text, left, right);
    }
    return left;
  }

  AsExpr parseAdditive() {
    var left = parseMultiplicative();
    while (check(TokenType.operator) &&
        (current.text == '+' || current.text == '-')) {
      final t = advance();
      final right = parseMultiplicative();
      left = BinOp(_id(), t.span, t.text, left, right);
    }
    return left;
  }

  AsExpr parseMultiplicative() {
    var left = parsePower();
    while (check(TokenType.operator) &&
        (current.text == '*' || current.text == '/')) {
      final t = advance();
      final right = parsePower();
      left = BinOp(_id(), t.span, t.text, left, right);
    }
    return left;
  }

  AsExpr parsePower() {
    final base = parseUnary();
    if (check(TokenType.operator) && current.text == '^') {
      final t = advance();
      return BinOp(_id(), t.span, '^', base, parsePower()); // right associative
    }
    return base;
  }

  AsExpr parseUnary() {
    if (check(TokenType.operator) && current.text == '-') {
      final t = advance();
      return UnOp(_id(), t.span, '-', parseUnary());
    }
    return parsePostfix();
  }

  AsExpr parsePostfix() {
    var e = parsePrimary();
    while (check(TokenType.lbracket)) {
      final t = advance();
      final idx = parseExpression();
      if (!matchType(TokenType.rbracket)) {
        errors.add(KodoError(
          code: ErrorCode.unexpectedToken,
          span: current.span,
          args: {'word': current.text, 'line': '${current.span.line}'},
        ));
      }
      e = IndexOf(_id(), t.span, e, idx);
    }
    return e;
  }

  AsExpr parsePrimary() {
    final t = current;
    switch (t.type) {
      case TokenType.number:
        advance();
        return Literal(_id(), t.span, NumberValue(t.number!));
      case TokenType.string:
        advance();
        return Literal(_id(), t.span, StringValue(t.stringValue!));
      case TokenType.variable:
        advance();
        return VarRef(_id(), t.span, t.text);
      case TokenType.lparen:
        advance();
        final inner = parseExpression();
        if (!matchType(TokenType.rparen)) {
          errors.add(KodoError(
            code: ErrorCode.unexpectedToken,
            span: current.span,
            args: {'word': current.text, 'line': '${current.span.line}'},
          ));
        }
        return Group(_id(), t.span, inner);
      case TokenType.lbracket:
        advance();
        final items = <AsExpr>[];
        while (!atEnd && !check(TokenType.rbracket)) {
          items.add(parseExpression());
          if (!matchType(TokenType.comma)) break;
        }
        if (!matchType(TokenType.rbracket)) {
          errors.add(KodoError(
            code: ErrorCode.unexpectedToken,
            span: current.span,
            args: {'word': current.text, 'line': '${current.span.line}'},
          ));
        }
        return ListLiteral(_id(), t.span, items);
      case TokenType.word:
        final lookup = kw.resolve(t.text);
        if (lookup?.syntax == SyntaxWord.true_) {
          advance();
          return Literal(_id(), t.span, BoolValue.yes);
        }
        if (lookup?.syntax == SyntaxWord.false_) {
          advance();
          return Literal(_id(), t.span, BoolValue.no);
        }
        if (lookup?.opcode != null) {
          return parseCommand(lookup!.opcode!, lookup.form);
        }
        final name = t.text.toLowerCase();
        if (_procArity.containsKey(name)) {
          advance();
          return ProcCall(_id(), t.span, t.text,
              parseArgs(_procArity[name]!, t.text, t.span));
        }
        advance();
        errors.add(KodoError(
          code: ErrorCode.unknownCommand,
          span: t.span,
          args: {'word': t.text},
          repair: _didYouMean(t.text),
        ));
        return Literal(_id(), t.span, const NumberValue(0));
      default:
        advance();
        errors.add(KodoError(
          code: ErrorCode.unexpectedToken,
          span: t.span,
          args: {'word': t.text, 'line': '${t.span.line}'},
        ));
        return Literal(_id(), t.span, const NumberValue(0));
    }
  }

  /// Nearest known word within an edit distance of 2.
  ///
  /// Two is deliberate: it catches `avnce`, `tourngauche` and `repete` without proposing
  /// `recule` when the child wrote `avance`. A wrong suggestion is worse than none, because
  /// a child will accept it.
  SuggestedRepair _didYouMean(String word) {
    final lower = word.toLowerCase();
    String? best;
    var bestDistance = 3;
    final candidates = <String>[
      for (final op in kw.coveredOpcodes) kw.entryFor(op).primary,
      for (final w in kw.coveredSyntax) kw.entryForSyntax(w).primary,
      ..._procArity.keys,
    ];
    for (final c in candidates) {
      final d = _editDistance(lower, c.toLowerCase());
      if (d < bestDistance) {
        bestDistance = d;
        best = c;
      }
    }
    return best == null
        ? const SuggestedRepair.none()
        : SuggestedRepair(RepairKind.didYouMean, word: best);
  }

  static int _editDistance(String a, String b) {
    if ((a.length - b.length).abs() > 2) return 99;
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final row = List<int>.filled(b.length + 1, 0);
      row[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = row[j - 1] + 1;
        final substitution = previous[j - 1] + cost;
        row[j] = deletion < insertion ? deletion : insertion;
        if (substitution < row[j]) row[j] = substitution;
      }
      previous = row;
    }
    return previous[b.length];
  }
}
