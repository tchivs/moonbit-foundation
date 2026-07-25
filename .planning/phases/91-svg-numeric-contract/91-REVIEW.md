---
phase: 91-svg-numeric-contract
reviewed: 2026-07-25T16:15:52Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - docs/policies/svg-numeric-admission.md
  - modules/mb-svg/svg/numeric_contract_wbtest.mbt
  - modules/mb-svg/svg/parse_wbtest.mbt
  - modules/mb-svg/svg/scene_wbtest.mbt
  - modules/mb-svg/svg/path_data_wbtest.mbt
  - modules/mb-svg/svg/transform_wbtest.mbt
  - modules/mb-svg/svg/lower_wbtest.mbt
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 91: Code Review Report

**Reviewed:** 2026-07-25T16:15:52Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

The prior smooth-route finding remains fixed: the policy and path tracer
explicitly exclude `S`/`s` and `T`/`t`, including reflected-control arithmetic,
from the Phase 91 public numeric-admission contract pending Phase 92. The
remaining direct-path policy is still broader than its evidence: it promises
derived admission after every supported direct relative command, while the
only numeric-contract probe exercises `m` and `l`. The focused native numeric
test suite passed (6/6); the all-target command did not complete within the
124-second review timeout.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Relative-route guarantee exceeds the test evidence

**Classification:** BLOCKER

**File:** `D:/source/moonbit-foundation/docs/policies/svg-numeric-admission.md:70`

**Issue:** `SVG-NUM-RELATIVE` promises derived admission after *every* direct
relative-coordinate result for the supported `M/L/H/V/C/Q/A` routes. The sole
numeric-contract test for that row, at
`D:/source/moonbit-foundation/modules/mb-svg/svg/path_data_wbtest.mbt:84-92`,
only executes `m` and `l`. It supplies no boundary probe for `h`, `v`, `c`,
`q`, or relative `a`, so their endpoint/control additions are not evidenced.
This conflicts with D-02's requirement to cover every derived path and makes
the published direct-relative guarantee unauditable.

**Fix:** Add direct-relative boundary cases for `h`, `v`, `c`, `q`, and `a`
that inspect their derived coordinates/control points, alongside the existing
`m`/`l` assertion. For example, start at `(65535, 65535)`, use each branch to
reach or leave `(65536, 65536)`, and inspect the corresponding `CanvasPath`
commands. If Phase 91 intentionally covers only `m`/`l`, narrow both the
matrix row and the scope text to say so rather than claiming all direct
relative routes.

---

_Reviewed: 2026-07-25T16:15:52Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
