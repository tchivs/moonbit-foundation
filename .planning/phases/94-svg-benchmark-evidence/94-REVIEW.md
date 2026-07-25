---
phase: 94-svg-benchmark-evidence
reviewed: 2026-07-25T20:43:06Z
depth: deep
files_reviewed: 3
files_reviewed_list:
  - modules/mb-svg/svg/svg_bench.mbt
  - scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1
  - docs/benchmarks/mb-svg-native-release-baseline.md
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 94: Code Review Report

**Reviewed:** 2026-07-25T20:43:06Z
**Depth:** deep
**Files Reviewed:** 3
**Status:** issues_found

## Summary

The prior CR-01, CR-02, WR-01, and WR-02 remediations are present: the audit canonically verifies all rendered Markdown, policy-owned toolchain fields are enforced, capture reads both redirected UTF-8 streams asynchronously, and the code parses under both Windows PowerShell 5.1 and pwsh. However, the committed evidence is not a canonical rendering of its embedded audit data. In a disposable clean detached worktree at `5bdd5cf`, `-Audit` fails identically under both hosts, so the baseline cannot currently be certified.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Committed baseline fails its own read-only audit after LF normalization

**Classification:** BLOCKER

**File:** `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1:85, 328, 435-442`

**Issue:** `Get-ToolOutput` retains CRLF in multi-line tool output, which is embedded both in the visible Markdown and as escaped `\r\n` in the audit JSON. The repository enforces LF for this Markdown file. Consequently, the visible `moon observed` block is LF-only while `ConvertFrom-Json` reconstructs CRLF from the JSON; `New-BaselineDocument` re-renders CRLF and `Assert-VisibleDocumentMatchesData` throws. A clean detached checkout at `5bdd5cf` produced this failure under both `powershell.exe` 5.1 and `pwsh`, despite an empty `git status --porcelain=v1 --untracked-files=all`.

**Fix:** Normalize line endings of every retained text fact before both rendering and serialization, using a dedicated helper that converts CRLF/CR to LF without changing intentional terminal-newline semantics. Apply it in `Get-ToolOutput` (and any other captured multi-line host/tool fact), regenerate the baseline from a clean worktree, then require `-Audit` to pass under both supported PowerShell hosts.

```powershell
function Normalize-RecordedText([string]$Text) {
  $Text.Replace("`r`n", "`n").Replace("`r", "`n")
}

# Keep the JSON and visible Markdown on the same LF representation.
$output = Normalize-RecordedText ((& $Command @Arguments 2>&1 | Out-String).TrimEnd("`r", "`n"))
```

---

_Reviewed: 2026-07-25T20:43:06Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
