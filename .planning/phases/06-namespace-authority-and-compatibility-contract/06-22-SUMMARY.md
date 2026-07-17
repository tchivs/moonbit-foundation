---
phase: 06-namespace-authority-and-compatibility-contract
plan: "22"
subsystem: compatibility
tags: [moonbit, baselines, reproducibility, source-anchor]
requires:
  - phase: 06-21
    provides: bounded anchored baseline-generation pattern through mb-image codec
provides:
  - anchored canonical public-interface evidence for tchivs/mb-image/metadata
  - anchored canonical public-interface evidence for tchivs/mb-image/model
affects: [06-23, 06-24, compatibility-finalization]
tech-stack:
  added: []
  patterns: [bounded exact-package generation, protected non-owner outputs]
key-files:
  created: []
  modified:
    - compatibility/baselines/0.1.0/mb-image/metadata/*
    - compatibility/baselines/0.1.0/mb-image/model/*
key-decisions:
  - "Preserve canonical package order by generating mb-image/metadata before mb-image/model without broadening the twelve-file ownership boundary."
patterns-established:
  - "An image package batch is accepted only when two-run generation and read-only check agree and every nonselected output remains byte-identical."
requirements-completed: [COMP-01, COMP-02]
coverage:
  - id: D1
    description: Canonical metadata and model interface baselines are generated twice from the immutable 0.1.0 source boundary.
    requirement: COMP-01
    verification:
      - kind: integration
        ref: "New-PublicInterfaceBaseline.ps1 generation and -Check for tchivs/mb-image/metadata and tchivs/mb-image/model"
        status: pass
    human_judgment: false
  - id: D2
    description: Exactly twelve selected package files changed while the source anchor, final manifest, and ninety nonselected package baselines remained unchanged.
    requirement: COMP-02
    verification:
      - kind: integration
        ref: "exact changed-file-set, protected-file, anchor-digest, source-binding, and target-record assertions"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 22: Image Metadata and Model Baseline Batch Summary

**The `tchivs/mb-image/metadata` and `tchivs/mb-image/model` packages now have reproducible four-target interface evidence bound to the immutable 0.1.0 source snapshot.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-17T13:08:45Z
- **Completed:** 2026-07-17T13:12:45Z
- **Tasks:** 1
- **Files modified:** 12

## Accomplishments

- Regenerated metadata and model from canonical `tchivs/*` source using the pinned MoonBit toolchain and immutable source commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7`.
- Proved two independent clean generations are byte-identical and passed the generator's read-only `-Check` mode.
- Proved the batch changed exactly twelve owned files and did not change `manifest.json`, source snapshot SHA-256 `7fc93ca072bb10fbfb213ae067d94ab0e50e3907635d6c43a5f7f2716424d9b0`, or any of ninety nonselected package baseline files.

## Task Commits

1. **Task 1: Generate and verify mb-image/metadata and mb-image/model** - `091b6bb` (feat)

## Files Created/Modified

- `compatibility/baselines/0.1.0/mb-image/metadata/*` - Canonical metadata package record plus raw and four normalized target interfaces.
- `compatibility/baselines/0.1.0/mb-image/model/*` - Canonical model package record plus raw and four normalized target interfaces.

## Decisions Made

- Kept the exact package request in canonical policy order (`tchivs/mb-image/metadata`, then `tchivs/mb-image/model`) while preserving the plan-owned twelve-file output boundary.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The next bounded image package batch can proceed in 06-23.
- Metadata and model are ready for complete-tree finalization in 06-24 after the remaining image package outputs are regenerated.

## Self-Check: PASSED

- Commit `091b6bb` exists and contains exactly the twelve plan-owned generated files.
- Both baseline records match source snapshot SHA-256 `7fc93ca072bb10fbfb213ae067d94ab0e50e3907635d6c43a5f7f2716424d9b0` and source commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7`.
- All eight target inspection records pass and match their canonical raw interfaces.
- The immutable anchor, final manifest SHA-256 `29ca24d05580eb4cec29258880a8032dd5963b8fef911b9fab3834e8f01398df`, and ninety nonselected package baseline files remained byte-unchanged.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
