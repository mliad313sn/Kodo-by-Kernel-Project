# G5 — the final low-level review

A standing review committee was seated to take the product apart at the lowest level it
has: the arithmetic, the bytes of the content packs, the manifest the operating system
reads, and the 1 240 exercises taken together rather than one at a time. This is what it
found, what was fixed, and what it could not close.

Every finding below was *measured*. Nothing here is an opinion about the code.

## The seats, and what each one actually examined

| Seat | What it did | Evidence |
|---|---|---|
| **Runtime engineer** | Ran the whole product twice — once on the Dart VM, once compiled to JavaScript and run under Node — and diffed 68 measurements: every pack hash, all 1 171 verdicts, path signatures, raster fingerprints, the PNG and SVG exports, and the seeded RNG at six seeds. | `packages/kodo_lang/test/fnv_test.dart`, CI gate 4a |
| **Assessment lead** | Measured where the right answer sits in all 436 multiple-choice items, and whether a child could reach *maîtrisé* without it. | `packages/kodo_grader/test/choice_order_test.dart` |
| **Content editor** | Re-graded every item against its own reference solution, ran all 2 324 authored wrong answers and all 1 470 alternatives through the grader, and fingerprinted the bank for repeats. | `worlds_acceptance_test.dart`, “the curriculum as a whole” |
| **Release engineer** | Built the web release, read the Android manifest, the web manifest, the launcher icons and the asset list, and compared them with what the app actually loads. | `app/test/m19_acceptance_test.dart` |
| **Beta tester** | Opened the built application in a browser, cut the network, and walked a child's path: profile, map, world, concept, tutorial, first step — driving it through the semantics tree, which is how a screen reader would. | `app/tool/web_offline_check.js` |
| **Privacy officer** | Read the telemetry schema, the pseudonym derivation, the session file and the platform backup policy. | `packages/kodo_insight/lib/src/events.dart`, `AndroidManifest.xml` |
| **Performance engineer** | Timed a cold start: JSON decode, pack construction, verification, one graded item, one dense rasterise, one PNG. | measured, AOT, §Performance below |
| **Commercial reviewer** | Walked the dependency tree and its licences, the bundle sizes, and what a parent or teacher sees when they install. | §Commercial below |

## Release blockers found

### 1. The first answer was always the right one

All **436** multiple-choice items in the curriculum — 35 % of the bank — were authored with
the correct choice written first, and the application rendered `item.choices` in that
order. A child who always taps the top answer passes every one of them. An eight-year-old
finds that out faster than any adult expects.

*Damage limit:* mastery needs four distinct item types and choice items span at most three
per concept, so no concept could be *completed* this way. Everything short of that — volume,
first-attempt accuracy, the “not similar to the example” criterion — was free.

**Fixed.** The authored order is kept, because an author reading the JSON should see the
answer at the top; the presented order is a deterministic permutation of the item's own
identity (`choiceOrder`). Same item, same order, on a phone, on a desktop, in a browser,
this year and next — so a verdict stays reproducible and a teacher sees the child's screen.
Grading still takes the authored index and knows nothing about presentation.

Two gates now stand behind it: a per-concept rule in the publish gate, and a bank-wide test
that no slot may hold more than 40 % of the right answers. The distribution is now
107 / 121 / 114 / 94.

### 2. The application shipped three worlds out of thirteen

`pack_loader.dart` read `const bundledWorlds = [0, 1, 2]`. It was written when there were
three worlds and never revisited. The other ten were authored, gated, listed in the
pubspec, and present in the asset bundle — and **974 of the 1 240 exercises were
unreachable from a built app**. Every content test passed, because they all read the JSON
off disk rather than through the loader.

**Fixed**, and a test now compares the list against the assets actually present, plus a
second that requires the loader to reach at least 1 200 exercises.

## High findings

### 3. Cold start hashed 4.7 MB before the first screen

`loadInstalledContent` ran SHA-256 over every installed pack on every launch: **505 ms
measured AOT on x86**, which on the 2 GB reference device is two to three seconds spent in
front of a child to answer a question that cannot come out wrong — an asset inside a signed
APK cannot be modified without breaking the signature Android already checked.

**Fixed.** `ContentLibrary.install` takes a `verify` flag that defaults to *on*. The shell
passes `false` for its own bundle and `true` for anything sideloaded, which is the case
`FR-M14-02` is actually about.

### 4. The web build has no offline story

`flutter_service_worker.js` is 784 bytes and **unregisters itself** — Flutter no longer
ships caching. NFR-OFF-01 is enforced in Dart and, on Android, by the operating system; on
the web target it was not enforced at all.

**Fixed.** `app/tool/make_service_worker.dart` generates a real worker from the build. The
application and **all thirteen worlds** are precached — 10.4 MB, fetched once — and the
graphics engine is kept the first time the browser asks for the variant it wants, so no
visitor is sent seven megabytes of a CanvasKit build their browser will never load. Its
cache name is a digest of its own contents, so a build that changes one exercise sweeps
the old cache. Registered from `index.html`, because newer Flutter registers nothing.

**Proved by running it, not by reading it.** `app/tool/web_offline_check.js` serves the
build, opens it in Chromium, waits for the worker, then puts the browser *genuinely*
offline and: reloads, reads World 5's 90 exercises, and opens the app again in a fresh tab
as if it were the next morning — which renders, and reads World 12's 86. Zero failed
requests, zero console errors. In CI, and in the verification loop as `G5-04`.

### 4b. The web build could not start without Google

Found the same way — by running it. The default Flutter web build fetches CanvasKit from
**`https://www.gstatic.com`** at run time. So KODO on the web could not start without a
Google CDN reachable, the 37 MB of CanvasKit it shipped was dead weight, and **every child
opening KODO sent their IP address to a third party before the first frame** — in a
product whose privacy note says a child's work goes nowhere.

**Fixed** with `--no-web-resources-cdn`, in CI as well as by hand. The browser run records
every origin the page asks for; the number is zero, and `G5-05` fails the build if it
ever is not.

### 5. Everything a person sees was Flutter's template

`android:label="kodo"`. A web manifest reading *“A new Flutter project.”* in Flutter's
default blue. And the launcher icon was **byte-identical** to the Flutter template logo in
all five mipmap buckets, plus the web icons and the favicon. The art committee drew a
character and nobody installing the app ever saw her.

**Fixed.** `app/tool/make_icons.dart` renders the icons from `kodo_art` — generated, not
exported, so they follow the art rather than drifting from it. A new rasteriser
(`raster_out.dart`, supersampled 4×) turns a `Drawing` into pixels. Names, descriptions and
theme colours are KODO's. A test checks all of it, including that the icons are no longer
the 544-byte template file.

## Medium findings

### 6. A hash that promised to be platform-independent, and was not

`Bitmap.hash` carried textbook FNV-1a under the comment *“identical on every platform”*.
`0xFFFFFFFF * 16777619` is about 2⁵⁶; a JavaScript number is exact below 2⁵³. Every drawing
in the curriculum hashed differently in a browser. Caught by running the same code both
ways.

**Fixed:** `fnv1a32` in `kodo_lang`, multiplying in 16-bit halves so no intermediate passes
2³⁷, with pinned vectors that run on the VM *and* in Chrome. After the fix the differential
is **0 differences across 68 measurements**.

**And gated:** `kodo_lang`, `kodo_stage` and `kodo_grader` — the three packages that decide
anything — now run their whole suites under headless Chrome in CI. 234 assertions, both
runtimes.

### 7. A child's work was being backed up to a stranger's Google account

The Android manifest set no backup policy, so Android's default applied: the app's private
directory, holding a child's progress and projects, copied into whichever Google account
owns the phone. NFR-PRIV-01 says that does not happen.

**Fixed:** `allowBackup="false"`, `fullBackupContent="false"`, and explicit Android 12+
extraction rules that also refuse device-to-device transfer.

### 8. Eight items in World 0 were the same question twice or three times

An authoring loop varied its numbers and handed them to a sentence that never mentioned
them, so `fill` was a silent no-op and the loop wrote one item repeatedly. Different ids,
so the scheduler's anti-repeat rule could not see it. **World 0 is the first world an
eight-year-old ever opens.**

**Fixed at the root:** `fillBoth` now *throws* when a value has no hole in any locale — the
check is across the locales together, because a hole per language (`{cfr}` in the French,
`{cen}` in the English) is a real and deliberate shape. That found eleven more dead
substitutions across eight worlds. The four prompts that had made items identical now carry
their parameters; the rest simply stopped passing values nobody used. A `duplicate-item`
rule in the publish gate fingerprints prompt, target, reference, choices and rubric, so a
copied item with a new id is refused.

### 9. One prompt asked for one block and was marked against two

Four C9.4 open builds said *“Fais une fleur avec un bloc pétale”* while their rubric
required two named blocks — and one of them repeated a C9.1 prompt word for word against a
different bar. A child experiences that as the app changing its mind.

**Fixed:** the prompts now say what is wanted. New gate rule `prompt-crosses-concepts`
refuses one instruction serving two rubrics.

### 10. Every exported drawing weighed 480 KB

`toPng` wrote truecolour over stored (undeflated) zlib blocks, so a child's line drawing
cost 480 000 bytes whatever was in it.

**Fixed, fully.** A two-entry palette took it to 160 KB; then the stored blocks were
replaced with a real compressor — LZ77 over a hash chain, then RFC 1951's *fixed* Huffman
tables, written out because a pure-Dart package with no dependencies has none to call.

| | was | now |
|---|---|---|
| blank page | 480 503 | **1 095** |
| a square | 480 503 | **1 287** |
| a 180-segment figure | 480 503 | **2 045** |
| a 36-fold rosette | 480 503 | **4 837** |

A compressor believed only by its own decoder is not believed, so the output is handed to
somebody else's: `tools/png_check.py` inflates every file with Python's zlib, checks each
chunk CRC and each scanline length, and runs in CI.

### 12. A child was asked to choose between `C0.1` and `C0.2`

Found by opening the application and walking it with the network off. The screen where a
child picks what to learn next listed the curriculum's internal ids. The pack has carried
the child-facing name all along — it is the sentence the tutorial closes with (`FR-M5-06`),
written for exactly this and then shown only at the end.

**Fixed.** The list now reads *Faire partir un programme · Les blocs ont un ordre · Un bloc
après l'autre · On peut toujours annuler*. The words are the pack's; the shell does not
name a concept, because it has no business inventing one.

### 11. CI was pinned to a moving target

`sdk: stable`. Two things in this repository are generated by the toolchain and compared
byte for byte — `dart format`'s output and the content pack hashes — so a Dart release
breaks the build on a morning when nobody changed a line, and it looks like a content
defect. The runner had already drifted: 61 files were unformatted against the current
formatter before this review touched anything.

**Fixed:** Dart pinned to 3.13.4, Flutter to 3.47.4, and the repository reformatted so the
two agree.

## What the review confirmed was sound

These were tested adversarially and held.

- **The content is correct.** All **1 171** items with a reference solution or choices pass
  their own grader. All **2 324** authored wrong answers fail. All **1 470** alternatives
  pass. Every non-open-build item has hints. No item has two choices reading the same.
- **The offline promise is enforced by the operating system.** The release Android manifest
  declares **zero permissions** — no INTERNET. The process cannot open a socket. INTERNET
  appears only in the debug and profile manifests, where Flutter's tooling needs it. A test
  now reads the manifest so a plugin cannot add one quietly.
- **Telemetry cannot carry a person.** `EventField` is a closed enum of fourteen values and
  `LearningEvent` refuses any field the schema does not declare, at the boundary as well as
  in CI. There is no name, no email, no device id, no advertising id — because there is
  nowhere to put one. The pseudonym is a salted hash whose salt never leaves the device, so
  the same child on two devices is two pseudonyms.
- **The supply chain is one package.** `crypto`, BSD-3, from the Dart team. Everything else
  is dev-only. No GPL, no vendor SDK, no analytics library, nothing that can start phoning
  home in a minor version.
- **Grading is inside budget.** One item, parsed, run and graded: **910 µs**.
- **The web build compiles**, and the language core, the surfaces and the grader all give
  identical answers there.

## Performance, measured

AOT on x86 — the reference device is slower, and the multiplier is the point.

| | |
|---|---|
| JSON decode, 13 worlds | 58 ms |
| Build 13 `ContentPack`s | 7 ms |
| Verify 13 packs (SHA-256, 4.7 MB) | 505 ms — **removed from the cold-start path** |
| Grade one item end to end | 910 µs |
| Rasterise a 180-segment drawing | < 1 ms |
| PNG of that drawing | 40 ms, 160 KB (was 480 KB) |

## Commercial

- **Bundle.** Web: 2.4 MB JS + 37 MB CanvasKit + 7.8 MB assets. Android: unmeasured
  against the 25 MB budget — no Android SDK in this environment, and it stays open.
- **Targets.** Android, Linux and Web are configured. **iOS, macOS and Windows are not.**
  That is a market decision nobody has recorded; it should be recorded.
- **Licensing.** One BSD-3 runtime dependency. Nothing to clear, nothing to disclose beyond
  a standard attribution file.
- **Content asset.** 1 240 exercises and 58 tutorials in two languages, each one gated, and
  every reference solution verified against its own grader. That is the defensible part of
  the product and it is in good order.

## The verification loop

A review is worth what its fixes are worth, and a fix is worth what proves it is still
there next month. `tools/verify_findings.dart` carries **one check per finding**, named by
its id. Some read the repository; the web ones read what a real browser did. It runs in CI
and fails the build on any finding that has come back.

```
$ dart run tools/verify_findings.dart --web
12 fixed · 0 open · 0 skipped · 5 cannot be decided here
```

The five are not passes. A check that cannot be decided says so — because a green tick that
covers a question nobody asked is how a review comes to mean nothing.

## Still open, and why no repository closes it

| | Why |
|---|---|
| Android base-app size vs 25 MB | The Android SDK cannot be installed here: the egress policy denies `dl.google.com`. No APK has been produced. |
| Cold start, item in 1.2 s, 50 force-kills | The reference device: Android 11, 2 GB. |
| Backdrop import, microphone, screen capture | Platform APIs — and **closed out for v1 by D-016**, because each costs the zero-permission property that makes the offline promise true. |
| Ghost-path value, phone layout, field test | A child panel and a classroom. |
| Wolof | v1.2 by the specification itself. |
| iOS, macOS, Windows | Not configured, and nobody has decided they should be. Recorded as open item **O-04**, so the absence stops looking like an oversight. |
