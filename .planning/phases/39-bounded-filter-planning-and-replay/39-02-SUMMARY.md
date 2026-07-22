---
phase: 39-bounded-filter-planning-and-replay
plan: "02"
subsystem: png-encoding
tags: [png, adaptive-filter, deflate, replay, resource-limits]
requires: [39-01]
provides: [adaptive-filtered-byte-source, filter-aware-preflight-ledger]
affects: [png-encode, png-stream-encode]
tech-stack:
  added: []
  patterns: [checked-work-ledger, shared-filtered-byte-provider]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/stream_encode_wbtest.mbt
decisions:
  - Keep filter-None on its legacy scanline provider while routing Adaptive through the shared logical filtered stream.
  - Charge checked adaptive candidate scoring before construction alongside selected output and existing matcher replay work.
metrics:
  tasks_completed: 2
status: complete
---

# Phase 39 Plan 02: Bounded Adaptive Planning and Replay Summary

Adaptive PNG filtering now supplies preflight and replay through one logical byte resolver, including filter tags and residuals for Stored, Fixed, and Dynamic paths.

## Completed Work

- Added RED internal coverage for adaptive row tags/residuals and exact adaptive work admission.
- Routed compressor planning and Fixed/Dynamic replay through filter-aware bytes.
- Kept filter-None on `_png_fixed_scanline_byte` and retained strict compression winner selection.
- Added checked adaptive ledger work: two `height * (5 * row_bytes)` scorer traversals before the single budget charge.

## Verification

- Passed focused adaptive planner tests on `js`, `wasm`, `wasm-gc`, and `native` (2/2 each).
- Aggregate `--target all` PNG regression exceeded the 124-second execution timeout without reporting a test assertion failure.

## Commits

- `e845e5e` — `test(39-02): add adaptive planner replay tests`
- `71fc1dd` — `feat(39-02): integrate bounded adaptive PNG replay`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test fixture] Corrected 2×2 plane descriptor lengths and row strides.**
- **Found during:** Task 2 focused GREEN verification.
- **Issue:** The initial multi-row fixtures supplied the descriptor length and row-byte arguments in the wrong order, causing construction to fail before encoder coverage.
- **Fix:** Set full plane lengths with matching packed row stride/row bytes.
- **Files modified:** `encode_wbtest.mbt`, `stream_encode_wbtest.mbt`.
- **Commit:** `71fc1dd`.

## Self-Check: PASSED

- Task commits `e845e5e` and `71fc1dd` exist.
- All four plan-owned source/test files exist.
