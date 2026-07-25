---
phase: 94-svg-benchmark-evidence
verified: 2026-07-25T20:58:32Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 94: SVG Benchmark Evidence Verification Report

**Phase Goal:** Maintainers can reproduce correctness-gated SVG workload measurements and compare a documented native-release baseline responsibly.
**Verified:** 2026-07-25T20:58:32Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Maintainers can run the fixed path-parse, transform-composition, and parse-to-lower workloads only after each validates its command, affine, or drawing-operation facts. | ✓ VERIFIED | `svg_bench.mbt` contains exactly three `test "bench ..."` workloads and three timed `b.bench` closures. The path gate checks 1,001 commands and first/last coordinates before timing; the transform gate checks finite/bounded affine components plus the frozen 1e-9 oracle; the lower gate checks 50 `Fill` operations before timing. Detached `moon bench modules/mb-svg/svg --target all --frozen` executed all three successfully. |
| 2 | The benchmark workloads build and run on `js`, `wasm`, `wasm-gc`, and `native` without cross-target performance comparison. | ✓ VERIFIED | The detached all-target benchmark invocation passed 3/3 on `wasm`, `wasm-gc`, `js`, and `native`. The baseline retains only target labels in its functional-qualification section, no timing digits there, and explicitly excludes cross-target comparisons. |
| 3 | A native release baseline records the exact command, corpus/correctness/source digests, toolchain and host facts, one warmup, seven captures, and native-host summary statistics. | ✓ VERIFIED | The Markdown record contains the literal frozen native command, policy/observed toolchain and host facts, three corpus + correctness digest pairs, two source + combined-source digests, one excluded warmup, seven retained captures, eight output digests, and mean/median/sample-SD/min/max/CV. Both audit engines recomputed and accepted all of these facts. |
| 4 | The baseline audit is read-only, requires a clean worktree, and independently validates the generated record rather than trusting it. | ✓ VERIFIED | `Invoke-ReadOnlyAudit` first calls `Assert-CleanWorktree`, reads the Markdown/current fixed inputs, recomputes source/corpus/correctness/output digests, reparses summaries, and recomputes seven-sample aggregates. On a fresh detached clean checkout, both `powershell.exe` and `pwsh` audits passed and `git status --porcelain=v1 --untracked-files=all` remained empty afterward. |
| 5 | Future comparison is limited to like-for-like native records; the phase introduces no threshold, CI gate, ranking, regression decision, or cross-target timing claim. | ✓ VERIFIED | The script fixes the native-release command and writes an explicit exact-identity comparison rule. Static inspection found no decision mechanism or CI workflow in the phase changes; the only threshold/ranking/CI/cross-target mentions are explicit prohibitions in the script and generated record. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-svg/svg/svg_bench.mbt` | Three deterministic correctness-gated SVG benchmarks | ✓ VERIFIED | 142 substantive lines; exactly the three required workload names, local deterministic corpus builders, public SVG API gates before closures, and `b.keep` sinks. Execution proved all three gates run. |
| `modules/mb-svg/svg/moon.pkg` | Explicit MoonBit benchmark import | ✓ VERIFIED | Imports `moonbitlang/core/bench` as `@bench`; the executable benchmark source uses `@bench.T`. |
| `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1` | Fixed-command native capture and read-only audit | ✓ VERIFIED | 569 substantive lines; one literal native command, clean-tree guard, SHA-256 implementation compatible with both PowerShell engines, capture/render path, and separate non-writing audit branch. |
| `docs/benchmarks/mb-svg-native-release-baseline.md` | Actual native-release evidence | ✓ VERIFIED | Canonical no-BOM/LF record with one warmup, captures 1–7, raw-output digest/provenance, and derived aggregates. Both engines validated its rendered and embedded evidence. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `svg_bench.mbt` | `path_data.mbt` | pre-timing plus timed `parse_path_data` | ✓ WIRED | Source calls `parse_path_data` for the guard and timed closure; all-target execution passed. |
| `svg_bench.mbt` | `transform.mbt` | pre-timing plus timed `parse_transform` | ✓ WIRED | Source calls `parse_transform` for its affine/probe guard and closure; all-target execution passed. |
| `svg_bench.mbt` | `lower.mbt` | guarded and timed `parse_svg` → `lower_to_drawing_list` | ✓ WIRED | Source validates the real drawing list before timing and invokes the same parse/lower path in the closure; all-target execution passed. |
| baseline script | benchmark source/package | source digest and frozen workload records | ✓ WIRED | Manual verification: script reads `modules\\mb-svg\\svg\\svg_bench.mbt` and `moon.pkg` at lines 489–491 and 534–535, and rejects digest mismatch. (The generic key-link probe missed this because its plan pattern expects forward-slash spelling.) |
| baseline script | baseline Markdown | capture rendering and audit reread | ✓ WIRED | Script resolves the Markdown path, writes it only in capture mode, and reads/revalidates it in `-Audit`; both real audits passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `svg_bench.mbt` | path/affine/drawing-list values | deterministic corpus → public parser/lower APIs | Actual parsed and lowered results, exercised on four targets | ✓ FLOWING |
| baseline script | provenance, runs, aggregates | current source/policy/tool commands and eight retained runner outputs | Capture path constructs the record; audit independently reconstructs it from the Markdown | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Four-target correctness-gated workloads | `moon bench modules/mb-svg/svg --target all --frozen` | Each exact workload passed; 3/3 on wasm, wasm-gc, js, and native. Timing output intentionally not retained here. | ✓ PASS |
| Existing SVG portable regression baseline | `moon test modules/mb-svg/svg --target all --frozen` | 125/125 passed on each of wasm, wasm-gc, js, and native. | ✓ PASS |
| Windows PowerShell audit | `powershell.exe -NoProfile -File scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1 -Audit` | Exit 0; independently verified clean state, provenance, eight output digests, summaries, and aggregates. | ✓ PASS |
| PowerShell 7 audit | `pwsh -NoProfile -File scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1 -Audit` | Exit 0 with the same independent verification; detached checkout remained clean. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SVGPR-04 | 94-01, 94-02 | Three accurately named correctness-gated workloads and a responsible native baseline without cross-target comparison. | ✓ SATISFIED | Code gates, four-target execution, native-only evidence record, and dual-engine clean-tree audit above. |

No Phase 94 requirement is orphaned: both plans declare SVGPR-04 and `REQUIREMENTS.md` maps it only to this phase.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, empty implementation, hardcoded empty rendered data, or unresolved stub found in phase artifacts. | ℹ️ None | No blocker. |

The words “threshold”, “CI”, “ranking”, and “cross-target” occur only to prohibit those policies/claims; inspection found no threshold or ranking decision logic and no Phase 94 CI workflow.

### Human Verification Required

None. The behavior-dependent workload and audit claims were exercised by named commands in a clean detached checkout.

### Gaps Summary

No gaps found. The submitted summaries were not used as proof: this verdict is based on the current implementation, all-target benchmark/regression execution, and a fresh detached-checkout audit under both supported PowerShell engines.

---

_Verified: 2026-07-25T20:58:32Z_
_Verifier: the agent (gsd-verifier)_
