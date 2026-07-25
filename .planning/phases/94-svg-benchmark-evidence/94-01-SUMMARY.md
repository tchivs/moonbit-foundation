---
phase: 94-svg-benchmark-evidence
plan: 01
subsystem: svg-benchmarking
tags: [moonbit, svg, benchmark, portability]
requires: [93-svg-compatibility-portable-qualification]
provides: [correctness-gated-svg-workloads, four-target-runnable-qualification]
affects: [94-02-native-baseline-evidence]
tech-stack:
  added: [moonbitlang/core/bench]
  patterns: [pre-timing semantic gates, deterministic local corpora, b.keep benchmark sinks]
key-files:
  created: [modules/mb-svg/svg/svg_bench.mbt]
  modified: [modules/mb-svg/svg/moon.pkg]
decisions:
  - "Three fixed SVG workloads validate their semantic result before timing."
  - "All-target benchmark output is used only as runnable qualification, never as cross-target timing evidence."
metrics:
  duration: "~8 minutes"
  completed: "2026-07-26"
status: complete
---

# Phase 94 Plan 01: Correctness-Gated SVG Workloads Summary

Three deterministic SVG workloads now reject incorrect parser, transform, or lowering results before their measured closure runs on any target.

## Completed Tasks

1. **Prove the path-parse workload end to end before measuring it** — `16a44c2`
   - Added the explicit `moonbitlang/core/bench` package import.
   - Added a deterministic 1,000-line corpus and command-count/first/last semantic gate for `path-parse/1000-line-to`.
2. **Complete the fixed transform and parse-to-lower workload contracts** — `7814a7f`
   - Added exact 50-function transform and 50-rect document builders.
   - Added frozen affine/probe and drawing-list-shape gates for the remaining named workloads.
   - Retained the corpus and correctness SHA-256 identities for Plan 94-02's native evidence record.

## Verification

- `moon bench modules/mb-svg/svg --target all --frozen` — passed all three workloads on wasm, wasm-gc, js, and native.
- `moon test modules/mb-svg/svg --target all --frozen` — passed 125/125 tests on each of wasm, wasm-gc, js, and native.
- Recomputed the no-BOM/no-trailing-newline UTF-8 digests for the three corpus literals and transform correctness text; all match the frozen plan values.
- `git diff --check` — passed.

## Decisions Made

- The only workload names are `path-parse/1000-line-to`, `transform-composition/50-segment`, and `parse-to-lower/50-rect`.
- The four-target benchmark command is a pass/fail runnable qualification; no target timing data is retained or compared.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Use the public CanvasPath read API in the path gate**
   - **Found during:** Task 1
   - **Issue:** `CanvasPath` has no `commands()` method and `Point2` does not implement equality.
   - **Fix:** Read the parsed commands through `to_path2()` and compare the required coordinate components directly.
   - **Files modified:** `modules/mb-svg/svg/svg_bench.mbt`
   - **Verification:** Four-target benchmark qualification passed.
   - **Commit:** `16a44c2`

2. **[Rule 1 - Bug] Align the affine envelope guard with the available numeric API**
   - **Found during:** Task 2
   - **Issue:** `Double.is_finite()` and a shared `SVG_NUMERIC_LIMIT` identifier are unavailable in this package.
   - **Fix:** Use the established `!is_nan() && !is_inf() && abs() <= 65536.0` admission contract.
   - **Files modified:** `modules/mb-svg/svg/svg_bench.mbt`
   - **Verification:** Four-target benchmark and regression commands passed.
   - **Commit:** `7814a7f`

3. **[Rule 3 - Blocking issue] Repair the stale execution position after the state handler rejected it**
   - **Found during:** Plan close-out
   - **Issue:** `state.advance-plan` could not parse the pre-existing `Plan: Not started` position, despite this plan's completed summary.
   - **Fix:** Updated the current focus and position to Phase 94 Plan 2 of 2 while preserving the remaining plan as the resume target.
   - **Files modified:** `.planning/STATE.md`
   - **Verification:** `state.update-progress` reports 7/8 completed plans and the roadmap reports 94-01 complete, 94-02 pending.

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocking issue).

## Known Stubs

None.

## Self-Check: PASSED

- Required source and manifest files exist.
- Both task commits are present in the repository history.
