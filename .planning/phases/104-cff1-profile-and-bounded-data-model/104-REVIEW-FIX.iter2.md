---
phase: 104-cff1-profile-and-bounded-data-model
fixed_at: 2026-07-28T11:51:37Z
review_path: D:/AI-Data/temp/Admin/mnf-phase100-exec/.planning/phases/104-cff1-profile-and-bounded-data-model/104-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 9
skipped: 0
status: all_fixed
---

# Phase 104: Code Review Fix Report

**Fixed at:** 2026-07-28T11:51:37Z  
**Source review:** `D:/AI-Data/temp/Admin/mnf-phase100-exec/.planning/phases/104-cff1-profile-and-bounded-data-model/104-REVIEW.md`  
**Iteration:** 1

**Summary:**

- Findings in scope: 9
- Fixed: 9
- Skipped: 0
- Focused CFF tests: 33 passed
- Focused selected-collection CFF test: 1 passed
- Full native suite: 1198 passed, 0 failed
- Four-target check: passed

## Fixed Issues

### CR-01: Caller work and allocation authority is checked after the work has already happened

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_admission.mbt`, `modules/mb-font/font/cff_keying.mbt`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`  
**Commit:** `697410db`  
**Applied fix:** Added a non-consuming cumulative CFF authority ledger. It preflights base table work, each declared INDEX offset allocation, charset/Encoding/descriptors, FD environments, FDSelect, Private DICTs, and local Subrs before their traversal or allocation. Added hostile work/allocation precedence tests with unchanged-budget assertions.

### CR-02: `allocation_size` is charged as a total instead of a per-allocation maximum

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_admission.mbt`, `modules/mb-font/font/cff_admission_wbtest.mbt`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`  
**Commit:** `697410db`  
**Applied fix:** Replaced table-plus-retained-total charging with the maximum checked size of the actual offsets, descriptors, environments, charset, Encoding, FD selector, and scratch allocations. Retained bytes remain an independent cumulative semantic limit.

### CR-03: Valid custom encodings with unencoded glyphs are rejected

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_keying.mbt`, `modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`  
**Commit:** `13d13e50`  
**Applied fix:** Custom Encoding formats now accept a produced GID count at most `glyph_count - 1`, preserve sequential GIDs from 1, and leave trailing glyphs unencoded. Supplements must resolve to a GID already present in the main Encoding.

### CR-04: Structurally incomplete OpenType fonts pass CFF admission

**Status:** fixed  
**Files modified:** `modules/mb-font/font/font.mbt`, `modules/mb-font/font/cff_admission.mbt`, `modules/mb-font/font/cff_admission_wbtest.mbt`, `modules/mb-font/font/collection_wbtest.mbt`  
**Commits:** `31efb6e7`, `697410db`  
**Applied fix:** Factored common table presence and reused existing table decoders for CFF admission. CFF1 now requires and validates `OS/2`, `cmap`, `head`, `hhea`, `hmtx`, `maxp`, `name`, and `post`, with exact CFF-compatible `hmtx` cardinality. Fixtures now build complete OpenType/CFF fonts and test every missing common table.

### CR-05: Required Private DICTs are modeled and admitted as optional

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_keying.mbt`, `modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt`, `modules/mb-font/font/cff_cid_fixture_wbtest.mbt`, `modules/mb-font/font/cff_admission_wbtest.mbt`  
**Commit:** `13d13e50`  
**Applied fix:** Name-keyed Top DICTs and every CID Font DICT must provide a Private operator. Zero-length Private DICTs remain valid. Admitted glyph/private environments now carry a non-optional decoded Private DICT.

### CR-06: The DICT token parser accepts malformed real numbers and oversized operand stacks

**Status:** fixed  
**Files modified:** `modules/mb-font/font/cff_dict.mbt`, `modules/mb-font/font/cff_dict_wbtest.mbt`  
**Commit:** `582e882e`  
**Applied fix:** Split mantissa/exponent digit state, constrained signs to the legal initial position, required exponent digits, validated full-byte `0xF` padding, and rejected the 49th pending operand before array growth.

### CR-07: The “typed” DICT schemas validate arity but not operand types or domains

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_dict.mbt`, `modules/mb-font/font/cff_admission.mbt`, `modules/mb-font/font/cff_keying.mbt`, `modules/mb-font/font/cff_dict_wbtest.mbt`  
**Commit:** `7850ed77`  
**Applied fix:** Added SID, boolean, and structural integer domain checks; retained Top/Font DICT SIDs for resolution against the String INDEX; validated FontName SIDs; and enforced CFF blue-zone and StemSnap array maxima.

### WR-01: Named structural counters do not measure the structures their names claim

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_admission.mbt`, `modules/mb-font/font/cff_dict.mbt`, `modules/mb-font/font/cff_keying.mbt`  
**Commit:** `697410db`  
**Applied fix:** Charges now retain the actual `hdrSize`, decoded DICT operand/operator unit count, format-3 FD range count, INDEX offset/object counts, selector entries, and concrete retained allocation count.

### WR-02: Exact-budget tests use the production result as their expected-value oracle

**Status:** fixed  
**Files modified:** `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`, `modules/mb-font/font/collection_wbtest.mbt`  
**Commit:** `697410db`  
**Applied fix:** Replaced production-derived expected budgets with independent checked literals for standalone CID and selected collection fixtures. Exact and one-less byte, allocation-count, allocation-size, and work cases now use those fixture constants, with direct named structural facts and early insufficient-authority cases.

---

_Fixed: 2026-07-28T11:51:37Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
