---
phase: 105-bounded-type-2-validation-and-retained-metrics
fixed_at: 2026-07-29T01:25:39+08:00
review_path: .planning/phases/105-bounded-type-2-validation-and-retained-metrics/105-REVIEW-RECHECK.md
iteration: 2
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 105: Code Review Fix Report

**Fixed at:** 2026-07-29T01:25:39+08:00  
**Source review:** `.planning/phases/105-bounded-type-2-validation-and-retained-metrics/105-REVIEW-RECHECK.md`  
**Iteration:** 2

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### BL-R1: The admitted depth-10 frame stack can reallocate past its four charged scratch allocations

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/limits.mbt`, `modules/mb-font/font/cff_type2.mbt`, `modules/mb-font/font/cff_type2_fixture_wbtest.mbt`, `modules/mb-font/font/cff_type2_fixed_wbtest.mbt`  
**RED commit:** `833cb412`  
**GREEN commit:** `bb4afbf3`  
**Applied fix:** Kept the public Type 2 subroutine-depth ceiling at 10 while deriving the actual root-plus-subroutine frame capacity as 11 with checked addition and checked UInt64-to-Int narrowing. The VM now allocates all 11 slots up front, and scratch allocation size is recomputed as the maximum of operand and frame backing-store sizes.

The regression constructs a non-tail chain that reaches legal depth 10, verifies ten calls and ten returns, directly verifies the preallocated capacity is exactly 11, and confirms the depth-11 twin still fails with `font-cff-type2-frame-depth`.

### MJ-R1: Opposite-signed rational cross-products still overflow before they cancel

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_type2_fixed.mbt`, `modules/mb-font/font/cff_type2_fixed_wbtest.mbt`  
**RED commit:** `a9ce360b`  
**GREEN commit:** `0fba7f1e`  
**Applied fix:** Rational addition now forms signed cross-products in an allocation-free two-word unsigned intermediate, performs exact sign-aware addition or subtraction, computes cancellation against the shared denominator from the wide remainder, divides before narrowing, and rejects only results whose reduced numerator or denominator remains outside the Int64 domain. No floating-point or saturating arithmetic is used.

Coverage includes the reviewer vector `6000000000000000001/2 + (-9000000000000000001)/3 = 1/6`, its sign-reversed twin, the matrix sum-of-products path, and positive and negative same-sign out-of-range twins.

## Verification

- `moon check --target native font` — completed with 0 errors.
- `moon test --target native font` — 243 passed, 0 failed.
- `moon test --target native -j 2` — 1252 passed, 0 failed.
- `moon check --target all` — completed with 0 errors and 31 existing warnings.
- `git diff --check` — clean for fixer changes.

## Deviations

- `.planning/config.json` was already modified on entry and was neither staged nor committed.

---

_Fixed: 2026-07-29T01:25:39+08:00_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 2_
