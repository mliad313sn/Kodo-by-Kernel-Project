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
import 'package:kodo_access/kodo_access.dart';
import 'package:kodo_lang/kodo_lang.dart';

import 'block_view.dart';
import 'code_export.dart';
import 'editor_controller.dart';
import 'keyword_suggestions.dart';
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
  /* One categorisation, shared with the export (`FR-M3-08`). An exporter that worked the
     colours out for itself would drift from the editor, and a child would print a program
     that is not the one on their screen. */
  return [
    for (final span in highlightSpans(line, keywords))
      TextSpan(
        text: span.text,
        style:
            theme.styleFor(span.category).toTextStyle(fontSize, fontFamily),
      ),
  ];
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
    this.highlightedLine,
    this.onExport,
  });

  final EditorController controller;
  final SyntaxTheme theme;
  final String locale;
  final List<Opcode> worldOpcodes;

  /// `FR-M3-02`. Toggleable, and on by default because a line number is what an error
  /// message points at.
  final bool showLineNumbers;

  final bool compact;

  /// The line a slow or stepped run is on (`FR-M4-07`).
  ///
  /// Derived from the same cursor that lights the block, never computed here: two
  /// highlights that were worked out separately would agree most of the time, and the
  /// times they did not would teach a child that the blocks and the words are two
  /// different programs.
  final int? highlightedLine;

  /// `FR-M3-08`: hands the program out as text and as a picture.
  ///
  /// The editor renders both and the caller decides what a file is — a share sheet on a
  /// phone, a download in a browser, a folder on a desktop. None of that belongs in an
  /// editor, and all of it differs per platform.
  final void Function(CodeExport export)? onExport;

  @override
  State<TextEditor> createState() => TextEditorState();
}

class TextEditorState extends State<TextEditor> {
  late final TextEditingController _text =
      TextEditingController(text: widget.controller.text);
  int? _focusedLine;

  /* The state the editor was left in by accepting an offer. A completed word is still a
     partial word of itself, so without this the strip re-opens the instant it is used and
     offers `avance` to a child who has just accepted `avance`. Cleared by the next edit. */
  TextEditingValue? _justCompleted;

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
    _justCompleted = null;
    _text.value = TextEditingValue(
      text: widget.controller.text,
      selection: TextSelection.collapsed(
        offset: offset.clamp(0, widget.controller.text.length),
      ),
    );
  }

  /// `FR-M3-03`: tapping the message scrolls to and highlights the line.
  void focusLine(int line) => setState(() => _focusedLine = line);

  /// What autocomplete is offering right now (`FR-M3-06`).
  ///
  /// Empty when the cursor is not at the end of a partial word, which is most of the
  /// time — a strip that is always there is a strip nobody reads.
  List<KeywordSuggestion> get suggestions {
    final selection = _text.selection;
    if (!selection.isValid || !selection.isCollapsed) return const [];
    if (_justCompleted == _text.value) return const [];
    final partial = partialWordAt(_text.text, selection.baseOffset);
    if (partial.length < 2) return const [];
    final keywords = widget.controller.keywords;
    return suggestKeywords(
      partial,
      keywords: keywords,
      other: keywords.locale == 'en' ? KeywordTables.fr : KeywordTables.en,
      scope: widget.worldOpcodes,
    );
  }

  /// `FR-M3-08`. The program as text and as a picture of itself.
  CodeExport buildExport() => exportProgram(
        widget.controller.program,
        widget.controller.keywords,
        widget.theme,
      );

  /// Takes an offer: replaces the partial word rather than appending to it.
  void accept(KeywordSuggestion suggestion) {
    final selection = _text.selection;
    final cursor = selection.isValid ? selection.baseOffset : _text.text.length;
    final (updated, at) = acceptSuggestion(_text.text, cursor, suggestion);
    _text.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: at),
    );
    _justCompleted = _text.value;
    widget.controller.setText(updated);
  }

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
    _justCompleted = null;
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
                          : (widget.highlightedLine == lineNumber
                              // `FR-M4-07`, and stronger than the tap focus below it: a
                              // run is moving and has to be findable at a glance.
                              ? Colors.amber.withValues(alpha: 0.38)
                              : (_focusedLine == lineNumber
                                  ? Colors.amber.withValues(alpha: 0.18)
                                  : null)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /* `FR-M4-07`. A caret as well as the tint, because a tint alone
                             is a colour and `FR-M16-01`'s rule — never one signal — holds
                             for a running line as much as for a block. */
                          if (widget.highlightedLine == lineNumber)
                            const Icon(Icons.play_arrow,
                                key: Key('running-line'), size: 14),
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
            /* `FR-M3-06`. Above the keyboard row rather than floating over the program:
               a popup on a 5.5" screen covers the line being typed, which is the line a
               child is looking at. */
            if (widget.onExport != null)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Semantics(
                    label: uiStrings.render(
                        'a11y.keep_program', UiLocale.byCode(widget.locale)),
                    button: true,
                    child: SizedBox(
                      width: minimumTouchTarget,
                      height: minimumTouchTarget,
                      child: InkWell(
                        key: const Key('export-code'),
                        onTap: () => widget.onExport!(buildExport()),
                        child: const ExcludeSemantics(
                            child: Icon(Icons.ios_share, size: 22)),
                      ),
                    ),
                  ),
                ),
              ),
            if (suggestions.isNotEmpty)
              KeywordSuggestionStrip(
                key: const Key('suggestions'),
                suggestions: suggestions,
                showEquivalent: showsEquivalentIn(widget.controller.world),
                onAccept: accept,
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

/// The row of offers autocomplete puts above the keyboard (`FR-M3-06`).
///
/// One tap each, 48 dp, and the other language's word underneath from World 9. The
/// equivalent is set in smaller, quieter type on purpose: it is there to be noticed over
/// weeks rather than read every time, which is how a child arrives at World 11 already
/// knowing that `répète` and `repeat` are one word.
class KeywordSuggestionStrip extends StatelessWidget {
  const KeywordSuggestionStrip({
    super.key,
    required this.suggestions,
    required this.onAccept,
    this.showEquivalent = false,
  });

  final List<KeywordSuggestion> suggestions;
  final void Function(KeywordSuggestion) onAccept;
  final bool showEquivalent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: showEquivalent ? 60 : 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final suggestion in suggestions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: InkWell(
                key: Key('suggest-${suggestion.word}'),
                borderRadius: BorderRadius.circular(8),
                onTap: () => onAccept(suggestion),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      minWidth: minimumTouchTarget,
                      minHeight: minimumTouchTarget),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(suggestion.word,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          if (showEquivalent)
                            Text(suggestion.equivalent,
                                key: Key('equivalent-${suggestion.word}'),
                                style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
