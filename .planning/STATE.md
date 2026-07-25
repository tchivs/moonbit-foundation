---
gsd_state_version: 1.0
milestone: v0.30
milestone_name: SVG Production Readiness
current_phase: 91
current_phase_name: SVG Numeric Contract
status: planning
stopped_at: Phase 91 context gathered
last_updated: "2026-07-25T15:07:51.061Z"
last_activity: 2026-07-25
last_activity_desc: v0.30 roadmap created; all SVGPR requirements mapped.
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

See `.planning/PROJECT.md`.

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** v0.30 SVG Production Readiness — Phase 91 SVG Numeric Contract.

## Current Position

Phase: 91 of 94 — SVG Numeric Contract
Plan: —
Status: Ready to plan
Last activity: 2026-07-25 — v0.30 roadmap created; all SVGPR requirements mapped.

Progress: [░░░░░░░░░░] 0%

## Milestone Metrics

**Current milestone:** v0.30 has 4 planned phases, 0 plans started, and all 4 scoped requirements mapped exactly once (SVGPR-01 → 91; SVGPR-02 → 92; SVGPR-03 → 93; SVGPR-04 → 94).

**Previous milestone:** v0.29 shipped Indexed Adam7 Compression Profiles; its detailed history is archived at `.planning/milestones/v0.29-ROADMAP.md`.

## Accumulated Context

### Decisions

- [v0.30 roadmap]: Phase 91 establishes the documented target-neutral numeric envelope and route-matrix evidence before parser migration.
- [v0.30 roadmap]: Phase 92 makes every explicit SVG scalar and derived path fail closed before a scene or drawing list can exist; omitted attributes retain existing defaults and finite singular transforms remain valid.
- [v0.30 roadmap]: Phase 93 is compatibility and four-target evidence for RFC 0008 isolated opacity and the existing 16-layer canvas capability, not a rendering-policy rewrite.
- [v0.30 roadmap]: Phase 94 freezes correctness-gated path-parse, transform-composition, and parse-to-lower workloads only after final semantics; native release captures are local like-for-like evidence, not cross-target performance claims.

### Blockers/Concerns

- Select the exact SVG scalar envelope from existing canvas, raster, and resource bounds during Phase 91; do not guess a generic `Double` magnitude.
- Ensure every explicit numeric ingress and derived arithmetic route propagates a stable structured SVG error; do not silently default invalid present attributes.
- Keep benchmark corpus, correctness digests, toolchain/host facts, and execution mode coupled so native comparisons cannot drift.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | SVG text, gradients, masks, filters, `<use>`, animation, broader XML/CSS, and percentage resolution | deferred |
| scope | Native acceleration, FFI, a second rasterizer, or image-sized layer-staging optimization | deferred |
| delivery | Registry publication, release automation, global timing thresholds, and cross-target timing comparisons | deferred |

## Session Continuity

Last session: 2026-07-25T15:07:51.050Z
Stopped at: Phase 91 context gathered
Resume file: .planning/phases/91-svg-numeric-contract/91-CONTEXT.md

## Operator Next Steps

- Start Phase 91 planning with `/gsd-plan-phase 91`.

## Performance Metrics

No v0.30 plans have been completed.
