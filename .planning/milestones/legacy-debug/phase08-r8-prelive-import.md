---
status: awaiting_human_verify
trigger: "Phase 8 plan 08-22 pre-live selector exits 0 but emits zero objects before any side effect because Invoke-Phase08R8PreLive.ps1 dot-sources R7 with -LibraryOnly and R7's top-level return escapes the caller."
created: 2026-07-19
updated: 2026-07-19T01:05:00+08:00
---

# Debug Session: Phase 08 R8 Pre-live Import

## Symptoms

- Expected behavior: the R8 pre-live selector loads only the reusable R7 functions, then emits exactly one sanitized pre-live object plus its digest without writes or external effects.
- Actual behavior: the selector exits 0 and emits zero objects because the nested R7 `-LibraryOnly` import executes a top-level `return` that exits the R8 caller before its body runs.
- Error: no explicit error; successful exit with empty output.
- Timeline: observed during Phase 8 plan 08-22 pre-live selection before any side effect.
- Reproduction: invoke `Invoke-Phase08R8PreLive.ps1`; its top-level dot-source of R7 with `-LibraryOnly` causes R7's top-level return to escape into R8.

## Current Focus

- hypothesis: self-verification is complete; the import-safe seam emits one digest-bound sanitized result through the tested selector core while preserving R7 semantics and adjacent Phase 08 contracts.
- test: human or orchestrator confirms the original pre-live command in the real persisted-history environment before any side effect.
- expecting: direct R8 pre-live invocation emits one JSON object whose `result_sha256` recomputes exactly and whose write/network counters remain zero.
- next_action: commit only the owned R7/R8 scripts, fixtures, module, and active debug session; then request real-environment confirmation.
- reasoning_checkpoint:
    hypothesis: R7 standalone fails after policy evolution because its seven-history checks consume the full current eight-history collection, while R8 reuses the same builder and needs eight.
    confirming_evidence:
      - Current policy has eight records, ending in r7.
      - Test-R7 generates seven remote rows but iterates the full policy and fails on the absent r7 row.
      - The historical seven-record digest from the R7 policy commit is the SHA-256 of the first seven current record digests.
    falsification_test: If selecting the first seven records does not reproduce the historical R7 set or R8 cannot explicitly select eight, the hypothesis is wrong.
    fix_rationale: An explicit history-count boundary preserves the immutable R7 view by default while allowing the R8 consumer to request the appended eighth record without duplicating builders.
    blind_spots: Production historical-root discovery for r7 cannot be exercised without live persisted roots; R7/R8 fixture validation and the unchanged generic loop structure cover the selection behavior locally.
- tdd_checkpoint:
    test_file: scripts/quality/Test-Phase08R7PreLive.ps1
    test_name: R7 preserves its seven-history snapshot after R8 policy append
    status: green
    failure_output:

## Evidence

- timestamp: 2026-07-19T00:00:00+08:00
  checked: focused R7/R8 selector and fixture source
  found: R8 line 7 dot-sources R7 with `-LibraryOnly`; R7 line 180 executes a script-level `return`; R8 line 84 repeats the same return pattern; Test-R8 line 7 dot-sources R8.
  implication: both the production selector and its fixture cross nested dot-source boundaries where `return` can terminate the importing scope instead of merely suppressing the standalone command body.
- timestamp: 2026-07-19T00:05:00+08:00
  checked: current Test-R8 fixture and direct R8 selector invocation
  found: Test-R8 exits 0 and prints its PASS marker, but direct R8 exits 0 with exactly zero output objects.
  implication: the fixture is not vacuous; the direct-only divergence points to R8's initially false `$LibraryOnly` being changed by the nested R7 import before R8 reaches its own guard.
- timestamp: 2026-07-19T00:10:00+08:00
  checked: minimal dot-source parameter binding
  found: a caller initialized with `$LibraryOnly=$false` reports `DOTSOURCE_LIBRARY_ONLY=True` after dot-sourcing a dependency with `-LibraryOnly`.
  implication: shared-scope parameter contamination is directly reproduced and explains why R8's own line-84 guard suppresses production output.
- timestamp: 2026-07-19T00:10:00+08:00
  checked: `Import-Module` directly against the R7 `.ps1`
  found: required R7 functions were visible, but caller `$LibraryOnly` still became true.
  implication: treating the `.ps1` itself as a module does not provide the required isolation; a real `.psm1` module boundary is necessary.
- timestamp: 2026-07-19T00:15:00+08:00
  checked: dynamic module counterfactual wrapping the R7 dot-source
  found: caller `$LibraryOnly` remained false and `New-Phase08R7ProductionContext` was exported.
  implication: a real module boundary is sufficient to contain the R7 parameter binding and return without duplicating R7 implementation.
- timestamp: 2026-07-19T00:20:00+08:00
  checked: new import-scope regression fixture before production changes
  found: Test-R8 fails at line 9 with `P08-R8-R7-MODULE-MISSING`.
  implication: RED is established for the missing import-safe module seam.
- timestamp: 2026-07-19T00:25:00+08:00
  checked: import-scope regression after adding the real R7 library module and switching R8 to import it
  found: Test-R8 exits 0 and prints `Phase 8 r8 pre-live selector fixtures: PASS.`
  implication: the first RED is GREEN; module isolation preserves all existing R8 positive and negative checks.
- timestamp: 2026-07-19T00:30:00+08:00
  checked: whole-result count and digest regression before result-construction changes
  found: one result object is returned, then Test-R8 fails with `P08-R8-RESULT-DIGEST: sanitized result digest is missing.`
  implication: the second RED isolates the missing whole-result digest while confirming the count is already exactly one.
- timestamp: 2026-07-19T00:35:00+08:00
  checked: whole-result digest regression after adding `result_sha256`
  found: Test-R8 exits 0; its independent projection recomputation agrees and every existing negative/zero-write assertion still passes.
  implication: the second RED is GREEN and the sanitized selector result is exactly one digest-bound object.
- timestamp: 2026-07-19T00:40:00+08:00
  checked: optional earlier R6 pre-live compatibility fixture
  found: Test-R6 fails resolving the r6 remote tag because it generates six remote rows but iterates the now eight-record policy history.
  implication: R6 is an existing policy-evolution mismatch outside the owned R7/R8 scope; verify R7 independently because its required seven-history semantics may need a focused compatibility fix.
- timestamp: 2026-07-19T00:45:00+08:00
  checked: required Test-R7 fixture against the current policy
  found: Test-R7 fails with `P08-R7-REMOTE-TAG` for r7 because the fixture generates seven rows but later iterates all eight live policy records.
  implication: R7 needs an explicit immutable seven-history view; R8 must opt into eight when reusing the builder.
- timestamp: 2026-07-19T00:50:00+08:00
  checked: Test-R7 and Test-R8 after history-count selection
  found: both fixtures exit 0 and print PASS; R7 validates seven records and its historical set while R8 validates all eight and its whole-result digest.
  implication: the focused R7 compatibility RED is GREEN without weakening the R8 evidence boundary.
- timestamp: 2026-07-19T00:55:00+08:00
  checked: R7 LibraryOnly and standalone entrypoint probes
  found: LibraryOnly emits zero objects while loading `New-Phase08R7ProductionContext`; standalone invocation without required arguments fails with the expected `P08-R7-INVOCATION` guard.
  implication: the module seam and history selection preserve both R7 entrypoint semantics required by the task.
- timestamp: 2026-07-19T01:00:00+08:00
  checked: Phase 08 adjacent regression suites from plan 08-21
  found: PublisherNegative, LiveSeam WorkflowOnly, LiveSeam full, Phase08Qualification, and MooncakesObservation all exit 0 with their PASS markers.
  implication: publisher, hosted, qualification, observation, and zero-mutation seams remain compatible with the focused fix.
- timestamp: 2026-07-19T01:05:00+08:00
  checked: final owned diff, PowerShell parser, trailing whitespace, and `git diff --check`
  found: all five changed/new PowerShell files parse without errors; no trailing whitespace or diff-check errors; unrelated user changes remain unstaged.
  implication: the patch is syntactically clean and scoped for an exact atomic commit.

## Eliminated

- hypothesis: `Import-Module Invoke-Phase08R7PreLive.ps1` alone provides an isolated functions-only seam.
  evidence: caller `$LibraryOnly` changed from false to true after direct `.ps1` import.
  timestamp: 2026-07-19T00:10:00+08:00

## Resolution

- root_cause: R8 dot-sources R7 with `-LibraryOnly` in the same script scope. PowerShell parameter binding overwrites R8's own `$LibraryOnly` from false to true; after the R7 import returns, R8 reaches `if($LibraryOnly){return}` and exits successfully before building or emitting the pre-live result.
- fix: Added an R7 functions-only `.psm1` isolation boundary, changed R8 to import it instead of dot-sourcing R7 in R8's invocation scope, appended `result_sha256` from the exact ordered sanitized projection, and made R7's immutable seven-history view explicit while R8 opts into eight.
- verification: GREEN — Test-R7 and Test-R8 pass; R7 LibraryOnly and standalone guards pass; PublisherNegative, LiveSeam WorkflowOnly/full, Phase08Qualification, and MooncakesObservation pass; all changed PowerShell files parse; `git diff --check` passes. Direct live-environment R8 confirmation remains the required human checkpoint because network/state-root actions were forbidden.
- files_changed: [scripts/quality/Invoke-Phase08R7PreLive.Library.psm1, scripts/quality/Invoke-Phase08R7PreLive.ps1, scripts/quality/Invoke-Phase08R8PreLive.ps1, scripts/quality/Test-Phase08R7PreLive.ps1, scripts/quality/Test-Phase08R8PreLive.ps1]
