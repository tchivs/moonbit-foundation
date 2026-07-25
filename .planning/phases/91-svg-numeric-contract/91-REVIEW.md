---
phase: 91-svg-numeric-contract
reviewed: 2026-07-25T15:54:06Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - docs/policies/svg-numeric-admission.md
  - modules/mb-svg/svg/numeric_contract_wbtest.mbt
  - modules/mb-svg/svg/parse_wbtest.mbt
  - modules/mb-svg/svg/scene_wbtest.mbt
  - modules/mb-svg/svg/path_data_wbtest.mbt
  - modules/mb-svg/svg/transform_wbtest.mbt
  - modules/mb-svg/svg/lower_wbtest.mbt
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 91: Code Review Report

**Reviewed:** 2026-07-25T15:54:06Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

The phase is limited to documentation and tests, and all 90 package tests pass on
`wasm`, `wasm-gc`, `js`, and `native`. However, the new route evidence misses an
unsafe transform-to-geometry path and marks an incorrectly parsed smooth cubic as
covered. Two further tests either miss the stated derived boundary or preserve an
incorrect SVG skew result.

## Critical Issues

### CR-01: Transform application to geometry is absent from the numeric contract

**Classification:** BLOCKER

**File:** `D:/source/moonbit-foundation/docs/policies/svg-numeric-admission.md:64-71`

**Issue:** The route matrix validates transform parameters and six affine
coefficients, but it has no route for applying the accumulated transform to shape
coordinates. An SVG such as `transform="scale(65536)"` around a shape at
`x="65536"` passes every listed source and affine admission check while producing
`4294967296` when the transform is applied. That is a derived SVG coordinate outside
the published envelope and reaches the canvas transform stack. This contradicts the
claim that every derived scalar is admitted before a usable scene is returned.

**Fix:** Add an `SVG-NUM-TRANSFORMED-GEOMETRY` route. Phase 92 must validate all
geometry under the accumulated affine (including transform stacks) before returning
the scene, with a rejection test for the example above. If transformed geometry is
intentionally owned by another layer, narrow the policy explicitly instead of
claiming complete derived-scalar admission.

### CR-02: The smooth-cubic path route is falsely reported as covered

**Classification:** BLOCKER

**File:** `D:/source/moonbit-foundation/modules/mb-svg/svg/path_data_wbtest.mbt:75-89`

**Issue:** The test claims every path command family is covered but only checks the
command count. In the exercised `S 11 12 13 14`, the current parser reads six
numbers for `S` rather than its required four, discards `11` and `12`, then treats
the following `T` command as two missing numbers (which become zero). The command
count still reaches `10`, so this test passes while accepting incorrect geometry and
not proving admission for all smooth-cubic scalar arguments.

**Fix:** In the Phase 92 parser migration, make `S/s` consume exactly
`cp2x cp2y x y` and propagate missing/malformed reads as errors. Replace the
count-only assertion with assertions on the emitted cubic's reflected control,
second control, and endpoint; retain a separate route assertion for each consumed
source scalar.

## Warnings

### WR-01: Relative-coordinate test does not reach the claimed inclusive boundary

**Classification:** WARNING

**File:** `D:/source/moonbit-foundation/modules/mb-svg/svg/path_data_wbtest.mbt:81-87`

**Issue:** The comment says relative arithmetic reaches the inclusive boundary, but
`-65536 + 1` is `-65535`. The test covers only an interior value, leaving the
derived-boundary condition untested.

**Fix:** Use a boundary-producing operation, for example
`m 65535 65535 l 1 1`, and assert `(65536, 65536)`.

### WR-02: Numeric test locks an incorrect SVG skew result

**Classification:** WARNING

**File:** `D:/source/moonbit-foundation/modules/mb-svg/svg/transform_wbtest.mbt:177-188`

**Issue:** The new controls expect `skewX(45)`/`skewY(45)` to shear by the radian
angle `pi/4` (`0.785398...`). SVG skew uses `tan(angle)`, so a 45-degree skew must
shear by `1.0`. The test makes the existing incorrect parser behavior a required
contract and will obstruct a standards-correct fix.

**Fix:** Keep this phase parser-neutral by asserting that the resulting affine
components are finite and in range, without encoding the current erroneous value.
Add or retain a standards test elsewhere that expects `tan(45 degrees) == 1.0`; fix
the transform implementation when its semantic correction is scheduled.

---

_Reviewed: 2026-07-25T15:54:06Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
