---
phase: 92-fail-closed-svg-parsing
reviewed: 2026-07-25T18:02:11Z
depth: deep
files_reviewed: 14
files_reviewed_list:
  - modules/mb-svg/svg/bounds_wbtest.mbt
  - modules/mb-svg/svg/color.mbt
  - modules/mb-svg/svg/length.mbt
  - modules/mb-svg/svg/lower_wbtest.mbt
  - modules/mb-svg/svg/numeric_contract_wbtest.mbt
  - modules/mb-svg/svg/parse_wbtest.mbt
  - modules/mb-svg/svg/path_data.mbt
  - modules/mb-svg/svg/path_data_wbtest.mbt
  - modules/mb-svg/svg/scene.mbt
  - modules/mb-svg/svg/scene_wbtest.mbt
  - modules/mb-svg/svg/svg.mbt
  - modules/mb-svg/svg/svg_test.mbt
  - modules/mb-svg/svg/transform.mbt
  - modules/mb-svg/svg/transform_wbtest.mbt
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
verdict: blocked
---

# Phase 92: Release Code Review

**Reviewed:** 2026-07-25T18:02:11Z
**Depth:** deep
**Files Reviewed:** 14
**Verdict:** **BLOCKED**

## Summary

CR-01 through CR-10 are fixed. In particular, `3b98857` admits source size before SVG tokenization and applies balanced depth leases to nested non-empty `<svg>` elements; the corresponding bounds tests cover both repairs. Earlier fixes retain structured numeric errors, strict comma/hex handling, tangent-based skew, correct close-path state, and post-close scalar rejection.

`moon test modules/mb-svg/svg --target all --frozen` passes: 114/114 on wasm, wasm-gc, js, and native. The release remains blocked by two untested public-input paths: direct path parsing still bypasses the caller's byte budget, and a valid self-closing deferred SVG element is rejected.

## Narrative Findings (AI reviewer)

The review traced `parse_svg_with_budget` through tokenization, scene construction, paint/list/path/transform parsing, and derived-geometry preflight, and separately traced the public `parse_path_data_with_budget` entry point. No prior CR-01–CR-10 regression was found. The findings below are independent release blockers for the requested bounded-input and valid-SVG compatibility gates.

## Critical Issues

### CR-11: Public path parser allocates and scans before honoring the byte budget

**Classification:** BLOCKER
**File:** `modules/mb-svg/svg/path_data.mbt:17-18, 31-42, 327-337`
**Issue:** `parse_path_data_with_budget` creates `s.to_array()` before consulting `budget`; its only charge uses `bytes=0UL`. Thus a caller can provide a tiny byte budget and a very large `d` string, yet the parser allocates/scans the full character array before it can return a work or numeric error. The default path budget's 8 MiB `bytes` limit is likewise inert. This bypasses the public bounded-input contract for the standalone path API.

**Fix:** Before `s.to_array()`, reject a source whose code-unit count exceeds `budget.remaining().bytes()` (or introduce a shared budget-aware scanner that charges bytes while scanning). Add all-target tests showing an oversized direct `parse_path_data_with_budget` input fails before conversion, while a boundary-sized valid path succeeds.

### CR-12: Self-closing deferred elements are treated as unterminated subtrees

**Classification:** BLOCKER
**File:** `modules/mb-svg/svg/scene.mbt:955-999`
**Issue:** For an unsupported/deferred element, `build_element` calls `skip_element_body` even when `build_attrs` reported `is_empty=true`. Consequently valid SVG such as `<svg><defs/></svg>` (or `<metadata/>`, `<linearGradient/>`) consumes the following tokens while seeking a nonexistent `</defs>` and returns `missing </defs> while skipping`. This breaks valid SVG compatibility at the documented deferred-element boundary.

**Fix:** In the default/deferred branch, return `Ok(None)` immediately when `is_empty` is true; call `skip_element_body` only for non-empty elements. Add a regression for `<svg><defs/><rect .../></svg>` that asserts successful parsing and one retained drawable child, plus a self-closing deferred-only control.

---

_Reviewed: 2026-07-25T18:02:11Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
