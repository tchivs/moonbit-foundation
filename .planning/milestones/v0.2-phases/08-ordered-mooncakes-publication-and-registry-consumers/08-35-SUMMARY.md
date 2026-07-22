---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "35"
subsystem: release-governance
tags: [r13, hosted-preparation, publisher-seams, static-history, tdd]
requires: [08-34]
provides:
  - r13 thirteen-history hosted preparation binding with post-checkout exact-tag verification
  - r13 thirteen-history propagation through publisher, live adapter, and publish workflow seams
  - static-only r13 authority contract (no tag, no dispatch, no credential, no publication)
affects: [08-36, r13-boundary-establishment, r13-publication]
tech-stack:
  added: []
  patterns:
    - post-checkout exact-tag fetch-and-verify gate before any preparation state creation
    - closed thirteen-history field set with recomputed LF aggregate at every publisher boundary
key-files:
  created: []
  modified:
    - scripts/quality/New-PreparedReleaseBundle.ps1
    - scripts/quality/New-ReleaseIntent.ps1
    - scripts/quality/ReleaseQualification.Common.ps1
    - scripts/quality/Test-PreparedReleaseBundle.ps1
    - scripts/quality/Invoke-Phase08HostedRun.ps1
    - scripts/quality/Test-Phase08Qualification.ps1
    - scripts/quality/Test-Phase08PrepareHistorySchema.ps1
    - scripts/quality/Invoke-ReleasePublisher.ps1
    - scripts/quality/Invoke-MooncakesLiveMutation.ps1
    - .github/workflows/publish-modules.yml
    - scripts/quality/Test-ReleasePublisherNegative.ps1
    - scripts/quality/Test-Phase08LiveSeam.ps1
decisions:
  - Hosted r13 preparation must verify a post-checkout fetched exact policy tag before it may create any local preparation state; disagreement fails before state/provider work.
  - Publisher-facing seams require r13 plus all thirteen ordered histories (attempt-zero through r12) and their LF aggregate, and remain static-only — they cannot authorize, tag, dispatch, or publish.
  - r12 is carried only as immutable REL01-REF terminal history (source 5e7b19cd, tag object 57b76c9f, failure_code REL01-REF, authority_acquired false); it never supplies current r13 authority.
  - The eight-path user-dirty baseline guard (Plan 34) runs before and after every task and proves unchanged user dirties.
key-commits:
  - caefb4a test(08-35): add r13 prepared bundle history coverage
  - 89b0184 feat(08-35): bind prepared validation to r13 history
  - 2c77144 feat(08-35): gate r13 hosted preparation
  - 8920d82 feat(08-35): propagate r13 publisher history
  - 4b21b39 fix(08-35): complete r13 static handoff history
metrics:
  tasks_completed: 2
  duration: ~49min (22:05–22:54 +08:00)
status: complete
---

# Phase 8 Plan 35: r13 Hosted Preparation and Publisher Seams — Summary

**r13 thirteen-history authority now flows through hosted preparation (with a post-checkout exact-tag verification gate) and through the publisher, live adapter, and publish-workflow seams — all static-only, with r12 carried as immutable REL01-REF terminal history and no tag, dispatch, credential, or publication performed.**

## Performance

- **Tasks:** 2
- **Files modified:** 12 (release qualification + hosted run + publisher + adapter + workflow + 5 test suites)
- **Commits:** 5 (one RED test commit, three feat, one fix-to-green closeout)

## Accomplishments

### Task 1 — Hosted r13 preparation gate

- Added a post-checkout exact-tag fetch-and-verify gate: hosted r13 preparation checks out the boundary SHA, fetches the exact policy tag, and verifies identity before it may create any local preparation state. Any disagreement fails before state or provider work.
- Bound the r13 thirteen-history intent ordering through `New-PreparedReleaseBundle`, `New-ReleaseIntent`, `ReleaseQualification.Common`, and `Invoke-Phase08HostedRun`.
- r12 is recorded only as immutable REL01-REF terminal history (source `5e7b19cd`, tag object `57b76c9f`, `failure_code=REL01-REF`, `authority_acquired=false`, `mutation_count=0`); it never supplies current r13 authority.

### Task 2 — Publisher and adapter r13 seams

- Propagated r13 plus all thirteen ordered histories (attempt-zero through r12) and their canonical LF aggregate through `Invoke-ReleasePublisher`, `Invoke-MooncakesLiveMutation`, and `.github/workflows/publish-modules.yml`.
- Publisher and adapter reject stale r12 authority, a missing r12 digest, an altered aggregate, a non-r13 ref, or a more-than-one-module request before any adapter execution.
- All seams remain static-only: no tag creation, no workflow dispatch, no credential materialization, no authorization receipt/handoff, no Mooncakes request, no registry mutation, no publication.

## Verification (all PASS, re-run by orchestrator on closeout)

Task 1 verify:
- `Assert-Phase08R13DirtyBaseline -Mode Verify` (before and after) — PASS
- `Test-ReleaseIntent.ps1` — PASS
- `Test-PreparedReleaseBundle.ps1` — PASS
- `Test-Phase08Qualification.ps1 -FixtureOnly` — PASS
- `Test-Phase08PrepareHistorySchema.ps1` — PASS

Task 2 verify:
- `Assert-Phase08R13DirtyBaseline -Mode Verify` (before and after) — PASS
- `Test-ReleasePublisherNegative.ps1` — PASS
- `Test-Phase08LiveSeam.ps1` — PASS

Baseline equality retained across both tasks (eight protected paths unchanged).

## What this plan did NOT do

- No r13 tag created, pushed, or verified on a remote.
- No pre-authorization, handoff, packet, or receipt artifact produced.
- No `PublishOne`, workflow dispatch, credential access, registry observation, or publication.
- r12 was not re-tried, re-tagged, or repaired in place — it remains immutable terminal evidence.

## Forward constraints

- An r13 boundary still does not exist. A separate later plan must create and verify an immutable r13 tag (this time the qualification script's `-ReleaseRef` and the policy must agree before tagging, per the ordering invariant recorded in STATE.md).
- Only a still-later r13-specific plan, after the r13 boundary is established and fresh qualification passes, may request explicit operator `authorize-core` authorization and attempt one ordered module operation.
- `Invoke-ReleaseQualification.ps1` (lines 303, 314, 354) still hardcodes `refs/tags/modules-v0.1.0-r12`. This is acceptable for the static seam work in 08-35 (tests pass), but **the r13 boundary-establishment plan must update these to r13 before the r13 tag is created**, otherwise the same REL01-REF failure that blocked r12 will recur. This is flagged as a known forward constraint, not a defect in 08-35.
