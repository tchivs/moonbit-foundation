---
phase: 98-unicode-mapping-and-kerning
reviewed: 2026-07-27T08:19:33Z
depth: deep
files_reviewed: 14
files_reviewed_list:
  - modules/mb-font/font/cmap.mbt
  - modules/mb-font/font/kern.mbt
  - modules/mb-font/font/tables.mbt
  - modules/mb-font/font/directory.mbt
  - modules/mb-font/font/font.mbt
  - modules/mb-font/font/limits.mbt
  - modules/mb-font/font/font_test.mbt
  - modules/mb-font/font/font_wbtest.mbt
  - modules/mb-font/font/generated_fonts_wbtest.mbt
  - modules/mb-font/README.mbt.md
  - CHANGELOG.md
  - policy/foundation.json
  - scripts/quality/Assert-Policy.ps1
  - README.md
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 98: Code Review Report

**Reviewed:** 2026-07-27T08:19:33Z
**Depth:** deep
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The review traced the new `cmap` and `kern` admission/query paths through
`Font::open`, shared-budget accounting, source revision guards, public tests,
generated fixtures, policy metadata, and the quality gate. The native font
suite passes all 62 tests and the font policy gate passes, but those checks
preserve or miss one resource-accounting bypass and two repository metadata
defects. The budget bypass is release-blocking because malformed fonts can
repeatedly perform attacker-sized scans without consuming the caller's
authoritative shared work budget.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01: Malformed `kern` scans bypass the authoritative shared work budget

**Classification:** BLOCKER

**File:** `modules/mb-font/font/kern.mbt:338-381`

**Related:** `modules/mb-font/font/font.mbt:117-121`,
`modules/mb-font/font/font_test.mbt:1266-1288`,
`modules/mb-font/font/font_test.mbt:1315-1384`

**Issue:** `font_admit_kern_bounded` only calls
`font_preflight_admission_work` before traversing the attacker-declared
subtable and pair counts. The mutating `budget.charge(admission.charge)` does
not occur until the entire admission helper returns successfully. A malformed
last subtable or last format-0 pair therefore makes the parser perform nearly
the maximum allowed scan, returns a data error, and leaves the caller-owned
`Budget` unchanged. The tests explicitly require this unchanged-budget
behavior for malformed envelopes and supported pairs. Repeating the same
hostile open defeats the shared budget's purpose: `max_work` bounds each
attempt, but the authoritative budget does not bound cumulative work. This
also violates Phase 98 decision D-13, which requires every attacker-declared
subtable and pair scan to be charged before its consuming loop.

**Fix:** Charge the subtable work immediately before
`font_kern_classic_envelope` and charge the pair work immediately before
`font_kern_format0_facts`, subtracting those amounts from the final successful
admission charge to avoid double charging. If successful admission must remain
transactional for bytes and allocations, add a work reservation/commit API
whose consumed work remains charged when later semantic validation fails.
Change the malformed-envelope and malformed-pair tests to assert that work
actually consumed by a scan is deducted, while bytes and allocations may
remain unchanged.

### Warnings

#### WR-01: The policy gate accepts stale public module descriptions

**Classification:** WARNING

**File:** `policy/foundation.json:2184`

**Related:** `scripts/quality/Assert-Policy.ps1:802-817`,
`modules/mb-font/moon.mod.json:4`

**Issue:** The policy now describes deterministic Unicode mapping and legacy
horizontal kerning, while the publishable `moon.mod.json` description still
advertises only admission and named metrics. The generic manifest checks
compare name, version, license, readme, targets, and dependencies, but never
compare `description`. Consequently `Assert-FontFoundationPolicy` passes even
though the public registry metadata is stale, so future capability additions
can drift the same way unnoticed.

**Fix:** Update `modules/mb-font/moon.mod.json` to the policy description and
add an exact assertion such as
`Assert-Condition ($manifest.description -ceq $module.description)` alongside
the existing manifest drift checks. Consider checking `repository` there as
well if it is intended to be governed metadata.

#### WR-02: The root status still identifies the shipped v0.27 line as active

**Classification:** WARNING

**File:** `README.md:24-29`

**Related:** `README.md:127-131`, `.planning/PROJECT.md:13-21`,
`.planning/STATE.md:3-4`

**Issue:** Both English and Chinese status sections say the active/current
line is v0.27, although the project state identifies v0.32 TrueType Font
Foundation as the current milestone and Phase 98 is part of it. This is not
merely historical prose: it is the repository's public current-status
statement, so contributors and consumers are directed to the wrong active
workstream.

**Fix:** Update both status paragraphs to name v0.32 TrueType Font Foundation
as the active line. Refer to v0.27 as a completed or shipped milestone if that
history is still useful.

---

_Reviewed: 2026-07-27T08:19:33Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
