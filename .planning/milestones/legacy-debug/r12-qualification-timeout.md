---
status: resolved-incorrect
supersedes_hypothesis: "executor budget timeout"
correct_root_cause: "REL01-REF — r12 boundary tag (5e7b19cd) internally inconsistent: policy declares r12 but Invoke-ReleaseQualification.ps1 still hardcodes r9"
created: 2026-07-19T21:35:00+08:00
updated: 2026-07-19T22:10:00+08:00
phase: "08"
plan: "32/33"
---

# r12 Qualification — Corrected Diagnosis

> **⚠ CORRECTION (2026-07-19T22:10):** The original `status: investigating` hypothesis below ("executor budget timeout") is **wrong**. A deterministic reproduction with `Set-PSBreakpoint` inside the boundary clone proved the failure is `REL01-REF`, not a timeout. The original timeout narrative and its recommended fix ("re-run with larger budget") will NOT resolve the issue. The verified root cause and the evidence that overturns the original hypothesis are recorded in the `Corrected Diagnosis` section. The original text is preserved verbatim below it for audit traceability — do not act on the original `Resolution` block.

## Corrected Diagnosis (2026-07-19T22:10, verified)

### Root cause

`REL01-REF: initial release ref is not the clone policy-selected immutable tag.` — thrown from `Assert-ReleaseInitialCloneBinding` at `scripts/quality/ReleaseQualification.Common.ps1:301`, called during `Write-InitialReleaseIntentBinding` in `New-ReleaseIntent.ps1:83`.

The r12 boundary tag (`refs/tags/modules-v0.1.0-r12`, object `57b76c9f`, peel `5e7b19cd`) is **internally inconsistent**:

- `policy/release-control.json` at commit `5e7b19cd` declares `initial_profile.release_ref = refs/tags/modules-v0.1.0-r12` and `initial_attempt_family.current_attempt = r12` (terminal_negative_history count 12).
- `scripts/quality/Invoke-ReleaseQualification.ps1` at the **same commit** still hardcodes the r9 release ref (lines 302, 313: `-ReleaseRef 'refs/tags/modules-v0.1.0-r9'`).
- The boundary wrapper `Invoke-Phase08R12Boundary.ps1` correctly derives r12 from clone-local policy → invokes the boundary-local qualifier → qualifier passes r9 to `New-ReleaseIntent.ps1` → `Assert-ReleaseInitialCloneBinding` compares `policy.release_ref (r12)` vs. `ReleaseRef (r9)` → throws `REL01-REF`.

### Why this is deterministic, not a timeout

The throw occurs **after** all three module packages (mb-core, mb-color, mb-image) qualify successfully. `Write-InitialReleaseIntentBinding` is the last step before the `finally` block in `Invoke-ReleaseQualification.ps1`. Package timing is irrelevant to this failure; it throws in seconds once intent binding runs.

### Timeline (the smoking gun)

| Time (2026-07-19 +08:00) | Event |
|---|---|
| 19:53:11 | commit `5e7b19cd` "fix(ci): use reachable MoonBit toolchain channel" — policy already says r12, qualifier script still says r9 |
| **19:56:43** | **r12 tag created** (object `57b76c9f`, peel `5e7b19cd`) — 3.5 min after the inconsistent commit |
| 20:22:24 | commit `d55f63a` "fix(ci): bind qualification to r12 release ref" — qualifier updated to r12, **26 min after the tag** |
| 20:27:31 | commit `4ff551c` "fix(ci): qualify immutable r12 source boundary" |

The tag was created at a commit where policy and qualifier disagreed. The fix landed 26 minutes later, but the tag is immutable and cannot be re-pointed.

### Process defect this exposes

There is **no hard gate preventing tag creation before the qualification script matches the target ref**. The r10/r11 tags were created under the same wrapper but happened to land on commits where script and policy agreed (or the mismatch was not exercised). r12 exposed the gap because the wrapper delegated to a qualifier that still hardcoded the predecessor ref.

### Recommended corrective ordering invariant (for r13+)

Before creating any future boundary tag `rN`:
1. Verify `scripts/quality/Invoke-ReleaseQualification.ps1` at the candidate commit references `refs/tags/modules-v0.1.0-rN` (not `r{N-1}`) on every `-ReleaseRef` argument.
2. Verify `policy/release-control.json` at the candidate commit declares `current_attempt = rN` and `release_ref = refs/tags/modules-v0.1.0-rN`.
3. Run the boundary wrapper end-to-end against the candidate commit in a disposable clone and require `PrepareAttempt` to complete (not just `InitializeBoundary`).
4. Only then create and push the `rN` tag.

This should be enforced by a new PreLive check that runs the qualifier's intent-binding step **before** tag creation, not only by the post-tag selector that currently exists.

### Consequence for r12

r12 is publish-blocked terminal evidence. It cannot pass its own qualification. Per Phase 08 invariants the tag is immutable (local == remote, ancestor of HEAD), so it cannot be fixed in place. The forward path is r13 (or later), not a retry of r12.

### Evidence overturning the original hypothesis

- Deterministic reproduction with `Set-PSBreakpoint` inside the boundary clone captured: `policy.initial_profile.release_ref = 'refs/tags/modules-v0.1.0-r12'`, `ReleaseRef = 'refs/tags/modules-v0.1.0-r9'`.
- The throw is `REL01-REF`, not a timeout exit code.
- All three module packages complete successfully before the throw (the original narrative claimed image did not complete due to timeout).
- `git show 5e7b19cd:scripts/quality/Invoke-ReleaseQualification.ps1` line 302 confirms `r9`; `git show 5e7b19cd:policy/release-control.json` confirms `r12`.
- `git show HEAD:scripts/quality/Invoke-ReleaseQualification.ps1` line 302 confirms the fix to `r12` landed later (commit `d55f63a`).

---

# Original Diagnosis (SUPERSEDED — preserved verbatim for audit, DO NOT ACT ON IT)

> The `hypothesis`, `expecting`, `Resolution.root_cause`, and `Resolution.fix` fields below are **incorrect**. They are retained only so the audit trail shows what was originally claimed and how it was overturned.

## Current Focus

hypothesis: "The failure was an outer executor budget timeout, not a deterministic mb-image package failure: the qualifier's image source-isolation alone schedules 76 MoonBit commands after core/color have already consumed 60 commands."
test: "Compare the canonical command model with observed completed core/color progress and verify that no executor-side redirection is part of the canonical R12 workflow."
expecting: "The command count and successful first image package explain the timeout position; a rerun with an explicit whole-qualification budget and an absolute temporary output directory should complete without creating a root log."
next_action: "Return the diagnosis and safe retry direction to the orchestrator; do not edit release scripts without evidence of a command-level hang."

## Symptoms

expected: "The non-publishing r12 boundary qualification completes for core, color, and image, then proceeds to preflight/dry-run with no repository-root output files."
actual: "Core and color qualification completed; the recovery timed out before image and left qualification.log at repository root."
errors: "No explicit qualification error; timeout plus unexpected root-level log."
timeline: "Observed during fresh baseline/preauthorization recovery after r12 tag and clone checks passed."
reproduction: "Execute the canonical r12 non-publishing qualification path from a disposable no-local clone."

## Eliminated

- hypothesis: "The first mb-image moon package --frozen --list command blocks in a detached clean clone."
  evidence: "The exact command completed in 1.19 seconds at r12 with exit code 0 under a 90-second process-tree timeout."
  timestamp: 2026-07-19T21:49:00+08:00

## Evidence

- timestamp: 2026-07-19T21:35:00+08:00
  checked: "Origin of qualification.log"
  found: "A terminated executor-owned pwsh process redirected Invoke-ReleaseQualification output to qualification.log in the repository root."
  implication: "The log was a recovery-process artifact, not user content or release evidence."

- timestamp: 2026-07-19T21:41:00+08:00
  checked: "Working tree and qualification references"
  found: "The working tree contains unrelated tracked and untracked user changes; the canonical implementation is scripts/quality/Invoke-ReleaseQualification.ps1 and the workflow calls it with -Check and a runner-temp output directory."
  implication: "Investigation must use a disposable clone or test-only temporary directory and must not stage, discard, or alter existing user paths."

- timestamp: 2026-07-19T21:43:00+08:00
  checked: "Canonical release qualifier entrypoint"
  found: "Invoke-ReleaseQualification requires -Check; it creates clean clones, runs moon package plus all-target source-isolation checks, and writes reports only to its configured output directory. The default report location is repository-relative, but the hosted R12 workflow explicitly supplies runner temp."
  implication: "A bounded reproduction must provide an absolute temporary OutputDirectory and avoid executor-level output redirection."

- timestamp: 2026-07-19T21:45:00+08:00
  checked: "Qualifier main execution path and R12 wrappers"
  found: "The qualifier processes mb-core, mb-color, then mb-image. For downstream modules it packages twice and then runs all-target source-isolation checks. R12 boundary itself only derives the clone-local immutable tag and delegates to HostedRun; it does not invoke MoonBit commands directly."
  implication: "The reported post-color timeout can be differentiated first at the initial mb-image package command, then at source isolation if packaging completes."

- timestamp: 2026-07-19T21:49:00+08:00
  checked: "First mb-image qualification command at r12 in a detached clean clone"
  found: "moon package --frozen --list for mb-image completed successfully in 1.19 seconds (55 tasks) with exit code 0."
  implication: "The initial mb-image packaging hypothesis is eliminated; the timeout occurred later in the stage or outside the canonical subprocess."

- timestamp: 2026-07-19T21:53:00+08:00
  checked: "Qualification command model from release policy and source-isolation loop"
  found: "The qualifier uses four targets, with 6 core, 5 color, and 6 image public packages. mb-image source isolation executes 68 dependency checks plus 8 consumer check/test commands (76 MoonBit commands); mb-color source isolation already executes 52. The canonical workflow invokes the qualifier directly with an absolute runner-temp output directory and has no qualification.log redirection."
  implication: "Observed core/color completion followed by timeout before image is consistent with an insufficient outer execution budget. It is not evidence for an image packaging defect; the root-level log was outside the canonical path."

- timestamp: 2026-07-19T21:54:00+08:00
  checked: "Bounded diagnostic cleanup"
  found: "The execution environment rejected the explicit recursive deletion of the verified temporary diagnostic clone at C:/Users/Admin/AppData/Local/Temp/mnf-r12-image-package-diag-bounded."
  implication: "No further temporary diagnostic artifacts should be created by this session; the existing temporary clone requires cleanup by an environment-authorized process."

## Resolution (SUPERSEDED — root_cause and fix are wrong)

root_cause: "The recovery executor imposed a timeout on a long sequential qualification workload and redirected its output to a repository-root log. The canonical qualifier had progressed through core and color; its remaining mb-image source-isolation stage alone invokes 76 MoonBit commands. The first mb-image package command completes in 1.19 seconds, so no command-level package hang was reproduced."
fix: "No source change is justified. Re-run only the non-publishing qualifier under an explicit whole-process timeout budget that covers all stages, pass an absolute temporary OutputDirectory, and capture output in the executor instead of redirecting to a repository file."
verification: "Static command-count inspection plus a bounded r12 detached-clone reproduction of the first mb-image package command (exit 0 in 1.19 seconds). End-to-end rerun remains for the orchestrator under a sufficiently large bounded budget."
files_changed: []

## Specialist Review

Not run: the inferred `general` review maps to `engineering:debug`, which is not available in this session. The evidence supports a workflow/executor timeout rather than a source-level defect.
