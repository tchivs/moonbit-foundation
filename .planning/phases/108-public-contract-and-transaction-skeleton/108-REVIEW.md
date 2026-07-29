---
phase: 108-public-contract-and-transaction-skeleton
reviewed: 2026-07-29T23:35:05Z
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
  critical: 1
  warning: 3
  info: 0
  total: 4
status: issues_found
---

# Phase 108: Code Review Report

**Reviewed:** 2026-07-29T23:35:05Z
**Depth:** standard
**Files Reviewed:** 32
**Status:** issues_found

## Summary

The Phase 108 arithmetic, budget composition, scope invalidation, final revision
guard, and current public empty-shape path are internally consistent, and the
focused native suites pass: 14 budget tests, 22 checked-arithmetic tests, 284
font tests, and 1323 workspace-resolved text tests. The FontQualification
contract-only negative matrix also passes.

That green result masks one release-gate blocker: FontQualification now attests
the 89-line Phase 108 public interface while its source-identity inventories and
policy count still describe the old 85-line implementation. The review also
found three robustness/publication defects in the new module contract.

The repository knowledge graph was consulted first as required, but the indexed
`modules` scope contained no Phase 108 MoonBit functions and the symbol search
returned zero results. Direct source and test inspection was therefore required.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: FontQualification omits the implementation and tests of the public transaction API

**Classification:** BLOCKER

**File:** `scripts/quality/Invoke-FontQualification.ps1:101-145`

**Also affected:** `scripts/quality/Assert-Policy.ps1:3123`,
`policy/foundation.json:2433-2505`

**Issue:** Phase 108 changes FontQualification's evidence to record an 89-line
semantic interface, but `$ProductionSourcePaths` still ends at
`cff_admission.mbt` and `$FontTestSourcePaths` still ends at the pre-Phase-108
test set. Consequently `source_identities`, `boundary_facts.production_sources`,
and their digests omit `shape_transaction.mbt`,
`shape_transaction_test.mbt`, and `shape_transaction_wbtest.mbt`. At the same
time, the policy and its validator still require
`public_interface_lines: 85`, while generated evidence requires 89.

Both contradictory contracts currently pass: the review ran
`Invoke-FontQualification.ps1 -ContractOnly` successfully. An implementation
change to the public transaction seam, paired with compensating changes to its
omitted tests, can therefore produce the same qualification source identities
and pass count. The evidence no longer binds the full published font package or
the public API it claims to seal.

**Fix:**

```powershell
$ProductionSourcePaths = @(
  # existing entries...
  'modules/mb-font/font/cff_admission.mbt',
  'modules/mb-font/font/shape_transaction.mbt'
)
$FontTestSourcePaths = @(
  # existing entries...
  'modules/mb-font/font/generated_fonts_wbtest.mbt',
  'modules/mb-font/font/shape_transaction_test.mbt',
  'modules/mb-font/font/shape_transaction_wbtest.mbt'
)
```

Update `qualification.public_interface_lines` to 89, regenerate the matching
policy file facts and semantic digest, and add negative probes that delete or
mutate each new source identity. The policy validator and evidence builder must
derive or compare the same interface count and source inventories.

## Warnings

### WR-01: Generated run projection can publish a foreign-font GlyphId

**Classification:** WARNING

**File:** `modules/mb-text/text/shape.mbt:166-199`

**Issue:** `project_generated_run` copies `fact.glyph` directly into a
`PositionedGlyph` without proving it belongs to the `Font` whose transaction is
active. `generated_shape_contract` receives the font and logical facts
separately, so a logical fact can contain a `GlyphId` issued by a different
font. All existing projection tests construct facts from the same font, leaving
the ownership failure untested. The current public nonempty route is closed,
but this production staging seam is intended to be connected by later phases;
as written, that connection can violate the documented same-font run invariant.

**Fix:** Bind generated glyph construction to the active font authority. For
example, validate every staged glyph through an mb-font-owned owner check before
projection (or derive the glyph and metrics from the active scope instead of
accepting an arbitrary `GlyphId`). Add a test using two distinct same-range
fonts and assert rejection before publication and budget charge.

### WR-02: Cluster staging accepts indices outside the request and reports internal corruption as caller input

**Classification:** WARNING

**File:** `modules/mb-text/text/shape.mbt:141-163`

**Issue:** `generated_cluster` checks only that the consumed-index array is
nonempty and then takes its minimum. It never checks that each index is less
than the validated scalar snapshot length. A one-scalar request can therefore
stage and publish cluster `99`. The empty-list case is also reported as
`InvalidInput`, even though it is malformed internal/generated structural data
after caller inputs have already passed validation. This breaks the locked
scalar-origin cluster invariant and the Input → State → Data → Capability →
Resource error taxonomy.

**Fix:** Pass the snapshot length into cluster projection, reject an empty list
or any index `>= input_count` as `Data/InvalidEncoding` with a stable projection
context, and test empty, exact-last, one-past, and mixed valid/invalid consumed
indices with unchanged budgets.

### WR-03: mb-text publication metadata deliberately permits a missing README declaration

**Classification:** WARNING

**File:** `modules/mb-text/moon.mod.json:1-13`

**Also affected:** `scripts/quality/Assert-Policy.ps1:808-812`

**Issue:** Every other foundation module declares
`"readme": "README.mbt.md"`, but the new mb-text manifest omits it. Instead of
enforcing the repository publication convention, `Assert-Policy.ps1`
special-cases mb-text as the only module allowed to omit the field. This can
publish the candidate module without associating its contract README, despite
the policy and summary claiming a closed documentation/publication boundary.
The special case also turns a one-module metadata mistake into accepted policy.

**Fix:** Add `"readme": "README.mbt.md"` to `modules/mb-text/moon.mod.json` and
remove the mb-text exception so the shared manifest check applies uniformly.

---

_Reviewed: 2026-07-29T23:35:05Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
