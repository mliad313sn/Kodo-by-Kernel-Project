/// The block editor (M2).
///
/// *"You are building the surface where an eight-year-old writes their first program by
/// dragging."* — and, on a phone, by tapping, because `FR-M2-07` makes tap-to-place an
/// **equal-status alternative** and the workbook already records `G4-003`: two eight-year
/// olds who could not drag a block accurately on a five-inch screen, and both abandoned.
///
/// So tap-to-place is not a fallback here. It is the path the widget tests exercise, and
/// dragging is offered on top of it.
library;

import 'package:flutter/material.dart';
import 'package:kodo_access/kodo_access.dart';
import 'package:kodo_lang/kodo_lang.dart';

import 'block_family.dart';
import 'block_help.dart';
import 'block_view.dart';
import 'editor_controller.dart';
import 'palette_scope.dart';

/// Where a tapped block will land.
enum InsertMode { append, insertAfterSelection }

/// One number position on a block: a literal that is there, or a hole where one is not.
class ArgumentSlot {
  const ArgumentSlot(
      {required this.commandId, required this.index, required this.literal});

  final String commandId;
  final int index;

  /// Null for a hole — the `___` an author wrote, which the parser recovered as a missing
  /// argument and which nothing used to draw.
  final Literal? literal;

  String get key => literal?.id ?? '$commandId-gap-$index';
}

/// The palette, the script area, and the tap-to-place interaction between them.
class BlockEditor extends StatefulWidget {
  const BlockEditor({
    super.key,
    required this.controller,
    required this.scope,
    this.locale = 'fr',
    this.onRunStack,
    this.onShowHelp,
    this.compact = false,
  });

  final EditorController controller;
  final PaletteScope scope;
  final String locale;

  /// `FR-M2-02`: clicking any block or stack runs it immediately.
  final void Function(Program stack)? onRunStack;

  /// `FR-M2-10`: one tap opens the reference entry with a runnable example.
  final void Function(Opcode opcode)? onShowHelp;

  /// Phone layout: the palette becomes a bottom sheet (`FR-M2-07`).
  final bool compact;

  @override
  State<BlockEditor> createState() => BlockEditorState();
}

class BlockEditorState extends State<BlockEditor> {
  String? _selectedNodeId;
  BlockFamily _openFamily = BlockFamily.mouvement;

  String? get selectedNodeId => _selectedNodeId;
  BlockFamily get openFamily => _openFamily;

  /// Opcodes the palette currently shows: the scope, narrowed to the open family.
  List<Opcode> get visibleOpcodes => [
        for (final op in widget.scope.opcodes)
          if ((blockHelp[op]?.family ?? BlockFamily.mouvement) == _openFamily)
            op,
      ];

  /// Families that have at least one block in scope. A family tab that opens on nothing is
  /// a dead end a child will tap twice and then stop trusting.
  List<BlockFamily> get visibleFamilies => [
        for (final family in BlockFamily.values)
          if (widget.scope.opcodes.any((op) =>
              (blockHelp[op]?.family ?? BlockFamily.mouvement) == family))
            family,
      ];

  void openFamilyTab(BlockFamily family) =>
      setState(() => _openFamily = family);

  void selectRow(String nodeId) => setState(
      () => _selectedNodeId = _selectedNodeId == nodeId ? null : nodeId);

  /// Tap-to-place: the child taps a block in the palette and it lands in the script.
  ///
  /// This is the whole of `FR-M2-07`'s equal-status claim, and it is deliberately the
  /// simplest possible interaction — one tap, always works, no gesture to learn.
  void placeOpcode(Opcode opcode) {
    final program = widget.controller.program;
    final arguments = <AsExpr>[
      for (var i = 0; i < opcode.minArgs; i++)
        Literal('new-arg-$i', SourceSpan.none, const NumberValue(50)),
    ];
    final block = Command('new-${DateTime.now().microsecondsSinceEpoch}',
        SourceSpan.none, opcode, arguments);

    final body = [...program.body];
    final at = _selectedNodeId == null
        ? body.length
        : body.indexWhere((s) => (s as Node).id == _selectedNodeId) + 1;
    body.insert(at <= 0 ? body.length : at, block);

    widget.controller.setProgram(
      Program(program.id, program.span, body),
      kind: 'block_placed',
      nodeId: opcode.id,
    );
    setState(() => _selectedNodeId = null);
  }

  /// `FR-M2-04`: a number inside a block is editable, negative values included.
  ///
  /// This was the last thing standing between the application and a child finishing an
  /// exercise: the very first item the practice mix serves is *"write the number to move
  /// 50 steps"*, and until now there was no way to write a number. Tapping the number
  /// opens a pad; the block is rebuilt with the new literal and nothing else changes.
  ///
  /// Negatives matter and are not an edge case — `recule -50` is `avance 50`, and that
  /// equivalence is one of the two the grader accepts for every World 1 item.
  /// The number slots a child may fill on this row, in the order they are written.
  ///
  /// A slot is either a literal that is there or a **hole** where one is missing, and the
  /// hole is the point. A T4 item ships `avance ___`; the parser recovers it as
  /// `MOVE_FORWARD` with no arguments and says `missingArg`, so the gap the author wrote
  /// is already in the tree — it just had nothing to render it. Without this, the first
  /// exercise KODO serves ("write the number to move 70 steps") shows a block with no
  /// number and no way to add one, and the item is unanswerable.
  ///
  /// Only the top level of a command's arguments: a literal nested inside an expression is
  /// World 6's business and editing it in place needs a structure editor, not a pad.
  List<ArgumentSlot> numberSlots(Node node) {
    if (node is! Command) return const [];
    final slots = <ArgumentSlot>[];
    final count =
        node.args.length > node.opcode.minArgs ? node.args.length : node.opcode.minArgs;
    for (var i = 0; i < count; i++) {
      final arg = i < node.args.length ? node.args[i] : null;
      if (arg == null) {
        slots.add(ArgumentSlot(commandId: node.id, index: i, literal: null));
      } else if (arg is Literal && arg.value is NumberValue) {
        slots.add(ArgumentSlot(commandId: node.id, index: i, literal: arg));
      }
      // Anything else is an expression, and not a pad's business.
    }
    return slots;
  }

  /// Fills a slot: replaces the literal that is there, or writes one where a hole was.
  void setSlot(ArgumentSlot slot, num value) {
    final program = widget.controller.program;

    AsStmt fill(AsStmt stmt) {
      if (stmt is! Command || stmt.id != slot.commandId) return stmt;
      final args = [...stmt.args];
      /* A hole beyond the end needs the earlier ones to exist. They are written as zero
         rather than left out: a child filling the second of two holes has not decided the
         first, and zero is the value the language already gives an omitted number. */
      while (args.length <= slot.index) {
        args.add(Literal('gap-${stmt.id}-${args.length}', stmt.span,
            const NumberValue(0)));
      }
      /* The node keeps its identity across the edit. Undo, the block/text bridge and the
         telemetry all key on node ids, and a fresh id for every keystroke would make one
         change look like a delete and an insert. */
      args[slot.index] = Literal(
          (args[slot.index] as Node).id, stmt.span, NumberValue(value));
      return Command(stmt.id, stmt.span, stmt.opcode, args, form: stmt.form);
    }

    widget.controller.setProgram(
      Program(program.id, program.span, [for (final s in program.body) fill(s)]),
      kind: 'literal_edited',
      nodeId: slot.commandId,
    );
  }

  /// `FR-M2-02`: run one block or one stack straight away.
  void runFrom(String nodeId) {
    final program = widget.controller.program;
    final index = program.body.indexWhere((s) => (s as Node).id == nodeId);
    if (index < 0) return;
    widget.onRunStack
        ?.call(Program(program.id, program.span, program.body.sublist(index)));
  }

  String _familyName(BlockFamily family) =>
      familyNames[widget.locale]?[family.nameKey] ??
      familyNames['fr']![family.nameKey]!;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final rows = flattenProgram(
            widget.controller.program, widget.controller.keywords);
        final palette = _buildPalette();
        final script = _buildScript(rows);

        if (widget.compact) {
          // Phone: stage on top, script in the middle, palette as a bottom sheet.
          return Column(children: [
            Expanded(child: script),
            SizedBox(height: 210, child: palette),
          ]);
        }
        return Row(children: [
          SizedBox(width: 260, child: palette),
          const VerticalDivider(width: 1),
          Expanded(child: script),
        ]);
      },
    );
  }

  Widget _buildPalette() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          // The row is the target plus its padding. Setting it to the target itself
          // leaves each chip at 44 dp, which is the kind of four-pixel miss that passes
          // review and fails an eight-year-old on a five-inch screen.
          height: minimumTouchTarget + 8,
          child: ListView(
            key: const Key('family-tabs'),
            scrollDirection: Axis.horizontal,
            children: [
              for (final family in visibleFamilies)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: BlockChip(
                    key: Key('family-${family.name}'),
                    label: _familyName(family),
                    family: family,
                    semanticsLabel: uiStrings.render(
                        'a11y.family_tab',
                        UiLocale.byCode(widget.locale),
                        {'family': _familyName(family)}),
                    selected: family == _openFamily,
                    onTap: () => openFamilyTab(family),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            key: const Key('palette'),
            padding: const EdgeInsets.all(8),
            children: [
              for (final opcode in visibleOpcodes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BlockChip(
                    key: Key('palette-${opcode.id}'),
                    label: widget.controller.keywords.write(opcode),
                    family: blockHelp[opcode]?.family ?? BlockFamily.mouvement,
                    semanticsLabel:
                        '${widget.controller.keywords.write(opcode)}, '
                        '${_familyName(blockHelp[opcode]?.family ?? BlockFamily.mouvement)}',
                    onTap: () => placeOpcode(opcode),
                    onHelp: () => widget.onShowHelp?.call(opcode),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The written form with its numbers taken out, because they are drawn as fields.
  ///
  /// The keywords are what stays: `avance 50` becomes `avance`, `va 10, 20` becomes `va`.
  /// Everything that is not a bare number is left alone — an expression is not a field.
  static String _wordsOnly(String label) => label
      .replaceAll(RegExp(r'(?<![\w$])-?\d+(?:\.\d+)?'), '')
      .replaceAll(RegExp(r'\s*,\s*'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Widget _buildScript(List<BlockRow> rows) {
    return ListView.builder(
      key: const Key('script-area'),
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row.isWrapperClose && row.label.isEmpty) {
          // The closing lip of a C-block: it shows the mouth enclosing the body
          // (`FR-M2-03`) and is not itself a target.
          return Padding(
            padding: EdgeInsets.only(left: 16.0 * row.depth, bottom: 6),
            child: Container(
              key: Key('wrapper-close-$index'),
              height: 12,
              width: 72,
              decoration: BoxDecoration(
                color: row.family.colour,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
            ),
          );
        }
        final slots = numberSlots(row.node);
        return Padding(
          padding: EdgeInsets.only(left: 16.0 * row.depth, bottom: 6),
          child: BlockChip(
            key: Key('block-${row.node.id}'),
            /* The words WITHOUT their numbers: the numbers are widgets now, and printing
               them in the label as well would show every value twice. */
            label: slots.isEmpty ? row.label : _wordsOnly(row.label),
            family: row.family,
            semanticsLabel: '${row.label}, ${_familyName(row.family)}'
                '${row.depth > 0 ? ', niveau ${row.depth + 1}' : ''}',
            selected: row.node.id == _selectedNodeId,
            onTap: () {
              selectRow(row.node.id);
              runFrom(row.node.id);
            },
            /* `FR-M2-04`, inside the block. Each one is a full 48 dp target, because
               workbook finding G4-003 is two eight-year-olds who could not hit a small
               target on a five-inch screen — and a number a child cannot press is a
               number a child cannot change. */
            fields: [
              for (final slot in slots)
                NumberField(
                  key: Key('literal-${slot.key}'),
                  value: slot.literal == null
                      ? null
                      : (slot.literal!.value as NumberValue).value,
                  family: row.family,
                  locale: widget.locale,
                  onChanged: (v) => setSlot(slot, v),
                ),
            ],
          ),
        );
      },
    );
  }
}
