---
phase: 97-font-admission-and-metrics
fixed_at: 2026-07-26T23:33:29Z
review_path: .planning/phases/97-font-admission-and-metrics/97-REVIEW.md
iteration: 3
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 97: Code Review Fix Report

**Fixed at:** 2026-07-26T23:33:29Z
**Source review:** `.planning/phases/97-font-admission-and-metrics/97-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Admission still performs uncharged linear directory scans

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/directory.mbt`, `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** 3197fa6
**Applied fix:** Added a checked discovery preflight allowance for the four count-bearing table lookups performed before the final transaction. The final authoritative charge now conservatively includes all 27 linear table lookups plus the profile and checksum table-iteration overhead. Updated the exact/one-short work boundary and added a discovery-preflight one-short atomicity regression.

### CR-02: Valid format-0 name records for user-defined platforms are rejected

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** b4dcbad
**Applied fix:** Name admission now reads `platformID`. Format-1 high language IDs still require an in-range language-tag index, while format-0 high language IDs are accepted only for user-defined platforms 240 through 255. Added a positive platform-240 fixture and a negative registered-platform fixture with the same `0x8000` language ID.

## Verification

- `moon check --target all` passed for JS, Wasm, Wasm-GC, and native.
- The CR-01 exact, one-short, and discovery-preflight regression passed on all four targets.
- The CR-02 user-defined-platform regression and the existing strict name/post envelope regression passed on all four targets.
- Full JS, Wasm, and Wasm-GC suites each passed 1,040 of 1,040 tests.
- The full native suite exceeded the five-minute command window while still compiling; both focused native regressions passed.
- `policy/foundation.json` and `scripts/quality/Assert-Policy.ps1` parsed successfully.
- `Assert-FontFoundationPolicy -PolicyPath .\policy\foundation.json` passed, including generated interfaces and all four declared targets.

---

_Fixed: 2026-07-26T23:33:29Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
