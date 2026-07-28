---
phase: 104-cff1-profile-and-bounded-data-model
plan: "04"
subsystem: font
tags: [moonbit, opentype, cff1, typed-dict, bounded-parser]

requires:
  - phase: 104-cff1-profile-and-bounded-data-model
    provides: bounded CFF INDEX/DICT parsing, complete name/CID keying, and atomic structural admission
provides:
  - exact closed PaintType and StrokeWidth semantics for the supported filled-outline CFF1 profile
  - encounter-ordered Top DICT reduction before later malformed bytes are parsed
  - atomic admission regressions for semantic capability and typed-schema data failures
affects: [105-type2-interpreter, 106-cff-font-integration, 107-cff-qualification]

tech-stack:
  added: []
  patterns:
    - one incremental DICT parse core with collecting and typed-reduction consumers
    - completed-entry Top DICT reduction before scanning the next token

key-files:
  created: []
  modified:
    - modules/mb-font/font/cff_dict.mbt
    - modules/mb-font/font/cff_dict_wbtest.mbt
    - modules/mb-font/font/cff_admission_wbtest.mbt

key-decisions:
  - "Treat every successfully decoded CffNumber with magnitude zero as the supported PaintType/StrokeWidth default, independent of sign normalization or denominator."
  - "Return operator-specific Capability for every well-formed non-zero PaintType/StrokeWidth without integer or non-negative coercion."
  - "Use one incremental parser for both collected DICT entries and immediate Top reduction so first-encountered typed outcomes precede later malformed bytes."

patterns-established:
  - "Incremental DICT: decode each operand/operator exactly once, account its dict units, then invoke the consumer before scanning the next token."
  - "Closed semantic singleton: check completed-entry arity, then duplication, then value-domain capability."

requirements-completed: [CFF-01]

coverage:
  - id: D1
    description: "Top DICT accepts omitted or exact-zero PaintType/StrokeWidth and rejects every decoded non-zero value with stable operator-specific Capability."
    requirement: CFF-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/cff_dict_wbtest.mbt#CFF Top DICT closes PaintType and StrokeWidth profile"
        status: pass
    human_judgment: false
  - id: D2
    description: "Completed-entry Capability wins over later malformed bytes while earlier parser faults and typed arity/duplicate failures retain deterministic Data contexts."
    requirement: CFF-01
    verification:
      - kind: unit
        ref: "moon test modules/mb-font/font --target native --filter \"CFF Top DICT closes PaintType and StrokeWidth profile\""
        status: pass
    human_judgment: false
  - id: D3
    description: "Rejected PaintType/StrokeWidth admission publishes no descriptor and leaves bytes, allocations, allocation-size authority, and work unchanged."
    requirement: CFF-01
    verification:
      - kind: integration
        ref: "modules/mb-font/font/cff_admission_wbtest.mbt#CFF1 PaintType and StrokeWidth profile rejects atomically before publication"
        status: pass
      - kind: unit
        ref: "moon test --target native (1204/1204)"
        status: pass
      - kind: other
        ref: "moon check --target all"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-07-28
status: complete
---

# Phase 104 Plan 04: Closed CFF1 Paint Profile Summary

**Incremental Top DICT reduction now accepts only omitted or exact-zero PaintType/StrokeWidth semantics and rejects unsupported outlines before malformed suffixes, descriptor publication, or caller charge.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-28T13:14:01Z
- **Completed:** 2026-07-28T13:25:47Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Replaced Top DICT parse-then-reduce ordering with one shared incremental parser that emits each complete entry before scanning later bytes.
- Added dedicated PaintType and StrokeWidth reducers with exact-zero acceptance, non-zero Capability rejection, and operator-specific arity/duplicate Data contexts.
- Added direct schema and real admission matrices covering exact numbers, malformed encodings, double-fault precedence, zero publication, and unchanged caller budget authority.
- Preserved CFF name/CID keying, the existing Type 2 tracer, and standalone/selected-collection static-glyf fingerprints.

## Task Commits

The tracer task followed the TDD RED/GREEN sequence:

1. **Task 1 RED: PaintType/StrokeWidth schema and atomic admission regressions** - `b99df333` (test)
2. **Task 1 GREEN: incremental Top DICT profile enforcement** - `401589d0` (feat)

## Files Created/Modified

- `modules/mb-font/font/cff_dict.mbt` - Adds the incremental DICT parse core, Top builder/reducer, and closed PaintType/StrokeWidth branches.
- `modules/mb-font/font/cff_dict_wbtest.mbt` - Proves exact-zero/non-zero semantics, parser/reducer contexts, duplicates, and encounter ordering.
- `modules/mb-font/font/cff_admission_wbtest.mbt` - Extends the checked CFF fixture and proves atomic profile rejection through real admission.

## Decisions Made

- Used `CffNumber.magnitude == 0` as the semantic predicate so integer zero, exact-real zero, and normalized signed-real zero are equivalent.
- Kept PaintType and StrokeWidth as validated-but-unretained defaults because every accepted representation collapses to the same closed filled-outline profile.
- Kept Font and Private DICT consumers on the compatibility collecting wrapper while Top DICT reduces incrementally through the same parser.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The literal filters `CFF name keying` and `CFF CID` matched zero tests under the current `moon test --filter` behavior. Equivalent wildcard filters ran the complete intended groups (`5/5` name-keyed and `7/7` CID), and the full native suite also passed `1204/1204`.
- `state.advance-plan` correctly moved the phase to verification but retained the pre-gap-plan `3/3` prose position. The tracking prose was aligned with the SDK-calculated `4/4` progress and the completed gap plan.

## TDD Gate Compliance

- RED commit: `b99df333`; both new focused filters failed before production changes.
- GREEN commit: `401589d0`; both focused filters pass after incremental reduction.
- Auto-mode tracer feedback gate: the plan's Top DICT focused verification was rerun after GREEN and passed `1/1`.
- Final native verification: `moon test --target native` — `1204/1204` passed.
- Four-target static verification: `moon check --target all` — all four targets passed.

## Known Stubs

None.

## Threat Review

- T-104-15: exact-zero semantics are value-based; every decoded non-zero integer, real, fractional, or negative value returns the specified Capability.
- T-104-16: incremental entry emission freezes first-encountered Capability/Data precedence without a second parser or pre-scan.
- T-104-19: parser-level contexts remain unchanged; only completed PaintType/StrokeWidth entries use operator-specific arity, duplicate, and capability contexts.
- T-104-17: rejected end-to-end fixtures return no admitted facts and leave all caller budget dimensions unchanged.
- T-104-18: CFF-02 keying and public static-glyf behavior pass unchanged.
- No new network, authentication, file-access, schema, FFI, dependency, or public API surface was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CFF-01's sole verifier gap is closed at the typed Top DICT boundary.
- Phase 105 can rely on every admitted descriptor representing the supported filled-outline profile without reparsing PaintType or StrokeWidth.
- No blockers remain.

## Self-Check: PASSED

- All three planned implementation/test files and this summary exist on disk.
- TDD/task commits `b99df333` and `401589d0` exist in repository history.

---
*Phase: 104-cff1-profile-and-bounded-data-model*
*Completed: 2026-07-28*
