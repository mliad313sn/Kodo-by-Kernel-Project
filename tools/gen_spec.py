#!/usr/bin/env python3
"""Regenerate the machine-readable specification from the committee workbook.

The workbook (docs/spec/_source/02_*.xlsx) stays the human artefact. This script is the
only path from it into spec/*.json, so the two can never silently diverge: CI regenerates
and diffs. Run: python3 tools/gen_spec.py
"""
import json, pathlib, zipfile, xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "docs/spec/_source/02_KODO_Curriculum_Benchmark_Backlog.xlsx"
OUT = ROOT / "spec"
M = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"


def sheets(path):
    z = zipfile.ZipFile(path)
    shared = []
    if "xl/sharedStrings.xml" in z.namelist():
        for si in ET.fromstring(z.read("xl/sharedStrings.xml")):
            shared.append("".join(t.text or "" for t in si.iter(f"{{{M}}}t")))
    rels = {r.get("Id"): r.get("Target") for r in ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))}
    wb = ET.fromstring(z.read("xl/workbook.xml"))
    out = {}
    for sh in wb.find(f"{{{M}}}sheets"):
        target = rels[sh.get(f"{{{R}}}id")].lstrip("/")
        path_in = target if target.startswith("xl/") else "xl/" + target
        rows = []
        for row in ET.fromstring(z.read(path_in)).iter(f"{{{M}}}row"):
            cells, width = {}, 0
            for c in row.findall(f"{{{M}}}c"):
                ref = "".join(ch for ch in c.get("r") if ch.isalpha())
                idx = 0
                for ch in ref:
                    idx = idx * 26 + (ord(ch) - 64)
                idx -= 1
                width = max(width, idx)
                v, inline = c.find(f"{{{M}}}v"), c.find(f"{{{M}}}is")
                if inline is not None:
                    val = "".join(x.text or "" for x in inline.iter(f"{{{M}}}t"))
                elif v is None:
                    val = ""
                elif c.get("t") == "s":
                    val = shared[int(v.text)]
                else:
                    val = v.text or ""
                cells[idx] = val.strip()
            rows.append([cells.get(i, "") for i in range(width + 1)])
        out[sh.get("name")] = rows
    return out


def module_id(rid):
    """FR-M12-03 -> M12 ; NFR-PERF-01 -> PERF."""
    return rid.split("-")[1]


def pad(row, n):
    return (row + [""] * n)[:n]


def requirements(rows):
    out, seen = [], set()
    for row in rows:
        row = pad(row, 9)
        rid = row[0]
        if not (rid.startswith("FR-") or rid.startswith("NFR-")):
            continue
        if rid in seen:
            raise SystemExit(f"duplicate requirement id in workbook: {rid}")
        seen.add(rid)
        out.append({
            "id": rid,
            "moduleId": module_id(rid),
            "module": row[1],
            "requirement": row[2],
            "source": row[3],
            "priority": row[4],
            "verification": row[5],
            "gate": row[6],
            "status": row[7] or "Not started",
            "owner": row[8],
        })
    return out


def concepts(rows):
    out = []
    for row in rows:
        row = pad(row, 11)
        cid = row[2]
        if not (len(cid) > 2 and cid[0] == "C" and cid[1].isdigit()):
            continue
        out.append({
            "id": cid,
            "world": int(row[0]),
            "worldName": row[1],
            "fr": row[3],
            "en": row[4],
            "prerequisites": [] if row[5] in ("-", "") else [p.strip() for p in row[5].split(",")],
            "band": row[6],
            "itemsMin": int(row[7]) if row[7].isdigit() else 0,
            "itemTypes": [t.strip() for t in row[8].split(",") if t.strip()],
            "misconception": row[9],
            "source": row[10],
        })
    return out


def main():
    book = sheets(SRC)
    OUT.mkdir(exist_ok=True)

    reqs = requirements(book["Exigences"])
    cons = concepts(book["Curriculum"])

    # Amendments raised by the Product Owner at G1. They are additions to the register, not
    # edits to it: the cahier des charges forbids changing a requirement silently (§16).
    amendments = [
        {"id": "FR-M4-09", "module": "M4 Canvas & stage",
         "requirement": "Mode leger auto-enabled below 3 GB RAM; rendering budget only, never changes a grading result",
         "source": "[PO D-004]", "priority": "M",
         "verification": "Device matrix test + grading-equality test between modes",
         "gate": "G3", "status": "Not started", "owner": "", "moduleId": "M4"},
        {"id": "FR-M3-09", "module": "M3 Text editor",
         "requirement": "Read-only one-way Python projection of the AST, World 12 only; no Python parsed or executed",
         "source": "[PO D-005]", "priority": "S",
         "verification": "Renderer test over the shared AST; no second parser in the dependency graph",
         "gate": "G4", "status": "Not started", "owner": "", "moduleId": "M3"},
        # M19 — the module the cahier does not have. Raised at G3 (PO decision D-012) after
        # eighteen modules were built and none of them turned out to be the application:
        # there is no entry point, no navigation and no platform project, because no module
        # prompt ever asked for one.
        {"id": "FR-M19-01", "module": "M19 Application shell",
         "requirement": "One application entry point assembling every module, with a platform project per target",
         "source": "[PO D-012]", "priority": "M",
         "verification": "The app builds and launches on each target in the device matrix",
         "gate": "G3", "status": "Not started", "owner": "", "moduleId": "M19"},
        {"id": "FR-M19-02", "module": "M19 Application shell",
         "requirement": "Navigation from profile to world map to tutorial and item player and Studio, with a back path from every screen",
         "source": "[PO D-012]", "priority": "M",
         "verification": "Navigation test: every screen reachable, every screen exitable, no dead end",
         "gate": "G3", "status": "Not started", "owner": "", "moduleId": "M19"},
        {"id": "FR-M19-03", "module": "M19 Application shell",
         "requirement": "Application state survives process death; the child returns to the item they were on",
         "source": "[PO D-012]", "priority": "M",
         "verification": "Force-kill test on the reference device, 50 times, as FR-M9-03 does for the Studio",
         "gate": "G3", "status": "Not started", "owner": "", "moduleId": "M19"},
        {"id": "FR-M19-04", "module": "M19 Application shell",
         "requirement": "One settings surface for interface language, keyword language and accessibility preferences, applied app-wide",
         "source": "[PO D-012]", "priority": "M",
         "verification": "Setting each preference once changes every screen; asserted across the widget tree",
         "gate": "G3", "status": "Not started", "owner": "", "moduleId": "M19"},
        {"id": "FR-M19-05", "module": "M19 Application shell",
         "requirement": "Cold start goes to where the child was, with no login wall and no network call",
         "source": "[PO D-012]", "priority": "M",
         "verification": "Cold start measured on the reference device with aircraft mode on",
         "gate": "G3", "status": "Not started", "owner": "", "moduleId": "M19"},
        {"id": "FR-M19-06", "module": "M19 Application shell",
         "requirement": "The shell composes modules and owns no learning logic: no grading, no mastery, no content",
         "source": "[PO D-012]", "priority": "M",
         "verification": "Dependency test: the shell imports module APIs and defines no grader, no mastery rule and no item",
         "gate": "G3", "status": "Not started", "owner": "", "moduleId": "M19"},
    ]
    known = {r["id"] for r in reqs}
    for a in amendments:
        if a["id"] not in known:
            reqs.append(a)

    # Delivery status is the squads' to edit, so it lives in the repository rather than in
    # the Committee's workbook. Unknown ids fail loudly: a status for a requirement that
    # does not exist means one of the two files is stale.
    overrides_path = OUT / "status_overrides.json"
    if overrides_path.exists():
        overrides = json.loads(overrides_path.read_text(encoding="utf-8"))
        by_id = {r["id"]: r for r in reqs}
        for field in ("status", "owner"):
            for rid, value in overrides.get(field, {}).items():
                if rid not in by_id:
                    raise SystemExit(f"status_overrides.json names unknown requirement {rid}")
                by_id[rid][field] = value

    by_concept = {}
    for c in cons:
        by_concept.setdefault(c["id"], c)
    for c in cons:
        for p in c["prerequisites"]:
            if p not in by_concept:
                raise SystemExit(f"concept {c['id']} declares unknown prerequisite {p}")

    committed = sum(c["itemsMin"] for c in cons)

    write(OUT / "requirements.json", {
        "source": "02_KODO_Curriculum_Benchmark_Backlog.xlsx :: Exigences, plus PO amendments",
        "generatedBy": "tools/gen_spec.py",
        "count": len(reqs),
        "requirements": reqs,
    })
    write(OUT / "concepts.json", {
        "source": "02_KODO_Curriculum_Benchmark_Backlog.xlsx :: Curriculum",
        "generatedBy": "tools/gen_spec.py",
        "conceptCount": len(cons),
        "itemsCommitted": committed,
        "concepts": cons,
    })
    print(f"requirements: {len(reqs)} ({len(amendments)} PO amendments)")
    print(f"concepts:     {len(cons)}  items committed: {committed}")


def write(path, obj):
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
