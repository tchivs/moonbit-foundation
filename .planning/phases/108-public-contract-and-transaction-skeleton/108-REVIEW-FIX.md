---
phase: 108-public-contract-and-transaction-skeleton
fixed_at: 2026-07-29T23:56:13Z
review_path: .planning/phases/108-public-contract-and-transaction-skeleton/108-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 108: Code Review Fix Report

**Fixed at:** 2026-07-29T23:56:13Z
**Source review:** `.planning/phases/108-public-contract-and-transaction-skeleton/108-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: FontQualification omits the implementation and tests of the public transaction API

**Status:** fixed
**Files modified:** `scripts/quality/Invoke-FontQualification.ps1`, `scripts/quality/Assert-Policy.ps1`, `policy/foundation.json`
**Commit:** cf2eee3a
**Applied fix:** Added `shape_transaction.mbt` and both transaction test files to the qualification source inventories and evidence identities, synchronized the public interface count at 89, regenerated all affected policy file facts, and added explicit negative identity probes for each newly bound source.

### WR-01: Generated run projection can publish a foreign-font GlyphId

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-text/text/shape.mbt`, `modules/mb-text/text/contract_wbtest.mbt`
**Commit:** fbda171e
**Applied fix:** Bound every generated glyph to the active font through the existing mb-font horizontal-metrics owner check before projection, with a distinct same-range font regression proving rejection before publication or budget charge.

### WR-02: Cluster staging accepts indices outside the request and reports internal corruption as caller input

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-text/text/shape.mbt`, `modules/mb-text/text/contract_wbtest.mbt`
**Commit:** ac34057f
**Applied fix:** Passed the validated scalar snapshot length into cluster projection, rejected empty and out-of-range generated indices as `Data/InvalidEncoding` under the stable `text-shape-project` / `cluster-source` context, and covered empty, exact-last, one-past, and mixed-index cases with unchanged budgets on rejection.

### WR-03: mb-text publication metadata deliberately permits a missing README declaration

**Status:** fixed
**Files modified:** `modules/mb-text/moon.mod.json`, `scripts/quality/Assert-Policy.ps1`, `policy/foundation.json`
**Commit:** 731bce82
**Applied fix:** Declared `README.mbt.md` in the mb-text manifest, removed the module-specific missing-README exception, and regenerated the validator's qualification-tool identity.

## Verification

- PASS — focused foreign-font and cluster-bound regression tests.
- PASS — native mb-text package: 19/19.
- PASS — js, wasm, wasm-gc, and native mb-text package: 19/19 per target.
- PASS — FontQualification contract-only negative matrix.
- PASS — Foundation and font policy validation, with only the documented pre-existing CFF warnings.
- PASS — full FontQualification: 4 targets, 4 records, semantic SHA-256 `086d75dc24084f6747cc9faf95c73b37e10ba1d48f6e9b6d0add9efdf8e35099`.

---

_Fixed: 2026-07-29T23:56:13Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
