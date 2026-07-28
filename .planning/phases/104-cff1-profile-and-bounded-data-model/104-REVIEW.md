---
phase: 104-cff1-profile-and-bounded-data-model
reviewed: 2026-07-28T12:29:47Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - modules/mb-font/font/cff_admission_wbtest.mbt
  - modules/mb-font/font/cff_admission.mbt
  - modules/mb-font/font/cff_cid_fixture_wbtest.mbt
  - modules/mb-font/font/cff_dict_wbtest.mbt
  - modules/mb-font/font/cff_dict.mbt
  - modules/mb-font/font/cff_hostile_fixture_wbtest.mbt
  - modules/mb-font/font/cff_index_wbtest.mbt
  - modules/mb-font/font/cff_index.mbt
  - modules/mb-font/font/cff_keying_wbtest.mbt
  - modules/mb-font/font/cff_keying.mbt
  - modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt
  - modules/mb-font/font/collection_test.mbt
  - modules/mb-font/font/collection_wbtest.mbt
  - modules/mb-font/font/directory.mbt
  - modules/mb-font/font/font_test.mbt
  - modules/mb-font/font/font_wbtest.mbt
  - modules/mb-font/font/font.mbt
  - modules/mb-font/font/limits.mbt
  - modules/mb-font/font/tables.mbt
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 104: Code Review Report

**Reviewed:** 2026-07-28T12:29:47Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

The exact original 19-file scope was reviewed after the iteration-2 fixes.
The package suite passes (`191/191`) and `moon check --target all` passes.
StemSnap arity, the exclusive SID/String INDEX bound, unsupported Top DICT
operators, concrete predefined/custom allocation maxima, Encoding supplement
capacity, named structural counters, and the existing public glyf path are
implemented without a new functional regression in the reviewed scope.

The result is still not shippable. Lookup work is counted only after the lookup
traversals have run, so a short caller budget can be rejected at the final
preflight after unauthorized keying work. The new common-table path also drops
the format-4 search-work term that the shared TrueType admission path already
charges. Two tests advertised as boundary/authority regressions do not exercise
those missing boundaries.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: SID/CID lookup traversal still precedes caller work authority

**Classification:** BLOCKER
**Files:** `modules/mb-font/font/cff_admission.mbt:1353-1357`,
`modules/mb-font/font/cff_admission.mbt:1448-1475`,
`modules/mb-font/font/cff_admission.mbt:1513-1595`,
`modules/mb-font/font/cff_keying.mbt:465-480`,
`modules/mb-font/font/cff_keying.mbt:609-632`,
`modules/mb-font/font/cff_keying.mbt:989-1000`,
`modules/mb-font/font/cff_keying.mbt:1092-1104`

**Issue:** The staged Encoding preflight authorizes `num_glyphs` for a
predefined Encoding or the retained entry count for a custom Encoding. It does
not authorize the lookup work later recorded in `sid_cid_lookups`. For example,
StandardEncoding always scans all 256 source slots and performs 149 nonzero SID
lookups, while the one-glyph path preflights only one Encoding work unit before
entering that loop. Custom supplements perform two counted operations per
supplement, and ROS, Top DICT, and Font DICT SID validations likewise run before
their counts are known to the final charge. The aggregate is constructed only
at lines 1513-1521 and enforced by `preflight_atomic` at lines 1589-1595, after
all of those traversals. A caller short by one of these work units therefore
receives `BudgetExceeded`, but only after the supposedly unauthorized work has
already happened.

**Fix:** Preflight each lookup group before entering it and keep the staged
ledger equal to the final exact charge. In particular:

```moonbit
// After decoding a DICT, before resolving its retained SIDs.
authority.preflight(sid_operands.length().to_uint64(), 0UL, 0UL)?

// Custom Encoding framing already exposes the supplement count.
let lookup_work = checked_mul(supplement_count, 2UL)?
authority.preflight(main_iteration_work + supplement_count + lookup_work, 0UL, 0UL)?

// CID ROS has two known validations.
authority.preflight(2UL, 0UL, 0UL)?
```

For predefined Encodings, compute and preflight both the fixed 256-entry source
scan and the known nonzero-SID lookup count before `cff_predefined_encoding`.
Add those same terms to `cff_admission_charge`; do not rely on the final atomic
preflight to retroactively authorize work.

### CR-02: CFF format-4 common-table work omits the search loop

**Classification:** BLOCKER
**Files:** `modules/mb-font/font/cff_admission.mbt:420-502`,
`modules/mb-font/font/cff_admission.mbt:636-657`,
`modules/mb-font/font/tables.mbt:1130-1161`,
`modules/mb-font/font/tables.mbt:1335-1358`,
`modules/mb-font/font/tables.mbt:1383-1391`

**Issue:** The CFF common-table preflight accumulates cmap record discovery,
format-4 segment discovery, body records, and mapping spans, but never adds
`font_cmap_search_selector(facts.body_records)`. The semantic decoder calls
`font_cmap_search_facts`, whose loop computes the canonical search parameters.
The existing shared TrueType admission path explicitly retains and charges this
as `CmapAdmissionWork.search_work`; the new CFF duplicate omits it from both the
staged authority ledger and `common_table_work`. Any CFF fixture with at least
two format-4 segments is therefore undercharged, and its published “exact”
work/one-short boundary is wrong.

**Fix:** Reuse the shared cmap declared-work facts if possible. Otherwise add a
checked `cmap_search_work` accumulator:

```moonbit
cmap_search_work = checked_add(
  cmap_search_work,
  font_cmap_search_selector(facts.body_records),
)?
```

Include it in the semantic preflight and the returned `common_table_work`, then
update the exact final charge. Add a CFF format-4 fixture with at least two
segments and assert both the corrected exact work and exact-minus-one failure.

## Warnings

### WR-01: Authority regressions probe common decoders but not keying lookups

**Classification:** WARNING
**File:** `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:187-223`,
`modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:228-283`

**Issue:** The one-short work test asserts only the eventual Resource result and
unchanged budget. The only traversal callback added by iteration 2 is invoked at
the three common-table decoder entries. Consequently the tests pass when keying
and SID/CID lookup loops run before the final work rejection, which is exactly
the CR-01 failure.

**Fix:** Add observable probes or precedence fixtures at the predefined
Encoding, custom supplement, and CID ROS/Font DICT lookup boundaries. For a
budget short at each boundary, assert the relevant lookup probe remains zero,
not merely that the budget was not committed.

### WR-02: The predefined Encoding allocation path has no one-short test

**Classification:** WARNING
**File:** `modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt:245-305`

**Issue:** The test proves that predefined and custom Encodings both succeed at
2048 bytes, but the 2047-byte rejection is exercised only against the custom
supplement fixture. It therefore proves that the predefined path is not
overcharged above 2048, but does not prove that its 2048-byte source-array
allocation cannot be undercharged. This does not satisfy the fix report's claim
that exact/one-short coverage exists for both paths.

**Fix:** Re-run the `predefined` fixture with `allocation_size=2047`, assert a
Resource/`allocation_size` error, and assert bytes, allocations, and work remain
unchanged, mirroring the custom case.

---

_Reviewed: 2026-07-28T12:29:47Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
