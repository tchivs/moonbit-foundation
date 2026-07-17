---
phase: 06-namespace-authority-and-compatibility-contract
plan: "19"
subsystem: compatibility
tags: [moonbit, baselines, reproducibility, source-anchor]
requires:
  - phase: 06-18
    provides: bounded anchored baseline-generation pattern for mb-core host and io
provides:
  - anchored canonical public-interface evidence for tchivs/mb-color/model
  - anchored canonical public-interface evidence for tchivs/mb-color/alpha
affects: [06-24, compatibility-finalization]
tech-stack:
  added: []
  patterns: [bounded exact-package generation, protected non-owner outputs]
key-files:
  created: []
  modified:
    - compatibility/baselines/0.1.0/mb-color/alpha/baseline.json
    - compatibility/baselines/0.1.0/mb-color/alpha/js.mbti
    - compatibility/baselines/0.1.0/mb-color/alpha/native.mbti
    - compatibility/baselines/0.1.0/mb-color/alpha/raw.mbti
    - compatibility/baselines/0.1.0/mb-color/alpha/wasm-gc.mbti
    - compatibility/baselines/0.1.0/mb-color/alpha/wasm.mbti
    - compatibility/baselines/0.1.0/mb-color/model/baseline.json
    - compatibility/baselines/0.1.0/mb-color/model/js.mbti
    - compatibility/baselines/0.1.0/mb-color/model/native.mbti
    - compatibility/baselines/0.1.0/mb-color/model/raw.mbti
    - compatibility/baselines/0.1.0/mb-color/model/wasm-gc.mbti
    - compatibility/baselines/0.1.0/mb-color/model/wasm.mbti
key-decisions:
  - "Use canonical policy order model then alpha at the exact-package generator boundary while preserving the plan-owned twelve-file output set."
patterns-established:
  - "A color batch is accepted only when generation and read-only check agree and the changed set equals the explicitly owned files."
requirements-completed: [COMP-01, COMP-02]
coverage:
  - id: D1
    description: Canonical model and alpha interface baselines are generated twice from the immutable 0.1.0 source boundary.
    requirement: COMP-01
    verification:
      - kind: integration
        ref: "New-PublicInterfaceBaseline.ps1 generation and -Check for tchivs/mb-color/model and tchivs/mb-color/alpha"
        status: pass
    human_judgment: false
  - id: D2
    description: Exactly twelve selected package files changed while the source anchor, final manifest, and ninety other package baselines remained unchanged.
    requirement: COMP-02
    verification:
      - kind: integration
        ref: "exact changed-file-set, protected-file, anchor-digest, source-binding, and target-record assertions"
        status: pass
    human_judgment: false
duration: 2min
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 19: Color Alpha and Model Baseline Batch Summary

**The `tchivs/mb-color` model and alpha packages now have reproducible four-target interface evidence bound to the immutable 0.1.0 source snapshot.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-07-17T12:39:15Z
- **Completed:** 2026-07-17T12:41:29Z
- **Tasks:** 1
- **Files modified:** 12

## Accomplishments

- Regenerated model and alpha from canonical `tchivs/*` source using the pinned MoonBit toolchain and immutable source commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7`.
- Proved the generator's two clean results are byte-identical and passed its read-only `-Check` mode.
- Proved the batch changed exactly twelve owned files and did not change `manifest.json`, the source snapshot, or any of ninety nonselected package baseline files.

## Task Commits

1. **Task 1: Generate and verify mb-color/alpha and mb-color/model** - `fe6c34f` (feat)

## Files Created/Modified

- `compatibility/baselines/0.1.0/mb-color/alpha/*` - Canonical alpha package record plus raw and four normalized target interfaces.
- `compatibility/baselines/0.1.0/mb-color/model/*` - Canonical model package record plus raw and four normalized target interfaces.

## Decisions Made

- Passed the selected packages in canonical policy order (`model`, then `alpha`) because the exact-package generator rejects out-of-order inventory requests; package membership and the twelve-file ownership boundary remained unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used canonical package order at the exact-package boundary**
- **Found during:** Task 1 (Generate and verify mb-color/alpha and mb-color/model)
- **Issue:** The plan's illustrative package array listed `alpha` before `model`, while `Assert-ExactPackages` requires canonical policy order (`model`, then `alpha`).
- **Fix:** Invoked the same exact two-package batch in canonical policy order.
- **Files modified:** None beyond the twelve planned generated outputs.
- **Verification:** Generation, independent second-run equality, read-only `-Check`, and exact changed-file-set assertions passed.
- **Committed in:** `fe6c34f`

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** Invocation order was corrected without changing package membership, generated content, or output ownership.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The model and alpha batch is ready for complete-tree finalization in 06-24.
- Remaining color package batches can proceed independently without manifest or cross-batch mutation.

## Self-Check: PASSED

- Commit `fe6c34f` exists and contains exactly the twelve plan-owned generated files.
- Both baseline records match source snapshot SHA-256 `7fc93ca072bb10fbfb213ae067d94ab0e50e3907635d6c43a5f7f2716424d9b0` and source commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7`.
- All eight target inspection records pass and match their canonical raw interfaces.
- The immutable anchor, final manifest, and ninety nonselected package baseline files remained byte-unchanged.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
