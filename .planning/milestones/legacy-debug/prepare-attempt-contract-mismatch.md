---
status: awaiting_human_verify
trigger: "Plan 08-07 Task 2 could not invoke PrepareAttempt because the helper lacks planned historical/boundary parameters and does not create fresh intent/prepared/store evidence."
created: 2026-07-18
updated: 2026-07-18T20:15:00Z
phase: "08"
plan: "07"
---

# PrepareAttempt Contract Mismatch

## Symptoms

- expected: From a validated boundary locator, `PrepareAttempt` accepts the exact Plan 08-07 parameters, preserves historical failed evidence, creates a fresh r1 root/current intent, genesis journal, prepared bundle, locator/index/store entries, and returns their digests without external actions.
- actual: Helper blob `669e4f575502d0d2101527a62f548137d9616f32` lacks BoundaryLocatorPath and Historical* parameters, globally requires Repository/Workflow and later release/module/locator bindings, and only validates caller-supplied PreparedRoot/StateRoot.
- errors: PowerShell parameter binding/prevalidation cannot execute the committed Task 2 command.
- timeline: Detected after Task 1 successfully pushed and initialized boundary `77c8ec7f76c2ae8e811b0d61e88741269768bc76`.
- reproduction: Invoke the clean-clone helper with the exact PrepareAttempt command block from 08-07 Task 2.

## Current Focus

hypothesis: Confirmed and self-verified — the exact contract composes the missing attempt evidence and all focused/adjacent local tests pass.
test: Human/operator verification must rerun the exact Plan 08-07 PrepareAttempt command from a newly committed and pushed clean boundary containing this fix.
expecting: The real no-provider invocation returns the same closed result and creates the same v2 store shape without hosted dispatch, secret access, tag mutation, or publication.
next_action: Await human verification in the real clean-clone workflow; archive only after confirmation.
reasoning_checkpoint:
  hypothesis: "PrepareAttempt fails because the helper omits and pre-rejects the plan's inputs, then has no production composition; New-PreparedReleaseBundle independently rejects r1."
  confirming_evidence:
    - "The RED fixture fails at PowerShell binding on BoundaryLocatorPath before any evidence provider runs."
    - "Helper lines 508-523 route PrepareAttempt through later bindings and only echo caller paths."
    - "New-PreparedReleaseBundle's release-ref regex accepts the terminal base tag and corrections, not r1."
  falsification_test: "If the exact unchanged plan-shaped invocation still cannot create and reopen a digest-valid v2 store after only these seams change, the hypothesis is incomplete."
  fix_rationale: "Mode-specific validation removes the erroneous precondition, while composition through existing builders creates the missing authority evidence instead of papering over the binder error."
  blind_spots: "The fixture replaces full qualification/package execution with a local test provider; focused existing qualification and prepared-bundle suites must cover those builders separately."
tdd_checkpoint:
  test_file: scripts/quality/Test-Phase08Qualification.ps1
  test_name: exact Plan 08-07 PrepareAttempt invocation with historical missing/mismatch negatives
  status: green
  failure_output: "A parameter cannot be found that matches parameter name 'BoundaryLocatorPath'."
  green_result: "Phase 8 qualification fixtures/static contract: PASS (exact call, missing/mismatch negatives, and later-mode closed matrix)."

## Evidence

- timestamp: 2026-07-18T00:00:00Z
  fact: Task 1 succeeded at boundary 77c8ec7 with a clean detached clone and digest-bound empty locator/index.
- timestamp: 2026-07-18T00:00:01Z
  fact: r1 tag, active attempt, hosted runs, packet, and publication remain absent.
- timestamp: 2026-07-18T00:00:02Z
  fact: Helper blob 669e4f575502d0d2101527a62f548137d9616f32 lacks the planned parameters and PrepareAttempt production behavior.
- timestamp: 2026-07-18T20:05:00Z
  checked: Invoke-Phase08HostedRun.ps1 lines 508-523 against 08-07-PLAN.md lines 130-132.
  found: PrepareAttempt is forced through Repository/Workflow plus release/source/root/current/prepared/module/locator/artifact prevalidation, does not accept BoundaryLocatorPath or HistoricalRunId/Attempt/ReleaseRef/SourceSha, and only returns PreparedRoot/StateRoot.
  implication: The exact Plan 08-07 call cannot bind and no fresh intent, journal, prepared bundle, v2 locator/index, or historical-negative evidence can be created.
- timestamp: 2026-07-18T20:05:01Z
  checked: New-PreparedReleaseBundle.ps1 Assert-PreparedBindings.
  found: The existing prepared builder still accepts the terminal attempt-zero tag but rejects refs/tags/modules-v0.1.0-r1.
  implication: Composition also requires correcting the builder's release-ref guard or the fresh r1 prepared bundle will fail after PrepareAttempt is wired.
- timestamp: 2026-07-18T20:06:00Z
  checked: Exact Plan 08-07-shaped PrepareAttempt fixture in Test-Phase08Qualification.ps1.
  found: RED reproduces deterministically with PowerShell parameter-binding failure for BoundaryLocatorPath before the local-only provider or any evidence write.
  implication: The missing command contract is directly reproduced and isolates the first divergence before runtime composition.
- timestamp: 2026-07-18T20:10:00Z
  checked: Counterfactual GREEN run of Test-Phase08Qualification.ps1 -FixtureOnly.
  found: Exact plan-shaped PrepareAttempt creates and reopens a digest-valid v2 store with fresh r1 root/current intent, genesis journal, prepared manifest, and indexed historical 29652468948/1 evidence; missing HistoricalRunId and mismatched HistoricalSourceSha fail closed; incomplete later modes do not dispatch.
  implication: The fix addresses the confirmed composition/binding mechanism while preserving the later-mode guard boundary.
- timestamp: 2026-07-18T20:10:01Z
  checked: Boundary locator digest reload during GREEN verification.
  found: ConvertFrom-Json materializes ISO timestamps as DateTime using local-zone semantics, so the generic digest projection could change bytes after reload.
  implication: Canonicalizing both string and DateTime timestamp representations is required for stable locator verification across Asia/Shanghai and UTC environments.
- timestamp: 2026-07-18T20:15:00Z
  checked: Focused and adjacent regression suites.
  found: Test-PreparedReleaseBundle full matrix, Test-ReleaseIntent -ContractOnly, Test-ReleasePublisherNegative -ReducerOnly, Test-Phase08LiveSeam, Test-Phase07Qualification -WorkflowOnly, and Test-PreparedReleaseBundle -WorkflowOnly all pass.
  implication: The r1 guard and mode-specific preparation changes preserve deterministic prepared evidence, reducer safety, and hosted/live static contracts.
- timestamp: 2026-07-18T20:15:01Z
  checked: Three consecutive Test-Phase08Qualification -FixtureOnly stability runs plus git diff --check.
  found: All three exact PrepareAttempt runs pass with zero failures; missing/mismatch and incomplete-later-mode cases remain closed; diff check is clean.
  implication: The fix is stable under repeated locator creation/reload and introduces no whitespace errors.

## Eliminated

- hypothesis: A harmless invocation rewrite can use the current helper.
  reason: Current helper requires caller-supplied evidence and does not produce the immutable attempt artifacts promised by the plan; rewriting would change authority ordering.

## Resolution

root_cause: Invoke-Phase08HostedRun.ps1 never implemented PrepareAttempt's mode-specific boundary/historical parameter contract or composition root, and New-PreparedReleaseBundle.ps1 retained an obsolete attempt-zero ref guard that rejects r1.
fix: Added mode-specific BoundaryLocatorPath and historical parameters; implemented local-only PrepareAttempt composition through New-ReleaseIntent/ReleasePublisher.Common/New-PreparedReleaseBundle into a digest-bound v2 locator/index/store; corrected the prepared builder to accept r1 and reject attempt-zero source; canonicalized locator timestamps across JSON reload; added exact RED/GREEN and adversarial missing/mismatch fixtures.
verification: Exact plan-shaped RED is GREEN in four total local runs (initial plus three stability runs); prepared-bundle, release-intent, reducer, Phase 8 live-seam, Phase 7 workflow, prepared workflow, parser, and diff checks pass. Real no-provider clean-boundary verification awaits the operator because this task forbids push/tag/dispatch/network actions.
files_changed: [scripts/quality/Invoke-Phase08HostedRun.ps1, scripts/quality/New-PreparedReleaseBundle.ps1, scripts/quality/Test-PreparedReleaseBundle.ps1, scripts/quality/Test-Phase08Qualification.ps1, .planning/debug/prepare-attempt-contract-mismatch.md]
