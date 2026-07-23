---
gsd_state_version: 1.0
milestone: v0.21
milestone_name: RGBA16 PNG Decode
status: planning
last_updated: "2026-07-23T09:09:07.233Z"
last_activity: 2026-07-23
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-23).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 62 — Explicit GrayAlpha16 Decode Contract.

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-07-23 — Milestone v0.21 started

## Performance Metrics

**Current milestone:** v0.20 has 3 scoped requirements mapped exactly once across Phases 62-64.

**Recent milestone:** v0.18 shipped with explicit GrayAlpha16 Adam7 factories, bounded streaming semantics, public portable evidence, and a four-target PNG qualification.

**Recent milestone:** v0.17 shipped with 4/4 requirements, 3/3 phases, 4/4 plans, 8 tasks, and 204/204 PNG tests on each supported target.

**Recent milestone:** v0.16 shipped with 5/5 requirements, 3/3 phases, and four-target GrayAlpha8 PNG evidence.
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 59 P01 | 14min | 1 tasks | 5 files |
| Phase 59 P02 | 18min | 2 tasks | 2 files |

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
- [v0.20]: High-precision Type-4/16 decode is explicit-only: generic eager and chunk facades remain frozen on `RGBA8(Ghi,Ghi,Ghi,Ahi)`.
- [v0.20]: The preservation result is packed little-endian `graya16`, straight alpha, and encoded-sRGB identity; sources with no colour declaration or `sRGB` are accepted, while legacy-colour and ICC declarations are rejected before allocation.
- [v0.20]: The sole decoder machine continues byte-domain filtering and Adam7 traversal; only the final profile-aware store maps `Ghi,Glo,Ahi,Alo` to `Glo,Ghi,Alo,Ahi` without staging.

### Pending Todos

- Plan Phase 62 after confirming local MoonBit API spelling and the established typed error for incompatible preservation profiles.

### Blockers/Concerns

- No current blocker. Phase 62 must retain the sRGB-only identity gate before image allocation and preserve generic decoder behavior.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | Palette/indexed encoding, Gray low-bit packing, Gray8 Adam7, broad U16 model expansion, generic decoder widening, and public high-precision conversion | deferred |
| scope | Image-sized staging buffers, alternate encoders, Big-endian changes, and native FFI | deferred |
| delivery | Registry publication, release automation, target wrappers, and source-tree copying | deferred |
| scope | cICP/HDR, non-sRGB Type-4/16 preservation, and full ICC colour transforms | deferred |

## Session Continuity

Last session: 2026-07-23T06:03:45.206Z
Stopped at: Phase 64 context gathered
Resume file: .planning/phases/64-grayalpha16-decode-qualification/64-CONTEXT.md

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
