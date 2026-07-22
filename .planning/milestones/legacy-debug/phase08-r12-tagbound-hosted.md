---
status: awaiting_human_verify
trigger: "GSD debug r12 tag-bound HostedRun runtime mismatch. Immutable tag object 57b76c9 peels/source 5e7b19c; zero-write gates/baseline passed; tag-bound Invoke-Phase08HostedRun Open-P08BoundaryStore still requires refs/tags/modules-v0.1.0-r10. Diagnose stale r10/r11 constants reachable by actual tag-bound HostedPreflight/PublisherDryRun; add minimum static+real tag-bound test that would fail before a future tag, fix source/tests/debug record atomically. Do not alter r12/tag/push/dispatch/credentials/registry/PublishOne/handoff; preserve 8 user dirty. Explain fixture gap and ensure future r13 pre-tag simulation covers OpenBoundaryStore."
created: 2026-07-19T00:00:00+08:00
updated: 2026-07-19T20:45:00+08:00
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

reasoning_checkpoint:
  hypothesis: "Open-P08BoundaryStore validates the durable r12 locator against hard-coded r10, rather than the HostedRun call's ReleaseRef, so all later modes reject before dispatch."
  confirming_evidence:
    - "The r12 detached-clone regression constructed a digest-valid r12 store and HostedPreflight failed at P08-BOUNDARY-BINDING before its dispatch sentinel."
    - "Open-P08BoundaryStore line 813 compares value.release_ref to refs/tags/modules-v0.1.0-r10, while every later mode first requires ReleaseRef r12 and calls this function unconditionally."
    - "The only r11 literals in HostedRun are PrepareAttempt terminal-history validation and are not reachable from later-mode store opening."
  falsification_test: "After passing the caller ReleaseRef into Open-P08BoundaryStore and comparing against it, either tag-bound HostedPreflight/PublisherDryRun still fail at P08-BOUNDARY-BINDING, or the r13 direct store simulation still rejects a matching r13 store."
  fix_rationale: "Making the store's release binding explicit and caller-supplied preserves the existing exact later-mode release gate while removing the stale duplicate source of truth; it also prevents the store check from becoming stale when the next release gate advances."
  blind_spots: "The immutable r12 tag cannot contain this new regression, so the verification uses a disposable annotated r12 clone and no external hosted dispatch. A full real GitHub hosted run remains intentionally out of scope."
next_action: "Await confirmation that the supplied immutable r12 tag-bound HostedRun now reaches its expected post-store boundary in the real workflow; do not dispatch, publish, or access credentials during that verification."

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: "A tag-bound r12 HostedRun resolves the boundary store using the r12 release ref and can proceed beyond the boundary-store step."
actual: "Tag-bound Invoke-Phase08HostedRun reaches Open-P08BoundaryStore and still requests refs/tags/modules-v0.1.0-r10, stopping before clone, wrapper, preflight, dry run, observation, packet, credential, or publish operations."
errors: "Boundary-store lookup requires refs/tags/modules-v0.1.0-r10 while running from immutable r12 tag object 57b76c9 (peeled source 5e7b19c)."
reproduction: "Run the tag-bound HostedRun path from r12 through Open-P08BoundaryStore after zero-write gates and baseline pass."
started: "Observed during the r12 immutable tag-bound HostedRun validation."

## Eliminated
<!-- APPEND only - prevents re-investigating -->

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-07-19T20:00:00+08:00
  checked: "Knowledge base keyword overlap"
  found: "No resolved knowledge-base entry shares two or more symptom keywords with the tag-bound HostedRun boundary-store mismatch."
  implication: "The remote-clone r11 diagnosis is related release context but not a confirmed known-pattern diagnosis for this runtime store path."

- timestamp: 2026-07-19T20:00:00+08:00
  checked: "Repository status and literal scan"
  found: "The worktree already has six unrelated user paths (two modified tracked files and four untracked paths). The new debug record is the only task-created path. Invoke-Phase08HostedRun.ps1 contains r12 active-contract checks and an Open-P08BoundaryStore comparison to r10 at line 813."
  implication: "Any fix must stage only the HostedRun source, focused test, and this debug record; r10/r11 literals elsewhere may be historical evidence and require reachability analysis."

- timestamp: 2026-07-19T20:10:00+08:00
  checked: "Complete HostedRun later-mode and store call graph"
  found: "Every non-library later mode passes the r12 binding gate then unconditionally calls Open-P08BoundaryStore before switch/dispatch. The store's sole release-ref comparison is r10. r11 literals occur only in New-P08PreparedAttempt's exact terminal-history validation."
  implication: "HostedPreflight and PublisherDryRun share one direct stale-r10 root cause; changing historical r11 evidence would be unrelated and unsafe."

- timestamp: 2026-07-19T20:10:00+08:00
  checked: "Existing r12 boundary fixture"
  found: "Test-Phase08R12Boundary creates a disposable tag-bound clone but deliberately throws at PrepareAttempt's provider sentinel and never reopens the PreparedAttempt locator through HostedPreflight or PublisherDryRun."
  implication: "The fixture passed because it proved canonical PrepareAttempt input propagation only; it did not exercise the later boundary-store gate where the stale literal resides."

- timestamp: 2026-07-19T20:15:00+08:00
  checked: "New focused regression before source modification"
  found: "The first execution stopped while creating its disposable annotated tag because the temporary clone has no Git committer identity; HostedRun was not reached."
  implication: "This is an isolated test-fixture setup defect, not evidence against the stale-release-ref hypothesis. The test must configure clone-local identity before creating disposable tags."

- timestamp: 2026-07-19T20:20:00+08:00
  checked: "Focused detached r12 tag-bound HostedPreflight regression after clone-local identity setup"
  found: "HostedPreflight failed P08-BOUNDARY-BINDING: Locator binding drifted before the injected P08-TAGBOUND-DISPATCH sentinel. The test's locator release_ref is the clone policy's r12 ref and all other binding fields are valid/digest-bound."
  implication: "The stale r10 equality inside Open-P08BoundaryStore directly causes the reported stop before dispatch, preflight, dry-run, credentials, or publish behavior."

- timestamp: 2026-07-19T20:25:00+08:00
  checked: "Focused regression immediately after the source fix"
  found: "The disposable --no-local clone still failed with the old P08-BOUNDARY-BINDING because Git cloning reads committed HEAD and therefore omitted the uncommitted source fix."
  implication: "The test must promote only the working HostedRun file into a disposable clone-local commit before creating its test tag; this isolates the release-candidate source without modifying repository tags or commits."

- timestamp: 2026-07-19T20:30:00+08:00
  checked: "Focused regression after candidate-source clone setup"
  found: "The r12 later-mode portion passed through the store; the r13 direct-store portion then failed because dot-sourcing HostedRun -LibraryOnly rebound the test's generic StateRoot variable to the script parameter's empty value."
  implication: "The source fix reached the intended dispatch sentinel. Rename the fixture-local variable to remove the test-only scope collision before final verification."

- timestamp: 2026-07-19T20:35:00+08:00
  checked: "r13 direct-store continuation after state-root rename"
  found: "Dot-sourcing HostedRun also overwrote the test's generic BoundarySha and ReleaseRef variables with empty script parameters, causing an empty Boundary binding."
  implication: "Preserve fixture data under names that cannot collide with HostedRun parameters; the r12 real later-mode assertions remain already successful."

- timestamp: 2026-07-19T20:40:00+08:00
  checked: "Focused post-fix verification"
  found: "Test-Phase08TagBoundHostedStore passed: detached tag-bound r12 HostedPreflight and PublisherDryRun each opened the store then stopped at the injected dispatch sentinel; a direct r13 store opened with its matching ref. Test-Phase08R12Boundary and Test-Phase08R12PreLive also passed; git diff --check passed."
  implication: "The source fix removes the runtime mismatch without dispatching, reading credentials, contacting a registry, or changing r12 immutable state."

- timestamp: 2026-07-19T20:45:00+08:00
  checked: "PowerShell parser, scoped staged diff, and commit"
  found: "Both changed PowerShell files parsed without errors. Only HostedRun, Test-Phase08TagBoundHostedStore, and this debug record were staged; they were committed together as 72ae3cf. Existing user/parallel worktree paths remained unstaged."
  implication: "The durable fix and regression are isolated and ready for real immutable-tag workflow confirmation."

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: "Open-P08BoundaryStore retained an r10 release-ref literal in the active later-mode locator binding. HostedPreflight and PublisherDryRun already require r12, then unconditionally open the store, so every valid r12 locator is rejected before dispatch."
fix: "Open-P08BoundaryStore now accepts the caller ReleaseRef and compares the durable locator to it; the later-mode caller passes its already-validated ReleaseRef. Added Test-Phase08TagBoundHostedStore.ps1, which statically forbids fixed r10/r11/r12 literals in that store, runs a disposable detached tag-bound r12 HostedPreflight and PublisherDryRun up to a dispatch sentinel, and directly opens an r13 pre-tag store."
verification: "Focused regression PASS; Test-Phase08R12Boundary PASS; Test-Phase08R12PreLive PASS; git diff --check PASS."
files_changed: ["scripts/quality/Invoke-Phase08HostedRun.ps1", "scripts/quality/Test-Phase08TagBoundHostedStore.ps1", ".planning/debug/phase08-r12-tagbound-hosted.md"]
