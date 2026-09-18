# KODO — Gate Register

Live successor to the `Gates` sheet of the companion workbook. **Status and evidence are the
only columns anyone edits.** A gate closes on evidence, never on a date and never on a merged
fix (§16).

| Gate | Name | Accountable | Planned | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| G0 | Mandate | Chair | W1 | **Done** | Both sources ingested; see `docs/spec/` |
| G1 | Cahier des charges | **Product Owner** | W4 | **Closed** | `00_PO_DECISION_REGISTER.md` D-001…D-006 answer Annex E; requirement register machine-readable at `spec/requirements.json`; concept ledger at `spec/concepts.json`; traceability enforced by `tools/trace_check.dart` in CI |
| G2 | Module prompts | Runtime + Eng leads | W5 | **Closed** | 18 prompts reviewed; M1 interface contract (`parse`/`render`/`Interpreter`/`Surface`) implemented and frozen at `packages/kodo_lang/lib/kodo_lang.dart`; two amendments raised — `FR-M4-09`, `FR-M3-09` — and registered |
| G3 | Build & integrate | QA & Release | W12 | **Build complete, gate open** | 18/18 modules built, 441 tests passing, 98/130 requirements Done and each named by a test. Three worlds authored (266 items), block+text+graded+offline all met and tested. **The gate stays open on the last four words of its own criterion: nobody has run the slice on the reference device.** Full assessment, and the 32 open requirements grouped by what each is waiting for, in `03_G3_ASSESSMENT.md` |
| G4 | Deep review | Safety + QA | W26 / W40 / W52 | Not started | — |
| G5 | Market challenge | Chair + PO | W27 / W41 / W53 | Not started | — |

## G3 exit criteria, item by item

The criterion is one sentence (§1.4) and it is assessed clause by clause in
`03_G3_ASSESSMENT.md`.

| Clause | Verdict | Evidence |
| --- | --- | --- |
| One full world | **Exceeded — three** | `content/world0.json`, `world1.json`, `world2.json`; 266 items, 13 concepts, each at or above its §6.3 commitment |
| Block + text | Conforme | One AST, two projections; 500 random language switches and 5 000 random edit sequences lose nothing |
| Graded | Conforme | All 266 items pass M6's publish gate, re-run over the shipped JSON |
| Offline | Conforme | `FR-M14-01`; no pack contains a URL, asserted for all three worlds |
| On the reference low-end device | **Écart** | No device was available to this delivery. Seat 14 owns the run; the protocol is in `03_G3_ASSESSMENT.md` |

## G1 exit criteria, item by item

| Criterion | Verdict | Evidence |
| --- | --- | --- |
| Spec accepted | Conforme | Accepted as v1.0 with two PO amendments, both registered as new requirements rather than silent edits (§16: *requirements are never changed silently*) |
| Every FR tagged and traceable | Conforme | `spec/requirements.json` — 100 requirements, each carrying module, source tag, MoSCoW priority, verification method and gate |
| Concept ledger complete | Conforme | `spec/concepts.json` — 58 concepts, 12 worlds, prerequisites, item commitments, misconception per concept |
| Annex E answered | Conforme | D-001 … D-006 |

## G2 exit criteria, item by item

| Criterion | Verdict | Evidence |
| --- | --- | --- |
| 18 prompts have inputs, outputs, acceptance tests, adjacent interfaces | Conforme | Reviewed as issued; no prompt required a G1 return |
| Interface contracts confirmed against adjacent modules | Conforme for M1 | `Surface` is the sole M1→M4 contract and is abstract; M1 has no import of any platform API — enforced in CI by `tools/trace_check.dart` |

## Amendments raised at G1 by the Product Owner

Recorded here because §16 forbids changing a requirement silently.

| ID | Requirement | Origin |
| --- | --- | --- |
| `FR-M4-09` | *Mode léger* auto-enabled below 3 GB RAM; rendering budget only, must not change a grading result | D-004 |
| `FR-M3-09` | Read-only, one-way Python projection of the AST, World 12 only | D-005 |
