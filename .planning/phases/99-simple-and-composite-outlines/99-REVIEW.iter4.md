---
phase: 99-simple-and-composite-outlines
reviewed: 2026-07-27T11:58:17Z
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

**Reviewed:** 2026-07-27T11:58:17Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The final auto re-review covered the original 14-file scope at commit
`4e8d12c5`. CR-01 through CR-03 still implement the required component-flag
rules, and WR-01's duplicate decoder remains removed. The latest CR-04 changes
correctly charge equal-`loca` and zero-contour root paths, both empty composite
child geometries, the discarded zero-contour child path, transformed storage,
and the final empty path. Their exact allocation counts of 9 and 10 match those
call paths.

One authoritative-budget gap remains outside those empty branches: composite
graph classification authorizes only one byte per glyph for an `Array[Int]`
state table. A caller can therefore set an `allocation_size` ceiling that
passes preflight but is smaller than the allocation the implementation
immediately performs.

All four package suites passed 91/91 on `native`, `js`, `wasm`, and `wasm-gc`.
The exact font foundation policy/interface gate also passed. Those gates do not
exercise a tight composite graph-state allocation-size ceiling.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Composite graph-state storage bypasses the allocation-size ceiling

**Classification:** BLOCKER
**File:** `D:/AI-Data/temp/Admin/mnf-phase99-exec/modules/mb-font/font/outline.mbt:1196-1210`
**Issue:** `font_classify_composite_graph` preflights the tri-color state table
with `allocation_size=index.num_glyphs`, then allocates
`Array[Int]::make(index.num_glyphs, 0)`. The charge therefore budgets one byte
per element even though each `Int` element requires multiple bytes. This is
inconsistent with the package's conservative portable allocation model (for
example, outline points, endpoints, descriptors, frames, and directory facts
all multiply element counts by an accounting size). With many glyphs and small
component/depth claims, this state table is the largest scratch allocation: an
`allocation_size` limit equal to `num_glyphs` passes, after which a materially
larger array is allocated. The caller's authoritative per-allocation ceiling is
therefore bypassed even though the allocation-count fixes are correct.

**Fix:**

```moonbit
let state_allocation_size = match
  @checked.checked_mul(index.num_glyphs, 8UL) {
  Err(_) => return Err(font_outline_data_error("font-outline-composite-state"))
  Ok(value) => value
}
match font_outline_charge_allocation(budget, state_allocation_size) {
  Err(error) => return Err(error)
  Ok(_) => ()
}
let states : Array[Int] = Array::make(index.num_glyphs.to_int(), 0)
```

Use a documented conservative portable slot size (or change the representation
to byte storage and keep a one-byte-per-glyph charge). Add an exact-fit and
one-byte-short `allocation_size` test with enough glyphs for the state table to
exceed the 80-byte descriptor and 64-byte frame plans; require the short case
to fail with `Resource` / `allocation_size` before `Array::make`.

---

_Reviewed: 2026-07-27T11:58:17Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
