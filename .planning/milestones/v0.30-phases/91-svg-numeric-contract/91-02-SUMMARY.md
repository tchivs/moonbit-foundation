---
phase: 91-svg-numeric-contract
plan: 02
subsystem: svg-numeric-testing
tags: [moonbit, svg, numeric-validation, route-matrix, portable-testing]
requires:
  - phase: 91-svg-numeric-contract
    provides: The 65536.0 numeric envelope, route identifiers, and valid-scene ownership decisions from Plan 01.
provides:
  - Focused valid finite controls for every documented SVG scalar-ingress and derived-value route.
  - Executable preservation evidence for omitted attributes, finite singular transforms, and RFC 0008 opacity layers.
affects: [92-fail-closed-svg-parsing, svg-parser, svg-lowering, mb-canvas-layer-semantics]
tech-stack:
  added: []
  patterns: [policy route identifier comments in white-box tests, finite-boundary controls separated from future rejection coverage]
key-files:
  created: []
  modified:
    - modules/mb-svg/svg/parse_wbtest.mbt
    - modules/mb-svg/svg/scene_wbtest.mbt
    - modules/mb-svg/svg/path_data_wbtest.mbt
    - modules/mb-svg/svg/transform_wbtest.mbt
    - modules/mb-svg/svg/lower_wbtest.mbt
key-decisions:
  - "Map focused test rows directly to public SVG-NUM route identifiers while keeping finite compatibility controls separate from Phase 92 rejection assertions."
  - "Preserve the current finite scale(0), viewBox/lower, and RFC 0008 PushLayer/PopLayer behavior without production source changes."
patterns-established:
  - "Route-matrix controls assert typed successful values rather than rendered CoreError diagnostics."
  - "Valid boundary tests keep source ingress, derived arithmetic, and absent/default branches independently visible."
requirements-completed: [SVGPR-01]
coverage:
  - id: D1
    description: Focused route-identified valid controls for lexical, scene, path, transform, and paint scalar ingress.
    requirement: SVGPR-01
    verification:
      - kind: integration
        ref: moon test modules/mb-svg/svg --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Valid finite derived-route, lowerer, singular-transform, and opacity-layer preservation controls.
    requirement: SVGPR-01
    verification:
      - kind: integration
        ref: moon test modules/mb-svg/svg --target all --frozen
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-07-25
status: complete
---

# Phase 91 Plan 02: SVG Numeric Route Controls Summary

**Focused all-target SVG numeric controls now cover every documented finite ingress and derivation route while preserving existing defaults, scale(0), and RFC 0008 layer ordering.**

## Performance

- **Duration:** 12 min
- **Completed:** 2026-07-25T23:48:34+08:00
- **Tasks:** 2/2
- **Files modified:** 5

## Accomplishments

- Added route-identified boundary controls for lexical values, roots, geometry, points, dash lists, supported RGB/HSL components, and absent/default branches.
- Added source and derived controls for every supported path command family, relative coordinates, affine construction/composition, and trigonometric transforms.
- Preserved valid viewBox lowering, rounded-rectangle ratio output, 32-segment circle sampling, finite singular transforms, and nested group/element opacity layers.

## Task Commits

1. **Task 1: Add lexical and scene-family numeric route controls** — `96ec188` (`test`)
2. **Task 2: Add path, affine, derivation, and valid-lowering route controls** — `7bc552a` (`test`)

## Files Created/Modified

- `modules/mb-svg/svg/parse_wbtest.mbt` — lexical length, number-list, and viewBox finite-boundary controls.
- `modules/mb-svg/svg/scene_wbtest.mbt` — scene ingress, paint/dash/color, and absent/default branch controls.
- `modules/mb-svg/svg/path_data_wbtest.mbt` — path command-family and relative-coordinate controls.
- `modules/mb-svg/svg/transform_wbtest.mbt` — affine, trigonometric, composition, and singular-transform controls.
- `modules/mb-svg/svg/lower_wbtest.mbt` — viewBox, opacity, rounded-rect, and ellipse-sampling lower controls.

## Decisions Made

- Kept every assertion on successful typed values and booleans, avoiding CoreError rendering and preserving Phase 92 ownership of rejection behavior.
- Used the established `Affine2` tolerance form to capture current finite transform behavior without modifying production parsing.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The all-target run emitted existing non-blocking warnings, including warnings from the user-untracked `modules/mb-svg/svg/svg_bench.mbt`; that file was neither modified nor staged.

The focused skew controls capture the current finite `Affine2::skew` interpretation; potential SVG skew-semantics review is recorded in `deferred-items.md` and production behavior remains out of scope for this test-only plan.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all five focused test files and this summary exist.
- Confirmed task commits `96ec188` and `7bc552a` exist in Git history.
- Scanned the shipped test files for placeholder and stub patterns; none were found.

## Next Phase Readiness

Phase 92 can add fail-closed source and derived numeric admission checks against a complete, route-identified valid-compatibility baseline.

---
*Phase: 91-svg-numeric-contract*
*Completed: 2026-07-25*
