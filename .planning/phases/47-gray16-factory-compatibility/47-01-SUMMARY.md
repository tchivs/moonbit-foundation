---
phase: 47-gray16-factory-compatibility
plan: 01
subsystem: png
tags: [moonbit, png, gray16, u16, stored-deflate]
requires:
  - phase: 46-portable-gray8-public-evidence
    provides: Explicit Gray8 PNG factory family and shared bounded encoder machine.
provides:
  - Checked packed U8/U16 component-byte access for storage-backed Gray16 sources.
  - Explicit Stored/non-interlaced eager and caller-buffered Gray16 PNG factories.
affects: [storage, png, gray16, regression-testing]
key-files:
  created:
    - .planning/phases/47-gray16-factory-compatibility/47-01-SUMMARY.md
  modified:
    - modules/mb-image/storage/views.mbt
    - modules/mb-image/storage/owned_image.mbt
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
key-decisions:
  - `get_byte` and `set_byte` remain packed-U8 APIs; paired component-byte access is required for packed U16 construction and reading.
  - Gray16 only exposes Stored, filter-None, non-interlaced factories in this phase.
  - PNG scanlines convert source storage order to mandatory big-endian sample order without a retained converted row.
requirements-completed: [GRAY16-01]
completed: 2026-07-22
status: complete
---

# Phase 47 Plan 01: Gray16 Factory Compatibility Summary

Explicit eager and caller-buffered Gray16 PNG routes now emit 16-bit, type-0, non-interlaced Stored PNGs while retaining the legacy and Gray8 paths.

## Accomplishments

- Added bounds-checked U8/U16 component-byte storage access, including callback-scoped construction of U16 images.
- Added `PngEncoder::new_gray16()` and `PngChunkEncoder::new_gray16()`.
- Serialized packed U16 Gray samples in PNG big-endian order from either source storage endianness.
- Preserved atomic rejection before writer output or usable chunk state, and retained existing RGB8/RGBA8/Gray8 tests.

## Verification

| Command | Result |
| --- | --- |
| `moon -C modules/mb-image test storage --target native --frozen` | PASS — 15 passed, 0 failed |
| `moon -C modules/mb-image test png --target native --frozen` | PASS — 183 passed, 0 failed |

Existing compiler warnings were emitted by the package suite; none are test failures.

## Task Commits

1. `4bdc5d2` — checked U16 component-byte storage access.
2. `6c80238` — explicit Gray16 PNG factories and native black-box evidence.

## Next Phase Readiness

Phase 48 can broaden Gray16 into the bounded strategy/filter surfaces while retaining this type-0/16-bit Stored baseline.
