---
phase: 101-collection-contract-and-bounded-envelope
reviewed: 2026-07-27T23:08:38Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - modules/mb-font/font/collection.mbt
  - modules/mb-font/font/collection_limits.mbt
  - modules/mb-font/font/collection_parser.mbt
  - modules/mb-font/font/collection_test.mbt
  - modules/mb-font/font/collection_wbtest.mbt
  - policy/foundation.json
  - scripts/quality/Assert-Policy.ps1
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 101: Code Review Report

**Reviewed:** 2026-07-27T23:08:38Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

All five findings from the prior review are directly addressed: work and caller-budget authority now precede the expensive traversals, the authorized face scan is retained instead of repeated without accounting, empty table offsets are aligned, the DSIG pair matrix is executable, and the independent interface gate checks the exact ordered sequence. The focused native suites pass 22 black-box and 4 white-box tests, and `Assert-FontFoundationPolicy` passes.

The CR-01 fix nevertheless introduced a new observable contract regression. It moved retained/work ceilings and caller budget preflight ahead of every face, protected-range, alias, and DSIG-block structural error, contrary to the frozen D-18 order and Plan 101-03's required precedence suite. The new test now asserts the opposite order instead of detecting the regression.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01 [BLOCKER]: The authority preflight fix silently reverses the frozen structural-error precedence

**File:** `D:/AI-Data/temp/Admin/mnf-phase100-exec/modules/mb-font/font/collection_parser.mbt:2007-2022`

**Issue:** `font_collection_parse` computes the retained/work charge and calls `budget.preflight` immediately after count and DSIG-declaration discovery. Every face search/tag/range/profile check, protected-range relation, table alias relation, and DSIG record/block check starts only at line 2023. A candidate that is both structurally malformed and one unit short on `max_work` or caller work budget therefore returns `Resource/BudgetExceeded` instead of the structural `Data`/`Capability` error. This contradicts CONTEXT D-18 and the explicit Plan 101-03 order: face facts, protected/alias relations, DSIG tuple/body facts, retained bytes, work, then caller budget. The regression is made permanent by `collection_test.mbt:1243-1271`, which now expects resource exhaustion to precede a malformed DSIG reserved field.

This is not merely a missing assertion: callers observe a different error category, code, context, and source location from the phase contract, and the claimed complete D-18 precedence qualification is false. The previous CR-01 denial-of-service concern and the frozen D-18 precedence are in tension; silently changing the latter inside a code-review fix is not a valid resolution.

**Fix:** Resolve the contract conflict explicitly before shipping. If D-18 remains authoritative, restore the specified allocation-free structural pass before retained/work and budget errors, then perform retained normalization only after preflight; account every normalization re-read in `font_collection_exact_work` so the prior CR-02 does not return. If security-first authority is the chosen behavior, amend the locked D-18 decision, research/plan truth, verification criteria, and the complete precedence matrix through the GSD decision flow before retaining the current ordering. In either case, add combined-conflict regressions for malformed face, protected/alias, and DSIG facts against both a one-short collection work limit and a one-short caller budget.

---

_Reviewed: 2026-07-27T23:08:38Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
