---
phase: 53-grayalpha16-model-and-checked-storage
plan: 01
subsystem: mb-image model and storage
tags: [moonbit, grayalpha16, u16, descriptor, checked-storage]
requires:
  - phase: 50-gray-alpha-image-model
    provides: Packed U8 GrayAlpha identity and fail-closed reference-operation boundary.
provides:
  - Public packed U16 GrayAlpha format identity with straight-alpha metadata admission.
  - Checked storage evidence for independent little-endian gray and alpha U16 byte lanes.
  - Typed rejection coverage for malformed U16 GrayAlpha descriptor identities.
affects: [54-grayalpha16-png-encoding, 55-grayalpha16-portable-public-evidence]
tech-stack:
  added: []
  patterns: [explicit-format-factory, descriptor-derived-packed-storage, fail-closed-capability]
key-files:
  created:
    - .planning/phases/53-grayalpha16-model-and-checked-storage/53-01-SUMMARY.md
  modified:
    - modules/mb-image/model/descriptor.mbt
    - modules/mb-image/model/model_test.mbt
    - modules/mb-image/storage/storage_test.mbt
key-decisions:
  - ImageFormat::graya16 is the public packed U16, little-endian GrayAlpha identity.
  - GrayAlpha admission accepts only U8 or U16 while retaining every existing alpha, colour, profile, layout, endianness, and orientation guard.
  - GrayAlpha remains excluded from reference operations; U16 access continues through checked component-byte APIs only.
patterns-established:
  - Distinct byte pairs in every U16 lane prove storage order and component indexing without numeric conversion.
requirements-completed: [GRAYA16-01]
coverage:
  - id: D1
    description: Public U16 GrayAlpha descriptor identity and strict metadata admission.
    requirement: GRAYA16-01
    verification:
      - kind: unit
        ref: modules/mb-image/model/model_test.mbt#GrayAlpha16 is a packed two-component straight-alpha descriptor
        status: pass
      - kind: unit
        ref: moon test --target all modules/mb-image/model modules/mb-image/storage modules/mb-image/ops
        status: pass
    human_judgment: false
  - id: D2
    description: Generic checked storage preserves both U16 GrayAlpha component-byte pairs and bounds.
    requirement: GRAYA16-01
    verification:
      - kind: unit
        ref: modules/mb-image/storage/storage_test.mbt#checked packed views retain both GrayAlpha16 component byte pairs
        status: pass
      - kind: other
        ref: moon check --target all
        status: pass
    human_judgment: false
duration: 4min
completed: 2026-07-23
status: complete
---

# Phase 53 Plan 01: GrayAlpha16 Model and Checked Storage Summary

**Packed U16 GrayAlpha now has a public straight-alpha descriptor identity with byte-accurate checked storage evidence and preserved fail-closed operations.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-23T04:25:28+08:00
- **Completed:** 2026-07-23T04:29:06+08:00
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Added `ImageFormat::graya16()` as the packed, little-endian U16 GrayAlpha factory.
- Narrowly admitted canonical U16 GrayAlpha descriptors without weakening any existing metadata or layout validation.
- Proved non-symmetric gray and alpha U16 storage bytes round-trip through the generic checked component-byte views while invalid channel, byte-index, and legacy U8-view access fail.
- Retained existing GrayAlpha reference-operation rejection and all legacy model, storage, and operation controls.

## Verification

| Command | Result |
| --- | --- |
| `moon test --target all modules/mb-image/model modules/mb-image/storage modules/mb-image/ops` | PASS — 81 tests each on wasm, wasm-gc, js, and native |
| `moon check --target all` | PASS — pre-existing repository warnings only |
| `git diff --check` | PASS |

## Task Commits

1. **Task 1: Admit one GrayAlpha16 descriptor through generic checked storage**
   - `041d8a2` — RED specification: GrayAlpha16 public model and storage behavior.
   - `c1c5292` — public factory and narrow U8-or-U16 admission implementation.
2. **Task 2: Lock malformed GrayAlpha16 rejection and legacy model/storage controls**
   - `079a18e` — malformed U16 identity matrix and retained compatibility evidence.

## Files Created/Modified

- `modules/mb-image/model/descriptor.mbt` — public factory and exact GrayAlpha U8-or-U16 admission predicate.
- `modules/mb-image/model/model_test.mbt` — canonical U16 descriptor, malformed identity, typed row-shape, and reference-operation regressions.
- `modules/mb-image/storage/storage_test.mbt` — U16 gray/alpha component-byte storage and bounds regression.

## Decisions Made

- Retained descriptor-derived generic storage rather than introducing a U16-specific backing or conversion path.
- Kept `get_byte`/`set_byte` U8-only; U16 continues to use checked component-byte access.
- Retained the explicit `GrayAlpha => false` reference-operation boundary.

## Deviations from Plan

None - plan executed within the declared model, storage, and test scope. The requested “unknown colour” test case is unrepresentable in the current `ColorSpaceIdentity` type, which has only `Srgb`; the exact sRGB equality check continues to reject any future non-sRGB variant structurally.

## Known Stubs

None.

## Next Phase Readiness

Phase 54 can add the Type-4/16 PNG encoder path against the stable packed U16 GrayAlpha source contract, without changing generic storage or reference-operation semantics.

## Self-Check: PASSED

- All three modified source/test files exist.
- Task commits `041d8a2`, `c1c5292`, and `079a18e` exist in git history.
