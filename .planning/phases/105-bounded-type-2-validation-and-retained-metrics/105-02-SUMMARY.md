---
phase: 105-bounded-type-2-validation-and-retained-metrics
plan: "02"
subsystem: font-cff-type2
tags: [moonbit, cff1, type2, vm, subroutines, resource-bounds]

requires:
  - phase: 105-bounded-type-2-validation-and-retained-metrics
    plan: "01"
    provides: checked Q16.16 arithmetic, deterministic PRNG, per-GID CFF environments, and private Type 2 limits
provides:
  - one iterative non-geometry Type 2 interpreter over explicit root/local/global frames
  - exact hintmask/cntrmask byte framing with cumulative stem accounting
  - deterministic stack, transient, width, random, subroutine, termination, and execution-ledger semantics
  - stable State then Resource then Capability then Data error authority
affects: [105-03, 105-04, 106-cff1-outline-and-metrics]

tech-stack:
  added: []
  patterns:
    - one operator switch shared by validation and future geometry sinks
    - preflighted fixed-capacity VM mutation with staged named execution facts
    - explicit local/global frames instead of host recursion

key-files:
  created:
    - modules/mb-font/font/cff_type2.mbt
    - modules/mb-font/font/cff_type2_wbtest.mbt
    - modules/mb-font/font/cff_type2_fixture_wbtest.mbt
  modified: []

key-decisions:
  - "Treat uninitialized transient get as Data and mutate transient/PRNG/stack state only after operator preflight."
  - "Require at least one accumulated stem before mask bytes and consume exactly ceil(stems/8) opaque bytes."
  - "Permit subroutine endchar only when every suspended caller is tail-positioned; ordinary subroutines require a terminal return."
  - "Classify deprecated seac and recognized CFF2 operators as Capability after revision and resource authority."

patterns-established:
  - "Type 2 execution returns staged width, stem, geometry-recognition, and named ledger facts without committing caller budget."
  - "Every non-State VM failure exits through a final source-revision preference guard."

requirements-completed: [T2-01, T2-02]

coverage:
  - id: D1
    description: Complete deterministic non-geometry Type 2 scalar VM semantics
    requirement: T2-01
    verification:
      - kind: unit
        ref: modules/mb-font/font/cff_type2_wbtest.mbt
        status: pass
      - kind: integration
        ref: moon test --target native -j 2
        status: pass
    human_judgment: false
  - id: D2
    description: Exact hint masks plus bounded iterative local/global subroutine frames
    requirement: T2-02
    verification:
      - kind: unit
        ref: modules/mb-font/font/cff_type2_fixture_wbtest.mbt
        status: pass
      - kind: integration
        ref: moon test --target native -j 2
        status: pass
    human_judgment: false
  - id: D3
    description: Tail-only subroutine endchar and stable State/Resource/Capability/Data precedence
    requirement: T2-02
    verification:
      - kind: unit
        ref: modules/mb-font/font/cff_type2_fixture_wbtest.mbt
        status: pass
      - kind: integration
        ref: moon check --target native
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-28
status: complete
---

# Phase 105 Plan 02: Bounded Type 2 Frame Machine Summary

**A single iterative VM now validates the complete supported non-geometry Type 2 surface with exact mask framing, explicit subroutine frames, deterministic mutation, and ordered error authority.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-07-28T14:35:06Z
- **Completed:** 2026-07-28T15:00:28Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Executes Type 2 numbers, stack/transient operators, checked arithmetic and logic, optional widths, deterministic random, and recognized geometry handoff through one bounded VM.
- Consumes mask payloads as opaque bytes derived from cumulative stems and evaluates local/global subroutines through depth-, call-, byte-, and work-bounded explicit frames.
- Enforces root/tail-call termination, deprecated seac and CFF2 capability classification, revision dominance, and Resource-before-Capability/Data precedence.

## Task Commits

Each task followed a RED then GREEN cycle:

1. **Task 1 RED: scalar VM tests** - `2f255b27`
2. **Task 1 GREEN: deterministic scalar VM** - `36ff4b06`
3. **Task 2 RED: hint and subroutine frame tests** - `32095bcb`
4. **Task 2 GREEN: exact masks and iterative frames** - `8d8f4e84`
5. **Task 3 RED: termination and precedence fixtures** - `a6690fdf`
6. **Task 3 GREEN: tail termination and ordered errors** - `9bccee67`

## Files Created/Modified

- `modules/mb-font/font/cff_type2.mbt` - Private VM state, operator dispatch, explicit frames, hint framing, termination, and named execution ledger.
- `modules/mb-font/font/cff_type2_wbtest.mbt` - Scalar operator, arity, numeric, transient, random, width, stack, stem, and mask boundaries.
- `modules/mb-font/font/cff_type2_fixture_wbtest.mbt` - Bias, cross-kind frame, recursion, termination, mutation, and multi-fault fixtures.

## Decisions Made

- Width is always resolved to either the checked Private default or nominal-plus-explicit delta, but remains validation state and is never compared with `hmtx`.
- The shared operand/transient/PRNG state lives outside frames; frames retain only source identity, cursor, kind, and tail-call status.
- Repeated subroutine execution is recharged because bytes and work are accounted when fetched and dispatched, not when INDEX storage is retained.
- Geometry operators are recognized by this same switch and counted for the Plan 03 sink; no second validator/renderer interpreter is introduced.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Holding the pre-mutation `ByteView` across a native mutable lease caused the native test runtime to terminate before assertion reporting. The fixture now captures the old revision, performs the mutation, then obtains a fresh view over the same backing; this preserves the intended mutation-dominance proof and passes natively.

## Known Stubs

None. Empty arrays found by the stub scan are active mutable test builders or the bounded `roll` scratch copy, not unwired production data.

## Verification

- `moon test modules/mb-font/font --target native -j 2` — 217/217 passed.
- `moon test --target native -j 2` — 1226/1226 passed.
- `moon check --target native` — passed, 0 errors.

## User Setup Required

None.

## Next Phase Readiness

- Plan 105-03 can attach fixed-point bounds/path events to the existing geometry recognition seam without duplicating scalar, hint, call, or termination semantics.
- Plan 105-04 can consume the staged ledger and VM facts before the single admission commit.

## Self-Check: PASSED

- All three implementation/test files and this Summary exist.
- All six RED/GREEN task commits resolve in Git.
- The only remaining worktree change outside this plan is the pre-existing, explicitly excluded `.planning/config.json`.

---
*Phase: 105-bounded-type-2-validation-and-retained-metrics*
*Completed: 2026-07-28*
