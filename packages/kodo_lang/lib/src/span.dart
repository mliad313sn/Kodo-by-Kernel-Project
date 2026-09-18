/// Source positions (FR-M1-10 — an error must point at the offending line).
library;

/// A half-open range of source offsets, carrying line and column for the M3 editor.
///
/// Every AST node has one. That is what lets the text editor mark a line red, the block
/// editor highlight a block, and both of them highlight *together* during step execution
/// (`FR-M4-07`) without either surface owning a second position model.
class SourceSpan {
  const SourceSpan({
    required this.start,
    required this.end,
    required this.line,
    required this.column,
  });

  /// A span that points nowhere. Used by nodes the block editor creates directly, which
  /// have no text origin until the program is rendered.
  static const none = SourceSpan(start: 0, end: 0, line: 1, column: 1);

  final int start;
  final int end;

  /// 1-based, because it is shown to a child beside a line of code.
  final int line;

  /// 1-based.
  final int column;

  bool get isNone => start == 0 && end == 0;

  Map<String, Object?> toJson() =>
      {'s': start, 'e': end, 'l': line, 'c': column};

  static SourceSpan fromJson(Map<String, Object?> j) => SourceSpan(
        start: j['s']! as int,
        end: j['e']! as int,
        line: j['l']! as int,
        column: j['c']! as int,
      );

  @override
  String toString() => 'L$line:C$column';
}
