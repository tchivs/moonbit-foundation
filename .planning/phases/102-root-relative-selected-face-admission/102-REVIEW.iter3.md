---
phase: 102-root-relative-selected-face-admission
reviewed: 2026-07-28T03:04:25Z
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
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 102: Code Review Report

**Reviewed:** 2026-07-28T03:04:25Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

CR-01 is closed: selected admission now carries one live deferred ledger through directory, profile/presence/checksum, cmap/kern discovery, and the remaining semantic/metric prefixes, with cumulative caller and ancestor preflights before each attacker-sized loop family and one final charge.

CR-02 is not closed. The replacement lexer correctly distinguishes comments from ordinary literals, but it erases MoonBit interpolation expressions even though those expressions are executable code. A forbidden operation can therefore remain hidden from the independent portable-source boundary.

Native white-box selection passed 13/13, public collection selection passed 31/31, the complete native font package passed 147/147, target-all checking passed, and the tracked policy gate passed. The policy gate's passing result is not evidence against the finding because its negative probes omit interpolation.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-02: BLOCKER — MoonBit interpolation still bypasses the portable-source policy

**File:** `D:/AI-Data/temp/Admin/mnf-phase100-exec/scripts/quality/Assert-Policy.ps1:1250-1265`

**Issue:** In `string` and `character` state, every backslash plus following character is replaced with spaces. MoonBit double-quoted strings and byte strings execute expressions inside `\{...}` interpolation. The scanner therefore removes the executable expression together with literal text. A valid source such as:

```moonbit
fn forbidden_probe() {
  let hidden = "\{rasterize_font()}"
}
```

is normalized to whitespace where `rasterize_font()` appeared, and `Assert-FontPortableSourceBoundary` accepts it. The same construction can hide FFI/native, filesystem, GUI, shaping, hinting, CFF, or rasterization calls. This preserves the security/policy bypass from the original CR-02 through a different lexical edge.

**Fix:** Give interpolation its own lexer state. When a string or bytes literal sees `\{`, retain or recursively scan the interpolation expression as executable code until its matching `}`, then resume the surrounding literal state. Handle interpolated `$|` multiline strings under the same rule while keeping raw `#|` lines non-executable. Add negative probes for every forbidden category inside both string and bytes interpolation, plus an allowed literal escape case, and require `Assert-FontPortableSourceBoundary` to reject the executable probes.

---

_Reviewed: 2026-07-28T03:04:25Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
