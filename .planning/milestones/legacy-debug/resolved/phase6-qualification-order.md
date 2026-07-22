---
status: resolved
trigger: "Phase 6 plan 06-13 real release qualification fails because shared qualification constants and module repository metadata are migrated after the plan that consumes them."
created: 2026-07-17T00:00:00+08:00
updated: 2026-07-17T19:08:00+08:00
---

## Symptoms

- expected: Plan 06-13 Task 2 runs the real positive `Invoke-ReleaseQualification.ps1` path after canonical `tchivs/*` migration.
- actual: Static checks pass, but real qualification fails before consumers because `ReleaseQualification.Common.ps1` still freezes the old owner/repository; a temporary projection then exposes old repository fields in the three module manifests.
- error: `Release policy identity, repository, or fixture manifest drifted.` then `mb-core manifest field 'repository' drifted from release policy.`
- timeline: First observed while executing Wave 9 plan 06-13 after successful plans 06-07, 06-12, 06-08, and 06-09.
- reproduction: Run the positive release qualification required by 06-13 Task 2 in the current checkout.

## Current Focus

- hypothesis: Confirmed: the repaired Phase 6 plan graph places all four canonical qualification prerequisites before the resumed 06-13 Task 2 path.
- test: Orchestrator reviewed and approved the bounded ownership and resume checkpoint after GSD graph validation passed.
- expecting: Pending execution begins at 06-25, then resumes 06-13 at Task 2 while preserving `9f05754` and the current Task 2 scripts.
- next_action: Execute approved plan 06-25.

reasoning_checkpoint:
  hypothesis: "06-13 fails because its real qualification consumes four canonical-identity prerequisites that the plan graph leaves stale until or beyond that plan."
  confirming_evidence:
    - "The exact 06-13 Task 2 command deterministically fails at ReleaseQualification.Common.ps1:427 because policy already uses the tchivs repository while the helper freezes the old organization URL."
    - "All three module manifests still carry the old repository URL although their names and dependency floors were migrated by completed plan 06-12."
    - "The helper contains additional old positive package, publication-order, and dependency constants and is scheduled only in later plan 06-14."
  falsification_test: "The hypothesis would be false if a completed predecessor already owned and migrated all four files, or if 06-13 did not execute the shared helper."
  fix_rationale: "A dedicated pre-06-13 plan restores dependency ownership while preserving completed evidence, 06-13's existing seven-file budget, and the partial Task 1 commit."
  blind_spots: "The repair plan still must be executed before the full positive path can prove whether any further stale file exists; its task includes a canonical-positive scan and the exact qualification command to expose that safely."

## Evidence

- timestamp: 2026-07-17T00:00:00+08:00
  observation: 06-13 Task 1 committed as `9f05754`; Task 2 scripts remain uncommitted.
- timestamp: 2026-07-17T00:00:00+08:00
  observation: Temporary `ReleaseQualification.Common.ps1` projection was restored; the second failure is the old repository URL in module manifests.
- timestamp: 2026-07-17T18:40:00+08:00
  observation: Plan 06-12 deliberately changed module names and dependencies while preserving all other closed metadata, leaving all three repository fields at the old organization URL; its completed summary confirms exactly that bounded scope.
- timestamp: 2026-07-17T18:41:00+08:00
  observation: Plan 06-13 depends only on 06-09 and invokes the real positive qualification, while `ReleaseQualification.Common.ps1` is not scheduled for migration until plan 06-14, which itself depends on the post-06-13 documentation chain.
- timestamp: 2026-07-17T18:46:00+08:00
  observation: The exact 06-13 Task 2 positive command fails deterministically at `ReleaseQualification.Common.ps1:427` with `Release policy identity, repository, or fixture manifest drifted.` before consumer execution.
- timestamp: 2026-07-17T18:47:00+08:00
  observation: The helper contains stale positive repository, package-order, PPM import, post-publish, and dependency constants; the two uncommitted 06-13 Task 2 scripts contain no old positive module or repository identity.
- timestamp: 2026-07-17T18:58:00+08:00
  observation: Added plan 06-25 with exactly four source files, changed 06-13 to depend on it, shifted only pending waves, removed later duplicate helper ownership from 06-14, and added an explicit 06-13 Task 2 resume marker.
- timestamp: 2026-07-17T19:00:00+08:00
  observation: `gsd-tools phase-plan-index 6` reports one plan per wave through the repaired chain and `gsd-tools validate consistency` passes with no errors; only pre-existing future-phase-directory warnings remain.

## Eliminated

- hypothesis: The package consumer migration is wrong.
  reason: Task 1 verification passed and the consumer files are committed.

## Resolution

- root_cause: Phase 6 omitted a prerequisite plan between 06-09 and 06-13 for the three manifest repository fields and the shared qualification helper, so 06-13 consumes mixed canonical/stale identity truth before 06-14 would migrate the helper.
- fix: Add a bounded pre-06-13 repair plan and rewire only pending plan dependencies/waves plus the 06-13 resume handoff; leave completed plans/summaries and partial commit `9f05754` intact.
- verification: Phase plan indexing and GSD consistency validation pass; git diff check passes; exact failure reproduction and static ownership scans are recorded; orchestrator approved the bounded graph repair. Source execution remains intentionally delegated to approved plan 06-25.
- files_changed: .planning/phases/06-namespace-authority-and-compatibility-contract/06-25-PLAN.md, .planning/phases/06-namespace-authority-and-compatibility-contract/06-13-DEFERRED.md, pending Phase 6 PLAN.md wave/dependency metadata, .planning/ROADMAP.md
