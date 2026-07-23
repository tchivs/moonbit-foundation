---
phase: 74-resumable-packed-grayscale-png
plan: 01
subsystem: png-stream-encoding
tags: [moonbit, png, grayscale, streaming, caller-buffered, packed-raster]
requires:
  - phase: 73-explicit-packed-grayscale-png
    provides: private Gray1/Gray2/Gray4 profiles with exact-level admission and packed rows
provides:
  - explicit Gray1, Gray2, and Gray4 caller-buffered PNG selectors
  - eager-identical hostile-lease coverage for every low-bit grayscale depth
affects: [phase-75, png-encoding]
tech-stack:
  added: []
  patterns:
    - direct profile-aware bounded-machine construction
    - public eager versus chunk lifecycle parity
key-files:
  created: []
  modified:
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/stream_encode_test.mbt
decisions:
  - "Low-bit chunk factories are fixed to Stored DEFLATE, filter None, and no interlace."
  - "All three selectors construct the existing profile-aware bounded machine before Active state exists."
metrics:
  duration: 16min
  tasks_completed: 2
  files_modified: 2
  completed: 2026-07-24
status: complete
---

# Phase 74 Plan 01: Resumable Packed Grayscale PNG Summary

**Gray1, Gray2, and Gray4 caller-buffered PNG output now reuses the one bounded machine with public eager byte identity and lease-safe terminals.**

## Accomplishments

- Added exactly `PngChunkEncoder::new_gray1`, `new_gray2`, and `new_gray4`.
- Bound each selector directly to its existing private profile with Stored/None/non-interlaced settings.
- Added public tests for all depths across zero-prefixed one-byte, one-byte, and ragged leases; tests assert accepted totals, untouched tails, eager parity, and Finished replay leases.
- Added all-depth invalid-level and insufficient-work admission checks plus released-lease typed-terminal replay coverage.

## Verification

- `moon -C modules/mb-image test png --target native --frozen` — passed (263/263).
- `moon -C modules/mb-image test png --target all --frozen` — passed (263/263 on wasm, wasm-gc, js, and native).

## Decisions Made

- Preserved the existing packing, preflight, source model, profile definitions, and pull state machine unchanged.
- Kept the stream tests at the public eager/chunk boundary; no production packing helper is used as a test oracle.

## Deviations from Plan

None - plan executed as specified.

## Known Stubs

None.

## Self-Check: PASSED

- Both planned source/test files exist and the scoped package gates pass on every supported target.
