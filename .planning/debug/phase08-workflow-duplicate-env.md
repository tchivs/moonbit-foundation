---
status: awaiting_human_verify
trigger: "Phase 8 r5 HostedPreflight was rejected before run creation because the immutable r5 workflow contains a duplicate EXPECTED_HISTORICAL_R4_SHA256 environment key."
created: 2026-07-19
updated: 2026-07-19T00:00:00+08:00
---

# Debug Session: Phase 8 Workflow Duplicate Environment Key

## Symptoms

- Expected: The r5 workflow is valid YAML and HostedPreflight creates exactly one non-mutating run.
- Actual: Dispatch fails with `P08-HOSTED-GH`; no r5 run is created.
- Reproduction: Validate `.github/workflows/publish-modules.yml` for duplicate mapping keys and exact controller/workflow field parity.

## Known External State

- r5 immutable boundary: `df105f06205298f1f82ac2f2cdca214d69d42e15`
- r5 tag object: `4a11582cf9aeae15802cf4f6d7394b013ece63ac`
- registry observation: `confirmed_absent`
- r5 publish runs, PublisherDryRun, packet, receipt, handoff, mutation: zero
- Forbidden: push, tag, GitHub/network, secret, StateRoot, registry/publication, moving r5, or planning r6.

## Current Focus

reasoning_checkpoint:
  hypothesis: "The second `EXPECTED_HISTORICAL_R4_SHA256` entry in the PublisherDryRun env mapping makes GitHub reject the workflow before run creation; it is misplaced because publisher verification consumes the same variable but does not declare it."
  confirming_evidence:
    - "Direct inspection shows two identical R4 keys in one PublisherDryRun env mapping and zero R4 declarations in the publisher verification env mapping."
    - "The unchanged WorkflowOnly suite passed, then the new uniqueness assertion failed deterministically with `P08-WORKFLOW-DUPLICATE-ENV-KEY: 'EXPECTED_HISTORICAL_R4_SHA256'.`"
  falsification_test: "Relocating only the second R4 declaration must make the same focused test pass with exactly one R4 mapping in each consuming mode and all 14 dispatch inputs unchanged; otherwise this hypothesis is wrong or incomplete."
  fix_rationale: "Moving the misplaced duplicate to the publisher verification env mapping repairs YAML uniqueness and supplies the already-consumed value without changing its digest, input surface, or safety semantics."
  blind_spots: "The regression statically validates the repository's indentation/key shape rather than invoking GitHub's remote workflow parser; required adjacent static suites and diff checks remain to be run."
tdd_checkpoint:
  test_file: "scripts/quality/Test-Phase08LiveSeam.ps1"
  test_name: "Workflow job/env key uniqueness and exact R4 propagation"
  status: "green"
  failure_output: "RED was Exit 1 at Test-Phase08LiveSeam.ps1:245: P08-WORKFLOW-DUPLICATE-ENV-KEY: 'EXPECTED_HISTORICAL_R4_SHA256'. GREEN exits 0."
next_action: Await human confirmation that the corrected immutable workflow creates the intended non-mutating hosted run; archive only after that confirmation.

## Evidence

- timestamp: 2026-07-19
  checked: r5 live attempt
  found: HostedPreflight failed at the dispatch boundary, GitHub created no r5 run, and all downstream effects remain zero.
  implication: Investigate only the immutable workflow's static validity; do not retry or mutate external state.
- timestamp: 2026-07-19
  checked: debug knowledge base and repository worktree
  found: No knowledge-base entry has two-keyword overlap with the duplicate environment-key symptom; unrelated tracked and untracked changes are present and must be preserved.
  implication: Test the duplicate-key hypothesis directly and stage only the workflow, owned regression test, and this debug record.
- timestamp: 2026-07-19
  checked: complete workflow and Phase 8 LiveSeam workflow-static assertions
  found: `publisher_dry_run.steps[PublisherDryRun].env` contains `EXPECTED_HISTORICAL_R4_SHA256` twice; the publisher verification script consumes the same variable, while existing static assertions cover exact 14 dispatch inputs and receipt propagation but no job/env mapping-key uniqueness.
  implication: A focused uniqueness regression should fail on the duplicate before the production workflow is modified, and historical R4 propagation must remain explicit after correction.
- timestamp: 2026-07-19
  checked: unchanged `Test-Phase08LiveSeam.ps1 -WorkflowOnly` baseline
  found: The suite exited 0 and reported all adapter, hosted-dispatch-field, and workflow fixtures PASS despite the duplicate YAML key.
  implication: The pre-existing suite has a confirmed static-validation gap; adding the regression before changing YAML is necessary to reproduce RED.
- timestamp: 2026-07-19
  checked: TDD RED with workflow unchanged and new job/env uniqueness regression active
  found: `Test-Phase08LiveSeam.ps1 -WorkflowOnly` exited 1 at the new assertion with `P08-WORKFLOW-DUPLICATE-ENV-KEY: 'EXPECTED_HISTORICAL_R4_SHA256'.`
  implication: The reported duplicate is reproducible locally through deterministic static validation and the root-cause hypothesis is confirmed.
- timestamp: 2026-07-19
  checked: focused TDD GREEN after relocating the second R4 env declaration
  found: `Test-Phase08LiveSeam.ps1 -WorkflowOnly` exited 0; workflow uniqueness, exact 14 dispatch parity, exact R4 propagation, adapter, and hosted-field fixtures all passed.
  implication: The minimal workflow correction directly fixes the reproduced failure without changing the dispatch contract.
- timestamp: 2026-07-19
  checked: full Phase 8 LiveSeam suite on the corrected tree
  found: `Test-Phase08LiveSeam.ps1` exited 0 with adapter, hosted dispatch field, and live workflow fixtures PASS.
  implication: The new static guard and workflow correction do not regress the adjacent local live-seam behavior.
- timestamp: 2026-07-19
  checked: full publisher negative and recovery suite
  found: `Test-ReleasePublisherNegative.ps1` exited 0; reducer negative matrix and controller recovery rehearsal matrix passed.
  implication: Publisher state reduction and recovery semantics remain unchanged.
- timestamp: 2026-07-19
  checked: full Phase 8 qualification suite
  found: `Test-Phase08Qualification.ps1` exited 0 with r5 receipt/handoff composition PASS.
  implication: Exact receipt and handoff composition remains intact after the workflow-only correction.
- timestamp: 2026-07-19
  checked: full Mooncakes observation suite
  found: `Test-MooncakesObservation.ps1` exited 0 with observation selector PASS.
  implication: Registry observation classification remains unchanged and no external observation boundary was contacted.
- timestamp: 2026-07-19
  checked: final diff, index, worktree scope, and immutable local r5 refs
  found: `git diff --check` exited 0; the index was empty; owned code changes were limited to a two-line workflow relocation and the static regression; r5 commit remained `df105f06205298f1f82ac2f2cdca214d69d42e15` and tag object remained `4a11582cf9aeae15802cf4f6d7394b013ece63ac`.
  implication: The correction is whitespace-clean, preserves the immutable boundary, and can be staged without touching unrelated concurrent changes.
- timestamp: 2026-07-19
  checked: atomic commit scope
  found: The commit contained exactly `.github/workflows/publish-modules.yml`, `scripts/quality/Test-Phase08LiveSeam.ps1`, and this debug record; all unrelated dirty and untracked paths remained outside the index.
  implication: The implementation is ready for the required human verification checkpoint without contaminating concurrent work.

## Eliminated

- hypothesis: The hosted dispatch controller omitted or duplicated one of the exact 14 workflow inputs.
  evidence: The unchanged suite's exact ordered 14-input and injected hosted-field fixtures passed before the new YAML uniqueness assertion was added.
  timestamp: 2026-07-19

## Resolution

- root_cause: The PublisherDryRun step declared `EXPECTED_HISTORICAL_R4_SHA256` twice in one YAML `env` mapping, while the publisher verification step consumed that variable without declaring it; existing static tests did not validate job/env mapping-key uniqueness.
- fix: Relocated the second dry-run R4 env declaration into the publisher verification env mapping and added deterministic job/env uniqueness, exact 14 count/uniqueness, and exact R4 propagation assertions.
- verification: RED reproduced with the workflow unchanged. GREEN passed for WorkflowOnly, full LiveSeam, full Publisher, full Phase 8 Qualification, and full Observation. `git diff --check` passed; exact r5 commit/tag identities were unchanged. A real hosted run remains intentionally unattempted pending human verification.
- files_changed: [.github/workflows/publish-modules.yml, scripts/quality/Test-Phase08LiveSeam.ps1, .planning/debug/phase08-workflow-duplicate-env.md]
