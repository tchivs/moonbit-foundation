---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "22"
subsystem: release-safety
tags: [r9, prepared-bundle, canonical-archives, authority, handoff]

requires:
  - phase: 08-21
    provides: r8 canonical prepared evidence and the terminal retry boundary
provides:
  - r9-only initial intent, prepared-bundle, authority, receipt, and handoff contracts
  - nine immutable terminal-negative history bindings including the r8 pre-locator failure
  - fresh r9 prepared validation and credential-free qualification identity
affects: [08-23, hosted-preflight, release-publisher, mooncakes-publication]

tech-stack:
  added: []
  patterns: [ordered history-set binding, closed authority unions, canonical archive validation]

key-files:
  created: []
  modified:
    - policy/release-control.json
    - release/qualification/phase-08-handoff-schema.json
    - scripts/quality/New-PreparedReleaseBundle.ps1
    - scripts/quality/ReleaseQualification.Common.ps1
    - scripts/quality/Test-Phase08Qualification.ps1

key-decisions:
  - "r9 is the sole current initial retry; r8 is immutable pre-locator canonical-archive failure evidence."
  - "Every authority, receipt, handoff, and prepared request carries nine individual history digests plus their ordered set digest."
  - "Prepared validation accepts only fresh r9 genesis state and canonical archive bytes bound to intent digests."

patterns-established:
  - "Forward retry contracts retain prior attempts as distinct immutable evidence rather than reusing state or paths."
  - "Receipt and handoff serialization must include each ordered history field before computing aggregate hashes."

requirements-completed: []

coverage:
  - id: D1
    description: r9 contracts bind r8 terminal evidence and nine ordered history digests.
    verification:
      - kind: integration
        ref: scripts/quality/Test-ReleaseIntent.ps1
        status: pass
    human_judgment: false
  - id: D2
    description: Fresh r9 prepared bundles reject prior-state reuse and bind canonical archive bytes to the intent.
    verification:
      - kind: integration
        ref: scripts/quality/Test-PreparedReleaseBundle.ps1
        status: pass
      - kind: integration
        ref: scripts/quality/Test-Phase08Qualification.ps1
        status: pass
    human_judgment: false
  - id: D3
    description: Credential-free qualification emits a r9 initial intent binding.
    verification:
      - kind: integration
        ref: scripts/quality/Invoke-ReleaseQualification.ps1 -Check
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-07-19
status: complete
---

# Phase 8 Plan 22: r9 Static Contracts and Prepared Identity Summary

**r9 is the sole fresh initial retry, with r8 preserved as a zero-effect canonical-archive failure and every prepared authority contract bound to nine immutable histories.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-07-19T07:20:50Z
- **Completed:** 2026-07-19T07:34:26Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Added the exact r8 source/tag, `PREP15-CANONICAL-ARCHIVE` / `REL-XPLAT-NONCANONICAL` failure, and zero locator/run/downstream effects as immutable terminal evidence.
- Advanced initial intent, prepared bundle, authority union, literal receipt, and deterministic handoff contracts to r9 with all nine individual digests and their LF-ordered aggregate.
- Required a fresh r9 genesis and canonical archive bytes matching the qualified intent; the credential-free qualification path now emits an r9 binding.

## Task Commits

1. **Task 1: Advance policy, intent, prepared, authority, receipt, and handoff to r9** - `fff8c0e` (test), `7143c50` (feat)
2. **Task 2: Bind canonical-copy seam and fresh r9 preparation** - `0a6b852` (test), `f4f525f` (feat)

## Files Created/Modified

- `policy/release-control.json` - Adds immutable r8 terminal evidence and designates r9 as current.
- `release/intent/schema.json` and `release/prepared/schema.json` - Restrict initial artifacts to r9.
- `release/qualification/phase-08-*-schema.json` - Bind authority, receipts, and handoffs to r9/nine histories.
- `scripts/quality/New-ReleaseIntent.ps1` and `scripts/quality/New-PreparedReleaseBundle.ps1` - Enforce fresh r9 construction and exact history sets.
- `scripts/quality/ReleaseQualification.Common.ps1` and `scripts/quality/Invoke-ReleaseQualification.ps1` - Carry r9 history fields through receipt, handoff, and qualification binding.
- `scripts/quality/Test-ReleaseIntent.ps1`, `scripts/quality/Test-PreparedReleaseBundle.ps1`, and `scripts/quality/Test-Phase08Qualification.ps1` - Cover r9 contracts, r8 zero-effect evidence, and fail-closed history drift.

## Decisions Made

- Preserve r8 as terminal local evidence: no locator, active attempt, hosted run, credential access, authority, handoff, publication, or successor is permitted.
- Require individual history fields in addition to the aggregate set digest so reordering or substitution has localized failure ownership.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated the qualification integration expectation from r1 to r9**
- **Found during:** Task 2
- **Issue:** `Test-ReleaseIntent.ps1 -QualificationIntegration` still expected the prior r1 initial binding after the planned r9 qualification change.
- **Fix:** Required `refs/tags/modules-v0.1.0-r9` in the integration binding assertion.
- **Files modified:** `scripts/quality/Test-ReleaseIntent.ps1`
- **Verification:** `pwsh -NoProfile -File ./scripts/quality/Test-ReleaseIntent.ps1 -QualificationIntegration`
- **Committed in:** `f4f525f`

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)

## Known Stubs

None. The sole placeholder match is a negative-test assertion, not runtime data.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 08-23 can now propagate the closed r9 prepared identity through the hosted and publisher seams. DIST-01 remains pending; this plan performed no tag, dispatch, credential access, registry observation, or publication.

## Self-Check: PASSED

- Confirmed key r9 policy, handoff schema, prepared validator, and this summary exist.
- Confirmed all four TDD commits exist in Git history.

---
*Phase: 08-ordered-mooncakes-publication-and-registry-consumers*
*Completed: 2026-07-19*
