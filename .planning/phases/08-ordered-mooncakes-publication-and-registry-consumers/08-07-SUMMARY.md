---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "07"
subsystem: release-safety
tags: [mooncakes, r2, release-intent, authorization-receipt, handoff, powershell]

requires:
  - phase: 08-06
    provides: Static hosted authority and cold-consumer evidence seams
provides:
  - Sole-current r2 initial retry with immutable attempt-zero and r1 terminal-negative history
  - Closed literal authorize-core receipt and exclusive digest-bound handoff schemas
  - Fresh prepared identity bound to both historical-negative digests
affects: [08-08, 08-09, 08-10, DIST-01]

tech-stack:
  added: []
  patterns: [self-excluding canonical digests, rooted file bindings, exclusive authority union]

key-files:
  created:
    - release/qualification/phase-08-authorization-receipt-schema.json
    - release/qualification/phase-08-handoff-schema.json
  modified:
    - policy/release-control.json
    - scripts/quality/ReleaseQualification.Common.ps1
    - scripts/quality/New-PreparedReleaseBundle.ps1

key-decisions:
  - "Only refs/tags/modules-v0.1.0-r2 can represent the current initial retry; attempt zero and r1 remain terminal-negative history."
  - "Prepared identity binds both historical negatives through the digest-covered request payload without importing prior state roots, locators, indexes, or predecessors."
  - "Mutation handoff requires packet plus literal receipt; exact-existing handoff forbids both and binds one exact-existing authority file."

patterns-established:
  - "Canonical UTC: normalize equivalent instants to second-precision Z form before content hashing."
  - "Handoff paths: require absolute paths rooted under one execution root and verify every referenced file digest."

requirements-completed: []
coverage:
  - id: D1
    description: "Static r2 initial-retry, receipt, prepared-history, and handoff contracts are implemented and adversarially tested."
    requirement: DIST-01
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-ReleaseIntent.ps1; Test-PreparedReleaseBundle.ps1; Test-Phase08Qualification.ps1"
        status: pass
    human_judgment: false

duration: 13min
completed: 2026-07-19
status: complete
---

# Phase 08 Plan 07: r2 Attempt-Family Contracts Summary

**A fresh r2 initial release identity now binds both immutable failed histories and can produce only a literal-authorized mutation handoff or a packet-free exact-existing handoff.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-07-18T21:13:27Z
- **Completed:** 2026-07-18T21:26:32Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments

- Replaced r1 current authority with an explicit r2-only initial attempt family while preserving exact attempt-zero and r1 terminal-negative facts.
- Added closed authorization-receipt and handoff schemas with canonical UTC timestamps, self-excluding digests, rooted paths, and mutually exclusive authority branches.
- Extended prepared generation to reject r1, prior-attempt sources, reused state fields, missing history, and history substitution while binding both negative-history digests into manifest identity.

## Task Commits

Each task used a RED/GREEN TDD boundary and was committed atomically:

1. **Task 1: Define the r2 attempt-family policy and initial intent** — `5d234f6` (RED), `bace9f3` (GREEN)
2. **Task 2: Define closed authority, receipt, and handoff schemas** — `82c9d1e` (RED), `f9e4b65` (GREEN)
3. **Task 3: Generate fresh r2 prepared identity and test contract composition** — `53efea7` (RED), `14830a2` (GREEN)

## Files Created/Modified

- `policy/release-control.json` — r2 current attempt family and exact terminal-negative histories.
- `release/intent/schema.json` — r2-only initial intent ref.
- `release/prepared/schema.json` — r2-only initial prepared ref.
- `release/qualification/phase-08-authority-schema.json` — r2 authority records.
- `release/qualification/phase-08-authorization-receipt-schema.json` — closed literal receipt.
- `release/qualification/phase-08-handoff-schema.json` — exclusive mutation/exact-existing handoff branches.
- `scripts/quality/New-ReleaseIntent.ps1` — initial retry and correction-lane rejection.
- `scripts/quality/New-PreparedReleaseBundle.ps1` — dual-history and fresh-state bindings.
- `scripts/quality/ReleaseQualification.Common.ps1` — canonical receipt/handoff construction and validation.
- `scripts/quality/Invoke-ReleaseQualification.ps1` — r2 initial qualification binding.
- `scripts/quality/Test-ReleaseIntent.ps1` — attempt-family and schema fixtures.
- `scripts/quality/Test-PreparedReleaseBundle.ps1` — prepared r2 positive and adversarial matrix.
- `scripts/quality/Test-Phase08Qualification.ps1` — receipt/handoff composition, reload, UTC, branch, path, and digest matrix.

## Decisions Made

- Retained the legacy attempt-zero projection as a compatibility view while making `initial_attempt_family` the authoritative two-history plus r2 policy contract.
- Bound historical negatives through `request.json`, whose payload digest is part of `prepared-bundle.json`; this preserves the fixed 18-payload inventory and avoids importing historical state containers.
- Kept `DIST-01` pending: this plan proves static eligibility contracts only and performs no publication, registry observation, or cold four-target consumption.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed PowerShell field-pair enumeration in handoff validation**
- **Found during:** Task 3 GREEN verification
- **Issue:** Nested two-item arrays were flattened by PowerShell, causing dynamic property access to read characters rather than field names.
- **Fix:** Replaced nested pairs with a fixed-step flat field inventory.
- **Files modified:** `scripts/quality/ReleaseQualification.Common.ps1`
- **Verification:** `Test-Phase08Qualification.ps1` and the full three-suite plan regression passed.
- **Committed in:** `14830a2`

**Total deviations:** 1 auto-fixed (Rule 1 bug)
**Impact on plan:** The fix is internal to the planned handoff validator and introduces no scope expansion.

## Issues Encountered

- The first schema fixture assumed an inline timestamp pattern where the schema correctly used a `$ref`; the test was corrected within Task 2 before GREEN.

## User Setup Required

None - this plan is credential-free and performs no external operation.

## Known Stubs

None. Empty receipt and handoff digest fields are intentional self-hash seeds and are populated before validation or return.

## Verification

- Release intent contract and focused adversarial suite: PASS.
- Prepared bundle deterministic and adversarial suite: PASS.
- Phase 8 r2 receipt/handoff composition suite: PASS.
- `git diff --check e38a9f7..HEAD`: PASS.
- Schema drift gate: PASS, no drift.
- Codebase drift gate: skipped because no structure map exists.
- UI safety gate: PASS, no UI files changed.

## Next Phase Readiness

- Plan 08-08 can wire the hosted controller, workflow, publisher, and adapter to the r2 contracts.
- No tag, push, dispatch, network request, secret access, registry observation, or publication occurred in this plan.

## Self-Check: PASSED

- All 13 planned files exist.
- All six RED/GREEN task commits exist.
- All plan tests and capability gates completed without a blocker.

---
*Phase: 08-ordered-mooncakes-publication-and-registry-consumers*
*Completed: 2026-07-19*
