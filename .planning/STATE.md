---
gsd_state_version: 1.0
milestone: v0.31
milestone_name: SVG Numeric Boundary Unification
current_phase: 96
current_phase_name: SVG Boundary Parity Qualification
status: planning
stopped_at: Phase 96 context gathered
last_updated: "2026-07-25T21:59:19.703Z"
last_activity: 2026-07-26
last_activity_desc: Phase 95 complete, transitioned to Phase 96
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
---

# Project State

## Project Reference

See `.planning/PROJECT.md`.

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 95 — Shared SVG Geometry Boundary

## Current Position

Phase: 96 — SVG Boundary Parity Qualification
Plan: Not started
Status: Ready to plan
Last activity: 2026-07-26 — Phase 95 complete, transitioned to Phase 96

## Milestone Metrics

**Current milestone:** v0.31 has 2 planned phases, 0 plans started, and all 3 scoped requirements mapped exactly once (SVGUNI-01 → 95; SVGUNI-02 → 96; SVGUNI-03 → 96).

**Previous milestone:** v0.30 shipped SVG Production Readiness across Phases 91-94; its detailed roadmap is archived at `.planning/milestones/v0.30-ROADMAP.md`.

## Accumulated Context

### Decisions

- [v0.31 roadmap]: Phase 95 consolidates parser preflight and lowering behind one internal checked seam for transforms, viewBox mapping, and shape/path coordinate derivation; it does not expand the public SVG surface.
- [v0.31 roadmap]: Phase 96 owns both fail-closed unsafe-geometry proof and target-neutral divergence controls, because qualification must exercise the shared seam delivered by Phase 95.
- [v0.31 roadmap]: Public valid SVG output, the v0.30 numeric limits and structured errors, finite singular transforms, and RFC 0008 opacity/layer semantics are compatibility controls, not new feature work.
- [Phase ?]: Shared checked SVG geometry facts preserve fail-closed parsing and total lowering recovery.
- [Phase ?]: Coordinate admission remains after the accumulated affine to preserve finite scale(0).
- [Phase ?]: Invalid manual SceneNode recovery remains a deterministic DrawingList fallback with no public error API.
- [Phase ?]: SVG compatibility is qualified through operation semantics and frozen all-target package tests, not snapshots or timing comparisons.

### Blockers/Concerns

- Keep the shared seam internal and acyclic; no new public API, numeric limit, or public error schema is in scope.
- Preserve error timing: unsafe explicit or derived geometry must fail before any scene, drawing list, or raster result can escape.
- Four-target controls must test semantic parity rather than compare timing across targets.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | SVG text, gradients, masks, filters, `<use>`, animation, broader XML/CSS, and percentage resolution | deferred |
| scope | Native acceleration, FFI, a second rasterizer, or a new numeric policy | deferred |
| delivery | Registry publication, release automation, global timing thresholds, and cross-target timing comparisons | deferred |

## Session Continuity

Last session: 2026-07-25T21:59:19.690Z
Stopped at: Phase 96 context gathered
Resume file: .planning/phases/96-svg-boundary-parity-qualification/96-CONTEXT.md

## Operator Next Steps

- Start Phase 95 planning with `/gsd-plan-phase 95`.

## Performance Metrics

No v0.31 plans have been completed.
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 95 P01 | 8min | 2 tasks | 4 files |
| Phase 95 P02 | 6min | 2 tasks | 2 files |
