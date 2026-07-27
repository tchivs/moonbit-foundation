---
phase: 97-font-admission-and-metrics
fixed_at: 2026-07-27T00:25:53Z
review_path: .planning/phases/97-font-admission-and-metrics/97-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 97: Code Review Fix Report

**Fixed at:** 2026-07-27T00:25:53Z
**Source review:** `.planning/phases/97-font-admission-and-metrics/97-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: Deferred-capability gate misses compound PascalCase and camelCase identifiers

**Status:** fixed
**Files modified:** `scripts/quality/Assert-Policy.ps1`
**Commit:** 6b4a9611
**Applied fix:** Normalized camelCase, PascalCase, and acronym-to-word identifier boundaries before applying the deferred-capability denylist. Expanded shape, hint, and raster noun-form matching, including `rasterizer`. Added fail-closed fixtures for `GlyphOutline`, `CmapLookup`, `FontRasterizer`, `Font::cmapLookup`, and `Font::openFile` while preserving the allowed `max_cmap_records` policy field.

### WR-02: Policy checks invoke Moon relative to the process working directory

**Status:** fixed
**Files modified:** `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Test-PolicyWorkingDirectory.ps1`
**Commit:** 1f5509dc
**Applied fix:** Anchored QOI, font, and PNG `moon -C` invocations to absolute module paths derived from the script-owned repository root. Anchored the QOI generated-interface fallback to the same root and added a regression that runs all three policy selectors from a temporary foreign working directory.

## Verification

- PowerShell AST parsing passed for both policy scripts.
- Focused deferred-capability fixtures rejected compound PascalCase/camelCase APIs while accepting the legitimate `max_cmap_records` field.
- QOI, font, and PNG policy/interface selectors passed when invoked from the repository root.
- `Test-PolicyWorkingDirectory.ps1` passed when launched from `C:\Windows\Temp`; all three selectors generated and compared interfaces successfully from a foreign caller cwd.
- `moon -C modules/mb-font check --target all --deny-warn --frozen` passed for JS, Wasm, Wasm-GC, and native.
- An additional full `moon -C modules/mb-font test --target all --frozen` run exceeded the ten-minute execution window without emitting a failure; its owned process was terminated and it was not used as the acceptance gate for these policy-only fixes.

---

_Fixed: 2026-07-27T00:25:53Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
