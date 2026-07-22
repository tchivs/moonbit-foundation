---
gsd_state_version: 1.0
milestone: v0.16
milestone_name: Grayscale Alpha PNG
status: planning
last_updated: "2026-07-22T15:30:23.918Z"
last_activity: 2026-07-22
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-22).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Planning the next code-first milestone.

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-07-22 — Milestone v0.16 started

## Performance Metrics

**Current milestone:** v0.15 shipped with 3/3 requirements, 3/3 phases, and four-target PNG evidence.

**Recent milestone:** v0.13 shipped Phases 41-43 on 2026-07-22 with explicit Adam7 RGB8/straight-RGBA8 encoding, caller-buffered parity, and independent four-target public evidence.

## Accumulated Context

### Decisions

- [v0.9]: PNG constructor preflight is atomic: incompatible capability, geometry, output, work, and budget requests fail before eager output or caller-buffered lease exposure.
- [v0.12]: Filter strategy is explicit; legacy filter-None constructors and compressed bytes remain compatibility baselines.
- [v0.13]: Explicit Adam7 remains additive; legacy non-interlaced routes and output bytes stay frozen.
- [v0.14]: Limit output scope to existing 8-bit `ChannelOrder::Gray`, non-interlaced Gray8 PNG. Reuse the bounded preflight, filter, compression, and acknowledgement-safe replay pipeline.
- [v0.14]: Exclude palette, low-bit, 16-bit, transparency conversion, Gray Adam7, and registry/release automation from this milestone.
- [v0.15]: Preserve U16 source bytes at the Gray16 PNG wire boundary while documenting RGB8 high-byte decoder canonicalization; use the shared bounded strategy and replay path rather than a Gray16 staging path.

### Pending Todos

None.

### Blockers/Concerns

- Next scope must preserve existing PNG byte and atomicity baselines, remain MoonBit-owned and portable, and include independent four-target evidence.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | Palette/indexed encoding, Gray low-bit packing, Gray16 output, transparency conversion, and Gray8 Adam7 | deferred |
| delivery | Registry publication and release automation | deferred |
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

Last session: 2026-07-22T14:41:06.713Z
Stopped at: Phase 49 context gathered
Resume file: .planning/milestones/v0.15-phases/49-portable-gray16-public-evidence/49-CONTEXT.md

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone.
