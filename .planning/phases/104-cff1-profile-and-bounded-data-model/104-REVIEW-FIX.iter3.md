---
phase: 104-cff1-profile-and-bounded-data-model
fixed_at: 2026-07-28T12:23:34Z
review_path: D:/AI-Data/temp/Admin/mnf-phase100-exec/.planning/phases/104-cff1-profile-and-bounded-data-model/104-REVIEW.md
iteration: 2
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 104: Code Review Fix Report

**Fixed at:** 2026-07-28T12:23:34Z  
**Source review:** `D:/AI-Data/temp/Admin/mnf-phase100-exec/.planning/phases/104-cff1-profile-and-bounded-data-model/104-REVIEW.md`  
**Iteration:** 2

**Summary:**

- Findings in scope: 7
- Fixed: 7
- Skipped: 0
- Focused CFF tests: 35 passed, 0 failed
- Focused selected-collection CFF test: 1 passed, 0 failed
- Full `mb-font/font` package: 191 passed, 0 failed
- Full native suite: 1200 passed, 0 failed
- Four-target check: passed

## Fixed Issues

### CR-01: Common-table traversal still precedes caller work authority

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_admission.mbt`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`, `modules/mb-font/font/collection_wbtest.mbt`  
**Commit:** `ea000104`  
**Applied fix:** Established the cumulative caller authority ledger before common-table semantics. Added staged preflights for declared cmap records, format-4 segment and mapping work, name and language records, and post glyph/name traversal. Common traversal work is included in the exact final charge. A traversal probe now proves zero common decoder entries under zero work authority.

### CR-02: `allocation_size` is still overcharged and under-preflighted

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_admission.mbt`, `modules/mb-font/font/limits.mbt`, `modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt`  
**Commit:** `ea000104`  
**Applied fix:** Replaced the 3032-byte predefined-charset constant with the concrete ISOAdobe, Expert, and ExpertSubset source-array maxima of 1832, 1328, and 696 bytes. Custom Encoding framing is pre-scanned before allocation, its checked final entry count is capped at 256, and each retained UInt64 array is preflighted and charged as `max(256, entries * 8)`. The retained-data ceiling now admits the valid 256-code supplement case. Exact 2048-byte and one-short 2047-byte regressions cover predefined and custom Encoding paths.

### CR-03: Valid odd-length StemSnap delta arrays are rejected

**Status:** fixed  
**Files modified:** `modules/mb-font/font/cff_dict.mbt`, `modules/mb-font/font/cff_dict_wbtest.mbt`  
**Commit:** `5c2c1faa`  
**Applied fix:** Added a non-empty bounded delta-array validator for StemSnapH/V while preserving paired even validation for blue-zone arrays. Regression tests accept cardinalities 1, 11, and 12 and reject 13.

### CR-04: SID typing and domain validation remain incomplete

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_dict.mbt`, `modules/mb-font/font/cff_keying.mbt`, `modules/mb-font/font/cff_dict_wbtest.mbt`  
**Commit:** `8dd3ccc3`  
**Applied fix:** Centralized SID number decoding as a nonnegative integer in `0..64999`, routed ROS registry/ordering through it, and capped the standard-plus-String-INDEX domain at the exclusive limit 65000. Added direct 65000 rejection coverage for ordinary Top DICT SID and ROS operands.

### CR-05: Unsupported Top DICT semantics are accepted and silently discarded

**Status:** fixed  
**Files modified:** `modules/mb-font/font/cff_dict.mbt`, `modules/mb-font/font/cff_dict_wbtest.mbt`  
**Commit:** `8dd3ccc3`  
**Applied fix:** SyntheticBase, embedded PostScript, BaseFontName, and BaseFontBlend now return the stable `font-cff-top-operator-unsupported` capability outcome instead of passing arity checks and being discarded. Tests freeze the capability category and context for all four operators.

### WR-01: `sid_cid_lookups` is still a proxy rather than an actual counter

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_admission.mbt`, `modules/mb-font/font/cff_keying.mbt`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`  
**Commit:** `ea000104`  
**Applied fix:** Carried checked SID/CID counters from the actual custom-charset validation, predefined-Encoding charset lookup, supplement SID validation and lookup, ROS validation, and Font DICT SID validation sites. The final charge adds retained Top DICT SID resolutions. Regressions assert 149 actual StandardEncoding lookups for the one-glyph fixture and 4 actual ROS/CID validations for the CID fixture.

### WR-02: Boundary tests still do not prove the claims in their names

**Status:** fixed  
**Files modified:** `modules/mb-font/font/cff_dict_wbtest.mbt`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`, `modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt`, `modules/mb-font/font/collection_wbtest.mbt`  
**Commits:** `5c2c1faa`, `8dd3ccc3`, `ea000104`  
**Applied fix:** Added the common-decoder traversal probe, exact `fd_ranges = 2`, actual SID/CID lookup counts, exact standalone work 1445, exact selected-collection work 526, concrete 2048-byte allocation boundaries, and positive/negative StemSnap pairs. Expected values are fixture literals rather than values derived from the production result.

## Skipped Issues

None.

---

_Fixed: 2026-07-28T12:23:34Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 2_
