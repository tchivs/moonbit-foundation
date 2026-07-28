---
phase: 104-cff1-profile-and-bounded-data-model
fixed_at: 2026-07-28T12:42:29Z
review_path: D:/AI-Data/temp/Admin/mnf-phase100-exec/.planning/phases/104-cff1-profile-and-bounded-data-model/104-REVIEW.md
iteration: 3
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 104: Code Review Fix Report

**Fixed at:** 2026-07-28T12:42:29Z  
**Source review:** `D:/AI-Data/temp/Admin/mnf-phase100-exec/.planning/phases/104-cff1-profile-and-bounded-data-model/104-REVIEW.md`  
**Iteration:** 3

**Summary:**

- Findings in scope: 4
- Fixed: 4
- Skipped: 0
- Focused lookup-authority regression: 1 passed, 0 failed
- Focused format-4 search-work regression: 1 passed, 0 failed
- Focused predefined/custom Encoding allocation regression: 1 passed, 0 failed
- Full native suite: 1202 passed, 0 failed
- Four-target check: passed

## Fixed Issues

### CR-01: SID/CID lookup traversal still precedes caller work authority

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_admission.mbt`, `modules/mb-font/font/cff_keying.mbt`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`, `modules/mb-font/font/cff_keying_wbtest.mbt`  
**Commit:** `147900ef`  
**Applied fix:** Moved caller-work preflights to every actual keying lookup group: retained Top DICT SIDs, custom charset SID/CID records, predefined Encoding's fixed 256-slot scan and exact 149/165 nonzero-SID counts, custom Encoding supplement validation plus SID-to-GID lookup, CID ROS, and Font DICT SIDs. The predefined scan is now part of the final exact charge instead of retroactive final authorization.

### CR-02: CFF format-4 common-table work omits the search loop

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_admission.mbt`, `modules/mb-font/font/cff_admission_wbtest.mbt`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`  
**Commit:** `ee1d5f76`  
**Applied fix:** Added the exact `font_cmap_search_selector(facts.body_records)` term for every CFF format-4 cmap to both the semantic authority preflight and returned `common_table_work`. A two-segment format-4 fixture freezes corrected exact work `1467` and exact-minus-one `1466`, including atomic budget preservation.

### WR-01: Authority regressions probe common decoders but not keying lookups

**Status:** fixed: requires human verification  
**Files modified:** `modules/mb-font/font/cff_admission.mbt`, `modules/mb-font/font/cff_keying.mbt`, `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`, `modules/mb-font/font/cff_keying_wbtest.mbt`  
**Commit:** `147900ef`  
**Applied fix:** Threaded a keying-lookup probe through the production admission path and added direct production-function boundary tests. One-short authority proves zero lookup probes for StandardEncoding (`404/405`), custom charset (`0/1`), custom supplement (`1/2`), CID ROS (`1/2`), and retained Top/Font DICT SID groups (`1/2`).

### WR-02: The predefined Encoding allocation path has no one-short test

**Status:** fixed  
**Files modified:** `modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt`  
**Commit:** `c1ad8755`  
**Applied fix:** Added the missing predefined Encoding `allocation_size=2047` rejection beside its existing exact `2048` success. The regression freezes the Resource/`allocation_size` outcome and proves bytes, allocations, allocation-size authority, and work remain unchanged.

## Skipped Issues

None.

---

_Fixed: 2026-07-28T12:42:29Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 3_
