---
gsd_state_version: 1.0
milestone: v0.1
milestone_name: milestone
current_phase: 1
current_phase_name: Foundation Charter and Reproducible Workspace
status: blocked
stopped_at: Plan 01-08 Task 2 — authentic RFC acceptance evidence unavailable
last_updated: "2026-07-16T17:30:45.791+08:00"
last_activity: 2026-07-16
last_activity_desc: Completed 01-07 deterministic Required/LLVM quality controller and pinned read-only CI
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 8
  completed_plans: 7
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-16).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 1 — Foundation Charter and Reproducible Workspace

## Current Position

Phase: 1 (Foundation Charter and Reproducible Workspace) — EXECUTING
Plan: 8 of 8
Status: Blocked at the authentic RFC acceptance evidence gate
Last activity: 2026-07-16 — Completed 01-07 deterministic Required/LLVM quality controller and pinned read-only CI

Progress: [█████████░] 88%

## Performance Metrics

**Velocity:**

- Phases completed: 0
- Plans completed: 7
- Requirements validated: 9/36

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 01 P01 | 4 min | 2 tasks | 3 files |
| Phase 01 P02 | 10min | 3 tasks | 9 files |
| Phase 01 P03 | 6min | 2 tasks | 7 files |
| Phase 01 P04 | 11min | 2 tasks | 4 files |
| Phase 01 P05 | 5min | 2 tasks | 5 files |
| Phase 01 P06 | 3min | 2 tasks | 6 files |
| Phase 01 P07 | 6min | 3 tasks | 11 files |

## Accumulated Context

### Decisions

- Plan v0.1 as five horizontal dependency layers rather than application-shaped vertical slices.
- Treat `mb-core` as the safety and portability prerequisite for `mb-color` and `mb-image`.
- Stabilize reference color semantics before the image contract.
- Use a strict bounded PPM P6 codec and public examples as proof of the layers, not as a reason to broaden codec scope.
- Reserve independent consumption and release qualification for a final explicit gate.
- Keep RFC 0001 Proposed until an authorized acceptance route has authentic evidence.
- Require accepted RFCs for new modules, public dependency-direction changes, and breaking architectural boundaries.
- [Phase 01]: Machine-compared foundation facts have one owner in policy/foundation.json.
- [Phase 01]: All three v0.1 modules start independently at 0.1.0 candidate while namespace publication stays blocked.
- [Phase 01]: External fixtures require complete provenance and confirmed redistribution; generated fixtures are preferred.
- [Phase 01]: Use normal 0.1.0 named dependencies so moon.work substitutes local members without path dependencies.
- [Phase 01]: Declare the explicit +js+wasm+wasm-gc+native set at module and public root package levels.
- [Phase 01]: Use the pinned CLI canonical supported_targets moon.pkg assignment while retaining moon.mod.json.
- [Phase 01]: Keep the Phase 1 mb-core proof package-private and expose no public domain API.
- [Phase 01]: Use an underscore-prefixed private probe for warning-free deny-warn builds while white-box tests exercise it.
- [Phase 01]: Document candidate status and publication blocking without fabricating a public example or released version.
- [Phase 01]: Keep the Phase 1 mb-color proof package-private and expose no public color API.
- [Phase 01]: Retain the mb-core module dependency while omitting a package import until a public core contract exists.
- [Phase 01]: Document candidate status and publication blocking without fabricating a public example or released version.
- [Phase 01]: Keep the Phase 1 mb-image proof package-private and expose no image or codec API.
- [Phase 01]: Retain mb-core and mb-color module dependencies while omitting unusable package imports until public contracts exist.
- [Phase 01]: Ignore pkg.generated.mbti outputs after exact semantic-interface verification.
- [Phase 01]: Keep moon.mod.json by formatting the complete MoonBit source inventory instead of accepting the pinned formatter's unconditional manifest migration.
- [Phase 01]: Run documentation generation per fixed workspace member because root workspace moon doc cannot infer a module.
- [Phase 01]: Treat structured policy and source-audit JSON strictly as data; process execution uses fixed commands and hard-coded target/module inventories.
- [Phase 01]: Keep LLVM isolated from Required success and pin every external CI action to an immutable commit with read-only permissions.

### Pending Decisions

- Resolve mooncakes.io namespace ownership and RFC acceptance authority with authentic evidence in Phase 1.
- Finalize numeric/tolerance, image lifetime/layout, resource-budget, and PPM subset details before their respective candidate APIs stabilize.

### Blockers

- Plan 01-08 cannot record RFC 0001 as Accepted until one complete D-03 route has authentic public evidence: either two distinct maintainer approvals, or an eligible project-lead approval with a public review interval of at least seven elapsed days; both routes also require completion of the two mandatory manual edge reviews and disposition of every blocking objection.
- Required quality, four-target tests, policy validation, and the exact `1/9/16/29/17/5` closed-world source audit pass, but they cannot substitute for the missing governance authority evidence.

## Session Continuity

**Resume file:** None

Last session: 2026-07-16T17:30:45.791+08:00
Stopped at: Resumed Plan 01-08; authentic D-03 acceptance evidence remains unavailable, so RFC 0001 stays Proposed.
Resume with: Supply one authentic D-03 evidence bundle, then execute Plan 01-08 Tasks 2-3.
