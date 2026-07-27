---
phase: 99-simple-and-composite-outlines
fixed_at: 2026-07-27T11:34:30Z
review_path: .planning/phases/99-simple-and-composite-outlines/99-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 99: Code Review Fix Report

**Fixed at:** 2026-07-27T11:34:30Z
**Source review:** `.planning/phases/99-simple-and-composite-outlines/99-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Instructions are incorrectly forbidden on non-final component records

**Files modified:** `modules/mb-font/font/outline.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** `320d1a00`
**Status:** fixed — requires human verification
**Applied fix:** Tracks `WE_HAVE_INSTRUCTIONS` across every component record, reads the single trailing instruction envelope after the final record, and covers first-record, last-record, and absent placements through the public outline API.

### CR-02: Flags that OpenType says to ignore for point attachment reject valid composites

**Files modified:** `modules/mb-font/font/outline.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** `5bc3f34b`
**Status:** fixed — requires human verification
**Applied fix:** Limits grid-rounding capability classification to XY placement and ignores the individual scaled/unscaled offset-policy bits for point attachment, with geometry-equivalence fixtures for every ignored flag.

### CR-03: `OVERLAP_COMPOUND` is accepted on later component records

**Files modified:** `modules/mb-font/font/outline.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** `f1b4ee68`
**Status:** fixed — requires human verification
**Applied fix:** Rejects `OVERLAP_COMPOUND` on every component after the first with a stable Data error context and a public negative fixture.

### CR-04: The authoritative Budget undercounts scratch allocations

**Files modified:** `modules/mb-font/font/outline.mbt`, `modules/mb-font/font/font_test.mbt`, `modules/mb-font/font/font_wbtest.mbt`
**Commits:** `e491dfd9`, `34a42813`, `63de2486`, `e8560931`
**Status:** fixed — requires human verification
**Applied fix:** Preflights and charges the complete four-array simple scratch plan before allocation, charges both composite accumulation arrays before allocation, uses checked conservative allocation-size bounds, and updates exact-fit, zero-allocation, one-short, successful-decoding, and malformed-taxonomy tests to the authoritative counts.

### WR-01: A second composite decoder is dead production code tested as if it were live

**Files modified:** `modules/mb-font/font/outline.mbt`, `modules/mb-font/font/font_wbtest.mbt`
**Commit:** `2abc9897`
**Status:** fixed
**Applied fix:** Removes the 324-line duplicate decoder and its warning suppression, and routes the white-box generated fixture through `Font::outline`.

## Verification

- Focused native regression tests passed for all five findings.
- Full native font package: 90/90 passed.
- Four-target font package: 90/90 passed on `wasm`, `wasm-gc`, `js`, and `native`.
- Exact font policy gate passed.
- `git diff --check` passed.

---

_Fixed: 2026-07-27T11:34:30Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
