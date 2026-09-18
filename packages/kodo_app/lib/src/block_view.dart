/// Rendering one block (FR-M2-01, FR-M2-03, FR-M2-04, FR-M16-01, FR-M16-04).
///
/// A block carries three signals — colour, icon and silhouette — and a screen-reader
/// label. The minimum touch target is 48 dp (`FR-M2-07`) and it is a constant here rather
/// than a number sprinkled through the layout, so the accessibility test can assert it.
library;

import 'package:flutter/material.dart';
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
