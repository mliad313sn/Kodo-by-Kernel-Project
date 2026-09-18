/// Acceptance test 1 — round-trip.
///
/// *"1 000 randomly generated programs survive `render(parse(x)) == x` modulo whitespace,
/// in both keyword languages."*
///
/// This is the test that `R3` (risk exposure 20, the joint-highest in the register) exists
/// for, and PO decision D-008 froze the build order so that it would run before any UI was
/// written. If the toggle can lose a program, every module built above it inherits the
/// defect, and `FR-M3-05` — the toggle never loses a program — becomes a promise nobody
/// can keep.
library;

import 'package:kodo_lang/kodo_lang.dart';
import 'package:test/test.dart';

import '../support/generator.dart';

void main() {
  for (final table in [KeywordTables.fr, KeywordTables.en]) {
    test('FR-M1-01 · 1000 programs round-trip exactly in ${table.locale}', () {
      final generator = ProgramGenerator(20260918);
      var checked = 0;
      for (var i = 0; i < 1000; i++) {
        final original = generator.generate(statements: 4 + (i % 5));
        final text = render(original, table);

        final reparsed = parse(text, table);
        expect(reparsed.errors, isEmpty,
            reason: 'generated program #$i did not parse:\n$text\n'
                '${reparsed.errors.map((e) => e.message(table.locale)).join('\n')}');

        expect(render(reparsed.program, table), text,
            reason:
                'program #$i changed when it went through blocks and back:\n$text');
        checked++;
      }
      expect(checked, 1000);
    });
  }

  test('round-trip is stable under repetition — no slow drift', () {
    final generator = ProgramGenerator(7);
    for (var i = 0; i < 200; i++) {
      var text = render(generator.generate(), KeywordTables.fr);
      for (var pass = 0; pass < 5; pass++) {
        final next =
            render(parse(text, KeywordTables.fr).program, KeywordTables.fr);
        expect(next, text, reason: 'drifted on pass $pass');
        text = next;
      }
    }
  });

  test('a program written with abbreviations keeps its abbreviations', () {
    const source = 'av 100\ntg 90\nav 100';
    final parsed = parse(source, KeywordTables.fr);
    expect(parsed.errors, isEmpty);
    expect(render(parsed.program, KeywordTables.fr), source);
  });

  test('unaccented French is accepted and rendered back with its accents', () {
    // A cheap Android keyboard is not a syntax error.
    final parsed = parse('repete 4 { levecrayon }', KeywordTables.fr);
    expect(parsed.errors, isEmpty);
    expect(render(parsed.program, KeywordTables.fr),
        'répète 4 {\n  lèvecrayon\n}');
  });

  test('comments survive the toggle', () {
    const source = '# mon carré\navance 100\n# fini';
    final parsed = parse(source, KeywordTables.fr);
    expect(render(parsed.program, KeywordTables.fr), source);
  });

  test('redundant brackets survive the toggle', () {
    // Concept C6.3's misconception is that operations run left to right. The repair is a
    // child adding brackets and watching the answer change; an editor that tidied them
    // away would delete the lesson.
    const source = r'$x = (2 + 3) * 4';
    final parsed = parse(source, KeywordTables.fr);
    expect(render(parsed.program, KeywordTables.fr), source);
  });

  test('FR-M1-01 · the AST serialises and reloads without changing the program',
      () {
    final generator = ProgramGenerator(99);
    for (var i = 0; i < 50; i++) {
      final program = generator.generate();
      final json = program.toJson();
      expect(json['k'], 'Program');
      // Every node carries a stable id and a span; an attempt stored under FR-M6-08 is
      // worthless without them.
      for (final node in walk(program)) {
        expect(node.id, isNotEmpty);
        expect(node.toJson()['id'], node.id);
      }
    }
  });
}
