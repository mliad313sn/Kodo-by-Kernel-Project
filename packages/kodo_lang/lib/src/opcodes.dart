/// The canonical opcode table (FR-M1-02).
///
/// Opcodes are stable identifiers. They are never shown to a child and never parsed from
/// source; the keyword tables in [KeywordTable] map them to display words per locale. This
/// indirection is the whole reason a French program and an English program can be the same
/// program (§4.4), and it is why adding Wolof is a data change, not a code change.
library;

/// Where an opcode may appear.
enum OpcodeKind {
  /// Performs an action, yields nothing. `avance 100`.
  command,

  /// Yields a value. `hasard 1 10`. May also stand alone as a statement; the result is
  /// discarded, exactly as in the source tradition.
  function,
}

/// Palette family, mirroring the ten block families of `FR-M2-01`. M2 reads this rather
/// than keeping a second list that can drift out of step.
enum OpcodeFamily {
  mouvement,
  apparence,
  son,
  stylo,
  donnees,
  evenements,
  controle,
  capteurs,
  operateurs
}

enum Opcode {
  // --- Mouvement -----------------------------------------------------------------------
  moveForward('MOVE_FORWARD', OpcodeKind.command, OpcodeFamily.mouvement, 1, 1),
  moveBack('MOVE_BACK', OpcodeKind.command, OpcodeFamily.mouvement, 1, 1),
  turnLeft('TURN_LEFT', OpcodeKind.command, OpcodeFamily.mouvement, 1, 1),
  turnRight('TURN_RIGHT', OpcodeKind.command, OpcodeFamily.mouvement, 1, 1),
  setDirection(
      'SET_DIRECTION', OpcodeKind.command, OpcodeFamily.mouvement, 1, 1),
  getDirection(
      'GET_DIRECTION', OpcodeKind.function, OpcodeFamily.mouvement, 0, 0),
  center('CENTER', OpcodeKind.command, OpcodeFamily.mouvement, 0, 0),
  go('GO', OpcodeKind.command, OpcodeFamily.mouvement, 2, 2),
  goX('GO_X', OpcodeKind.command, OpcodeFamily.mouvement, 1, 1),
  goY('GO_Y', OpcodeKind.command, OpcodeFamily.mouvement, 1, 1),
  positionX('POSITION_X', OpcodeKind.function, OpcodeFamily.mouvement, 0, 0),
  positionY('POSITION_Y', OpcodeKind.function, OpcodeFamily.mouvement, 0, 0),

  // --- Stylo ---------------------------------------------------------------------------
  penUp('PEN_UP', OpcodeKind.command, OpcodeFamily.stylo, 0, 0),
  penDown('PEN_DOWN', OpcodeKind.command, OpcodeFamily.stylo, 0, 0),
  penWidth('PEN_WIDTH', OpcodeKind.command, OpcodeFamily.stylo, 1, 1),
  penColor('PEN_COLOR', OpcodeKind.command, OpcodeFamily.stylo, 3, 3),

  // --- Canevas -------------------------------------------------------------------------
  canvasSize('CANVAS_SIZE', OpcodeKind.command, OpcodeFamily.apparence, 2, 2),
  canvasColor('CANVAS_COLOR', OpcodeKind.command, OpcodeFamily.apparence, 3, 3),
  clear('CLEAR', OpcodeKind.command, OpcodeFamily.apparence, 0, 0),
  reset('RESET', OpcodeKind.command, OpcodeFamily.apparence, 0, 0),

  // --- Lutin ---------------------------------------------------------------------------
  show('SHOW', OpcodeKind.command, OpcodeFamily.apparence, 0, 0),
  hide('HIDE', OpcodeKind.command, OpcodeFamily.apparence, 0, 0),

  // --- Texte ---------------------------------------------------------------------------
  print('PRINT', OpcodeKind.command, OpcodeFamily.apparence, 1, 1),
  fontSize('FONT_SIZE', OpcodeKind.command, OpcodeFamily.apparence, 1, 1),

  // --- Maths ---------------------------------------------------------------------------
  round('ROUND', OpcodeKind.function, OpcodeFamily.operateurs, 1, 1),
  random('RANDOM', OpcodeKind.function, OpcodeFamily.operateurs, 2, 2),
  mod('MOD', OpcodeKind.function, OpcodeFamily.operateurs, 2, 2),
  sqrt('SQRT', OpcodeKind.function, OpcodeFamily.operateurs, 1, 1),
  pi('PI', OpcodeKind.function, OpcodeFamily.operateurs, 0, 0),
  sin('SIN', OpcodeKind.function, OpcodeFamily.operateurs, 1, 1),
  cos('COS', OpcodeKind.function, OpcodeFamily.operateurs, 1, 1),
  tan('TAN', OpcodeKind.function, OpcodeFamily.operateurs, 1, 1),
  arcsin('ARCSIN', OpcodeKind.function, OpcodeFamily.operateurs, 1, 1),
  arccos('ARCCOS', OpcodeKind.function, OpcodeFamily.operateurs, 1, 1),
  arctan('ARCTAN', OpcodeKind.function, OpcodeFamily.operateurs, 1, 1),

  // --- Dialogue ------------------------------------------------------------------------
  message('MESSAGE', OpcodeKind.command, OpcodeFamily.apparence, 1, 1),
  ask('ASK', OpcodeKind.function, OpcodeFamily.capteurs, 1, 1),

  // --- Contrôle ------------------------------------------------------------------------
  wait('WAIT', OpcodeKind.command, OpcodeFamily.controle, 1, 1),
  assertion('ASSERT', OpcodeKind.command, OpcodeFamily.controle, 1, 1);

  const Opcode(this.id, this.kind, this.family, this.minArgs, this.maxArgs);

  /// Stable canonical identifier. Persisted in ASTs and in stored attempts (`FR-M6-08`),
  /// so it may never change once an item has been authored against it.
  final String id;
  final OpcodeKind kind;
  final OpcodeFamily family;
  final int minArgs;
  final int maxArgs;

  static final Map<String, Opcode> _byId = {
    for (final o in Opcode.values) o.id: o
  };

  static Opcode? byId(String id) => _byId[id];

  /// True when a drawing surface must be involved. Used by M6 to decide whether an item
  /// needs a headless canvas at all.
  bool get touchesSurface =>
      family == OpcodeFamily.mouvement ||
      family == OpcodeFamily.stylo ||
      family == OpcodeFamily.apparence;
}
