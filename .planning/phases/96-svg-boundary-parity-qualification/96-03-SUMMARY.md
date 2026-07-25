---
phase: 96-svg-boundary-parity-qualification
plan: 03
subsystem: svg-lowering
tags: [moonbit, svg, affine, drawing-list, numeric-safety, tdd]
requires:
  - phase: 95-shared-svg-geometry-boundary
    provides: checked affine composition and total-lowering geometry adapters
  - phase: 96-svg-boundary-parity-qualification
    provides: parser, opacity, and portable compatibility controls
provides:
  - Checked inherited-affine admission at Svg and Group lowering boundaries
  - Deterministic identity recovery for manual nested affine overflow
  - Nested Group and viewBox-to-Group portable regressions
affects: [SVGUNI-01, SVGUNI-02, SVGUNI-03, svg-lowering]
tech-stack:
  added: []
  patterns: [thread checked accumulated affine through recursive lowering, preserve stack-relative DrawOps during total recovery]
key-files:
  created: []
  modified:
    - modules/mb-svg/svg/lower.mbt
    - modules/mb-svg/svg/lower_wbtest.mbt
key-decisions:
  - "Group composition failure emits identity while descendants retain the last admitted inherited affine."
  - "Svg maps are also composed into inherited state, with identity recovery for manually invalid nested composition."
patterns-established:
  - "Total lowerer recovery: retain safe ancestor state rather than propagating an unsafe local DrawOp."
requirements-completed: [SVGUNI-01, SVGUNI-02, SVGUNI-03]
coverage:
  - id: D1
    description: "Nested Groups and viewBox-to-Group overflow recover with identity DrawOps and preserve paint/layer/pop order."
    requirement: SVGUNI-02
    verification:
      - kind: unit
        ref: "modules/mb-svg/svg/lower_wbtest.mbt#manual inherited affine recovery"
        status: pass
    human_judgment: false
  - id: D2
    description: "Checked affine traversal preserves valid Groups, parser failure boundaries, scale(0), viewBox/default, and RFC 0008 behavior on all targets."
    requirement: SVGUNI-03
    verification:
      - kind: integration
        ref: "moon test modules/mb-svg/svg --target all --frozen"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-07-26
status: complete
---

# Phase 96 Plan 03: Group Affine Gap Closure Summary

**SVG lowering now admits every inherited Svg and Group affine through the shared checked seam, recovering manual effective overflow with identity DrawOps while preserving deterministic paint and layer order.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-07-26T06:47:00+08:00
- **Completed:** 2026-07-26T06:55:43+08:00
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added RED regressions for nested `translate(65536)` plus `translate(1)` and for a viewBox map plus local Group scale that derives overflow.
- Threaded the checked accumulated affine from the identity root through Svg maps and Group transforms.
- Preserved valid local transforms, parser fail-closed behavior, `scale(0)`, RFC 0008 layer order, and all four portable targets.

## Task Commits

1. **Task 1: Write failing inherited-affine recovery regressions** — `b70b9d4` (test)
2. **Task 2: Thread checked inherited affine through Svg and Group lowering** — `3bb4ae0` (feat)

## Files Created/Modified

- `modules/mb-svg/svg/lower_wbtest.mbt` — deterministic nested-affine, viewBox-boundary, valid-control, and DrawOp-order regressions.
- `modules/mb-svg/svg/lower.mbt` — private inherited-affine traversal and identity recovery.

## Decisions Made

- At a failed Group composition, emit identity and traverse descendants with the already admitted current affine; this keeps DrawingList transforms stack-relative and prevents unsafe effective state.
- Apply the same checked-state threading at every Svg boundary so a valid viewBox map cannot bypass accumulated admission.

## Verification

- RED confirmed: `moon test modules/mb-svg/svg --target native --frozen` failed before production changes because the inner Group still emitted `translate(1)`.
- GREEN passed: `moon test modules/mb-svg/svg --target native --frozen` — 137/137.
- Acceptance passed: `moon test modules/mb-svg/svg --target all --frozen` — 137/137 on wasm, wasm-gc, js, and native.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Issues Encountered

None. Existing deprecation and unused-helper warnings remain outside this plan's scope.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The audited Group-affine bypass is closed with portable regression evidence. No blocker remains for the Phase 96 gap closure.

## Self-Check: PASSED

- Confirmed the summary and both modified SVG files exist.
- Confirmed task commits `b70b9d4` and `3bb4ae0` exist in git history.

---
*Phase: 96-svg-boundary-parity-qualification*
*Completed: 2026-07-26*
