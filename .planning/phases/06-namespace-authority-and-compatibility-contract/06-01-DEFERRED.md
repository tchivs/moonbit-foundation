---
phase: 06-namespace-authority-and-compatibility-contract
plan: "01"
status: deferred
decision_date: 2026-07-17
decision: mark-and-skip
resume_after: 06-05
requirements_pending: [REG-01, REG-02, REG-03]
---

# 06-01 External Authority Checkpoint Deferred

The sole maintainer chose to skip creating or registering the external GitHub and Mooncakes identity during the current local-development run. This is a scheduling decision, not evidence of registry authority and not a waiver of the fail-closed publication contract.

## Completed work retained

- `e7d8979` — closed registry authority and capability contracts.
- `133370a` — sanitized, read-only registry observation seam.
- `e47f63a` — projected observation validation.
- `47d7593` — rejection of status text and ambiguous identity projections.
- Credential-free contract and negative tests pass.
- Publication readiness correctly rejects the current unknown facts with `REG03-REQUIRED-FACT-UNKNOWN`.

## Work still pending

- Task 3 has not captured an authoritative account identity.
- Authority over `moonbit-foundation` and the exact `mb-core`, `mb-color`, and `mb-image` identities remains unknown.
- REG-01, REG-02, and REG-03 remain pending.
- No `06-01-SUMMARY.md` may be created and no production publication may run until the checkpoint is satisfied.

## Safe continuation

Plans 06-03, 06-04, and 06-05 form an independent credential-free chain rooted in completed plan 06-02 and may execute now. Plan 06-06 keeps its hard dependency on 06-01 and must not execute until this checkpoint resumes and completes.

## Resume condition

Resume 06-01 only after the exact `moonbit-foundation` GitHub/Mooncakes identity exists and an allowlisted, credential-redacted read-only observation can prove the authenticated account, namespace authority, and all three canonical module identities.
