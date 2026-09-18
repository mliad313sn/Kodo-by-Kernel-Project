/// Turning source text into tokens.
///
/// The lexer knows nothing about French or English. It produces *words*; the parser asks
/// the active [KeywordTable] what a word means. That split is what makes a keyword-language
/// swap a table swap rather than a re-parse.
library;

import 'errors.dart';
import 'span.dart';

enum TokenType {
  number,
  string,
  word,
  variable,
  comment,
  lbrace,
  rbrace,
  lparen,
  rparen,
  lbracket,
  rbracket,
  comma,
  operator,
  assign,
  eof,
}

class Token {
  const Token(this.type, this.text, this.span, {this.number, this.stringValue});

  final TokenType type;

  /// The source text of the token, verbatim.
  final String text;
  final SourceSpan span;

  /// Set for [TokenType.number].
  final num? number;

  /// Set for [TokenType.string] and [TokenType.comment]: the value with escapes resolved
  /// and the delimiters removed.
  final String? stringValue;

  @override
  String toString() => '$type(${text.isEmpty ? '·' : text})';
}

class LexResult {
  LexResult(this.tokens, this.errors);
  final List<Token> tokens;
  final List<KodoError> errors;
}

/// Accented letters are ordinary identifier characters.
///
/// `répète` and `lèvecrayon` are the French keywords, so a lexer that treated `é` as
/// punctuation would make the reference language unusable. Anything at or above U+0080 is
/// treated as a letter, which is coarse but correct for every language we will ship: it
/// also lets a child name a variable `$côté`.
bool _isLetter(int c) =>
    (c >= 0x61 && c <= 0x7A) ||
    (c >= 0x41 && c <= 0x5A) ||
    c == 0x5F ||
    c >= 0x80;

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

bool _isIdentChar(int c) => _isLetter(c) || _isDigit(c);

LexResult tokenize(String source) {
  final tokens = <Token>[];
  final errors = <KodoError>[];
  var i = 0;
  var line = 1;
  var lineStart = 0;

  SourceSpan spanFrom(int start, int startLine, int startCol) =>
      SourceSpan(start: start, end: i, line: startLine, column: startCol);

  int col(int at) => at - lineStart + 1;

  while (i < source.length) {
    final start = i;
    final c = source.codeUnitAt(i);

    // Whitespace. Newlines are not significant: a program is a sequence of statements,
    // and a child who wraps a long line has not changed their program.
    if (c == 0x0A) {
      i++;
      line++;
      lineStart = i;
      continue;
    }
    if (c == 0x20 || c == 0x09 || c == 0x0D) {
      i++;
      continue;
    }

    final startLine = line;
    final startCol = col(start);

    // Comment: '#' to end of line. Kept as a token — World 11 teaches commenting out a
    // line as a debugging tool, so comments are part of the program, not noise.
    if (c == 0x23) {
      i++;
      final textStart = i;
      while (i < source.length && source.codeUnitAt(i) != 0x0A) {
        i++;
      }
      tokens.add(Token(
        TokenType.comment,
        source.substring(start, i),
        spanFrom(start, startLine, startCol),
        stringValue: source.substring(textStart, i),
      ));
      continue;
    }

    if (_isDigit(c)) {
      while (i < source.length && _isDigit(source.codeUnitAt(i))) {
        i++;
      }
      if (i + 1 < source.length &&
          source.codeUnitAt(i) == 0x2E &&
          _isDigit(source.codeUnitAt(i + 1))) {
        i++;
        while (i < source.length && _isDigit(source.codeUnitAt(i))) {
          i++;
        }
      }
      final text = source.substring(start, i);
      // A digit run immediately followed by letters — `12abc` — is a typo, not two tokens.
      if (i < source.length && _isLetter(source.codeUnitAt(i))) {
        while (i < source.length && _isIdentChar(source.codeUnitAt(i))) {
          i++;
        }
        errors.add(KodoError(
          code: ErrorCode.badNumber,
          span: spanFrom(start, startLine, startCol),
          args: {'word': source.substring(start, i)},
        ));
        continue;
      }
      tokens.add(Token(
        TokenType.number,
        text,
        spanFrom(start, startLine, startCol),
        number: num.parse(text),
      ));
      continue;
    }

    if (c == 0x24) {
      // '$' — a variable. The sigil is syntax; the name is what the child sees.
      i++;
      final nameStart = i;
      while (i < source.length && _isIdentChar(source.codeUnitAt(i))) {
        i++;
      }
      if (i == nameStart) {
        errors.add(KodoError(
          code: ErrorCode.expectedVariable,
          span: spanFrom(start, startLine, startCol),
        ));
        continue;
      }
      tokens.add(Token(
        TokenType.variable,
        source.substring(nameStart, i),
        spanFrom(start, startLine, startCol),
      ));
      continue;
    }

    if (_isLetter(c)) {
      while (i < source.length && _isIdentChar(source.codeUnitAt(i))) {
        i++;
      }
      tokens.add(Token(
        TokenType.word,
        source.substring(start, i),
        spanFrom(start, startLine, startCol),
      ));
      continue;
    }

    if (c == 0x22) {
      // '"' — a string. Unterminated at end of line is its own error, because that is the
      // shape of the mistake: the child pressed Enter before the closing quote.
      i++;
      final buffer = StringBuffer();
      var closed = false;
      while (i < source.length) {
        final ch = source.codeUnitAt(i);
        if (ch == 0x0A) break;
        if (ch == 0x5C && i + 1 < source.length) {
          final next = source.codeUnitAt(i + 1);
          if (next == 0x22 || next == 0x5C) {
            buffer.writeCharCode(next);
            i += 2;
            continue;
          }
        }
        if (ch == 0x22) {
          i++;
          closed = true;
          break;
        }
        buffer.writeCharCode(ch);
        i++;
      }
      if (!closed) {
        errors.add(KodoError(
          code: ErrorCode.unclosedString,
          span: spanFrom(start, startLine, startCol),
          repair: const SuggestedRepair(RepairKind.closeString, insert: '"'),
        ));
        continue;
      }
      tokens.add(Token(
        TokenType.string,
        source.substring(start, i),
        spanFrom(start, startLine, startCol),
        stringValue: buffer.toString(),
      ));
      continue;
    }

    TokenType? simple;
    switch (c) {
      case 0x7B:
        simple = TokenType.lbrace;
      case 0x7D:
        simple = TokenType.rbrace;
      case 0x28:
        simple = TokenType.lparen;
      case 0x29:
        simple = TokenType.rparen;
      case 0x5B:
        simple = TokenType.lbracket;
      case 0x5D:
        simple = TokenType.rbracket;
      case 0x2C:
        simple = TokenType.comma;
    }
    if (simple != null) {
      i++;
      tokens.add(Token(simple, source.substring(start, i),
          spanFrom(start, startLine, startCol)));
      continue;
    }

    // Two-character operators first, so '==' never lexes as two '='.
    if (i + 1 < source.length) {
      final two = source.substring(i, i + 2);
      if (two == '==' || two == '!=' || two == '<=' || two == '>=') {
        i += 2;
        tokens.add(Token(
            TokenType.operator, two, spanFrom(start, startLine, startCol)));
        continue;
      }
    }
    const singles = {'+', '-', '*', '/', '^', '<', '>'};
    final one = source[i];
    if (singles.contains(one)) {
      i++;
      tokens.add(
          Token(TokenType.operator, one, spanFrom(start, startLine, startCol)));
      continue;
    }
    if (one == '=') {
      i++;
      tokens.add(
          Token(TokenType.assign, one, spanFrom(start, startLine, startCol)));
      continue;
    }

    i++;
    errors.add(KodoError(
      code: ErrorCode.unexpectedToken,
      span: spanFrom(start, startLine, startCol),
      args: {'word': one, 'line': '$startLine'},
    ));
  }

  tokens.add(Token(TokenType.eof, '',
      SourceSpan(start: i, end: i, line: line, column: col(i))));
  return LexResult(tokens, errors);
}
