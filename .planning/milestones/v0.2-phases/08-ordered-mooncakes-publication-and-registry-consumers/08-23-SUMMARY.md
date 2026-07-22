---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "23"
subsystem: release-safety
tags: [r9, hosted-preflight, mooncakes, zero-write, canonical-archives]

requires:
  - phase: 08-22
    provides: r9 prepared identity, canonical archive validation, and nine-history authority contracts
provides:
  - r9-only publisher, workflow, and hosted exact14 propagation with nine immutable histories
  - credential-free r9 pre-live selector that rejects r8 evidence drift, remote tag drift, and handoff presence
affects: [08-24, hosted-preflight, release-publisher, mooncakes-publication]

tech-stack:
  added: []
  patterns: [closed nine-history binding, canonical-copy prepared validation, zero-write pre-live selection]

key-files:
  created:
    - scripts/quality/Invoke-Phase08R9PreLive.ps1
    - scripts/quality/Test-Phase08R9PreLive.ps1
  modified:
    - scripts/quality/Invoke-ReleasePublisher.ps1
    - scripts/quality/Invoke-MooncakesLiveMutation.ps1
    - .github/workflows/publish-modules.yml
    - scripts/quality/Invoke-Phase08HostedRun.ps1
    - scripts/quality/Test-ReleasePublisherNegative.ps1
    - scripts/quality/Test-Phase08LiveSeam.ps1
    - scripts/quality/Test-Phase08Qualification.ps1

key-decisions:
  - "r9 is the only accepted hosted and publisher initial binding; r8 remains terminal evidence rather than a runnable current release."
  - "The pre-live gate returns one sanitized result and performs no mutation, handoff write, credential access, tag creation, dispatch, or PublishOne call."

patterns-established:
  - "Thread each individual history digest as well as its LF-ordered aggregate through publisher, workflow, controller, receipt, and handoff seams."
  - "Use injected remote-tag fixtures for pre-live tests; production performs exactly one read-only git ls-remote tag query."

requirements-completed: []

coverage:
  - id: D1
    description: r9 publisher and hosted seam accept only canonical prepared identity and nine ordered terminal histories.
    verification:
      - kind: integration
        ref: scripts/quality/Test-ReleasePublisherNegative.ps1
        status: pass
      - kind: integration
        ref: scripts/quality/Test-Phase08LiveSeam.ps1
        status: pass
    human_judgment: false
  - id: D2
    description: Zero-write r9 pre-live gate verifies r8 terminal facts, remote tag state, and r9 handoff absence.
    verification:
      - kind: integration
        ref: scripts/quality/Test-Phase08R9PreLive.ps1
        status: pass
      - kind: integration
        ref: scripts/quality/Test-Phase08Qualification.ps1
        status: pass
      - kind: integration
        ref: scripts/quality/Test-MooncakesObservation.ps1
        status: pass
    human_judgment: false

duration: 31min
completed: 2026-07-19
status: complete
---

# Phase 8 Plan 23: r9 Hosted and Pre-Live Seam Summary

**r9 now carries canonical prepared-copy identity and nine immutable terminal histories through publisher, workflow, hosted exact14, and a zero-write pre-live gate.**

## Performance

- **Duration:** 31 min
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Advanced publisher, live adapter, workflow, hosted controller, receipts, and fixed handoff contracts from r8/eight histories to r9/nine histories.
- Added adversarial r9 hosted tests for raw/current substitution, history drift, exact-existing safety, fixed handoff rollover, and exact14 dispatch parity.
- Added a read-only pre-live selector that validates r8's canonical-archive terminal record, one remote tag query, r9 tag absence, committed-clean summaries in production mode, and r9 handoff absence.

## Task Commits

1. **Task 1: Enforce r9 canonical prepared-copy identity in publisher and hosted workflow** - `cea3ded` (test), `d5cc14c` (feat)
2. **Task 2: Add zero-write r9 pre-live gate retaining all prior safeguards** - `4c0f7cc` (test), `a3321be` (feat)

## Files Created/Modified

- `scripts/quality/Invoke-ReleasePublisher.ps1` and `Invoke-MooncakesLiveMutation.ps1` - Enforce r9/nine-history request and prepared-manifest binding.
- `.github/workflows/publish-modules.yml` - Carries the ninth history through workflow preparation and publisher validation.
- `scripts/quality/Invoke-Phase08HostedRun.ps1` - Persists r8 historical evidence in r9 active-attempt, receipt, handoff, and exact14 dispatch contracts.
- `scripts/quality/Invoke-Phase08R9PreLive.ps1` - Provides the zero-write selector with closed sanitized output.
- `scripts/quality/Test-*.ps1` - Covers r9 regression, hosted fields, qualification preparation, and pre-live negatives.

## Decisions Made

- Keep r8's raw-archive failure immutable and explicitly zero-effect; it must never be converted into current r9 authority.
- Require r9 pre-live evidence to remain read-only and fail closed before any credential boundary.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None. Fixture data is restricted to LibraryOnly regression paths and is not wired to production release execution.

## Issues Encountered

- Existing r8 fixture objects initially omitted the ninth history field after the planned contract advance; the planned r9 fixture updates corrected the closed-object mismatch before GREEN verification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 08-24 can run its separately authorized clean, non-publishing r9 hosted preflight. DIST-01 remains pending: this plan performed no tag, dispatch, credential access, registry observation, handoff write, or publication.

## Self-Check: PASSED

- Confirmed all ten plan-owned source/test/summary files exist.
- Confirmed `cea3ded`, `d5cc14c`, `4c0f7cc`, and `a3321be` are present in Git history.

---
*Phase: 08-ordered-mooncakes-publication-and-registry-consumers*
*Completed: 2026-07-19*
