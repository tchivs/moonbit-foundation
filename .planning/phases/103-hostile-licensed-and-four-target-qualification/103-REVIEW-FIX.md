---
phase: 103-hostile-licensed-and-four-target-qualification
fixed_at: 2026-07-28T07:27:54Z
review_path: .planning/phases/103-hostile-licensed-and-four-target-qualification/103-REVIEW.md
iteration: 3
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 103: Code Review Fix Report

**Fixed at:** 2026-07-28T07:27:54Z
**Source review:** `.planning/phases/103-hostile-licensed-and-four-target-qualification/103-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-06: Quoted continuation keys bypass the prerequisite-step guard

**Files modified:** `scripts/quality/Assert-Policy.ps1`, `scripts/quality/Invoke-FontQualification.ps1`
**Commit:** `052d6fa4`
**Status:** fixed: requires human verification
**Applied fix:** The restricted workflow parser now unquotes and normalizes YAML mapping keys before fail-closed comparison, closes checkout and installer steps to exact schemas, and rejects quoted/cased/spaced continuation keys at job and every step level. The policy toolchain declaration is locked to its existing exact values. Runtime capture and every evidence record must match the identity derived from that policy; mutually consistent unauthorized substitutions are rejected.

## Exact Toolchain Gate

- Moon: `moon 0.1.20260713 (75c7e1f 2026-07-13)`
- moonc: `moonc v0.10.4+2cc641edf (2026-07-15)`
- moonrun: `moonrun 0.1.20260713 (75c7e1f 2026-07-13)`

## Verification

- Baseline workflow: accepted.
- Quoted continuation matrix: 16/16 job, prerequisite, runner, and upload variants rejected.
- Cased/spaced continuation variants: rejected.
- Policy Moon/moonc/moonrun substitution probes: rejected.
- Captured local toolchain identity: exact gate passed.
- Mutually consistent four-record unauthorized toolchain substitution: rejected.
- PowerShell parse checks: passed.
- Full foundation policy and permanent negatives: passed.
- Complete four-target qualification: 14 focused gates and 152 package tests per target; 29 evidence negatives; comparison passed.
- Semantic hash: `af508a8c549bc5ebbeb4710960e2eabb7978dacbf4059e3efe0c83da4259f8d4`.

---

_Fixed: 2026-07-28T07:27:54Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
