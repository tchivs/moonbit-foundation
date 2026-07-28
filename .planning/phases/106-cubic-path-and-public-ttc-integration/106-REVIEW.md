---
phase: 106-cubic-path-and-public-ttc-integration
reviewed: 2026-07-28T20:38:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - modules/mb-core/math/path.mbt
  - modules/mb-core/math/path_wbtest.mbt
  - modules/mb-font/font/cff_admission.mbt
  - modules/mb-font/font/cff_admission_wbtest.mbt
  - modules/mb-font/font/cff_hostile_fixture_wbtest.mbt
  - modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt
  - modules/mb-font/font/cff_type2.mbt
  - modules/mb-font/font/cff_type2_bounds.mbt
  - modules/mb-font/font/cff_type2_fixture_wbtest.mbt
  - modules/mb-font/font/cff_type2_path.mbt
  - modules/mb-font/font/cff_type2_path_wbtest.mbt
  - modules/mb-font/font/collection.mbt
  - modules/mb-font/font/collection_test.mbt
  - modules/mb-font/font/collection_wbtest.mbt
  - modules/mb-font/font/font.mbt
  - modules/mb-font/font/font_qualification_hostile_test.mbt
  - modules/mb-font/font/font_test.mbt
  - modules/mb-font/font/font_wbtest.mbt
  - modules/mb-font/font/tables.mbt
findings:
  critical: 3
  warning: 2
  info: 0
  total: 5
status: issues_found
---

# Phase 106: Code Review Report

**Reviewed:** 2026-07-28T20:38:00Z  
**Depth:** standard  
**Files Reviewed:** 19  
**Status:** issues_found

## Summary

The public CFF/TTC integration is not ready to ship. Three blocking defects were found: private CFF operation names escape through the format-neutral public API, the common-table refactor changes established static-glyf error precedence, and CFF kern traversal can execute work before cumulative caller/ancestor authority is preflighted. Two additional robustness gaps leave the staged path mutable after exact validation and make key resource/compatibility tests self-referential.

## Narrative Findings (AI reviewer)

The findings below come from direct review of `f5da94cf..HEAD`, including the public dispatch paths, CFF admission/resource ledgers, selected Type 2 transaction, static-glyf wrapper, and Phase 106 tests.

## Critical Issues

### CR-01: Private CFF operation names leak through public `Font` and `FontCollection` APIs

**Classification:** BLOCKER  
**File:** `D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\font.mbt:397-425, 765-773`  
**Issue:** `Font::open` returns CFF admission errors unchanged, `FontCollection::open_face` rewrites only `Capability` errors, and `Font::outline` returns Type 2 errors unchanged. Consequently public callers observe private operation names such as `font-cff-admit` and `font-cff-type2` instead of the existing format-neutral operations `font-open`, `font-collection-open-face`, and `font-outline`. This violates D-01/D-16 and makes the public error contract depend on outline format. The new tests assert categories and contexts but generally omit the operation for CFF failures, so the leak is not detected.

**Fix:**

```moonbit
// At each public boundary, preserve category/code/context/requested/limit,
// but replace the private operation with the receiving public operation.
let admitted = match admit_cff1_structure(source, limits, budget, 0UL) {
  Err(error) => return Err(font_rebind_operation(error, "font-open"))
  Ok(value) => value
}

// Apply the same rule for:
// - selected CFF admission -> "font-collection-open-face"
// - selected CFF outline execution -> "font-outline"
```

Add black-box assertions for `operation()` across representative State, Resource, Capability, and Data failures for standalone open, selected collection open, and outline.

### CR-02: Common-table extraction changes static-glyf multi-fault error precedence

**Classification:** BLOCKER  
**File:** `D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\tables.mbt:2158-2198`  
**Issue:** Before this phase, `font_admit_required_tables_impl` fetched common tables, decoded `head`, then decoded `maxp`, `hhea`, `OS/2`, and `cmap`, and only then admitted `kern`. The refactor now decodes `maxp` first (lines 2169-2179), admits `kern` next (2180-2190), and only afterward calls the helper that decodes `head` and the remaining common tables. A static-glyf font with both malformed `head` and malformed `maxp` now reports the maxp failure instead of the established head failure; malformed kern can likewise outrank head/hhea/OS/2/cmap faults. This is a directly observable D-17 compatibility regression even though valid-font fingerprints remain green.

**Fix:**

```moonbit
// Preserve the original static-glyf sequencing in this wrapper:
let head = font_decode_head(head_table)?
let maxp = font_decode_maxp(maxp_table, limits)?
let hhea = font_decode_hhea(hhea_table, maxp)?
let os2 = font_decode_os2(os2_table)?
let cmap = font_admit_cmap_envelope(cmap_table, maxp, limits)?
let kern = ... // retain the original position after cmap
font_admit_name_envelope(name_table, limits)?
font_admit_post_envelope(post_table, maxp, limits)?
```

Keep the new maxp-injected helper for CFF callers, or refactor it around already-decoded facts without reordering the glyf wrapper. Add static-glyf multi-fault tests that freeze the pre-Phase-106 operation/context ordering.

### CR-03: Kern pairs are traversed before cumulative CFF work authority is preflighted

**Classification:** BLOCKER  
**File:** `D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_admission.mbt:1227-1258`  
**Issue:** Common-table traversal advances `CffAuthorityLedger.work`, but kern admission is then run with a fresh `FontAdmissionLedger` whose staged work starts at zero. `font_admit_kern_bounded` therefore preflights only kern-local subtable/pair counts before iterating attacker-controlled pairs. The cumulative `authority.preflight(kern_work, ...)` happens only after the kern traversal has completed. A caller whose work window can cover the prior common scan and the kern scan independently, but not their sum, can force the kern pair loop to run beyond authorized caller/ancestor work before receiving `Resource`. This breaks the stated resource-authority ordering and permits bounded CPU work outside the supplied transaction.

**Fix:**

```moonbit
// Seed the kern ledger with work already staged by CFF admission, or route
// kern's staged preflights directly through CffAuthorityLedger.
let kern_ledger = FontAdmissionLedger::new_with_staged_work(
  budget,
  FontAdmissionCommitMode::CollectionDeferred,
  authority.work,
)
let kern = font_admit_kern_bounded(..., kern_ledger, ...)
```

The cumulative preflight must occur before `font_kern_format0_facts` enters its pair loop. Add a probe-based test where each stage fits separately but `common_work + kern_work` is one over the caller and ancestor limit, and assert that no pair traversal occurs.

## Warnings

### WR-01: The post-stage probe can mutate the exact path after validation and before charging

**Classification:** WARNING  
**File:** `D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\cff_type2_path.mbt:171-204, 253-289`  
**Issue:** The retained/emitted count and `path.length()` are validated before `after_stage(path)` runs. `Path2` is appendable through public `push`, and its array storage is shared through the value passed to the callback. A package-internal probe can therefore append commands after the count/capacity/work checks; the transaction then charges the original `CffPathCharge` and returns the enlarged path. Current probes only mutate source bytes, but the callback signature unnecessarily permits an uncharged result mutation at the most sensitive transaction seam.

**Fix:**

```moonbit
fn cff_decode_outline_atomic(
  // ...
  after_stage : () -> Unit,
) -> Result[@math.Path2, @error.CoreError] {
  // validate staged path
  after_stage()
  // final revision guard, one charge, immediate return
}
```

Use a no-argument probe (or an immutable summary) so no code can modify the staged `Path2` after exact validation.

### WR-02: Exact-charge and compatibility tests derive their oracle from the implementation under test

**Classification:** WARNING  
**File:** `D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\font_wbtest.mbt:1073-1095`; `D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\collection_wbtest.mbt:1436-1519`; `D:\AI-Data\temp\Admin\mnf-phase100-exec\modules\mb-font\font\font_test.mbt:1878-1975`  
**Issue:** `font_wb_cff_path_charge` reruns `type2_execute_glyph_with_path_capacity` and calls the same production `cff_path_charge` used by `Font::outline`; exact and one-short budgets are then constructed from that result. Selected-admission tests similarly obtain their “exact” limits from another call to the same admission implementation. The static-glyf “fingerprint” compares two executions of the current code rather than fixed pre-Phase-106 values. An undercharge, overcharge, or deterministic compatibility regression therefore updates both the implementation and its oracle and still passes; CR-02 is one concrete regression these fingerprints miss.

**Fix:** Freeze independent fixture constants for bytes, allocations, largest allocation, work, ordered errors, and path commands. Derive those constants manually from the fixture layout/VM instruction sequence or from a separately versioned golden artifact, not from `combined_charge`, `cff_path_charge`, or a second call to the production executor.

---

_Reviewed: 2026-07-28T20:38:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
