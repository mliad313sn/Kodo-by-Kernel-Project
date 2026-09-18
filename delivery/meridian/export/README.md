# The KODO portfolio, exported from a running Meridian

Load this into any Meridian instance to walk every screen and report with the real
programme in it.

| File | What it is |
| --- | --- |
| **`meridian-kodo-database.json`** | **The one to load.** Exactly what `GET /api/admin/export` returned from the running instance at the end of the build — all eighteen modules, three worlds, 130 requirements' worth of status. 98 KB |
| `meridian-kodo-database-import-payload.json` | The same, wrapped as `{"db": …}`, which is the shape `POST /api/admin/import` reads |
| `meridian-kodo-book.json` | The earlier snapshot, taken when six modules were built. Kept so the two can be diffed |
| `meridian-kodo-import-payload.json` | That earlier snapshot, wrapped |

The current pair was produced from a live instance and **round-tripped through it**: exported,
re-imported, exported again, and the two exports compared field by field. **Zero differences.**
It carries 18 projects, 90 activities, 15 milestones, 15 RAID items, 6 change requests,
8 documents and 24 board cards.

Neither file contains a password hash, a session token or an account. Meridian's importer
refuses identity data by design (*"a file should never be able to hand someone an
administrator login"*), and the exporter does not emit it.

---

## Before you load it: apply the patch

> **The import will fail without `../patches/0001-importer-and-earned-value-fixes.patch`.**

Meridian 5.9.0 cannot import any book whose identifiers contain letters — which includes
this one (`M1`, `PE-10`, `CR-001`) **and Meridian's own export** (`PRJ-144`). The importer's
SQL sits in a JavaScript template literal, so `regexp_replace(id, '\D', …)` reaches Postgres
as `'D'`: it strips the letter D instead of every non-digit, and anything else hits a
failing `::int` cast. The failure surfaces as *"One of those values is not in a form the
system can read"* with nothing in the server log.

This is finding `MER-13` and it is a one-character fix. It is not a KODO quirk: no test
anywhere exercises `importBook`, so the round-trip has never been run.

## Loading it

```bash
# in a Meridian checkout
npm ci --ignore-scripts
git apply /path/to/Kodo-by-Kernel-Project/delivery/meridian/patches/0001-*.patch

mkdir -p server/.data/pgdata
export PGLITE_DIR=./server/.data/pgdata     # without this the server runs in memory
                                            # and the seeded accounts vanish — MER-12

npm run seed && npm run dev
```

Then sign in as `admin@meridian.example` / `meridian-admin-2026` and:

```bash
curl -X POST http://localhost:4173/api/admin/import \
     -H 'Content-Type: application/json' \
     --cookie-jar /tmp/c --cookie /tmp/c \
     --data @delivery/meridian/export/meridian-kodo-database-import-payload.json
```

The import **replaces** the whole portfolio. Load it into a fresh instance or
`npm run training`, not over a book you want to keep.

---

## What you will see, and what you should not believe

**Every earned-value figure is zero, on purpose.** `NFR-COST-01` has no agreed budget and
PO open item O-01 records that, so every project carries a zero budget rather than an
invented one. With the patch applied, Meridian says so honestly — *"No cost baseline —
schedule progress only"* — and the roll-up reports `measured 0 of 18`. Without the patch it
would report SPI 1.00, CPI 1.00 and a green light on a portfolio it has not measured.

**Progress is real, and it is computed rather than typed.** Every module's completion is
read off `spec/requirements.json` by `tools/meridian_book.py`: Done counts one, In progress
counts a half, Not started counts nothing. Nobody sets a percentage by hand, so a module
cannot be reported green here while its requirements say otherwise.

**No module reads gate 4, and that is deliberate.** Gate 4 is a *programme* gate and G3 is
not closed — its criterion ends *"running on the reference low-end device"* and nobody has
run it on one. A module bar reading gate 4 above an open G3 is exactly the false green a
portfolio is supposed to prevent, so the generator caps every module at 3. For the same
reason a module shows **Closure** only when its functional requirements are all Done *and*
it owns no open non-functional requirement: M16 has every `FR-M16` closed and still reads
Execution, because the external accessibility audit has not happened.

**The fourteen non-functional requirements are cards on the improvement board**, not hidden
behind eighteen green module bars. Each carries what it is actually waiting for — a phone,
an external reviewer, or a decision. Ten of them are waiting on a phone.

**Read the narrative first.** `narrative.concerns` is eight paragraphs and the first one is
the only one that matters: *G3 is not closed.* Everything else in this portfolio is
downstream of that.

**Gates are flattened, and this is the biggest thing the portfolio cannot tell you.**
KODO has six gates (G0–G5) and they *loop* — G4 → G5 → back to G1, at least three times
before launch. Meridian has exactly four, fixed in `shared/engine.js` and constrained in
the database (`gate_n BETWEEN 1 AND 4`). G1, G2 and G3 are mapped onto gates 1, 2 and 3;
G0, G4 and G5 are plain milestones, which means **gate locking and gate evidence do not
apply to the two gates that actually block a KODO release.** That is finding `MER-01`.

**130 requirements are invisible.** Meridian has no requirement entity, so the register,
its verification methods and the CI traceability behind them do not appear anywhere in the
portfolio. See `MER-03` — it is the largest gap and, in my view, Meridian's largest
opportunity.

**What the portfolio is honest about, and what it cannot be.** Everything above is
generated from artefacts that are already true in the repository — the requirement
register, the concept ledger, the risk register, the PO decision register. What it cannot
tell you is whether the product is *good*: nobody has read the 266 items, nobody has
watched a child use it, and no number here was measured on the reference device. Those are
G3 and G4 findings and they are recorded as such in
[`docs/governance/03_G3_ASSESSMENT.md`](../../../docs/governance/03_G3_ASSESSMENT.md).

The full analysis of Meridian itself is in
[`docs/reports/MERIDIAN_PRODUCT_REPORT.md`](../../../docs/reports/MERIDIAN_PRODUCT_REPORT.md).

---

## If you would rather move the database itself

`server/.data/pgdata` is a 31 MB PGlite directory and can be copied wholesale to another
machine running the same Meridian version. It is not a portability format: it is tied to
the PGlite build and to the migration state. The book export above is the supported path
and the one Meridian's own reversibility commitment
(`docs/25-reversibilite-et-la-porte-manquante.md`) is written about.
