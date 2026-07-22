---
phase: 39-bounded-filter-planning-and-replay
plan: "01"
subsystem: png
tags: [moonbit, png, filters, deterministic-scoring]
requires:
  - phase: 38-adaptive-filter-compatibility
    provides: PngFilterStrategy compatibility seam and filter-None baseline
provides:
  - Exact package-private PNG method-0 row residual helpers
  - Checked signed-residual scoring with stable candidate selection
affects: [39-02-adaptive-planning-replay, png-adaptive-filtering]
tech-stack:
  added: []
  patterns: [raw-neighbor filter predictors, checked UInt64 candidate scores, strict earlier-wins ties]
key-files:
  created: []
  modified: [modules/mb-image/png/encode.mbt, modules/mb-image/png/encode_wbtest.mbt]
key-decisions:
  - "Use original raw samples and a 3- or 4-byte pixel stride for every method-0 neighbor."
  - "Keep None, Sub, Up, Average, Paeth order and replace a winner only for a strictly lower score."
requirements-completed: [PNGF-02]
coverage:
  - id: D1
    description: Exact RGB8 and straight-RGBA8 PNG method-0 residual and predictor helpers.
    requirement: PNGF-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_wbtest.mbt#PNG filter arithmetic
        status: pass
    human_judgment: false
  - id: D2
    description: Checked signed-absolute scoring and deterministic first-minimum filter selection.
    requirement: PNGF-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_wbtest.mbt#PNG filter arithmetic
        status: pass
    human_judgment: false
metrics:
  duration: 7min
  completed: 2026-07-22
status: complete
---

# Phase 39 Plan 01: Bounded Filter Arithmetic Summary

**Exact reusable PNG method-0 residual predictors and checked stable row scoring for RGB8 and straight-RGBA8.**

## Accomplishments

- Added None, Sub, Up, Average, and Paeth candidate residual helpers using original raw row neighbors.
- Added checked UInt64 signed-absolute scoring, including byte `0x80`, and strict earliest-winner selection.
- Added focused white-box vectors for pixel-stride edges, previous rows, upper-left Paeth selection, scoring, and ties.

## Task Commits

1. **Task 1: Add RED vectors for filter formulas, scoring, and stable selection** - `566a66b` (test)
2. **Task 2: Implement checked PNG method-0 filter and score helpers** - `c84058d` (feat)

## Verification

- `moon -C modules/mb-image test png --target native --target-dir _build/phase39-01-native2 --frozen -f '*filter arithmetic*'` — 4/4 passed.
- Focused `*filter arithmetic*` tests passed on `js`, `wasm`, `wasm-gc`, and `native` with isolated target directories.
- `moon -C modules/mb-image check png --target all --target-dir _build/phase39-01-check --frozen` passed.

## Decisions Made

- Predictors consume raw source neighbors; filtered residuals are never reused as neighbors.
- Paeth comparisons retain the PNG `pa`, then `pb`, then `pc` precedence, while row selection keeps the earlier candidate on score ties.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test vector] Corrected RGBA Average alpha residual**
- **Found during:** Task 2
- **Issue:** The first-row RGBA Average fixture expected `0x19`; the exact residual is `0x1d` because `(40 + 0) / 2 = 20` and `49 - 20 = 29`.
- **Fix:** Corrected the expected fixture byte.
- **Files modified:** `modules/mb-image/png/encode_wbtest.mbt`
- **Commit:** `c84058d`

## Known Stubs

None.

## Next Phase Readiness

Plan 39-02 can use `PngRowFilter`, `_png_filter_candidate_byte`, and `_png_filter_row_winner` to construct its bounded planning and replay cursor while preserving the legacy filter-None provider.

## Self-Check: PASSED

- Both modified implementation/test files and this summary exist.
- RED (`566a66b`) and GREEN (`c84058d`) commits are present in history.
