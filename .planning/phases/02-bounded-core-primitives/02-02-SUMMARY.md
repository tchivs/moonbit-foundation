---
phase: 02-bounded-core-primitives
plan: "02"
subsystem: checked-core
tags: [moonbit, checked-arithmetic, half-open-ranges, portable-narrowing]

requires:
  - phase: 02-bounded-core-primitives
    plan: "01"
    provides: stable CoreError vocabulary and exact package classifiers
provides:
  - guarded UInt64 addition, subtraction, multiplication, alignment, and offset movement
  - centralized checked UInt64-to-Int narrowing and allocation sizing
  - opaque half-open CheckedRange and prevalidated Dimensions contracts
  - exact checked package topology, interface, imports, and publication inventory
affects: [02-budget, 02-bytes, 02-io, 03-color, 04-image]

tech-stack:
  added: []
  patterns: [guard-before-operator, explicit-width logical quantities, opaque validated values]

key-files:
  created:
    - modules/mb-core/checked/moon.pkg
    - modules/mb-core/checked/checked.mbt
    - modules/mb-core/checked/range.mbt
    - modules/mb-core/checked/dimensions.mbt
    - modules/mb-core/checked/checked_test.mbt
    - modules/mb-core/checked/checked_wbtest.mbt
  modified:
    - modules/mb-core/error/core_error.mbt
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1

key-decisions:
  - "Keep logical counts and positions as UInt64 and permit direct UInt64-to-Int conversion only inside checked_narrow_int after the pinned 2147483647 ceiling guard."
  - "Represent arithmetic underflow, invalid alignment, invalid offset, narrowing failure, and invalid dimensions with distinct stable error codes."
  - "Treat empty half-open ranges, including an empty range at UInt64 maximum, as valid and non-overlapping."

patterns-established:
  - "Checked arithmetic: every wrapping operator is dominated by a non-overflowing precondition guard."
  - "Validated models: ranges and dimensions store only values derived through checked constructors."

requirements-completed: [CORE-01]

coverage:
  - id: D1
    description: "Checked arithmetic, offsets, alignment, narrowing, and allocation sizing reject boundary violations before operators or conversion"
    requirement: CORE-01
    verification:
      - kind: unit
        ref: "moon -C modules/mb-core test checked --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Opaque half-open ranges and dimensions preserve valid empty boundaries while rejecting overflow and escaped subranges"
    requirement: CORE-01
    verification:
      - kind: unit
        ref: "moon -C modules/mb-core test checked --target all --frozen"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exact checked package imports, semantic interface, targets, publication contents, and read-only qualification are synchronized"
    requirement: CORE-01
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 13min
completed: 2026-07-16
status: complete
---

# Phase 02 Plan 02: Checked Arithmetic, Ranges, and Dimensions Summary

**Guard-before-operator UInt64 contracts with centralized backend narrowing, opaque half-open ranges, validated dimensions, and exact four-target qualification**

## Performance

- **Duration:** 13 min
- **Started:** 2026-07-16T14:35:04Z
- **Completed:** 2026-07-16T14:47:50Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added checked addition, subtraction, multiplication, power-of-two alignment, offset movement, backend narrowing, and allocation-size calculation with distinct structured failures.
- Added opaque `CheckedRange` and `Dimensions` values with valid empty boundaries, exact half-open adjacency, relative subrange containment, and prevalidated pixel counts.
- Registered the exact error/checked interfaces and publication contents, then passed the full Required lane with 27/27 tests on each of js, wasm, wasm-gc, and native.

## Task Commits

1. **Task 1 RED: Specify checked arithmetic boundaries** - `165a507` (test)
2. **Task 1 GREEN: Implement checked arithmetic and offsets** - `2d1e420` (feat)
3. **Task 2 RED: Specify checked range and dimension contracts** - `e5dbf32` (test)
4. **Task 2 GREEN: Add checked ranges and dimensions** - `6227448` (feat)
5. **Task 3: Register checked package invariants** - `5d3cc42` (chore)

## Files Created/Modified

- `modules/mb-core/checked/checked.mbt` - Guarded arithmetic, offsets, alignment, narrowing, and allocation sizes.
- `modules/mb-core/checked/range.mbt` - Opaque checked half-open ranges and relative subranges.
- `modules/mb-core/checked/dimensions.mbt` - Opaque dimensions, pixel counts, and storage sizing.
- `modules/mb-core/checked/checked_test.mbt` - Public boundary and structured-failure contract tests.
- `modules/mb-core/checked/checked_wbtest.mbt` - Internal guard adjacency and ordering probes.
- `modules/mb-core/checked/moon.pkg` - Four-target package with the sole MNF dependency on `error`.
- `modules/mb-core/error/core_error.mbt` - Distinct checked-operation error codes and canonical tokens.
- `policy/foundation.json` - Exact checked package interface, import, target, and publication allowlists.
- `scripts/quality/Assert-Policy.ps1` - Fail-closed parsing for the pinned brace-form package import syntax.

## Decisions Made

- Logical quantities remain `UInt64`; the pinned 32-bit `Int` ceiling is checked centrally before the only direct `to_int()` conversion.
- Empty ranges are valid at any representable boundary and never overlap, while touching non-empty ranges are adjacent rather than overlapping.
- Range and dimension overflow are remapped into domain-specific stable codes rather than leaking lower-level arithmetic overflow semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added distinct checked-operation error codes**
- **Found during:** Task 1 implementation
- **Issue:** The prerequisite error vocabulary lacked the plan-required distinct codes for underflow, invalid offsets/alignment, narrowing failure, and invalid dimensions.
- **Fix:** Extended `ErrorCode` and its canonical renderer tokens without changing error representation or category semantics.
- **Files modified:** `modules/mb-core/error/core_error.mbt`, `policy/foundation.json`
- **Verification:** Checked tests and exact generated-interface classification passed on all four targets.
- **Committed in:** `2d1e420` and synchronized in `5d3cc42`

**2. [Rule 3 - Blocking] Generalized exact policy parsing for pinned brace-form imports**
- **Found during:** Task 3 Required verification
- **Issue:** The policy validator accepted only a legacy single-line import form that the pinned MoonBit parser rejects, so the first real package dependency could not satisfy both compiler and policy.
- **Fix:** Added strict brace-block parsing with exact quoted-entry validation while retaining duplicate and allowlist rejection.
- **Files modified:** `scripts/quality/Assert-Policy.ps1`
- **Verification:** Foundation policy validation and the full Required lane passed.
- **Committed in:** `5d3cc42`

---

**Total deviations:** 2 auto-fixed (1 missing critical, 1 blocking)
**Impact on plan:** Both fixes were necessary to express and qualify the locked checked contract; no new package dependency or broader topology was introduced.

## Issues Encountered

- An early unscoped formatter invocation proposed the explicitly deferred `moon.mod.json` to `moon.mod` migration. The generated files were removed and the three original manifests restored before any task commit; subsequent formatting used explicit source paths and Required's protected source inventory.
- Required's read-only proof intentionally failed while Task 3 changes were uncommitted; after the atomic Task 3 commit, the same full lane passed with an unchanged tracked checkout.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The only placeholder-related scan hit is the pre-existing policy validator that rejects placeholder approval evidence.

## Threat Flags

None. The plan adds no network, filesystem, authentication, schema, or ambient-host surface.

## Next Phase Readiness

- Plan 02-03 can build atomic hierarchical budgets on checked arithmetic and the shared structured error vocabulary.
- `error -> checked` is the sole MNF package dependency, and Required proves the exact topology and all four portable targets.

## Self-Check: PASSED

- All six checked package files exist.
- Task commits `165a507`, `2d1e420`, `e5dbf32`, `6227448`, and `5d3cc42` exist.
- `moon -C modules/mb-core test checked --target all --frozen` passed 16/16 per target.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` passed with 27/27 tests per target, exact interfaces/packages, and read-only tracked proof.

---
*Phase: 02-bounded-core-primitives*
*Completed: 2026-07-16*
