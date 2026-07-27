---
phase: 99-simple-and-composite-outlines
reviewed: 2026-07-27T11:17:02Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - README.md
  - modules/mb-font/CHANGELOG.md
  - modules/mb-font/README.mbt.md
  - modules/mb-font/font/font.mbt
  - modules/mb-font/font/font_test.mbt
  - modules/mb-font/font/font_wbtest.mbt
  - modules/mb-font/font/generated_fonts_wbtest.mbt
  - modules/mb-font/font/limits.mbt
  - modules/mb-font/font/metrics.mbt
  - modules/mb-font/font/moon.pkg
  - modules/mb-font/font/outline.mbt
  - modules/mb-font/font/tables.mbt
  - policy/foundation.json
  - scripts/quality/Assert-Policy.ps1
findings:
  critical: 4
  warning: 1
  info: 0
  total: 5
status: issues_found
---

# Phase 99: Code Review Report

**Reviewed:** 2026-07-27T11:17:02Z  
**Depth:** standard  
**Files Reviewed:** 14  
**Status:** issues_found

## Summary

The public outline coordinator, fixed-point lowering, policy surface, documentation, and tests were reviewed against the Phase 99 context and all three plans. The native package suite passes 87/87 and the exact font policy gate passes, but the composite parser still rejects valid OpenType encodings, accepts one malformed metadata placement, and undercharges caller-authorized allocations. A private 324-line duplicate composite implementation also remains compiled solely for a white-box test.

The four Critical findings are correctness and hostile-input/resource-contract failures and must be fixed before shipping.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Instructions are incorrectly forbidden on non-final component records

**Classification:** BLOCKER  
**File:** `D:/AI-Data/temp/Admin/mnf-phase99-exec/modules/mb-font/font/outline.mbt:1238-1240,1409-1448`  
**Issue:** The parser rejects `WE_HAVE_INSTRUCTIONS` whenever `MORE_COMPONENTS` is also set, then decides whether to read the composite instruction block solely from `last_flags`. OpenType 1.9.1 explicitly permits `WE_HAVE_INSTRUCTIONS` to be set on any component; the instruction length and bytes still follow the last component. A conforming composite with the flag on an earlier record is therefore returned as malformed Data even though it is valid. The generated matrices never cover this placement, so all tests remain green.

**Fix:**

```moonbit
let mut saw_instructions = false
// Do not reject WE_HAVE_INSTRUCTIONS together with MORE_COMPONENTS.
if (flags & 0x0100UL) != 0UL {
  saw_instructions = true
}
// After the last component:
if saw_instructions {
  // Read, limit, charge, and skip the instruction envelope once.
}
```

Add public fixtures with the flag on the first of multiple records, on the last record, and absent.

### CR-02: Flags that OpenType says to ignore for point attachment reject valid composites

**Classification:** BLOCKER  
**File:** `D:/AI-Data/temp/Admin/mnf-phase99-exec/modules/mb-font/font/outline.mbt:1250-1258,1631-1633`  
**Issue:** For point-number placement (`ARGS_ARE_XY_VALUES` clear), OpenType specifies that `SCALED_COMPONENT_OFFSET`, `UNSCALED_COMPONENT_OFFSET`, and `ROUND_XY_TO_GRID` are ignored. The parser instead returns Data for either offset flag and records grid rounding unconditionally, which later returns Capability. Valid point-attached glyphs carrying these irrelevant bits cannot be outlined. This also contradicts the phase contract's placement-specific offset semantics.

**Fix:**

```moonbit
if (flags & 0x1800UL) == 0x1800UL {
  return Err(font_outline_data_error("font-outline-component-offset-flags"))
}
if xy && (flags & 0x0004UL) != 0UL {
  saw_grid_rounding = true
}
// A single offset-policy bit is acted on only for ComponentXY;
// for ComponentPoints it is ignored.
```

Add fixtures for point attachment with each ignored flag and verify the same geometry as the unflagged record.

### CR-03: `OVERLAP_COMPOUND` is accepted on later component records

**Classification:** BLOCKER  
**File:** `D:/AI-Data/temp/Admin/mnf-phase99-exec/modules/mb-font/font/outline.mbt:1226-1265`  
**Issue:** The parser treats `OVERLAP_COMPOUND` as neutral wherever it appears. The pinned OpenType contract requires this bit, when used, to be set on the first component record. A later record with bit `0x0400` is malformed but currently passes graph classification and publishes geometry. Existing coverage tests only the valid first-record placement.

**Fix:**

```moonbit
let is_first = descriptors.length() == 0
if (flags & 0x0400UL) != 0UL && !is_first {
  return Err(font_outline_data_error("font-outline-overlap-compound"))
}
```

Add a two-component negative fixture with `OVERLAP_COMPOUND` only on the second record and require a Data error with no path publication.

### CR-04: The authoritative Budget undercounts scratch allocations

**Classification:** BLOCKER  
**File:** `D:/AI-Data/temp/Admin/mnf-phase99-exec/modules/mb-font/font/outline.mbt:516,615-619,664,684,1474-1492,1634-1635`  
**Issue:** Simple decoding creates separate endpoint, flag, x-coordinate, and point arrays, but charges only one scratch allocation, after the endpoint array has already been created. Composite decoding similarly creates `parent_points` and `parent_endpoints` without any allocation preflight. The public exact-fit test consequently authorizes only two allocations for a simple path even though the implementation creates several scratch arrays plus the output command array. This bypasses the caller's authoritative allocation-count ceiling and violates D-18's requirement to preflight and charge scratch/output allocations before allocation.

**Fix:** Pre-compute and preflight the complete scratch plan before creating any array, then either:

- charge each actual array allocation and conservative maximum allocation size; or
- consolidate the temporary representation into a deliberately precharged scratch allocation.

Move the endpoint allocation after that preflight, cover composite accumulation arrays, and update exact-fit/one-short tests to reflect the real allocation count. Add zero-allocation and one-short allocation-count cases, not only work-limit cases.

## Warnings

### WR-01: A second composite decoder is dead production code tested as if it were live

**Classification:** WARNING  
**File:** `D:/AI-Data/temp/Admin/mnf-phase99-exec/modules/mb-font/font/outline.mbt:857-1181`; `D:/AI-Data/temp/Admin/mnf-phase99-exec/modules/mb-font/font/font_wbtest.mbt:231-262`  
**Issue:** `font_decode_tracer_composite_outline` is a 324-line duplicate implementation suppressed with `#warnings("-1")`. Its only caller is the white-box test named “directly verified production slice”; `Font::outline` uses `font_decode_composite_outline` instead. Fixes can diverge between the two implementations, and the direct tracer test can stay green while the public production path is broken.

**Fix:** Remove the duplicate function and route the test through `Font::outline`, or refactor genuinely shared parsing/placement helpers used by the single production implementation. Do not suppress the unused-function warning for a test-only shadow decoder.

---

_Reviewed: 2026-07-27T11:17:02Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
