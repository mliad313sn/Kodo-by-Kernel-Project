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

  /// Names *when* a script runs. Only ever the head of a `quand` block, never a step
  /// inside one (`FR-M21-01`). A trigger is not something a program does; it is the
  /// question the world asks before anything is done at all.
  event,
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

  /// Text to number.
  ///
  /// Added after M9: [ask] returns text, and without this there is no way for a child to
  /// use the answer to *"combien de points ?"* as a number. Every game a nine-year-old
  /// actually wants to write needs it, and the gap was invisible until the Studio's
  /// Recettes panel tried to ship a recipe that asks the player something. See decision
  /// D-011.
  toNumber('TO_NUMBER', OpcodeKind.function, OpcodeFamily.operateurs, 1, 1),

  // --- Contrôle ------------------------------------------------------------------------
  wait('WAIT', OpcodeKind.command, OpcodeFamily.controle, 1, 1),
  assertion('ASSERT', OpcodeKind.command, OpcodeFamily.controle, 1, 1),

  // --- Événements (D-014 / FR-M21-01) --------------------------------------------------
  // Three triggers at v1, which is what §5.2 commits World 5 to and no more.
  whenFlag('WHEN_FLAG', OpcodeKind.event, OpcodeFamily.evenements, 0, 0),
  whenKey('WHEN_KEY', OpcodeKind.event, OpcodeFamily.evenements, 1, 1),
  whenClicked('WHEN_CLICKED', OpcodeKind.event, OpcodeFamily.evenements, 0, 0),

  // --- Capteurs (FR-M21-03) ------------------------------------------------------------
  // Every one of these reads the item's scripted inputs when grading, never a real device:
  // a question a grader cannot answer the same way twice is not an exercise.
  keyDown('KEY_DOWN', OpcodeKind.function, OpcodeFamily.capteurs, 1, 1),
  mouseX('MOUSE_X', OpcodeKind.function, OpcodeFamily.capteurs, 0, 0),
  mouseY('MOUSE_Y', OpcodeKind.function, OpcodeFamily.capteurs, 0, 0),
  mouseDown('MOUSE_DOWN', OpcodeKind.function, OpcodeFamily.capteurs, 0, 0),
  touchingEdge('TOUCHING_EDGE', OpcodeKind.function, OpcodeFamily.capteurs, 0, 0),
  touchingColour(
      'TOUCHING_COLOUR', OpcodeKind.function, OpcodeFamily.capteurs, 3, 3),

  // --- Lutins, costumes, sons, arrière-plans, effets (FR-M21-04) -----------------------

  /* `lutin "chat"` — choose which sprite the following blocks talk to.
  
     Added for World 10, and for a reason worth recording: concept C10.1 is "un lutin est
     un objet" and the misconception it exists to correct is *"there can be only one
     character"*. Without a way to address a second sprite, the curriculum would have
     been teaching a claim the language contradicts — the same gap `D-014` recorded when
     the language was specified against Worlds 0 to 4 while the curriculum ran to World
     12. The stage could already hold several sprites and select between them; only the
     word was missing. */
  selectSprite('SELECT_SPRITE', OpcodeKind.command, OpcodeFamily.apparence, 1, 1),
  nextCostume('NEXT_COSTUME', OpcodeKind.command, OpcodeFamily.apparence, 0, 0),
  setCostume('SET_COSTUME', OpcodeKind.command, OpcodeFamily.apparence, 1, 1),
  costumeNumber(
      'COSTUME_NUMBER', OpcodeKind.function, OpcodeFamily.apparence, 0, 0),
  setBackdrop('SET_BACKDROP', OpcodeKind.command, OpcodeFamily.apparence, 1, 1),
  setEffect('SET_EFFECT', OpcodeKind.command, OpcodeFamily.apparence, 2, 2),
  clearEffects(
      'CLEAR_EFFECTS', OpcodeKind.command, OpcodeFamily.apparence, 0, 0),
  say('SAY', OpcodeKind.command, OpcodeFamily.apparence, 1, 1),
  playSound('PLAY_SOUND', OpcodeKind.command, OpcodeFamily.son, 1, 1),
  playDrum('PLAY_DRUM', OpcodeKind.command, OpcodeFamily.son, 2, 2),
  playNote('PLAY_NOTE', OpcodeKind.command, OpcodeFamily.son, 2, 2);

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
