/// Rendering one block (FR-M2-01, FR-M2-03, FR-M2-04, FR-M16-01, FR-M16-04).
///
/// A block carries three signals — colour, icon and silhouette — and a screen-reader
/// label. The minimum touch target is 48 dp (`FR-M2-07`) and it is a constant here rather
/// than a number sprinkled through the layout, so the accessibility test can assert it.
library;

import 'package:flutter/material.dart';
import 'package:kodo_access/kodo_access.dart';
import 'package:kodo_lang/kodo_lang.dart';

import 'block_family.dart';
import 'block_help.dart';

/// §9.3 and `FR-M2-07`. Every interactive thing a child touches is at least this big.
const double minimumTouchTarget = 48.0;

/// One row of the flattened block view.
class BlockRow {
  const BlockRow({
    required this.node,
    required this.depth,
    required this.label,
    required this.family,
    required this.isWrapperOpen,
    required this.isWrapperClose,
  });

  final Node node;
  final int depth;

  /// The words on the block, in the child's keyword language.
  final String label;
  final BlockFamily family;

  /// True for the head of a C-block, whose mouth encloses what follows.
  final bool isWrapperOpen;

  /// True for the closing lip of a C-block.
  final bool isWrapperClose;
}

/// Flattens a program into rows the block editor draws.
///
/// The block editor reads the M1 AST directly (the M2 prompt's interface contract). This
/// is a *view* of that tree, rebuilt on every change, never a parallel model that could
/// drift out of step with it.
List<BlockRow> flattenProgram(Program program, KeywordTable keywords) {
  final rows = <BlockRow>[];

  void walkStatements(List<AsStmt> body, int depth) {
    for (final stmt in body) {
      switch (stmt) {
        case Command():
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            label: _renderInline(stmt, keywords),
            family: blockHelp[stmt.opcode]?.family ?? BlockFamily.mouvement,
            isWrapperOpen: false,
            isWrapperClose: false,
          ));
        case Comment(:final text):
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            label: '#$text',
            family: BlockFamily.mesBlocs,
            isWrapperOpen: false,
            isWrapperClose: false,
          ));
        case Assign(:final variable):
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            label: _renderInline(stmt, keywords),
            family: BlockFamily.donnees,
            isWrapperOpen: false,
            isWrapperClose: false,
          ));
          if (variable.isEmpty) continue;
        case Repeat(:final body):
        case While(:final body):
        case For(:final body):
          rows.add(BlockRow(
            node: stmt as Node,
            depth: depth,
            label: _renderHead(stmt, keywords),
            family: BlockFamily.controle,
            isWrapperOpen: true,
            isWrapperClose: false,
          ));
          walkStatements(body, depth + 1);
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            label: '',
            family: BlockFamily.controle,
            isWrapperOpen: false,
            isWrapperClose: true,
          ));
        case If(:final then, :final orElse):
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            label: _renderHead(stmt, keywords),
            family: BlockFamily.controle,
            isWrapperOpen: true,
            isWrapperClose: false,
          ));
          walkStatements(then, depth + 1);
          if (orElse != null) {
            rows.add(BlockRow(
              node: stmt,
              depth: depth,
              label: keywords.writeSyntax(SyntaxWord.else_),
              family: BlockFamily.controle,
              isWrapperOpen: true,
              isWrapperClose: true,
            ));
            walkStatements(orElse, depth + 1);
          }
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            label: '',
            family: BlockFamily.controle,
            isWrapperOpen: false,
            isWrapperClose: true,
          ));
        case ProcDef(:final body):
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            label: _renderHead(stmt, keywords),
            family: BlockFamily.mesBlocs,
            isWrapperOpen: true,
            isWrapperClose: false,
          ));
          walkStatements(body, depth + 1);
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            label: '',
            family: BlockFamily.mesBlocs,
            isWrapperOpen: false,
            isWrapperClose: true,
          ));
        default:
          rows.add(BlockRow(
            node: stmt as Node,
            depth: depth,
            label: _renderInline(stmt, keywords),
            family: BlockFamily.controle,
            isWrapperOpen: false,
            isWrapperClose: false,
          ));
      }
    }
  }

  walkStatements(program.body, 0);
  return rows;
}

String _renderInline(AsStmt stmt, KeywordTable keywords) {
  final single = Program('tmp', SourceSpan.none, [stmt]);
  return render(single, keywords).trim();
}

/// The head line of a C-block: everything before the `{`.
String _renderHead(AsStmt stmt, KeywordTable keywords) {
  final text = _renderInline(stmt, keywords);
  final brace = text.indexOf('{');
  return (brace < 0 ? text : text.substring(0, brace)).trim();
}

/// One block on screen.
class BlockChip extends StatelessWidget {
  const BlockChip({
    super.key,
    required this.label,
    required this.family,
    required this.semanticsLabel,
    this.selected = false,
    this.onTap,
    this.onHelp,
    this.fields = const [],
  });

  final String label;
  final BlockFamily family;

  /// What a screen reader announces (`FR-M16-04`). Never the same string as [label]: a
  /// child using a screen reader needs the family named, because they cannot see the
  /// colour that tells a sighted child which it is.
  final String semanticsLabel;

  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onHelp;

  /// The editable numbers this block carries (`FR-M2-04`).
  ///
  /// Inside the block, not beside it. A block spans the width of the script — that is how
  /// a block has looked since Scratch — so a number placed next to it lands on a line of
  /// its own and stops reading as part of anything. Written out, `avance 50` is one
  /// thing; on screen it has to stay one thing.
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: minimumTouchTarget,
          minWidth: minimumTouchTarget,
        ),
        child: Material(
          color: family.colour,
          borderRadius: _radiusFor(family.silhouette),
          child: InkWell(
            onTap: onTap,
            onLongPress: onHelp,
            borderRadius: _radiusFor(family.silhouette),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The icon is the second signal. It is never decorative, so it is
                  // excluded from semantics — the label already names the family.
                  ExcludeSemantics(
                      child: Icon(family.icon, size: 18, color: Colors.white)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  for (final field in fields) ...[
                    const SizedBox(width: 8),
                    field,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The third signal: the outline shape. Different families round differently, so the
  /// silhouette alone separates a control block from a reporter.
  static BorderRadius _radiusFor(BlockSilhouette silhouette) =>
      switch (silhouette) {
        BlockSilhouette.stack => BorderRadius.circular(6),
        BlockSilhouette.hat => const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(4)),
        BlockSilhouette.wrapper => const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(6)),
        BlockSilhouette.reporter => BorderRadius.circular(20),
        BlockSilhouette.boolean => BorderRadius.circular(2),
        BlockSilhouette.cap => const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20)),
      };
}

/// A number inside a block, and the pad that changes it (`FR-M2-04`).
///
/// A pad rather than a text field, and this is not a simplification. A text field on a
/// phone raises a full keyboard over the program the child is reading, accepts `12e4` and
/// `--3`, and gives an eight-year-old six ways to produce something the parser will
/// refuse. Ten digits, a minus sign and a rubber cannot produce a number that is not a
/// number.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.value,
    required this.family,
    required this.onChanged,
    this.locale = 'fr',
  });

  /// Null means a hole: the author wrote `___` and the child has not filled it yet.
  final num? value;
  final BlockFamily family;
  final void Function(num) onChanged;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final text = value == null ? '?' : '$value';
    return Semantics(
      // The screen reader says what it is and that it can be changed, because a number
      // that reads as decoration is a number nobody edits.
      label: uiStrings.render(
          value == null ? 'a11y.number_gap' : 'a11y.number_field',
          UiLocale.byCode(locale),
          {'value': text}),
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final next = await showDialog<num>(
            context: context,
            builder: (context) => NumberPad(value: value, locale: locale),
          );
          if (next != null) onChanged(next);
        },
        /* Sized by its number, never by the room it is in. A `Container` with an
           `alignment` set grows to fill whatever constraints it is handed, which put a
           three-character field across the full width of the script and pushed the block
           it belongs to onto its own line — the same layout `BlockChip` avoids by
           building its content out of a `Row(mainAxisSize: min)`. */
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              minWidth: minimumTouchTarget, minHeight: minimumTouchTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              /* A hole is drawn with a heavier rim so a child can see there is something
                 to fill without being told. Shape, not colour. */
              border:
                  Border.all(color: family.colour, width: value == null ? 3 : 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: value == null ? family.colour : null)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ten digits, a minus sign, a rubber, and a way out.
class NumberPad extends StatefulWidget {
  const NumberPad({super.key, required this.value, this.locale = 'fr'});

  /// Null for a hole: the pad opens empty rather than on a number nobody chose.
  final num? value;
  final String locale;

  @override
  State<NumberPad> createState() => _NumberPadState();
}

/// The rubber. A name, not a glyph: U+232B is missing from the fonts a tree-shaken
/// Flutter web build ships, and it rendered as an empty box on the first run in a
/// browser — a button a child cannot read is a button a child will not press.
const String _back = 'back';

class _NumberPadState extends State<NumberPad> {
  late String _text = widget.value?.toString() ?? '';

  /// What the pad currently means. An empty box is zero, not an error.
  num get _value => num.tryParse(_text) ?? 0;

  void _press(String key) {
    setState(() {
      switch (key) {
        case _back:
          if (_text.isNotEmpty) _text = _text.substring(0, _text.length - 1);
        case '−':
          // One sign, at the front, toggled. `--3` is not reachable from here.
          _text = _text.startsWith('-') ? _text.substring(1) : '-$_text';
        default:
          // A number a child can keep typing forever is a number that overflows a block
          // and a canvas. Six digits is past anything World 1 to 12 asks for.
          if (_text.replaceAll('-', '').length < 6) _text = '$_text$key';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = UiLocale.byCode(widget.locale);
    return AlertDialog(
      key: const Key('number-pad'),
      title: Text(_text.isEmpty ? '0' : _text,
          key: const Key('number-pad-value'),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 240,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.3,
          children: [
            for (final key in const [
              '1', '2', '3', '4', '5', '6', '7', '8', '9', '−', '0', _back
            ])
              FilledButton.tonal(
                key: Key('pad-$key'),
                onPressed: () => _press(key),
                style: FilledButton.styleFrom(
                    minimumSize:
                        const Size(minimumTouchTarget, minimumTouchTarget),
                    padding: EdgeInsets.zero),
                child: key == _back
                    ? const Icon(Icons.backspace_outlined, size: 22)
                    : Text(key, style: const TextStyle(fontSize: 22)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('pad-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(uiStrings.render('button.undo', locale)),
        ),
        FilledButton(
          key: const Key('pad-ok'),
          onPressed: () => Navigator.of(context).pop(_value),
          child: Text(uiStrings.render('button.ok', locale)),
        ),
      ],
    );
  }
}
