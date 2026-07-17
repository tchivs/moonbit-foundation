---
phase: 06-namespace-authority-and-compatibility-contract
plan: "13"
status: deferred
decision_date: 2026-07-17
decision: repair-prerequisite-and-resume
resume_after: 06-25
requirements_pending: [COMP-01, COMP-02, COMP-03, COMP-04, PROV-03]
---

# 06-13 Qualification Consumer Plan Deferred at Task 2

Plan 06-13 started before the shared qualification prerequisites were canonical. Task 1 is complete and committed; Tasks 2 and 3 remain pending. This marker preserves the partial execution boundary while the bounded 06-25 repair plan runs first.

## Completed work retained

- `9f05754` — migrated the bounded positive leaf qualification consumer to `tchivs/mb-core@0.1.0`.
- Task 1 verification passed.
- The current uncommitted changes in `scripts/quality/Invoke-ReleaseQualification.ps1` and `scripts/quality/Test-ReleaseQualification.ps1` are Task 2 work in progress and must be preserved, not staged by 06-25.

## Root cause and repair boundary

- The real Task 2 path consumes `scripts/quality/ReleaseQualification.Common.ps1`, which still freezes old positive repository, package, dependency, and publication-order constants.
- The three module manifests have canonical names and dependencies but still carry the obsolete organization repository URL.
- Plan 06-25 owns exactly those four prerequisites. It does not rewrite completed 06-12 evidence and does not widen 06-13's seven-file budget.

## Safe continuation

1. Execute and complete 06-25 while preserving `9f05754` and both uncommitted Task 2 scripts.
2. Resume 06-13 at Task 2; rerun the exact real positive qualification command.
3. Complete Task 3 exact negative ownership, then create `06-13-SUMMARY.md` covering the retained Task 1 commit and resumed work.

## Resume condition

Resume 06-13 only after `06-25-SUMMARY.md` exists and its four-file static verification passes. No external authentication, repository creation, push, or publication is required.
