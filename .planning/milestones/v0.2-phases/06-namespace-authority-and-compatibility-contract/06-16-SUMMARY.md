---
phase: 06-namespace-authority-and-compatibility-contract
plan: "16"
subsystem: compatibility
tags: [moonbit, baselines, reproducibility, source-anchor]
requires:
  - phase: 06-15
    provides: immutable 0.1.0 source snapshot and exact-package baseline generator
provides:
  - anchored canonical public-interface evidence for tchivs/mb-core/budget
  - anchored canonical public-interface evidence for tchivs/mb-core/bytes
affects: [06-24, compatibility-finalization]
tech-stack:
  added: []
  patterns: [bounded exact-package generation, protected non-owner outputs]
key-files:
  created: []
  modified:
    - compatibility/baselines/0.1.0/mb-core/budget/baseline.json
    - compatibility/baselines/0.1.0/mb-core/budget/js.mbti
    - compatibility/baselines/0.1.0/mb-core/budget/native.mbti
    - compatibility/baselines/0.1.0/mb-core/budget/raw.mbti
    - compatibility/baselines/0.1.0/mb-core/budget/wasm-gc.mbti
    - compatibility/baselines/0.1.0/mb-core/budget/wasm.mbti
    - compatibility/baselines/0.1.0/mb-core/bytes/baseline.json
    - compatibility/baselines/0.1.0/mb-core/bytes/js.mbti
    - compatibility/baselines/0.1.0/mb-core/bytes/native.mbti
    - compatibility/baselines/0.1.0/mb-core/bytes/raw.mbti
    - compatibility/baselines/0.1.0/mb-core/bytes/wasm-gc.mbti
    - compatibility/baselines/0.1.0/mb-core/bytes/wasm.mbti
key-decisions:
  - "Keep the batch boundary at exactly budget and bytes; the immutable anchor, final manifest, and every nonselected baseline remain byte-unchanged."
patterns-established:
  - "Batch evidence is accepted only when generation and read-only check agree and the staged diff equals the plan-owned file set."
requirements-completed: [COMP-01, COMP-02]
coverage:
  - id: D1
    description: Canonical budget and bytes interface baselines are regenerated twice from the immutable 0.1.0 source boundary.
    requirement: COMP-01
    verification:
      - kind: integration
        ref: "New-PublicInterfaceBaseline.ps1 batch generation and -Check for tchivs/mb-core/budget and tchivs/mb-core/bytes"
        status: pass
    human_judgment: false
  - id: D2
    description: Exactly twelve selected package files changed while the source anchor, final manifest, and all nonselected baselines remained unchanged.
    requirement: COMP-02
    verification:
      - kind: integration
        ref: "exact staged-file-set, protected-file, anchor-digest, and target-record assertions"
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-07-17
status: complete
---

# Phase 6 Plan 16: Core Budget and Bytes Baseline Batch Summary

**The `tchivs/mb-core` budget and bytes packages now have reproducible four-target interface evidence bound to the immutable 0.1.0 source snapshot.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-17T12:15:00Z
- **Completed:** 2026-07-17T12:18:52Z
- **Tasks:** 1
- **Files modified:** 12

## Accomplishments

- Regenerated budget and bytes from canonical `tchivs/*` source using the pinned MoonBit toolchain and exact immutable source commit.
- Proved the generator's two clean results are byte-identical and passed its read-only `-Check` mode.
- Proved the batch changed exactly twelve owned files and did not change `manifest.json`, the source snapshot, or any nonselected baseline output.

## Task Commits

1. **Task 1: Generate and verify mb-core/budget and mb-core/bytes** - `af527b6` (feat)

## Files Created/Modified

- `compatibility/baselines/0.1.0/mb-core/budget/*` - Canonical budget package record plus raw and four normalized target interfaces.
- `compatibility/baselines/0.1.0/mb-core/bytes/*` - Canonical bytes package record plus raw and four normalized target interfaces.

## Decisions Made

- Preserved the exact two-package ownership boundary; no final-manifest write is permitted before the complete 17-package tree is ready.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first in-memory nonselected-file-set assertion used PowerShell array comparison incorrectly and reported a false failure after both generator checks had passed. The repository diff and corrected exact-set assertion confirmed that only the twelve selected files changed; no repository repair was needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The budget and bytes batch is ready for complete-tree finalization in 06-24.
- Remaining package batches can proceed independently without manifest or cross-batch mutation.

## Self-Check: PASSED

- Commit `af527b6` contains exactly the twelve plan-owned generated files.
- Both baseline records match source snapshot SHA-256 `7fc93ca072bb10fbfb213ae067d94ab0e50e3907635d6c43a5f7f2716424d9b0` and its exact source commit.
- All eight target inspection records pass and match their canonical raw interfaces.

---
*Phase: 06-namespace-authority-and-compatibility-contract*
*Completed: 2026-07-17*
