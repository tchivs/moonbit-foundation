---
phase: 100-portable-font-qualification
plan: 02
subsystem: font
tags: [moonbit, opentype, cmap, format-6, dejavu, portability]

requires:
  - phase: 100-portable-font-qualification
    plan: 01
    provides: exact generated DejaVu Sans 2.37 bytes and independently inventoried cmap facts
  - phase: 98-unicode-mapping-and-kerning
    provides: canonical format-4/12 selection, validation, and lookup contracts
provides:
  - bounded private cmap envelopes for formats 4, 6, and 12
  - exact Macintosh 1/0/6 coexistence without format-6 lookup support
  - compact and licensed real-font regressions on all four supported targets
  - exact pre-edit and post-repair public interface identity
affects: [100-03-public-qualification, 100-04-policy-closure, mb-font-cmap]

tech-stack:
  added: []
  patterns:
    - bound recognized non-selected records before deciding whether supported decoding applies
    - charge cmap record discovery once while excluding ignored format-6 body work

key-files:
  created:
    - artifacts/phase100-plan02/mb-font-interface-baseline.txt
  modified:
    - modules/mb-font/font/tables.mbt
    - modules/mb-font/font/cmap.mbt
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt

key-decisions:
  - "Recognize only platform 1, encoding 0, format 6 as a bounded non-selected coexistence record."
  - "Keep CmapLookupFacts, canonical ranks, supported decoding, and public API limited to formats 4 and 12."
  - "Charge a recognized non-selected format-6 record only for the existing encoding-record scan, never for body traversal."

patterns-established:
  - "Cmap envelope classification precedes supported format-specific facts and validation."
  - "Real-font compatibility repairs require an authoritative pre-edit interface baseline and four-target regression proof."

requirements-completed: [FONT-05]

coverage:
  - id: D1
    description: Valid Macintosh format-6 records coexist with canonical format-12 lookup in compact and exact DejaVu fonts.
    requirement: FONT-05
    verification:
      - kind: integration
        ref: "font/font_test.mbt#format 6 coexists with canonical Unicode cmap without becoming selectable"
        status: pass
      - kind: integration
        ref: "font/font_test.mbt#DejaVu Sans 2.37 opens with its non-selected format 6 cmap"
        status: pass
      - kind: e2e
        ref: "moon -C modules/mb-font test font on js, wasm, wasm-gc, and native (97/97 each)"
        status: pass
    human_judgment: false
  - id: D2
    description: Format 6 remains non-queryable, non-selectable, bounded, and uncharged as a supported mapping body.
    requirement: FONT-05
    verification:
      - kind: unit
        ref: "font/font_test.mbt#format 6 remains non-queryable without canonical Unicode cmap"
        status: pass
      - kind: unit
        ref: "font/font_wbtest.mbt#format-6 coexistence is bounded without supported body work"
        status: pass
    human_judgment: false
  - id: D3
    description: Malformed and wrong-domain format-6 records still fail closed while the 56-line public interface remains byte-identical.
    requirement: FONT-05
    verification:
      - kind: unit
        ref: "font/font_test.mbt#malformed format 6 envelopes remain cmap data failures"
        status: pass
      - kind: integration
        ref: "pre-edit baseline, regenerated interface, and foundation policy sequence comparison"
        status: pass
    human_judgment: false

duration: 16min
completed: 2026-07-27
status: complete
---

# Phase 100 Plan 02: Format-6 Coexistence Repair Summary

**A bounded private cmap classifier now admits DejaVu's non-selected Macintosh format 6 record while preserving exact format-4/12 lookup scope and the frozen public interface.**

## Performance

- **Duration:** 16 minutes
- **Started:** 2026-07-27T14:00:43Z
- **Completed:** 2026-07-27T14:16:50Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Captured the untouched generated semantic interface as an exact 56-line UTF-8-without-BOM baseline with SHA-256 `ce22405a386fcb709ded1320ec72bf5ad722c23db5c4f26da06e3fa60a381464`.
- Reproduced the defect with both a compact checksum-correct font and the exact 757,076-byte DejaVu Sans 2.37 fixture before changing production code.
- Added a private checked envelope for cmap formats 4, 6, and 12 while retaining all complete format-4/12 structural, glyph-range, and selection validation.
- Ignored only exact platform 1 / encoding 0 / format 6 records for lookup and body work; format-6-only fonts remain `CapabilityUnavailable` and malformed or wrong-domain records remain data failures.
- Passed all 97 font tests independently on `js`, `wasm`, `wasm-gc`, and `native`; DejaVu opens and maps U+0041 to glyph 36 without another admission defect.
- Regenerated the final interface and proved the exact ordered sequence and SHA-256 are unchanged from both the pre-edit baseline and `policy/foundation.json`.

## Task Commits

Each TDD gate was committed atomically:

1. **Task 1 RED: Pin compact and real-font format-6 coexistence failures** - `82c409fa` (`test`)
2. **Task 2 GREEN: Bound and ignore only recognized non-selected format 6** - `6e8067b4` (`feat`)

## Files Created/Modified

- `artifacts/phase100-plan02/mb-font-interface-baseline.txt` - Authoritative pre-edit 56-line semantic interface.
- `modules/mb-font/font/tables.mbt` - Private subtable envelope and supported-body work separation.
- `modules/mb-font/font/cmap.mbt` - Exact 1/0/6 recognition and non-selected admission path.
- `modules/mb-font/font/font_test.mbt` - Compact, DejaVu, unsupported-only, and malformed public regressions.
- `modules/mb-font/font/font_wbtest.mbt` - Private envelope and record-scan-only work proof.

## Decisions Made

- Format 6 is recognized only as bounded coexistence evidence for the exact Macintosh 1/0 tuple; it is not a supported mapping format.
- The common envelope carries only format and checked in-table length. Format-4/12 language, cardinality, search, glyph-range, and retained lookup facts remain in their existing supported decoder.
- A recognized non-selected format-6 body receives no search, mapping, or supported-body work charge.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Synchronized the advanced STATE frontmatter plan counter**
- **Found during:** Final state validation
- **Issue:** `state.advance-plan` advanced the Current Position body to Plan 3 but left `current_plan: 2` in frontmatter.
- **Fix:** Updated the frontmatter counter to 3 so machine-readable and human-readable state agree.
- **Files modified:** `.planning/STATE.md`
- **Verification:** STATE frontmatter and Current Position both identify Plan 3 of 5.
- **Committed in:** Final plan metadata commit.

---

**Total deviations:** 1 auto-fixed (Rule 3 blocking metadata inconsistency)
**Impact on plan:** Planning metadata only; implementation, runtime behavior, and verification evidence are unchanged.

## Issues Encountered

- The first native RED run used `unwrap()` on the expected opening errors, which caused an opaque Windows-native abort. The RED tests were refined to assert `Data / InvalidEncoding / font-cmap-envelope` explicitly before forcing failure; the complete RED run then reported 93 passing and three expected failing tests.
- `moon fmt` treats a selected file path as a package formatting request. Its incidental changes to unrelated package files and pre-existing formatting were restored before the RED commit; no formatter churn remains.
- The broad `Assert-FontFoundationPolicy` command currently fails on a pre-existing Plan 100-01 inventory mismatch: `generated_font_qualification_test.mbt` is present but the older policy selector still expects 13 package files. This plan does not own policy inventory files. The exact 56-line interface comparison, independent Phase 99 surface classifier, sole `tchivs/mb-core` dependency check, and all runtime tests pass. Plan 100-04 owns policy and qualification-selector closure.

## TDD Gate Compliance

- RED commit `82c409fa` exists and demonstrates the compatibility defect before production changes.
- GREEN commit `6e8067b4` follows RED and passes the complete four-target suite.

## Verification

- `moon -C modules/mb-font test font --target <js|wasm|wasm-gc|native> --frozen --target-dir target/phase100-plan02-<target> --no-parallelize` — 97/97 on each target.
- `moon -C modules/mb-font info --target all --frozen` — generated exactly 56 semantic lines.
- Baseline, regenerated interface, and `policy/foundation.json` allowlist — exact ordered match; baseline and final SHA-256 both `ce22405a386fcb709ded1320ec72bf5ad722c23db5c4f26da06e3fa60a381464`.
- `Assert-FontPhase99Surface` — pass.
- Direct dependency set — exactly `tchivs/mb-core`.

## Known Stubs

None. Empty arrays in the touched test files are mutable fixture-builder accumulators, not unwired production or UI data.

## User Setup Required

None - no external service configuration is required.

## Next Phase Readiness

- Plan 100-03 can use the now-opening exact DejaVu bytes and compact generated workflow across every target.
- Plan 100-04 must add the Plan 100-01 generated qualification test source to the canonical policy/publication inventory before the broad foundation selector can pass.

## Self-Check: PASSED

- All five implementation/test artifacts and this summary exist.
- Both TDD task commits resolve in repository history.
- Four-target tests, exact interface identity, focused policy classification, dependency, stub, and threat-surface claims were rechecked.

---
*Phase: 100-portable-font-qualification*
*Completed: 2026-07-27*
