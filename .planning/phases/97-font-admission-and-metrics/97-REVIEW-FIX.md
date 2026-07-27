---
phase: 97-font-admission-and-metrics
fixed_at: 2026-07-27T01:02:05Z
review_path: .planning/phases/97-font-admission-and-metrics/97-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 97: Code Review Fix Report

**Fixed at:** 2026-07-27T01:02:05Z
**Source review:** `.planning/phases/97-font-admission-and-metrics/97-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: The post-name ceiling is enforced only after the budget transaction

**Status:** fixed
**Files modified:** `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** 313472e0
**Applied fix:** Enforced `max_post_name_bytes` during admission-charge derivation, before the aggregate work calculation and authoritative budget transaction. Added an exact-limit success and one-short rejection that verifies the rejected caller budget retains its bytes, allocations, allocation-size, and work dimensions.

### WR-01: Compound deferred-capability names still bypass the policy selector

**Status:** fixed
**Files modified:** `scripts/quality/Assert-Policy.ps1`
**Commit:** 94b7afcb
**Applied fix:** Normalized `CMap` acronym spellings to the protected `cmap` token and rejected ordered `open`/`file` and `from`/`path` token co-occurrence even when a domain token occurs between them. Added the reported `CMapLookup`, `openFontFile`, and `fromFontPath` bypasses to the negative fixture matrix.

### WR-02: The real interface-checker branch remains foreign-CWD dependent

**Status:** fixed
**Files modified:** `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Invoke-MoonQuality.ps1`, `scripts/quality/Test-PolicyWorkingDirectory.ps1`
**Commit:** cc511884
**Applied fix:** Rooted the production generated-interface checker against an explicit or script-derived repository root, passed the selector-owned root through the QOI and font production branches, and added a library-mode import that lets the foreign-CWD regression exercise both local fallback and real production checker branches.

## Verification

- `moon check --target all --deny-warn --frozen` passed for the mb-font module.
- Full mb-font/workspace tests passed independently on all supported targets: wasm, wasm-gc, JS, and native each reported 1,041/1,041 tests passing.
- The focused post-name exact/one-short test passed on wasm, wasm-gc, JS, and native.
- PowerShell AST parsing passed for `Assert-Policy.ps1`, `Invoke-MoonQuality.ps1`, and `Test-PolicyWorkingDirectory.ps1`.
- The three reported deferred-capability fixtures were rejected while the legitimate `max_cmap_records` interface remained accepted.
- QOI and font selectors passed from the repository root through both fallback and production interface-checker branches.
- `Test-PolicyWorkingDirectory.ps1` passed from a temporary foreign working directory, covering QOI/font fallback and production branches plus the PNG selector.

---

_Fixed: 2026-07-27T01:02:05Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
