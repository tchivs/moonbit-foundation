---
phase: 62-explicit-grayalpha16-decode-contract
plan: "01"
subsystem: png decoder
tags: [moonbit, png, graya16, decode, raster]
requires:
  - phase: 61-png-graya16-encode-contract
    provides: Existing packed graya16 image-model and encoder contracts.
provides:
  - Explicit eager `PngDecoder::decode_graya16` selector returning the existing `DecodeResult`.
  - Private first-IDAT profile admission and Type-4/16 little-endian raster sink.
  - Public fidelity and private atomic-admission regression coverage.
affects: [png decoding, image-model consumers, future explicit PNG profiles]
tech-stack:
  added: []
  patterns:
    - Private decoder profiles select explicit fidelity behavior without changing generic decode semantics.
    - Profile admission occurs before image lifecycle allocation at the first IDAT boundary.
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/stream_decode.mbt
    - modules/mb-image/png/raster_decode.mbt
    - modules/mb-image/png/png_test.mbt
    - modules/mb-image/png/stream_decode_wbtest.mbt
key-decisions:
  - "Expose GrayAlpha16 through one eager public selector while retaining the existing DecodeResult envelope."
  - "Admit only non-interlaced Type-4/16 PNGs with default or sRGB colour declarations before allocating a result."
  - "Store explicit Type-4/16 components through U16 byte lanes in little-endian order; leave generic RGBA8 widening unchanged."
patterns-established:
  - "Use a private decode profile threaded from preflight to raster storage for opt-in PNG fidelity contracts."
requirements-completed: [GRA16DEC-01]
coverage:
  - id: D1
    description: Explicit Type-4/16 GrayAlpha16 decoding preserves all source bytes in packed little-endian graya16 output.
    requirement: GRA16DEC-01
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target js --frozen --filter '*explicit graya16*'"
        status: pass
    human_judgment: false
  - id: D2
    description: Incompatible explicit profiles fail atomically before private lifecycle allocation, while default and sRGB Type-4/16 profiles are admitted.
    requirement: GRA16DEC-01
    verification:
      - kind: unit
        ref: "moon -C modules/mb-image test png --target js --frozen --filter '*graya16 profile*'"
        status: pass
    human_judgment: false
duration: 16min
completed: 2026-07-23
status: complete
---

# Phase 62 Plan 01: Explicit GrayAlpha16 Decode Contract Summary

**An opt-in PNG Type-4/16 decoder now preserves unequal gray and alpha source bytes as packed little-endian graya16 while the generic decoder remains RGBA8-compatible.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-07-23T13:18:29+08:00
- **Completed:** 2026-07-23T13:34:39+08:00
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added `PngDecoder::decode_graya16`, retaining the established `DecodeResult` API envelope.
- Added the private `GrayAlpha16` profile, with atomic first-IDAT admission for non-interlaced Type-4/16 PNGs carrying only default or sRGB colour declarations.
- Routed the explicit profile through U16 component-byte storage so `Ghi,Glo,Ahi,Alo` becomes `Glo,Ghi,Alo,Ahi`; generic PNG decoding still exposes the historical RGBA8 high-byte widening.
- Added public literal-payload fidelity checks and white-box typed rejection/admission tests.

## Task Commits

1. **Task 1: public explicit Type-4/16 decode contract** - `cce9745` (RED test), `3ff334c` (implementation)
2. **Task 2: atomic private profile admission** - `2e5c441` (RED test), `503d535` (implementation)

## Files Created/Modified

- `modules/mb-image/png/png.mbt` - exposes the eager explicit decoder selector.
- `modules/mb-image/png/stream_decode.mbt` - owns profile admission, descriptor selection, and budget routing.
- `modules/mb-image/png/raster_decode.mbt` - writes explicit Type-4/16 lanes through the U16 component-byte API.
- `modules/mb-image/png/png_test.mbt` - verifies literal default/sRGB payload fidelity and generic compatibility.
- `modules/mb-image/png/stream_decode_wbtest.mbt` - verifies typed first-IDAT rejection is allocation-free and valid profiles are admitted.

## Decisions Made

- Kept the profile private and selected it only through the one eager public `decode_graya16` entry point.
- Rejected interlacing, transparency, legacy gAMA/cHRM, iCCP, incompatible type/depth, and all non-default/non-sRGB declarations with `png-decode/graya16-profile` before lifecycle allocation.
- Preserved the generic decoder's existing RGBA8 behavior as an explicit compatibility boundary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected sRGB raster-budget channel accounting for the explicit profile**
- **Found during:** Task 2 (valid sRGB profile admission)
- **Issue:** The transport has two source components, but the existing sRGB result metadata and image allocation reserve four output bytes per pixel. Using the transport channel count made valid sRGB input fail admission under the declared budget.
- **Fix:** Used the image metadata channel count when calculating the sRGB output budget; generic behavior is unchanged because its transport and metadata counts match.
- **Files modified:** `modules/mb-image/png/stream_decode.mbt`
- **Verification:** The default and sRGB admission regression passes.
- **Committed in:** `503d535`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** Required for valid sRGB Type-4/16 admission; no scope expansion.

## Verification

- Passed: `moon -C modules/mb-image test png --target js --frozen --filter '*explicit graya16*'` (1/1).
- Passed: `moon -C modules/mb-image test png --target js --frozen --filter '*graya16 profile*'` (2/2).
- Passed: `moon -C modules/mb-image check --target native --frozen` (0 errors; pre-existing warnings only).
- The planned full native PNG test command was attempted but could not complete because Clang 22 exhausted memory while compiling the pre-existing generated black-box corpus. Focused JS tests and native source checking provide the completed verification evidence.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The explicit PNG fidelity contract is ready for consumers; future PNG profile work can reuse the private preflight-to-sink profile pattern.

## Self-Check: PASSED

- All five planned source/test files exist.
- TDD commits `cce9745`, `3ff334c`, `2e5c441`, and `503d535` exist in git history.

---
*Phase: 62-explicit-grayalpha16-decode-contract*
*Completed: 2026-07-23*
