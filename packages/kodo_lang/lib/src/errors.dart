/// The closed error catalogue (FR-M1-10).
///
/// Every failure a KodoScript program can produce is one of these codes. Each carries the
/// offending node, a French and an English message written as a full sentence at CE2/CM1
/// level, and a machine-readable [SuggestedRepair] the text editor can offer as a one-tap
/// fix (`FR-M3-03`).
///
/// Three rules hold this together, and all three are enforced by tests rather than by
/// good intentions:
///
/// 1. **The catalogue is closed.** There is no "other" code and no free-text error. A new
///    failure mode means a new entry here, reviewed like content, because it is content.
/// 2. **No Dart exception crosses the module boundary.** M1 returns errors; it does not
///    throw them at the app.
/// 3. **No message names a thing a child has not been taught.** Not "token", not "AST",
///    not "null". The reviewer test for this is reading it aloud to a nine-year-old.
library;

import 'keywords.dart';
import 'opcodes.dart';
import 'span.dart';

/// Every way a KodoScript program can fail.
enum ErrorCode {
  // --- Reading the program -------------------------------------------------------------
  unknownCommand('E_UNKNOWN_COMMAND'),
  unexpectedToken('E_UNEXPECTED_TOKEN'),
  unclosedBlock('E_UNCLOSED_BLOCK'),
  unclosedString('E_UNCLOSED_STRING'),
  badNumber('E_BAD_NUMBER'),
  missingArg('E_MISSING_ARG'),
  argCount('E_ARG_COUNT'),
  expectedVariable('E_EXPECTED_VARIABLE'),
  expectedName('E_EXPECTED_NAME'),
  duplicateProc('E_DUPLICATE_PROC'),

  // --- Running the program -------------------------------------------------------------
  type('E_TYPE'),
  undefinedVar('E_UNDEFINED_VAR'),
  undefinedProc('E_UNDEFINED_PROC'),
  divZero('E_DIV_ZERO'),
  notAValue('E_NOT_A_VALUE'),
  badIndex('E_INDEX'),
  negativeCount('E_NEGATIVE_COUNT'),
  breakOutsideLoop('E_BREAK_OUTSIDE_LOOP'),
  returnOutsideProc('E_RETURN_OUTSIDE_PROC'),

  // --- Guards (FR-M1-12) ---------------------------------------------------------------
  depth('E_DEPTH'),
  timeout('E_TIMEOUT'),
  segmentLimit('E_SEGMENT_LIMIT');

  const ErrorCode(this.id);

  /// Stable identifier. Persisted in attempts and item telemetry, so it never changes.
  final String id;

  static final Map<String, ErrorCode> _byId = {
    for (final c in ErrorCode.values) c.id: c
  };

  static ErrorCode? byId(String id) => _byId[id];
}

/// What kind of fix the editor may offer, and with what.
///
/// Machine-readable so M3 can present a one-tap repair and M6 can tell a *typo* apart from
/// a *misunderstanding* when it feeds the misconception model — `didYouMean` is a spelling
/// slip, `defineVariable` is concept C6.1 not yet landing.
enum RepairKind {
  /// A near-miss spelling. `word` holds the suggestion.
  didYouMean,

  /// A block was opened and not closed. `insert` holds the text.
  closeBlock,

  /// A string was opened and not closed.
  closeString,

  /// The command needs more numbers after it. `count` holds how many are missing.
  addArgument,

  /// The command was given more than it can use.
  removeArgument,

  /// The variable was used before it was given a value.
  defineVariable,

  /// A `$` is missing before a name.
  addVariableSigil,

  /// Nothing safe to propose. The message has to carry the whole weight.
  none,
}

class SuggestedRepair {
  const SuggestedRepair(this.kind, {this.word, this.insert, this.count});
  const SuggestedRepair.none() : this(RepairKind.none);

  final RepairKind kind;
  final String? word;
  final String? insert;
  final int? count;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        if (word != null) 'word': word,
        if (insert != null) 'insert': insert,
        if (count != null) 'count': count,
      };
}

/// One failure, ready to be shown to a child or stored in an attempt.
class KodoError {
  KodoError({
    required this.code,
    required this.span,
    this.nodeId,
    this.args = const {},
    this.repair = const SuggestedRepair.none(),
  });

  final ErrorCode code;
  final SourceSpan span;

  /// The offending node, when one exists. Parse errors happen before there is a node.
  final String? nodeId;

  /// Values substituted into the message.
  ///
  /// A value may be a plain string, or a *reference* the catalogue resolves against the
  /// child's language:
  ///
  /// * `opcode:MOVE_FORWARD` → `avance` / `forward`
  /// * `syntax:if_` → `si` / `if`
  /// * `type.number` → `un nombre` / `a number`
  ///
  /// The indirection is not decoration. Writing the opcode id straight into `args` would
  /// put `MOVE_FORWARD` on a nine-year-old's screen, which is the exact leak `FR-M1-10`
  /// exists to prevent — and it would be invisible in an English-language review.
  final Map<String, String> args;

  final SuggestedRepair repair;

  /// The child-facing sentence in [locale].
  ///
  /// Never call this to build a log line. Logs take [code]; children take this.
  String message(String locale, {KeywordTable? keywords}) =>
      ErrorCatalogue.render(code, locale, args, keywords: keywords);

  /// 1-based line, for the red marker in the text editor (`FR-M3-03`).
  int get line => span.line;

  Map<String, Object?> toJson() => {
        'code': code.id,
        'node': nodeId,
        'span': span.toJson(),
        'args': args,
        'repair': repair.toJson(),
      };

  @override
  String toString() =>
      '${code.id} at $span'; // diagnostics only, never shown to a child
}

/// The message catalogue, in both shipped languages.
abstract final class ErrorCatalogue {
  /// French is the reference language (§0 of the prompt library).
  static const Map<ErrorCode, String> fr = {
    ErrorCode.unknownCommand:
        "Je ne connais pas le mot « {word} ». Vérifie comment il s'écrit.",
    ErrorCode.unexpectedToken:
        "Je ne comprends pas « {word} » à cet endroit. Regarde la ligne {line}.",
    ErrorCode.unclosedBlock:
        "Tu as ouvert une accolade { et tu ne l'as pas refermée. Ajoute } à la fin.",
    ErrorCode.unclosedString:
        "Tu as ouvert un guillemet \" et tu ne l'as pas refermé sur la même ligne.",
    ErrorCode.badNumber: "« {word} » ne ressemble pas à un nombre.",
    ErrorCode.missingArg:
        "Il manque un nombre après « {word} ». Par exemple : {word} 100.",
    ErrorCode.argCount:
        "« {word} » attend {expected} nombre(s), et tu en as mis {actual}.",
    ErrorCode.expectedVariable:
        "Ici j'attends le nom d'une boîte, qui commence par \$. Par exemple \$côté.",
    ErrorCode.expectedName: "Ici j'attends un nom pour ton nouveau bloc.",
    ErrorCode.duplicateProc:
        "Tu as déjà appris un bloc qui s'appelle « {name} ». Donne-lui un autre nom.",
    ErrorCode.type:
        "« {word} » ne marche pas avec {got}. Ici il faut {expected}.",
    ErrorCode.undefinedVar:
        "La boîte \${name} est vide : tu ne lui as encore rien mis dedans.",
    ErrorCode.undefinedProc:
        "Tu n'as pas encore appris de bloc qui s'appelle « {name} ».",
    ErrorCode.divZero:
        'On ne peut pas partager en zéro part. Change le nombre après le signe ÷.',
    ErrorCode.notAValue:
        "« {word} » fait quelque chose, mais ne donne pas de résultat à ranger.",
    ErrorCode.badIndex:
        "Ta liste a {size} case(s), et tu demandes la case {asked}.",
    ErrorCode.negativeCount:
        "On ne peut pas répéter {count} fois. Mets un nombre plus grand que zéro.",
    ErrorCode.breakOutsideLoop:
        'Coupure sert à sortir d\'une boucle, et ici il n\'y a pas de boucle.',
    ErrorCode.returnOutsideProc:
        "Retourne sert à donner un résultat depuis un bloc que tu as appris.",
    ErrorCode.depth:
        "Ton bloc « {name} » s'appelle lui-même sans jamais s'arrêter.",
    ErrorCode.timeout:
        'Ton programme tourne encore… Il est très long. Tu peux l\'arrêter.',
    ErrorCode.segmentLimit:
        'Ton dessin a trop de traits pour tenir sur le canevas.',
  };

  static const Map<ErrorCode, String> en = {
    ErrorCode.unknownCommand:
        'I do not know the word "{word}". Check how it is spelled.',
    ErrorCode.unexpectedToken:
        'I do not understand "{word}" here. Look at line {line}.',
    ErrorCode.unclosedBlock:
        'You opened a curly bracket { and never closed it. Add } at the end.',
    ErrorCode.unclosedString:
        'You opened a quote " and never closed it on the same line.',
    ErrorCode.badNumber: '"{word}" does not look like a number.',
    ErrorCode.missingArg:
        'A number is missing after "{word}". For example: {word} 100.',
    ErrorCode.argCount:
        '"{word}" expects {expected} number(s), and you gave {actual}.',
    ErrorCode.expectedVariable:
        'Here I need the name of a box, starting with \$. For example \$side.',
    ErrorCode.expectedName: 'Here I need a name for your new block.',
    ErrorCode.duplicateProc:
        'You already learned a block called "{name}". Give this one another name.',
    ErrorCode.type:
        '"{word}" does not work with {got}. Here it needs {expected}.',
    ErrorCode.undefinedVar:
        'The box \${name} is empty: you have not put anything in it yet.',
    ErrorCode.undefinedProc:
        'You have not learned a block called "{name}" yet.',
    ErrorCode.divZero:
        'We cannot share into zero parts. Change the number after the ÷ sign.',
    ErrorCode.notAValue:
        '"{word}" does something, but it does not give a result to keep.',
    ErrorCode.badIndex:
        'Your list has {size} slot(s), and you asked for slot {asked}.',
    ErrorCode.negativeCount:
        'We cannot repeat {count} times. Use a number bigger than zero.',
    ErrorCode.breakOutsideLoop:
        'Break is for leaving a loop, and there is no loop here.',
    ErrorCode.returnOutsideProc:
        'Return is for giving a result back from a block you learned.',
    ErrorCode.depth: 'Your block "{name}" calls itself and never stops.',
    ErrorCode.timeout:
        'Your program is still running… It is very long. You can stop it.',
    ErrorCode.segmentLimit:
        'Your drawing has too many lines to fit on the canvas.',
  };

  static final Map<String, Map<ErrorCode, String>> byLocale = {
    'fr': fr,
    'en': en
  };

  /// Type names, so that `{got}` and `{expected}` are also localised. A French message
  /// containing the word "number" would be exactly the leak `FR-M1-10` forbids.
  static const Map<String, Map<String, String>> typeNames = {
    'fr': {
      'type.number': 'un nombre',
      'type.string': 'un texte',
      'type.boolean': 'vrai ou faux',
      'type.list': 'une liste',
      'type.nothing': 'rien',
    },
    'en': {
      'type.number': 'a number',
      'type.string': 'some text',
      'type.boolean': 'true or false',
      'type.list': 'a list',
      'type.nothing': 'nothing',
    },
  };

  static String render(
    ErrorCode code,
    String locale,
    Map<String, String> args, {
    KeywordTable? keywords,
  }) {
    final table = byLocale[locale];
    if (table == null) {
      throw ArgumentError('no error messages for locale "$locale"');
    }
    final words = keywords ?? KeywordTables.byLocale[locale];
    var text = table[code]!;
    for (final e in args.entries) {
      text = text.replaceAll('{${e.key}}', resolve(e.value, locale, words));
    }
    return text;
  }

  /// Turns an argument value into something a child can read.
  static String resolve(String value, String locale, KeywordTable? words) {
    if (value.startsWith('opcode:')) {
      final op = Opcode.byId(value.substring(7));
      if (op != null && words != null) return words.write(op);
      return value.substring(7).toLowerCase().replaceAll('_', ' ');
    }
    if (value.startsWith('syntax:')) {
      final name = value.substring(7);
      if (words != null) {
        for (final w in SyntaxWord.values) {
          if (w.name == name) return words.writeSyntax(w);
        }
      }
      return name.replaceAll('_', '');
    }
    return typeNames[locale]?[value] ?? value;
  }

  /// Argument values that would still read as machine text after resolution.
  ///
  /// Used by the CI content gate: an `args` value that is neither a reference, a number,
  /// nor a name the child typed is a technical string on its way to a child's screen.
  static bool looksTechnical(String value) =>
      RegExp(r'^[A-Z][A-Z0-9_]{2,}$').hasMatch(value);

  /// Codes with no message in [locale]. CI fails the build when this is not empty, so a
  /// missing translation is caught at build time and never on a child's screen.
  static List<ErrorCode> missingIn(String locale) {
    final table = byLocale[locale] ?? const {};
    return [
      for (final c in ErrorCode.values)
        if (!table.containsKey(c)) c
    ];
  }

  /// Placeholders a message uses, so a test can prove every one is always supplied.
  static Set<String> placeholdersOf(ErrorCode code, String locale) {
    final text = byLocale[locale]![code]!;
    return RegExp(r'\{(\w+)\}')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toSet();
  }
}
