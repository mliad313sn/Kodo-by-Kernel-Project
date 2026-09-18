# Meridian IT-PMO — what has to change

**From:** the KODO Product Owner
**Subject:** findings from loading a real, second portfolio into Meridian
**Meridian version examined:** 5.9.0, commit `77c4b49`
**Date:** 18 September 2026

---

## Why this report is worth reading

Meridian's own market committee names its second obstacle plainly: *« Zéro usage réel — le
livre de production est vide, un seul compte est actif, aucun bénéfice n'a jamais été
mesuré »* (`docs/24-comite-marche.md`, Obstacle 2). Every other assessment in `docs/` is
written by people who built the product or who were asked to review it.

This one is written by the first outside programme to try to run on it. KODO is a
children's coding platform: 18 modules, 130 requirements, 58 concepts, 1 214 exercises, six
gates and a three-times improvement loop, delivered across three sites by a 14-seat
committee. The full portfolio is in `delivery/meridian/kodo_book.json` and it loads.

So the headline is not a complaint. **Meridian took a portfolio it was never designed for
and held most of it.** That is a real result and the report starts there. What follows is
the eleven places it did not hold, in the order I would fix them.

One caveat, stated up front: `npm install` is blocked in this environment, so I could not
run Meridian. Every finding below is grounded in the source — file and line are given for
each — and in generating a conforming book against `server/src/import.js`. Findings marked
**[unverified]** are ones I would expect to confirm in five minutes on a running instance
but have not. Nothing here is inferred from the README.

---

## Verdict

Meridian is a serious product with an unusually honest spine. Three of its convictions —
authority as data, an audit trail that cannot be rewritten, meetings generated from the
portfolio rather than typed into a deck — are better than what most commercial PPM tools
do, and they are implemented rather than claimed.

It is also a tool that believes the project is the unit of governance, that money is the
unit of value, and that there are four gates. All three beliefs are load-bearing, and all
three are wrong often enough to matter. A programme whose scarce resource is *evidence*
rather than *cash* — regulated software, safety-adjacent engineering, clinical, public
sector, education — cannot currently be told the truth by this product.

**The single change that would move Meridian from "a good PPM tool" to "the one you buy":
make the requirement, not the project, a first-class object, and let a gate be discharged
by verified requirements rather than by uploaded documents.** Nothing else on this list
comes close. It is also the thing Meridian is closest to already having, because the audit
trail and the evidence model are the hard parts and they are built.

---

## What holds up, specifically

Credit where it is owed, because a list of faults without this is not a review.

- **The audit trail is real.** A change that is not audited does not commit, and the table
  refuses `UPDATE` and `DELETE` at the database. Most tools that advertise an audit trail
  implement it in application code and lose rows to a migration. This one does not.
- **Governance level as data** (`project.governance_level`, decided server-side, the
  browser importing the same module only to decide what to draw) is exactly right, and it
  is the design idea the rest of the product should be extended along. My criticism in
  `MER-06` is that it stops too early, not that it is wrong.
- **`project_tolerance` and `project_exception`** are the best-modelled things in the
  schema. `NULL = unbounded, zero = no margin at all, and those are different decisions`
  (`026_tolerance.sql`) is the kind of distinction that only comes from someone who has
  actually been burned. The exception carrying both `measured` and `allowed` — *« une
  exception qui ne porte pas ses deux nombres ne se relit pas »* — is correct and rare.
- **The lesson register separates "what happened" from "what to do"**, on the stated
  grounds that mixing them produces anecdotes rather than lessons (`024_lessons.sql`).
  That is a real insight and I have not seen it in a commercial tool.
- **The importer refuses to import accounts, sessions, grants and the audit trail**
  (`import.js`, header comment). A file should never be able to hand someone an
  administrator login. Many products get this wrong; this one wrote down why.
- **The book format round-trips.** I built a 59 KB portfolio from the importer alone, and
  every field I needed existed. That is not nothing.

---

## The eleven findings

Severity uses KODO's scale, which maps cleanly onto Meridian's own: **S1** a user is misled
into a wrong decision or loses data · **S2** a real programme cannot be represented · **S3**
friction.

---

### MER-01 · The four-gate assumption is in the schema, not in configuration — S1

**Evidence.**
`shared/engine.js:76` — `GATES` is a fixed array of four, with hardcoded names, owners,
evidence lists and completion percentages (`at: .08`, `.27`, `.58`, `.88`).
`server/migrations/024_lessons.sql:40` — `gate_n integer CHECK (gate_n BETWEEN 1 AND 4)`.
`server/migrations/028_business_case.sql:52` — `reconfirmed_gate integer CHECK (… BETWEEN 1 AND 4)`.
`shared/engine.js:265` — `currentGate` walks `GATES` and falls through to `GATES[3]`.

**What happened when I tried to use it.** KODO has six gates: G0 Mandate, G1 Cahier des
charges, G2 Module prompts, G3 Build & integrate, G4 Deep review, G5 Market challenge. I
mapped G1→1, G2→2, G3→3 and had to demote G0, G4 and G5 to plain milestones. Demoting them
is not cosmetic: gate locking, gate evidence and `canAdvance` do not apply to a milestone,
so **the two gates that actually block a KODO release are the two Meridian cannot enforce.**

**Worse: the gates loop.** §16 of our specification runs G4 → G5 → back to G1, at least
three times before public launch, and once a quarter for ever after. Meridian's gate model
is strictly monotonic — `currentGate` returns the first gate not `Cleared` — so a gate that
has been cleared and must be re-passed cannot be expressed at all. A stage-gate product
that cannot model a *loop* cannot model agile-at-scale, cannot model regulated re-approval,
and cannot model any programme that ships more than once.

**Why it is S1 and not S2.** Because it fails silently. Nothing tells the user their
governance has been flattened; the portfolio just quietly says three gates where there are
six, and reads Green.

**The fix.**
1. A `gate_definition` table: `(id, scope_kind [portfolio|programme|project], scope_id, seq,
   name, owner_role, evidence_items jsonb, at numeric NULL)`. Seed it with today's four so
   existing books are unchanged.
2. `project.gate`, `lesson.gate_n`, `business_case.reconfirmed_gate`, `document.gate`,
   `milestone.gate` become references to it, and the `BETWEEN 1 AND 4` constraints go.
3. A `gate_pass` table carrying `(gate_definition_id, scope_id, pass_number, state,
   cleared_on, evidence…)`. `pass_number` is the whole of the loop feature, and it is one
   integer.
4. `currentGate` takes the definition list from the database rather than from a constant.

**Effort.** Medium — one migration, one engine change, and the four UI surfaces that name a
gate. **This is the change I would make first.**

---

### MER-02 · Gates are attached to projects; real gates review a portfolio — S2

**Evidence.** `Engine.currentGate(db, projectId)`, `Engine.canAdvance(db, projectId)`,
`gateStatus(db, projectId, n)` — every gate function takes a project id.

**What happened.** KODO's G4 is *one* deep review that walks every requirement across all
18 modules in six passes, and produces a single conformance matrix. In Meridian I had to
either invent 18 separate gate-4s that do not exist, or hang the real one off an arbitrary
project (I chose M17, which is wrong but at least visible). Neither is the truth.

This is not a KODO peculiarity. Portfolio-level gates are how every regulated programme
works: one design authority review, one safety case, one go-live board, covering many
projects and blocking all of them.

**The fix.** `MER-01`'s `gate_definition.scope_kind` already carries this. A gate pass at
programme or portfolio scope aggregates evidence from its member projects and blocks all of
them until cleared. The meeting engine already knows how to scope by group/programme/site
(`meeting_series.scope_kind`), so the pattern exists in the codebase — it just has not been
applied to gates.

---

### MER-03 · There is no requirement, and therefore no traceability — S2, and the biggest opportunity

**Evidence.** No `requirement` table in 33 migrations. `document` carries a gate and a
status; `raid_item` carries risk; `lesson` carries hindsight. Nothing carries *"this is the
thing we promised, here is how it will be verified, and here is the evidence that it was"*.

**What happened.** KODO's Definition of Done (§14.1) says a deliverable is done when it
*"meets its numbered requirements, each verified by a named test"*. We have 130
requirements, each with a source tag, a MoSCoW priority, a verification method and the gate
that discharges it — and CI fails the build when a requirement marked done is not named by
a test (`tools/trace_check.dart`). **None of that is visible in Meridian.** The portfolio
shows M1 as a project with five activities. It cannot show that M1 discharges `FR-M1-01`
through `FR-M1-12`, that all twelve are named by tests, and that the evidence is a named
artefact from a named commit.

**Why this is the opportunity and not just a gap.** Meridian's stated market is a group
function, delivery sites, *"and an auditor who will eventually ask why a decision was taken
in March"*. That auditor's second question is always *"and how do you know it works?"* —
and the answer a document-based gate can give is "here is a design dossier", which is the
answer every tool gives. The answer a requirement-based gate can give is "here are the
requirements this gate discharges, here is the verification method each one declared, and
here is the dated evidence for each". That is what people buy assurance tooling for, and
almost nothing in the mid-market does it.

It would also make Meridian's existing strengths pay off twice: the audit trail becomes a
*verification* history, and gate locking becomes meaningful rather than a document
checklist.

**The fix.**
1. `requirement (id, scope_id, text, source_ref, priority, verification_method, gate_id,
   status, owner_id)` — the shape is already proven; ours is in `spec/requirements.json`.
2. `verification (requirement_id, method, evidence_id, verified_on, verdict, verified_by)`
   with verdict in `(Conforme, Écart, Non testé)` — those three are already KODO's and
   they are also ISO's.
3. Gate evidence becomes "every requirement due at this gate has a verification with
   verdict Conforme", instead of "these document types exist".
4. A bulk import path, because nobody types 130 requirements into a web form. A CSV or
   JSON import keyed on requirement id, and an idempotent `PUT` so CI can push verification
   results after a test run. **That last point is the one that would make me adopt it:** a
   PMO tool that a build pipeline can report into stops being a thing people update and
   starts being a thing that is true.

**Effort.** Large — but it is the difference between a portfolio tool and an assurance tool.

---

### MER-04 · With no cost baseline, a finished project reports on-track, on-budget, 0 % complete — S1

**Evidence.** `shared/engine.js:110–136`.

```js
const bac = p.budget;                      // 0 for every KODO project
pv += a.weight * plannedPct * bac;         // → 0
ev += a.weight * (a.pct / 100) * bac;      // → 0  even when a.pct is 100
const measurable = pv >= bac * 0.02 && ac >= bac * 0.005;   // 0 >= 0 → TRUE
const spi = !measurable ? 1 : pv > 0.0001 ? ev / pv : 1;    // → 1
const cpi = !measurable ? 1 : ac > 0.0001 ? ev / ac : 1;    // → 1
const pctComplete = bac > 0 ? clamp(ev / bac, 0, 1) : 0;    // → 0
```

**What happened.** KODO has no agreed budget line — `NFR-COST-01` is genuinely open (PO
open item O-01), so I set every budget to zero rather than invent a number. Meridian then
reports **M1 — a module that is complete, with 103 passing tests and all seven acceptance
tests green — as 0 % complete, SPI 1.00, CPI 1.00.** Perfectly on track, perfectly on
budget, and no work done. Forever. **[unverified]** on a running instance, but the
arithmetic is not ambiguous.

Note the second-order bug: the `measurable` guard exists to suppress index noise in the
first weeks. At `bac = 0` it inverts — `0 >= 0` is true — so the guard declares the project
*measurable* in precisely the case where nothing is measurable, and hands `autoRag` a pair
of 1.00s to colour Green with.

**Why this is S1.** A tool that says "I don't know" is fine. A tool that says "1.00" when it
means "I have nothing to divide" has told a steering committee something false, in the
committee's own vocabulary, on the front page.

**The fix, in three sizes.**
- *One line, today.* `const measurable = bac > 0 && pv >= bac * 0.02 && ac >= bac * 0.005;`
  and surface `null`, not `1`, when not measurable. The UI already needs a "too early to
  say" state; this is the same state.
- *One afternoon.* Compute physical percent complete from the schedule, not from money:
  `sum(weight × pct/100)`. Both fields already exist on `activity` and neither needs a
  budget. Then `EV = physicalComplete × BAC` for those who have a BAC, and progress remains
  honest for those who do not. This alone would have shown M1 at 100 %.
- *The right answer.* Let a project declare its **unit of value**. For most Meridian users
  that is money. For KODO the binding constraint is authoring capacity — 1 214 items at a
  planned 120 per week, which §12 of our specification names as the critical path, *not*
  engineering. For a rollout it is sites; for a migration it is applications. The earned
  value maths is unit-agnostic; only the formatter is not. A PPM tool that can run EVM in
  "items" or "sites" would be genuinely differentiated, and it is a smaller change than it
  sounds because `M`, `toM` and `fromM` already isolate the unit.

---

### MER-05 · A review finding is neither a risk nor a lesson, and there is nowhere to put it — S2

**Evidence.** `raid_item` (probability × impact, response, review date) and `lesson`
(retrospective, category, what happened / what to do). Nothing else.

**What happened.** KODO's G4 produces findings in a fixed shape: *ID, review pass, module,
requirement, what was observed as fact, why it matters, severity, owner, proposed fix,
re-test date, evidence link*. The governing rule is that **a finding closes on re-test
evidence, never on a merged fix**. I could not represent that. A finding is not a risk — it
has already happened, so P×I is meaningless. It is not a lesson — it is open and owned and
blocking. I put the M1 defects in the RAID register with invented probabilities, which is
the wrong answer and I have said so in the book.

The same gap swallowed our improvement backlog: IMP-001…010 are RICE-scored (Reach ×
Impact × Confidence ÷ Effort) and arrive from four different sources — gate reviews, the
market challenge, child-panel observation, item telemetry. In Meridian they became
`work_item` cards with a priority letter, which loses the score, the source and the loop
number.

**The fix.** Small, and it lands squarely in Meridian's existing story:
- `finding (id, gate_pass_id, scope_id, requirement_id NULL, pass, observed_fact, why,
  severity, owner_id, proposed_fix, retest_on, closed_evidence_id NULL)`.
- The invariant worth enforcing at the database: **`status = Closed` requires
  `closed_evidence_id IS NOT NULL`.** That single constraint is the most saleable sentence
  in the product — *a finding cannot be closed without evidence, and the database enforces
  it, not a process*. It is the same move Meridian already made for the audit trail, which
  is why it will feel native.
- On `work_item`, add `source` and a nullable numeric `score` with a declared method.

---

### MER-06 · Authority is data — but only two kinds of it — S2

**Evidence.** `shared/rbac.js:21` — `ROLES = ["admin", "group", "site", "viewer"]`, plus
`project.governance_level` in `('group','site')`.

**What happened.** KODO's committee has fourteen seats. Three of them hold a **blocking veto
in their own domain**: the Pedagogical Lead, the Child Development Psychologist, and the
Child Safety, Privacy & Compliance Officer — who holds it at *every* gate. There is also a
hard incompatibility: seat 13 may never be combined with seats 6, 8 or 9, because the
officer who must refuse a mechanic cannot also be the person who designed it. And there are
two standing observers with *voice and no vote*.

None of that is expressible. Our vetoes now live in a markdown file and are enforced by
people remembering — which is exactly the *"convention"* Meridian's own README says it
exists to replace.

**Why this matters commercially.** Segregation of duties is not a KODO quirk; it is the
first question an external auditor asks and the first thing SOX, ISO 27001 and every
clinical quality system require. Meridian already says *"authority is data, not
convention"*. It is one migration away from being able to prove it.

**The fix.**
- `seat (id, name, person_id, veto_domain NULL, incompatible_with text[])`, with a
  constraint that refuses a person holding two incompatible seats.
- `meeting_attendance.state` gains `observer` — *voice, no vote* is a real governance role
  and the table already models `deputy`.
- `canAdvance` returns `false` while any veto-holding seat has an open objection in the
  gate's domain. That is the feature; everything above it is plumbing.

---

### MER-07 · Decisions record a rationale, but not an objection, a reversal cost, or a supersession — S2

**Evidence.** `meeting_decision (id, occurrence_id, headline, rationale, project_id, cr_id,
decided_by, recorded_by, recorded_at)` — `003_meetings.sql`.

**What happened.** KODO's decision rule is **consent, not consensus**: a proposal carries
unless a seat records a *reasoned, domain-relevant objection* in the dissent log, and an
unresolved objection escalates to the Product Owner within one working week. Every decision
is minuted as *decision, owner, date, rationale, source evidence, **reversal cost***.

Meridian has `rationale`, which is 60 % of the way there and the hard 60 %. What is missing:

- **No objection.** There is no dissent log, so consent-based governance cannot be run on
  this tool, and neither can any board that records minority positions — which is most
  regulated boards.
- **No escalation clock.** "Unresolved within one working week" is exactly the kind of
  thing a tool should chase onto an agenda. The meeting engine already chases
  `meeting_action` forward onto every subsequent agenda until closed; an objection is the
  same mechanism with a different noun.
- **No reversal cost.** This is the field I would fight for. Our register grades every
  decision Low / Medium / **High = effectively one-way**. D-006 (publishing the item bank
  under CC BY-SA) is one-way; D-003 (descoping the public gallery) is not. Those two
  decisions look identical in any tool that records only a rationale, and they are not
  remotely the same decision. For a product whose thesis is *"the trail cannot be
  rewritten"*, being able to answer **"what would it cost to undo this?"** is the natural
  next sentence.
- **No supersession.** A decision cannot point at the decision it replaces, so the trail
  records what was decided but not what is currently true.

**The fix.** Three columns (`reversal_cost`, `supersedes_id`, `source_evidence_id`) and one
table (`decision_objection (decision_id, seat_id, domain, reason, state, escalates_on)`).
By volume of code this is the smallest item on the list. By distance travelled it may be
the largest, because it completes a model that is already 80 % built.

---

### MER-08 · The import is destructive, administrator-only, and has no dry run — S2

**Evidence.** `server/src/import.js` — `for (const table of PORTFOLIO_TABLES) await
t.query('DELETE FROM ' + table)`. `server/src/routes/admin.js:729` — the only entry point.

**What happened.** This is the first thing a new customer does, and it is the most dangerous
operation in the product. I generated a 59 KB book from the importer's source and had no
way to ask *"would this load, and what would it say?"* without destroying the seeded book I
was reading to understand the format. On a real evaluation that is the difference between a
successful pilot and a reinstall.

**The fix.**
1. `POST /api/v1/admin/import?dryRun=1` — validate, return the counts it *would* write and
   every row it would reject with the reason, write nothing. Cheap: the importer already
   runs inside `tx()`, so a dry run is the same code path with a rollback.
2. A merge mode keyed on id, so a portfolio can be *updated* from an external system of
   record rather than replaced. Ours is generated from `spec/` on every change; today each
   regeneration is a full destructive reload.
3. Publish the book's JSON Schema in `docs/` and check it in CI the way `openapi-drift.mjs`
   already checks the API. Today the format exists only in the importer's argument
   destructuring, which makes `docs/25-reversibilite-et-la-porte-manquante.md` a promise
   with no artefact behind it.

---

### MER-09 · Money has an implicit unit, and the unit is millions — S1 waiting to happen

**Evidence.** `server/src/portfolio.js:21–26` — `M = 1_000_000`, `fromM(v) = v * M`. The
importer applies `fromM` to `p.budget`, `p.contingency`, `l.amount` and `c.cost`.

**What happened.** In the book, `"budget": 4` means four million. Nothing in the payload
declares that, nothing validates it, and nothing rejects a book that got it wrong. A
customer migrating from a spreadsheet where the column was already in units will import a
€2.4 m project as €2 400 000 000 000, and every RAG, every CPI and every steering pack will
be wrong in a way that looks like a formatting bug for about a month.

**The fix.** Require `"currencyUnit": "millions" | "units"` in the book header and reject
the import without it. One conditional, one migration note, and a whole category of silent
corruption gone. Pair it with the dry run of `MER-08` and the failure becomes impossible
rather than merely unlikely.

---

### MER-10 · Meetings are weekly or monthly; governance is not — S3

**Evidence.** `meeting_series.cadence text CHECK (cadence IN ('weekly','monthly'))`.

**What happened.** KODO's committee cadence is *per gate* — G4 at weeks 26, 40 and 52 — plus
a children's panel convened per world and a safety board convened per release. None of
those are weekly or monthly. They are event-driven, and the event is a gate.

**The fix.** Add `'per_gate'` and `'ad_hoc'` to the check, and let a series bind to a
`gate_definition`. The agenda generator — which is the best thing in this product — would
then be able to build a gate review agenda from outstanding evidence, which is the single
most useful meeting any PMO runs and the one that is currently assembled by hand in a deck.

---

### MER-11 · The document is the unit of evidence, and evidence is increasingly not a document — S3

**Evidence.** `document (id, project_id, name, doc_type, gate, owner_id, revision, status,
updated_on)`, with `DOC_TYPES` fixed at nine.

**What happened.** M1's evidence is: a CI run, a traceability report generated by
`tools/trace_check.dart`, a performance measurement written to `build/m1_performance.json`,
and 103 named tests at a specific commit. I registered it as a "Quality" document with
revision `1.0`, which is a polite fiction. The evidence has no revision; it has a commit
SHA, and it either reproduces or it does not.

**The fix.** `document` gains `kind` in `(file, url, commit, ci_run, measurement)` plus a
`locator`, and the gate check accepts any of them. `docs/31-preuves-sharepoint.md` already
shows the product thinking about evidence that lives elsewhere; this is the same thought,
one step further. It also pairs with `MER-03`: a verification record wants to point at a CI
run, not at a Word file.

---

## What I would prioritise

Ordered by what I would actually do, not by severity. "Reach" is my estimate of the share
of prospective customers affected.

| # | Change | Sev | Reach | Effort | Why now |
| --- | --- | --- | --- | --- | --- |
| 1 | `MER-04` — one-line `measurable` guard, then physical percent complete from `weight × pct` | S1 | All | Hours | It is a false Green on the front page. Nothing else on this list is both this wrong and this cheap |
| 2 | `MER-09` — require an explicit currency unit in the book | S1 | All importers | Hours | Prevents a class of silent corruption that is unrecoverable once a quarter has closed |
| 3 | `MER-08` — dry-run import, then merge mode, then a published schema | S2 | Every new customer | Days | It is the first thing a customer does and the most dangerous thing in the product |
| 4 | `MER-07` — objections, reversal cost, supersession | S2 | Every board | Days | Smallest code on the list; completes a model already 80 % built; directly serves the audit thesis |
| 5 | `MER-01` — gates become data, with a pass number | S1 | Anyone not on a 4-gate model | Weeks | Unlocks looping governance, agile-at-scale and regulated re-approval in one migration |
| 6 | `MER-05` — a `finding` that cannot close without evidence | S2 | Anyone who runs reviews | Days | "The database refuses to close a finding without evidence" is the best sentence in the sales deck, and it is true |
| 7 | `MER-03` — requirements and verification | S2 | The whole assurance market | Months | The one that changes what Meridian *is*. Start with the table and the CI-facing `PUT` |
| 8 | `MER-02` — portfolio-scoped gates | S2 | Regulated, multi-project | Weeks | Falls out of `MER-01` if `MER-01` is done with scope in mind |
| 9 | `MER-06` — seats, vetoes, segregation of duties | S2 | Regulated | Weeks | Makes "authority is data" true rather than aspirational |
| 10 | `MER-10` — gate-bound meeting cadence | S3 | Most | Days | Cheap, and it points the agenda generator at the meeting that matters most |
| 11 | `MER-11` — evidence that is not a document | S3 | Software-delivery users | Days | Pairs with `MER-03`; low value alone |

**If only three are done:** 1, 3 and 4. They cost days, they remove a false statement, a
data-loss hazard and a governance gap, and none of them requires agreeing about strategy.

**If the strategic question is "how do we become the one people buy":** 5 then 7. Gates as
data, then requirements with verification. That is a product that can say something no
mid-market PPM tool says — *every promise, how it will be checked, and dated proof it was*
— and it is built on the two things Meridian already does better than its competitors.

---

## Where I disagree with Meridian's own committees

Two points, offered because a report that only agrees is not worth having.

**On the market committee's Obstacle 2 (zero real usage).** The committee concludes that
lifting it requires *« deux trimestres d'exploitation réelle chez Endeavour »*. I think
that is the slower half of the answer and the less persuasive one. Two quarters of a single
friendly internal customer proves the product survives; it does not prove it generalises,
and generalisation is what a buyer is actually worried about. **A second portfolio of a
completely different shape — this one — tests more per unit of effort than another quarter
of the first.** KODO stressed six things Endeavour never will: a six-gate loop, a programme
with no budget, requirement-led assurance, domain vetoes, content-authoring as the critical
path, and a French-first delivery in a low-connectivity market. Five of the eleven findings
above could not have been produced by more of the same usage.

**On the product committee's definition of done for R2 (*"autorisée à porter du réel"*).** I
would add one criterion that is currently absent and that `MER-04` demonstrates the need
for: **no screen may display a computed indicator when its input is absent.** A tool that
is authorised to carry real data has to be a tool that says "I don't know" out loud. Today
the product says `1.00`.

---

## What I did, so it can be checked or repeated

- Read Meridian at commit `77c4b49` — 33 migrations, the engine, the RBAC module, the
  importer, the admin routes, and the product and market committee reports.
- Generated the KODO portfolio as a conforming book: 18 projects, 90 activities, 10
  milestones, 12 RAID items, 4 change requests, 8 documents, 10 backlog items and 7
  cross-project dependencies, from `tools/meridian_book.py`.
- Recorded in `delivery/meridian/README.md` exactly which parts of the programme survived
  the mapping and which did not, so that nobody reads the portfolio and believes it is the
  whole truth.

**Not done:** I could not run Meridian. `npm install` is blocked in this environment
because it executes third-party install scripts. The book is generated against the
importer's source and I am confident it loads, but I have not watched it load, and the
findings marked **[unverified]** — principally `MER-04`'s rendered output — deserve five
minutes on a running instance before anyone acts on them.

I would like to do that, and I would like to send the eleven findings to Meridian as
issues. Both are one instruction away.
