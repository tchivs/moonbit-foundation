---
phase: 45-bounded-gray8-encoder-path
plan: 01
subsystem: png-encoding
tags: [moonbit, png, gray8, deflate, streaming]
requires:
  - phase: 44-gray8-factory-compatibility
    provides: explicit Stored/None/non-interlaced Gray8 eager and caller-buffered baseline
provides:
  - explicit Gray8 compression-only, filter-only, and combined-strategy factories
  - one-channel reuse of bounded filtering, preflight, compression planning, and replay
  - native strategy, admission, accepted-progress, and sticky-replay regressions
affects: [46-gray8-conformance-evidence, png-encoding]
tech-stack:
  added: []
  patterns: [profile-aware bounded preflight, accepted-byte caller-buffered replay]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Gray8 factories fix interlace to None while permitting every existing compression and filter selection."
  - "One-channel Gray8 enters the existing scalar filter/planner/replay path; no raster staging or profile-specific planner was added."
patterns-established:
  - "New profile strategies delegate to the profile-aware machine constructor after the sole atomic preflight."
requirements-completed: [GRAYPNG-02]
coverage:
  - id: D1
    description: Gray8 eager and caller-buffered compression/filter factories use the shared bounded encoder.
    requirement: GRAYPNG-02
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test png --target native --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Gray8 admission, accepted-progress accounting, and sticky replay are protected by native regressions.
    requirement: GRAYPNG-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG Gray8 strategy admission is atomic
        status: pass
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG Gray8 fixed replay mismatch is sticky
        status: pass
    human_judgment: false
metrics:
  duration: 35m
  completed: 2026-07-22
status: complete
---

# Phase 45 Plan 01: Bounded Gray8 Encoder Path Summary

**Gray8 strategy factories now use the existing bounded preflight, filter, DEFLATE winner, and acknowledgement-safe replay machine.**

## Performance

- **Duration:** 35m
- **Completed:** 2026-07-22
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added explicit eager and caller-buffered Gray8 compression-only, filter-only, and combined factories.
- Generalized one-channel filter admission and lifted only the Gray8 Stored/None strategy exclusion; Gray8 Adam7 remains rejected and all public Gray8 factories select non-interlaced output.
- Added native regressions for factory parity, atomic capability/geometry/output/work/budget rejection, accepted-byte progress, and sticky replay leases.

## Task Commits

1. **Task 1: Wire Gray8 FixedOrStored/None through the existing bounded eager and chunk pipeline** - `b0aac04` (test), `39f709e` (feat)
2. **Task 2: Expand the shared Gray8 path to every compression and filter selection with atomic replay coverage** - `d3286a4` (test)

## Files Created/Modified

- `modules/mb-image/png/png.mbt` - Gray8 eager strategy factory family.
- `modules/mb-image/png/encode.mbt` - One-channel filter admission and Gray8 non-interlace-only preflight guard.
- `modules/mb-image/png/stream_encode.mbt` - Caller-buffered Gray8 strategy factory family routed to the common machine.
- `modules/mb-image/png/encode_test.mbt` - Eager FixedOrStored and strategy selection coverage.
- `modules/mb-image/png/stream_encode_test.mbt` - Chunk/eager parity, atomic admission, and replay coverage.

## Decisions Made

- Gray8 factories mirror legacy strategy naming but permanently bind `PngInterlaceStrategy::None`.
- Existing filtered traversal facts and scalar DEFLATE plans remain the sole state used by Gray8; no full-image output staging was introduced.

## Deviations from Plan

None - plan implementation followed the shared-pipeline design. A short-lived black-box test attempted to access private profile internals and was removed because the public Gray8 factory boundary intentionally does not expose Adam7 selection.

## Issues Encountered

The native package suite takes roughly two minutes and emits pre-existing compiler warnings; its final run completed successfully.

## Known Stubs

None.

## Next Phase Readiness

Phase 46 can add generated decode fidelity, hostile zero/one/ragged capacity schedules, and independent four-target evidence without changing this public strategy surface.

## Self-Check: PASSED

- All five planned source/test files exist and the three task commits are present.
- `moon -C modules/mb-image test png --target native --frozen` passed: 179 tests, 179 passed, 0 failed.

---
*Phase: 45-bounded-gray8-encoder-path*
*Completed: 2026-07-22*
