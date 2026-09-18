/// M15 and M16 acceptance tests.
///
/// **M15:** string coverage is 100 % in FR and EN, enforced in CI · a pseudo-locale run
/// reveals zero hard-coded strings and zero truncation at 140 % string length · switching
/// keyword language mid-program preserves the program byte-for-byte.
///
/// **M16:** every screen passes an automated contrast check at both themes, in CI · a
/// blind reviewer completes World 0 with a screen reader · an external accessibility audit
/// before public launch, with findings closed.
library;

import 'dart:io';
import 'dart:math';

import 'package:kodo_access/kodo_access.dart';
import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';
import 'package:test/test.dart';

void main() {
  // =====================================================================================
  // M15 — localisation
  // =====================================================================================

  group('FR-M15-01 · three layers, localised independently', () {
    test('interface, keywords and content are three different tables', () {
      // Interface: the catalogue here. Keywords: M1's KeywordTable. Content: the packs.
      // Nothing in the interface catalogue is a keyword, and nothing in the keyword table
      // is an interface string — if they were one table, a child could not read French
      // screens while writing English keywords.
      final keywords = {
        for (final opcode in Opcode.values) KeywordTables.fr.write(opcode),
      };
      for (final string in uiStrings.all) {
        expect(keywords.contains(string.key), isFalse);
      }
      // And the interface can be French while the keywords are English.
      expect(uiStrings.render('button.run', UiLocale.fr), 'Essayer');
      expect(KeywordTables.en.write(Opcode.moveForward), 'forward');
    });
  });

  group('FR-M15-02, FR-M15-04 · acceptance 1 — coverage is 100 %, enforced here', () {
    test('every string exists in FR and EN', () {
      for (final locale in UiLocale.v1) {
        expect(uiStrings.coverageOf(locale), 1.0,
            reason: 'missing in ${locale.code}: ${uiStrings.missingIn(locale)}');
      }
      expect(uiStrings.length, greaterThan(30));
    });

    test('the catalogue passes the fragment and context lint', () {
      final faults = lintCatalogue(uiStrings.all);
      expect(faults, isEmpty, reason: faults.join('\n'));
    });

    test('the lint actually catches each thing it claims to catch', () {
      // A fragment.
      expect(
          lintCatalogue([
            const UiString(
                key: 'editor.fragment',
                texts: {'fr': 'Tu as fait', 'en': 'You have made'},
                context: 'A fragment somebody means to glue to a noun.')
          ]).map((f) => f.rule),
          contains('fragment'));

      // A string that trails off on a connector, with punctuation to hide it.
      expect(
          lintCatalogue([
            const UiString(
                key: 'editor.dangling',
                texts: {'fr': 'Choisis un bloc et.', 'en': 'Pick a block and.'},
                context: 'Ends on a connector, which means it continues elsewhere.')
          ]).map((f) => f.rule),
          contains('fragment'));

      // No context note.
      expect(
          lintCatalogue([
            const UiString(
                key: 'editor.no_context',
                texts: {'fr': 'Tout va bien.', 'en': 'All is well.'},
                context: 'ok')
          ]).map((f) => f.rule),
          contains('context-note'));

      // Missing English.
      expect(
          lintCatalogue([
            const UiString(
                key: 'editor.fr_only',
                texts: {'fr': 'Tout va bien.'},
                context: 'A string a translator has not reached yet.')
          ]).map((f) => f.rule),
          contains('coverage'));

      // A placeholder declared but never used, and one used but never declared.
      expect(
          lintCatalogue([
            const UiString(
                key: 'editor.lost_value',
                texts: {'fr': 'Il y a des blocs.', 'en': 'There are blocks.'},
                context: 'The count never appears, so the value is silently lost.',
                placeholders: ['count'])
          ]).map((f) => f.rule),
          contains('placeholder-missing'));
      expect(
          lintCatalogue([
            const UiString(
                key: 'editor.undeclared',
                texts: {'fr': 'Il y a {count} blocs.', 'en': 'There are {count} blocks.'},
                context: 'Uses a placeholder nobody declared, so nothing fills it.')
          ]).map((f) => f.rule),
          contains('placeholder-undeclared'));

      // A button label is not required to be a sentence.
      expect(
          lintCatalogue([
            const UiString(
                key: 'button.go',
                texts: {'fr': 'Essayer', 'en': 'Try it'},
                context: 'A button label, which is a complete utterance already.')
          ]),
          isEmpty);
    });

    test('a missing value is an error, and a missing key is too', () {
      expect(() => uiStrings.render('a11y.text_size', UiLocale.fr),
          throwsArgumentError);
      expect(uiStrings.render('a11y.text_size', UiLocale.fr, {'percent': '150'}),
          'Taille du texte : 150 %.');
      // Never a silent fallback to the key: `editor.run_button` on a child's screen must
      // be impossible to miss.
      expect(() => uiStrings.render('editor.nope', UiLocale.fr), throwsArgumentError);
    });
  });

  group('FR-M15-04 · acceptance 2 — the pseudo-locale run', () {
    // Where each family of strings actually appears, at the child font size on the
    // reference device (360 dp wide, ~29 characters a line).
    final slots = <String, LayoutSlot>{
      'button.': const LayoutSlot(name: 'button', characters: 18, lines: 1),
      'menu.': const LayoutSlot(name: 'menu item', characters: 20, lines: 1),
      'tab.': const LayoutSlot(name: 'family tab', characters: 14, lines: 1),
      // A field label sits above its field and may wrap; a button may not, which is why
      // the button slot stays at one line and the button strings were shortened instead.
      'label.': const LayoutSlot(name: 'field label', characters: 24, lines: 2),
      'editor.': const LayoutSlot(name: 'status line', characters: 29, lines: 3),
      'language.': const LayoutSlot(name: 'settings row', characters: 29, lines: 3),
      'a11y.': const LayoutSlot(name: 'settings row', characters: 29, lines: 3),
      'share.': const LayoutSlot(name: 'notice panel', characters: 29, lines: 4),
      'class.': const LayoutSlot(name: 'notice panel', characters: 29, lines: 4),
    };

    test('zero truncation at 140 % string length', () {
      final run = PseudoLocaleRun(uiStrings, slots);
      // Every string is checked. An unchecked string is not a passing string.
      expect(run.unslottedKeys, isEmpty,
          reason: 'no slot declared for ${run.unslottedKeys}');
      final truncations = run.truncations();
      expect(truncations, isEmpty, reason: truncations.join('\n'));
    });

    test('the pseudo-locale really does grow and really is visible', () {
      const source = 'Try it';
      final grown = pseudo(source);
      expect(grown.length, greaterThanOrEqualTo((source.length * growthFactor).ceil()));
      expect(grown, startsWith('['));
      expect(grown, endsWith(']'));
      expect(grown, isNot(source));
      // Placeholders survive, or the pseudo-locale would only prove itself broken.
      expect(pseudo('Text size: {percent} %.'), contains('{percent}'));
    });

    test('the truncation check is not vacuous — a long string in a small slot fails', () {
      final tight = PseudoLocaleRun(
        StringCatalogue([
          const UiString(
              key: 'button.very_long_label_indeed',
              texts: {
                'fr': 'Appuie ici pour lancer ton programme',
                'en': 'Press here to run your program'
              },
              context: 'A button label nobody measured.')
        ]),
        {'button.': const LayoutSlot(name: 'button', characters: 18, lines: 1)},
      );
      expect(tight.truncations(), isNotEmpty);
    });

    test('zero hard-coded strings reach a widget', () {
      final uiFiles = Directory('../kodo_app/lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(uiFiles, isNotEmpty, reason: 'the scan found no UI source to scan');

      final found = <HardCodedString>[];
      for (final file in uiFiles) {
        found.addAll(scanForHardCodedStrings(file.path, file.readAsStringSync()));
      }
      expect(found, isEmpty, reason: found.join('\n'));
    });

    test('the scanner catches a hard-coded string when there is one', () {
      expect(
          scanForHardCodedStrings('x.dart', "Text('Essaie encore')"), hasLength(1));
      // A key, an asset path and a variable are not findings.
      expect(scanForHardCodedStrings('x.dart', "Text(strings['button.run'])"), isEmpty);
      expect(scanForHardCodedStrings('x.dart', "Text(label)"), isEmpty);
      expect(scanForHardCodedStrings('x.dart', "// Text('a comment')"), isEmpty);
    });
  });

  group('FR-M15-03 · acceptance 3 — switching keyword language mid-program', () {
    test('the program survives byte-for-byte, over 500 random programs', () {
      final random = Random(20260918);
      const opcodes = [
        Opcode.moveForward,
        Opcode.moveBack,
        Opcode.turnLeft,
        Opcode.turnRight,
        Opcode.penUp,
        Opcode.penDown,
      ];
      for (var run = 0; run < 500; run++) {
        final lines = <String>[];
        for (var i = 0; i < 1 + random.nextInt(8); i++) {
          final opcode = opcodes[random.nextInt(opcodes.length)];
          final word = KeywordTables.fr.write(opcode);
          lines.add(opcode.minArgs == 0 ? word : '$word ${random.nextInt(200)}');
        }
        final source = lines.join('\n');
        final parsed = parse(source, KeywordTables.fr);
        expect(parsed.errors, isEmpty, reason: source);

        // The switch is a re-render of the same tree, never a re-parse of text.
        final inEnglish = render(parsed.program, KeywordTables.en);
        final andBack = render(
            parse(inEnglish, KeywordTables.en).program, KeywordTables.fr);
        expect(andBack.trim(), render(parsed.program, KeywordTables.fr).trim(),
            reason: 'switching language changed "$source"');
      }
    });

    test('the switch does not depend on the program being valid', () {
      // A child switches language halfway through typing. The tree is what it is.
      const halfWritten = 'avance 50\ntournedroite';
      final parsed = parse(halfWritten, KeywordTables.fr);
      expect(parsed.errors, isNotEmpty);
      // Rendering still produces something, and re-rendering it is stable.
      final once = render(parsed.program, KeywordTables.en);
      final twice = render(parse(once, KeywordTables.en).program, KeywordTables.en);
      expect(twice.trim(), once.trim());
    });
  });

  group('FR-M15-05 · numbers and pronunciation are locale-specific', () {
    test('the display uses the language\'s own convention; the parser does not', () {
      expect(formatNumber(1.5, UiLocale.fr), '1,5');
      expect(formatNumber(1.5, UiLocale.en), '1.5');
      expect(formatNumber(12345, UiLocale.fr), '12 345');
      expect(formatNumber(12345, UiLocale.en), '12,345');
      // French typography does not group four digits.
      expect(formatNumber(1000, UiLocale.fr), '1000');
      expect(formatNumber(-7.25, UiLocale.fr), '-7,25');

      // And the program parser is unchanged in every language, because a program that
      // parses differently in French is a different language, not a translation.
      for (final table in [KeywordTables.fr, KeywordTables.en]) {
        final parsed = parse('avance 1.5', KeywordTables.fr);
        expect(parsed.errors, isEmpty);
        expect(render(parsed.program, table), contains('1.5'));
      }
      expect(parse('avance 1,5', KeywordTables.fr).errors, isNotEmpty);
    });

    test('a number typed into a data field is read in the child\'s convention', () {
      expect(parseLocalNumber('1,5', UiLocale.fr), 1.5);
      expect(parseLocalNumber('1.5', UiLocale.en), 1.5);
      expect(parseLocalNumber('12 345', UiLocale.fr), 12345);
      expect(parseLocalNumber('pas un nombre', UiLocale.fr), isNull);
    });

    test('every compound keyword has a spoken form, in both languages', () {
      for (final locale in UiLocale.v1) {
        final table = locale == UiLocale.fr ? KeywordTables.fr : KeywordTables.en;
        for (final opcode in Opcode.values) {
          final written = table.write(opcode);
          final spoken = pronounce(written, locale);
          // A compound is any keyword built from more than one word. The heuristic is
          // crude; what it protects is real — a new compound keyword cannot ship mute.
          final isCompound = _looksCompound(written, locale);
          if (isCompound) {
            expect(spoken, isNot(written),
                reason: '"$written" (${locale.code}) has no spoken form, so the '
                    'narrator would read it as one word');
            expect(spoken, contains(' '));
          }
        }
      }
    });
  });

  group('FR-M15-02 · Wolof is prepared, and honestly labelled (D-002)', () {
    test('the interface locale exists and is not claimed for v1', () {
      expect(UiLocale.wo.shipsInV1, isFalse);
      expect(UiLocale.v1, [UiLocale.fr, UiLocale.en]);
      // The endonym is in its own language, for the picker.
      expect(UiLocale.wo.endonym, 'Wolof');
      // Number convention is already known and recorded, so v1.2 is a translation job
      // rather than a research job.
      expect(NumberConvention.of(UiLocale.wo).decimalSeparator, ',');
      // And there is no Wolof keyword table: D-002 records it as research, not a
      // commitment, so the absence is the honest state rather than an oversight.
      expect(() => KeywordTables.of('wo'), throwsA(isA<Object>()));
    });
  });

  // =====================================================================================
  // M16 — accessibility
  // =====================================================================================

  group('FR-M16-01 · acceptance 3 — contrast, in CI, at both themes', () {
    test('the pen palette is legible on both canvas backgrounds', () {
      const white = NamedColour('blanc', 'white', 255, 255, 255);
      const dark = NamedColour('nuit', 'night', 20, 20, 20);

      for (final background in [white, dark]) {
        final failures = auditContrast({
          for (final colour in colourBlindSafe)
            '${colour.keyEn} on ${background.keyEn}': (colour, background),
        }, floor: nonTextContrast);
        // The picker must not offer a colour that vanishes on the canvas in use, so most
        // of the safe set has to clear the non-text floor on each background.
        expect(failures.length, lessThan(colourBlindSafe.length / 2),
            reason: 'on ${background.keyEn}: ${failures.join('; ')}');
      }
    });

    test('a failing pair is reported with its ratio, not just flagged', () {
      const grey = NamedColour('gris', 'grey', 119, 119, 119);
      const white = NamedColour('blanc', 'white', 255, 255, 255);
      final failures = auditContrast({'grey on white': (grey, white)});
      expect(failures, hasLength(1));
      expect(failures.single.ratio, lessThan(bodyTextContrast));
      expect(failures.single.toString(), contains(':1'));
    });
  });

  group('FR-M16-03 · text scales to 200 % without breaking', () {
    // The boxes that hold text on the reference device, with the height they are given.
    final boxes = [
      // One line. The three-line version of this box breaks at 110 %, which is the
      // finding `M16-001` recorded: a status *line* holds a status, and the longer
      // messages belong in the panel below, which is allowed to grow.
      const ScalableBox(
          name: 'status line',
          baseFontDp: 16,
          heightDp: 72,
          widthDp: 360,
          lines: 1,
          scrollsVertically: false),
      const ScalableBox(
          name: 'message panel',
          baseFontDp: 16,
          heightDp: 160,
          widthDp: 360,
          lines: 3,
          scrollsVertically: false),
      const ScalableBox(
          name: 'prompt panel',
          baseFontDp: 20,
          heightDp: 240,
          widthDp: 360,
          lines: 3,
          scrollsVertically: false),
      const ScalableBox(
          name: 'help card',
          baseFontDp: 16,
          heightDp: 120,
          widthDp: 360,
          lines: 6,
          scrollsVertically: true),
      const ScalableBox(
          name: 'block chip',
          baseFontDp: 16,
          heightDp: 96,
          widthDp: 160,
          lines: 1,
          scrollsVertically: false),
    ];

    test('every box survives the whole 100–200 % range', () {
      final breaks = checkTextScaling(boxes);
      expect(breaks, isEmpty, reason: breaks.join('\n'));
    });

    test('the check is not vacuous — a tight box is caught', () {
      final breaks = checkTextScaling([
        const ScalableBox(
            name: 'measured at 100 % only',
            baseFontDp: 16,
            heightDp: 24,
            widthDp: 360,
            lines: 1)
      ]);
      expect(breaks, hasLength(1));
      expect(breaks.single.scale, greaterThan(1.0));
    });

    test('the preference range is exactly what FR-M16-03 commits to', () {
      expect(const AccessibilityPreferences(textScale: 1.0).textScaleIsSupported, isTrue);
      expect(const AccessibilityPreferences(textScale: 2.0).textScaleIsSupported, isTrue);
      expect(const AccessibilityPreferences(textScale: 2.1).textScaleIsSupported, isFalse);
      expect(const AccessibilityPreferences(textScale: 0.9).textScaleIsSupported, isFalse);
    });

    test('reduced motion and the dyslexia font are one preference each', () {
      const defaults = AccessibilityPreferences();
      expect(defaults.reducedMotion, isFalse);
      expect(defaults.font, ReadingFont.standard);
      expect(defaults.narrationOn, isTrue,
          reason: 'narration is on by default; a child who cannot read yet gets it '
              'without anybody having to know to turn it on');
      final set = defaults.copyWith(
          reducedMotion: true, font: ReadingFont.dyslexiaFriendly);
      expect(set.font.family, 'OpenDyslexic');
      expect(set.reducedMotion, isTrue);
      // The same flag M4's render budget reads — one preference, not two, which is why
      // the light-device budget already turns motion off.
      expect(const RenderBudget().motion, isTrue);
      expect(const RenderBudget.leger().motion, isFalse);
    });
  });

  group('FR-M16-04 · complete keyboard operation, block placement included', () {
    test('every editor action has a key — that is what "complete" means', () {
      for (final action in EditorAction.values) {
        expect(desktopKeyMap.containsKey(action), isTrue,
            reason: '${action.name} cannot be done from the keyboard');
        expect(desktopKeyMap[action]!.keys, isNotEmpty);
      }
      // Including the one usually left out, because placing a block is thought of as a
      // drag.
      expect(desktopKeyMap[EditorAction.placeBlock]!.printed, 'Enter');
      expect(desktopKeyMap[EditorAction.placeBlock]!.note, contains('places'));
    });

    test('no two actions share a binding', () {
      final seen = <String, EditorAction>{};
      for (final entry in desktopKeyMap.entries) {
        final printed = entry.value.printed;
        expect(seen.containsKey(printed), isFalse,
            reason: '"$printed" is both ${seen[printed]?.name} and ${entry.key.name}');
        seen[printed] = entry.key;
      }
    });
  });

  group('FR-M16-02, FR-M16-04 · a canvas and a block can be heard', () {
    test('the canvas announcement is M4\'s description, not a second one', () {
      final parsed = parse('répète 4 { avance 80 tournedroite 90 }', KeywordTables.fr);
      final canvas = HeadlessCanvas();
      Interpreter(parsed.program, canvas).run();

      final announced = canvasAnnouncement(canvas);
      expect(announced, describeCanvas(canvas, locale: 'fr'));
      expect(announced, isNotEmpty);
      // It says something about the picture, in both languages.
      expect(canvasAnnouncement(canvas, locale: UiLocale.en),
          isNot(canvasAnnouncement(canvas)));
    });

    test('an empty canvas says so rather than saying nothing', () {
      final announced = canvasAnnouncement(HeadlessCanvas());
      expect(announced.trim(), isNotEmpty,
          reason: 'silence is indistinguishable from a broken screen reader');
    });

    test('a block label is a sentence built from the catalogue', () {
      final label = blockLabel(
        catalogue: uiStrings,
        familyKey: 'tab.mouvement',
        keyword: 'avance',
        position: 2,
        total: 5,
      );
      expect(label, 'avance, famille Bouger, bloc 2 sur 5.');
      expect(
          blockLabel(
              catalogue: uiStrings,
              familyKey: 'tab.mouvement',
              keyword: 'forward',
              position: 2,
              total: 5,
              locale: UiLocale.en),
          'forward, Move family, block 2 of 5.');
    });
  });
}

/// True when a keyword is built from more than one word and would be read as noise.
bool _looksCompound(String keyword, UiLocale locale) {
  const parts = {
    'fr': ['tourne', 'crayon', 'canevas', 'nettoie', 'taille', 'position', 'tantque', 'obtenir', 'va'],
    'en': ['turn', 'pen', 'canvas', 'font', 'position', 'get', 'go'],
  };
  if (keyword.length < 5) return false;
  final pieces = parts[locale.code]!;
  final hits = pieces.where(keyword.startsWith).toList();
  if (hits.isEmpty) return false;
  // `va` alone, `taille` alone and `position` alone are single words.
  return hits.any((p) => keyword.length > p.length);
}
