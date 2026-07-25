---
phase: 91-svg-numeric-contract
reviewed: 2026-07-25T16:06:17Z
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

**Reviewed:** 2026-07-25T16:06:17Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

The four prior findings are resolved as documented: transformed geometry is now
an explicit Phase 92 route, the misleading smooth-cubic coverage assertion was
removed, the relative-path probe reaches `(65536, 65536)`, and skew checks no
longer lock the incorrect coefficient. One requirement-level gap remains. The
published path route still promises coverage for `S` and `T` plus smooth-control
derivations, but Phase 91 has no route-matrix test for either command family.
This prevents SVGPR-01's claim of evidence for every supported scalar ingress
and derived path from being true.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Smooth path routes remain uncovered despite being declared supported

**Classification:** BLOCKER

**File:** `D:/source/moonbit-foundation/modules/mb-svg/svg/path_data_wbtest.mbt:75-90`

**Issue:** The numeric-contract test calls `M`, `L`, `H`, `V`, `C`, `Q`, and
`A`, then exercises only relative `m`/`l`. It explicitly excludes `S` at lines
77-78 and never invokes `T`, `s`, or `t`. This conflicts with the published
`SVG-NUM-PATH` route, which lists `S` and `T` as supported command numeric
arguments, and `SVG-NUM-RELATIVE`, which requires derived admission in the
smooth-control branches ([svg-numeric-admission.md](../../../docs/policies/svg-numeric-admission.md):66-67).
Consequently, the phase does not provide the required evidence for every
supported scalar ingress and derived-value path. The known `S` parser defect
must remain a Phase 92 implementation fix, but excluding it here cannot make
the Phase 91 coverage claim correct.

**Fix:** Keep parser changes deferred to Phase 92, but make the contract and
phase state truthful now: either (1) move `S`/`T` and their reflected-control
routes out of the completed SVGPR-01 coverage claim and mark that portion
pending on Phase 92, or (2) add Phase 92 acceptance tests for absolute and
relative `S`/`T` that prove every source argument and reflected/relative result
is admitted before marking SVGPR-01 complete. Do not restore a count-only `S`
test; it would conceal the known parameter-consumption defect again.

---

_Reviewed: 2026-07-25T16:06:17Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
