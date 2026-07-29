---
phase: 105-bounded-type-2-validation-and-retained-metrics
plan: 04
subsystem: font
tags: [moonbit, cff1, type2, font-metrics, atomic-admission]

requires:
  - phase: 104-cff1-profile-and-bounded-data-model
    provides: checked name-keyed and CID-keyed CFF1 glyph descriptors
  - phase: 105-bounded-type-2-validation-and-retained-metrics
    provides: bounded Type 2 VM execution and compact glyph bounds staging
provides:
  - atomic structural plus all-glyph CFF1 admission
  - retained per-glyph bounds and exact named Type 2 charges
  - face-local hmtx metric authority for admitted CFF1 faces
  - deterministic zero-publication and zero-charge failure behavior
affects: [phase-106-cff-outline-publication, font-admission, font-collections]

tech-stack:
  added: []
  patterns:
    - staged CFF structure and Type 2 execution before one final budget commit
    - retained hmtx facts independent of Type 2 width operands

key-files:
  created: []
  modified:
    - modules/mb-font/font/cff_admission.mbt
    - modules/mb-font/font/metrics.mbt
    - modules/mb-font/font/cff_admission_wbtest.mbt
    - modules/mb-font/font/cff_hostile_fixture_wbtest.mbt
    - modules/mb-font/font/font_wbtest.mbt

key-decisions:
  - "CFF1 structural facts and all-glyph Type 2 facts are staged together, revision-checked, preflighted, and committed exactly once."
  - "hmtx remains the sole public advance-width and side-bearing authority; Type 2 widths are validated VM facts only."
  - "CFF1 facts remain private until Phase 106; this plan adds no public CFF-backed outline or Path2 API."

patterns-established:
  - "Atomic CFF admission: every failure returns no AdmittedCff1 and leaves every caller budget dimension unchanged."
  - "All-glyph ordering: glyphs execute in ascending GID order and the earliest realizable fault wins."

requirements-completed: [T2-01, T2-02, CFF-03]

coverage:
  - id: D1
    description: "Every admitted name-keyed or CID-keyed CFF1 glyph is executed by the production Type 2 VM and retained as a compact bounds slot before publication."
    requirement: CFF-03
    verification:
      - kind: integration
        ref: "modules/mb-font/font/cff_admission_wbtest.mbt#CFF1 admission publishes complete all-glyph facts after one combined commit"
        status: pass
      - kind: integration
        ref: "moon test --target native (1245 passed)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Named Type 2 resource charges, hostile error precedence, and mutation failures are deterministic and atomically uncharged."
    requirement: T2-02
    verification:
      - kind: unit
        ref: "modules/mb-font/font/cff_admission_wbtest.mbt#CFF1 admission retains exact named VM charges including subroutine work"
        status: pass
      - kind: integration
        ref: "modules/mb-font/font/cff_hostile_fixture_wbtest.mbt#CFF all-glyph capability data and smallest-failing-GID outcomes are atomic"
        status: pass
    human_judgment: false
  - id: D3
    description: "CFF Type 2 width operands do not replace face-local hmtx metrics, while existing standalone and selected-collection static-glyf APIs remain compatible."
    requirement: CFF-03
    verification:
      - kind: integration
        ref: "modules/mb-font/font/cff_admission_wbtest.mbt#CFF1 Type 2 width mismatch retains hmtx as metric authority"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/font_test.mbt#Phase 105 preserves the public standalone static glyf fingerprint"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#Phase 105 preserves the public selected static glyf fingerprint"
        status: pass
    human_judgment: false

duration: 31min
completed: 2026-07-28
status: complete
---

# Phase 105 Plan 04: Atomic CFF1 Admission and Retained Metrics Summary

**CFF1 structure and every glyph now pass through one bounded transaction that retains compact bounds and hmtx authority, then publishes and charges exactly once.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-07-28T15:39:39Z
- **Completed:** 2026-07-28T16:10:55Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Replaced the single-glyph structural tracer with ascending all-GID Type 2 staging for both name-keyed and CID-keyed CFF1 faces.
- Combined structural and VM byte/allocation/allocation-size/work charges into one preflight and one final commit after the closing revision guard.
- Retained one truthful optional bounds entry per GID plus exact executed-byte, call, return, operator, number, mask, geometry, point, contour, and command evidence.
- Preserved face-local `hmtx` as the sole advance-width and side-bearing authority even when Type 2 width operands disagree.
- Froze mutation, capability/data precedence, smallest-failing-GID, shared-CFF collection, and public static-glyf compatibility behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire all-glyph Type 2 validation into the CFF admission transaction**
   - `40b4bcb6` — test: expose later-glyph atomicity gap
   - `dcddad51` — feat: admit CFF structure and all glyphs atomically
2. **Task 2: Freeze metric authority, exact resource, mutation, and error behavior**
   - `8c5fba6b` — test: add failing CFF metric authority test
   - `f020656f` — feat: retain CFF metrics and atomic failure evidence
3. **Task 3: Close native and portable regression evidence**
   - `269c4c5e` — test: preserve public static-glyf fingerprints

## Files Created/Modified

- `modules/mb-font/font/cff_admission.mbt` — staged structure/VM transaction, combined charge, final revision guard, and retained facts.
- `modules/mb-font/font/metrics.mbt` — shared checked hmtx reader and retained CFF metric facts.
- `modules/mb-font/font/cff_admission_wbtest.mbt` — all-glyph, exact charge, revision, mutation, and hmtx-authority evidence.
- `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt` — capability/data/smallest-GID and zero-charge hostile regressions.
- `modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt` — complete name-keyed all-glyph retained facts and combined budgets.
- `modules/mb-font/font/cff_cid_fixture_wbtest.mbt` — complete CID all-glyph retained facts and combined budgets.
- `modules/mb-font/font/font_wbtest.mbt` — shared-CFF collection bounds identity and face-local hmtx evidence.
- `modules/mb-font/font/collection_wbtest.mbt` — collection admission migrated to complete all-glyph facts and combined charges.
- `modules/mb-font/font/font_test.mbt` — standalone public static-glyf metric fingerprint.
- `modules/mb-font/font/collection_test.mbt` — selected TTC public static-glyf metric fingerprint.

## Decisions Made

- Structural admission no longer commits independently. It produces staged facts consumed by the all-glyph VM transaction so no partial `AdmittedCff1` can escape.
- The final source-revision guard runs after every glyph and immediately before the sole commit; a mutate-and-restore still fails because the revision changes.
- Combined allocation-size authority is the maximum of structural and Type 2 scratch ceilings, while bytes, allocations, and work are checked additions.
- Type 2 width operands remain private execution facts. The retained `head`/`maxp`/`hhea`/`hmtx` facts continue to answer metrics.
- No Phase 106 public CFF outline surface was introduced.

## Verification

- `moon test modules/mb-font/font --target native -j 2 -f "Phase 105 preserves the public*"` — 2 passed, 0 failed.
- `moon test --target native -j 2` — 1245 passed, 0 failed.
- `moon check --target native` — passed with 0 errors.
- `moon check --target all` — passed with 0 errors on all configured targets.
- The checks report 31 non-fatal warnings from private staged fields/helpers and existing debug-display usage; no warning is a failed verification.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- A first draft of the named-charge fixture used one glyph with a three-entry custom Encoding and failed at `font-cff-encoding-cardinality`; on native Windows its subsequent unwrap surfaced as exit `0xc0000409`. The focused test identified the fixture error, and the fixture was corrected to the supported three-glyph cardinality before the final full suite.

## Known Stubs

None. Empty arrays and placeholder offset objects found by the scan are fixture builders or intentional zero-length test inputs, not unwired production data.

## Threat Flags

None. This plan adds no public endpoint, authentication path, filesystem access, schema boundary, or new public trust surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 106 can consume complete private `AdmittedCff1` bounds and metrics without repeating structural or Type 2 admission.
- Public CFF-backed outline publication remains intentionally absent and ready to be introduced under the Phase 106 contract.
- No blockers remain.

## Self-Check: PASSED

- All listed implementation and evidence files exist.
- All five task commits are present in repository history.
- Final native tests and native/all-target checks passed.

---
*Phase: 105-bounded-type-2-validation-and-retained-metrics*
*Completed: 2026-07-28*
