---
status: awaiting_human_verify
trigger: "r11真实clone ref mismatch：r11 immutable remote tag object 735ad679 / peel-source 30479a2546；static/zero-write prelive/fixture pass，但真实 disposable --no-local --no-tags LF clone fetch+verify r11 后，InitializeBoundary 后 PrepareAttempt 仍为 REL01-REF initial release ref is not clone policy-selected immutable tag。r10/r11均有同类失败；r11 static fix 未覆盖实际 clone。"
created: 2026-07-19T18:45:53+08:00
updated: 2026-07-19T19:05:00+08:00
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

reasoning_checkpoint:
  hypothesis: "REL01-REF is caused by a caller passing a value other than the clone policy's canonical refs/tags/modules-v0.1.0-r11 string; it is not caused by r11 tag resolution, because the real remote clone resolves the tag object, peel, HEAD, boundary, and policy ref identically and reaches PrepareAttempt's provider with that canonical input."
  confirming_evidence:
    - "A fresh --no-local --no-tags HTTPS clone fetched r11 as tag object 735ad67910dca97a95cfc1d4e94f6b003bcc3f30, peeled to and checked out 30479a2546e0fc6416a9a26b10e39ed1f686c860."
    - "The cloned policy selected refs/tags/modules-v0.1.0-r11; InitializeBoundary recorded the same 30479a2546e0fc6416a9a26b10e39ed1f686c860 boundary; PrepareAttempt with that exact string reached a sentinel provider."
    - "The only early equality that emits the reported text compares the caller's ReleaseRef against clone-local policy.initial_profile.release_ref."
  falsification_test: "If the new real-remote clone regression passes a noncanonical ReleaseRef while still reaching its provider, or the canonical ref fails before its provider with equal policy/tag/head/boundary values, this diagnosis is wrong."
  fix_rationale: "Add an opt-in, zero-publish real-remote clone regression that passes the policy-derived canonical ref through InitializeBoundary -> PrepareAttempt and asserts all tag object/peel/head/boundary values. This prevents a future tag from being qualified only by a local bare-fixture path."
  blind_spots: "The original failed command line was not available, so its exact noncanonical argument cannot be named; no source caller invokes PrepareAttempt outside tests, so the fault is at the external invocation boundary."
next_action: "Await confirmation that the intended external real-clone invocation supplies the canonical policy release_ref; retain this session unarchived and do not modify immutable r11."

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: "After fetching and verifying immutable remote r11 in a disposable --no-local --no-tags LF clone, InitializeBoundary and PrepareAttempt use the clone policy-selected immutable r11 tag reference."
actual: "PrepareAttempt reports REL01-REF: initial release ref is not clone policy-selected immutable tag, although static, zero-write prelive, and fixture checks pass."
errors: "REL01-REF initial release ref is not clone policy-selected immutable tag"
reproduction: "Create a disposable LF clone with --no-local --no-tags; fetch and verify r11; run InitializeBoundary then PrepareAttempt."
started: "Observed for r10 and r11; r11 static fix did not cover the actual clone path."

## Eliminated
<!-- APPEND only - prevents re-investigating -->

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-07-19T18:45:53+08:00
  checked: "Local repository tag namespace"
  found: "Local r11 tag is absent; supplied immutable remote tag object is 735ad679 and peel/source is 30479a2546."
  implication: "Investigation must observe the remote-fetch clone path, not infer behavior from a pre-existing local r11 tag."

- timestamp: 2026-07-19T18:50:00+08:00
  checked: "Fresh HTTPS --no-local --no-tags clone, explicit r11 fetch, detached checkout, InitializeBoundary, and PrepareAttempt ref gate"
  found: "Remote tag object=735ad67910dca97a95cfc1d4e94f6b003bcc3f30; peel=HEAD=boundary=30479a2546e0fc6416a9a26b10e39ed1f686c860; clone policy release_ref=refs/tags/modules-v0.1.0-r11; PrepareAttempt with that literal reached the sentinel provider."
  implication: "r11's immutable source and clone ref resolution are internally consistent; the reported REL01-REF requires a different caller-supplied ReleaseRef."

- timestamp: 2026-07-19T18:52:00+08:00
  checked: "PrepareAttempt implementation and existing clone regression"
  found: "The reported message is only emitted by canonical caller-vs-policy equality checks. Existing Test-Phase08Qualification uses a local bare fixture clone, not an actual remote clone."
  implication: "A remote-clone regression is needed; it cannot be included in immutable r11, so any source-level gate requires a subsequent r12 tag."

- timestamp: 2026-07-19T18:59:00+08:00
  checked: "New Test-Phase08RemoteCloneRef.ps1 against immutable r11"
  found: "Canonical r11 policy ref passed through InitializeBoundary -> PrepareAttempt to one sentinel provider call with tag object=735ad67910dca97a95cfc1d4e94f6b003bcc3f30 and peel=head=boundary=30479a2546e0fc6416a9a26b10e39ed1f686c860. The derived noncanonical refs/tags/modules-v0.1.0-r11^{} negative input was rejected with P08-PREPARE-REF before the provider and without an active locator."
  implication: "The new regression distinguishes the caller contract from tag-resolution behavior and proves the reported mechanism."

- timestamp: 2026-07-19T19:00:00+08:00
  checked: "Existing broad Test-Phase08Qualification.ps1"
  found: "It fails before this regression with P08-R9-PREPARED: Missing prepared r9 contract refs/tags/modules-v0.1.0-r9."
  implication: "Broad qualification is currently blocked by an unrelated stale r9 static expectation; it was not changed for this scoped debug fix."

- timestamp: 2026-07-19T19:03:00+08:00
  checked: "Focused r11 zero-write/history gates and diff whitespace"
  found: "Test-Phase08R11PreLive.ps1 PASS; Test-Phase08PrepareHistorySchema.ps1 PASS; git diff --check PASS."
  implication: "The targeted regression does not disturb the r11 zero-write selector or the protected history schema."

- timestamp: 2026-07-19T19:04:00+08:00
  checked: "Minimal staged source diff and local commit"
  found: "Only scripts/quality/Test-Phase08RemoteCloneRef.ps1 was staged and committed as 508eccc (test: cover phase 8 remote clone ref gate). Existing user-dirty files were not staged."
  implication: "The regression is isolated in a new post-r11 commit; it must be included by a new immutable r12 tag before it can validate that tag's own remote clone path."

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: "The failed real-clone invocation supplied a noncanonical ReleaseRef to PrepareAttempt. The r11 remote tag itself is correct: a fresh no-local/no-tags clone sees policy ref, tag object, peel, HEAD, and boundary all agree. Existing coverage only proved a local bare-fixture clone, so it did not make the remote invocation contract observable."
fix: "Added Test-Phase08RemoteCloneRef.ps1, an opt-in disposable --no-local --no-tags remote clone gate. It verifies immutable object/peel, detached HEAD, clone policy, boundary and canonical PrepareAttempt context; it also proves ref^{} is rejected before provider/state creation."
verification: "Passed against immutable remote r11: object 735ad67910dca97a95cfc1d4e94f6b003bcc3f30; peel/head/boundary 30479a2546e0fc6416a9a26b10e39ed1f686c860; provider_calls=1; mutation_count=0. Broad Test-Phase08Qualification remains blocked by independent P08-R9-PREPARED static contract drift."
files_changed: ["scripts/quality/Test-Phase08RemoteCloneRef.ps1"]
