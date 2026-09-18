# M15 and M16 — Localisation and accessibility · Definition of Done

Package: `packages/kodo_access` — 27 tests, plus the coverage already carried by M1
(keyword tables, the 22-code error catalogue in both languages), M2 (colour, icon and
silhouette per family; the contrast audit at both themes), M4 (colour-blind-safe palette,
canvas descriptions) and M3 (the keyword-language switch).

## The acceptance tests

### M15 — Localisation

| # | Test | Result |
| --- | --- | --- |
| 1 | String coverage is 100 % in FR and EN, enforced in CI | Pass — 39 interface strings, both locales, plus a lint that refuses a fragment, a missing context note, an undeclared placeholder and a declared-but-unused one. The lint is itself tested against one example of each |
| 2 | A pseudo-locale run reveals zero hard-coded strings and zero truncation at 140 % | Pass — every string has a declared slot (an unchecked string is not a passing string), and the UI source scan is clean. Both halves are tested against a deliberate failure so neither can pass vacuously |
| 3 | Switching keyword language mid-program preserves the program byte-for-byte | Pass — 500 random programs, and one half-written program with a parse error, because a child switches language mid-type |

### M16 — Accessibility

| # | Test | Result |
| --- | --- | --- |
| 1 | An external accessibility audit before public launch, with findings closed, not merely logged | **Owed — G4.** It is an external audit; nothing in this repository can stand in for it. What is ready for it: the contrast audit, the keyboard map, the scaling budget and the screen-reader labels |
| 2 | A blind reviewer completes World 0 with a screen reader | **Owed — G3/G4.** Blocked on World 0 existing. The canvas and every block already announce themselves, and an empty canvas says so rather than saying nothing |
| 3 | Every screen passes an automated contrast check at both themes, in CI | Pass — M2 audits 13 syntax categories × 2 themes at ≥ 4.5:1; this package audits the pen palette against both canvas backgrounds at the non-text floor |

---

## Defects found while building

| ID | Severity | What was wrong | Why it mattered | Closed by |
| --- | --- | --- | --- | --- |
| `M15-001` | S2 | `block_editor.dart` built a screen-reader label as `'Famille ${_familyName(family)}'`. The family *name* was localised; the word around it was hard-coded French | A blind English-speaking child would hear `Famille Move`. It is also exactly the class of string a translator can never reach, which is what the pseudo-locale acceptance test exists to surface — and it surfaced it | `a11y.family_tab` in the catalogue, with the placeholder declared; `kodo_app` now depends on `kodo_access` and renders it. The scan runs over the whole UI package in CI |
| `M16-001` | S2 | The editor's status area was budgeted as three lines of 16 dp in 72 dp. That is 67 dp at 100 % and **breaks at 110 %**, long before the 200 % `FR-M16-03` commits to | A child who turns text up to read it at all would have the status text clipped — the line that says *"I stopped your program"* is the one they most need | The status line holds one line; the longer messages move to a message panel with room for three lines at 200 %. The scaling check now walks the whole range in ten steps and reports the first scale at which a box breaks |

Two tool defects were also fixed before they could hide a real one: the hard-coded-string
scanner counted `'#$text'` and `'${line.error.line}'` as prose (a scanner that cries wolf
is a scanner nobody reads), and the field-label slot was modelled as one line when a field
label above its field can wrap — the button slot, which genuinely cannot wrap, was left
alone and the two over-long button strings were shortened instead.

---

## Three things these modules do structurally rather than by policy

**Three layers, three tables.** The interface catalogue here, `KeywordTable` in M1, and the
item and tutorial text in the packs. A test asserts no interface key is a keyword, because
if the layers were one table a child could not read French screens while writing English
keywords — which is the thing §6 asks for and the thing the block↔text bridge is built on.

**A missing string is loud.** `StringCatalogue.render` throws on an unknown key and on a
missing placeholder value. There is no fallback to the key, because
`editor.run_button` on a child's screen has to be impossible to miss, and no silent empty
string, because a sentence with a hole in it reads as a finished sentence.

**Display convention and parser convention are separated on purpose.** `formatNumber`
shows `1,5` to a French child because that is what their maths lesson says; `parse` takes
`1.5` in every language and refuses `1,5`, because a program that parses differently in
French is a different language, not a translation. A test asserts both halves, in both
directions.

---

## What is owed

| Item | Gate | Note |
| --- | --- | --- |
| The external accessibility audit | G4 | The precondition of public launch. Findings closed on re-test evidence, not on a merged fix |
| A blind reviewer through World 0 | G3/G4 | Blocked on World 0 |
| Wolof interface and narration | v1.2 | `FR-M15-02` is marked *In progress* for that reason. The locale, the endonym and the number convention are already recorded, so v1.2 is a translation job. The **keyword** set stays research, per `D-002` — `KeywordTables.of('wo')` throws, and a test asserts it, so the absence is the honest state rather than an oversight |
| Narration recordings | G3 | The keys ship and every compound keyword has a spoken form with a note for the voice actor. The audio does not exist |
| Keyboard operation wired into the Flutter editor | P3 | The map is complete and collision-free — 21 actions, block placement included. Binding it to widgets is M2 work that follows the desktop build |
