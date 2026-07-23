---
phase: 66-explicit-rgba16-png-preservation
plan: 01
subsystem: png-decoder
tags: [moonbit, png, rgba16, adam7, u16, preflight]
requires:
  - phase: 65-packed-rgba16-decode-model
    provides: Checked packed little-endian rgba16 descriptor and component-byte views.
provides:
  - Explicit eager PngDecoder::decode_rgba16 selector for default/sRGB Type-6/16 PNG input.
  - Exact little-endian RGBA16 lane stores for ordinary and Adam7 rows.
  - Typed, pre-allocation RGBA16 profile admission and eight-byte output accounting.
affects: [phase-67-rgba16-chunk-decode, phase-68-rgba16-portable-qualification, png-decoder]
tech-stack:
  added: []
  patterns:
    - Explicit high-precision decode profiles select their descriptor, storage budget, and final byte store without widening generic decode.
    - Explicit colour-fact gates run before generic ICC validation when the profile promises a typed admission error.
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/stream_decode.mbt
    - modules/mb-image/png/raster_decode.mbt
    - modules/mb-image/png/png_test.mbt
    - modules/mb-image/png/stream_decode_wbtest.mbt
key-decisions:
  - "Only the eager selector is exposed; generic Type-6/16 decode remains the RGBA8 high-byte projection."
  - "RGBA16 accepts only declaration-free or sRGB Type-6/16 input and writes source lanes once into packed U16 little-endian storage."
  - "RGBA16 result preflight reserves eight storage bytes per pixel while filtered source-row accounting remains byte-domain."
patterns-established:
  - "Thread explicit decode profiles through the existing single raster sink so normal and Adam7 paths share the final-store contract."
requirements-completed: [RGBA16DEC-02]
coverage:
  - id: D1
    description: Explicit eager Type-6/16 decode preserves all normal-row and Adam7 RGBA16 source lanes while generic RGBA8 stays high-byte-only.
    requirement: RGBA16DEC-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/png_test.mbt#rgba16 eager normal and Adam7 tests; moon -C modules/mb-image test png --target js --frozen --filter '*rgba16*'
        status: pass
      - kind: integration
        ref: moon -C modules/mb-image test png --target wasm|wasm-gc|js|native --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Explicit profile mismatches fail before lifecycle allocation and RGBA16 preflight reserves eight output bytes per pixel.
    requirement: RGBA16DEC-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_decode_wbtest.mbt#rgba16 profile admission and layout test; moon -C modules/mb-image test png --target js --frozen --filter '*rgba16*'
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-07-23
status: complete
---

# Phase 66 Plan 01: Explicit RGBA16 PNG Preservation Summary

**Eager Type-6/16 PNG decode now preserves every straight-alpha RGBA source lane in packed little-endian rgba16 storage without changing generic RGBA8 decoding.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-23T17:55:26+08:00
- **Completed:** 2026-07-23T18:07:43+08:00
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added the eager-only `PngDecoder::decode_rgba16` selector backed by the existing byte-fed decode machine.
- Preserved normal-row and Adam7 Type-6/16 wire lanes as `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi`; generic decoding remains `RGBA8(Rhi,Ghi,Bhi,Ahi)`.
- Added typed default/sRGB-only admission before allocation and verified the eight-byte-per-pixel result layout while retaining GrayAlpha16 behavior.

## Task Commits

1. **Task 1: Red-green explicit eager RGBA16 profile and exact normal/Adam7 stores**
   - `9d5c07e` `test(66-01): add failing rgba16 decode contract`
   - `7fa7a69` `feat(66-01): add explicit rgba16 eager decode`
2. **Task 2: Red-green strict preallocation admission and 8-byte output-layout accounting**
   - `03d8bb1` `test(66-01): cover rgba16 preflight boundaries`
   - `959fba3` `fix(66-01): gate rgba16 colour facts before validation`

## Files Created/Modified

- `modules/mb-image/png/png.mbt` — Adds the explicit eager RGBA16 selector.
- `modules/mb-image/png/stream_decode.mbt` — Adds profile admission, typed colour-fact ordering, and eight-byte output budget selection.
- `modules/mb-image/png/raster_decode.mbt` — Builds the RGBA16 descriptor and performs exact normal/Adam7 component-byte stores.
- `modules/mb-image/png/png_test.mbt` — Adds independent normal and sRGB Adam7 Type-6/16 lane regressions plus generic compatibility evidence.
- `modules/mb-image/png/stream_decode_wbtest.mbt` — Adds atomic profile-fact and resource-boundary white-box coverage.

## Decisions Made

- Kept `decode_rgba16` eager-only; no chunk selector or second decoder was introduced.
- Reused the existing byte-domain filters and single raster traversal, changing only the profile-specific descriptor, budget, and final component-byte store.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Typed RGBA16 ICC rejection could be bypassed by generic ICC validation**
- **Found during:** Task 2
- **Issue:** An incompatible ICC fact could return a generic ICC validation error before the explicit `rgba16-profile` admission gate ran.
- **Fix:** Performed explicit Type-6/16 colour-fact admission before generic declaration validation, preserving the required typed, allocation-free failure.
- **Files modified:** `modules/mb-image/png/stream_decode.mbt`, `modules/mb-image/png/stream_decode_wbtest.mbt`
- **Verification:** Focused RGBA16 and GrayAlpha16 JS PNG checks passed; all four package targets passed.
- **Committed in:** `959fba3`

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)

## Verification

- `moon -C modules/mb-image test png --target js --frozen --filter '*rgba16*'` — passed (4 tests).
- `moon -C modules/mb-image test png --target js --frozen --filter '*graya16*'` — passed (8 tests).
- `moon -C modules/mb-image test png --target wasm --frozen` — passed (239 tests).
- `moon -C modules/mb-image test png --target wasm-gc --frozen` — passed (239 tests).
- `moon -C modules/mb-image test png --target js --frozen` — passed (239 tests).
- `moon -C modules/mb-image test png --target native --frozen` — passed (239 tests).

The aggregate `--target all` invocation exceeded the execution runner's 180-second limit without a failure signal; the required target set was then verified serially with the ordinary per-target package command above.

## Next Phase Readiness

Phase 67 can add the caller-buffered RGBA16 selector by reusing `PngDecodeProfile::Rgba16`; the eager contract, strict gate, exact storage layout, and generic compatibility baseline are established.

## Self-Check: PASSED

Verified all five implementation/test files and task commits `9d5c07e`, `7fa7a69`, `03d8bb1`, and `959fba3` exist in repository history.
