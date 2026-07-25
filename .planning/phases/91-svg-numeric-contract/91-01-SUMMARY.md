---
phase: 91-svg-numeric-contract
plan: 01
subsystem: svg-numeric-policy
tags: [moonbit, svg, numeric-validation, coreerror, portable-testing]
requires:
  - phase: 91-svg-numeric-contract
    provides: Phase context, researched numeric seams, and the SVG/canvas ownership decisions D-01 through D-06.
provides:
  - Public target-neutral SVG scalar-admission policy with an inclusive 65536.0 envelope.
  - Stable CoreError field contract and source/derived route matrix for Phase 92 enforcement.
  - Four-target parse-to-lower tracer covering inclusive coordinates and finite singular transforms.
affects: [91-02-svg-numeric-enforcement, svg-parser, svg-lowering, mb-canvas-layer-semantics]
tech-stack:
  added: []
  patterns: [policy-backed package-local white-box tracer, route identifiers for future numeric admission checks]
key-files:
  created:
    - docs/policies/svg-numeric-admission.md
    - modules/mb-svg/svg/numeric_contract_wbtest.mbt
  modified: []
key-decisions:
  - "Anchor SVG_NUMERIC_LIMIT at the existing 65536 resource width/height ceiling rather than an arbitrary Double maximum."
  - "Treat finite singular transforms such as scale(0) as valid; determinant zero is not numeric unsafety."
  - "Reserve behavior-changing explicit-value rejection assertions for Phase 92 while Phase 91 proves valid boundary preservation."
patterns-established:
  - "Numeric policies document source and derived routes separately and identify the exact future admission point."
  - "SVG compatibility uses CoreError category, code, operation, and context rather than rendered diagnostic prose."
requirements-completed: [SVGPR-01]
coverage:
  - id: D1
    description: Public SVG numeric-admission policy with a stable error-field contract and complete route matrix.
    requirement: SVGPR-01
    verification:
      - kind: other
        ref: docs/policies/svg-numeric-admission.md
        status: pass
    human_judgment: false
  - id: D2
    description: Inclusive-boundary and finite-singular-transform parse-to-lower tracer on all supported targets.
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

# Phase 91 Plan 01: SVG Numeric Contract Summary

**A documented 65536.0 SVG numeric envelope, stable structured-error fields, complete ingress/derivation matrix, and four-target parse-to-lower boundary tracer.**

## Performance

- **Duration:** 12 min
- **Completed:** 2026-07-25T23:39:08+08:00
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Published the inclusive target-neutral scalar envelope and preserved the SVG-to-canvas ownership boundary.
- Added a package-local tracer proving inclusive coordinates and `scale(0)` parse and lower successfully on all portable targets.
- Defined stable `CoreError` fields and every supported source or derived numeric route for Phase 92 enforcement.

## Task Commits

1. **Task 1: Publish and run the inclusive-boundary SVG contract tracer** — `0680488` (`test`)
2. **Task 2: Complete the public route matrix and stable error-field contract** — `39404d3` (`docs`)

## Files Created/Modified

- `docs/policies/svg-numeric-admission.md` — public scalar envelope, ownership, errors, and route matrix.
- `modules/mb-svg/svg/numeric_contract_wbtest.mbt` — portable valid-boundary `parse_svg` → `lower_to_drawing_list` tracer.

## Decisions Made

- Derived the symmetric scalar envelope from existing SVG resource limits (`65536UL` width and height).
- Kept determinant-zero finite transforms valid and retained RFC 0008 opacity/layer ownership in canvas.
- Documented all rejection outcomes now, while assigning behavior-changing rejection tests and implementation to Phase 92.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

The required package test emitted pre-existing non-blocking warnings, including warnings from the user-untracked `modules/mb-svg/svg/svg_bench.mbt`. The test passed on all four targets, and that file was neither modified nor staged.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed the policy, tracer, and summary files exist.
- Confirmed task commits `0680488` and `39404d3` exist in Git history.
- Scanned the shipped artifacts for placeholder and stub patterns; none were found.

## Next Phase Readiness

Phase 92 can implement the documented source and derived admission routes without changing the finite-boundary, singular-transform, lowerer, or RFC 0008 layer contracts established here.

---
*Phase: 91-svg-numeric-contract*
*Completed: 2026-07-25*
