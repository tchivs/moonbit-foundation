---
phase: 92-fail-closed-svg-parsing
reviewed: 2026-07-25T17:52:07Z
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
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
verdict: blocked
---

# Phase 92: Final Code Re-Review Report

**Reviewed:** 2026-07-25T17:52:07Z
**Depth:** deep
**Files Reviewed:** 13
**Status:** issues_found — **BLOCKED**

## Summary

CR-01 through CR-08 are fixed in `5c6e093` through `78485a6`: malformed functional and hexadecimal paints now retain the numeric error identity; percent and comma grammar reject malformed input; skew uses tangent; close-path state and compact signed paths are correct; and scalars after `Z/z` fail immediately instead of consuming the command budget. The full SVG package suite passes on wasm, wasm-gc, js, and native (111 tests per target).

SVGPR-02 is nevertheless blocked. The parser's documented resource boundary can be bypassed by nested supported `<svg>` elements, and its caller-provided budget is not applied until after unbounded markup tokenization and allocation. Both defects permit untrusted input to consume stack or heap outside the advertised limits.

## Narrative Findings (AI reviewer)

The re-review traced every Phase 92 ingress (`parse_svg` → scene builder → paint/list/path/transform parsers → preflight) and checked the repaired CR-01..CR-08 cases. It also traced the budget call chain into the markup tokenizer and compared nesting handling for `g` and nested `svg` structural nodes. No remaining malformed numeric route that was previously reported returns a scene; the remaining blockers are parser-resource defects.

## Critical Issues

### CR-09: Nested supported `<svg>` elements bypass the depth budget

**Classification:** BLOCKER
**File:** `modules/mb-svg/svg/scene.mbt:896-901, 1004-1015`
**Issue:** `build_element` recursively dispatches every nested `<svg>` to `build_svg_root`, but `build_svg_root` never acquires a `Budget::enter_depth()` lease. Only `build_group` does. Thus `parse_svg_with_budget(source, budget)` accepts arbitrarily deep nested `<svg>` trees under a budget with a tiny depth ceiling, until recursion exhausts the runtime stack; `preflight_scene` then recurses through the same unbounded tree. This contradicts the public bounded-input contract and makes hostile input a denial-of-service path.
**Fix:** Apply the same depth lease around non-empty nested `<svg>` child construction as `build_group` uses, releasing it on every return path. Add a tight-budget regression such as five nested `<svg>` elements under `depth=3` and assert a structured `svg-budget` error; retain a shallow nested-`svg` success control.

### CR-10: The resource budget is applied only after unbounded markup tokenization

**Classification:** BLOCKER
**File:** `modules/mb-svg/svg/scene.mbt:175-182` (called parser: `modules/mb-core/text/xml_tokenize.mbt:53-82`)
**Issue:** `parse_svg_with_budget` passes the entire untrusted source to `tokenize_markup` before charging any part of the supplied budget. The tokenizer scans the complete string and constructs an unbounded `Array[MarkupToken]`; `build_attrs`/`build_children` charge work only after that array already exists. Consequently a caller's byte, allocation, and work ceilings do not prevent tokenization-time memory or CPU consumption (for example, a document containing far more tokens than the work limit still allocates all of them before returning `svg-budget`). This violates the documented fail-closed resource boundary for untrusted SVG.
**Fix:** Introduce a budget-aware tokenizer (preferred) that charges source bytes and each emitted token/allocation while scanning, or reserve/check the input byte budget before tokenization and enforce a bounded token count during lexing. Add a tight-budget test with an oversized many-tag document that asserts failure before a full token array is materialized.

---

_Reviewed: 2026-07-25T17:52:07Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
