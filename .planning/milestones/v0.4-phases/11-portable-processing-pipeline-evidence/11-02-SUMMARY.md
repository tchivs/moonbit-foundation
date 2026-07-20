---
phase: 11-portable-processing-pipeline-evidence
plan: "02"
subsystem: testing
tags: [moonbit, ppm, image-processing, portable, conformance, budget]
requires:
  - phase: "09"
    provides: "Checked nearest-neighbor resize and portable geometry operations"
  - phase: "10"
    provides: "RGBA conversion and alpha-correct source-over operations"
provides:
  - "Public fixed-vector proof for the named resize-to-source-over processing route"
  - "White-box composed-pipeline resource rejection with complete budget atomicity assertions"
affects: [phase-11-verification, integ-02, portable-ops-suite]
tech-stack:
  added: []
  patterns: ["fixed public composition vectors", "complete resource-snapshot assertions around a real charged stage"]
key-files:
  created:
    - modules/mb-image/ops/processing_pipeline_test.mbt
    - modules/mb-image/ops/processing_pipeline_wbtest.mbt
  modified: []
key-decisions:
  - "The public proof uses only exported resize, conversion, composite, and strict conversion APIs."
  - "The adversarial boundary is composite work preflight after the preceding public stages have succeeded."
patterns-established:
  - "Cross-target evidence runs the verbose ops suite and checks named test execution, not merely aggregate totals."
requirements-completed: [INTEG-02]
coverage:
  - id: D1
    description: "Public PPM-compatible resize, RGB/RGBA conversion, opaque source-over, and strict RGB conversion route."
    requirement: INTEG-02
    verification:
      - kind: unit
        ref: "modules/mb-image/ops/processing_pipeline_test.mbt#public processing pipeline resize-composite opaque PPM vector"
        status: pass
    human_judgment: false
  - id: D2
    description: "Composed pipeline resource failure returns its typed error without any budget mutation."
    requirement: INTEG-02
    verification:
      - kind: unit
        ref: "modules/mb-image/ops/processing_pipeline_wbtest.mbt#processing pipeline insufficient resource leaves budget unchanged"
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-07-20
status: complete
---

# Phase 11 Plan 02: Portable Processing Pipeline Evidence Summary

**The public resize-to-opaque-source-over pipeline and its atomic composite budget failure are directly exercised on all four portable targets.**

## Performance

- **Duration:** 14 min
- **Completed:** 2026-07-20
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added a public fixed-vector test that composes nearest resize, RGB/RGBA conversion, source-over, and strict RGB conversion, asserting the 2×1 `0c 22 38` result and operand order.
- Added a public capability-boundary assertion for an incompatible conversion input.
- Added a white-box composed-route test that reaches composite work preflight and verifies category, code, operation, context, and every budget resource field is unchanged.

## Task Commits

1. **Task 1: Add public fixed-vector evidence for the composed processing route** — `e72a7e4`
2. **Task 2: Add adversarial pipeline budget-atomicity coverage** — `f41abc3`

## Files Created/Modified

- `modules/mb-image/ops/processing_pipeline_test.mbt` — Public fixed-vector composition and capability-boundary tests.
- `modules/mb-image/ops/processing_pipeline_wbtest.mbt` — Adversarial composite work-limit and complete budget-snapshot test.

## Decisions Made

- Used opaque TopLeft built-in-sRGB RGB test images so the documented conversion and composite contracts are satisfied without bypassing public APIs.
- Chose the composite output-work preflight as the resource boundary, preserving evidence that the earlier public stages compose successfully.

## Verification

- `moon test modules/mb-image/ops --target js --frozen -v` — 38 passed; both new test names listed.
- `moon test modules/mb-image/ops --target wasm --frozen -v` — 38 passed; both new test names listed.
- `moon test modules/mb-image/ops --target wasm-gc --frozen -v` — 38 passed; both new test names listed.
- `moon test modules/mb-image/ops --target native --frozen -v` — 38 passed; both new test names listed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added a white-box-local compatible RGB image helper**
- **Found during:** Task 2
- **Issue:** White-box test compilation does not expose black-box `resize_convert_image`, so the planned composed setup could not construct its RGB inputs.
- **Fix:** Added a small local owned-RGB fixture helper using existing model/storage contracts; it is test-only and does not add production behavior.
- **Files modified:** `modules/mb-image/ops/processing_pipeline_wbtest.mbt`
- **Verification:** All four verbose target suites pass and list the new white-box test.
- **Commit:** `f41abc3`

**Total deviations:** 1 auto-fixed blocking issue.

## Known Stubs

None.

## Next Phase Readiness

Phase verification can use the named public and adversarial pipeline tests as explicit four-target INTEG-02 evidence.

## Self-Check: PASSED

- Confirmed both planned test files exist and commits `e72a7e4` and `f41abc3` are present in git history.
