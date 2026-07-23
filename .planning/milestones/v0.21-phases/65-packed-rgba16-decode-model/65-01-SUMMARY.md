---
phase: 65-packed-rgba16-decode-model
plan: 01
subsystem: image-model-storage
tags: [moonbit, rgba16, u16, image-descriptor, storage-views]
requires:
  - phase: 62-explicit-grayalpha16-decode-contract
    provides: Packed U16 identity and component-byte view precedent.
provides:
  - Checked packed little-endian U16 RGBA descriptor identity.
  - Storage-order component-byte proof for all four RGBA16 lanes.
affects: [phase-66-rgba16-png-decode, image-model, image-storage]
tech-stack:
  added: []
  patterns:
    - Narrow format-specific identity validation before descriptor construction.
    - Packed U16 lane evidence through existing component-byte views.
key-files:
  created: []
  modified:
    - modules/mb-image/model/descriptor.mbt
    - modules/mb-image/model/model_test.mbt
    - modules/mb-image/storage/storage_test.mbt
key-decisions:
  - "RGBA16 is restricted to packed little-endian U16, straight alpha, encoded builtin-sRGB, and TopLeft orientation."
  - "Existing component-byte views remain the sole U16 storage access path; get_byte stays U8-only."
patterns-established:
  - "Add high-precision public formats with a dedicated validator instead of broadening legacy RGBA admission."
requirements-completed: [RGBA16DEC-01]
coverage:
  - id: D1
    description: Checked packed RGBA16 descriptor identity and invalid metadata/layout rejection.
    requirement: RGBA16DEC-01
    verification:
      - kind: unit
        ref: modules/mb-image/model/model_test.mbt#rgba16 descriptor tests; moon -C modules/mb-image test model --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: All eight little-endian RGBA16 component bytes are writable and readable without U8 narrowing.
    requirement: RGBA16DEC-01
    verification:
      - kind: unit
        ref: modules/mb-image/storage/storage_test.mbt#checked packed views retain all rgba16 component byte pairs; moon -C modules/mb-image test storage --target all --frozen
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-07-23
status: complete
---

# Phase 65 Plan 01: Packed RGBA16 Decode Model Summary

**Packed little-endian U16 RGBA descriptors now provide one strict straight-alpha encoded-sRGB identity and observable eight-byte storage order.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-23T17:31:00+08:00
- **Completed:** 2026-07-23T17:34:08+08:00
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Added `ImageFormat::rgba16()` for packed little-endian U16 RGBA samples.
- Added a dedicated RGBA16 validator that rejects noncanonical alpha, colour identity, orientation, layout, and endianness facts before descriptor creation.
- Proved all `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi` bytes through the existing checked component-byte views while retaining U8-only `get_byte` rejection.

## Task Commits

1. **Task 1: Red-green the public packed RGBA16 descriptor identity**
   - `8414825` `test(65-01): add failing rgba16 descriptor contract`
   - `e72b738` `feat(65-01): add constrained packed rgba16 descriptor`
2. **Task 2: Prove all RGBA16 component lanes through existing storage views**
   - `44dbf85` `test(65-01): cover rgba16 storage component bytes`

## Files Created/Modified

- `modules/mb-image/model/descriptor.mbt` — Adds the public RGBA16 format and its constrained identity validation.
- `modules/mb-image/model/model_test.mbt` — Tests the exact descriptor shape and all invalid identity facts.
- `modules/mb-image/storage/storage_test.mbt` — Tests all eight RGBA16 component bytes, checked bounds, and U8 accessor rejection.

## Decisions Made

- RGBA16 admission is deliberately separate from legacy RGBA validation, so `rgba8` can retain its established alpha behavior.
- Existing generic U16 component-byte views satisfy RGBA16 storage semantics; no parallel storage API was added.

## Verification

- `moon -C modules/mb-image test model --target js --frozen --filter '*rgba16*'` — passed (2 tests).
- `moon -C modules/mb-image test storage --target js --frozen --filter '*rgba16*'` — passed (1 test).
- `moon -C modules/mb-image test model --target all --frozen` — passed (18 tests on wasm, wasm-gc, js, and native).
- `moon -C modules/mb-image test storage --target all --frozen` — passed (18 tests on wasm, wasm-gc, js, and native; upstream MoonBit generated-code unused-value warnings only).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The Task 2 regression passed on its first run because the existing generic packed-U16 component-byte implementation already supports four channels. This confirmed the planned reuse of `views.mbt`; no unowned storage implementation change was necessary.

## Next Phase Readiness

Phase 66 can target the exact eight-byte packed `rgba16` descriptor contract without changing existing U8 descriptor or view behavior.

## Self-Check: PASSED

Verified all three implementation/test files, the summary artifact, and task commits `8414825`, `e72b738`, and `44dbf85` exist in repository history.
