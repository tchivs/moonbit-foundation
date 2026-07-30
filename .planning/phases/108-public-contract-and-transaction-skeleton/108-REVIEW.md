---
phase: 108-public-contract-and-transaction-skeleton
reviewed: 2026-07-30T00:00:36Z
depth: standard
files_reviewed: 32
files_reviewed_list:
  - modules/mb-core/budget/budget_test.mbt
  - modules/mb-core/budget/budget_wbtest.mbt
  - modules/mb-core/budget/budget.mbt
  - modules/mb-core/CHANGELOG.md
  - modules/mb-core/checked/checked_test.mbt
  - modules/mb-core/checked/checked_wbtest.mbt
  - modules/mb-core/checked/checked.mbt
  - modules/mb-core/README.mbt.md
  - modules/mb-font/CHANGELOG.md
  - modules/mb-font/font/font_test.mbt
  - modules/mb-font/font/font_wbtest.mbt
  - modules/mb-font/font/font.mbt
  - modules/mb-font/font/shape_transaction_test.mbt
  - modules/mb-font/font/shape_transaction_wbtest.mbt
  - modules/mb-font/font/shape_transaction.mbt
  - modules/mb-font/README.mbt.md
  - modules/mb-text/CHANGELOG.md
  - modules/mb-text/moon.mod.json
  - modules/mb-text/README.mbt.md
  - modules/mb-text/text/contract_test.mbt
  - modules/mb-text/text/contract_wbtest.mbt
  - modules/mb-text/text/limits.mbt
  - modules/mb-text/text/moon.pkg
  - modules/mb-text/text/options.mbt
  - modules/mb-text/text/run.mbt
  - modules/mb-text/text/shape.mbt
  - modules/mb-text/text/tags.mbt
  - moon.work
  - policy/foundation.json
  - scripts/quality/Assert-Policy.ps1
  - scripts/quality/Invoke-FontQualification.ps1
  - scripts/quality/Invoke-MoonQuality.ps1
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 108: Code Review Report

**Reviewed:** 2026-07-30T00:00:36Z
**Depth:** standard
**Files Reviewed:** 32
**Status:** issues_found

## Summary

The four findings from the previous review were rechecked against commits
`cf2eee3a`, `fbda171e`, `ac34057f`, and `731bce82`. Their direct defects are
resolved: FontQualification now binds the transaction source and tests into its
89-line evidence contract and negative matrix; generated projection rejects a
foreign same-range glyph; cluster sources are bounded and classified as
`Data/InvalidEncoding`; and mb-text declares its README under the common policy.

All 19 mb-text tests pass on JS, Wasm, Wasm-GC, and native.
FontQualification's contract-only closed-contract and one-field negative probes
pass, and the foundation policy accepts the updated inventories and manifest
rule.

One error-precedence defect remains in the generated staging seam. The new
single-fault checks are correct, but the same facts lose to earlier capability
or numeric exits when faults are combined.

The repository knowledge graph was consulted first as required, but it did not
contain the Phase 108 MoonBit symbols. Direct source and test inspection was
therefore required.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Real input/data validation still runs after the capability gate

**Classification:** WARNING

**File:** `modules/mb-text/text/shape.mbt:188-207`

**Also affected:** `modules/mb-text/text/shape.mbt:280-296`,
`modules/mb-text/text/contract_wbtest.mbt:431-585`

**Issue:** `generated_shape_contract` returns
`text_shape_layout_unavailable()` when `capability_fault` is set before it calls
`project_generated_run`. The projection function is where the implementation
actually validates glyph ownership and cluster structure. It also performs
advance arithmetic before validating the cluster. Consequently:

- a foreign-font glyph combined with `capability_fault=true` returns
  `Capability` instead of the locked caller-contract `InvalidInput`;
- an empty or out-of-range cluster combined with `capability_fault=true`
  returns `Capability` instead of `Data/InvalidEncoding`; and
- malformed cluster data can lose to an earlier advance overflow inside the
  same projection.

This contradicts the Phase 108 precedence contract:
`InvalidInput -> State -> Data -> Capability -> Resource`. The added tests
exercise each new validation only with `capability_fault=false` and ordinary
advances, so they do not detect the multi-fault ordering error.

**Fix:** Split validation from projection. Validate glyph provenance in the
caller-contract stage, then validate and retain every cluster source immediately
after the entry state guard and before the capability gate. Only after those
passes should capability rejection and checked numeric/resource projection run.
Add combined-fault tests for foreign glyph plus capability, malformed cluster
plus capability, and malformed cluster plus overflowing advance, asserting the
locked category and an unchanged budget.

---

_Reviewed: 2026-07-30T00:00:36Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
