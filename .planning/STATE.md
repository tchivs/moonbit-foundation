---
gsd_state_version: 1.0
milestone: v0.4
milestone_name: Portable Image Interchange
current_phase: 15
current_phase_name: Public QOI Processing Example
status: executing
stopped_at: Phase 15 context gathered
last_updated: "2026-07-20T11:39:14.303Z"
last_activity: 2026-07-20
last_activity_desc: Phase 14 complete, transitioned to Phase 15
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 10
  completed_plans: 10
  percent: 86
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-18).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 13 — qoi-format-core-and-safe-decode

## Current Position

Phase: 15 of 15 (Public QOI Processing Example)
Plan: Not started
Status: Ready to execute
Last activity: 2026-07-20 — Phase 14 complete, transitioned to Phase 15

## Performance Metrics

**Current milestone:** 0 plans completed across 3 planned phases; plan count will be set during phase planning.

**Historical context:** v0.1 delivered five completed phases and 41 plans. v0.2 publication work is deferred without registry mutation and is excluded from v0.3 progress.

## Accumulated Context

### Decisions

- [v0.3]: Prioritize portable MoonBit image-processing capabilities over further publication automation.
- [v0.3]: Start at Phase 9; Phase 8 remains a deferred v0.2 release route.
- [Phase 9]: Centralize checked geometry and deterministic diagnostics before compositing and filters depend on them.
- [Phase 11]: Prove the finished API through public cross-target tests, one PPM pipeline example, and reproducible benchmarks; do not add release automation.
- [Phase ?]: Crop returns a fresh tightly packed OwnedImage and preserves all metadata.
- [Phase ?]: Right-angle rotation uses named APIs and normalizes physical output orientation to TopLeft.
- [Phase ?]: Nearest-neighbor remains the sole documented reference resampler; no interpolation or conversion fallback was introduced.
- [Phase ?]: Invalid alpha combinations are rejected during descriptor construction, so operation-level capability coverage uses representable unsupported layout, component, channel, and transfer variants.
- [Phase ?]: Phase 10: Raster operations use typed linear-premultiplied sRGB conversion with strict metadata compatibility before allocation.
- [v0.4]: Keep QOI as an eager whole-image-memory QOI 1.0 codec over the existing portable contracts; explicitly defer PNG/DEFLATE, FFI, streaming APIs, release automation, and performance baselines.
- [Phase 13]: Reuse the public codec limits, budgets, diagnostics, and forward-only I/O seams; probe must consume only caller-owned prefix bytes.

### Pending Todos

None.

### Blockers/Concerns

- Native verification requires the configured C toolchain; portable behavior must remain conformant on `js`, `wasm`, `wasm-gc`, and `native`.
- Registry publication, provenance closure, and all release automation remain deferred outside this milestone.
- v0.4 intentionally excludes PNG/DEFLATE, foreign-codec FFI, streaming QOI state APIs, and QOI benchmark baselines until portable codec behavior is stable.

## Deferred Items

Items acknowledged and deferred at v0.3 milestone close on 2026-07-20. They belong to the prior publication-qualification route and do not block the verified image-processing milestone.

| Category | Item | Status |
|----------|------|--------|
| debug | clean-diff-empty-binding | awaiting_human_verify |
| debug | hosted-toolchain-setup-failure | awaiting_human_verify |
| debug | initialize-boundary-parameter-contract | awaiting_human_verify |
| debug | knowledge-base | unknown |
| debug | phase08-cross-platform-intent-components | awaiting_human_verify |
| debug | phase08-cross-platform-prepared-zip | awaiting_human_verify |
| debug | phase08-prelive-attempt-zero-root | awaiting_human_verify |
| debug | phase08-prepare-canonicalization-seam | awaiting_human_verify |
| debug | phase08-r11-real-ref-mismatch | awaiting_human_verify |
| debug | phase08-r12-tagbound-hosted | awaiting_human_verify |
| debug | phase08-r8-prelive-import | awaiting_human_verify |
| debug | phase08-r9-history-schema-debug | awaiting_human_verify |
| debug | phase08-workflow-duplicate-env | awaiting_human_verify |
| debug | phase08-workflow-receipt-input | awaiting_human_verify |
| debug | prepare-attempt-contract-mismatch | awaiting_human_verify |
| debug | r12-qualification-timeout | resolved-incorrect |

## Session Continuity

Last session: 2026-07-20T11:30:59.554Z
Stopped at: Phase 15 context gathered
Resume file: .planning/phases/15-public-qoi-processing-example/15-CONTEXT.md

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 09 P01 | 18min | 2 tasks | 2 files |
| Phase 09 P02 | 20min | 2 tasks | 3 files |
| Phase 10 P01 | 22min | 3 tasks | 5 files |

## Operator Next Steps

- Plan Phase 13 with /gsd-plan-phase 13.
