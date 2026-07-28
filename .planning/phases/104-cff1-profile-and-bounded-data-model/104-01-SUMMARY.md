---
phase: 104-cff1-profile-and-bounded-data-model
plan: "01"
subsystem: font
tags: [moonbit, opentype, cff1, bounded-parser, typed-dict]

requires:
  - phase: 103-collection-qualification
    provides: retained caller-owned SFNT/TTC table authority and selected-face invariants
provides:
  - exact private static-CFF1 OTTO profile classification
  - one checked CFF INDEX representation for all structural object families
  - typed Top, Font, and Private DICT facts with exact rational numbers and named offset bases
  - atomic name-keyed GID-to-CharString execution descriptor tracer
affects: [104-02, 104-03, 105-type2-interpreter, 106-cff-font-integration]

tech-stack:
  added: []
  patterns:
    - opt-in reuse of the canonical SFNT directory parser for CFF1
    - table-relative and Private-DICT-relative offset wrapper facts
    - parse-validate-preflight-revision-commit private publication

key-files:
  created:
    - modules/mb-font/font/cff_index.mbt
    - modules/mb-font/font/cff_dict.mbt
    - modules/mb-font/font/cff_admission.mbt
    - modules/mb-font/font/cff_admission_wbtest.mbt
    - modules/mb-font/font/cff_index_wbtest.mbt
    - modules/mb-font/font/cff_dict_wbtest.mbt
  modified:
    - modules/mb-font/font/directory.mbt

key-decisions:
  - "Reuse the canonical directory parser through a private allow_static_cff1 gate so existing public TrueType admission and capability outcomes remain unchanged."
  - "Represent DICT numbers as sign, magnitude, and denominator facts; no Double or unresolved numeric token reaches typed schemas."
  - "Reject explicit non-Type-2 CharstringType and recognized unsupported outline profiles before retaining a per-GID descriptor."

patterns-established:
  - "CFF INDEX: prove count, offset-array width, first/monotonic offsets, and terminal extent before creating object windows."
  - "Typed DICT: distinct Top/Font/Private reducers enforce arity, defaults, named bases, and duplicate singleton rejection."

requirements-completed: [CFF-01, CFF-02]

coverage:
  - id: D1
    description: "Exact static CFF1 profile, Header, shared INDEX, and typed DICT structural admission"
    requirement: CFF-01
    verification:
      - kind: unit
        ref: "moon test --target native (1171/1171; cff_admission_wbtest.mbt, cff_index_wbtest.mbt, cff_dict_wbtest.mbt)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Name-keyed GID 0 resolves to one bounded CharString and selected private environment"
    requirement: CFF-02
    verification:
      - kind: integration
        ref: "cff_admission_wbtest.mbt#CFF1 tracer admits default and explicit Type 2 then resolves GID zero"
        status: pass
    human_judgment: false

duration: 22min
completed: 2026-07-28
status: complete
---

# Phase 104 Plan 01: CFF1 Profile and Bounded Data Model Summary

**Bounded static-CFF1 OTTO admission now resolves a name-keyed GID through one shared INDEX/typed-DICT model to an atomic private CharString environment.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-07-28T09:44:15Z
- **Completed:** 2026-07-28T10:05:19Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added closed OTTO CFF1 profile precedence, maxp 0.5 validation, checked `CFF ` table authority, and unchanged legacy TrueType parsing behavior.
- Added one bounded INDEX decoder for empty and `offSize` 1–4 forms with checked 1-based object windows and deterministic structural errors.
- Added exact rational DICT number decoding and separate Top, Font, and Private schemas, including CID-facing ROS/FDArray/FDSelect facts for later plans.
- Added an atomic name-keyed GID tracer retaining caller-owned CharString, Private DICT, local Subrs, Global Subrs, and FontMatrix facts without Type 2 execution.

## Task Commits

Each task followed the TDD RED/GREEN sequence:

1. **Task 1 RED: CFF1 admission tracer tests** - `224f9861`
2. **Task 1 GREEN: bounded name-keyed CFF1 tracer** - `16dd77f9`
3. **Task 2 RED: INDEX and typed DICT contract tests** - `3f988bde`
4. **Task 2 GREEN: complete structural contracts** - `e1404a27`

## Files Created/Modified

- `modules/mb-font/font/directory.mbt` - Private opt-in OTTO/CFF1 path through the canonical SFNT directory parser.
- `modules/mb-font/font/cff_index.mbt` - Shared checked INDEX and object-window representation.
- `modules/mb-font/font/cff_dict.mbt` - Exact structural numbers and typed Top/Font/Private DICT schemas.
- `modules/mb-font/font/cff_admission.mbt` - Closed profile admission and atomic name-keyed GID descriptor tracer.
- `modules/mb-font/font/cff_admission_wbtest.mbt` - End-to-end profile, stage-boundary, atomicity, and CharstringType coverage.
- `modules/mb-font/font/cff_index_wbtest.mbt` - Empty/`offSize` 1–4 and hostile INDEX invariant coverage.
- `modules/mb-font/font/cff_dict_wbtest.mbt` - Numeric, default, arity, duplicate, offset-base, and CID seam coverage.

## Decisions Made

- The public `Font::open` TrueType route remains unchanged; only the private CFF admission seam opts into OTTO and the `CFF ` tag.
- Predefined/default DICT semantics stay typed and private, while custom offsets carry an explicit coordinate-space wrapper.
- The future Type 2 VM receives resolved views and facts only; no bytecode, bounds, paths, or public CFF-backed `Font` was introduced.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Targeted `moon fmt` formatted additional files in the package. Those unrelated mechanical changes were identified before staging and restored individually; no unrelated file entered a task commit.
- `state.advance-plan` could not parse the milestone's initial `Plan: —` placeholder. The placeholder was normalized to `Plan: 1 of 3`, after which the SDK handler advanced state successfully to Plan 2.

## TDD Gate Compliance

- RED commits: `224f9861`, `3f988bde`
- GREEN commits: `16dd77f9`, `e1404a27`
- Final verification: `moon test --target native` — 1171 passed, 0 failed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 104-02 can extend the retained typed facts into complete name-keyed charset/Encoding/SID resolution and the generalized per-GID keying model. Plan 104-03 can reuse the same INDEX/DICT/offset seams for CID FDArray/FDSelect resolution and collection rebasing.

## Self-Check: PASSED

- All seven implementation/test files and this SUMMARY exist on disk.
- TDD/task commits `224f9861`, `16dd77f9`, `3f988bde`, and `e1404a27` exist in repository history.

---
*Phase: 104-cff1-profile-and-bounded-data-model*
*Completed: 2026-07-28*
