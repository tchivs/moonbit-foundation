---
phase: 105-bounded-type-2-validation-and-retained-metrics
plan: "03"
subsystem: font-cff-type2
tags: [moonbit, cff1, type2, geometry, bounds, fixed-point]
requires:
  - phase: 105-02
    provides: bounded Type 2 VM, exact arithmetic, and per-GID environments
provides:
  - checked lowering for every supported Type 2 line, curve, and flex operator
  - exact-matrix conservative GlyphBoundsFacts with outward rounding
  - ascending all-GID staging with aggregate VM/geometry charge and no budget commit
affects: [105-04, 106-cff-outline-publication]
tech-stack:
  added: []
  patterns:
    - snapshot-before-mutation geometry sink
    - exact rational transform before integer bound rounding
    - preflight-only all-GID staged transaction
key-files:
  created:
    - modules/mb-font/font/cff_type2_bounds.mbt
  modified:
    - modules/mb-font/font/cff_type2.mbt
    - modules/mb-font/font/cff_type2_wbtest.mbt
    - modules/mb-font/font/cff_type2_bounds_wbtest.mbt
    - modules/mb-font/font/cff_type2_fixture_wbtest.mbt
key-decisions:
  - "Retain only one optional compact GlyphBoundsFacts slot per GID; no Path2 or command stream is retained."
  - "Charge transformed control-hull work as geometry points plus commands, alongside the exact VM execution ledger."
  - "All-GID staging preflights retained and aggregate authority but deliberately leaves caller and ancestor budgets unchanged."
metrics:
  duration: 41m
  completed: 2026-07-28
  tasks: 3
  files: 5
status: complete
---

# Phase 105 Plan 03: Type 2 Geometry and Retained Bounds Summary

One checked VM now lowers every supported Type 2 path form into exact transformed conservative bounds and stages complete ascending all-GID facts without publishing geometry or committing budget.

## Performance

- **Duration:** 41 minutes
- **Tasks:** 3
- **Files changed:** 5
- **Native test total:** 1237 passed

## Accomplishments

- Added atomic contour, line, and cubic lowering for all ordinary Type 2 path operators, including alternating and optional-argument forms.
- Lowered `flex`, `hflex`, `hflex1`, and `flex1` to exactly two cubics through the same bounds sink.
- Applied Top and optional FD matrices exactly before outward floor/ceil finalization; empty and moveto-only glyphs retain `None`.
- Added ascending all-GID staging over Phase 104 descriptors with fresh stack, transient, frames, PRNG, and geometry per glyph.
- Aggregated exact named execution and geometry facts, preflighted the compact bounds array and final resource charge, and committed no caller budget.

## Task Commits

1. **Task 1 RED: ordinary geometry behavior** - `7e468c3a`
2. **Task 1 GREEN: checked contour, line, and cubic lowering** - `9b9adc8b`
3. **Task 2 RED: flex and transformed-bounds behavior** - `ed710618`
4. **Task 2 GREEN: flex lowering and conservative bounds** - `71e9fa37`
5. **Task 3 RED: all-GID staging behavior** - `6bfbf176`
6. **Task 3 GREEN: ascending staged execution and charge** - `634a5a0c`

## Files Created/Modified

- `modules/mb-font/font/cff_type2_bounds.mbt` - fixed-point staged geometry sink, matrix hull, and compact bounds finalization.
- `modules/mb-font/font/cff_type2.mbt` - ordinary/flex dispatch, transformed per-glyph execution, and all-GID staging ledger.
- `modules/mb-font/font/cff_type2_wbtest.mbt` - ordinary geometry helper coverage.
- `modules/mb-font/font/cff_type2_bounds_wbtest.mbt` - hand-derived operator, flex, transform, rounding, empty, overflow, and ceiling fixtures.
- `modules/mb-font/font/cff_type2_fixture_wbtest.mbt` - ascending traversal, fresh state, PRNG reset, first failure, exact charge, and unchanged-budget fixtures.

## Decisions Made

- Bounds use the transformed endpoint/control-point hull, not target-dependent cubic extrema.
- A new moveto closes an open contour and legal endchar closes the final contour, with Move/Line/Curve/Close accounting fixed before mutation.
- The compact bounds slot is charged as 24 bytes per GID; per-glyph fixed scratch allocations and the largest retained/scratch allocation are reported separately.
- Aggregate work is checked against the phase-wide Type 2 work ceiling before staged facts can escape.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected width-sensitive invalid-arity fixtures**

- **Found during:** Task 1 RED/GREEN verification
- **Issue:** An initial moveto extra operand is a legal optional width, so the first invalid-arity fixture exercised a valid program.
- **Fix:** Moved invalid residual-argument coverage after width resolution, where the same arity is unambiguously malformed.
- **Files modified:** `modules/mb-font/font/cff_type2_bounds_wbtest.mbt`
- **Commit:** `9b9adc8b`

## Verification

- `moon test modules/mb-font/font --target native -j 2` — 228 passed.
- `moon test --target native -j 2` — 1237 passed.
- `moon check --target native` — completed with 0 errors.

## Known Stubs

None.

## Deferred Issues

None.

## Next Phase Readiness

Plan 04 can combine `Type2AllGlyphResult.charge.resource` with the staged structural charge, perform the final source revision guard, commit once, and publish the complete private `AdmittedCff1`.

## Self-Check: PASSED

All five implementation/test files, this summary, and all six task commits were verified on disk.
