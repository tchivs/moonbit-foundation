---
phase: 67-resumable-rgba16-png-preservation
plan: 01
subsystem: png-decoder
tags: [moonbit, png, rgba16, streaming, adam7, lifecycle]
requires:
  - phase: 66-explicit-rgba16-png-preservation
    provides: Explicit eager Rgba16 profile with exact Type-6/16 stores, strict admission, and eight-byte accounting.
provides:
  - Additive PngChunkDecoder::new_rgba16 selector for the established shared Rgba16 machine.
  - Public eager/chunk component-byte parity for normal and Adam7 Type-6/16 schedules.
  - Sticky public terminal and private lifecycle evidence for the resumable Rgba16 facade.
affects: [phase-68-rgba16-portable-qualification, png-decoder]
tech-stack:
  added: []
  patterns:
    - Explicit chunk profiles select the existing private decode machine without changing generic selection or lifecycle state.
    - Public schedule tests use fresh caller-owned chunks and eager decode as the exact component-byte oracle.
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/stream_decode_test.mbt
    - modules/mb-image/png/stream_decode_wbtest.mbt
key-decisions:
  - "new_rgba16 selects only PngDecodeProfile::Rgba16 through the existing chunk facade."
  - "Generic Type-6/16 chunk decoding remains the frozen RGBA8 high-byte projection."
patterns-established:
  - "Chunk parity compares descriptors, metadata, bytes-read, dispositions, and all U16 component bytes against a fresh eager result."
requirements-completed: [RGBA16DEC-03]
coverage:
  - id: D1
    description: Caller-owned empty, one-byte, and ragged schedules reproduce eager RGBA16 normal and Adam7 results while generic decoding remains RGBA8 high-byte compatible.
    requirement: RGBA16DEC-03
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_decode_test.mbt#PNG rgba16 chunk schedules match eager preservation
        status: pass
      - kind: integration
        ref: moon -C modules/mb-image test png --target wasm|wasm-gc|js|native --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Rgba16 chunk progress is accepted-only, result transfer is finish-only, and malformed, truncated, profile-invalid, and resource terminals stay typed and sticky.
    requirement: RGBA16DEC-03
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_decode_test.mbt#PNG rgba16 chunk terminals retain atomic sticky compatibility; modules/mb-image/png/stream_decode_wbtest.mbt#PNG rgba16 chunk keeps lifecycle and outcome private until finish
        status: pass
      - kind: integration
        ref: moon -C modules/mb-image test png --target wasm|wasm-gc|js|native --frozen
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-07-23
status: complete
---

# Phase 67 Plan 01: Resumable RGBA16 PNG Preservation Summary

**Caller-owned PNG chunks can now select exact Type-6/16 RGBA preservation with eager-identical normal and Adam7 results, without changing the generic RGBA8 contract.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-23T10:35:41Z
- **Completed:** 2026-07-23T10:43:48Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Added `PngChunkDecoder::new_rgba16`, which delegates solely to the established `PngDecodeProfile::Rgba16` machine.
- Proved descriptor, metadata, accounting, disposition, and every U16 component byte match fresh eager decoding for normal and Adam7 input under empty, one-byte, and ragged caller schedules.
- Covered accepted-only progress, finish-only result transfer, private pre-finish lifecycle, sticky malformed/truncated/profile/resource failures, and frozen generic Type-6/16 RGBA8 high-byte output.

## Task Commits

1. **Task 1: Red-green the additive resumable RGBA16 constructor and eager parity**
   - `80dc387` `test(67-01): add failing rgba16 chunk contract`
   - `6a5a6ac` `feat(67-01): add resumable rgba16 decode`
2. **Task 2: Red-green chunk lifecycle, atomic failures and sticky terminals**
   - `32bf791` `test(67-01): cover rgba16 chunk terminals`

## Files Created/Modified

- `modules/mb-image/png/png.mbt` — Adds the sole new public surface, `PngChunkDecoder::new_rgba16`.
- `modules/mb-image/png/stream_decode_test.mbt` — Exercises eager/chunk parity, generic compatibility, accepted-only progress, and sticky public terminals.
- `modules/mb-image/png/stream_decode_wbtest.mbt` — Confirms the selected facade keeps the Rgba16 machine's lifecycle and outcome private before `finish()`.

## Decisions Made

- Reused the existing private Rgba16 machine and did not alter framing, raster, buffering, or eager decode paths.
- Kept generic `PngChunkDecoder::new` unchanged so Type-6/16 remains RGBA8 high-byte compatible unless callers explicitly opt into `new_rgba16`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Kept the white-box lifecycle fixture self-contained**
- **Found during:** Task 2
- **Issue:** White-box test compilation does not share helpers or literals from black-box test files.
- **Fix:** Used a minimal authenticated Type-6/16 prefix and local limits solely to drive the public facade to its private first-IDAT lifecycle boundary.
- **Files modified:** `modules/mb-image/png/stream_decode_wbtest.mbt`
- **Verification:** Focused RGBA16 and GrayAlpha16 JS checks passed; all four ordinary package targets passed.
- **Committed in:** `32bf791`

**Total deviations:** 1 auto-fixed (1 Rule 3 blocking issue)
**Impact on plan:** Test-only fixture isolation; production scope remains exactly the planned constructor selection.

## Verification

- `moon -C modules/mb-image test png --target js --frozen --filter '*rgba16*'` — passed (7 tests).
- `moon -C modules/mb-image test png --target js --frozen --filter '*graya16*'` — passed (8 tests).
- `moon -C modules/mb-image test png --target wasm --frozen` — passed (242/242).
- `moon -C modules/mb-image test png --target wasm-gc --frozen` — passed (242/242).
- `moon -C modules/mb-image test png --target js --frozen` — passed (242/242).
- `moon -C modules/mb-image test png --target native --frozen` — passed (242/242).

## Next Phase Readiness

Phase 68 can qualify the additive chunk selector across its broader hostile and portable matrix. The shared Rgba16 decoder, explicit lifecycle contract, generic compatibility baseline, and serial four-target package evidence are ready.

## Self-Check: PASSED

Verified the three scoped implementation/test files, this summary, and task commits `80dc387`, `6a5a6ac`, and `32bf791` exist in repository history.
