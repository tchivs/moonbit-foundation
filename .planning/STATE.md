---
gsd_state_version: 1.0
milestone: v0.12
milestone_name: PNG Filter Optimization
current_phase: 39
current_phase_name: Bounded Filter Planning and Replay
status: planning
stopped_at: v0.12 roadmap created; Phase 38 is ready for planning
last_updated: "2026-07-22T00:43:04.242Z"
last_activity: 2026-07-22
last_activity_desc: Phase 38 complete, transitioned to Phase 39
progress:
  total_phases: 1
  completed_phases: 1
  total_plans: 1
  completed_plans: 1
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-21).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 38 — establish the explicit adaptive-filter compatibility seam while freezing legacy filter-None output.

## Current Position

Phase: 39 of 40 (Bounded Filter Planning and Replay)
Plan: Not started
Status: Ready to plan
Last activity: 2026-07-22 — Phase 38 complete, transitioned to Phase 39

## Performance Metrics

**Current milestone:** v0.12 planned: 0/TBD plans complete across 0/3 phases; 0/4 requirements completed across Phases 38-40.

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
- [Phase ?]: Retain Phase 20 structural validation as complete when the generated matrix and isolated Png lane pass; classify later decode, encode, and colour success as Phase 21-25 scope.
- [Phase ?]: Precompute exact current PNG structural outcomes and budget policy before PngDecoder execution.
- [Phase ?]: Retain immutable caller-budget assertions only for below-limit preflight resource records.
- [v0.8]: Refactor the eager PNG framing, IDAT/CRC, DEFLATE, and raster pipeline into explicit pausable MoonBit-owned state; a buffered eager wrapper is not resumable decode.
- [v0.8]: Publish decode-only `PngChunkDecoder` with caller-owned chunk input, exact consumed-byte reporting, explicit `finish()`, and sticky terminal behavior; do not change `Reader` EOF semantics.
- [v0.8]: Keep completed images private until final IDAT CRC, zlib Adler-32, IEND CRC, and explicit end-of-input validation pass.
- [Phase 26]: Route the existing eager facade through one private byte-fed machine; preserve the public `PngDecoder`/`PngEncoder` interface until Phase 27.
- [Phase 26]: Retain framing, CRC, DEFLATE, raster, Adam7, and terminal continuation state without retaining a caller `ByteView` or a complete IDAT stream.
- [Phase ?]: Publish PngChunkDecoder as a thin one-byte adapter over PngDecodeMachine; only finish transfers its private result.
- [Phase 27]: Require executable public partition/ownership/eager-parity evidence and a complete frozen EOF classifier matrix before treating PngChunkDecoder as complete.
- [Phase 27]: Preserve zero-length non-IEND type input as a private pending state so strict finish reports png-iend-type deterministically.
- [Phase ?]: Phase 28 proves PngChunkDecoder only through public empty-one-byte and ragged schedules, with a separate eager oracle for results, diagnostics, budgets, and sticky terminals.
- [Phase ?]: Phase 28 freezes a public chunk-decode to bilinear-resize to eager-PNG-encode evidence line across all four targets and keeps the quality lane scoped away from release and registry automation.
- [v0.9]: Preserve eager PNG byte and failure semantics through a private resumable MoonBit encode state machine before publishing the caller-buffered API.
- [v0.9]: Keep constructor preflight atomic: incompatible image capability, dimensions, limits, and budgets fail before any encoded output can be observed.
- [v0.9]: Prove output ownership, exact progress, hostile-capacity handling, sticky terminals, and the public chunk-decode to operation to chunk-encode workflow on js, wasm, wasm-gc, and native.
- [Phase ?]: Use Writer.write directly for the eager one-byte staging view so a Failed outcome returns the provider CoreError unchanged.
- [Phase ?]: Acknowledge a private PNG byte only after WriteOutcome::Progress(1); all other progress values are adapter errors.
- [Phase ?]: Run four portable targets as independent target-directory-isolated evidence commands instead of an aggregate target invocation.
- [v0.12]: Preserve all legacy filter-None constructors and compression-strategy bytes; adaptive filtering is explicit opt-in through eager and caller-buffered factories.
- [v0.12]: Feed bounded deterministic None/Sub/Up/Average/Paeth row selection into the existing atomic preflight and replay path, not a staged image buffer.
- [v0.12]: Treat generated RGB8/RGBA8 strict-win, hostile-capacity eager/chunk identity, and complete four-target public decode as one portable evidence boundary.

### Pending Todos

None.

### Blockers/Concerns

- Colour declarations must not silently change the image's claimed sRGB semantics.
- ICC payload handling must have independent compressed, inflated, allocation, and work bounds before image visibility.
- False resumability is a primary risk: pausing must be safe inside DEFLATE bit/tree/match, CRC, scanline, and IEND/EOF transitions, not only between buffered chunks.
- Public completion must never expose raster output before strict trailing-input and final framing validation.

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
| 260721-i66 | Add deterministic alpha-correct bilinear resize for portable RGB8 and straight-RGBA8 images with checked limits, budgets, and four-target tests | 2026-07-21 | 6411680 | Verified | [260721-i66-add-deterministic-alpha-correct-bilinear](./quick/260721-i66-add-deterministic-alpha-correct-bilinear/) |
| 260721-j94 | Extend the portable PNG public workflow to use deterministic alpha-correct bilinear resize with fixed four-target output evidence | 2026-07-21 | 76ef821 | Verified | [260721-j94-extend-the-portable-png-public-workflow-](./quick/260721-j94-extend-the-portable-png-public-workflow-/) |
| 260722-8t4 | Correct the stale PNG Dynamic replay comment and add Phase 35 requirement-completion metadata for a clean v0.11 audit | 2026-07-22 | ae4496c | Verified | [260722-8t4-correct-the-stale-png-dynamic-replay-com](./quick/260722-8t4-correct-the-stale-png-dynamic-replay-com/) |

\* The PNG quality lane and all portable tests pass; the all-package `--deny-warn` command still reports the pre-existing 26 generated/legacy unused-field diagnostics documented in the quick-task verification.
| Phase 23-png-colour-declaration-and-srgb-semantics P01 | 0h 24m | 2 tasks | 9 files |
| Phase 23-png-colour-declaration-and-srgb-semantics P02 | 0h 18m | 2 tasks | 6 files |
| Phase 24-bounded-non-srgb-and-icc-preservation P01 | 40min | 3 tasks | 9 files |
| Phase 20-png-structural-safety-gate P05 | 4min | 2 tasks | 1 files |
| Phase 21-bounded-png-decode-and-deflate P03 | 30min | 2 tasks | 2 files |
| Phase 27 P01 | 25min | 3 tasks | 6 files |
| Phase 27 P02 | gap closure | 3 tasks | 3 files |
| Phase 27 P03 | EOF matrix closure | 2 tasks | 2 files |
| Phase 28-portable-png-streaming-evidence P01 | 31min | 3 tasks | 4 files |
| Phase 29-pausable-png-encode-substrate P03 | 15min | 2 tasks | 5 files |

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| scope | cICP/HDR and full ICC colour transforms | deferred |
| scope | Public resumable PNG encoder | validated in v0.9 |
| delivery | Registry publication and release automation | deferred |
| closeout-debug | clean-diff-empty-binding | acknowledged historical record |
| closeout-debug | hosted-toolchain-setup-failure | acknowledged historical record |
| closeout-debug | initialize-boundary-parameter-contract | acknowledged historical record |
| closeout-debug | knowledge-base | acknowledged historical record |
| closeout-debug | phase08-cross-platform-intent-components | acknowledged historical record |
| closeout-debug | phase08-cross-platform-prepared-zip | acknowledged historical record |
| closeout-debug | phase08-prelive-attempt-zero-root | acknowledged historical record |
| closeout-debug | phase08-prepare-canonicalization-seam | acknowledged historical record |
| closeout-debug | phase08-r11-real-ref-mismatch | acknowledged historical record |
| closeout-debug | phase08-r12-tagbound-hosted | acknowledged historical record |
| closeout-debug | phase08-r8-prelive-import | acknowledged historical record |
| closeout-debug | phase08-r9-history-schema-debug | acknowledged historical record |
| closeout-debug | phase08-workflow-duplicate-env | acknowledged historical record |
| closeout-debug | phase08-workflow-receipt-input | acknowledged historical record |
| closeout-debug | prepare-attempt-contract-mismatch | acknowledged historical record |
| closeout-debug | r12-qualification-timeout | acknowledged historical record |
| closeout-quick-task | 260721-jyh-add-a-public-resumable-png-stream-decode | missing historical record |
| Phase 20-png-structural-safety-gate P02 | 13min | 2 tasks | 8 files |
| Phase 22-canonical-png-encode-and-portable-evidence P01 | 9min | 2 tasks | 8 files |

## Session Continuity

Last session: 2026-07-21T18:12:27.677Z
Stopped at: v0.12 roadmap created; Phase 38 is ready for planning
Resume file: None

## Operator Next Steps

- Plan Phase 38 with /gsd-plan-phase 38
