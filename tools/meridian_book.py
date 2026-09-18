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

PROGRAMMES = [
    ("RUN", "Runtime & Editors", "Language & Runtime Architect", "PE-08"),
    ("PED", "Pedagogy & Practice", "Pedagogical Lead", "PE-03"),
    ("CRE", "Creation & Community", "Game Designer", "PE-06"),
    ("PLT", "Platform, School & Trust", "Cross-platform Engineering Lead", "PE-09"),
]

# module id, name, programme, site, pm, governance, phase, gate, start week, finish week,
# percent complete, health override
MODULES = [
    ("M1", "Language core and interpreter", "RUN", "REM", "PE-08", "group", 5, 12, 100),
    ("M4", "Canvas, stage, sprites and inspector", "RUN", "REM", "PE-08", "group", 7, 16, 0),
    ("M2", "Block editor", "RUN", "REM", "PE-07", "group", 9, 20, 0),
    ("M3", "Text editor and the block-text bridge", "RUN", "REM", "PE-08", "group", 12, 24, 0),
    ("M5", "Tutorial engine", "PED", "PAR", "PE-03", "site", 13, 24, 0),
    ("M6", "Exercise delivery and grading", "PED", "PAR", "PE-04", "group", 14, 26, 0),
    ("M7", "Progression, mastery and scheduling", "PED", "PAR", "PE-04", "group", 16, 28, 0),
    ("M14", "Offline-first content packs", "PLT", "REM", "PE-09", "group", 14, 26, 0),
    ("M13", "Accounts, identity and sync", "PLT", "REM", "PE-10", "group", 18, 30, 0),
    ("M8", "Motivation system", "PED", "REM", "PE-06", "site", 20, 30, 0),
    ("M11", "Parent space", "PLT", "DKR", "PE-12", "site", 22, 32, 0),
    ("M9", "Studio (free creation)", "CRE", "REM", "PE-07", "site", 27, 38, 0),
    ("M18", "Authoring CMS", "PED", "PAR", "PE-04", "group", 26, 40, 0),
    ("M12", "Classroom mode", "PLT", "DKR", "PE-12", "site", 41, 50, 0),
    ("M10", "Sharing, gallery and moderation", "CRE", "PAR", "PE-13", "group", 41, 50, 0),
    ("M15", "Localisation", "PLT", "DKR", "PE-11", "site", 20, 48, 0),
    ("M16", "Accessibility", "PLT", "REM", "PE-07", "group", 9, 48, 0),
    ("M17", "Analytics and learning telemetry", "PLT", "REM", "PE-10", "group", 24, 44, 0),
]

# The workbook's risk register, updated to reflect what is now true.
RISKS = [
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
    ("CR-003", "M10", "Remove the public gallery from v1 scope",
     "PO decision D-003. §13 requires every child-authored public text reviewed before "
     "publication and a 24-hour triage SLA. That is a staffing commitment we cannot hold at "
     "launch. Class galleries ship; the public gallery is gated behind a staffed moderation "
     "function and a seat-13 adversarial review.",
     "PE-01", 4, -3, -6, "Approved"),
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
]

# A module's shape of work. `w` is the share of the module the stage carries.
WBS = [
    ("Interface contract and specification review", 0.15),
    ("Build", 0.40),
    ("Acceptance tests and evidence", 0.20),
    ("Localisation and accessibility pass", 0.10),
    ("Child panel and pedagogical review", 0.15),
]


def build():
    projects, activities, milestones, raid, crs, items, docs = [], [], [], [], [], [], []

    for mid, name, prog, site, pm, gov, start_w, finish_w, pct in MODULES:
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
                    f"tagged {mid} in spec/requirements.json.",
            "phase": "Closure" if pct == 100 else ("Execution" if start_w <= 12 else "Initiation"),
            "gate": 4 if pct == 100 else (2 if start_w <= 12 else 1),
            "closed": False,
        })

        span = finish_w - start_w
        cursor = start_w
        for i, (stage_name, weight) in enumerate(WBS):
            length = max(1, round(span * weight))
            done = 100 if pct == 100 else 0
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
        "people": [{"id": pid, "name": f"Seat — {seat}", "role": owns, "site": site, "rate": 0}
                   for pid, seat, site, owns in SEATS],
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
            {"from": "M14", "fromStage": 1, "to": "M5", "toStage": 1,
             "label": "Tutorials are content-pack data, not code"},
        ],
        "milestones": milestones,
        "ledger": [],
        "raid": raid,
        "crs": crs,
        "allocations": [],
        "docs": docs,
        "items": items,
        "narrative": {
            "highlights": [
                "G1 closed. All six Annex E questions answered in the PO decision register "
                "(D-001 … D-006), with rationale and reversal cost. R9, the only risk the "
                "workbook records as outside the Committee's authority, is closed with it.",
                "G2 closed. M1's interface contract is frozen and implemented.",
                "M1 delivered: 7/7 acceptance tests green, 103 tests in total. R3 — the "
                "joint-highest risk in the register — is closed on evidence, not on a merged fix.",
                "Five defects were found and closed during the M1 build. Three of them were "
                "invisible until a child would have hit them.",
            ],
            "concerns": [
                "Every performance and platform claim so far is CI-measured. No measurement "
                "exists on the reference device (Android 11, 2 GB). G3 cannot close without it.",
                "The 22 child-facing error messages M1 ships have had no seat-3 or seat-11 "
                "review. They reach a child the moment M3 ships.",
                "No budget line has been agreed (NFR-COST-01, PO open item O-01), so every "
                "earned-value figure in this portfolio is zero by construction rather than by "
                "accident.",
                f"{done} of {requirements['count']} requirements are done. The curriculum "
                f"ledger commits {concepts['itemsCommitted']} items across "
                f"{concepts['conceptCount']} concepts and none are authored yet — authoring "
                "capacity, not engineering, sets the schedule (§12).",
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
