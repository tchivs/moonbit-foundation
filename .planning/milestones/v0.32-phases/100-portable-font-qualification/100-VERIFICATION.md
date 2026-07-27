---
phase: 100-portable-font-qualification
verified: 2026-07-27T19:52:40Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 4/4
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 100: Portable Font Qualification Verification Report

**Phase Goal:** Maintainers can reproduce the complete public font workflow and hostile-input behavior with immutable fixtures on every supported target.
**Verified:** 2026-07-27T19:52:40Z
**Status:** passed
**Re-verification:** Yes — final independent verification after code-review hardening

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A maintainer can run one immutable public workflow that opens a font, maps BMP and supplementary scalars, reads metrics, extracts simple and composite outlines, and queries kerning with identical facts on all four targets. | ✓ VERIFIED | A fresh local `FontQualification` run passed the focused outline assertion 1/1 and the complete package 103/103 on each of `js`, `wasm`, `wasm-gc`, and `native`. Hosted job `90083617417` independently passed the same gates on exact code commit `8897f1c17bd7b35cd41213c7d00055265f13b953`. |
| 2 | Generated adversarial fixtures produce identical structured malformed-input, unsupported-feature, mutation, arithmetic, and resource-limit outcomes on all targets. | ✓ VERIFIED | The fresh local run passed the exact hostile assertion 1/1 on every target. Every local and hosted target record has `hostile_assertion_passed=true`, 11 hostile outcomes, and `pass=true`; normalized records compare equal. |
| 3 | A licensed real-font specimen has immutable bytes, provenance/license, digest, inventory, and reproducible public interoperability facts. | ✓ VERIFIED | The DejaVu Sans 2.37 fixture, notice, manifest, oracle 1.1.0, generator `-Check`, and focused policy gate all passed. Complete command-vector fingerprints remain independently bound to target-side exhaustive outline assertions. |
| 4 | Isolated font and workspace controls preserve `mb-font -> mb-core` only and exclude forbidden ambient/deferred capabilities. | ✓ VERIFIED | The generated interface contains exactly 56 semantic lines and matches both the recorded baseline and policy allowlist in exact order. `moon.mod.json` still declares only `tchivs/mb-core: 0.1.0`; `moon.pkg` still imports the five approved mb-core packages and supports all four targets. Exact hosted Required completed successfully through the bounded wrapper. |

**Score:** 4/4 truths verified (0 present-but-behavior-unverified)

## Final Hosted Evidence

GitHub Actions run `30297979654` completed successfully for exact code commit
`8897f1c17bd7b35cd41213c7d00055265f13b953`. The current verification worktree
HEAD, `5fdbfcfaba203fa951c782d4f41690918e615f18`, differs from that code commit
only by the two review reports.

| Job | Job ID | Result | Direct evidence |
|---|---:|---|---|
| Required | `90083617352` | ✓ PASS | Exact pinned toolchain installed; POSIX descendant-containment probe passed; real Required ran with `-TimeoutSeconds 1800` and passed. |
| FontQualification | `90083617417` | ✓ PASS | Focused outline 1/1, focused hostile 1/1, and package 103/103 on all four supported targets. |
| LLVM | `90083617339` | ✓ PASS | Experimental job passed and remains explicitly non-blocking. |

The artifacts were independently downloaded, hashed, and inspected:

| Artifact | Artifact ID | ZIP SHA-256 | Inspected result |
|---|---:|---|---|
| `required-diagnostic` | `8666037685` | `4e56a2126e38df10419e917c7e5c5b4008b0d488a222c9389430785f3e2be75a` | `timeout_seconds=1800`, `timed_out=false`, `exit_code=0`, `process_tree_terminated=true`, `termination_status=exited-session-terminated-verified`, `status=pass`. |
| `font-qualification-evidence` | `8665402336` | `df2266437bbf4ccfa0241c202b18d2b7bfc1acb24bd6a2bace2b3a4eeef692b3` | Four target records have `pass=true`, 11 hostile outcomes, and both focused assertions true. `comparison.json` has `equal=true` and semantic SHA-256 `65b63177ed296ffa4cb1f46a4c6943d6036a71d70eb1b8409830a35e65fcdef8`. |

All hosted jobs checked out the exact code commit and reported the authenticated
pinned identity `moon 0.1.20260713 (75c7e1f 2026-07-13)`.

## Previous Gap Closure Regression

The previously closed fingerprint-evidence gap remains closed:

| Scalar | Complete commands | Independently recomputed fingerprint | Status |
|---|---:|---|---|
| U+0041 | 13 | `ccb4bab2977fff264d8a8421ccb01e333b837e02bc7b5eb6c67e435ffcd2d308` | ✓ MATCH |
| U+034C | 48 | `f5dfde0b4b9620c9de27a766cdd3fee9efa89f7fd1044c9d9f68ce2e94aed827` | ✓ MATCH |
| U+10300 | 13 | `c082fb5502ff6694c084a4ebce10d0208171a9c8079051cb544868b44e92267a` | ✓ MATCH |

All 74 ordered commands remain generated from the immutable TTF through the
independent oracle and are exhaustively asserted through the public `Font::outline`
and `Path2` API before evidence publication.

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf` and license/manifest | Immutable licensed real-font specimen | ✓ VERIFIED | Exact provenance, digest, license, and redistribution policy pass the focused selector. |
| `fixtures/font/dejavu-sans-2.37/oracle.json` | Independent complete public facts | ✓ VERIFIED | Oracle 1.1.0 retains the complete command vectors and exact fingerprints. |
| `scripts/fixtures/Generate-FontQualification.ps1` | Deterministic fixture/oracle-to-test generation | ✓ VERIFIED | Fresh `-Check` passed; generated data remains drift-free. |
| `modules/mb-font/font/generated_font_qualification_test.mbt` | Test-private immutable facts | ✓ VERIFIED | Contains all three supported outline expectations and 74 ordered commands. |
| `modules/mb-font/font/font_qualification_test.mbt` | Complete public-workflow and exhaustive outline assertions | ✓ VERIFIED | Focused outline assertion passed on every target locally and in hosted CI. |
| `modules/mb-font/font/font_qualification_hostile_test.mbt` | Closed hostile-input behavior matrix | ✓ VERIFIED | Focused hostile assertion passed on every target locally and in hosted CI. |
| `modules/mb-font/font/tables.mbt` | Strict bounded cmap classification | ✓ VERIFIED | Format 6 now requires the checked exact declared length `10 + entryCount * 2`; the regression is exercised by the passing package tests. |
| `scripts/quality/Invoke-FontQualification.ps1` | Fail-closed four-target evidence runner | ✓ VERIFIED | Separately gates exact outline and hostile tests before full-suite evidence construction. |
| `scripts/quality/Invoke-RequiredBounded.ps1` | Bounded process-tree-contained Required execution | ✓ VERIFIED | Local Windows containment regression passed; hosted POSIX containment and real Required diagnostic passed. |
| `scripts/ci/Install-PinnedMoonBit.ps1` and `.github/workflows/quality.yml` | Authenticated immutable toolchain and bounded jobs | ✓ VERIFIED | Hosted run used the exact installer and identity; policy mutations fail closed. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Immutable DejaVu TTF | Independent oracle | Closed offline SFNT parser | ✓ WIRED | Complete vectors and hashes are derived from immutable bytes without using mb-font output. |
| Independent oracle | Generated MoonBit expectations | Deterministic generator | ✓ WIRED | Count, vector, and hash invariants pass; generated drift check passes. |
| Generated expectations | Public Path2 results | Exhaustive black-box outline test | ✓ WIRED | All 74 ordered commands are structurally asserted on all four targets. |
| Hostile descriptors | Structured public errors | Exact focused hostile test | ✓ WIRED | All 11 outcomes are target-exercised before evidence publication. |
| Focused tests | Target evidence | Exact exit-code and one-test-summary gates | ✓ WIRED | Each target record states both focused assertions passed. |
| Target records | Canonical comparison | Normalize only `target` and `runner` | ✓ WIRED | Four records compare equal with the expected semantic digest. |
| Workflow | Pinned toolchain installer | Exact named step with `shell: pwsh` | ✓ WIRED | Hosted jobs report the exact authenticated MoonBit identity. |
| Required workflow step | Bounded wrapper | 35-minute outer timeout and 1800-second wrapper | ✓ WIRED | Hosted Required diagnostic proves pass and verified process-tree termination. |

## Data-Flow Trace (Level 4)

| Data | Source | Consumer | Produces real data | Status |
|---|---|---|---|---|
| Complete DejaVu commands | Independent parsing of immutable TTF bytes | Oracle `path.commands` | Yes | ✓ FLOWING |
| Structured expected commands | Oracle complete vectors | Generated MoonBit black-box test | Yes | ✓ FLOWING |
| Runtime outline geometry | Public `Font::outline` | Exhaustive target assertions | Yes | ✓ FLOWING |
| Hostile outcomes | Generated malformed/adversarial fixtures | Public error assertions and target records | Yes | ✓ FLOWING |
| Required status | Real hosted Required process | Uploaded `required-invocation.json` | Yes | ✓ FLOWING |

## Code-Review Hardening Verification

| Finding | Verification | Status |
|---|---|---|
| CR-01: format 6 cmap length validation | Source requires checked exact length; four-target 103-test suites pass. | ✓ CLOSED |
| CR-02: evidence cleanup boundary | `Test-FontQualificationEvidenceBoundary.ps1` passed, including linked/reparse containment. | ✓ CLOSED |
| CR-03: descendant termination | Local Windows Job Object test passed; hosted POSIX session sentinel and Required diagnostic prove dynamic containment. | ✓ CLOSED |
| CR-04: hostile evidence gate | Fresh and hosted records require and report `hostile_assertion_passed=true`. | ✓ CLOSED |
| WR-01: oracle documentation | README identifies oracle 1.1.0. | ✓ CLOSED |
| WR-02/03: pinned immutable toolchain | Hosted jobs authenticated exact immutable archives and exact tool identities. | ✓ CLOSED |
| WR-04: installer shell binding | Workflow policy mutation matrix passed and hosted step executed through exact `shell: pwsh`. | ✓ CLOSED |
| Required timeout budget | Policy enforces 35 minutes / 1800 seconds; hosted real Required passed and uploaded unconditional diagnostics. | ✓ CLOSED |

The current `100-REVIEW.md` is clean with zero findings. That review is
corroborating evidence; the verdict above is based on direct source inspection,
local executions, hosted job results, and independently inspected artifacts.

## Public Surface, Dependency, and Scope Regression

| Check | Result | Status |
|---|---|---|
| Generated interface | 80 physical lines, exactly 56 semantic lines after the project’s blank/comment filter | ✓ PASS |
| Semantic interface identity | Exact ordered match to both Phase 100 baseline and `policy/foundation.json` | ✓ PASS |
| Runtime module dependency | Exactly `tchivs/mb-core: 0.1.0` | ✓ PASS |
| Package imports | Approved `budget`, `bytes`, `checked`, `error`, and `math` mb-core packages only | ✓ PASS |
| Supported targets | `+js+wasm+wasm-gc+native` | ✓ PASS |
| Code delta after hosted commit | Current HEAD adds only `100-REVIEW.md` and `100-REVIEW-FIX.md` | ✓ PASS |
| Forbidden/deferred capabilities | Focused policy and source-boundary checks pass | ✓ PASS |

## Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Complete portable font qualification | `./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/font-final-verification` | Outline 1/1, hostile 1/1, package 103/103 on all four targets; comparison equal | ✓ PASS |
| Evidence destructive boundary | `./scripts/quality/Test-FontQualificationEvidenceBoundary.ps1` | Boundary test passed | ✓ PASS |
| Workflow/toolchain policy | `./scripts/quality/Test-QualityWorkflowPolicy.ps1` | Complete mutation matrix passed | ✓ PASS |
| Windows descendant containment | `./scripts/quality/Test-RequiredProcessTreeTermination.ps1` | Normal, late, and ephemeral descendants contained | ✓ PASS |
| Hosted POSIX descendant containment | Required job `90083617352` | Exact POSIX sentinel passed | ✓ PASS |
| Hosted real Required | Artifact `8666037685` | Exit 0, no timeout, verified termination, status pass | ✓ PASS |

## Probe Execution

No phase-declared `probe-*.sh` is part of the Phase 100 contract. The dedicated
PowerShell behavioral checks are recorded above.

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| FONT-05 | 100-01 through 100-06 | Licensed immutable complete public font workflow and hostile qualification on all supported targets | ✓ SATISFIED | Fresh local and exact-commit hosted qualification pass all four targets; artifacts are reproducible and independently inspected. |

No additional Phase 100 requirement is orphaned from the phase plans.

## Anti-Patterns Found

No unresolved `TBD`, `FIXME`, or `XXX` debt marker, placeholder implementation,
empty handler, evidence-before-test construction, mutable toolchain transport,
public API expansion, dependency expansion, or target exception was found in the
final hardened scope.

## Human Verification Required

None.

## Gaps Summary

No gaps, regressions, behavior-unverified truths, unresolved prohibitions, or
human decisions remain. The phase goal is achieved.

---

_Verified: 2026-07-27T19:52:40Z_
_Verifier: the agent (gsd-verifier)_
