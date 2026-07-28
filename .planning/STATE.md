---
gsd_state_version: 1.0
milestone: v0.34
milestone_name: CFF Outline Foundation
current_phase: 105
current_phase_name: Bounded Type 2 Validation and Retained Metrics
status: planning
stopped_at: Phase 105 context gathered
last_updated: "2026-07-28T13:55:13.946Z"
last_activity: 2026-07-28
last_activity_desc: Phase 104 complete, transitioned to Phase 105
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 4
  completed_plans: 4
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-28 for v0.34).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 105 — Bounded Type 2 Validation and Retained Metrics

## Current Position

Phase: 105 of 107 (Bounded Type 2 Validation and Retained Metrics)
Plan: Not started
Status: Ready to plan
Last activity: 2026-07-28 — Phase 104 complete, transitioned to Phase 105

Progress: [██████████] 100%

## Milestone Metrics

**Completed milestone:** v0.33 shipped 3 phases, 9 plans, and 5/5 verified requirements. Final qualification passed fourteen focused gates and 152/152 package tests per target, twenty-nine evidence negatives, and four semantically equal target records.

**Previous milestone:** v0.32 shipped 16 plans across Phases 97-100 with FONT-01 through FONT-05 verified, 103/103 font tests on each supported target, and a passing hosted Required lane.

## Accumulated Context

### Decisions

- [v0.34 roadmap]: Phase 104 freezes exact CFF1 profile, bounded structural data, and one name-keyed or CID-keyed execution environment per GID before bytecode execution.
- [v0.34 roadmap]: Phase 105 owns the single deterministic Type 2 interpreter, all-glyph validation, retained conservative bounds, `hmtx` metric authority, and atomic admission.
- [v0.34 roadmap]: Phase 106 adds a cubic path sink and routes standalone and TTC/OTC CFF1 through the existing opaque `Font` contract without changing static-`glyf` behavior.
- [v0.34 roadmap]: Phase 107 closes generated, licensed, hostile, performance, compatibility, and exact four-target evidence.
- [v0.34 roadmap]: CFF2/variable execution, WOFF, shaping, hint execution, rasterization, color/bitmap glyphs, authoring, FFI, and ambient I/O remain out of scope.
- [Phase 104]: Reuse the canonical SFNT directory parser through a private static-CFF1 gate, preserving existing public TrueType admission.
- [Phase 104]: Represent CFF DICT values as exact sign/magnitude/denominator facts with named table-relative and Private-relative offset wrappers.
- [Phase 104]: Reject recognized unsupported profiles and non-Type-2 CharStrings before retaining or charging a per-GID descriptor.
- [Phase 104]: Retain closed predefined CFF1 charset and Encoding tables in private MoonBit code for deterministic bounded lookup.
- [Phase 104]: Validate every FDArray private environment before FDSelect materialization, including FDs selected by no glyph.
- [Phase 104]: Preserve Top and per-FD FontMatrix as separate structural facts for Phase 105 composition rules.
- [Phase 104]: Derive private CFF structural ceilings from the existing non-zero FontLimits contract without widening the public limits API.
- [Phase 104]: Use one deferred FontAdmissionLedger transaction for standalone and selected-collection CFF admission, committing only after revision validation.
- [Phase 104]: Keep the private outline source closed over Glyf or one complete AdmittedCff1 aggregate; public CFF-backed Font promotion remains deferred.
- [Phase 104]: Treat every decoded zero-magnitude CffNumber as the supported PaintType and StrokeWidth default. — Value-based validation preserves integer, exact-real, and normalized signed-zero equivalence without accepting any non-zero semantics.
- [Phase 104]: Reduce each completed Top DICT entry before parsing subsequent bytes. — Incremental reduction makes first-encountered capability and data outcomes deterministic while retaining one parser implementation.

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 105 planning must freeze fixed-point rounding, deterministic PRNG/reset rules, FontMatrix composition, contour closure, deprecated `endchar` policy, bounds rounding, and resource-ledger units.
- Phase 107 planning must approve immutable redistributable Latin/CJK assets, licenses/notices, parent and derivative digests, deterministic recipes, and independent pinned oracles.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| compressed containers | WOFF1/WOFF2 decode and reconstruction | deferred | v0.33 scope |
| variable outlines | CFF2 execution and variable-font instantiation | deferred | v0.34 scope |
| text/rendering | Shaping, bidi, layout, discovery/fallback, hinting, and rasterization | deferred | v0.32 scope |
| other font profiles | Color/bitmap glyphs | deferred | v0.34 scope |
| authoring | Font writing, extraction, subsetting, serialization, merging, and standalone materialization | deferred | v0.34 scope |

## Session Continuity

Last session: 2026-07-28T13:55:13.932Z
Stopped at: Phase 105 context gathered
Resume file: .planning/phases/105-bounded-type-2-validation-and-retained-metrics/105-CONTEXT.md

## Operator Next Steps

- Discuss Phase 105 and freeze deterministic Type 2 arithmetic, random, FontMatrix, bounds, resource, and termination contracts before planning.

## Performance Metrics

Historical execution metrics remain available in archived milestone roadmaps. v0.34 has completed four plans.

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 104 | 4 | - | - |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 104 P01 | 22min | 2 tasks | 7 files |
| Phase 104 P02 | 25min | 3 tasks | 5 files |
| Phase 104 P03 | 27min | 3 tasks | 10 files |
| Phase 104 P04 | 12min | 1 tasks | 3 files |
