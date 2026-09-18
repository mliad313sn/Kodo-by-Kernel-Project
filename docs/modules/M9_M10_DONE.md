# M9 and M10 — Studio, and the smallest safe social surface · Definition of Done

Package: `packages/kodo_studio` — 35 tests, all passing.

## The acceptance tests

### M9 — Studio

| # | Test | Result |
| --- | --- | --- |
| 1 | Force-kill during an edit loses at most 20 s of work, measured 50 times | Pass — 50 runs, pseudo-random kill points, every one inside the interval, and some runs really did have unsaved work |
| 2 | A project with 6 sprites, 40 costumes and 12 sounds opens in ≤ 4 s on the reference device | **Partial.** What is asserted is that the *format* is not where the budget goes: decoding such a project is under 100 ms in CI, leaving the 4 s for the work that has to happen on glass. **Device measurement owed at G3** |
| 3 | Every recipe is runnable as shipped and localised | Pass — 22 recipes, each parsed and run to `finished` through the real interpreter, each rendered and re-parsed in FR and EN |
| 4 | Export round-trips: an exported project reimports identically | Pass — 6 sprites, 40 costumes, 12 sounds, a custom block and a list, byte-identical re-encode and equal checksum |

### M10 — Sharing, gallery and moderation

| # | Test | Result |
| --- | --- | --- |
| 1 | Adversarial review: personal data through a display name, a title, a thumbnail or an asset — fails on all four | Pass on all four. Display name: 500 generated names, none typed, none scannable. Title: six real attacks refused, and instructions and asset names are scanned too. Thumbnail: renderable only from a canvas, with a fixed title. Asset: an imported asset cannot reach a gallery at all. **Seat 13's own review still owed at G4** |
| 2 | A moderation drill triages 50 synthetic reports within SLA | Pass — 50 reports over a 48-hour window, worked oldest-first at eight minutes a case, every one triaged inside 24 h |
| 3 | Sharing is provably unreachable without the guardian flag, verified by a test | Pass — `ShareableProject` has a private constructor, `SharingGate.share` is the only door, and it checks `Capability.sharing` first. The three consent states are asserted separately |

---

## Defects found while building

| ID | Severity | What was wrong | Why it mattered | Closed by |
| --- | --- | --- | --- | --- |
| `M1-004` | **S2** | `demande` / `ask` returns text and the language had **no conversion**, so `$p = demande "combien ?"` followed by `avance $p` fails. Every counting game — the commonest thing a nine-year-old wants to build — was unwritable | Annex §515 presents the opcode set as complete. An input verb whose result cannot be used is not a feature, it is a trap, and it would have been found by a child in the Studio rather than by us | PO decision **D-011**: `nombre` / `number` (`TO_NUMBER`) added to the opcode set, both keyword tables with the `nb` abbreviation, the interpreter, `BlockHelp` and the annex. A value that will not convert raises the ordinary type error rather than yielding zero |
| `M10-001` | **S2** | The personal-data filter's French keywords never matched. Dart's `\b` is ASCII-only, so `\bécole` cannot match — the character before `é` and `é` itself are both non-word, so there is no boundary there. `école`, `collège`, `lycée` and `j'ai … ans` were all dead patterns | A filter that silently matches nothing is worse than no filter, because it is believed. The `school` and `age` rules were exactly the ones aimed at what a child actually writes in French | An explicit `(?:^\|[^\wÀ-ÿ])` edge, and the six attack strings are asserted individually rather than as a set |

---

## Four things these modules do structurally rather than by policy

**The Studio palette is a constant.** `studioPalette` is `Opcode.values`, and a test asserts
it is *the same object*. The module prompt's `Do not` — do not gate any block behind
progression — is enforced by there being no seam for a filter to be added at: no learner
parameter, no progress argument, nothing to pass.

**Sharing has one door.** `ShareableProject` has a private constructor and private storage;
`SharingGate.share` is the only function that can produce one, and it consults M4's
`ConsentGate` — the same object the parent space writes to, not a copy of the flag —
before anything else. "Off by default" is not a setting; it is what `ConsentGate` returns
when no guardian has answered.

**There is no free-text channel because there is no free-text type.** No comment class, no
message class, no method anywhere that takes a string from one child and shows it to
another. Reactions are a closed enum of four, and none of them can be used to mock: there
is no thumbs-down and no laughing face, because a reaction set is a vocabulary and this one
has no word for it. A test asserts those glyphs are absent.

**A shared card cannot leak an identifier it does not hold.** `ShareableProject` has no
profile id, account id, device id or first name — only a generated display name. The test
encodes a shared item and asserts the string contains none of those words. `RemixCredit`
is the same: it names a display name and a project, and attribution is computed from the
thing being remixed rather than supplied by the remixer, so there is no parameter to get
wrong.

---

## What is owed

| Item | Gate | Note |
| --- | --- | --- |
| Seat 13's own adversarial review | G4 | The four vectors are closed in code; the review is the evidence, and a reviewer will find a fifth |
| A 4-second open on the reference device | G3 | The format is proven cheap. The scene build is not |
| MP4 screen capture | P3 | `FR-M9-05` is desktop-first and is marked *In progress*: the project file, PNG and SVG ship, the recorder does not exist. The export sheet already answers `kindsOn` correctly, so no button is offered that would fail |
| 50 fps drag with 60 blocks in the Studio | G3 | Inherited from M2, and the Studio's palette is larger |
| A human moderation rota that can actually hold 24 h | G4 | The SLA is modelled and the console exists. Whether anybody is on the other end is an operations commitment, not a code one |
