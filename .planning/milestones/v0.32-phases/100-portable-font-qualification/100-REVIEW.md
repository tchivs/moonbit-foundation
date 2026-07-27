---
phase: 100-portable-font-qualification
reviewed: 2026-07-27T19:49:02Z
depth: deep
files_reviewed: 16
files_reviewed_list:
  - .github/workflows/quality.yml
  - fixtures/font/dejavu-sans-2.37/oracle.json
  - modules/mb-font/README.mbt.md
  - modules/mb-font/font/font_qualification_hostile_test.mbt
  - modules/mb-font/font/font_test.mbt
  - modules/mb-font/font/tables.mbt
  - policy/foundation.json
  - scripts/ci/Install-PinnedMoonBit.ps1
  - scripts/quality.ps1
  - scripts/quality/Assert-Policy.ps1
  - scripts/quality/Invoke-FontQualification.ps1
  - scripts/quality/Invoke-MoonQuality.ps1
  - scripts/quality/Invoke-RequiredBounded.ps1
  - scripts/quality/Test-FontQualificationEvidenceBoundary.ps1
  - scripts/quality/Test-QualityWorkflowPolicy.ps1
  - scripts/quality/Test-RequiredProcessTreeTermination.ps1
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 100: Code Review Report

**Reviewed:** 2026-07-27T19:49:02Z
**Depth:** deep
**Files Reviewed:** 16
**Status:** clean

## Summary

All reviewed files meet quality standards. No issues found.

The original six findings, the two installer follow-up warnings, and the subsequent
Required timeout-budget concern are resolved on exact commit
`8897f1c17bd7b35cd41213c7d00055265f13b953`. Deep re-review covered the immutable
toolchain transport in `f01a8cef`, exact installer-step shell binding in `7ecb34b6`,
and the paired Required runner/wrapper timeout changes in `280a5462` and
`8897f1c1`.

GitHub Actions run
[30297979654](https://github.com/tchivs/moonbit-foundation/actions/runs/30297979654)
completed successfully for that exact commit. The blocking Required job, portable
FontQualification job, and experimental non-blocking LLVM job all installed the
authenticated pinned toolchain from the immutable release assets and passed.

## Narrative Findings (AI reviewer)

No actionable bugs, security vulnerabilities, or quality defects remain in the
reviewed scope.

## Hosted Verification Evidence

- All three jobs checked out exact commit
  `8897f1c17bd7b35cd41213c7d00055265f13b953`.
- Required job `90083617352` completed successfully and printed the exact sentinel:

  ```text
  PASS: Required POSIX session preserves output and contains timed-out and ephemeral descendants
  ```

- The real Required lane ran through the bounded wrapper with
  `-TimeoutSeconds 1800` and passed.
- Required artifact `8666037685` was independently downloaded. Its ZIP SHA-256,
  `4e56a2126e38df10419e917c7e5c5b4008b0d488a222c9389430785f3e2be75a`,
  matches the GitHub artifact digest. Its `required-invocation.json` contains:

  ```json
  {
    "timeout_seconds": 1800,
    "timed_out": false,
    "exit_code": 0,
    "process_tree_terminated": true,
    "termination_status": "exited-session-terminated-verified",
    "status": "pass"
  }
  ```

- Portable FontQualification job `90083617417` completed successfully: focused
  outline `1/1`, hostile matrix `1/1`, and package suite `103/103` on each of `js`,
  `wasm`, `wasm-gc`, and `native`.
- Font artifact `8665402336` was independently downloaded. Its ZIP SHA-256,
  `df2266437bbf4ccfa0241c202b18d2b7bfc1acb24bd6a2bace2b3a4eeef692b3`,
  matches GitHub. `comparison.json` reports `equal=true` and semantic SHA-256
  `65b63177ed296ffa4cb1f46a4c6943d6036a71d70eb1b8409830a35e65fcdef8`;
  all four target records report `pass=true`.
- Experimental LLVM job `90083617339` completed successfully and remained explicitly
  unsupported and non-blocking.
- Every job reported exact identity
  `moon 0.1.20260713 (75c7e1f 2026-07-13)` with a verified core archive.

## Fix Verification

- **CR-01 resolved:** exact checked format 6 cmap length semantics pass on every
  supported target.
- **CR-02 resolved:** managed evidence cleanup rejects reparse/link traversal without
  mutating outside files.
- **CR-03 resolved:** Windows Job Object and POSIX session containment are both
  dynamically verified, including the exact blocking Ubuntu probe and authoritative
  Required termination evidence.
- **CR-04 resolved:** hostile evidence is bound to an exact focused test and exact
  passing summary on every target.
- **WR-01 resolved:** public documentation identifies oracle version `1.1.0`.
- **WR-02 resolved:** CI authenticates the exact toolchain and core archives before
  use, verifies identities, digests, modes, core layout, and four-target bundles,
  then exports the toolchain only after verification.
- **WR-03 resolved:** both archives now use immutable, versioned prerelease asset
  URLs while retaining byte length, archive SHA-256, binary SHA-256, identity, and
  layout checks. The policy matrix rejects mutable `latest` archive URLs.
- **WR-04 resolved:** the policy parses each job's step blocks and requires one exact
  installer step with the name, immediate `shell: pwsh`, and exact run command
  bound together. Independent mutation of all installer shells to Bash is rejected.
- **Required timeout budget resolved:** the Required job uses a 35-minute runner
  timeout paired with an 1800-second bounded wrapper, retains the blocking POSIX
  gate, and always uploads the exact diagnostic path. Policy tests reject independent
  or paired timeout drift, inverted cleanup margin, fail-open execution, and
  conditional diagnostic upload.

Local verification also passed the complete workflow/toolchain policy matrix,
PowerShell parser checks for all changed scripts, targeted negative mutations for
the Bash installer shell and mutable `latest` URL, and `git diff --check`.

---

_Reviewed: 2026-07-27T19:49:02Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
