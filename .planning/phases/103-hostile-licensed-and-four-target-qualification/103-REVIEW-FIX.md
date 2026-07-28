---
phase: 103-hostile-licensed-and-four-target-qualification
fixed_at: 2026-07-28T07:08:00Z
review_path: .planning/phases/103-hostile-licensed-and-four-target-qualification/103-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 103: Code Review Fix Report

**Fixed at:** 2026-07-28T07:08:00Z  
**Source review:** `.planning/phases/103-hostile-licensed-and-four-target-qualification/103-REVIEW.md`  
**Iteration:** 1

**Summary:**

- Findings in scope: 8
- Fixed: 8
- Skipped: 0

## Fixed Issues

### CR-01: The canonical collection corpus records false structured outcomes

**Files modified:** `scripts/fixtures/Generate-FontQualification.ps1`, `fixtures/font/collection-qualification-cases.json`, `fixtures/manifest.json`, `modules/mb-font/font/generated_font_qualification_test.mbt`, `scripts/quality/Assert-Policy.ps1`  
**Commit:** `16980ffe`  
**Status:** fixed: requires human verification  
**Applied fix:** Replaced generic ID-derived values with explicit per-case runtime contracts and regenerated every derived identity.

### CR-02: The closed matrix can pass without executing locked cases

**Files modified:** `modules/mb-font/font/font_qualification_hostile_test.mbt`, `modules/mb-font/font/collection_wbtest.mbt`, `scripts/fixtures/Generate-FontQualification.ps1`, `fixtures/font/collection-qualification-cases.json`, `fixtures/manifest.json`, `modules/mb-font/font/generated_font_qualification_test.mbt`, `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Invoke-FontQualification.ps1`  
**Commit:** `bbe59b7e`  
**Status:** fixed: requires human verification  
**Applied fix:** Added generated-row lookup and full error comparison, direct selected/collection limit dispatch, checked overflow execution, and exact parent/child budget accounting.

### CR-03: Validators accept nested semantic drift

**Files modified:** `scripts/quality/Invoke-FontQualification.ps1`, `scripts/quality/Assert-Policy.ps1`  
**Commit:** `0bb1f297`  
**Status:** fixed: requires human verification  
**Applied fix:** Closed all nested schemas and canonical values, enforced failure atomicity, and locked the complete corpus semantic digest.

### CR-04: A post-initialization link swap escapes the evidence root

**Files modified:** `scripts/quality/Invoke-FontQualification.ps1`, `scripts/quality/Test-FontQualificationEvidenceBoundary.ps1`  
**Commit:** `700687ed`  
**Status:** fixed: requires human verification  
**Applied fix:** Revalidated every write boundary, staged with exclusive creation, flushed and atomically published files, then added target/comparison swap regressions.

### CR-05: Portable-source policy is only a name filter

**Files modified:** `scripts/quality/Assert-Policy.ps1`, `policy/foundation.json`  
**Commit:** `4708a5b1`  
**Status:** fixed: requires human verification  
**Applied fix:** Added executable token and container-magic flow checks plus independently locked production and negative-contract semantic digests.

### CR-06: CI policy accepts an additional failing-evidence upload

**Files modified:** `scripts/quality/Assert-Policy.ps1`  
**Commit:** `449e913e`  
**Status:** fixed: requires human verification  
**Applied fix:** Added a fail-closed structural workflow parser and negative probes for duplicate upload, alias path, job continuation, and shadow lanes.

### WR-01: comparison.json is neither closed nor read back

**Files modified:** `scripts/quality/Invoke-FontQualification.ps1`  
**Commit:** `d7e69d9f`  
**Applied fix:** Added exact comparison schema, record/semantic hash verification, durable read-back, and negative probes.

### WR-02: Evidence does not bind all focused test sources

**Files modified:** `scripts/quality/Invoke-FontQualification.ps1`, `scripts/quality/Test-FontQualificationEvidenceBoundary.ps1`  
**Commit:** `d4eea58d`  
**Applied fix:** Added exact repository commit/tree and ordered hashes for all eight focused test and helper sources.

## Verification

- Generator drift check: passed.
- Policy, schema, inventory, source-boundary, and negative contracts: passed.
- Native hostile matrix: 3/3 passed.
- Native collection white-box suite: 14/14 passed.
- Evidence destructive/link-swap boundary suite: passed.
- Complete four-target qualification: 14 focused gates and 152 full-package tests per target; 25 negative probes; semantic comparison passed.

---

_Fixed: 2026-07-28T07:08:00Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
