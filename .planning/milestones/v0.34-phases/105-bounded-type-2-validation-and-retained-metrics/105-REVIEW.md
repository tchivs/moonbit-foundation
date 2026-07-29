---
phase: 105-bounded-type-2-validation-and-retained-metrics
reviewed: 2026-07-28T16:46:48Z
depth: deep
diff_base: a7d021de
files_reviewed: 21
files_reviewed_list:
  - modules/mb-font/font/cff_admission.mbt
  - modules/mb-font/font/cff_admission_wbtest.mbt
  - modules/mb-font/font/cff_cid_fixture_wbtest.mbt
  - modules/mb-font/font/cff_dict.mbt
  - modules/mb-font/font/cff_dict_wbtest.mbt
  - modules/mb-font/font/cff_hostile_fixture_wbtest.mbt
  - modules/mb-font/font/cff_keying.mbt
  - modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt
  - modules/mb-font/font/cff_type2.mbt
  - modules/mb-font/font/cff_type2_bounds.mbt
  - modules/mb-font/font/cff_type2_bounds_wbtest.mbt
  - modules/mb-font/font/cff_type2_fixed.mbt
  - modules/mb-font/font/cff_type2_fixed_wbtest.mbt
  - modules/mb-font/font/cff_type2_fixture_wbtest.mbt
  - modules/mb-font/font/cff_type2_wbtest.mbt
  - modules/mb-font/font/collection_test.mbt
  - modules/mb-font/font/collection_wbtest.mbt
  - modules/mb-font/font/font_test.mbt
  - modules/mb-font/font/font_wbtest.mbt
  - modules/mb-font/font/limits.mbt
  - modules/mb-font/font/metrics.mbt
findings:
  blocker: 1
  critical: 0
  major: 1
  minor: 0
  total: 2
status: issues_found
---

# Phase 105: Code Review Report

**Reviewed:** 2026-07-28T16:46:48Z  
**Depth:** deep  
**Range:** `a7d021de..HEAD`  
**Files Reviewed:** 21  
**Status:** issues_found

## Summary

The verifier gap fixes themselves are present on the exercised paths: the PRNG emits `high16(state) + 1`, each non-empty contour contributes its start to the transformed hull, and VM error exits added by Plan 105-05 recheck source revision. However, Phase 105 is not ready to ship because its caller-owned resource charge materially understates allocations made while interpreting untrusted Type 2 programs. A separate checked-rational defect rejects representable CFF numbers and matrices solely because an unreduced intermediate overflows.

Validation run during review:

- `moon test modules/mb-font/font --target native -j 2`: 238 passed, 0 failed.
- `moon check --target all`: completed with 0 errors and 31 warnings.

Passing tests do not cover either adversarial case below.

## Blockers

### BL-01: The staged Type 2 charge does not authorize the allocations the VM actually performs

**Classification:** BLOCKER  
**Files:** `modules/mb-font/font/limits.mbt:249-252`; `modules/mb-font/font/cff_type2.mbt:517-523`; `modules/mb-font/font/cff_type2.mbt:1745-1784`; `modules/mb-font/font/cff_type2_fixed.mbt:363-369`; `modules/mb-font/font/cff_type2_fixed.mbt:439-445`; `modules/mb-font/font/cff_type2_bounds.mbt:79-101`; `modules/mb-font/font/cff_type2_bounds.mbt:386-390`; `modules/mb-font/font/cff_admission_wbtest.mbt:373-420`

**Issue:** `type2_limits` declares exactly five scratch allocations per glyph and a largest scratch allocation of 384 bytes. `type2_stage_all_glyphs_unchecked_with_probe` multiplies that constant by the glyph count, adds one bounds-array allocation, and uses those values as the complete Type 2 `ResourceCharge`.

The implementation performs additional allocations that are not represented by that charge:

- every non-zero `roll` creates a fresh `Array[Type2Fixed]` at lines 517-523, so an attacker can cause operator-count-dependent allocations by repeatedly executing `roll`;
- matrix conversion/scaling creates temporary arrays at `cff_type2_fixed.mbt:363-369` and `439-445` for every glyph;
- every geometry operation snapshots a new `Type2BoundsSink`, and every cubic creates an array literal of points;
- the growable operand and frame arrays are not preallocated to their locked capacities, so backing-store growth need not equal one allocation each;
- retained `Some(GlyphBoundsFacts)` values may require per-bound objects in addition to the outer bounds array, but the charge records only the outer allocation.

Consequently a budget with the reported exact allocation count can pass both Type 2 and combined preflight and be committed even though admission allocated more objects, or a larger object, than the caller authorized. This contradicts the Phase 105 D-18/D-22 atomic resource contract and makes the bounded interpreter vulnerable to allocation amplification from untrusted charstrings.

The “exact” test at `cff_admission_wbtest.mbt:373-420` cannot detect this: it constructs the second budget from the implementation's own undercounted `combined_charge` and then checks only the budget counters, not allocations performed by execution.

**Fix:** Make allocation behavior and accounting agree before executing attacker-controlled programs. Prefer a genuinely fixed-scratch VM:

1. Preallocate operand, transient/init, and frame storage once at their closed capacities and reuse them for each glyph where possible.
2. Implement `roll` in place with a constant number of scalar temporaries; remove arrays/array literals and heap-producing snapshots from operator and bounds hot paths.
3. Convert/scale the six matrix elements without temporary arrays.
4. Define the retained bounds representation explicitly and include every retained allocation and its actual largest allocation size.
5. If any dynamic allocation remains, preflight a proven upper bound derived from admitted limits before the first such allocation; do not derive the charge after performing the work.
6. Add an adversarial repeated-`roll`/many-curve admission test backed by allocation instrumentation or an allocation-free VM invariant, and assert exact/one-short authority against independently derived constants rather than values returned by the implementation under test.

## Major Issues

### MJ-01: Unreduced checked arithmetic rejects representable CFF fixed values and matrices

**Classification:** WARNING (Major)  
**Files:** `modules/mb-font/font/cff_dict.mbt:141-157`; `modules/mb-font/font/cff_type2_fixed.mbt:294-335`; `modules/mb-font/font/cff_type2_fixed.mbt:427-444`

**Issue:** CFF-to-Q16.16 conversion computes `magnitude * 65536` before dividing by the CFF denominator. Rational addition and multiplication similarly cross-multiply full numerators and denominators before reduction. These operations can overflow even when the final Q16.16 or transformed rational result is small and representable.

For example, the existing DICT real parser can retain `999999999999999999 / 1000000000000000000` (approximately one). It fits Q16.16, but `cff_number_to_type2_fixed` rejects it because multiplying the numerator by 65536 overflows `UInt64`. The same value used in a FontMatrix can pass `type2_rational_from_cff`, then fail when `type2_matrix_scale` multiplies it by a normal `unitsPerEm`, although the mathematical result is approximately 1000. Equivalent cancellation failures exist in `type2_rational_add`.

This turns valid, representable Private DICT widths/seeds and FontMatrix values into deterministic Data errors. It violates the intended rule that checked intermediates protect arithmetic while returned values are rejected only when the result cannot fit the locked representation.

**Fix:** Reduce before multiplication:

- For Q16.16 conversion, cancel `gcd(denominator, 65536)` first, or split into integer and remainder parts and perform a checked, cancellation-aware scaled division.
- For rational multiplication, cross-cancel `gcd(abs(left.numerator), right.denominator)` and `gcd(abs(right.numerator), left.denominator)` before multiplying.
- For addition, reduce the denominators by their GCD and use the least-common-denominator form, with any further cancellation available before checked products.
- Add tests using large-magnitude/large-denominator DICT reals whose mathematical values fit Q16.16, plus Top/FD matrix composition and `unitsPerEm` scaling vectors that require cancellation. Include positive, negative, and just-out-of-range twins.

---

_Reviewed: 2026-07-28T16:46:48Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: deep_
