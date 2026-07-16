---
phase: 04-image-model-views-and-operations
plan: "03"
subsystem: image-storage
tags: [moonbit, owned-image, retained-views, mutable-leases, atomic-budgets]

requires:
  - phase: 02-bounded-core-primitives
    provides: Atomic hierarchical budgets, checked arithmetic, owned bytes, and callback-scoped mutable leases
  - phase: 04-image-model-views-and-operations/04-02
    provides: Validated explicit image descriptors and checked planes
provides:
  - Atomic storage-plus-operation allocation with exact scalar charges
  - Descriptor-backed owned images and retained zero-copy immutable crops
  - Callback-scoped mutable image views with proved-disjoint logical splits
affects: [04-image-model-views-and-operations, image-operations, codecs]

tech-stack:
  added: []
  patterns:
    - Checked narrowing and allocator approval before one combined hierarchical charge
    - One enclosing byte lease shared by runtime-validated logical image descendants

key-files:
  created:
    - modules/mb-image/storage/moon.pkg
    - modules/mb-image/storage/owned_image.mbt
    - modules/mb-image/storage/views.mbt
    - modules/mb-image/storage/storage_test.mbt
    - modules/mb-image/storage/storage_wbtest.mbt
  modified:
    - modules/mb-core/bytes/owned_bytes.mbt
    - modules/mb-core/bytes/bytes_test.mbt
    - modules/mb-core/bytes/bytes_wbtest.mbt
    - policy/foundation.json

key-decisions:
  - "Construct one ResourceCharge inside mb-core/bytes from explicit storage, dimension, pixel, and work scalars after narrowing and allocator approval."
  - "Represent canonical empty immutable crops without backing while rejecting every empty mutable crop."
  - "Share one enclosing MutByteLease across logical descendants and prove both rectangle and addressed row-byte disjointness before split creation."

requirements-completed: [IMAG-02, IMAG-03, IMAG-04]

coverage:
  - id: D1
    description: Storage and operation dimensions commit once or leave every consumable counter unchanged.
    requirement: IMAG-02
    verification:
      - kind: unit
        ref: "modules/mb-core/bytes tests; 16/16 on js, wasm, wasm-gc, and native"
        status: pass
    human_judgment: false
  - id: D2
    description: Owned images retain validated descriptors and immutable packed crops remain zero-copy, including padded rows and canonical empty views.
    requirement: IMAG-03
    verification:
      - kind: unit
        ref: "modules/mb-image/storage tests; 9/9 on js, wasm, wasm-gc, and native"
        status: pass
    human_judgment: false
  - id: D3
    description: Mutable image authority is callback-scoped, stale after every exit, and splits only after logical and byte-range disjointness proofs.
    requirement: IMAG-04
    verification:
      - kind: integration
        ref: "scripts/quality.ps1 -Lane Required; 142/142 workspace tests per target"
        status: pass
    human_judgment: false

duration: 38min
completed: 2026-07-17
status: complete
---

# Phase 4 Plan 3: Safe Owned Image Storage Summary

**Atomic descriptor-backed storage, retained immutable crops, and one-lease callback-scoped mutable image authority across all four targets**

## Performance

- **Duration:** 38 min
- **Completed:** 2026-07-17
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added a single authoritative `OwnedBytes` transaction for allocation bytes plus explicit width, height, pixels, and work, with no partial failure consumption.
- Added owned images that retain validated descriptors and metadata, padded packed zero-copy crops, planar capability rejection, and a canonical backing-free empty immutable view.
- Added runtime-stale mutable image descendants over one enclosing byte lease, with empty/overlap rejection and per-row byte disjointness proof before split mutation.

## Task Commits

1. **Task 1 RED:** `f53e861` — failing combined allocation charge tests
2. **Task 1 GREEN:** `035dcc8` — atomic combined allocation charge
3. **Task 2 RED:** `abf76cd` — failing owned image and immutable view tests
4. **Task 2 GREEN:** `cd410fa` — owned images and retained immutable views
5. **Task 3 RED:** `ee801d6` — failing mutable image authority tests
6. **Task 3 GREEN:** `67d7108` — callback-scoped mutable views and exact policy

## Decisions Made

- Existing byte constructors delegate with zero extra dimensions so the new path cannot double-charge.
- Empty immutable crops canonicalize to zero-by-zero, no-backing views; mutable empties reject before lease access.
- Logical split descendants share the callback scope and underlying lease; each pair must be rectangle-disjoint and every addressed row interval must also be disjoint.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected storage publication entries to the mb-image module**
- **Found during:** Task 3 Required verification
- **Issue:** The first policy edit inserted six storage publication paths into the preceding mb-color module, causing its exact package allowlist to fail.
- **Fix:** Moved only those six entries into mb-image and reran the complete Required lane.
- **Files modified:** `policy/foundation.json`
- **Verification:** Required passed exact mb-color and mb-image package allowlists, interfaces, DAG, targets, and read-only proof.
- **Committed in:** `67d7108`

**Total deviations:** 1 auto-fixed bug. **Impact:** Policy placement only; no API or architecture change.

## Issues Encountered

- The Required lane's expected negative README fixture prints a missing-file error while the enclosing negative check succeeds; the lane completed with exit code 0.

## Verification

- `moon -C modules/mb-core test bytes --target all --frozen`: 16/16 passed on each target.
- `moon -C modules/mb-image test storage --target all --frozen`: 9/9 passed on each target.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`: passed with 142/142 workspace tests per target and the 39-line exact storage interface.

## Self-Check: PASSED

- All five storage package files and four modified contract/policy files exist.
- All six RED/GREEN task commits resolve in repository history.
- No stubs, new network/filesystem/auth surface, raw mutable backing, or escaped active authority remain.

## Next Phase Readiness

- Plan 04-04 can implement fresh copy and flips over `ImageView`/`MutImageView` while forwarding one explicit combined output charge.
- No blockers remain.

---
*Phase: 04-image-model-views-and-operations*
*Completed: 2026-07-17*
