---
phase: 04-image-model-views-and-operations
plan: "04"
subsystem: image-operations
tags: [moonbit, copy, flip, packed-u8, metadata-disposition, atomic-budgets]

requires:
  - phase: 04-image-model-views-and-operations/04-01
    provides: Bounded canonical metadata and machine-readable disposition records
  - phase: 04-image-model-views-and-operations/04-02
    provides: Explicit validated image formats, planes, color identity, alpha, and orientation
  - phase: 04-image-model-views-and-operations/04-03
    provides: Retained immutable views and atomic fresh-operation allocation
provides:
  - Closed supported packed U8 operation dispatcher
  - Fresh tightly packed copy and horizontal/vertical flip operations
  - Preserve-all metadata disposition for stored-coordinate operations
affects: [04-image-model-views-and-operations, orientation, resize, pixel-conversion]

tech-stack:
  added: []
  patterns:
    - Unsupported capability and geometry validation before one combined output charge
    - Fresh logical-pixel traversal that never observes or propagates source padding

key-files:
  created:
    - modules/mb-image/ops/moon.pkg
    - modules/mb-image/ops/copy_flip.mbt
    - modules/mb-image/ops/copy_flip_test.mbt
    - modules/mb-image/ops/copy_flip_wbtest.mbt
  modified:
    - policy/foundation.json

key-decisions:
  - "Return one ImageOperationResult containing the fresh image and metadata disposition so later deterministic operations share one inspectable result contract."
  - "Support exactly encoded-sRGB packed U8 RGB, straight RGBA, and premultiplied RGBA; reject planar, U16, F32, Gray, and mismatched identity before output charge."
  - "Use output logical byte length as deterministic work and pass explicit width, height, pixels, and work once to OwnedImage::new_operation."

patterns-established:
  - "Operation gate: format and identity support, checked tight geometry, fixed disposition, single combined allocation, then no-alias traversal."
  - "Stored-coordinate transforms preserve orientation and all metadata while emitting sorted alpha/color/opaque/orientation/profile preservation fields."

requirements-completed: [IMAG-05, IMAG-06]

coverage:
  - id: D1
    description: Copy produces independent tightly packed images for all three supported U8 formats without copying padded bytes.
    requirement: IMAG-05
    verification:
      - kind: unit
        ref: "modules/mb-image/ops/copy_flip_test.mbt; moon -C modules/mb-image test ops --target all --frozen (6/6 per target)"
        status: pass
    human_judgment: false
  - id: D2
    description: Horizontal and vertical flips implement exact stored-coordinate permutations with fresh backing for single-axis and multi-row images.
    requirement: IMAG-05
    verification:
      - kind: unit
        ref: "modules/mb-image/ops/copy_flip_test.mbt and copy_flip_wbtest.mbt; 6/6 per target"
        status: pass
    human_judgment: false
  - id: D3
    description: Copy and flips preserve color, profile, alpha, orientation, and opaque metadata with an exact machine-readable disposition while unsupported paths do not charge.
    requirement: IMAG-06
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required; 148/148 workspace tests per target"
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-07-17
status: complete
---

# Phase 4 Plan 4: Fresh Copy and Flip Operations Summary

**Alias-safe tightly packed U8 copy and exact stored-coordinate flips with atomic output budgets and preserve-all metadata dispositions**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-17T05:32:08+08:00
- **Completed:** 2026-07-17T05:38:00+08:00
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added copy, horizontal flip, and vertical flip over the closed encoded-sRGB packed U8 RGB/straight-RGBA/premultiplied-RGBA spine.
- Allocated fresh tight output through the scalar operation factory and traversed only logical pixels, leaving source row padding unobservable.
- Preserved stored orientation and every metadata class with an exact sorted disposition while rejecting unsupported formats and insufficient work atomically.

## Task Commits

1. **Task 1 RED: Add failing copy and flip contracts** - `e51977e` (test)
2. **Task 1 GREEN: Implement fresh copy and flips** - `9386166` (feat)
3. **Task 2: Register the initial operations interface** - `c24093f` (chore)

## Files Created/Modified

- `modules/mb-image/ops/moon.pkg` - Exact inward imports and explicit four-target package policy.
- `modules/mb-image/ops/copy_flip.mbt` - Closed format gate, tight descriptor construction, fresh traversal, and shared operation result.
- `modules/mb-image/ops/copy_flip_test.mbt` - Public copy, flip, padding, metadata, budget, and fresh-backing evidence.
- `modules/mb-image/ops/copy_flip_wbtest.mbt` - Adversarial planar/U16/F32/Gray, work rejection, and single-axis cases.
- `policy/foundation.json` - Exact ops publication inventory, dependency allowlist, targets, and 14-line semantic interface.

## Decisions Made

- Used a shared `ImageOperationResult` rather than an unlabelled tuple so later orientation, resize, and conversion APIs can expose the same explicit image/disposition contract.
- Kept the allocator private and accepted only `ImageView` plus caller `Budget` publicly; the authoritative storage layer still receives all explicit scalar charges once.
- Defined work as output logical byte writes, matching the deterministic loop and excluding padding from both cost and result.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `moon -C modules/mb-image test ops --target all --frozen`: 6/6 passed independently on js, wasm, wasm-gc, and native.
- `moon -C modules/mb-image check --target all --deny-warn --frozen`: passed on all four targets.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`: passed with 148/148 workspace tests per target, exact 14-line ops interface, package allowlist, DAG, negative fixtures, and read-only proof.

## Self-Check: PASSED

- All five planned source/policy files exist.
- Commits `e51977e`, `9386166`, and `c24093f` resolve in repository history.
- No known stubs, in-place API, raw backing, host/filesystem/codec import, or new network/auth/schema threat surface was introduced.

## Next Phase Readiness

- Plan 04-05 can reuse the closed dispatcher, tight output construction, shared result, and preserve-all disposition for all eight orientation mappings.
- No blockers remain.

---
*Phase: 04-image-model-views-and-operations*
*Completed: 2026-07-17*
