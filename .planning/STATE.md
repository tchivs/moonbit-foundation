---
gsd_state_version: 1.0
milestone: v0.15
milestone_name: Gray16 PNG Interchange
current_phase: 47
status: completed
stopped_at: Phase 48 context gathered
last_updated: "2026-07-22T12:49:20.189Z"
last_activity: 2026-07-22
last_activity_desc: Phase 47 marked complete
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 1
  completed_plans: 1
  percent: 33
current_phase_name: Gray16 Factory Compatibility
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-22).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 47 — Gray16 Factory Compatibility

## Current Position

Phase: 47 — COMPLETE
Plan: 1 of ?
Status: Phase 47 complete
Last activity: 2026-07-22 — Phase 47 marked complete

## Performance Metrics

**Current milestone:** 3 requirements mapped once across 3 planned phases; no plans complete.

**Recent milestone:** v0.13 shipped Phases 41-43 on 2026-07-22 with explicit Adam7 RGB8/straight-RGBA8 encoding, caller-buffered parity, and independent four-target public evidence.

## Accumulated Context

### Decisions

- [v0.9]: PNG constructor preflight is atomic: incompatible capability, geometry, output, work, and budget requests fail before eager output or caller-buffered lease exposure.
- [v0.12]: Filter strategy is explicit; legacy filter-None constructors and compressed bytes remain compatibility baselines.
- [v0.13]: Explicit Adam7 remains additive; legacy non-interlaced routes and output bytes stay frozen.
- [v0.14]: Limit output scope to existing 8-bit `ChannelOrder::Gray`, non-interlaced Gray8 PNG. Reuse the bounded preflight, filter, compression, and acknowledgement-safe replay pipeline.
- [v0.14]: Exclude palette, low-bit, 16-bit, transparency conversion, Gray Adam7, and registry/release automation from this milestone.

### Pending Todos

None.

### Blockers/Concerns

- Preserve RGB8 and straight-RGBA8 public output and failure behavior exactly.
- Keep Gray8 construction and replay within existing declared resource limits; do not introduce image-sized staging.
- Four-target evidence must use separate js, wasm, wasm-gc, and native runs.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | Palette/indexed encoding, Gray low-bit packing, Gray16 output, transparency conversion, and Gray8 Adam7 | deferred |
| delivery | Registry publication and release automation | deferred |
| scope | cICP/HDR and full ICC colour transforms | deferred |

## Session Continuity

Last session: 2026-07-22T12:49:20.168Z
Stopped at: Phase 48 context gathered
Resume file: .planning/phases/48-bounded-gray16-encoder-path/48-CONTEXT.md

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
