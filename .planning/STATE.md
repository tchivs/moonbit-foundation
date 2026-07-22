---
gsd_state_version: 1.0
milestone: v0.18
milestone_name: GrayAlpha16 Adam7 PNG
status: planning
stopped_at: Milestone initialized; roadmap pending
last_updated: "2026-07-23T00:00:00+08:00"
last_activity: 2026-07-23
last_activity_desc: Initialized v0.18 GrayAlpha16 Adam7 PNG requirements
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
current_phase: null
current_phase_name: null
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-23).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Define and execute v0.18 GrayAlpha16 Adam7 PNG.

## Current Position

Phase: Roadmap initialization
Plan: —
Status: Planning v0.18
Last activity: 2026-07-23 — v0.18 requirements defined

## Performance Metrics

**Current milestone:** v0.18 has 3 scoped requirements; roadmap and phases are pending.

**Recent milestone:** v0.17 shipped with 4/4 requirements, 3/3 phases, 4/4 plans, 8 tasks, and 204/204 PNG tests on each supported target.

**Recent milestone:** v0.16 shipped with 5/5 requirements, 3/3 phases, and four-target GrayAlpha8 PNG evidence.

**Recent milestone:** v0.13 shipped Phases 41-43 on 2026-07-22 with explicit Adam7 RGB8/straight-RGBA8 encoding, caller-buffered parity, and independent four-target public evidence.
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 51 P01 | 4min | 2 tasks | 5 files |
| Phase 52-portable-gray-alpha-public-evidence P01 | 14min | 2 tasks | 2 files |
| Phase 53-grayalpha16-model-and-checked-storage P01 | 4min | 2 tasks | 3 files |
| Phase 54-bounded-type-4-16-encoder P01 | 14min | 2 tasks | 5 files |
| Phase 54-bounded-type-4-16-encoder P02 | 5min | 2 tasks | 1 files |
| Phase 55-portable-public-evidence P01 | 14min | 2 tasks | 2 files |

## Accumulated Context

### Decisions

- [v0.9]: PNG constructor preflight is atomic: incompatible capability, geometry, output, work, and budget requests fail before eager output or caller-buffered lease exposure.
- [v0.12]: Filter strategy is explicit; legacy filter-None constructors and compressed bytes remain compatibility baselines.
- [v0.13]: Explicit Adam7 remains additive; legacy non-interlaced routes and output bytes stay frozen.
- [v0.14]: Limit output scope to existing 8-bit `ChannelOrder::Gray`, non-interlaced Gray8 PNG. Reuse the bounded preflight, filter, compression, and acknowledgement-safe replay pipeline.
- [v0.14]: Exclude palette, low-bit, 16-bit, transparency conversion, Gray Adam7, and registry/release automation from this milestone.
- [v0.15]: Preserve U16 source bytes at the Gray16 PNG wire boundary while documenting RGB8 high-byte decoder canonicalization; use the shared bounded strategy and replay path rather than a Gray16 staging path.
- [v0.16]: Add only packed U8 Gray+Alpha with explicit straight-alpha metadata, then reuse the existing bounded PNG pipeline and prove the result publicly on all four portable targets.
- [v0.17]: Add only packed U16 Gray+Alpha with explicit straight-alpha metadata, then reuse the existing checked storage and bounded PNG pipeline; Type-4/16 wire fidelity and RGBA8 decoder canonicalization remain separate public guarantees.
- [Phase ?]: GrayAlpha8 reuses the existing profile-aware bounded preflight, filter, compression planner, and replay machine without a staging buffer.
- [Phase ?]: GrayAlpha8 admission is limited to packed U8 straight-alpha GrayAlpha with builtin encoded sRGB and top-left metadata.
- [Phase ?]: Phase 52 freezes GrayAlpha8 wire/decode behavior only through public PNG APIs and literal expected data.
- [Phase ?]: GrayAlpha8 caller-buffered evidence uses fresh encoders per schedule and asserts accepted-only lease ownership plus sticky success terminals.
- [Phase ?]: GrayAlpha16 admission is limited to packed U16 straight-alpha builtin-sRGB top-left descriptors; generic checked storage and GrayAlpha operation rejection remain unchanged.
- [Phase ?]: GrayAlpha16 reuses the existing bounded preflight, filter, compression planner, and replay machine without staging.
- [Phase ?]: Phase 53 little-endian-only GrayAlpha16 descriptor admission remains locked; Big-endian construction is rejected before PNG admission.
- [Phase ?]: GrayAlpha16 admission tests cover only legal little-endian sources; Big-endian descriptors remain rejected before PNG admission.
- [Phase ?]: GrayAlpha16 Fixed and Dynamic Adaptive replay regressions require zero-write sticky terminal failures after checked U16 mutation.
- [Phase ?]: Phase 55 separates literal GrayAlpha16 U16 wire fidelity from public RGBA8 high-byte decoder canonicalization.
- [Phase ?]: Phase 55 uses fresh encoders for zero, one-byte, and ragged GrayAlpha16 drains to prove accepted-only leases and sticky success terminals.

### Pending Todos

None.

### Blockers/Concerns

- No current code or verification blocker. The next milestone must retain the strict little-endian GrayAlpha16 descriptor boundary and frozen non-interlaced PNG bytes.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | Palette/indexed encoding, Gray low-bit packing, Gray16 output, transparency conversion, and Gray8 Adam7 | deferred |
| scope | Gray+Alpha Adam7 | deferred |
| scope | GrayAlpha16 Adam7, color conversion, palette/low-bit output, decoder model widening, and image-sized staging | deferred |
| delivery | Registry publication, release automation, and source-tree copying | deferred |
| scope | cICP/HDR and full ICC colour transforms | deferred |
| historical debug | clean-diff-empty-binding | awaiting_human_verify |
| historical debug | hosted-toolchain-setup-failure | awaiting_human_verify |
| historical debug | initialize-boundary-parameter-contract | awaiting_human_verify |
| historical debug | knowledge-base | unknown |
| historical debug | phase08-cross-platform-intent-components | awaiting_human_verify |
| historical debug | phase08-cross-platform-prepared-zip | awaiting_human_verify |
| historical debug | phase08-prelive-attempt-zero-root | awaiting_human_verify |
| historical debug | phase08-prepare-canonicalization-seam | awaiting_human_verify |
| historical debug | phase08-r11-real-ref-mismatch | awaiting_human_verify |
| historical debug | phase08-r12-tagbound-hosted | awaiting_human_verify |
| historical debug | phase08-r8-prelive-import | awaiting_human_verify |
| historical debug | phase08-r9-history-schema-debug | awaiting_human_verify |
| historical debug | phase08-workflow-duplicate-env | awaiting_human_verify |
| historical debug | phase08-workflow-receipt-input | awaiting_human_verify |
| historical debug | phase39-adaptive-mutation-route | diagnosed |
| historical debug | phase39-dynamic-ring-crash | root_cause_found |
| historical debug | phase39-png-js-conformance-stall | diagnosed |
| historical debug | prepare-attempt-contract-mismatch | awaiting_human_verify |
| historical debug | r12-qualification-timeout | resolved-incorrect |
| historical quick task | 260721-jyh-add-a-public-resumable-png-stream-decode | missing |

## Session Continuity

Last session: 2026-07-22T22:01:01.053Z
Stopped at: Completed 55-01-PLAN.md
Resume file: None

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
