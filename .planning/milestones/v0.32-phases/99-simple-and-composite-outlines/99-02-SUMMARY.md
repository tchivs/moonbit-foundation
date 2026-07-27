---
phase: 99-simple-and-composite-outlines
plan: 02
subsystem: font-outline
tags: [moonbit, truetype, glyf, composite, q15, path2]

requires:
  - phase: 99-simple-and-composite-outlines
    plan: 01
    provides: Guarded public Font::outline transaction and exact simple-glyph Q15 lowering
provides:
  - Bounded one-level composite outline extraction through the unchanged public Font::outline query
  - Iterative tri-color descriptor graph classification with cycle-before-capability precedence
  - Exact F2DOT14 Q15 transforms, XY offsets, and real-point attachment
  - Stable composite Data, Capability, Resource, and State failure evidence
affects: [99-03-interface-closure, phase-100-font-qualification]

tech-stack:
  added: []
  patterns:
    - Shared admitted loca/glyf glyph-window helper
    - Private exact-Q15 composite graph and placement pipeline
    - Full graph validation before one-level geometry publication

key-files:
  created: []
  modified:
    - modules/mb-font/font/outline.mbt
    - modules/mb-font/font/metrics.mbt
    - modules/mb-font/font/generated_fonts_wbtest.mbt
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt

key-decisions:
  - "Classify every reachable composite descriptor with an explicit tri-color stack before returning nested-composite or grid-rounding Capability."
  - "Keep serialized F2DOT14 coefficients, transformed points, XY offsets, and point-attachment translations in checked Int64 Q15 until final Path2 construction."
  - "Use one admitted table-local glyph-window helper for metrics, root outlines, and component lookup."

patterns-established:
  - "Composite traversal: validate graph structure and cycles first, then lower only direct simple or empty children."
  - "Real-point placement: transform encoded child points before attachment; implied contour midpoints never enter component numbering."
  - "Transactional publication: accumulate private points/endpoints and construct one Path2 only after all graph, arithmetic, limit, budget, and revision checks pass."

requirements-completed: [FONT-03]

coverage:
  - id: D1
    description: Exact one-level composite placement supports signed XY, real-point attachment, uniform, independent-axis, and 2x2 transforms in component order.
    requirement: FONT-03
    verification:
      - kind: integration
        ref: "modules/mb-font/font/font_test.mbt#outline preserves component order and attaches transformed real points"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/font_wbtest.mbt#outline Q15 matrix order and signed attachment subtraction are exact"
        status: pass
    human_judgment: false
  - id: D2
    description: Reachable cycles and malformed composites are Data while fully validated deeper graphs, phantom attachment, and grid rounding are Capability.
    requirement: FONT-03
    verification:
      - kind: integration
        ref: "modules/mb-font/font/font_test.mbt#outline composite graph and flag taxonomy is stable"
        status: pass
      - kind: integration
        ref: "modules/mb-font/font/font_test.mbt#outline composite phantom malformed and resource outcomes are distinct"
        status: pass
    human_judgment: false
  - id: D3
    description: Composite extraction remains independently budgeted, mutation guarded, metrics neutral, and atomically published.
    requirement: FONT-03
    verification:
      - kind: integration
        ref: "modules/mb-font/font/font_test.mbt#outline overlap and unique metrics flags are geometry and metric neutral"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/font_wbtest.mbt#composite outline rejects post-decode revision drift without publication"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test font --target native --frozen --target-dir target/phase99-composite-package-final --no-parallelize (85/85)"
        status: pass
    human_judgment: false

duration: 17min
completed: 2026-07-27
status: complete
---

# Phase 99 Plan 02: Bounded Composite Outlines Summary

**Exact one-level TrueType composite Path2 extraction with iterative cycle classification, checked Q15 transforms, real-point attachment, and transactional resource guards**

## Performance

- **Duration:** 17 min
- **Started:** 2026-07-27T10:32:38Z
- **Completed:** 2026-07-27T10:49:32Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Extended the unchanged `Font::outline` transaction from simple glyphs to ordered one-level composites over direct simple or empty children.
- Added exact uniform, independent-axis, and general 2x2 F2DOT14 transforms plus scaled, unscaled, default XY offsets and transformed-child real-point attachment.
- Added iterative tri-color traversal that validates reachable descriptors, reports cycles as Data, and reports only fully validated deeper acyclic graphs as Capability.
- Froze phantom, reserved-flag, duplicate `USE_MY_METRICS`, component/maxp/limit/work/Budget, and post-decode mutation outcomes with generated checksum-correct fixtures.

## Task Commits

Each task was committed atomically with mandatory TDD gates:

1. **Task 1 RED: failing composite tracer** - `310316bc` (`test`)
2. **Task 1 GREEN: exact signed-XY uniform-scale tracer** - `7f5c524b` (`feat`)
3. **Task 2 RED: failing full composite matrices** - `bd775c56` (`test`)
4. **Task 2 GREEN: complete bounded composite profile** - `c21fbc3a` (`feat`)

## Files Created/Modified

- `modules/mb-font/font/metrics.mbt` - Factors admitted `loca`/`glyf` lookup into one reusable private glyph-window helper.
- `modules/mb-font/font/outline.mbt` - Implements composite descriptor parsing, iterative graph classification, checked Q15 transforms, XY and point placement, and private full-path publication.
- `modules/mb-font/font/generated_fonts_wbtest.mbt` - Adds semantic simple/composite body, descriptor, graph, `loca`, glyph-count, and `maxp` fixture builders.
- `modules/mb-font/font/font_test.mbt` - Freezes exact public commands and composite error/resource taxonomy.
- `modules/mb-font/font/font_wbtest.mbt` - Freezes matrix order, Q15 subtraction, generated placement seams, and composite mutation guards.

## Verification

- `moon -C modules/mb-font check --target native --frozen` — passed.
- Focused composite/outline gate — 20/20 tests passed.
- Full isolated native font package — 85/85 tests passed.
- Public `Font::outline(Self, GlyphId, Budget) -> Result[Path2, CoreError]` shape remains unchanged.

## Decisions Made

- Graph classification completes before unsupported-capability publication so a reachable cycle cannot be hidden by earlier nesting or grid metadata.
- Component point numbering uses only encoded real child and accumulated parent points; implied midpoints remain lowerer-only facts.
- `USE_MY_METRICS` and `OVERLAP_COMPOUND` remain geometry neutral, and admitted horizontal metrics are never replaced.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Planning state] Normalized state fields left stale by the SDK advance**

- **Found during:** Final state update
- **Issue:** The SDK advanced the human-readable position to Plan 3 and the completed-plan count to 8, but left `current_plan`, last-activity prose, the displayed plan ratio, the resolved composite-planning concern, and operator next step stale.
- **Fix:** Synchronized those fields to the completed Plan 99-02 state without changing roadmap scope.
- **Files modified:** `.planning/STATE.md`
- **Verification:** STATE frontmatter, Current Position, Session Continuity, and ROADMAP all identify 99-02 complete and 99-03 next.

**Total deviations:** 1 auto-fixed (1 planning-state consistency bug).
**Impact on plan:** No implementation scope change; this only keeps the canonical GSD state internally consistent.

## Issues Encountered

- The codebase-memory graph did not contain the newly added Phase 99 MoonBit symbols, so discovery fell back to the plan-specified source files under the repository's documented fallback rule.

## Known Stubs

None.

## TDD Gate Compliance

- Task 1 RED `310316bc` precedes GREEN `7f5c524b`.
- Task 2 RED `bd775c56` precedes GREEN `c21fbc3a`.
- Both failing gates failed before implementation and both final focused/full native gates pass.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 99-03 can qualify the unchanged interface, four portable targets, policy surface, and bilingual documentation.
- Nested geometry lowering, phantom synthesis, grid fitting, hinting, rasterization, and Phase 100 real-font qualification remain deliberately out of scope.

## Self-Check: PASSED

- All five modified implementation/test files and this summary exist.
- All four recorded TDD task commits resolve in repository history.
- No new public symbol was introduced in the outline or glyph-window implementation.

---
*Phase: 99-simple-and-composite-outlines*
*Completed: 2026-07-27*
