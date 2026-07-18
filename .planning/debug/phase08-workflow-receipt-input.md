---
status: awaiting_human_verify
trigger: "Phase 8 r3 HostedPreflight dispatch is rejected before run creation because the controller sends authorization_receipt_sha256 as field 14 while the tagged workflow_dispatch contract does not declare or propagate that input."
created: 2026-07-19
updated: 2026-07-19T08:14:30+08:00
phase: "08"
plan: "07"
---

# Phase 08 Workflow Authorization Receipt Input Parity

## Symptoms

- expected: The controller's exact 14-field HostedPreflight dispatch contract and the workflow_dispatch input/job propagation contract should be closed for both start with an empty receipt and resume with a valid receipt digest.
- actual: `Invoke-Phase08HostedRun.ps1` sends `authorization_receipt_sha256` as field 14, but the immutable r3 workflow does not declare that input, so `gh` rejects the request before creating a run.
- errors: `P08-HOSTED-GH` occurs at the pre-dispatch GitHub CLI boundary because the requested workflow input is undeclared.
- timeline: Observed on immutable r3 (`67b1fbc`, tag object `a308767`) after `Observe` confirmed absent; no r3 run or mutation exists and `PublisherDryRun` did not run.
- reproduction: Use local static/fixture assertions to compare the controller's exact 14 fields with workflow_dispatch declarations and job propagation for start/empty-receipt and resume/valid-receipt cases. Do not invoke GitHub or any external boundary.

## Current Focus

reasoning_checkpoint:
  hypothesis: publish-modules.yml rejects the controller dispatch because its workflow_dispatch schema is an obsolete 17-field contract that omits controller field 14, authorization_receipt_sha256, and downstream validation reads a stale mutation-prefixed packet field instead of the controller packet/receipt pair.
  confirming_evidence:
    - A mechanical source probe found controller_count=14 and workflow_count=17, with authorization_receipt_sha256 controller-only and four obsolete workflow-only inputs.
    - The focused permanent HostedFieldsOnly RED failed at P08-WORKFLOW-DISPATCH-PARITY and printed the exact differing vectors before any production YAML change.
    - Complete workflow inspection showed MUTATION_AUTHORIZATION_PACKET_SHA256 is used for PublishOne validation while authorization_receipt_sha256 is neither declared nor propagated.
  falsification_test: If changing only the workflow declaration/use sites to the exact 14 inputs leaves HostedFieldsOnly failing parity or packet/receipt propagation, or if start-empty and resume-valid controller fixtures fail, this root-cause model is wrong or incomplete.
  fix_rationale: Replacing the obsolete declarations and use sites with the controller's existing packet/receipt pair makes GitHub accept field 14 and preserves the digest safety binding through prepare and publisher jobs without deleting or weakening it.
  blind_spots: Local tests cannot exercise GitHub's hosted workflow parser; removing obsolete inputs could expose an untested external caller, but repository search found the Phase 8 controller as the only dispatch producer and the deleted inputs were not emitted by it.
next_action: Await human confirmation that an authorized real HostedPreflight start accepts the empty receipt field and that a later authorized PublishOne resume accepts the valid packet/receipt digest pair; do not dispatch from this debug session.

## Evidence

- timestamp: 2026-07-19T07:31:15+08:00
  checked: .planning/debug/knowledge-base.md for workflow_dispatch, authorization_receipt_sha256, and propagation keyword overlap
  found: The only prior entry concerns Phase 6 qualification ordering and has no two-keyword overlap.
  implication: There is no known-pattern shortcut; investigate the local contract directly.

- timestamp: 2026-07-19T07:32:48+08:00
  checked: Repository-wide literal search and git status
  found: Invoke-Phase08HostedRun.ps1 constructs authorization_receipt_sha256 in the dispatch fields; publish-modules.yml is the sole workflow_dispatch definition; the authorized debug record is untracked and all listed user-dirty paths remain outside the intended change set.
  implication: The contract boundary is localized to the authorized controller/workflow/test surfaces, and unrelated user changes must not be staged.

- timestamp: 2026-07-19T07:44:10+08:00
  checked: Complete controller, workflow, Test-Phase08LiveSeam, Test-ReleasePublisherNegative, Test-Phase08Qualification, and Test-MooncakesObservation sources
  found: The controller constructs 14 ordered fields including authorization_packet_sha256 and authorization_receipt_sha256. The workflow declares authorization_packet_sha256 but not authorization_receipt_sha256, separately declares mutation_authorization_packet_sha256, exact_existing_authority_sha256, prior_authority_record_sha256, and observation_phase, and validates the mutation-prefixed packet input. Existing hosted-field fixtures prove controller start/resume values but do not compare them to workflow declarations or publisher propagation.
  implication: The missing receipt is part of a wider local data-contract drift at declaration and downstream use sites; a mechanical parity RED should distinguish the exact mismatches.

- timestamp: 2026-07-19T07:50:40+08:00
  checked: Mechanical extraction of Invoke-P08HostedDispatch field keys and publish-modules.yml workflow_dispatch input keys
  found: Controller count is 14 and workflow count is 17. Controller-only is authorization_receipt_sha256. Workflow-only fields are mutation_authorization_packet_sha256, exact_existing_authority_sha256, prior_authority_record_sha256, and observation_phase. The workflow validation consumes the mutation-prefixed packet field, while Invoke-ReleasePublisher.ps1 has no packet/receipt parameters.
  implication: The fix must make the workflow declaration exactly match the controller, replace stale packet use sites, and enforce the receipt pair within workflow job environments before the existing publisher invocation.

- timestamp: 2026-07-19T07:55:30+08:00
  checked: Focused RED via Test-Phase08LiveSeam.ps1 -HostedFieldsOnly after adding the permanent parity assertion
  found: P08-WORKFLOW-DISPATCH-PARITY failed with expected exact 14 names and actual 17 names; the output explicitly showed the missing authorization_receipt_sha256 and stale workflow declarations.
  implication: The hypothesis is directly reproducible and confirmed; production YAML can now be changed one variable at a time.

- timestamp: 2026-07-19T08:02:05+08:00
  checked: Focused GREEN via the identical Test-Phase08LiveSeam.ps1 -HostedFieldsOnly command
  found: Exit 0; both Phase 8 live adapter fixtures and hosted dispatch field fixtures passed with the exact workflow parity assertions active.
  implication: The minimal workflow change closes the focused mismatch while preserving exact start-empty and resume-valid controller vectors; adjacent regressions remain to be checked.

- timestamp: 2026-07-19T08:05:40+08:00
  checked: Full local adjacent regression matrix
  found: Test-Phase08LiveSeam full, Test-ReleasePublisherNegative full, Test-Phase08Qualification R3ContractOnly, Test-Phase08Qualification FixtureOnly, and Test-MooncakesObservation full all exited 0. The only output besides PASS lines was Git's existing LF-to-CRLF advisory inside the fixture clone.
  implication: The contract fix preserves publisher recovery, r3 receipt/handoff, qualification, observation, and full live-seam behavior; final static/diff hygiene remains.

- timestamp: 2026-07-19T08:08:30+08:00
  checked: Dedicated Test-Phase08LiveSeam.ps1 -WorkflowOnly static selector and local workflow-parser availability
  found: WorkflowOnly exited 0 with live adapter, exact hosted dispatch fields, and workflow assertions passing. No actionlint, yq, or ConvertFrom-Yaml parser is installed locally.
  implication: Permanent source assertions verify exact declaration/propagation locally; hosted YAML parsing remains an acknowledged environment blind spot and no network/tool bootstrap is permitted for this task.

- timestamp: 2026-07-19T08:11:55+08:00
  checked: git diff --check, authorized diff, and full worktree status
  found: git diff --check exited 0. The authorized diff contains only publish-modules.yml and Test-Phase08LiveSeam.ps1 plus this untracked debug record; all pre-existing user-dirty paths remain unstaged and untouched.
  implication: The self-verified fix is clean and ready for the requested exact-file atomic commit; only a real hosted dispatch can provide final human/environment verification.

- timestamp: 2026-07-19T08:14:30+08:00
  checked: Exact-file staging and atomic commit preparation
  found: Cached whitespace checks passed and the staged inventory contained only publish-modules.yml, Test-Phase08LiveSeam.ps1, and this debug record; the requested fix commit was created without staging any user-dirty path.
  implication: Local implementation is complete and the session correctly waits at the human/environment verification boundary.

## Eliminated

## Resolution

root_cause: publish-modules.yml retained an obsolete 17-input workflow_dispatch contract that omitted authorization_receipt_sha256 and validated mutation_authorization_packet_sha256 instead of the controller's authorization_packet_sha256/authorization_receipt_sha256 pair, so GitHub rejected field 14 before run creation and the receipt safety binding could not reach publisher jobs.
fix: Added an exact ordered 14-input workflow_dispatch contract, made authorization_receipt_sha256 optional/default-empty for start, replaced stale mutation-prefixed/legacy inputs with paired packet+receipt validation, and propagated both digests through prepare, publisher verification, and LiveOneStep environments. Added permanent static parity/propagation assertions alongside the existing exact start/resume field fixtures.
verification: Focused RED reproduced P08-WORKFLOW-DISPATCH-PARITY with workflow 17 versus controller 14. The identical HostedFieldsOnly command then passed GREEN. Full Test-Phase08LiveSeam, Test-ReleasePublisherNegative, Test-Phase08Qualification -R3ContractOnly, Test-Phase08Qualification -FixtureOnly, Test-MooncakesObservation, Test-Phase08LiveSeam -WorkflowOnly, and git diff --check all exited 0. No network, gh, secrets, StateRoot, registry, publication, tags, or immutable r3 state were touched.
files_changed: [.github/workflows/publish-modules.yml, scripts/quality/Test-Phase08LiveSeam.ps1, .planning/debug/phase08-workflow-receipt-input.md]
