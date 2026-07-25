---
phase: 96-svg-boundary-parity-qualification
plan: 01
subsystem: testing
tags: [moonbit, svg, numeric-boundaries, parser, geometry]
requires:
  - phase: 95-shared-svg-geometry-boundary
    provides: Shared checked SVG geometry Result seam consumed by parser preflight.
provides:
  - Public structured-error evidence for every unsafe SVG geometry family before SceneNode publication.
  - Private checked-seam parity matrix without a duplicated arithmetic oracle.
affects: [96-02-total-lowerer-and-portable-qualification]
tech-stack:
  added: []
  patterns:
    - Pair parser-facing adversarial fixtures with direct package-private Result observations.
    - Use checked_path_points as the shared admission oracle for built primitive and CanvasPath forms.
key-files:
  created: []
  modified:
    - modules/mb-svg/svg/svg_test.mbt
    - modules/mb-svg/svg/geometry_wbtest.mbt
key-decisions:
  - "Parser failures remain Err(CoreError) only; no failed parser result is lowered."
  - "Geometry parity tests compose existing checked Result functions instead of reimplementing numeric formulas."
patterns-established:
  - "SVG numeric qualification: named public row plus matching checked-seam Result fact."
requirements-completed: [SVGUNI-02]
coverage:
  - id: D1
    description: Public parser rejects unsafe source-derived root, affine, primitive, point-list, and path geometry with the established structured error.
    requirement: SVGUNI-02
    verification:
      - kind: unit
        ref: moon test modules/mb-svg/svg --target native --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Package-private geometry controls observe matching derived errors while finite scale(0), compact viewBox, and omitted defaults remain valid.
    requirement: SVGUNI-02
    verification:
      - kind: unit
        ref: modules/mb-svg/svg/geometry_wbtest.mbt#geometry parity matrix observes every checked derived-geometry family
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-07-25
status: complete
---

# Phase 96 Plan 01: SVG Parser Geometry Parity Tracer Summary

**Public SVG numeric failures now have named, structured parser-boundary rows paired with direct checked-geometry Result evidence for every shared geometry family.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-25T22:21:07Z
- **Completed:** 2026-07-25T22:25:42Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Established a public parser tracer for derived viewBox rejection while retaining finite `scale(0)` lowering only after `Ok(scene)`.
- Expanded named public rows across root mapping, affine composition, all primitives, point lists, CanvasPath commands, and transformed path points.
- Added a private Result parity matrix that uses the shared checked seam rather than duplicated numeric arithmetic.

## Task Commits

1. **Task 1: Trace one unsafe derived route from exported parser rejection to its checked-seam counterpart** — `87351fe` (test)
2. **Task 2: Expand the parity matrix across every shared geometry family** — `319aab7` (test)

## Files Created/Modified

- `modules/mb-svg/svg/svg_test.mbt` — named public structured-error matrix proving parser rejection before SceneNode publication.
- `modules/mb-svg/svg/geometry_wbtest.mbt` — direct private Result controls for root, affine, primitives, points, CanvasPath, and path-point admission.

## Decisions Made

- Keep all negative parser evidence at `Err(CoreError)`; do not invoke lowering after a parser failure.
- Pair each public source family with checked seam facts and use `checked_path_points` as the shared post-construction admission check.

## Verification

- `moon test modules/mb-svg/svg --target native --frozen` — passed, 135/135 tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the tracer helper's Result type**
- **Found during:** Task 1
- **Issue:** The first helper accepted `Result[Unit, CoreError]`, but `checked_transform_point` returns a point Result.
- **Fix:** Narrowed that helper to `Result[Point2, CoreError]` and retained the same structured-error assertion.
- **Files modified:** `modules/mb-svg/svg/geometry_wbtest.mbt`
- **Verification:** `moon test modules/mb-svg/svg --target native --frozen` passed.
- **Committed in:** `87351fe`

**Total deviations:** 1 auto-fixed (Rule 1)

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed both modified test files and this summary exist.
- Confirmed task commits `87351fe` and `319aab7` exist in git history.

## Next Phase Readiness

Plan 96-02 can add manual-invalid lowerer and four-target qualification controls on top of these parser/seam parity rows.
