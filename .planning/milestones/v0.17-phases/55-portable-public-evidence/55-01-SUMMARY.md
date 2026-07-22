---
phase: 55-portable-public-evidence
plan: "01"
subsystem: testing
tags: [moonbit, png, graya16, portability, regression]
requires:
  - phase: 54-bounded-type-4-16-encoder
    provides: Legal little-endian Type-4/16 eager and caller-buffered public factories
provides:
  - Public Type-4/16 GrayAlpha16 wire and RGBA8 decode compatibility evidence
  - All-six-pair caller-buffered lease and terminal regression matrix
  - Frozen Gray8, Gray16, GrayAlpha8, RGB8, and RGBA8 eager/chunk PNG vectors
affects: [png, graya16, public-api-compatibility, portable-targets]
tech-stack:
  added: []
  patterns: [literal PNG vectors, accepted-prefix caller-buffer assertions, four-target portable qualification]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Prove U16 wire fidelity and U8 decoder canonicalization as separate public contracts."
  - "Use a fresh public chunk encoder for each hostile schedule and preserve caller-owned lease tails."
patterns-established:
  - "Literal Stored/None PNG data is retained as an independent compatibility oracle."
  - "All compression/filter pairs receive zero-capacity, one-byte, and ragged public drain evidence."
requirements-completed: [GRAYA16-04]
coverage:
  - id: D1
    description: "Legal GrayAlpha16 output proves literal Type-4/16 U16 lane order and public straight-RGBA8 high-byte decoding."
    requirement: GRAYA16-04
    verification:
      - kind: unit
        ref: "modules/mb-image/png/encode_test.mbt#PNG GrayAlpha16 public eager wire and decode fidelity"
        status: pass
    human_judgment: false
  - id: D2
    description: "All six GrayAlpha16 compression/filter pairs preserve eager bytes, accepted-only progress, lease tails, and sticky success terminals across hostile schedules."
    requirement: GRAYA16-04
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha16 chunk public evidence"
        status: pass
    human_judgment: false
  - id: D3
    description: "Frozen eager and caller-buffered Gray8, Gray16, GrayAlpha8, RGB8, and RGBA8 vectors pass on every portable target."
    requirement: GRAYA16-04
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target all --frozen"
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-07-23
status: complete
---

# Phase 55 Plan 01: Portable Public Evidence Summary

**Public GrayAlpha16 compatibility evidence now freezes Type-4/16 U16 wire lanes, straight-RGBA8 high-byte decoding, caller-buffered ownership, and five PNG format baselines across all portable targets.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-07-22T21:46:00Z
- **Completed:** 2026-07-22T22:00:07Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Proved the legal `(1234,A7C5)/(BE0F,5A76)` GrayAlpha16 Type-4/16 Stored/None raster as literal `00 12 34 A7 C5 BE 0F 5A 76`, then decoded it publicly to `(12,12,12,A7)` and `(BE,BE,BE,5A)`.
- Exercised Stored, FixedOrStored, and DynamicOrFixedOrStored with None and Adaptive filters under independent zero, one-byte, and ragged caller-buffered schedules.
- Frozen complete GrayAlpha8 Stored/None vectors alongside the existing Gray8, Gray16, RGB8, and straight-RGBA8 eager/chunk baselines.
- Passed the public PNG package suite on wasm, wasm-gc, js, and native (204 tests per target).

## Task Commits

Each task was committed atomically:

1. **Task 1: Prove one public GrayAlpha16 wire-to-decode path and freeze eager compatibility vectors** - `af47151` (test)
2. **Task 2: Prove all-six-pair GrayAlpha16 hostile chunk schedules and all-target portability** - `c8267c9` (test)

## Files Created/Modified

- `modules/mb-image/png/encode_test.mbt` - Public Type-4/16 wire/decode assertions and a frozen GrayAlpha8 eager vector.
- `modules/mb-image/png/stream_encode_test.mbt` - Six-pair hostile drain matrix, accepted-prefix/tail/sticky-terminal assertions, and a frozen GrayAlpha8 chunk vector.

## Decisions Made

- Kept full U16 lane fidelity at the literal PNG wire boundary and asserted only documented high-byte data at the current public RGBA8 decoder boundary.
- Used fresh public encoders for each hostile schedule so a prior pull cannot hide initial capacity or terminal behavior.
- Retained the existing strict Big-endian GrayAlpha16 descriptor-rejection coverage unchanged; all added sources are legal little-endian fixtures.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The focused native invocation specified by the plan exited successfully but reported no matching test entry for its filter. The required unfiltered four-target package command then executed all 204 tests successfully on each target and is the recorded acceptance result.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

GRAYA16-04 is closed with portable public regression evidence. No production codec, API, FFI, fixture, release, source-copy, retry, or target-specific branch changes were introduced.

## Self-Check: PASSED

- Confirmed both modified PNG test files exist.
- Confirmed task commits `af47151` and `c8267c9` exist.
- No new stub patterns were found in the modified test files.

---
*Phase: 55-portable-public-evidence*
*Completed: 2026-07-23*
