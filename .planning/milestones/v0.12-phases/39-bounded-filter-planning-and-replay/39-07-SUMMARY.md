---
phase: 39-bounded-filter-planning-and-replay
plan: "07"
subsystem: png-encoder
tags: [moonbit, png, adaptive-filtering, deflate, atomic-admission]
requires:
  - phase: 39-06
    provides: bounded acknowledgement-safe Adaptive cursor and replay
provides:
  - Dynamic planning outcomes retain real cursor facts on selected and declined paths
  - Shared Adaptive preflight charges declined Dynamic work before atomic admission
affects: [png-filter-planning, png-encoder-budgeting]
tech-stack:
  added: []
  patterns: [fact-carrying private planner outcomes, single atomic preflight ledger]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Carry Dynamic frequency and bit traversal facts in one private outcome even when no Dynamic plan is selected."
  - "Use the existing preflight ledger for a forced post-bit-count decline test; production retains the fixed PNG IDAT ceiling."
patterns-established:
  - "Candidate declines report all work already executed before fallback selection."
requirements-completed: [PNGF-03]
coverage:
  - id: D1
    description: Declined Dynamic traversal facts are included once in atomic Adaptive preflight accounting.
    requirement: PNGF-03
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_wbtest.mbt#PNG adaptive Dynamic decline facts are admitted
        status: pass
    human_judgment: false
  - id: D2
    description: Adaptive eager and caller-buffered fallback routes share an exact public admission boundary.
    requirement: PNGF-03
    verification:
      - kind: integration
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG adaptive Dynamic decline public admission is atomic
        status: pass
    human_judgment: false
duration: 41min
completed: 2026-07-22
status: complete
---

# Phase 39 Plan 07: Dynamic-decline accounting Summary

**Adaptive Dynamic candidate work is retained and charged before Fixed-or-Stored fallback can expose eager output or a chunk encoder.**

## Performance

- **Duration:** 41 min
- **Tasks:** 2
- **Files modified:** 3
- **Verification:** Nine targeted selectors passed independently on js, wasm, wasm-gc, and native; `moon check png --target all` passed.

## Accomplishments

- Replaced the Dynamic planner's option-only result with a fact-carrying private outcome.
- Charged real Dynamic frequency and bit-count facts before strict Dynamic-versus-baseline selection.
- Added exact/one-less ledger and public eager/chunk atomicity regressions, including complete decode parity.

## Task Commits

1. **Task 1: Add RED Dynamic-decline fact and atomic-boundary regressions** — `6328609` (`test`)
2. **Task 2: Return declined Dynamic facts and charge them before selection** — `e918fe7` (`feat`)

## Decisions Made

- Kept Fixed tie preference, strict Dynamic win, legacy None output, public factories, and the bounded cursor unchanged.
- Added a private IDAT-limit test seam so the existing small Adaptive fixture deterministically exercises the real post-bit-count decline and the production ledger unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Testability] Added a private Dynamic IDAT-limit seam**
- **Found during:** Task 1
- **Issue:** A real PNG IDAT-capacity decline cannot be constructed from a compact in-memory test image.
- **Fix:** Used a private bound only in white-box tests to exercise the same post-bit-count decline and shared preflight path; production always supplies PNG's fixed maximum.
- **Files modified:** `modules/mb-image/png/encode.mbt`, `modules/mb-image/png/encode_wbtest.mbt`
- **Verification:** Named white-box selector and all-target targeted matrix pass.
- **Committed in:** `e918fe7`

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

Dynamic planning and replay now preserve every executed Adaptive cursor fact through fallback admission. No QOI, public API, policy, or planning-state files were changed.

## Self-Check: PASSED

- Both task commits exist and the three declared PNG files are present.
- Isolated `phase39-07-green` target root was removed after verification.
