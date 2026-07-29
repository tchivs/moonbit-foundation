---
gsd_state_version: 1.0
milestone: v0.35
milestone_name: Text Shaping Foundation
status: ready_to_plan
stopped_at: Roadmap created; ready to plan Phase 108
last_updated: "2026-07-30T03:20:00+08:00"
last_activity: 2026-07-30
last_activity_desc: Created v0.35 roadmap with complete requirement coverage
progress:
  total_phases: 6
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
current_phase: 108
current_phase_name: Public Contract and Transaction Skeleton
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-30 for v0.35).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Plan Phase 108 — Public Contract and Transaction Skeleton

## Current Position

Phase: 108 of 113 (1 of 6 in v0.35)
Plan: Not planned
Status: Ready to plan
Last activity: 2026-07-30 — Created the six-phase v0.35 roadmap with 10/10 requirements mapped

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Current milestone:** 0/6 phases complete; plans are defined during phase planning.

Historical execution metrics remain in archived milestone roadmaps.

## Accumulated Context

### Decisions

- [v0.35 roadmap]: The milestone uses six risk-isolated phases, 108-113: contract, admission, GSUB, GPOS/kerning, integrated hardening, and qualification.
- [v0.35 roadmap]: `mb-text` owns explicit string-level policy and positioned runs; `mb-font` retains binary ownership behind one opaque request-scoped transaction; `mb-core` provides checked charge composition.
- [v0.35 roadmap]: The closed profile admits GSUB 1/4 and 7→1/4, GPOS 2 and 9→2, Coverage/ClassDef 1/2, GDEF 1.0 glyph classes, and the three class-ignore flags.
- [v0.35 roadmap]: Selected unsupported paths fail closed; unrelated unselected rich tables do not over-reject; complex scripts, normalization, bidi, fallback, vertical layout, variables, and production FFI remain deferred.
- [v0.35 roadmap]: Shaping stays in logical order, RTL reverses only final pen records, clusters are scalar origins, and one run-level GPOS-or-legacy kerning authority prevents double application.

### Pending Todos

None.

### Blockers/Concerns

- Phase 108 planning must freeze MoonBit continuation ergonomics, signed RTL pen deltas, empty-run charging, and the complete error-stage precedence matrix.
- Phases 109, 111, 112, and 113 require the focused research called out in ROADMAP.md; Phase 110 does not require a separate research pass.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| complex shaping | Contextual/chained, Arabic/Indic/Khmer, cursive, mark attachment, and script-specific reordering | deferred | v0.35 scope |
| Unicode/layout | Normalization, bidi analysis, segmentation, fallback, multi-font, line/paragraph, justification, and vertical layout | deferred | v0.35 scope |
| extended font formats | Variables, FeatureVariations, device positioning, WOFF/WOFF2, color/bitmap, rasterization, and hint execution | deferred | v0.35 scope |
| lifecycle/performance | Persistent caches, production FFI shapers, authoring/subsetting, and stable publication promotion | deferred | v0.35 scope |

## Session Continuity

Last session: 2026-07-30
Stopped at: Roadmap created; ready to plan Phase 108
Resume file: None

## Operator Next Steps

- Run `$gsd-plan-phase 108`.
