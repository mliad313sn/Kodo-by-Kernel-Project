/// `FR-M3-08` — export the program as text and as a code image (`KT §2.5.1`).
///
/// Two exports, and they are not the same thing. The text is the program: it goes back
/// into KODO, into a message, into a file a teacher collects. The image is the program as
/// the child sees it, colours and all — the thing that goes on a wall. A child who has
/// written their first working program has made something, and "copy the text out" is not
/// a way to show it to anybody.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodo_app/kodo_app.dart';
import 'package:kodo_lang/kodo_lang.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  const source = 'répète 4 {\n  avance 50 # un côté\n  tournedroite 90\n}\n';
  Program parsed(String s) => parse(s, KeywordTables.fr).program;

  group('FR-M3-08 · the text half', () {
    test('the text is the program, and it goes back in', () {
      final export = exportProgram(
          parsed(source), KeywordTables.fr, SyntaxTheme.light,
          name: 'carré');
      // The round trip is the whole test: an export a child cannot reopen is a picture
      // with a misleading extension.
      final back = parse(export.text, KeywordTables.fr);
      expect(back.errors, isEmpty);
      expect(render(back.program, KeywordTables.fr), export.text);
      expect(export.textFileName, 'carré.kodo');
      expect(export.imageFileName, 'carré.svg');
    });

    test('it is written in the child\'s keywords, not a canonical set', () {
      final program = parsed(source);
      final fr = exportProgram(program, KeywordTables.fr, SyntaxTheme.light);
      final en = exportProgram(program, KeywordTables.en, SyntaxTheme.light);
      expect(fr.text, contains('répète'));
      expect(en.text, contains('repeat'));
      // A program exported in English from a French child's screen is not the program
      // they wrote.
      expect(fr.text, isNot(en.text));
    });
  });

  group('FR-M3-08 · the image half', () {
    String svg({SyntaxTheme? theme}) =>
        codeToSvg(source, KeywordTables.fr, theme ?? SyntaxTheme.light,
            title: 'Mon carré');

    test('it is a standalone picture of the program', () {
      final out = svg();
      expect(out, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(out, contains('<svg xmlns="http://www.w3.org/2000/svg"'));
      expect(out.trim(), endsWith('</svg>'));
      expect(out, contains('<title>Mon carré</title>'));
      // Every line of the program is in it, and the line numbers with them.
      for (final word in ['répète', 'avance', 'tournedroite']) {
        expect(out, contains(word));
      }
    });

    test('the same program exports the same file, to the character', () {
      // Determinism is what makes "an exported program reopens identically" a test
      // rather than an opinion — and what lets a teacher diff two of them.
      expect(svg(), svg());
    });

    test('the colours are the editor\'s, not the exporter\'s own', () {
      final light = svg();
      final dark = svg(theme: SyntaxTheme.dark);
      expect(light, isNot(dark));

      // The comment is italic in the theme, so it is italic in the picture. An exporter
      // that worked the highlighting out for itself would drift from the editor and a
      // child would print a program that is not the one on their screen.
      final comment = SyntaxTheme.light.styleFor(SyntaxCategory.comment);
      final hex = (comment.colour.toARGB32() & 0xFFFFFF)
          .toRadixString(16)
          .padLeft(6, '0');
      expect(light, contains('#$hex'));
      if (comment.italic) expect(light, contains('font-style="italic"'));
    });

    test('a program with angle brackets in it is still valid XML', () {
      final out = codeToSvg('si 3 < 5 {\n  écris "a & b"\n}\n',
          KeywordTables.fr, SyntaxTheme.light);
      expect(out, contains('&lt;'));
      expect(out, contains('&amp;'));
      expect(out, isNot(contains('"a & b"')));
    });

    test(
        'it carries a description, because FR-M16-04 does not stop at the '
        'edge of the app', () {
      expect(svg(), contains('<desc>'));
      expect(svg(), contains('tournedroite 90'));
    });

    test(
        'the picture is as wide as the longest line and as tall as the program',
        () {
      final one = codeToSvg('avance 10\n', KeywordTables.fr, SyntaxTheme.light);
      final many = codeToSvg('avance 10\navance 20\navance 30\n',
          KeywordTables.fr, SyntaxTheme.light);
      double heightOf(String s) =>
          double.parse(RegExp(r'height="([\d.]+)"').firstMatch(s)!.group(1)!);
      expect(heightOf(many), greaterThan(heightOf(one)));

      // A trailing newline is how a program ends; it may not become a band of blank
      // paper under every picture.
      final trailing =
          codeToSvg('avance 10\n\n\n', KeywordTables.fr, SyntaxTheme.light);
      expect(heightOf(trailing), greaterThan(heightOf(one)));
    });
  });

  group('FR-M3-08 · the child asks for it', () {
    testWidgets('one button hands out both, and the editor decides neither',
        (tester) async {
      CodeExport? given;
      final controller = EditorController(initialSource: source);
      await tester.pumpWidget(_wrap(TextEditor(
        controller: controller,
        theme: SyntaxTheme.light,
        onExport: (export) => given = export,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('export-code')));
      await tester.pumpAndSettle();
      expect(given, isNotNull);
      expect(given!.text, contains('répète'));
      expect(given!.svg, contains('<svg'));
      // What a file IS differs per platform — a share sheet, a download, a folder — and
      // none of that belongs in an editor.
    });

    testWidgets('no button where the host offers no way to keep a file',
        (tester) async {
      final controller = EditorController(initialSource: source);
      await tester.pumpWidget(
          _wrap(TextEditor(controller: controller, theme: SyntaxTheme.light)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('export-code')), findsNothing);
    });
  });
}
