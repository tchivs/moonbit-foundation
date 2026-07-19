---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "27"
subsystem: release-safety
tags: [r11, immutable-history, prepared-qualification, clean-clone]
requires:
  - phase: 08-26
    provides: clone-local immutable-tag qualification gate
provides:
  - r11-only initial contracts with eleven immutable terminal histories
  - r10 clean-clone REL01-REF terminal evidence bound into authority and prepared artifacts
affects: [08-28, release-qualification, publisher-boundary]
tech-stack:
  added: []
  patterns: [closed history family, LF-ordered aggregate, clone-local tag gate]
key-files:
  modified: [policy/release-control.json, release/intent/schema.json, release/prepared/schema.json, release/qualification/phase-08-authority-schema.json, release/qualification/phase-08-authorization-receipt-schema.json, release/qualification/phase-08-handoff-schema.json, scripts/quality/New-PreparedReleaseBundle.ps1, scripts/quality/ReleaseQualification.Common.ps1, scripts/quality/Invoke-Phase08HostedRun.ps1]
key-decisions:
  - "r11 is the sole current initial retry; attempt-zero through r10 form its exact immutable history family."
  - "r10 records only attested clean-clone REL01-REF facts and is never reused as current state."
  - "The uncreated r11 tag does not weaken the real clone-local tag gate; static tests defer focused construction until separately authorized tag creation."
metrics:
  tasks: 2
  files: 12
status: complete
---

# Phase 8 Plan 27: r11 History Contracts Summary

**r11 now binds eleven exact terminal-history digests, including r10's attested clean-clone REL01-REF terminal record, before the publisher boundary.**

## Accomplishments

- Recorded immutable r10 tag object `0546025` and peel `d49edc5` with only the verified zero-downstream facts.
- Advanced initial intent, prepared, authority, receipt, handoff, and shared prepared serialization to r11 plus the LF-ordered eleven-digest aggregate.
- Kept the real clean-clone fixture local and fail-closed while it validates an r11 state against its fixture-only tag.
- Preserved the strict r8 legacy-history regression without allowing r10 state reuse.

## Task Commits

1. Task 1 RED: `ccf7e57`
2. Task 1 GREEN: `9268514`
3. Task 2 RED: `5d624c5`
4. Task 2 GREEN/follow-up fixes: `57d4964`, `7db702d`, `eddd03a`, `dfe3f41`

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 2 - Critical contract closure] Added authority and receipt schemas omitted from the plan file list.
- The action and contract test require these closed artifacts to carry the r10 digest; leaving them at r10 would permit a stale authority/receipt boundary.

2. [Rule 2 - Blocking qualification dependency] Updated `Invoke-Phase08HostedRun.ps1`.
- The real FixtureOnly path still serialized ten histories, so it could not exercise a fresh r11 prepared bundle.

3. [Rule 2 - Test fixture correctness] Updated `New-ReleaseIntent.ps1` and `Test-Phase08PrepareHistorySchema.ps1`.
- Their r10-current fixtures would otherwise fail at the deliberately retained r11 clone-local ref gate before reaching the intended assertions.

## Verification

- `Test-PreparedReleaseBundle.ps1` — PASS
- `Test-Phase08Qualification.ps1 -FixtureOnly` — PASS
- `Test-ReleaseIntent.ps1` — PASS (focused construction is deferred until r11 tag authorization)
- `Test-Phase08PrepareHistorySchema.ps1` — PASS
- PowerShell parse checks and `git diff --check` — PASS

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all scoped source and test artifacts exist in committed history.
- Confirmed task commits `ccf7e57`, `9268514`, `5d624c5`, `57d4964`, `7db702d`, `eddd03a`, and `dfe3f41` exist.
