---
phase: 95-shared-svg-geometry-boundary
plan: 01
subsystem: svg-geometry
tags: [moonbit, svg, geometry, numeric-admission, canvas]
requires:
  - phase: v0.30
    provides: SVG numeric admission and total-lowering compatibility contracts
provides:
  - Package-private checked SVG geometry facts shared by parser preflight and lowering
  - Deterministic total-lowering recovery for manually invalid scene geometry
affects: [95-02, phase-96, svg-numeric-boundary]
tech-stack:
  added: []
  patterns: [checked package-private geometry facts, parser fail-closed with total lowering adapters]
key-files:
  created: [modules/mb-svg/svg/geometry.mbt, modules/mb-svg/svg/geometry_wbtest.mbt]
  modified: [modules/mb-svg/svg/scene.mbt, modules/mb-svg/svg/lower.mbt]
key-decisions:
  - "Apply derived coordinate admission after the accumulated affine so finite scale(0) remains compatible."
  - "Use identity or empty-path total adapters only at the public lowering boundary for manually invalid SceneNode values."
patterns-established:
  - "Shared geometry seam: parser propagates Result errors while lowerer converts the same checked facts into deterministic fallbacks."
requirements-completed: [SVGUNI-01]
coverage:
  - id: D1
    description: Parser preflight and lowerer consume shared checked viewBox, affine, primitive, and CanvasPath geometry facts.
    requirement: SVGUNI-01
    verification:
      - kind: unit
        ref: moon test modules/mb-svg/svg --target native --frozen -f '*geometry*'
        status: pass
      - kind: integration
        ref: moon test modules/mb-svg/svg --target native --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Invalid manually constructed roots and shapes lower deterministically without changing the public lowerer signature.
    requirement: SVGUNI-01
    verification:
      - kind: unit
        ref: modules/mb-svg/svg/geometry_wbtest.mbt#geometry lowering stays total for manually invalid root and rectangle
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-07-26
status: complete
---

# Phase 95 Plan 01: Shared SVG Geometry Boundary Summary

**One checked package-private SVG geometry seam now serves parser preflight and total drawing-list lowering for the supported transform, viewBox, shape, and path subset.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-26T05:38:06+08:00
- **Completed:** 2026-07-26T05:45:36+08:00
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added shared checked facts for viewBox mapping, affine composition, transformed points, all supported primitive paths, and CanvasPath conversion.
- Routed parser preflight through those facts so derived errors remain fail-closed before SceneNode publication.
- Kept `lower_to_drawing_list` total with identity/empty-path recovery for invalid manually constructed scene data, while preserving valid draw and layer behavior.

## Task Commits

1. **Task 1: Wire one checked root-transform and rectangle path** — `16217c9` (TDD RED), `ddf9dfe` (implementation)
2. **Task 2: Expand shared checked facts to all supported geometry** — `dcd73e9` (TDD RED), `b122cba` (implementation)
3. **Compatibility correction** — `ced7d2e` (preserve finite `scale(0)` admission order)

## Files Created/Modified

- `modules/mb-svg/svg/geometry.mbt` — package-private checked geometry authority.
- `modules/mb-svg/svg/geometry_wbtest.mbt` — direct seam, parser/lowerer tracer, and total-fallback controls.
- `modules/mb-svg/svg/scene.mbt` — fail-closed checked-fact consumer.
- `modules/mb-svg/svg/lower.mbt` — total checked-fact consumer and deterministic recovery adapters.

## Decisions Made

- Retained existing operation ordering: primitive path coordinates are admitted after the accumulated affine, so valid finite singular transforms such as `scale(0)` remain accepted.
- Kept paint creation and layer ordering in `lower.mbt`; geometry owns facts only.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved finite singular-transform compatibility**
- **Found during:** Task 2 verification
- **Issue:** The initial shared rectangle fact admitted local `x + width` before `scale(0)` could collapse it, rejecting an established valid SVG route.
- **Fix:** Deferred coordinate admission to the shared transformed-point route and made total lowering validate manual geometry against identity before choosing its empty-path fallback.
- **Files modified:** `modules/mb-svg/svg/geometry.mbt`, `modules/mb-svg/svg/lower.mbt`
- **Verification:** Focused suite 9/9 and native package suite 131/131 pass.
- **Committed in:** `ced7d2e`

**Total deviations:** 1 auto-fixed (Rule 1 bug).

## Issues Encountered

- The full native suite caught the singular-transform regression that the focused seam tests did not initially exercise; it was corrected before plan completion.

## Known Stubs

None.

## Next Phase Readiness

- Phase 95-02 can add portable parity qualification over the shared seam without a public API change.

## Self-Check: PASSED

- All four source/test artifacts and the summary exist.
- All five task and compatibility commits are present in git history.
