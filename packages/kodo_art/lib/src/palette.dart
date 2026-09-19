/// The KODO palette.
///
/// Warm, and not infantile. Eight-to-eleven is not three-to-five: a child of nine who is
/// shown pastel bubbles knows it was made for somebody younger, and stops. The register
/// here is *adventure*, not *nursery*.
///
/// It is anchored in the launch market (§17, Dakar first) — sand, sea, mango, baobab,
/// hibiscus, the indigo of a night sky — because §15 asks for content that is *culturally
/// legible*, and a palette is content. None of it is exotic decoration: these are the
/// colours of the place, used plainly.
///
/// Every value below survives four checks, and the tests run them:
///   1. body text ≥ 4.5:1 against its surface (`FR-M16-01`);
///   2. large text and non-text ≥ 3.0:1;
///   3. the ten block families stay separable under three kinds of colour blindness;
///   4. a high-contrast variant exists for every surface pair.
library;

import 'package:kodo_stage/kodo_stage.dart';

import 'geometry.dart';

/// One colour, with the two names a child-facing product needs.
class Swatch {
  const Swatch(this.id, this.r, this.g, this.b,
      {required this.nameFr, required this.nameEn});

  final String id;
  final int r, g, b;

  /// What a child calls it. Used by the colour lesson of World 3 and by the pen picker,
  /// so it is authored rather than invented at the call site.
  final String nameFr, nameEn;

  int get packed => (r << 16) | (g << 8) | b;
  String get hex => '#${packed.toRadixString(16).padLeft(6, '0')}';

  /// Reuses M4's WCAG arithmetic rather than restating it. One luminance formula in the
  /// product, as with everything else.
  NamedColour get asNamedColour => NamedColour(nameFr, nameEn, r, g, b);

  double contrastAgainst(Swatch other) =>
      asNamedColour.contrastAgainst(other.asNamedColour);
}

/// The palette proper.
class KodoPalette {
  const KodoPalette._();

  // --- surfaces ---------------------------------------------------------------------
  /// The page a child reads on. Warm white, not blue-white: a cool grey reads as
  /// *software*, and this is meant to read as *paper*.
  static const sand =
      Swatch('sand', 0xFD, 0xF7, 0xEC, nameFr: 'sable', nameEn: 'sand');
  static const sandDeep = Swatch('sand.deep', 0xF2, 0xE4, 0xCE,
      nameFr: 'sable foncé', nameEn: 'deep sand');

  /// Night, for the dark theme and for World 8's sky.
  static const night =
      Swatch('night', 0x13, 0x1B, 0x2E, nameFr: 'nuit', nameEn: 'night');
  static const nightSoft = Swatch('night.soft', 0x22, 0x2E, 0x4A,
      nameFr: 'nuit claire', nameEn: 'soft night');

  // --- ink --------------------------------------------------------------------------
  /// Body text. Near-black with a trace of the sea in it, so it sits in the world rather
  /// than on top of it.
  static const ink =
      Swatch('ink', 0x14, 0x20, 0x24, nameFr: 'encre', nameEn: 'ink');
  static const inkSoft = Swatch('ink.soft', 0x45, 0x55, 0x5A,
      nameFr: 'encre pâle', nameEn: 'soft ink');

  // --- the world --------------------------------------------------------------------
  static const sea =
      Swatch('sea', 0x0E, 0x7C, 0x86, nameFr: 'mer', nameEn: 'sea');
  static const seaDeep = Swatch('sea.deep', 0x07, 0x4E, 0x57,
      nameFr: 'mer profonde', nameEn: 'deep sea');
  static const sky =
      Swatch('sky', 0x8E, 0xD3, 0xDE, nameFr: 'ciel', nameEn: 'sky');

  /// The action colour. Mango — the one thing on screen a child may press.
  static const mango =
      Swatch('mango', 0xE2, 0x6D, 0x0A, nameFr: 'mangue', nameEn: 'mango');
  static const mangoDeep = Swatch('mango.deep', 0xA8, 0x4B, 0x03,
      nameFr: 'mangue mûre', nameEn: 'ripe mango');

  /// Success. A leaf, not a tick — growth rather than a mark out of ten.
  static const leaf =
      Swatch('leaf', 0x2F, 0x7D, 0x32, nameFr: 'feuille', nameEn: 'leaf');
  static const leafDeep = Swatch('leaf.deep', 0x1B, 0x52, 0x1E,
      nameFr: 'feuille foncée', nameEn: 'deep leaf');

  /// Attention — never alarm. §10 forbids loss framing, and a red bar on a child's screen
  /// is loss framing whatever the words beside it say.
  static const hibiscus = Swatch('hibiscus', 0xC2, 0x2E, 0x54,
      nameFr: 'hibiscus', nameEn: 'hibiscus');

  static const bark =
      Swatch('bark', 0x6B, 0x4A, 0x2F, nameFr: 'écorce', nameEn: 'bark');
  static const sun =
      Swatch('sun', 0xF2, 0xB5, 0x14, nameFr: 'soleil', nameEn: 'sun');

  /// Tika's own colours. A turtle a child can draw themselves afterwards.
  static const shell =
      Swatch('shell', 0x2E, 0x8B, 0x57, nameFr: 'carapace', nameEn: 'shell');
  static const shellDeep = Swatch('shell.deep', 0x1C, 0x5E, 0x3A,
      nameFr: 'carapace foncée', nameEn: 'deep shell');
  static const skin =
      Swatch('skin', 0x8C, 0xC6, 0x3F, nameFr: 'peau', nameEn: 'skin');
  static const skinDeep = Swatch('skin.deep', 0x63, 0x94, 0x28,
      nameFr: 'peau foncée', nameEn: 'deep skin');

  static const white =
      Swatch('white', 0xFF, 0xFF, 0xFF, nameFr: 'blanc', nameEn: 'white');

  static const all = [
    sand,
    sandDeep,
    night,
    nightSoft,
    ink,
    inkSoft,
    sea,
    seaDeep,
    sky,
    mango,
    mangoDeep,
    leaf,
    leafDeep,
    hibiscus,
    bark,
    sun,
    shell,
    shellDeep,
    skin,
    skinDeep,
    white,
  ];

  /// Which swatch an [Tint] role resolves to, in the ordinary theme.
  static const forInk = <Tint, Swatch>{
    Tint.shell: shell,
    Tint.shellDark: shellDeep,
    Tint.skin: skin,
    Tint.skinDark: skinDeep,
    Tint.eye: ink,
    Tint.highlight: white,
    Tint.sand: sandDeep,
    Tint.sea: sea,
    Tint.seaDeep: seaDeep,
    Tint.sky: sky,
    Tint.sun: sun,
    Tint.mango: mango,
    Tint.leaf: leaf,
    Tint.leafDark: leafDeep,
    Tint.bark: bark,
    Tint.night: night,
    Tint.outline: ink,
    Tint.sandLine: sandDeep,
    Tint.inkLine: ink,
    Tint.mangoDeep: mangoDeep,
    Tint.hibiscusInk: hibiscus,
  };

  /// The high-contrast theme (`FR-M16-03`).
  ///
  /// It raises separation rather than swapping the palette, so a child who turns it on
  /// still recognises the world they were in a moment ago. Only the roles that carry
  /// *meaning* move; the decorative ones stay put.
  static const forInkHighContrast = <Tint, Swatch>{
    Tint.shell: shellDeep,
    Tint.shellDark: shellDeep,
    Tint.skin: leafDeep,
    Tint.skinDark: leafDeep,
    Tint.eye: ink,
    Tint.highlight: white,
    Tint.sand: white,
    Tint.sea: seaDeep,
    Tint.seaDeep: seaDeep,
    Tint.sky: white,
    Tint.sun: mangoDeep,
    Tint.mango: mangoDeep,
    Tint.leaf: leafDeep,
    Tint.leafDark: leafDeep,
    Tint.bark: ink,
    Tint.night: night,
    Tint.outline: ink,
    /* A ruling drawn in deep sand vanishes once `sand` becomes white, so in high contrast
       it becomes a soft ink line: the grid of World 4 is the picture, not decoration. */
    Tint.sandLine: inkSoft,
    Tint.inkLine: ink,
    Tint.mangoDeep: mangoDeep,
    Tint.hibiscusInk: hibiscus,
  };

  static Swatch resolve(Tint role, {bool highContrast = false}) =>
      (highContrast ? forInkHighContrast : forInk)[role]!;
}

/// Surface / foreground pairs that must clear WCAG, named so a test failure says which
/// screen is wrong rather than which hex is wrong.
const contrastPairs = <String, (Swatch, Swatch)>{
  'body text on paper': (KodoPalette.ink, KodoPalette.sand),
  'soft text on paper': (KodoPalette.inkSoft, KodoPalette.sand),
  'body text on deep sand': (KodoPalette.ink, KodoPalette.sandDeep),
  'paper text on night': (KodoPalette.sand, KodoPalette.night),
  'paper text on soft night': (KodoPalette.sand, KodoPalette.nightSoft),
  'button label on mango': (KodoPalette.white, KodoPalette.mangoDeep),
  'button label on sea': (KodoPalette.white, KodoPalette.seaDeep),
  'button label on leaf': (KodoPalette.white, KodoPalette.leafDeep),
  'attention label on hibiscus': (KodoPalette.white, KodoPalette.hibiscus),
};
