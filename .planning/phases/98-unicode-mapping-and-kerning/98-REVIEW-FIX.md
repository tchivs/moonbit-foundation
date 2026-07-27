---
phase: 98-unicode-mapping-and-kerning
fixed_at: 2026-07-27T08:42:01.147Z
review_path: .planning/phases/98-unicode-mapping-and-kerning/98-REVIEW.md
iteration: 2
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 98: Code Review Fix Report

**Fixed at:** 2026-07-27T08:42:01.147Z
**Source review:** `.planning/phases/98-unicode-mapping-and-kerning/98-REVIEW.md`
**Iteration:** 2

**Summary:**

- Iteration 2 findings in scope: 1
- Iteration 2 fixed: 1
- Cumulative findings in scope: 4
- Cumulative fixed: 4
- Skipped: 0

## Fixed Issues

### CR-98-002 (iteration-2 CR-01): Malformed `cmap` discovery scans bypass the authoritative shared work budget

**Fix status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/kern.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** `4f916918`
**Applied fix:** Encoding-record work is now preflighted and committed immediately before the record loop. Each format-4 segment scan separately compares full cumulative work against `max_work`, preflights only its still-uncharged base and current segment count against the shared budget, and commits that segment count before traversal. Kern admission now receives distinct cumulative and shared-budget bases. Successful aggregate admission subtracts all precharged cmap and kern discovery work, preserving exact-once total charging.
**Verification:** Added repeated malformed late-record and late-segment opens over shared budgets, plus one-short semantic and shared-budget preflight cases. They prove cumulative work deductions, no charge for a rejected scan, byte/allocation atomicity, and unchanged Data/InvalidEncoding or Resource/BudgetExceeded taxonomy. The full font package passed 65/65 on each supported target.

### CR-98-001 (CR-01): Malformed `kern` scans bypass the authoritative shared work budget

**Fix status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/kern.mbt`, `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** `1d2fb155`
**Applied fix:** Preflighted subtable and pair work is now committed immediately before each attacker-declared scan. Pair admission compares the full cumulative work against `max_work` while preflighting only the uncharged remainder against the shared budget. The successful aggregate charge subtracts already-committed work, preserving exact-once accounting. Bytes and allocations remain transactional, error taxonomy is unchanged, and repeated malformed last-pair opens now prove cumulative deductions from one shared budget.
**Verification:** Full native font package passed 63/63 before commit. Final independent package runs passed 63/63 on each of `native`, `js`, `wasm`, and `wasm-gc`, using unique external target directories and `--no-parallelize`.

### WR-98-001 (WR-01): The policy gate accepts stale public module descriptions

**Files modified:** `modules/mb-font/moon.mod.json`, `scripts/quality/Assert-Policy.ps1`
**Commit:** `5bb88f20`
**Applied fix:** Updated the font manifest to the governed Phase 98 description and added a case-sensitive exact manifest-description assertion to the generic module policy checks.
**Verification:** JSON exact comparison passed and `Assert-FontFoundationPolicy -PolicyPath policy/foundation.json` verified policy, dependency, publication, documentation, target, source, and semantic-interface selection.

### WR-98-002 (WR-02): The root status still identifies the shipped v0.27 line as active

**Files modified:** `README.md`
**Commit:** `d5597d55`
**Applied fix:** Updated the English and Chinese status sections to identify v0.32 TrueType Font Foundation as active and v0.27 as completed history.
**Verification:** Scoped bilingual assertions confirmed both v0.32 active-line statements, exactly two historical v0.27 mentions, and no stale v0.27 active-line wording. The module literate README check passed on all four supported targets.

## Session Verification

- `moon -C modules/mb-font test font --target <target> --frozen --target-dir <unique-external-dir> --no-parallelize`: 65/65 passed independently on `native`, `js`, `wasm`, and `wasm-gc`.
- `moon -C modules/mb-font check README.mbt.md --target <target> --frozen --target-dir <unique-external-dir>`: passed on all four targets.
- `moon -C modules/mb-font info --target all --frozen --target-dir <unique-external-dir>`: passed; generated interface SHA-256 remained `f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade`.
- `Assert-FontFoundationPolicy -PolicyPath policy/foundation.json`: passed.
- `git diff --check`: passed.
- The unscoped Required lane was intentionally not run because of the documented Windows `mb-image/png` stall.

---

_Fixed: 2026-07-27T08:42:01.147Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
