---
phase: 71-rgba16-adam7-png-encoding
plan: 01
subsystem: png-encoding
tags: [moonbit, png, rgba16, adam7, streaming]
requires:
  - phase: 70-resumable-rgba16-png-encoding
    provides: explicit RGBA16 caller-buffered encoder factories and lifecycle evidence
provides:
  - Explicit eager and caller-buffered RGBA16 Adam7 selector families
  - Independent Type-6/16 seven-pass lane-fidelity evidence
  - RGBA16 Adam7 eager/chunk hostile-lease parity evidence
affects: [png-encoding, rgba16, adam7]
tech-stack:
  added: []
  patterns: [explicit profile selector facades reuse the shared bounded Adam7 machine]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "RGBA16 Adam7 remains opt-in through exactly two eager and two chunk selector facades."
  - "The existing Rgba16 Adam7 traversal is enabled by removing only its obsolete preflight exclusion."
patterns-established:
  - "RGBA16 Adam7 parity uses a fresh eager encoder as the caller-buffered byte oracle."
requirements-completed: [RGBA16ENC-03]
coverage:
  - id: D1
    description: Explicit eager Type-6/16 RGBA16 Adam7 selectors preserve seven-pass wire lanes and decoded packed storage lanes.
    requirement: RGBA16ENC-03
    verification:
      - kind: unit
        ref: "modules/mb-image/png/encode_test.mbt#PNG RGBA16 Adam7 eager wire and explicit decode fidelity"
        status: pass
    human_judgment: false
  - id: D2
    description: Explicit caller-buffered RGBA16 Adam7 selectors retain eager parity, hostile lease ownership, atomic admission, and sticky terminals.
    requirement: RGBA16ENC-03
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG RGBA16 Adam7 chunk parity and hostile schedules"
        status: pass
    human_judgment: false
duration: 31min
completed: 2026-07-23
status: complete
---

# Phase 71 Plan 01: RGBA16 Adam7 PNG Encoding Summary

**Explicit eager and caller-buffered RGBA16 Adam7 selectors now emit legal Type-6/16 PNGs while preserving every packed little-endian source lane.**

## Performance

- **Duration:** 31 min
- **Completed:** 2026-07-23T21:42:26+08:00
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added exactly two eager and two caller-buffered RGBA16 interlace selector APIs, all routed through the established `Rgba16` profile and bounded encoder machine.
- Independently enumerated the 211-byte seven-pass Type-6/16 raster for a non-symmetric 5x5 packed RGBA16 source and verified full decode lane restoration.
- Proved fresh eager/chunk identity for all six compression/filter pairs under zero-capacity, one-byte, and ragged lease schedules, including atomic admission and sticky failure paths.

## Task Commits

1. **Task 1: Red-green the eager RGBA16 Adam7 path with an independent seven-pass fidelity oracle** - `dc34893` (test RED), `6271366` (feat GREEN)
2. **Task 2: Red-green caller-buffered RGBA16 Adam7 selectors and hostile-schedule eager parity** - `9b66ab8` (test RED), `4be15ad` (feat GREEN), `b8e2349` (test lifecycle coverage)

## Files Created/Modified

- `modules/mb-image/png/png.mbt` - eager RGBA16 interlace and all-strategy facades.
- `modules/mb-image/png/encode.mbt` - enables `Rgba16` to use the pre-existing Adam7 traversal.
- `modules/mb-image/png/encode_test.mbt` - independent seven-pass Type-6/16 raster and full packed-lane decode evidence.
- `modules/mb-image/png/stream_encode.mbt` - chunk RGBA16 interlace and all-strategy facades.
- `modules/mb-image/png/stream_encode_test.mbt` - hostile schedule, atomic-admission, released-lease, and mutation-replay coverage.

## Decisions Made

- Kept every existing RGBA16 factory explicitly non-interlaced; Adam7 is selected only through the four additive public APIs.
- Used the existing profile-aware machine, Adam7 pass planner, filter/compression logic, and `pull` lifecycle unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed obsolete RGBA16 Adam7 preflight exclusion**
- **Found during:** Task 1
- **Issue:** `PngEncodeProfile::Rgba16` was rejected for every non-`None` interlace strategy, contradicting the plan's confirmed shared Adam7 support and making the requested facades unusable.
- **Fix:** Removed only the `rgba16-noninterlaced-required` preflight arm; all other profile gates, wire mapping, planner, and lifecycle code remain unchanged.
- **Files modified:** `modules/mb-image/png/encode.mbt`
- **Verification:** focused RGBA16 suite (13/13) and focused Adam7 suite (42/42) pass.
- **Committed in:** `6271366`

**Total deviations:** 1 auto-fixed (Rule 1 bug)

## Issues Encountered

- The plan's source audit described Rgba16 Adam7 as already permitted, but the narrow preflight arm still blocked it. The parent executor authorized the directly required minimal correction.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

RGBA16 Adam7 supports public eager and caller-buffered use with focused JS evidence; Phase 72 retains broad portability qualification.

## Self-Check: PASSED

- Confirmed all five modified source/test files exist.
- Confirmed task commits `dc34893`, `6271366`, `9b66ab8`, `4be15ad`, and `b8e2349` exist in history.
- Confirmed no new stubs were introduced in Phase 71 code; unrelated pre-existing documentation wording was not changed.
