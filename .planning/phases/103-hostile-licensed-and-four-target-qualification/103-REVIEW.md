---
phase: 103-hostile-licensed-and-four-target-qualification
reviewed: 2026-07-28T06:07:19Z
depth: deep
files_reviewed: 18
files_reviewed_list:
  - .github/workflows/quality.yml
  - docs/policies/licensing-and-fixtures.md
  - fixtures/font/collection-qualification-cases.json
  - fixtures/font/dejavu-sans-2.37/DejaVuSans-two-face-v1.ttc
  - fixtures/font/dejavu-sans-2.37/collection-oracle.json
  - fixtures/manifest.json
  - modules/mb-font/CHANGELOG.md
  - modules/mb-font/README.mbt.md
  - modules/mb-font/font/collection_wbtest.mbt
  - modules/mb-font/font/font_qualification_hostile_test.mbt
  - modules/mb-font/font/font_qualification_test.mbt
  - modules/mb-font/font/generated_font_qualification_test.mbt
  - modules/mb-font/moon.mod.json
  - policy/foundation.json
  - scripts/fixtures/Generate-FontQualification.ps1
  - scripts/quality/Assert-Policy.ps1
  - scripts/quality/Invoke-FontQualification.ps1
  - scripts/quality/Test-FontQualificationEvidenceBoundary.ps1
findings:
  critical: 6
  warning: 2
  info: 0
  total: 8
status: resolved
resolved: 2026-07-28T07:08:00Z
fix_report: 103-REVIEW-FIX.md
---

# Phase 103: Code Review Report

**Reviewed:** 2026-07-28T06:07:19Z  
**Depth:** deep  
**Files Reviewed:** 18  
**Status:** resolved

## Resolution

All eight findings were addressed and verified on 2026-07-28.

| Finding | Resolution | Commit |
|---|---|---|
| CR-01 | Replaced ID-derived placeholder outcomes with explicit runtime facts; regenerated the canonical corpus, manifest identity, generated MoonBit, and semantic policy digest. | `16980ffe` |
| CR-02 | Bound runtime errors to generated rows field-for-field; directly executes collection limits, selected limit/open or constructor boundaries, checked pair overflow, caller budgets, and ancestor success/failure accounting. | `bbe59b7e` |
| CR-03 | Closed every nested evidence section against canonical values, enforced failed-budget atomicity, and added permanent nested drift probes. | `0bb1f297` |
| CR-04 | Added immediate write-boundary revalidation, exclusive same-directory staging, durable flush, atomic publication, read-back validation, and post-initialization link-swap regressions. | `700687ed` |
| CR-05 | Added executable-token and container-magic flow guards plus independently locked production and negative-contract semantic digests. | `4708a5b1` |
| CR-06 | Added a fail-closed structural workflow parser requiring one exact lane and one success-only upload, with all requested negative probes. | `449e913e` |
| WR-01 | Closed, read back, and hash-validated `comparison.json`. | `d7e69d9f` |
| WR-02 | Bound the evidence payload to all eight focused test/helper sources and exact repository commit/tree identity. | `d4eea58d` |

Verification passed for the generator check, policy/negative contracts, evidence-boundary link-swap suite, native hostile and white-box focused tests, and the complete four-target runner: four records, fourteen focused gates per target, 152 full-package tests per target, 25 negative probes, and semantic hash `b60b515ab2015973e28230ce1ebf06e7d4596d21de678125e527be845b0d941b`.

Implementation boundaries are explicit: the portable filesystem implementation rejects completed swaps before I/O and minimizes, but cannot mathematically eliminate, an adversarial swap in the final path-validation-to-create window without platform-specific handle-relative APIs. The capability policy uses locked executable-token/magic-flow analysis because no MoonBit AST facility is available in this toolchain. The workflow parser is intentionally a fail-closed parser for the repository's allowed YAML subset, not a general YAML implementation.

## Summary

The Phase 103 fixture bytes and provenance identities are reproducible, but the qualification boundary is not trustworthy enough to ship. The canonical case corpus contains structured outcomes that contradict the runtime assertions, the focused “closed matrix” test does not execute much of that matrix, and both evidence validators accept semantic drift. The path and policy guards also have demonstrated bypasses.

Read-only validation confirmed that `Generate-FontQualification.ps1 -Check` and `Test-FontQualificationEvidenceBoundary.ps1` pass in the current tree. Separate adversarial probes demonstrated all of the following accepted states:

- removal of `standalone_baseline.public_facts.compact.units_per_em`;
- a drifted generated fixture ID and hostile error context;
- a non-atomic failure `budget_after`;
- an extra shared-coordinate key;
- a post-initialization junction swap that redirected `js.json` outside the managed evidence root;
- executable `decode_type2_charstring`, `inflate_sfnt_container`, and `apply_gvar_deltas` declarations;
- a second `actions/upload-artifact` step guarded by `always()`.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: The canonical collection corpus records false structured outcomes

**Classification:** BLOCKER  
**File:** `scripts/fixtures/Generate-FontQualification.ps1:1301-1454`  
**Issue:** The generator manufactures generic error facts instead of freezing the runtime contract it claims to represent. Nineteen hostile rows use the case ID as `error.context` (`$context = $id`), although the runtime tests expect contexts such as `font-collection-header`. The face-index row records category `Input`, code `InvalidInput`, and operation `font-collection-face`, while the executable test expects category `InvalidInput`, code `InvalidRange`, and operation `font-collection-open-face`. Profile-selection rows and mutation rows likewise record operations that differ from their tests. Every limit row uses placeholder `requested=1` and `limit=0/1`, even where the executable assertions require values such as `88/87`, `5/4`, or `440/439`.

These false values are committed in `fixtures/font/collection-qualification-cases.json` (for example lines 414 and 1174), copied into generated MoonBit, and published unchanged in every target evidence record.

**Fix:** Replace the generic loops with an explicit per-case table containing the exact category, code, operation, context, source offset, requested value, limit, publication state, and budget snapshots. Make the runtime dispatcher consume those same rows and compare every field. Regenerate the corpus, manifest digest, generated source, and v2 evidence only after the corrected rows pass.

### CR-02: The “closed matrix” test can pass without executing the locked cases

**Classification:** BLOCKER  
**File:** `modules/mb-font/font/font_qualification_hostile_test.mbt:376-409`  
**Issue:** `font_collection_qualification_assert_ids` checks IDs and a few non-empty fields, then explicitly ignores `face_index`, `source_offset`, `requested`, and `limit`. Runtime behavior is exercised later by unrelated hand-written examples rather than by dispatching each generated case. Consequently, the test passes despite CR-01's false corpus.

Coverage is also incomplete: the hostile dispatcher never executes `collection-checked-pair-work-overflow`; the selected-limit section only exercises a source-bytes one-short failure (`lines 1054-1074`) rather than the 14 exact/one-short selected `FontLimits` families; and the ancestor section exercises only one-short bytes/work failures (`lines 1020-1052`), not the two ancestor exact-success rows. The focused test at lines 1078-1083 still reports one passing identity and is accepted as proof for all 97 rows.

**Fix:** Implement one exhaustive dispatcher over `font_collection_qualification_cases()`. Each case must build its declared fixture and authority, invoke its declared entry point, and compare all error fields, publication state, and all eight caller/ancestor budget fields. Fail if any ID lacks a dispatcher branch. Add direct executions for checked pair-work overflow, every selected limit exact/one-short boundary, and ancestor exact successes.

### CR-03: Target-record and independent-policy validators accept nested semantic drift

**Classification:** BLOCKER  
**File:** `scripts/quality/Invoke-FontQualification.ps1:423-629`  
**Issue:** `Assert-FontQualificationEvidenceRecord` closes only selected container keys and counts. It does not close or validate the nested public facts, fixture identities, generated fixture/workflow IDs, shared-coordinate records, hostile error values, or budget atomicity. Direct probes against the committed `js.json` record were all accepted after:

- removing `compact.units_per_em`;
- replacing a generated fixture ID;
- replacing a hostile error context;
- changing a failed case's `budget_after.work`;
- adding a key to a shared-table coordinate.

The independent corpus policy repeats the defect: `Assert-FontCollectionCorpusContract` checks the fixture schema only on `fixtures[0]` and otherwise checks schemas/counts/ID digest, not semantic values or budget atomicity (`scripts/quality/Assert-Policy.ps1:1534-1629`). It accepted a missing key on the second fixture, hostile-context drift, and non-atomic budget drift.

**Fix:** Define recursive ordered schemas for every target-record object and array element, including public facts, all fixture facts, generated IDs, coordinate/profile records, every case field, and comparison records. Validate exact ordered ID/value tables and require every failure's complete before/after snapshots to match. Add a negative probe for every nested section, for missing/reordered keys as well as extra keys and value drift.

### CR-04: A symlink/junction swap after initialization escapes the evidence root

**Classification:** BLOCKER  
**File:** `scripts/quality/Invoke-FontQualification.ps1:1132-1155`  
**Issue:** Containment and reparse checks occur during initialization and cleanup, but the runner then spends the target-test interval without holding or revalidating the directory. Record writes at line 1310 and the comparison write at line 1108 call `WriteAllText` without another containment/link check. Replacing the initialized child directory with a junction before a write redirected `js.json` into an outside directory (`ESCAPED_WRITE_ACCEPTED`) in a safe temporary reproduction.

**Fix:** Re-resolve and revalidate the managed root, every directory component, ownership marker, and destination immediately before each write, read-back, and hash. Prefer creating a fresh staging directory using non-following/handle-based filesystem primitives, writing all known files there, and atomically renaming it only after validation. Extend the boundary test with a post-initialization link swap before target-record and comparison writes.

### CR-05: The portable-source policy is a name filter, not a capability boundary

**Classification:** BLOCKER  
**File:** `scripts/quality/Assert-Policy.ps1:1472-1488`  
**Issue:** Deferred capabilities are rejected only when function/module names contain a small regex vocabulary. A temporary MoonBit source containing the semantically explicit declarations `decode_type2_charstring`, `inflate_sfnt_container`, and `apply_gvar_deltas` was accepted (`POLICY_BYPASS_ACCEPTED`), although these correspond to CFF Type 2 execution, WOFF/SFNT inflation, and variable-font execution respectively. The exact source inventory and public-interface lock do not prevent an implementation from being added inside an existing production file under neutral names.

**Fix:** Replace name-based regex classification with a compiler/AST-backed rule set and immutable behavioral capability tests. Preserve and inspect executable tag/magic constants and call/data flow so `CFF `, `CFF2`, `wOFF`, `wOF2`, `fvar`, `gvar`, and their execution paths cannot be hidden by renaming. Lock the content or semantic digest of the negative capability tests so coordinated test weakening is detected independently.

### CR-06: CI policy accepts an additional failing-evidence upload

**Classification:** BLOCKER  
**File:** `scripts/quality/Assert-Policy.ps1:1696-1734`  
**Issue:** `Assert-FontQualificationWorkflowContract` proves only that one expected success-only upload block exists. It does not require exactly one `upload-artifact` use in the job or reject additional upload steps. Adding a second pinned upload of the same evidence directory with `if: ${{ always() }}` was accepted (`EXTRA_ALWAYS_UPLOAD_ACCEPTED`), defeating the promised “never upload failing evidence” boundary.

**Fix:** Parse the workflow as YAML and select the `font-qualification` job structurally. Require exactly one upload step, exactly one `actions/upload-artifact` use, the exact `success()` condition, artifact name/path, and no other step that uploads or copies the evidence directory. Add negative probes for a second upload step, an aliased path, job-level `continue-on-error`, and a second FontQualification job under another key.

## Warnings

### WR-01: `comparison.json` is neither closed nor read back

**Classification:** WARNING  
**File:** `scripts/quality/Invoke-FontQualification.ps1:1099-1108`  
**Issue:** Target records are read back and passed to a validator, but `comparison.json` is written and returned without a comparison-schema validator or read-back. This contradicts the plan's closed/read-back-validated comparison contract and leaves corruption, key drift, or post-write redirection undetected before upload.

**Fix:** Add `Assert-FontQualificationComparisonRecord` with exact ordered keys, target order, four record hashes, one semantic hash, exact normalization list, and `equal=true`. Read the file back, validate it, and verify its hashes against the just-read target files before declaring success.

### WR-02: Evidence does not bind all focused test sources

**Classification:** WARNING  
**File:** `scripts/quality/Invoke-FontQualification.ps1:411-425`  
**Issue:** Evidence hashes `font_qualification_test.mbt` and `font_qualification_hostile_test.mbt`, but focused gates also rely on `font_test.mbt`, `collection_wbtest.mbt`, and `font_wbtest.mbt` (plus shared helpers in `collection_test.mbt`). The record stores only their names and pass summaries. Those tests can be weakened under the same names without changing the semantic evidence payload or any recorded source digest.

**Fix:** Include a closed ordered source-identity section covering every file that supplies a focused assertion or helper, plus the exact module commit/tree identity. Validate those hashes before running tests and retain them in semantic comparison.

---

_Reviewed: 2026-07-28T06:07:19Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: deep_
