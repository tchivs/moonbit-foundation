---
phase: 104-cff1-profile-and-bounded-data-model
reviewed: 2026-07-28T11:59:38Z
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
  critical: 5
  warning: 2
  info: 0
  total: 7
status: issues_found
---

# Phase 104: Code Review Report

**Reviewed:** 2026-07-28T11:59:38Z
**Depth:** standard
**Files Reviewed:** 19
**Status:** issues_found

## Summary

The exact original 19-file scope was re-reviewed after the iteration-1 fixes.
The focused native font-package suite passes (`189/189`). Required common-table
presence, required name/CID Private DICTs, partial custom Encodings, Encoding
supplement membership, malformed-real rejection, and the 48-operand DICT limit
are now enforced.

The fixes are not shippable yet. Common OpenType table traversal still happens
before caller work authority is established; `allocation_size` remains both
overcharged and under-preflighted; the typed DICT schema still accepts invalid
SID operands and silently discards unsupported semantic operators; and the
StemSnap maximum fix rejects valid odd-length delta arrays. Named structural
lookup accounting and its tests also remain inexact.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Common-table traversal still precedes caller work authority

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_admission.mbt:781-788`
**Issue:** `cff_validate_common_tables` runs before `CffAuthorityLedger::new`.
That validation calls the cmap, name, and post envelope decoders, which perform
attacker-sized record, segment, code-point, name, and glyph loops. A caller with
zero work authority therefore pays for the complete common-table semantic
traversal before receiving `BudgetExceeded`. The new ledger only protects the
later CFF INDEX/keying work, so the original authority-ordering finding is only
partially fixed.

**Fix:** Establish the non-consuming caller ledger before
`cff_validate_common_tables`, and give common-table validation staged,
declared-count preflights before each record/segment/glyph traversal. Reuse the
existing common-table work facts where possible, then retain the final atomic
preflight/commit ordering.

### CR-02: `allocation_size` is still overcharged and under-preflighted

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_admission.mbt:967-993`
**Issue:** Predefined charsets are assigned a hard-coded 3032-byte scratch
allocation. The actual source arrays are ISOAdobe `229 * 8 = 1832` bytes,
Expert `166 * 8 = 1328` bytes, and ExpertSubset `87 * 8 = 696` bytes; the
largest predefined Encoding source array is 2048 bytes. Thus an ISOAdobe font
whose actual largest allocation is 2048 bytes is incorrectly rejected unless
the caller grants 3032 bytes. In the opposite direction, custom Encoding
preflight grants only 256 bytes for the `seen` table. Supplements can grow each
retained `codes` and `gids` array to 256 UInt64 entries (2048 bytes), so those
allocations occur before the final exact charge discovers that the caller's
limit was too small. Lines 1054-1071 repeat the 3032-byte overcharge in the
committed charge.

**Fix:** Compute predefined scratch maxima from the actual array lengths.
For custom Encodings, pre-scan the bounded format/count/supplement framing,
calculate the checked final entry count, and preflight
`max(256, entries * 8)` before growing `codes` or `gids`. Use the same concrete
per-allocation maximum for the final charge.

### CR-03: Valid odd-length StemSnap delta arrays are rejected

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_dict.mbt:905-908`
**Issue:** StemSnapH and StemSnapV are validated with
`cff_require_even_bounded`. CFF defines these operands as a non-empty delta
array with a maximum of 12 values; unlike the blue-zone pair arrays, StemSnap
has no even-cardinality requirement. A valid one-value StemSnap is therefore
rejected as malformed.

**Fix:** Keep even bounded validation for BlueValues/OtherBlues families, but
use a separate non-empty `<= 12` delta-array validator for StemSnapH/V. Add
positive tests for cardinalities 1 and 11 plus rejection at 13.

### CR-04: SID typing and domain validation remain incomplete

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_dict.mbt:458-474`
**Issue:** `cff_require_sid_operand` permits values through 65535 even though
the CFF SID domain ends at 64999. More importantly, Top DICT PostScript
(`12 21`) and BaseFontName (`12 22`) are grouped with generic one-operand
operators at lines 715-733. Negative or fractional operands are accepted for
these SID fields, they are not added to `sid_operands`, and they are never
resolved against the String INDEX. This leaves the previous typed-schema
finding only partially fixed.

**Fix:** Route every SID-valued operator through one SID decoder enforcing
integer `0..64999`, retain all decoded SIDs, and resolve each against standard
strings plus the String INDEX. Cap the String INDEX-derived domain so reserved
implementation SIDs cannot become valid merely because the INDEX is large.

### CR-05: Unsupported Top DICT semantics are accepted and silently discarded

**Classification:** BLOCKER
**File:** `modules/mb-font/font/cff_dict.mbt:715-743`
**Issue:** SyntheticBase, embedded PostScript, BaseFontName, and BaseFontBlend
are accepted by arity-only branches, but `CffTopDict` retains none of them and
admission implements none of their semantics. In the phase's one-font exact
profile, a synthetic font cannot resolve a non-synthetic base font; embedded
PostScript and multiple-master blend behavior are also outside the admitted
static environment. Such a font is currently published as an ordinary
name-keyed/CID descriptor set with meaning-changing operators ignored.

**Fix:** Reject these operators as unsupported capability/profile cases before
descriptor construction, unless their complete semantics are explicitly added
to the supported profile. Do not accept and discard semantic operators.

## Warnings

### WR-01: `sid_cid_lookups` is still a proxy rather than an actual counter

**Classification:** WARNING
**File:** `modules/mb-font/font/cff_admission.mbt:1033-1047`
**Issue:** The counter is calculated as charset length plus Encoding length
plus two for CID ROS. It omits Top/Font DICT SID validations and does not match
the actual predefined-Encoding or supplement SID-to-GID lookup calls. For
example, the one-glyph default fixture records one lookup even though Standard
Encoding scans many nonzero SIDs; a supplement performs both SID validation
and charset lookup but contributes only one. This proxy feeds the exact work
charge at lines 592-627, so the named counter still does not measure what its
name claims.

**Fix:** Increment checked counters at the actual SID/CID validation and lookup
sites and carry them through `CffKeyingResult`, or rename the field to the
retained-key quantity it really measures and remove the claim that it is exact
lookup work.

### WR-02: Boundary tests still do not prove the claims in their names

**Classification:** WARNING
**File:** `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt:224-257`
**Issue:** The caller-authority test checks only the eventual Resource error
and unchanged budget. It has no traversal probe, so it passes even though
common cmap/name/post validation already ran before the work preflight.
Elsewhere, `fd_ranges` is asserted only as `> 0` at lines 163-166 rather than
the fixture's exact value of 2, and the structural test freezes the inaccurate
`sid_cid_lookups = 1` value at lines 58-67. The DICT tests at
`cff_dict_wbtest.mbt:200-220` cover only over-maximum even arrays and omit a
valid odd StemSnap case.

**Fix:** Add traversal callbacks/counters around common-table decoders and
assert they remain zero under insufficient authority. Assert exact named
structural values, and add positive/negative DICT boundary pairs rather than
only oversized rejection cases.

---

_Reviewed: 2026-07-28T11:59:38Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
