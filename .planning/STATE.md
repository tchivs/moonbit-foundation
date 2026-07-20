---
gsd_state_version: 1.0
milestone: v0.6
milestone_name: PNG Interchange
current_phase: 22
current_phase_name: Canonical PNG Encode and Portable Evidence
status: completed
stopped_at: Completed 22-01-PLAN.md
last_updated: "2026-07-20T18:13:55.960Z"
last_activity: 2026-07-21
last_activity_desc: Phase 22 complete
progress:
  total_phases: 14
  completed_phases: 2
  total_plans: 6
  completed_plans: 4
  percent: 14
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-20).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 20 — PNG Structural Safety Gate.

## Current Position

Phase: 22 of 22 (Canonical PNG Encode and Portable Evidence)
Plan: Not started
Status: Milestone complete
Last activity: 2026-07-21 — Completed quick task 260721-661: bounded low-bit indexed PNG decode

Progress: [███████░░░] 67%

## Performance Metrics

**Current milestone:** 0 plans completed across 3 planned phases.

**Historical context:** v0.5 shipped three phases and three plans on 2026-07-20. v0.2 publication and registry work remains deferred and excluded from this code-first milestone.

## Accumulated Context

### Decisions

- [v0.6]: Keep the public scope to strict eager PNG RGB/RGBA interchange; do not add public resumable PNG streaming.
- [v0.6]: Use pure-MoonBit bounded DEFLATE for stored, fixed-Huffman, and dynamic-Huffman decode; do not use FFI.
- [v0.6]: Freeze deterministic stored-DEFLATE PNG output and validate one public workflow on all four portable targets.
- [Phase ?]: Keep generated PNG fixtures package-private and run them through white-box tests to preserve PngDecoder as the sole public PNG surface.
- [Phase ?]: Phase 20 accepts complete structural RGB/RGBA transport only to return deflate-and-raster-pending; Phase 21 owns DEFLATE and image success.
- [Phase ?]: Freeze RGB8 and straight-RGBA8 PNG output as one stored-DEFLATE filter-None representation with CRC-32 and Adler-32 evidence.
- [Phase ?]: Use fixed public PNG bytes plus a target-neutral digest for four-target decode-flip-encode proof.

### Pending Todos

None.

### Blockers/Concerns

- PNG compatibility claims must remain limited to non-interlaced 8-bit truecolour RGB/RGBA and explicitly reject unsupported semantic inputs.
- Correctness depends on preserving preflight limits, CRC/Adler validation, atomic image visibility, and arbitrary IDAT-boundary handling.

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260721-37p | Decode non-interlaced 8-bit grayscale PNG as RGB8 with complete filter, resource-boundary, and four-target tests | 2026-07-21 | 51dc49e | Verified | [260721-37p-validate-decode-non-interlaced-8-bit-gra](./quick/260721-37p-validate-decode-non-interlaced-8-bit-gra/) |
| 260721-3xb | Decode non-interlaced 8-bit indexed PNG with validated PLTE as RGB8 under bounded filters and budgets | 2026-07-21 | acd83dc | Verified | [260721-3xb-validate-decode-non-interlaced-8-bit-ind](./quick/260721-3xb-validate-decode-non-interlaced-8-bit-ind/) |
| 260721-4vk | Decode PNG tRNS transparency for grayscale, RGB, and indexed PLTE into bounded RGBA8 | 2026-07-21 | 21e5556 | Verified | [260721-4vk-validate-decode-png-trns-transparency-fo](./quick/260721-4vk-validate-decode-png-trns-transparency-fo/) |
| 260721-5j4 | Decode non-interlaced low-bit-depth grayscale PNG with packed filters and tRNS into RGB8/RGBA8 | 2026-07-21 | a2a22e1 | Verified | [260721-5j4-validate-decode-non-interlaced-low-bit-d](./quick/260721-5j4-validate-decode-non-interlaced-low-bit-d/) |
| 260721-661 | Decode non-interlaced low-bit-depth indexed PNG with PLTE/tRNS into RGB8/RGBA8 | 2026-07-21 | e956784 | Verified | [260721-661-implement-bounded-non-interlaced-low-bit](./quick/260721-661-implement-bounded-non-interlaced-low-bit/) |

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | PNG palette, grayscale, transparency, 16-bit, Adam7, and colour-management support | deferred |
| scope | Public resumable PNG streaming API | deferred |
| delivery | Registry publication and release automation | deferred |
| Phase 20-png-structural-safety-gate P02 | 13min | 2 tasks | 8 files |
| Phase 22-canonical-png-encode-and-portable-evidence P01 | 9min | 2 tasks | 8 files |

## Session Continuity

Last session: 2026-07-20T18:05:40.950Z
Stopped at: Completed 22-01-PLAN.md
Resume file: None
