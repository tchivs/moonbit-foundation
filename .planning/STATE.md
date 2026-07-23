---
gsd_state_version: 1.0
milestone: v0.26
milestone_name: Indexed8 Adam7 PNG Encode
current_phase: 81
current_phase_name: first of 2; planning
status: planning
stopped_at: Phase 81 context gathered
last_updated: "2026-07-23T22:29:32.196Z"
last_activity: 2026-07-24
last_activity_desc: Defined v0.26 requirements and roadmap from Indexed8 Adam7 research.
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

**Current focus:** Phase 81 — Indexed8 Adam7 Machine and Eager Wire Contract.

## Current Position

Phase: 81 (first of 2; planning)
Plan: —
Status: v0.26 roadmap ready; Phase 81 is next to plan.
Last activity: 2026-07-24 — Defined v0.26 requirements and roadmap from Indexed8 Adam7 research.

## Milestone Metrics

**Current milestone:** v0.26 has 6 scoped requirements mapped exactly once across 2 planned phases; 0/2 phases and 0 plans are complete.

**Previous milestone:** v0.25 shipped Indexed Type-3/1, /2, and /4 non-interlaced eager/chunk output through the existing machine. Its detailed history is archived at `.planning/milestones/v0.25-ROADMAP.md`.

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
- [v0.26]: Indexed Type-3/1, /2, and /4 Adam7 remains deferred until packed pass traversal has a separately proven bounded contract.

### Blockers/Concerns

- No current blocker. Verify the public spelling of the additive eager/chunk Indexed8 interlace selectors while preserving legacy method signatures.
- The 5×5 seven-pass raw-raster fixture is an independent oracle and must not be derived from production traversal helpers.
- Do not promise diagnostics-content assertions unless a stable public diagnostics query is confirmed during phase planning.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | Indexed Type-3/1, /2, and /4 Adam7 / packed pass traversal | deferred pending a separate bounded contract |
| scope | Indexed adaptive filters and Fixed/Dynamic compression selection | deferred |
| scope | Generic indexed image-model widening, palette generation, quantization, dithering, and scaling | deferred |
| implementation | Image/pass/output staging, alternate encoders, FFI, target wrappers, and copied source trees | deferred |
| delivery | Registry publication and release automation | deferred |

## Session Continuity

Last session: 2026-07-23T22:29:32.186Z
Stopped at: Phase 81 context gathered
Resume file: .planning/phases/81-indexed8-adam7-machine-and-eager-wire-contract/81-CONTEXT.md

## Operator Next Steps

- Plan Phase 81 with the v0.26 research summary and requirements as its contract.
