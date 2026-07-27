---
phase: 101-collection-contract-and-bounded-envelope
reviewed: 2026-07-27T23:27:45Z
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

**Reviewed:** 2026-07-27T23:27:45Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

The original five findings are directly addressed: traversal now has staged work authority, normalization re-reads are charged, empty table offsets are aligned, the two-record DSIG matrix is executable, and the independent interface gate enforces the exact ordered surface. The focused native suite passes 26/26 tests, `moon check --target all --frozen`, `Assert-FontFoundationPolicy`, PowerShell parsing, JSON parsing, and `git diff --check` all pass.

The iteration-2 precedence blocker is only partially fixed. The new combined-conflict tests use limits one below the *complete* charge but still above the structural-stage charge, so they do not exercise the point where staged authority actually changes the public error. DSIG declaration validation also still runs before all face, protected-range, and alias facts. Consequently the implementation does not implement the unconditional D-18 sequence claimed by the context and Plan 101-03.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01 [BLOCKER]: Staged authority still violates D-18 at its stage boundary and DSIG declarations remain out of order

**File:** `D:/AI-Data/temp/Admin/mnf-phase100-exec/modules/mb-font/font/collection_parser.mbt:2134-2166`

**Issue:** The fix preflights `structural_work` at lines 2141-2166 before the first face scan at line 2167. For the shipped one-face DSIG fixture the structural charge is 43 and the complete charge is 57. The new regressions at `collection_test.mbt:1243-1328` use `max_work=56` or caller work 56, so structural traversal is authorized and the malformed fact correctly wins. With `max_work=42` or caller work 42, however, the same malformed face/alias/DSIG-block candidate returns `Resource/BudgetExceeded` before the structural error. D-18 and Plan 101-03 specify face, protected/alias, and DSIG facts before the retained/work/budget tiers; no decision artifact narrows that promise to budgets above the structural charge.

There is a second observable ordering hole in the same path: `font_collection_parse_dsig_declaration` is called at lines 2134-2138 before face scanning and validates DSIG version/count/flags. A v2 candidate with both malformed face search facts and an unsupported DSIG version therefore returns DSIG `Capability` before the face `Data` error, despite Plan 101-03 explicitly ordering face and protected/alias facts before DSIG tuple/body facts. The added precedence matrix covers only a late DSIG reserved-field error, not DSIG declaration errors.

**Fix:** Resolve the contract conflict through the GSD decision flow rather than another local parser-only change. The defensible security-first contract is to document declaration-stage and structural-stage work/budget preflights as explicit earlier precedence tiers, amend D-18 and the Plan 101-03 truth accordingly, and add exact `declaration_work-1`, `structural_work-1`, and `exact_work-1` tests for both collection and caller authority. Separately split DSIG authority discovery from DSIG semantic validation: gather only the bounded counts needed for the structural charge, defer version/flags/record semantics until after face and protected/alias validation, and add combined malformed-face versus DSIG tuple/version/count/flags cases. If D-18 must remain unchanged, the implementation cannot expose the current early stage failures and needs a different authority model.

---

_Reviewed: 2026-07-27T23:27:45Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
