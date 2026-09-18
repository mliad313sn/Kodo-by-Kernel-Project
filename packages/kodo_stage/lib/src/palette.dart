/// Colour reference (Annex C, FR-M16-05).
///
/// Two palettes, and they are not the same thing. [rgbReference] is the *lesson* — the
/// table World 3 teaches RGB from, reproduced from Annex C without editorial change,
/// because a child looking at the reference card and the picker must see the same numbers.
/// [colourBlindSafe] is the *default* — what the picker offers first, chosen so that no two
/// entries collapse under the common colour-vision deficiencies.
library;

import 'dart:math' as math;

/// A named colour a child can choose.
class NamedColour {
  const NamedColour(this.keyFr, this.keyEn, this.r, this.g, this.b);

  /// Child-facing name in French, the reference language.
  final String keyFr;
  final String keyEn;
  final int r, g, b;

  int get packed => (r << 16) | (g << 8) | b;

  String get hex => '#${packed.toRadixString(16).padLeft(6, '0')}';

  /// Relative luminance, per WCAG 2.2, for the contrast checks of `FR-M16-01`.
  double get luminance {
    double channel(int v) {
      final s = v / 255.0;
      return s <= 0.03928
          ? s / 12.92
          : math.pow((s + 0.055) / 1.055, 2.4) as double;
    }

    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
  }

  /// WCAG contrast ratio against [other]. AA large text needs 3.0, body text 4.5.
  double contrastAgainst(NamedColour other) {
    final a = luminance, b = other.luminance;
    final lighter = a > b ? a : b;
    final darker = a > b ? b : a;
    return (lighter + 0.05) / (darker + 0.05);
  }
}

/// Annex C, verbatim. The World-3 reference card.
const List<NamedColour> rgbReference = [
  NamedColour('noir', 'black', 0, 0, 0),
  NamedColour('blanc', 'white', 255, 255, 255),
  NamedColour('rouge', 'red', 255, 0, 0),
  NamedColour('rouge foncé', 'dark red', 150, 0, 0),
  NamedColour('vert', 'green', 0, 255, 0),
  NamedColour('bleu', 'blue', 0, 0, 255),
  NamedColour('bleu clair', 'light blue', 0, 255, 255),
  NamedColour('rose', 'pink', 255, 0, 255),
  NamedColour('jaune', 'yellow', 255, 255, 0),
];

/// The picker's default set.
///
/// Built on the Okabe–Ito qualitative palette, which is designed to stay distinguishable
/// under deuteranopia, protanopia and tritanopia. `FR-M16-05` requires a colour-blind-safe
/// picker, and `FR-M16-01` requires that colour is never the only carrier of meaning — so
/// every entry also has a name, and the picker shows the name.
const List<NamedColour> colourBlindSafe = [
  NamedColour('noir', 'black', 0, 0, 0),
  NamedColour('orange', 'orange', 230, 159, 0),
  NamedColour('bleu ciel', 'sky blue', 86, 180, 233),
  NamedColour('vert bouteille', 'bluish green', 0, 158, 115),
  NamedColour('jaune', 'yellow', 240, 228, 66),
  NamedColour('bleu', 'blue', 0, 114, 178),
  NamedColour('orange foncé', 'vermillion', 213, 94, 0),
  NamedColour('rose', 'reddish purple', 204, 121, 167),
];
