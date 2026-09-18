/// The text editor and the bridge (M3).
///
/// *"the single most differentiating feature in the product: the moment a child sees their
/// blocks as words in their own language, and then as words in English."*
///
/// Three rules from the module prompt's `Do not` shape everything here: the editor never
/// auto-corrects a child's code, it never hides the error panel by itself, and the toggle
/// is a first-class control beside the run button rather than a setting in a menu.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kodo_lang/kodo_lang.dart';

import 'block_view.dart';
import 'editor_controller.dart';
import 'syntax_theme.dart';

/// Splits a line into coloured spans (FR-M3-01).
///
/// It highlights from the **lexer**, not from a regular expression, so a word is coloured
/// as what the parser will actually call it. A highlighter with its own idea of the
/// language eventually disagrees with the error panel, and then a child is looking at a
/// word that is blue and underlined in red.
List<TextSpan> highlightLine(
  String line,
  KeywordTable keywords,
  SyntaxTheme theme, {
  double fontSize = 16,
  String? fontFamily,
}) {
  final spans = <TextSpan>[];
  final tokens = tokenize(line).tokens;
  var cursor = 0;

  void emit(String text, SyntaxCategory category) {
    if (text.isEmpty) return;
    spans.add(TextSpan(
      text: text,
      style: theme.styleFor(category).toTextStyle(fontSize, fontFamily),
    ));
  }

  for (final token in tokens) {
    if (token.type == TokenType.eof) break;
    if (token.span.start > cursor) {
      emit(line.substring(cursor, token.span.start), SyntaxCategory.command);
    }
    final text = line.substring(token.span.start, token.span.end);
    emit(text, _categoryOf(token, keywords));
    cursor = token.span.end;
  }
  if (cursor < line.length) {
    emit(line.substring(cursor), SyntaxCategory.command);
  }
  return spans;
}

SyntaxCategory _categoryOf(Token token, KeywordTable keywords) {
  switch (token.type) {
    case TokenType.comment:
      return SyntaxCategory.comment;
    case TokenType.string:
      return SyntaxCategory.string;
    case TokenType.number:
      return SyntaxCategory.number;
    case TokenType.variable:
      return SyntaxCategory.variable;
    case TokenType.lbrace:
    case TokenType.rbrace:
      return SyntaxCategory.brace;
    case TokenType.operator:
      return const {'==', '!=', '<', '>', '<=', '>='}.contains(token.text)
          ? SyntaxCategory.comparisonOperator
          : SyntaxCategory.mathOperator;
    case TokenType.assign:
      return SyntaxCategory.mathOperator;
    case TokenType.word:
      final lookup = keywords.resolve(token.text);
      if (lookup == null) return SyntaxCategory.command;
      final syntax = lookup.syntax;
      if (syntax == null) return SyntaxCategory.command;
      return switch (syntax) {
        SyntaxWord.true_ || SyntaxWord.false_ => SyntaxCategory.boolean,
        SyntaxWord.and ||
        SyntaxWord.or ||
        SyntaxWord.not =>
          SyntaxCategory.booleanOperator,
        SyntaxWord.learn => SyntaxCategory.learn,
        _ => SyntaxCategory.controlFlow,
      };
    default:
      return SyntaxCategory.command;
  }
}

/// The programming keyboard row (FR-M3-07).
///
/// *"`{ } ( ) $ , " # < > =` plus the twelve most-used keywords of the current world,
/// scrollable."* On a phone this is the difference between a child typing a program and a
/// child giving up: none of these characters is on the first page of an Android keyboard.
class ProgrammingKeyboardRow extends StatelessWidget {
  const ProgrammingKeyboardRow({
    super.key,
    required this.keywords,
    required this.worldOpcodes,
    required this.onInsert,
  });

  final KeywordTable keywords;

  /// The world's opcodes, in teaching order. The row shows the first twelve.
  final List<Opcode> worldOpcodes;
  final void Function(String text) onInsert;

  static const symbols = [
    '{',
    '}',
    '(',
    ')',
    r'$',
    ',',
    '"',
    '#',
    '<',
    '>',
    '='
  ];

  List<String> get entries => [
        ...symbols,
        for (final op in worldOpcodes.take(12)) keywords.write(op),
      ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: minimumTouchTarget,
      child: ListView(
        key: const Key('keyboard-row'),
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: minimumTouchTarget,
                  minHeight: minimumTouchTarget,
                ),
                child: OutlinedButton(
                  key: Key('kbd-$entry'),
                  onPressed: () => onInsert(entry),
                  child: Text(entry),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One error, as the child reads it.
class ErrorLine {
  const ErrorLine(this.error, this.message, this.repairLabel);
  final KodoError error;
  final String message;

  /// The one-tap fix, when there is one (`FR-M3-03`). Null means the panel offers nothing
  /// but the sentence — which is better than offering a guess.
  final String? repairLabel;
}

/// Builds the error panel's contents in the child's language.
List<ErrorLine> errorLinesFor(
  List<KodoError> errors,
  String locale,
  KeywordTable keywords,
) =>
    [
      for (final error in errors)
        ErrorLine(
          error,
          error.message(locale, keywords: keywords),
          switch (error.repair.kind) {
            RepairKind.didYouMean => error.repair.word,
            RepairKind.closeBlock => error.repair.insert,
            RepairKind.closeString => error.repair.insert,
            _ => null,
          },
        ),
    ];

/// The text view.
class TextEditor extends StatefulWidget {
  const TextEditor({
    super.key,
    required this.controller,
    required this.theme,
    this.locale = 'fr',
    this.worldOpcodes = const [],
    this.showLineNumbers = true,
    this.compact = false,
  });

  final EditorController controller;
  final SyntaxTheme theme;
  final String locale;
  final List<Opcode> worldOpcodes;

  /// `FR-M3-02`. Toggleable, and on by default because a line number is what an error
  /// message points at.
  final bool showLineNumbers;

  final bool compact;

  @override
  State<TextEditor> createState() => TextEditorState();
}

class TextEditorState extends State<TextEditor> {
  late final TextEditingController _text =
      TextEditingController(text: widget.controller.text);
  int? _focusedLine;

  int? get focusedLine => _focusedLine;
  TextEditingController get textController => _text;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _text.dispose();
    super.dispose();
  }

  void _syncFromController() {
    if (_text.text == widget.controller.text) return;
    // Keeping the cursor is `FR-M3-06`'s neighbour and the reason a keyword-language
    // switch mid-edit does not feel like losing your place.
    final offset = _text.selection.baseOffset;
    _text.value = TextEditingValue(
      text: widget.controller.text,
      selection: TextSelection.collapsed(
        offset: offset.clamp(0, widget.controller.text.length),
      ),
    );
  }

  /// `FR-M3-03`: tapping the message scrolls to and highlights the line.
  void focusLine(int line) => setState(() => _focusedLine = line);

  /// Inserts text at the cursor, for the keyboard row.
  void insertAtCursor(String text) {
    final selection = _text.selection;
    final base = selection.isValid ? selection.start : _text.text.length;
    final updated = _text.text
        .replaceRange(base, selection.isValid ? selection.end : base, text);
    _text.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: base + text.length),
    );
    widget.controller.setText(updated);
  }

  /// `FR-M3-04`: one tap comments or uncomments the current line, taught as a debugging
  /// tool rather than hidden in a menu.
  void toggleCommentOnLine(int lineNumber) {
    final lines = widget.controller.text.split('\n');
    if (lineNumber < 1 || lineNumber > lines.length) return;
    final index = lineNumber - 1;
    final line = lines[index];
    final trimmed = line.trimLeft();
    final indent = line.substring(0, line.length - trimmed.length);
    lines[index] = trimmed.startsWith('#')
        ? indent + trimmed.substring(1).trimLeft()
        : '$indent# $trimmed';
    widget.controller.setText(lines.join('\n'), kind: 'comment_toggled');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final lines = widget.controller.text.split('\n');
        final errorsByLine = <int, List<KodoError>>{};
        for (final error in widget.controller.errors) {
          errorsByLine.putIfAbsent(error.line, () => []).add(error);
        }
        final panel = errorLinesFor(widget.controller.errors, widget.locale,
            widget.controller.keywords);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: widget.theme.background,
                child: ListView.builder(
                  key: const Key('code-lines'),
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final lineNumber = index + 1;
                    final hasError = errorsByLine.containsKey(lineNumber);
                    return Container(
                      key: Key('line-$lineNumber'),
                      color: hasError
                          ? widget.theme
                              .styleFor(SyntaxCategory.error)
                              .colour
                              .withValues(alpha: 0.14)
                          : (_focusedLine == lineNumber
                              ? Colors.amber.withValues(alpha: 0.18)
                              : null),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.showLineNumbers)
                            SizedBox(
                              width: 28,
                              child: Text(
                                '$lineNumber',
                                style: widget.theme
                                    .styleFor(SyntaxCategory.comment)
                                    .toTextStyle(13, 'monospace'),
                              ),
                            ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: highlightLine(
                                  lines[index],
                                  widget.controller.keywords,
                                  widget.theme,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (widget.compact)
              ProgrammingKeyboardRow(
                keywords: widget.controller.keywords,
                worldOpcodes: widget.worldOpcodes,
                onInsert: insertAtCursor,
              ),
            // The panel is never hidden automatically — the module prompt's `Do not`.
            if (panel.isNotEmpty)
              Material(
                key: const Key('error-panel'),
                // Material rather than a coloured box: a ListTile paints its ink on the
                // nearest Material ancestor, and a ColoredBox in between swallows the
                // touch feedback — which on a phone is the only confirmation a child gets
                // that their tap landed.
                color: widget.theme
                    .styleFor(SyntaxCategory.error)
                    .colour
                    .withValues(alpha: 0.08),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: ListView(
                    children: [
                      for (final line in panel)
                        ListTile(
                          key: Key(
                              'error-${line.error.code.id}-${line.error.line}'),
                          dense: true,
                          leading: Text('${line.error.line}',
                              style: widget.theme
                                  .styleFor(SyntaxCategory.error)
                                  .toTextStyle(14, null)),
                          title: Text(line.message),
                          trailing: line.repairLabel == null
                              ? null
                              : TextButton(
                                  key: Key('repair-${line.error.code.id}'),
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: line.repairLabel!));
                                  },
                                  child: Text(line.repairLabel!),
                                ),
                          onTap: () => focusLine(line.error.line),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
