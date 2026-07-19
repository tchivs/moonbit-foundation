---
status: awaiting_human_verify
trigger: "Phase 8 r4 HostedPreflight run 29667231047 fails in a clean Linux checkout because Assert-ReleaseTrackedSnapshot rejects the legitimate empty-string tracked diff snapshot."
created: 2026-07-19
updated: 2026-07-19T00:43:00Z
phase: "08"
plan: "13"
---

# Clean Diff Empty Binding

## Symptoms

- expected: HostedPreflight should accept identical empty tracked-diff snapshots before and after release qualification in a clean checkout.
- actual: The prepare job stops before producing its prepared artifact because the empty `Before` snapshot cannot bind to a mandatory string parameter.
- errors: `Cannot bind argument to parameter 'Before' because it is an empty string.` at `Assert-ReleaseTrackedSnapshot -Before $initialDiff -After $finalDiff`.
- timeline: First observed in immutable r4 HostedPreflight run `29667231047/1`; the equivalent local run occurred in a user-dirty checkout and therefore supplied a non-empty diff.
- reproduction: Run `Invoke-ReleaseQualification.ps1 -Check` from a clean Linux checkout where both `git diff --binary --no-ext-diff HEAD --` snapshots are empty strings.

## Current Focus

reasoning_checkpoint:
  hypothesis: `Assert-ReleaseTrackedSnapshot` declares mandatory string parameters without `AllowEmptyString`, so PowerShell rejects the valid clean-tree baseline before the function can compare equality.
  confirming_evidence:
    - Hosted run 29667231047 reached release qualification and completed all three package checks before failing at the tracked snapshot call.
    - `Get-ReleaseTrackedDiffSnapshot` intentionally joins zero diff lines into an empty string in a clean checkout.
    - `Assert-ReleaseTrackedSnapshot` uses mandatory string parameters and only needs ordinal equality semantics.
  falsification_test: A focused clean-tree regression must still fail before the fix and pass after allowing empty snapshots, while unequal non-empty snapshots remain rejected.
  fix_rationale: Permit empty strings at the comparison boundary without weakening the equality check or changing tracked-source mutation detection.
  blind_spots: Local Windows checkout is user-dirty, so the permanent regression must explicitly exercise empty inputs independent of ambient worktree state.
next_action: preserve immutable r4 failure and verify the committed fix only on a new forward boundary; never retry or move r4

## Evidence

- timestamp: 2026-07-19T00:37:39Z
  checked: immutable r4 HostedPreflight run 29667231047/1
  found: prepare failed before artifact upload, PublisherDryRun, credentials, packet, receipt, handoff, mutation, or publication.
  implication: r4 is terminal for this plan and must not be retried or moved.

- timestamp: 2026-07-19T00:40:30Z
  checked: focused RED in Test-ReleaseQualificationNegative.ps1
  found: the new equal-empty snapshot case failed with the exact hosted error before entering Assert-ReleaseTrackedSnapshot.
  implication: mandatory string binding, not Git diff behavior or package qualification, is the reproduced root cause.

- timestamp: 2026-07-19T00:42:30Z
  checked: focused GREEN and adjacent release-contract suites
  found: Test-ReleaseQualificationNegative, Test-ReleaseIntent -ContractOnly, and Test-Phase08LiveSeam -HostedFieldsOnly all passed; unequal snapshots still fail with REL14-TRACKED-SOURCE-MUTATION.
  implication: allowing empty strings preserves mutation detection while admitting the clean-tree equality case.

## Eliminated

## Resolution

root_cause: Get-ReleaseTrackedDiffSnapshot intentionally returns an empty string for a clean checkout, but Assert-ReleaseTrackedSnapshot declared mandatory string parameters without AllowEmptyString, so PowerShell rejected valid empty baselines before equality comparison.
fix: Added AllowEmptyString to both snapshot parameters and a permanent equal-empty regression beside the existing unequal mutation rejection.
verification: Focused RED reproduced the hosted binding error. GREEN passed Test-ReleaseQualificationNegative, Test-ReleaseIntent -ContractOnly, and Test-Phase08LiveSeam -HostedFieldsOnly. No network action, hosted retry, secret access, receipt, handoff, mutation, publication, or r4 ref change occurred during the fix.
files_changed: [scripts/quality/ReleaseQualification.Common.ps1, scripts/quality/Test-ReleaseQualificationNegative.ps1, .planning/debug/clean-diff-empty-binding.md]
