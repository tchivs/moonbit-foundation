---
phase: 102-root-relative-selected-face-admission
reviewed: 2026-07-28T02:37:15Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - modules/mb-font/font/collection.mbt
  - modules/mb-font/font/directory.mbt
  - modules/mb-font/font/font.mbt
  - modules/mb-font/font/kern.mbt
  - modules/mb-font/font/tables.mbt
  - modules/mb-font/font/collection_test.mbt
  - modules/mb-font/font/collection_wbtest.mbt
  - modules/mb-font/font/font_test.mbt
  - policy/foundation.json
  - scripts/quality/Assert-Policy.ps1
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 102: Code Review Report

**Reviewed:** 2026-07-28T02:37:15Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

The selected-face implementation preserves root-relative table offsets, collection checksum semantics, final revision guarding, and a single deferred charge, but it does not enforce the promised caller/ancestor work authority before every attacker-sized loop. The independent policy classifier also has a lexical bypass that can hide forbidden executable source. Both defects must be fixed before shipping.

The complete native `mb-font/font` suite passed 146/146 from an external target directory; the passing suite does not exercise either defect.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: BLOCKER — Selected admission performs attacker-sized loops before caller budget authority

**File:** `D:/AI-Data/temp/Admin/mnf-phase100-exec/modules/mb-font/font/font.mbt:141-185`

**Affected code:** `directory.mbt:592`, `directory.mbt:873`, and `tables.mbt:1382-1535,1694-1919`

**Issue:** `font_open_collection_face` parses the selected directory, scans every selected table checksum, admits cmap/name/post semantics, and builds the metric index before the exact `budget.preflight` at line 185. The deferred ledger only stages caller preflights for cmap record/format-4 discovery and kern counts. It does not authorize the directory record/overlap loop, checksum loop, format-12 group validation, format-4 mapping validation, name/language record loops, post glyph/custom-name loops, or later glyph/loca/metric loops before they execute.

Consequently, a caller or live ancestor with insufficient work can still be forced to perform attacker-declared traversal up to the much larger `FontLimits.max_work` ceiling before receiving `BudgetExceeded`. This violates D-10 and Plan 102-02's explicit requirement that every dependent loop cumulatively preflight the real caller/ancestors, weakening the resource boundary into a denial-of-service path. The existing exact/one-short tests assert only the final error and unchanged counters, so they cannot detect that the work already ran without authority.

**Fix:**

Thread the deferred ledger through every selected admission stage and preflight the cumulative prefix before each attacker-sized loop. At minimum, cover directory record/overlap processing, selected-table checksum work, cmap format-4 and format-12 validation/mapping, name and language records, post glyph/custom-name bytes, and glyph/loca/metric scans. Keep these collection preflights non-consuming, then retain the existing exact aggregate preflight, final revision guard, and single charge. Add a test hook/counter proving a deliberately short caller or ancestor fails before entering each dependent loop.

### CR-02: BLOCKER — Portable-source policy can be bypassed with comment markers inside strings

**File:** `D:/AI-Data/temp/Admin/mnf-phase100-exec/scripts/quality/Assert-Policy.ps1:1167-1175`

**Issue:** `Get-FontExecutableSourceText` removes block and line comments before removing string literals. The comment regexes therefore interpret `/*`, `*/`, or `//` contained inside a valid MoonBit string as real comments. For example, string literals containing `/*` and a later `*/` can cause the sanitizer to delete all intervening executable source, including a forbidden FFI, native, filesystem, shaping, hinting, or rasterization token, before `Assert-FontPortableSourceBoundary` scans it. This makes the supposedly independent fail-closed policy boundary bypassable by source formatting.

**Fix:**

Replace the regex pipeline with a small stateful MoonBit lexical scanner that distinguishes code, line comments, block comments, byte/string literals, character literals, and escapes, emitting only executable tokens. Add negative fixtures with comment delimiters inside strings surrounding each representative forbidden token and require the policy gate to reject them. Do not merely reverse the regex order, because quote-like text inside comments creates the inverse ambiguity.

---

_Reviewed: 2026-07-28T02:37:15Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
