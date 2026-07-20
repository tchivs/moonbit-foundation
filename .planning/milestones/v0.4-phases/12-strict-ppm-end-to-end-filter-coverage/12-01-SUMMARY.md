---
phase: 12-strict-ppm-end-to-end-filter-coverage
plan: "01"
subsystem: image-processing-integration
tags: [moonbit, ppm, raster-processing, portable-tests, budgets]
requires:
  - phase: 11-portable-processing-pipeline-evidence
    provides: Portable PPM example and public processing-pipeline test support.
provides:
  - Strict-P6 crop/rotate/grayscale/blur/source-over encoding vector on four targets.
  - Radius-one box-blur budget-boundary proof with full budget atomicity.
affects: [v0.3-audit, mb-image, portable-ppm-example]
tech-stack:
  added: []
  patterns: [Explicit per-stage resource budgets, exact binary oracle plus semantic pixel assertions]
key-files:
  created: []
  modified:
    - examples/ppm-portable/main/main.mbt
    - examples/ppm-portable/main/moon.pkg
    - modules/mb-image/ops/processing_pipeline_test.mbt
    - modules/mb-image/ops/processing_pipeline_wbtest.mbt
key-decisions:
  - "Use the existing portable executable as the public codec-to-ops integration boundary."
  - "Use a radius-one blur with 54/53 work budgets to prove both clamp-edge behavior and preflight atomicity."
patterns-established:
  - "Portable binary evidence combines complete bytes, rolling digest, SHA identity, and selected semantic pixels."
requirements-completed: [INTEG-01, INTEG-02, RASTER-02, RASTER-03]
coverage:
  - id: D1
    description: Strict-P6 crop, rotation, filter, source-over, and exact encoding route.
    requirement: INTEG-01
    verification:
      - kind: integration
        ref: moon -C examples/ppm-portable run main --target js|wasm|wasm-gc|native --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Public semantic vector and atomic 53-work box-blur rejection.
    requirement: RASTER-03
    verification:
      - kind: unit
        ref: modules/mb-image/ops/processing_pipeline_test.mbt and processing_pipeline_wbtest.mbt
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-07-20
status: complete
---

# Phase 12 Plan 01: Strict PPM End-to-End Filter Coverage Summary

**Portable strict-P6 geometry and alpha-aware filter pipeline with exact 29-byte output and atomic radius-one blur budget coverage.**

## Performance

- **Duration:** 14 min
- **Tasks:** 2/2
- **Files modified:** 4
- **Verification:** js, wasm, wasm-gc, and native all passed.

## Accomplishments

- Replaced the portable vector with strict P6 decode → crop → rotate → RGBA conversion → grayscale → radius-one blur → source-over → RGB encode.
- Asserted exact 29-byte bytes, rolling digest `714923673`, SHA-256 identity, diagnostics, geometry, grayscale, and clamp-edge blur pixels.
- Added public semantic coverage and a white-box proof that a 53-work radius-one blur rejects before every resource counter changes.

## Task Commits

1. **Task 1: Replace the portable PPM route with the audited geometry-and-filter vector** — `a06afbd` (`feat`)
2. **Task 2: Add discriminating public and hostile filter-path tests** — `e5e80f6` (`test`)

## Files Created/Modified

- `examples/ppm-portable/main/main.mbt` — portable strict-P6 end-to-end executable vector.
- `examples/ppm-portable/main/moon.pkg` — local `model` import for public crop rectangles.
- `modules/mb-image/ops/processing_pipeline_test.mbt` — public crop/rotate/filter/source-over assertions.
- `modules/mb-image/ops/processing_pipeline_wbtest.mbt` — hostile radius-one blur preflight atomicity test.

## Decisions Made

- Kept all production APIs, codecs, benchmarks, releases, and configuration untouched.
- Used opaque converted source and destination images so strict RGBA-to-RGB conversion remains a meaningful final contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test correctness] Corrected test construction syntax and geometry work budgets.**
- **Found during:** Task 2.
- **Issue:** Tuple destructuring was unsupported by the local MoonBit syntax, and crop/rotation charge output-byte work rather than pixel-count work.
- **Fix:** Replaced the unsupported loop with explicit assertions and set geometry budgets to 18 work units.
- **Files modified:** `modules/mb-image/ops/processing_pipeline_test.mbt`, `modules/mb-image/ops/processing_pipeline_wbtest.mbt`.
- **Verification:** All four target suites pass.
- **Committed in:** `e5e80f6`.

**Total deviations:** 1 auto-fixed (Rule 1).

## Known Stubs

None.

## Self-Check: PASSED

- All four planned implementation artifacts exist and both task commits are present.
- Four-target executable and ops-suite verification passed.
