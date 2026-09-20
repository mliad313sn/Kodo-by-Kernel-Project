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

### D-010 — Criterion 2's window widens from 8 items to 10

**Decision.** §4.6's criterion 2 becomes *"≥ 80 % first-attempt success over the last **10**
items"*. Raised as an amendment, not a silent edit; `FR-M7-01` is re-issued accordingly.
The per-concept item commitment of §6.3 stays at 18–24.

**Rationale.** Finding `M7-SIM-01`, measured over 10 000 synthetic learners before a single
item has been authored. At a window of eight, the 95th-percentile *capable* child needs
about 30 items on a concept to satisfy criteria 1–3, against a bank the curriculum sizes at
18–24. The bank is undersized for its own rule by roughly a third.

Widening the window reduces the variance of the estimate without lowering the bar — ten
observations are a better measurement of a child's rate than eight, not a kinder one. The
simulation prices both arms and confirms the part that matters: **the wider window does not
let more weak learners through.** Had it done so, this decision would have gone the other
way and the money would have gone into the bank.

**The alternative, and why not.** Raising the commitment to ~30 items per concept costs
about **+390 items** across 58 concepts. §12 already names authoring capacity — not
engineering — as the critical path, and `R1` is the joint-highest risk in the register.
Spending a third of a quarter of that capacity to buy a noisier statistic is the wrong
trade.

**What this decision is not.** It is not a relaxation of mastery. All four criteria stand,
the retention check stands at 72 hours, and the measured false-positive rate is unchanged
at roughly 3 in 10 000.

**Source evidence.** `docs/modules/M7_DONE.md` § `M7-SIM-01`; the simulation runs in CI at
both settings and is written to fail if the finding stops reproducing.

**Reversal cost.** **Low** — one constant, and the simulation re-prices it on demand.

**Consulted.** Seats 3 and 4 hold the learning model and the item bank and have the
blocking veto here; this decision is recorded as the PO's answer to an escalation and is
open to a reasoned, domain-relevant objection in the dissent log until G3.

---

## D-011 — `nombre` / `number` joins the opcode set

**Date.** Taken while building M9. **Status.** Decided. **Reversal cost.** Low before
World 0 authoring begins; high afterwards.

**The decision.** One opcode is added to the frozen set of Annex §515:
`nombre` / `number` (`TO_NUMBER`), text to number, one argument, family *opérateurs*.

**What was observed as fact.** `demande` / `ask` returns text. The language had no
conversion, so `avance nombre-de-pas-que-le-joueur-a-tapé` could not be written at all:
`$x = demande "combien ?"` followed by `avance $x` fails with *« avance » ne marche pas
avec un texte*. Every counting game — the single commonest thing a nine-year-old wants to
build — was unreachable, and `FR-M9-06`'s Recettes panel could not ship a recipe that asks
the player anything numeric.

**Why this is not scope creep.** The gap was not a missing feature; it was a hole in a set
that Annex §515 presents as complete. `demande` is already in the annex, and an input verb
whose result cannot be used is not a feature, it is a trap. The module build order exists
precisely so that building M9 exposes what M1 got wrong, and this is that.

**Why an opcode rather than a coercion.** Making `avance "50"` silently work would teach
that text and numbers are the same thing, and the concept graph spends World 5 teaching
that they are not. An explicit `nombre` is the thing the curriculum can point at. A value
that cannot be converted raises the ordinary type error rather than yielding zero, because
a child who typed *trois* must be told, not scored zero in silence.

**Blast radius, and what was updated.** `Opcode.toNumber`, both keyword tables (with the
`nb` abbreviation, symmetric in FR and EN), the interpreter, `BlockHelp`, and Annex §515 in
the cahier. Opcode **ids never change**, so adding one cannot invalidate a stored AST or an
authored item (`FR-M6-08`). No World-1 item uses it; nothing was re-authored.

**Consulted.** Seat 3 (language and curriculum) owns the opcode set. This is recorded as
the PO's decision on a defect found in delivery and is open to objection until G3.

---

## D-012 — M19, the module the cahier des charges does not have

**Date.** Taken at G3. **Status.** Decided. **Reversal cost.** None — it adds a module that
was always implied.

**The decision.** A nineteenth module is added: **M19 — Application shell and navigation**,
with six requirements `FR-M19-01 … 06`. It is raised as an amendment, not an edit, per §16.

**What was observed as fact.** Eighteen modules were built. All eighteen pass their
acceptance tests. **There is no application**: no `main.dart`, no Android, iOS, desktop or
web project, and nothing that assembles the eleven packages into something a child can
open. Searching the eighteen module prompts for *shell*, *navigation*, *home screen* or
*main* returns nothing.

**Why this happened, and why it is the specification's fault rather than the build's.** The
cahier decomposes KODO into capabilities — a language, an editor, a canvas, a grader, a
tutorial engine — and each prompt was honoured exactly. None of them is *the application*,
so nobody built one, and no gate caught it because every gate measured modules. A
decomposition that names every organ and no body produces precisely this.

**Why M19 owns no learning logic (`FR-M19-06`).** The temptation, once a shell exists, is to
let it accumulate: a bit of routing logic becomes a bit of progression logic becomes a
second place mastery is decided. The one-AST rule has an organisational twin — there is one
grader, one mastery rule, one item bank, and the shell composes them. The requirement is
verified by a dependency test rather than by a promise.

**Consequence for G3.** G3's criterion ends *"running on the reference low-end device"*.
`FR-M19-01`, `02`, `03` and `05` are the requirements that make that sentence testable at
all. They are marked G3 and they are the critical path; `docs/governance/04_COMMITTEE_AND_DELIVERY_ORGANISATION.md`
assigns them to squad S1 under seat 9.

**What this decision is not.** It is not a new capability, a scope increase, or a change to
any existing requirement. Nothing in the eighteen modules changes. It names work that was
always necessary and was never written down.

**Consulted.** Seats 8 and 9 hold the architecture. Recorded as the PO's answer to a
specification gap found in delivery, and open to a reasoned objection until G4.

---

## D-013 — The visual universe is a module (M20), and a tab label is not a destination name

**Date.** 2026-09-19 · **Status.** Decided · **Scope.** Specification amendment (six
requirements) + one localisation ruling · **Requirements.** `FR-M20-01` … `FR-M20-06`

**The decision.** KODO's appearance is specified, built and tested like everything else in
this programme: `packages/kodo_art` holds the universe as geometry-as-data, the app paints
it, `tool/publish_art.dart` emits the same geometry as SVG, and six requirements say what
must be true of it. Separately, and as part of the same decision: **§9.1 names the five
destinations, and the child-facing label on a tab is allowed to be a different word.**

**Why art is a module and not a task.** D-012 found that eighteen prompts had specified
every organ and no body. Looking at the body once it existed showed the same gap one level
down: the map was thirteen grey rows, the first screen a child ever meets was one word in
the corner of a white page, and there was nowhere in the repository where a decision about
appearance could be written down, tested, or argued with. A children's product whose
appearance is undefined is not a product with a to-do item; it is a product with a missing
specification. So the appearance got one.

**Why geometry as data.** The same reason the language is one AST. Two drawings drift: a
PNG in the app and an SVG in the content pack become different pictures in the third
month, and nobody notices until a child does. One `Drawing`, two projections — a Flutter
`CustomPainter` and an SVG emitter — cannot drift, and the sentence a screen reader speaks
travels with the geometry rather than being attached to a file somebody may forget
(`FR-M20-02`, `FR-M20-03`). It also happens to cost 33 kB for the whole universe, which
matters on the 2 GB reference device and matters more to `R4`'s audio budget.

**The tab-label ruling, and the measurement behind it.** Five tabs across a 360 dp phone
give each label roughly ten characters a line. The M15 pseudo-locale run grows every
string by 40 % to stand in for a worse translation. *Entraînement* is twelve characters
before that growth, and the bar broke it as **"Entraîneme / nt"** — not a word in any
language. A soft hyphen was tried and merely moved the problem past the measurement.

The route, the enum constant, the navigation graph and every document keep the name
§9.1 gives the destination: **Entraînement**. What changes is the word printed under the
icon, which is now **"Défis" (fr) / "Practice" (en)**. A destination's architectural name
and a child's word for it are two different strings, and localisation is precisely the
discipline of not confusing them. §10's ban stands and is written into the string's
context note: no "test", "quiz", "exam" or "évaluation" may ever appear on that tab, in
any language.

**Why the PO is deciding a label at all.** Because the alternative was a squad quietly
widening a tab, shrinking a font below the accessibility floor, or shipping a broken word
— three decisions that look small and each of which breaks a committed requirement.

**What this decision is not.** It is not a change to §9.1, which still names five
destinations and still forbids a sixth. It is not a new capability. It does not change any
existing requirement, and no module's scope moves.

**Consulted.** Seats A1 (art direction) and A6 (colour and accessibility) of the Art
Committee; seat 10 holds localisation and the pseudo-locale run that produced the
measurement.

---

## D-014 — The language must be able to say what the curriculum teaches (M21)

**Date.** 2026-09-19 · **Status.** Decided · **Scope.** Specification amendment (six
requirements) · **Requirements.** `FR-M21-01` … `FR-M21-06`

**The decision.** M1's language gains **events, sensing and a stage**, because without them
three of the thirteen worlds cannot be written at all.

**How this was found.** By trying to author World 5. §5.2 says World 5 is *"green flag; key
pressed; click on sprite; two scripts at once"*, and there is no way to express any of it:
the opcode table has no event, no sensor and no sprite command, and a program is a single
linear script with a single continuation stack. World 8's *"sensing (touching, key,
mouse)"* and the whole of World 10 — *"sprite; costume switching & animation; sounds &
drums; backdrops; graphic effects"* — are in the same position. Between them that is
**three worlds and roughly 280 of the 1 214 committed exercises** that the language cannot
say.

**This is the third gap of the same shape, and that is the finding.** D-012 found that
eighteen module prompts specified every organ and no body. D-013 found that they specified
capability and no appearance. This one is narrower and sharper: **M1's prompt specified a
language against Worlds 0–4, and the curriculum runs to World 12.** Nobody compared the
opcode table with §5.2 line by line, because the two documents were written for different
readers and no gate reads both. The traceability checker now does — see `FR-M21-06`.

**What is added, and what is deliberately not.**

* **Events.** `quand <déclencheur> { … }` as a top-level script. Three triggers at v1:
  the green flag, a named key, and a click. A program becomes a *set* of scripts rather
  than one, which is what §5.2's *"two scripts at once"* means and cannot be faked by
  running them one after another — C5.4's whole point is that the child sees them
  interleave.
* **Concurrency, by stepping.** The interpreter is already step-resumable, because
  `FR-M1-05` asked for a stepped run that draws the same figure as a full-speed one. That
  property is what makes concurrency cheap and honest here: several scripts are several
  continuation stacks advanced in turn, sharing globals and one surface. No threads, no
  scheduler to explain to a nine-year-old, and a stepped run still draws what a full-speed
  run draws.
* **Sensing, deterministically.** A sensor reads from the item's scripted inputs, exactly
  as `demande` already does. A question a grader cannot answer the same way twice is not
  an exercise, so sensing that reads a real mouse is a Studio affordance and never an
  item's.
* **A stage is a capability, not a bigger Surface.** `Surface` stays as it is and
  `StageSurface` extends it. A canvas is not a stage, and a program that asks a canvas for
  a costume gets a sentence saying so rather than a crash. Every existing implementer keeps
  working, which is the test of whether an extension was designed or bolted on.
* **Not added:** networking, a physics model, collision between sprites beyond `touche`,
  or user-defined events. None is in §5.2 and each would need its own misconception
  ledger.

**Why the PO is deciding this rather than a squad.** Because the alternative was a squad
quietly writing World 5 out of the blocks that happen to exist, and shipping a world that
teaches something other than what the curriculum committed to — which is a change to the
product that looks like an authoring choice.

**What this decision is not.** It is not a change to any of the thirteen worlds, to the
mastery rule, or to the one-AST rule — which it in fact extends, since blocks and text
remain two projections of the same tree and events are a node in that tree like any other.

**Consulted.** Seats 8 and 9 (architecture), seat 5 (curriculum). Recorded as the PO's
answer to a specification gap found in delivery.

---

## D-016 — v1 ships no platform plugins

Full text: `docs/governance/D-016.md`.

**In one line.** No Flutter plugin that costs an Android permission ships in v1, which
closes out backdrop import (`FR-M4-04`), sound import and recording (`FR-M4-05`) and
screen capture (`FR-M9-05`) until at least v1.2.

**Why.** The G5 review measured something nobody had claimed: the release manifest asks for
**no permissions at all**, so the operating system — not a code review — is what stops the
process reaching the network, the camera or the microphone. That is the strongest form of
KODO's central promise, and each of those three requirements spends it. The consent gates
are built and tested; only the plugins are missing, and the plugins are the expensive part.

**What a child loses.** Nothing the curriculum needs: backdrops can be drawn, sounds are
made with `tambour` and `note`, and a drawing already exports as SVG and PNG.

**Enforced by** the manifest test in `app/test/m19_acceptance_test.dart` and finding
`G5-08` of `tools/verify_findings.dart`, both of which fail the build if a permission
appears.

---

## Open items the PO has *not* decided

Recorded so that silence is not mistaken for a decision.

| # | Item | Why it is not decided yet | Decide by |
| --- | --- | --- | --- |
| O-01 | The agreed budget line behind `NFR-COST-01` | Needs the D-001 licence model priced against real school counts in the launch markets | Before P2 |
| O-02 | Whether the family support tier of D-001 ever ships | Depends on whether the institutional lines cover marginal cost; deciding early adds a surface we may delete | Post-launch loop 1 |
| O-04 | iOS, macOS and Windows targets | Only Android, Linux and Web are configured. Adding a target is a market decision with a support cost, and nobody has taken it — recording it here so its absence stops looking like an oversight | Before the v1.2 scope is set |
| O-03 | Audio casting: two consistent FR and EN voices (§12) | Casting is a content decision belonging to seat 11, not a PO decision; the PO owns only the 15 % re-record reserve | Before World 0 narration freeze |
