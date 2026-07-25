---
phase: 92-fail-closed-svg-parsing
plan: "02"
subsystem: svg-parser
tags: [moonbit, svg, paint, color, transform, numeric-validation, four-target]
requires:
  - phase: 92-01
    provides: Shared source-admission helpers and public no-scene parser-error contract
provides:
  - Fail-closed explicit paint scalar and consumed functional-color component parsing
  - Exact-arity transform parsing with validated derived affine construction and composition
affects: [92-03, svg-numeric-routes, svg-parser]
tech-stack:
  added: []
  patterns:
    - Present SVG style values return Result failures; only absent values inherit or default.
    - Parser-owned affine construction and composition admit every derived coefficient before publication.
key-files:
  created: []
  modified:
    - modules/mb-svg/svg/color.mbt
    - modules/mb-svg/svg/scene.mbt
    - modules/mb-svg/svg/transform.mbt
    - modules/mb-svg/svg/scene_wbtest.mbt
    - modules/mb-svg/svg/transform_wbtest.mbt
    - modules/mb-svg/svg/svg_test.mbt
key-decisions:
  - "Preserve existing fallback behavior for nonnumeric unsupported color names while propagating only typed numeric functional-color failures."
  - "Reject transform arity errors as svg-numeric-source and every unsafe constructed or composed affine as svg-numeric-derived."
patterns-established:
  - "Style builders return Result and propagate errors before constructing root, group, or leaf SceneNode values."
  - "Finite determinant-zero transforms remain valid because coefficient admission does not depend on inverse availability."
requirements-completed: [SVGPR-02]
coverage:
  - id: D1
    description: Explicit paint scalars, dash entries, and consumed RGB/HSL components fail closed with stable numeric errors while omission and inheritance remain valid.
    requirement: SVGPR-02
    verification:
      - kind: integration
        ref: moon test modules/mb-svg/svg --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Exact SVG transform arity and derived affine coefficient admission reject unsafe groups, while finite scale(0) remains drawable.
    requirement: SVGPR-02
    verification:
      - kind: integration
        ref: moon test modules/mb-svg/svg --target all --frozen
        status: pass
    human_judgment: false
duration: 25 min
completed: 2026-07-26
status: complete
---

# Phase 92 Plan 02: Paint and Transform Admission Summary

**Fail-closed SVG paint/color scalar parsing and exact, derived-safe affine transform construction across all four production targets.**

## Performance

- **Duration:** 25 min
- **Completed:** 2026-07-26
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Propagated every explicit paint scalar, dash-list, and consumed RGB/HSL component failure through root, group, and leaf scene construction.
- Enforced exact SVG transform arity and admitted radians, constructed affine components, and compositions before a group can be published.
- Preserved omitted/inherited paint values, lowerer/canvas opacity ownership, and finite singular `scale(0)` parsing.

## Task Commits

1. **Task 1: Propagate paint and color scalar failures through a parsed leaf** - `dede16f` (test), `e373c3d` (feat)
2. **Task 2: Make transforms exact-arity and derived-affine safe** - `e75c486` (test), `bbc80f9` (feat)

## Files Created/Modified

- `modules/mb-svg/svg/color.mbt` - admits consumed functional-color source scalars.
- `modules/mb-svg/svg/scene.mbt` - propagates paint Result failures through all SceneNode builders.
- `modules/mb-svg/svg/transform.mbt` - validates arity plus derived affine values and compositions.
- `modules/mb-svg/svg/scene_wbtest.mbt` - covers paint rejection and inheritance control.
- `modules/mb-svg/svg/transform_wbtest.mbt` - covers transform rejection tables and singular-transform control.
- `modules/mb-svg/svg/svg_test.mbt` - proves public no-scene rejection for paint and group transforms.

## Decisions Made

- Keep legacy behavior for unsupported nonnumeric color forms; only malformed, non-finite, or out-of-envelope consumed numeric components take the fail-closed path.
- Use `svg-numeric-derived` for unsafe degree conversion, affine construction, and composition, without treating a zero determinant as unsafe.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Existing compiler warnings outside this plan's files remain unchanged.

## User Setup Required

None - no external service configuration required.

## Verification

`moon test modules/mb-svg/svg --target all --frozen` passed: 99 tests on js, wasm, wasm-gc, and native.

## Next Phase Readiness

Paint and transform numeric ingress now uses the shared typed error contract; Phase 92-03 can extend remaining derived parser/lowering routes without changing opacity ownership.

## Self-Check: PASSED

- Confirmed all six planned source/test files exist.
- Confirmed task commits `dede16f`, `e373c3d`, `e75c486`, and `bbc80f9` exist.
