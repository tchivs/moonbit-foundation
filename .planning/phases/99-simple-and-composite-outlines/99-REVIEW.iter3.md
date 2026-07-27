---
phase: 99-simple-and-composite-outlines
reviewed: 2026-07-27T11:44:17Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - README.md
  - modules/mb-font/CHANGELOG.md
  - modules/mb-font/README.mbt.md
  - modules/mb-font/font/font.mbt
  - modules/mb-font/font/font_test.mbt
  - modules/mb-font/font/font_wbtest.mbt
  - modules/mb-font/font/generated_fonts_wbtest.mbt
  - modules/mb-font/font/limits.mbt
  - modules/mb-font/font/metrics.mbt
  - modules/mb-font/font/moon.pkg
  - modules/mb-font/font/outline.mbt
  - modules/mb-font/font/tables.mbt
  - policy/foundation.json
  - scripts/quality/Assert-Policy.ps1
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 99: Code Review Report

**Reviewed:** 2026-07-27T11:44:17Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The iteration-two fixes were reviewed across the original 14-file scope. CR-01, CR-02, and CR-03 now implement the OpenType 1.9.1 component-flag rules, and WR-01's duplicate decoder has been removed. The non-empty simple and composite paths added by the CR-04 fix now charge their principal scratch arrays, but the fix is incomplete: empty outlines and empty composite components still create arrays without preflighting or charging the caller's authoritative allocation budget.

The exact font policy gate passes, and all 90 font tests pass on `wasm`, `wasm-gc`, `js`, and `native`. Existing empty-outline tests use generous budgets, so those green checks do not exercise the remaining allocation bypass.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Empty outlines still bypass the authoritative allocation-count budget

**Classification:** BLOCKER
**File:** `D:/AI-Data/temp/Admin/mnf-phase99-exec/modules/mb-font/font/outline.mbt:825-870,1370-1393,1583-1586`
**Issue:** Equal-`loca` glyphs and valid zero-contour glyphs return `Path2::new()` without calling `font_outline_charge_allocation`. `Path2::new()` owns a `commands: []` array, and the foundation budget contract counts even zero-byte allocations (for example, zero-length owned storage is charged as one allocation with size zero). A caller with `allocations=0` can therefore receive an allocated empty path successfully, contradicting the documented rule that scratch/output allocations are preflighted and charged. The composite path has the same gap: an empty component constructs `OutlineGeometry` with two fresh empty arrays, while a zero-contour component additionally creates and discards an uncharged empty `Path2`; none of these allocations are included in the composite exact-fit count. A font containing empty components can consequently exceed the caller-authorized allocation count while decoding succeeds.

**Fix:**

```moonbit
fn font_outline_empty_path(
  budget : @budget.Budget,
) -> Result[@math.Path2, @error.CoreError] {
  match font_outline_charge_allocation(budget, 0UL) {
    Err(error) => return Err(error)
    Ok(_) => Ok(@math.Path2::new())
  }
}
```

Use this helper for equal-`loca` and top-level zero-contour results. Split zero-contour validation from path construction so composite children do not allocate a path that is discarded, and skip empty children directly instead of materializing `{ points: [], endpoints: [] }` (or explicitly precharge both arrays if they remain). Add zero-allocation and exact-fit/one-short tests for equal-`loca`, zero-contour, and composites containing empty components.

---

_Reviewed: 2026-07-27T11:44:17Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
