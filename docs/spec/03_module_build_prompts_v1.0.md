# KODO — Module Deployment Prompt Library v1.0

**Companion to** `01_KODO_Cahier_des_Charges_v1.0.docx` and `02_KODO_Curriculum_Benchmark_Backlog.xlsx`
**Purpose** — one self-contained prompt per module, so that any capable agent or squad can deploy that module without reading the whole specification, and so that two independently deployed modules still fit together.
**Gate** — G2. No prompt is released until the Runtime Architect (seat 8) and the Engineering Lead (seat 9) have confirmed its interface contract against the adjacent modules.

---

## How to use this library

1. Every prompt follows the same seven-part shape: **Role · Context · Inputs · Build · Interfaces · Acceptance tests · Do-not**.
2. Paste **§0 Shared preamble** ahead of any individual module prompt. It carries the constraints that are true for every module and that are the most common source of integration failure.
3. Interfaces are contracts. If a module needs to change an interface, that is a specification change and goes back to G1 — not a pull request.
4. Every prompt ends with acceptance tests written so that "done" is observable by someone who did not build it.
5. Build order is **M1 → M4 → M2 → M3 → M5 → M6 → M7** (the vertical slice), then M14, M13, M8, M11, M9, M18, M12, M10, M15, M16, M17.

---

## §0 — Shared preamble (prepend to every module prompt)

> You are building one module of **KODO**, an all-in-one coding environment that teaches children aged 8 to 11 to program and to build small apps, on phone, tablet and desktop, in French and English, online and offline.
>
> **Non-negotiable constraints, true for every module:**
> - **Reference device:** Android 11, 2 GB RAM, 5.5" screen, no reliable internet. If a feature does not work there, it does not ship.
> - **Offline-first:** no learning feature may block on a network call. Telemetry queues locally.
> - **Stack:** Flutter (Dart) for all clients plus a WASM web build; the language core is pure Dart with no platform APIs; SQLite for local state; signed JSON content packs.
> - **One AST:** blocks and text are two projections of a single program representation. Never implement a second parser, a second interpreter or a second grader.
> - **Localisation:** no hard-coded strings; French is the reference language, English is parallel; keywords are locale data, not code.
> - **Child-facing language:** no technical error text ever reaches a child's screen. Every message is a full sentence at a CE2/CM1 reading level, and every message has a French and an English recording key.
> - **Accessibility:** WCAG 2.2 AA; minimum touch target 48 dp; colour is never the only carrier of meaning; everything narratable.
> - **Safety:** no advertising, no open chat, no purchase surface visible to a child, no third-party SDK that reserves rights over the data, no personal data beyond what §13 of the cahier des charges permits.
> - **Motivation ethics:** never implement a countdown on a learning item, a randomised reward box, a loss-framed streak, or a notification after 20:00 local time. If a requirement seems to ask for one, stop and raise it.
>
> **Deliverables for every module:** source, unit and widget tests, an interface document matching the contract below, a performance measurement on the reference device, a localisation coverage report, and a short "how a reviewer verifies this" note.

---

## M1 — Language core and interpreter

**Role.** You are a language and runtime engineer building the heart of KODO: the program representation, the parser, the interpreter and the error model.

**Context.** The language, *KodoScript*, is a translated-keyword language in the Logo/TurtleScript tradition: a child writes `avance 100` or `forward 100` and the same program executes identically. Blocks and text are projections of the same tree. Execution must be watchable — slowed, paused, stepped — because that is how a child debugs.

**Inputs.** Cahier des charges §4.4 (keyword rosetta), §7/M1 (`FR-M1-01` … `FR-M1-12`), Annex A (keyword tables), Annex B (colour semantics).

**Build.**
1. **AST** — a serialisable node model: `Program`, `Command(opcode, args)`, `Repeat(count, body)`, `While(cond, body)`, `For(var, from, to, step, body)`, `If(cond, then, else)`, `Assign(var, expr)`, `ProcDef(name, params, body)`, `ProcCall(name, args)`, `Return(expr)`, `Break`, `Exit`, `Literal`, `VarRef`, `BinOp`, `UnOp`, `Comment`. Every node carries a stable `id` and a source span.
2. **Opcode table as data** — opcodes are canonical identifiers (`MOVE_FORWARD`); display keywords come from locale files mapping opcode → {primary, abbreviation} per language. Ship `fr` and `en` (minimum: `avance/av ↔ forward/fd`, `tournegauche/tg ↔ turnleft/tl`, `répète ↔ repeat`, `tantque ↔ while`, `pour…à…pas ↔ for…to…step`, `si/sinon ↔ if/else`, `apprends ↔ learn`, `retourne ↔ return`, `demande ↔ ask`, `écris ↔ print`, `lèvecrayon/lc ↔ penup/pu`, `baissecrayon/bc ↔ pendown/pd`, `couleurcrayon ↔ pencolor`, `taillecanevas ↔ canvassize`, `nettoietout ↔ clear`, `initialise ↔ reset`, `hasard ↔ random`, `attends ↔ wait`).
3. **Types** — number (int and decimal, `.` separator), string, boolean, list. Dynamic typing, explicit coercion rules, no silent truthiness of numbers.
4. **Operators** — `+ - * / ^`, `== != < > <= >=`, `et / ou / non`, parentheses.
5. **Interpreter** — tree-walking with an **explicit continuation stack**, so a run can be suspended between any two steps and resumed. Expose `step()`, `runUntilBreakpoint()`, `setSpeed(full|slow|slower|slowest|step)`, `pause()`, `stop()`. Speed changes take effect on the next step, mid-run.
6. **Determinism** — a seeded RNG per run; `attends` uses a virtual clock so a stepped run and a full-speed run draw the same figure.
7. **Errors** — a closed catalogue. Each error has: a stable code (`E_UNKNOWN_COMMAND`, `E_MISSING_ARG`, `E_TYPE`, `E_UNDEFINED_VAR`, `E_DIV_ZERO`, `E_DEPTH`, `E_TIMEOUT`, `E_UNCLOSED_BLOCK`), the offending node id, a French and English message key, and a machine-readable `suggestedRepair`. Never throw a Dart exception across the module boundary.
8. **Guards** — 50 000 steps/s ceiling, 10 000 drawn segments, 30 s wall clock, recursion depth 200; each raises a catalogued error, never a crash.
9. **Headless mode** — the same interpreter must run with no UI, for grading.

**Interfaces.**
- `Program parse(String source, Locale kw)` → AST or a list of catalogued errors with spans.
- `String render(Program p, Locale kw)` → text in the requested keyword language.
- `Interpreter(Program p, Surface s, {int seed})` with the control methods above, emitting `ExecutionEvent{nodeId, kind, varsSnapshot}`.
- `Surface` is an abstract drawing/stage sink implemented by **M4**; M1 must not know how anything is rendered.

**Acceptance tests.**
1. **Round-trip:** 1 000 randomly generated programs survive `render(parse(x)) == x` modulo whitespace, in both keyword languages.
2. **Locale swap:** a running program, switched from `fr` to `en` keywords, continues and produces an identical drawing.
3. **Determinism:** the same program with the same seed produces an identical path signature across 100 runs and across all three platforms.
4. **Step equality:** a program executed in step mode draws the same figure as at full speed, including `attends` and `hasard`.
5. **Error catalogue:** every error path is reachable by a test, and every code has an FR and EN message; a test fails the build if any message key is missing.
6. **Hostility:** a fuzzer of 10 000 malformed programs produces only catalogued errors, no crash, no hang past the guards.
7. **Performance:** a 2 000-segment rosette completes in under 2 s on the reference device.

**Do not.** Do not implement `eval`, dynamic loading, file or network access from inside the language. Do not let an English identifier leak into a French error message. Do not write a second interpreter for grading.

---

## M2 — Block editor

**Role.** You are building the surface where an eight-year-old writes their first program by dragging.

**Context.** The block model children already recognise: coloured families in a palette, blocks that snap, C-shaped blocks whose mouth encloses what they repeat, editable numbers inside blocks, dropdowns, and the fact that clicking any block or stack runs it immediately.

**Inputs.** §7/M2 (`FR-M2-01` … `FR-M2-10`), §9.3 device adaptation, Annex B.

**Build.**
1. Palette with ten families — Mouvement, Apparence, Son, Stylo, Données, Événements, Contrôle, Capteurs, Opérateurs, Mes blocs — each with a colour **and** an icon **and** a silhouette, so colour is never the only signal.
2. Drag-and-drop with snapping; C-blocks that grow to enclose their body; stacks grabbed by their top block.
3. Click any block or stack → it runs immediately against the current surface.
4. Inline editable literals, including negatives; dropdown parameters bound to project assets (sounds, sprites, keys, effects).
5. **Mobile mode:** tap-a-block-then-tap-a-slot as an equal-status alternative to dragging; palette as a bottom sheet with family tabs; pinch-zoom and pan on the script area; long-press opens block help.
6. Palette scoping: the editor accepts an allow-list of opcodes so an exercise can present only what it needs.
7. Unlimited undo/redo. Block help: one tap → the reference entry plus a three-line runnable example.

**Interfaces.** Reads and writes the M1 AST directly; emits `EditEvent` for M17; accepts `PaletteScope` from M6; calls M1's interpreter for click-to-run; renders into the M4 surface.

**Acceptance tests.**
1. Two children aged 8, on the reference phone, each place five blocks and run them, unassisted, within three minutes. *(Pass 3 evidence, not an automated test — record it.)*
2. Drag maintains ≥ 50 fps on the reference device with 60 blocks on canvas.
3. Every block has help content in FR and EN; a coverage test fails the build otherwise.
4. Colour-blind simulation: every family remains distinguishable with colour removed.
5. Palette scoping test: an exercise configured for World 1 exposes exactly 7 opcodes.
6. Undo 50 steps and redo 50 steps restores byte-identical AST.

**Do not.** Do not invent a block shape whose meaning a child must be told. Do not put more than 12 blocks in the visible palette for Worlds 0–2. Do not require a long-press for any primary action.

---

## M3 — Text editor and the block↔text bridge

**Role.** You are building the single most differentiating feature in the product: the moment a child sees their blocks as words in their own language, and then as words in English.

**Context.** Worlds 1–6 show text read-only. Worlds 7–9 make it editable. Worlds 10–12 make it the default. The toggle must never lose a child's program — that event would destroy trust in the feature permanently.

**Inputs.** §4.3, §4.4, §7/M3 (`FR-M3-01` … `FR-M3-08`), Annex A, Annex B.

**Build.**
1. Editor with syntax highlighting per Annex B, adjusted to WCAG AA contrast; toggleable line numbers; `#` comments with a one-tap comment/uncomment action taught as a debugging tool.
2. Error presentation: the offending line marked in red, an error panel beneath, tapping the message scrolls to and highlights the line, and offers `suggestedRepair` as a one-tap fix where one exists.
3. **The bridge:** a single toggle. Block → text is always safe. Text → block is safe when the text parses; when it does not, present two choices in child language — "corrige ton texte" (stay, with the error shown) or "reviens à ta dernière version qui marchait" (restore the last valid AST, which is always retained).
4. Keyword autocomplete in the active language; from World 9, show the English equivalent greyed beside each suggestion.
5. **Mobile programming keyboard row** above the system keyboard: `{ } ( ) $ , " # < > =` plus the twelve most-used keywords of the current world, scrollable.
6. A "mode anglais" switch that relabels every keyword in place without changing the program — the World-11 lesson depends on this being instantaneous and lossless.
7. Export the program as text and as an image of the code.

**Interfaces.** `parse`/`render` from M1 only; receives the current AST from M2 and returns an AST; publishes `bridge_toggled` and `keyword_locale_changed` events to M17.

**Acceptance tests.**
1. **Loss test:** 5 000 random edit sequences with toggles interleaved; the program is never lost and never silently altered.
2. Toggle latency ≤ 100 ms for a 200-node program on the reference device.
3. Every error code from M1's catalogue renders as a child-language message with a line marker; verified against the full catalogue.
4. Keyword-language switch mid-edit preserves cursor position and selection.
5. An 11-year-old, unassisted, types a five-line program on a phone using the programming keyboard row in under four minutes.
6. Contrast audit of every highlight colour against both the light and dark themes.

**Do not.** Do not auto-correct a child's code. Do not hide the error panel automatically. Do not make the toggle a setting buried in a menu — it is a first-class control next to the run button.

---

## M4 — Canvas, stage, sprites and inspector

**Role.** You are building the world the program acts on, and the window that shows a child what the program is thinking.

**Context.** Two surfaces: the **canevas**, a turtle drawing surface with the origin at the top-left and a settable size; and the **scène**, a sprite stage with backdrops and a centre origin. Both are driven by the same interpreter through one `Surface` interface.

**Inputs.** §7/M4 (`FR-M4-01` … `FR-M4-08`), Annex C (RGB reference table).

**Build.**
1. Vector renderer with zoom, exporting PNG and SVG; a pen model with width and RGB colour; canvas size and colour commands; `nettoietout` (clear drawings only) versus `initialise` (full reset) implemented with exactly that distinction, because World 3 teaches it.
2. Turtle sprite: show/hide, position, heading; jump commands (`va`, `vax`, `vay`, `centre`) that never draw, whatever the pen state.
3. Stage: multiple sprites, costume lists, costume switching, graphic effects, backdrop library plus import; sounds including a drum/notes set, imports, and microphone recording behind a parental-consent gate; camera capture behind the same gate and **disabled in v1** (see backlog IMP-009).
4. **Inspector** panel: live variables with name, value and type; user-defined procedures; the execution tree. It updates on every interpreter event and is the visual proof that a variable is a box with something in it.
5. Execution highlighting: in slow and step modes, the executing block **and** the corresponding text line are both highlighted, and a ghosted preview shows the segment about to be drawn.

**Interfaces.** Implements `Surface` for M1; exposes `exportPng()`, `exportSvg()`, `pathSignature()` (the ordered list of positions and headings, used by M6's grader) and `rasterHash()`.

**Acceptance tests.**
1. `pathSignature()` is stable across platforms for the same seeded program — the grader depends on it.
2. 2 000-segment drawing renders at ≥ 30 fps on the reference device; SVG export reopens in a browser identically.
3. Jump commands never leave a mark with the pen down; a regression test covers all four.
4. Inspector reflects a variable change within one frame of the assignment executing.
5. Consent gate: microphone and camera are unreachable without a guardian action; verified by seat 13, not by the squad.
6. Colour-blind safe default palette in the colour picker, with the RGB values of Annex C as named presets.

**Do not.** Do not render through a webview. Do not let the stage and the canvas diverge into two code paths for the same primitive.

---

## M5 — Tutorial engine

**Role.** You are building the teacher's voice: 90-to-180-second guided steps that a child can follow without being able to read well.

**Context.** Each tutorial step has three beats — *Je regarde* (watch two ideas at most), *On fait ensemble* (complete a program with one hole), *Je fais* (build from zero, graded). No step introduces something the child will not use within 60 seconds.

**Inputs.** §4.2, §7/M5 (`FR-M5-01` … `FR-M5-06`), the concept ledger (`Curriculum` sheet).

**Build.**
1. A tutorial is **data**: an ordered list of steps, each with `narrationKey`, `audioKey`, `spotlightTarget`, `demoBlocks`, `expectedAction`, `successCondition`, `retryHint`.
2. A player that can: spotlight any UI element in M2/M3/M4, animate ghost blocks into place, wait for a specific child action, and detect success.
3. Narration in FR and EN, auto-playing on first exposure, always with visible text and a replay control; ≤ 12 words per line; a readability check in CI.
4. Steps are unskippable on first pass, fully skippable on repeat.
5. The tutorial always runs on its own scratch document — it must be impossible for a tutorial to modify a child's saved project.
6. Every tutorial closes by naming the concept in the child's words, which is the string that later appears on the progress map and in the parent's weekly summary.

**Interfaces.** Consumes tutorial JSON from M14 content packs; drives M2/M3/M4 through a narrow `TutorialHost` interface; reports `tutorial_step_completed` to M7 and M17.

**Acceptance tests.**
1. A new tutorial can be added by editing content only, with no app build.
2. Audio coverage 100 % for FR and EN; a missing recording fails the content publish gate, not the runtime.
3. Isolation test: a fuzzed tutorial cannot write to any project store.
4. Three children per age band complete the World-1 tutorial unassisted; any hesitation over eight seconds is logged as a finding.
5. Readability: every narration line scores at or below the CM1 target.

**Do not.** Do not build a video player. Do not allow a step that says "maintenant, essaie" without a defined success condition.

---

## M6 — Exercise delivery and grading

**Role.** You are building the machine that decides, fairly and on-device, whether a child has actually understood.

**Context.** Nine item types (T1 build-to-target, T2 fix-the-bug, T3 predict, T4 fill-the-gap, T5 Parsons, T6 read-and-answer, T7 golf, T8 explain, T9 open build). Grading combines a behavioural signal, a structural signal and a process signal. A correct program written in an unexpected but valid way must pass.

**Inputs.** §6 in full, §7/M6 (`FR-M6-01` … `FR-M6-09`).

**Build.**
1. An item player per type, each loading and becoming interactive in ≤ 1.2 s on the reference device.
2. **Behavioural grading:** run the child's program headlessly in M1 against an M4 headless surface; compare `rasterHash` with a ±2 px tolerance **and** compare the normalised `pathSignature`, so a figure drawn in a different but valid order passes.
3. **Structural grading:** an assertion language over the AST — `contains(Repeat)`, `bodyLength(Repeat) >= 2`, `blockCount <= 12`, `usesOnly([...])`, `noJumpWithPenDown`. Assertions are authored per item, never inferred.
4. **Process signals:** attempts, runs, hints shown, time to first run. These never decide pass or fail; they feed M7 and the dashboards.
5. **Diagnostic failure messages:** each item carries an authored message pattern that names the observable difference ("Ta figure a 4 côtés, la cible en a 6. Regarde le nombre dans répète."). Generic failure text is a build error.
6. Two-level hints; hints reduce the search space and never reveal the solution. Escalation per §4.7 at three, five and seven failures.
7. Attempt persistence: every attempt stores the AST snapshot, the verdict, the signals and the item version.
8. Item versioning: a corrected item never retroactively invalidates a child's mastery.

**Interfaces.** Loads items from M14; calls M1 and M4 headlessly; reports `Attempt` to M7 and M17; requests `PaletteScope` from M2.

**Acceptance tests.**
1. **Negative testing:** for every shipped item, at least three wrong reference programs must fail it, and at least two alternative correct programs must pass it. This is a publish gate in M18.
2. No item's verdict changes when whitespace, block position, or the order of independent statements changes.
3. Grading is fully offline; the airplane-mode soak test completes 200 items with no network call.
4. 100 % of failure messages are authored and localised; a generic string fails CI.
5. Item load-to-interactive ≤ 1.2 s at the 95th percentile on the reference device.
6. A replayed attempt from stored AST reproduces the original verdict exactly.

**Do not.** Do not grade by string comparison of code. Do not use a process signal to fail a child. Do not let an item ship without two hints and a diagnostic message.

---

## M7 — Progression, mastery and scheduling

**Role.** You are building the claim that KODO makes and that its competitors do not: that a concept is mastered, not merely visited.

**Inputs.** §4.6 mastery rule, §5.3 difficulty curve, §7/M7 (`FR-M7-01` … `FR-M7-07`), the `Curriculum` sheet.

**Build.**
1. Concept state machine: `Non vu → Découvert → En cours → Maîtrisé → À revoir`, computed entirely on device.
2. **Mastery rule:** ≥ 10 items passed spanning ≥ 4 item types; ≥ 80 % first-attempt success over the last 8 items; ≥ 1 pass on an item structurally dissimilar to the tutorial example; and a retention check passed ≥ 72 h later. All four, or the concept stays `En cours`.
3. **Decay:** untouched for 21 days → `À revoir`, re-entering the mix at low volume.
4. **Daily mix:** 60 % current concept, 20 % interleaved earlier concepts, 20 % decayed concepts due.
5. **Within-session difficulty:** the D1–D5 ratios of §5.3, shifting with mastery, with a hard floor — two consecutive failures forces a D1 item of the same concept.
6. **Placement:** a six-item adaptive check at first launch proposing a start world, always overridable by the child or the teacher.
7. **Progress map:** worlds as islands, concepts as stars (0–3 by mastery depth). No path is ever purchasable or ad-unlockable.

**Interfaces.** Consumes `Attempt` from M6 and the prerequisite graph from M14 content; publishes `MasteryState` to M8, M11, M12 and M17.

**Acceptance tests.**
1. Simulation: 10 000 synthetic learners with known ability produce a mastery distribution with no learner mastering a concept they cannot do, and no learner blocked for more than 25 items on a single concept.
2. The scheduler never presents the same item twice within 20 items.
3. Retention-check timing honours the 72-hour rule across device clock changes and time zones.
4. Offline for 30 days: mastery is computed, stored and later synced without loss or double-counting.
5. Removing an item from the bank does not change any existing `Maîtrisé` state.

**Do not.** Do not equate completion with mastery anywhere in the data model. Do not let the scheduler produce a session with zero achievable items.

---

## M8 — Motivation system

**Role.** You are making a child want to come back tomorrow, using competence rather than compulsion.

**Inputs.** §10 in full, §7/M8 (`FR-M8-01` … `FR-M8-05`).

**Build.** Stars tied to mastery depth; badges for behaviours worth reinforcing (debugging, shortening a program, finishing a project, helping through a remix); cosmetics for Tika and the stage, earned only; a child-set daily goal (10/20/30 minutes) with a celebration **and an explicit "c'est bien de s'arrêter maintenant"**; forgiving streaks with two free days a week and no loss of accumulated work; self-comparison views; an opt-in, teacher-mediated class board of effort.

**Interfaces.** Reads `MasteryState` from M7; exposes a `RewardEvent` stream to M17; owns nothing that gates learning content.

**Acceptance tests.**
1. **Prohibited-mechanics audit** (seat 5 + seat 6 + seat 13) finds zero instances of: countdowns on learning items, variable-ratio reward boxes, loss-framed streaks, peer-ranking against strangers, notifications after 20:00, or any monetised interruption.
2. No reward can be obtained without a learning event behind it.
3. Wellbeing telemetry is live: frustration events, late-night sessions, overruns past the child's own goal, and abandonment after failure are all instrumented before launch.
4. A child who misses four days returns to zero punitive messaging; verified by script review of every string.

**Do not.** Do not ship a leaderboard. Do not use red as the colour of a missed day.

---

## M9 — Studio (free creation)

**Role.** You are building the room where the child stops being a student and becomes an author.

**Inputs.** §7/M9 (`FR-M9-01` … `FR-M9-06`).

**Build.** Unlimited projects from blank, template or remix; the full palette with multiple sprites, backdrops, sounds, custom blocks and lists; naming, thumbnails, autosave every 20 s and on background, with ten retained local versions; full-screen presentation mode; export of the project file, PNG/SVG, and a 30-second screen capture on desktop; and a **Recettes** panel of at least twenty copy-a-pattern recipes ("faire rebondir", "compter les points", "changer d'écran", "suivre le doigt", "gagner / perdre").

**Interfaces.** Uses M2, M3, M4 unchanged; persists via M13's local store; hands a project to M10 for sharing.

**Acceptance tests.** Force-kill during an edit loses at most 20 s of work, measured 50 times. A project with 6 sprites, 40 costumes and 12 sounds opens in ≤ 4 s on the reference device. Every recipe is runnable as shipped and localised. Export round-trips: an exported project reimports identically.

**Do not.** Do not gate any block behind progression in the Studio — the Studio is where a child may attempt what they have not yet been taught.

---

## M10 — Sharing, gallery and moderation

**Role.** You are building the smallest safe social surface that still lets a child be proud in public.

**Inputs.** §7/M10, §13 in full.

**Build.** Sharing off by default, enabled only by a verified guardian or teacher action; class galleries as the default scope, a public gallery as a separate later opt-in; shared items carrying title, thumbnail, instructions and remix credit; **no free-text comments in v1**, fixed icon reactions only; display names generated from a curated word list and re-rollable but never typed; one-tap remix with attribution; a report control on every item with a 24-hour triage SLA and removal on doubt; a moderation console with queue, decision log and audit trail.

**Interfaces.** Consumes projects from M9; enforces M11 consent flags; writes `ModerationCase` records; never exposes a child's account identifiers to another child.

**Acceptance tests.** An adversarial review by seat 13 attempts to surface personal data through a display name, a project title, a thumbnail or an asset, and fails on all four. A moderation drill triages 50 synthetic reports within SLA. Sharing is provably unreachable without the guardian flag, verified by an automated test, not by UI inspection.

**Do not.** Do not ship any child-to-child free-text channel in v1, under any framing.

---

## M11 — Parent space

**Role.** You are building the screen that earns a parent's trust in ninety seconds.

**Build.** A PIN- or biometric-gated area children cannot enter; a one-screen weekly summary in plain language — time spent, concepts mastered, what that concept actually *is*, and **one question to ask the child at dinner**; controls for daily time cap, sharing, camera, microphone, sound, sync, data export and account deletion; and a purchase surface that, if a paid tier ever exists, lives here and only here.

**Acceptance tests.** Ten parents with no coding background each read the weekly summary and correctly explain what their child learned, unprompted. Three children aged 8–11 attempt to enter the parent space and fail. Deletion completes end-to-end within the stated window in a live test, not a documented promise.

**Do not.** Do not use the words "variable", "boucle" or "conditionnelle" in the parent summary without a five-word explanation beside them.

---

## M12 — Classroom mode

**Role.** You are building for a teacher with thirty-five pupils, one hour a week, and no internet.

**Build.** Class creation and class codes; pupils joining with a first name only; assignment of worlds, concepts or item sets with a due date; a live mastery grid of pupil × concept; **offline classroom operation** — a teacher device seeds content and collects progress over a local hotspot, plus SD-card and USB sideloading with checksum verification; printable A4 progress sheets and printable unplugged worksheets per world; and a projection mode with large type and high contrast for whole-class discussion of one pupil's program.

**Acceptance tests.** A no-internet drill: 35 devices seeded and collected in under 20 minutes. A teacher who has never seen KODO creates a class, assigns World 2 and reads the grid in under 10 minutes, unassisted. Printed sheets are legible in monochrome on a low-toner printer.

**Do not.** Do not require a pupil email address. Do not put any child's surname anywhere in the classroom UI.

---

## M13 — Accounts, identity and sync

**Build.** Full functionality with no account at all, on a local profile with an avatar and a four-symbol picture password; optional accounts created only by a guardian or teacher, storing the minimum: display name, birth year, locale, guardian contact for consent; multi-profile on one device, because a shared family phone is the norm; sync that resolves conflicts by creating a copy, never by silent overwrite; self-service full export and full deletion within 30 days.

**Acceptance tests.** The complete World-1 experience runs with no account and no network. A conflict matrix of 20 scenarios produces zero silent data loss. A deletion request removes every record across every store, verified by an independent query.

**Do not.** Do not ask a child for an email address, a surname, a photograph of their face, or a location.

---

## M14 — Offline-first content packs

**Build.** Signed, versioned content packs per world (tutorials, items, hints, audio, assets, prerequisite graph), with a budget of ≤ 12 MB per world and ≤ 25 MB for the base app; resumable Wi-Fi-preferred downloads; sideloading from a teacher device, SD card or USB; local telemetry queueing with opportunistic upload; and a content-version migration path that never invalidates stored mastery.

**Acceptance tests.** The complete curriculum, World 0 to World 12, is usable in airplane mode after one download — this is the single most important test in the programme. A corrupted or unsigned pack is rejected with a child-legible message. A CI size budget fails the build when a world exceeds its allowance.

**Do not.** Do not put any learning content behind a runtime network call. Do not auto-download on mobile data without an explicit choice.

---

## M15 — Localisation

**Build.** Three independently localised layers — interface, keywords, content — with French as the reference and English in full parity at v1; keyword language hot-swappable mid-session without losing the program; a CMS lint rule forbidding concatenated sentence fragments and requiring a context note per string; locale-correct number display and keyword pronunciation for the voice-over; and a Wolof interface and narration track prepared for v1.2 with the Wolof keyword set flagged as research, not a commitment.

**Acceptance tests.** String coverage is 100 % in FR and EN, enforced in CI. A pseudo-locale run reveals zero hard-coded strings and zero truncation at 140 % string length. Switching keyword language mid-program preserves the program byte-for-byte.

**Do not.** Do not machine-translate child-facing content without a human review by seat 11.

---

## M16 — Accessibility

**Build.** WCAG 2.2 AA as the floor; every block family carrying a colour **and** an icon **and** a silhouette; full narration of every instruction, question and error; a dyslexia-friendly font option; text scaling 100–200 % without layout breakage; a reduced-motion mode; complete keyboard operation on desktop, including block placement; screen-reader labels for every block and every canvas state; colour-blind-safe palettes throughout.

**Acceptance tests.** An external accessibility audit before public launch, with findings closed, not merely logged. A blind reviewer completes World 0 with a screen reader. Every screen passes an automated contrast check at both themes, in CI.

**Do not.** Do not treat accessibility as a phase-four task; the block-family shapes must be decided before the art is drawn.

---

## M17 — Analytics and learning telemetry

**Build.** A fixed event taxonomy (`item_started`, `run`, `error_raised`, `hint_shown`, `item_passed`, `item_failed`, `concept_mastered`, `project_saved`, `session_end`, plus the wellbeing events of M8); pseudonymous identifiers with no advertising IDs and no third-party SDK holding data rights; item-health metrics (pass rate, mean attempts, abandon rate, discrimination) flagging any item outside a 35–97 % pass band; and a weekly curriculum health report delivered to the Committee, which is the evidence base for the improvement loop.

**Acceptance tests.** A schema test rejects any undeclared event. A privacy review by seat 13 confirms no field can identify a child. The weekly report is generated and delivered for four consecutive weeks before G4 sign-off.

**Do not.** Do not add an event because it might be interesting later. Do not send telemetry before the guardian consent state is known.

---

## M18 — Authoring CMS

**Build.** A web tool in which a non-engineer authors worlds, concepts, tutorials, items, hints and rubrics, with **preview-as-child** on a simulated reference device; a publication gate that rejects any item lacking a concept link, a difficulty tag, two hints, a diagnostic failure message, FR and EN text and audio keys, a passing reference solution, three failing wrong solutions and two passing alternative solutions; a workflow of author → pedagogical reviewer → localisation reviewer → publish with a full audit trail; and bulk import/export of item banks in a documented structured format.

**Acceptance tests.** A partner teacher, with two hours of training and no engineering help, authors and publishes five items that pass review. The publish gate is proven by attempting to publish ten deliberately incomplete items, all of which are rejected with a specific reason. An exported bank reimports with zero differences.

**Do not.** Do not allow an engineer-only path that bypasses the publish gate.

---

## §19 — The review prompt (Gate G4)

> You are a reviewer at KODO's deep review. You did not build this. Your job is to find what is wrong at the smallest level of detail, not to assess whether it is broadly good.
>
> Work one pass at a time: **(1) conformance** — walk every requirement in the `Exigences` sheet and record `Conforme / Écart / Non testé` with evidence; **(2) content** — read aloud a stratified 15 % sample of items plus every tutorial, hint and error message, and flag any string a nine-year-old would not understand, any generic failure message, and any untranslated or machine-translated line; **(3) child run** — observe six children, two per age band, unassisted, and log every hesitation over eight seconds and every abandonment; **(4) pedagogy** — verify that every mastery claim is supported by item-level data rather than completion; **(5) safety and privacy** — audit consent flows, data flows, the SDK allow-list, the moderation queue and the prohibited-mechanics list; **(6) engineering** — performance on the device matrix, crash-free rate, offline soak, sync conflicts, interpreter fuzzing.
>
> Record each finding as: ID, pass, module, requirement, **what you observed as fact**, why it matters, severity (S1 a child can be harmed, lose work or be blocked from learning; S2 a concept is taught wrongly or a core flow fails on the reference device; S3 friction or polish), owner, proposed fix, re-test date, evidence link.
>
> Do not propose a redesign. Do not soften a finding because the fix is expensive. Do not close a finding because a fix was merged — close it on re-test evidence only.

---

## §20 — The challenge prompt (Gate G5)

> You are challenging KODO against the market. Take one product from the benchmark set — Scratch, ScratchJr, Snap!, Code.org CS Fundamentals, Tynker, Kodable, CodeSpark Academy, Lightbot, Blockly Games, Turtle Academy, KTurtle, Swift Playgrounds, Grasshopper/Mimo, MIT App Inventor/Thunkable, Minecraft Education/Roblox Studio, and Duolingo as a mechanics benchmark.
>
> Spend 60 minutes hands-on with a child of the target age present. Then answer, with evidence and screenshots: **What does a brand-new nine-year-old actually reach in the first fifteen minutes?** **Where is this product better than KODO, specifically and concretely?** **What three things should we steal?** **What one thing beats us outright, and what is our proposed response?** Score the product against the twenty criteria on the `Benchmark` sheet, 0–5, and attach the evidence link. A score without evidence is not a score.
>
> Then answer the hostile question honestly: *if a parent can use Scratch and Code.org for free, why would they install KODO?* If the answer is not one of — the block↔text bridge with the child's own keywords, true offline on a low-end phone, graded practice volume with a real mastery rule, French-first curriculum quality, no ads and no chat, or a classroom mode that works without internet — then the answer is that they would not, and that is a Severity-1 finding against the product, not against the marketing.
>
> Write every finding into the improvement backlog with a RICE score, an owner and a loop number. Then re-open the cahier des charges and version it.
