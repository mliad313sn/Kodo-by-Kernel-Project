/// Palette scoping (FR-M2-08).
///
/// *"an exercise may expose only the blocks it needs, so a beginner is never facing 120
/// blocks"* — and the M2 prompt's `Do not`: **no more than 12 blocks in the visible
/// palette for Worlds 0–2.**
///
/// The default scope per world is data, so a content pack can narrow it further per item
/// without an app release.
library;

import 'package:kodo_lang/kodo_lang.dart';

/// What the palette may show.
class PaletteScope {
  const PaletteScope(this.opcodes);

  final List<Opcode> opcodes;

  /// Everything. The Studio (M9) uses this: *"the Studio is where a child may attempt what
  /// they have not yet been taught."*
  static final unrestricted = PaletteScope(Opcode.values.toList());

  static PaletteScope ofIds(List<String> ids) => PaletteScope([
        for (final id in ids)
          if (Opcode.byId(id) != null) Opcode.byId(id)!,
      ]);

  int get length => opcodes.length;
  bool allows(Opcode op) => opcodes.contains(op);
}

/// The default scope for each world, cumulative — a child keeps what they have learned.
///
/// The counts matter and are asserted in a test: Worlds 0 to 2 stay at or under twelve.
const worldOpcodes = <int, List<String>>{
  0: ['MOVE_FORWARD', 'TURN_RIGHT', 'CLEAR'],
  1: [
    'MOVE_FORWARD',
    'MOVE_BACK',
    'TURN_LEFT',
    'TURN_RIGHT',
    'PEN_UP',
    'PEN_DOWN',
    'CLEAR'
  ],
  2: [
    'MOVE_FORWARD',
    'MOVE_BACK',
    'TURN_LEFT',
    'TURN_RIGHT',
    'PEN_UP',
    'PEN_DOWN',
    'CLEAR',
    'RESET',
    'WAIT',
    'CENTER'
  ],
  3: [
    'MOVE_FORWARD',
    'MOVE_BACK',
    'TURN_LEFT',
    'TURN_RIGHT',
    'PEN_UP',
    'PEN_DOWN',
    'PEN_WIDTH',
    'PEN_COLOR',
    'CANVAS_SIZE',
    'CANVAS_COLOR',
    'CLEAR',
    'RESET',
    'WAIT',
    'CENTER'
  ],
  4: [
    'MOVE_FORWARD',
    'MOVE_BACK',
    'TURN_LEFT',
    'TURN_RIGHT',
    'SET_DIRECTION',
    'GO',
    'GO_X',
    'GO_Y',
    'POSITION_X',
    'POSITION_Y',
    'CENTER',
    'PEN_UP',
    'PEN_DOWN',
    'PEN_WIDTH',
    'PEN_COLOR',
    'CANVAS_SIZE',
    'CANVAS_COLOR',
    'CLEAR',
    'RESET',
    'WAIT'
  ],
};

/// The scope for [world], falling back to everything learned so far.
PaletteScope scopeForWorld(int world) {
  final ids = worldOpcodes[world.clamp(0, 4)] ?? worldOpcodes[4]!;
  return PaletteScope.ofIds(
      world > 4 ? Opcode.values.map((o) => o.id).toList() : ids);
}
