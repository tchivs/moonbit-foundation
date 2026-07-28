---
phase: 101-collection-contract-and-bounded-envelope
fixed_at: 2026-07-27T23:21:16.0314031Z
review_path: .planning/phases/101-collection-contract-and-bounded-envelope/101-REVIEW.md
iteration: 2
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 101: Code Review Fix Report

**Fixed at:** 2026-07-27T23:21:16.0314031Z
**Source review:** `.planning/phases/101-collection-contract-and-bounded-envelope/101-REVIEW.md`
**Iteration:** 2

**Summary:**
- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-01: The authority preflight fix silently reverses the frozen structural-error precedence

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/collection_parser.mbt`, `modules/mb-font/font/collection_test.mbt`, `modules/mb-font/font/collection_wbtest.mbt`
**Commit:** 1a768538
**Applied fix:** Split exact work authorization into declaration, allocation-free structural, and complete normalization stages. Each attacker-controlled traversal receives an exact work-only preflight before it runs, while the complete retained/work/caller-budget failures remain after all face, protected/alias, and DSIG structural facts per D-18. The retained normalization re-read is included in the exact charge. Replaced the reversed-precedence test with combined-conflict coverage for malformed face search facts, cross-face overlap, and malformed DSIG reserved fields against both one-short collection work and one-short caller work budgets.

**Verification:**
- Focused native black-box suite: 22/22 passed.
- Focused native white-box suite: 4/4 passed.
- Full `font` package: 129/129 passed independently on js, wasm, wasm-gc, and native.
- `moon info --target all`, ignored generated interface check, `Assert-FontFoundationPolicy`, `moon check --target all`, and `git diff --check` passed.

---

_Fixed: 2026-07-27T23:21:16.0314031Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
