---
phase: 92-fail-closed-svg-parsing
plan: 03
subsystem: svg-parser
tags: [moonbit, svg, numeric-admission, path-parser, affine, geometry]
requires:
  - phase: 92-02
    provides: typed source and transform numeric admission helpers
provides:
  - Result-propagating SVG path scanner with exact smooth-command grammar
  - Parser-side derived-geometry preflight before SceneNode publication
affects: [Phase 93 SVG compatibility qualification, SVG lowering consumers]
tech-stack:
  added: []
  patterns: [fail-closed Result scanners, parser-side preflight of total lowerer arithmetic]
key-files:
  created: []
  modified:
    - modules/mb-svg/svg/path_data.mbt
    - modules/mb-svg/svg/scene.mbt
    - modules/mb-svg/svg/svg_test.mbt
    - modules/mb-svg/svg/lower_wbtest.mbt
key-decisions:
  - "Path tokens and relative/reflected results are admitted before CanvasPath mutation is exposed."
  - "parse_svg validates lowering-derived geometry before its sole successful SceneNode return; lower_to_drawing_list remains total."
patterns-established:
  - "Mirror deterministic lowering arithmetic in parser preflight and return svg-numeric-derived on unsafe intermediate or output values."
requirements-completed: [SVGPR-02]
coverage:
  - id: D1
    description: Fail-closed path grammar and smooth-command normalization
    requirement: SVGPR-02
    verification:
      - kind: unit
        ref: moon test modules/mb-svg/svg --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: No-scene parser preflight for derived SVG geometry
    requirement: SVGPR-02
    verification:
      - kind: integration
        ref: moon test modules/mb-svg/svg --target all --frozen
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-07-26
status: complete
---

# Phase 92 Plan 03: Derived SVG Geometry Preflight Summary

**Fail-closed SVG path normalization and parser-side validation of every lowering-owned geometry route before a SceneNode can escape.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-25T17:15:37Z
- **Completed:** 2026-07-25T17:24:03Z
- **Tasks:** 2/2
- **Files modified:** 7
- **Verification:** `moon test modules/mb-svg/svg --target all --frozen` — 105 passed on wasm, wasm-gc, js, and native.

## Accomplishments

- Replaced fallback path-number reads with typed Result propagation, source admission, checked relative coordinates, and exact S/s/T/t grammar with compatible reflection state.
- Added a no-DrawingList preflight at the successful parser boundary for viewBox arithmetic, affine stack composition, transformed controls, rounded rectangles, and circle/ellipse samples.
- Preserved omitted defaults, finite `scale(0)`, and existing opacity/layer lowering behavior while proving derived-invalid documents cannot reach the total lowerer.

## Task Commits

1. **Task 1: Normalize and fail-close all path command numeric routes**
   - `a833ce3` `test(92-03): add failing path admission coverage`
   - `1798f1d` `feat(92-03): fail close SVG path command parsing`
2. **Task 2: Preflight all derived scene geometry before total lowering**
   - `d686bb5` `test(92-03): add failing derived geometry coverage`
   - `4c24037` `test(92-03): cover no-lowering derived failures`
   - `e4ba9a5` `feat(92-03): preflight derived SVG scene geometry`

## Files Created/Modified

- `modules/mb-svg/svg/path_data.mbt` — checked path scanner, relative arithmetic, and smooth curves.
- `modules/mb-svg/svg/scene.mbt` — validated-scene walk before `parse_svg` returns `Ok`.
- `modules/mb-svg/svg/path_data_wbtest.mbt` — path admission and exact smooth-command regression tests.
- `modules/mb-svg/svg/svg_test.mbt` — public no-scene path and derived-geometry contracts.
- `modules/mb-svg/svg/lower_wbtest.mbt` — verifies parser failures never reach the unchanged lowerer.
- `modules/mb-svg/svg/numeric_contract_wbtest.mbt` — omitted/default, singular-transform, and opacity compatibility control.
- `modules/mb-svg/svg/scene_wbtest.mbt` — valid inclusive-boundary geometry control.

## Decisions Made

- Path scanner failures use the established typed SVG source/derived contexts rather than zero-coordinate fallback.
- The parser owns admission for parser-produced scenes; `lower_to_drawing_list` deliberately stays unchanged and total for public manually constructed `SceneNode` values.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test fixture] Corrected a former source-only boundary fixture that now derives unsafe geometry.**
- **Found during:** Task 2
- **Issue:** The Phase 91 fixture combined envelope-edge circle/ellipse geometry with a translating viewBox, producing coordinates outside the Phase 92 derived envelope.
- **Fix:** Kept inclusive scalar coverage while using an identity viewBox mapping and geometrically safe circle/ellipse positions.
- **Files modified:** `modules/mb-svg/svg/scene_wbtest.mbt`
- **Verification:** All 105 SVG tests pass on all four targets.
- **Committed in:** `e4ba9a5`

**Total deviations:** 1 auto-fixed (Rule 1 test-fixture correction).

## Known Stubs

None. The accumulator arrays found in parser code are intentional construction state, not placeholders or rendered data.

## Issues Encountered

None. Existing compiler warnings are pre-existing and unrelated to this plan.

## User Setup Required

None.

## Next Phase Readiness

Phase 93 can qualify valid SVG/lowering behavior across portable targets with the parser now serving as the complete numeric admission boundary.

## Self-Check: PASSED

- Verified all seven modified SVG source/test files and this summary exist.
- Verified task commits `a833ce3`, `1798f1d`, `d686bb5`, `4c24037`, and `e4ba9a5` exist in git history.
