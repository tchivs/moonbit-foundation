---
phase: 86
plan: 01
subsystem: png-indexed-compression
tags: [png, indexed, preflight, limits, streaming]
requires: [85-01]
provides: [ancillary-aware-admission-evidence]
affects: [INDEXCOMP-03]
tech-stack:
  added: []
  patterns: [selected-facts limits, atomic preflight, shared-machine parity]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
decisions:
  - Retain the existing 512-pixel matrix as the sole selected-frame corpus.
  - Exercise cap-plus-one only for profiles whose cap is below the public IndexedImage 256-entry maximum.
metrics:
  tasks_completed: 2
  tests: 9
status: complete
---

# Phase 86 Plan 01: Ancillary-Aware Preflight and Shared-Machine Integration Summary

Selected Type-3 preflight facts now have all-depth ancillary, exact-limit, and eager/chunk admission evidence without introducing another PNG planner or machine.

## Completed Tasks

1. Added a Fixed-winner tracer for retained PLTE/tRNS facts plus public eager/chunk parity.
2. Expanded to the complete 1/2/4/8 Fixed/Stored matrix with selected work/output boundaries and atomic public-facade checks.

## Verification

- `moon -C modules/mb-image test png --target native --frozen --filter "*indexed compression admission tracer*"` — 3 passed.
- `moon -C modules/mb-image test png --target native --frozen --filter "*indexed compression ancillary admission*"` — 3 passed.
- `moon -C modules/mb-image test png --target native --frozen --filter "*indexed compression*"` — 9 passed.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Avoided an unreachable Indexed8 palette-cap fixture.
- **Found during:** Task 2.
- **Issue:** A `cap + 1` Indexed8 source exceeds `PngIndexedImage::new`'s deliberate public 256-entry validity ceiling, so it cannot reach encoder preflight.
- **Fix:** Kept cap-plus-one preflight checks for profiles 1/2/4 and retained constructor-level invalid-source rejection evidence for Indexed8.
- **Files modified:** `modules/mb-image/png/encode_wbtest.mbt`.
- **Commit:** `812abc0`.

## Known Stubs

None.

## Self-Check: PASSED

- Test artifacts and both task commits exist.
