---
gsd_state_version: 1.0
milestone: v0.2
milestone_name: Publication & Compatibility
current_phase: 08
current_phase_name: Ordered Mooncakes Publication and Registry Consumers
status: executing — 08-32 satisfied-by-prior-run; only 08-33 (publication) remains and is NOT operator-authorized
stopped_at: 08-32-SUMMARY.md committed (satisfied-by-prior-run); 08-33 awaits explicit authorize-core
last_updated: "2026-07-19T20:30:00.000Z"
last_activity: 2026-07-19
last_activity_desc: r12 publish-blocked by REL01-REF (tag-before-script-fix); corrected misdiagnosed timeout; recorded ordering invariant for r13+
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 61
  completed_plans: 60
  percent: 50
---

# Project State

## Project Reference

See `.planning/PROJECT.md` (updated 2026-07-17).

**Core value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

**Current focus:** Phase 08 — Ordered Mooncakes Publication and Registry Consumers

## Current Position

Phase: 08 (Ordered Mooncakes Publication and Registry Consumers) — EXECUTING
Plan: 32 of 33 (only 08-33 remains)
Status: r12 publish-blocked (REL01-REF) — its boundary commit (5e7b19cd) declared policy release_ref=r12 but Invoke-ReleaseQualification.ps1 still hardcoded r9; the fix (d55f63a) landed 26 min after the immutable tag. 08-33 cannot run on r12. Forward path is r13+; do NOT retry r12.
Last activity: 2026-07-19 — corrected the misdiagnosed timeout narrative (deterministic REL01-REF), recorded the tag-before-script-fix ordering invariant for r13+

## Progress

Current milestone: [█████░░░░░] 50% of v0.2 phases complete

- v0.2 phases completed: 2/4
- Phase 6 plans completed: 25/25
- Phase 7 plans completed: 3/3
- Phase 8 plans completed: 32/33 (only 08-33 remains; NOT operator-authorized)
- v0.2 requirements mapped: 21/21
- Historical total: 5 completed phases, 43 completed plans, 36/36 v0.1 requirements validated

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
- [Phase 08]: Bound registry propagation observation to 20 attempts at a fixed 15-second cadence.
- [Phase 08]: Accept only structured caller-supplied surface records and persist only the closed sanitized projection.
- [Phase 08]: Treat every missing, weak, ambiguous, secret-shaped, or disagreeing fact as non-mutating unknown or mismatch evidence.
- [Phase 08]: Keep fixture evidence explicitly distinct from live registry evidence. — Unavailable registry versions must never be represented by fixture-generated live proof.
- [Phase 08]: Compare resolved graphs semantically but serialize accepted proofs in canonical policy order. — Dependency tree line ordering is not semantic evidence, while proof identity must remain deterministic.
- [Phase 08]: Replay every supplied checkpoint through the Phase 7 reducer before deriving the next module.
- [Phase 08]: Expose the token only through one temporary credentials file under a child-only MOON_HOME and persist only an allowlisted classification.
- [Phase 08]: Carry the tracked live adapter as the eighteenth exact prepared payload so the publisher remains artifact-only.
- [Phase 08]: Keep refs/tags/modules-v0.1.0 and refs/tags/modules-v0.1.0-r1 through refs/tags/modules-v0.1.0-r9 as immutable terminal historical evidence; only refs/tags/modules-v0.1.0-r10 may be current initial forward-retry authority.
- [Phase 08]: Require the exact closed tchivs whoami projection and prepared-manifest digest before publisher or live mutation eligibility.
- [Phase 08]: Represent exact-existing registry authority as a bound zero-mutation checkpoint that cannot enter the mutation adapter.
- [Phase 08]: Bind every hosted helper use to one clean r1 execution root, HEAD, and exact Git blob before any operation.
- [Phase 08]: Accept exactly one core-entry authority variant: absent may yield a MutationAuthorizationPacket, while exact yields zero-mutation ExactExistingAuthority.
- [Phase 08]: Keep DIST-01 through DIST-04 and PROV-05 pending until live publication and registry-only evidence exist.
- [Phase 08]: Only refs/tags/modules-v0.1.0-r10 is current initial retry; attempt zero and r1 through r9 are immutable terminal-negative history.
- [Phase 08]: Prepared r2 identity binds both terminal-negative digests through the digest-covered request payload without importing prior state containers.
- [Phase 08]: Mutation handoff requires packet plus literal receipt; exact-existing handoff forbids both variants' mutation evidence.
- [Phase 08]: Publisher and live adapter accept only r2 plus two distinct terminal-negative history digests.
- [Phase 08]: Production fixed r2 handoff path is internal and non-overridable; only LibraryOnly fixtures inject paths.
- [Phase 08]: r3 is the sole current initial retry; attempt-zero, r1, and r2 remain immutable terminal-negative history and are never correction predecessors.
- [Phase 08]: Eligibility binds three exact record digests and the SHA-256 of their LF-joined canonical order; individual evidence is never replaced by the aggregate.
- [Phase 08]: DIST-01 remains pending because Plan 08-09 performs no tag, dispatch, publication, registry observation, or cold consumer proof.
- [Phase 08]: The hosted dispatch carries one canonical historical_attempts_sha256 field while the workflow deterministically expands and validates the three exact record digests before credentials.
- [Phase 08]: The start vector carries empty packet and receipt fields; a PublishOne resume requires both digests as one closed authority pair.
- [Phase 08]: DIST-01 remains pending because Plan 08-10 performs no push, tag, hosted dispatch, publication, registry observation, or cold consumer proof.
- [Phase 08]: Only refs/tags/modules-v0.1.0-r10 is current initial retry; attempt-zero and r1 through r9 are ten immutable terminal-negative histories.
- [Phase 08]: Eligibility carries all four individual record digests plus the SHA-256 of their canonical LF-joined order; the aggregate never replaces individual evidence.
- [Phase 08]: DIST-01 remains pending because Plan 08-11 performs no push, tag, hosted dispatch, registry observation, mutation, or publication.
- [Phase 08]: Publisher, adapter, workflow, and hosted controller accept only r4 and bind four individual terminal-negative history digests plus their canonical LF-ordered set.
- [Phase 08]: The hosted dispatch contract remains exactly 14 ordered fields with an empty start packet/receipt pair and a valid paired PublishOne resume.
- [Phase 08]: Production uses only the non-overridable fixed %TEMP%/mnf-phase08-r4-handoff.json path; LibraryOnly GUID fixtures may inject owned paths.
- [Phase 08]: DIST-01 remains pending because Plan 08-12 performs no push, tag, dispatch, registry observation, mutation, or publication.
- [Phase 08]: The r4 terminal record binds hosted run 29667231047/1 to the credential-free clean-snapshot binding failure and explicit zero downstream artifacts.
- [Phase 08]: r5 eligibility requires five individual terminal-history digests plus their canonical LF-ordered set digest.
- [Phase 08]: DIST-01 remains pending because Plan 08-13 performs no external publication or registry-consumer action.
- [Phase 08]: Publisher, adapter, workflow, and hosted controller accept only r5 and bind five immutable terminal-negative histories.
- [Phase 08]: The hosted dispatch remains exactly 14 ordered fields; five individual histories are recomputed into the canonical aggregate before dispatch.
- [Phase 08]: Production uses only the non-overridable fixed %TEMP%/mnf-phase08-r5-handoff.json path; LibraryOnly fixtures use GUID-owned roots.
- [Phase 08]: DIST-01 remains pending because Plan 08-14 performs no push, tag, dispatch, registry observation, mutation, or publication.
- [Phase 08]: Only refs/tags/modules-v0.1.0-r10 is current initial authority; attempt-zero and r1 through r9 remain immutable terminal-negative history.
- [Phase 08]: The r5 terminal record binds exact source/tag, successful preparation and absence, duplicate-env pre-run rejection, no hosted run, and zero downstream effects.
- [Phase 08]: DIST-01 remains pending because Plan 08-15 performs no external publication or registry-consumer action.
- [Phase 08]: Publisher, adapter, workflow, and hosted controller accept only r6 and bind six immutable terminal histories.
- [Phase 08]: The r6 pre-live selector is read-only and emits one closed sanitized result before any live action.
- [Phase 08]: Only refs/tags/modules-v0.1.0-r10 is current initial authority; attempt-zero and r1 through r9 remain immutable terminal-negative evidence.
- [Phase 08]: The r6 terminal record binds run 29671691604/1, prepare job 88151792308, P08-PREPARED-INTENT-BINDING, and explicit zero downstream effects.
- [Phase 08]: Every r7 prepared, authority, receipt, and handoff contract binds seven individual history digests plus their canonical LF-ordered set.
- [Phase 08]: DIST-01 remains pending because Plan 08-17 performs no external publication or registry-consumer action.
- [Phase 08]: Publisher, adapter, workflow, and hosted controller accept only r7 and bind seven immutable histories.
- [Phase 08]: The r7 pre-live selector trusts one remote-tag query, preserves rootless attempt-zero, and requires rooted r1-r6 evidence plus exact r6 downstream-zero failure.
- [Phase 08]: DIST-01 remains pending because Plan 08-18 performs no external publication or registry-consumer action.
- [Phase 08]: Only refs/tags/modules-v0.1.0-r10 is current initial authority; attempt-zero and r1 through r9 remain immutable terminal-negative evidence.
- [Phase 08]: The r7 record binds source 195e08d, tag object 52a47cd, run 29673849108/1, prepare job 88157456895, P08-PREPARED-INTENT-BINDING, raw cross-OS moon ZIP-container drift, and zero downstream effects.
- [Phase 08]: Every r8 intent, prepared, authority, receipt, and handoff contract carries eight individual history digests plus their canonical LF-ordered set digest.
- [Phase 08]: DIST-01 remains pending because Plan 08-19 performs no tag creation, hosted dispatch, registry observation, credential access, mutation, or publication.
- [Phase 08]: Canonical ZIP identity uses EOCD-bounded central-directory parsing with safe ordered paths, exact payloads, fixed Unix metadata, and stored compression. — Host/runtime ZIP container bytes must not influence r8 release identity.
- [Phase 08]: Prepared archive validation canonicalizes only a disposable copy and requires exact core-color-image digest agreement across intent, manifest, and bytes. — Validation must reject raw or recompressed payloads rather than silently repairing them.
- [Phase 08]: DIST-01 remains pending after Plan 08-20. — This plan performed no tag, hosted dispatch, registry observation, credential access, mutation, or publication.
- [Phase 08]: Publisher, workflow, and hosted seams accept only r8 with eight ordered histories while exact14 remains unchanged.
- [Phase 08]: The r8 selector binds exact r7 terminal evidence, canonical archives, committed ancestry, and r8 absence without persistent output.
- [Phase 08]: DIST-01 remains pending because 08-21 intentionally performs no external release action.
- [Phase 08]: r8 is immutable pre-live terminal evidence: source 8d0f050, tag object 20907c7, and PREP15-CANONICAL-ARCHIVE / REL-XPLAT-NONCANONICAL occurred before locator, run, credential, packet, receipt, handoff, mutation, or successor effects.
- [Phase 08]: r9 is immutable terminal evidence: its remote annotated tag peels to 4158dff and its PrepareAttempt stopped under StrictMode before a locator, run, credential, packet, receipt, handoff, mutation, or successor effect.
- [Phase 08]: r10 is the sole current forward retry; it binds ten individual terminal-history digests plus their LF-ordered set, including r9's exact partial-terminal evidence.
- [Phase ?]: r10 is the sole current retry; r9 is immutable pre-locator StrictMode terminal evidence bound by ten individual history digests plus an LF-ordered set.
- [Phase ?]: r11 is the sole current retry; r10 is immutable clean-clone REL01-REF terminal evidence bound by eleven individual digests and their LF-ordered aggregate.
- [Phase ?]: r12 pre-live is credential-free and zero-write: it binds immutable r11 tag/peel and canonical-wrapper evidence, r12 absence, and an absent handoff.
- [Phase ?]: Publisher, live adapter, HostedRun, and workflow require twelve individual history digests plus the canonical LF aggregate; stale r11 authority cannot reach the adapter.
- [Phase ?]: r12 (object 57b76c9f, peel 5e7b19cd) is publish-blocked terminal evidence — its boundary commit declared policy release_ref=r12 but Invoke-ReleaseQualification.ps1 still hardcoded r9, so its own qualification throws REL01-REF deterministically; the r12 script fix (d55f63a) landed 26 min after the immutable tag. r13+ must be the forward retry; do not retry r12.
- [Phase ?]: Order tag creation after script/policy ref agreement — before creating any future boundary tag rN, verify at the candidate commit that (1) Invoke-ReleaseQualification.ps1 references refs/tags/modules-v0.1.0-rN on every -ReleaseRef, (2) policy/release-control.json declares current_attempt=rN and release_ref=refs/tags/modules-v0.1.0-rN, (3) the boundary wrapper completes PrepareAttempt (not just InitializeBoundary) in a disposable clone. This closes the gap that let r12 tag a self-inconsistent commit.

### Pending Decisions

- Execute r9 static contracts and hosted/pre-live seam before creating an r9 boundary.
- Preserve the distinction between verified local account/environment readiness and authority proven by successful exact publication plus read-only registry observation.

### Blockers

None

## Session Continuity

**Resume file:** None

Last session: 2026-07-19T20:30:00Z
Stopped at: 08-32-SUMMARY.md committed (satisfied-by-prior-run); 08-33 awaits explicit authorize-core
Resume with: `/gsd-execute-phase 8` ONLY after operator explicitly authorizes 08-33 publication

## Operator Next Steps

- 08-32 is reconciled as satisfied-by-prior-run (immutable r12 tag 57b76c9f / peel 5e7b19cd already exists locally+remotely, ancestor of HEAD).
- 08-33 is quarantined and obsolete: it was scoped to r12 authority and must never be dispatched, resumed, or used for publication. r12 is immutable terminal REL01-REF evidence only.
- The active route is static r13 recovery through 08-34 then 08-35. A later plan must separately create and verify an immutable r13 boundary; only a distinct later r13 plan may request explicit authorization for any publication.
- A current-HEAD eight-path baseline must be recaptured before any future pre-live or publisher run that evaluates the baseline against working-tree content (the captured baseline is stale vs current HEAD).
- Watch: two non-baseline files appeared modified mid-session (`release/qualification/phase-06-requirements.json`, `release/registry/authority-observation.json`) — investigate whether a sibling process is editing release artifacts.

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
| Phase 08 P02 | 15min | 2 tasks | 4 files |
| Phase 08 P03 | 28min | 3 tasks | 6 files |
| Phase 08 P04 | 29min | 3 tasks | 7 files |
| Phase 08 P05 | 9min | 2 tasks | 10 files |
| Phase 08 P06 | 20min | 3 tasks | 9 files |
| Phase 08 P07 | 13min | 3 tasks | 13 files |
| Phase 08 P08 | 18min | 2 tasks | 8 files |
| Phase 08 P09 | 16min | 3 tasks | 13 files |
| Phase 08 P10 | 16min | 2 tasks | 8 files |
| Phase 08 P11 | 10min | 3 tasks | 13 files |
| Phase 08 P12 | 15min | 2 tasks | 8 files |
| Phase 08 P13 | 9min | 3 tasks | 13 files |
| Phase 08 P14 | 17min | 2 tasks | 8 files |
| Phase 08 P15 | 10min | 3 tasks | 13 files |
| Phase 08 P16 | 25min | 3 tasks | 10 files |
| Phase 08 P17 | 14min | 3 tasks | 13 files |
| Phase 08 P18 | 32min | 3 tasks | 10 files |
| Phase 08 P19 | 13min | 3 tasks | 13 files |
| Phase 08 P20 | 15min | 2 tasks | 6 files |
| Phase 08 P21 | 24min | 3 tasks | 10 files |
| Phase 08 P24 | 54min | 2 tasks | 13 files |
| Phase 08 P27 | 45min | 2 tasks | 12 files |
| Phase 08 P31 | 10min | 2 tasks | 10 files |
