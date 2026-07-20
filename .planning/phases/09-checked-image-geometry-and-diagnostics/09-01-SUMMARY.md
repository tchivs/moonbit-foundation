---
phase: 09-checked-image-geometry-and-diagnostics
plan: "01"
subsystem: image-geometry
tags: [moonbit, raster, crop, rotation, diagnostics, portable]
requires:
  - phase: "04"
    provides: "Image descriptors, metadata, views, owned storage, and portable image operations"
provides:
  - "Checked, tightly packed, owned-image crop operation"
  - "Named clockwise rotate_90, rotate_180, and rotate_270 operations"
  - "Deterministic capability, region, and budget failure behavior"
affects: [phase-09-plan-02, phase-10-raster-operations, phase-11-pipeline-evidence]
tech-stack:
  added: []
  patterns: ["validate geometry before allocation", "one OwnedImage operation charge before mutation", "explicit named right-angle rotations"]
key-files:
  created:
    - modules/mb-image/ops/geometry.mbt
    - modules/mb-image/ops/geometry_test.mbt
  modified: []
key-decisions:
  - "Crop returns a fresh tightly packed OwnedImage and preserves all metadata."
  - "Right-angle rotation uses named APIs and normalizes physical output orientation to TopLeft."
patterns-established:
  - "Geometry operations reuse the existing packed sRGB U8 RGB/RGBA capability gate and atomic owned-output allocation."
requirements-completed: [GEOM-01, GEOM-02, RASTER-03]
coverage:
  - id: D1
    description: "Checked crop produces a fresh tight owned image with stable invalid-region diagnostics."
    requirement: GEOM-01
    verification:
      - kind: unit
        ref: "modules/mb-image/ops/geometry_test.mbt#crop returns a fresh tight owned image and preserves metadata"
        status: pass
      - kind: unit
        ref: "modules/mb-image/ops/geometry_test.mbt#crop rejects invalid public requests before charging the budget"
        status: pass
      - kind: unit
        ref: "modules/mb-image/ops/geometry_test.mbt#crop and rotation reject unsupported formats before charging the budget"
        status: pass
    human_judgment: false
  - id: D2
    description: "Named rotations preserve every RGB/RGBA pixel mapping and normalize orientation metadata."
    requirement: GEOM-02
    verification:
      - kind: unit
        ref: "modules/mb-image/ops/geometry_test.mbt#explicit rotations map every non-square RGB and RGBA coordinate clockwise"
        status: pass
      - kind: unit
        ref: "modules/mb-image/ops/geometry_test.mbt#rotation budget failure remains typed and atomic"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-07-20
status: complete
---

# Phase 9 Plan 01: Checked Owned Crop and Explicit Rotations Summary

**Portable checked crop produces independent tightly packed images, while named clockwise rotations preserve every packed RGB/RGBA pixel and normalize output orientation.**

## Performance

- **Duration:** 18 min
- **Completed:** 2026-07-20
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added `crop`, which validates capability and bounds before one budgeted owned-image allocation, then copies the requested stored-coordinate rectangle into tight storage.
- Added `rotate_90`, `rotate_180`, and `rotate_270` with direct clockwise coordinate maps, fresh output, and `TopLeft` metadata.
- Added public tests for RGB/RGBA crop and rotation behavior, metadata disposition, deterministic diagnostics, capability rejection, and atomic budget rejection.

## Task Commits

1. **Task 1: Add checked fresh owned-image crop** — `320e1a6`, `6aa3a25`, `2931d85`
2. **Task 2: Add explicit right-angle rotation operations** — `db59567`, `10687a8`, `6e602dd`

## Files Created/Modified

- `modules/mb-image/ops/geometry.mbt` — Checked owned crop and three named clockwise rotations.
- `modules/mb-image/ops/geometry_test.mbt` — Public pixel, metadata, diagnostic, and budget behavior tests.

## Decisions Made

- Kept the capability, descriptor, allocation, and metadata conventions from the existing copy/flip and orientation operations.
- Added only the three named rotation functions; no rotation enum or generic dispatch API.

## Verification

- `moon test modules/mb-image/ops --target js` — 23 passed
- `moon test modules/mb-image/ops --target wasm` — 23 passed
- `moon test modules/mb-image/ops --target wasm-gc` — 23 passed
- `moon test modules/mb-image/ops --target native` — 23 passed
- `moon info` — completed successfully

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `state.advance-plan` could not parse the pre-existing `Plan: —` state position. The remaining state handlers recorded 1/2 progress, the metric, decisions, session, roadmap, and completed requirements successfully.

## Known Stubs

None.

## Next Phase Readiness

The checked crop and explicit rotation APIs are available for Plan 02 adversarial coverage and the subsequent raster-processing work.

## Self-Check: PASSED

- Confirmed both geometry source/test files exist and all six task commits are present in git history.
