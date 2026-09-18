# M1 — Language core and interpreter · Definition of Done

Checked against §14.1. Items that cannot apply to a module with no child-facing surface
are marked `n/a` with the reason, never silently skipped.

| # | Criterion | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Meets its numbered requirements, each verified by a named test | **Met** | 12/12 `FR-M1-*` named by a test; enforced by `tools/trace_check.dart`, report at `build/traceability.md` |
| 2 | Works offline on the reference device | **Partly** | M1 makes no network call and imports no platform library — enforced in CI. *Not yet measured on the reference device* (see below) |
| 3 | FR and EN with 100 % string coverage and recorded audio | **Met for strings**, `n/a` for audio | Keyword coverage and error-message coverage are both CI gates. M1 emits no narration; audio belongs to M5 |
| 4 | Accessibility checklist | `n/a` | No surface. The obligation passes to M2/M3/M4 through the `Surface` contract |
| 5 | Used by three children unassisted, observed | `n/a` | No surface a child can use. First applies at M2 |
| 6 | Telemetry events fire and appear in the health report | **Deferred to M17** | `ExecutionEvent` is emitted and typed; the taxonomy of `FR-M17-01` is M17's |
| 7 | Failure modes are child-legible; no technical string reaches a child | **Met** | Closed catalogue of 22 codes, FR + EN, full sentences, capitalised, no banned technical word — all asserted in `a5_error_catalogue_test.dart` |
| 8 | No open S1 or S2 defect, no open safety finding | **Met** | Four defects were found during the build and all four are closed; see below |
| 9 | Content reviewed by pedagogical and localisation reviewers | **Outstanding** | The 22 error messages are content and have not had a seat-3 or seat-11 review. Raised as `M1-REV-01` |
| 10 | Rollback path documented | **Met** | M1 is a leaf package with no persisted state. Rollback is a version pin in `packages/*/pubspec.yaml`; ASTs carry no schema version yet because nothing persists them until M13 |

## The seven acceptance tests of the module prompt

| # | Test | Result |
| --- | --- | --- |
| 1 | Round-trip, 1 000 programs, both keyword languages | Pass |
| 2 | Locale swap mid-run, identical drawing | Pass |
| 3 | Determinism, same seed, 100 runs | Pass (cross-platform pinned by a golden, not yet run on three platforms) |
| 4 | Step equality including `attends` and `hasard` | Pass |
| 5 | Every error path reachable, FR + EN complete | Pass |
| 6 | 10 000 malformed programs, no crash, no hang | Pass |
| 7 | 2 000-segment rosette under 2 s | Pass on CI (11 ms); **not yet measured on the reference device** |

## Defects found and closed during the build

Recorded because §16 says a finding closes on evidence, and because three of these would
have been invisible until a child hit them.

| ID | Severity | What was wrong | Why it mattered | Closed by |
| --- | --- | --- | --- | --- |
| `M1-001` | S2 | Opcode identifiers (`MOVE_FORWARD`) were passed into error messages as substitution values | A French sentence would have rendered with a machine word in it — the exact leak `FR-M1-10` forbids, and invisible to an English-speaking reviewer | Arguments are now references (`opcode:…`, `syntax:…`) resolved through the keyword table; asserted by a test that scans every rendered message |
| `M1-002` | S2 | `avance 0` recorded a zero-length segment | Two programs differing only by an invisible stroke would have produced different path signatures and therefore different grading verdicts, breaking `FR-M6-02` | Zero-length moves record no segment |
| `M1-003` | S1 | The parser could read past end-of-file and throw `RangeError` | A crash in front of a child, and a stack trace where `FR-M1-10` promises none. Found by the acceptance-test-6 fuzzer on a malformed program | End-of-file is sticky; `advance()` cannot move past it |
| `M1-004` | S3 | One misspelled command produced two error marks | A child who made one typo was told they made two mistakes — friction of exactly the kind §4.7 exists to remove | Orphaned arguments are consumed during recovery |
| `M1-005` | S3 | `montre` abbreviated to `mo` in French, but `show` had no English short form | A child who typed `mo`, switched to English keywords and back, found their code silently rewritten — small, and corrosive to the trust `FR-M3-05` protects | Added `ss`/`sh`; abbreviation coverage is now identical across tables and asserted in CI |

## Outstanding, and owned

| ID | What | Owner | Due |
| --- | --- | --- | --- |
| `M1-PERF-01` | Measure the 2 000-segment rosette, cold parse and toggle latency on the reference device (Android 11, 2 GB) | Seat 9 | G3 |
| `M1-PLAT-01` | Run the determinism suite on Android, iOS, desktop and the WASM web build, not only on CI | Seat 9 | G3 |
| `M1-REV-01` | Pedagogical (seat 3) and localisation (seat 11) review of all 22 error messages, read aloud | Seats 3, 11 | Before the first child sees an error, i.e. before M3 ships |
| `M1-REV-02` | Confirm with seat 3 that 1-based list indexing is the right call for 8–11 year olds | Seat 3 | Before World 12 content is authored |
