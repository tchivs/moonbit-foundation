---
phase: 105-bounded-type-2-validation-and-retained-metrics
reviewed: 2026-07-28T17:12:39Z
depth: deep
review_type: fix-recheck
diff_base: 6388615e
files_reviewed: 10
files_reviewed_list:
  - modules/mb-font/font/cff_admission_wbtest.mbt
  - modules/mb-font/font/cff_dict.mbt
  - modules/mb-font/font/cff_hostile_fixture_wbtest.mbt
  - modules/mb-font/font/cff_type2.mbt
  - modules/mb-font/font/cff_type2_bounds.mbt
  - modules/mb-font/font/cff_type2_fixed.mbt
  - modules/mb-font/font/cff_type2_fixed_wbtest.mbt
  - modules/mb-font/font/cff_type2_fixture_wbtest.mbt
  - modules/mb-font/font/collection_wbtest.mbt
  - modules/mb-font/font/limits.mbt
findings:
  blocker: 1
  critical: 0
  major: 1
  minor: 0
  total: 2
status: issues_found
---

# Phase 105: Code Review Fix Recheck

**Reviewed:** 2026-07-28T17:12:39Z  
**Range:** `6388615e..HEAD`  
**Status:** issues_found

## Summary

Both fixes materially improve the implementation: `roll`, geometry, and matrix hot paths no longer create operator-proportional arrays; retained bounds receive cumulative authority before allocation; Q16 conversion avoids the overflowing `magnitude * 65536`; and rational multiplication cross-cancels correctly. The independently fixed 10-allocation regression also avoids the original tautological exact-budget test.

Two boundary defects remain. The fixed frame array is one slot short at the legal nesting ceiling, and rational addition can still overflow its cross-products even when opposite-signed terms cancel to a small representable result.

## Blockers

### BL-R1: Legal depth-10 execution still grows the supposedly fixed frame array

**Classification:** BLOCKER  
**Files:** `modules/mb-font/font/cff_type2.mbt:1214-1256`; `modules/mb-font/font/cff_type2.mbt:1345-1366`; `modules/mb-font/font/limits.mbt:238-252`; `modules/mb-font/font/cff_type2_fixture_wbtest.mbt:79-102`; `modules/mb-font/font/cff_type2_fixture_wbtest.mbt:375-418`

**Issue:** `Type2Vm::new` reserves `limits.max_frames` entries, which is 10. The depth check counts suspended callers plus the new subroutine:

```moonbit
let requested_depth = self.frames.length().to_uint64() + 1UL
if requested_depth > self.limits.max_frames { ... }
```

For a legal call at nesting depth 10, the VM then pushes both the current caller and the new child. At that point the array contains the root caller, nine suspended subroutine callers, and the depth-10 child: 11 entries. The capacity-10 array therefore reallocates before the subsequent depth-11 call is rejected.

That backing-store growth is not included in the declared four fixed scratch-array allocations. The new exact-authority test covers repeated `roll` and many curves, but not the maximum legal call-frame occupancy; the existing recursion test only observes the eventual Resource error and cannot detect the earlier allocation.

**Fix:** Reserve the actual peak frame occupancy (`max_frames + 1`) with checked narrowing, or change frame representation so its proven peak is exactly `max_frames`. Recalculate `scratch_allocation_size` against that capacity. Extend the independent allocation-authority test with a tail/non-tail chain that successfully reaches depth 10, and a depth-11 twin that fails without any backing-store growth or caller charge.

## Major Issues

### MJ-R1: Rational addition still overflows before opposite-signed cancellation

**Classification:** WARNING (Major)  
**Files:** `modules/mb-font/font/cff_type2_fixed.mbt:294-333`; `modules/mb-font/font/cff_type2_fixed_wbtest.mbt:203-275`

**Issue:** The new addition correctly reduces denominator scaling by `gcd(left.denominator, right.denominator)`, but it still forms each scaled numerator independently with checked `Int64` multiplication before adding them:

```moonbit
left.numerator * left_scale
right.numerator * right_scale
```

Those products can overflow even when opposite-signed terms cancel and the final reduced rational is tiny. A concrete normalized, fully representable counterexample is:

```text
6000000000000000001 / 2
  + (-9000000000000000001 / 3)
  = 1 / 6
```

Both input rationals and the result fit `Int64`, but the implementation rejects the first `numerator * scale` product (`18000000000000000003`). The new LCM test uses small numerators and therefore does not exercise cross-summand cancellation.

This preserves the core MJ-01 behavior for valid matrices whose large positive and negative terms cancel during composition.

**Fix:** Implement an exact overflow-free signed fraction addition. Options include a checked wider intermediate when available, or sign-aware comparison/subtraction of cross-products using quotient/remainder decomposition so opposite-signed products can cancel before materialization. Only return the transform error when the reduced final numerator or denominator cannot fit. Add the counterexample above, its sign-reversed twin, a same-sign genuinely overflowing twin, and a matrix sum-of-products case that reaches this path.

## Verification Evidence

- Focused allocation regression: `moon test modules/mb-font/font --target native -j 2 -f "Type 2 repeated roll and many curves use fixed scratch allocation authority"` — 1 passed, 0 failed.
- Focused arithmetic regression: `moon test modules/mb-font/font --target native -j 2 -f "Type 2 rational add multiply and matrix scale cancel before products"` — 1 passed, 0 failed.
- Full native evidence adopted from `105-REVIEW-FIXES.md`: 1250 passed, 0 failed.
- `moon check --target all` re-run: 0 errors, 31 existing warnings.
- `git diff --check 6388615e..HEAD -- modules/mb-font/font`: clean.

The focused tests pass because neither contains the residual boundary described above.

---

_Reviewed: 2026-07-28T17:12:39Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: deep fix recheck_
