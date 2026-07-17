---
phase: 02-bounded-core-primitives
plan: "08"
subsystem: byte-ownership
tags: [moonbit, mutable-leases, callback-cleanup, lifecycle, tdd]

requires:
  - phase: 02-bounded-core-primitives
    plan: "04"
    provides: callback-scoped mutable leases and checked disjoint splitting
  - phase: 02-bounded-core-primitives
    plan: "07"
    provides: exact public interfaces, executable docs, and fail-closed Required qualification
provides:
  - group-wide invalidation of retained split descendants on every callback exit
  - exact-once owner restoration with balanced nested split handle accounting
  - executable proof that mutable access can be reacquired after an unreleased split callback
affects: [02-verification, 04-image, 05-codec]

tech-stack:
  added: []
  patterns: [shared-lease-scope-invalidation, exact-once-owner-restoration, red-green-regression]

key-files:
  created: []
  modified:
    - modules/mb-core/bytes/views.mbt
    - modules/mb-core/bytes/bytes_test.mbt
    - modules/mb-core/bytes/bytes_wbtest.mbt
    - modules/mb-core/README.mbt.md

key-decisions:
  - "Callback cleanup closes the shared LeaseGroup scope, rather than releasing the parent handle consumed by split_mut."
  - "Nested split accounting applies a net increment of one handle, while group cleanup normalizes the count to zero and restores the owner once."

patterns-established:
  - "Lease scope: every mutable access and split requires both an active handle and an active shared group scope."
  - "Cleanup idempotence: explicit release may restore the owner early, but deferred scope cleanup never restores it a second time."

requirements-completed: [CORE-02]

coverage:
  - id: D1
    description: "Normal and structured-error callback exits invalidate every retained split descendant and permit immediate mutable reacquisition"
    requirement: CORE-02
    verification:
      - kind: unit
        ref: "modules/mb-core/bytes/bytes_test.mbt#split callback lifecycle regressions"
        status: pass
      - kind: unit
        ref: "moon -C modules/mb-core test bytes --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Nested descendants and zero, one, or all explicit child releases preserve balanced exact-once owner restoration"
    requirement: CORE-02
    verification:
      - kind: unit
        ref: "modules/mb-core/bytes/bytes_wbtest.mbt#nested and mixed cleanup regressions"
        status: pass
    human_judgment: false
  - id: D3
    description: "Executable documentation proves post-split reacquisition while exact interfaces, package contents, negative fixtures, and tracked-read-only behavior remain unchanged"
    requirement: CORE-02
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-17
status: complete
---

# Phase 02 Plan 08: Split Callback Lease Cleanup Summary

**Shared lease-group scope cleanup now invalidates all split descendants and restores mutable owner availability exactly once on normal and structured-error exits**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-16T16:35:27Z
- **Completed:** 2026-07-16T16:39:57Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Reproduced the confirmed leak on all four targets before implementation with public normal/error callback tests plus internal nested and mixed-release regressions.
- Moved callback cleanup to shared `LeaseGroup` scope state, made all descendant access group-aware, balanced nested split counts, and restored the owner at most once.
- Extended the executable README with post-split reacquisition and passed the complete Required lane: 66/66 tests per target, exact 30-line bytes interface, exact package contents, ten rejected negative fixtures, and tracked-read-only proof.

## Task Commits

1. **Task 1 RED: Reproduce split callback lease leak** - `a1eef49` (test)
2. **Task 1 GREEN: Clean up mutable lease groups on callback exit** - `589a78f` (feat)
3. **Task 2: Prove split callback lease reacquisition in public docs** - `b172c04` (docs)

## Files Created/Modified

- `modules/mb-core/bytes/views.mbt` - Shared callback scope state, exact-once owner restoration, and balanced nested split accounting.
- `modules/mb-core/bytes/bytes_test.mbt` - Public normal/error retained-descendant staleness and reacquisition regressions.
- `modules/mb-core/bytes/bytes_wbtest.mbt` - Internal nested split, mixed explicit release, normalized count, and exact-once invariants.
- `modules/mb-core/README.mbt.md` - Executable post-split mutable reacquisition proof.

## Decisions Made

- Keep the public byte API and exact semantic interface unchanged; the correction is entirely within private lease-group lifecycle state.
- Treat callback scope activity independently from per-handle activity so retained descendants fail closed without enumerating or mutating each handle.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The initial RED run failed all four new regressions on every required target, exactly matching the verifier's diagnosed parent-handle cleanup defect. GREEN resolved all failures.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. Retained descendant authority and owner availability were the plan's declared threat boundaries and are covered by group-scope checks and exact-once cleanup tests.

## Next Phase Readiness

- The sole Phase 2 verification gap is implemented and deterministically covered; Phase 2 is ready for independent re-verification.
- Downstream image and codec phases can rely on callback-scoped split leases without permanent owner poisoning or escaped descendant authority.

## Self-Check: PASSED

- All four modified implementation, test, and documentation files exist.
- Task commits `a1eef49`, `589a78f`, and `b172c04` exist in order.
- `moon -C modules/mb-core test bytes --target all --frozen` passed 14/14 on js, wasm, wasm-gc, and native.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` passed 66/66 tests per target, exact interfaces/package lists, all negative fixtures, and the read-only tracked proof.
- Stub scan found no TODO, FIXME, placeholder, coming-soon, or not-available markers in plan-modified files.

---
*Phase: 02-bounded-core-primitives*
*Completed: 2026-07-17*
