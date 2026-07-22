---
phase: 38-adaptive-filter-compatibility
plan: "01"
subsystem: png
tags: [moonbit, png, filters, compatibility]
requires: []
provides:
  - PngFilterStrategy with additive eager and caller-buffered factories
affects: [phase-39-row-filter-work]
tech-stack:
  added: []
  patterns: [configured factories normalize Adaptive to filter-None]
key-files:
  created: []
  modified: [modules/mb-image/png/png.mbt, modules/mb-image/png/encode.mbt, modules/mb-image/png/stream_encode.mbt, modules/mb-image/png/encode_test.mbt, modules/mb-image/png/stream_encode_test.mbt, policy/foundation.json]
key-decisions:
  - "Adaptive uses Stored compression and normalizes to the established filter-None provider."
requirements-completed: [PNGF-01]
status: complete
---

# Phase 38 Plan 01: Adaptive Filter Compatibility Summary

**Additive PNG filter-selection API that preserves the existing filter-None encoder path.**

## Task Commits

1. **Task 1: Write public frozen-vector tests** - `ca04390`
2. **Task 2: Implement filter factories** - `6bbc637`

## Accomplishments

- Added documented `PngFilterStrategy::{None, Adaptive}` plus eager and chunk configured factories.
- Kept all legacy and compression constructors explicit `None` routes through a shared private constructor.
- Registered the generated PNG interface additions in `policy/foundation.json`.

## Verification

- Resolved the native test-layout abort by moving the immutable strict-Dynamic vector to the established public strict-winner stream test. That test already verifies hostile caller-buffered parity, complete-input decode, RGB components, and the Dynamic block marker. The rationale and reproduction are retained in `.planning/debug/png-dynamic-vector-native.md`.
- `moon -C modules/mb-image test png --target <js|wasm|wasm-gc|native> --target-dir _build/phase38-final-<target> --frozen` passed: **133/133** on every declared target.
- Focused eager/filter and strict-Dynamic vector tests passed independently on js, wasm, wasm-gc, and native using isolated recovery target directories.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` completed without policy or semantic-interface errors; pre-existing compiler warnings remain non-fatal.

## Deviations from Plan

The strict-Dynamic exact vector now has one stable public home in `stream_encode_test.mbt` instead of duplicating it in the eager filter test. This preserves the planned complete-vector, eager, hostile caller-buffered, marker, and decode evidence while avoiding a native test-runner abort caused by the original test layout.
