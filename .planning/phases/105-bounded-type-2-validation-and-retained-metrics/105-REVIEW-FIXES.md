---
phase: 105-bounded-type-2-validation-and-retained-metrics
fixed_at: 2026-07-29T01:06:39+08:00
review_path: .planning/phases/105-bounded-type-2-validation-and-retained-metrics/105-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 105: Code Review Fix Report

**Fixed at:** 2026-07-29T01:06:39+08:00  
**Source review:** `.planning/phases/105-bounded-type-2-validation-and-retained-metrics/105-REVIEW.md`  
**Iteration:** 1

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0
- Full native tests: 1250 passed, 0 failed
- All-target check: 0 errors, 31 pre-existing warnings

## Fixed Issues

### BL-01: The staged Type 2 charge does not authorize the allocations the VM actually performs

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/limits.mbt`, `modules/mb-font/font/cff_type2.mbt`, `modules/mb-font/font/cff_type2_bounds.mbt`, `modules/mb-font/font/cff_type2_fixed.mbt`, `modules/mb-font/font/cff_type2_fixture_wbtest.mbt`, `modules/mb-font/font/cff_type2_fixed_wbtest.mbt`, `modules/mb-font/font/cff_admission_wbtest.mbt`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`, `modules/mb-font/font/collection_wbtest.mbt`  
**RED commit:** `09793df2`  
**GREEN commit:** `396a3835`  
**Applied fix:** Preallocated the four fixed-capacity VM scratch arrays and retained-bounds array; changed `roll` to a scalar in-place three-reversal rotation; removed geometry snapshots, cubic point-array literals, and matrix conversion/scaling arrays; delayed each non-empty `GlyphBoundsFacts` allocation until cumulative caller authority has passed; and charged the exact four scratch arrays, one outer bounds array, and actual retained bounds objects.

The adversarial regression executes 64 rolls and 32 curves. Its exact allocation authority is independently fixed at 10 allocations: two glyphs × four scratch arrays, one outer bounds array, and one non-empty retained bounds object. The one-short budget of 9 fails with Resource/`allocations` before the retained object is created.

### MJ-01: Unreduced checked arithmetic rejects representable CFF fixed values and matrices

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_dict.mbt`, `modules/mb-font/font/cff_type2_fixed.mbt`, `modules/mb-font/font/cff_type2_fixed_wbtest.mbt`  
**RED commit:** `6721d282`  
**GREEN commit:** `98bccbb3`  
**Applied fix:** Q16.16 conversion now GCD-normalizes the CFF ratio and derives sixteen fractional bits with overflow-free remainder doubling instead of forming `magnitude × 65536`. Rational multiplication cross-cancels each numerator against the opposite denominator. Rational addition uses denominator GCD/LCM scaling and cancels the summed numerator against the shared denominator factor before the final checked product.

Coverage includes positive and negative near-one CFF ratios, positive maximum and negative minimum Q16 values, positive and negative out-of-range twins, reciprocal multiplication, LCM addition, Top-plus-FD translation composition, `unitsPerEm` scaling, and genuinely unrepresentable add/multiply results.

## Verification

- `moon test modules/mb-font/font --target native -j 2` — 241 passed, 0 failed.
- `moon test --target native -j 2` — 1250 passed, 0 failed.
- `moon check --target all` — completed with 0 errors and 31 existing warnings.
- `git diff --check` — clean for fixer changes.

## Deviations

- The RED positive-maximum Q16 test vector was corrected in the GREEN commit from a value that rounded to raw `2147483646` to the exact independently calculated raw `2147483647` boundary.
- Existing exact-budget fixtures were reduced by three allocations for three-glyph empty programs because the corrected ledger no longer invents one geometry scratch allocation per glyph and only charges retained bounds objects that actually exist.
- `.planning/config.json` was already modified on entry and was neither staged nor committed.

---

_Fixed: 2026-07-29T01:06:39+08:00_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
