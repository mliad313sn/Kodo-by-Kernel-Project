/// M4 acceptance tests, from the module prompt.
///
/// 1. `pathSignature()` is stable across platforms for the same seeded program.
/// 2. A 2 000-segment drawing renders inside budget; SVG export reopens identically.
/// 3. Jump commands never leave a mark with the pen down — all four.
/// 4. The inspector reflects a variable change within one frame of the assignment.
/// 5. The consent gate makes microphone and camera unreachable without a guardian action.
/// 6. A colour-blind-safe default palette, with Annex C's RGB values as named presets.
library;

import 'dart:typed_data';

import 'package:kodo_lang/kodo_lang.dart';
import 'package:kodo_stage/kodo_stage.dart';
import 'package:test/test.dart';

VectorCanvas _draw(String source, {int seed = 1, RenderBudget? budget}) {
  final parsed = parse(source, KeywordTables.fr);
  expect(parsed.errors, isEmpty,
      reason: parsed.errors.map((e) => e.message('fr')).join('\n'));
  final canvas = VectorCanvas(budget: budget ?? const RenderBudget());
  final run = runProgram(parsed.program, canvas,
      seed: seed, limits: const RunLimits(maxSegments: 100000));
  expect(run.error, isNull, reason: run.error?.message('fr'));
  return canvas;
}

void main() {
  stageCapabilityTests();
  group('FR-M4-01 · two surfaces, one turtle model', () {
    test('the canvas has a top-left origin and the stage a centre origin', () {
      final canvas = VectorCanvas();
      expect(canvas.positionX, 200);
      expect(canvas.positionY, 200);

      final stage = SpriteStage();
      expect(stage.stageX, 0);
      expect(stage.stageY, 0);
    });

    test('the same program draws the same shape on both surfaces', () {
      const source = 'répète 4 {\n  avance 60\n  tournedroite 90\n}';
      final program = parse(source, KeywordTables.fr).program;

      final canvas = VectorCanvas();
      runProgram(program, canvas);
      final stage = SpriteStage(width: 400, height: 400);
      runProgram(program, stage);

      // Identical geometry from one implementation — the M4 prompt's "do not let the stage
      // and the canvas diverge into two code paths for the same primitive".
      expect(stage.pathSignature(), canvas.pathSignature());
    });
  });

  group('FR-M6-01 · acceptance 1 — the grader can depend on the signature', () {
    test('a seeded program gives one signature across 200 runs', () {
      const source =
          'répète 10 {\n  avance hasard 20, 60\n  tournedroite 36\n}';
      final program = parse(source, KeywordTables.fr).program;
      final signatures = <String>{};
      for (var i = 0; i < 200; i++) {
        final canvas = VectorCanvas();
        runProgram(program, canvas, seed: 99);
        signatures.add(canvas.pathSignature());
      }
      expect(signatures, hasLength(1));
    });

    test('the raster hash is stable and the bitmap is deterministic', () {
      final a = _draw('répète 6 {\n  avance 50\n  tournedroite 60\n}');
      final b = _draw('répète 6 {\n  avance 50\n  tournedroite 60\n}');
      expect(a.rasterHash(), b.rasterHash());
      expect(a.toBitmap().inkCount, greaterThan(0));
    });

    test('a figure drawn in a different but valid order still matches', () {
      // FR-M6-02, and workbook finding G4-001: the grader penalising a valid alternative
      // is a Severity-2 defect, so the comparison has to be order-blind in pixels too.
      final clockwise = _draw('répète 4 {\n  avance 100\n  tournedroite 90\n}');
      final anticlockwise =
          _draw('direction 90\nrépète 4 {\n  avance 100\n  tournegauche 90\n}');

      final match = compareRaster(anticlockwise, clockwise);
      expect(match.matches, isTrue,
          reason:
              'attempt ${match.attemptCoverage}, target ${match.targetCoverage}');
    });

    test('the grader sees colour, because World 3 is about colour', () {
      /* Found while authoring World 3. `couleurcrayon` was a command a child could run
         and the grader could not see: a square in blue graded identically to the same
         square in red, in the world whose whole subject is the pen. A world that teaches
         colour cannot be marked by a monochrome comparison. */
      const square = 'répète 4 {\n  avance 80\n  tournedroite 90\n}';
      final red = _draw('couleurcrayon 200, 30, 40\n$square');
      final blue = _draw('couleurcrayon 20, 60, 200\n$square');

      final m = compareRaster(red, blue);
      expect(m.matches, isFalse, reason: 'red is not blue');
      // The shape still matches, and the message a child gets must be able to say so.
      expect(m.attemptCoverage, greaterThanOrEqualTo(0.98));
      expect(m.missingColours, isNotEmpty);
      expect(m.extraColours, isNotEmpty);

      // Same colour, same drawing: nothing else changed.
      expect(
          compareRaster(red, _draw('couleurcrayon 200, 30, 40\n$square'))
              .matches,
          isTrue);
    });

    test('a colour in the right place is not a colour in the wrong place', () {
      /* Two drawings with the SAME two colours and the same total ink, with the halves
         swapped. A comparison that only counted colours would pass this, which is why
         each colour is compared as its own plane. */
      const half = 'avance 80\ntournedroite 90\navance 80';
      final a = _draw('couleurcrayon 200, 30, 40\n$half\n'
          'couleurcrayon 20, 60, 200\ntournedroite 90\n$half');
      final b = _draw('couleurcrayon 20, 60, 200\n$half\n'
          'couleurcrayon 200, 30, 40\ntournedroite 90\n$half');

      final m = compareRaster(a, b);
      expect(m.extraColours, isEmpty, reason: 'both use the same two colours');
      expect(m.missingColours, isEmpty);
      expect(m.penMatches, isFalse, reason: 'each colour is in the other half');
      expect(m.matches, isFalse);
    });

    test('pen width is graded too: a thick line is not a thin one', () {
      final thin = _draw('largeurcrayon 1\navance 100');
      final thick = _draw('largeurcrayon 12\navance 100');
      expect(compareRaster(thick, thin).matches, isFalse);
    });

    test('the canvas is part of the drawing: its colour and its size', () {
      /* The other half of the same defect. `couleurcanevas` was recorded and never read,
         and a wrong `taillecanevas` was silently squashed into the target's dimensions
         before comparison — so the two commands World 3's fourth concept is about were
         both invisible to the grader. */
      final plain = _draw('avance 60');
      final onSand = _draw('couleurcanevas 253, 247, 236\navance 60');
      expect(compareRaster(onSand, plain).matches, isFalse);
      expect(compareRaster(onSand, plain).backgroundMatches, isFalse);
      expect(compareRaster(onSand, plain).attemptCoverage,
          greaterThanOrEqualTo(0.98),
          reason:
              'the line itself is in the right place — only the paper changed');

      final small = _draw('taillecanevas 200, 200\navance 60');
      expect(compareRaster(small, plain).sizeMatches, isFalse);
      expect(compareRaster(small, plain).matches, isFalse);
      expect(
          compareRaster(
                  _draw('couleurcanevas 253, 247, 236\navance 60'), onSand)
              .matches,
          isTrue);
    });

    test('the tolerance is real: two pixels off passes, twenty does not', () {
      final target = _draw('avance 100');
      final nudged = _draw('va 200, 202\nbaissecrayon\navance 100');
      final wrong = _draw('va 200, 240\nbaissecrayon\navance 100');

      expect(compareRaster(nudged, target, tolerancePx: 3).matches, isTrue);
      expect(compareRaster(wrong, target, tolerancePx: 2).matches, isFalse);
    });

    test(
        'a figure that covers the target but adds a stroke is told apart from one that '
        'stops short', () {
      final target = _draw('répète 4 {\n  avance 80\n  tournedroite 90\n}');
      // A fifth pass of a square retraces the first side and draws nothing new — which is
      // concept C2.1's misconception made visible — so the "too much" case needs a stroke
      // that genuinely leaves the figure.
      final tooMuch = _draw('répète 4 {\n  avance 80\n  tournedroite 90\n}\n'
          'tournedroite 45\navance 80');
      final tooLittle = _draw('répète 3 {\n  avance 80\n  tournedroite 90\n}');

      expect(compareRaster(tooMuch, target).drewTooMuch, isTrue);
      expect(compareRaster(tooLittle, target).drewTooLittle, isTrue);
    });
  });

  group('FR-M4-02 · acceptance 2 — 2 000 segments and a faithful export', () {
    test('a 2 000-segment rosette draws and exports', () {
      final canvas = _draw('''
répète 50 {
  répète 40 {
    avance 8
    tournedroite 9
  }
  tournedroite 7.2
}''');
      expect(canvas.segmentCount, 2000);

      final svg = canvas.toSvg();
      expect(svg, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(svg, contains('<svg xmlns="http://www.w3.org/2000/svg"'));
      expect('<line'.allMatches(svg).length, 2000);
      expect(svg.trimRight(), endsWith('</svg>'));
    });

    test('SVG export is byte-identical for the same program', () {
      final a = _draw('répète 8 {\n  avance 40\n  tournegauche 45\n}');
      final b = _draw('répète 8 {\n  avance 40\n  tournegauche 45\n}');
      expect(a.toSvg(), b.toSvg());
    });

    test('SVG carries a narratable description, not just pixels', () {
      final canvas = _draw('couleurcrayon 255, 0, 0\navance 50\nécris "carré"');
      final svg = canvas.toSvg(title: 'Mon carré');
      expect(svg, contains('<title>Mon carré</title>'));
      expect(svg, contains('<desc>'));
      expect(canvas.describe(), contains('trait'));
      expect(canvas.describe(locale: 'en'), contains('line'));
      expect(canvas.describe(locale: 'fr'), isNot(contains('segment')));
    });

    test('an empty canvas describes itself as empty rather than saying nothing',
        () {
      expect(VectorCanvas().describe(), 'Le canevas est vide.');
      expect(VectorCanvas().describe(locale: 'en'), 'The canvas is empty.');
    });

    test('PNG export produces a valid, deterministic file', () {
      final canvas = _draw('répète 4 {\n  avance 60\n  tournedroite 90\n}');
      final png = canvas.toPng(scale: 0.5);

      expect(
          png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      expect(String.fromCharCodes(png.sublist(12, 16)), 'IHDR');
      expect(String.fromCharCodes(png.sublist(png.length - 8, png.length - 4)),
          'IEND');
      expect(canvas.toPng(scale: 0.5), png);
    });
  });

  group('FR-M4-09 · mode léger is a budget, never a different answer', () {
    test('a light-mode canvas grades identically to a full one', () {
      const source = 'répète 30 {\n  avance 20\n  tournedroite 12\n}';
      final full = _draw(source);
      final light = _draw(source, budget: const RenderBudget.leger());

      // PO decision D-004 says in terms: it must not change a grading result.
      expect(light.pathSignature(), full.pathSignature());
      expect(light.rasterHash(), full.rasterHash());
      expect(light.segmentCount, full.segmentCount);
    });

    test('the budget hides the oldest strokes and says that it did', () {
      final canvas = _draw('répète 5000 {\n  avance 2\n  tournedroite 1\n}',
          budget: const RenderBudget.leger());
      expect(canvas.segmentCount, 5000);
      expect(canvas.visibleSegments.length, 4000);
      expect(canvas.isTruncatedByBudget, isTrue);
      expect(VectorCanvas().isTruncatedByBudget, isFalse);
    });

    test('a device under 3 GB gets the light budget', () {
      expect(RenderBudget.forDevice(ramMegabytes: 2048).ghostPreview, isFalse);
      expect(RenderBudget.forDevice(ramMegabytes: 6144).ghostPreview, isTrue);
    });
  });

  group('FR-M4-01 · acceptance 3 — jumps never draw', () {
    test('va, vax, vay and centre leave no mark with the pen down', () {
      // Concept C3.1's misconception is exactly "va draws a line". A regression here does
      // not break a feature, it teaches a child something false.
      final canvas = _draw('baissecrayon\nva 10, 10\nvax 300\nvay 250\ncentre');
      expect(canvas.segmentCount, 0);
      expect(canvas.toBitmap().inkCount, 0);
    });

    test('each jump command is covered on its own', () {
      for (final jump in ['va 20, 20', 'vax 100', 'vay 100', 'centre']) {
        final canvas = _draw('baissecrayon\n$jump');
        expect(canvas.segmentCount, 0, reason: '"$jump" drew something');
      }
    });

    test('a jump followed by a move draws only the move', () {
      final canvas = _draw('baissecrayon\nva 100, 100\navance 50');
      expect(canvas.segmentCount, 1);
    });
  });

  group('FR-M4-06, FR-M4-07 · acceptance 4 — the inspector', () {
    test('a variable change shows up on the next sample, flagged as changed',
        () {
      final parsed = parse(
          r'$côté = 10' '\n' r'avance $côté' '\n' r'$côté = 50',
          KeywordTables.fr);
      final canvas = VectorCanvas();
      final interpreter = Interpreter(parsed.program, canvas);
      final inspector = Inspector(interpreter);

      expect(inspector.sample().variables, isEmpty);

      interpreter.step(); // $côté = 10
      var snap = inspector.sample();
      expect(snap.variables.single.name, 'côté');
      expect(snap.variables.single.display, '10');
      expect(snap.variables.single.changed, isTrue);
      expect(snap.variables.single.typeKey, 'type.number');

      interpreter.step(); // avance $côté — the box did not change
      snap = inspector.sample();
      expect(snap.variables.single.changed, isFalse);

      interpreter.step(); // $côté = 50
      snap = inspector.sample();
      expect(snap.variables.single.display, '50');
      expect(snap.variables.single.changed, isTrue);
    });

    test('the inspector names one node so blocks and text highlight together',
        () {
      // FR-M4-07 needs both surfaces lit from one source of truth, or they drift.
      final parsed = parse('avance 10\navance 20', KeywordTables.fr);
      final interpreter = Interpreter(parsed.program, VectorCanvas());
      final inspector = Inspector(interpreter);

      interpreter.step();
      final id = inspector.sample().currentNodeId;
      expect(id, isNotNull);
      expect(walk(parsed.program).map((n) => n.id), contains(id));
    });

    test('procedures a child defined are listed, by their own names', () {
      final parsed = parse(
          'apprends carré {\n  répète 4 {\n    avance 30\n    tournedroite 90\n  }\n}\ncarré',
          KeywordTables.fr);
      final interpreter = Interpreter(parsed.program, VectorCanvas());
      final inspector = Inspector(interpreter);
      interpreter.run();
      expect(inspector.sample().procedures, ['carré']);
    });

    test('the execution tree opens and closes with the procedure', () {
      final parsed = parse(
          r'apprends trait $n {'
          '\n'
          r'  avance $n'
          '\n}'
          '\ntrait 10\ntrait 20',
          KeywordTables.fr);
      final interpreter = Interpreter(parsed.program, VectorCanvas());
      final inspector = Inspector(interpreter);
      interpreter.run();
      // Both calls returned, so nothing is left on the stack.
      expect(inspector.sample().stack, isEmpty);
    });
  });

  group('FR-M4-04, FR-M4-05 · acceptance 5 — consent', () {
    test('the microphone is unreachable until a guardian allows it', () {
      final stage = SpriteStage();
      expect(
          stage.consent.stateOf(Capability.microphone), ConsentState.notAsked);

      final refused = stage.recordSound('s1', 'sound.one');
      expect(refused, isNotNull);
      expect(refused!.capability, Capability.microphone);
      expect(stage.sounds, isEmpty);

      stage.consent.setByGuardian(Capability.microphone, allowed: true);
      expect(stage.recordSound('s1', 'sound.one'), isNull);
      expect(stage.sounds.single.recorded, isTrue);
    });

    test('a guardian saying no is different from never being asked', () {
      final gate = ConsentGate();
      expect(gate.stateOf(Capability.sharing), ConsentState.notAsked);
      gate.setByGuardian(Capability.sharing, allowed: false);
      expect(gate.stateOf(Capability.sharing), ConsentState.refused);
    });

    test('the camera cannot be unlocked by any consent at all', () {
      // PO decision D-007. This is the test seat 13 would write, and it is deliberately
      // hostile: it tries the thing a future contributor would try.
      final gate = ConsentGate(granted: {Capability.camera: true});
      expect(gate.allows(Capability.camera), isFalse);
      expect(gate.stateOf(Capability.camera), ConsentState.notInThisVersion);
      expect(gate.setByGuardian(Capability.camera, allowed: true), isFalse);
      expect(gate.allows(Capability.camera), isFalse);

      final stage =
          SpriteStage(consent: ConsentGate(granted: {Capability.camera: true}));
      expect(stage.captureFromCamera().state, ConsentState.notInThisVersion);
    });

    test('consent never gates the learning path', () {
      // §13: "Consent: any account creation, any sharing, any camera or microphone access,
      // and any sync requires verifiable guardian action. Nothing about the learning path
      // does." A World-1 program must run on a stage with no consent whatsoever.
      final stage = SpriteStage();
      final program = parse(
              'répète 4 {\n  avance 40\n  tournedroite 90\n}', KeywordTables.fr)
          .program;
      final run = runProgram(program, stage);
      expect(run.status, RunStatus.finished);
      expect(stage.segmentCount, 4);
    });

    test('consent survives a round trip through storage', () {
      final gate = ConsentGate()
        ..setByGuardian(Capability.microphone, allowed: true)
        ..setByGuardian(Capability.sharing, allowed: false);
      final restored = ConsentGate.fromJson(gate.toJson());
      expect(restored.allows(Capability.microphone), isTrue);
      expect(restored.stateOf(Capability.sharing), ConsentState.refused);
      expect(restored.allows(Capability.camera), isFalse);
    });
  });

  group('FR-M16-05 · acceptance 6 — the palette', () {
    test('Annex C is reproduced exactly', () {
      expect(rgbReference, hasLength(9));
      final red = rgbReference.firstWhere((c) => c.keyFr == 'rouge');
      expect([red.r, red.g, red.b], [255, 0, 0]);
      final darkRed = rgbReference.firstWhere((c) => c.keyFr == 'rouge foncé');
      expect([darkRed.r, darkRed.g, darkRed.b], [150, 0, 0]);
      expect(rgbReference.firstWhere((c) => c.keyFr == 'bleu clair').hex,
          '#00ffff');
    });

    test('every default colour has a name in both languages', () {
      // FR-M16-01: colour is never the only carrier of meaning, so the picker shows names
      // — and a name that exists only in French is not a name for half the users.
      for (final c in [...colourBlindSafe, ...rgbReference]) {
        expect(c.keyFr.trim(), isNotEmpty);
        expect(c.keyEn.trim(), isNotEmpty);
      }
      // Some names genuinely coincide — "orange" is the same word — so the check that
      // matters is that the two lists are authored separately, not that every pair differs.
      expect(colourBlindSafe.map((c) => c.keyFr).toSet(),
          hasLength(colourBlindSafe.length));
      expect(colourBlindSafe.map((c) => c.keyEn).toSet(),
          hasLength(colourBlindSafe.length));
    });

    test('the default palette stays distinguishable without colour', () {
      // A crude but honest proxy for a colour-blind simulation: if two entries have nearly
      // the same luminance they are hard to tell apart in greyscale, and greyscale is the
      // worst case every deficiency approaches.
      final palette = colourBlindSafe;
      for (var i = 0; i < palette.length; i++) {
        for (var j = i + 1; j < palette.length; j++) {
          final gap = (palette[i].luminance - palette[j].luminance).abs();
          final hueGap = ((palette[i].r - palette[j].r).abs() +
                  (palette[i].g - palette[j].g).abs() +
                  (palette[i].b - palette[j].b).abs()) /
              765.0;
          expect(gap > 0.03 || hueGap > 0.25, isTrue,
              reason:
                  '${palette[i].keyFr} and ${palette[j].keyFr} are too close');
        }
      }
    });

    test('black on white clears WCAG AA for body text', () {
      final black = colourBlindSafe.firstWhere((c) => c.keyFr == 'noir');
      const white = NamedColour('blanc', 'white', 255, 255, 255);
      expect(black.contrastAgainst(white), greaterThanOrEqualTo(4.5));
    });
  });

  group('FR-M4-03 · the stage model teaches what the concepts say it teaches',
      () {
    test('a stage holds many sprites — concept C10.1', () {
      final stage = SpriteStage();
      expect(stage.sprites, hasLength(1));
      stage.addSprite('zigo', 'sprite.zigo');
      expect(stage.sprites, hasLength(2));
    });

    test('animation is switching costumes, not playing a video — concept C10.2',
        () {
      final stage = SpriteStage();
      final sprite = stage.addSprite('chat', 'sprite.cat', costumes: const [
        Costume('c1', 'costume.one'),
        Costume('c2', 'costume.two'),
      ]);
      expect(sprite.costume!.id, 'c1');
      sprite.nextCostume();
      expect(sprite.costume!.id, 'c2');
      sprite.nextCostume();
      expect(sprite.costume!.id, 'c1');
    });

    test('effects are not permanent — concept C10.5', () {
      final stage = SpriteStage();
      stage.selected.effects.ghost = 50;
      expect(stage.selected.effects.isClear, isFalse);
      stage.reset();
      expect(stage.selected.effects.isClear, isTrue);
    });

    test('a backdrop is not a sprite — concept C10.4', () {
      final stage = SpriteStage();
      expect(stage.backdrop.id, 'blank');
      // The type has no position and no heading. If someone adds them, this stops compiling
      // and they have to argue with the concept ledger first.
      expect(stage.backdrop, isA<Backdrop>());
      expect(stage.backdrop, isNot(isA<Sprite>()));
    });

    test('sounds play in program order — concept C10.3', () {
      final stage = SpriteStage()
        ..playSound('tambour')
        ..playSound('miaou');
      expect(stage.playedSounds, ['tambour', 'miaou']);
    });

    test('stage coordinates are centre-origin with y upwards', () {
      final stage = SpriteStage(width: 480, height: 360);
      stage.goToStage(100, 50);
      expect(stage.stageX, closeTo(100, 1e-9));
      expect(stage.stageY, closeTo(50, 1e-9));
    });
  });

  group('C3.5 · nettoietout and initialise are different, and stay different',
      () {
    test('clear erases the drawing and leaves the turtle and its labels gone',
        () {
      final canvas =
          _draw('avance 100\nécris "salut"\ntournedroite 90\nnettoietout');
      expect(canvas.segmentCount, 0);
      expect(canvas.texts, isEmpty);
      expect(canvas.direction, 90);
    });

    test('reset puts everything back', () {
      final canvas = _draw(
          'couleurcanevas 255, 0, 0\navance 100\ntournedroite 90\ninitialise');
      expect(canvas.segmentCount, 0);
      expect(canvas.direction, 0);
      expect(canvas.canvasBackground, 0xFFFFFF);
    });
  });
}

/// D-014's second half, on the stage the blocks were written for (`FR-M21-03`,
/// `FR-M21-04`).
///
/// The language extension is only half a feature until something implements it. These are
/// the tests that say the stage does — and that a sensor reads what the ITEM said it
/// would read, because a question a grader cannot answer the same way twice is not an
/// exercise.
void stageCapabilityTests() {
  SpriteStage stageWith(String source, {void Function(SpriteStage)? setUp}) {
    final stage = SpriteStage();
    setUp?.call(stage);
    final parsed = parse(source, KeywordTables.fr);
    expect(parsed.errors, isEmpty,
        reason: parsed.errors.map((e) => e.message('fr')).join('\n'));
    final machine = Interpreter(parsed.program, stage)..run();
    expect(machine.error, isNull, reason: machine.error?.message('fr') ?? '');
    return stage;
  }

  group('FR-M21-04 · costumes, backdrops, effects, speech and a score', () {
    test('costumesuivant walks the costumes and wraps', () {
      final stage = stageWith('costumesuivant\ncostumesuivant\ncostumesuivant',
          setUp: (s) => s.selected.costumes.addAll(const [
                Costume('a', 'costume.a'),
                Costume('b', 'costume.b'),
              ]));
      expect(stage.costumeNumber, 2, reason: 'three steps of two costumes');
    });

    test('costume n counts from one, the way the picker shows it', () {
      final stage = stageWith('costume 2',
          setUp: (s) => s.selected.costumes.addAll(const [
                Costume('a', 'costume.a'),
                Costume('b', 'costume.b'),
                Costume('c', 'costume.c'),
              ]));
      expect(stage.costumeNumber, 2);
      expect(stage.selected.costumeIndex, 1);
    });

    test('a costume out of range wraps rather than failing', () {
      // A child typing 7 where there are three costumes is exploring, not erring.
      final stage = stageWith('costume 7',
          setUp: (s) => s.selected.costumes.addAll(const [
                Costume('a', 'costume.a'),
                Costume('b', 'costume.b'),
                Costume('c', 'costume.c'),
              ]));
      expect(stage.costumeNumber, 1);
    });

    test('an effect is set by name, and cleared', () {
      final stage = stageWith('effet "fantôme", 50\neffet "tourbillon", 20');
      expect(stage.selected.effects.ghost, 50);
      expect(stage.selected.effects.whirl, 20);

      final cleared = stageWith('effet "fantôme", 50\neffaceeffets');
      expect(cleared.selected.effects.isClear, isTrue);
    });

    test('an effect nobody has heard of is ignored, not fatal', () {
      // The names are content; a pack may ship its own, so an unknown one is a missing
      // asset rather than a bug in the child's program.
      final stage = stageWith('effet "bidule", 30');
      expect(stage.selected.effects.isClear, isTrue);
    });

    test('the score is recorded in order, and never played', () {
      final stage =
          stageWith('tambour 2, 1\nnote 60, 0.5\njouson "miaou"\ntambour 5, 2');
      expect(stage.score.map((e) => '${e.kind}:${e.value}×${e.beats}').toList(),
          ['drum:2×1', 'note:60×0.5', 'sound:miaou×0', 'drum:5×2']);
    });

    test('and the score remembers WHEN, not only what', () {
      /* World 10's third concept is "the sound plays where it is written". Without the
         moment, a program that beats a drum between each line and one that draws
         everything and then beats produce identical scores — and the grader would have
         called the misconception correct. */
      final stage =
          stageWith('avance 10\ntambour 1, 1\navance 10\ntambour 1, 1');
      expect(stage.score.map((e) => e.after).toList(), [1, 2]);

      final atTheEnd =
          stageWith('avance 10\navance 10\ntambour 1, 1\ntambour 1, 1');
      expect(atTheEnd.score.map((e) => e.after).toList(), [2, 2]);
      expect(atTheEnd.score.map((e) => e.toString()).toList(),
          isNot(stage.score.map((e) => e.toString()).toList()));
    });

    test('dis is the sprite talking, message is the system talking', () {
      final stage = stageWith('dis "bonjour"\nmessage "attention"');
      expect(stage.saidLines.map((l) => l.text).toList(), ['bonjour']);
      expect(stage.messages, ['attention']);
    });
  });

  group('FR-M21-03 · sensing answers the item, not a device', () {
    test('a key the item said is down reads as down', () {
      final stage = stageWith('si touchepressée "espace" {\n  avance 50\n}',
          setUp: (s) => s.keysDown.add('espace'));
      expect(stage.positionY, 130);
    });

    test('a key the item did not name reads as up', () {
      final stage = stageWith('si touchepressée "a" {\n  avance 50\n}',
          setUp: (s) => s.keysDown.add('espace'));
      expect(stage.segments, isEmpty);
    });

    test('the mouse is where the item put it', () {
      final stage = stageWith('va sourisx, sourisy', setUp: (s) {
        s.mousePointerX = 300;
        s.mousePointerY = 120;
      });
      expect(stage.positionX, 300);
      expect(stage.positionY, 120);
    });

    test('touchebord is true at the edge and false in the middle', () {
      expect(stageWith('va 0, 100').touchingEdge, isTrue);
      expect(stageWith('va 200, 150').touchingEdge, isFalse);
    });

    test('touchecouleur reads the ink already drawn', () {
      /* Read from the segments rather than from a rasterised frame: the canvas is
         vectors, and rasterising on every sensor read would cost more than the whole
         program. */
      final stage = stageWith(
        'couleurcrayon 255, 0, 0\nlargeurcrayon 6\navance 60\n'
        'si touchecouleur 255, 0, 0 {\n  écris "rouge"\n}',
      );
      expect(stage.output, ['rouge']);

      final other = stageWith(
        'couleurcrayon 255, 0, 0\navance 60\n'
        'si touchecouleur 0, 0, 255 {\n  écris "bleu"\n}',
      );
      expect(other.output, isEmpty);
    });

    test('the same program run twice gives the same answers', () {
      // The whole reason sensing is scripted: an item has to be markable twice.
      SpriteStage once() => stageWith(
          'si touchepressée "espace" {\n'
          '  avance 40\n}\nécris positiony',
          setUp: (s) => s.keysDown.add('espace'));
      expect(once().output, once().output);
    });
  });

  group('the stage drives events, which is what World 5 needs', () {
    test('a key script runs on that key and draws on the stage', () {
      final stage = SpriteStage();
      final parsed = parse(
          'quand touche "espace" {\n  avance 50\n}\n'
          'quand touche "a" {\n  avance 200\n}',
          KeywordTables.fr);
      expect(parsed.errors, isEmpty);
      Interpreter(parsed.program, stage, trigger: const KeyPressed('espace'))
          .run();
      expect(stage.segments, hasLength(1));
    });
  });

  /* The PNG encoder, after the review. `png.dart` carries a hand-rolled LZ77 and RFC
     1951's fixed Huffman tables, because a pure-Dart package with no dependencies has no
     compressor to call. These tests check the parts a structure check can reach; the part
     that matters — that the bytes actually inflate — is checked by somebody else's zlib,
     in `tools/png_check.py`, on every CI run. A compressor believed only by its own
     decoder is not believed.
  */
  group('FR-M4-02 · an exported drawing is a file a child can keep', () {
    Uint8List drawn(String source) {
      final canvas = VectorCanvas();
      Interpreter(parse(source, KeywordTables.fr).program, canvas).run();
      return canvas.toPng();
    }

    ({int width, int height, int colourType, int idat}) header(Uint8List png) {
      expect(
          png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
          reason: 'not a PNG');
      var at = 8;
      var width = 0, height = 0, colourType = -1, idat = 0;
      while (at < png.length) {
        final length = (png[at] << 24) |
            (png[at + 1] << 16) |
            (png[at + 2] << 8) |
            png[at + 3];
        final kind = String.fromCharCodes(png.sublist(at + 4, at + 8));
        if (kind == 'IHDR') {
          width = (png[at + 8] << 24) |
              (png[at + 9] << 16) |
              (png[at + 10] << 8) |
              png[at + 11];
          height = (png[at + 12] << 24) |
              (png[at + 13] << 16) |
              (png[at + 14] << 8) |
              png[at + 15];
          colourType = png[at + 17];
        }
        if (kind == 'IDAT') idat += length;
        at += 12 + length;
      }
      expect(at, png.length, reason: 'chunks do not fill the file');
      return (width: width, height: height, colourType: colourType, idat: idat);
    }

    test('it is an indexed PNG of the right size', () {
      final png = drawn('répète 4 {\n  avance 80\n  tournedroite 90\n}');
      final h = header(png);
      expect(h.width, 400);
      expect(h.height, 400);
      // Colour type 3: a palette. Two colours do not need three bytes each.
      expect(h.colourType, 3);
    });

    test('a drawing costs kilobytes, not half a megabyte', () {
      /* What this replaced: truecolour over stored zlib blocks, which charged 480 503
         bytes for any drawing at all — a child with a dozen saved pictures was spending
         six megabytes of a 2 GB phone on white. */
      for (final source in const [
        'lèvecrayon\navance 10',
        'répète 4 {\n  avance 80\n  tournedroite 90\n}',
        'répète 180 {\n  avance 90\n  tournedroite 178\n}',
      ]) {
        final png = drawn(source);
        expect(png.length, lessThan(20000),
            reason: 'a drawing should not cost ${png.length} bytes');
      }
    });

    test('an empty page costs less than a busy one', () {
      // The compressor is doing something, rather than emitting stored blocks under a
      // new name: a page of one colour has to collapse further than a page of many runs.
      final blank = drawn('lèvecrayon\navance 10').length;
      final busy = drawn('répète 36 {\n  répète 4 {\n    avance 60\n'
              '    tournedroite 90\n  }\n  tournedroite 10\n}')
          .length;
      expect(blank, lessThan(busy));
      expect(blank * 3, lessThan(busy));
    });

    test('the same drawing exports the same bytes', () {
      // Determinism, which is what lets the visual-regression tests compare at all.
      final once = drawn('répète 6 {\n  avance 50\n  tournedroite 60\n}');
      final twice = drawn('répète 6 {\n  avance 50\n  tournedroite 60\n}');
      expect(once, twice);
    });
  });
}
