---
phase: 102-root-relative-selected-face-admission
fixed_at: 2026-07-28T03:17:01Z
review_path: .planning/phases/102-root-relative-selected-face-admission/102-REVIEW.md
iteration: 2
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 102: Code Review Fix Report

**Fixed at:** 2026-07-28T03:17:01Z
**Source review:** `.planning/phases/102-root-relative-selected-face-admission/102-REVIEW.md`
**Iteration:** 2

**Summary:**

- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-02: MoonBit interpolation still bypasses the portable-source policy

**Files modified:** `scripts/quality/Assert-Policy.ps1`
**Commit:** `d8dccd6ca3715e3c9bff6428acb287b36c34d6c7`
**Status:** fixed: requires human verification
**Applied fix:** Added executable interpolation frames to the MoonBit source lexer so ordinary string, bytes, and `$|` multiline interpolation expressions remain policy-visible while literal string, character, comment, escaped interpolation, and raw `#|` text remain non-executable. Matching braces, nested literals/interpolations, nested block comments, malformed newlines, and unterminated interpolation fail closed. Added string and bytes interpolation negatives for every forbidden source category, plus multiline, nesting, comment-brace, escape, and raw-literal regressions.

## Verification

- PowerShell parser: passed.
- Full `Assert-FoundationPolicy`: passed.
- Selected white-box tests: 13/13 passed.
- Public collection tests: 31/31 passed.
- Full native font package: 147/147 passed.
- `moon -C modules/mb-font check --target all --frozen`: passed.
- `git diff --check`: passed.
- CR-01 source remained unchanged and its focused/full regressions passed.

---

_Fixed: 2026-07-28T03:17:01Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
