/// Tika.
///
/// A green turtle, seen from above, because that is how a child sees her on the canvas:
/// turtle graphics have been top-down since Papert, and a character drawn in profile for
/// the menus and from above on the stage is two characters.
///
/// **Design constraints, and each one is a refusal of something easier.**
///
/// *She has no mouth on the stage.* A face that smiles when a program runs is a face that
/// looks disappointed when it does not, and §10 forbids loss framing. The stage Tika is a
/// tool — a cursor with a heading. The *portrait* Tika, who appears beside a hint or a
/// tutorial line, does have a face, because there she is speaking to the child rather than
/// judging their work.
///
/// *Her heading is visible without colour.* The shell notch points the way she faces. A
/// child who cannot tell green from brown still knows which way she will move, and that is
/// `FR-M16-01` applied to the one glyph the whole product turns on.
///
/// *She is drawn from nine shapes.* At 24 px in a palette row she must still read as a
/// turtle; detail that disappears below 48 px is detail that costs bytes and gives
/// nothing.
library;

import 'geometry.dart';

/// Tika on the stage: top-down, heading up, no face.
///
/// The coordinate space is 0–100 with (50, 50) at her centre and *up* meaning heading 0,
/// so the painter rotates around the centre and nothing else has to know about angles.
const tikaTopDown = Drawing(
  id: 'tika',
  describeFr: 'Tika, la tortue verte, vue de dessus.',
  describeEn: 'Tika the green turtle, seen from above.',
  shapes: [
    // Legs, placed so they stand CLEAR of the shell on both sides. The first version put
    // them under it and drew a turtle with no legs — at 120 px she read as an avocado.
    Oval(Tint.skinDark, P(20, 34), 11, 8),
    Oval(Tint.skinDark, P(80, 34), 11, 8),
    Oval(Tint.skinDark, P(20, 72), 11, 8),
    Oval(Tint.skinDark, P(80, 72), 11, 8),
    Oval(Tint.skin, P(21, 34), 9, 6),
    Oval(Tint.skin, P(79, 34), 9, 6),
    Oval(Tint.skin, P(21, 72), 9, 6),
    Oval(Tint.skin, P(79, 72), 9, 6),

    // Tail, opposite the head — the second heading cue.
    Poly(Tint.skinDark, [P(50, 86), P(44, 96), P(56, 96)]),

    // Head, proud of the shell and large enough to be a head rather than a bump.
    Circle(Tint.skinDark, P(50, 17), 14),
    Circle(Tint.skin, P(50, 16), 12),

    // The shell, with a dark rim so the silhouette holds at 24 px and in greyscale.
    Oval(Tint.shellDark, P(50, 56), 27, 29),
    Oval(Tint.shell, P(50, 56), 24, 26),

    // The notch: a wedge cut toward the head. Heading survives colour blindness and
    // greyscale, because it is a shape.
    Poly(Tint.shellDark, [P(50, 30), P(38, 50), P(62, 50)]),

    // Scutes — three plates, enough to read as a shell and no more.
    Oval(Tint.shellDark, P(50, 60), 14, 15),
    Oval(Tint.shell, P(50, 60), 9, 10),
  ],
);

/// Tika's portrait: face on, with eyes and a mouth, for the moments she is speaking.
///
/// Used beside a tutorial line (M5) and beside a hint (M6). Never beside a verdict — a
/// character who reacts to a wrong answer is a character a child starts performing for.
const tikaPortrait = Drawing(
  id: 'tika-portrait',
  describeFr: 'Tika te regarde et sourit.',
  describeEn: 'Tika is looking at you and smiling.',
  shapes: [
    /* Second redraw, and again because somebody looked: at 120 px the previous version
       read as a green smiley ball. The shell was a RIM around the head, which from the
       front is indistinguishable from a circle. A turtle seen from the front is a DOME
       with a head rising out of it and two flippers at the sides, so that is what this
       is — and the silhouette now survives being shrunk, which a ball never did. */

    // The shell: a dome, wider than she is, sitting low.
    Oval(Tint.shellDark, P(50, 68), 42, 30),
    Oval(Tint.shell, P(50, 69), 37, 25),
    // Three scutes, so the dome reads as a shell and not as a hill.
    Stroke(Tint.shellDark, [P(50, 46), P(50, 92)], width: 2.4),
    Stroke(Tint.shellDark, [P(22, 62), P(38, 70)], width: 2.4),
    Stroke(Tint.shellDark, [P(78, 62), P(62, 70)], width: 2.4),

    // Flippers, at the sides where they show against the sand.
    Oval(Tint.skinDark, P(13, 74), 11, 8),
    Oval(Tint.skin, P(13, 73), 9.5, 6.5),
    Oval(Tint.skinDark, P(87, 74), 11, 8),
    Oval(Tint.skin, P(87, 73), 9.5, 6.5),

    // Neck and head, rising out of the shell.
    Oval(Tint.skinDark, P(50, 52), 15, 14),
    Oval(Tint.skinDark, P(50, 32), 26, 25),
    Oval(Tint.skin, P(50, 31), 24, 23),

    // Eyes: whites, pupils, then a highlight. The highlight is what makes a circle look
    // alive; without it she reads as a button.
    Circle(Tint.highlight, P(39, 27), 8.5),
    Circle(Tint.highlight, P(61, 27), 8.5),
    Circle(Tint.eye, P(40, 28), 4.3),
    Circle(Tint.eye, P(60, 28), 4.3),
    Circle(Tint.highlight, P(41.5, 26), 1.7),
    Circle(Tint.highlight, P(61.5, 26), 1.7),

    // A smile, as a stroke so the thinking pose can swap it.
    Stroke(Tint.eye, [P(42, 41), P(50, 46), P(58, 41)], width: 2.6),
  ],
);

/// Tika thinking. Shown while a program runs, and beside a hint.
///
/// The difference from the portrait is the mouth and one raised eye — not a frown. She is
/// *working*, which is what a child is doing too.
const tikaThinking = Drawing(
  id: 'tika-thinking',
  describeFr: 'Tika réfléchit.',
  describeEn: 'Tika is thinking.',
  shapes: [
    Oval(Tint.shellDark, P(50, 68), 42, 30),
    Oval(Tint.shell, P(50, 69), 37, 25),
    Stroke(Tint.shellDark, [P(50, 46), P(50, 92)], width: 2.4),
    Stroke(Tint.shellDark, [P(22, 62), P(38, 70)], width: 2.4),
    Stroke(Tint.shellDark, [P(78, 62), P(62, 70)], width: 2.4),
    Oval(Tint.skinDark, P(13, 74), 11, 8),
    Oval(Tint.skin, P(13, 73), 9.5, 6.5),
    Oval(Tint.skinDark, P(87, 74), 11, 8),
    Oval(Tint.skin, P(87, 73), 9.5, 6.5),
    Oval(Tint.skinDark, P(50, 52), 15, 14),
    Oval(Tint.skinDark, P(50, 32), 26, 25),
    Oval(Tint.skin, P(50, 31), 24, 23),
    Circle(Tint.highlight, P(39, 27), 8.5),
    Circle(Tint.highlight, P(61, 27), 8.5),
    // Looking up and to one side. Working, not worried.
    Circle(Tint.eye, P(41, 24), 4.3),
    Circle(Tint.eye, P(62, 23), 4.3),
    Circle(Tint.highlight, P(42.5, 22), 1.7),
    Circle(Tint.highlight, P(63.5, 21), 1.7),
    // A small flat mouth, slightly off-centre. Neutral, never sad.
    Stroke(Tint.eye, [P(44, 43), P(55, 42)], width: 2.6),
  ],
);

/// Every pose, by id.
const tikaPoses = <String, Drawing>{
  'tika': tikaTopDown,
  'tika-portrait': tikaPortrait,
  'tika-thinking': tikaThinking,
};
