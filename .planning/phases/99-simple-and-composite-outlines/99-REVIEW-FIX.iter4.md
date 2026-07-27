---
phase: 99-simple-and-composite-outlines
fixed_at: 2026-07-27T12:06:13Z
review_path: .planning/phases/99-simple-and-composite-outlines/99-REVIEW.md
iteration: 3
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 99: Code Review Fix Report

**Fixed at:** 2026-07-27T12:06:13Z
**Source review:** `.planning/phases/99-simple-and-composite-outlines/99-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-01: Composite graph-state storage bypasses the allocation-size ceiling

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/outline.mbt`, `modules/mb-font/font/font_wbtest.mbt`
**Commit:** 18180593
**Applied fix:** The composite graph classifier now computes the `Array[Int]` state-table plan with checked multiplication and a documented conservative eight-byte portable slot size before allocating. Exact-fit (88 bytes), one-byte-short (87 bytes), and arithmetic-overflow regression cases preserve the required Resource/allocation-size and Data/invalid-encoding taxonomy. An audit of the remaining typed arrays found their element sizes already conservatively covered.

## Verification

- Failing-first regression: failed before the source fix with native test-process exit `0xc0000409`.
- Focused state-allocation regression: 1/1 passed on native.
- Focused outline suite: 26/26 passed on native.
- Full font package: 92/92 passed on native, js, wasm, and wasm-gc.
- Exact generated-interface and font foundation policy gate passed.

---

_Fixed: 2026-07-27T12:06:13Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
