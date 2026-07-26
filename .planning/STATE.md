---
gsd_state_version: 1.0
milestone: v0.32
milestone_name: TrueType Font Foundation
current_phase: 97
current_phase_name: Font Admission and Metrics
status: executing
stopped_at: Completed 97-01-PLAN.md
last_updated: "2026-07-26T09:09:02.633Z"
last_activity: 2026-07-26
last_activity_desc: Phase 97 execution started
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 3
  completed_plans: 1
---

# Project State

## Project Reference

See `.planning/PROJECT.md`.

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 97 — Font Admission and Metrics

## Current Position

Phase: 97 (Font Admission and Metrics) — EXECUTING
Plan: 2 of 3
Status: Ready to execute
Last activity: 2026-07-26 — Phase 97 execution started

Progress: [███░░░░░░░] 33%

## Milestone Metrics

**Current milestone:** v0.32 has 4 planned phases, 0 plans started, and all 5 scoped requirements mapped exactly once.

**Previous milestone:** v0.31 shipped SVG Numeric Boundary Unification across Phases 95-96; its detailed roadmap is archived at `.planning/milestones/v0.31-ROADMAP.md`.

## Accumulated Context

### Decisions

- [v0.32 roadmap]: `tchivs/mb-font` remains pure MoonBit, portable, and independently publishable with `tchivs/mb-core` as its only public runtime dependency.
- [v0.32 roadmap]: Coarse granularity merges the research's simple/composite implementation slices into Phase 99 so FONT-03 has one complete verification owner.
- [v0.32 roadmap]: Phase 98 owns both deterministic cmap selection and legacy kern semantics because both query admitted glyph identities without depending on outline geometry.
- [v0.32 roadmap]: Phase 100 qualifies immutable generated and licensed real-font evidence through the public workflow on `js`, `wasm`, `wasm-gc`, and `native`.
- [Phase 97]: Font retains the caller ByteView and gates every query on the opening revision.
- [Phase 97]: Admission uses table-local ByteViews and atomically charges bytes plus work before checksum scans.
- [Phase 97]: Unsupported font profiles are capability failures while malformed admitted TrueType bytes are data failures.

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 99 planning must freeze composite point attachment, phantom-point/`USE_MY_METRICS`, offset-scaling, and F2DOT14 evaluation rules before implementation.
- Phase 100 planning must finalize licensed real-font specimen provenance, redistribution records, digests, inventories, and independent semantic facts.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| font formats | CFF/CFF2, TTC/OTC, WOFF/WOFF2, variable, color, and bitmap fonts | deferred | v0.32 scope |
| text/rendering | Shaping, bidi, layout, discovery/fallback, hinting, and rasterization | deferred | v0.32 scope |
| authoring | Font writing, editing, subsetting, and serialization | deferred | v0.32 scope |

## Session Continuity

Last session: 2026-07-26T09:09:02.615Z
Stopped at: Completed 97-01-PLAN.md
Resume file: None

## Operator Next Steps

- Run `/gsd-plan-phase 97`.

## Performance Metrics

No v0.32 plans have been completed.

**Per-Phase Metrics:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 97-100 | 0 | — | — |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 97 P01 | 39m | 3 tasks | 11 files |
