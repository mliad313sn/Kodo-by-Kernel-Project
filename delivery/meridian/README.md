# Driving KODO through Meridian

[Meridian IT-PMO](https://github.com/mliad313sn/Meridian) is the delivery system of record
for this programme. This directory holds the KODO portfolio in Meridian's book format,
generated from the artefacts that are already true here rather than re-typed into a tool.

```bash
python3 tools/meridian_book.py     # regenerates both files below
```

| File | What it is |
| --- | --- |
| `kodo_book.json` | The portfolio in the shape `importBook()` reads |
| `kodo_import_payload.json` | The same book wrapped as `{"db": …}`, which is what the endpoint expects |

## Loading it

```bash
# in a Meridian checkout
npm install && npm run seed && npm run dev

# then, as an administrator
curl -X POST http://localhost:4173/api/v1/admin/import \
     -H 'Content-Type: application/json' \
     --data @delivery/meridian/kodo_import_payload.json
```

**The import is destructive.** `server/src/import.js` deletes every portfolio table before
it writes. Load it into a fresh instance or `npm run training`, never over a book you want
to keep. (That this has no dry-run is finding `MER-09` of the product report.)

## What maps to what

| KODO | Meridian | Notes |
| --- | --- | --- |
| The 18 modules | `project` × 18 | Each carries the five-stage WBS of the module prompts |
| The four product streams | `programme` × 4 | Runtime & Editors · Pedagogy & Practice · Creation & Community · Platform, School & Trust |
| Dakar · Paris · Remote | `site` × 3 | Governance level per project follows §1.3: architecture-bearing modules are `group` |
| The 14 Committee seats | `person` × 14 | A seat is a competence, not a person (§1.2) |
| Risk register R1–R9 | `raid_item` | Plus three raised during the M1 build (R10, R11, R12). R3 and R9 are closed on evidence |
| PO amendments and descopes | `change_request` × 4 | `FR-M4-09`, `FR-M3-09`, the public-gallery descope, and camera removal |
| Improvement backlog IMP-001…010 | `work_item` on a board | RICE scores do not survive the mapping; see `MER-05` |
| Module interface contracts | `cross_dep` × 7 | "M4 implements the Surface contract frozen by M1", and so on |
| Gates G1, G2, G3 | `milestone` `kind: gate` | **G0 and G5 have nowhere to go.** See `MER-01` |
| Gates G4 and G5, loops 1–3 | `milestone` `kind: milestone` | The improvement loop is not expressible as gates; see `MER-01` |

## What does not map, and what we did instead

Four things in this programme have no home in Meridian today. They are recorded here so
that nobody reads the portfolio and believes it is the whole truth.

1. **Six gates, and they loop.** Meridian has exactly four gates, fixed in
   `shared/engine.js` and constrained in the database (`024_lessons.sql:40` —
   `gate_n BETWEEN 1 AND 4`). KODO has G0–G5, and G4 → G5 → G1 runs at least three times
   before launch (§16). G1/G2/G3 are mapped onto gates 1/2/3; everything else is a plain
   milestone, which means gate locking and gate evidence do not apply to them.

2. **The requirement register.** 130 requirements, each with a verification method and the
   gate that discharges it, live in `spec/requirements.json` and are checked in CI by
   `tools/trace_check.dart`. Meridian has no requirement entity, so none of that is
   visible in the portfolio. This is the largest gap and the largest opportunity.

3. **The budget is genuinely undecided.** `NFR-COST-01` has no agreed figure and PO open
   item O-01 records that. Every project therefore carries a **zero budget on purpose**.
   Be aware that Meridian then reports every one of them as SPI 1.00, CPI 1.00 and 0 %
   complete — including M1, which is finished. That is finding `MER-04`, and it is why no
   earned-value number in this portfolio should be believed.

4. **Domain vetoes.** Seats 3, 5 and 13 can each block a release in their domain, and seat
   13 may never be combined with seats 6, 8 or 9. Meridian's access model has four roles
   and a group/site axis; a per-domain veto is not expressible, so the vetoes live in
   `docs/governance/02_WAYS_OF_WORKING.md` and are enforced by people.

The full analysis is in [`docs/reports/MERIDIAN_PRODUCT_REPORT.md`](../../docs/reports/MERIDIAN_PRODUCT_REPORT.md).
