/// The editing model shared by the block editor and the text editor (M2, M3).
///
/// One controller, one AST. The block editor and the text editor are two views of it, and
/// the toggle between them is a change of view rather than a conversion — which is the
/// only way `FR-M3-05`'s promise, that the toggle never loses a program, can be kept
/// rather than defended.
library;

import 'package:flutter/foundation.dart';
import 'package:kodo_lang/kodo_lang.dart';

/// Which view the child is looking at.
enum EditorView { blocks, text }

/// How far into the curriculum the child is, which decides what the text view may do.
///
/// §4.3: Worlds 1–6 text is read-only, 7–9 editable, 10–12 default. The editor is told
/// the world rather than a pile of booleans, so the rule lives in one place and matches
/// the document it came from.
enum TextMode { readOnly, editable, preferred }

TextMode textModeForWorld(int world) {
  if (world <= 6) return TextMode.readOnly;
  if (world <= 9) return TextMode.editable;
  return TextMode.preferred;
}

/// An edit, for M17's telemetry and for the undo stack.
class EditEvent {
  const EditEvent(this.kind, {this.nodeId, this.detail});
  final String kind;
  final String? nodeId;
  final String? detail;
}

/// The result of asking to switch from text to blocks with text that does not parse.
///
/// §4.3 and `FR-M3-05`: the child is offered two choices in their own language — stay and
/// fix the text, or return to the last version that worked. **The last valid AST is always
/// retained**, which is what makes the second choice honest.
class BridgeConflict {
  const BridgeConflict(this.errors, this.lastValidProgram);
  final List<KodoError> errors;
  final Program lastValidProgram;
}

/// The one editing surface.
class EditorController extends ChangeNotifier {
  EditorController({
    String initialSource = '',
    KeywordTable? keywords,
    this.world = 1,
    this.maxHistory = 200,
  }) : _keywords = keywords ?? KeywordTables.fr {
    final parsed = parse(initialSource, _keywords);
    _program = parsed.program;
    _lastValid = parsed.program;
    _errors = parsed.errors;
    // The child's own text, verbatim — NOT re-rendered from the tree.
    //
    // Rendering here looks tidy and quietly deletes work: a parse error drops the
    // offending statement, so re-rendering a saved file with a typo in it would open it
    // with the typo's whole line missing. The child would not be told, and the M3
    // prompt's `Do not` is explicit — do not auto-correct a child's code. An empty source
    // is the only case where there is nothing to preserve.
    _text = initialSource.isEmpty ? render(_program, _keywords) : initialSource;
    _history.add(_text);
  }

  KeywordTable _keywords;
  final int world;

  /// `FR-M2-09` says unlimited undo. A bounded deque is the honest implementation on a
  /// 2 GB phone; 200 steps is far past the acceptance test's fifty and past anything a
  /// child does in a sitting. When it is full the *oldest* step is dropped, so the recent
  /// past — the part an undo is for — is never the part that is lost.
  final int maxHistory;

  late Program _program;
  late Program _lastValid;
  late List<KodoError> _errors;
  late String _text;

  final List<String> _history = [];
  final List<String> _redo = [];
  final List<EditEvent> _events = [];

  EditorView _view = EditorView.blocks;

  Program get program => _program;
  List<KodoError> get errors => List.unmodifiable(_errors);
  String get text => _text;
  EditorView get view => _view;
  KeywordTable get keywords => _keywords;
  TextMode get textMode => textModeForWorld(world);
  List<EditEvent> get events => List.unmodifiable(_events);

  bool get canUndo => _history.length > 1;
  bool get canRedo => _redo.isNotEmpty;
  bool get parses => _errors.isEmpty;

  /// The program as the child would read it in [locale]'s keywords.
  String renderIn(KeywordTable table) => render(_program, table);

  void _commit(String source, EditEvent event) {
    final parsed = parse(source, _keywords);
    _program = parsed.program;
    _errors = parsed.errors;
    if (parsed.errors.isEmpty) _lastValid = parsed.program;
    _text = source;
    _history.add(source);
    while (_history.length > maxHistory) {
      _history.removeAt(0);
    }
    _redo.clear();
    _events.add(event);
    notifyListeners();
  }

  /// Replaces the program from the block editor.
  void setProgram(Program program,
      {String kind = 'block_edit', String? nodeId}) {
    _commit(render(program, _keywords), EditEvent(kind, nodeId: nodeId));
  }

  /// Replaces the text from the text editor. Invalid text is kept — a child must be able
  /// to look at their own mistake (`FR-M3-03`), so the editor does not reject typing.
  void setText(String source, {String kind = 'text_edit'}) {
    _commit(source, EditEvent(kind));
  }

  /// `FR-M2-09`. Returns false when there is nothing to undo.
  bool undo() {
    if (!canUndo) return false;
    _redo.add(_history.removeLast());
    _applyCurrent();
    _events.add(const EditEvent('undo'));
    notifyListeners();
    return true;
  }

  bool redo() {
    if (!canRedo) return false;
    _history.add(_redo.removeLast());
    _applyCurrent();
    _events.add(const EditEvent('redo'));
    notifyListeners();
    return true;
  }

  void _applyCurrent() {
    final source = _history.last;
    final parsed = parse(source, _keywords);
    _program = parsed.program;
    _errors = parsed.errors;
    if (parsed.errors.isEmpty) _lastValid = parsed.program;
    _text = source;
  }

  /// Switches keyword language without touching the program (`FR-M15-03`).
  ///
  /// This is World 11's lesson. It re-renders rather than re-parsing the old text, so a
  /// program with a mistake in it also survives the switch.
  void setKeywordLanguage(KeywordTable table) {
    if (table.locale == _keywords.locale) return;
    final wasValid = _errors.isEmpty;
    _keywords = table;
    if (wasValid) {
      _text = render(_program, table);
      _history.add(_text);
    }
    _events.add(EditEvent('keyword_locale_changed', detail: table.locale));
    notifyListeners();
  }

  /// Blocks → text is always safe.
  void showText() {
    _view = EditorView.text;
    _text = render(_program, _keywords);
    _events.add(const EditEvent('bridge_toggled', detail: 'text'));
    notifyListeners();
  }

  /// Text → blocks, which is safe only when the text parses.
  ///
  /// Returns null on success, or the conflict the interface must put to the child. It does
  /// **not** decide for them: auto-correcting a child's code is forbidden by the M3
  /// prompt's `Do not`, and silently reverting would be worse.
  BridgeConflict? showBlocks() {
    final parsed = parse(_text, _keywords);
    if (parsed.errors.isNotEmpty) {
      return BridgeConflict(parsed.errors, _lastValid);
    }
    _program = parsed.program;
    _lastValid = parsed.program;
    _errors = const [];
    _view = EditorView.blocks;
    _events.add(const EditEvent('bridge_toggled', detail: 'blocks'));
    notifyListeners();
    return null;
  }

  /// The child chose *"reviens à ta dernière version qui marchait"*.
  void restoreLastValid() {
    _program = _lastValid;
    _errors = const [];
    _text = render(_program, _keywords);
    _history.add(_text);
    _view = EditorView.blocks;
    _events.add(const EditEvent('bridge_restored'));
    notifyListeners();
  }
}
