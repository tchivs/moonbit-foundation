---
phase: 95-shared-svg-geometry-boundary
plan: 02
subsystem: svg-geometry-testing
tags: [moonbit, svg, drawing-list, geometry, portability, rfc-0008]
requires:
  - phase: 95-01
    provides: Package-private checked SVG geometry facts and total lowerer adapters
provides:
  - Semantic DrawOp compatibility controls for checked geometry and total lowering
  - Exported parse-to-lower regression coverage for all supported SVG shape families
  - Four-target qualification evidence for the shared geometry boundary
affects: [phase-96, svg-numeric-boundary, svg-compatibility]
tech-stack:
  added: []
  patterns: [operation-level drawing-list assertions, exported API compatibility fixtures, four-target MoonBit qualification]
key-files:
  created: []
  modified: [modules/mb-svg/svg/lower_wbtest.mbt, modules/mb-svg/svg/svg_test.mbt]
key-decisions:
  - "Keep invalid manual SceneNode recovery observable only through deterministic DrawingList operations, without a public error API."
  - "Qualify compatibility with operation semantics and the ordinary frozen all-target suite instead of snapshots or timing comparisons."
patterns-established:
  - "SVG seam regressions assert affine components, Path2 forms, and DrawOp order rather than implementation text."
requirements-completed: [SVGUNI-01]
coverage:
  - id: D1
    description: "Valid checked geometry keeps compact viewBox mapping, rounded-rectangle, ellipse, point-list, and path DrawOp forms while invalid manual scenes lower deterministically."
    requirement: SVGUNI-01
    verification:
      - kind: unit
        ref: "moon test modules/mb-svg/svg --target native --frozen -f '*lower*'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exported parse_svg and lower_to_drawing_list retain viewBox, finite scale(0), omitted defaults, and all supported shape/path families on every supported target."
    requirement: SVGUNI-01
    verification:
      - kind: integration
        ref: "moon test modules/mb-svg/svg --target all --frozen"
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-07-26
status: complete
---

# Phase 95 Plan 02: Shared SVG Geometry Boundary Compatibility Summary

**Checked SVG geometry now has semantic DrawOp and exported parse-to-lower regression coverage, qualified unchanged on wasm, wasm-gc, js, and native.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-26T05:45:40+08:00
- **Completed:** 2026-07-26T05:51:15+08:00
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added operation-level controls for compact viewBox/shape/path forms and deterministic empty-path fallback for invalid manually constructed scenes.
- Preserved RFC 0008 group/element layer ordering while directly asserting total lowerer recovery twice for identical observable output.
- Added an exported-API fixture covering root mapping, finite `scale(0)`, omitted defaults, and every supported SVG geometry family.
- Passed the frozen SVG package suite on wasm, wasm-gc, js, and native (134/134 per target).

## Task Commits

1. **Task 1: Assert deterministic total lowering and unchanged semantic operation forms** — `91f7228` (`test`)
2. **Task 2: Add public valid-SVG compatibility coverage and run the portable regression gate** — `2ea2726` (`test`)

## Files Created/Modified

- `modules/mb-svg/svg/lower_wbtest.mbt` — semantic DrawOp controls for checked map/path forms, total invalid-scene recovery, and preserved layer sequencing.
- `modules/mb-svg/svg/svg_test.mbt` — exported parser-to-lowerer fixture spanning supported valid geometry, defaults, and finite singular transforms.

## Decisions Made

- Used direct operation and `Path2` assertions to preserve observable compatibility without coupling tests to private seam implementation text.
- Reused 95-01's completed shared implementation; the new regression tests passed immediately, so no production code change was needed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The package reports existing deprecation and unused-function warnings, but all requested test commands passed; no unrelated cleanup was made.

## Known Stubs

None.

## Next Phase Readiness

- Phase 96 can use these stable public and operation-level controls to add unsafe-geometry parity qualification without changing the SVG API.

## Self-Check: PASSED

- Both modified test files and this summary exist.
- Task commits `91f7228` and `2ea2726` are present in git history.
