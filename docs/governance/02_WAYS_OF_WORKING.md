# KODO — Ways of Working

## The Committee, and what it is for

Fourteen seats (§1.2). The Committee **does not build** — it specifies, reviews, challenges
and re-specifies. Delivery squads own build quality. The PO owns scope, budget and release.

Seats 3 (Pedagogical Lead), 5 (Child Development Psychologist) and 13 (Child Safety, Privacy
& Compliance) hold **blocking vetoes** in their domains. Seat 13's veto applies at every gate.
Seat 13 may never be combined with seats 6, 8 or 9 — the conflict is that the officer who
must refuse a mechanic cannot also be the person who designed it.

## Standing working groups convened by the PO

The PO's delegation includes convening whatever bodies the work needs. Four are standing;
the rest are called per gate.

| Group | Seats | Cadence | Output |
| --- | --- | --- | --- |
| **Runtime contract group** | 8, 9, 14 | Per module prompt | Interface contracts. An interface change is a specification change and returns to G1 — it is never a pull request |
| **Content authority** | 3, 4, 11 + pilot teacher | Weekly | Item acceptance, misconception coverage, the publish gate of `FR-M18-02` |
| **Child experience panel** | 7, 5 + six children (8–11, rotating, accompanied) | Per world | Pass-3 evidence for G4. Voice, no vote |
| **Safety board** | 13 + external child-safety auditor | Per release | Consent flows, SDK allow-list, moderation queue, the prohibited-mechanics audit of §10 |

## Decision rule

**Consent, not consensus.** A proposal carries unless a seat records a *reasoned,
domain-relevant* objection in the dissent log. "I would have done it differently" is not an
objection. Unresolved objections escalate to the PO within one working week.

Every decision is minuted as: decision, owner, date, rationale, source evidence, reversal
cost. PO-level decisions live in `00_PO_DECISION_REGISTER.md`.

## Severity scale — used identically everywhere

| | Meaning | Consequence |
| --- | --- | --- |
| **S1** | A child can be harmed, lose work, or be blocked from learning | Release blocker |
| **S2** | A concept is taught wrongly, or a core flow fails on the reference device | Fix before gate exit |
| **S3** | Friction, cosmetic, or content polish | Backlog with a date |

## Two rules that are load-bearing

1. **A finding closes on re-test evidence, never on a merged fix** (§16). A pull request is
   not evidence.
2. **Every loop produces a new version of the cahier des charges.** Requirements are never
   changed silently. Both G1 amendments in the gate register exist because of this rule.

## Definition of Done (§14.1) — every deliverable, no exceptions

A deliverable is done when all of these are true, evidenced, and linked in the gate register:

- [ ] Meets its numbered requirements, each verified by a **named** test
- [ ] Works offline on the reference device
- [ ] Works in FR and EN with 100 % string coverage and recorded audio
- [ ] Passes the accessibility checklist — contrast, target size, narration, keyboard, reduced motion
- [ ] Used by at least three children of the 8–11 panel, unassisted, and observed
- [ ] Telemetry events fire correctly and appear in the curriculum health report
- [ ] Failure modes are child-legible; **no technical error string can reach a child's screen**
- [ ] No open S1 or S2 defect, no open safety finding
- [ ] Content reviewed by the pedagogical reviewer *and* the localisation reviewer
- [ ] Rollback path documented

Items that cannot yet be satisfied (a child panel cannot observe a language core) are marked
`n/a — no child-facing surface` in the module's own done checklist, never silently skipped.
