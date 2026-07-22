---
phase: 06-namespace-authority-and-compatibility-contract
plan: "21"
subsystem: compatibility
tags: [moonbit, baselines, reproducibility, source-anchor]
requires:
  - phase: 06-20
    provides: bounded anchored baseline-generation pattern for mb-color quantize and profile
provides:
  - anchored canonical public-interface evidence for tchivs/mb-color/transfer
  - anchored canonical public-interface evidence for tchivs/mb-image/codec
affects: [06-24, compatibility-finalization]
tech-stack:
  added: []
  patterns: [bounded exact-package generation, protected non-owner outputs]
key-files:
  created: []
  modified:
    - compatibility/baselines/0.1.0/mb-color/transfer/baseline.json
    - compatibility/baselines/0.1.0/mb-color/transfer/js.mbti
    - compatibility/baselines/0.1.0/mb-color/transfer/native.mbti
    - compatibility/baselines/0.1.0/mb-color/transfer/raw.mbti
    - compatibility/baselines/0.1.0/mb-color/transfer/wasm-gc.mbti
    - compatibility/baselines/0.1.0/mb-color/transfer/wasm.mbti
    - compatibility/baselines/0.1.0/mb-image/codec/baseline.json
    - compatibility/baselines/0.1.0/mb-image/codec/js.mbti
    - compatibility/baselines/0.1.0/mb-image/codec/native.mbti
    - compatibility/baselines/0.1.0/mb-image/codec/raw.mbti
    - compatibility/baselines/0.1.0/mb-image/codec/wasm-gc.mbti
    - compatibility/baselines/0.1.0/mb-image/codec/wasm.mbti
key-decisions:
  - "Preserve canonical global package order by generating mb-color/transfer before mb-image/codec without broadening the twelve-file ownership boundary."
patterns-established:
  - "A cross-module batch is accepted only when two-run generation and read-only check agree and every nonselected output remains byte-identical."
requirements-completed: [COMP-01, COMP-02]
coverage:
  - id: D1
    description: Canonical transfer and codec interface baselines are generated twice from the immutable 0.1.0 source boundary.
    requirement: COMP-01
    verification:
      - kind: integration
        ref: "New-PublicInterfaceBaseline.ps1 generation and -Check for tchivs/mb-color/transfer and tchivs/mb-image/codec"
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

# Phase 6 Plan 21: Color Transfer and Image Codec Baseline Batch Summary

**The `tchivs/mb-color/transfer` and `tchivs/mb-image/codec` packages now have reproducible four-target interface evidence bound to the immutable 0.1.0 source snapshot.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-17T12:58:00Z
- **Completed:** 2026-07-17T13:02:08Z
- **Tasks:** 1
- **Files modified:** 12

## Accomplishments

- Regenerated transfer and codec from canonical `tchivs/*` source using the pinned MoonBit toolchain and immutable source commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7`.
- Proved two independent clean generations are byte-identical and passed the generator's read-only `-Check` mode.
- Proved the batch changed exactly twelve owned files and did not change `manifest.json`, source snapshot SHA-256 `7fc93ca072bb10fbfb213ae067d94ab0e50e3907635d6c43a5f7f2716424d9b0`, or any of ninety nonselected package baseline files.

## Task Commits

1. **Task 1: Generate and verify mb-color/transfer and mb-image/codec** - `39864fe` (feat)

## Files Created/Modified

- `compatibility/baselines/0.1.0/mb-color/transfer/*` - Canonical transfer package record plus raw and four normalized target interfaces.
- `compatibility/baselines/0.1.0/mb-image/codec/*` - Canonical codec package record plus raw and four normalized target interfaces.

## Decisions Made

- Kept the exact package request in canonical global policy order (`tchivs/mb-color/transfer`, then `tchivs/mb-image/codec`) while preserving the plan-owned twelve-file output boundary.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The final bounded package batch is ready for complete-tree finalization in 06-24.
- Image package batches can proceed without manifest or cross-batch mutation.

## Self-Check: PASSED

- Commit `39864fe` exists and contains exactly the twelve plan-owned generated files.
- Both baseline records match source snapshot SHA-256 `7fc93ca072bb10fbfb213ae067d94ab0e50e3907635d6c43a5f7f2716424d9b0` and source commit `b81cff59d4d1bd371b250ed0fd314ca1a6a008e7`.
- All eight target inspection records pass and match their canonical raw interfaces.
- The immutable anchor, final manifest, and ninety nonselected package baseline files remained byte-unchanged.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
