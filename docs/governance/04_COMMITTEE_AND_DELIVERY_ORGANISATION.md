# KODO — The Committee, seated · and the delivery organisation under it

**Convened by the Product Owner** under the delegation of §1.3 and PO decision `D-009`.
**Purpose:** carry KODO from *"the engine is built"* to *"a child in Dakar is learning on a
2 GB phone"*, without a gate closing on anything but evidence.

> **On names.** §1.2 is explicit: *"Each seat is a competence, not necessarily a separate
> person."* This charter therefore staffs **roles and allocations**, not individuals. The
> `Holder` column is for the Chair to fill as people are appointed; a seat with no holder is
> an **unfilled seat**, and the register below says what it blocks. Inventing names here
> would put fiction into the one document the programme is supposed to be run from.

---

# Part 1 — The Committee (14 seats)

The Committee **does not build.** It specifies, reviews, challenges and re-specifies. It
meets weekly for 90 minutes, chaired by seat 2, minuted as decision / owner / date /
rationale / evidence / reversal cost.

| # | Seat | FTE | Holder | Veto | What it owns in the work that remains | First action |
| --- | --- | ---: | --- | --- | --- | --- |
| 1 | **Product Owner** | 1.0 | *(seated — this delivery)* | — | Scope, budget, release, gate sign-off. Arbitrates every unresolved objection within one working week | Commission the reference device (WP-3). Nothing else unblocks 12 requirements |
| 2 | Committee Chair / Programme Director | 0.6 | — | — | Agenda, gate register, dissent log, the weekly burn-up that risk `R1` is tracked on | Fill the `Holder` column below. An unfilled seat is a decision nobody is making |
| 3 | **Pedagogical Lead** (CS education) | 1.0 | — | **Blocking** | The learning model. The M7-SIM-01 ruling (open S2). Reading the 266 items nobody has read | Rule on `D-010` — mastery window 8 → 10 — so `M7-SIM-01` stops blocking G3 |
| 4 | **Curriculum & Assessment Designer** | 1.0 | — | **Blocking** | The concept ledger, the exercise bank, the 948 items still owed. Chairs the content authority | Stand up the partner-teacher pool. `R1` is the joint-highest risk and it is this seat's |
| 5 | **Child Development Psychologist** | 0.4 | — | **Blocking** | Age-appropriateness. The child panel's protocol and its findings | Write the observation protocol for the six-child panel before the app shell lands |
| 6 | Game Designer (ethical engagement) | 0.4 | — | — | The motivation system, and the standing audit that no prohibited mechanic has crept back | Re-run `auditMechanics()` against every new screen as it ships |
| 7 | **Children's UX/UI + Accessibility** | 1.0 | — | — | The design system, and **the ten screens that do not exist** | Design the app shell and the ten missing screens. This is the critical path |
| 8 | Language & Runtime Architect | 0.6 | — | — | M1–M4. The opcode set, frozen except by PO decision (see `D-011`) | Hold the interface contract as the client squad builds against it |
| 9 | **Cross-platform Engineering Lead** | 1.0 | — | — | Architecture, the device matrix, the app shell's structure | Own WP-1: `main.dart`, the platform projects, navigation, state |
| 10 | Backend, Data & Learning Analytics | 0.6 | — | — | M13, M17, sync, the weekly curriculum health report | Stand the health report up for four consecutive weeks — it is a G4 precondition |
| 11 | **Localisation & Culture Lead** | 0.8 | — | — | FR/EN parity, the ~380 recordings owed for Worlds 0–2, the Wolof v1.2 track | Cast two FR and two EN voices. Audio is 60 % of each world's size budget |
| 12 | Teacher & Parent Representative | 0.4 | — | — | Classroom reality. M11, M12. The 35-device drill | Book the no-internet drill in a real school |
| 13 | **Child Safety, Privacy & Compliance** | 0.5 | — | **Blocking, every gate** | §13. The moderation rota, the SDK allow-list, the adversarial review | Commission the external child-safety audit (`NFR-SEC-01`). Lead time is months |
| 14 | **QA & Release Manager** | 1.0 | — | — | Test strategy, the defect taxonomy, **the G3 device run** | Run the G3 protocol in `03_G3_ASSESSMENT.md` the day the device arrives |

**Observers — voice, no vote.** Six children aged 8–11, rotating, always accompanied. One
classroom pilot teacher.

**Committee FTE: 9.3.**

### Seats that may not be combined

Seat 13 may never hold seats 6, 8 or 9 (§1.2) — *the officer who must refuse a mechanic
cannot be the person who designed it.* Beyond the cahier, this delivery adds one:

> **Seat 14 may not hold seat 9.** The engineer who built the client cannot be the person
> who signs off that it meets its performance budget on the device. G3 turns entirely on
> that measurement.

---

# Part 2 — The delivery organisation (technical staff)

The Committee is the second line. **These squads are the first line** — they own build
quality and self-testing against §14. Each squad has one lead, reports to one Committee
seat, and owns a named set of requirements.

## S1 · Client Shell squad — *the critical path*

| | |
| --- | --- |
| **Lead** | Seat 9 (Cross-platform Engineering Lead) |
| **Staff** | 2 Flutter engineers |
| **Owns** | `main.dart`, the Android / iOS / desktop / web projects, navigation, state management, the run/stop/step controls, theming, and the accessibility preferences surface |
| **Why it exists** | There is no application. Eleven packages of tested logic and **no `main.dart`**. Every other squad's work is invisible until this one lands |
| **Done when** | A child can install it, open it, and reach an exercise |

## S2 · Learning Client squad

| | |
| --- | --- |
| **Lead** | Seat 7 (Children's UX/UI) |
| **Staff** | 2 Flutter engineers + 1 illustrator/motion designer |
| **Owns** | The ten missing screens: profile & picture password · world map · tutorial player · item player · hint & diagnostic panel · Studio · recipes panel · gallery · parent space · classroom teacher view |
| **Requirements** | `FR-M2-04` · `FR-M2-05` · `FR-M2-06` · `FR-M2-07` · `FR-M3-06` · `FR-M3-08` · `FR-M4-08` · `FR-M5-02` · `FR-M6-06` |
| **Done when** | Each screen passes the §14.1 checklist, including three children using it unassisted |

## S3 · Runtime & Platform squad

| | |
| --- | --- |
| **Lead** | Seat 8 (Language & Runtime Architect) |
| **Staff** | 1 language-runtime engineer + 1 platform engineer |
| **Owns** | M1–M4 maintenance, and the platform plumbing nothing has been wired to yet |
| **Requirements** | `FR-M4-02` · `FR-M4-04` · `FR-M4-05` · `FR-M4-07` · `FR-M9-05` · `FR-M14-03` |
| **Rule** | Every one of these sits behind `ConsentGate`, which is built and tested. Wire to the gate, never around it |

## S4 · Data & Trust squad

| | |
| --- | --- |
| **Lead** | Seat 10, with seat 13 embedded |
| **Staff** | 1 backend/data engineer |
| **Owns** | Sync, telemetry, the weekly curriculum health report, the moderation console's operational side |
| **Requirements** | `NFR-REL-01` · `NFR-SEC-01` (with seat 13) |
| **Done when** | The health report has been delivered four consecutive weeks — a G4 precondition |

## S5 · Content Factory

| | |
| --- | --- |
| **Lead** | Seat 4 (Curriculum & Assessment Designer) |
| **Staff** | 1 curriculum designer + **a pool of 4 partner teachers** |
| **Owns** | Worlds 3–12 — **948 items**, ~8 weeks at the §12 rate of 120 artefacts/week, and the schedule's critical path per §6 |
| **Tooling** | The M18 CMS is built and tested. Partner teachers author through it; the publish gate refuses anything incomplete, with a specific reason |
| **Rule** | **Scope is cut in worlds, never in items per concept** (`R1`). A thin concept is a false mastery claim |

## S6 · Voice & Art

| | |
| --- | --- |
| **Lead** | Seat 11 (Localisation & Culture) |
| **Staff** | 2 FR voices + 2 EN voices + the S2 illustrator |
| **Owns** | ~380 recordings for Worlds 0–2, then ~2 400 more for Worlds 3–12; `art/tika.svg` and each world's illustration |
| **Budget rule** | Audio is ~9 MB of each world's 12 MB budget. Opus, and freeze the narration copy before recording — `R7` holds a 15 % re-record reserve |
| **Requirements** | `FR-M15-02` (Wolof v1.2 interface; keywords stay research per `D-002`) |

## S7 · Device & Release

| | |
| --- | --- |
| **Lead** | Seat 14 (QA & Release Manager) |
| **Staff** | 1 QA engineer + the device matrix |
| **Owns** | **The G3 device run** and every number that can only be measured on glass |
| **Requirements** | `NFR-PERF-01..03` · `NFR-SIZE-01` · `NFR-BATT-01` · `NFR-OFF-01` · `NFR-COMP-01` · `FR-M6-07` · `FR-M14-02` |
| **Done when** | The protocol in `03_G3_ASSESSMENT.md` has been run and every number is written into `spec/status_overrides.json` |

**Delivery FTE: 14.0** (2 + 3 + 2 + 1 + 5 + 1 illustrator shared + 1 QA, plus the voice pool
engaged per world).

---

# Part 2b — The Art Committee

**Convened by the PO** because §9 names a design system and seat 7 owns it, but a design
system is not an illustrated world. KODO's differentiator is a *place a child wants to be*,
and nobody in the fourteen seats draws.

> **The rule this committee exists to hold.** The art serves the learning, never decorates
> it. A picture that makes a screen prettier and a concept harder is a regression, and
> seats 3 and 5 say so.

| # | Seat | FTE | Holder | Brings | Owns |
| --- | --- | ---: | --- | --- | --- |
| A1 | **Art Director** | 0.6 | — | A coherent world, and the authority to refuse one that is not | The visual bible, and the final look |
| A2 | **Character Designer** | 0.5 | — | Tika, and whoever else lives here | The character sheet: poses, expressions, what Tika may and may not do |
| A3 | **World Illustrator** | 1.0 | — | Thirteen places a child recognises | One illustrated world per curriculum world |
| A4 | **Icon & Block Designer** | 0.4 | — | Ten block families, each legible at 24 px | Icons and silhouettes — `FR-M16-01`'s *shape*, not just its colour |
| A5 | **Motion Designer** | 0.4 | — | Motion that shows causality | Every transition, and the reduced-motion variant of each |
| A6 | **Colour & Accessibility** | 0.3 | — | WCAG 2.2 AA, and three kinds of colour blindness | The palette, and the proof it survives all four checks |

**Art FTE: 3.2.** Reports to seat 7 (Children's UX/UI + Accessibility), who holds the
design system; seat 5 (Child Development Psychologist) keeps the age-appropriateness veto,
and seat 3 keeps the pedagogical one.

### What the art committee may not do

1. **Colour is never the only signal.** Every block family carries a colour *and* an icon
   *and* a silhouette (`FR-M16-01`). A11y is not a pass at the end; A6 sits in the room.
2. **No motion a child cannot interrupt** (§9.2), and every animation has a reduced-motion
   form that is not simply "nothing happens".
3. **Nothing modal a child can get trapped behind** (§9.2).
4. **No reward art for a mechanic §10 forbids.** A loot box is still a loot box when it is
   beautifully drawn, and seat 6's `auditMechanics()` runs against new screens.
5. **Vector, always.** `R4`: per-world budget, art as vector, audio as Opus. A raster
   world illustration eats the pack budget a child's narration needs.

### The visual bible, as data

The palette, spacing, type scale, motion durations and the character sheet live in
`packages/kodo_art` as **code**, not as a file somebody exports from a design tool. Tests
run over them: contrast, colour-blind separation, touch targets, and the reduced-motion
pair. A design system that cannot fail a build is a mood board.

---

# Part 3 — RACI over everything that remains

**A** = accountable (one, always). **R** = responsible. **C** = consulted. **I** = informed.

| # | Work package | Reqs | A | R | C | Blocks |
| --- | --- | ---: | --- | --- | --- | --- |
| WP-1 | **App shell** — `main.dart`, platform projects, navigation | — | Seat 9 | S1 | 7, 14 | **Everything** |
| WP-2 | The ten missing screens | 9 | Seat 7 | S2 | 3, 5, 13 | G3 child run |
| WP-3 | **Reference device** + the numbers only it can give | 9 | Seat 14 | S7 | 9 | **G3 closure** |
| WP-4 | Platform APIs behind the consent gate | 6 | Seat 8 | S3 | 13 | G4 |
| WP-5 | Worlds 3–12 — 948 items | — | Seat 4 | S5 | 3, 11 | G4 #2 |
| WP-6 | Narration and illustration | — | Seat 11 | S6 | 4, 7 | G3 |
| WP-7 | Read the 266 items nobody has read | — | Seat 3 | 3, 4 | 11 | **G4** |
| WP-8 | External accessibility audit | `NFR-A11Y-01` | Seat 7 | external | 13 | **Public launch** |
| WP-9 | External child-safety & security audit | `NFR-SEC-01` | Seat 13 | external | 10 | **Public launch** |
| WP-10 | Child panel — six children, per world | — | Seat 5 | 5, 7 | 3 | G4 |
| WP-11 | Weekly curriculum health report × 4 | — | Seat 10 | S4 | 3, 4 | **G4** |
| WP-12 | Rule on `M7-SIM-01` / `D-010` | — | Seat 3 | 3, 4 | 1 | **G3** |
| WP-13 | Wolof interface v1.2 | `FR-M15-02` | Seat 11 | S6 | 12 | v1.2 |
| WP-14 | Agree the budget line (`O-01`) | `NFR-COST-01` | **Seat 1** | 1 | 2, 12 | G5 |
| WP-15 | **The visual universe** — character, worlds, icons, motion | §9 | Seat 7 | A1–A6 | 3, 5, 6 | G4 |
| WP-16 | The five root destinations of §9.1 | §9.1 | Seat 7 | S1, S2 | A1 | **G3** |

**Read the Blocks column.** Three work packages block a *gate*, two block *public launch*,
and one — WP-1 — blocks everything. That ordering is the plan.

---

# Part 4 — Operating rhythm, under the Product Owner

| When | What | Who | Output |
| --- | --- | --- | --- |
| **Daily, 15 min** | Squad stand-up | Each squad | Blockers only. Anything unresolved by noon goes to the PO |
| **Weekly, 90 min** | Committee | All 14 + observers | Minuted decisions. The `R1` authoring burn-up. The open-S1/S2 list |
| **Weekly** | Content authority | 3, 4, 11 + pilot teacher | Item acceptance. The publish gate is the floor, not the ceiling |
| **Weekly** | Curriculum health report | Seat 10 | The evidence base for the improvement loop |
| **Per module prompt** | Runtime contract group | 8, 9, 14 | Interface contracts. **An interface change is a specification change and returns to G1 — never a pull request** |
| **Per world** | Child experience panel | 5, 7 + six children | Pass-3 evidence. Every hesitation over eight seconds logged |
| **Per release** | Safety board | 13 + external auditor | Consent flows, SDK allow-list, moderation queue, prohibited-mechanics audit |
| **Per gate** | Gate review | Committee + PO | A gate closes on evidence. Never on a date, never on a merged fix |

### The PO's standing commitments

1. **Arbitrate within one working week.** An objection that sits is a decision being made by exhaustion.
2. **Never silently change a requirement.** Every change is an amendment in the register, as `FR-M4-09`, `FR-M3-09` and `D-011` already are.
3. **Cut worlds, not items per concept.** The mastery claim is the product.
4. **Refuse a gate that wants to close on a merged fix.** Evidence is a re-test.

---

# Part 5 — Decision rights, and how an argument ends

**Consent, not consensus.** A proposal carries unless a seat records a *reasoned,
domain-relevant* objection in the dissent log. *"I would have done it differently"* is not
an objection.

| Situation | Who decides |
| --- | --- |
| Build quality, how to implement | The squad (first line) |
| Is this taught correctly | Seat 3 — **blocking** |
| Is this age-appropriate | Seat 5 — **blocking** |
| Is this safe / compliant | Seat 13 — **blocking, at every gate** |
| Does the item bank support the mastery claim | Seat 4 — **blocking** |
| Interface between two modules | Runtime contract group (8, 9, 14) → returns to G1 |
| Scope, budget, release, ties | **Seat 1 (PO)**, within one working week |
| Is the product good enough to launch | Third line: external academic + external child-safety auditor, reporting **to the PO, not the Chair** |

---

# Part 6 — Staffing findings the PO is raising now

Three, recorded rather than discovered later.

### SF-01 (High) — §17.2's team shape did not anticipate that the application would be a separate workstream

The cahier allocates *"3 Flutter engineers"*. The client work that remains is an app shell
from zero, ten screens, and a web CMS front end. **Four Flutter engineers are allocated here
(S1: 2, S2: 2)** and the illustrator is named separately, because putting the shell and the
screens in one squad makes the shell wait for design and the design wait for the shell.

*Consequence if refused:* WP-1 and WP-2 serialise, and everything behind them slips.

### SF-02 (High) — the two external audits have a lead time nobody has started

`NFR-A11Y-01` and `NFR-SEC-01` are **preconditions of public launch**, and neither has been
commissioned. Auditors are booked months ahead. Seats 7 and 13 are directed to commission
both **now**, against the current build, and to schedule the re-test — a finding closes on
re-test evidence, never on a merged fix.

### SF-03 (Medium) — the authoring pool is the schedule, and it is not yet hired

`R1` is the joint-highest risk in the register and its response is *"templates + teacher
pool + weekly burn-up"*. The templates exist and are proven — 266 items went through them.
**The pool does not exist.** At 120 artefacts/week the remaining 948 items are ~8 weeks of
authoring *once the pool is working*; hiring and training four partner teachers is not in
that 8 weeks.

---

# Part 7 — How each remaining gate closes

| Gate | Closes when | Accountable |
| --- | --- | --- |
| **G3** | WP-1 lands · the device run is done and every number is recorded · `M7-SIM-01` is ruled on · no open S1 or S2 | Seat 14, signed by seat 1 |
| **G4 #1** | The §19 six-pass review, with findings **closed on re-test** · zero S1 · zero open safety findings · four weekly health reports delivered · six children observed | Committee + PO |
| **G5 #1** | The §20 challenge against the benchmark set, evidence attached · the hostile question answered honestly · the improvement backlog RICE-scored and re-planned | Chair + PO |
| **Loop** | G4 → G5 → **back to G1**, at least three times before public launch. Every loop produces a new version of the cahier des charges | Seat 1 |

---

## Register of unfilled seats

**As of this charter, thirteen of fourteen seats are unfilled.** Seat 1 is seated — this
delivery. That is not a criticism of anyone; it is the state, and it is written down so it
cannot be mistaken for a staffing plan that already happened.

The Chair (seat 2) is the first appointment, because an unfilled Chair means the dissent log
has no keeper and the decision hygiene this whole structure rests on has no owner.
