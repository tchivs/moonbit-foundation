---
phase: 94-svg-benchmark-evidence
plan: 02
subsystem: benchmark-evidence
tags: [powershell, moonbit, svg, native, reproducibility, sha256]
requires:
  - phase: 94-01
    provides: correctness-gated SVG benchmark workloads and portable runnable qualification
provides:
  - PowerShell 5.1-safe native SVG baseline capture and read-only Markdown audit
  - committed clean-worktree evidence with one warmup and seven retained native captures
affects: [svg-benchmarking, release-evidence, native-performance-observation]
tech-stack:
  added: [PowerShell SHA-256 capture/audit script]
  patterns: [clean-worktree provenance, HTML-escaped raw output audit, seven-sample native-only statistics]
key-files:
  created:
    - scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1
    - docs/benchmarks/mb-svg-native-release-baseline.md
  modified: []
key-decisions:
  - "Native evidence uses one excluded warmup and exactly seven retained release captures."
  - "The audit decodes explicitly no-BOM UTF-8 evidence and revalidates full output digests without rerunning MoonBit."
  - "Raw output is HTML-escaped in collapsible preformatted blocks so exact whitespace remains auditable while git diff --check stays clean."
patterns-established:
  - "Benchmark evidence is captured only from a clean detached worktree and committed before read-only audit."
  - "PowerShell 5.1 compatibility requires SHA256.Create, BitConverter hexadecimal rendering, ASCII regex escapes, and explicit UTF-8 decoding."
requirements-completed: [SVGPR-04]
coverage:
  - id: D1
    description: Native capture and read-only audit generator records provenance, complete output, and seven-capture statistics.
    requirement: SVGPR-04
    verification:
      - kind: integration
        ref: powershell.exe and pwsh Invoke-SvgNativeBenchmarkBaseline.ps1 -Audit
        status: pass
    human_judgment: false
  - id: D2
    description: Committed native-release baseline retains one excluded warmup and seven separately recorded captures.
    requirement: SVGPR-04
    verification:
      - kind: integration
        ref: docs/benchmarks/mb-svg-native-release-baseline.md audited in a clean detached worktree
        status: pass
    human_judgment: false
metrics:
  duration: 17min
  completed: 2026-07-25
status: complete
---

# Phase 94 Plan 02: Native SVG Baseline Evidence Summary

**A PowerShell 5.1-safe, clean-worktree native SVG evidence generator now preserves one warmup, seven release captures, complete auditable output, immutable SHA-256 provenance, and native-only summary statistics.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-07-25T20:00:16Z
- **Completed:** 2026-07-25T20:16:40Z
- **Tasks:** 3/3
- **Files modified:** 2

## Accomplishments

- Added a fixed-command generator/auditor that is syntactically valid in Windows PowerShell 5.1 and PowerShell 7, refuses dirty worktrees, validates the policy-pinned toolchain, and never adds a threshold or CI decision.
- Captured and committed native-only evidence from a clean detached checkout: one excluded warmup and seven retained captures for path parsing, transform composition, and parse-to-lower.
- Audited the final committed Markdown record under both engines, independently matching current source/corpus/correctness digests, eight output digests, ordered runner summaries, and seven-sample aggregates without running MoonBit or writing files.

## Baseline Facts

- **Evidence commit:** `967bd9102f2d3ad29efebd9eebe47fc2fa2b6634`; worktree identity: `(clean)`.
- **Exact command:** `moon bench modules/mb-svg/svg --release --target native --frozen`.
- **Host:** Windows 11 Enterprise 10.0.22631 build 22631, Intel Xeon Platinum 8378C (4 physical / 8 logical cores), 34,358,808,576 bytes physical memory, Balanced power plan.
- **Seven-capture means:** path parse `1.777142857 ms`; transform composition `0.137724286 ms`; parse-to-lower `0.902464286 ms`.

## Task Commits

1. **Task 1: Add a PowerShell 5.1-safe native capture and read-only audit generator** — `3dd8e3d`, `81827a4`, `76381c9`, `c4af258`.
2. **Task 2: Generate the clean-tree native-release baseline** — `c5e95ef`, `c382805`, `14255e6`, `56da3e9`.
3. **Task 3: Audit the committed baseline under both supported PowerShell engines** — `967bd91`, `760224b`, `d385721`, `49fbbc7`.

## Verification

- Windows PowerShell 5.1 syntax/load verification — passed.
- PowerShell 7 syntax/load verification — passed.
- Clean detached-worktree generator run — passed; retained one warmup and seven captures.
- `powershell.exe ... -Audit` — passed.
- `pwsh ... -Audit` — passed.
- `git diff --check ab631b28..HEAD` — passed.

## Decisions Made

- The capture command is fixed in source and cannot be supplied or altered by callers.
- Raw benchmark output is stored in collapsible HTML-escaped `<pre>` blocks; audit decodes those exact strings before hashing and parsing.
- The document retains all-target invocation only as non-timing functional qualification context; no cross-target timing values, ranking, threshold, or regression conclusion is emitted.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Captured MoonBit warnings and runner output reliably across PowerShell engines**
   - **Found during:** Task 1
   - **Issue:** Native stderr warnings were terminating in PowerShell, and the Windows PowerShell parser could not safely read literal benchmark glyphs from a no-BOM script.
   - **Fix:** Captured the fixed MoonBit command through `cmd.exe` merged output, accepted only its exit code, stripped the runner's `bench ` prefix, and used ASCII regex escapes for units and symbols.
   - **Files modified:** `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1`
   - **Commits:** `81827a4`, `76381c9`, `c4af258`

2. **[Rule 3 - Blocking issue] Create the planned documentation output directory before first rendering**
   - **Found during:** Task 2
   - **Issue:** `docs/benchmarks/` did not exist, so the successful capture could not write its planned artifact.
   - **Fix:** Created the output directory only when absent before writing the baseline document.
   - **Files modified:** `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1`
   - **Commit:** `c5e95ef`

3. **[Rule 1 - Bug] Make generated Markdown independently auditable in Windows PowerShell 5.1**
   - **Found during:** Task 3
   - **Issue:** Windows PowerShell read UTF-8-no-BOM content with its ANSI default and the visible aggregate parser could select a per-run row.
   - **Fix:** ASCII-escaped the audit JSON, decoded document bytes with the declared UTF-8 encoder, and scoped aggregate parsing to the dedicated summary section.
   - **Files modified:** `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1`, `docs/benchmarks/mb-svg-native-release-baseline.md`
   - **Commits:** `967bd91`, `760224b`, `d385721`, `49fbbc7`

4. **[Rule 1 - Bug] Preserve exact raw output while passing whitespace validation**
   - **Found during:** Task 2 final diff gate
   - **Issue:** MoonBit's complete runner output contains trailing display spaces, which made `git diff --check` fail.
   - **Fix:** Rendered raw output as HTML-escaped collapsible preformatted content and decoded it before audit hashing/parsing.
   - **Files modified:** `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1`, `docs/benchmarks/mb-svg-native-release-baseline.md`
   - **Commits:** `14255e6`, `56da3e9`

**Total deviations:** 8 auto-fixed (7 Rule 1 bugs, 1 Rule 3 blocking issue).

## Known Stubs

None.

## Issues Encountered

- The main worktree held unrelated user-owned untracked files, so all capture and audit actions used temporary detached worktrees. Each temporary worktree created for this plan was removed only after it was clean; no pre-existing worktree was touched.

## Next Phase Readiness

The native SVG evidence record is reproducible and audit-ready. Future observations must match the recorded workload/source/corpus/correctness digests, command, release target, toolchain, and host facts before being considered comparable.

## Self-Check: PASSED

- `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1` and `docs/benchmarks/mb-svg-native-release-baseline.md` exist.
- All listed task commits are present in repository history.
- The final temporary worktree `D:\source\moonbit-foundation-phase94-02-capture-14255e6` was removed after clean audit completion.
