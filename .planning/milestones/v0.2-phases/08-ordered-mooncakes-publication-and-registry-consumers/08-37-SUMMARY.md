---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "37"
subsystem: release-governance
tags: [r13, boundary-tag, ordering-invariant, non-publishing, tdd]
requires: [08-36]
provides:
  - immutable r13 boundary tag (refs/tags/modules-v0.1.0-r13, object 611fb286, peel 003b604)
  - r13 boundary wrapper (Invoke-Phase08R13Boundary.ps1) with no caller-controlled ReleaseRef
  - r13 zero-write pre-tag absence selector (Invoke-Phase08R13PreLive.ps1)
  - proven ordering-invariant evidence (script/policy/wrapper agree on r13 BEFORE the tag was created)
affects: [08-38, r13-publication]
tech-stack:
  added: []
  patterns:
    - ordering-invariant gate — prove script/policy/wrapper agreement in a disposable clone BEFORE creating any immutable boundary tag (the gate r12 violated)
    - non-force annotated tag push with pre-tag absence re-check
key-files:
  created:
    - scripts/quality/Invoke-Phase08R13Boundary.ps1
    - scripts/quality/Invoke-Phase08R13PreLive.ps1
    - scripts/quality/Test-Phase08R13Boundary.ps1
    - scripts/quality/Test-Phase08R13PreLive.ps1
  modified:
    - scripts/quality/Invoke-ReleaseQualification.ps1   # lines 303/314/354 r12→r13
    - .planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/08-R13-RECOVERY-CONTEXT.md
key-commits:
  - 003b604 feat(08-37): advance qualification and r13 boundary wrappers
decisions:
  - r13 boundary tag is immutable (local object 611fb286 == remote; peel 003b604 is ancestor of main HEAD).
  - The ordering invariant r12 violated is now satisfied: Task 2 proved in a disposable clone that Invoke-ReleaseQualification.ps1 (0 r12 / 3 r13 matches on lines 303/314/354), policy/release-control.json (current_attempt=r13, release_ref=refs/tags/modules-v0.1.0-r13), and the r13 boundary wrapper's PrepareAttempt all agree on r13 BEFORE the tag was created.
  - Task 3 Steps 1-6 (tag creation, push, identity verification, disposable remote-clone canonical boundary returning a zero-mutation closed record) are complete.
  - Task 3 Steps 7-9 (HostedPreflight, PublisherDryRun, absent-variant preauthorization.json) are DEFERRED to plan 08-38 because Invoke-Phase08HostedRun.ps1's publication path is hard-coded to r12 (lines 208, 229, 662, 667, 1042). This is a plan-defect in 08-37's scope assumption, not an execution failure. The core Task 3 <done> deliverable — an immutable r13 boundary tag verified zero-mutation — IS satisfied.
  - Task 4 (authorize-core checkpoint) was not reached; it is deferred to 08-38 alongside the publication-path upgrade.
metrics:
  tasks_completed: 3_of_4 (Task 4 deferred to 08-38)
  status: boundary-established-publication-deferred
---

# Phase 8 Plan 37: r13 Boundary Establishment — Summary

**r13 immutable boundary tag is established (object 611fb286 peeling to 003b604, byte-identical locally and remotely, ancestor of main HEAD) with the ordering-invariant fix that r12 violated. The publication-path validation (preflight, dry-run, preauthorization) is deferred to plan 08-38 because the HostedRun publication modes are still hard-coded to r12.**

## Performance

- **Tasks:** 3 of 4 complete (Task 4 deferred)
- **Files:** 4 created, 2 modified
- **Commits:** 1 (`003b604`)
- **Tag created:** `refs/tags/modules-v0.1.0-r13` (object `611fb2862533ffd959ed830a222da663df80af49`, peel `003b604978a06c87858fe2cdc0a1969fd20159f7`)

## Accomplishments

### Task 1 — r13 script + boundary wrappers
- Updated `Invoke-ReleaseQualification.ps1` lines 303/314/354 from `refs/tags/modules-v0.1.0-r12` → `refs/tags/modules-v0.1.0-r13` (verified: 0 r12 matches, 3 r13 matches).
- Created `Invoke-Phase08R13Boundary.ps1` — canonical clone-policy wrapper with no caller-controlled `-ReleaseRef` (derives r13 from clone-local `policy/release-control.json` only).
- Created `Invoke-Phase08R13PreLive.ps1` — zero-write pre-tag absence selector.
- Created `Test-Phase08R13Boundary.ps1` and `Test-Phase08R13PreLive.ps1` — both PASS.
- Annotated `08-R13-RECOVERY-CONTEXT.md` with the 2026-07-19 authorization update.

### Task 2 — The ordering-invariant gate (the r12 fix)
This is the gate r12 never had. Proven in a disposable clone at HEAD `003b604`:
- **Step 3:** `Select-String` confirms `Invoke-ReleaseQualification.ps1` has 0 `r12` matches and exactly 3 `r13` matches on lines 303/314/354.
- **Step 4:** `policy/release-control.json` declares `current_attempt=r13`, `release_ref=refs/tags/modules-v0.1.0-r13`, thirteen histories with `history_set_sha256=961780e0...`.
- **Step 5:** In a disposable `--no-local --no-tags` clone with a synthesized r13 fixture tag, `Invoke-Phase08R13Boundary.ps1` derived `refs/tags/modules-v0.1.0-r13` from clone-local policy and reached the provider exactly once with the r13 context — proving script, policy, and wrapper agree BEFORE any real tag exists.
- **Step 6:** Negative control (mismatched `ExpectedTagObject`) threw `P08-R13-TAG` before provider invocation.
- Baseline equality retained before and after.

### Task 3 — r13 boundary tag (Steps 1-6 complete)
- Pre-tag absence re-check passed (`Invoke-Phase08R13PreLive -Check` returned `eligible=true, mutation_count=0`).
- Created + pushed ONE non-force annotated tag `refs/tags/modules-v0.1.0-r13` at the proven HEAD `003b604`.
- Tag identity verified: local object `611fb286` == remote; peel `003b604` is ancestor of HEAD.
- Disposable remote-clone canonical boundary invocation returned a zero-mutation closed record (`release_ref=refs/tags/modules-v0.1.0-r13, mutation_count=0`); the clone-local default provider ran a real `Invoke-ReleaseQualification.ps1 -Check` that packaged mb-core, mb-color, and mb-image.

## What this plan did NOT do (deferred to 08-38)

- Task 3 Steps 7-9 (HostedPreflight, PublisherDryRun, `%TEMP%/mnf-phase08-r13-preauthorization.json`) — blocked because `Invoke-Phase08HostedRun.ps1` publication modes are hard-coded to r12 (lines 208, 229, 662, 667, 1042). Upgrading them is publication-path work that belongs in 08-38 alongside the authorize-core flow.
- Task 4 (authorize-core checkpoint) — not reached; deferred to 08-38.
- No Mooncakes mutation, no workflow dispatch, no credential access, no receipt, no handoff.
- `%TEMP%/mnf-phase08-r13-preauthorization.json` and `%TEMP%/mnf-phase08-r13-handoff.json` are both correctly absent.

## Plan-defect note

08-37's Task 3 assumed the publication path (HostedPreflight/PublisherDryRun/ValidatePreAuthorization) could run for r13. This was incorrect: 08-35 upgraded the static thirteen-history seams but left the publication-path modes r12-hard-coded. This is a scoping defect in 08-37, recorded here so 08-38 can address it deliberately rather than as an ad-hoc execution workaround.

## Forward constraints for 08-38

- Upgrade `Invoke-Phase08HostedRun.ps1` publication modes from r12 to r13 (5 sites: lines 208, 229, 662, 667, 1042), with adversarial tests.
- After the publication path accepts r13, run HostedPreflight + PublisherDryRun (publisher-only temp Moon home + teardown) and emit the absent-variant `preauthorization.json`.
- Then surface the authorize-core/stop checkpoint; on authorize-core, execute the ordered module publication (mb-core → mb-color → mb-image) with cold consumer proof per DIST-01..04 and PROV-05.
- Recapture the eight-path baseline against the current HEAD before 08-38 execution (the Task 2 baseline was consumed).
