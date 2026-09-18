# M2 and M3 — Block editor, text editor, and the bridge · Definition of Done

## The acceptance tests

### M2 — Block editor

| # | Test | Result |
| --- | --- | --- |
| 1 | Two children aged 8 place five blocks and run them, unassisted, in three minutes | **Owed — pass-3 evidence.** The module prompt itself marks this *"evidence, not an automated test — record it"*. What is automated is that the task takes five taps and no gesture |
| 2 | Drag holds ≥ 50 fps with 60 blocks on the reference device | **Owed** — needs the device |
| 3 | Every block has help in FR and EN; a coverage test fails the build otherwise | Pass — 41 opcodes, every one with a summary in both languages and a runnable three-line example that is parsed by the test |
| 4 | Colour-blind simulation: every family distinguishable with colour removed | Pass — asserted over all 45 pairs |
| 5 | An exercise configured for World 1 exposes exactly 7 opcodes | Pass |
| 6 | Undo 50, redo 50, byte-identical AST | Pass |

### M3 — Text editor and the bridge

| # | Test | Result |
| --- | --- | --- |
| 1 | 5 000 random edit sequences with toggles interleaved; never lost, never silently altered | Pass |
| 2 | Toggle latency ≤ 100 ms for a 200-node program | Pass on CI (well under 10 ms); **device measurement owed** |
| 3 | Every M1 error code renders as a child-language message with a line marker | Pass — all 22 codes, both languages |
| 4 | Keyword-language switch mid-edit preserves cursor and selection | Pass |
| 5 | An 11-year-old types a five-line program on a phone in under four minutes | **Owed — pass-3 evidence** |
| 6 | Contrast audit of every highlight colour, light and dark | Pass — 13 categories × 2 themes, all ≥ 4.5:1 |

34 tests.

---

## Defects found while building

| ID | Severity | What was wrong | Why it mattered | Closed by |
| --- | --- | --- | --- | --- |
| `M3-001` | **S1** | `EditorController` re-rendered its initial source from the parsed tree. A parse error drops the offending statement, so opening a saved file with a typo in it deleted that whole line — silently | This is data loss disguised as tidiness, and it is exactly what the M3 prompt's `Do not` forbids: *do not auto-correct a child's code*. A child would reopen yesterday's work with a line gone and no way to know why | The child's text is kept verbatim; only an empty source is rendered from the tree. A test opens a three-line program with a typo and asserts all three lines survive |
| `M2-001` | S2 | Palette family tabs rendered at 44 dp | `FR-M2-07` and §9.3 set the floor at 48 dp, and workbook finding `G4-003` records two eight-year-olds who could not hit a block on a five-inch screen and both abandoned. Four pixels is the whole of that finding | The tab row is sized to the target plus its padding, and a test measures every `BlockChip` in the tree |
| `M3-002` | S3 | The error panel's `ListTile` sat inside a `ColoredBox`, so touch feedback was swallowed | On a phone the ink splash is the only confirmation a child gets that their tap landed | The panel is a `Material` |

---

## Two things this module does structurally rather than by policy

**The block editor and the text editor share one controller and one AST.** The toggle is a
change of *view*, not a conversion, which is why `FR-M3-05`'s promise — the toggle never
loses a program — can be kept rather than defended. The 5 000-sequence loss test is cheap
to pass because there is nothing in the design that could lose anything.

**Tap-to-place is the primary interaction, and dragging is offered on top of it.** The
module prompt makes tap-to-place an *equal-status* alternative; workbook finding `G4-003`
is what happens when it is treated as a fallback. Every widget test here places blocks by
tapping, because that is the path a child on the reference device actually takes.

---

## Definition of Done (§14.1)

| # | Criterion | Verdict |
| --- | --- | --- |
| 1 | Numbered requirements verified by named tests | **Met for what is claimed.** 15 of 19 M2/M3 requirements are Done; `FR-M2-05`, `FR-M2-06`, `FR-M3-06` and `FR-M3-08` are honestly Not started |
| 2 | Works offline on the reference device | **Partly** — no network path exists; not measured on the device |
| 3 | FR and EN, 100 % strings | **Met** — block help, family names and every error message; a coverage test fails the build |
| 4 | Accessibility checklist | **Partly** — contrast, 48 dp targets and screen-reader labels are tested. Keyboard-only operation (`FR-M16-04`) and reduced motion are **not built** |
| 5 | Three children, unassisted, observed | **Not met.** This is the gating item for M2 and M3 and no amount of widget testing substitutes for it |
| 6 | Telemetry events fire | **Partly** — `EditEvent` carries `bridge_toggled` and `keyword_locale_changed`; the taxonomy is M17's |
| 7 | Failure modes child-legible | **Met** — the panel renders M1's catalogue, and a test asserts no machine text and no unfilled placeholder in either language |
| 8 | No open S1 or S2 | **Met** — `M3-001` and `M2-001` are closed with tests |
| 9 | Pedagogical and localisation review | **Outstanding** — the 41 block-help entries are content and nobody has read them |
| 10 | Rollback path | **Met** — no persisted state; the editor is a view over an AST |

## Outstanding, and owned

| ID | What | Owner | Due |
| --- | --- | --- | --- |
| `M2-PANEL-01` | Six children, two per age band, observed placing five blocks and typing five lines on the reference phone | Seats 7, 5, 14 | **Before G3 can close** |
| `M2-PERF-01` | 50 fps drag with 60 blocks, and cold start, on Android 11 / 2 GB | Seat 9 | G3 |
| `M2-002` | Dropdown parameters (`FR-M2-05`) and grab-a-stack-by-its-top-block (`FR-M2-06`) | M2 squad | G3 |
| `M3-003` | Keyword autocomplete with the English equivalent from World 9 (`FR-M3-06`) | M3 squad | Before World 9 |
| `M3-004` | Export as text and as an image of the code (`FR-M3-08`) | M3 squad | G4 |
| `M2-A11Y-01` | Keyboard-only block placement on desktop (`FR-M16-04`) and reduced motion (`FR-M16-03`) | Seat 7 | G4 |
| `M2-REV-01` | Pedagogical and localisation review of all 41 block-help entries | Seats 3, 11 | Before a child sees them |
