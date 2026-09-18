# M7 — Progression, mastery and scheduling · Definition of Done

## The five acceptance tests of the module prompt

| # | Test | Result |
| --- | --- | --- |
| 1 | 10 000 synthetic learners; no learner masters a concept they cannot do, none blocked past 25 items | **Pass, with a finding** — see `M7-SIM-01` |
| 2 | The scheduler never presents the same item twice within 20 items | Pass (400-item run, every 20-window checked) |
| 3 | Retention timing honours 72 h across clock changes and time zones | Pass |
| 4 | 30 days offline: computed, stored, later synced with no loss or double-counting | Pass |
| 5 | Removing an item from the bank does not change an existing `Maîtrisé` | Pass |

27 tests in total.

---

## M7-SIM-01 — the mastery rule needs a bigger bank than the curriculum commits

**Severity:** S2 (a core claim is not deliverable as specified)
**Raised by:** the 10 000-learner simulation, at first build
**Owner:** seats 3 and 4, escalated to the Product Owner
**Status:** open, answered by PO decision **D-010**

### What was observed, as fact

§4.6's criterion 2 asks for **≥ 80 % first-attempt success over the last 8 items**. For a
child whose true first-attempt rate is 80 %, whether any particular window of eight
qualifies is close to a coin toss. The number of items before one occurs is therefore
geometric, and it has a long tail.

Measured over 10 000 synthetic learners, on a concept with a 30-item bank:

| Ability band (aptitude ceiling) | Median items to criteria 1–3 | 95th percentile |
| --- | --- | --- |
| 0.92 – 0.96 — gets there quickly | under 25 | **30** |
| 0.78 – 0.84 — will get there | ~26 | higher |
| 0.40 – 0.46 — not yet | mostly never reaches them | — |

§6.3 commits **18 to 24 items per concept**. The rule the bank is supposed to serve needs
about **30** for the 95th-percentile capable child. The bank is undersized for its own
mastery rule by roughly a third.

### Why it matters

This is the difference between KODO's central claim and a slogan. If the bank runs out
before the rule can be satisfied, one of three things happens, and all three are bad: the
child sees the same items repeatedly, or the rule is quietly relaxed, or `Maîtrisé` is
awarded on weaker evidence than §4.6 describes. `R1` — *item authoring under-delivers and
mastery becomes a claim rather than a measurement* — is the register's joint-highest risk,
and this is the mechanism by which it would actually happen.

### Two things this finding is not

- **It is not a false-mastery problem.** Measured false positives: 3 in 10 000, all at the
  very top of the weak band. An exact zero is not assertable — the rule is a statistical
  test over a noisy signal, and every such test has a false-positive rate. For scale, a
  completion-based rule of the kind every competitor ships has a false-positive rate of
  100 % by construction.
- **It is not a scheduler problem, any more.** A separate defect *was* found and fixed:
  §4.6 says that until all four criteria hold the concept stays `En cours` and *"the
  scheduler keeps injecting its items"*, which with a 60 % current-concept mix meant a
  child who had already demonstrated a concept spent 72 hours drilling it. Measured cost:
  **50 items**, against a bank of 22. The scheduler now demotes a concept that is waiting
  only on its retention window to the 20 % interleaved band. The child moves on, the
  concept still comes back, and the retention check lands on time. That change alone took
  the figure from 50 to about 26.

### The proposed amendment, and its evidence

Widen criterion 2's window from **8 to 10** items.

This is a *reduction in variance*, not a reduction in the bar: a longer window is a better
estimate of the child's true rate, not a more forgiving one. The simulation prices it
directly, at 3 000 learners per arm, and the test `M7-SIM-01` asserts both halves:

- the 95th-percentile capable child needs fewer items at window 10 than at window 8;
- **and no more weak learners get through** — which is the question that decides whether
  it is an improvement or a softening.

The alternative — raising the per-concept commitment from 18–24 to about 30 — costs
roughly **+390 items** across 58 concepts, a third of a quarter of authoring capacity on
the programme's stated critical path. It buys nothing pedagogically.

### How this cannot silently regress

`accuracyWindow` is a named parameter on `MasteryCalculator`, defaulting to §4.6's value,
and the simulation runs in CI at both settings. The test is written to fail if the finding
*stops* reproducing, so nobody can delete it quietly once the numbers move.

---

## Definition of Done (§14.1)

| # | Criterion | Verdict |
| --- | --- | --- |
| 1 | Numbered requirements verified by named tests | **Met** — FR-M7-01 … FR-M7-07 each named |
| 2 | Works offline on the reference device | **Partly** — computed entirely on device with no I/O; not yet measured on the device |
| 3 | FR and EN, 100 % strings, recorded audio | `n/a` — M7 emits message *keys*, never text |
| 4 | Accessibility checklist | `n/a` — no surface |
| 5 | Three children, unassisted, observed | `n/a` — no surface. The simulation is not a substitute and is not offered as one |
| 6 | Telemetry events fire | **Deferred to M17** |
| 7 | Failure modes child-legible | **Met** — `MasteryEvidence.outstanding` returns keys, so the words stay in the localisation layer |
| 8 | No open S1 or S2 | **Open: `M7-SIM-01` is S2** and must close before G3 |
| 9 | Pedagogical and localisation review | **Outstanding** — seats 3 and 4 must rule on `M7-SIM-01` |
| 10 | Rollback path | **Met** — pure functions over stored attempts; mastery is recomputed, never migrated |

## Outstanding, and owned

| ID | What | Owner | Due |
| --- | --- | --- | --- |
| `M7-SIM-01` | Rule on the window amendment, or fund the larger bank | Seats 3, 4 → PO | Before G3 |
| `M7-PERF-01` | Measure mastery recomputation on the reference device with a year of attempts | Seat 9 | G3 |
| `M7-REV-01` | Seat 3 to confirm that D3-and-above is the right reading of criterion 3's "structurally dissimilar to the tutorial example" | Seat 3 | Before World 2 content |
