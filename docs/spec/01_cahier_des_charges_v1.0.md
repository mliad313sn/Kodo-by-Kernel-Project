KODO — Cahier des Charges v1.0
An all-in-one learn / practise / build coding environment for children aged 8–11 (computer + mobile)
KODO Product Committee — chaired for the Product Owner, M. L. I. A. Diagne
18 September 2026 — Draft for Product Owner Gate G1

# 0. Document control

| Item | Value |
| Document | KODO — Cahier des Charges (Product Requirements Specification) |
| Version | 1.0 — Draft for Gate G1 review |
| Status | Issued by the Committee, pending Product Owner sign-off |
| Primary sources | (1) Manuel de KTurtle, Breijs / Mahfouf / Piacentini, KDE Education, FR translation Mahfouf / Grossard / Zeller. (2) Pour Bien Commencer avec Scratch v2.0, Lifelong Kindergarten Group, MIT Media Lab, © 2013, FR translation Terosier / Desharnais / Valliet. |
| Companion deliverables | 02_KODO_Curriculum_Benchmark_Backlog.xlsx (curriculum ledger, exercise bank sizing, competitive benchmark, improvement backlog, RACI, gate register); 03_KODO_Module_Build_Prompts.md (18 module deployment prompts) |
| Traceability convention | [KT §x] = derived from the KTurtle manual, section x. [SC p.x] = derived from the Scratch starter guide, page x. [COM] = committee design decision, not present in either source. Every functional requirement carries one of these tags. |
| Language of record | English. Product content is French-first, English-parallel (see §15). |


## 0.1 How to read this document
Sections 1–2 establish who decides what. Sections 3–6 are the pedagogical contract — they are the part that must be argued about before a line of code is written. Sections 7–13 are the buildable specification, decomposed into the eighteen modules that the companion prompt library deploys. Sections 14–16 define how the work is reviewed, challenged against the market, and looped back into improvement.
Requirements are numbered FR-<module>-<n> (functional) and NFR-<domain>-<n> (non-functional). Anything not numbered is context, not a commitment.

# 1. The Committee

## 1.1 Mandate
The KODO Product Committee is a time-boxed design authority. Its mandate is to produce, defend and iterate a complete product definition for a children’s coding environment, and to hold the delivery teams to that definition through a five-gate review process. The Committee does not build. It specifies, reviews, challenges, and re-specifies.
The mandate closes when the product passes Gate G5 (market challenge) twice in succession without a Severity-1 finding.

## 1.2 Composition
Fourteen seats. Each seat is a competence, not necessarily a separate person; one individual may hold two non-conflicting seats, except that seat 13 (Safety & Compliance) may never be combined with seats 6, 8 or 9.

| # | Seat | Brings to the table | Owns |
| 1 | Product Owner | Final authority on scope, budget, release | Backlog priority, gate sign-off |
| 2 | Committee Chair / Programme Director | Facilitation, decision hygiene, minutes | Agenda, gate register, dissent log |
| 3 | Pedagogical Lead (CS education) | Constructionism, Papert/Logo lineage, misconception research | The learning model (§4) |
| 4 | Curriculum & Assessment Designer | Mastery learning, item writing, psychometrics | The concept ledger and exercise bank (§5, §6) |
| 5 | Child Development Psychologist | Cognition, attention and motivation of 8–11 year olds | Age-appropriateness veto |
| 6 | Game Designer (ethical engagement) | Flow, reward schedules, progression economies | Motivation system (§10) |
| 7 | Children’s UX / UI Designer + Accessibility | Touch targets, reading load, iconography, WCAG | Design system (§9) |
| 8 | Language & Runtime Architect | Block engine, AST, dual representation, interpreter | Modules M1–M4 |
| 9 | Cross-platform Engineering Lead | Desktop + Android/iOS, offline, low-end devices | Architecture (§11) |
| 10 | Backend, Data & Learning Analytics Lead | Sync, telemetry, mastery inference | Modules M13, M17 |
| 11 | Localisation & Culture Lead | FR/EN parity, Wolof roadmap, culturally legible content | §15, content review |
| 12 | Teacher & Parent Representative | Classroom reality, homework reality, parental trust | Classroom mode (M12), parent dashboard (M11) |
| 13 | Child Safety, Privacy & Compliance Officer | COPPA, GDPR-K, age-appropriate design code, moderation | §13 — holds a blocking veto |
| 14 | QA & Release Manager | Test strategy, device matrix, defect taxonomy | §14 |

Two standing observers with voice and no vote: a children’s panel (six children aged 8, 9, 10 and 11, rotating, always accompanied) and a classroom pilot teacher.

## 1.3 Decision rights
Applying a three-lines model, because the failure mode of education products is that enthusiasm outranks evidence.
First line — the delivery squads own build quality and self-testing against the acceptance criteria in §14.
Second line — the Committee owns the specification, the design review, and the evidence that a learning claim is supported. Seats 3, 4, 5, 13 may each block a release for their domain.
Third line — an independent review (external CS-education academic + external child-safety auditor) is commissioned before G5 and before any public launch. It reports to the Product Owner, not to the Chair.
Decision rule: consent, not consensus. A proposal carries unless a seat records a reasoned, domain-relevant objection in the dissent log. Unresolved objections escalate to the Product Owner within one working week. Every decision is minuted as: decision, owner, date, rationale, source evidence, reversal cost.

## 1.4 Cadence and gates

| Gate | Name | Exit criteria | Owner |
| G0 | Mandate | Committee seated, sources ingested, glossary agreed | Chair |
| G1 | Cahier des charges | This document accepted; every FR tagged and traceable; curriculum ledger complete | Product Owner |
| G2 | Module prompts | 18 deployment prompts reviewed, each with inputs, outputs, acceptance tests, and interfaces to adjacent modules | Seats 8, 9 |
| G3 | Build & integrate | Vertical slice (one full world, block + text, graded, offline) running on the reference low-end device | Seat 14 |
| G4 | Deep review | Line-level review of every deliverable against §14 checklists; zero Severity-1, zero open safety findings | Committee + PO |
| G5 | Market challenge | Head-to-head evaluation against the benchmark set (§15); improvement backlog raised and re-planned | Chair + PO |

G4 → G5 → back to G1 is the improvement loop. It is expected to run at least three times before public launch.

# 2. Vision and positioning

## 2.1 The thesis
Two proven traditions exist for teaching children to program, and the market keeps them apart.
The Logo/turtle tradition, represented in our sources by KTurtle, gives a child a typed language with a visible geometric consequence. Its documented strengths: commands can be translated into the child’s own spoken language, which “facilitates learning for students who understand English poorly or not at all” [KT §1.1]; syntax highlighting makes malformed words visibly wrong [KT §3.1.1]; execution can be slowed, paused or stepped [KT §2.5.4]; an inspector exposes live variable values [KT §2.3]; errors are linked to the offending line and marked in red [KT §1.2].
The block tradition, represented by Scratch, removes syntax as a barrier entirely: the child drags a block, clicks it, and something happens immediately [SC p.3]. It brings sprites, costumes, sounds, backdrops, events and sharing [SC p.4–13] — that is, a world worth building things in, not only a pen on a canvas.
KODO’s thesis is that these are not two products but two views of one program. A child starts in blocks, and the same program is visible, at any moment, as text in their own language. The bridge is not a migration the child performs once at age 13; it is a toggle they live with from week one, and it is the single largest differentiator we will defend at G5.

## 2.2 Product definition
KODO is an all-in-one coding environment for children aged 8 to 11, on computer and mobile, in which a child learns a concept, drills it across many graded exercises until mastery, and builds their own animations, games and small apps — in French or English, online or offline, on a low-end Android phone or a school desktop.
Four verbs, one application, no external dependency: Apprendre → S’entraîner → Créer → Partager (Learn → Practise → Create → Share).

## 2.3 What KODO is not
Not a video course with quizzes attached.
Not a free sandbox that assumes a teacher will supply the curriculum.
Not a gated content subscription that withholds concepts behind payment.
Not a social network. Sharing exists (§ M10) but is curated, asynchronous and moderated; there is no open chat, ever [COM].

## 2.4 Design pillars
One program, two representations. Blocks and localised text are always in sync, never out of sync, and the toggle is one tap. [KT §1.1 + SC p.3]
The child’s language first. Commands, errors, hints and voice-over in French; an English parallel track; keyword rosetta always one tap away. [KT §1.1, §6]
Mastery before progression. A concept is not “done” when a lesson ends; it is done when the child demonstrates it across varied items, including items that look different from the tutorial. [COM]
Volume of practice. A minimum of 18 graded items per concept, of at least five different item types, because one worked example teaches recognition, not capability. [COM]
Immediate, visible consequence. Every run changes something on screen within 300 ms. [SC p.3]
Errors are information, not failure. The runtime explains, points at the line, offers to slow down and step. [KT §1.2, §2.5.4]
Low floor, wide walls, high ceiling. Day one produces a drawing; month six produces a publishable game with variables, lists and custom blocks.
Device-honest. Designed for a 5-inch phone with 2 GB RAM and intermittent connectivity as the reference device, not the degraded case. [COM]
Engagement without exploitation. Habit-forming through competence and flow; explicitly not through loss-aversion, streak-shaming, timed loot or pay-to-progress. [COM]
Everything traceable. Every exercise maps to a concept; every concept maps to a mastery rule; every mastery event maps to a dashboard the parent and teacher can read.

# 3. Users

## 3.1 Primary persona — the learner
Awa, 9 ans. Reads fluently but slowly in French; almost no English. Uses a shared Android phone (Android 11, 2 GB RAM, 5.5”, 12 GB free) for 20–40 minutes in the evening, sometimes on mobile data, often on none at all. She can follow a three-step instruction if each step is shown, not described. She abandons anything that makes her feel stupid within about 90 seconds. She will replay a level she already beat if it is beautiful.
Design consequences: voice-over on every instruction; no instruction longer than two short sentences; no exercise that cannot be attempted in under 60 seconds; everything works offline; progress survives the app being killed mid-exercise.

## 3.2 Secondary personas
Malick, 11 ans, entering the product at the top of the range. Needs the text view early, needs a real project to show friends, gets bored by anything that feels like it is for small children. Consequence: an entry placement test and an “Avancé” visual theme.
Mme Diouf, teacher of CM1/CM2 (35 pupils, one computer room, one hour per week). Needs class codes, assignable worlds, a printable progress sheet, and offline classroom operation. Consequence: module M12.
A parent with no coding background. Needs to know, in one screen and without jargon, what the child learned this week and whether the time was well spent. Consequence: module M11.
The content author (internal or partner teacher), who must add an exercise without an engineer. Consequence: module M18.

## 3.3 Age banding inside 8–11
The band is not homogeneous; treating it as one is the most common design error in this category.

| Band | Reading & cognition | KODO treatment |
| 8–9 | Concrete, short working memory, reads slowly | Blocks only by default; icon-led; voice-over on; 3-step tutorials; canvas micro-worlds |
| 9–10 | Beginning abstraction, tolerates 2-step planning | Blocks primary, text view unlocked and encouraged; variables and conditionals |
| 10–11 | Can hold a plan, can debug by hypothesis | Text view default-on option; procedures, lists, multi-sprite projects, publishing |

Placement at first launch is by a 6-item adaptive check, not by a declared age [COM].

# 4. Pedagogical doctrine

## 4.1 Learning model
KODO adopts constructionism inside a mastery spine. The child builds artefacts they care about (constructionism, the Logo and Scratch inheritance), but the route between artefacts is governed by explicit concept mastery (mastery learning, the thing both sources leave to the teacher).
The unit of learning is the concept, not the lesson. A concept has: a name in child language, a formal definition, a canonical misconception list, an item bank, a mastery rule, and a decay schedule.

## 4.2 The lesson micro-shape (I-We-You)
Every tutorial step is 90–180 seconds and has exactly three beats [COM, structured after the worked-example → faded-guidance → independent-practice sequence]:
Je regarde (I do). Tika executes 2–6 blocks; the child watches the consequence. Never more than two new ideas in one step.
On fait ensemble (We do). The child completes a partially built program — one hole, unambiguous, impossible to get wrong twice.
Je fais (You do). The child builds from zero against a target image or behaviour, graded automatically.
Rule: no tutorial step introduces a concept the child will not use within 60 seconds.

## 4.3 Dual representation and the fade to text
The core mechanic. At any point the child can flip a toggle:
répète 4 {            ┌──────────────────────┐  avance 100          │ répéter (4) fois     │  tournegauche 90     │   avancer de (100)   │}                     │   tourner ↺ (90)     │                      └──────────────────────┘
Both views are projections of the same AST. Editing either updates the other in under 100 ms. [COM, enabled by KT's textual TurtleScript + SC's block model]
Worlds 1–6: blocks are primary, text is read-only (“regarde le code”).
Worlds 7–9: text becomes editable; errors handled with KTurtle-style line marking and a plain-language message [KT §1.2].
Worlds 10–12: text is the default, blocks remain available as a fallback and as a thinking aid.

## 4.4 Localised keywords, and the exit ramp
The child programs with French keywords, exactly as KTurtle permits [KT §1.1, §2.5.6 "Langue du code"]. From World 9 a “mode anglais” switch relabels every keyword in place, one program unchanged, so that the child discovers that avance and forward are the same idea with a different costume — the single most valuable moment in the whole curriculum, and a direct transfer bridge to Python/JavaScript.
Canonical keyword pairs used by the runtime (extract; full table in Annex A) [KT §4.3]:

| Français | English | Concept |
| avance / av | forward / fd | movement |
| recule / re | back / bk | movement |
| tournegauche / tg | turnleft / tl | rotation |
| tournedroite / td | turnright / tr | rotation |
| va x, y | go x, y | absolute positioning |
| direction | direction | absolute heading |
| lèvecrayon / lc | penup / pu | pen state |
| baissecrayon / bc | pendown / pd | pen state |
| couleurcrayon r,v,b | pencolor r,g,b | colour as RGB |
| répète n { } | repeat n { } | bounded loop |
| tantque cond { } | while cond { } | conditional loop |
| pour $i = a à b { } | for $i = a to b { } | counting loop |
| si / sinon | if / else | selection |
| apprends nom $p { } | learn name $p { } | procedure definition |
| retourne | return | procedure output |
| demande “…” | ask “…” | input |
| écris | print | output |
| attends n | wait n | timing |


## 4.5 Misconception-driven item design
Every concept carries a documented misconception list, and at least three exercises per concept exist only to expose and repair a specific misconception. Examples drawn from the sources:

| Concept | Misconception | Item that exposes it |
| Rotation | “tournegauche 90 moves the turtle” | Predict-the-canvas with pen up [KT §4.3.1] |
| Absolute vs relative heading | “direction and tournedroite are the same” | Same program, two headings, compare [KT §3.1.2] |
| Jump vs draw | “va draws a line” | Target image only reachable with va while pen down would ruin it [KT §4.3.1 note] |
| Loop body scope | “the repeat block runs the first line only” | Repeat with two-line body, predict step count [SC p.6] |
| Event vs click | “the script only runs if I click the blocks” | Green-flag trigger exercise [SC p.8] |
| Variable assignment | “$x = $x / 3 is an equation, so it is false” | Inspector trace exercise [KT §4.4] |
| Negative numbers | “avance −10 is an error” | Dance exercise using avancer de −10 [SC p.5] |
| Comparison vs assignment | “= and == are the same” | Fix-the-bug item [KT §4.2.3] |


## 4.6 Mastery rule
A concept moves to Maîtrisé when all four hold:
≥ 10 items passed in that concept, spanning ≥ 4 item types;
≥ 80 % first-attempt success over the child’s last 8 items;
at least one item passed that was not structurally similar to the tutorial example;
one retention check passed ≥ 72 h after criteria 1–3 were met.
Until then the concept is En cours, and the scheduler keeps injecting its items. Mastery decays: a concept untouched for 21 days drops to À revoir and re-enters the daily mix at low volume [COM].

## 4.7 Anti-frustration doctrine
Three failed attempts → a hint (not the answer): the relevant block glows.
Five → a guided step: the program runs slowly and stops at the divergence point [KT §2.5.4].
Seven → do-it-with-me: the tutorial rebuilds the first half, the child finishes.
Never: a locked path, a life system, a countdown on a learning item, or a “you failed” screen.
Always: the child may abandon an exercise and come back; the scheduler will re-offer it later in easier clothing.

# 5. Curriculum architecture

## 5.1 Shape
13 worlds (World 0 to World 12) → 58 concepts → 1 214 exercises → 13 bosses → 13 mini-projects → 1 capstone. Estimated 40–55 hours of engaged time, designed for 20–30 minutes a day over one school year. The full ledger is the Curriculum sheet of the companion workbook; the figures below are the Gate G1 commitment and are computed from it, not estimated.
Each world contains: 4–5 concepts; per concept 3 tutorial steps and 18–24 exercises; a defi debug set (5 broken programs); a mini-projet (open build with a rubric); a boss (a composite target the child cannot pass without every concept of the world).

## 5.2 The worlds

| # | World (FR / EN) | Concepts | Source lineage |
| 0 | Bonjour Tika / Hello Tika | run a program; sequence; instruction order; undo | [SC p.3] |
| 1 | La tortue bouge / The turtle moves | avance/recule; tournegauche/tournedroite; degrees; pen down | [KT §3.1.1, §4.3.1] |
| 2 | Encore et encore / Again and again | répète; loop body; nested repeat; loop vs copy-paste | [SC p.6], [KT §4.5.5] |
| 3 | Couleurs et crayon / Colours and pen | lèvecrayon/baissecrayon; largeurcrayon; couleurcrayon RGB; couleurcanevas | [KT §4.3.3–4.3.4, §5 RGB table] |
| 4 | Le plan / The grid | va x,y; vax/vay; positionx/positiony; direction vs turn; centre | [KT §4.3.1–4.3.2] |
| 5 | Quand… / Events | green flag; key pressed; click on sprite; two scripts at once | [SC p.8, p.10] |
| 6 | Mes variables / Variables | assignment; using a variable as its value; arithmetic operators; the inspector | [KT §4.2.1, §4.4, §2.3] |
| 7 | Si… sinon / Decisions | booleans; comparison operators; si; sinon; et/ou/non | [KT §4.1.5, §4.2.2–4.2.3, §4.5.2–4.5.3] |
| 8 | Tant que / While & sensing | tantque; loop termination; sensing (touching, key, mouse); coupure | [KT §4.5.4, §4.5.7] |
| 9 | Mes propres blocs / My own blocks | apprends; parameters; return; recursion (gentle); decomposition | [KT §4.6] |
| 10 | Lutins, costumes, sons / Sprites, costumes, sounds | sprite; costume switching & animation; sounds & drums; backdrops; graphic effects | [SC p.4, p.5, p.7, p.11, p.12] |
| 11 | Je passe au texte / Into text | typing a program; syntax & the # comment; reading an error; commenting out a line; EN keywords | [KT §4.1.1, §1.2, §6] |
| 12 | Mon application / My app | plan a project; lists; screens & navigation; publish; iterate on feedback | [SC p.13–14], [COM] |


## 5.3 Difficulty is a curve, not a step
Within a concept, items are tagged D1–D5 and delivered in a ratio that shifts as mastery rises:

| Difficulty | What changes | Share at start | Share at mastery |
| D1 | One step, one new idea, visible template | 45 % | 5 % |
| D2 | Two steps, familiar shape | 30 % | 15 % |
| D3 | Recombination; the shape differs from the example | 15 % | 30 % |
| D4 | Requires composing the concept with an older one | 8 % | 30 % |
| D5 | Open target; several correct programs exist | 2 % | 20 % |

Cross-world interleaving is mandatory from World 3 onward: 20 % of every session’s items are drawn from earlier worlds, selected by the decay scheduler.

## 5.4 Worked example of one concept (specimen for content authors)
Concept C2.1 — répète [SC p.6], [KT §4.5.5]
Child-language definition: “Répète, c’est dire une seule fois quelque chose qu’on veut faire plusieurs fois.”
Prerequisites: C1.1 avance, C1.2 tourne.
Tutorial (3 steps): (i) four avance/tourne pairs drawn by hand → a square; (ii) the same square wrapped in répète 4, side by side, same drawing; (iii) the child changes 4 to 3 and predicts.
Items — 22 total: 4 predict-the-canvas; 4 fill-the-gap; 3 fix-the-bug (body of one line only; count off by one; loop placed after the movement); 4 build-to-target (square, triangle, staircase, cross); 3 read-the-code MCQ; 2 shortest-program challenges; 2 interleaved with C1.2.
Misconceptions: body scope; “repeat 4 means 4 sides”; that the turtle returns to origin automatically.
Mastery evidence: builds a hexagon without a template (D4) and explains, by choosing one of four statements, why répète 6 { avance 100 tournegauche 60 } closes.
Boss contribution: the World-2 boss (a rosette, mirroring the nested-repeat figure on the nested-repeat figure on the KTurtle main window, repeat 8 { repeat 4 { … } } [KT §2]) requires nested repetition.

# 6. The exercise and grading system

## 6.1 Item types
Nine types. Every concept must use at least five.

| Code | Type | Child sees | Graded by |
| T1 | Construire vers la cible (build-to-target) | A target drawing/behaviour | Canvas raster diff (tolerance ±2 px) + AST constraint check |
| T2 | Trouve le bug (fix-the-bug) | A program that draws the wrong thing | Output match + edit-distance ceiling |
| T3 | Devine le résultat (predict) | A program, four candidate canvases | Selection |
| T4 | Complète (fill-the-gap) | Program with 1–3 holes, block palette restricted | Slot match or output match |
| T5 | Remets dans l’ordre (Parsons) | Shuffled blocks to sequence | Order equivalence (allows correct alternatives) |
| T6 | Lis le code (read & answer) | Program + a question in words | MCQ / numeric |
| T7 | Le plus court (golf) | A target + a block budget | Output match + block count ≤ budget |
| T8 | Explique (justify) | Why did this happen? four statements | Selection; feeds misconception model |
| T9 | Défi libre (open build) | A rubric with 3–5 criteria | Automated rubric checks + optional peer/teacher review |


## 6.2 The grader
FR-M6-01 The grader evaluates three independent signals and combines them by a per-item policy:
Behavioural — final canvas raster compare, plus a normalised path signature (sequence of turtle positions/headings) so that a correct figure drawn in a different order still passes;
Structural — AST assertions (“contains a repeat whose body has ≥ 2 statements”, “contains no more than 12 blocks”, “does not use va while the pen is down”);
Process — attempts, hint use, run count, time-to-first-run; never used to pass/fail, only to feed the scheduler and the dashboards.
FR-M6-02 A pass must never depend on incidental whitespace, block position on canvas, or ordering of independent statements. FR-M6-03 Failure messages are diagnostic and in the child’s language: “Ta figure a 4 côtés, la cible en a 6. Regarde le nombre dans répète.” Never “Incorrect”. FR-M6-04 The grader runs fully on-device, with no network call. [COM — non-negotiable for offline use] FR-M6-05 Every item carries a hand-authored “best hint” and a “second hint”; the system never reveals the solution, only reduces the search space. FR-M6-06 For T9 open builds, the rubric is shown to the child before they start, in three to five checkable lines.

## 6.3 Exercise bank volume (Gate G1 commitment)

|  | Concepts | Items (min) | Debug defis | Mini-projects | Bosses | Artefacts |
| Worlds 0–4 | 23 | 454 | 25 | 5 | 5 | 489 |
| Worlds 5–9 | 22 | 484 | 25 | 5 | 5 | 519 |
| Worlds 10–12 | 13 | 276 | 15 | 3 | 4 (incl. capstone) | 298 |
| Total | 58 | 1 214 | 65 | 13 | 14 | 1 306 |

At a steady-state authoring pipeline of 120 published artefacts per week (§12), the bank represents 10.9 weeks of authoring capacity — the schedule’s critical path.
Authoring capacity, not engineering, therefore sets the schedule. §12 addresses it.

# 7. Functional requirements by module
Eighteen modules. Each maps 1:1 to a deployment prompt in the companion prompt library.

## M1 — Language core & interpreter
FR-M1-01 A single AST is the canonical program representation; blocks and text are both bidirectional projections of it. [COM] FR-M1-02 Keyword tables are data, not code: a locale file maps canonical opcodes to display keywords, with abbreviations (avance/av). [KT §4.3] FR-M1-03 Supported types: number (integer and decimal, . as separator), string, boolean, list. [KT §4.1.3–4.1.5] FR-M1-04 Operators: + - * / ^, comparison == != < > <= >=, boolean et/ou/non. [KT §4.2] FR-M1-05 Control: si, sinon, tantque, répète, pour ... à ... pas ..., coupure, sortie. [KT §4.5] FR-M1-06 Procedures via apprends with parameters and retourne; recursion permitted with a depth guard of 200 and a child-legible message on overflow. [KT §4.6] FR-M1-07 Execution speed settings: plein / lent / plus lent / pas à pas, changeable while running. [KT §2.5.4] FR-M1-08 Pause and stop at any moment. [KT §2.5.4] FR-M1-09 Deterministic execution given a seed, so that a child’s shared project replays identically, and hasard is seeded per run for reproducible grading. [KT §4.3.8] FR-M1-10 Every runtime error carries: a stable error code, a child-language message, the offending node, and a suggested repair. No stack traces are ever shown. FR-M1-11 The interpreter is step-resumable (a program can be halted and continued), which is what makes step mode and the debugger possible. FR-M1-12 Hard ceilings: 50 000 steps/second, 10 000 drawn segments, 30 s wall clock per run, with a friendly “ton programme tourne encore…” panel offering stop.

## M2 — Block editor
FR-M2-01 Palette organised in coloured families, mirroring the known model: Mouvement, Apparence, Son, Stylo, Données, Événements, Contrôle, Capteurs, Opérateurs, Mes blocs. [SC p.3] FR-M2-02 Drag a block to the script area; click any block or stack to run it immediately. [SC p.3, p.5] FR-M2-03 C-shaped blocks visually enclose their body. [SC p.6] FR-M2-04 Editable literals inside blocks, including negative values. [SC p.5] FR-M2-05 Dropdown parameters (sound, key, effect, sprite). [SC p.4, p.8] FR-M2-06 Grab a stack by its top block to move the whole stack. [SC p.6] FR-M2-07 Mobile adaptation (KODO-specific): tap-to-place as well as drag; a one-handed layout; palette as a bottom sheet; pinch-zoom on the script area; long-press for block help. Minimum touch target 48 dp. [COM] FR-M2-08 Palette scoping: an exercise may expose only the blocks it needs, so a beginner is never facing 120 blocks. FR-M2-09 Unlimited undo/redo. [KT §2.5.2] FR-M2-10 Contextual help on any block: “Aide sur …” equivalent, one tap, opens the reference entry with a runnable 3-line example. [KT §2.5.7 F2]

## M3 — Text editor and the bridge
FR-M3-01 Syntax highlighting by category — commands, control flow, comments, strings, numbers, booleans, variables, operators — with the documented colour semantics as the baseline. [KT §5 table 5.1] FR-M3-02 Line numbers, toggleable. [KT §2.5.6] FR-M3-03 Error lines marked in red with an error panel that links message → line. [KT §1.2, §2.2] FR-M3-04 Comments with #, and a one-tap “commenter / décommenter” action, taught explicitly as a debugging tool. [KT §4.1.1] FR-M3-05 The block↔text toggle preserves cursor/selection context and never loses a program; if the text is syntactically invalid, the toggle offers “revenir aux blocs (ta dernière version correcte)”. FR-M3-06 Autocomplete of keywords in the active language, with the English equivalent shown greyed beside it from World 9. FR-M3-07 Mobile text input uses a programming keyboard row ({ } ( ) $ , " # <> and the top-12 keywords) above the system keyboard. [COM] FR-M3-08 Export of the current program as text, and as an image of the code, for sharing. [KT §2.5.1 HTML export analogue]

## M4 — Canvas, stage and inspector
FR-M4-01 Two execution surfaces, switchable per project: Canevas (turtle geometry, origin top-left, size settable) [KT §4.3.4] and Scène (sprite stage with backdrops, centre origin) [SC p.9]. FR-M4-02 Vector rendering, zoomable, with export to PNG and SVG. [KT §2.5.3, §5 "pixels"] FR-M4-03 Sprites: show/hide, costume list, costume switching, graphic effects, multiple sprites on one stage. [SC p.7, p.10, p.11] FR-M4-04 Backdrop library + import + draw + camera capture, with camera gated behind parental consent. [SC p.9, p.10], [COM] FR-M4-05 Sound: built-in library, drum/note blocks, import MP3/WAV, record with microphone (parental consent gated). [SC p.4, p.11] FR-M4-06 Inspector panel showing live variables (name, value, type), user-defined functions, and the execution tree. [KT §2.3] FR-M4-07 During slow/step execution the currently executing block and the corresponding text line are both highlighted. [KT §2.5.4] FR-M4-08 A “trace tortue” overlay that draws the turtle’s future path ghosted when stepping. [COM]

## M5 — Tutorial engine
FR-M5-01 Tutorials are authored data (JSON), not code: steps, narration text, audio key, highlighted UI target, expected child action, success condition. FR-M5-02 Each step supports: spotlight on a UI element, a ghost block animation, a “fais comme moi” demonstration, and a single call to action. FR-M5-03 Voice-over in FR and EN, auto-play on first exposure, with text always visible and a replay button. Reading level target: CE2/CM1 (≈ 8–9 years), sentences ≤ 12 words. FR-M5-04 No step may be skipped on first pass; all steps are skippable on repeat. FR-M5-05 A tutorial may never take control of the child’s own project; it always runs on its own scratch document. FR-M5-06 Every tutorial ends by naming the concept in words the child can repeat.

## M6 — Exercise delivery & grading
Requirements FR-M6-01 … FR-M6-06 are specified in §6.2. In addition: FR-M6-07 The item player must load and be interactive in ≤ 1.2 s on the reference device. FR-M6-08 Every attempt is persisted locally with its program snapshot, so that a teacher or parent can see what the child actually wrote, not only pass/fail. FR-M6-09 Items are versioned; a fix to an item never retroactively invalidates a child’s mastery.

## M7 — Progression, mastery & scheduling
FR-M7-01 Implements the mastery rule of §4.6, computed on device. FR-M7-02 A daily “Mon entraînement” mix: 60 % current concept, 20 % interleaved earlier concepts, 20 % decayed concepts due for review. FR-M7-03 Adaptive difficulty inside a session per §5.3, with a floor: after two consecutive failures the next item is D1 of the same concept. FR-M7-04 A placement check at first launch (6 adaptive items) proposing a start world. FR-M7-05 Concept state machine: Non vu → Découvert → En cours → Maîtrisé → À revoir. FR-M7-06 Progress is a map, not a list: worlds as islands, concepts as stars (0–3 stars by mastery depth). FR-M7-07 Nothing in the progression may be bought, skipped for payment, or unlocked by watching an advertisement. [COM]

## M8 — Motivation system
FR-M8-01 Rewards are competence-linked: stars for mastery, badges for behaviours we want (debugging, shortening a program, helping via a shared remix), collectible cosmetics for Tika and the stage. FR-M8-02 A daily goal the child sets themselves (10 / 20 / 30 minutes) with a gentle end-of-goal celebration and an explicit “c’est bien de s’arrêter” message. [COM] FR-M8-03 Streaks exist but are forgiving: two free days per week, no loss of accumulated items, never a red warning. FR-M8-04 Prohibited by design decision, and auditable at G4: countdown timers on learning items, randomised loot with variable reward schedules, artificial scarcity, guilt messaging, push notifications after 20:00 local, any leaderboard ranking children against strangers. [COM] FR-M8-05 Permitted social comparison: the child versus their own past, and an opt-in class-level (teacher-mediated) board of effort, not speed.

## M9 — Studio (free creation)
FR-M9-01 Unlimited personal projects; create from blank, from a template, or by remixing a gallery project. [SC p.14] FR-M9-02 Full palette, multiple sprites, backdrops, sounds, custom blocks, lists. FR-M9-03 Project naming, thumbnail, autosave every 20 s and on background; local versions kept for 10 saves. [SC p.12] FR-M9-04 “Mode plein écran” presentation of a finished project. [SC p.14] FR-M9-05 Export: project file, PNG/SVG of canvas, MP4 screen capture of a 30-second run (desktop first). FR-M9-06 A Recettes panel: 20+ copy-a-recipe patterns (“faire rebondir”, “compter les points”, “changer d’écran”), the equivalent of the Conseils window. [SC p.13]

## M10 — Sharing, gallery & moderation
FR-M10-01 Sharing is off by default and requires a verified parent/teacher action. [COM] FR-M10-02 A shared project carries: title, thumbnail, instructions, credits to the original if remixed. [SC p.14] FR-M10-03 No free-text comments in v1. Reactions are a fixed set of icons. Text project descriptions pass an automated filter plus human review before publication. FR-M10-04 No usernames that can carry personal data; display names are generated from a curated word list (e.g. “TortueFuchsia42”) and may be re-rolled, not typed. [COM] FR-M10-05 Remix is one tap and always attributes. [SC p.14] FR-M10-06 A report button on every shared item, with SLA: triage < 24 h, removal on doubt. FR-M10-07 Class galleries (visible to one class only) are the default sharing scope; the public gallery is a separate, later-phase opt-in.

## M11 — Parent space
FR-M11-01 A separate, PIN- or biometric-gated area; children cannot enter it. [COM] FR-M11-02 One-screen weekly summary in plain language: time, concepts mastered this week, what that concept actually is, one thing to ask the child at dinner. FR-M11-03 Controls: daily time cap, sharing on/off, camera & microphone on/off, sound on/off, data-sync on/off, account deletion and data export. FR-M11-04 No advertising of any kind; if a paid tier exists, all purchase surfaces live in the parent space only. [COM]

## M12 — Classroom mode
FR-M12-01 Teacher creates a class, gets a class code; pupils join with the code and a first name only. FR-M12-02 Assign worlds/concepts/items with a due date; see a live grid of mastery per pupil per concept. FR-M12-03 Offline classroom: a teacher device can seed content and collect progress over local Wi-Fi/hotspot with no internet. [COM — essential for the target school context] FR-M12-04 Printable A4 progress sheet and printable unplugged worksheets per world. FR-M12-05 Projection mode: big-font, high-contrast rendering of one pupil’s program for whole-class discussion.

## M13 — Accounts, identity & sync
FR-M13-01 Full functionality without an account; local profile with an avatar and a 4-symbol picture-password for young children. [COM] FR-M13-02 Optional account, created by a parent or teacher only, minimum data: display name, birth year, locale, guardian contact for consent. FR-M13-03 Multi-profile on one device (shared family phone is the norm in the target market). FR-M13-04 Sync is last-write-wins per project with conflict copies, never a silent overwrite. FR-M13-05 Full data export and full deletion in ≤ 30 days, self-service from the parent space.

## M14 — Offline-first & content packs
FR-M14-01 The entire curriculum through World 12 must be usable with the aircraft mode on, after the initial install plus one content download. [COM] FR-M14-02 Content is delivered as signed, versioned packs per world (target ≤ 12 MB/world including audio, ≤ 25 MB base app). FR-M14-03 Packs download on Wi-Fi by default, resumable, and can be sideloaded from a teacher device or SD card. FR-M14-04 All telemetry queues locally and uploads opportunistically; no feature ever blocks on the network.

## M15 — Localisation
FR-M15-01 Three layers are localised independently: interface, keywords, and content (narration, exercise text, audio). [KT §6] FR-M15-02 v1 ships FR (reference) and EN complete. Wolof interface + narration is a committed v1.2 target; Wolof keyword set is a research item, not a commitment. [COM] FR-M15-03 Keyword changes are hot-swappable inside a session without losing the program. [KT §2.5.6] FR-M15-04 Content authoring forbids concatenated sentence fragments; every string is a full sentence with context notes for translators. FR-M15-05 Number format, decimal separator display, and voice-over pronunciation are locale-specific; the language’s own decimal convention is shown even though the parser accepts . [KT §4.1.3]

## M16 — Accessibility
FR-M16-01 WCAG 2.2 AA as the floor for all text and controls, with contrast ≥ 4.5:1 and no colour-only meaning — critical because the block families are colour-coded. Every family therefore also carries a distinct icon and shape. [COM] FR-M16-02 Full narration of every instruction, question and error. FR-M16-03 Dyslexia-friendly font option, text size 100–200 %, reduced-motion mode. FR-M16-04 Keyboard-only operation on desktop, including block placement; screen-reader labels on all blocks. FR-M16-05 Colour-blind safe palette for the block families and for the pen colour picker.

## M17 — Analytics & learning telemetry
FR-M17-01 Event taxonomy fixed at design time: item_started, run, error_raised, hint_shown, item_passed/failed, concept_mastered, project_saved, session_end. FR-M17-02 Pseudonymous by construction; no advertising identifiers, no third-party SDK with data-sale rights. [COM] FR-M17-03 Item-level health metrics: p-value (pass rate), average attempts, abandon rate, discrimination. Any item with pass rate < 35 % or > 97 % is flagged for rewrite. FR-M17-04 A weekly curriculum health report to the Committee, which is the evidence base for the improvement loop (§16).

## M18 — Authoring CMS
FR-M18-01 Non-engineers author worlds, concepts, tutorials, items, hints and rubrics through a web tool with preview-as-child. FR-M18-02 An item cannot be published without: concept link, difficulty tag, two hints, a diagnostic failure message, FR and EN text, and a passing reference solution. FR-M18-03 Content review workflow with roles author → pedagogical reviewer → localisation reviewer → publish, and a full audit trail. FR-M18-04 Bulk import/export of item banks as structured files, so the bank is portable and auditable.

# 8. Non-functional requirements

| ID | Domain | Requirement |
| NFR-PERF-01 | Performance | Cold start ≤ 3.0 s on the reference device (Android 11, 2 GB RAM, Snapdragon 4-series class) |
| NFR-PERF-02 | Performance | Block drag at ≥ 50 fps; canvas run at ≥ 30 fps with 2 000 drawn segments |
| NFR-PERF-03 | Performance | Time from “run” to first visible change ≤ 300 ms |
| NFR-SIZE-01 | Footprint | Base install ≤ 25 MB; full curriculum with audio ≤ 180 MB |
| NFR-BATT-01 | Battery | ≤ 8 % battery per 30-minute session on the reference device |
| NFR-OFF-01 | Availability | 100 % of learning features function offline (see FR-M14-01) |
| NFR-REL-01 | Reliability | Crash-free session rate ≥ 99.5 %; no data loss on force-kill (autosave ≤ 20 s) |
| NFR-SEC-01 | Security | All transport TLS 1.3; content packs signed; no remote code execution paths in the interpreter |
| NFR-PRIV-01 | Privacy | Data minimisation by default; see §13 |
| NFR-COMP-01 | Compatibility | Android 8+, iOS 14+, Windows 10+, macOS 12+, Linux (Debian/Ubuntu LTS), plus a browser build for school desktops |
| NFR-A11Y-01 | Accessibility | WCAG 2.2 AA verified by external audit before public launch |
| NFR-I18N-01 | Localisation | No hard-coded strings; 100 % string coverage enforced in CI |
| NFR-MAINT-01 | Maintainability | Curriculum content is data; adding a world requires no app release |
| NFR-COST-01 | Economics | Marginal cost per active child per month ≤ the agreed budget line; server dependency for the free tier is optional |


# 9. Experience design for 8–11

## 9.1 Information architecture
Five root destinations, always reachable, never more:
Carte — the world map, and the single entry point to learning.
Entraînement — today’s mix, one button.
Studio — my projects.
Galerie — class/community projects (if enabled).
Moi — avatar, badges, stars, settings.
Parent space is not a sixth tab; it is behind a gate in Moi.

## 9.2 Rules of the interface
Maximum three primary actions on any screen.
Every screen answers, without reading: where am I, what do I do now, how do I go back.
Icon + word, never icon alone, never word alone.
Text: ≤ 12 words per instruction line; no paragraph on a learning screen; narration for everything.
Motion is meaningful (it shows causality) and always interruptible.
The “run” affordance is one, unmistakable, and in the same place forever — a green flag on the stage, a play button on the canvas. [SC p.8]
Nothing modal that a child can get trapped behind. Every dialog has a visible way out.

## 9.3 Device adaptation

|  | Phone (≥ 5”, portrait) | Tablet | Desktop |
| Layout | Stage top / palette bottom sheet / script area centre, swappable | Three-pane | Three-pane, dockable/detachable panels [KT §2.1, §2.3] |
| Input | Tap-to-place + drag, 48 dp targets | Drag | Drag + full keyboard + shortcuts |
| Text mode | Programming keyboard row | Split view | Full editor with inspector |
| Session shape | 10–20 min | 20–40 min | 20–60 min, classroom |

The phone is the design origin. Desktop is the phone plus space, not the reverse [COM].

## 9.4 Visual identity
Two guides: Tika, a turtle, custodian of the canvas world — a deliberate lineage marker to the Logo tradition our first source embodies [KT §1]; and Zigo, a sprite who lives on the stage and who can be replaced by any sprite the child chooses, because in this world every object is a lutin [SC p.10].
Art direction: bright, high-contrast, geometric, non-infantilising at the top of the age band; a switchable “Avancé” theme from World 9 that dials down the roundness for 11-year-olds who do not want a toy.

# 10. Engagement ethics
The brief asks for an environment that is ludique et addictive. The Committee accepts the intent — sustained voluntary return — and specifies it precisely, because “addictive” as a mechanic and “addictive” as an outcome are different products.
We build for return through competence. The engine of return is the feeling of getting better at something visibly difficult, plus artefacts the child is proud to show. That is the documented pull of both source traditions: a child clicks a block and the cat moves [SC p.3]; a child writes eight lines and a rosette appears [KT §2].
We refuse compulsion mechanics. Specifically prohibited and testable at G4: variable-ratio reward boxes; countdowns on learning content; streak loss framed as punishment; “your friends are ahead” messaging; notifications engineered around bedtime; any monetised interruption.
We instrument for wellbeing, not only for retention. The metric set the Committee reviews weekly includes frustration events (3+ consecutive failures), late-night sessions, session overruns past the child’s own goal and abandonment after failure. A rise in these is treated as a defect of the same severity as a crash.
The parent-facing promise, written into the store listing and testable: no ads, no open chat, no purchase surface visible to the child, no data sold, works offline.

# 11. Technical architecture

## 11.1 Stack decision

| Layer | Choice | Rationale |
| Client | Flutter (single codebase: Android, iOS, Windows, macOS, Linux) + a web build for school desktops | One UI codebase across the five required platforms; strong custom-rendering performance for blocks and canvas on low-end hardware |
| Language core | Dart, pure, no platform APIs — compiled to WASM for the web build | Same interpreter semantics everywhere; identical grading results on every device |
| Rendering | Custom canvas painter (vector), with an SVG/PNG exporter | [KT §5 — vector canvas, zoomable] |
| Local store | SQLite (progress, attempts, item cache) + file store (projects, packs) | Offline-first, cheap, portable |
| Content | Signed JSON packs + audio (Opus) + vector assets | Content without app releases (NFR-MAINT-01) |
| Backend | Managed Postgres + object storage + a thin API; optional for the free tier | Keeps marginal cost near zero and the free tier genuinely offline |
| Auth | Guardian-initiated, email-less where possible (class codes, device profiles) | Minimises personal data on children |
| CMS | Web app on the same API, role-gated | M18 |

Alternatives recorded in the dissent log: React Native + Blockly (faster start, weaker low-end rendering); native Kotlin/Swift (best performance, triples cost); pure web PWA (fails the offline and performance bars on 2 GB devices).

## 11.2 Interpreter design constraints
Tree-walking interpreter with an explicit continuation stack (required for pause/step/resume, FR-M1-11).
No eval, no dynamic code loading, no reflection over host APIs — the interpreter is a closed sandbox.
A deterministic clock for attends, so a step-mode run and a full-speed run produce the same drawing [KT §4.5.1].
Grading runs the child’s program in a headless instance of the same interpreter — never a second, “close enough” implementation.

## 11.3 Data model (core entities)
Child profile · Concept · Item · Attempt · MasteryState · Project · ProjectVersion · Pack · Class · Assignment · ShareRecord · ModerationCase · Event.
Every Attempt stores the program AST snapshot, the grader verdict, the signals, and the item version (FR-M6-08, FR-M6-09).

# 12. Content production
Authoring 1 214 items plus 92 projects and bosses is the schedule risk. Plan:
Item templates. Each of the nine types has a parameterised template; a large share of D1–D2 items are generated from parameter sets and then human-reviewed, not hand-built from zero.
Reference solutions first. An item exists only once its reference solution runs and its grader policy passes a negative test (a wrong program must fail it).
Teacher co-authoring. Partner teachers author D3–D5 items against the rubric, paid per accepted item, reviewed by seat 4.
Audio. FR and EN narration recorded by two consistent voices; a pronunciation lexicon for keywords; re-recording budget of 15 % held back for the post-G5 loop.
Pipeline SLA. Author → pedagogical review → localisation → audio → publish, with a target of 120 published items per week at steady state.
Item health loop. FR-M17-03 flags items; flagged items are rewritten in the next content sprint, never silently deleted.

# 13. Safety, privacy and compliance
This section is owned by seat 13 and carries a blocking veto.
Regulatory frame: COPPA (US), GDPR + GDPR-K Art. 8 (EU), UK Age Appropriate Design Code, and the data-protection law applicable in each launch market, including Senegal’s Loi 2008-12 and the CDP registration where required. Where regimes differ, the strictest applies globally.
Consent: any account creation, any sharing, any camera or microphone access, and any sync requires verifiable guardian action. Nothing about the learning path does.
Data minimisation: no surname, no address, no photo of a face as a profile picture, no precise location, no contact list, no advertising ID. Birth year only, and only if an account is created.
No third-party trackers. The SDK allow-list is reviewed at every release by seat 13; any SDK that reserves the right to use data for its own purposes is refused.
Moderation: all child-authored public text is reviewed before publication; project assets are hash-checked against known-bad sets; reports triaged within 24 h.
Contact: no child-to-child free text in v1. Teacher-to-class messaging only, inside the classroom module.
Incident response: a documented breach and safeguarding runbook, with a named accountable person, rehearsed before launch.
Transparency: a one-page, child-readable privacy notice, and a separate parent notice in plain French and English.

# 14. Quality: definition of done and the deep-review protocol

## 14.1 Definition of Done (every deliverable)
A deliverable is done when all of the following are true, evidenced, and linked in the gate register:
It meets its numbered requirements, each verified by a named test.
It works offline on the reference device.
It works in FR and EN with 100 % string coverage and recorded audio.
It passes the accessibility checklist (contrast, target size, narration, keyboard, reduced motion).
It has been used by at least three children in the 8–11 panel, unassisted, and observed.
Its telemetry events fire correctly and appear in the curriculum health report.
Its failure modes are child-legible; no technical error string can reach a child’s screen.
It has no open Severity-1 or Severity-2 defect and no open safety finding.
Its content is reviewed by the pedagogical reviewer and the localisation reviewer.
Its rollback path is documented.

## 14.2 The deep review (Gate G4)
The Product Owner’s requirement is a review “at very, very minimum level” — that is, line by line, artefact by artefact, not a demo. The protocol:
Pass 1 — conformance. Every FR/NFR walked against evidence. Output: conformance matrix, one row per requirement, verdict Conforme / Écart / Non testé.
Pass 2 — content. A stratified sample of 15 % of all items, every tutorial, every hint, every error message, read aloud by a reviewer who is not the author. Output: content defect log.
Pass 3 — child run. Six children, two per age band, unassisted, screen- and face-recorded with consent; every hesitation > 8 s and every abandonment logged as a finding.
Pass 4 — pedagogy. Seat 3 and seat 4 verify that mastery claims are supported by item-level data, not by completion.
Pass 5 — safety & privacy. Seat 13 audits consent flows, data flows, SDK list, moderation queue and the prohibited-mechanics list of §10.
Pass 6 — engineering. Performance on the device matrix, crash-free rate, offline soak test, sync conflict tests, interpreter fuzzing.
Severity scale: S1 = a child can be harmed, lose work, or be blocked from learning. S2 = a concept is taught wrongly, or a core flow fails on the reference device. S3 = friction, cosmetic, or content polish. S1 = release blocker; S2 = fix before gate exit; S3 = backlog with a date.
Each finding is recorded as: ID, pass, severity, evidence link, module, owner, fix, re-test date.

# 15. The market challenge (Gate G5)

## 15.1 Benchmark set
KODO is evaluated head-to-head against fifteen products, grouped by what they would take from us: Scratch / ScratchJr / Snap! (block creation), Code.org CS Fundamentals (curriculum breadth, free), Tynker, Kodable, CodeSpark Academy, Lightbot (paid children’s courses), Swift Playgrounds, Grasshopper, Mimo, SoloLearn (text-code learning), KTurtle / Turtle Academy / Blockly Games (turtle lineage), MIT App Inventor / Thunkable (child app building), Minecraft Education / Roblox Studio (engagement and creation ceiling), Duolingo (as a mechanics benchmark for mastery, streaks and scheduling, not a competitor).

## 15.2 Scoring frame
Twenty criteria in five families, scored 0–5 with evidence: Pedagogy (concept coverage, mastery evidence, misconception handling, practice volume); Experience (onboarding, clarity, motivation, session fit); Reach (offline, low-end device, price, language, classroom); Creation (ceiling, publishing, remix); Trust (privacy, safety, ads, parental control). The full matrix is the Benchmark sheet of the companion workbook.

## 15.3 Where we expect to win, and where we must not lose
Expected wins: the block↔text bridge with localised keywords in a single product; true offline on low-end Android; practice volume with a real mastery rule; French-first content of curriculum quality; no ads and no chat; a classroom mode that works without internet.
Expected exposure, to be closed deliberately: the creation ceiling and community scale of Scratch (we will never match its gallery — we compete on the road to creation, and we support export/remix rather than pretending to replace it); the production polish of Tynker/CodeSpark; the brand pull of Minecraft/Roblox; the breadth of Code.org’s free classroom ecosystem.

## 15.4 Challenge protocol
For each benchmark product, a committee pair (one pedagogy seat, one experience seat) completes: 60 minutes of hands-on with a child present; the first-15-minutes teardown (what does a new child actually reach?); three “steal this” findings; one “we are beaten here” finding with a proposed response; a score against the 20 criteria. Findings enter the improvement backlog with severity and an owner.

# 16. The improvement loop
The loop is not a phase; it is the operating rhythm after G3.
G4 deep review  ──►  findingsG5 market challenge ─►  findings          ┐child panel + item health telemetry ──────┤──►  improvement backlog (scored RICE)teacher/parent feedback ──────────────────┘        │        ▼ re-open the cahier des charges (this document, versioned)        │        ▼ re-issue affected module prompts  ──►  build  ──►  G4  ──►  G5 ...
Rules: - Every loop produces a new version of this document; requirements are never changed silently. - A finding is closed only by evidence, not by a fix being merged. - Three loops minimum before public launch; thereafter one loop per quarter, permanently. - The loop exits a world from “learning beta” only when its item health metrics are inside band and its child-panel abandonment rate is below 10 %.

# 17. Roadmap, resourcing and risk

## 17.1 Phases

| Phase | Weeks | Content | Exit |
| P0 Foundations | 1–4 | Committee, this spec, prompts, design system, reference device matrix | G1, G2 |
| P1 Vertical slice | 5–12 | M1–M6 for World 1 only, FR, offline, on phone | G3 |
| P2 Core curriculum | 13–26 | Worlds 0–6, M7, M8, M11, M13, M14, EN parity | G4 #1, G5 #1 |
| P3 Depth | 27–40 | Worlds 7–9, text bridge (M3), Studio (M9), CMS (M18) | G4 #2, G5 #2 |
| P4 Creation & school | 41–52 | Worlds 10–12, sprites/sound (M4), gallery (M10), classroom (M12), accessibility audit | G4 #3, G5 #3 |
| P5 Launch & loop | 53+ | Public release, Wolof interface, quarterly loops | — |


## 17.2 Team shape (steady state)
Product Owner · Chair/PM · 2 pedagogy/curriculum · 1 child-UX + 1 illustrator/motion · 1 language-runtime engineer · 3 Flutter engineers · 1 backend/data · 1 QA · 1 localisation/audio · 0.5 safety-compliance · pool of 4 partner-teacher item authors.

## 17.3 Top risks

| # | Risk | Impact | Response |
| R1 | Item authoring under-delivers; the bank is thin and mastery becomes a claim | High | Templates + teacher pool + weekly burn-up tracked at Committee; scope is cut in worlds, never in items per concept |
| R2 | Block editor performance on 2 GB Android | High | Performance budget fixed in P1; reference device is the gate device; custom painter, no heavy DOM/webview |
| R3 | Dual representation is harder than assumed (round-tripping, invalid text states) | High | Prototype the AST round-trip in P1 before anything else; fall back to read-only text through World 6 |
| R4 | Offline content packs bloat past device storage | Medium | Per-world budget; audio in Opus; art as vector |
| R5 | Safety/compliance rework late | High | Seat 13 embedded from P1, consent flows designed before the first account screen exists |
| R6 | We build a smaller Scratch and lose | High | The G5 protocol exists precisely to detect this; the differentiators of §15.3 are treated as requirements, not marketing |
| R7 | Voice-over cost and re-recording after content changes | Medium | Freeze narration copy per world before recording; 15 % re-record reserve |


# Annex A — Keyword rosetta (extract)
Full table maintained as data in the runtime locale files (FR-M1-02). Source: [KT §4.3, Annexe B index].
Mouvement: avance/av · recule/re · tournegauche/tg · tournedroite/td · direction/dir · obtenirdirection · centre · va · vax/vx · vay/vy Position: positionx · positiony Crayon: lèvecrayon/lc · baissecrayon/bc · largeurcrayon/lac · couleurcrayon/cc Canevas: taillecanevas/tc · couleurcanevas/cca · nettoietout/ntt · initialise Lutin: montre/mo · cache/ca Texte: écris · taillepolice Maths: arrondi · hasard/hsd · mod · racine · pi · sin · cos · tan · arcsin · arccos · arctan Dialogue: message · demande · nombre/nb *(added by PO decision D-011)* Contrôle: attends · si · sinon · tantque · répète · pour … à … pas … · coupure · sortie · assertion Fonctions: apprends · retourne

# Annex B — Colour semantics for syntax highlighting
Baseline inherited from [KT §5 table 5.1], adjusted for WCAG AA and colour-blind safety (FR-M16-05): ordinary commands dark blue; control flow black bold; comments grey; braces dark green bold; apprends light green bold; strings red; numbers dark red; booleans dark red; variables violet; maths operators grey; comparison operators light blue bold; boolean operators pink bold. Each block family additionally carries a distinct icon and silhouette so that colour is never the only signal.

# Annex C — Specimen RGB table for the colour lesson
From [KT §5 table 5.2], reused as the World-3 reference card: 0,0,0 noir · 255,255,255 blanc · 255,0,0 rouge · 150,0,0 rouge foncé · 0,255,0 vert · 0,0,255 bleu · 0,255,255 bleu clair · 255,0,255 rose · 255,255,0 jaune.

# Annex D — Glossary for children
Programme — une liste d’ordres. Bloc — un ordre que tu peux attraper. Lutin — un personnage sur la scène [SC p.10]. Canevas — la feuille où Tika dessine [KT §2.2]. Boucle — répéter sans réécrire. Variable — une boîte avec un nom [KT §4.4]. Bug — une erreur dans ton programme. Déboguer — trouver le bug et le réparer. Degré — la mesure d’un tour ; un tour complet = 360 [KT §5]. Pixel — le plus petit point de l’écran [KT §5].

# Annex E — Open questions for the Product Owner at G1
Business model: free-and-open, freemium via the parent space, school licence, or donor/NGO funded? This changes M10, M11 and the roadmap.
Launch markets and launch languages — is Wolof v1.2 a commitment or an aspiration?
Is the public gallery in scope at all for v1, or class-only sharing until a moderation team exists?
Device floor: is Android 8 / 2 GB the true floor, or should we target 1 GB?
Does KODO need to export to a real language (Python) at World 12, or is the EN-keyword bridge sufficient for v1?
Ownership of the item bank if partner teachers author it.
