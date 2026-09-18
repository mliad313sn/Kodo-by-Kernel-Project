# KODO

An all-in-one learn / practise / build coding environment for children aged 8 to 11, on
phone, tablet and desktop, in French and English, **online and offline**.

A child starts in blocks and can see, at any moment, the same program as text in their own
language — and from World 11, the same program again in English. That toggle is not a
feature of the product; it is the product.

**Reference device: Android 11, 2 GB RAM, 5.5", no reliable internet.** If a feature does
not work there, it does not ship.

---

## Where things are

| Path | What it holds |
| --- | --- |
| `docs/spec/` | The Committee's issued specification — cahier des charges v1.0, the curriculum workbook, the 18 module build prompts. The originals are in `_source/` |
| `docs/governance/` | The Product Owner's decision register, the gate register, ways of working |
| `docs/modules/` | One Definition-of-Done record per module, with its defects and what is still owed |
| `spec/` | The specification as data: 130 requirements, 58 concepts. Generated from the workbook, checked by CI |
| `packages/` | **All eighteen modules**, in eleven packages. `kodo_lang` (M1) is pure Dart, and so is everything except `kodo_app`, so the language core, the grader and the mastery rule can be reasoned about without a UI toolkit in the way |
| `content/` | The three authored worlds — 266 items, 13 concepts. Re-authored through the publish gate in CI and then diffed |
| `delivery/meridian/` | The programme as a Meridian portfolio, generated from `spec/`. Meridian is the delivery system of record (PO decision D-009) |
| `docs/reports/` | Reports to other parties, including the Meridian product report |
| `tools/` | `gen_spec.py` regenerates `spec/`; `meridian_book.py` regenerates the portfolio; `trace_check.dart` is the traceability gate |

## Status

**All eighteen modules are built.** Eleven packages, ~28 000 lines of Dart, **441 tests
passing**, 100 of 130 requirements Done and every one of them named by a test — enforced in
CI, which fails the build if a requirement claims Done without one.

| Gate | State |
| --- | --- |
| G0 Mandate | Done |
| G1 Cahier des charges | **Closed** — Annex E answered, D-001 … D-011 |
| G2 Module prompts | **Closed** — M1's interface contract frozen |
| G3 Build & integrate | **Build complete, gate open.** Its criterion is *"vertical slice (one full world, block + text, graded, offline) running on the reference low-end device"*. Every clause is met and tested except the last four words — nobody has run it on an Android 11 phone with 2 GB of RAM. See [`docs/governance/03_G3_ASSESSMENT.md`](docs/governance/03_G3_ASSESSMENT.md) |
| G4 Deep review | Not started |
| G5 Market challenge | Not started |

| Module | Package | Tests | Module | Package | Tests |
| --- | --- | ---: | --- | --- | ---: |
| M1 language core | `kodo_lang` | 103 | M9 · M10 Studio, sharing | `kodo_studio` | 35 |
| M2 · M3 editors and the bridge | `kodo_app` | 34 | M11 · M13 parent space, accounts | `kodo_account` | 27 |
| M4 canvas and stage | `kodo_stage` | 39 | M12 · M18 classroom, CMS | `kodo_school` | 31 |
| M5 · M14 tutorials, packs | `kodo_content` | 52 | M15 · M16 localisation, access | `kodo_access` | 27 |
| M6 grading | `kodo_grader` | 36 | M7 progression and mastery | `kodo_progress` | 27 |
| M8 · M17 motivation, telemetry | `kodo_insight` | 30 | | | |

**Content:** Worlds 0, 1 and 2 — 266 items over 13 concepts, every concept at or above its
§6.3 commitment and using at least five item types. 948 items remain of the 1 214 the
curriculum commits.

**The 30 open requirements**, grouped by what each is actually waiting for: 12 a phone,
7 a platform API, 4 a gesture on a real screen, 5 an external human, 4 a recorded v1 scope
decision. None is waiting on a decision nobody has taken.

Build order is frozen by PO decision D-008: **M1 → M4 → M2 → M3 → M5 → M6 → M7**, then
M14, M13, M8, M11, M9, M18, M12, M10, M15, M16, M17. M1 is first because risk `R3` —
dual-representation round-tripping — carries the joint-highest exposure in the register,
and its recorded response is to prototype the round-trip before anything else.

## Running it

```bash
# every pure-Dart package
for p in packages/*/; do (cd "$p" && dart pub get && dart analyze && dart test); done
# the Flutter one
cd packages/kodo_app && flutter pub get && flutter test && cd ../..

dart tools/trace_check.dart               # requirement traceability — a gate, not a report
python3 tools/gen_spec.py                 # regenerate spec/ from the Committee's workbook
python3 tools/meridian_book.py            # regenerate the Meridian portfolio from spec/

# re-author the content. Each tool refuses to write a pack unless every item passes the
# publish gate and every tutorial passes the content gate.
cd packages/kodo_content
dart run tool/author_world0.dart && dart run tool/author_world1.dart && dart run tool/author_world2.dart
```

```dart
import 'package:kodo_lang/kodo_lang.dart';

final result = parse('répète 4 { avance 100 tournegauche 90 }', KeywordTables.fr);
final canvas = HeadlessCanvas();
runProgram(result.program, canvas);

print(render(result.program, KeywordTables.en));
// repeat 4 {
//   forward 100
//   turnleft 90
// }
```

## The rules that are not negotiable

From §0 of the module prompt library. They are repeated here because every one of them has
already been the reason for a design decision in `packages/kodo_lang`:

- **Offline-first.** No learning feature may block on a network call.
- **One AST.** Blocks and text are two projections of a single program representation.
  Never a second parser, a second interpreter or a second grader.
- **Keywords are locale data, not code.** French is the reference language.
- **No technical error text ever reaches a child's screen.** Every message is a full
  sentence at a CE2/CM1 reading level, in French and English.
- **No countdown on a learning item, no randomised reward box, no loss-framed streak, no
  notification after 20:00.** If a requirement seems to ask for one, stop and raise it.

## What the build found

Nine defects, eight of them caught by a gate refusing to let something ship, and thirty-four
authoring faults refused before a pack was written. Each module's
[`docs/modules/*_DONE.md`](docs/modules/) lists its own. The four that would have reached a
child:

| ID | What it was |
| --- | --- |
| `M3-001` (S1) | The editor re-rendered a child's saved file from the parsed tree, so reopening yesterday's work with a typo in it **deleted that line silently** |
| `M12-001` (S2) | Two pupils named Awa both displayed as `Awa P.` — every id starts `pupil-`. The one screen whose job is to tell a teacher which of 35 children needs help showed two of them as the same person |
| `M16-001` (S2) | The status line broke at **110 %** text scale, against a 200 % commitment — losing the line that says *"I stopped your program"* for the child who most needs it |
| `M15-001` (S2) | A screen-reader label built as `'Famille ${name}'`, so a blind English-speaking child would hear *"Famille Move"* |

And one that would have reached the curriculum: `M1-004` — `demande`/`ask` returns text and
the language had **no way to make it a number**, so no child could write a counting game.
Closed by PO decision `D-011`, the only addition to the frozen Annex §515 opcode set in this
delivery.
