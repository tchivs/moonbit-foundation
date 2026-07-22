---
status: resolved
trigger: "Phase 8 r2 HostedPreflight fails locally before any gh dispatch because Invoke-P08HostedDispatch constructs $fields with +(if(...){...}), producing: The term 'if' is not recognized."
created: 2026-07-19
updated: 2026-07-19T02:25:00+08:00
phase: "08"
plan: "07"
---

# Phase 08 Hosted Dispatch Fields Parsing Failure

## Symptoms

- expected: The Phase 8 hosted helper should construct the workflow input field list deterministically before any dispatch boundary is reached.
- actual: r2 HostedPreflight fails locally while constructing `$fields`, before any `gh workflow run` or other network operation.
- errors: `The term 'if' is not recognized` at the `+(if (...){...})` expression in `Invoke-P08HostedDispatch`.
- timeline: Observed during the immutable r2 Phase 8 forward attempt; r2 must remain fixed and all existing forensic roots must be preserved.
- reproduction: Exercise the helper's HostedPreflight field construction through a local regression seam with dispatch/network disabled.

## Current Focus

tdd_checkpoint:
  test_file: "scripts/quality/Test-Phase08LiveSeam.ps1"
  test_name: "HostedFieldsOnly start/no-packet and resume/packet exact field vectors"
  status: "green"
  failure_output: "RED before fix: The term 'if' is not recognized. GREEN after fix: Phase 8 hosted dispatch field fixtures: PASS."
hypothesis: Confirmed — field expression grouping caused the hosted failure, and imported permanent tags caused the independent local Qualification fixture collision.
test: Scientific RED/GREEN for HostedFields and Qualification `-FixtureOnly`, followed by the complete required adjacent matrix and `git diff --check`.
expecting: All commands pass locally with exact 14-field order and isolated temporary fixture tag state.
next_action: Stage exactly the four authorized files, verify staged names/diff, and create one atomic commit.

## Evidence

- timestamp: 2026-07-19T00:00:00+08:00
  checked: `Invoke-P08HostedDispatch` field construction in `scripts/quality/Invoke-Phase08HostedRun.ps1`
  found: The current helper uses three `+(if(...){...})` forms for `run_mode`, `live_authorization`, and `authorization_packet_sha256` in the `$fields` array literal.
  implication: The reported parser/runtime failure is present on the pre-dispatch path and can be exercised with an injected `GhCommand` without touching GitHub.

- timestamp: 2026-07-19T00:00:00+08:00
  checked: Repository status and debugger/project skill configuration
  found: Existing unrelated dirty files are present; no project or configured debugger skills were discovered.
  implication: The fix and commit must be restricted to the explicitly owned helper, regression test, and debug session file.

- timestamp: 2026-07-19T00:10:00+08:00
  checked: Complete `Invoke-P08HostedDispatch`, `Invoke-P08Gh`, `Get-P08Runs`, and adjacent `Test-Phase08LiveSeam.ps1`
  found: `Get-P08Runs` is the only pre-field-construction call, and `Invoke-P08Gh` delegates every CLI boundary to `$script:GhCommand` when injected; the live seam already dot-sources the hosted helper with `-LibraryOnly`.
  implication: A deterministic fake can prove the field-construction failure and exact field vector without network, secrets, registry observation, or repository/state writes.

- timestamp: 2026-07-19T00:25:00+08:00
  checked: First isolated RED command
  found: The test stopped at PowerShell named-parameter binding because the three-array `ExpectedFields` expression was not grouped; production field construction was not reached.
  implication: This is a fixture syntax defect, not evidence for or against the production hypothesis; correct only the grouping and rerun RED.

- timestamp: 2026-07-19T00:30:00+08:00
  checked: Corrected isolated RED command on the unchanged production helper
  found: `pwsh -NoProfile -File scripts/quality/Test-Phase08LiveSeam.ps1 -HostedFieldsOnly` exited 1 at `Assert-P08HostedDispatchFields` with the exact error `The term 'if' is not recognized`; only the fake initial run-list boundary had executed.
  implication: The production hypothesis is confirmed and the regression is RED before the fix.

- timestamp: 2026-07-19T00:40:00+08:00
  checked: First focused GREEN run after the three-subexpression production fix
  found: The original `if` error disappeared and the fake dispatch was reached, but the assertion showed one space-joined actual argument element and expected prefix/value pairs split at test-side `+` expressions.
  implication: Production behavior advanced exactly as predicted; the remaining failure is in regression fixture array construction/binding and must be corrected before verification can continue.

- timestamp: 2026-07-19T00:50:00+08:00
  checked: Direct PowerShell evaluation of the production comma/concatenation expression shape
  found: The four-field minimal form returns `System.Object[]` with count 1 and the value `operation_mode=HostedPreflight run_mode=start release_ref=... source_sha=...`.
  implication: Each field concatenation must be grouped as its own array expression in addition to making `if` a `$()` subexpression.

- timestamp: 2026-07-19T01:00:00+08:00
  checked: Focused GREEN command after the complete expression correction
  found: `pwsh -NoProfile -File scripts/quality/Test-Phase08LiveSeam.ps1 -HostedFieldsOnly` exited 0; adapter fixtures and hosted dispatch field fixtures both passed.
  implication: Both start/no-packet and resume/packet cases now produce the exact ordered 14-field vectors through the injected local boundary.

- timestamp: 2026-07-19T01:05:00+08:00
  checked: Full Phase 08 LiveSeam suite
  found: `pwsh -NoProfile -File scripts/quality/Test-Phase08LiveSeam.ps1` exited 0; adapter, hosted field, and workflow fixtures passed.
  implication: The new regression integrates with all existing local live-seam and workflow-static fixtures.

- timestamp: 2026-07-19T01:10:00+08:00
  checked: Phase 08 qualification `-FixtureOnly` adjacent command
  found: It exited 1 during setup with `P08-QUAL-PREPARE-TAG: Unable to create the local-only r2 fixture tag` because `modules-v0.1.0-r2` already exists; no tag was created or moved.
  implication: This selector is incompatible with the immutable-tag constraint in the current checkout and did not test the production change; identify and use the qualification selector that does not attempt tag mutation.

- timestamp: 2026-07-19T01:15:00+08:00
  checked: `Assert-P08FixtureContract`, `Assert-P08R2Contract`, and qualification selector routing
  found: `-FixtureOnly` clones the repository (including the existing r2 tag) and then tries to recreate that tag; `-R2ContractOnly` performs receipt/handoff composition solely under a GUID-owned temporary directory and is also the script's no-argument default.
  implication: Use the explicit `-R2ContractOnly` selector for the constrained, non-mutating qualification regression.

- timestamp: 2026-07-19T01:20:00+08:00
  checked: Non-mutating Phase 08 qualification selector
  found: `pwsh -NoProfile -File scripts/quality/Test-Phase08Qualification.ps1 -R2ContractOnly` exited 0 with `Phase 8 r2 receipt/handoff composition: PASS.`
  implication: The r2 receipt/handoff qualification contract remains valid after the hosted-field fix.

- timestamp: 2026-07-19T01:25:00+08:00
  checked: Full local publisher negative/recovery suite
  found: `pwsh -NoProfile -File scripts/quality/Test-ReleasePublisherNegative.ps1` exited 0; reducer negative matrix and controller recovery rehearsal matrix passed.
  implication: Publisher state reduction and recovery behavior are unchanged by the hosted dispatch field correction.

- timestamp: 2026-07-19T01:30:00+08:00
  checked: Full local Mooncakes observation suite
  found: `pwsh -NoProfile -File scripts/quality/Test-MooncakesObservation.ps1` exited 0 with `Mooncakes observation selector: PASS`.
  implication: Observation validation behavior remains intact and no real registry boundary was invoked.

- timestamp: 2026-07-19T01:40:00+08:00
  checked: New acceptance requirement that Qualification `-FixtureOnly` must pass with permanent r2 history
  found: The failing clone/tag setup is implemented only in `scripts/quality/Test-Phase08Qualification.ps1`, which is outside this agent's owned file set and runs in a separate PowerShell process; no change in `Test-Phase08LiveSeam.ps1` can alter it safely.
  implication: An exact-path atomic commit is intentionally withheld pending ownership expansion or a separate owner fix. The safe direction is to isolate the temporary clone from source tags, then create the fixture tag only inside that clone.

- timestamp: 2026-07-19T01:45:00+08:00
  checked: Checkpoint response from the parent debugger
  found: Ownership is explicitly expanded to `scripts/quality/Test-Phase08Qualification.ps1` only for adding `--no-tags` to its GUID-owned temporary clone.
  implication: Apply exactly that local fixture isolation change; the final commit may contain exactly four authorized files.

- timestamp: 2026-07-19T01:55:00+08:00
  checked: Qualification `-FixtureOnly` GREEN after local clone isolation
  found: `pwsh -NoProfile -File scripts/quality/Test-Phase08Qualification.ps1 -FixtureOnly` exited 0 with `Phase 8 qualification fixtures/static contract: PASS.`
  implication: The permanent source history no longer collides with the GUID-owned clone's fixture tag, and the required qualification fixture reaches all assertions.

- timestamp: 2026-07-19T02:00:00+08:00
  checked: Final-tree focused hosted dispatch field selector
  found: `pwsh -NoProfile -File scripts/quality/Test-Phase08LiveSeam.ps1 -HostedFieldsOnly` exited 0; adapter and hosted dispatch field fixtures passed.
  implication: Exact start/no-packet and resume/packet 14-field vectors remain GREEN after the qualification fixture isolation change.

- timestamp: 2026-07-19T02:05:00+08:00
  checked: Final-tree full Phase 08 LiveSeam suite
  found: `pwsh -NoProfile -File scripts/quality/Test-Phase08LiveSeam.ps1` exited 0; adapter, hosted dispatch field, and workflow fixtures passed.
  implication: All adjacent live seam and static workflow contracts remain GREEN.

- timestamp: 2026-07-19T02:10:00+08:00
  checked: Final-tree r2 qualification composition selector
  found: `pwsh -NoProfile -File scripts/quality/Test-Phase08Qualification.ps1 -R2ContractOnly` exited 0 with `Phase 8 r2 receipt/handoff composition: PASS.`
  implication: R2 receipt/handoff composition remains GREEN alongside the now-idempotent full fixture selector.

- timestamp: 2026-07-19T02:15:00+08:00
  checked: Final-tree full publisher negative/recovery suite
  found: `pwsh -NoProfile -File scripts/quality/Test-ReleasePublisherNegative.ps1` exited 0; reducer negative and controller recovery matrices passed.
  implication: Publisher behavior remains GREEN after both fixes.

- timestamp: 2026-07-19T02:20:00+08:00
  checked: Final-tree full Mooncakes observation suite
  found: `pwsh -NoProfile -File scripts/quality/Test-MooncakesObservation.ps1` exited 0 with `Mooncakes observation selector: PASS`.
  implication: Observation behavior remains GREEN and the final remaining quality gate is diff/index validation.

- timestamp: 2026-07-19T02:25:00+08:00
  checked: Final whitespace, authorized diff, index, and worktree scope
  found: `git diff --check` exited 0; the index was empty; task changes are limited to the helper, LiveSeam test, Qualification test, and this debug record, while all unrelated dirty paths remain untouched.
  implication: The fully verified four-file patch is ready for exact-path atomic staging and commit.

## Eliminated

- hypothesis: The fake `GhCommand` typed `[string[]]` parameter stringifies an array passed as one argument.
  evidence: A direct PowerShell micro-test passed `@('alpha','beta')` to typed and untyped scriptblocks; both received count 2 and joined as `alpha,beta`.
  timestamp: 2026-07-19T00:45:00+08:00

## Resolution

root_cause: The `$fields` array uses ungrouped PowerShell concatenation expressions. Parenthesized `if` operands are resolved as a command and abort construction; after that is corrected, comma/plus precedence still collapses the nominal 14 fields into one space-joined string. The dispatch contract therefore cannot produce ordered `-f` pairs.
fix: Used `$()` for the three conditional values and grouped each of the 14 field concatenations as a distinct array element; added a local injected-boundary regression for start/no-packet and resume/packet vectors; isolated the Qualification GUID-owned clone with `--no-tags` so its clone-local fixture tag cannot collide with permanent source history.
verification: RED: HostedFields failed with `The term 'if' is not recognized`; after the conditional-only partial fix it exposed a one-element space-joined field vector. GREEN: focused HostedFields, full LiveSeam, Qualification `-R2ContractOnly`, Qualification `-FixtureOnly`, full Publisher, full Observation, and `git diff --check` all exited 0 from the final working tree.
files_changed: [scripts/quality/Invoke-Phase08HostedRun.ps1, scripts/quality/Test-Phase08LiveSeam.ps1, scripts/quality/Test-Phase08Qualification.ps1, .planning/debug/phase08-hosted-fields.md]
