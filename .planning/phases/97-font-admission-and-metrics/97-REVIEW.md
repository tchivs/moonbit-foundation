---
phase: 97-font-admission-and-metrics
reviewed: 2026-07-26T22:22:18Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - modules/mb-font/CHANGELOG.md
  - modules/mb-font/font/cursor.mbt
  - modules/mb-font/font/directory.mbt
  - modules/mb-font/font/font_test.mbt
  - modules/mb-font/font/font_wbtest.mbt
  - modules/mb-font/font/font.mbt
  - modules/mb-font/font/limits.mbt
  - modules/mb-font/font/metrics.mbt
  - modules/mb-font/font/moon.pkg
  - modules/mb-font/font/tables.mbt
  - modules/mb-font/moon.mod.json
  - modules/mb-font/README.mbt.md
  - policy/foundation.json
  - scripts/quality/Assert-Policy.ps1
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 97: Code Review Report

**Reviewed:** 2026-07-26T22:22:18Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The new font module establishes a narrow public surface and consistently uses checked table-local reads, but the trusted admission boundary is incomplete. The shared budget is consulted only after attacker-driven directory work and does not include later count-driven allocation/validation. In addition, malformed `cmap`, format-1 `name`, and version-2 `post` references can pass `Font::open` and be published as admitted facts. The policy selector also has a blind spot that can hide deferred capabilities added to the limits constructor.

The native test command did not complete within the 60-second review window and remained in native compilation, so no passing test result is claimed.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01: Admission performs and undercharges attacker-driven work outside the authoritative budget

**Classification:** BLOCKER

**File:** `D:/AI-Data/temp/Admin/mnf-260726-sss-exec-118e99a5514745129bd6e2559fb7f13d/modules/mb-font/font/font.mbt:104-121`

**Issue:** `Font::open` fully parses the directory before calling `Budget::charge`, so a budget that is known to be too small still permits the record scan and the construction of the directory arrays. The eventual charge declares `allocations=0` and derives `work` only as `source.length() * 2 + num_tables` (`directory.mbt:400-409`). After that charge, admission allocates `loca_offsets` (`metrics.mbt:110-150`) and performs glyph-, cmap-, and name-count-driven loops, including a full glyph-header pass (`metrics.mbt:422-431`), without charging those allocations or work. A caller can therefore supply an allocation budget of zero and only `2 * source bytes + table count` work yet successfully trigger all of these allocations and scans; the public exact-budget test at `font_test.mbt:917-936` currently codifies that undercharge. This bypasses the caller-owned authoritative resource boundary and leaves hostile input able to consume substantially more work and memory than the shared budget authorizes.

**Fix:**

Preflight the directory scan against `budget.remaining()` before entering any count-driven loop, then derive one checked aggregate charge that includes every later declared-count scan and retained array allocation. Commit that charge before allocating or iterating:

```mbt
let total_work = checked_directory_work
  |> checked_add(num_glyphs)
  |> checked_add(cmap_record_count)
  |> checked_add(name_record_count)
  |> checked_add(language_record_count)
let index_bytes = checked_mul(num_glyphs + 1UL, 8UL)

budget.charge(
  @budget.ResourceCharge::new(
    bytes=source.length(),
    allocations=3UL,
    allocation_size=index_bytes,
    width=0UL,
    height=0UL,
    pixels=0UL,
    work=total_work,
  ),
)
```

If the one-transaction contract prevents committing until all counts are known, add a non-mutating budget preflight helper or conservatively preflight each bounded discovery stage against `remaining()` before doing the work, while retaining one final atomic commit.

#### CR-02: Malformed cmap records can point into the cmap header and still be admitted

**Classification:** BLOCKER

**File:** `D:/AI-Data/temp/Admin/mnf-260726-sss-exec-118e99a5514745129bd6e2559fb7f13d/modules/mb-font/font/tables.mbt:288-400`

**Issue:** `font_admit_cmap_envelope` verifies only that a referenced offset has enough bytes to read a format and length and that the declared positive length ends within the table. It never requires the subtable to begin after the encoding-record array, never rejects a zero-record cmap, never restricts the format to a structurally supported format, and never verifies that the declared length is at least the format's own header. For a one-record cmap, setting the subtable offset to `0` makes the outer version bytes look like format 0 and the outer record count look like a declared subtable length of 1; `length != 0` and `end <= table.length_value` both pass. `Font::open` can therefore publish a malformed required cmap as admitted, breaking the invariant later cmap code is intended to rely on.

**Fix:**

Reject `record_count == 0`, require each subtable offset to be at least `records_end`, accept only explicitly supported structural formats, and validate a per-format minimum header length before accepting the checked subrange. Shared subtables may reuse the same valid checked range, but none may alias the cmap header or record directory.

#### CR-03: Required name and post tables do not validate their referenced string envelopes

**Classification:** BLOCKER

**File:** `D:/AI-Data/temp/Admin/mnf-260726-sss-exec-118e99a5514745129bd6e2559fb7f13d/modules/mb-font/font/tables.mbt:404-555`

**Issue:** Format-1 `name` admission checks that the language-tag record array fits before string storage, but it never reads each language-tag record's length/offset pair or proves that the referenced string lies within the table. A record with an out-of-range relative offset is accepted. Similarly, post version 2.0 admission verifies only the glyphNameIndex array size and treats every remaining byte as bounded custom-name data; it never validates glyph name indices or the Pascal-string sequence they reference. A glyphNameIndex of `0xFFFF` with no custom strings passes when the table ends immediately after the index array. These are malformed required tables, yet the public `Font` is published as fully admitted.

**Fix:**

For name format 1, iterate all language-tag records and checked-validate `storage + relative + length <= table.length_value`, just as ordinary name records are validated. For post 2.0, validate every glyphNameIndex and parse the required number of bounded Pascal strings, rejecting missing, truncated, or unreferenced malformed suffixes. For post 2.5 and fixed-size versions, enforce their version-specific exact envelope instead of treating arbitrary trailing bytes as custom-name storage.

### Warnings

#### WR-01: Deferred-capability policy scan skips the entire FontLimits constructor

**Classification:** WARNING

**File:** `D:/AI-Data/temp/Admin/mnf-260726-sss-exec-118e99a5514745129bd6e2559fb7f13d/scripts/quality/Assert-Policy.ps1:1053-1055`

**Issue:** To permit `max_cmap_records`, the selector removes the whole `FontLimits::new` semantic-interface line from the deferred-capability scan. If a future policy and generated interface add a forbidden constructor parameter such as an outline, filesystem, or host-discovery option, the exact-interface comparison can still agree with the modified policy and this leak guard will not see the forbidden term. The gate therefore does not enforce its stated Phase 98+ boundary for one of the public API's most extensible lines.

**Fix:** Scan the complete constructor after removing only the specifically allowed identifier, for example by replacing `max_cmap_records` with an empty string before applying `$deferredLeakPattern`. Add a negative fixture that injects a forbidden constructor parameter and proves the selector rejects it.

---

_Reviewed: 2026-07-26T22:22:18Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
