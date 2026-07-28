---
phase: 105-bounded-type-2-validation-and-retained-metrics
reviewed: 2026-07-28T17:30:53Z
depth: deep
review_type: final-fix-recheck
diff_base: 6a66e15d
diff_head: 7c8bc8b9
files_reviewed: 5
files_reviewed_list:
  - modules/mb-font/font/cff_type2.mbt
  - modules/mb-font/font/cff_type2_fixed.mbt
  - modules/mb-font/font/cff_type2_fixed_wbtest.mbt
  - modules/mb-font/font/cff_type2_fixture_wbtest.mbt
  - modules/mb-font/font/limits.mbt
findings:
  blocker: 0
  critical: 0
  major: 0
  minor: 0
  total: 0
status: clean
---

# Phase 105: Final Code Review Recheck

**Reviewed:** 2026-07-28T17:30:53Z  
**Range:** `6a66e15d..7c8bc8b9`  
**Status:** clean

## Summary

The two findings from `105-REVIEW-RECHECK.md` are closed. The five changed source/test files were reviewed for correctness, resource/accounting consistency, overflow behavior, target portability, and test independence. No new Blocker or Major issue was found in this bounded fix range.

## Finding Closure

### BL-R1: Closed — legal depth 10 no longer reallocates frame scratch

**Production evidence:**

- `modules/mb-font/font/limits.mbt:234-248` keeps the semantic subroutine-depth ceiling at 10, derives `frame_slots = max_frames + 1` with checked arithmetic, and narrows it through `checked_narrow_int`.
- `modules/mb-font/font/limits.mbt:243-277` independently derives operand and frame backing-store sizes and records their maximum as `scratch_allocation_size`, while preserving exactly four charged scratch arrays.
- `modules/mb-font/font/cff_type2.mbt:1345-1366` constructs the frame array with `capacity=limits.frame_capacity`; the root is inserted into the already-authorized 11-slot backing store.
- The existing call check still rejects only `requested_depth > max_frames`, so legal depth 10 and Resource failure at depth 11 retain their prior semantics.

The peak occupancy is root plus ten live subroutine frames, exactly 11 slots. No push on an admitted depth-10 path exceeds the reserved capacity, so the previously uncharged grow/reallocation path is removed.

**Regression evidence:**

- `modules/mb-font/font/cff_type2_fixture_wbtest.mbt:106-159` builds a non-tail chain that reaches depth 10, directly asserts capacity 11, observes ten calls and ten returns, and verifies the depth-11 twin fails with `font-cff-type2-frame-depth`.
- `modules/mb-font/font/cff_type2_fixed_wbtest.mbt:377-399` freezes `max_frames == 10`, `frame_capacity == 11`, four scratch allocations, and the independently derived largest allocation size.

### MJ-R1: Closed — opposite-signed cross-products cancel before narrowing

**Production evidence:**

- `modules/mb-font/font/cff_type2_fixed.mbt:19-22` defines the two-word unsigned value as an allocation-free value type.
- `modules/mb-font/font/cff_type2_fixed.mbt:261-343` implements exact 64×64→128 multiplication, carry-aware addition, lexicographic comparison, borrow-aware subtraction, and fixed 128-step unsigned division/remainder.
- `modules/mb-font/font/cff_type2_fixed.mbt:370-445` computes both scaled numerator magnitudes in the wide domain, performs sign-aware addition/subtraction, obtains cancellation from the exact wide remainder modulo the shared denominator, divides before narrowing, and rejects only a reduced magnitude outside the retained `Int64` rational domain.

The helper preconditions are satisfied by `Type2Rational`: numerators exclude `INT64_MIN`, denominators are positive `Int64`, each 64×64 product is below 2^126, their sum is below 2^127, and the long-division remainder cannot overflow while doubling because its divisor is at most `INT64_MAX`. The implementation uses no heap array, floating-point, saturation, or target-width `Int` arithmetic in this path.

**Regression evidence:**

- `modules/mb-font/font/cff_type2_fixed_wbtest.mbt:279-335` freezes the reviewer counterexample `6000000000000000001/2 + (-9000000000000000001)/3 = 1/6`, its sign-reversed twin, the matrix sum-of-products route, and positive/negative same-sign overflow twins.
- The earlier LCM/cancellation tests continue to cover a nontrivial shared-denominator cancellation and matrix composition/scaling.

## Verification Evidence

- Existing second-fix package evidence from `105-REVIEW-FIXES-2.md`: 243 native font tests passed, 0 failed.
- Existing full native evidence from `105-REVIEW-FIXES-2.md`: 1252 passed, 0 failed.
- Existing all-target evidence from `105-REVIEW-FIXES-2.md`: 0 errors, 31 pre-existing warnings.
- Re-run in this review: `git diff --check 6a66e15d..7c8bc8b9 -- modules/mb-font/font` — clean.

A focused re-run was not used as additional evidence because the shared default Moon build directory was occupied by another active repository task. The already-recorded post-fix package/full/all-target results cover both newly added regression tests, and no other process or workspace change was disturbed.

## Final Verdict

All files in the bounded second-fix range meet the Phase 105 correctness and resource-accounting contracts relevant to BL-R1 and MJ-R1. The final re-review is clean.

---

_Reviewed: 2026-07-28T17:30:53Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: deep final fix recheck_
