---
gsd_state_version: 1.0
milestone: v0.32
milestone_name: TrueType Font Foundation
current_phase: 100
status: completed
stopped_at: Phase 100 complete; v0.32 ready for milestone audit
last_updated: "2026-07-28T04:00:05+08:00"
last_activity: 2026-07-28
last_activity_desc: Phase 100 complete
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 16
  completed_plans: 16
current_phase_name: Portable Font Qualification
current_plan: 6
total_plans_in_phase: 6
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-28 after Phase 100 validation).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Audit and archive v0.32 TrueType Font Foundation

## Current Position

Phase: 100
Plan: Not started
Status: All phases complete
Last activity: 2026-07-28 — Phase 100 complete

Progress: [██████████] 100%

## Milestone Metrics

**Current milestone:** v0.32 completed all 16 implementation plans across Phases 97-100. FONT-01 through FONT-05 are verified; Phase 100 passed its deep review, 4/4 goal verification, 18/18 UAT deliverables, 35/35 threat checks, four-target qualification, and hosted Required contract.

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
- [Phase 99]: Phase 99 simple outlines keep all format arithmetic in private checked Int64 Q15 until final Point2 construction.
- [Phase 99]: Outline queries cumulatively enforce maxp claims, retained limits and max_work, and caller Budget before traversal or allocation.
- [Phase 99]: Generated interfaces remain ignored local tool output; semantic baseline and final hashes are recorded without force-staging.
- [Phase 99]: Phase 99 composites classify every reachable descriptor graph before unsupported-capability publication, so cycles remain Data.
- [Phase 99]: Phase 99 composite transforms and attachments remain checked Int64 Q15 until final Path2 Point2 construction.
- [Phase 99]: Metrics and outline component lookup share one admitted table-local glyph-window helper.
- [Phase 99]: Phase 99 permanent qualification uses one empty/simple/composite checksum-correct font through the public outline workflow.
- [Phase 99]: Phase 99 publication keeps pkg.generated.mbti ignored while policy and an independent classifier freeze its exact 56 semantic lines.
- [Phase 99]: Phase 99 documents generated four-target evidence while reserving licensed real-font workflow qualification for Phase 100.
- [Phase 99]: The focused font selector independently enforces case-sensitive manifest-description equality with policy.
- [Phase 99]: README taxonomy checks are bullet-scoped: maxp underclaims are Data, while FontLimits, max_work, and Budget exhaustion are Resource.
- [Phase 100]: Phase 100 Plan 01 freezes a versioned closed PowerShell SFNT oracle that cannot be updated from mb-font output.
- [Phase 100]: Phase 100 keeps 4096-byte DejaVu literal chunks after successful compilation on js, wasm, wasm-gc, and native.
- [Phase 100]: Phase 100 uses a 580-byte checksum-correct compact font for minimal complete workflow qualification.
- [Phase 100]: Recognize only platform 1, encoding 0, format 6 as a bounded non-selected coexistence record.
- [Phase 100]: Keep CmapLookupFacts, canonical ranks, supported decoding, and public API limited to formats 4 and 12.
- [Phase 100]: Charge a recognized non-selected format-6 record only for the existing encoding-record scan, never for body traversal.
- [Phase 100]: Use U+034C as the independently qualified supported DejaVu composite; keep U+00E9 at the explicit font-outline-grid-rounding capability boundary.
- [Phase 100]: Normalize only top-level target and runner fields before byte-comparing four-target font qualification evidence.
- [Phase 100]: Permit only zero-valued 0-3 byte TrueType glyph alignment padding after an otherwise valid outline.
- [Phase 100]: Keep FontQualification as a dedicated selector that forwards EvidenceDirectory and never invokes or replaces Required.
- [Phase 100]: Audit executable MoonBit source separately from comments and string literals so provenance text and unsupported-profile test data cannot self-trigger capability gates.
- [Phase 100]: Remove only target and runner metadata from comparison; every public, hostile, fixture, toolchain, and dependency fact remains byte-visible.
- [Phase 100]: Label only successfully validated focused records as font-qualification-evidence; upload Required output separately as required-diagnostic.
- [Phase 100]: Require a Required-named evidence path and record timeout, exit, streams, and process-tree termination without touching focused evidence.
- [Phase 100]: Preserve the workspace Required timeout as a real failure while treating the independently passing focused font evidence as a separate boundary.
- [Phase 100]: Persist complete canonical M/L/Q/Z arrays in oracle schema 1.1.0 while retaining SHA-256 exclusively in offline PowerShell tooling.
- [Phase 100]: Generate one ordered test-private expectation set for U+0041, U+034C, and U+10300 and structurally assert every command.
- [Phase 100]: Publish target fingerprints only after the exact one-test DejaVu assertion reports 1/1 passing for that target.

### Pending Todos

None yet.

### Blockers/Concerns

None. The prior workspace Required timeout concern is closed by hosted run `30297979654`, which completed the full Required lane and published verified exit/process-session evidence.

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

Last session: 2026-07-28T04:00:05+08:00
Stopped at: Phase 100 complete; v0.32 ready for milestone audit
Resume file: None

## Operator Next Steps

- Run the v0.32 milestone audit, close any cross-phase gaps, then archive and tag the milestone.

## Performance Metrics

Phases 97-100 completed all 16 implementation plans. Phase 100 proves all 74 supported DejaVu commands through an exact 1/1 focused gate before each target record, with 103/103 full-suite tests on every supported target and a passing hosted Required lane.

**Per-Phase Metrics:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 97-100 | 16 | 371m | 23m |
| 97 | 3 | 121m | 40m |
| 98 | 3 | 98m | 33m |
| 99 | 4 | 54m | 14m |
| 100 | 6 | 98m | 16m |
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
| Phase 99 P02 | 17min | 2 tasks | 5 files |
| Phase 99 P03 | 12min | 3 tasks | 8 files |
| Phase 99 P04 | 4min | 2 tasks | 3 files |
| Phase 100 P01 | 14min | 2 tasks | 7 files |
| Phase 100 P02 | 16min | 2 tasks | 5 files |
| Phase 100 P03 | 25min | 2 tasks | 10 files |
| Phase 100 P04 | 10min | 1 tasks | 5 files |
| Phase 100 P05 | 25min | 2 tasks | 5 files |
| Phase 100 P06 | 8min | 2 tasks | 6 files |
