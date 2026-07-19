---
status: investigating
trigger: "Non-publishing r12 preauthorization recovery timed out while qualifying the three module packages; its agent left an unexpected root-level qualification.log, which was removed after its originating process was terminated."
created: 2026-07-19T21:35:00+08:00
updated: 2026-07-19T21:35:00+08:00
phase: "08"
plan: "32/33"
---

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

## Resolution

root_cause: "The recovery executor imposed a timeout on a long sequential qualification workload and redirected its output to a repository-root log. The canonical qualifier had progressed through core and color; its remaining mb-image source-isolation stage alone invokes 76 MoonBit commands. The first mb-image package command completes in 1.19 seconds, so no command-level package hang was reproduced."
fix: "No source change is justified. Re-run only the non-publishing qualifier under an explicit whole-process timeout budget that covers all stages, pass an absolute temporary OutputDirectory, and capture output in the executor instead of redirecting to a repository file."
verification: "Static command-count inspection plus a bounded r12 detached-clone reproduction of the first mb-image package command (exit 0 in 1.19 seconds). End-to-end rerun remains for the orchestrator under a sufficiently large bounded budget."
files_changed: []

## Specialist Review

Not run: the inferred `general` review maps to `engineering:debug`, which is not available in this session. The evidence supports a workflow/executor timeout rather than a source-level defect.
