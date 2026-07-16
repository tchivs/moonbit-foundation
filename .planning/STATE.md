---
gsd_state_version: 1.0
milestone: v0.1
milestone_name: milestone
current_phase: 03
current_phase_name: Reference Color Semantics
status: executing
stopped_at: Completed 03-02-PLAN.md
last_updated: "2026-07-16T18:02:52.902Z"
last_activity: 2026-07-17
last_activity_desc: Phase 03 execution started
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 23
  completed_plans: 18
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-16).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 03 — Reference Color Semantics

## Current Position

Phase: 03 (Reference Color Semantics) — EXECUTING
Plan: 3 of 7
Status: Ready to execute
Last activity: 2026-07-17 — Phase 03 execution started

Progress: [████████░░] 78% (1/5 phases; 8/8 currently planned plans complete)

## Performance Metrics

**Velocity:**

- Phases completed: 1
- Plans completed: 8
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
| Phase 01 P08 | 7min | 3 tasks | 4 files |
| Phase 02 P01 | 10min | 3 tasks | 8 files |
| Phase 02 P02 | 13min | 3 tasks | 9 files |
| Phase 02 P03 | 7min | 2 tasks | 5 files |
| Phase 02 P04 | 10min | 3 tasks | 6 files |
| Phase 02 P05 | 10min | 3 tasks | 8 files |
| Phase 02 P06 | 18min | 2 tasks | 6 files |
| Phase 02 P07 | 17min | 3 tasks | 8 files |
| Phase 02 P08 | 5min | 2 tasks | 4 files |
| Phase 03 P01 | 11min | 2 tasks | 6 files |
| Phase 03 P02 | 18min | 2 tasks | 4 files |

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
- [Phase 01]: For the current one-maintainer repository, use the canonical `sole-project-owner-bootstrap` route and the project owner's exact conditional preauthorization; eligibility derives from `policy/maintainers.json` and expires when a second distinct maintainer is added.
- [Phase 01]: Normative RFC evidence must be the exact repository decision artifact, remain beneath the repository root, and contain no symbolic-link or reparse-point component.
- [Phase 01]: Both mandatory governance edge reviews completed with no omitted boundary or authority case and no unresolved blocking objection.
- [Phase 01]: RFC 0001 is Accepted through the exact sole-project-owner conditional preauthorization, without asserting a second approval or elapsed public review.
- [Phase 02]: Treat policy semantic-interface lines and publication contents as exact ordered and closed allowlists.
- [Phase 02]: Map host failures by discarding foreign detail and retaining only a bounded portable operation token.
- [Phase 02]: Keep logical counts and positions as UInt64 and permit direct UInt64-to-Int conversion only inside checked_narrow_int after the pinned 2147483647 ceiling guard.
- [Phase 02]: Represent arithmetic underflow, invalid alignment, invalid offset, narrowing failure, and invalid dimensions with distinct stable error codes.
- [Phase 02]: Treat empty half-open ranges, including an empty range at UInt64 maximum, as valid and non-overlapping.
- [Phase 02]: Treat bytes, allocation count, pixels, and work as consumable counters while allocation size and dimensions are per-operation ceilings and depth is a balanced shared ceiling.
- [Phase 02]: Represent budget hierarchy as a chain of shared windows; preflight every ancestor and charge dimension before committing any consumable counter.
- [Phase 02]: Use Resource/BudgetExceeded with a bounded dimension context token for machine-readable limit rejection.
- [Phase 02]: Use callback-scoped runtime lease groups so split consumes the parent and final child release restores owner availability.
- [Phase 02]: Keep built-in physical OOM unrecoverable while exposing deterministic injected allocator rejection before budget charge and allocation.
- [Phase 02]: Retain zero-copy immutable views over owned backing and copy external immutable Bytes into independent storage.
- [Phase 02]: Use an opaque ReadWindow so bounded adapters can narrow writable access without consuming the caller lease or exposing a larger destination.
- [Phase 02]: Keep bounded stream adapters non-seeking and expose seeking only through separately implemented Seeker capabilities.
- [Phase 02]: Reject zero progress after one transition for non-empty exact operations while zero-length operations bypass the backend.
- [Phase 02]: Keep file access and logical resource resolution as separate portable traits without prescribed native adapters.
- [Phase 02]: Use one deterministic instance-local fake per capability and no Host aggregate or ambient fallback.
- [Phase 02]: Map host adapter failures to fixed bounded operation tokens and advance fake clocks with checked arithmetic.
- [Phase 02]: Publish exactly six mb-core packages in error, checked, budget, bytes, io, host order; retain no root facade.
- [Phase 02]: Run standalone README compilation and fail-closed negative fixtures in every Required qualification.
- [Phase 02]: Callback cleanup closes the shared LeaseGroup scope instead of releasing the parent handle consumed by split_mut. — Every retained descendant observes the shared inactive scope while owner availability is restored exactly once.
- [Phase 03]: Represent encoded-sRGB, linear-sRGB, normalized alpha, encoded color, and encoded alpha as distinct opaque scalar types rather than aliases or a universal color record.
- [Phase 03]: Reject non-finite and out-of-range normalized inputs before range acceptance, and reject full-width encoded values above 255 before Byte narrowing.
- [Phase 03]: Keep the Phase 1 root package private and non-reexporting while registering model as the first real public mb-color package.
- [Phase 03]: Generate standards-formula-derived and repository-derived evidence from one canonical in-memory dataset while keeping their provenance claims separate.
- [Phase 03]: Make each package selector own exactly one package-local reference vector table so portable tests require no filesystem capability.
- [Phase 03]: Use byte-for-byte UTF-8 no-BOM LF check mode for fixtures, generated test tables, and manifest digest refresh.

### Pending Decisions

- Resolve mooncakes.io namespace ownership before publication.
- Finalize numeric/tolerance, image lifetime/layout, resource-budget, and PPM subset details before their respective candidate APIs stabilize.

### Blockers

None. Phase 01 is independently verified and complete; Phase 02 is ready for context discussion and planning.

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260716-pml | Add a transparent sole-owner bootstrap route and rewire Plan 01-08 without fabricated evidence | 2026-07-16 | c310a68 | Verified | [260716-pml-bootstrap-rfc-01-08-validate](./quick/260716-pml-bootstrap-rfc-01-08-validate/) |

## Session Continuity

**Resume file:** None

Last session: 2026-07-16T18:02:52.884Z
Stopped at: Completed 03-02-PLAN.md
Resume with: Discuss Phase 02, then plan and execute it through the active auto chain.
