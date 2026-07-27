---
phase: 97-font-admission-and-metrics
fixed_at: 2026-07-27T02:02:48Z
review_path: .planning/phases/97-font-admission-and-metrics/97-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 97: Code Review Fix Report

**Fixed at:** 2026-07-27T02:02:48Z
**Source review:** `.planning/phases/97-font-admission-and-metrics/97-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: Cmap admission validates byte counts but publishes malformed mappings

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** de3c3401
**Applied fix:** Added complete structural admission for supported format-4 and format-12 subtables: derived search fields, strict segment/group ordering, valid ranges, bounded nonzero `idRangeOffset` addressing, Unicode and glyph-cardinality bounds, and sorted unique encoding-record keys in explicitly supported platform/encoding domains. Count discovery now includes both encoding-record passes and every segment/group validation loop in the one aggregate work charge. Added checksummed hostile bodies, record-key/domain cases, and exact/one-short work coverage.

### CR-02: The post validator rejects valid uint16 indices and omits the version-1 glyph contract

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** 0ad8cedc
**Applied fix:** Removed the artificial 32767 glyph-name-index ceiling, retained checked traversal through the full 258..65535 custom-name domain, and validated every Pascal name against the 63-byte ASCII identifier contract. Split post 1.0 from 3.0 and required the standard 258-glyph cardinality for version 1.0. Replaced the former `0xFFFF` rejection with a fully backed high-index success and added invalid-character, overlength-name, and version-1/non-258 regressions.

### CR-03: Name admission never enforces canonical record ordering

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** f42ef277
**Applied fix:** Read all four name-record key fields and enforced nondecreasing lexicographic order by platform ID, encoding ID, language ID, then name ID. The selected profile explicitly permits duplicate keys while rejecting every decreasing key. Added a sorted success plus hostile encoding-only and name-ID-only inversions.

### WR-01: Deferred filesystem and FFI capabilities still have ordinary selector bypasses

**Status:** fixed
**Files modified:** `scripts/quality/Assert-Policy.ps1`
**Commit:** 2d306839
**Applied fix:** Extended normalized-token capability classification to catch split `file system`, expanded `foreign function interface`, and load/read/open/from verbs paired with file/path tokens. Added all six reported bypass spellings to the selector's fail-closed negative matrix.

## Verification

- `moon check --target all --deny-warn --frozen` passed on the final source state.
- `moon -C modules/mb-font test --target all --deny-warn --frozen` passed on wasm, wasm-gc, JS, and native with 1,044/1,044 tests on each target.
- Focused JS selectors passed for malformed cmap structures, exact cmap body work, post name references, and canonical four-part name ordering.
- `Assert-FoundationPolicy -PolicyPath policy/foundation.json` passed, including the font semantic-interface and embedded negative selectors.
- `Test-PolicyWorkingDirectory.ps1` passed the repository-root and foreign-working-directory policy branches.
- PowerShell AST parsing passed, and all six new filesystem/FFI fixtures were rejected while `max_cmap_records` remained accepted.
- Pinned `moonfmt.exe` equality passed for both modified MoonBit files; canonical-only changes are recorded in `d86e75b1`.
- `git diff --check` passed.

---

_Fixed: 2026-07-27T02:02:48Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
