---
gsd_state_version: 1.0
milestone: v0.34
milestone_name: CFF Outline Foundation
current_phase: 107
current_phase_name: Hostile, Licensed, and Four-Target Qualification
status: executing
stopped_at: Completed 106-03-PLAN.md
last_updated: "2026-07-29T01:24:04.733Z"
last_activity: 2026-07-29
last_activity_desc: Phase 106 complete, transitioned to Phase 107
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 18
  completed_plans: 12
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-28 for v0.34).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 106 — cubic-path-and-public-ttc-integration

## Current Position

Phase: 107 — Hostile, Licensed, and Four-Target Qualification
Plan: Not started
Status: Ready to execute
Last activity: 2026-07-29 — Phase 106 complete, transitioned to Phase 107

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
- [Phase 106]: Retain compact CFF bounds plus exact per-GID publishable command counts, never full paths or replay streams.
- [Phase 106]: Use one Type 2 geometry lifecycle and convert exact rational coordinates only at Point2 construction.
- [Phase 106]: Keep face-local hmtx and retained CFF bounds as metric authority while Type 2 width remains validation-only.
- [Phase 106]: Charge CFF outlines once across caller and ancestors after exact path staging and final revision validation.
- [Phase 106]: Keep public CFF outline execution on the no-op wrapper; expose only private pre-commit probes for white-box evidence.
- [Phase 106]: Run the selected CFF pre-execution probe before resource preflight and immediately guard the outer revision so State outranks Resource, Capability, and Data.
- [Phase 106]: Reuse the existing Type 2 VM read probe for mid-fetch evidence and add no post-charge seam after the sole CFF Budget commit.
- [Phase 106]: Selected CFF collection opens reuse shared admission with the collection opening revision as authoritative.
- [Phase 106]: Selected CFF capability failures preserve the established collection profile error boundary.
- [Phase 106]: Static-glyf production routing remains unchanged and is frozen by expanded deterministic evidence.

### Pending Todos

None yet.

### Blockers/Concerns

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

Last session: 2026-07-28T20:27:03.374Z
Stopped at: Completed 106-03-PLAN.md
Resume file: None

## Operator Next Steps

- Verify completed Phase 106, then plan Phase 107 hostile, licensed, performance, compatibility, and four-target qualification.

## Performance Metrics

Historical execution metrics remain available in archived milestone roadmaps. v0.34 has completed twelve plans.

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 104 | 4 | - | - |
| 105 | 5 | - | - |
| 106 | 3 | - | - |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 104 P01 | 22min | 2 tasks | 7 files |
| Phase 104 P02 | 25min | 3 tasks | 5 files |
| Phase 104 P03 | 27min | 3 tasks | 10 files |
| Phase 104 P04 | 12min | 1 tasks | 3 files |
| Phase 106 P01 | 33min | 2 tasks | 15 files |
| Phase 106 P02 | 17min | 2 tasks | 5 files |
| Phase 106 P03 | 31min | 2 tasks | 7 files |
