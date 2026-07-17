---
phase: 02-bounded-core-primitives
plan: "03"
subsystem: resource-budget
tags: [moonbit, atomic-budget, hierarchical-limits, denial-of-service]

requires:
  - phase: 02-bounded-core-primitives
    plan: "01"
    provides: stable Resource/BudgetExceeded structured error vocabulary
  - phase: 02-bounded-core-primitives
    plan: "02"
    provides: checked UInt64 subtraction and portable logical quantity rules
provides:
  - atomic multidimensional pre-work charges across bytes, allocations, dimensions, pixels, and work
  - shared hierarchical child budgets that can only narrow ancestor allowance
  - balanced shared nesting-depth scopes with idempotent leave and deferred cleanup
  - exact budget package topology, interface, targets, and publication inventory
affects: [02-bytes, 02-io, 04-image, 05-codec]

tech-stack:
  added: []
  patterns: [preflight-then-commit, shared-window-chain, deferred-scope-cleanup]

key-files:
  created:
    - modules/mb-core/budget/moon.pkg
    - modules/mb-core/budget/budget.mbt
    - modules/mb-core/budget/budget_test.mbt
    - modules/mb-core/budget/budget_wbtest.mbt
  modified:
    - policy/foundation.json

key-decisions:
  - "Treat bytes, allocation count, pixels, and work as consumable counters while allocation size and dimensions are per-operation ceilings and depth is a balanced shared ceiling."
  - "Represent hierarchy as a chain of shared mutable windows, preflight every ancestor and every charge dimension, then commit all consumable counters only after the complete preflight succeeds."
  - "Return Resource/BudgetExceeded with a bounded dimension token in structured context so callers can identify the rejected limit without parsing prose."

patterns-established:
  - "Atomic budgets: no ledger field mutates until the complete charge passes every local and ancestor window."
  - "Hierarchical limits: children copy only the window-reference chain and append a non-expanding local allowance."

requirements-completed: [CORE-07]

coverage:
  - id: D1
    description: "Atomic UInt64 resource charges reject exact-boundary overflow, multidimensional failures, excessive allocation or dimensions, and work limits without partial consumption"
    requirement: CORE-07
    verification:
      - kind: unit
        ref: "moon -C modules/mb-core test budget --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Narrowed child budgets consume shared ancestor state and balanced depth scopes clean up on success, error, repeated leave, and limit rejection"
    requirement: CORE-07
    verification:
      - kind: unit
        ref: "moon -C modules/mb-core test budget --target all --frozen"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exact budget imports, semantic interface, targets, and publication contents are synchronized with the root quality contract"
    requirement: CORE-07
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-07-16
status: complete
---

# Phase 02 Plan 03: Atomic Hierarchical Resource Budgets Summary

**Preflight-then-commit UInt64 budgets with shared narrowed child windows, balanced nesting leases, and exact four-target qualification**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-16T14:57:27Z
- **Completed:** 2026-07-16T15:04:16Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added opaque `ResourceLimits`, `ResourceCharge`, `Budget`, and `BudgetScope` contracts covering bytes, allocation count/size, dimensions, pixels, nesting depth, and abstract work.
- Added all-ancestor preflight and atomic commit semantics so rejected multidimensional charges consume nothing and descendants cannot reset or bypass parent allowance.
- Added deterministic `with_depth` cleanup and idempotent `leave`, then qualified 9/9 budget tests on js, wasm, wasm-gc, and native and passed the full Required lane with 36/36 tests per target.

## Task Commits

1. **Task 1 RED: Specify atomic hierarchical budget behavior** - `5b4b543` (test)
2. **Task 1 GREEN: Implement atomic hierarchical resource budgets** - `9023ca5` (feat)
3. **Task 2: Register exact budget package contract** - `336282e` (chore)

## Files Created/Modified

- `modules/mb-core/budget/budget.mbt` - Opaque limit/charge values, shared hierarchical ledger windows, atomic charging, narrowed children, and balanced depth scopes.
- `modules/mb-core/budget/budget_test.mbt` - Public threshold, rollback, hierarchy, cap, UInt64, and cleanup behavior.
- `modules/mb-core/budget/budget_wbtest.mbt` - Internal mutation-order and full-width precision probes.
- `modules/mb-core/budget/moon.pkg` - Portable package declaration importing only checked and error prerequisites.
- `policy/foundation.json` - Exact budget interface, import, target, and publication allowlists.

## Decisions Made

- Consumable allowance is tracked for bytes, allocation count, pixels, and work; allocation size, width, and height are checked as per-operation ceilings.
- Each child retains the ancestor window references and adds one narrowed local window, allowing complete preflight across the whole hierarchy before any commit.
- Nesting uses an idempotent scope lease, and `with_depth` uses `defer` so both successful and structured-error callback results restore shared depth.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Exact Interface] Included the package-private budget window type in policy classification**
- **Found during:** Task 2 Required verification
- **Issue:** `moon info` emits the opaque package-private `type BudgetWindow` line, leaving the first policy entry one semantic line short.
- **Fix:** Added the exact generated line without making the type public or changing the package surface.
- **Files modified:** `policy/foundation.json`
- **Verification:** The rerun classified all 34 budget semantic lines and the full Required lane passed.
- **Committed in:** `336282e`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 exact-classification correction)
**Impact on plan:** The correction only synchronized machine policy with the generated interface; runtime behavior and package topology were unchanged.

## Issues Encountered

- The first Required run reached interface classification after all four-target tests passed, then reported the single missing package-private interface line. Adding that exact generated line resolved the mismatch; the complete rerun passed.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. The package introduces no network, filesystem, authentication, schema, FFI, or ambient-host surface; its resource ledger directly mitigates the planned denial-of-service threat.

## Next Phase Readiness

- Plan 02-04 can precharge owned byte allocation through `Budget::charge` and reuse shared child scopes without resetting allowance.
- The exact dependency spine is now `error -> checked -> budget`, and Required proves the budget contract on all four portable targets.

## Self-Check: PASSED

- All four budget package files exist.
- Task commits `5b4b543`, `9023ca5`, and `336282e` exist.
- `moon -C modules/mb-core test budget --target all --frozen` passed 9/9 on each required target.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` passed with 36/36 tests per target, exact 34-line budget interface classification, exact package contents, and read-only tracked proof.

---
*Phase: 02-bounded-core-primitives*
*Completed: 2026-07-16*
