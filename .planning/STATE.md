---
gsd_state_version: 1.0
milestone: v0.32
milestone_name: TrueType Font Foundation
current_phase: 97
current_phase_name: Font Admission and Metrics
status: verifying
stopped_at: Completed 97-03-PLAN.md
last_updated: "2026-07-27T04:31:38.913Z"
last_activity: 2026-07-27
last_activity_desc: "Completed quick task 260727-h6r: Normalize Phase 97 legacy coverage schema and close automated UAT"
progress:
  total_phases: 1
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
---

# Project State

## Project Reference

See `.planning/PROJECT.md`.

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 97 — Font Admission and Metrics

## Current Position

Phase: 97 (Font Admission and Metrics) — EXECUTING
Plan: 3 of 3
Status: Phase complete — ready for verification
Last activity: 2026-07-27 — Completed quick task 260727-h6r: Normalize Phase 97 legacy coverage schema and close automated UAT

Progress: [██████████] 100%

## Milestone Metrics

**Current milestone:** v0.32 has 4 planned phases, 0 plans started, and all 5 scoped requirements mapped exactly once.

**Previous milestone:** v0.31 shipped SVG Numeric Boundary Unification across Phases 95-96; its detailed roadmap is archived at `.planning/milestones/v0.31-ROADMAP.md`.

## Accumulated Context

### Decisions

- [v0.32 roadmap]: `tchivs/mb-font` remains pure MoonBit, portable, and independently publishable with `tchivs/mb-core` as its only public runtime dependency.
- [v0.32 roadmap]: Coarse granularity merges the research's simple/composite implementation slices into Phase 99 so FONT-03 has one complete verification owner.
- [v0.32 roadmap]: Phase 98 owns both deterministic cmap selection and legacy kern semantics because both query admitted glyph identities without depending on outline geometry.
- [v0.32 roadmap]: Phase 100 qualifies immutable generated and licensed real-font evidence through the public workflow on `js`, `wasm`, `wasm-gc`, and `native`.
- [Phase 97]: Font retains the caller ByteView and gates every query on the opening revision.
- [Phase 97]: Admission uses table-local ByteViews and atomically charges bytes plus work before checksum scans.
- [Phase 97]: Unsupported font profiles are capability failures while malformed admitted TrueType bytes are data failures.
- [Phase 97]: Font retains private directory, required-table, and metric-index state without exposing raw parser facts.
- [Phase 97]: Required-table presence is checked without payload decoding before checksums to preserve the stable missing-table error contract.
- [Phase 97]: Head bounds, hhea metrics, and OS/2 typographic metrics remain separate signed integer values with no implicit selector.
- [Phase 97]: GlyphId remains opaque and every receiving Font revalidates its numeric range before lookup.
- [Phase 97]: Every non-empty common glyf header is validated during admission before Font publication.
- [Phase 97]: The mb-font semantic interface is frozen to limits, opaque font/glyph values, and named global/per-glyph metrics.

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 99 planning must freeze composite point attachment, phantom-point/`USE_MY_METRICS`, offset-scaling, and F2DOT14 evaluation rules before implementation.
- Phase 100 planning must finalize licensed real-font specimen provenance, redistribution records, digests, inventories, and independent semantic facts.
- Full Required gate needs a separate governance quick: forward Lane through scripts/quality.ps1 and reconcile RFC 0001 Accepted policy with Proposed canonical RFC/index.

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260726-r3a | Normalize MoonBit formatting for the Required WORK-04 module set and verify mb-core mb-color mb-image | 2026-07-26 | f20b8f2 | Verified | [260726-r3a-normalize-moonbit-formatting-for-the-req](./quick/260726-r3a-normalize-moonbit-formatting-for-the-req/) |
| 260726-toy | Preserve fixture manifest ordering during color vector regeneration | 2026-07-26 | f11d085 | Verified | [260726-toy-preserve-fixture-manifest-ordering-durin](./quick/260726-toy-preserve-fixture-manifest-ordering-durin/) |
| 260726-u7d | Preserve fixture manifest ordering during PPM vector regeneration | 2026-07-26 | 3e8229f | Verified | [260726-u7d-preserve-fixture-manifest-ordering-durin](./quick/260726-u7d-preserve-fixture-manifest-ordering-durin/) |
| 260726-uhq | Scope image floating policy to audited typed color math | 2026-07-26 | d0afa0e | Verified | [260726-uhq-scope-the-image-floating-prohibition-to-](./quick/260726-uhq-scope-the-image-floating-prohibition-to-/) |
| 260727-h6r | Normalize Phase 97 legacy coverage schema and close automated UAT | 2026-07-27 | b10f4263 | Complete | [260727-h6r-normalize-phase-97-legacy-coverage-schem](./quick/260727-h6r-normalize-phase-97-legacy-coverage-schem/) |

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| font formats | CFF/CFF2, TTC/OTC, WOFF/WOFF2, variable, color, and bitmap fonts | deferred | v0.32 scope |
| text/rendering | Shaping, bidi, layout, discovery/fallback, hinting, and rasterization | deferred | v0.32 scope |
| authoring | Font writing, editing, subsetting, and serialization | deferred | v0.32 scope |

## Session Continuity

Last session: 2026-07-26T10:57:39.568Z
Stopped at: Completed 97-03-PLAN.md
Resume file: None

## Operator Next Steps

- Run `/gsd-plan-phase 97`.

## Performance Metrics

No v0.32 plans have been completed.

**Per-Phase Metrics:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 97-100 | 0 | — | — |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 97 P01 | 39m | 3 tasks | 11 files |
| Phase 97 P02 | 40m | 3 tasks | 7 files |
| Phase 97 P03 | 42m | 3 tasks | 13 files |
