---
phase: 50-gray-alpha-image-model
plan: 01
subsystem: mb-image model, storage, and operations
tags: [gray-alpha, descriptor, storage, capability-boundary]
requires:
  - phase: 49
    provides: portable Gray16 image-model baseline
provides:
  - packed U8 Gray+Alpha descriptor contract with straight alpha
  - generic checked storage/view coverage for two-component pixels
  - fail-closed reference and copy/flip capability boundaries
affects: [51-gray-alpha-png-encoding, 52-gray-alpha-portable-evidence]
tech-stack:
  added: []
  patterns: [descriptor-driven storage, explicit capability rejection]
key-files:
  created:
    - .planning/phases/50-gray-alpha-image-model/50-01-SUMMARY.md
  modified:
    - modules/mb-image/model/descriptor.mbt
    - modules/mb-image/model/model_test.mbt
    - modules/mb-image/storage/storage_test.mbt
    - modules/mb-image/ops/copy_flip.mbt
    - modules/mb-image/ops/copy_flip_test.mbt
decisions:
  - GrayAlpha is limited to packed U8, encoded-sRGB, builtin-sRGB, top-left, straight-alpha descriptors.
  - Existing operations reject GrayAlpha until an operation contract explicitly supports it.
metrics:
  tests: 79 package tests on each of js, wasm, wasm-gc, and native
---

# Phase 50 Plan 01: Gray+Alpha Image Model Summary

Implemented the public two-component `GrayAlpha` image model without adding any PNG or release behavior.

## Delivered

- Added `ChannelOrder::GrayAlpha`, `ImageFormat::graya8()`, and the two-component descriptor layout.
- Restricted descriptor admission to the locked packed U8, straight-alpha sRGB identity.
- Reused descriptor-driven owned storage and checked views to preserve separate gray and alpha bytes.
- Kept reference operations and copy/flip fail-closed for Gray+Alpha.
- Added black-box regressions for valid construction, invalid metadata/representation variants, checked component bounds, legacy compatibility, and atomic typed copy rejection.

## Commits

| Commit | Description |
| --- | --- |
| `59f9d3b` | Added focused failing GrayAlpha public regressions. |
| `9d4fc1b` | Implemented the GrayAlpha descriptor and explicit operation-boundary handling. |

## Verification

- `moon test --target all modules/mb-image/model modules/mb-image/storage modules/mb-image/ops` — 79 passed on each target.
- `moon check --target all` — passed; existing repository warnings only.

## Deviations

None. Two existing white-box test helpers were updated only to handle the newly exhaustive channel-order enum; no codec, PNG, release, copied-source, or target-specific code changed.

## Self-Check: PASSED

- The public model accepts exactly the required Gray+Alpha identity and rejects unsupported variants.
- Generic storage/views preserve non-symmetric gray and alpha values and reject a third component.
- Existing reference and copy/flip capabilities reject Gray+Alpha before consuming operation budget.
