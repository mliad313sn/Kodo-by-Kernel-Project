# G3 — Build & integrate · Assessment

**Exit criterion, verbatim (§1.4):** *"Vertical slice (one full world, block + text, graded,
offline) running on the reference low-end device."*

**Verdict: met in every part except the last four words.** Everything the criterion names
exists, is built, and is tested. Nobody has run it on an Android 11 phone with 2 GB of RAM,
because this delivery had no such phone. **G3 does not close on this document.** It closes
when seat 14 runs the slice on the device and records what happened.

That is not a formality. Six of the thirty-two open requirements are performance numbers,
and a performance number that has never been measured is a guess whatever the CI timings
say.

---

## The criterion, clause by clause

| Clause | Verdict | Evidence |
| --- | --- | --- |
| **one full world** | **Exceeded** — three | `content/world0.json` (80 items), `world1.json` (100), `world2.json` (86). 266 items over 13 concepts, every concept at or above its §6.3 commitment and using ≥ 5 item types. Each pack re-verified from the shipped JSON in `packages/kodo_content/test/` |
| **block + text** | Met | One AST, two projections. 500 random programs survive a keyword-language switch byte-for-byte; 5 000 random edit sequences with toggles interleaved lose nothing. `packages/kodo_app` (M2/M3) and `packages/kodo_lang` (M1) |
| **graded** | Met | M6 grades three signals against the real interpreter. Every one of the 266 shipped items passes the publish gate — including three wrong solutions that must fail and two alternative correct ones that must pass, run through the grader at authoring time and again over the shipped JSON |
| **offline** | Met | `FR-M14-01`, the module prompt's *"single most important test in the programme"*: World 1 is worked to mastery with no network in `m5_m14_acceptance_test.dart`. No pack contains a `http://` or `https://` string — asserted for all three worlds |
| **running on the reference low-end device** | **Not met** | No device was available. See below |

---

## What is built

18 of 18 modules, 11 packages, ~28 000 lines of Dart, **441 tests, all passing.**

| Module | Package | Tests |
| --- | --- | --- |
| M1 language core | `kodo_lang` | 103 |
| M2 block editor · M3 text editor | `kodo_app` (Flutter) | 34 |
| M4 canvas and stage | `kodo_stage` | 39 |
| M5 tutorials · M14 content packs | `kodo_content` | 52 |
| M6 grading | `kodo_grader` | 36 |
| M7 progression and mastery | `kodo_progress` | 27 |
| M8 motivation · M17 telemetry | `kodo_insight` | 30 |
| M9 Studio · M10 sharing and moderation | `kodo_studio` | 35 |
| M11 parent space · M13 accounts and sync | `kodo_account` | 27 |
| M12 classroom · M18 authoring CMS | `kodo_school` | 31 |
| M15 localisation · M16 accessibility | `kodo_access` | 27 |

**Requirements: 98 of 130 Done**, each named by a test — enforced in CI by
`tools/trace_check.dart`, which fails the build if a requirement claims Done without one.

---

## The 32 that are not Done, grouped by what they are actually waiting for

Nothing here is waiting on a decision or on someone's time. Each group is waiting on a
thing this delivery did not have.

### 1. A phone (12)

`NFR-PERF-01…03`, `NFR-SIZE-01`, `NFR-BATT-01`, `NFR-REL-01`, `NFR-OFF-01`,
`FR-M6-07`, `FR-M4-02`, `FR-M4-07`, `FR-M14-02`, `NFR-COMP-01`.

Cold start, frame rate, interpreter throughput, install size, battery, crash-free rate,
the 72-hour offline soak, the 1.2 s item-player load, zoomable vector rendering, the
step-execution highlight, the 12 MB pack budget *with audio present*, the device matrix.
CI measures what it can — the interpreter runs 50 000 steps a second headlessly, World 1
decodes in under 100 ms, every pack is 2–3 % of its budget before audio — but a number
measured on this machine is not a number measured on a 2 GB Android 11 phone, and saying
otherwise is how a product ships slow.

### 2. A platform API Flutter has to reach (7)

`FR-M2-05` (dropdown parameters), `FR-M4-04` (backdrop import), `FR-M4-05` (sound library,
MP3/WAV import, microphone recording), `FR-M9-05` (MP4 screen capture), `FR-M14-03` (pack
download on Wi-Fi), `FR-M3-06` (autocomplete), `FR-M3-08` (export code as an image).

The consent gate these sit behind is built and tested (`Capability.microphone`,
`Capability.imageImport`; the camera is permanently unreachable per `D-007`). What is
missing is the plumbing to the device.

### 3. A gesture on a real screen (4)

`FR-M2-04` (editable literals including negatives), `FR-M2-06` (grab a stack by its top
block), `FR-M2-07` (pinch-zoom, bottom-sheet palette, one-handed layout), `FR-M4-08`
(ghosted future-path overlay).

Tap-to-place is built and is the primary interaction; the 48 dp floor is enforced by a
widget test after defect `M2-001`. Drag, pinch and long-press need fingers.

### 4. An external human (5)

`NFR-A11Y-01` (the external accessibility audit before public launch), `NFR-SEC-01`
(security review), `FR-M6-06` (T9 rubrics shown to children and validated),
`FR-M5-02` (the ghost-block animation, which needs the illustrator), `NFR-MAINT-01`.

### 5. A deliberate v1 scope decision, recorded (4)

`FR-M15-02` — Wolof interface at v1.2, Wolof keywords research only (`D-002`).
`FR-M3-09` — the Python projection is built and tested but is World 12 only, and World 12
does not exist yet (`D-005`).
`NFR-I18N-01`, `NFR-COST-01` — the latter is open item `O-01`, awaiting the licence model
priced against real school counts.

---

## What the build found that a review would not have

Nine defects were found by building, eight of them by a gate refusing to let something
ship. They are listed in full in each module's `docs/modules/*_DONE.md`. The four that
would have reached a child:

| ID | What it was |
| --- | --- |
| `M3-001` (S1) | The editor re-rendered a child's saved file from the parsed tree, so reopening yesterday's work with a typo in it **deleted that line silently**. Data loss disguised as tidiness |
| `M12-001` (S2) | Two pupils named Awa both displayed as `Awa P.` — every id starts `pupil-`. The one screen whose job is to tell a teacher which of 35 children needs help showed two of them as the same person |
| `M16-001` (S2) | The status line broke at **110 %** text scale, against a 200 % commitment. A child who turns text up to read it at all would lose the line that says *"I stopped your program"* |
| `M15-001` (S2) | A screen-reader label built as `'Famille ${name}'` — a blind English-speaking child would hear *"Famille Move"* |

And one that would have reached the curriculum: `M1-004`, where `demande`/`ask` returns
text and the language had **no way to make it a number**, so no child could write a
counting game. Closed by PO decision `D-011`, which adds `nombre`/`number` to the opcode
set — the only addition to the frozen Annex §515 list in this delivery.

---

## Recommendation to seat 14

Close G3 when, and only when, this has been done on an Android 11 phone with 2 GB of RAM:

1. Install the base app and one world pack. Record the install size against
   `NFR-SIZE-01` (25 MB app, 12 MB world).
2. Cold-start to the first item. Record against `NFR-PERF-01`.
3. Work five World-1 items block-side and five text-side, with aircraft mode on for the
   whole session. Record the item-player load time (`FR-M6-07`, 1.2 s) and any frame drop.
4. Leave it in aircraft mode for 72 hours, come back, and finish a concept to mastery
   (`NFR-OFF-01`).
5. Log every hesitation over eight seconds, per the §19 review prompt.

Anything that fails is a G3 finding and is fixed before G4, not logged for later. Anything
that passes gets its number written into `spec/status_overrides.json`, which is the only
place a requirement's status may change.
