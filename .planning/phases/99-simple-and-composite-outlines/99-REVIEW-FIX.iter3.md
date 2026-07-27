---
phase: 99-simple-and-composite-outlines
fixed_at: 2026-07-27T11:52:14Z
review_path: .planning/phases/99-simple-and-composite-outlines/99-REVIEW.md
iteration: 2
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 99: Code Review Fix Report

**Fixed at:** 2026-07-27T11:52:14Z
**Source review:** `.planning/phases/99-simple-and-composite-outlines/99-REVIEW.md`
**Iteration:** 2

**Summary:**

- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-04: The authoritative Budget undercounts scratch allocations

**Files modified:** `modules/mb-font/font/outline.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** 4e8d12c5
**Status:** fixed: requires human verification
**Applied fix:** Added reusable precharged empty-path and empty-geometry allocation plans, then routed equal-`loca`, zero-contour, and empty/zero-contour composite geometry branches through them before constructing their arrays or paths. Added failing-first exact-fit, zero-allocation, and one-short allocation-count coverage for each branch.

**Verification:**

- Focused failing-first native empty-outline tests: failed before the source fix, then passed 5/5.
- Focused native outline tests: passed 26/26.
- Full native font package: passed 91/91.
- Full JS font package: passed 91/91.
- Full Wasm font package: passed 91/91.
- Full Wasm-GC font package: passed 91/91.
- Exact font foundation policy/interface gate: passed.

---

_Fixed: 2026-07-27T11:52:14Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
