---
phase: 06-namespace-authority-and-compatibility-contract
plan: "18"
subsystem: compatibility
tags: [moonbit, baselines, reproducibility, source-anchor]
requires:
  - phase: 06-17
    provides: bounded anchored baseline-generation pattern for mb-core
provides:
  - anchored canonical public-interface evidence for tchivs/mb-core/host
  - anchored canonical public-interface evidence for tchivs/mb-core/io
affects: [06-24, compatibility-finalization]
tech-stack:
  added: []
  patterns: [bounded exact-package generation, protected non-owner outputs]
key-files:
  created: []
  modified:
    - compatibility/baselines/0.1.0/mb-core/host/baseline.json
    - compatibility/baselines/0.1.0/mb-core/host/js.mbti
    - compatibility/baselines/0.1.0/mb-core/host/native.mbti
    - compatibility/baselines/0.1.0/mb-core/host/raw.mbti
    - compatibility/baselines/0.1.0/mb-core/host/wasm-gc.mbti
    - compatibility/baselines/0.1.0/mb-core/host/wasm.mbti
    - compatibility/baselines/0.1.0/mb-core/io/baseline.json
    - compatibility/baselines/0.1.0/mb-core/io/js.mbti
    - compatibility/baselines/0.1.0/mb-core/io/native.mbti
    - compatibility/baselines/0.1.0/mb-core/io/raw.mbti
    - compatibility/baselines/0.1.0/mb-core/io/wasm-gc.mbti
    - compatibility/baselines/0.1.0/mb-core/io/wasm.mbti
key-decisions:
  - "Use canonical policy order io then host at the exact-package generator boundary while preserving the plan-owned twelve-file output set."
patterns-established:
  - "A batch is accepted only when generation and read-only check agree and the changed set equals the explicitly owned files."
requirements-completed: [COMP-01, COMP-02]
coverage:
  - id: D1
    description: Canonical host and io interface baselines are generated twice from the immutable 0.1.0 source boundary.
    requirement: COMP-01
    verification:
      - kind: integration
        ref: "New-PublicInterfaceBaseline.ps1 generation and -Check for tchivs/mb-core/io and tchivs/mb-core/host"
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
duration: 4min
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 18: Core Host and IO Baseline Batch Summary

**The `tchivs/mb-core` host and io packages now have reproducible four-target interface evidence bound to the immutable 0.1.0 source snapshot.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-17T12:31:55Z
- **Completed:** 2026-07-17T12:35:11Z
- **Tasks:** 1
- **Files modified:** 12

## Accomplishments

- Regenerated host and io from canonical `tchivs/*` source using the pinned MoonBit toolchain and immutable source commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7`.
- Proved the generator's two clean results are byte-identical and passed its read-only `-Check` mode.
- Proved the batch changed exactly twelve owned files and did not change `manifest.json`, the source snapshot, or any of ninety nonselected baseline outputs.

## Task Commits

1. **Task 1: Generate and verify mb-core/host and mb-core/io** - `ed29895` (feat)

## Files Created/Modified

- `compatibility/baselines/0.1.0/mb-core/host/*` - Canonical host package record plus raw and four normalized target interfaces.
- `compatibility/baselines/0.1.0/mb-core/io/*` - Canonical io package record plus raw and four normalized target interfaces.

## Decisions Made

- Passed the selected packages in canonical policy order (`io`, then `host`) because the exact-package generator rejects out-of-order inventory requests; package membership and the twelve-file ownership boundary remained unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used canonical package order at the exact-package boundary**
- **Found during:** Task 1 (Generate and verify mb-core/host and mb-core/io)
- **Issue:** The plan's illustrative package array listed `host` before `io`, while `Assert-ExactPackages` requires canonical policy order (`io`, then `host`).
- **Fix:** Invoked the same exact two-package batch in canonical policy order.
- **Files modified:** None beyond the twelve planned generated outputs.
- **Verification:** Generation, independent second-run equality, read-only `-Check`, and exact changed-file-set assertions passed.
- **Committed in:** `ed29895`

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** Invocation order was corrected without changing package membership, generated content, or output ownership.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The host and io batch is ready for complete-tree finalization in 06-24.
- Remaining package batches can proceed independently without manifest or cross-batch mutation.

## Self-Check: PASSED

- Commit `ed29895` exists and contains exactly the twelve plan-owned generated files.
- Both baseline records match source snapshot SHA-256 `7fc93ca072bb10fbfb213ae067d94ab0e50e3907635d6c43a5f7f2716424d9b0` and source commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7`.
- All eight target inspection records pass and match their canonical raw interfaces.
- The immutable anchor, final manifest, and ninety nonselected baseline files remained byte-unchanged.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
