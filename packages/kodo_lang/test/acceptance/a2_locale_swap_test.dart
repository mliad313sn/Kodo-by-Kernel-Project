/// Acceptance test 2 — locale swap.
///
/// *"A running program, switched from `fr` to `en` keywords, continues and produces an
/// identical drawing."*
///
/// This is World 11's lesson made mechanical (§4.4): the child discovers that `avance` and
/// `forward` are the same idea with a different costume. If the swap were lossy, the
/// discovery would be a bug report.
library;

import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

import '../support/generator.dart';

void main() {
  test(
      'FR-M1-02 · the same tree renders to both languages and parses back identically',
      () {
    final generator = ProgramGenerator(4242);
    for (var i = 0; i < 300; i++) {
      final program = generator.generate();

      final french = render(program, KeywordTables.fr);
      final english = render(program, KeywordTables.en);

      final fromFrench = parse(french, KeywordTables.fr);
      final fromEnglish = parse(english, KeywordTables.en);
      expect(fromFrench.errors, isEmpty);
      expect(fromEnglish.errors, isEmpty);

      // Same program, two costumes: rendering either parse through the *other* table must
      // produce the other language's text exactly.
      expect(render(fromFrench.program, KeywordTables.en), english);
      expect(render(fromEnglish.program, KeywordTables.fr), french);
    }
  });

  test('a program swapped mid-run continues and draws the same figure', () {
    const french = 'répète 6 {\n  avance 80\n  tournedroite 60\n}';
    final program = parse(french, KeywordTables.fr).program;

    // Full run in French.
    final reference = HeadlessCanvas();
    runProgram(program, reference);

    // Half the run, then the keyword language changes underneath it.
    final swapped = HeadlessCanvas();
    final interpreter = Interpreter(program, swapped);
    for (var i = 0; i < 7; i++) {
      interpreter.step();
    }

    final english = render(program, KeywordTables.en);
    expect(english.contains('forward'), isTrue);
    expect(english.contains('avance'), isFalse);

    // The swap is a *display* change: the running tree is untouched, so the run continues.
    interpreter.run();
    expect(interpreter.status, RunStatus.finished);
    expect(swapped.pathSignature(), reference.pathSignature());
  });

  test('abbreviations swap language rather than expanding', () {
    final parsed = parse('av 100\ntg 90', KeywordTables.fr);
    expect(render(parsed.program, KeywordTables.en), 'fd 100\ntl 90');
  });

  test('FR-M1-02 · keyword tables are data: a table round-trips through JSON',
      () {
    final json = KeywordTables.fr.toJson();
    final reloaded = KeywordTable.fromJson(json);
    expect(reloaded.locale, 'fr');
    expect(reloaded.write(Opcode.moveForward), 'avance');
    expect(reloaded.write(Opcode.moveForward, KeywordForm.abbreviation), 'av');

    final program = parse('avance 100', reloaded).program;
    expect(render(program, KeywordTables.en), 'forward 100');
  });

  test('every shipped table abbreviates the same opcodes', () {
    // Not cosmetic: an abbreviation that exists in one language and not another is lost on
    // a swap, and a child sees their own typing rewritten. See KeywordTable.abbreviatedOpcodes.
    final tables = KeywordTables.byLocale.values.toList();
    final reference = tables.first.abbreviatedOpcodes;
    for (final table in tables.skip(1)) {
      expect(table.abbreviatedOpcodes, reference,
          reason:
              'table "\${table.locale}" abbreviates a different set of opcodes than '
              '"\${tables.first.locale}", so a swap would drop a short form');
    }
  });

  test(
      'FR-M1-02, NFR-I18N-01 · every shipped table covers every opcode and every syntax word',
      () {
    // The localisation coverage gate (NFR-I18N-01). A missing keyword must fail the build,
    // not surprise a child mid-lesson.
    for (final table in KeywordTables.byLocale.values) {
      final missingOpcodes =
          Opcode.values.toSet().difference(table.coveredOpcodes);
      expect(missingOpcodes, isEmpty,
          reason: 'table "${table.locale}" has no word for $missingOpcodes');

      final missingSyntax =
          SyntaxWord.values.toSet().difference(table.coveredSyntax);
      expect(missingSyntax, isEmpty,
          reason: 'table "${table.locale}" has no word for $missingSyntax');
    }
  });
}
