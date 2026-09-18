# Worlds 0 and 2 · Definition of Done

`content/world0.json` — 80 items, 4 tutorials, 270 kB.
`content/world2.json` — 86 items, 4 tutorials, 318 kB.

With World 1 that is **266 items across 13 concepts** — 21 % of the 1 214 the curriculum
commits, and the three worlds a child actually meets first.

| | Committed (§6.3) | Shipped | Types per concept (§6.1 needs 5) |
| --- | --- | --- | --- |
| C0.1 Lancer un programme | 18 | 21 | 6 |
| C0.2 Séquence | 20 | 23 | 6 |
| C0.3 Ordre des instructions | 18 | 18 | 5 |
| C0.4 Annuler / recommencer | 18 | 18 | 5 |
| C2.1 Répète n fois | 22 | 24 | 6 |
| C2.2 Le corps de la boucle | 22 | 22 | 6 |
| C2.3 Boucles imbriquées | 22 | 22 | 5 |
| C2.4 Boucle ou copier-coller | 18 | 18 | 5 |

Each world's author tool refuses to write the pack unless every item passes M6's publish
gate, every tutorial passes M5's content gate, every concept has five item types and the
§6.3 volume is met. The shipped JSON is then re-checked by
`test/worlds_0_2_acceptance_test.dart`, because the thing that ships and the thing that was
checked have to be the same thing.

---

## What the publish gate caught, and what it taught

Thirty-four authoring faults were refused before anything was written. Four of them are
worth recording, because they are not typos — they are the same mistake in four costumes,
and the mistake is **authoring an item whose wrong answer is not actually wrong**.

| What was authored | Why it passed when it should not have | What it is now |
| --- | --- | --- |
| C2.1's first loops: *"go forward, n times"* | `répète n { avance s }` draws **one straight line** of length `n × s`. Three dashes and five dashes are the same picture at different lengths — the count the concept is about is invisible to the child and to the grader, and at the canvas edge two different counts clip to the same pixels | A dashed line: pen down, forward, pen up, forward. Every turn round the loop leaves a mark you can count |
| The off-by-one bug, `répète 5` where `répète 4` was meant | Round a **closed** polygon, one extra turn retraces the first side. The drawing is byte-identical; only the turtle's final pose differs | `requireFinalPose: true`, which is exactly what that flag is for |
| C2.2's *"forward h, then back h"* flourish in the loop body | A line drawn and then retraced leaves the same pixels **and** the same pose. The extra body lines the concept is about were ungradable | A zigzag: every line in the body goes somewhere new |
| `tournedroite 90` listed as a wrong answer, in an item whose shape has four sides | It is the right answer. Asserting it wrong would have taught the grader to fail a correct child | The wrong angle is derived from the right one, never written as a constant |

The same class of fault appeared in World 0 twice more: two parameter rows where the two
side lengths were equal, so *"swap the two forward blocks"* produced the identical program;
and pen-order items where the pen starts down, so putting it down late changes nothing.

None of these would have been caught by reading the items. All of them were caught by
running the grader over every authored wrong answer, which is what the gate is.

---

## Two things the worlds do that World 1 did not have to

**World 0 is a five-block palette and a twelve-word sentence.** A test asserts both over
every item: no item offers more than five blocks, and no *sentence* in any prompt exceeds
§4.2's twelve words, in either language. Fourteen prompts were rewritten to meet it — they
read better for it, which is the usual outcome.

**The concept graph is now checkable for real.** With three worlds present, the graph has
one root (`C0.1`), every prerequisite names a concept that exists, no edge points forward
into a later world, and every one of the thirteen concepts is reachable from the root. A
curriculum with two starting points has no first lesson; a test now says so.

---

## What is owed

| Item | Gate | Note |
| --- | --- | --- |
| ~15 MB of narration for both worlds | G3 | 184 + 196 recording keys ship; the audio does not. Both worlds are at ~60 % of the 12 MB budget once it arrives |
| A six-year-old through World 0, unassisted | G3 | The reading level is enforced; whether a pre-reader can start is a child run |
| Worlds 3–12 | P2/P3 | 948 items remain of the 1 214 the curriculum commits |
| Illustration (`art/world0-plage.svg`, `art/world2-rosace.svg`) | G3 | Named by the packs, not yet drawn |
