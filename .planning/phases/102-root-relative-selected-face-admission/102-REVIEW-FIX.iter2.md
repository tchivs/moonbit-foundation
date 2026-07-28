---
phase: 102-root-relative-selected-face-admission
fixed_at: 2026-07-28T02:53:46Z
review_path: .planning/phases/102-root-relative-selected-face-admission/102-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 102: Code Review Fix Report

**Fixed at:** 2026-07-28T02:53:46Z
**Source review:** `.planning/phases/102-root-relative-selected-face-admission/102-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### CR-01: Selected admission performs attacker-sized loops before caller budget authority

**Files modified:** `modules/mb-font/font/collection.mbt`, `modules/mb-font/font/collection_wbtest.mbt`, `modules/mb-font/font/directory.mbt`, `modules/mb-font/font/font.mbt`, `modules/mb-font/font/tables.mbt`
**Commit:** `8195a491e2ddb678dd21ac6921788d1cdbea8064`
**Status:** fixed: requires human verification
**Applied fix:** Extended the non-consuming deferred ledger across selected directory, profile/presence/checksum, count-discovery, and exact semantic/metric prefixes; removed an unaccounted selected-extent traversal; retained the final revision guard and single aggregate charge; and added caller/ancestor stage-hook regression coverage proving one-short authority fails before loop entry.

### CR-02: Portable-source policy can be bypassed with comment markers inside strings

**Files modified:** `scripts/quality/Assert-Policy.ps1`
**Commit:** `a89f013f3056b53f2d1a482f6277f68a084d4202`
**Applied fix:** Replaced the ordered regex sanitizer with a fail-closed single-pass MoonBit lexical scanner for code, line comments, nested block comments, byte/string literals, character literals, and escapes. Added negative probes for every forbidden source category with comment delimiters inside strings, plus line-comment and inverse quote-in-comment cases.

---

_Fixed: 2026-07-28T02:53:46Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
