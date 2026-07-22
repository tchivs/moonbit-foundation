---
phase: 06-namespace-authority-and-compatibility-contract
plan: "17"
subsystem: compatibility
tags: [moonbit, baselines, reproducibility, source-anchor]
requires:
  - phase: 06-16
    provides: bounded anchored baseline-generation pattern for mb-core
provides:
  - anchored canonical public-interface evidence for tchivs/mb-core/checked
  - anchored canonical public-interface evidence for tchivs/mb-core/error
affects: [06-24, compatibility-finalization]
tech-stack:
  added: []
  patterns: [bounded exact-package generation, protected non-owner outputs]
key-files:
  created: []
  modified:
    - compatibility/baselines/0.1.0/mb-core/checked/baseline.json
    - compatibility/baselines/0.1.0/mb-core/checked/js.mbti
    - compatibility/baselines/0.1.0/mb-core/checked/native.mbti
    - compatibility/baselines/0.1.0/mb-core/checked/raw.mbti
    - compatibility/baselines/0.1.0/mb-core/checked/wasm-gc.mbti
    - compatibility/baselines/0.1.0/mb-core/checked/wasm.mbti
    - compatibility/baselines/0.1.0/mb-core/error/baseline.json
    - compatibility/baselines/0.1.0/mb-core/error/js.mbti
    - compatibility/baselines/0.1.0/mb-core/error/native.mbti
    - compatibility/baselines/0.1.0/mb-core/error/raw.mbti
    - compatibility/baselines/0.1.0/mb-core/error/wasm-gc.mbti
    - compatibility/baselines/0.1.0/mb-core/error/wasm.mbti
key-decisions:
  - "Use canonical policy order error then checked at the generator boundary while preserving the plan-owned twelve-file output set."
patterns-established:
  - "Batch evidence is accepted only when generation and read-only check agree and the changed file set equals the plan-owned file set."
requirements-completed: [COMP-01, COMP-02]
coverage:
  - id: D1
    description: Canonical checked and error interface baselines are generated twice from the immutable 0.1.0 source boundary.
    requirement: COMP-01
    verification:
      - kind: integration
        ref: "New-PublicInterfaceBaseline.ps1 generation and -Check for tchivs/mb-core/error and tchivs/mb-core/checked"
        status: pass
    human_judgment: false
  - id: D2
    description: Exactly twelve selected package files changed while the source anchor, final manifest, and ninety nonselected baselines remained unchanged.
    requirement: COMP-02
    verification:
      - kind: integration
        ref: "exact changed-file-set, protected-file, anchor-digest, and target-record assertions"
        status: pass
    human_judgment: false
duration: 2min
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 17: Core Checked and Error Baseline Batch Summary

**The `tchivs/mb-core` checked and error packages now have reproducible four-target interface evidence bound to the immutable 0.1.0 source snapshot.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-07-17T12:24:50Z
- **Completed:** 2026-07-17T12:26:18Z
- **Tasks:** 1
- **Files modified:** 12

## Accomplishments

- Regenerated checked and error from canonical `tchivs/*` source using the pinned MoonBit toolchain and exact immutable source commit.
- Proved the generator's two clean results are byte-identical and passed its read-only `-Check` mode.
- Proved the batch changed exactly twelve owned files and did not change `manifest.json`, the source snapshot, or any of ninety nonselected baseline outputs.

## Task Commits

1. **Task 1: Generate and verify mb-core/checked and mb-core/error** - `a3290ac` (feat)

## Files Created/Modified

- `compatibility/baselines/0.1.0/mb-core/checked/*` - Canonical checked package record plus raw and four normalized target interfaces.
- `compatibility/baselines/0.1.0/mb-core/error/*` - Canonical error package record plus raw and four normalized target interfaces.

## Decisions Made

- Passed the selected packages in canonical policy order (`error`, then `checked`) because the exact-package generator intentionally rejects out-of-order inventory requests; this does not alter the plan-owned output boundary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used canonical package order at the exact-package boundary**
- **Found during:** Task 1 (Generate and verify mb-core/checked and mb-core/error)
- **Issue:** The plan's illustrative package array listed `checked` before `error`, while `Assert-ExactPackages` requires canonical policy order (`error`, then `checked`).
- **Fix:** Invoked the same exact two-package batch in canonical policy order.
- **Files modified:** None beyond the twelve planned generated outputs.
- **Verification:** Generation, independent second-run equality, read-only `-Check`, and exact changed-file-set assertions passed.
- **Committed in:** `a3290ac`

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** The invocation order was corrected without changing package membership, generated content, or output ownership.

## Issues Encountered

- The first verification command had a PowerShell parser error in an in-memory key-set comparison before generation started. Correcting the expression allowed the full verification to run; no repository files were changed by the failed invocation.
- The state progress recalculation handler did not recognize the current frontmatter shape and temporarily wrote `percent: 0`; the plan close-out corrected the derived value to 60% and advanced the next-plan pointer to 06-18.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The checked and error batch is ready for complete-tree finalization in 06-24.
- Remaining package batches can proceed independently without manifest or cross-batch mutation.

## Self-Check: PASSED

- Commit `a3290ac` exists and contains exactly the twelve plan-owned generated files.
- Both baseline records match source snapshot SHA-256 `7fc93ca072bb10fbfb213ae067d94ab0e50e3907635d6c43a5f7f2716424d9b0` and source commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7`.
- All eight target inspection records pass and match their canonical raw interfaces.
- The immutable anchor, final manifest, and ninety nonselected baseline files remained byte-unchanged.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
