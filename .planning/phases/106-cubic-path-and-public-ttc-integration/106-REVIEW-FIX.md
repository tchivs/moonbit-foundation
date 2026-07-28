---
phase: 106
fixed_at: 2026-07-28T22:11:52Z
review_path: .planning/phases/106-cubic-path-and-public-ttc-integration/106-REVIEW.md
iteration: 1
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 106: Code Review Fix Report

**Fixed at:** 2026-07-28T22:11:52Z
**Source review:** `.planning/phases/106-cubic-path-and-public-ttc-integration/106-REVIEW.md`
**Iteration:** 1 (fresh targeted cycle)

**Summary:**

- Findings in scope: 1
- Fixed: 1
- Skipped: 0
- Focused positive one-short regressions: 2 passed, 0 failed
- Full font suite: 269 passed, 0 failed
- Full native suite: 1281 passed, 0 failed
- All-target check: 0 errors (39 warnings)
- Diff check: passed

## Fixed Issues

### CR-01: Type 2 admission fetches an instruction before authorizing its work unit

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_type2.mbt`, `modules/mb-font/font/cff_type2_fixture_wbtest.mbt`  
**Commit:** `f7374542`  
**Applied fix:** Split the per-instruction VM charge into a preflight ticket and a post-read ledger acceptance. After the frame EOF check, the VM now verifies the initial byte limit first, then the VM work limit and deferred caller/ancestor work authority, all before invoking `read_probe` or `source.get`. A successful read accepts the already-authorized byte/work values without a second budget preflight or duplicate charge. Existing byte-before-work resource precedence is explicit in the ticket construction, and all deferred authority remains private until the admission transaction's existing sole commit.

Independent caller and ancestor regressions use a valid three-instruction glyph followed by a second glyph. Each budget has positive authority for exactly two instruction units and is one short for the third. Both tests observe exactly two VM reads, reject before the third read, never visit the later glyph, return no staged publication, and leave caller, ancestor, and child budgets unchanged.

## Cumulative Phase 106 Resolution

- The original review's five findings remain resolved: public CFF operation rebinding, static-glyf error precedence, cumulative CFF kern authority, the mutable post-stage path seam, and independent fixed goldens.
- Iteration 2's selected-outline pre-execution authority, negative public path capacity, and maximum-single-allocation findings remain resolved by commits `0020c030`, `da63eb07`, and `79143cf7`.
- Admission's deferred Type 2 work authority was introduced by `6f2164d9`; this fresh cycle closes its remaining mid-glyph read-order blocker with `f7374542`.
- The final review now has no outstanding Critical, Warning, or Info finding in scope.

---

_Fixed: 2026-07-28T22:11:52Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1 (fresh targeted cycle)_
