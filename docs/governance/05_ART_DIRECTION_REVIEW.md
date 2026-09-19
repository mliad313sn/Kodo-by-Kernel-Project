# Art direction review — KODO visual universe

**Owner.** Seat A1, Art Director, under the Product Owner.
**Reviewed.** `packages/kodo_art` (the universe) and `app/` (where it is shown).
**Method.** Build the web target, open it at 360 × 740, and *look at every screen*.
**Date.** 2026-09-19 · **Decision of record.** `D-013` · **Requirements.** `FR-M20-01` … `06`

---

## Why this document exists

Every other quality in this programme is asserted by a test that fails. Appearance is the
one that is not, because the failure mode is *"a child does not want to open it"* and no
assertion has ever detected that. So the committee's method is the oldest one there is:
render it, look at it, and write down what is wrong.

Nine of the eleven findings below were invisible to the test suite when they were found.
Every one of them was found by looking. Where a finding could be turned into an assertion
afterwards, it was — the fourth column says which test now holds the line, so the same
mistake cannot come back through a refactor.

---

## Findings

| # | Where | What was actually on the screen | Fixed by, and what now holds it |
| --- | --- | --- | --- |
| **A-001** | Tika, stage pose | At 120 px she read as **an avocado**. Her legs were drawn under the shell oval and painted over by it. | Legs moved outside the shell silhouette; dark rim added. `her legs are outside her shell` |
| **A-002** | Tika, portrait | Two stacked circles read as **a snowman**. | Shell redrawn as a rim behind the head. Superseded by A-009. |
| **A-003** | World 1 | Two bare ovals at eye height on an island read as **a face**. | Trees with trunks and crowns. `every shape stays inside the drawing box` + review |
| **A-004** | Own test | The first legibility test capped a drawing at ten shapes. Wrong metric: the rim that made Tika *more* legible took her to sixteen. | Assert minimum **feature size** at the size actually shown, and byte budget separately. `Tika reads at 24 px` |
| **A-005** | Carte | Thirteen worlds, three drawings. The map was a **filing cabinet with three pictures in it**. | Ten worlds drawn, each carrying what its world teaches. `all thirteen worlds are places` |
| **A-006** | Carte, world 2 | Eight petals in one flat colour merged into **four blobs** at card size. | Petals alternate `sea` / `seaDeep` — the alternation *is* the repetition count, made countable. Review |
| **A-007** | Carte, world 0 | Two brown ovals on sand read as **a pair of eyes**. The same accident as A-003, in a different world. | Replaced with a trail of tracks and a shell: a trail has a direction and a cause, which is world 0's whole story. Review |
| **A-008** | Bottom bar | *Entraînement* broke as **"Entraîneme / nt"**. Twelve characters into a ten-character tab. | Label ruling in `D-013`; the slot is now measured in `m15_m16_acceptance_test.dart`. `zero truncation at 140 %` |
| **A-009** | Tika, portrait & thinking | At 120 px she read as **a green smiley ball**. A shell drawn as a rim *around* a head is, from the front, a circle. | Redrawn as a dome with a head rising out of it, scutes, and two flippers. Review + `the stage Tika has no face` |
| **A-010** | Profile picker | The first screen a child ever meets was **one word in the corner of a white page** — the visual language of a settings dialog. | Tika, a question, and cards. Review |
| **A-011** | Every screen | The art existed in a package and reached **no screen at all**. A folder of SVGs is not a product. | `FR-M20-03` and a widget test that walks every `Art` on every screen. `the universe reaches the child` |

---

## Rulings that now bind the committee

1. **Colour is a role, never a hex.** `Tint.sandLine` is *a ruling on sand*, not a brown.
   High contrast re-resolves roles; it never swaps a palette, so a child who turns it on
   still recognises the world they were in a moment ago (`FR-M20-04`).
2. **Colour is never the only signal.** Every distinction a child must make survives
   greyscale: Tika's heading is a notch *and* a tail, the taken branch of world 7 has an
   end marker, a locked world card has an icon.
3. **One geometry, two projections.** Nobody hand-draws a second copy of anything
   (`FR-M20-02`). This is the one-AST rule, applied to pictures.
4. **Every picture speaks.** A drawing carries the sentence a screen reader says, in both
   languages, authored by a person (`FR-M20-03`). An illustration a screen reader skips
   gives the emptiest screen to the child who needs it most.
5. **The picture is the concept, not a mood.** World 2 teaches repetition, so its place is
   a rosace — the figure a loop draws. A child should be able to guess what a world is
   about from its card before reading its name.
6. **Tika never judges.** She appears where a child is spoken to and nowhere a child is
   assessed (`FR-M20-06`, §10). The stage pose has no face at all: a character who smiles
   when a program runs looks disappointed when it does not, and a child starts performing
   for her.
7. **Motion needs a reason.** Causality, continuity or feedback — decoration is not a
   reason. Every animation has a reduced form that is not *nothing*, and none runs longer
   than 320 ms (`FR-M20-05`).

---

## Still open

| # | Item | Waiting for |
| --- | --- | --- |
| A-O1 | Worlds 3–12 have places drawn but no content behind them | The authoring runs for worlds 3–12 (948 items) |
| A-O2 | Badges, stars and the avatar of §9.1's *Moi* are unillustrated | M8's motivation set, which is specified but not drawn |
| A-O3 | The block palette uses Material icons, not KODO's own | Seat A4; the ten family silhouettes are decided in code (`block_family.dart`) and the icons can now be drawn against them |
| A-O4 | No pose of Tika has been shown to a child | The first playtest, which is G4's, not G3's |
