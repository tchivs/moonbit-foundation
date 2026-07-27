---
phase: 101-collection-contract-and-bounded-envelope
fixed_at: 2026-07-27T23:01:29Z
review_path: .planning/phases/101-collection-contract-and-bounded-envelope/101-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 101: Code Review Fix Report

**Fixed at:** 2026-07-27T23:01:29Z
**Source review:** `.planning/phases/101-collection-contract-and-bounded-envelope/101-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Work authority is checked only after all bounded and quadratic traversals finish

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/collection_parser.mbt`, `modules/mb-font/font/collection_test.mbt`
**Commit:** f74a81f3
**Applied fix:** Split DSIG declaration parsing from block traversal, computed the exact retained/work charge once all declared counts were known, and preflighted both collection and caller authority before face, range, alias, or DSIG pair traversal. Added malformed-DSIG precedence regressions for both authority sources.

### CR-02: The advertised exact work charge omits the second full directory/table scan

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/collection_parser.mbt`, `modules/mb-font/font/collection_wbtest.mbt`
**Commit:** 0a7a704f
**Applied fix:** Retained the `CollectionFaceFacts` produced by the authorized structural scan and built protected bookkeeping from those facts, eliminating the second read and validation pass. Strengthened the structural-pass regression with exact retained directory and table facts.

### CR-03: Zero-length tables bypass mandatory table-offset alignment

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/collection_parser.mbt`, `modules/mb-font/font/collection_test.mbt`
**Commit:** e362a6d3
**Applied fix:** Applied four-byte table-offset alignment unconditionally while continuing to treat empty ranges as non-overlapping. Added a black-box zero-length, misaligned, in-bounds fixture with exact context and source-offset assertions.

### WR-01: DSIG pairwise containment and overlap branches have no executable tests

**Status:** fixed
**Files modified:** `modules/mb-font/font/collection_test.mbt`, `modules/mb-font/font/collection_wbtest.mbt`
**Commit:** 5ab3acf2
**Applied fix:** Added generated two-record DSIG fixtures for touching and non-monotonic disjoint blocks, partial and exact overlap, record-array containment, trailing gaps, and exact record/work/budget boundaries, including precise diagnostic fields and atomic-budget assertions.

### WR-02: The independent public-surface gate checks membership, not the required interface

**Status:** fixed
**Files modified:** `scripts/quality/Assert-Policy.ps1`
**Commit:** 7ddfe2e6
**Applied fix:** Replaced set membership with an independently maintained ordered declaration array checked through `Assert-ExactSequence`; retained deferred-capability pattern checks and added removed, duplicated, and reordered negative fixtures.

## Verification

- Focused regression tests passed for every finding.
- `collection_test.mbt` and `collection_wbtest.mbt` passed all 26 tests on each of `wasm`, `wasm-gc`, `js`, and `native`.
- `Assert-FontFoundationPolicy` passed, including generated four-target interface checks and the new negative fixtures.
- A whole-module `moon test --target all --frozen` attempt and a whole-module native attempt each exceeded 10 minutes without producing a test failure; the remaining idle driver process was stopped after timeout. The affected collection suite and policy gates completed successfully.

---

_Fixed: 2026-07-27T23:01:29Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
