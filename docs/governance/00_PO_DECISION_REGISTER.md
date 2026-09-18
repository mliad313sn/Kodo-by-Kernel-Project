# KODO — Product Owner Decision Register

**Authority.** The Product Owner holds final authority on scope, budget and release (seat 1,
`Comite & RACI`), is Accountable at G0, G1, G4 and G5, and is the escalation point for
unresolved Committee objections within one working week (§1.3).

**Format.** Every decision is minuted as the cahier des charges requires: *decision, owner,
date, rationale, source evidence, reversal cost*. A decision is not a discussion. It is
binding on the squads until it is superseded by a numbered replacement in this register.

**Reversal cost** is stated explicitly because §1.3 requires it and because it is the single
most useful thing to know before arguing with a decision:

| Cost | Meaning |
| --- | --- |
| Low | Reversible inside one sprint, no external promise broken |
| Medium | Reversible, but costs rework in more than one module or a re-record/re-author cycle |
| High | Effectively one-way. Breaks a public promise, a licence, or a published artefact |

---

## Part 1 — Annex E: the six questions reserved for the Product Owner

Annex E of the cahier des charges lists six open questions and Gate G1's exit criteria
require them answered. `Risques!R9` records that the funding model is *"the only risk whose
response is outside the Committee's authority"*. All six are answered below. G1 is closed.

---

### D-001 — Business model: free core forever, funded by institutions, not by children

**Decision.** KODO's entire learning path — every world, every concept, every one of the
1 214 items — is free, permanently, to every child, with no account required. Revenue comes
from three lines, none of which touches a child's screen:

1. **School and district licences** for classroom mode (M12): class management, the mastery
   grid, printable progress and unplugged worksheets, offline seeding, and teacher training.
   **Priced at zero for public schools in the launch markets** (adopting `IMP-002`), paid for
   private, international and out-of-market schools.
2. **Institutional and donor funding** for the Francophone-Africa deployment, sold against
   the offline and low-end-device capability, which is the thing no competitor has.
3. **An optional family support tier**, post-v1, living in the parent space (M11) and
   unlocking **cosmetics only** — never a concept, never an item, never a world.

**Rationale.** Three parts of the specification already made this decision and were waiting
for someone to sign it. §2.3: KODO is *"not a gated content subscription that withholds
concepts behind payment"*. `FR-M7-07`: nothing in the progression may be bought or skipped
for payment. §10: the parent-facing promise, *written into the store listing and testable*,
is no ads and no purchase surface visible to the child. A consumer freemium model contradicts
all three, and it loses the head-to-head it was invented to win: on the `Benchmark` sheet
KODO targets 5 on *Free / affordable* against Code.org's 5 and Tynker's 2. If a parent can
use Code.org free and KODO costs money, §15's hostile question answers itself.

**Consequences for the build.** M11 ships a purchase surface that is empty in v1 but
architecturally present and parent-gated. M10's public gallery loses its business case
(see D-003). The licence line depends on M12 being genuinely good offline, which promotes
`FR-M12-03` from a feature to a revenue dependency.

**Source evidence.** §2.3, §10, `FR-M7-07`, `FR-M10-01`, `FR-M11-04`, `NFR-COST-01`,
`Backlog amelioration!IMP-002`, `Risques!R9`, `Benchmark` weights.

**Reversal cost.** **High.** The no-purchase promise goes into the store listing and is
testable at G4. Retrofitting a consumer paywall after launch breaks a published promise.

**Closes.** `Risques!R9` (exposure 16, previously unowned).

---

### D-002 — Launch markets and languages: FR + EN at v1; Wolof interface is a commitment, Wolof keywords are not

**Decision.** v1 ships **French (reference) and English (full parity)**, per `FR-M15-02`.
Launch markets: **Senegal and France** for French, plus English for international schools in
both. **Wolof interface and narration is a funded commitment for v1.2**, paid from the
institutional line of D-001. The **Wolof keyword set stays a research item**, not a
commitment, exactly as the specification already words it.

**Rationale.** The distinction the specification draws between the three localisation layers
(`FR-M15-01` — interface, keywords, content) is what makes this answerable. Translating the
interface and the narration is a content and audio cost with a known shape. Translating the
*keywords* is a language-design problem: it needs a lexicon a Wolof-speaking CS educator will
defend, and shipping a bad keyword set would poison the one mechanic (§4.4) the whole product
is built on. Committing to the first and not the second is not hedging; it is the only split
that survives contact with §15.3.

**Reversal cost.** **Low** for the v1.2 date. **Medium** for the keyword split — promoting
Wolof keywords later is additive, demoting them after a promise is not.

---

### D-003 — The public gallery is out of scope for v1

**Decision.** v1 ships **class galleries only** (`FR-M10-07`). The public gallery is removed
from v1 scope and gated behind two conditions, both of which are evidence, not dates: a
staffed moderation function able to hold the 24-hour triage SLA of `FR-M10-06`, and a passing
seat-13 adversarial review. Earliest reconsideration is the second G5 loop.

**Rationale.** §13 requires that *all* child-authored public text is reviewed before
publication and that reports are triaged within 24 hours. That is a staffing commitment, not
a feature flag. Shipping a public gallery we cannot moderate creates exactly the risk that
`IMP-009` already forced us to accept for camera capture — an S1 surface we cannot staff at
launch. The same reasoning applies, so the same answer applies. `FR-M10-07` already calls the
public gallery *"a separate, later-phase opt-in"*; this decision makes that binding.

**Reversal cost.** **Low.** The decision is subtractive and the capability is additive later.

---

### D-004 — Device floor stays Android 8 / 2 GB, plus a mandatory "mode léger"

**Decision.** The device floor stays **Android 8, 2 GB RAM** (`NFR-COMP-01`). The **gate**
device stays the reference device of the module prompts: Android 11, 2 GB RAM, 5.5", no
reliable internet. We do **not** target 1 GB. In exchange, a new requirement is raised:

> **FR-M4-09 (new, raised by the PO at G1)** — a *mode léger* auto-enabled on devices
> reporting under 3 GB of RAM and manually selectable anywhere: reduced motion, no ghosted
> future-path overlay (`FR-M4-08`), a lowered drawn-segment ceiling, and simplified block
> shadows. It is a rendering budget, not a second code path, and it must not change any
> grading result.

**Rationale.** Dropping the floor to 1 GB would force cuts to the vector renderer and the
inspector — and the inspector is not a nicety, it is the entire teaching apparatus of concept
C6.4 and the evidence that a variable is a box. `R2` (exposure 15) is already the second
highest engineering risk at 2 GB. The *mode léger* recovers most of the reach benefit of a
1 GB target for a fraction of the cost, and it is the honest form of `NFR-PERF-02`: a
performance budget that degrades visibly rather than a promise that breaks silently.

**Reversal cost.** **Medium.** Lowering the floor later means re-testing the whole device
matrix; raising it means abandoning users.

---

### D-005 — No Python authoring in v1, but a one-way Python *view* ships in World 12

**Decision.** The English-keyword bridge (§4.4, World 11) remains the v1 commitment. KODO
does **not** gain a Python editor, a Python parser or Python execution in v1. Instead a new
requirement is raised:

> **FR-M3-09 (new, raised by the PO at G1)** — *"Regarde ton programme en Python."* A third,
> **read-only, one-way** projection of the same AST: the child's program rendered as
> commented, runnable-elsewhere Python, exportable as a `.py` file, offered in World 12 only.
> No Python is parsed, no Python is executed, and there is no round-trip. It is a renderer
> over `render(Program, target)`, nothing more.

**Rationale.** M1 already owes us `render(Program p, Locale kw)`. A Python emitter is a third
target for a renderer that has to exist anyway — days, not weeks — and it must be built on
the one-AST rule of the shared preamble, never as a second representation. What it buys is
disproportionate: it is a concrete, screenshottable answer to `IMP-001` (Scratch's creation
ceiling out-pulls us at World 10), it turns "we are a bridge to real languages" from a claim
into an artefact a child can show a parent, and it costs nothing on the `Benchmark` sheet
because *Block ↔ text bridge* is already where we score 5 and Scratch scores 1.

**The trap this avoids.** A Python *editor* means a second parser, a second interpreter and a
second grader — explicitly forbidden by §0 of the prompt library and by §11.2. One-way
rendering does not cross that line. Full Python authoring is a v2 conversation and belongs
with a re-opened cahier des charges, not a pull request.

**Reversal cost.** **Low.**

---

### D-006 — KODO owns the item bank; authors keep their classroom rights; the bank opens at maturity

**Decision.** Three parts, and they only work together:

1. **Ownership.** Partner teachers assign copyright in an accepted item to KODO on payment of
   the per-item fee (§12). The bank is owned outright and unencumbered.
2. **Author rights back.** Every accepted author receives a perpetual, irrevocable,
   royalty-free licence to use their own items in their own teaching, and named attribution
   in the item metadata and the M18 audit trail (`FR-M18-03`).
3. **Opening.** Each world's item bank is **published under CC BY-SA 4.0 at the moment that
   world exits "learning beta"** — that is, when §16's exit condition is met: item health
   metrics inside band and child-panel abandonment below 10 %.

**Rationale.** §12 makes the bank the critical path and the `Banque exercices` sheet prices
it at 10.9 weeks of authoring capacity. Ambiguous ownership makes it unlicensable to schools
(killing D-001's first revenue line) and unforkable by the NGOs who are D-001's second. Part
3 is the part that matters: it is what makes the answer to §15's hostile question — *why
would a parent install KODO when Scratch and Code.org are free?* — survive being asked a
second time. We are not a walled garden with better French. We are the bank, open, plus the
engine that grades it.

**Why not open the bank immediately?** §16 is explicit that a finding closes on evidence and
that a world leaves beta on metrics. Publishing an item bank before its item-health data
exists would export our unvalidated content as though it were validated, and `FR-M17-03`
exists precisely because we expect a share of items to be rewritten.

**Reversal cost.** **High** for part 3 — publication is one-way. **Low** for parts 1 and 2 if
settled before the first author contract is signed, **high** afterwards.

---

## Part 2 — Standing decisions raised outside Annex E

### D-007 — `IMP-009` is promoted from backlog item to standing scope decision

**Decision.** Camera capture is **disabled in v1** in code, not in configuration. Import from
the device gallery stays, behind guardian consent. The `Do not` line of the M4 prompt and
`FR-M4-04` are amended accordingly.

**Rationale.** `IMP-009` is already logged at S1 with confidence 1.0 and effort 1 person-week.
An S1 with full confidence is not a backlog candidate; it is a decision someone forgot to
take. Taking it now prevents the consent plumbing being built and then deleted.

**Reversal cost.** Low.

### D-008 — Build order is frozen; M1 is built and proven before any UI exists

**Decision.** The build order of §"How to use this library" (M1 → M4 → M2 → M3 → M5 → M6 →
M7, then the rest) is frozen, and **M1's seven acceptance tests must pass before a single
widget is written.**

**Rationale.** `R3` — dual-representation round-tripping is harder than assumed — carries the
joint-highest risk exposure of 20, and its own recorded response is *"prototype the AST
round-trip in P1 before anything else"*. The failure mode this prevents is the expensive one:
discovering at World 7 that the toggle loses programs, after three modules have been built on
top of the assumption that it does not. `FR-M3-05` says the toggle must never lose a
program; that is a property of M1, and it is provable now.

**Reversal cost.** Low.

### D-009 — Meridian is the delivery system of record

**Decision.** [Meridian IT-PMO](https://github.com/mliad313sn/Meridian) drives KODO
delivery. The portfolio is **generated** from the artefacts that are already true in this
repository — the requirement register, the concept ledger, the risk register and this
decision register — by `tools/meridian_book.py`, and loaded through Meridian's book import.
It is never typed in twice.

**Rationale.** Three of Meridian's convictions match how this programme has to be run and
are implemented rather than claimed: authority is data and is decided server-side; the
audit trail cannot be rewritten, because a change that is not audited does not commit; and
the meeting is generated from the portfolio rather than assembled in a deck. §1.3 gives us
a three-lines model and an external auditor who will eventually ask why a decision was
taken; Meridian is built for exactly that question.

**Four things it cannot yet hold**, recorded so nobody mistakes the portfolio for the whole
truth. Meridian has four gates fixed in its schema and KODO has six that loop; its gates
attach to a project and our G4 reviews the whole portfolio; it has no requirement entity,
so our 130 requirements and their CI-enforced traceability are invisible in it; and it has
no way to express a domain veto, so seats 3, 5 and 13 are enforced by people. All four,
with the fixes, are in `docs/reports/MERIDIAN_PRODUCT_REPORT.md`.

**Consequence.** Where Meridian and this repository disagree, **the repository wins** until
`MER-01` and `MER-03` are closed, because the repository is the one CI can check. That is
an uncomfortable answer for a system of record and it is the honest one.

**Reversal cost.** **Low.** The book is generated, so moving to another tool costs one
generator.

---

## Open items the PO has *not* decided

Recorded so that silence is not mistaken for a decision.

| # | Item | Why it is not decided yet | Decide by |
| --- | --- | --- | --- |
| O-01 | The agreed budget line behind `NFR-COST-01` | Needs the D-001 licence model priced against real school counts in the launch markets | Before P2 |
| O-02 | Whether the family support tier of D-001 ever ships | Depends on whether the institutional lines cover marginal cost; deciding early adds a surface we may delete | Post-launch loop 1 |
| O-03 | Audio casting: two consistent FR and EN voices (§12) | Casting is a content decision belonging to seat 11, not a PO decision; the PO owns only the 15 % re-record reserve | Before World 0 narration freeze |
