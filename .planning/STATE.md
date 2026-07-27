---
gsd_state_version: 1.0
milestone: v0.32
milestone_name: TrueType Font Foundation
current_phase: 99
current_phase_name: Simple and Composite Outlines
status: executing
stopped_at: Completed 99-01-PLAN.md
last_updated: "2026-07-27T10:28:56.612Z"
last_activity: 2026-07-27
last_activity_desc: Phase 98 complete, transitioned to Phase 99
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 9
  completed_plans: 7
current_plan: 1
total_plans_in_phase: 3
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-27 after Phase 98 validation).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 99 — Simple and Composite Outlines

## Current Position

Phase: 99 — Simple and Composite Outlines
Plan: 2 of 3
Status: Ready to execute
Last activity: 2026-07-27 — Phase 98 complete, transitioned to Phase 99

Progress: [████████░░] 78% (2/4 phases; 6/6 completed plans)

## Milestone Metrics

**Current milestone:** v0.32 has 4 planned phases; Phases 97-98 have completed all 6 implementation plans and passed verification, deep review, security, and automated UAT. FONT-01, FONT-02, and FONT-04 are complete; Phase 99 is ready for discussion and planning.

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
- [Phase 98]: Canonical cmap priority is 0/4/12, 3/10/12, 0/3/4, then 3/1/4.
- [Phase 98]: Supported noncanonical format-4/12 records are validated but never selected or used as fallback.
- [Phase 98]: Duplicate canonical cmap keys fail admission while different encoding records may alias one checked subtable.
- [Phase 98]: Only one classic version-0 coverage-0x0001 format-0 subtable is queryable; structurally valid alternatives remain Unsupported.
- [Phase 98]: Exact Apple v1 envelopes are validated without parsing format bodies, while complete unknown prefixes defer to Capability without traversal.
- [Phase 98]: FontAdmissionPlan retains pre-admitted KernState so optional, subtable, and pair scans are preflighted and charged exactly once.
- [Phase 98]: Phase 98 uses one checksum-correct generated font as the permanent Unicode-to-opaque-glyph-to-signed-kern tracer.
- [Phase 98]: Phase 98 publication exposes only glyph_for_scalar, kerning, two kern ceilings, and the expanded FontLimits constructor; cmap/kern facts remain private.
- [Phase 98]: The independent font policy classifier approves the exact Phase 98 surface while rejecting raw cmap/kern facts and Phase 99+ capabilities.
- [Phase ?]: Phase 99 simple outlines keep all format arithmetic in private checked Int64 Q15 until final Point2 construction.
- [Phase ?]: Outline queries cumulatively enforce maxp claims, retained limits and max_work, and caller Budget before traversal or allocation.
- [Phase ?]: Generated interfaces remain ignored local tool output; semantic baseline and final hashes are recorded without force-staging.

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 99 planning must freeze composite point attachment, phantom-point/`USE_MY_METRICS`, offset-scaling, and F2DOT14 evaluation rules before implementation.
- Phase 100 planning must finalize licensed real-font specimen provenance, redistribution records, digests, inventories, and independent semantic facts.
- [Windows] The workspace-wide Required lane remains subject to the known unscoped `mb-image/png` driver stall recorded in `.planning/WINDOWS.md`; isolated Phase 98 font, interface, policy, and documentation gates all pass.

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260726-r3a | Normalize MoonBit formatting for the Required WORK-04 module set and verify mb-core mb-color mb-image | 2026-07-26 | f20b8f2 | Verified | [260726-r3a-normalize-moonbit-formatting-for-the-req](./quick/260726-r3a-normalize-moonbit-formatting-for-the-req/) |
| 260726-toy | Preserve fixture manifest ordering during color vector regeneration | 2026-07-26 | f11d085 | Verified | [260726-toy-preserve-fixture-manifest-ordering-durin](./quick/260726-toy-preserve-fixture-manifest-ordering-durin/) |
| 260726-u7d | Preserve fixture manifest ordering during PPM vector regeneration | 2026-07-26 | 3e8229f | Verified | [260726-u7d-preserve-fixture-manifest-ordering-durin](./quick/260726-u7d-preserve-fixture-manifest-ordering-durin/) |
| 260726-uhq | Scope image floating policy to audited typed color math | 2026-07-26 | d0afa0e | Verified | [260726-uhq-scope-the-image-floating-prohibition-to-](./quick/260726-uhq-scope-the-image-floating-prohibition-to-/) |
| 260727-h6r | Normalize Phase 97 legacy coverage schema and close automated UAT | 2026-07-27 | b10f4263 | Complete | [260727-h6r-normalize-phase-97-legacy-coverage-schem](./quick/260727-h6r-normalize-phase-97-legacy-coverage-schem/) |
| 260727-loc | Add deterministic mid-query revision drift tests for Phase 98 glyph and kerning post-read guards | 2026-07-27 | 96c09619 | Verified | [260727-loc-add-deterministic-mid-query-revision-dri](./quick/260727-loc-add-deterministic-mid-query-revision-dri/) |
| 260727-nip | Normalize Phase 98 coverage verification kinds for automated UAT | 2026-07-27 | 456ce4bb | Complete | [260727-nip-normalize-phase-98-coverage-verification](./quick/260727-nip-normalize-phase-98-coverage-verification/) |

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| font formats | CFF/CFF2, TTC/OTC, WOFF/WOFF2, variable, color, and bitmap fonts | deferred | v0.32 scope |
| text/rendering | Shaping, bidi, layout, discovery/fallback, hinting, and rasterization | deferred | v0.32 scope |
| authoring | Font writing, editing, subsetting, and serialization | deferred | v0.32 scope |

## Session Continuity

Last session: 2026-07-27T10:28:32.623Z
Stopped at: Completed 99-01-PLAN.md
Resume file: None

## Operator Next Steps

- Discuss Phase 99 and freeze simple/composite outline semantics before planning.

## Performance Metrics

Phases 97-98 completed all six plans. Phase 98 passed final deep review, 19/19 security verification, 16/16 canonical verification, 9/9 automated UAT, and 65/65 isolated font tests on every supported target.

**Per-Phase Metrics:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 97-100 | 3 | 121m | 40m |
| 97 | 3 | 121m | 40m |
| 98 | 3 | - | - |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 97 P01 | 39m | 3 tasks | 11 files |
| Phase 97 P02 | 40m | 3 tasks | 7 files |
| Phase 97 P03 | 42m | 3 tasks | 13 files |
| Phase 98 P01 | 42m | 2 tasks | 5 files |
| Phase 98 P02 | 36min | 3 tasks | 9 files |
| Phase 98 P03 | 20min | 2 tasks | 7 files |
| Phase 99 P01 | 21min | 2 tasks | 9 files |
