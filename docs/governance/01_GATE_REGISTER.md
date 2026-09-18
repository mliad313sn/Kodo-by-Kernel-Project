# KODO — Gate Register

Live successor to the `Gates` sheet of the companion workbook. **Status and evidence are the
only columns anyone edits.** A gate closes on evidence, never on a date and never on a merged
fix (§16).

| Gate | Name | Accountable | Planned | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| G0 | Mandate | Chair | W1 | **Done** | Both sources ingested; see `docs/spec/` |
| G1 | Cahier des charges | **Product Owner** | W4 | **Closed** | `00_PO_DECISION_REGISTER.md` D-001…D-006 answer Annex E; requirement register machine-readable at `spec/requirements.json`; concept ledger at `spec/concepts.json`; traceability enforced by `tools/trace_check.dart` in CI |
| G2 | Module prompts | Runtime + Eng leads | W5 | **Closed** | 18 prompts reviewed; M1 interface contract (`parse`/`render`/`Interpreter`/`Surface`) implemented and frozen at `packages/kodo_lang/lib/kodo_lang.dart`; two amendments raised — `FR-M4-09`, `FR-M3-09` — and registered |
| G3 | Build & integrate | QA & Release | W12 | **In progress** | M1 complete, 7/7 acceptance tests passing. M4 → M2 → M3 → M5 → M6 → M7 outstanding |
| G4 | Deep review | Safety + QA | W26 / W40 / W52 | Not started | — |
| G5 | Market challenge | Chair + PO | W27 / W41 / W53 | Not started | — |

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
