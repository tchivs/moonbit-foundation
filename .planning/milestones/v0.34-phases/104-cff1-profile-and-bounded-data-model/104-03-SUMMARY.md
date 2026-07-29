---
phase: 104-cff1-profile-and-bounded-data-model
plan: "03"
subsystem: font
tags: [moonbit, opentype, cff1, collections, bounded-admission]

requires:
  - phase: 104-cff1-profile-and-bounded-data-model
    provides: checked CFF INDEX/DICT parsing and complete name/CID per-GID environments
provides:
  - exact private CFF structural ceilings and named work/allocation charge facts
  - one atomic standalone or selected-collection CFF1 admission transaction
  - hostile exact/one-short, mutation, authority, and precedence evidence
  - closed private Glyf or complete-Cff1 outline-source promotion boundary
  - frozen public standalone and collection static-glyf fingerprints
affects: [105-type2-interpreter, 106-cff-font-integration, 107-cff-qualification]

tech-stack:
  added: []
  patterns:
    - one root-relative selected-face directory adapted to a checked table-local CFF window
    - deferred ledger preflight followed by final revision guard and one atomic charge
    - closed private outline-source promotion from complete admitted facts only

key-files:
  created:
    - modules/mb-font/font/cff_hostile_fixture_wbtest.mbt
  modified:
    - modules/mb-font/font/limits.mbt
    - modules/mb-font/font/tables.mbt
    - modules/mb-font/font/directory.mbt
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/cff_admission.mbt
    - modules/mb-font/font/collection_wbtest.mbt
    - modules/mb-font/font/font_wbtest.mbt
    - modules/mb-font/font/collection_test.mbt
    - modules/mb-font/font/font_test.mbt

key-decisions:
  - "Derive all private CFF structural ceilings from the existing non-zero FontLimits contract and closed format maxima; do not add a second public limits surface."
  - "Use the existing deferred FontAdmissionLedger for both standalone and selected-collection CFF transactions, committing only after the final source-revision guard."
  - "Keep the private outline source closed over Glyf or one complete AdmittedCff1 aggregate; Phase 104 does not expose a public CFF-backed Font."

patterns-established:
  - "CFF structural charge retains each opaque ResourceCharge dimension beside named structural facts so exact/one-less qualification is independently observable."
  - "Collection CFF admission preserves root-relative SFNT table records and shares the same table-local admission implementation as standalone CFF."

requirements-completed: [CFF-01, CFF-02]

coverage:
  - id: D1
    description: "Standalone and selected collection CFF1 facts pass one bounded atomic transaction with exact authority, one-short failure, and final mutation protection."
    requirement: CFF-01
    verification:
      - kind: integration
        ref: "modules/mb-font/font/collection_wbtest.mbt#selected collection CFF1 facts use one bounded atomic shared-table transaction"
        status: pass
      - kind: unit
        ref: "moon test --target native (1190/1190)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Generated hostile CFF fixtures lock structural exact/one-short boundaries, named charge dimensions, atomic absence, and state/resource/capability/data precedence."
    requirement: CFF-02
    verification:
      - kind: integration
        ref: "modules/mb-font/font/cff_hostile_fixture_wbtest.mbt (3 matrix tests)"
        status: pass
      - kind: unit
        ref: "moon check --target all"
        status: pass
    human_judgment: false
  - id: D3
    description: "Only complete private CFF facts cross the closed outline-source boundary while public standalone and collection static-glyf behavior stays frozen."
    requirement: CFF-02
    verification:
      - kind: integration
        ref: "modules/mb-font/font/font_wbtest.mbt#private outline source accepts complete CFF facts and no partial or mixed state"
        status: pass
      - kind: integration
        ref: "modules/mb-font/font/font_test.mbt and collection_test.mbt Phase 104 static-glyf fingerprints"
        status: pass
    human_judgment: false

duration: 27min
completed: 2026-07-28
status: complete
---

# Phase 104 Plan 03: Bounded Atomic CFF1 Admission Summary

**Exact private CFF1 structural charges now admit standalone or shared collection tables atomically, retain no hostile partial state, and cross only a closed private outline-source boundary.**

## Performance

- **Duration:** 27 min
- **Started:** 2026-07-28T10:38:29Z
- **Completed:** 2026-07-28T11:04:40Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Derived private CFF structural ceilings and exact named Header, INDEX, DICT, charset, Encoding, FD, SID/CID, descriptor, retained-allocation, and caller-budget charge facts.
- Routed non-zero selected collection directories with shared root-relative table records into the same checked table-local admission transaction as standalone CFF1, with one final revision guard and one charge.
- Added generated hostile exact/one-short and multi-fault evidence asserting zero retained facts and zero charge on every failure.
- Added a closed private `Glyf | Cff1(AdmittedCff1)` promotion boundary while keeping public CFF-backed font/path behavior absent.
- Frozen public standalone and selected-collection static-glyf metrics, mapping, kerning, outline, profile, and charge fingerprints.

## Task Commits

Each task followed the TDD RED/GREEN sequence:

1. **Task 1 RED: selected collection CFF tracer** - `096d126f` (test)
2. **Task 1 GREEN: atomic collection CFF admission** - `53cc31fe` (feat)
3. **Task 2 RED: hostile exact/one-short matrix** - `7c828d0b` (test)
4. **Task 2 GREEN: named charge and precedence enforcement** - `c33e610a` (feat)
5. **Task 3 RED: closed promotion and glyf fingerprints** - `2b813a38` (test)
6. **Task 3 GREEN: closed private outline source** - `fc5b46e3` (feat)
7. **Task 3 REFACTOR: intentional private seams** - `f95fc96f` (refactor)

## Files Created/Modified

- `modules/mb-font/font/limits.mbt` - Derives private non-zero CFF structural ceilings.
- `modules/mb-font/font/tables.mbt` - Adds deferred atomic preflight/commit over the existing admission ledger.
- `modules/mb-font/font/directory.mbt` - Adapts standalone or non-zero selected directories without rebasing root-relative table records.
- `modules/mb-font/font/cff_admission.mbt` - Owns exact named charges, shared admission routing, precedence, revision guards, and one private-fact commit.
- `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt` - Generated structural/resource/mutation/precedence matrix with atomicity assertions.
- `modules/mb-font/font/collection_wbtest.mbt` - Private shared-CFF collection authority and exact/one-short transaction tracer.
- `modules/mb-font/font/font.mbt` - Closed private Glyf/Cff1 outline-source representation.
- `modules/mb-font/font/font_wbtest.mbt` - Complete CFF promotion plus partial/mixed rejection evidence.
- `modules/mb-font/font/collection_test.mbt` - Public selected static-glyf compatibility fingerprint only.
- `modules/mb-font/font/font_test.mbt` - Public standalone static-glyf compatibility fingerprint only.

## Decisions Made

- Retained all CFF limits and admitted facts as private implementation details; the existing public `FontLimits`, `Font`, outline, and collection surfaces remain unchanged.
- Counted CFF table bytes and explicit named structural/keying units under checked arithmetic so each exact/one-less boundary has a stable charge dimension.
- Performed source-revision checks before attacker/resource classification and again immediately before commit, preserving deterministic state-first failure and zero publication.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- A repository-wide `moon fmt --check` invocation reported pre-existing formatting drift in unrelated package files because this toolchain formats the whole package even when file paths are provided. No unrelated formatting changes were written or staged.

## TDD Gate Compliance

- RED commits: `096d126f`, `7c828d0b`, `2b813a38`
- GREEN commits: `53cc31fe`, `c33e610a`, `fc5b46e3`
- REFACTOR commit: `f95fc96f`
- Final native verification: `moon test --target native` — 1190 passed, 0 failed.
- Four-target static verification: `moon check --target all` — passed with 0 warnings.

## Known Stubs

None.

## Threat Review

- T-104-09: non-zero selected directories preserve root-relative records and share one table-local CFF transaction.
- T-104-10: every named structural and retained dimension uses checked arithmetic, derived ceilings, and exact caller preflight.
- T-104-11: revision drift wins before final commit and leaves both admitted facts and caller charge absent.
- T-104-12: no constructor accepts partial CFF state; only complete `AdmittedCff1` can form the private CFF outline-source case.
- T-104-13: generated multi-fault evidence freezes state, resource, capability, then supported-data outcomes.
- T-104-14: public black-box tests inspect only existing standalone and collection static-glyf behavior.
- No new network, authentication, file-access, schema, FFI, or public API surface was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 105 can consume one complete private per-GID CFF environment through the closed source boundary without reparsing collection offsets, FDSelect, DICT, or keying data.
- Structural resource, mutation, and error precedence are frozen for the future Type 2 interpreter.
- No blockers remain.

## Self-Check: PASSED

- All ten planned implementation/test files and this summary exist on disk.
- Task commits `096d126f`, `53cc31fe`, `7c828d0b`, `c33e610a`, `2b813a38`, `fc5b46e3`, and `f95fc96f` exist in repository history.

---
*Phase: 104-cff1-profile-and-bounded-data-model*
*Completed: 2026-07-28*
