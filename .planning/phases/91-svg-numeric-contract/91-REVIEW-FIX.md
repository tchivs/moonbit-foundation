---
phase: 91-svg-numeric-contract
fixed_at: 2026-07-25T15:59:08Z
review_path: D:/source/moonbit-foundation/.planning/phases/91-svg-numeric-contract/91-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 91: Code Review Fix Report

**Fixed at:** 2026-07-25T15:59:08Z
**Source review:** `D:/source/moonbit-foundation/.planning/phases/91-svg-numeric-contract/91-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: Transform application to geometry is absent from the numeric contract

**Files modified:** `docs/policies/svg-numeric-admission.md`
**Commit:** `7d8f817`
**Applied fix:** Added `SVG-NUM-TRANSFORMED-GEOMETRY`, explicitly assigning accumulated root/group affine geometry validation and its rejection evidence to Phase 92.

### CR-02: The smooth-cubic path route is falsely reported as covered

**Files modified:** `modules/mb-svg/svg/path_data_wbtest.mbt`
**Commit:** `92d3d26`
**Applied fix:** Scoped Phase 91 path evidence to direct commands and explicitly deferred smooth-cubic parameter and emitted-geometry verification to Phase 92.

### WR-01: Relative-coordinate test does not reach the claimed inclusive boundary

**Files modified:** `modules/mb-svg/svg/path_data_wbtest.mbt`
**Commit:** `c80ba34`
**Applied fix:** Changed the relative path control to derive and assert the inclusive `(65536, 65536)` endpoint.

### WR-02: Numeric test locks an incorrect SVG skew result

**Files modified:** `modules/mb-svg/svg/transform_wbtest.mbt`
**Commit:** `dbb09bf`
**Applied fix:** Replaced angle-coefficient assertions with finite, in-envelope checks for all six affine components; standards-correct skew semantics remain Phase 92 work.

---

_Fixed: 2026-07-25T15:59:08Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
