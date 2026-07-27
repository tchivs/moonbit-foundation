---
phase: 101-collection-contract-and-bounded-envelope
reviewed: 2026-07-27T22:26:41Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - modules/mb-font/font/collection.mbt
  - modules/mb-font/font/collection_limits.mbt
  - modules/mb-font/font/collection_parser.mbt
  - modules/mb-font/font/collection_test.mbt
  - modules/mb-font/font/collection_wbtest.mbt
  - policy/foundation.json
  - scripts/quality/Assert-Policy.ps1
findings:
  critical: 3
  warning: 2
  info: 0
  total: 5
status: issues_found
---

# Phase 101: Code Review Report

**Reviewed:** 2026-07-27T22:26:41Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

The public facade and checked range helpers are generally structured defensively, but the implementation does not yet enforce its work authority before attacker-controlled traversal. Two related accounting defects let a collection consume substantially more work than the accepted `max_work` and caller `Budget` charge. The parser also accepts a malformed zero-length table record that violates the package's established alignment rule. Test and policy gates leave important security branches and exact-interface invariants insufficiently protected.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01 [BLOCKER]: Work authority is checked only after all bounded and quadratic traversals finish

**File:** `modules/mb-font/font/collection_parser.mbt:1988-2039`

**Issue:** `font_collection_parse` performs every face scan, protected-range pair comparison, table-by-protected comparison, unordered table-pair comparison, and DSIG block-pair comparison before calling `font_collection_retained_charge`, where `max_work` is finally compared, and before `Budget::preflight`. Consequently, `max_work=1` or a one-unit caller work budget does not prevent any of the declared `C2(P)`, `R*P`, `C2(R)`, or `C2(N)` work from executing. With caller-authorized but hostile counts this is a CPU denial-of-service and directly violates the phase contract that exact work authority precede pair traversal.

**Fix:** Split DSIG declaration/count parsing from DSIG block traversal, compute the complete checked work charge as soon as `F`, `R`, `P`, `S`, and `N` are known, compare it with `limits.max_work()`, and preflight the caller budget before entering structural/pair loops. Alternatively, use a checked work meter that reserves the complete charge before traversal and never performs an operation before its authority is established.

#### CR-02 [BLOCKER]: The advertised exact work charge omits the second full directory/table scan

**File:** `modules/mb-font/font/collection_parser.mbt:2042-2065`

**Issue:** Normalization calls `font_collection_scan_face` again for every face. That helper rereads the directory header, search fields, and every table record and repeats ordering, range, alignment, and profile work. However, `font_collection_exact_work` accounts for normalization only as `1 + face_count + protected_count` at lines 1835-1849; it does not include the repeated per-record scan. A successful open therefore consumes more work than the supposedly exact value charged to `Budget`, and the discrepancy grows with table count.

**Fix:** Preserve the compact `CollectionFaceFacts` produced by the authorized structural pass and move them into the retained array without rescanning untrusted bytes. If rescanning is intentional, add its complete face/record cost to the formula and preflight that larger value before either scan.

#### CR-03 [BLOCKER]: Zero-length tables bypass mandatory table-offset alignment

**File:** `modules/mb-font/font/collection_parser.mbt:1615`

**Issue:** Alignment is rejected only when `table_length > 0`. A zero-length record with an in-range offset such as `97` is therefore admitted even though the established SFNT parser applies the four-byte table-offset rule unconditionally. Empty ranges should be excluded from overlap checks, but emptiness does not make a malformed offset aligned. This creates divergent standalone-versus-collection admission semantics and accepts invalid TTC directory records.

**Fix:**

```moonbit
if table_offset % 4UL != 0UL {
  return Err(
    font_collection_data_error(
      "font-collection-table-alignment",
      source_offset=record_offset + 8UL,
    ),
  )
}
```

Add a black-box case with `length=0` and a misaligned in-bounds offset and assert `Data/InvalidEncoding`.

### Warnings

#### WR-01 [WARNING]: DSIG pairwise containment and overlap branches have no executable tests

**File:** `modules/mb-font/font/collection_test.mbt:948-1145`

**Issue:** Every DSIG fixture declares exactly one signature. The white-box suite checks only the arithmetic formula and likewise never opens a two-record DSIG. As a result, the security-sensitive `earlier_index < current_index` overlap loop, touching-block acceptance, out-of-order disjoint blocks, and multi-record outer-end behavior are untested despite the phase plan and summary claiming a complete block-pair matrix.

**Fix:** Add generated two-record DSIG fixtures covering disjoint/touching blocks, partial and exact overlap, a block entering the complete record array, non-monotonic but disjoint offsets, trailing gaps, and exact `max_dsig_records`/`max_work` boundaries. Assert both the precise error fields and unchanged budget.

#### WR-02 [WARNING]: The “independent” public-surface gate checks membership, not the required interface

**File:** `scripts/quality/Assert-Policy.ps1:989-1073`

**Issue:** `Assert-FontPhase101Surface` stores approved lines in a `HashSet` and only rejects lines outside that set. It does not independently reject missing approved declarations, duplicates, or reordering. The JSON golden and generated-interface comparison catch ordinary drift, but a coordinated policy/implementation edit can weaken or reorder the contract while still passing this purportedly independent gate, particularly if the fixed line count is preserved.

**Fix:** Keep the approved declarations in one ordered array and call `Assert-ExactSequence` against `InterfaceLines`. Retain the forbidden-pattern checks as defense in depth, and add negative fixtures for a removed method, a duplicated approved line, and reordered declarations.

---

_Reviewed: 2026-07-27T22:26:41Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
