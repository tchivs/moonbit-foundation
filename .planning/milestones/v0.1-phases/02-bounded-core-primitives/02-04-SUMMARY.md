---
phase: 02-bounded-core-primitives
plan: "04"
subsystem: byte-ownership
tags: [moonbit, owned-bytes, validated-views, mutable-leases, resource-budget]

requires:
  - phase: 02-bounded-core-primitives
    plan: "01"
    provides: stable structured range, allocation, budget, and state errors
  - phase: 02-bounded-core-primitives
    plan: "02"
    provides: checked UInt64 ranges and backend index narrowing
  - phase: 02-bounded-core-primitives
    plan: "03"
    provides: atomic hierarchical pre-allocation budgets
provides:
  - opaque owned mutable byte storage with checked budgeted construction
  - retained zero-copy immutable byte views with relative validated subviews
  - callback-scoped exclusive mutable leases with stale-use rejection and checked disjoint splitting
  - deterministic injected allocator rejection without a false catchable physical-OOM claim
affects: [02-io, 04-image, 05-codec]

tech-stack:
  added: []
  patterns: [runtime-validated-lease-group, retained-validated-window, pre-allocation-approval]

key-files:
  created:
    - modules/mb-core/bytes/moon.pkg
    - modules/mb-core/bytes/owned_bytes.mbt
    - modules/mb-core/bytes/views.mbt
    - modules/mb-core/bytes/bytes_test.mbt
    - modules/mb-core/bytes/bytes_wbtest.mbt
  modified:
    - policy/foundation.json

key-decisions:
  - "Use a callback-scoped runtime lease group: split invalidates the parent, children remain disjoint, and the owner becomes available only after the final active child releases."
  - "Expose allocator rejection as a deterministic pre-allocation approval seam while documenting built-in physical OOM as unrecoverable on the portable pinned toolchain."
  - "Retain the owned FixedArray behind opaque immutable views, while copying external immutable Bytes into independent owned storage."

patterns-established:
  - "Lease validation: every mutable access checks handle activity and relative range before touching backing storage."
  - "Allocation ordering: checked narrowing, injected approval, atomic budget charge, then built-in allocation."

requirements-completed: [CORE-02]

coverage:
  - id: D1
    description: "Callback-scoped exclusive mutable leases reject overlap and stale use, consume split parents, and release idempotently after disjoint children finish"
    requirement: CORE-02
    verification:
      - kind: unit
        ref: "modules/mb-core/bytes/bytes_wbtest.mbt#exclusive lease and checked split tests"
        status: pass
      - kind: unit
        ref: "moon -C modules/mb-core test bytes --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Owned bytes and retained zero-copy views validate relative ranges, copy external immutable bytes, precharge budgets, and distinguish injected allocation rejection"
    requirement: CORE-02
    verification:
      - kind: unit
        ref: "modules/mb-core/bytes/bytes_test.mbt#owned storage and validated view tests"
        status: pass
      - kind: unit
        ref: "moon -C modules/mb-core test bytes --target all --frozen"
        status: pass
    human_judgment: false
  - id: D3
    description: "The bytes package has an exact four-target interface, dependency allowlist, and publication inventory in the root quality contract"
    requirement: CORE-02
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-16
status: complete
---

# Phase 02 Plan 04: Owned Bytes and Validated Views Summary

**Opaque budgeted byte storage with retained zero-copy views and runtime-validated callback-scoped mutable leases across all four portable targets**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-16T15:10:47Z
- **Completed:** 2026-07-16T15:20:59Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added opaque `OwnedBytes` construction with checked backend narrowing, injected allocation approval, atomic resource precharge, copied external `Bytes`, and an explicit non-catchable physical-OOM boundary.
- Added retained `ByteView` windows and callback-scoped `MutByteLease` access with relative bounds checks, overlap/stale rejection, parent-consuming disjoint splits, and idempotent cleanup.
- Qualified 10/10 bytes tests on js, wasm, wasm-gc, and native, then passed the full Required lane with 46/46 tests per target and exact 30-line interface classification.

## Task Commits

1. **Task 1 RED: Specify exclusive mutable lease behavior** - `7a7a48e` (test)
2. **Task 1 GREEN: Implement runtime-validated mutable leases** - `04b1200` (feat)
3. **Task 2 RED: Specify owned storage and validated views** - `7ad6d90` (test)
4. **Task 2 GREEN: Add owned bytes and retained views** - `bcf023f` (feat)
5. **Task 3: Register exact bytes package contract** - `ce7a483` (chore)

## Files Created/Modified

- `modules/mb-core/bytes/moon.pkg` - Portable package declaration importing only error, checked, and budget prerequisites.
- `modules/mb-core/bytes/owned_bytes.mbt` - Opaque owned storage, budgeted constructors, external copying, and allocator rejection seam.
- `modules/mb-core/bytes/views.mbt` - Retained immutable windows and exclusive runtime-validated mutable lease state machine.
- `modules/mb-core/bytes/bytes_test.mbt` - Public ownership, range, budget, copy, and allocation-failure contract tests.
- `modules/mb-core/bytes/bytes_wbtest.mbt` - Internal overlap, stale-use, split, retention, and cleanup invariants.
- `policy/foundation.json` - Exact bytes imports, semantic interface, targets, and publication contents.

## Decisions Made

- MoonBit does not statically prove borrow exclusivity, so v0.1 uses an opaque shared lease group with per-handle active state; it guarantees deterministic reentrant/interleaved rejection without claiming an unproven thread-safety guarantee.
- `Allocator` is an injectable approval/rejection seam before built-in allocation. Range and budget failures remain structured, injected rejection maps to `AllocationFailed`, and physical runtime OOM is not presented as catchable.
- Immutable views retain and share owned backing without exposing it. Conversion from external immutable `Bytes` copies so later owned mutation cannot alter the source.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Applied canonical MoonBit formatting before Required qualification**
- **Found during:** Task 3 (Register bytes and prove the green exit)
- **Issue:** The first Required run stopped at `WORK-04 format check` because the four new MoonBit files had not yet been passed through the pinned formatter.
- **Fix:** Formatted only the four plan-owned `.mbt` files, rechecked formatting, and reran the complete Required lane.
- **Files modified:** `modules/mb-core/bytes/bytes_test.mbt`, `modules/mb-core/bytes/bytes_wbtest.mbt`, `modules/mb-core/bytes/owned_bytes.mbt`, `modules/mb-core/bytes/views.mbt`
- **Verification:** `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` passed.
- **Committed in:** `ce7a483`

---

**Total deviations:** 1 auto-fixed (1 Rule 3 blocking correction)
**Impact on plan:** Formatting only canonicalized plan-owned source; public behavior and topology were unchanged.

## Issues Encountered

- The first Required run correctly rejected unformatted new MoonBit source. The scoped formatter correction resolved it, and the complete rerun passed.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. The new memory access surface is the planned threat-model scope: opaque retained windows mitigate disclosure, and runtime lease identity plus checked splitting mitigate overlapping mutation and denial-of-service paths.

## Next Phase Readiness

- Plan 02-05 can consume `ByteView` and `MutByteLease` without raw backing or ambient storage access.
- The exact dependency spine is now `error -> checked -> budget -> bytes`, with Required proving it on every declared target.

## Self-Check: PASSED

- All five bytes package files and the exact policy entry exist.
- Task commits `7a7a48e`, `04b1200`, `7ad6d90`, `bcf023f`, and `ce7a483` exist.
- `moon -C modules/mb-core test bytes --target all --frozen` passed 10/10 on every required target.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` passed with 46/46 tests per target, exact 30-line bytes interface classification, exact package contents, and read-only tracked proof.

---
*Phase: 02-bounded-core-primitives*
*Completed: 2026-07-16*
