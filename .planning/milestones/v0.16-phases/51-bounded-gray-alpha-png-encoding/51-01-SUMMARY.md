---
phase: 51-bounded-gray-alpha-png-encoding
plan: "01"
subsystem: png-encoding
tags: [moonbit, png, grayscale-alpha, bounded-encoding, streaming]
requires:
  - phase: 50-gray-alpha-image-model
    provides: packed U8 GrayAlpha images with explicit straight-alpha metadata
provides:
  - Explicit eager and caller-buffered Gray+Alpha8 PNG factory families
  - Private type-4, 8-bit, non-interlaced encode profile on the shared bounded machine
  - Eager/chunk parity coverage for every bounded compression/filter pair
affects: [52-gray-alpha-png-qualification, png-encoding]
tech-stack:
  added: []
  patterns: [explicit private PNG profile, descriptor admission before output exposure, eager-chunk byte parity]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Gray+Alpha8 reuses the profile-aware preflight, filter, compression planner, and replay machine without a staging buffer."
  - "Only packed U8 GrayAlpha with straight alpha, builtin encoded sRGB, and top-left metadata is admitted."
patterns-established:
  - "New PNG pixel profiles mirror the explicit eager and caller-buffered factory families while selecting one private profile value."
requirements-completed: [GRAYA-02, GRAYA-03]
coverage:
  - id: D1
    description: Explicit Gray+Alpha8 eager and caller-buffered PNG routes emit non-interlaced type-4/8-bit output with ordered gray/alpha pairs.
    requirement: GRAYA-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#PNG GrayAlpha8 eager Stored output uses type 4 packed pairs
        status: pass
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha8 chunk Stored output matches eager
        status: pass
    human_judgment: false
  - id: D2
    description: All public Gray+Alpha8 compression/filter factory combinations use the ordinary bounded eager and caller-buffered route.
    requirement: GRAYA-03
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#PNG GrayAlpha8 eager factory strategies preserve framing
        status: pass
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG GrayAlpha8 chunk factory strategies match eager
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-07-23
status: complete
---

# Phase 51 Plan 01: Bounded Gray+Alpha PNG Encoding Summary

**Packed U8 straight-alpha Gray+Alpha sources now encode as bounded, non-interlaced PNG type 4 through explicit eager and caller-buffered APIs.**

## Performance

- **Duration:** 4 min
- **Completed:** 2026-07-23
- **Tasks:** 2/2
- **Files modified:** 5
- **Verification:** `moon -C modules/mb-image test png --target native --frozen` — 194 passed, 0 failed

## Accomplishments

- Added the private `GrayAlpha8` encode profile and all four eager plus four caller-buffered `graya8` factory shapes.
- Fail-closed admission accepts only the locked packed U8 straight-alpha GrayAlpha descriptor before shared preflight can read source pixels, charge budget, or expose output.
- Emitted IHDR uses bit depth 8, colour type 4, and interlace 0; the generic two-channel U8 wire path preserves gray then alpha.
- Added default fidelity and full three-compression by two-filter eager/chunk regression coverage.

## Task Commits

1. **Task 1: Wire one default Gray+Alpha8 image through eager and caller-buffered PNG encoding** — `13f7454` (`feat`)
2. **Task 2: Prove every graya8 factory shape selects the shared ordinary bounded route** — `e870cc4` (`test`)

## Files Created/Modified

- `modules/mb-image/png/png.mbt` — private profile and eager Gray+Alpha8 factory family.
- `modules/mb-image/png/encode.mbt` — locked descriptor admission and non-interlace profile guard.
- `modules/mb-image/png/stream_encode.mbt` — caller-buffered factory family and type-4 IHDR emission.
- `modules/mb-image/png/encode_test.mbt` — eager raster-order, decoder-fidelity, and factory-strategy coverage.
- `modules/mb-image/png/stream_encode_test.mbt` — ordinary caller-buffered drain parity across all strategy pairs.

## Decisions Made

- Kept Gray+Alpha8 on the existing single bounded pipeline; no staging buffer, alternative encoder, source-tree copy, release automation, or target-specific path was introduced.
- Used non-symmetric component pairs so tests detect gray/alpha swaps at the raster boundary and after decoder canonicalization.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None. The scan found only pre-existing explanatory comments containing the phrase "not available"; no placeholder behavior or unwired data path was introduced.

## Self-Check: PASSED

- All five modified PNG source/test files and this summary exist.
- Task commits `13f7454` and `e870cc4` exist in the repository history.

## Next Phase Readiness

- Phase 52 can add the planned hostile-schedule and four-target qualification evidence using the public `graya8` factory families.
- Existing Gray8, Gray16, RGB8, and straight-RGBA8 routes remain unchanged.

---
*Phase: 51-bounded-gray-alpha-png-encoding*
*Plan: 01*
*Completed: 2026-07-23*
