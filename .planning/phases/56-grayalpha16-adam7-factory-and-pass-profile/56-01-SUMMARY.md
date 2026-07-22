---
phase: 56-grayalpha16-adam7-factory-and-pass-profile
plan: "01"
subsystem: png-encoding
tags: [moonbit, png, adam7, grayalpha16, u16, streaming]
requires:
  - phase: 55-portable-public-evidence
    provides: Legal little-endian GrayAlpha16 profile, Type-4/16 wire mapping, and public eager/chunk parity baseline.
provides:
  - Additive eager and caller-buffered GrayAlpha16 Adam7 selector pairs.
  - Type-4/depth-16 Adam7 source lanes serialized through the existing U16 PNG wire mapper.
affects: [57-bounded-adam7-streaming-semantics, 58-portable-adam7-public-evidence, png-encoding]
tech-stack:
  added: []
  patterns: [explicit opt-in interlace factories, profile-aware Adam7 scalar wire reads, shared-machine construction]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "GrayAlpha16 Adam7 is additive through explicit eager and caller-buffered factories; legacy GrayAlpha16 factories retain PngInterlaceStrategy::None."
  - "Adam7 reads use _png_wire_byte with the existing GrayAlpha16 profile, preserving Ghi/Glo/Ahi/Alo before filters, compression planning, and replay."
patterns-established:
  - "New format/interlace combinations select an existing profile and PngEncodeMachine rather than adding a second machine or staging buffer."
requirements-completed: [GRAYA16A7-01]
coverage:
  - id: D1
    description: Explicit eager and chunk GrayAlpha16 Adam7 factories produce matching Type-4/depth-16/interlace-1 Stored/None output with seven-pass Ghi/Glo/Ahi/Alo lanes.
    requirement: GRAYA16A7-01
    verification:
      - kind: integration
        ref: "moon -C modules/mb-image test png --target all --frozen -f 'PNG GrayAlpha16 Adam7 eager pass profile'"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-image test png --target all --frozen -f 'PNG GrayAlpha16 Adam7 chunk parity'"
        status: pass
      - kind: unit
        ref: "moon -C modules/mb-image test png --target native --frozen"
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-07-23
status: complete
---

# Phase 56 Plan 01: GrayAlpha16 Adam7 Factory and Pass Profile Summary

**Explicit eager and caller-buffered GrayAlpha16 Adam7 factories now emit shared-machine Type-4/16 PNG pass data in Ghi/Glo/Ahi/Alo wire order.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-23T06:56:25+08:00
- **Completed:** 2026-07-23T07:04:23+08:00
- **Tasks:** 1/1
- **Files modified:** 5

## Accomplishments

- Added narrow Stored/None and all-strategy GrayAlpha16 Adam7 factories for `PngEncoder` and `PngChunkEncoder`.
- Allowed Adam7 only for the existing `GrayAlpha16` profile while preserving Gray8, Gray16, and GrayAlpha8 rejection guards.
- Routed Adam7 scalar reads through the profile-aware U16 wire mapper and proved all seven nonempty 5x5 passes use `Ghi,Glo,Ahi,Alo` order.
- Proved ordinary caller-buffered output equals the eager oracle on every supported target and retained the native PNG suite baseline.

## Task Commits

1. **Task 1: Prove and deliver one legal GrayAlpha16 Adam7 eager-to-chunk path**
   - `0f111ee` — RED coverage for eager pass lanes and caller-buffered parity.
   - `eb2bc6a` — shared-profile factory, admission, and traversal implementation.

## Files Created/Modified

- `modules/mb-image/png/png.mbt` — additive eager GrayAlpha16 Adam7 factory pair.
- `modules/mb-image/png/encode.mbt` — GrayAlpha16 Adam7 admission plus profile-aware pass wire reads.
- `modules/mb-image/png/stream_encode.mbt` — additive caller-buffered GrayAlpha16 Adam7 factory pair using `PngEncodeMachine::new_with_profile`.
- `modules/mb-image/png/encode_test.mbt` — 5x5 seven-pass Stored/None wire-order regression.
- `modules/mb-image/png/stream_encode_test.mbt` — 5x5 eager/chunk parity regression.

## Decisions Made

- Kept the Phase 53 little-endian descriptor admission boundary unchanged; no Big-endian encoder route was introduced.
- Retained `_png_adam7_passes` as the sole geometry authority and reused the existing bounded machine without staging.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test fixture bug] Corrected the initial 5x5 plane descriptor and Adam7-capable eager helper.**

- **Found during:** Task 1
- **Issue:** The initial test fixture swapped plane-size and row-byte fields, and the normal eager helper did not carry the Adam7 test limits.
- **Fix:** Used the canonical packed descriptor layout and the existing Adam7-capable helper.
- **Files modified:** `modules/mb-image/png/encode_test.mbt`, `modules/mb-image/png/stream_encode_test.mbt`
- **Verification:** Focused eager/chunk tests passed on wasm, wasm-gc, JS, and native; native PNG suite passed 206/206.
- **Committed in:** `eb2bc6a`

**Total deviations:** 1 auto-fixed (Rule 1 test-fixture bug).

**Impact on plan:** The correction was limited to test setup and did not alter the planned production architecture.

## Known Stubs

None. The stub scan found only pre-existing explanatory comments containing “not available”; no placeholder behavior was introduced.

## Issues Encountered

- The invalid initial fixture caused the native test executable to terminate with `0xc0000409`; the narrower JS run located the failing descriptor construction and confirmed the fixture correction.

## Next Phase Readiness

- Phase 57 can extend the new legal profile through bounded compression/filter/replay semantics without adding another encoder path.
- Strict Big-endian descriptor rejection and frozen non-interlaced GrayAlpha16 routes remain covered by existing behavior and the passing native PNG suite.

## Self-Check: PASSED

- All five scoped PNG source/test files and this summary exist.
- Task commits `0f111ee` and `eb2bc6a` exist in repository history.

---
*Phase: 56-grayalpha16-adam7-factory-and-pass-profile*
*Plan: 01*
*Completed: 2026-07-23*
