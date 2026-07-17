---
phase: 06-namespace-authority-and-compatibility-contract
plan: "23"
subsystem: compatibility
tags: [moonbit, baselines, reproducibility, source-anchor]
requires:
  - phase: 06-22
    provides: anchored canonical mb-image metadata and model baseline batch
provides:
  - anchored canonical public-interface evidence for tchivs/mb-image/ops
  - anchored canonical public-interface evidence for tchivs/mb-image/ppm
affects: [06-24, compatibility-finalization]
tech-stack:
  added: []
  patterns: [bounded exact-package generation, protected non-owner outputs]
key-files:
  created: []
  modified:
    - compatibility/baselines/0.1.0/mb-image/ops/*
    - compatibility/baselines/0.1.0/mb-image/ppm/*
key-decisions:
  - "Preserve canonical package order by generating mb-image/ops before mb-image/ppm without broadening the twelve-file ownership boundary."
patterns-established:
  - "The final image package batch is accepted only when two-run generation and read-only check agree and every nonselected output remains byte-identical."
requirements-completed: [COMP-01, COMP-02]
coverage:
  - id: D1
    description: Canonical ops and PPM interface baselines are generated twice from the immutable 0.1.0 source boundary.
    requirement: COMP-01
    verification:
      - kind: integration
        ref: "New-PublicInterfaceBaseline.ps1 generation and -Check for tchivs/mb-image/ops and tchivs/mb-image/ppm"
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
duration: 3min
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 23: Image Ops and PPM Baseline Batch Summary

**The `tchivs/mb-image/ops` and `tchivs/mb-image/ppm` packages now have reproducible four-target interface evidence bound to the immutable 0.1.0 source snapshot.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-17T13:16:59Z
- **Completed:** 2026-07-17T13:19:52Z
- **Tasks:** 1
- **Files modified:** 12

## Accomplishments

- Regenerated ops and PPM from canonical `tchivs/*` source using the pinned MoonBit toolchain and immutable source commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7`.
- Proved two independent clean generations are byte-identical and passed the generator's read-only `-Check` mode.
- Proved the batch changed exactly twelve owned files and did not change `manifest.json`, source snapshot SHA-256 `7fc93ca072bb10fbfb213ae067d94ab0e50e3907635d6c43a5f7f2716424d9b0`, or any of ninety nonselected package baseline files.

## Task Commits

1. **Task 1: Generate and verify mb-image/ops and mb-image/ppm** - `4e80e88` (chore)

## Files Created/Modified

- `compatibility/baselines/0.1.0/mb-image/ops/*` - Canonical operations package record plus raw and four normalized target interfaces.
- `compatibility/baselines/0.1.0/mb-image/ppm/*` - Canonical PPM package record plus raw and four normalized target interfaces.

## Decisions Made

- Kept the exact package request in canonical policy order (`tchivs/mb-image/ops`, then `tchivs/mb-image/ppm`) while preserving the plan-owned twelve-file output boundary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected stale state progress fields after SDK advancement**
- **Found during:** Plan close-out
- **Issue:** `state.advance-plan` updated the completed-plan count but retained the old next-plan/activity prose, while `state.update-progress` returned `Progress field not found` and left the percentage at zero.
- **Fix:** Synchronized the Phase 6 state to 21/25 complete, 84%, next 06-24, and the ops/PPM completion activity.
- **Files modified:** `.planning/STATE.md`
- **Verification:** STATE frontmatter and narrative agree with the 21 summaries counted by `roadmap.update-plan-progress`.
- **Committed in:** Plan metadata commit

---

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** Generated evidence and task scope are unchanged; the fix only restores accurate workflow metadata.

## Issues Encountered

- The GSD state progress handler did not recognize this repository's narrative progress field; corrected during close-out.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All seventeen package baseline batches are now regenerated from the immutable personal-namespace source snapshot.
- The complete baseline tree is ready for exact finalization in 06-24.

## Self-Check: PASSED

- Commit `4e80e88` exists and contains exactly the twelve plan-owned generated files.
- Both baseline records match source snapshot SHA-256 `7fc93ca072bb10fbfb213ae067d94ab0e50e3907635d6c43a5f7f2716424d9b0` and source commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7`.
- All eight target inspection records pass and match their canonical raw interfaces.
- The immutable anchor, final manifest SHA-256 `29ca24d05580eb4cec29258880a8032dd5963b8fef911b9fab3834e8f01398df`, and ninety nonselected package baseline files remained byte-unchanged.
- Stub scan found no TODO, FIXME, placeholder, coming-soon, or unavailable markers in the generated outputs.
- STATE and ROADMAP both report 21/25 plans complete with 06-24 next.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
