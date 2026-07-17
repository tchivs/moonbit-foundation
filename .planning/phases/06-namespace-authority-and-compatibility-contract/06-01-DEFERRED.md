---
phase: 06-namespace-authority-and-compatibility-contract
plan: "01"
status: superseded
decision_date: 2026-07-17
decision: mark-and-skip
resume_after: 06-11
requirements_pending: [REG-01, REG-02, REG-03]
---

# 06-01 External Authority Checkpoint Replanned

The original external-authority attempt was deferred before the personal namespace decision. The retained commits remain historical implementation evidence, but this marker is superseded by the revised 06-01 plan and must not cause that plan to be skipped.

## Completed work retained

- `e7d8979` — closed registry authority and capability contracts.
- `133370a` — sanitized, read-only registry observation seam.
- `e47f63a` — projected observation validation.
- `47d7593` — rejection of status text and ambiguous identity projections.
- Credential-free contract and negative tests pass.
- Publication readiness correctly rejects the current unknown facts with `REG03-REQUIRED-FACT-UNKNOWN`.

## Work still pending

- The credential-free personal-namespace remediation chain 06-07 -> 06-12 -> 06-08 -> 06-09 -> 06-13 -> 06-10 -> 06-14 -> 06-15 -> 06-16 -> 06-17 -> 06-18 -> 06-19 -> 06-20 -> 06-21 -> 06-22 -> 06-23 -> 06-24 -> 06-11 must complete first.
- Task 3 has not captured an authoritative Mooncakes account identity.
- Authority over `tchivs` and the exact `tchivs/mb-core`, `tchivs/mb-color`, and `tchivs/mb-image` identities remains unknown.
- REG-01, REG-02, and REG-03 remain pending.
- No `06-01-SUMMARY.md` may be created and no production publication may run until the checkpoint is satisfied.

## Safe continuation

Plans 06-02 through 06-05 remain completed historical work. Execute the explicit credential-free chain through 06-11 next, then resume the revised 06-01 human OAuth and sanitized observation checkpoint. Plan 06-06 remains blocked until both complete.

## Resume condition

Resume 06-01 after 06-11. The sole maintainer completes `moon register` or `moon login` through GitHub OAuth as `tchivs`; the executor then uses only the allowlisted, credential-redacted read-only collector to prove the exact account, namespace authority, and three canonical module identities. Creation or push of `tchivs/moonbit-foundation` remains a separate explicit authorization boundary.
