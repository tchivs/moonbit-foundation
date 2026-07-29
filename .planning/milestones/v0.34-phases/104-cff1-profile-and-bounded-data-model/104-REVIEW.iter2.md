---
phase: 104-cff1-profile-and-bounded-data-model
reviewed: 2026-07-28T11:21:32Z
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
  critical: 7
  warning: 2
  info: 0
  total: 9
status: issues_found
---

# Phase 104: Code Review Report

**Reviewed:** 2026-07-28T11:21:32Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

The CFF1 parser, keying model, admission transaction, integration changes, and
their tests were reviewed at standard depth. The native font-package suite
passes (`181/181`), but the implementation still admits malformed CFF data,
rejects valid custom encodings, and performs attacker-driven parsing and
allocation before caller work/allocation authority is established. The passing
resource tests are partly circular and therefore do not detect the accounting
errors below.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Caller work and allocation authority is checked after the work has already happened

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_admission.mbt:635-713`
**Issue:** `cff_resolve_keying` builds charset, encoding, FDSelect, environment,
INDEX-offset, and per-GID descriptor arrays before `cff_admission_charge` is
calculated and before `ledger.preflight_atomic` checks the caller's work,
allocation-count, and allocation-size limits. Standalone admission only
preflights the source-byte dimension at lines 483-498; collection admission
skips even that prefix when `collection_charge` is true. An unaffordable hostile
font can therefore force the complete bounded parse and all retained-array
allocations before returning `BudgetExceeded`, defeating the resource boundary
the budget is meant to provide.

**Fix:** Add bounded discovery/preflight stages before every attacker-declared
count traversal or allocation (INDEX offsets, charset/Encoding expansion,
FDArray/FDSelect, local Subrs, and descriptors). Keep those checks
non-consuming, perform the final exact aggregate preflight after discovery, and
commit once only after the revision guard.

### CR-02: `allocation_size` is charged as a total instead of a per-allocation maximum

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_admission.mbt:344-347`
**Issue:** The charge sets `allocation_size` to `cff.length_value +
retained_bytes`. In the shared budget contract, `allocation_size` is a
per-operation/per-allocation ceiling, not a consumable total. The CFF table is a
retained `ByteView`, not one newly allocated buffer, and the retained arrays are
separate allocations. This formula can reject a caller that can afford every
actual allocation merely because the sum exceeds the largest-allocation limit;
the exact/one-less test then freezes that incorrect value as its oracle.

**Fix:** Calculate the checked size of each concrete allocation independently
(each offsets array, descriptor array, charset/encoding array, FD selector,
environment array, and so on) and charge the maximum single size. Keep total
retained bytes as a separate semantic ceiling if required.

### CR-03: Valid custom encodings with unencoded glyphs are rejected

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_keying.mbt:492-494`
**Issue:** Format 0 requires `nCodes == glyph_count - 1`, and format 1 repeats
the same equality check at lines 543-545. CFF custom encodings may encode only
some glyphs; glyphs omitted from the main encoding are explicitly unencoded.
Thus a font with three glyphs and one encoded non-`.notdef` glyph is valid, but
this parser returns `font-cff-encoding-cardinality`. The test fixture at
`cff_name_keyed_fixture_wbtest.mbt:45-46` incorrectly labels that valid shape as
`short_cardinality`.

**Fix:** Require the main encoding's produced GID count to be *at most*
`glyph_count - 1`, map its entries sequentially from GID 1, and leave remaining
glyphs unencoded. When supplements are present, also verify that each
supplemented SID resolves to a glyph already mentioned by the main encoding, as
required by the CFF supplement contract.

### CR-04: Structurally incomplete OpenType fonts pass CFF admission

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_admission.mbt:500-530`
**Issue:** After directory/checksum validation, admission requires only the
`CFF ` and `maxp` tables. It never requires or validates the common OpenType
tables that must be preserved for either outline format (`cmap`, `head`, `hhea`,
`hmtx`, `name`, `OS/2`, and `post`). The successful fixture builder confirms
the gap: `cff_admission_wbtest.mbt:80-85` constructs only `CFF `, `head`, and
`maxp`, and the tracer admits it. This violates the phase's explicit
"preserve existing common-table rules" boundary and allows an incomplete
OpenType face to be promoted as fully admitted CFF structure.

**Fix:** Factor the existing required-table validation into common-table and
outline-specific parts. CFF admission must require and validate the common
tables plus `CFF ` and maxp 0.5, while omitting only the glyf-specific
`glyf`/`loca` requirements.

### CR-05: Required Private DICTs are modeled and admitted as optional

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_keying.mbt:766-807`
**Issue:** `cff_decode_private_environment` treats a missing Private range as a
successful environment with `private_dict = None`. Name-keyed admission uses
that directly at lines 823-832, and CID admission accepts any Font DICT without
a Private operator at lines 974-999. CFF1 requires a Private DICT (a zero-length
Private DICT is the valid way to express all defaults), and each CID Font DICT
must identify its corresponding Private DICT. The current optional descriptor
can therefore publish malformed keying state to the future Type 2 VM.

**Fix:** Require `Top DICT.Private` for name-keyed fonts and
`Font DICT.Private` for every CID FD before descriptor construction. Accept
`size == 0` as a present default-valued Private DICT, but reject an absent
operator. Make the admitted environment non-optional once validated.

### CR-06: The DICT token parser accepts malformed real numbers and oversized operand stacks

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_dict.mbt:140-218`
**Issue:** The real-number state machine uses one `digit_seen` flag for both
mantissa and exponent, so an encoding such as `1E` followed by a terminator is
accepted as exponent zero. It also permits a minus sign in non-initial grammar
positions and, when a high nibble is `0xF`, silently ignores a non-`0xF` padding
nibble. Separately, `cff_parse_dict` at lines 342-385 never enforces CFF's
maximum of 48 operands before an operator. These malformed sequences can reach
typed admission instead of failing at the DICT boundary.

**Fix:** Implement an explicit mantissa/exponent grammar with separate
`mantissa_digit_seen` and `exponent_digit_seen` state, allow the sign only in
the legal initial position, validate full-byte `0xF` padding, and reject a 49th
pending operand before pushing it.

### CR-07: The “typed” DICT schemas validate arity but not operand types or domains

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_dict.mbt:599-624`
**Issue:** SID, boolean, integer, and generic number operators are grouped
together and checked only for one operand. For example, a negative/fractional
`FullName` SID or `isFixedPitch = 2` is accepted. `FontName` receives the same
arity-only handling at lines 706-710, and Private DICT booleans/numeric domains
at lines 777-788 are likewise unvalidated. Custom SIDs are never resolved
against the String INDEX for these operators. This contradicts the promised
separate typed schemas and lets malformed supported-profile structure pass.

**Fix:** Decode every known operator into its declared type: boolean must be
integer 0/1, SID must be a non-negative integer in the CFF SID domain and must
resolve after the String INDEX is available, offsets must use their named base,
and operator-specific bounded arrays/deltas must enforce their format limits.

## Warnings

### WR-01: Named structural counters do not measure the structures their names claim

**Classification:** WARNING
**File:** `modules/mb-font/font/cff_admission.mbt:648-675`
**Issue:** `fd_ranges` is assigned the expanded selector array length (glyph
count), not the number of format-3 ranges; `dict_units` is Top DICT byte length
plus FD count rather than the number of DICT tokens/operators; and
`header_bytes` is hard-coded to 4 even when `hdrSize` is larger. Allocation
count is similarly a fixed `12 + indexes.length()` at lines 413-417. These
values cannot support the stated exact per-structure ceilings or meaningful
one-less qualification.

**Fix:** Accumulate checked, format-specific counters during bounded discovery:
actual header extent, INDEX offsets/objects, decoded operands/operators,
format-3 range count, and each concrete retained allocation. Use those facts
both for semantic limits and the final charge.

### WR-02: Exact-budget tests use the production result as their expected-value oracle

**Classification:** WARNING
**File:** `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:158-173`
**Issue:** The test first admits the font, reads `admitted.charge`, and then
declares those same values to be the exact expected budget. The collection test
repeats this at `collection_wbtest.mbt:1227-1247`. Any systematic overcharge,
undercount, or wrong dimension semantics therefore passes. The structural
ceiling checks at lines 64-71 only assert `> 0`, so they also do not provide the
promised exact/one-less evidence.

**Fix:** Compute expected charges from independent fixture facts or checked
literal constants, then test exact and one-less values without first asking the
production parser for the answer. Add direct cases for every structural ceiling
and for affordable bytes with insufficient work/allocation authority before
parsing begins.

---

_Reviewed: 2026-07-28T11:21:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
