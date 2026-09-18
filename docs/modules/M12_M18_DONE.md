# M12 and M18 — Classroom mode and the authoring CMS · Definition of Done

Package: `packages/kodo_school` — 31 tests, all passing.

Both modules are built for adults, and both are judged the same way: *can somebody who has
never seen KODO do the thing in ten minutes without help.*

## The acceptance tests

### M12 — Classroom mode

| # | Test | Result |
| --- | --- | --- |
| 1 | No-internet drill: 35 devices seeded **and collected** in under 20 minutes | Pass in the model — ~4 min for three worlds at the `FR-M14-02` ceiling (36 MB) over a contended hotspot. **Device drill owed at G3** |
| 2 | A teacher who has never seen KODO creates a class, assigns World 2 and reads the grid in under 10 minutes, unassisted | **Owed — pass-3 evidence.** Automated: the path is three actions and requires no email, password, payment or network call |
| 3 | Printed sheets legible in monochrome on a low-toner printer | Pass — five distinct single-character glyphs, no filled shapes, legend in FR and EN, every line inside 80 columns |

### M18 — Authoring CMS

| # | Test | Result |
| --- | --- | --- |
| 1 | A partner teacher, two hours of training, no engineering help, authors and publishes five items that pass review | Pass — five World-1 items through author → pedagogy → localisation → publish; the audit trail contains three actor ids and not one engineer |
| 2 | Ten deliberately incomplete items, all rejected with a specific reason | Pass — ten distinct authoring mistakes, ten distinct rule names, asserted both through `checkDraft` and through the CMS, which writes each refusal to the trail |
| 3 | An exported bank reimports with zero differences | Pass — all 100 World-1 items, byte-identical re-encode, equal checksum, and a second CMS on another machine arrives at the same checksum |

---

## Defects found while building

| ID | Severity | What was wrong | Why it mattered | Closed by |
| --- | --- | --- | --- | --- |
| `M12-001` | **S2** | `Pupil.displayNameAmong` disambiguated two children with the same first name using `id.substring(0, 1)`. Every id begins `pupil-`, so both Awas rendered as **`Awa P.`** | The one screen whose job is to tell a teacher which of thirty-five children needs help showed two of them as the same person. The bug also *looked* like a surname initial, which is what the module prompt forbids | Disambiguation is the order they joined — `Awa (1)`, `Awa (2)` — and a child with no clash keeps a bare first name. The test asserts both names and that they differ |
| `M18-001` | **S2** | World 1's 100 items carried **no prompt audio keys at all**, while `FR-M18-02` makes an audio key a condition of publication | A seven-year-old at the start of World 1 reads slowly. A prompt they can only see is a prompt they skip, and the gate that was supposed to catch this had nothing to check against | `ContentPack.itemAudioKeys` (item → locale → key), emitted by `tool/author_world1.dart` and folded into `audioKeys` so the existing coverage and budget checks cover it. World 1 regenerated: 230 recordings, 360 kB of JSON |
| `M18-002` | S3 | A draft in `approved` could only go forward. A reviewer who signed off and *then* spotted a problem had no way to say so | The only remaining action was to publish an item they knew was wrong | `reject` is allowed from `approved` as well as from either review state |

---

## Three things these modules do structurally rather than by policy

**No pupil email address and no child's surname.** The M12 prompt's two `Do not`s are not
rules a screen has to remember: `Pupil` has three fields — id, first name, join time — so
there is no surname to leak and no inbox to wait for. The disambiguator above is the only
place the question even arises, and it answers it with join order.

**No engineer-only path around the publish gate.** `PublishedBank` has a private
constructor and a private map. `ContentCms.publish` is the only function in the programme
that can put an item into one, and it runs the gate first. `bank.items` returns a copy, so
a caller who mutates it changes nothing — a test asserts exactly that. Importing a bank
file is gated identically: an item arriving in a file is the same engineer-only path
wearing a different hat, so each imported item is checked and the refusals are returned
and written to the trail. An engineer who wants to ship an ungated item has to edit
`cms.dart`, which is a diff a reviewer can see.

**A hotspot is modelled as contended.** `IMP-008` records one hotspot for thirty-five
devices measured as too slow. Modelling the rate as a constant is how a drill passes on
paper and fails in a classroom, so the rate is divided by `1 + devices / 8`, and a test
asserts that seeding 35 devices is slower *per device* than seeding 5. Collection is
modelled as serial, because the teacher's device is the single sink — and on the numbers,
the 35 handshakes cost more than the bytes do.

---

## What is owed

| Item | Gate | Note |
| --- | --- | --- |
| The real no-internet drill on 35 devices | G3 | The model says ~4 minutes with three worlds. The drill is the evidence |
| A teacher's unassisted first run, stopwatch | G3 / G4 pass 3 | Ten minutes is a stopwatch reading, not an assertion |
| Printed sheets on an actual low-toner printer | G4 pass 2 | The glyph choice is defensible; the print is the proof |
| A partner teacher's two-hour training session | G4 | The workflow passes; the training material does not exist yet |
| ~9 MB of World-1 prompt recordings | G3 | The keys ship; the audio does not. World 1 is at 78 % of its 12 MB budget once it does, which is the number World 2 onwards must be measured against, not assumed |
