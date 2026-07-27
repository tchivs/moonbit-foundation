---
phase: 97-font-admission-and-metrics
fixed_at: 2026-07-27T02:26:30Z
review_path: .planning/phases/97-font-admission-and-metrics/97-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 97: Code Review Fix Report

**Fixed at:** 2026-07-27T02:26:30Z
**Source review:** `.planning/phases/97-font-admission-and-metrics/97-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Format-4 cmap admission still publishes glyph IDs outside `maxp`

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** 240214e6
**Applied fix:** Evaluated both format-4 mapping formulas for every non-sentinel character. Zero remains the missing glyph; every nonzero direct-delta or indexed/delta-adjusted result must be below `maxp.numGlyphs`. Added checksum-correct negatives for both mapping paths plus exact last-valid-glyph positives in a two-glyph font.

### CR-02: Nontrivial format-4 validation performs uncharged attacker-driven work

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/font.mbt`, `modules/mb-font/font/font_test.mbt`
**Commits:** 15b056af, 3a58d1eb
**Applied fix:** Added cumulative non-mutating preflights before cmap record and format-4 segment discovery. The one atomic charge now includes encoding-record passes, body validation, exact pre-charge segment discovery, search-helper iterations, and every direct/indexed mapping iteration, including repeated work for distinct records sharing a subtable. Pre-charge discovery now enforces the same ordering invariants so malformed inputs retain deterministic data-envelope errors. Added exact and one-short work tests for single-record and shared-subtable format 4.

### WR-01: Filesystem and FFI policy enforcement remains trivially aliasable

**Status:** fixed
**Files modified:** `scripts/quality/Assert-Policy.ps1`
**Commit:** a18e7349
**Applied fix:** Added an explicit Phase 97 reviewed-surface allowlist independent from `policy/foundation.json`, so coordinated policy and implementation edits cannot introduce an unclassified public line. Broadened token defense for system-font, font-file/source, disk/URI, native/extern/foreign-call, bindings, C ABI, adapter, and bridge concepts. Added all seven reported aliases to the fail-closed negative matrix.

## Verification

- `moon check --target all --deny-warn` passed for wasm, wasm-gc, JS, and native.
- `moon test --target all --deny-warn -p tchivs/mb-font/font` passed 37/37 tests on each of wasm, wasm-gc, JS, and native.
- Focused native tests passed for format-4 glyph cardinality, exact traversal budgets, and malformed-body classification.
- `Assert-FontFoundationPolicy -PolicyPath policy/foundation.json` passed from repository root.
- `scripts/quality/Test-PolicyWorkingDirectory.ps1` passed the fallback and real font policy selectors from a foreign working directory.
- PowerShell AST parsing and `git diff --check` passed.

---

_Fixed: 2026-07-27T02:26:30Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
