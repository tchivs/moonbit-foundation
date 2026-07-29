---
phase: 104-cff1-profile-and-bounded-data-model
plan: "02"
subsystem: font
tags: [moonbit, opentype, cff1, charset, encoding, fdselect]

requires:
  - phase: 104-cff1-profile-and-bounded-data-model
    provides: checked CFF INDEX windows, typed Top/Font/Private DICT facts, and static-CFF1 admission
provides:
  - complete name-keyed predefined/custom charset and Encoding resolution
  - complete CID ROS, charset, FDArray, and FDSelect 0/3 resolution
  - atomic per-GID CharString/private-environment descriptors with separate Top and FD FontMatrix facts
affects: [104-03, 105-type2-interpreter, 106-cff-font-integration]

tech-stack:
  added: []
  patterns:
    - two-pass range preflight before retained charset or FDSelect expansion
    - complete all-FD validation before any per-GID descriptor publication
    - one bounded standard-plus-String SID validation domain

key-files:
  created:
    - modules/mb-font/font/cff_keying.mbt
    - modules/mb-font/font/cff_keying_wbtest.mbt
    - modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt
    - modules/mb-font/font/cff_cid_fixture_wbtest.mbt
  modified:
    - modules/mb-font/font/cff_admission.mbt

key-decisions:
  - "Retain closed ISOAdobe, Expert, ExpertSubset, Standard, and Expert tables in MoonBit so predefined keying is deterministic, bounded, and dependency-free."
  - "Resolve and validate every FDArray entry before decoding FDSelect into per-GID descriptors, including FDs selected by no glyph."
  - "Keep Top and selected FD FontMatrix facts separate; Phase 104 performs no composition, normalization, or geometry work."

patterns-established:
  - "Name keying: validate the complete charset/SID and Encoding/code mapping before building the shared Top-private descriptor set."
  - "CID keying: preflight charset and FDSelect ranges, validate every FD private environment, then materialize exactly one descriptor per GID."

requirements-completed: [CFF-02]

coverage:
  - id: D1
    description: "Every valid name-keyed GID resolves through predefined/custom charset and Encoding data to one bounded CharString and the single checked Top private environment."
    requirement: CFF-02
    verification:
      - kind: integration
        ref: "modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt (5 exact/hostile name-keying tests)"
        status: pass
      - kind: unit
        ref: "moon test --target native (1183/1183)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every valid CID-keyed GID resolves through ROS, CID charset, FDArray, FDSelect 0/3, and checked per-FD private facts with atomic late-fault rejection."
    requirement: CFF-02
    verification:
      - kind: integration
        ref: "modules/mb-font/font/cff_cid_fixture_wbtest.mbt (7 exact/hostile CID-keying tests)"
        status: pass
      - kind: unit
        ref: "moon check --target all"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-28
status: complete
---

# Phase 104 Plan 02: Complete CFF1 Keying Summary

**Bounded name-keyed and CID-keyed adapters now normalize every admitted GID to one checked CharString/private environment before Type 2 execution.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-07-28T10:09:51Z
- **Completed:** 2026-07-28T10:34:08Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added exact predefined and custom name-keyed charset/Encoding resolution, including supplements, SID boundaries, duplicate-code rejection, range preflight, and atomic cardinality checks.
- Added complete CID ROS, charset 0/1/2, FDArray, and FDSelect 0/3 resolution with every FD private/local-Subrs/FontMatrix environment validated before selection.
- Replaced the single tracer descriptor with a complete private descriptor set while preserving caller-owned CharString windows, budget/revision ordering, and separate structural matrices.

## Task Commits

Each TDD task was committed atomically:

1. **Task 1 RED: CID multi-FD tracer tests** - `eb0109ee` (test)
2. **Task 1 GREEN: CID glyph environments** - `21dae453` (feat)
3. **Task 2 RED: name-keyed keying tests** - `c436253d` (test)
4. **Task 2 GREEN: name-keyed CFF resolution** - `1e45cb99` (feat)
5. **Task 3 RED: FDSelect format 3 tests** - `e181c23d` (test)
6. **Task 3 GREEN: CID FDSelect validation** - `ec7dbb34` (feat)

## Files Created/Modified

- `modules/mb-font/font/cff_keying.mbt` - Normalized charsets, Encodings, FDSelect, private environments, keying facts, and per-GID descriptors.
- `modules/mb-font/font/cff_admission.mbt` - Builds and charges the complete descriptor transaction before private publication.
- `modules/mb-font/font/cff_keying_wbtest.mbt` - Shared exact INDEX/DICT fixture builders and atomic budget assertions.
- `modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt` - Predefined/custom charset, Encoding, supplement, SID, range, and one-short evidence.
- `modules/mb-font/font/cff_cid_fixture_wbtest.mbt` - ROS, CID charset, FDArray, FDSelect 0/3, unused-FD, matrix, and one-short evidence.

## Decisions Made

- Embedded the closed predefined charset/Encoding tables directly in private MoonBit code to avoid ambient lookup or a foreign dependency.
- Required custom Encoding main records to cover exactly GIDs 1 through `nGlyphs - 1`; supplements may add checked alternate codes only for an existing non-`.notdef` SID.
- Validated every FDArray entry before FDSelect materialization so an invalid unused FD cannot survive as latent execution state.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first CID fixture accidentally used the helper's default one-glyph `maxp` around three CharStrings; the resulting expected `font-cff-charstrings-count` rejection was corrected by making the fixture cardinality explicit before the Task 1 GREEN commit.

## Known Stubs

None. Fixture variables named `placeholder_*` are fixed-width layout probes used only to calculate final CFF offsets; they do not flow into admitted facts.

## Threat Review

- T-104-05: complete SID/CID range and cardinality validation uses one bounded SID domain and rejects duplicates before descriptor creation.
- T-104-06: only FDSelect 0/3 is accepted; all FD/range/sentinel references are resolved before descriptor publication.
- T-104-07: attacker-controlled range bodies and retained counts are preflighted under format/glyph ceilings before expansion.
- No new network, authentication, file-access, schema, FFI, or public API surface was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 104-03 can derive and freeze the remaining structural limits and multi-fault precedence over one complete keying model.
- Phase 105 can consume per-GID CharString/private/local-Subrs/FontMatrix facts without parsing charset, Encoding, FDArray, FDSelect, or DICT bytes.
- No blockers remain.

## Self-Check: PASSED

- All five implementation/test files and this summary exist.
- All six TDD task commits are present in git history.

---
*Phase: 104-cff1-profile-and-bounded-data-model*
*Completed: 2026-07-28*
