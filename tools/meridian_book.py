#!/usr/bin/env python3
"""Generate the KODO portfolio in Meridian's book format.

Meridian (github.com/mliad313sn/Meridian) is the delivery system of record for this
programme. Its `importBook` accepts a single JSON object in the engine's own field names;
this script produces that object from the artefacts that are already the truth here — the
requirement register, the concept ledger, the risk register and the PO decision register —
so the portfolio is generated from the programme rather than re-typed into it.

    python3 tools/meridian_book.py
    # then, in a running Meridian:  POST /api/v1/book/import  with the file as the body

Deliberately NOT invented: budgets. `NFR-COST-01` has no agreed figure and PO open item
O-01 records that. Writing a plausible number here would put fiction into the one screen
Meridian is best at, so every project carries a zero budget and the report says why.
"""
import json, pathlib, datetime as dt

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "delivery/meridian/kodo_book.json"

# Programme week 1. The cahier des charges is dated 18 September 2026; week 1 is the
# Monday of that week, so every gate date below is the workbook's week number, resolved.
WEEK1 = dt.date(2026, 9, 14)


def week(n, day=4):
    """End of programme week `n` (default Friday)."""
    return (WEEK1 + dt.timedelta(weeks=n - 1, days=day)).isoformat()


SITES = [
    {"id": "DKR", "city": "Dakar", "region": "Sénégal", "tz": 0, "tzName": "GMT",
     "headcount": 9, "fte": 8,
     "role": "Launch market · classroom pilot · partner-teacher authoring pool"},
    {"id": "PAR", "city": "Paris", "region": "France", "tz": 1, "tzName": "CET",
     "headcount": 7, "fte": 6,
     "role": "Curriculum authority · French-first content · narration"},
    {"id": "REM", "city": "Remote", "region": "Distributed", "tz": 0, "tzName": "UTC",
     "headcount": 6, "fte": 5, "role": "Runtime and client engineering · QA"},
]

# The fourteen Committee seats of §1.2. A seat is a competence, not necessarily a person.
SEATS = [
    ("PE-01", "Product Owner", "REM", "Scope, budget, release; final sign-off"),
    ("PE-02", "Committee Chair / Programme Director", "PAR", "Agenda, minutes, dissent log"),
    ("PE-03", "Pedagogical Lead (CS education)", "PAR", "The learning model — blocking veto"),
    ("PE-04", "Curriculum & Assessment Designer", "PAR", "Concept ledger and exercise bank"),
    ("PE-05", "Child Development Psychologist", "PAR", "Age-appropriateness veto"),
    ("PE-06", "Game Designer (ethical engagement)", "REM", "Motivation system"),
    ("PE-07", "Children's UX/UI + Accessibility", "REM", "Design system, WCAG"),
    ("PE-08", "Language & Runtime Architect", "REM", "Modules M1-M4"),
    ("PE-09", "Cross-platform Engineering Lead", "REM", "Architecture, device matrix"),
    ("PE-10", "Backend, Data & Learning Analytics", "REM", "M13, M17, item health telemetry"),
    ("PE-11", "Localisation & Culture Lead", "DKR", "FR/EN parity, Wolof roadmap"),
    ("PE-12", "Teacher & Parent Representative", "DKR", "M11, M12, classroom reality"),
    ("PE-13", "Child Safety, Privacy & Compliance", "PAR", "§13 — blocking veto on every gate"),
    ("PE-14", "QA & Release Manager", "DKR", "Test strategy, defect taxonomy"),
]

# The delivery squads (first line). The Committee specifies and reviews; these build.
# Charter: docs/governance/04_COMMITTEE_AND_DELIVERY_ORGANISATION.md
#   squad id, name, lead seat, site, fte, what it owns
SQUADS = [
    ("S1", "Client Shell squad", "PE-09", "REM", 2.0,
     "main.dart, the platform projects, navigation, state — M19. The critical path"),
    ("S2", "Learning Client squad", "PE-07", "REM", 3.0,
     "The ten missing screens: profile, world map, tutorial player, item player, Studio, gallery, parent, classroom"),
    ("S3", "Runtime & Platform squad", "PE-08", "REM", 2.0,
     "M1-M4 maintenance, and the platform APIs behind the consent gate"),
    ("S4", "Data & Trust squad", "PE-10", "REM", 1.0,
     "Sync, telemetry, the weekly curriculum health report, moderation operations"),
    ("S5", "Content Factory", "PE-04", "DKR", 5.0,
     "Worlds 3-12 — 948 items, the schedule's critical path per §12"),
    ("S6", "Voice & Art", "PE-11", "DKR", 1.0,
     "~380 recordings owed for Worlds 0-2, then Worlds 3-12; illustration"),
    ("S7", "Device & Release", "PE-14", "DKR", 1.0,
     "The G3 device run and every number only glass can give"),
]

PROGRAMMES = [
    ("RUN", "Runtime & Editors", "Language & Runtime Architect", "PE-08"),
    ("PED", "Pedagogy & Practice", "Pedagogical Lead", "PE-03"),
    ("CRE", "Creation & Community", "Game Designer", "PE-06"),
    ("PLT", "Platform, School & Trust", "Cross-platform Engineering Lead", "PE-09"),
]

# module id, name, programme, site, pm, governance, start week, finish week.
#
# Percent complete is NOT in this table. It is computed from `spec/requirements.json`, which
# is generated from the Committee's workbook and the squads' status overrides — so the
# portfolio moves when the delivery moves, and a module cannot be reported green here while
# its requirements say otherwise. The rule is stated once, in `completion_of` below, and it
# is deliberately unflattering: a requirement is finished or it is not.
MODULES = [
    ("M1", "Language core and interpreter", "RUN", "REM", "PE-08", "group", 5, 12),
    ("M4", "Canvas, stage, sprites and inspector", "RUN", "REM", "PE-08", "group", 7, 16),
    ("M2", "Block editor", "RUN", "REM", "PE-07", "group", 9, 20),
    ("M3", "Text editor and the block-text bridge", "RUN", "REM", "PE-08", "group", 12, 24),
    ("M5", "Tutorial engine", "PED", "PAR", "PE-03", "site", 13, 24),
    ("M6", "Exercise delivery and grading", "PED", "PAR", "PE-04", "group", 14, 26),
    ("M7", "Progression, mastery and scheduling", "PED", "PAR", "PE-04", "group", 16, 28),
    ("M14", "Offline-first content packs", "PLT", "REM", "PE-09", "group", 14, 26),
    ("M13", "Accounts, identity and sync", "PLT", "REM", "PE-10", "group", 18, 30),
    ("M8", "Motivation system", "PED", "REM", "PE-06", "site", 20, 30),
    ("M11", "Parent space", "PLT", "DKR", "PE-12", "site", 22, 32),
    ("M9", "Studio (free creation)", "CRE", "REM", "PE-07", "site", 27, 38),
    ("M18", "Authoring CMS", "PED", "PAR", "PE-04", "group", 26, 40),
    ("M12", "Classroom mode", "PLT", "DKR", "PE-12", "site", 41, 50),
    ("M10", "Sharing, gallery and moderation", "CRE", "PAR", "PE-13", "group", 41, 50),
    ("M15", "Localisation", "PLT", "DKR", "PE-11", "site", 20, 48),
    ("M16", "Accessibility", "PLT", "REM", "PE-07", "group", 9, 48),
    ("M17", "Analytics and learning telemetry", "PLT", "REM", "PE-10", "group", 24, 44),
    # Raised at G3 by PO decision D-012: eighteen modules were built and none of them was
    # the application. This is the critical path — every other module is invisible until it
    # lands. See docs/governance/04_COMMITTEE_AND_DELIVERY_ORGANISATION.md, squad S1.
    ("M19", "Application shell and navigation", "PLT", "REM", "PE-09", "group", 12, 24),
]

# The workbook's risk register, updated to reflect what is now true.
RISKS = [
    # Staffing findings raised by the PO when the Committee was seated. Issues, not risks:
    # a risk might happen, and these already have.
    ("SF-01", "Issue", "§17.2's team shape did not anticipate the application as a workstream",
     "The cahier allocates three Flutter engineers. What remains is an app shell from zero (M19), "
     "ten screens and a web CMS front end. Four are allocated in the charter — squads S1 and S2 — "
     "because one squad holding both makes the shell wait for design and the design wait for the shell.",
     5, 4, "Open", "Mitigate", "PE-01", "M19"),
    ("SF-02", "Issue", "Both external audits are launch preconditions and neither is commissioned",
     "NFR-A11Y-01 and NFR-SEC-01 block public launch. Auditors book months ahead and nobody has "
     "started. Seats 7 and 13 are directed to commission both now, against the current build, and "
     "to schedule the re-test — a finding closes on re-test evidence, never on a merged fix.",
     5, 4, "Open", "Mitigate", "PE-13", None),
    ("SF-03", "Issue", "The partner-teacher authoring pool does not exist yet",
     "R1's response is templates plus a teacher pool plus a weekly burn-up. The templates are proven "
     "— 266 items went through them. The pool has not been hired. At 120 artefacts a week the "
     "remaining 948 items are about 8 weeks of authoring once the pool works; hiring and training "
     "four partner teachers is not inside those 8 weeks.",
     4, 5, "Open", "Mitigate", "PE-04", None),
    ("R1", "Risk", "Item authoring under-delivers; the bank is thin and mastery becomes a claim",
     "Templates, partner-teacher pool, weekly burn-up at Committee. Scope is cut in worlds, never in items per concept.",
     4, 5, "Open", "Mitigate", "PE-04", None),
    ("R2", "Risk", "Block editor performance fails on 2 GB Android",
     "Performance budget fixed in P1; the reference device is the gate device; custom painter, no webview. Mode leger raised as FR-M4-09.",
     3, 5, "Open", "Mitigate", "PE-09", "M2"),
    ("R3", "Risk", "Dual-representation round-tripping is harder than assumed",
     "CLOSED on evidence: M1 acceptance test 1 round-trips 1000 generated programs in both keyword languages, and test 2 proves a lossless mid-run locale swap. Three defects found and fixed in the process.",
     4, 5, "Closed", "Mitigate", "PE-08", "M1"),
    ("R4", "Risk", "Offline content packs exceed device storage",
     "Per-world size budget enforced in CI; Opus audio; vector art.", 3, 3, "Open", "Mitigate", "PE-09", "M14"),
    ("R5", "Risk", "Safety and compliance rework arrives late",
     "Seat 13 embedded from P1; consent flows designed before the first account screen exists. Camera capture removed from v1 by PO decision D-007.",
     2, 5, "Open", "Avoid", "PE-13", "M13"),
    ("R6", "Risk", "We build a smaller Scratch and lose on every axis",
     "The G5 protocol exists to detect this; the differentiators of §15.3 are treated as requirements. D-005 adds a one-way Python projection as a concrete exit ramp.",
     3, 5, "Open", "Monitor", "PE-02", None),
    ("R7", "Risk", "Voice-over cost and re-recording after content changes",
     "Freeze narration copy per world before recording; hold a 15% re-record reserve.", 4, 2, "Open", "Accept", "PE-11", "M15"),
    ("R8", "Risk", "Committee decision drift: enthusiasm outranks evidence",
     "Dissent log, consent rule, third-line independent review before G5 and before launch.", 3, 4, "Open", "Mitigate", "PE-02", None),
    ("R9", "Risk", "No sustainable funding model decided",
     "CLOSED by PO decision D-001: free core forever, funded by school licences and institutional funding, no child-facing paywall.",
     4, 4, "Closed", "Avoid", "PE-01", None),
    ("R10", "Dependency", "Reference-device measurements are owed for every module",
     "M1 is proven on CI only. The Android 11 / 2 GB device matrix must exist before G3 can close. Tracked as M1-PERF-01 and M1-PLAT-01.",
     4, 4, "Open", "Mitigate", "PE-09", "M1"),
    ("R11", "Assumption", "120 published artefacts per week is achievable at steady state",
     "Committee planning figure, never observed. The whole 10.9-week authoring estimate rests on it; the first four weeks of real authoring either confirm it or reset the schedule.",
     3, 5, "Open", "Monitor", "PE-04", "M18"),
    ("R13", "Issue", "M7-SIM-01 — the mastery rule needs a bigger bank than the curriculum commits",
     "Measured over 10 000 synthetic learners: at §4.6's 8-item accuracy window the "
     "95th-percentile CAPABLE child needs about 30 items on a concept, against the 18-24 "
     "§6.3 commits. Answered by PO decision D-010 (widen the window to 10, a variance "
     "reduction rather than a softening). Seats 3 and 4 hold the ruling until G3.",
     4, 4, "Open", "Mitigate", "PE-03", "M7"),
    ("R14", "Risk", "M14-SEC-01 — content packs are integrity-checked but not authenticated",
     "SHA-256 detects a corrupted or truncated pack, which covers what a classroom meets. "
     "It does not prove who made a pack. FR-M14-02 says signed; Ed25519 verification in "
     "pure Dart is not written. Recorded rather than papered over with an HMAC, which "
     "would put the signing key on every device.",
     3, 4, "Open", "Mitigate", "PE-09", "M14"),
    ("R15", "Issue", "World 1's 100 items have had no seat-3 or seat-4 pedagogical review",
     "The bank is machine-gated — every item is failed by three wrong programs and passed "
     "by two alternatives — but nobody has read it. The gate proves an item is GRADABLE, "
     "never that it TEACHES.",
     5, 3, "Open", "Fix", "PE-04", "M6"),
    ("R12", "Issue", "22 child-facing error messages have had no pedagogical or localisation review",
     "M1 ships a closed error catalogue in FR and EN. Neither seat 3 nor seat 11 has read them aloud. They reach a child as soon as M3 ships.",
     5, 3, "Open", "Fix", "PE-03", "M1"),
]

# The improvement backlog, as cards on a board.
BACKLOG = [
    ("IMP-001", "Ship project export/import so a KODO graduate can continue in Scratch", "M9", "P2", 4),
    ("IMP-002", "Printable unplugged worksheets + 6-hour teacher onboarding; school tier at zero for public schools", "M12", "P2", 6),
    ("IMP-003", "Spaced-repetition scheduling with a forgetting curve per concept; A/B against the fixed 60/20/20 mix", "M7", "P3", 5),
    ("IMP-004", "Illustration and motion pass for Worlds 0-2; remove all reading dependency from the first 15 minutes", "M5", "P2", 8),
    ("IMP-005", "Animated target preview before a build-to-target item starts", "M6", "P1", 2),
    ("IMP-006", "Rewrite the C6.2 and C7.2 item sets with a stronger worked-example fade", "M18", "P2", 3),
    ("IMP-007", "Replace the block/text toggle icon with an animated first-use demonstration", "M3", "P3", 1),
    ("IMP-008", "SD-card and USB pack sideloading with a checksum verification screen", "M14", "P2", 3),
    ("IMP-009", "Disable camera capture in v1; keep gallery import behind parental consent", "M4", "P1", 1),
    ("IMP-010", "Programming keyboard row and inline error affordances before World 11 ships", "M3", "P2", 4),
]

# PO amendments raised at G1 are change requests: that is exactly what they are.
CHANGE_REQUESTS = [
    ("CR-001", "M4", "Add FR-M4-09 — mode leger below 3 GB RAM",
     "PO decision D-004. Rather than lowering the device floor to 1 GB, a rendering budget "
     "auto-enabled below 3 GB: reduced motion, no ghosted path overlay, lowered segment "
     "ceiling. It is a budget, not a second code path, and it must not change a grading result.",
     "PE-01", 4, 0, 2, "Approved"),
    ("CR-002", "M3", "Add FR-M3-09 — read-only Python projection in World 12",
     "PO decision D-005. A third one-way projection of the same AST. No Python is parsed or "
     "executed. Proven in M1 already: the emitter is 150 lines over the existing renderer.",
     "PE-01", 4, 0, 1, "Approved"),
    ("CR-007", "M19", "Add M19 — application shell and navigation (FR-M19-01 … 06)",
     "PO decision D-012, raised at G3. Eighteen modules were built, all eighteen pass their "
     "acceptance tests, and there is no application: no entry point, no platform project, nothing "
     "that assembles the eleven packages into something a child can open. Searching the eighteen "
     "module prompts for shell, navigation or home screen returns nothing. A decomposition that "
     "names every organ and no body produces exactly this. Adds a module; changes none.",
     "PE-01", 12, 0, 0, "Approved"),
    ("CR-003", "M10", "Remove the public gallery from v1 scope",
     "PO decision D-003. §13 requires every child-authored public text reviewed before "
     "publication and a 24-hour triage SLA. That is a staffing commitment we cannot hold at "
     "launch. Class galleries ship; the public gallery is gated behind a staffed moderation "
     "function and a seat-13 adversarial review.",
     "PE-01", 4, -3, -6, "Approved"),
    ("CR-005", "M7", "Widen mastery criterion 2's window from 8 items to 10",
     "PO decision D-010, answering M7-SIM-01. A longer window is a better estimate of a "
     "child's rate, not a kinder one, and the simulation confirms the half that matters: "
     "no more weak learners get through. The alternative — raising the per-concept "
     "commitment to ~30 — costs about +390 items on the programme's stated critical path.",
     "PE-01", 12, 0, 0, "Approved"),
    ("CR-006", "M6", "Add a final-pose signal to behavioural grading",
     "Found by the publish gate while authoring World 1: 'go out and come back' draws "
     "exactly the same pixels as 'go out', so thirteen items' wrong solutions all passed. "
     "Item.requireFinalPose is authored per item, because most items are about a figure "
     "and demanding a final pose on those would fail a child who drew it from the other end.",
     "PE-08", 12, 0, 0, "Approved"),
    ("CR-004", "M4", "Remove camera capture from v1",
     "PO decision D-007, promoting IMP-009 from a backlog item to scope. An S1 finding at "
     "confidence 1.0 is not a backlog candidate; it is a decision nobody had taken.",
     "PE-13", 4, -1, -1, "Approved"),
]

DOCS = [
    ("DOC-001", None, "Cahier des charges v1.0", "Charter", 1, "PE-02", "1.0", "Approved"),
    ("DOC-002", None, "Curriculum, Benchmark & Improvement Backlog workbook", "Quality", 1, "PE-04", "1.0", "Approved"),
    ("DOC-003", None, "Module Deployment Prompt Library v1.0", "Design", 2, "PE-08", "1.0", "Approved"),
    ("DOC-004", None, "Product Owner decision register (D-001 … D-008)", "Charter", 1, "PE-01", "1.0", "Approved"),
    ("DOC-005", None, "Gate register", "Assurance", 1, "PE-02", "1.1", "Approved"),
    ("DOC-006", "M1", "M1 Definition of Done, defects and outstanding items", "Quality", 3, "PE-14", "1.0", "Approved"),
    ("DOC-007", None, "Requirement traceability report (generated in CI)", "Assurance", 2, "PE-14", "auto", "Approved"),
    ("DOC-008", None, "Ways of working: committee, decision rights, severity scale", "Governance", 1, "PE-02", "1.0", "Approved"),
    ("DOC-009", None, "G3 assessment: the criterion clause by clause, and the 30 open requirements", "Assurance", 3, "PE-14", "1.0", "Approved"),
    ("DOC-010", None, "Committee and delivery organisation: 14 seats, 7 squads, the RACI", "Governance", 3, "PE-01", "1.0", "Approved"),
    ("DOC-011", "M19", "M19 deployment prompt — application shell and navigation", "Design", 3, "PE-09", "1.0", "Approved"),
]

# A module's shape of work. `w` is the share of the module the stage carries.
WBS = [
    ("Interface contract and specification review", 0.15),
    ("Build", 0.40),
    ("Acceptance tests and evidence", 0.20),
    ("Localisation and accessibility pass", 0.10),
    ("Child panel and pedagogical review", 0.15),
]


REQUIREMENTS = json.loads((ROOT / "spec/requirements.json").read_text(encoding="utf-8"))
_REQ_ROWS = REQUIREMENTS["requirements"] if isinstance(REQUIREMENTS, dict) else REQUIREMENTS


# Which module carries each non-functional requirement, and what it is actually waiting
# for. Used twice: to put a card on the improvement board, and to stop a module reporting
# Closure while an NFR it owns is open.
NFR_HOME = {
    "PERF": ("M4", "a phone"), "SIZE": ("M14", "a phone"),
    "BATT": ("M4", "a phone"), "OFF": ("M14", "a phone"),
    "REL": ("M13", "a phone"), "COMP": ("M16", "a phone"),
    "SEC": ("M14", "an external reviewer"),
    "A11Y": ("M16", "an external reviewer"),
    "PRIV": ("M13", "nothing — done"),
    "I18N": ("M15", "nothing — done"),
    "MAINT": ("M14", "nothing — done"),
    "COST": ("M11", "PO open item O-01"),
}


def open_nfrs_of(module_id):
    """The non-functional requirements this module owns that are not Done."""
    return [
        r["id"] for r in _REQ_ROWS
        if r["id"].startswith("NFR-")
        and NFR_HOME.get(r.get("moduleId", ""), (None, None))[0] == module_id
        and r.get("status") != "Done"
    ]


def completion_of(module_id):
    """Percent complete for a module, read off its requirements.

    Done counts 1, In progress counts a half, Not started counts nothing. The half is the
    only judgement in the whole book and it is generous on purpose: if the number looks
    optimistic against the module's own DONE record, the DONE record wins, because that is
    where the evidence is.

    A module with no requirements of its own (none, currently) would report zero rather
    than a hundred, because "nothing to do" and "everything done" must not look alike on a
    portfolio screen.
    """
    mine = [r for r in _REQ_ROWS if r.get("moduleId") == module_id]
    if not mine:
        return 0
    score = sum({"Done": 1.0, "In progress": 0.5}.get(r.get("status"), 0.0) for r in mine)
    return round(score / len(mine) * 100)


def build():
    projects, activities, milestones, raid, crs, items, docs = [], [], [], [], [], [], []
    allocations = []

    for mid, name, prog, site, pm, gov, start_w, finish_w in MODULES:
        pct = completion_of(mid)
        projects.append({
            "id": mid, "name": f"{mid} — {name}", "programme": prog, "site": site,
            "governanceLevel": gov, "pm": pm, "method": "Hybrid",
            "start": week(start_w, 0), "finish": week(finish_w),
            "baselineFinish": week(finish_w),
            # Budget is deliberately zero: NFR-COST-01 has no agreed figure and PO open
            # item O-01 records that. See delivery/meridian/README.md.
            "budget": 0, "contingency": 0, "contingencyUsed": 0,
            "desc": f"Module {mid} of the eighteen. Built from its deployment prompt in "
                    f"docs/spec/03_module_build_prompts_v1.0.md against the requirements "
                    f"tagged {mid} in spec/requirements.json. "
                    + (f"Open non-functional requirements: {', '.join(open_nfrs_of(mid))}."
                       if open_nfrs_of(mid)
                       else "No open non-functional requirements."),
            # A module is in Closure only when its functional requirements are all Done
            # AND it owns no open non-functional requirement. M16 with the external
            # accessibility audit outstanding is not closed, however green its FRs are.
            "phase": "Closure" if (pct == 100 and not open_nfrs_of(mid))
                     else ("Execution" if pct > 0 or start_w <= 12 else "Initiation"),
            # Gate 4 is a PROGRAMME gate and G3 is not closed, so no module may report
            # past 3. A module bar reading gate 4 above an open G3 is the false green this
            # portfolio exists to prevent — and finding MER-05 of the product report is
            # about exactly that kind of number.
            "gate": 3 if pct == 100 else (2 if pct >= 60 or start_w <= 12 else 1),
            "closed": False,
        })

        span = finish_w - start_w
        cursor = start_w
        # Spend the module's completion across its stages in order, so the earned-value
        # curve reflects which stages are actually finished rather than a flat average.
        remaining = pct / 100.0
        for i, (stage_name, weight) in enumerate(WBS):
            length = max(1, round(span * weight))
            share = min(weight, remaining)
            remaining -= share
            done = round(share / weight * 100)
            activities.append({
                "id": f"{mid}-A{i + 1}", "project": mid, "name": stage_name, "stage": i,
                "start": week(cursor, 0), "end": week(cursor + length),
                "weight": weight, "pct": done,
                "owner": pm,
                "deps": [f"{mid}-A{i}"] if i else [],
            })
            cursor += length

    # KODO's own gates, as milestones on the modules that carry them.
    gate_dates = {"G1": 4, "G2": 5, "G3": 12, "G4.1": 26, "G5.1": 27,
                  "G4.2": 40, "G5.2": 41, "G4.3": 52, "G5.3": 53}
    milestones.append({"id": "MS-G1", "project": "M1", "name": "G1 — Cahier des charges accepted",
                       "date": week(gate_dates["G1"]), "kind": "gate", "gate": 1,
                       "owner": "PE-01", "done": True})
    milestones.append({"id": "MS-G2", "project": "M1", "name": "G2 — Module prompts reviewed",
                       "date": week(gate_dates["G2"]), "kind": "gate", "gate": 2,
                       "owner": "PE-08", "done": True})
    milestones.append({"id": "MS-G3", "project": "M6", "name": "G3 — Vertical slice on the reference device",
                       "date": week(gate_dates["G3"]), "kind": "gate", "gate": 3,
                       "owner": "PE-14", "done": False})
    for n, (label, wk) in enumerate([("G4 loop 1", 26), ("G5 loop 1", 27), ("G4 loop 2", 40),
                                     ("G5 loop 2", 41), ("G4 loop 3", 52), ("G5 loop 3", 53)]):
        milestones.append({
            "id": f"MS-{label.replace(' ', '-')}", "project": "M17",
            "name": f"{label} — {'deep review' if label.startswith('G4') else 'market challenge'}",
            "date": week(wk), "kind": "gate" if n < 2 else "milestone",
            "gate": 4 if n < 2 else None,
            "owner": "PE-13" if label.startswith("G4") else "PE-02", "done": False})

    milestones.append({"id": "MS-M1-DONE", "project": "M1",
                       "name": "M1 acceptance tests green (7/7)", "date": week(12),
                       "kind": "milestone", "owner": "PE-08", "done": True})
    for mid, label, wk in [
        ("M4", "M4 canvas, stage and inspector — 39 tests green", 12),
        ("M6", "M6 grading and the publish gate — 36 tests green", 12),
        ("M7", "M7 mastery and scheduling — 27 tests green", 12),
        ("M14", "World 1 published: 100 items, 5 tutorials, all gated", 12),
        ("M6", "G3 vertical slice runs end to end, offline", 12),
    ]:
        milestones.append({
            "id": f"MS-{mid}-{label[:6].strip().replace(' ', '-')}",
            "project": mid, "name": label, "date": week(wk),
            "kind": "milestone", "owner": "PE-14", "done": True})

    for rid, kind, title, response_detail, p, i, status, response, owner, project in RISKS:
        raid.append({"id": rid, "project": project, "type": kind, "title": title,
                     "detail": response_detail, "p": p, "i": i, "status": status,
                     "response": response, "owner": owner,
                     "opened": week(1), "review": week(12)})

    for cid, project, title, desc, raised_by, week_raised, weeks, cost, status in CHANGE_REQUESTS:
        crs.append({"id": cid, "project": project, "title": title, "desc": desc,
                    "raisedBy": raised_by, "raised": week(week_raised),
                    "cost": 0, "weeks": weeks, "funding": "Contingency",
                    "riskDelta": "0", "status": status, "applied": True,
                    "steps": [
                        {"role": "Raised", "state": "done", "when": week(week_raised)},
                        {"role": "Committee consent", "state": "done", "when": week(week_raised)},
                        {"role": "Product Owner", "state": "done", "when": week(week_raised),
                         "comment": "Registered as an amendment, not a silent edit (§16)."},
                    ]})

    # The non-functional requirements, as cards. A portfolio that shows eighteen module
    # bars and hides fourteen NFRs is hiding precisely the part that is not finished, so
    # each one is a card on the improvement board, carrying what it is actually waiting
    # for. Grouped per `docs/governance/03_G3_ASSESSMENT.md`.
    for requirement in _REQ_ROWS:
        rid = requirement["id"]
        if not rid.startswith("NFR-"):
            continue
        family = requirement.get("moduleId", "")
        home, waiting = NFR_HOME.get(family, ("M1", "a decision"))
        status = requirement.get("status", "Not started")
        items.append({
            "id": rid,
            "project": home,
            "column": "done" if status == "Done"
                      else ("doing" if status == "In progress" else "next"),
            "title": f"{rid} — {requirement.get('requirement', '')}",
            "assignee": None,
            "points": 0 if status == "Done" else 3,
            "priority": "P1",
            "created": week(1),
            "note": f"Waiting on: {waiting}. Verification: "
                    f"{requirement.get('verification', 'not stated')}.",
        })

    # squad -> the module projects it owns. Charter part 2.
    SQUAD_PROJECTS = {
        "S1": ["M19"],
        "S2": ["M2", "M3", "M5", "M6", "M9", "M11", "M12"],
        "S3": ["M1", "M4", "M14"],
        "S4": ["M13", "M17", "M10"],
        "S5": ["M18"],
        "S6": ["M15", "M16"],
        "S7": ["M7", "M8"],
    }
    for sid, name, lead, site, fte, owns in SQUADS:
        targets = SQUAD_PROJECTS.get(sid, [])
        if not targets:
            continue
        # Meridian's allocation is a PERCENTAGE of the entity's time (`allocation.pct`),
        # not an FTE count — an `fte` key is silently dropped and the row lands at 0 %,
        # which reads as a squad assigned to a project and doing nothing on it. The squad's
        # head count lives on its person record instead.
        share = round(100 / len(targets))
        for project in targets:
            allocations.append({
                "person": sid, "project": project,
                "from": week(12, 0), "to": week(52),
                "pct": share,
            })

    for iid, title, module, priority, points in BACKLOG:
        items.append({"id": iid, "project": module, "column": "backlog", "title": title,
                      "assignee": None, "points": points, "priority": priority,
                      "created": week(1)})

    for did, project, name, doc_type, gate, owner, rev, status in DOCS:
        docs.append({"id": did, "project": project, "name": name, "type": doc_type,
                     "gate": gate, "owner": owner, "rev": rev, "status": status,
                     "updated": week(4)})

    concepts = json.loads((ROOT / "spec/concepts.json").read_text(encoding="utf-8"))
    requirements = json.loads((ROOT / "spec/requirements.json").read_text(encoding="utf-8"))
    done = sum(1 for r in requirements["requirements"] if r.get("status") == "Done")

    return {
        "orgName": "KODO",
        "statusDate": dt.date(2026, 9, 18).isoformat(),
        "sites": SITES,
        "people": [
            {"id": pid, "name": f"Seat {pid[-2:]} — {seat}", "role": owns, "site": site,
             "rate": 0}
            for pid, seat, site, owns in SEATS
        ] + [
            {"id": sid, "name": f"{sid} — {name} ({fte:g} FTE)", "role": owns,
             "site": site, "rate": 0}
            for sid, name, lead, site, fte, owns in SQUADS
        ],
        "programmes": [{"id": pid, "name": name, "sponsor": sponsor, "managerId": mgr}
                       for pid, name, sponsor, mgr in PROGRAMMES],
        "columns": [{"id": "backlog", "name": "Improvement backlog", "wip": 0},
                    {"id": "next", "name": "Next loop", "wip": 5},
                    {"id": "doing", "name": "In hand", "wip": 3},
                    {"id": "done", "name": "Closed on evidence", "wip": 0}],
        "projects": projects,
        "activities": activities,
        "crossDeps": [
            {"from": "M1", "fromStage": 2, "to": "M4", "toStage": 0,
             "label": "M4 implements the Surface contract frozen by M1"},
            {"from": "M1", "fromStage": 2, "to": "M2", "toStage": 0,
             "label": "M2 edits the M1 AST directly"},
            {"from": "M1", "fromStage": 2, "to": "M3", "toStage": 0,
             "label": "M3 uses only M1's parse and render"},
            {"from": "M4", "fromStage": 2, "to": "M6", "toStage": 0,
             "label": "M6 grades against a headless M4 surface"},
            {"from": "M6", "fromStage": 2, "to": "M7", "toStage": 0,
             "label": "M7 consumes Attempt from M6"},
            {"from": "M18", "fromStage": 2, "to": "M6", "toStage": 1,
             "label": "The publish gate is what makes an item gradable"},
            # The one that explains the whole plan: no child can be put in front of any
            # module until there is an application to open. Every module's child-panel
            # stage waits on M19's build.
            {"from": "M19", "fromStage": 1, "to": "M2", "toStage": 4,
             "label": "No child panel on any screen until there is an app to open it in"},
            {"from": "M19", "fromStage": 1, "to": "M6", "toStage": 4,
             "label": "The item player needs a shell before a child can reach an item"},
            {"from": "M19", "fromStage": 1, "to": "M7", "toStage": 4,
             "label": "Progression is invisible without a world map to show it on"},
            {"from": "M14", "fromStage": 1, "to": "M5", "toStage": 1,
             "label": "Tutorials are content-pack data, not code"},
        ],
        "milestones": milestones,
        "ledger": [],
        "raid": raid,
        "crs": crs,
        # Who is actually on what. Squads are allocated to the projects they own in the
        # charter; Committee seats are not allocated, because the Committee does not build
        # (§1.1) and showing it as delivery capacity would overstate the team by nine FTE.
        "allocations": allocations,
        "docs": docs,
        "items": items,
        "narrative": {
            "highlights": [
                "G1 and G2 closed on evidence. All six Annex E questions answered in the "
                "PO decision register (D-001 … D-011), each with rationale and reversal "
                "cost. R9, the only risk the workbook records as outside the Committee's "
                "authority, is closed with D-001.",
                "All eighteen modules are built. Eleven packages, ~28 000 lines of Dart, "
                "441 tests passing, every module prompt's automatable acceptance tests "
                "green.",
                f"{done} of {requirements['count']} requirements are Done, and every one "
                "of them is named by a test — enforced in CI, which fails the build if a "
                "requirement claims Done without one.",
                "Three worlds authored and published: 266 items over 13 concepts, every "
                "concept at or above its §6.3 commitment and using at least five item "
                "types. Each pack is re-authored through the publish gate in CI and then "
                "diffed, so a bank that ships and a bank that was checked are the same "
                "bank.",
                "The gates did their job. Thirty-four authoring faults were refused before "
                "anything was written, and nine build defects were found — four of which "
                "would have reached a child, including an editor that silently deleted a "
                "line of a child's saved work (M3-001, S1).",
                "The G3 vertical slice runs end to end and offline: pack verified, "
                "tutorial played, items scheduled, answers graded, mastery reached, next "
                "concept unlocked. Every component is the real one.",
                "NFR-MAINT-01 is closed by demonstration rather than by architecture: "
                "Worlds 0 and 2 were added after every package was built, with no change "
                "to any lib/ file.",
                "The Committee is seated and the delivery organisation is standing: 14 "
                "seats with their vetoes and first actions, 7 squads with explicit "
                "ownership, and a RACI over all 14 remaining work packages. See "
                "docs/governance/04_COMMITTEE_AND_DELIVERY_ORGANISATION.md.",
            ],
            "concerns": [
                "M19 DID NOT EXIST UNTIL NOW. Eighteen modules were built, all eighteen "
                "pass their acceptance tests, and there is no application — no entry point, "
                "no platform project, nothing that assembles the eleven packages into "
                "something a child can open. No module prompt ever asked for one. Raised as "
                "PO decision D-012 and CR-007; it is the critical path and every module's "
                "child-panel stage now waits on it.",
                "Thirteen of the fourteen Committee seats are UNFILLED. Seat 1 is seated. "
                "The Chair is the first appointment, because an unfilled Chair means the "
                "dissent log has no keeper.",
                "G3 IS NOT CLOSED, and closes on one thing: its own criterion ends "
                "'running on the reference low-end device', and nobody has run it on an "
                "Android 11 phone with 2 GB of RAM. Twelve of the thirty open requirements "
                "are waiting on that phone and nothing else. See "
                "docs/governance/03_G3_ASSESSMENT.md for the protocol seat 14 should run.",
                "Every performance, size, battery and soak figure in this portfolio is "
                "CI-measured. A number measured on a build server is not a number measured "
                "on the reference device, and reporting it as one is how a product ships "
                "slow.",
                "Nobody has READ the 266 items. The banks are machine-gated, which proves "
                "every item is gradable and proves nothing about whether it teaches. Seats "
                "3 and 4 owe a review before a child sees them.",
                "The 22 child-facing error messages and every tutorial line have had no "
                "seat-11 review. They are the strings a child meets when they are already "
                "stuck.",
                "No budget line has been agreed (NFR-COST-01, PO open item O-01), so every "
                "earned-value figure in this portfolio is zero by construction rather than "
                "by accident.",
                "Seven requirements wait on platform plumbing Flutter has not been wired to "
                "yet — sound, image import, screen capture, pack download, autocomplete. "
                "The consent gate they sit behind is built and tested; the plumbing is not.",
                "Two external reviews are preconditions of public launch and neither has "
                "been commissioned: the WCAG 2.2 AA audit (NFR-A11Y-01) and the security "
                "review (NFR-SEC-01).",
                "M7-SIM-01 remains an open S2 against G3: the mastery rule as specified "
                "needs about 30 items per concept against the 18-24 committed. PO decision "
                "D-010 proposes the fix; seats 3 and 4 hold the ruling.",
            ],
        },
        "settings": {"autoRag": True, "gateLock": True, "ccb": True},
    }


if __name__ == "__main__":
    book = build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(book, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    # The import endpoint reads req.body.db, so ship the wrapped payload too rather than
    # making every caller remember the wrapper (server/src/routes/admin.js:729).
    payload = OUT.with_name("kodo_import_payload.json")
    payload.write_text(json.dumps({"db": book}, ensure_ascii=False, indent=2) + "\n",
                       encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}")
    print(f"wrote {payload.relative_to(ROOT)}")
    for key in ("sites", "people", "programmes", "projects", "activities", "milestones",
                "raid", "crs", "docs", "items", "crossDeps"):
        print(f"  {key:12} {len(book[key])}")
