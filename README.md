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
| `packages/kodo_lang/` | **M1 — the language core.** Pure Dart: one AST, one parser, one interpreter, one grader |
| `delivery/meridian/` | The programme as a Meridian portfolio, generated from `spec/`. Meridian is the delivery system of record (PO decision D-009) |
| `docs/reports/` | Reports to other parties, including the Meridian product report |
| `tools/` | `gen_spec.py` regenerates `spec/`; `meridian_book.py` regenerates the portfolio; `trace_check.dart` is the traceability gate |

## Status

| Gate | State |
| --- | --- |
| G0 Mandate | Done |
| G1 Cahier des charges | **Closed** — Annex E answered, D-001 … D-006 |
| G2 Module prompts | **Closed** — M1's interface contract frozen |
| G3 Build & integrate | **In progress** — M1 complete, 7/7 acceptance tests green. M4 → M2 → M3 → M5 → M6 → M7 outstanding |
| G4 Deep review | Not started |
| G5 Market challenge | Not started |

Build order is frozen by PO decision D-008: **M1 → M4 → M2 → M3 → M5 → M6 → M7**, then
M14, M13, M8, M11, M9, M18, M12, M10, M15, M16, M17. M1 is first because risk `R3` —
dual-representation round-tripping — carries the joint-highest exposure in the register,
and its recorded response is to prototype the round-trip before anything else.

## Running M1

```bash
cd packages/kodo_lang
dart pub get
dart test                    # the seven acceptance tests plus the semantics suite
dart analyze --fatal-infos
cd ../.. && dart tools/trace_check.dart   # requirement traceability
python3 tools/gen_spec.py                 # regenerate spec/ from the workbook
python3 tools/meridian_book.py            # regenerate the Meridian portfolio
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
