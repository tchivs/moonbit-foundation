---
status: resolved
trigger: "Phase 8 r4 HostedPreflight run 29667231047 failed in prepare/Invoke-ReleaseQualification because a clean checkout produced an empty tracked-diff snapshot and Assert-ReleaseTrackedSnapshot rejected the empty Before value."
created: 2026-07-19
updated: 2026-07-19T00:00:14+08:00
---

# Debug Session: Phase 8 Clean Tracked Snapshot

## Symptoms

- Expected: A clean checkout is represented as a valid empty tracked-diff snapshot, HostedPreflight qualification proceeds, and later non-empty drift remains detectable.
- Actual: `Get-ReleaseTrackedDiffSnapshot` legally returns an empty string, then `Assert-ReleaseTrackedSnapshot` rejects the mandatory string parameter `Before` before its comparison logic runs.
- Error: HostedPreflight run `29667231047` failed during prepare / `Invoke-ReleaseQualification`.
- Timeline: Observed on the immutable r4 boundary `ee4a8eb` after registry observation confirmed the module absent.
- Reproduction: Run the release qualification path from a clean checkout where the tracked diff snapshot is empty.

## Known External State

- r4 immutable boundary: `ee4a8eb`
- registry observation: `confirmed_absent`
- publish run `29667231047`: failure
- PublisherDryRun, packet, receipt, handoff, mutation: zero
- Forbidden during this session: push, tag, GitHub/network access, secret access, StateRoot changes, registry/publication actions, moving r4, or planning r5.

## Current Focus

- hypothesis: Confirmed — valid empty tracked snapshots were rejected solely by PowerShell parameter binding; allowing empty strings fixes clean snapshots without weakening ordinal drift comparison.
- test: Human verification confirmed the committed fix is accepted for the next forward clean-checkout boundary while immutable r4 remains terminal and unmoved.
- expecting: Satisfied — original issue confirmed fixed.
- next_action: Commit this archived record and its knowledge-base entry as one focused documentation commit.
- reasoning_checkpoint:
    hypothesis: `Get-ReleaseTrackedDiffSnapshot` maps a clean Git diff to `''`, but the pre-fix `Assert-ReleaseTrackedSnapshot` mandatory string parameters reject `''` before its ordinal equality comparison.
    confirming_evidence:
      - The hosted failure and parallel debug record report the exact empty-string binding error at the assertion call after package checks completed.
      - HEAD commit `cca6196` changes only the snapshot parameter contract and adds an equal-empty regression beside the existing unequal mutation rejection.
      - The focused helper/test paths have no uncommitted diff, so the fix and regression are already tracked in HEAD.
    falsification_test: Loading `cca6196^` helper code and invoking `Assert-ReleaseTrackedSnapshot -Before '' -After ''` would disprove the hypothesis if it entered the function or succeeded instead of failing parameter binding.
    fix_rationale: Adding `[AllowEmptyString()]` admits the valid empty snapshot value at the binding boundary while retaining the same ordinal comparison, so unequal snapshots still throw `REL14-TRACKED-SOURCE-MUTATION`.
    blind_spots: The local ambient checkout is dirty and cannot reproduce a naturally empty Git diff; the regression therefore supplies explicit empty values, and full focused suites must still confirm adjacent prepared/publisher/live/observation behavior.
- tdd_checkpoint:
    test_file: scripts/quality/Test-ReleaseQualificationNegative.ps1
    test_name: equal-empty tracked snapshot acceptance
    status: green
    failure_output: "Cannot bind argument to parameter 'Before' because it is an empty string."

## Evidence

- timestamp: 2026-07-19T00:00:01+08:00
  checked: Debug knowledge base
  found: The only prior entry concerns Phase 6 qualification ordering; it has fewer than two symptom/error keyword overlaps with this empty-snapshot binding failure.
  implication: No known-pattern candidate qualifies; investigate the local PowerShell contract directly.

- timestamp: 2026-07-19T00:00:02+08:00
  checked: Project rules, project skills, and configured gsd-debugger agent skills
  found: No project skill directories, `rules/*.md`, or configured debugger agent skills are present.
  implication: Repository AGENTS.md and the core debugger protocol are the applicable local rules.

- timestamp: 2026-07-19T00:00:03+08:00
  checked: Code discovery availability and worktree status
  found: The configured codebase-memory graph tools are unavailable in this session, so literal `rg` fallback located the PowerShell helper/callers/tests. Existing dirty files are unrelated; the focused helper and test suite are clean.
  implication: Preserve all existing dirty paths and limit changes to the focused helper, regression test, and this debug record.

- timestamp: 2026-07-19T00:00:04+08:00
  checked: Parallel active debug record `.planning/debug/clean-diff-empty-binding.md`
  found: It records the exact hosted binding error, a RED equal-empty regression, a minimal `[AllowEmptyString()]` fix on both snapshot parameters, GREEN adjacent suites, and status `awaiting_human_verify`.
  implication: Avoid duplicate edits; first verify whether that independently completed change is already in the current tracked snapshot.

- timestamp: 2026-07-19T00:00:05+08:00
  checked: Focused current code, test, git diff, and commit history
  found: HEAD is `cca6196 fix(08-13): accept clean tracked snapshots`; `Test-ReleaseQualificationNegative.ps1` includes `Assert-ReleaseTrackedSnapshot -Before '' -After ''` immediately before the existing unequal `REL14-TRACKED-SOURCE-MUTATION` case, and both focused paths have no uncommitted diff.
  implication: The minimal fix/regression are already committed; verify RED causality against the commit predecessor rather than duplicating or reverting tracked work.

- timestamp: 2026-07-19T00:00:07+08:00
  checked: TDD RED against `cca6196^` using the committed equal-empty regression input
  found: The pre-fix helper failed exactly with `Cannot bind argument to parameter 'Before' because it is an empty string.`
  implication: The regression directly reproduces the hosted bug and confirms the root cause before the fix; the next continuation may perform GREEN verification at HEAD.

- timestamp: 2026-07-19T00:00:09+08:00
  checked: Required suite entrypoint discovery
  found: Local candidates are `Test-ReleaseQualificationNegative.ps1`, `Test-PreparedReleaseBundle.ps1`, `Test-ReleasePublisherNegative.ps1`, `Test-Phase08LiveSeam.ps1`, and `Test-MooncakesObservation.ps1`; the initial wildcard plan search was not portable to PowerShell/Windows and returned no plan references.
  implication: Inspect each candidate's declared selectors and use literal-path plan enumeration rather than guessing commands.

- timestamp: 2026-07-19T00:00:10+08:00
  checked: Test parameter/dispatch guards and Phase 8 automated verification commands
  found: Phase 8 plans define these scripts as local automated verification; prepared/publisher/live/observation tests operate through generated temp fixtures and library/static seams. Full LiveSeam is a tracked test command in plans 08-08 through 08-12, and no selected command invokes hosted/network/publication modes.
  implication: The required GREEN matrix is safe to run locally; include both the focused release-negative regression and Phase 8 qualification coverage.

- timestamp: 2026-07-19T00:00:11+08:00
  checked: TDD GREEN and required adjacent suite matrix at HEAD `cca6196`
  found: `Test-ReleaseQualificationNegative`, `Test-Phase08Qualification`, `Test-PreparedReleaseBundle`, `Test-ReleasePublisherNegative`, full `Test-Phase08LiveSeam`, and `Test-MooncakesObservation` all exited 0. The qualification-negative suite explicitly reported rejection of `REL14-TRACKED-SOURCE-MUTATION` for unequal non-empty snapshots.
  implication: Equal empty snapshots are accepted and non-empty drift detection remains fail-closed across all required adjacent contracts.

- timestamp: 2026-07-19T00:00:12+08:00
  checked: `git diff --check`
  found: Exit 0; only LF-to-CRLF warnings were emitted for three pre-existing unrelated user-dirty files.
  implication: The focused commit/debug work introduces no whitespace errors, and unrelated user changes remain untouched.

- timestamp: 2026-07-19T00:00:13+08:00
  checked: Human verification checkpoint
  found: User response was `confirmed fixed`.
  implication: The session may be resolved, archived, and committed without changing the existing fix commit or r4 state.

- timestamp: 2026-07-19T00:00:14+08:00
  checked: Debug archive target
  found: Session moved to `.planning/debug/resolved/phase08-clean-tracked-snapshot.md`; no prior destination existed.
  implication: The resolved record and knowledge-base entry are ready for one focused documentation commit.

## Eliminated


## Resolution

- root_cause: A clean checkout produces `''` from `Get-ReleaseTrackedDiffSnapshot`, but the pre-fix mandatory string parameters on `Assert-ReleaseTrackedSnapshot` rejected that legitimate value during PowerShell binding before ordinal equality could run.
- fix: Already present in HEAD commit `cca6196`: add `[AllowEmptyString()]` to both snapshot parameters and add an equal-empty regression beside the existing unequal mutation rejection.
- verification: RED against `cca6196^` reproduced the exact hosted binding error. GREEN at `cca6196` passed QualificationNegative, Phase08Qualification, Prepared, Publisher, full LiveSeam, Observation, and diff-check suites; unequal non-empty drift still rejected as `REL14-TRACKED-SOURCE-MUTATION`.
- files_changed: [scripts/quality/ReleaseQualification.Common.ps1, scripts/quality/Test-ReleaseQualificationNegative.ps1]
