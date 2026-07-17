---
phase: 04-image-model-views-and-operations
plan: "09"
subsystem: image-storage-safety
tags: [moonbit, budgets, planar-layout, retained-views, fail-closed]

requires:
  - phase: 04-image-model-views-and-operations/04-08
    provides: Completed image contracts and exact four-target qualification
provides:
  - Descriptor-derived atomic operation allocation without forgeable charge scalars
  - Fail-closed planar byte and mutable authority gates before backing access
  - Exact interface and synthetic-negative regression gates for both verifier gaps
affects: [05-bounded-ppm-p6-proof, image-operations, image-storage]

tech-stack:
  added: []
  patterns:
    - Derive width, height, and pixels from an opaque validated descriptor
    - Gate unsupported layouts before ByteView access or mutable lease acquisition

key-files:
  created: []
  modified:
    - modules/mb-image/storage/owned_image.mbt
    - modules/mb-image/storage/views.mbt
    - modules/mb-image/storage/storage_test.mbt
    - modules/mb-image/storage/storage_wbtest.mbt
    - modules/mb-image/ops/copy_flip.mbt
    - modules/mb-image/ops/orientation.mbt
    - modules/mb-image/ops/resize.mbt
    - modules/mb-image/ops/convert.mbt
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1

key-decisions:
  - "Keep OwnedImage::new_operation public for cross-package operations, but accept only a validated descriptor, budget, allocator, and explicit operation work."
  - "Preserve OwnedImage::view() -> ImageView exactly while allowing planar full views to expose safe descriptive state only."
  - "Reject non-packed-U8 byte and mutable access before backing authority, with defense-in-depth gates inside mutable accessors."

requirements-completed: [IMAG-02, IMAG-03, IMAG-04, IMAG-05]

duration: 25min
completed: 2026-07-17
status: complete
---

# Phase 4 Plan 9: Allocation and Planar Authority Gap Closure Summary

**Descriptor-derived atomic charges and packed-U8 authority gates close both Phase 4 verifier blockers without narrowing the general planar descriptor model.**

## Performance

- **Duration:** 25 min
- **Completed:** 2026-07-17
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Removed public width, height, pixel, and `ResourceCharge` authority from image operation allocation; the storage package now derives descriptor dimensions and pixels internally and atomically charges once with explicit work.
- Preserved `OwnedImage::view() -> ImageView` while making reordered planar full views descriptive-only: byte, crop, and mutable authority fail with stable `CapabilityUnavailable` errors before backing access or lease acquisition.
- Added exact failure snapshots for independently underfunded width, height, pixels, and work, plus a single exact success charge.
- Added reordered-plane sentinel, metadata, budget, raw-lease availability, and immediate reacquisition regressions.
- Migrated copy, flips, orientation, resize, and conversion to descriptor-plus-work allocation and added fail-closed policy/source negatives.

## Task Commits

1. **RED: allocation and reordered-planar regressions** - `cd1c401` (test)
2. **GREEN: safe allocation seam, planar gates, operation migration, and exact negatives** - `5fb1f88` (fix)
3. **Formatter-exact public regression assertions** - `6187d6f` (style)

## Decisions Made

- Kept the cross-package operation factory public because `ops` is a separate package, but made its only caller-provided accounting scalar explicit deterministic work.
- Reused the existing storage `CapabilityUnavailable` vocabulary and bounded stable contexts instead of adding a new error code.
- Treated dimension limits as checked ceilings and bytes, allocations, pixels, and work as consumable counters, matching the established mb-core budget contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Atomic interface migration] Migrated every operation caller in the same GREEN commit**
- **Found during:** Task 1 GREEN compilation
- **Issue:** Removing charge scalars is a package interface change; committing storage alone would leave the `ops` package uncompilable.
- **Fix:** Migrated copy/flip, orientation, resize, and conversion callers together with the safe storage factory.
- **Files modified:** `modules/mb-image/storage/owned_image.mbt`, four `modules/mb-image/ops/*.mbt` callers
- **Verification:** Storage and ops both pass on all four targets.
- **Commit:** `5fb1f88`

**Total deviations:** 1 blocking atomic-migration adjustment. **Impact:** No scope expansion; it preserves a buildable commit boundary.

## Issues Encountered

- The Required lane's intentional missing-README negative emits a native canonicalization error while the enclosing negative succeeds; the lane exited 0 as designed.
- The pinned formatter attempted manifest migration; generated `moon.mod` files were removed and the tracked `moon.mod.json` files restored before commits.

## User Setup Required

None.

## Verification

- `moon -C modules/mb-image test storage --target all --frozen`: 14/14 passed on each of js, wasm, wasm-gc, and native.
- `moon -C modules/mb-image test ops --target all --frozen`: 18/18 passed on each target.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`: passed with 174/174 workspace tests per target, exact 39-line storage interface, all new image negatives, generated evidence, package policy, and read-only proof.

## Self-Check: PASSED

- All 11 modified implementation, regression, policy, and quality files exist.
- Commits `cd1c401`, `5fb1f88`, and `6187d6f` resolve in repository history.
- No TODO/FIXME/placeholder stub or new host, filesystem, network, authentication, registry, codec, or schema surface was introduced.

## Next Phase Readiness

- Both failures recorded in `04-VERIFICATION.md` now have behavioral, counter, sentinel, lease, interface, negative-fixture, and four-target closure evidence.
- Phase 4 is ready for verifier rerun; this plan does not mark the phase complete.

---
*Phase: 04-image-model-views-and-operations*
*Completed: 2026-07-17*
