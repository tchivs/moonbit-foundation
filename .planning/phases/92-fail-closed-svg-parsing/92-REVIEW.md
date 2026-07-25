---
phase: 92-fail-closed-svg-parsing
reviewed: 2026-07-25T17:40:54Z
depth: deep
files_reviewed: 13
files_reviewed_list:
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
  critical: 3
  warning: 0
  info: 0
  total: 3
status: issues_found
verdict: blocked
---

# Phase 92: Code Re-Review Report

**Reviewed:** 2026-07-25T17:40:54Z
**Depth:** deep
**Files Reviewed:** 13
**Status:** issues_found — **BLOCKED**

## Summary

The fixes in `5c6e093`, `376ca7c`, and `c45650c` resolve every previously reported blocker: malformed functional colors and percent spellings now produce `svg-numeric-source`; SVG skew uses tangent coefficients and rejects unsafe results; and path close restores the subpath point while compact signed numbers scan correctly.

The all-target package suite passes (`107` tests on wasm, wasm-gc, js, and native), but SVGPR-02 remains blocked. Three malformed explicit-input routes still produce a usable scene or consume the full parser budget instead of failing immediately with the required `svg-numeric-source` error.

## Narrative Findings (AI reviewer)

The review traced `parse_svg` through color/paint fallback, shared numeric-list parsing, path scanning, transform construction, and parser-side preflight. The prior five findings are resolved, but the remaining issues violate the phase's explicit malformed-input/no-scene contract.

## Critical Issues

### CR-06: Malformed hexadecimal colors are converted to a usable fallback paint

**Classification:** BLOCKER
**File:** `modules/mb-svg/svg/color.mbt:49-78`, propagated through `modules/mb-svg/svg/scene.mbt:1212-1255`
**Issue:** `parse_color` recognizes every value beginning with `#`, but `parse_hex_color` returns the generic `svg-color` error for an invalid length (for example, `#12`) and `hex_digit` converts every non-hex character to zero (for example, `#ggg` becomes black). `build_paint` only propagates numeric-context errors, so malformed explicit `color`, `fill`, or `stroke` values either silently become black/none/inherited or decode as black. This violates the required fail-closed behavior before a `SceneNode` exists.
**Fix:** Make `hex_digit` return `Result[Int, CoreError]` and return `svg-numeric-source` for invalid digits and invalid supported hex lengths. Alternatively, propagate all errors from values recognized as hexadecimal paint. Add public rejection tests for `fill="#ggg"`, `stroke="#12"`, and `color="#12"`.

### CR-07: Duplicate or leading commas are discarded instead of rejected as malformed numeric source

**Classification:** BLOCKER
**File:** `modules/mb-svg/svg/length.mbt:59-70` and `modules/mb-svg/svg/path_data.mbt:272-275`
**Issue:** Both scanners discard separators without recording whether a number was required. Consequently malformed values such as `viewBox="0,,0,1,1"`, `transform="translate(1,,2)"`, `stroke-dasharray="1,,2"`, and `d="M0,,0"` are normalized into valid numbers and `parse_svg` returns `Ok(SceneNode)`. These are explicitly present malformed numeric lists, which the Phase 92 contract requires to return `Data/InvalidEncoding/svg/svg-numeric-source` rather than construct a scene.
**Fix:** Track separator state in `parse_number_list` and `read_number`: permit only the SVG grammar's valid comma/whitespace form, reject a leading comma, a second comma before a scalar, and a trailing required-separator comma with `svg-numeric-source`. Add public fixtures for every shared-list route and path-data route above.

### CR-08: A numeric token after `Z/z` repeatedly appends close commands until budget exhaustion

**Classification:** BLOCKER
**File:** `modules/mb-svg/svg/path_data.mbt:219-226`
**Issue:** After `Z/z`, the parser leaves `last_cmd` as `Z` and does not consume any following non-letter input. For malformed path data such as `M0 0 Z 1 1`, the next loop sees the same `1`, repeatedly executes `close_path`, and only fails after exhausting the supplied work budget. Through `parse_svg` this can append up to the default two million close commands, turning a malformed scalar sequence into avoidable allocation/work and returning `svg-budget` rather than the required immediate `svg-numeric-source` error.
**Fix:** After handling close, clear `last_cmd` (for example, set it to `' '`). A subsequent explicit `Z` still works because it resets the command letter; a following scalar then reaches the default source-error branch. Add tests for `M0 0 Z 1 1` and `M0 0 Z,1` that assert an immediate numeric-source error and no scene.

---

_Reviewed: 2026-07-25T17:40:54Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
