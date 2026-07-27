---
phase: 97-font-admission-and-metrics
fixed_at: 2026-07-27T02:44:21Z
review_path: .planning/phases/97-font-admission-and-metrics/97-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 97: Code Review Fix Report

**Fixed at:** 2026-07-27T02:44:21Z
**Source review:** `.planning/phases/97-font-admission-and-metrics/97-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Format-4 terminal mappings bypass glyph cardinality validation

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** d8d947ac
**Applied fix:** Removed the terminal-segment exemption from direct and indexed format-4 mapping validation. The terminal one-character span is now included in mapping work, and checksum-correct tests cover invalid direct/indexed terminal mappings plus the final valid glyph.

### CR-02: Cmap discovery can exceed `FontLimits.max_work` before enforcing it

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/tables.mbt`, `modules/mb-font/font/font_test.mbt`
**Commit:** 3d724111
**Applied fix:** Threaded the semantic `max_work` ceiling through cumulative cmap discovery preflights. Record and format-4 segment loops now reject with the semantic `max-work` diagnostic before exceeding the ceiling, without mutating the caller-owned budget. Added ample-budget one-short tests at both discovery boundaries.

### CR-03: Directory search-fact traversal is absent from the work ledger

**Status:** fixed: requires human verification
**Files modified:** `modules/mb-font/font/directory.mbt`, `modules/mb-font/font/font_test.mbt`, `modules/mb-font/font/font_wbtest.mbt`
**Commit:** c2fcaa49
**Applied fix:** Replaced the attacker-count-driven directory selector loop with a constant-time bounded power/selector helper and added the exact selector work to the authoritative directory ledger. Discovery preflight and final charge now share that value. Updated exact/one-short admission expectations and added selector boundary tests around 1, 2, 4, and 8 tables.

## Skipped Issues

None.

## Verification

- `moon check --target all --deny-warn` passed for Wasm, Wasm-GC, JavaScript, and native.
- `moon test --target all --deny-warn -p tchivs/mb-font/font` passed 39/39 tests on each of Wasm, Wasm-GC, JavaScript, and native.
- Per-finding native font suites passed after each atomic fix.
- `git diff --check` passed for every finding.

---

_Fixed: 2026-07-27T02:44:21Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
