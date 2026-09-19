/// Keyword tables as locale data (FR-M1-02, FR-M15-01, FR-M15-03).
///
/// Nothing in the parser, the interpreter or the grader knows the word `avance`. They know
/// [Opcode.moveForward]. A keyword table maps between the two, and swapping the table
/// mid-session relabels a running program without touching it — which is the World-11
/// lesson (§4.4) and, per the cahier des charges, "the single most valuable moment in the
/// whole curriculum".
///
/// These tables are *data*. The two shipped below are the compiled-in defaults so that the
/// base app works with no content pack; [KeywordTable.fromJson] loads any other, which is
/// how Wolof arrives at v1.2 without an engineering change (PO decision D-002).
library;

import 'opcodes.dart';

/// Which of an entry's two written forms a program used.
///
/// Stored on the node rather than the lexeme itself, so that a child who typed `av`
/// still reads `av` after a block round-trip, and reads `fd` — not `forward` — after
/// switching to English keywords. Preserving the *form* rather than the *string* is what
/// lets `FR-M3-05` (never silently alter a program) and `FR-M15-03` (hot-swap) both hold.
enum KeywordForm { primary, abbreviation }

/// Words that are grammar rather than opcodes.
enum SyntaxWord {
  repeat,
  while_,
  for_,
  to,
  step,
  if_,
  else_,
  learn,
  return_,
  break_,
  exit,
  and,
  or,
  not,
  true_,
  false_,

  /// `quand` — the head of an event script (`FR-M21-01`).
  when_,
}

/// What a syntax word is called in an item's palette scope (`FR-M2-08`).
///
/// A palette is a list of what a child may reach for, and `répète` is as much a thing
/// they reach for as `avance` is — but it is grammar, so it has no opcode id. The two
/// have been sharing one list of strings since World 0, with nothing checking that a
/// palette entry names anything at all: `'REPAET'` would have shipped.
///
/// The name is derived rather than typed, so the two can never disagree: the enum's name
/// without its trailing underscore, upper-cased. `if_` is `IF`, `when_` is `WHEN`.
extension SyntaxWordPalette on SyntaxWord {
  String get paletteId => name.replaceAll('_', '').toUpperCase();
}

/// Every palette id that names a syntax word rather than an opcode.
final Set<String> syntaxPaletteIds = {
  for (final word in SyntaxWord.values) word.paletteId,
};

/// One opcode's written forms in one language.
class KeywordEntry {
  const KeywordEntry(this.primary,
      {this.abbreviation, this.aliases = const []});

  /// The canonical spelling. What the renderer writes and what block help shows.
  final String primary;

  /// The short form, e.g. `av`, `fd`. Optional — not every command has one.
  final String? abbreviation;

  /// Additional spellings accepted on input but never written back.
  ///
  /// This is where unaccented French lives: a child on a cheap Android keyboard types
  /// `repete` and `levecrayon`, and refusing that would be a syntax error caused by a
  /// keyboard rather than by a misunderstanding. The renderer always restores the accent.
  final List<String> aliases;

  String write(KeywordForm form) =>
      form == KeywordForm.abbreviation ? (abbreviation ?? primary) : primary;
}

/// A complete keyword language.
class KeywordTable {
  KeywordTable({
    required this.locale,
    required this.name,
    required Map<Opcode, KeywordEntry> opcodes,
    required Map<SyntaxWord, KeywordEntry> syntax,
  })  : _opcodes = opcodes,
        _syntax = syntax {
    for (final e in opcodes.entries) {
      _index(e.value, opcode: e.key);
    }
    for (final e in syntax.entries) {
      _index(e.value, syntax: e.key);
    }
  }

  /// BCP-47 code: `fr`, `en`.
  final String locale;

  /// Endonym, for the language picker. Shown to a child, so it is in its own language.
  final String name;

  final Map<Opcode, KeywordEntry> _opcodes;
  final Map<SyntaxWord, KeywordEntry> _syntax;
  final Map<String, KeywordLookup> _words = {};

  void _index(KeywordEntry entry, {Opcode? opcode, SyntaxWord? syntax}) {
    void put(String word, KeywordForm form) {
      final key = word.toLowerCase();
      final existing = _words[key];
      if (existing != null) {
        throw StateError(
          'keyword table "$locale" maps "$word" twice — a keyword table must be '
          'unambiguous or a program means two things at once',
        );
      }
      _words[key] = KeywordLookup(opcode: opcode, syntax: syntax, form: form);
    }

    put(entry.primary, KeywordForm.primary);
    if (entry.abbreviation != null) {
      put(entry.abbreviation!, KeywordForm.abbreviation);
    }
    for (final a in entry.aliases) {
      put(a, KeywordForm.primary);
    }
  }

  KeywordEntry entryFor(Opcode op) =>
      _opcodes[op] ??
      (throw StateError('keyword table "$locale" has no word for ${op.id}'));

  KeywordEntry entryForSyntax(SyntaxWord w) =>
      _syntax[w] ??
      (throw StateError('keyword table "$locale" has no word for $w'));

  String write(Opcode op, [KeywordForm form = KeywordForm.primary]) =>
      entryFor(op).write(form);

  String writeSyntax(SyntaxWord w) => entryForSyntax(w).primary;

  /// Resolve a written word. `null` when the word belongs to no keyword — which is how the
  /// parser knows it is looking at a procedure name or a mistake.
  KeywordLookup? resolve(String word) => _words[word.toLowerCase()];

  /// Every opcode this table can write. A table missing an opcode fails the localisation
  /// coverage gate in CI rather than at run time in front of a child.
  Set<Opcode> get coveredOpcodes => _opcodes.keys.toSet();

  Set<SyntaxWord> get coveredSyntax => _syntax.keys.toSet();

  /// Opcodes this table gives a short form to.
  ///
  /// Every shipped table must agree on this set, and a test enforces it. The reason is
  /// small and matters: if French abbreviates `montre` to `mo` and English has no short
  /// form for `show`, then a child who switches to English keywords and back finds `mo`
  /// silently expanded to `montre`. Nothing breaks, the drawing is identical — and the
  /// child has still been shown that the toggle rewrites their code, which is precisely
  /// the trust `FR-M3-05` is protecting.
  Set<Opcode> get abbreviatedOpcodes => {
        for (final e in _opcodes.entries)
          if (e.value.abbreviation != null) e.key
      };

  Map<String, Object?> toJson() => {
        'locale': locale,
        'name': name,
        'opcodes': {
          for (final e in _opcodes.entries)
            e.key.id: {
              'primary': e.value.primary,
              if (e.value.abbreviation != null)
                'abbreviation': e.value.abbreviation,
              if (e.value.aliases.isNotEmpty) 'aliases': e.value.aliases,
            },
        },
        'syntax': {
          for (final e in _syntax.entries)
            e.key.name: {
              'primary': e.value.primary,
              if (e.value.abbreviation != null)
                'abbreviation': e.value.abbreviation,
              if (e.value.aliases.isNotEmpty) 'aliases': e.value.aliases,
            },
        },
      };

  static KeywordTable fromJson(Map<String, Object?> json) {
    KeywordEntry entry(Object? raw) {
      final m = raw! as Map<String, Object?>;
      return KeywordEntry(
        m['primary']! as String,
        abbreviation: m['abbreviation'] as String?,
        aliases: ((m['aliases'] as List<Object?>?) ?? const []).cast<String>(),
      );
    }

    final ops = <Opcode, KeywordEntry>{};
    for (final e in (json['opcodes']! as Map<String, Object?>).entries) {
      final op = Opcode.byId(e.key);
      if (op == null) {
        throw ArgumentError('keyword table names an unknown opcode: ${e.key}');
      }
      ops[op] = entry(e.value);
    }
    final syn = <SyntaxWord, KeywordEntry>{};
    for (final e in (json['syntax']! as Map<String, Object?>).entries) {
      syn[SyntaxWord.values.byName(e.key)] = entry(e.value);
    }
    return KeywordTable(
      locale: json['locale']! as String,
      name: json['name']! as String,
      opcodes: ops,
      syntax: syn,
    );
  }
}

/// What a written word turned out to mean.
class KeywordLookup {
  const KeywordLookup({this.opcode, this.syntax, required this.form});
  final Opcode? opcode;
  final SyntaxWord? syntax;
  final KeywordForm form;
}

/// The two keyword languages shipped at v1 (PO decision D-002).
abstract final class KeywordTables {
  static final KeywordTable fr = KeywordTable(
    locale: 'fr',
    name: 'Français',
    opcodes: {
      Opcode.moveForward: const KeywordEntry('avance', abbreviation: 'av'),
      Opcode.moveBack: const KeywordEntry('recule', abbreviation: 're'),
      Opcode.turnLeft: const KeywordEntry('tournegauche', abbreviation: 'tg'),
      Opcode.turnRight: const KeywordEntry('tournedroite', abbreviation: 'td'),
      Opcode.setDirection: const KeywordEntry('direction', abbreviation: 'dir'),
      Opcode.getDirection: const KeywordEntry('obtenirdirection'),
      Opcode.center: const KeywordEntry('centre'),
      Opcode.go: const KeywordEntry('va'),
      Opcode.goX: const KeywordEntry('vax', abbreviation: 'vx'),
      Opcode.goY: const KeywordEntry('vay', abbreviation: 'vy'),
      Opcode.positionX: const KeywordEntry('positionx'),
      Opcode.positionY: const KeywordEntry('positiony'),
      Opcode.penUp: const KeywordEntry('lèvecrayon',
          abbreviation: 'lc', aliases: ['levecrayon']),
      Opcode.penDown: const KeywordEntry('baissecrayon', abbreviation: 'bc'),
      Opcode.penWidth: const KeywordEntry('largeurcrayon', abbreviation: 'lac'),
      Opcode.penColor: const KeywordEntry('couleurcrayon', abbreviation: 'cc'),
      Opcode.canvasSize:
          const KeywordEntry('taillecanevas', abbreviation: 'tc'),
      Opcode.canvasColor:
          const KeywordEntry('couleurcanevas', abbreviation: 'cca'),
      Opcode.clear: const KeywordEntry('nettoietout', abbreviation: 'ntt'),
      Opcode.reset: const KeywordEntry('initialise'),
      Opcode.show: const KeywordEntry('montre', abbreviation: 'mo'),
      Opcode.hide: const KeywordEntry('cache', abbreviation: 'ca'),
      Opcode.print: const KeywordEntry('écris', aliases: ['ecris']),
      Opcode.fontSize: const KeywordEntry('taillepolice'),
      Opcode.round: const KeywordEntry('arrondi'),
      Opcode.random: const KeywordEntry('hasard', abbreviation: 'hsd'),
      Opcode.mod: const KeywordEntry('mod'),
      Opcode.sqrt: const KeywordEntry('racine'),
      Opcode.pi: const KeywordEntry('pi'),
      Opcode.sin: const KeywordEntry('sin'),
      Opcode.cos: const KeywordEntry('cos'),
      Opcode.tan: const KeywordEntry('tan'),
      Opcode.arcsin: const KeywordEntry('arcsin'),
      Opcode.arccos: const KeywordEntry('arccos'),
      Opcode.arctan: const KeywordEntry('arctan'),
      Opcode.message: const KeywordEntry('message'),
      Opcode.ask: const KeywordEntry('demande'),
      Opcode.toNumber: const KeywordEntry('nombre', abbreviation: 'nb'),
      Opcode.wait: const KeywordEntry('attends'),
      Opcode.assertion: const KeywordEntry('assertion'),
      // Événements (D-014)
      Opcode.whenFlag: const KeywordEntry('drapeau'),
      Opcode.whenKey: const KeywordEntry('touche'),
      Opcode.whenClicked: const KeywordEntry('clic'),
      // Capteurs
      Opcode.keyDown: const KeywordEntry('touchepressée',
          abbreviation: 'tp', aliases: ['touchepressee']),
      Opcode.mouseX: const KeywordEntry('sourisx'),
      Opcode.mouseY: const KeywordEntry('sourisy'),
      Opcode.mouseDown: const KeywordEntry('sourisappuyée',
          aliases: ['sourisappuyee']),
      Opcode.touchingEdge: const KeywordEntry('touchebord'),
      Opcode.touchingColour: const KeywordEntry('touchecouleur'),
      // Lutins et scène
      Opcode.nextCostume: const KeywordEntry('costumesuivant',
          abbreviation: 'cs'),
      Opcode.setCostume: const KeywordEntry('costume'),
      Opcode.costumeNumber: const KeywordEntry('numérocostume',
          aliases: ['numerocostume']),
      Opcode.setBackdrop: const KeywordEntry('arrièreplan',
          aliases: ['arriereplan']),
      Opcode.setEffect: const KeywordEntry('effet'),
      Opcode.clearEffects: const KeywordEntry('effaceeffets'),
      Opcode.say: const KeywordEntry('dis'),
      Opcode.playSound: const KeywordEntry('jouson'),
      Opcode.playDrum: const KeywordEntry('tambour'),
      Opcode.playNote: const KeywordEntry('note'),
    },
    syntax: {
      SyntaxWord.when_: const KeywordEntry('quand'),
      SyntaxWord.repeat: const KeywordEntry('répète', aliases: ['repete']),
      SyntaxWord.while_: const KeywordEntry('tantque'),
      SyntaxWord.for_: const KeywordEntry('pour'),
      SyntaxWord.to: const KeywordEntry('à', aliases: ['a']),
      SyntaxWord.step: const KeywordEntry('pas'),
      SyntaxWord.if_: const KeywordEntry('si'),
      SyntaxWord.else_: const KeywordEntry('sinon'),
      SyntaxWord.learn: const KeywordEntry('apprends'),
      SyntaxWord.return_: const KeywordEntry('retourne'),
      SyntaxWord.break_: const KeywordEntry('coupure'),
      SyntaxWord.exit: const KeywordEntry('sortie'),
      SyntaxWord.and: const KeywordEntry('et'),
      SyntaxWord.or: const KeywordEntry('ou'),
      SyntaxWord.not: const KeywordEntry('non'),
      SyntaxWord.true_: const KeywordEntry('vrai'),
      SyntaxWord.false_: const KeywordEntry('faux'),
    },
  );

  static final KeywordTable en = KeywordTable(
    locale: 'en',
    name: 'English',
    opcodes: {
      Opcode.moveForward: const KeywordEntry('forward', abbreviation: 'fd'),
      Opcode.moveBack: const KeywordEntry('back', abbreviation: 'bk'),
      Opcode.turnLeft: const KeywordEntry('turnleft', abbreviation: 'tl'),
      Opcode.turnRight: const KeywordEntry('turnright', abbreviation: 'tr'),
      Opcode.setDirection: const KeywordEntry('direction', abbreviation: 'dir'),
      Opcode.getDirection: const KeywordEntry('getdirection'),
      Opcode.center: const KeywordEntry('center'),
      Opcode.go: const KeywordEntry('go'),
      Opcode.goX: const KeywordEntry('gox', abbreviation: 'gx'),
      Opcode.goY: const KeywordEntry('goy', abbreviation: 'gy'),
      Opcode.positionX: const KeywordEntry('positionx'),
      Opcode.positionY: const KeywordEntry('positiony'),
      Opcode.penUp: const KeywordEntry('penup', abbreviation: 'pu'),
      Opcode.penDown: const KeywordEntry('pendown', abbreviation: 'pd'),
      Opcode.penWidth: const KeywordEntry('penwidth', abbreviation: 'pw'),
      Opcode.penColor: const KeywordEntry('pencolor', abbreviation: 'pc'),
      Opcode.canvasSize: const KeywordEntry('canvassize', abbreviation: 'cs'),
      Opcode.canvasColor: const KeywordEntry('canvascolor', abbreviation: 'cc'),
      Opcode.clear: const KeywordEntry('clear', abbreviation: 'clr'),
      Opcode.reset: const KeywordEntry('reset'),
      Opcode.show: const KeywordEntry('show', abbreviation: 'ss'),
      Opcode.hide: const KeywordEntry('hide', abbreviation: 'sh'),
      Opcode.print: const KeywordEntry('print'),
      Opcode.fontSize: const KeywordEntry('fontsize'),
      Opcode.round: const KeywordEntry('round'),
      Opcode.random: const KeywordEntry('random', abbreviation: 'rnd'),
      Opcode.mod: const KeywordEntry('mod'),
      Opcode.sqrt: const KeywordEntry('sqrt'),
      Opcode.pi: const KeywordEntry('pi'),
      Opcode.sin: const KeywordEntry('sin'),
      Opcode.cos: const KeywordEntry('cos'),
      Opcode.tan: const KeywordEntry('tan'),
      Opcode.arcsin: const KeywordEntry('arcsin'),
      Opcode.arccos: const KeywordEntry('arccos'),
      Opcode.arctan: const KeywordEntry('arctan'),
      Opcode.message: const KeywordEntry('message'),
      Opcode.ask: const KeywordEntry('ask'),
      Opcode.toNumber: const KeywordEntry('number', abbreviation: 'nb'),
      Opcode.wait: const KeywordEntry('wait'),
      Opcode.assertion: const KeywordEntry('assert'),
      // Events (D-014)
      Opcode.whenFlag: const KeywordEntry('flag'),
      Opcode.whenKey: const KeywordEntry('key'),
      Opcode.whenClicked: const KeywordEntry('clicked'),
      // Sensing
      Opcode.keyDown: const KeywordEntry('keydown', abbreviation: 'kd'),
      Opcode.mouseX: const KeywordEntry('mousex'),
      Opcode.mouseY: const KeywordEntry('mousey'),
      Opcode.mouseDown: const KeywordEntry('mousedown'),
      Opcode.touchingEdge: const KeywordEntry('touchingedge'),
      Opcode.touchingColour: const KeywordEntry('touchingcolour',
          aliases: ['touchingcolor']),
      // Sprites and stage
      Opcode.nextCostume: const KeywordEntry('nextcostume', abbreviation: 'nc'),
      Opcode.setCostume: const KeywordEntry('costume'),
      Opcode.costumeNumber: const KeywordEntry('costumenumber'),
      Opcode.setBackdrop: const KeywordEntry('backdrop'),
      Opcode.setEffect: const KeywordEntry('effect'),
      Opcode.clearEffects: const KeywordEntry('cleareffects'),
      Opcode.say: const KeywordEntry('say'),
      Opcode.playSound: const KeywordEntry('playsound'),
      Opcode.playDrum: const KeywordEntry('drum'),
      Opcode.playNote: const KeywordEntry('note'),
    },
    syntax: {
      SyntaxWord.when_: const KeywordEntry('when'),
      SyntaxWord.repeat: const KeywordEntry('repeat'),
      SyntaxWord.while_: const KeywordEntry('while'),
      SyntaxWord.for_: const KeywordEntry('for'),
      SyntaxWord.to: const KeywordEntry('to'),
      SyntaxWord.step: const KeywordEntry('step'),
      SyntaxWord.if_: const KeywordEntry('if'),
      SyntaxWord.else_: const KeywordEntry('else'),
      SyntaxWord.learn: const KeywordEntry('learn'),
      SyntaxWord.return_: const KeywordEntry('return'),
      SyntaxWord.break_: const KeywordEntry('break'),
      SyntaxWord.exit: const KeywordEntry('exit'),
      SyntaxWord.and: const KeywordEntry('and'),
      SyntaxWord.or: const KeywordEntry('or'),
      SyntaxWord.not: const KeywordEntry('not'),
      SyntaxWord.true_: const KeywordEntry('true'),
      SyntaxWord.false_: const KeywordEntry('false'),
    },
  );

  static final Map<String, KeywordTable> byLocale = {'fr': fr, 'en': en};

  static KeywordTable of(String locale) =>
      byLocale[locale] ??
      (throw ArgumentError('no keyword table for locale "$locale"'));
}
