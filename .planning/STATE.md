---
gsd_state_version: 1.0
milestone: v0.7
milestone_name: PNG Colour Fidelity
current_phase: 24
current_phase_name: Bounded Non-sRGB and ICC Preservation
status: planning
stopped_at: Completed 24-01-PLAN.md
last_updated: "2026-07-21T02:09:21.491Z"
last_activity: 2026-07-21
last_activity_desc: Phase 23 complete, transitioned to Phase 24
progress:
  total_phases: 17
  completed_phases: 4
  total_plans: 9
  completed_plans: 7
  percent: 24
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-20).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 23 — PNG Colour Declaration and sRGB Semantics.

## Current Position

Phase: 24 of 25 (Bounded Non-sRGB and ICC Preservation)
Plan: Not started
Status: Ready to plan
Last activity: 2026-07-21 — Phase 23 complete, transitioned to Phase 24

Progress: [████████░░] 78%

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
- [v0.7]: Preserve validated PNG colour declarations before transforming pixels; only confirmed sRGB may enter existing reference operations.
- [Phase ?]: Generated PNG colour fixtures independently validate CRC, order, grammar, sRGB metadata intent, and non-sRGB capability boundaries.
- [Phase ?]: Fixed-size PNG colour chunks are rejected from their headers before payload reads; iCCP remains on its streaming envelope path.
- [Phase ?]: Generated 2 GiB fixed-colour hostile cases end at the chunk type to prove pre-payload rejection.
- [Phase ?]: Retained non-sRGB PNG declarations use opaque profiles and a non-encoded-sRGB identity.

### Pending Todos

None.

### Blockers/Concerns

- Colour declarations must not silently change the image's claimed sRGB semantics.
- ICC payload handling must have independent compressed, inflated, allocation, and work bounds before image visibility.

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260721-37p | Decode non-interlaced 8-bit grayscale PNG as RGB8 with complete filter, resource-boundary, and four-target tests | 2026-07-21 | 51dc49e | Verified | [260721-37p-validate-decode-non-interlaced-8-bit-gra](./quick/260721-37p-validate-decode-non-interlaced-8-bit-gra/) |
| 260721-3xb | Decode non-interlaced 8-bit indexed PNG with validated PLTE as RGB8 under bounded filters and budgets | 2026-07-21 | acd83dc | Verified | [260721-3xb-validate-decode-non-interlaced-8-bit-ind](./quick/260721-3xb-validate-decode-non-interlaced-8-bit-ind/) |
| 260721-4vk | Decode PNG tRNS transparency for grayscale, RGB, and indexed PLTE into bounded RGBA8 | 2026-07-21 | 21e5556 | Verified | [260721-4vk-validate-decode-png-trns-transparency-fo](./quick/260721-4vk-validate-decode-png-trns-transparency-fo/) |
| 260721-5j4 | Decode non-interlaced low-bit-depth grayscale PNG with packed filters and tRNS into RGB8/RGBA8 | 2026-07-21 | a2a22e1 | Verified | [260721-5j4-validate-decode-non-interlaced-low-bit-d](./quick/260721-5j4-validate-decode-non-interlaced-low-bit-d/) |
| 260721-661 | Decode non-interlaced low-bit-depth indexed PNG with PLTE/tRNS into RGB8/RGBA8 | 2026-07-21 | e956784 | Verified | [260721-661-implement-bounded-non-interlaced-low-bit](./quick/260721-661-implement-bounded-non-interlaced-low-bit/) |
| 260721-6k0 | Decode non-interlaced 8-bit grayscale-alpha PNG into straight RGBA8 with split-IDAT failure equivalence evidence | 2026-07-21 | 289a4e6 | Verified | [260721-6k0-implement-bounded-non-interlaced-8-bit-g](./quick/260721-6k0-implement-bounded-non-interlaced-8-bit-g/) |
| 260721-7d5 | Decode non-interlaced 16-bit grayscale and truecolour PNG into RGB8/RGBA8 with raw tRNS matching | 2026-07-21 | 8e11370 | Verified | [260721-7d5-implement-bounded-non-interlaced-16-bit-](./quick/260721-7d5-implement-bounded-non-interlaced-16-bit-/) |
| 260721-81r | Decode non-interlaced 16-bit grayscale-alpha and RGBA PNG into straight RGBA8 | 2026-07-21 | a451101 | Verified | [260721-81r-implement-bounded-non-interlaced-16-bit-](./quick/260721-81r-implement-bounded-non-interlaced-16-bit-/) |
| 260721-8nz | Decode bounded Adam7 PNG across all supported profiles with independent split-boundary evidence | 2026-07-21 | e9669ef | Verified* | [260721-8nz-implement-bounded-adam7-interlaced-png-d](./quick/260721-8nz-implement-bounded-adam7-interlaced-png-d/) |

\* The PNG quality lane and all portable tests pass; the all-package `--deny-warn` command still reports the pre-existing 26 generated/legacy unused-field diagnostics documented in the quick-task verification.
| Phase 23-png-colour-declaration-and-srgb-semantics P01 | 0h 24m | 2 tasks | 9 files |
| Phase 23-png-colour-declaration-and-srgb-semantics P02 | 0h 18m | 2 tasks | 6 files |
| Phase 24-bounded-non-srgb-and-icc-preservation P01 | 40min | 3 tasks | 9 files |

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | cICP/HDR and full ICC colour transforms | deferred |
| scope | Public resumable PNG streaming API | deferred |
| delivery | Registry publication and release automation | deferred |
| Phase 20-png-structural-safety-gate P02 | 13min | 2 tasks | 8 files |
| Phase 22-canonical-png-encode-and-portable-evidence P01 | 9min | 2 tasks | 8 files |

## Session Continuity

Last session: 2026-07-21T02:09:21.476Z
Stopped at: Completed 24-01-PLAN.md
Resume file: None
