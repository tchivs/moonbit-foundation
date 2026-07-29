---
phase: 108-public-contract-and-transaction-skeleton
plan: "02"
subsystem: core-arithmetic
tags: [moonbit, int64, checked-arithmetic, portability, text-shaping]

requires:
  - phase: 108-01
    provides: checked charge composition and the public shaping transaction tracer
provides:
  - portable checked signed Int64 addition with exact MIN/MAX behavior
  - checked Int64 negation that rejects only the signed minimum
  - numerically guarded UInt64-to-Int64 narrowing
affects: [108-04, text-run-projection, signed-design-unit-arithmetic]

tech-stack:
  added: []
  patterns:
    - sign-branch overflow guards before signed addition
    - numeric range proof before representation-preserving reinterpretation

key-files:
  created: []
  modified:
    - modules/mb-core/checked/checked.mbt
    - modules/mb-core/checked/checked_test.mbt
    - modules/mb-core/checked/checked_wbtest.mbt

key-decisions:
  - "Shared signed helpers return InvalidInput/ArithmeticOverflow with the helper name as the stable operation for downstream rebinding."
  - "UInt64 narrowing compares against the exact Int64 maximum before reinterpret_as_int64 is permitted."

patterns-established:
  - "Signed add authority: select the positive, negative, or zero right-operand branch, prove its exact bound, then perform addition."
  - "Guarded representation conversion: reinterpretation is an implementation step after a numeric proof, never the proof itself."

requirements-completed: [TXT-02]

coverage:
  - id: D1
    description: "Checked signed addition and negation accept every exact Int64 boundary and reject one-step overflow with stable CoreError facts."
    requirement: TXT-02
    verification:
      - kind: unit
        ref: "modules/mb-core/checked/checked_test.mbt#checked Int64 addition accepts exact boundaries and rejects one-step overflow"
        status: pass
      - kind: unit
        ref: "modules/mb-core/checked/checked_test.mbt#checked Int64 negation rejects only the signed minimum"
        status: pass
    human_judgment: false
  - id: D2
    description: "UInt64-to-Int64 conversion accepts zero and the exact maximum while rejecting one-over and UInt64::MAX before reinterpretation."
    requirement: TXT-02
    verification:
      - kind: unit
        ref: "modules/mb-core/checked/checked_test.mbt#checked UInt64 to Int64 conversion proves the numeric maximum"
        status: pass
      - kind: unit
        ref: "modules/mb-core/checked/checked_wbtest.mbt#checked UInt64 to Int64 conversion guards before reinterpretation"
        status: pass
    human_judgment: false
  - id: D3
    description: "The checked package compiles warning-free and all 22 focused tests pass on js, wasm, wasm-gc, and native."
    requirement: TXT-02
    verification:
      - kind: other
        ref: "moon -C modules/mb-core check checked --target <js|wasm|wasm-gc|native> --deny-warn --frozen"
        status: pass
      - kind: other
        ref: "moon -C modules/mb-core test checked --target <js|wasm|wasm-gc|native> --frozen"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-07-30
status: complete
---

# Phase 108 Plan 02: Checked Int64 Arithmetic Summary

**Portable signed addition, negation, and UInt64 narrowing now preserve exact Int64 boundaries with structured overflow failures on all four MoonBit targets.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-29T21:28:08Z
- **Completed:** 2026-07-29T21:34:25Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Added sign-branch checked Int64 addition covering zero, mixed-sign cancellation, exact MIN/MAX edges, and one-step overflow.
- Added checked negation that rejects only `Int64::MIN` and stable `ArithmeticOverflow` error facts for downstream operation/context rebinding.
- Added exact UInt64-to-Int64 range proof before representation reinterpretation, with public and white-box boundary matrices passing on four targets.

## Task Commits

TDD gates and implementation were committed atomically:

1. **Task 1 RED: Add failing checked Int64 boundary tests** - `0a9ef29b` (test)
2. **Task 1 GREEN: Implement checked Int64 arithmetic** - `9ec77a11` (feat)

## Files Created/Modified

- `modules/mb-core/checked/checked.mbt` - Shared checked add, negate, and narrowing helpers.
- `modules/mb-core/checked/checked_test.mbt` - Public exact-boundary, overflow, and stable-error coverage.
- `modules/mb-core/checked/checked_wbtest.mbt` - Internal sign-branch and pre-reinterpretation range-proof coverage.

## Decisions Made

- Kept generic arithmetic failures in the existing `InvalidInput` category with `ArithmeticOverflow`, using each exact helper name as the stable operation.
- Preserved unsigned `requested` and `limit` facts for narrowing failures; signed add/negate failures omit unsigned-only magnitude fields rather than encode misleading values.
- Used bit reinterpretation only after proving `value <= 9223372036854775807UL`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced direct Result inspection with value-matching test helpers**

- **Found during:** Task 1 GREEN verification
- **Issue:** Directly inspecting `Result[Int64, CoreError]` requires `CoreError` to implement a debugging trait that is intentionally absent, so the newly resolvable tests would not compile.
- **Fix:** Matched successful results explicitly and inspected only the returned Int64 value; error branches continue asserting typed CoreError accessors.
- **Files modified:** `modules/mb-core/checked/checked_test.mbt`, `modules/mb-core/checked/checked_wbtest.mbt`
- **Verification:** All 22 focused tests pass on js, wasm, wasm-gc, and native.
- **Committed in:** `9ec77a11`

---

**Total deviations:** 1 auto-fixed (1 blocking test-harness correction).
**Impact on plan:** The correction changes only how tests observe successful values; public behavior and production scope are unchanged.

## Issues Encountered

- The exact module-wide `moon -C modules/mb-core check --target js --deny-warn --frozen` command stops on the pre-existing, out-of-scope `mb-font` CFF warning backlog already recorded in `.planning/WINDOWS.md` entry 61. Package-scoped `checked` checks pass with `--deny-warn`, and all focused tests pass on js, wasm, wasm-gc, and native.
- A relative edit briefly targeted the main checkout instead of the authorized orchestrator worktree. The exact hunk was removed immediately, leaving the main checkout with no diff, and all subsequent edits used containment-verified absolute worktree paths.

## Deferred Issues

- Clear the existing `mb-font` CFF warnings before treating workspace-resolved module-wide `--deny-warn` checks as a clean gate.

## Known Stubs

None.

## Threat Flags

None. The signed-extreme and unsigned-narrowing trust boundaries are covered by the plan threat model and focused boundary tests.

## TDD Gate Compliance

- RED gate: `0a9ef29b`
- GREEN gate: `9ec77a11`
- RED failed only for the three absent public helpers; GREEN follows it and passes the full focused four-target matrix.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 108-04 can consume the exact shared helpers for checked signed projection and total advance accumulation.
- Glyph ownership and other Phase 108 capabilities remain isolated to their own plans.

## Self-Check: PASSED

All three planned files, both TDD commits, the generated four-target helper interface, and the coverage classification were verified. `TXT-02` remains gated by unfinished sibling plans, so no premature requirement-state mutation was made.

---
*Phase: 108-public-contract-and-transaction-skeleton*
*Completed: 2026-07-30*
