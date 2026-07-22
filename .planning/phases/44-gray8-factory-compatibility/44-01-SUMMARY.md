---
phase: 44-gray8-factory-compatibility
plan: 01
subsystem: png-encoding
tags: [moonbit, png, gray8, stored-deflate, caller-buffered]
requires:
  - phase: 43
    provides: bounded PNG encoder preflight and acknowledgement-safe replay
provides:
  - Explicit eager and caller-buffered Gray8 Stored PNG factories.
  - Atomic Gray8 profile admission and type-0 IHDR emission.
affects: [45-gray8-filter-compression, 46-gray8-portability]
tech-stack:
  added: []
  patterns:
    - Private output profiles preserve legacy public factory behavior.
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Gray8 is exposed only by explicit Stored/None/non-interlaced factories."
  - "Legacy RGB8 and straight-RGBA8 constructors remain on a separate private profile."
patterns-established:
  - "Profile-aware source admission is performed before budget charging or output exposure."
requirements-completed: [GRAYPNG-01]
coverage:
  - id: D1
    description: Explicit eager Gray8 Stored output emits a complete type-0, 8-bit, non-interlaced PNG and rejects RGB input atomically.
    requirement: GRAYPNG-01
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#PNG Gray8 eager Stored output and profile admission are atomic
        status: pass
    human_judgment: false
  - id: D2
    description: Explicit caller-buffered Gray8 Stored output matches eager bytes and rejects incompatible construction atomically.
    requirement: GRAYPNG-01
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG Gray8 chunk Stored output matches eager and rejects atomically
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-07-22
status: complete
---

# Phase 44 Plan 01: Gray8 Factory Compatibility Summary

**Explicit eager and caller-buffered Gray8 factories now produce standards-compliant 8-bit, type-0, non-interlaced Stored PNGs without changing legacy RGB8 or straight-RGBA8 behavior.**

## Performance

- **Duration:** 18 min
- **Completed:** 2026-07-22
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added `PngEncoder::new_gray8()` and `PngChunkEncoder::new_gray8(...)`, both locked to Stored, filter None, and no interlace.
- Added a private Gray8 profile to central source admission, bounded preflight, replay state, and IHDR emission; type 0 is derived from that same profile.
- Added native focused eager/chunk tests for complete Gray8 bytes, IHDR fields, eager/chunk identity, atomic profile rejection, and accepted-byte accounting.

## Task Commits

1. **Task 1: Implement the explicit default-Stored Gray8 encoder route** — `8217c2b` (`feat`)
2. **Task 2: Prove real Gray8 Stored output and freeze compatibility boundaries** — `518975f` (`test`)

## Files Created/Modified

- `modules/mb-image/png/png.mbt` — private profile selection and eager Gray8 factory.
- `modules/mb-image/png/encode.mbt` — profile-aware source admission and atomic preflight.
- `modules/mb-image/png/stream_encode.mbt` — chunk factory, profile-carrying machine, and Gray8 IHDR emission.
- `modules/mb-image/png/encode_test.mbt` — deterministic eager Gray8 Stored fixture and rejection test.
- `modules/mb-image/png/stream_encode_test.mbt` — caller-buffered Gray8 identity and rejection test.

## Decisions Made

- Kept Gray8 strategy, filter, and Adam7 surfaces private and unavailable; later phases own those extensions.
- Preserved the legacy profile as the default delegation path so existing RGB/RGBA admission and bytes stay unchanged.

## Deviations from Plan

None — plan scope was implemented without auto-fixes or scope expansion.

## Verification

- `moon check modules/mb-image/png --target native` — passed (64 pre-existing warnings, 0 errors).
- `moon test modules/mb-image/png/encode_test.mbt --target native --index 10` — passed (1/1): eager Gray8 output and atomic admission.
- `moon test modules/mb-image/png/stream_encode_test.mbt --target native --index 0` — passed (1/1): chunk Gray8 eager identity and atomic admission.
- `moon test modules/mb-image/png --target native` was attempted twice but exceeded the runner harness's fixed 64-second limit without diagnostics; targeted indexed native tests were used after a successful test build.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all five scoped source/test files and this summary exist.
- Confirmed task commits `8217c2b` and `518975f` exist in repository history.

## Next Phase Readiness

Phase 45 can extend the same private Gray8 profile through filter and Fixed/Dynamic strategy planning without changing this default Stored compatibility route.
