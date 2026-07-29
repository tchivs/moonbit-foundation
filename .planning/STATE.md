---
gsd_state_version: 1.0
milestone: v0.34
milestone_name: CFF Outline Foundation
status: Awaiting next milestone
stopped_at: Completed 107-06-PLAN.md
last_updated: "2026-07-29T18:47:11.975Z"
last_activity: 2026-07-30
last_activity_desc: Milestone v0.34 completed and archived
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 18
  completed_plans: 18
current_phase: 107
current_phase_name: hostile-licensed-and-four-target-qualification
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-28 for v0.34).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 107 — hostile-licensed-and-four-target-qualification

## Current Position

Phase: Milestone v0.34 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-07-30 — Milestone v0.34 completed and archived

## Milestone Metrics

**Completed milestone:** v0.33 shipped 3 phases, 9 plans, and 5/5 verified requirements. Final qualification passed fourteen focused gates and 152/152 package tests per target, twenty-nine evidence negatives, and four semantically equal target records.

**Previous milestone:** v0.32 shipped 16 plans across Phases 97-100 with FONT-01 through FONT-05 verified, 103/103 font tests on each supported target, and a passing hosted Required lane.

## Accumulated Context

### Decisions

- [v0.34 roadmap]: Phase 104 freezes exact CFF1 profile, bounded structural data, and one name-keyed or CID-keyed execution environment per GID before bytecode execution.
- [v0.34 roadmap]: Phase 105 owns the single deterministic Type 2 interpreter, all-glyph validation, retained conservative bounds, `hmtx` metric authority, and atomic admission.
- [v0.34 roadmap]: Phase 106 adds a cubic path sink and routes standalone and TTC/OTC CFF1 through the existing opaque `Font` contract without changing static-`glyf` behavior.
- [v0.34 roadmap]: Phase 107 closes generated, licensed, hostile, performance, compatibility, and exact four-target evidence.
- [v0.34 roadmap]: CFF2/variable execution, WOFF, shaping, hint execution, rasterization, color/bitmap glyphs, authoring, FFI, and ambient I/O remain out of scope.
- [Phase 104]: Reuse the canonical SFNT directory parser through a private static-CFF1 gate, preserving existing public TrueType admission.
- [Phase 104]: Represent CFF DICT values as exact sign/magnitude/denominator facts with named table-relative and Private-relative offset wrappers.
- [Phase 104]: Reject recognized unsupported profiles and non-Type-2 CharStrings before retaining or charging a per-GID descriptor.
- [Phase 104]: Retain closed predefined CFF1 charset and Encoding tables in private MoonBit code for deterministic bounded lookup.
- [Phase 104]: Validate every FDArray private environment before FDSelect materialization, including FDs selected by no glyph.
- [Phase 104]: Preserve Top and per-FD FontMatrix as separate structural facts for Phase 105 composition rules.
- [Phase 104]: Derive private CFF structural ceilings from the existing non-zero FontLimits contract without widening the public limits API.
- [Phase 104]: Use one deferred FontAdmissionLedger transaction for standalone and selected-collection CFF admission, committing only after revision validation.
- [Phase 104]: Keep the private outline source closed over Glyf or one complete AdmittedCff1 aggregate; public CFF-backed Font promotion remains deferred.
- [Phase 104]: Treat every decoded zero-magnitude CffNumber as the supported PaintType and StrokeWidth default. — Value-based validation preserves integer, exact-real, and normalized signed-zero equivalence without accepting any non-zero semantics.
- [Phase 104]: Reduce each completed Top DICT entry before parsing subsequent bytes. — Incremental reduction makes first-encountered capability and data outcomes deterministic while retaining one parser implementation.
- [Phase 106]: Retain compact CFF bounds plus exact per-GID publishable command counts, never full paths or replay streams.
- [Phase 106]: Use one Type 2 geometry lifecycle and convert exact rational coordinates only at Point2 construction.
- [Phase 106]: Keep face-local hmtx and retained CFF bounds as metric authority while Type 2 width remains validation-only.
- [Phase 106]: Charge CFF outlines once across caller and ancestors after exact path staging and final revision validation.
- [Phase 106]: Keep public CFF outline execution on the no-op wrapper; expose only private pre-commit probes for white-box evidence.
- [Phase 106]: Run the selected CFF pre-execution probe before resource preflight and immediately guard the outer revision so State outranks Resource, Capability, and Data.
- [Phase 106]: Reuse the existing Type 2 VM read probe for mid-fetch evidence and add no post-charge seam after the sole CFF Budget commit.
- [Phase 106]: Selected CFF collection opens reuse shared admission with the collection opening revision as authoritative.
- [Phase 106]: Selected CFF capability failures preserve the established collection profile error boundary.
- [Phase 106]: Static-glyf production routing remains unchanged and is frozen by expanded deterministic evidence.
- [Phase 107]: Committed oracle identities exclude machine-local paths; the ignored validated handoff is the sole executable path authority.
- [Phase 107]: OTS is structural-only while fontTools and AFDKO remain independent semantic readers.
- [Phase 107]: Hostile outcomes carry literal error, GID, publication, and B8 facts; consumers cannot derive expected outcomes.
- [Phase 107]: Licensed CFF intake accepts only the literal summary-bound 107-01 handoff path and digest; ambient toolchain input is ignored.
- [Phase 107]: Source Sans license bytes come from the exact official 3.052R tag because the official OTF archive omits a license member.
- [Phase 107]: Semantic reader agreement normalizes only reader-specific contour-close rendering while validating keying and the complete CFF profile independently.
- [Phase 107]: Upstream OTF and license records remain external/OFL-1.1; reconstructed qualification metadata is generated/Apache-2.0.
- [Phase 107]: The evidence module is non-published, supports all four targets, and resolves tchivs/mb-font@0.1.0 only through explicit tracked workspace members under --frozen.
- [Phase 107]: Each licensed CFF payload has exactly one package-private MoonBit literal owner, and every carrier accessor reuses that owner.
- [Phase 107]: Wave 4 private regions remain generator-owned: absent markers are untouched in Plan 107-03, while present regions must byte-match canonical rendering.
- [Phase 107]: Compatibility and workload facts are closed producer data, including workflow IDs, static-glyf locks, B8 ordering, targets, workloads, and precedence.
- [Phase 107]: Public CFF evidence remains package-private and is qualified exclusively through public Font and FontCollection observations.
- [Phase 107]: Portable Type 2 depth evidence locks live frame state plus exact call/return depth, never backend-specific Array capacity.
- [Phase 107]: The closed 53-row private hostile corpus is materialized once and thereafter enforced by exact generator mirror checks.
- [Phase 107]: Qualification v3 owns exactly js.json, wasm.json, wasm-gc.json, native.json, and comparison.json beneath a link-free managed root.
- [Phase 107]: Cross-target equality removes only top-level target and runner; every other closed field remains equality-bearing.
- [Phase 107]: Wave 6 owns the observation-only native baseline and final benchmark/workspace identity refresh; Wave 5 makes no threshold, comparison, verdict, release, or stability claim.
- [Phase 107]: Native timing remains observation-only and separate from portable four-target correctness evidence.
- [Phase 107]: The active power scheme is sealed by locale-independent GUID rather than localized display text.
- [Phase 107]: Existing baseline replacement uses same-directory File.Replace backup and guaranteed cleanup.

### Pending Todos

None yet.

### Blockers/Concerns

None.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| compressed containers | WOFF1/WOFF2 decode and reconstruction | deferred | v0.33 scope |
| variable outlines | CFF2 execution and variable-font instantiation | deferred | v0.34 scope |
| text/rendering | Shaping, bidi, layout, discovery/fallback, hinting, and rasterization | deferred | v0.32 scope |
| other font profiles | Color/bitmap glyphs | deferred | v0.34 scope |
| authoring | Font writing, extraction, subsetting, serialization, merging, and standalone materialization | deferred | v0.34 scope |

## Session Continuity

Last session: 2026-07-29T10:34:06.512Z
Stopped at: Completed 107-06-PLAN.md
Resume file: None

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone

## Performance Metrics

Historical execution metrics remain available in archived milestone roadmaps. v0.34 has completed seventeen plans.

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 104 | 4 | - | - |
| 105 | 5 | - | - |
| 106 | 3 | - | - |
| 107 | 6 | - | - |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 104 P01 | 22min | 2 tasks | 7 files |
| Phase 104 P02 | 25min | 3 tasks | 5 files |
| Phase 104 P03 | 27min | 3 tasks | 10 files |
| Phase 104 P04 | 12min | 1 tasks | 3 files |
| Phase 106 P01 | 33min | 2 tasks | 15 files |
| Phase 106 P02 | 17min | 2 tasks | 5 files |
| Phase 106 P03 | 31min | 2 tasks | 7 files |
| Phase 107 P01 | 58min | 3 tasks | 9 files |
| Phase 107 P02 | 13min | 3 tasks | 10 files |
| Phase 107 P03 | 24min | 2 tasks | 5 files |
| Phase 107 P04 | 111min | 3 tasks | 15 files |
| Phase 107 P05 | 67min | 3 tasks | 9 files |
| Phase 107 P06 | 3h 41m | 2 tasks | 7 files |
