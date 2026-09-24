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
npm ci --ignore-scripts            # nothing here needs a postinstall script

git apply /path/to/Kodo-by-Kernel-Project/delivery/meridian/patches/0001-*.patch
#   ^ REQUIRED. Without it the import fails with 22P02 on any book whose ids
#     contain letters — including Meridian's own export. See MER-13.

git apply /path/to/Kodo-by-Kernel-Project/delivery/meridian/patches/0002-*.patch
#   ^ REQUIRED FOR THIS BOOK. It makes the gate model configuration data and adds
#     the requirement register, so Meridian can hold KODO's six looping gates and
#     its 136 requirements instead of squashing them onto four and dropping them.
#     Also fixes MER-12 (the default store), MER-14 (allocation identity and
#     silently-dropped keys) and MER-15 (a refusal that says what is missing).
#     18 new tests; 467 pass.

# With patch 0002 applied, PGLITE_DIR is no longer needed: the default store is
# ./server/.data/pgdata and the directory is created for you. Set PGLITE_DIR only to
# put the book somewhere else, or PGLITE_DIR=:memory: to ask for memory on purpose.

npm run seed && npm run dev

# then, as an administrator
# (session route, not /api/v1: sign in first and pass the session cookie)
curl -X POST 'http://localhost:4173/api/admin/import?dryRun=1&mode=merge' \
     -b cookies.txt -H 'Content-Type: application/json' \
     --data @delivery/meridian/kodo_import_payload.json
# then the same without dryRun=1 to write it
```

Then sign in as `admin@meridian.example` / `meridian-admin-2026` (the seeded
administrator) before importing.

**Upstream since Meridian 5.17.0** (docs/36 C-03): patches 0001–0003 are merged into
Meridian `main`, the import has a dry run (`?dryRun=1`) and a merge mode (`?mode=merge`),
and a book must carry `"currencyUnit"` (their D-36.04), which the generator now writes.
Verified against Meridian 5.36.1: the regenerated book merges with 0 rejects.

**A replace import is destructive.** `server/src/import.js` deletes every portfolio table before
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

## The patch in `patches/`

Three fixes, two files, nine lines, all 449 of Meridian's own tests still green:

1. **`server/src/import.js`** — the importer's `'\D'` sits in a JavaScript template
   literal, so it reaches Postgres as `'D'`. It strips the letter D instead of every
   non-digit, and any id with another letter in it hits a failing `::int` cast. This is
   why Meridian cannot re-import its own export.
2. **`shared/engine.js`** — the `measurable` guard inverts at a zero budget (`0 >= 0`),
   so a project with no cost baseline reports SPI 1.00 / CPI 1.00 / 0 % complete and a
   Green light. Progress now falls back to `weight × pct`, which needs no money and is
   already in the data.
3. **`shared/engine.js`** — a distinct RAG reason for "no cost baseline", instead of
   borrowing the "too early to measure" sentence.

These are offered to Meridian, not applied to it — this repository has read access only.

The full analysis is in [`docs/reports/MERIDIAN_PRODUCT_REPORT.md`](../../docs/reports/MERIDIAN_PRODUCT_REPORT.md).
