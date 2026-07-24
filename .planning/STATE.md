---
gsd_state_version: 1.0
milestone: v0.27
milestone_name: Low-Bit Indexed Adam7 PNG Encode
current_phase: 84
status: completed
stopped_at: Phase 84 context gathered
last_updated: "2026-07-24T04:16:07.029Z"
last_activity: 2026-07-24
last_activity_desc: Phase 84 complete
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 2
  completed_plans: 2
  percent: 100
current_phase_name: low-bit-indexed-adam7-streaming-qualification
---

# Project State

## Project Reference

See `.planning/PROJECT.md`.

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 84 — low-bit-indexed-adam7-streaming-qualification

## Current Position

Phase: 84
Plan: Not started
Status: All phases complete
Last activity: 2026-07-24 — Phase 84 complete

## Milestone Metrics

**Current milestone:** v0.27 has 6 scoped requirements mapped exactly once across 2 planned phases; 1/2 phases and 1 plan are complete.

**Previous milestone:** v0.26 shipped Type-3/8 Adam7 eager/chunk output through the existing acknowledged machine. Its detailed history is archived at `.planning/milestones/v0.26-ROADMAP.md`.

## Accumulated Context

### Decisions

- [v0.9]: PNG constructor preflight is atomic: incompatible capability, geometry, output, work, and budget requests fail before eager output or caller-buffered lease exposure.
- [v0.12]: Filter strategy is explicit; legacy filter-None constructors and compressed bytes remain compatibility baselines.
- [v0.13]: Explicit Adam7 remains additive; legacy non-interlaced routes and output bytes stay frozen.
- [v0.18]: Type-4 Adam7 additions reuse the existing shared bounded traversal, filtering/planning, and acknowledgement-safe replay machinery; no alternate encoder is introduced.
- [v0.19]: GrayAlpha8 Adam7 is opt-in through explicit eager and caller-buffered factories only; existing non-interlaced selection and bytes remain frozen.
- [v0.20]: High-precision preservation remains explicit-only; generic facades retain their compatibility result.
- [v0.25]: Public `PngIndexedBitDepth` selects One, Two, or Four while Indexed8 remains on its established API; low-bit indexed pixels pack directly in the acknowledged machine.
- [v0.26]: Indexed8 Adam7 is an additive Type-3/8 Stored/filter-None capability. Existing `encode_indexed8` and `new_indexed8` remain non-interlaced compatibility wrappers.
- [v0.26]: Reuse `_png_adam7_passes(width, height, 1, 8)` and scalar `PngIndexedImage::index_at` traversal inside the single machine; do not stage a pass/image raster or create a second encoder.
- [v0.26]: Indexed Type-3/1, /2, and /4 Adam7 remained deferred until packed pass traversal had a separately proven bounded contract.
- [Phase 81]: Indexed8 Adam7 is opt-in through additive eager and chunk selectors; established Indexed8 and low-bit routes explicitly retain None.
- [Phase 81]: Preflight and scalar output each consume _png_adam7_passes(width, height, 1UL, 8), without staging or an alternate encoder.
- [Phase 82]: Indexed8 Adam7 stream qualification stays test-only and exercises the existing Phase 81 selector/machine.
- [Phase 82]: Zero-capacity leases use a sentinel-backed zero-length view; recurring zero pulls preserve prior accepted totals.
- [v0.27]: Low-bit Indexed Adam7 is opt-in through the existing selected-depth eager/chunk selector families; non-interlaced Indexed1/2/4 and Indexed8 routes remain explicit `None` compatibility forwards.
- [v0.27]: Low-bit Adam7 pass facts must use `_png_adam7_passes(width, height, 1UL, depth)` in both preflight and output; each pass row packs anew from local column zero with deterministic zero tails.
- [v0.27]: Type-3/1, /2, and /4 Adam7 retains Stored DEFLATE/filter None and the sole acknowledged machine; qualification must parse collected chunk-origin bytes independently of eager parity.
- [Phase 83]: Low-bit Indexed Adam7 uses additive selected-depth eager/chunk selectors with legacy APIs explicitly forwarding None.
- [Phase 83]: Selected-depth Adam7 preflight and scalar replay share profile-depth pass geometry; no staging or second encoder is introduced.

### Blockers/Concerns

- No current blocker. Preserve the established public spelling of the selected-depth eager/chunk selector methods while making their legacy wrappers explicit `None` forwards.
- The compact all-seven-pass fixture must be non-symmetric and supplemented with odd/narrow dimensions so every selected depth has a non-byte-aligned tail; expected bytes must not call production Adam7, packer, row-byte, or preflight helpers.
- Do not promise diagnostics-content assertions unless a stable public diagnostics query is confirmed during phase planning.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | Indexed adaptive filters and Fixed/Dynamic compression selection | deferred |
| scope | Generic indexed image-model widening, packed public source format, palette generation, quantization, dithering, scaling, and decoder changes | deferred |
| implementation | Image/pass/output staging, alternate encoders, FFI, target wrappers, and copied source trees | deferred |
| delivery | Registry publication and release automation | deferred |

## Session Continuity

Last session: 2026-07-24T02:12:40.993Z
Stopped at: Phase 84 context gathered
Resume file: .planning/phases/84-low-bit-indexed-adam7-streaming-qualification/84-CONTEXT.md

## Operator Next Steps

- Plan Phase 84 with /gsd-plan-phase 84

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 81-indexed8-adam7-machine-and-eager-wire-contract P01 | 41min | 2 tasks | 5 files |
| Phase 82 P01 | 39min | 2 tasks | 1 files |
| Phase 83 P01 | 15m | 2 tasks | 5 files |
