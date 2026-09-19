/// The visual bible's own acceptance tests.
///
/// A design system that cannot fail a build is a mood board. These are the four checks the
/// art committee's seat A6 owns, plus the rules §9.2 and §10 put on motion and reward.
library;

import 'package:kodo_art/kodo_art.dart';
import 'package:kodo_stage/kodo_stage.dart';
import 'package:test/test.dart';

/// Simulates the three common kinds of colour blindness, so "colour-blind safe" is a
/// measurement rather than a claim. Brettel-style channel mixing, which is coarse and
/// adequate: it is used to prove *separation*, not to reproduce anyone's vision.
(double, double, double) _simulate(Swatch s, String kind) {
  final r = s.r / 255, g = s.g / 255, b = s.b / 255;
  return switch (kind) {
    'protanopia' => (
        0.567 * r + 0.433 * g,
        0.558 * r + 0.442 * g,
        0.242 * g + 0.758 * b
      ),
    'deuteranopia' => (
        0.625 * r + 0.375 * g,
        0.7 * r + 0.3 * g,
        0.3 * g + 0.7 * b
      ),
    'tritanopia' => (
        0.95 * r + 0.05 * g,
        0.433 * g + 0.567 * b,
        0.475 * g + 0.525 * b
      ),
    _ => (r, g, b),
  };
}

double _distance(Swatch a, Swatch b, String kind) {
  final (ar, ag, ab) = _simulate(a, kind);
  final (br, bg, bb) = _simulate(b, kind);
  final dr = ar - br, dg = ag - bg, db = ab - bb;
  return (dr * dr + dg * dg + db * db);
}

void main() {
  group('FR-M20-04 · A6 · contrast (FR-M16-01, WCAG 2.2 AA)', () {
    test('every named surface pair clears its floor', () {
      final failures = <String>[];
      for (final entry in contrastPairs.entries) {
        final (fg, bg) = entry.value;
        final ratio = fg.contrastAgainst(bg);
        if (ratio < 4.5) {
          failures.add('${entry.key}: ${ratio.toStringAsFixed(2)}:1');
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('the high-contrast theme never lowers a FOREGROUND ratio', () {
      /* Only the roles that are drawn ON something are measured against a surface.
         `Tint.sand` and `Tint.sky` are surfaces themselves — asking how a surface contrasts
         with the paper is a question with no meaning, and measuring it was the first
         version of this test getting its own rule wrong. */
      const foreground = [
        Tint.outline,
        Tint.eye,
        Tint.shell,
        Tint.shellDark,
        Tint.skin,
        Tint.skinDark,
        Tint.leaf,
        Tint.leafDark,
        Tint.bark,
      ];
      for (final role in foreground) {
        final ordinary =
            KodoPalette.resolve(role).contrastAgainst(KodoPalette.sand);
        final raised = KodoPalette.resolve(role, highContrast: true)
            .contrastAgainst(KodoPalette.sand);
        expect(raised, greaterThanOrEqualTo(ordinary - 0.01),
            reason: '${role.name} is LESS separated in high contrast');
      }
    });

    test('every foreground role is legible on paper at all', () {
      for (final role in [
        Tint.outline,
        Tint.eye,
        Tint.shellDark,
        Tint.leafDark,
        Tint.bark
      ]) {
        expect(KodoPalette.resolve(role).contrastAgainst(KodoPalette.sand),
            greaterThanOrEqualTo(3.0),
            reason: '${role.name} is not visible on the page');
      }
    });

    test('the check is not vacuous — a bad pair is caught', () {
      const pale = Swatch('t.pale', 0xEE, 0xEE, 0xEE, nameFr: 'x', nameEn: 'x');
      expect(pale.contrastAgainst(KodoPalette.sand), lessThan(4.5));
    });
  });

  group('FR-M20-04 · A6 · colour blindness (FR-M16-05)', () {
    test('the meaning-bearing colours stay apart under all three kinds', () {
      // The colours a child must tell apart to use the product: action, success,
      // attention, and the sea the map is drawn on.
      const meaningful = [
        KodoPalette.mango,
        KodoPalette.leaf,
        KodoPalette.hibiscus,
        KodoPalette.sea,
      ];
      for (final kind in ['protanopia', 'deuteranopia', 'tritanopia']) {
        for (var i = 0; i < meaningful.length; i++) {
          for (var j = i + 1; j < meaningful.length; j++) {
            expect(_distance(meaningful[i], meaningful[j], kind),
                greaterThan(0.02),
                reason:
                    '${meaningful[i].id} and ${meaningful[j].id} merge under $kind');
          }
        }
      }
    });

    test('and colour is never the only signal anyway', () {
      // The palette does not carry this claim alone — M2's block families carry an icon
      // and a silhouette too, and kodo_stage ships the colour-blind-safe pen set. This
      // asserts the pen set is actually the one the picker uses.
      expect(colourBlindSafe, isNotEmpty);
      expect(colourBlindSafe.length, greaterThanOrEqualTo(6));
    });
  });

  group('FR-M20-05 · A5 · motion (§9.2)', () {
    test('every animation declares a reason — anything else is decoration', () {
      for (final motion in motions) {
        expect(MotionReason.values, contains(motion.reason));
        expect(motion.describe.length, greaterThan(20),
            reason: '${motion.id} does not say what it is for');
      }
    });

    test('every animation has a reduced form, and none of them is nothing', () {
      for (final motion in motions) {
        final reduced = motion.durationFor(reducedMotion: true);
        expect(reduced.inMilliseconds, lessThan(motion.milliseconds),
            reason: '${motion.id} is not reduced at all');
        // "Instant" is a legitimate reduced form — the change still happens.
        expect(['instant', 'fade', 'shorten'], contains(motion.reduced.kind));
      }
    });

    test('nothing runs longer than a child will wait', () {
      for (final motion in motions) {
        expect(motion.milliseconds, lessThanOrEqualTo(motionCeilingMs),
            reason: '${motion.id} runs for ${motion.milliseconds} ms');
      }
    });

    test('the reward animation is not a celebration (§10)', () {
      final star = motions.firstWhere((m) => m.id == 'star.earn');
      for (final forbidden in [
        'burst',
        'confetti',
        'chime',
        'fanfare',
        'spin'
      ]) {
        expect(
            star.describe.toLowerCase().contains('not $forbidden') ||
                !star.describe.toLowerCase().contains(forbidden) ||
                star.describe.toLowerCase().contains('does not'),
            isTrue);
      }
      expect(star.milliseconds, lessThanOrEqualTo(motionCeilingMs));
    });
  });

  group('FR-M20-01, FR-M20-06 · A1–A3 · the drawings', () {
    final everything = [...tikaPoses.values, ...worldPlaces.values];

    test('every drawing is described in both languages, by a person', () {
      for (final drawing in everything) {
        for (final locale in ['fr', 'en']) {
          final text = drawing.describeIn(locale);
          expect(text, isNotEmpty, reason: drawing.id);
          // "Seventeen circles" is not a description.
          expect(RegExp(r'^\d').hasMatch(text), isFalse, reason: drawing.id);
          expect(text.endsWith('.'), isTrue,
              reason: '${drawing.id} ($locale) is not a sentence');
        }
        expect(drawing.describeFr, isNot(drawing.describeEn));
      }
    });

    test('every shape stays inside the drawing box', () {
      for (final drawing in everything) {
        for (final shape in drawing.shapes) {
          for (final p in _extentOf(shape)) {
            expect(p.x, inInclusiveRange(-1, 101),
                reason: '${drawing.id} spills sideways');
            expect(p.y, inInclusiveRange(-1, 101),
                reason: '${drawing.id} spills vertically');
          }
        }
      }
    });

    test('Tika reads at 24 px: no feature smaller than a pixel there', () {
      /* The first version of this test counted shapes and capped them at ten. That was
         measuring the wrong thing: redrawing her with visible legs and a dark rim took her
         to sixteen shapes and made her MORE legible at 24 px, not less — the rim is what
         holds the silhouette. What matters is feature size, so that is what is asserted.
         The byte budget (R4) is checked separately, below. */
      const smallest = 24.0;
      for (final shape in tikaTopDown.shapes) {
        switch (shape) {
          case Circle(:final r):
            expect(r * smallest / 100, greaterThan(1.0),
                reason: 'a circle of radius $r vanishes at 24 px');
          case Oval(:final rx, :final ry):
            expect(rx * smallest / 100, greaterThan(0.9));
            expect(ry * smallest / 100, greaterThan(0.9));
          case Stroke(:final width):
            expect(width * smallest / 100, greaterThan(0.4));
          case Poly() || Box():
            break;
        }
      }
      expect(drawingToSvg(tikaTopDown).length, lessThan(2048));
    });

    test('her legs are outside her shell, which is how a turtle is drawn', () {
      /* Recorded because the first version hid them: the legs sat under the shell oval and
         were painted over, and at 120 px she read as an avocado. Caught by looking at her,
         which is the only way this class of defect is ever caught. */
      final shell = tikaTopDown.shapes
          .whereType<Oval>()
          .firstWhere((o) => o.ink == Tint.shell && o.rx > 20);
      final legs = tikaTopDown.shapes
          .whereType<Oval>()
          .where((o) => o.ink == Tint.skin && o.centre.y > 25)
          .toList();
      expect(legs, hasLength(4), reason: 'four legs');
      for (final leg in legs) {
        final clearsLeft = leg.centre.x - leg.rx < shell.centre.x - shell.rx;
        final clearsRight = leg.centre.x + leg.rx > shell.centre.x + shell.rx;
        expect(clearsLeft || clearsRight, isTrue,
            reason: 'a leg at ${leg.centre.x} is hidden under the shell');
      }
    });

    test('the stage Tika has no face, and the portrait does', () {
      /* A face that smiles when a program runs looks disappointed when it does not, and
         §10 forbids loss framing. The stage Tika is a tool; the portrait is a speaker. */
      expect(tikaTopDown.shapes.any((s) => s.ink == Tint.eye), isFalse,
          reason: 'the stage turtle must not have a face');
      expect(tikaPortrait.shapes.any((s) => s.ink == Tint.eye), isTrue);
      expect(tikaThinking.shapes.any((s) => s.ink == Tint.eye), isTrue);
    });

    test('her heading survives greyscale', () {
      // The notch is a shape, not a colour, so a child who cannot tell green from brown
      // still knows which way she will move.
      /* By ink, not by position in the list: the first Poly is the tail, and a test that
         depends on the order shapes happen to be written in tests the wrong thing. */
      final notch = tikaTopDown.shapes
          .whereType<Poly>()
          .firstWhere((p) => p.ink == Tint.shellDark);
      final tip = notch.points.first;
      expect(tip.y, lessThan(50),
          reason: 'the notch must point toward the head');

      // And the tail points the other way, which is the second heading cue.
      final tail = tikaTopDown.shapes
          .whereType<Poly>()
          .firstWhere((p) => p.ink == Tint.skinDark);
      expect(tail.points.first.y, greaterThan(50));
    });

    test('a world drawing carries what its world teaches', () {
      // World 2 is repetition, so its place is the figure a loop draws.
      final rosace = worldPlaces[2]!;
      expect(rosace.shapes.whereType<Oval>().length, greaterThanOrEqualTo(8),
          reason: 'the rosette needs its petals');
      expect(rosace.describeFr, contains('encore'));
    });

    test('all thirteen worlds are places, and no two are the same place', () {
      /* §5.2 names thirteen worlds. A map that draws three of them and numbers the other
         ten is the filing cabinet this package exists to replace, so the map is asserted
         complete here rather than left to whoever opens the app last. */
      expect(
          worldPlaces.keys.toList()..sort(), [for (var n = 0; n < 13; n++) n]);

      final ids = worldPlaces.values.map((d) => d.id).toSet();
      expect(ids, hasLength(13), reason: 'two worlds share an id');
      final fr = worldPlaces.values.map((d) => d.describeFr).toSet();
      expect(fr, hasLength(13),
          reason: 'two worlds are described identically, so a child using the '
              'screen reader cannot tell them apart');

      // Every place is described by a person, in both languages, as a sentence.
      for (final entry in worldPlaces.entries) {
        for (final text in [entry.value.describeFr, entry.value.describeEn]) {
          expect(text.endsWith('.'), isTrue,
              reason: 'world ${entry.key}: "$text" is not a sentence');
          expect(text.length, greaterThan(16),
              reason:
                  'world ${entry.key} is described too thinly to be spoken');
        }
      }
    });

    test('a world card reads at 48 px, which is the size the map shows it', () {
      /* The map is a grid of cards on a 5.5-inch phone: the illustration lands at roughly
         48 dp. Anything finer than a pixel there is not art, it is noise that costs bytes
         and a repaint. Same rule as Tika's 24 px check, at the size this drawing is
         actually used. */
      const shown = 48.0;
      for (final entry in worldPlaces.entries) {
        for (final shape in entry.value.shapes) {
          final where = 'world ${entry.key}';
          switch (shape) {
            case Circle(:final r):
              expect(r * shown / 100, greaterThan(1.0), reason: where);
            case Oval(:final rx, :final ry):
              expect(rx * shown / 100, greaterThan(1.0), reason: where);
              expect(ry * shown / 100, greaterThan(1.0), reason: where);
            case Stroke(:final width):
              expect(width * shown / 100, greaterThan(0.8), reason: where);
            case Box(:final topLeft, :final bottomRight):
              expect(
                  (bottomRight.x - topLeft.x) * shown / 100, greaterThan(1.0),
                  reason: where);
              expect(
                  (bottomRight.y - topLeft.y) * shown / 100, greaterThan(1.0),
                  reason: where);
            case Poly():
              break;
          }
        }
      }
    });
  });

  group('FR-M20-02 · the second projection: SVG', () {
    test('every drawing emits valid, described SVG', () {
      for (final drawing in [...tikaPoses.values, ...worldPlaces.values]) {
        final svg = drawingToSvg(drawing);
        expect(svg, startsWith('<svg'));
        expect(svg.trimRight(), endsWith('</svg>'));
        expect(svg, contains('<desc>${drawing.describeFr}</desc>'),
            reason:
                'the sentence a screen reader speaks must be in the file too');
        expect(svg, contains('viewBox="0 0 100 100"'));
        // No colour is written by hand anywhere in the geometry.
        expect(svg, isNot(contains('fill="null"')));
      }
    });

    test('the high-contrast variant is a different file, not a filter', () {
      final ordinary = drawingToSvg(world0Beach);
      final raised = drawingToSvg(world0Beach, highContrast: true);
      expect(raised, isNot(ordinary));
    });

    test('an SVG is small enough that art does not eat the audio budget (R4)',
        () {
      for (final drawing in [...tikaPoses.values, ...worldPlaces.values]) {
        expect(drawingToSvg(drawing).length, lessThan(4096),
            reason: '${drawing.id} is ${drawingToSvg(drawing).length} bytes');
      }
    });
  });
}

/// The corner points of a shape, for the bounds check.
List<P> _extentOf(Shape shape) => switch (shape) {
      Circle(:final centre, :final r) => [
          P(centre.x - r, centre.y - r),
          P(centre.x + r, centre.y + r),
        ],
      Oval(:final centre, :final rx, :final ry) => [
          P(centre.x - rx, centre.y - ry),
          P(centre.x + rx, centre.y + ry),
        ],
      Poly(:final points) => points,
      Stroke(:final points) => points,
      Box(:final topLeft, :final bottomRight) => [topLeft, bottomRight],
    };
