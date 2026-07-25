---
gsd_state_version: 1.0
milestone: v0.31
milestone_name: SVG Numeric Boundary Unification
status: planning
last_updated: "2026-07-25T21:11:51.4414318Z"
last_activity: 2026-07-26
progress:
  total_phases: 2
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See `.planning/PROJECT.md`.

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 95 — Shared SVG Geometry Boundary

## Current Position

Phase: 95 of 96 (not started)
Plan: —
Status: Roadmap created; ready for phase planning
Last activity: 2026-07-26 — v0.31 roadmap created with complete requirement traceability

## Milestone Metrics

**Current milestone:** v0.31 has 2 planned phases, 0 plans started, and all 3 scoped requirements mapped exactly once (SVGUNI-01 → 95; SVGUNI-02 → 96; SVGUNI-03 → 96).

**Previous milestone:** v0.30 shipped SVG Production Readiness across Phases 91-94; its detailed roadmap is archived at `.planning/milestones/v0.30-ROADMAP.md`.

## Accumulated Context

### Decisions

- [v0.31 roadmap]: Phase 95 consolidates parser preflight and lowering behind one internal checked seam for transforms, viewBox mapping, and shape/path coordinate derivation; it does not expand the public SVG surface.
- [v0.31 roadmap]: Phase 96 owns both fail-closed unsafe-geometry proof and target-neutral divergence controls, because qualification must exercise the shared seam delivered by Phase 95.
- [v0.31 roadmap]: Public valid SVG output, the v0.30 numeric limits and structured errors, finite singular transforms, and RFC 0008 opacity/layer semantics are compatibility controls, not new feature work.

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

Last session: 2026-07-26
Stopped at: Created v0.31 roadmap
Resume file: `.planning/ROADMAP.md`

## Operator Next Steps

- Start Phase 95 planning with `/gsd-plan-phase 95`.

## Performance Metrics

No v0.31 plans have been completed.
