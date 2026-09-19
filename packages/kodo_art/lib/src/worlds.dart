/// The worlds, as places.
///
/// A world in KODO is not a folder of exercises with a number on it. It is somewhere a
/// child goes, and the illustration is what makes the map worth opening. §9.1 calls the
/// map *"the single entry point to learning"*; a list of thirteen grey rows is not an
/// entry point, it is a filing cabinet.
///
/// Each place is built from the same handful of shapes as Tika, and each one carries what
/// its world actually teaches. World 2 is *Encore et encore* — repetition — so its place
/// is a rosace, the figure a loop draws. The picture is the concept, not a mood.
library;

import 'geometry.dart';

/// World 0 — *Bonjour Tika*. A beach at the start of everything: sand, one wave, one sun.
/// Nothing to do yet but arrive.
const world0Beach = Drawing(
  id: 'world0-plage',
  describeFr: 'Une plage au soleil. Tika arrive.',
  describeEn: 'A sunny beach. Tika arrives.',
  shapes: [
    Box(Tint.sky, P(0, 0), P(100, 58)),
    Circle(Tint.sun, P(78, 18), 11),
    Box(Tint.sea, P(0, 46), P(100, 66)),
    Stroke(
        Tint.highlight, [P(6, 58), P(20, 54), P(34, 58), P(48, 54), P(62, 58)],
        width: 2),
    Box(Tint.sand, P(0, 62), P(100, 100)),
    /* Tracks coming up the beach, not pebbles. The first version put two brown ovals on
       the sand and they read as a pair of eyes — the same accident world 1's bushes made.
       A trail has a direction and a cause, which is the whole story of world 0: somebody
       arrived. */
    Oval(Tint.sandLine, P(30, 94), 4, 2.5),
    Oval(Tint.sandLine, P(42, 88), 4, 2.5),
    Oval(Tint.sandLine, P(54, 82), 4, 2.5),
    Oval(Tint.sandLine, P(66, 76), 4, 2.5),
    // A shell where the tracks stop, so the eye has somewhere to land.
    Oval(Tint.shell, P(80, 72), 7, 5),
    Oval(Tint.shellDark, P(80, 72), 3, 2.2),
  ],
);

/// World 1 — *La tortue bouge*. An island with a path across it: the first line a child
/// draws, made into a place.
const world1Island = Drawing(
  id: 'world1-island',
  describeFr: 'Une île avec un chemin qui tourne une fois.',
  describeEn: 'An island with a path that turns once.',
  shapes: [
    Box(Tint.sea, P(0, 0), P(100, 100)),
    // Surf, so the island sits IN the sea rather than on it.
    Oval(Tint.sky, P(50, 58), 44, 34),
    Oval(Tint.sand, P(50, 58), 40, 30),

    /* The path is the first two concepts of the world, drawn: C1.1 goes forward, C1.2
       turns. It is a wide stroke with a rounded cap, so it reads as a track — the first
       version drew a thin line and it read as a flagpole. */
    Stroke(Tint.bark, [P(24, 80), P(56, 80), P(56, 44)], width: 6),

    /* Two trees, not two circles. A trunk and a crown read as vegetation; two bare ovals
       at eye height read as a face, which is what the first version accidentally drew. */
    Stroke(Tint.bark, [P(30, 62), P(30, 52)], width: 3),
    Oval(Tint.leafDark, P(30, 48), 10, 8),
    Stroke(Tint.bark, [P(76, 66), P(76, 58)], width: 3),
    Oval(Tint.leaf, P(76, 54), 8, 7),

    // Where the path ends, which is where the child is going.
    Circle(Tint.mango, P(56, 42), 5),
  ],
);

/// World 2 — *Encore et encore*. A rosace: the figure a nested loop draws, and the one
/// the M5 tutorial ends on.
const world2Rosace = Drawing(
  id: 'world2-rosace',
  describeFr: 'Une rosace : la même figure, encore et encore.',
  describeEn: 'A rosette: the same shape, again and again.',
  shapes: [
    Box(Tint.night, P(0, 0), P(100, 100)),
    /* Eight petals around a centre, drawn as the loop would draw them — and ALTERNATING,
       because eight petals in one flat colour merge into four blobs at card size. The
       alternation is not decoration: it is the repetition count, made countable. */
    Oval(Tint.sea, P(50, 26), 9, 18),
    Oval(Tint.seaDeep, P(67, 33), 9, 18),
    Oval(Tint.sea, P(74, 50), 18, 9),
    Oval(Tint.seaDeep, P(67, 67), 9, 18),
    Oval(Tint.sea, P(50, 74), 9, 18),
    Oval(Tint.seaDeep, P(33, 67), 9, 18),
    Oval(Tint.sea, P(26, 50), 18, 9),
    Oval(Tint.seaDeep, P(33, 33), 9, 18),
    Circle(Tint.sun, P(50, 50), 10),
  ],
);

/// World 3 — *Couleurs et crayon*. Three bands of colour laid down by a pen that is
/// getting wider, because that is literally what `largeurcrayon` does.
const world3Pen = Drawing(
  id: 'world3-crayon',
  describeFr: 'Trois traits de couleur, du plus fin au plus large.',
  describeEn: 'Three colour strokes, from thin to wide.',
  shapes: [
    Box(Tint.sand, P(0, 0), P(100, 100)),
    Stroke(Tint.sea, [P(16, 26), P(84, 26)], width: 3),
    Stroke(Tint.mango, [P(16, 50), P(84, 50)], width: 8),
    Stroke(Tint.hibiscusInk, [P(16, 76), P(84, 76)], width: 14),
    // The pen itself, nib down on the last stroke, so the strokes have a cause.
    Poly(Tint.bark, [P(72, 62), P(84, 50), P(90, 56), P(78, 68)]),
    Poly(Tint.night, [P(72, 62), P(78, 68), P(70, 70)]),
  ],
);

/// World 4 — *Le plan*. A grid with one point on it: `va x,y` is going somewhere named,
/// not somewhere reached by turning.
const world4Grid = Drawing(
  id: 'world4-plan',
  describeFr: 'Un quadrillage avec un point marqué.',
  describeEn: 'A grid with one marked point.',
  shapes: [
    Box(Tint.sand, P(0, 0), P(100, 100)),
    Stroke(Tint.sandLine, [P(25, 6), P(25, 94)], width: 2),
    Stroke(Tint.sandLine, [P(50, 6), P(50, 94)], width: 2),
    Stroke(Tint.sandLine, [P(75, 6), P(75, 94)], width: 2),
    Stroke(Tint.sandLine, [P(6, 25), P(94, 25)], width: 2),
    Stroke(Tint.sandLine, [P(6, 50), P(94, 50)], width: 2),
    Stroke(Tint.sandLine, [P(6, 75), P(94, 75)], width: 2),
    // The axes, heavier than the rulings, crossing at the centre §4 keeps calling home.
    Stroke(Tint.inkLine, [P(50, 6), P(50, 94)], width: 4),
    Stroke(Tint.inkLine, [P(6, 50), P(94, 50)], width: 4),
    // The point, and the two hops that name it.
    Stroke(Tint.sea, [P(50, 50), P(75, 50), P(75, 25)], width: 4),
    Circle(Tint.mango, P(75, 25), 8),
    Circle(Tint.highlight, P(75, 25), 3),
  ],
);

/// World 5 — *Quand…*. The green flag, and two scripts that start together.
const world5Events = Drawing(
  id: 'world5-quand',
  describeFr: 'Un drapeau vert, et deux départs en même temps.',
  describeEn: 'A green flag, and two starts at once.',
  shapes: [
    Box(Tint.sand, P(0, 0), P(100, 100)),
    Stroke(Tint.bark, [P(30, 84), P(30, 20)], width: 5),
    Poly(Tint.leaf, [P(30, 20), P(70, 30), P(30, 42)]),
    Poly(Tint.leafDark, [P(30, 32), P(54, 38), P(30, 42)]),
    /* Two scripts, drawn as two chains of blocks leaving the same flag. "Two at once" is
       the concept the world exists for, so it is the picture. */
    Box(Tint.sea, P(48, 54), P(90, 64), radius: 3),
    Box(Tint.sea, P(48, 68), P(90, 78), radius: 3),
    Box(Tint.mango, P(10, 54), P(42, 64), radius: 3),
    Box(Tint.mango, P(10, 68), P(42, 78), radius: 3),
  ],
);

/// World 6 — *Mes variables*. A labelled box with a number in it, and the number changing.
const world6Variables = Drawing(
  id: 'world6-variables',
  describeFr: 'Une boîte étiquetée qui garde un nombre.',
  describeEn: 'A labelled box holding a number.',
  shapes: [
    Box(Tint.sand, P(0, 0), P(100, 100)),
    // The box: open at the top, because a variable is put into, not sealed.
    Box(Tint.mango, P(22, 44), P(78, 86), radius: 6),
    Box(Tint.mangoDeep, P(22, 44), P(78, 52), radius: 4),
    // The label, as a tag on a string — a name tied to the box, which is the whole idea.
    Stroke(Tint.bark, [P(50, 30), P(50, 44)], width: 3),
    Box(Tint.highlight, P(30, 16), P(70, 32), radius: 4),
    Stroke(Tint.inkLine, [P(36, 24), P(64, 24)], width: 4),
    // What is inside, arriving.
    Circle(Tint.sea, P(38, 66), 8),
    Circle(Tint.seaDeep, P(60, 70), 6),
  ],
);

/// World 7 — *Si… sinon*. A fork: one road in, two roads out, and a lozenge where the
/// question is asked.
const world7Decision = Drawing(
  id: 'world7-si',
  describeFr: 'Un chemin qui se sépare en deux après une question.',
  describeEn: 'A path that splits in two after a question.',
  shapes: [
    Box(Tint.sand, P(0, 0), P(100, 100)),
    Stroke(Tint.bark, [P(50, 92), P(50, 62)], width: 7),
    // The question, as the diamond a boolean slot is shaped like.
    Poly(Tint.sea, [P(50, 36), P(72, 52), P(50, 68), P(28, 52)]),
    Poly(Tint.highlight, [P(50, 44), P(62, 52), P(50, 60), P(38, 52)]),
    // Two ways on, one of them taken. Colour is not the only signal: only one has an end
    // marker, so the "taken" branch survives greyscale.
    Stroke(Tint.leaf, [P(28, 52), P(14, 34), P(14, 14)], width: 6),
    Stroke(Tint.mango, [P(72, 52), P(86, 34), P(86, 14)], width: 6),
    Circle(Tint.leafDark, P(14, 12), 7),
  ],
);

/// World 8 — *Tant que*. A loop that keeps going while something is true — drawn as a
/// circuit with a sensor on it, because a `tantque` with nothing sensed never stops.
const world8While = Drawing(
  id: 'world8-tantque',
  describeFr: 'Une boucle qui continue tant que le capteur voit quelque chose.',
  describeEn: 'A loop that keeps going while the sensor sees something.',
  shapes: [
    Box(Tint.night, P(0, 0), P(100, 100)),
    Stroke(Tint.sea, [
      P(50, 18), P(76, 30), P(82, 56), P(62, 78), P(38, 78), P(18, 56),
      P(24, 30), P(50, 18)
    ], width: 7),
    // The arrow head, so the circuit has a direction rather than being a ring.
    Poly(Tint.sea, [P(50, 10), P(62, 20), P(50, 26)]),
    // The sensor, watching. While it sees, the loop turns.
    Circle(Tint.mango, P(50, 52), 13),
    Circle(Tint.highlight, P(50, 52), 6),
    Circle(Tint.night, P(52, 50), 3),
  ],
);

/// World 9 — *Mes propres blocs*. Four small shapes becoming one named shape: that is
/// `apprends`, and it is also what decomposition looks like.
const world9MyBlocks = Drawing(
  id: 'world9-mesblocs',
  describeFr: 'Des petits blocs qui deviennent un seul bloc nommé.',
  describeEn: 'Small blocks becoming a single named block.',
  shapes: [
    Box(Tint.sand, P(0, 0), P(100, 100)),
    // The parts, loose.
    Box(Tint.sea, P(10, 16), P(34, 30), radius: 3),
    Box(Tint.mango, P(10, 36), P(34, 50), radius: 3),
    Box(Tint.leaf, P(10, 56), P(34, 70), radius: 3),
    // The arrow: many into one.
    Stroke(Tint.inkLine, [P(38, 43), P(54, 43)], width: 4),
    Poly(Tint.inkLine, [P(54, 37), P(64, 43), P(54, 49)]),
    // The whole, with a notch on top and a tab beneath, so it reads as a block you can use.
    Box(Tint.hibiscusInk, P(66, 26), P(94, 62), radius: 5),
    Box(Tint.hibiscusInk, P(74, 20), P(86, 28), radius: 3),
    Box(Tint.hibiscusInk, P(74, 60), P(86, 68), radius: 3),
    Stroke(Tint.highlight, [P(72, 44), P(88, 44)], width: 4),
  ],
);

/// World 10 — *Lutins, costumes, sons*. One character in two costumes, and a sound
/// leaving it.
const world10Sprites = Drawing(
  id: 'world10-lutins',
  describeFr: 'Un lutin avec deux costumes, et un son qui sort.',
  describeEn: 'A sprite with two costumes, and a sound coming out.',
  shapes: [
    Box(Tint.sand, P(0, 0), P(100, 100)),
    // The second costume, behind and faded to a flat tint — the same body, another frame.
    Oval(Tint.sandLine, P(34, 56), 18, 20),
    Circle(Tint.sandLine, P(34, 32), 12),
    // The costume on stage.
    Oval(Tint.shell, P(44, 56), 18, 20),
    Oval(Tint.shellDark, P(44, 56), 18, 20),
    Oval(Tint.shell, P(44, 57), 14, 16),
    Circle(Tint.skin, P(44, 30), 13),
    Circle(Tint.eye, P(40, 28), 3),
    Circle(Tint.eye, P(49, 28), 3),
    // The sound, as the three arcs every speaker icon has used since icons existed.
    Stroke(Tint.mango, [P(70, 44), P(78, 38), P(78, 62), P(70, 56)], width: 4),
    Stroke(Tint.mango, [P(84, 42), P(88, 50), P(84, 58)], width: 3),
    Stroke(Tint.mango, [P(92, 36), P(96, 50), P(92, 64)], width: 3),
  ],
);

/// World 11 — *Je passe au texte*. The same program, twice: blocks on the left, the words
/// they already were on the right. The one-AST rule, drawn.
const world11Text = Drawing(
  id: 'world11-texte',
  describeFr: 'Les mêmes instructions, en blocs et en mots.',
  describeEn: 'The same instructions, as blocks and as words.',
  shapes: [
    Box(Tint.sand, P(0, 0), P(100, 100)),
    Box(Tint.sea, P(8, 20), P(42, 32), radius: 3),
    Box(Tint.mango, P(8, 38), P(42, 50), radius: 3),
    Box(Tint.leaf, P(8, 56), P(42, 68), radius: 3),
    // The bridge: it points both ways, because M3 is a bridge and not a door.
    Poly(Tint.inkLine, [P(46, 44), P(52, 38), P(52, 50)]),
    Poly(Tint.inkLine, [P(78, 44), P(72, 38), P(72, 50)]),
    Stroke(Tint.inkLine, [P(50, 44), P(74, 44)], width: 3),
    // The words. Lines of text, in the same three colours, so the pairing is visible.
    Box(Tint.highlight, P(56, 14), P(96, 74), radius: 4),
    Stroke(Tint.sea, [P(60, 24), P(88, 24)], width: 4),
    Stroke(Tint.mango, [P(60, 42), P(84, 42)], width: 4),
    Stroke(Tint.leaf, [P(60, 60), P(92, 60)], width: 4),
    Box(Tint.night, P(60, 80), P(72, 88), radius: 2),
  ],
);

/// World 12 — *Mon application*. A phone with screens behind it: the last world is where
/// a child stops making a drawing and starts making a thing other people use.
const world12App = Drawing(
  id: 'world12-application',
  describeFr: 'Un téléphone avec plusieurs écrans derrière.',
  describeEn: 'A phone with several screens behind it.',
  shapes: [
    Box(Tint.night, P(0, 0), P(100, 100)),
    // The other screens of the app, fanned behind.
    Box(Tint.seaDeep, P(20, 16), P(62, 84), radius: 8),
    Box(Tint.sea, P(28, 12), P(70, 88), radius: 8),
    // The screen in hand.
    Box(Tint.highlight, P(36, 8), P(80, 92), radius: 9),
    Box(Tint.sand, P(40, 18), P(76, 82), radius: 4),
    // What is on it: a title bar and two rows, which is every app a child will ever build.
    Stroke(Tint.seaDeep, [P(44, 26), P(64, 26)], width: 5),
    Box(Tint.mango, P(44, 38), P(72, 50), radius: 3),
    Box(Tint.leaf, P(44, 56), P(72, 68), radius: 3),
    // The home button, so the phone reads as a phone at 24 px.
    Circle(Tint.night, P(58, 88), 3),
  ],
);

/// The places that exist. A world with no drawing gets its number and a plain card — a
/// placeholder that says "not drawn yet", never a wrong picture.
const worldPlaces = <int, Drawing>{
  0: world0Beach,
  1: world1Island,
  2: world2Rosace,
  3: world3Pen,
  4: world4Grid,
  5: world5Events,
  6: world6Variables,
  7: world7Decision,
  8: world8While,
  9: world9MyBlocks,
  10: world10Sprites,
  11: world11Text,
  12: world12App,
};
