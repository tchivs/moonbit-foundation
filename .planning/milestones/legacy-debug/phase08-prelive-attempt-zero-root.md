---
status: awaiting_human_verify
trigger: "Phase 8 plan 08-17 pre-live selector fails before the first side effect with P08-R6-HISTORICAL-ROOT: Expected one immutable state root for attempt_zero, got 0."
created: 2026-07-19
updated: 2026-07-19
---

# Debug Session: Phase 08 Pre-live Attempt-zero Root

## Symptoms

- Expected behavior: attempt_zero is validated from its immutable tag, peeled commit, historical run 29652468948/1, artifact, and terminal evidence while explicitly having no Phase 8 local StateRoot; r1 through r5 retain their actual persisted root/locator/index/store requirements.
- Actual behavior: the selector requires every history entry, including attempt_zero, to have exactly one immutable local state root.
- Error: `P08-R6-HISTORICAL-ROOT Expected one immutable state root for attempt_zero, got 0.`
- Timeline: observed during Phase 8 plan 08-17 pre-live selection before any side effect.
- Reproduction: run the 08-17 pre-live selector fixtures against the current historical evidence with r6 absent.

## Current Focus

- hypothesis: attempt_zero predates Phase 8 local StateRoot persistence, but the selector applies the r1-r5 local-root invariant uniformly to all historical attempts.
- test: add a RED fixture proving attempt_zero is valid only with immutable tag/source/run/artifact terminal evidence and an explicit absence of Phase 8 root, while r1-r5 keep their stage-appropriate persisted evidence requirements.
- expecting: the current selector fails the historically correct fixture only because attempt_zero has zero local roots.
- next_action: inspect the selector and focused fixtures, write the failing regression test, then apply the smallest stage-aware validation change and run adjacent Phase 8 suites.
- reasoning_checkpoint:
    hypothesis: "attempt_zero predates Phase 8 StateRoot persistence, but production discovery and validation applied the r1-r5 root invariant to all six histories."
    confirming_evidence:
      - "Production failed with P08-R6-HISTORICAL-ROOT before any side effect because no boundary locator has attempt_zero source SHA."
      - "The RED fixture represented attempt_zero with null local-root fields plus its digest-valid terminal artifact and failed at the uniform Test-Path root loop."
    falsification_test: "A stage-aware selector must accept exactly one rootless attempt_zero terminal artifact while rejecting any claimed attempt_zero root, any artifact digest drift, and any missing r1-r5 root."
    fix_rationale: "Bind attempt_zero to the r5-indexed canonical HistoricalNegative artifact and validate its immutable tag/peel/run/digest without inventing a local root; keep active-locator/root/store containment mandatory for r1-r5."
    blind_spots: "The production `git ls-remote --tags origin` call was intentionally not executed during debug; deterministic injected rows cover its exact output contract."
- tdd_checkpoint:
    test_file: "scripts/quality/Test-Phase08R6PreLive.ps1"
    test_name: "attempt_zero explicit root absence with immutable terminal artifact"
    status: green
    failure_output: "RED exited 1 at Invoke-Phase08R6PreLive.ps1:51 because Test-Path received a null attempt_zero root; GREEN exits 0."
- next_action: From the committed clean tree, rerun the read-only production selector so `git ls-remote --tags origin` verifies the live remote rows; do not fetch, recreate local refs, or create/move r6.

## Evidence

- timestamp: 2026-07-19
  checked: production failure and selector discovery logic
  found: `Find-R6HistoricalBoundary` required one Phase 8 boundary for every history, although attempt_zero source `198436a...` has no Phase 8 StateRoot.
  implication: attempt_zero needs a distinct rootless historical-evidence branch; r1-r5 must remain root-backed.
- timestamp: 2026-07-19
  checked: TDD RED fixture
  found: A digest-valid rootless attempt_zero fixture failed when the common validator called `Test-Path` with its null root.
  implication: The stage error is locally reproducible before changing production code.
- timestamp: 2026-07-19
  checked: focused TDD GREEN and negative matrix
  found: The selector accepted rootless attempt_zero with one exact terminal artifact and rejected a fabricated attempt_zero root, artifact digest drift, and a missing r1 StateRoot.
  implication: The exception is exact and does not weaken persisted-history validation.
- timestamp: 2026-07-19
  checked: adjacent Phase 8 suites
  found: R6PreLive, LiveSeam, ReleasePublisherNegative, Phase08Qualification, and MooncakesObservation all exited 0; `git diff --check` exited 0.
  implication: Digests, no-run/downstream, receipt/handoff, observation, and static live boundaries remain intact.
- timestamp: 2026-07-19
  checked: read-only production selector after GREEN
  found: It advanced beyond attempt_zero discovery but stopped at local `refs/tags/modules-v0.1.0-r1` absence; local r1 and r4 refs were already absent, and this session did not fetch or recreate them.
  implication: The selector incorrectly treated local tag refs as remote authority despite its required `-Remote origin` contract.
- timestamp: 2026-07-19
  checked: second-layer TDD RED for remote tag authority
  found: Deterministic remote rows could not be validated because no remote tag resolver existed; production used local `rev-parse`/`cat-file` and a noncanonical remote-tracking r6 ref.
  implication: Exact remote object/peeled resolution must be injectable for fixtures and use `git ls-remote --tags origin` only in production.
- timestamp: 2026-07-19
  checked: second-layer GREEN remote-row matrix
  found: Lightweight attempt_zero and annotated r1-r5 rows resolved exactly; missing row, duplicate row, peeled-source drift, and r5 tag-object drift all failed closed. Static checks require the production `ls-remote --tags` call and reject remote-tracking ref dependence.
  implication: Historical tag authority now follows `-Remote origin` without fetching, recreating, or writing local refs.
- timestamp: 2026-07-19
  checked: second-layer adjacent regression matrix
  found: R6PreLive, LiveSeam, ReleasePublisherNegative, Phase08Qualification, MooncakesObservation, and `git diff --check` all passed without an actual network call.
  implication: The remote-authority correction preserves root, digest, no-run, downstream-zero, committed-clean, and r6-absence invariants.


## Eliminated


## Resolution

- root_cause: The pre-live selector both treated rootless attempt_zero like root-backed r1-r5 and resolved historical tags from local refs instead of the required remote authority, so it failed on valid absence and then on legitimately missing local r1/r4 refs.
- fix: Added an exact rootless attempt_zero branch backed by the canonical r5-indexed terminal artifact; retained strict active-locator/root/store containment for r1-r5; and replaced local tag authority with fail-closed parsing of one read-only `git ls-remote --tags origin` result, injectable in fixtures.
- verification: Two RED/GREEN cycles reproduced the null-root and missing remote-resolver gaps. Focused and adjacent suites pass, including negative proofs for fabricated roots, artifact drift, missing persisted roots, and missing/duplicate/mismatched/peeled-drift remote tags. No actual network or external mutation occurred during debug.
- files_changed: [scripts/quality/Invoke-Phase08R6PreLive.ps1, scripts/quality/Test-Phase08R6PreLive.ps1, .planning/debug/phase08-prelive-attempt-zero-root.md]
