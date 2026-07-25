---
phase: 92-fail-closed-svg-parsing
reviewed: 2026-07-25T17:30:58Z
depth: deep
files_reviewed: 12
files_reviewed_list:
  - modules/mb-svg/svg/color.mbt
  - modules/mb-svg/svg/length.mbt
  - modules/mb-svg/svg/lower_wbtest.mbt
  - modules/mb-svg/svg/numeric_contract_wbtest.mbt
  - modules/mb-svg/svg/path_data.mbt
  - modules/mb-svg/svg/path_data_wbtest.mbt
  - modules/mb-svg/svg/scene.mbt
  - modules/mb-svg/svg/scene_wbtest.mbt
  - modules/mb-svg/svg/svg.mbt
  - modules/mb-svg/svg/svg_test.mbt
  - modules/mb-svg/svg/transform.mbt
  - modules/mb-svg/svg/transform_wbtest.mbt
findings:
  critical: 5
  warning: 0
  info: 0
  total: 5
status: issues_found
verdict: blocked
---

# Phase 92: Code Review Report

**Reviewed:** 2026-07-25T17:30:58Z  
**Depth:** deep  
**Files Reviewed:** 12  
**Status:** issues_found — **BLOCKED**

## Summary

The review traced public `parse_svg` through paint construction, transform creation, path normalization, parser-side preflight, and the unchanged total lowerer. The all-target suite currently passes, but it does not cover malformed functional-color syntax, SVG skew semantics, or several valid path-data grammar/state cases. These defects either let malformed explicit numeric input fall back to a scene or change valid SVG geometry, so SVGPR-02 cannot ship as fail-closed and compatibility-preserving.

## Critical Issues

### CR-01: Malformed functional colors silently fall back to paint defaults

**Classification:** BLOCKER  
**File:** `modules/mb-svg/svg/color.mbt:114` (propagated through `modules/mb-svg/svg/scene.mbt:1230`)  
**Issue:** `rgb(1,2)` / `hsl(1,2%)` returns the generic `svg-color` error when fewer than three components are present. `build_paint` only propagates errors whose context is one of the numeric contexts, so it converts this explicit malformed supported numeric form into the old fill fallback (black), stroke fallback (`none`), or inherited `color`, and `parse_svg` returns `Ok(SceneNode)`. This violates the explicit-malformed/no-scene contract.

**Fix:** Classify malformed functional syntax and arity as `svg-numeric-source` (or propagate all errors from recognized `rgb`/`rgba`/`hsl`/`hsla` forms). Add public cases for `fill="rgb(1,2)"`, `stroke="hsl(1,2%)"`, and `color="rgb(1,2)"` that assert `Err(InvalidEncoding, svg-numeric-source)`.

### CR-02: Percent parser accepts malformed numeric spellings

**Classification:** BLOCKER  
**File:** `modules/mb-svg/svg/color.mbt:165`  
**Issue:** `replace(old="%", new="")` removes every percent sign instead of validating one trailing suffix. Thus `rgb(0,1%%,0)` is normalized to `1` and accepted; `rgb(0,1%2,0)` becomes `12` and is also accepted. Both are explicit malformed numeric scalars that must fail before scene publication.

**Fix:** Require exactly one final `%`, remove only that suffix, and reject any remaining `%` or non-numeric characters through `svg-numeric-source`. Add all-target tests for duplicate, embedded, and missing percent suffixes.

### CR-03: `skewX`/`skewY` use radians as shear coefficients instead of tangent

**Classification:** BLOCKER  
**File:** `modules/mb-svg/svg/transform.mbt:151`  
**Issue:** The code passes radians directly to `Affine2::skew`, but that constructor stores its arguments as the raw matrix coefficients (`c=shx`, `b=shy`) in `modules/mb-core/math/affine.mbt:242-245`; it does not calculate a tangent. Consequently `skewX(45)` produces `c≈0.785` rather than the SVG-required `tan(45°)=1`. It also accepts `skewX(90)` with a finite coefficient instead of rejecting the out-of-envelope trigonometric result.

**Fix:** Compute `tan(degrees_to_radians(angle))`, admit that derived result, then pass it to `Affine2::skew`. Cover the 45-degree matrix coefficient and a 90-degree `svg-numeric-derived` rejection on every target.

### CR-04: Closing a path does not restore the current point to the subpath start

**Classification:** BLOCKER  
**File:** `modules/mb-svg/svg/path_data.mbt:215`  
**Issue:** `Z/z` only appends `close_path`; it leaves `cur_x`/`cur_y` at the previous endpoint. In valid input such as `M 0 0 L 10 0 Z l 5 0`, the relative line must start at `(0,0)` and end at `(5,0)`, but this parser starts at `(10,0)` and emits `(15,0)`. This also corrupts newly normalized smooth commands following a close.

**Fix:** Track the active subpath start whenever `M/m` is processed, set the current point back to it on `Z/z`, and clear reflection state. Add absolute command-coordinate assertions for a relative line and smooth command immediately after `Z`.

### CR-05: Path scanner rejects valid sign-separated SVG numbers

**Classification:** BLOCKER  
**File:** `modules/mb-svg/svg/path_data.mbt:272`  
**Issue:** The scanner only stops on whitespace, commas, or command letters. It therefore collects `0-10` as one token and rejects valid compact SVG path data such as `M0-10` or `L5-3`. SVG path-number grammar permits a sign to start the next number without a comma or whitespace. The Phase 92 rewrite retains this incompatibility while claiming normalized path support.

**Fix:** Treat `+`/`-` as a new token boundary unless it is the first character or immediately follows `e`/`E`. Add controls for compact signed coordinates and scientific notation (`M1e-3-2`) so the delimiter rule does not break exponents.

---

_Reviewed: 2026-07-25T17:30:58Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: deep_
