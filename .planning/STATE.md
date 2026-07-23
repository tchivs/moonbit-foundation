---
gsd_state_version: 1.0
milestone: v0.19
milestone_name: GrayAlpha8 Adam7 PNG
status: planning
last_updated: "2026-07-23T00:00:00Z"
last_activity: 2026-07-23
progress:
  total_phases: 3
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-23).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Plan Phase 59 — GrayAlpha8 Adam7 Factory and Pass Profile.

## Current Position

Phase: 59 of 61 (GrayAlpha8 Adam7 Factory and Pass Profile)
Plan: Not yet planned
Status: Roadmap ready; phase context is next
Last activity: 2026-07-23 — v0.19 requirements mapped to Phases 59-61

## Performance Metrics

**Current milestone:** v0.19 has 3 scoped requirements mapped exactly once across 3 planned phases.

**Recent milestone:** v0.18 shipped with explicit GrayAlpha16 Adam7 factories, bounded streaming semantics, public portable evidence, and a four-target PNG qualification.

**Recent milestone:** v0.17 shipped with 4/4 requirements, 3/3 phases, 4/4 plans, 8 tasks, and 204/204 PNG tests on each supported target.

**Recent milestone:** v0.16 shipped with 5/5 requirements, 3/3 phases, and four-target GrayAlpha8 PNG evidence.

## Accumulated Context

### Decisions

- [v0.9]: PNG constructor preflight is atomic: incompatible capability, geometry, output, work, and budget requests fail before eager output or caller-buffered lease exposure.
- [v0.12]: Filter strategy is explicit; legacy filter-None constructors and compressed bytes remain compatibility baselines.
- [v0.13]: Explicit Adam7 remains additive; legacy non-interlaced routes and output bytes stay frozen.
- [v0.16]: Packed U8 Gray+Alpha is limited to explicit straight-alpha metadata and reuses the existing bounded PNG pipeline without staging.
- [v0.18]: Type-4 Adam7 additions reuse the existing shared bounded traversal, filter, Stored/Fixed/Dynamic planning, and acknowledgement-safe replay machinery; no alternate encoder is introduced.
- [v0.19]: GrayAlpha8 Adam7 is opt-in through explicit eager and caller-buffered factories only; existing GrayAlpha8 non-interlaced selection and bytes remain frozen.
- [v0.19]: GrayAlpha8 Adam7 must retain the profile-aware single machine, pass-local filtering, atomic preflight, and pre-write mutation rejection across Stored, Fixed, and Dynamic replay.
- [v0.19]: Public proof uses literal Type-4/8 multipass wire data, established RGBA8 decode canonicalization, hostile caller schedules, frozen legacy vectors, and the ordinary all-target PNG package command.

### Pending Todos

- Plan and execute Phase 59 without broadening descriptor admission or adding a second encoder route.

### Blockers/Concerns

- No current blocker. Phase 60 must verify that Stored, Fixed, and Dynamic replay all validate source revision before the next lease write.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | Palette/indexed encoding, Gray low-bit packing, Gray8 Adam7, U16 model expansion, colour conversion, and decoder-model widening | deferred |
| scope | Image-sized staging buffers, alternate encoders, Big-endian changes, and native FFI | deferred |
| delivery | Registry publication, release automation, target wrappers, and source-tree copying | deferred |
| scope | cICP/HDR and full ICC colour transforms | deferred |

## Session Continuity

Last session: 2026-07-23
Stopped at: v0.19 roadmap created
Resume file: `.planning/ROADMAP.md`

## Operator Next Steps

- Discuss and plan Phase 59: GrayAlpha8 Adam7 Factory and Pass Profile.
