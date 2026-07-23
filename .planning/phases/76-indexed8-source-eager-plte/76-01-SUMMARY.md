---
phase: 76
plan: 01
subsystem: png
tags: [png, indexed8, plte, stored-deflate]
status: complete
requires: []
provides: [PngIndexedImage, eager-indexed8-png]
affects: [modules/mb-image/png]
tech-stack:
  added: []
  patterns: [owning-source-validation, frame-facts, acknowledged-crc]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/encode_wbtest.mbt
decisions:
  - Indexed8 stays PNG-specific and eager-only, without extending ImageView or ImageEncoder.
  - Zero-PLTE frame facts retain legacy offsets and byte streams exactly.
metrics:
  tasks_completed: 2
  files_modified: 5
  verification: moon test --target all (798 tests on each target)
---

# Phase 76 Plan 01: Indexed8 Source & Eager PLTE Summary

Immutable Indexed8 sources now encode as bounded Type-3/8 PNGs with an RGB PLTE and Stored/filter-None raster.

## Delivered

- Added `PngIndexedImage`, which validates dimensions, index raster shape, RGB palette cardinality, and index bounds before one defensive owned copy.
- Added eager-only `PngEncoder::encode_indexed8`, using the existing acknowledged byte machine with a fixed Stored/None/non-interlaced profile.
- Added variable frame facts so Indexed8 emits `IHDR → PLTE → IDAT → IEND`, while zero-PLTE legacy framing remains numerically unchanged.
- Added acknowledged PLTE CRC accounting, independent wire/CRC/Stored-scanline proof, public RGB8 decode-back, atomic source/eager rejection checks, and white-box frame-fact coverage.
- Review hardening keeps source ownership to one budget-charged `OwnedBytes` allocation (including width, height, and pixel charge), rejects zero dimensions before scanline arithmetic, rejects Indexed8 IDAT lengths beyond the PNG U32 field, and keeps `max_pixels=0` atomic on both source and eager-encode budgets.

## Verification

`moon test --target all` passed: 798/798 tests on wasm, wasm-gc, js, and native.

## Deviations from Plan

None - plan executed within the specified API and wire-format scope.

## Self-Check: PASSED

All five authorized source/test files exist, the indexed source and eager API are covered by public and white-box tests, and the frozen four-target package suite passed.
