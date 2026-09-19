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
import 'block_stack.dart';

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
    this.site = const DropSite(index: 0),
  });

  final Node node;
  final int depth;

  /// Where this row sits in the tree (`FR-M2-06`).
  ///
  /// The flattened rows are what a child points at, and a drop has to be expressed against
  /// the tree — so the row carries the translation. For a block, it is the block's own
  /// place; for the closing lip of a C-block, it is the *end of that block's mouth*, which
  /// is how a child drops something in at the bottom of a loop.
  final DropSite site;

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

  void walkStatements(List<AsStmt> body, int depth,
      {String? ownerId, BodySlot slot = BodySlot.body}) {
    for (var index = 0; index < body.length; index++) {
      final stmt = body[index];
      final here = DropSite(ownerId: ownerId, slot: slot, index: index);
      switch (stmt) {
        case Command():
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            site: here,
            label: _renderInline(stmt, keywords),
            family: blockHelp[stmt.opcode]?.family ?? BlockFamily.mouvement,
            isWrapperOpen: false,
            isWrapperClose: false,
          ));
        case Comment(:final text):
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            site: here,
            label: '#$text',
            family: BlockFamily.mesBlocs,
            isWrapperOpen: false,
            isWrapperClose: false,
          ));
        case Assign(:final variable):
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            site: here,
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
            site: here,
            label: _renderHead(stmt, keywords),
            family: BlockFamily.controle,
            isWrapperOpen: true,
            isWrapperClose: false,
          ));
          walkStatements(body, depth + 1, ownerId: (stmt as Node).id);
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            site: DropSite(ownerId: stmt.id, index: body.length),
            label: '',
            family: BlockFamily.controle,
            isWrapperOpen: false,
            isWrapperClose: true,
          ));
        case If(:final then, :final orElse):
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            site: here,
            label: _renderHead(stmt, keywords),
            family: BlockFamily.controle,
            isWrapperOpen: true,
            isWrapperClose: false,
          ));
          walkStatements(then, depth + 1, ownerId: stmt.id);
          if (orElse != null) {
            /* The `sinon` divider is the end of the `si` mouth, so that is where dropping
               on it puts a stack. The mouth below it is a different place entirely: a
               program with a block in `sinon` is not the program with it at the end of
               `si`, and a drop that confused the two would be silently wrong. */
            rows.add(BlockRow(
              node: stmt,
              depth: depth,
              site: DropSite(ownerId: stmt.id, index: then.length),
              label: keywords.writeSyntax(SyntaxWord.else_),
              family: BlockFamily.controle,
              isWrapperOpen: true,
              isWrapperClose: true,
            ));
            walkStatements(orElse, depth + 1,
                ownerId: stmt.id, slot: BodySlot.orElse);
          }
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            site: orElse == null
                ? DropSite(ownerId: stmt.id, index: then.length)
                : DropSite(
                    ownerId: stmt.id,
                    slot: BodySlot.orElse,
                    index: orElse.length),
            label: '',
            family: BlockFamily.controle,
            isWrapperOpen: false,
            isWrapperClose: true,
          ));
        case ProcDef(:final body):
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            site: here,
            label: _renderHead(stmt, keywords),
            family: BlockFamily.mesBlocs,
            isWrapperOpen: true,
            isWrapperClose: false,
          ));
          walkStatements(body, depth + 1, ownerId: stmt.id);
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            site: DropSite(ownerId: stmt.id, index: body.length),
            label: '',
            family: BlockFamily.mesBlocs,
            isWrapperOpen: false,
            isWrapperClose: true,
          ));
        /* An event script is a hat block with a body, and it was falling through to the
           default below — which rendered `quand touche "espace" { avance 10 }` as one
           flat row with its braces showing, and gave its body no indentation and its
           trigger no editable slot. World 5 shipped that way because nothing looked at a
           `WhenEvent` here; World 10's dropdowns are what made it visible. */
        case WhenEvent(:final body):
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            site: here,
            label: _renderHead(stmt, keywords),
            family: BlockFamily.evenements,
            isWrapperOpen: true,
            isWrapperClose: false,
          ));
          walkStatements(body, depth + 1, ownerId: stmt.id);
          rows.add(BlockRow(
            node: stmt,
            depth: depth,
            site: DropSite(ownerId: stmt.id, index: body.length),
            label: '',
            family: BlockFamily.evenements,
            isWrapperOpen: false,
            isWrapperClose: true,
          ));
        default:
          rows.add(BlockRow(
            node: stmt as Node,
            depth: depth,
            site: here,
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

/// A named argument, chosen from a list (`FR-M2-05`).
///
/// The same shape as [NumberField] on purpose: a child who has learned that the thing
/// inside a block can be pressed should not have to learn it twice. The difference is
/// what opens — a list of names rather than a keypad — because a name is chosen and never
/// typed. There is no keyboard anywhere in this, which is the whole point: a
/// five-year-old spelling of *sourisappuyée* is a program that does not run.
class ChoiceField extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.value,
    required this.options,
    required this.family,
    required this.onChanged,
    this.locale = 'fr',
  });

  /// Null means a hole, drawn the way a number hole is.
  final String? value;
  final List<String> options;
  final BlockFamily family;
  final void Function(String) onChanged;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final text = value ?? '?';
    return Semantics(
      label: uiStrings.render(
          value == null ? 'a11y.choice_gap' : 'a11y.choice_field',
          UiLocale.byCode(locale),
          {'value': text}),
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: options.isEmpty
            // An empty list is not a dialogue: a project with no sounds has nothing to
            // choose, and opening a blank sheet over the program would say otherwise.
            ? null
            : () async {
                final next = await showDialog<String>(
                  context: context,
                  builder: (context) =>
                      ChoiceList(value: value, options: options, locale: locale),
                );
                if (next != null) onChanged(next);
              },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              minWidth: minimumTouchTarget, minHeight: minimumTouchTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
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
                  const SizedBox(width: 4),
                  // The arrow says "there are others", which a bare word does not.
                  Icon(Icons.arrow_drop_down, color: family.colour),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The list a [ChoiceField] opens: one name per row, each a full touch target.
class ChoiceList extends StatelessWidget {
  const ChoiceList(
      {super.key, required this.value, required this.options, this.locale = 'fr'});

  final String? value;
  final List<String> options;
  final String locale;

  @override
  Widget build(BuildContext context) => AlertDialog(
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: 280,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final option in options)
                ListTile(
                  key: Key('choice-$option'),
                  // 48 dp, like every other target a child has to hit (`FR-M2-04`).
                  minTileHeight: minimumTouchTarget,
                  title: Text(option, style: const TextStyle(fontSize: 18)),
                  // A tick, not a highlight: the current one has to be findable without
                  // relying on colour (`FR-M16-01`).
                  trailing: option == value ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.of(context).pop(option),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('choice-cancel'),
            onPressed: () => Navigator.of(context).pop(),
            // The same word the number pad uses. Two ways out of two very similar
            // dialogues should not read differently.
            child: Text(uiStrings.render('button.undo', UiLocale.byCode(locale))),
          ),
        ],
      );
}

/// The handle that picks up a stack (`FR-M2-06`).
///
/// A separate target beside the block, never the block itself. The block already means two
/// things — a tap runs it, a long press explains it — and giving the same pixels a third
/// meaning is how a child runs a program they meant to move.
///
/// It is both a button and a drag source. Tapping picks the stack up and leaves it held
/// while the child chooses where it goes, which is the path that works on a five-inch
/// screen (`G4-003`: two eight-year-olds who could not drag accurately, and both
/// abandoned). Dragging does the same thing for anyone who would rather drag.
class GrabHandle extends StatelessWidget {
  const GrabHandle({
    super.key,
    required this.family,
    required this.held,
    required this.semanticsLabel,
    required this.onGrab,
  });

  final BlockFamily family;

  /// True while this handle's stack is the one in the child's hands.
  final bool held;

  final String semanticsLabel;
  final VoidCallback onGrab;

  @override
  Widget build(BuildContext context) {
    final handle = Semantics(
      label: semanticsLabel,
      button: true,
      selected: held,
      child: SizedBox(
        width: minimumTouchTarget,
        height: minimumTouchTarget,
        child: Material(
          color: held
              ? family.colour
              : family.colour.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onGrab,
            borderRadius: BorderRadius.circular(8),
            child: ExcludeSemantics(
              child: Icon(
                held ? Icons.back_hand : Icons.drag_indicator,
                size: 20,
                color: held ? Colors.white : family.colour,
              ),
            ),
          ),
        ),
      ),
    );

    return LongPressDraggable<String>(
      data: 'grab',
      onDragStarted: onGrab,
      feedback: Material(
        color: Colors.transparent,
        child: Icon(Icons.back_hand, size: 28, color: family.colour),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: handle),
      child: handle,
    );
  }
}

/// A place a held stack can be put down (`FR-M2-06`).
///
/// Drawn only while something is held, and only where the drop is legal — so a child finds
/// out that a loop cannot go inside itself by the gap simply not being there, rather than
/// by being refused after they have committed to the gesture.
class DropGap extends StatelessWidget {
  const DropGap({
    super.key,
    required this.depth,
    required this.family,
    required this.semanticsLabel,
    required this.onDrop,
  });

  final int depth;
  final BlockFamily family;
  final String semanticsLabel;
  final VoidCallback onDrop;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (_) => onDrop(),
      builder: (context, candidate, _) => Semantics(
        label: semanticsLabel,
        button: true,
        child: Padding(
          padding: EdgeInsets.only(left: 16.0 * depth, bottom: 2),
          child: InkWell(
            onTap: onDrop,
            child: Container(
              // A full touch target even though the line drawn inside it is thin: the
              // line says where, the target is what a finger actually has to hit.
              height: minimumTouchTarget,
              alignment: Alignment.centerLeft,
              child: Container(
                height: candidate.isEmpty ? 4 : 8,
                width: 120,
                decoration: BoxDecoration(
                  color: family.colour.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
