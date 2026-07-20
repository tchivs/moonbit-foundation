---
phase: 09-checked-image-geometry-and-diagnostics
plan: "02"
subsystem: image-geometry
tags: [moonbit, raster, diagnostics, nearest-neighbor, portable, documentation]
requires:
  - phase: "09-01"
    provides: "Checked owned crop and explicit clockwise rotation operations"
provides:
  - "Adversarial crop and rotation diagnostics with atomic budget evidence"
  - "Two-dimensional deterministic nearest-neighbor floor-mapping regression coverage"
  - "Executable four-target public geometry and resize documentation"
affects: [phase-10-raster-operations, phase-11-pipeline-evidence]
tech-stack:
  added: []
  patterns: ["full Budget::remaining snapshots on rejection", "independent integer-floor resize oracle in white-box tests"]
key-files:
  created:
    - modules/mb-image/ops/geometry_wbtest.mbt
  modified:
    - modules/mb-image/ops/resize_convert_wbtest.mbt
    - modules/mb-image/README.mbt.md
key-decisions:
  - "Nearest-neighbor remains the sole documented reference resampler; no interpolation or conversion fallback was introduced."
  - "Invalid alpha combinations are rejected during descriptor construction, so operation-level capability coverage uses representable unsupported layout, component, channel, and transfer variants."
patterns-established:
  - "Resource-limit diagnostics prove all observable Budget::remaining fields are unchanged after preflight rejection."
requirements-completed: [GEOM-03]
coverage:
  - id: D1
    description: "Adversarial geometry inputs produce typed deterministic diagnostics without budget mutation."
    requirement: GEOM-03
    verification:
      - kind: unit
        ref: "modules/mb-image/ops/geometry_wbtest.mbt#geometry rejects checked rectangles and capability variants without charging"
        status: pass
      - kind: unit
        ref: "modules/mb-image/ops/geometry_wbtest.mbt#crop and rotations reject every output resource atomically"
        status: pass
    human_judgment: false
  - id: D2
    description: "Nearest-neighbor uses the documented integer-floor mapping on all supported targets."
    requirement: GEOM-03
    verification:
      - kind: unit
        ref: "modules/mb-image/ops/resize_convert_wbtest.mbt#nearest resize applies the documented two-dimensional integer-floor mapping"
        status: pass
      - kind: other
        ref: "moon test modules/mb-image/ops --target js|wasm|wasm-gc|native"
        status: pass
    human_judgment: false
  - id: D3
    description: "Public documentation distinguishes borrowed crops, owned crop operations, rotations, and nearest-neighbor semantics."
    requirement: GEOM-03
    verification:
      - kind: other
        ref: "moon -C modules/mb-image check README.mbt.md --target js|wasm|wasm-gc|native --frozen"
        status: pass
    human_judgment: false
duration: 20min
completed: 2026-07-20
status: complete
---

# Phase 9 Plan 02: Geometry Diagnostics and Resize Baseline Summary

**Portable geometry now has adversarial atomic-budget proof, while the existing integer-floor nearest-neighbor mapping is documented and regression-tested across all four targets.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-20T07:30:00Z
- **Completed:** 2026-07-20T07:50:42Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Added white-box evidence for crop rectangle diagnostics, capability rejection, every output resource ceiling, and exhaustive non-square RGB/RGBA rotation coordinate maps.
- Added an independent two-dimensional channel-by-channel nearest-neighbor floor-mapping regression plus typed unsupported-resize budget evidence.
- Updated checked public documentation to make view crop versus owned operation crop, clockwise rotations, normalized orientation, error behavior, and the sole resize formula explicit.

## Task Commits

1. **Task 1: Add adversarial crop and rotation diagnostic evidence** — `f840a4c` (test)
2. **Task 2: Document geometry and retain nearest-neighbor as the tested reference baseline** — `5eba153` (docs)

## Files Created/Modified

- `modules/mb-image/ops/geometry_wbtest.mbt` — Adversarial diagnostics, full budget atomicity, and independent rotation coordinate oracles.
- `modules/mb-image/ops/resize_convert_wbtest.mbt` — Two-dimensional nearest-neighbor mapping and capability regression coverage.
- `modules/mb-image/README.mbt.md` — Executable public geometry API and nearest-neighbor reference contract.

## Decisions Made

- Retained the existing nearest-neighbor implementation and generated vector tables unchanged; the new test computes its own two-dimensional floor mapping.
- Kept invalid alpha-combination coverage at the descriptor invariant boundary because invalid combinations cannot become an `ImageView` accepted by an operation.

## Verification

- `moon test modules/mb-image/ops --target js` — 28 passed
- `moon test modules/mb-image/ops --target wasm` — 28 passed
- `moon test modules/mb-image/ops --target wasm-gc` — 28 passed
- `moon test modules/mb-image/ops --target native` — 28 passed
- `moon -C modules/mb-image check README.mbt.md --target js|wasm|wasm-gc|native --frozen` — passed on all targets
- `moon info` — completed successfully

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- An attempted operation-level invalid RGBA-without-alpha fixture was rejected by `ImageDescriptor::new` before an image view could exist. The final coverage preserves that model invariant and exercises all representable unsupported operation variants.

## Known Stubs

None.

## Next Phase Readiness

Phase 10 can rely on checked geometry diagnostics and a fixed portable nearest-neighbor baseline without inheriting interpolation, alpha filtering, or release-automation scope.

## Self-Check: PASSED

- Confirmed all three planned files exist and both task commits are present in git history.
