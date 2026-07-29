---
phase: 105-bounded-type-2-validation-and-retained-metrics
plan: "01"
subsystem: font-cff-type2
tags: [moonbit, cff1, type2, fixed-point, font-matrix, resource-limits]

requires:
  - phase: 104-cff1-profile-and-bounded-data-model
    provides: typed CFF DICT facts, per-GID keying environments, and bounded structural admission
provides:
  - checked signed Q16.16 number decoding and arithmetic
  - deterministic per-glyph xorshift32 random streams
  - retained initialRandomSeed plus distinct Top and optional FD matrix facts
  - exact rational matrix composition, application, and outward bounds rounding
  - private Type 2 hard and caller-derived resource limits
affects: [105-02, 105-03, 105-04, 106-cff1-outline-and-metrics]

tech-stack:
  added: []
  patterns:
    - signed Q16.16 values with checked Int64 intermediates
    - exact rational FD-then-Top matrix composition before unitsPerEm normalization
    - private format ceilings intersected with existing public FontLimits

key-files:
  created:
    - modules/mb-font/font/cff_type2_fixed.mbt
    - modules/mb-font/font/cff_type2_fixed_wbtest.mbt
  modified:
    - modules/mb-font/font/cff_dict.mbt
    - modules/mb-font/font/cff_keying.mbt
    - modules/mb-font/font/limits.mbt
    - modules/mb-font/font/cff_dict_wbtest.mbt
    - modules/mb-font/font/cff_cid_fixture_wbtest.mbt

key-decisions:
  - "Use signed-32 Q16.16 as the only Type 2 runtime numeric representation; Int64 remains a checked intermediate."
  - "Reset xorshift32 from the checked Private DICT seed for each glyph, normalizing zero to 0x6D2B79F5 and emitting raw values 1..65536."
  - "Represent FD FontMatrix as optional and compose explicit FD-local then Top; omission is identity inheritance."
  - "Derive Type 2 command, byte, call, work, geometry, and scratch authority from existing FontLimits without changing its public shape."

patterns-established:
  - "Type 2 Data errors use operation font-cff-type2 with stable numeric contexts."
  - "Matrix calculations stay rational through composition/application and round bounds only at the final floor/ceil boundary."

requirements-completed: [T2-01, T2-02, CFF-03]

coverage:
  - id: D1
    description: Checked Type 2 Q16.16 decoding, arithmetic, square root, and deterministic PRNG
    requirement: T2-01
    verification:
      - kind: unit
        ref: modules/mb-font/font/cff_type2_fixed_wbtest.mbt
        status: pass
      - kind: integration
        ref: moon test --target native
        status: pass
    human_judgment: false
  - id: D2
    description: Retained initialRandomSeed and non-duplicated Top/optional FD matrix handoff
    requirement: CFF-03
    verification:
      - kind: unit
        ref: modules/mb-font/font/cff_dict_wbtest.mbt
        status: pass
      - kind: unit
        ref: modules/mb-font/font/cff_cid_fixture_wbtest.mbt
        status: pass
    human_judgment: false
  - id: D3
    description: Exact rational transforms, outward bounds rounding, and private Type 2 limits
    requirement: T2-02
    verification:
      - kind: unit
        ref: modules/mb-font/font/cff_type2_fixed_wbtest.mbt
        status: pass
      - kind: integration
        ref: moon check --target native
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-28
status: complete
---

# Phase 105 Plan 01: Deterministic Type 2 Numeric Foundation Summary

**A target-independent signed Q16.16 kernel now carries checked Type 2 numbers, deterministic random state, exact matrix recipes, outward bounds primitives, and private VM authority.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-28T14:15:00Z
- **Completed:** 2026-07-28T14:35:00Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Decodes every Type 2 numeric wire form into checked signed Q16.16 and implements deterministic checked arithmetic, integer square root, and xorshift32 streams.
- Retains checked `initialRandomSeed` facts and exposes Top plus optional FD-local matrices without synthesizing an omitted FD transform.
- Derives closed Type 2 VM limits from existing caller authority and provides exact FD-then-Top transform/application with conservative outward rounding.

## Task Commits

Each task followed an explicit RED then GREEN cycle:

1. **Task 1 RED: fixed arithmetic and PRNG tests** - `10c76d90`
2. **Task 1 GREEN: checked fixed kernel** - `3f4e050c`
3. **Task 2 RED: seed and matrix handoff tests** - `de3bb221`
4. **Task 2 GREEN: retained seed and optional FD matrix facts** - `d207c4a1`
5. **Task 3 RED: limit and transform tests** - `ed403e22`
6. **Task 3 GREEN: private limits and exact transforms** - `057e8648`

## Files Created/Modified

- `modules/mb-font/font/cff_type2_fixed.mbt` - Type 2 fixed arithmetic, PRNG, rational matrices, application, and outward rounding.
- `modules/mb-font/font/cff_type2_fixed_wbtest.mbt` - wire, arithmetic, PRNG, limit, matrix, and rounding qualification.
- `modules/mb-font/font/cff_dict.mbt` - checked `initialRandomSeed` retention and optional FD FontMatrix presence.
- `modules/mb-font/font/cff_keying.mbt` - distinct Top and optional FD-local matrix handoff per GID.
- `modules/mb-font/font/limits.mbt` - closed Type 2 ceilings and derived caller authority.
- `modules/mb-font/font/cff_dict_wbtest.mbt` - seed/default/duplicate/range and matrix-presence tests.
- `modules/mb-font/font/cff_cid_fixture_wbtest.mbt` - name/CID explicit and omitted FD matrix facts.

## Decisions Made

- Q16.16 results are narrowed at every kernel boundary; no `Double` participates in Type 2 numeric behavior.
- Matrix composition follows `unitsPerEm × Top × optional-FD × coordinate`, with omitted FD represented as `None`.
- Scratch authority names five fixed arrays and a 384-byte largest allocation; dynamic VM arrays remain subject to the caller budget.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Preserved the Phase 104 internal matrix compatibility seam**

- **Found during:** Task 2
- **Issue:** Removing the Phase 104 `font_matrix` tracer field would require modifying an out-of-plan regression file and would break existing structural admission tests before later Phase 105 plans migrate consumers.
- **Fix:** Added authoritative `top_font_matrix`/`fd_font_matrix` facts for the VM while retaining the old internal alias with an explicit compatibility comment.
- **Files modified:** `modules/mb-font/font/cff_keying.mbt`
- **Verification:** `moon test --target native` passed 1213/1213.
- **Committed in:** `d207c4a1`

**Total deviations:** 1 auto-fixed (1 Rule 3).
**Impact on plan:** The new VM receives unambiguous matrix facts while Phase 104 regressions remain green; no public API or file outside Plan 105-01 changed.

## Issues Encountered

- The first foreground full-workspace test reached its command timeout while native image tests were still active. Re-running it as a monitored background process completed successfully with 1213/1213 tests.
- Native checks report expected unused-private-function warnings because Plans 105-02 and 105-03 have not wired the new kernel into the interpreter yet; there are no errors.

## Verification

- `moon test modules/mb-font/font --target native -j 2` — 204/204 passed.
- `moon test --target native -j 2` — 1213/1213 passed.
- `moon check --target native` — passed, 0 errors.

## User Setup Required

None.

## Next Phase Readiness

Plan 105-02 can build the iterative non-geometry VM directly on `Type2Fixed`, `Type2Prng`, and `Type2Limits`. Plan 105-03 can reuse the same rational matrix and outward rounding primitives for retained bounds.

## Self-Check: PASSED

- All seven created/modified implementation and test files exist.
- All six RED/GREEN task commits resolve in Git.
- Coverage metadata classifies all three deliverables as automatically proven.

---
*Phase: 105-bounded-type-2-validation-and-retained-metrics*
*Completed: 2026-07-28*
