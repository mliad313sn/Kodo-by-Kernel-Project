# The KODO portfolio, exported from a running Meridian

Load this into any Meridian instance to walk every screen and report with the real
programme in it.

| File | What it is |
| --- | --- |
| `meridian-kodo-book.json` | Exactly what `GET /api/admin/export` returned from the running instance, 94 KB |
| `meridian-kodo-import-payload.json` | The same book wrapped as `{"db": …}`, which is the shape `POST /api/admin/import` reads |

Both were produced from a live instance and **re-imported into it to prove they load** —
18 projects, 90 activities, 15 milestones, 15 RAID items, 6 change requests, 8 documents,
10 backlog cards.

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
     --data @delivery/meridian/export/meridian-kodo-import-payload.json
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

**Progress is real.** Activity percentages reflect which stages are actually finished:
M1 at 100 %, M4, M6 and M14 in Execution with their build and test stages closed, M2 and M3
not started.

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

The full analysis is in
[`docs/reports/MERIDIAN_PRODUCT_REPORT.md`](../../../docs/reports/MERIDIAN_PRODUCT_REPORT.md).

---

## If you would rather move the database itself

`server/.data/pgdata` is a 31 MB PGlite directory and can be copied wholesale to another
machine running the same Meridian version. It is not a portability format: it is tied to
the PGlite build and to the migration state. The book export above is the supported path
and the one Meridian's own reversibility commitment
(`docs/25-reversibilite-et-la-porte-manquante.md`) is written about.
