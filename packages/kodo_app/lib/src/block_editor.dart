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
        return Padding(
          padding: EdgeInsets.only(left: 16.0 * row.depth, bottom: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: BlockChip(
              key: Key('block-${row.node.id}'),
              label: row.label,
              family: row.family,
              semanticsLabel: '${row.label}, ${_familyName(row.family)}'
                  '${row.depth > 0 ? ', niveau ${row.depth + 1}' : ''}',
              selected: row.node.id == _selectedNodeId,
              onTap: () {
                selectRow(row.node.id);
                runFrom(row.node.id);
              },
            ),
          ),
        );
      },
    );
  }
}
