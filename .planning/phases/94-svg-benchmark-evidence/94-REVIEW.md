---
phase: 94-svg-benchmark-evidence
reviewed: 2026-07-25T20:22:34Z
depth: deep
files_reviewed: 3
files_reviewed_list:
  - modules/mb-svg/svg/svg_bench.mbt
  - scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1
  - docs/benchmarks/mb-svg-native-release-baseline.md
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 94: Code Review Report

**Reviewed:** 2026-07-25T20:22:34Z
**Depth:** deep
**Files Reviewed:** 3
**Status:** issues_found

## Summary

The three correctness gates compile and run on all four targets, and the documented clean detached-worktree audit evidence was inspected rather than re-run from this dirty checkout. The evidence generator nevertheless has two integrity blockers: it permits a non-pinned toolchain and its audit does not validate much of the visible Markdown it claims to audit. Its process capture also needs robust stream handling and explicit UTF-8 decoding before a future baseline is trusted.

## Critical Issues

### CR-01: Read-only audit does not validate the human-visible evidence it certifies

**Classification:** BLOCKER

**File:** `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1:385`

**Issue:** `Invoke-ReadOnlyAudit` verifies the embedded JSON, decoded `<pre>` payloads, and visible aggregate rows only. It never verifies the visible comparison identity, workload/source-digest table, toolchain/host facts, per-run timestamps/status/output digest lines, or the per-run runner-summary tables rendered at lines 252-330. For example, changing the displayed Capture 1 path mean at `docs/benchmarks/mb-svg-native-release-baseline.md:793`, a displayed SHA-256 at line 26, or the stated native command at line 10 leaves every check in lines 385-425 unchanged and still reports a passed audit. The retained document can therefore make false provenance or timing claims while its advertised audit succeeds.

**Fix:** Parse each rendered field and compare it to the independently recomputed value (or to the verified JSON value for captured host/timestamp facts). Require exactly one ordered visible capture section per JSON run, validate each visible per-run summary row and digest, and validate all visible identity/provenance/toolchain/host fields before printing success.

### CR-02: Capture accepts a toolchain that violates the exact policy pin

**Classification:** BLOCKER

**File:** `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1:134`

**Issue:** The policy explicitly owns exact versions, commits, and release dates, but the capture gate checks only that each raw tool output contains `policy.toolchain.<tool>.version`. For `moon` and `moonrun`, a different commit/date with the same `0.1.20260713` version is accepted and recorded as valid native evidence. The `$expected` values assembled at lines 129-133 are only rendered; they are not enforced. This breaks the frozen toolchain identity required for comparable baselines.

**Fix:** Validate every policy-owned component against the observed version output before capture, including the Moon/Moonrun commit and release date and moonc release date. Fail the preflight on any missing or differing component; retain the raw output only after that exact check passes.

## Warnings

### WR-01: Sequential redirected-stream reads can deadlock a capture

**Classification:** WARNING

**File:** `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1:192`

**Issue:** The process reads `StandardOutput` to EOF before beginning to drain `StandardError`. If a future Moon invocation emits enough stderr while stdout remains open, the stderr pipe can fill, blocking the child; stdout never closes and `ReadToEnd()` hangs. Capture then fails to produce the required seven records.

**Fix:** Start asynchronous reads for both redirected streams (for example `ReadToEndAsync()` for each), wait for the process and both readers, then combine the completed strings deterministically.

### WR-02: The subprocess decoding is not explicitly UTF-8

**Classification:** WARNING

**File:** `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1:182`

**Issue:** The Markdown is written with an explicit no-BOM UTF-8 encoder, but `ProcessStartInfo` leaves `StandardOutputEncoding` and `StandardErrorEncoding` unset. Their decoding follows the host default rather than the declared evidence encoding. On a host whose default code page does not match Moon's UTF-8 output, units, ellipses, localized text, or diagnostics can be corrupted before their hashes and audit data are made, yielding a self-consistent but inaccurate "complete normalized UTF-8" record.

**Fix:** Before `Start()`, set both `StandardOutputEncoding` and `StandardErrorEncoding` to `$utf8` (and document Moon output as UTF-8), then hash/render the resulting normalized text.

---

_Reviewed: 2026-07-25T20:22:34Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
