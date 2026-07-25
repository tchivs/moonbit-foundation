---
phase: 92-fail-closed-svg-parsing
plan: "01"
subsystem: svg-parser
tags: [moonbit, svg, numeric-validation, core-error, four-target]
requires:
  - phase: 91-svg-numeric-contract
    provides: SVG numeric admission policy and inclusive 65536 scalar envelope
provides:
  - Fail-closed root, viewBox, basic geometry, and points numeric parsing
  - Stable typed CoreError fields for malformed, non-finite, and out-of-range source values
  - Public no-scene/no-drawing-list parser rejection coverage
affects: [92-02, 92-03, svg-numeric-routes]
tech-stack:
  added: []
  patterns:
    - Shared SVG numeric source-admission helper maps all source failures to stable typed CoreError fields.
    - Present numeric attributes propagate Result failures; only absent attributes select established defaults.
key-files:
  created:
    - modules/mb-svg/svg/svg_test.mbt
  modified:
    - modules/mb-svg/svg/svg.mbt
    - modules/mb-svg/svg/length.mbt
    - modules/mb-svg/svg/scene.mbt
    - modules/mb-svg/svg/parse_wbtest.mbt
    - modules/mb-svg/svg/numeric_contract_wbtest.mbt
key-decisions:
  - "Use exact svg-numeric-source, svg-numeric-nonfinite, and svg-numeric-range contexts with Data/svg CoreError fields."
  - "Retain absent-attribute defaults while returning Err for every invalid present root, geometry, or points scalar."
patterns-established:
  - "Parser ingress helpers return Result and builders propagate errors before constructing SceneNode values."
requirements-completed: [SVGPR-02]
coverage:
  - id: D1
    description: Fail-closed root, viewBox, geometry, and points source admission with stable typed errors.
    requirement: SVGPR-02
    verification:
      - kind: unit
        ref: moon test modules/mb-svg/svg --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Public rejected parse has no SceneNode or DrawingList, while inclusive boundary and finite scale(0) remain drawable.
    requirement: SVGPR-02
    verification:
      - kind: integration
        ref: modules/mb-svg/svg/svg_test.mbt#public parse rejects numeric input before a scene exists
        status: pass
      - kind: integration
        ref: modules/mb-svg/svg/svg_test.mbt#public parse keeps finite boundary and singular transform drawable
        status: pass
    human_judgment: false
duration: 4 min
completed: 2026-07-25
status: complete
---

# Phase 92 Plan 01: Fail-Closed SVG Parsing Summary

**Typed fail-closed SVG source numeric admission for root, viewBox, geometry, and points values, with public no-scene/no-drawing-list proof.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-25T17:00:44Z
- **Completed:** 2026-07-25T17:04:35Z
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added centralized SVG source numeric errors and inclusive `[-65536.0, 65536.0]` admission.
- Propagated explicit root, viewBox, basic geometry, and points failures before any `SceneNode` is constructed.
- Added white-box route controls and public parse/lower contract tests across all declared targets.

## Task Commits

1. **Task 1: Prove fail-closed root and geometry admission end to end** - `569e18f` (test), `c0f5174` (feat)
2. **Task 2: Lock the public no-scene/no-drawing-list contract** - `20b7317` (test)

## Files Created/Modified

- `modules/mb-svg/svg/svg.mbt` - stable numeric error and admission helpers.
- `modules/mb-svg/svg/length.mbt` - lexical, non-finite, range, and exact-viewBox validation.
- `modules/mb-svg/svg/scene.mbt` - Result propagation through root and basic shape construction.
- `modules/mb-svg/svg/parse_wbtest.mbt` - internal ROOT/GEOMETRY/POINTS rejection checks.
- `modules/mb-svg/svg/svg_test.mbt` - public parser error and valid parse-to-lower checks.
- `modules/mb-svg/svg/numeric_contract_wbtest.mbt` - explicit successful boundary/scale-zero tracer.

## Decisions Made

- Stable diagnostics use `Data`, `InvalidEncoding` or `InvalidRange`, operation `svg`, and the policy route contexts instead of rendered prose.
- The parser preserves defaults only for absent attributes; present invalid values fail before a usable scene is returned.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Existing compiler warnings outside this plan's files remain unchanged.

## User Setup Required

None - no external service configuration required.

## Verification

`moon test modules/mb-svg/svg --target all --frozen` passed: 95 tests on js, wasm, wasm-gc, and native.

## Next Phase Readiness

The shared source-admission seam and public error contract are ready for the remaining numeric ingress and derived-arithmetic routes.

## Self-Check: PASSED

- Confirmed all six key source/test files exist.
- Confirmed task commits `569e18f`, `c0f5174`, and `20b7317` exist.
