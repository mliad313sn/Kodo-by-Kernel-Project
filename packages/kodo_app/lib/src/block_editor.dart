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

import 'block_choices.dart';
import 'block_family.dart';
import 'block_help.dart';
import 'block_stack.dart';
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
    this.choices = BlockChoices.empty,
    this.onRunStack,
    this.onShowHelp,
    this.highlightedNodeId,
    this.compact = false,
  });

  final EditorController controller;
  final PaletteScope scope;
  final String locale;

  /// What the dropdowns offer (`FR-M2-05`). The language's own lists come with it; the
  /// project's sprites, backdrops and sounds are handed in, because they are content.
  final BlockChoices choices;

  /// `FR-M2-02`: clicking any block or stack runs it immediately.
  final void Function(Program stack)? onRunStack;

  /// `FR-M2-10`: one tap opens the reference entry with a runnable example.
  final void Function(Opcode opcode)? onShowHelp;

  /// The statement a slow or stepped run is on (`FR-M4-07`).
  ///
  /// Given from outside rather than owned here, because the *same* value lights the text
  /// view's line. Two views, one cursor — which is the block/text bridge proving itself
  /// every second of a slow run.
  final String? highlightedNodeId;

  /// Phone layout: the palette becomes a bottom sheet (`FR-M2-07`).
  final bool compact;

  @override
  State<BlockEditor> createState() => BlockEditorState();
}

class BlockEditorState extends State<BlockEditor> {
  String? _selectedNodeId;
  BlockFamily _openFamily = BlockFamily.mouvement;
  String? _grabbedNodeId;

  String? get selectedNodeId => _selectedNodeId;
  BlockFamily get openFamily => _openFamily;

  /// The top block of the stack the child is holding, or null (`FR-M2-06`).
  String? get grabbedNodeId => _grabbedNodeId;

  /// The blocks that would move if the held stack were put down now.
  List<AsStmt> get grabbedStack => _grabbedNodeId == null
      ? const []
      : stackAt(widget.controller.program, _grabbedNodeId!);

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

  /// The named arguments of [node] — the ones chosen from a list rather than typed.
  ///
  /// `FR-M2-05`. A block like `lutin "chat"` has a name where `avance 50` has a number,
  /// and until World 10 there was no such block, which is why this arrived with it.
  List<ArgumentSlot> choiceSlots(Node node) {
    /* A trigger is not a `Command` — it is the head of a `WhenEvent`, which is what D-014
       added — so `quand touche "espace"` needs naming here as well or the one block in
       the language whose name a child most wants to change has no list behind it. */
    final opcode = switch (node) {
      Command(:final opcode) => opcode,
      WhenEvent(:final trigger) => trigger,
      _ => null,
    };
    if (opcode == null) return const [];
    if (!namedArguments.containsKey(opcode)) return const [];
    final args = node is Command ? node.args : (node as WhenEvent).args;
    // Always the first argument: `effet "fantôme", 50` names a thing and then sizes it,
    // and the size belongs to the number pad.
    final arg = args.isEmpty ? null : args.first;
    if (arg == null) {
      return [ArgumentSlot(commandId: node.id, index: 0, literal: null)];
    }
    if (arg is Literal && arg.value is StringValue) {
      return [ArgumentSlot(commandId: node.id, index: 0, literal: arg)];
    }
    // An expression where a name belongs is somebody being clever; leave it alone.
    return const [];
  }

  /// Fills a named slot with a chosen word.
  void setChoice(ArgumentSlot slot, String value) =>
      _fillSlot(slot, StringValue(value));

  /// Fills a slot: replaces the literal that is there, or writes one where a hole was.
  void setSlot(ArgumentSlot slot, num value) => _fillSlot(slot, NumberValue(value));

  void _fillSlot(ArgumentSlot slot, KodoValue value) {
    final program = widget.controller.program;

    AsStmt fill(AsStmt stmt) {
      if (stmt is WhenEvent && stmt.id == slot.commandId) {
        final args = [...stmt.args];
        while (args.length <= slot.index) {
          args.add(Literal('gap-${stmt.id}-${args.length}', stmt.span,
              const NumberValue(0)));
        }
        args[slot.index] =
            Literal((args[slot.index] as Node).id, stmt.span, value);
        return WhenEvent(stmt.id, stmt.span, stmt.trigger, args, stmt.body);
      }
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
      args[slot.index] =
          Literal((args[slot.index] as Node).id, stmt.span, value);
      return Command(stmt.id, stmt.span, stmt.opcode, args, form: stmt.form);
    }

    /* Into the mouths as well as along the top. This walked `program.body` and stopped,
       so `avance 50` inside a `répète` showed an editable number that could not be
       edited — the tap registered, the program did not change, and a child would have
       tapped it a dozen times before deciding the app was broken. World 1's second item
       is a number inside a loop. */
    AsStmt fillDeep(AsStmt stmt) => rebuildBodies(
        fill(stmt), (body, _) => [for (final s in body) fillDeep(s)]);

    widget.controller.setProgram(
      Program(
          program.id, program.span, [for (final s in program.body) fillDeep(s)]),
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

  /// `FR-M2-06`: picks up the block and everything under it.
  ///
  /// Grabbing is a state, not a gesture in flight, and that is the whole reason a child on
  /// a five-inch screen can do this at all. Workbook finding `G4-003` is two eight-year
  /// olds who could not drag a block accurately; a held stack that waits while they choose
  /// where it goes asks them for two taps and no accuracy. Dragging the handle does the
  /// same thing for anyone who would rather drag.
  void grabStack(String nodeId) => setState(() {
        _grabbedNodeId = _grabbedNodeId == nodeId ? null : nodeId;
        _selectedNodeId = null;
      });

  /// Puts a held stack down. A refused drop releases it where it was rather than
  /// swallowing the gesture: the child asked for something impossible and should see the
  /// program they still have.
  void dropStackAt(DropSite site) {
    final held = _grabbedNodeId;
    if (held == null) return;
    final moved = moveStack(widget.controller.program, held, site);
    if (!identical(moved, widget.controller.program)) {
      widget.controller.setProgram(moved, kind: 'stack_moved', nodeId: held);
    }
    setState(() => _grabbedNodeId = null);
  }

  void releaseStack() => setState(() => _grabbedNodeId = null);

  String _say(String key, [Map<String, String> args = const {}]) =>
      uiStrings.render(key, UiLocale.byCode(widget.locale), args);

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
          /* Phone: script above, palette as a bottom sheet. The sheet takes 210 dp where
             there is room and a share of what there is where there is not — a fixed 210
             inside a shorter box (a tutorial, which spends height on narration and one
             button) overflows, and an overflowing palette is blocks a child cannot reach
             rather than a visual blemish. */
          return LayoutBuilder(
            builder: (context, box) => Column(children: [
              Expanded(child: script),
              SizedBox(
                height: box.maxHeight.isFinite
                    ? (box.maxHeight * 0.45).clamp(120.0, 210.0)
                    : 210,
                child: palette,
              ),
            ]),
          );
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
    final held = _grabbedNodeId;
    if (held == null) {
      return ListView.builder(
        key: const Key('script-area'),
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        itemBuilder: (context, index) => _buildRow(rows[index], index),
      );
    }

    /* `FR-M2-06`, the holding half. Every place the stack could go is drawn as a gap the
       child taps, so the gesture is "pick up, then point" rather than a drag they have to
       land — and the places it could NOT go are simply not drawn, which is how a child
       finds out that a loop cannot go inside itself without being told off for trying. */
    final program = widget.controller.program;
    final endOfProgram = DropSite(index: program.body.length);
    return ListView.builder(
      key: const Key('script-area'),
      padding: const EdgeInsets.all(12),
      itemCount: rows.length * 2 + 1,
      itemBuilder: (context, index) {
        if (index.isOdd) return _buildRow(rows[(index - 1) ~/ 2], index ~/ 2);
        final at = index ~/ 2;
        final site = at < rows.length ? rows[at].site : endOfProgram;
        final depth = at < rows.length ? rows[at].depth : 0;
        if (!canDrop(program, held, site)) return const SizedBox.shrink();
        return DropGap(
          key: Key('gap-$site'),
          depth: depth,
          family: at < rows.length ? rows[at].family : BlockFamily.mouvement,
          semanticsLabel: _say('a11y.drop_here'),
          onDrop: () => dropStackAt(site),
        );
      },
    );
  }

  Widget _buildRow(BlockRow row, int index) {
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
        final names = choiceSlots(row.node);
        /* `FR-M16-04`. Two sentences: what the block says and which family it is, then —
           only when it is inside something — how deep. A child who cannot see the
           indentation has no other way to know a block is inside a loop. */
        final spoken = StringBuffer('${row.label}, ${_familyName(row.family)}.');
        if (row.depth > 0) {
          spoken.write(
              ' ${_say('a11y.block_level', {'level': '${row.depth + 1}'})}');
        }
        final chip = BlockChip(
            key: Key('block-${row.node.id}'),
            /* The words WITHOUT their numbers: the numbers are widgets now, and printing
               them in the label as well would show every value twice. */
            label: slots.isEmpty && names.isEmpty
                ? row.label
                : _wordsOnly(row.label),
            family: row.family,
            semanticsLabel: spoken.toString(),
            selected: row.node.id == _selectedNodeId,
            onTap: () {
              /* Holding a stack changes what a tap means. Running a program while the
                 child is halfway through moving part of it would run a program that does
                 not exist yet. */
              if (_grabbedNodeId != null) {
                dropStackAt(row.site);
                return;
              }
              selectRow(row.node.id);
              runFrom(row.node.id);
            },
            /* `FR-M2-04`, inside the block. Each one is a full 48 dp target, because
               workbook finding G4-003 is two eight-year-olds who could not hit a small
               target on a five-inch screen — and a number a child cannot press is a
               number a child cannot change. */
            fields: [
              /* Names first, numbers after, which is the order the blocks themselves
                 read in: `effet "fantôme", 50` chooses the thing and then sizes it. */
              for (final slot in names)
                ChoiceField(
                  key: Key('choice-${slot.key}'),
                  value: slot.literal == null
                      ? null
                      : (slot.literal!.value as StringValue).value,
                  options: widget.choices.optionsFor(
                      namedArguments[switch (row.node) {
                        Command(:final opcode) => opcode,
                        WhenEvent(:final trigger) => trigger,
                        _ => Opcode.selectSprite,
                      }]!,
                      widget.locale),
                  family: row.family,
                  locale: widget.locale,
                  onChanged: (v) => setChoice(slot, v),
                ),
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
        );
        /* `FR-M2-06`. The handle is a separate 48 dp target beside the block rather than
           the block itself, because the block already has two jobs — tap runs it
           (`FR-M2-02`) and long-press explains it (`FR-M2-10`) — and a third meaning for
           the same pixels is how a child ends up running a program they meant to move. */
        final handle = GrabHandle(
          key: Key('grab-${row.node.id}'),
          family: row.family,
          held: row.node.id == _grabbedNodeId,
          semanticsLabel: _say('a11y.grab_stack'),
          onGrab: () => grabStack(row.node.id),
        );
        /* `FR-M4-07`. A ring around the block rather than a change of its colour: the
           colour IS the family (`FR-M16-01`), and a child who has learned that blue means
           movement may not have it mean "running" for a second. */
        final running = row.node.id == widget.highlightedNodeId;
        return Padding(
          padding: EdgeInsets.only(left: 16.0 * row.depth, bottom: 6),
          child: Container(
            key: running ? const Key('running-block') : null,
            decoration: running
                ? BoxDecoration(
                    border: Border.all(color: Colors.amber.shade700, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            padding: const EdgeInsets.all(2),
            child: Row(children: [
              handle,
              const SizedBox(width: 4),
              Flexible(child: chip),
            ]),
          ),
        );
  }
}
