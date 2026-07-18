---
gsd_state_version: 1.0
milestone: v0.2
milestone_name: Publication & Compatibility
current_phase: 08
current_phase_name: Ordered Mooncakes Publication and Registry Consumers
status: executing
stopped_at: Completed 08-01-PLAN.md
last_updated: "2026-07-18T10:04:38.994Z"
last_activity: 2026-07-18
last_activity_desc: Phase 08 execution started
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 34
  completed_plans: 29
  percent: 50
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-17).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 08 — Ordered Mooncakes Publication and Registry Consumers

## Current Position

Phase: 08 (Ordered Mooncakes Publication and Registry Consumers) — EXECUTING
Plan: 2 of 6
Status: Executing Wave 2
Last activity: 2026-07-18 — Phase 08 execution started

## Progress

Current milestone: [█████░░░░░] 50% of v0.2 phases complete

- v0.2 phases completed: 2/4
- Phase 6 plans completed: 25/25
- Phase 7 plans completed: 3/3
- v0.2 requirements mapped: 21/21
- Historical total: 5 completed phases, 41 completed plans, 36/36 v0.1 requirements validated

## Accumulated Context

### Decisions

- v0.1 is archived; phase numbering continues at Phase 6.
- Required remains credential-free; only the isolated publisher receives a least-privilege Mooncakes credential.
- Compatibility baselines and fail-closed authority checks precede credentialed release automation.
- Publication order is `mb-core` → registry consumer → `mb-color` → registry consumer → `mb-image` → full-graph consumer.
- Recovery is monotonic and forward-only; automation assumes no overwrite, delete, unpublish, or yank capability.
- The project has one maintainer, so the workflow uses sole-owner authorization and introduces no multi-person approval or team ceremony.
- v0.2 adds no new module family and closes with immutable provenance and a milestone audit.
- [Phase 06]: Use tchivs as the canonical initial personal Mooncakes owner while preserving MoonBit Native Foundation branding. — Official username-prefixed namespace rules and the locked personal-identity decision require the personal owner before publication.
- [Phase 06]: Keep the tracked authority seed unknown-first until fresh sanitized external proof exists. — Prior local authentication cannot prove the exact Mooncakes account, namespace, repository liveness, or module authority.
- [Phase 06]: Keep the unpublished tchivs module family at 0.1.0 while rebasing roots and exact dependency floors. — The owner correction precedes publication and is not a SemVer release break.
- [Phase 06]: Use disposable complete-import overlays only for transitional wave verification; never broaden tracked plan scope. — The main moon.work intentionally contains later-wave old-owner members until their owning plans execute.
- [Phase 06]: Use disposable modules-only workspaces for staged source-graph verification while example consumers remain owned by 06-09. — Moon parent-workspace discovery otherwise resolves intentionally unmigrated example identities before module checks.
- [Phase 06]: Keep native runtime verification fail-closed by default; compile-only requires explicit opt-in. — This machine lacks a system C compiler, and compile-only evidence must never be equivalent to linking or runtime-output proof.
- [Phase 06]: Treat the tchivs GitHub repository URL as intended metadata only until an explicit external liveness gate verifies it. — Plan 06-25 is credential-free and cannot create, authenticate to, or prove the repository.
- [Phase 06]: Use canonical tchivs identities inside semantic negative fixtures so each failure remains owned by its intended rule. — Stale namespace drift would mask the exact path-substitution, higher-layer, or extra-import failure being tested.
- [Phase 06]: Require real native compilation, linking, and runtime execution for release qualification; compile-only is not equivalent. — Plan 06-13 produced full native evidence with the explicitly configured Clang and LLVM-MinGW sysroot.
- [Phase 06]: Keep intended GitHub and reporting routes unverified until read-only existence proof succeeds. — Repository metadata cannot establish external route liveness or Mooncakes authority.
- [Phase 06]: A tracked authority seed cannot infer account, namespace, module, timestamp, or freshness evidence. — Only fresh sanitized external observation can advance publication authority.
- [Phase 06]: Bind public-interface baseline batches to the immutable completed 06-14 source snapshot. — Later HEAD and obsolete manifest metadata must never influence compatibility evidence.
- [Phase 06]: Use canonical policy order error then checked at the generator boundary while preserving the plan-owned twelve-file output set. — The exact-package generator rejects out-of-order inventory requests, and package order does not alter batch membership or output ownership.
- [Phase 06]: Use canonical policy order io then host at the generator boundary while preserving the plan-owned twelve-file output set. — Exact-package ordering is a validation constraint and does not broaden batch membership or file ownership.
- [Phase 06]: Use canonical policy order model then alpha at the generator boundary while preserving the plan-owned twelve-file output set. — Exact-package ordering is a validation constraint and does not broaden batch membership or file ownership.
- [Phase 06]: Use canonical policy order quantize then profile at the exact-package generator boundary while preserving the plan-owned twelve-file output set. — Exact-package ordering is a validation constraint and does not broaden batch membership or file ownership.
- [Phase 06]: Preserve canonical global package order by generating mb-color/transfer before mb-image/codec without broadening the twelve-file ownership boundary. — The exact-package generator enforces policy order while plan ownership remains limited to the enumerated outputs.
- [Phase 06]: Preserve canonical package order by generating mb-image/metadata before mb-image/model without broadening the twelve-file ownership boundary. — Exact-package ordering is a validation constraint while plan ownership remains limited to the twelve enumerated outputs.
- [Phase 06]: Preserve canonical package order by generating mb-image/ops before mb-image/ppm without broadening the twelve-file ownership boundary. — Exact-package ordering is a validation constraint while plan ownership remains limited to the twelve enumerated outputs.
- [Phase 06]: Keep the final package batch limited to mb-image/storage while preserving the six-file ownership boundary. — Exact-package generation and protected-file hashing complete the anchored package tree without manifest or cross-batch mutation.
- [Phase 06]: Close active old-identity inventory at 105 exact occurrence records with content-addressed contexts and preserve fail-closed authority. — Final compatibility evidence must distinguish immutable history, explicit mappings, source audit, and named negative fixtures without broad allowlists.
- [Phase 06]: Account identity, public account presence, documented namespace syntax, and version absence do not prove current-token namespace or publish authority.
- [Phase 06]: Phase 6 satisfies REG-03 by proving the readiness gate rejects unknown required authority; Phase 7 validates the authenticated publish seam before mutation.
- [Phase 06]: Required treats REG03-REQUIRED-FACT-UNKNOWN as the only valid publish-readiness outcome until Phase 7 proves the authenticated seam. — Account identity, public presence, and version absence cannot prove current-token namespace or publication authority.
- [Phase 06]: Source-isolation consumers prebuild public packages in canonical module and package order before consumer check and test on every target. — Explicit topological construction removes incremental Native interface ordering dependence while preserving source-only isolation and manifest immutability.
- [Phase 07]: Authorize exact canonical release-intent digests separately from content identity and retain one immutable initial root across forward corrections.
- [Phase 07]: Serialize publication by repository plus immutable root, preserve verified checkpoints, and permit only monotonic dependency-safe transitions.
- [Phase 07]: Keep Required credential-free and non-publishing; the Mooncakes secret is confined to one environment-gated LiveOneStep after prepared-bundle revalidation.
- [Phase 07]: Treat mismatch as terminal for the current intent and allow only a newly qualified, newly authorized, unpublished forward correction.
- [Phase 08]: Use one fixed ordered 17-payload inventory and treat the manifest digest as artifact identity without self-reference.
- [Phase 08]: Carry the prepared validator inside the bundle so the publisher reruns identical closed validation before secret materialization.

### Pending Decisions

- Plan the explicit Phase 8 first irreversible publish checkpoint and registry-only consumer sequence.
- Preserve the distinction between verified local account/environment readiness and authority proven by successful exact publication plus read-only registry observation.

### Blockers

None

## Session Continuity

**Resume file:** None

Last session: 2026-07-18T10:04:38.980Z
Stopped at: Completed 08-01-PLAN.md
Resume with: `/gsd-execute-phase 8`

## Operator Next Steps

- Discuss and plan Phase 8 ordered publication and cold registry-only consumers.
- Keep the first irreversible Mooncakes mutation behind an explicit Phase 8 authorization checkpoint.

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 06 P07 | 8m | 2 tasks | 9 files |
| Phase 06 P12 | 12m | 2 tasks | 4 files |
| Phase 06 P08 | 18m | 3 tasks | 15 files |
| Phase 06 P09 | 18m | 2 tasks | 8 files |
| Phase 06 P25 | 13m | 2 tasks | 4 files |
| Phase 06 P13 | 39m | 3 tasks | 7 files |
| Phase 06 P10 | 18m | 2 tasks | 12 files |
| Phase 06 P14 | 16m | 3 tasks | 7 files |
| Phase 06 P15 | 25min | 1 tasks | 3 files |
| Phase 06 P16 | 4min | 1 tasks | 12 files |
| Phase 06 P17 | 2min | 1 tasks | 12 files |
| Phase 06 P18 | 4min | 1 tasks | 12 files |
| Phase 06 P19 | 2min | 1 tasks | 12 files |
| Phase 06 P20 | 2min | 1 tasks | 12 files |
| Phase 06 P21 | 4min | 1 tasks | 12 files |
| Phase 06 P22 | 4min | 1 tasks | 12 files |
| Phase 06 P23 | 3min | 1 tasks | 12 files |
| Phase 06 P24 | 5min | 1 tasks | 6 files |
| Phase 06 P11 | 28min | 3 tasks | 4 files |
| Phase 06 P01 | 50min | 2 tasks | 4 files |
| Phase 06 P06 | 10h 31m | 2 tasks | 4 files |
| Phase 07 P01 | 13min | 3 tasks | 7 files |
| Phase 07 P02 | 13min | 2 tasks | 5 files |
| Phase 07 P03 | 20min | 3 tasks | 8 files |
| Phase 08 P01 | 24min | 2 tasks | 3 files |
