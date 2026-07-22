# Phase 42: Bounded Adam7 Pass Encoding - Context

**Gathered:** 2026-07-22
**Status:** Ready for planning

## Phase Boundary

Replace Phase 41's typed Adam7-pending boundary with real, bounded Adam7 RGB8/RGBA8 emission. Preserve all non-interlaced bytes and public API choices; public portability evidence remains Phase 43.

## Implementation Decisions

- Reuse `_png_adam7_passes` as the only checked pass-geometry authority; do not duplicate pass formulas.
- Model all nonempty passes as one deterministic logical filtered-byte source. Each pass starts a fresh PNG filter row history; Adaptive selection never reads a row from another pass.
- Let Stored, FixedOrStored, and DynamicOrFixedOrStored planning plus acknowledgement-safe replay consume that same bounded source. No pass/image-sized token buffer, selected-row cache, or staging output is allowed.
- Extend the atomic preflight ledger with exact pass scanline/filter/compression traversals and retain existing capability, dimension, output, work, and budget rejection semantics.
- Write IHDR interlace method `1` only for the real Adam7 route; legacy None remains method `0` with frozen bytes.
- Keep public factory surface from Phase 41 unchanged; Phase 42 changes pending rejection to actual emission only for compatible RGB8/RGBA8 sources.

## Canonical References

- `.planning/ROADMAP.md` — Phase 42 success criteria.
- `.planning/REQUIREMENTS.md` — PNGI-02 and PNGI-03.
- `.planning/phases/41-adam7-opt-in-compatibility/41-CONTEXT.md` — compatibility boundary decisions.
- `modules/mb-image/png/structural.mbt` — `_png_adam7_passes` checked geometry.
- `modules/mb-image/png/encode.mbt` — existing filtered cursor, planner, and atomic ledger.
- `modules/mb-image/png/stream_encode.mbt` — machine construction and acknowledgement-safe replay.

## Deferred

- Generated public four-target Adam7 fidelity corpus and final compatibility proof remain Phase 43.
