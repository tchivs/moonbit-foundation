---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "25"
subsystem: release-safety
tags: [r10, hosted-seam, prelive, zero-write, publisher]
requires:
  - phase: 08-24
    provides: r10 static ten-history contracts and immutable r9 terminal evidence
provides:
  - r10-only hosted, publisher, adapter, and workflow history binding
  - credential-free r10 pre-live selection and zero-mutation pre-authorization validation
affects: [08-26, hosted-preflight, release-publisher]
tech-stack:
  added: []
  patterns: [closed ten-history binding, terminal-evidence-only retry selection, zero-write authority projection]
key-files:
  created: [scripts/quality/Invoke-Phase08R10PreLive.ps1, scripts/quality/Test-Phase08R10PreLive.ps1]
  modified: [scripts/quality/Invoke-Phase08HostedRun.ps1, scripts/quality/Invoke-ReleasePublisher.ps1, scripts/quality/Invoke-MooncakesLiveMutation.ps1, .github/workflows/publish-modules.yml]
key-decisions:
  - "r9 is immutable terminal evidence, never an active attempt, locator, handoff, or publisher input."
  - "Pre-authorization accepts only exact-existing or confirmed-absent zero-mutation states and never persists a receipt or handoff."
requirements-completed: []
coverage:
  - id: D1
    description: r10 hosted preparation and pre-live selection require ten exact immutable histories and reject r9 reuse.
    verification:
      - kind: integration
        ref: pwsh -NoProfile -File scripts/quality/Test-Phase08PrepareHistorySchema.ps1
        status: pass
      - kind: integration
        ref: pwsh -NoProfile -File scripts/quality/Test-Phase08R10PreLive.ps1
        status: pass
    human_judgment: false
  - id: D2
    description: Publisher, live adapter, and workflow accept only r10 with ten-history binding and preserve the isolated single-module boundary.
    verification:
      - kind: integration
        ref: pwsh -NoProfile -File scripts/quality/Test-ReleasePublisherNegative.ps1
        status: pass
      - kind: integration
        ref: pwsh -NoProfile -File scripts/quality/Test-Phase08LiveSeam.ps1
        status: pass
    human_judgment: false
duration: 45min
completed: 2026-07-19
status: complete
---

# Phase 8 Plan 25: r10 Hosted and Pre-Live Seam Summary

**r10 now has a ten-history hosted and publisher seam with r9 locked as terminal-only evidence and a credential-free zero-write pre-live gate.**

## Accomplishments

- Added the r10 pre-live selector, which requires immutable r8/r9 remote tag evidence, r10 absence, clean prerequisite summaries, and an absent fixed handoff.
- Advanced active-attempt, packet, receipt, handoff, publisher, live-adapter, and workflow validation from nine histories/r9 to ten histories/r10.
- Added closed pre-authorization validation for mutually exclusive exact-existing and confirmed-absent authority projections, both with zero mutation, receipt, and handoff evidence.

## Task Commits

1. **Task 1: Make r10 hosted preparation and pre-live selection history-complete** — `d9e59b8` (RED) and `50e6643` (GREEN)
2. **Task 2: Carry r10 authority through the isolated publisher workflow** — `02a1ca5`

## Files Created/Modified

- `scripts/quality/Invoke-Phase08HostedRun.ps1` — validates r10 active, dispatch, and pre-authorization contracts.
- `scripts/quality/Invoke-Phase08R10PreLive.ps1` — implements the credential-free selector.
- `scripts/quality/Invoke-ReleasePublisher.ps1` and `Invoke-MooncakesLiveMutation.ps1` — require r10 and all ten immutable digests.
- `.github/workflows/publish-modules.yml` — propagates the tenth digest without widening secret scope.
- Focused test scripts — cover selector, history schema, publisher negatives, dispatch fields, workflow, and adapter seams.

## Decisions Made

- Keep r9 as an exact tag/peel-bound pre-locator StrictMode terminal record; it cannot supply a current locator, handoff, receipt, packet, or active root.
- Keep pre-live and pre-authorization credential-free and zero-write; the existing publisher-only temporary `MOON_HOME` remains the sole credential-materialization boundary.

## Deviations from Plan

None - plan executed within its declared file boundary.

## Known Stubs

None.

## Threat Flags

None - no new network endpoint, credential route, file trust boundary, or schema trust boundary was introduced beyond the plan's reviewed hosted/publisher seam.

## Verification

- `Test-Phase08PrepareHistorySchema.ps1` — PASS
- `Test-Phase08R10PreLive.ps1` — PASS
- `Test-ReleasePublisherNegative.ps1` — PASS
- `Test-Phase08LiveSeam.ps1` — PASS
- PowerShell parse checks and `git diff --check` — PASS

## Next Phase Readiness

Plan 08-26 may consume r10's non-publishing eligibility seam. No tag, push, dispatch, credential read, `PublishOne`, registry call, handoff write, or Mooncakes mutation was performed.

## Self-Check: PASSED

- Verified task commits `d9e59b8`, `50e6643`, and `02a1ca5` exist.
- Verified all r10 seam scripts and tests listed above exist.
