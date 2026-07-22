---
status: awaiting_human_verify
trigger: "Plan 08-07 InitializeBoundary failed because Invoke-Phase08HostedRun.ps1 globally requires later-stage release, intent, module, locator, and artifact parameters."
created: 2026-07-18
updated: 2026-07-19
phase: "08"
plan: "07"
---

# InitializeBoundary Parameter Contract

## Symptoms

- expected: `InitializeBoundary` accepts only repository, workflow, boundary SHA, execution root, and state root, then atomically creates the empty durable locator/root/index.
- actual: PowerShell parameter binding requires ReleaseRef, SourceSha, root/current/prepared digests, TargetModule, LocatorPath, and ArtifactRoot before mode dispatch; helper then pre-validates r1/digests before boundary initialization.
- errors: The clean clone invocation stopped before locator creation; no synthetic placeholder was permitted.
- timeline: First r1 forward attempt after boundary 22974c64e10e14e8910986cc74b17e4b7e96d8e5 was pushed.
- reproduction: Invoke the pushed helper blob 190c32971a5d49a08877304648352b1cc20df4dc with `-Mode InitializeBoundary` and only the parameters specified by 08-07 Task 1.

## Current Focus

hypothesis: Global Mandatory attributes and the unconditional r1 binding check reject InitializeBoundary before mode dispatch; the initialization branch also incorrectly builds a release-attempt locator from parameters that the 08-07 boundary contract does not supply.
test: Re-ran the exact minimal initialization fixture, all ten incomplete later-mode negative cases, Phase 08 live adapter/workflow fixtures, publisher reducer negatives, and git diff whitespace validation.
expecting: Human verification should repeat the exact clean-clone InitializeBoundary call from 08-07 and observe a closed empty boundary locator/root/index without release placeholders.
next_action: Await parent/orchestrator verification of the real clean-clone workflow; do not dispatch, tag, publish, or access registry/hosted services in this debug session.
tdd_checkpoint: GREEN; exact minimal InitializeBoundary succeeds and all ten later modes fail with P08-HOSTED-MISSING-BINDING before GhCommand when their release evidence is omitted.
reasoning_checkpoint:
  hypothesis: Global Mandatory attributes prevent mode dispatch, and the InitializeBoundary writer consumes release-attempt fields that cannot exist until after the boundary is established.
  confirming_evidence:
    - The exact 08-07 six-argument call fails in PowerShell parameter binding before script code runs.
    - New-P08BoundaryLocator currently serializes ReleaseRef, SourceSha, three intent digests, LocatorPath, and ArtifactRoot even though 08-07 supplies only BoundarySha, ExecutionRoot, and StateRoot after common identity.
  falsification_test: If removing only later-stage Mandatory binding and routing InitializeBoundary to a boundary-only writer still fails the exact fixture, or if an incomplete later mode reaches GhCommand, the hypothesis is wrong.
  fix_rationale: Mode-scoped script validation permits initialization to establish its own durable boundary evidence while retaining explicit fail-closed validation before any later store open or hosted dispatch.
  blind_spots: This local fixture injects GitCommand and does not exercise a remote clone; existing execution-boundary tests cover clean HEAD/blob enforcement separately.

## Evidence

- timestamp: 2026-07-18T00:00:00Z
  fact: origin/main equals 22974c64e10e14e8910986cc74b17e4b7e96d8e5 and the detached clone is clean.
- timestamp: 2026-07-18T00:00:01Z
  fact: modules-v0.1.0-r1 is absent; no locator, attempt, hosted mode, PublishOne, or publication exists.
- timestamp: 2026-07-18T00:00:02Z
  fact: Helper blob 190c32971a5d49a08877304648352b1cc20df4dc rejects the planned minimal InitializeBoundary call at parameter binding/prevalidation.
- timestamp: 2026-07-19T00:00:00Z
  fact: Focused regression fixture reproduces the bug locally before helper changes; PowerShell reports all later-stage Mandatory parameters missing for the exact six-argument InitializeBoundary contract.
- timestamp: 2026-07-19T00:00:01Z
  fact: After the mode-scoped fix, the fixture creates mnf-phase08-boundary-locator/1 and mnf-phase08-boundary-index/1 with zero records using only the 08-07 InitializeBoundary parameters.
- timestamp: 2026-07-19T00:00:02Z
  fact: Every non-initialization mode rejects missing release/intent/module/store bindings with P08-HOSTED-MISSING-BINDING before the injected GhCommand can run.
- timestamp: 2026-07-19T00:00:03Z
  fact: Test-Phase08Qualification -FixtureOnly, Test-Phase08LiveSeam, Test-ReleasePublisherNegative -ReducerOnly, and git diff --check all pass locally without hosted or registry access.

## Eliminated

- hypothesis: Existing r1 evidence must be recovered.
  reason: No r1 tag, locator, active attempt, or hosted run was created.

## Resolution

root_cause: Invoke-Phase08HostedRun.ps1 declared release-attempt parameters globally Mandatory and validated the r1 binding before mode selection; InitializeBoundary therefore never reached dispatch and its writer depended on evidence that cannot exist until after boundary creation.
fix: Made release-attempt parameters optional at PowerShell binding, routed InitializeBoundary first through a six-argument boundary-only contract, wrote a closed digest-bound locator plus empty boundary-bound root/index below StateRoot, and added a common fail-closed binding gate before every later mode.
verification: RED reproduced at parameter binding; GREEN exact minimal initialization and all ten later-mode negatives pass. Phase 08 live workflow/adapter fixtures and reducer negative matrix also pass; no hosted, registry, tag, push, secret, or publication action was performed.
files_changed:
  - scripts/quality/Invoke-Phase08HostedRun.ps1
  - scripts/quality/Test-Phase08Qualification.ps1
