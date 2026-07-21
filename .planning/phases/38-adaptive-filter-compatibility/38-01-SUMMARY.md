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
  modified: [modules/mb-image/png/png.mbt, modules/mb-image/png/encode.mbt, modules/mb-image/png/stream_encode.mbt, policy/foundation.json]
key-decisions:
  - "Adaptive uses Stored compression and normalizes to the established filter-None provider."
requirements-completed: []
status: blocked
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

## Blocker

The focused native frozen-vector test aborts with exit code `0xc0000409` when it evaluates the strict-Dynamic complete PNG vector. RGB8, RGBA8, and FixedOrStored portions pass when the Dynamic section is excluded. This also occurs with the vector represented as one literal, chunked literals, and scalar-byte construction, so it is not caused by the Phase 38 factory implementation. The reproducible command is:

`moon -C modules/mb-image test png --target native --target-dir _build/phase38-recover7-native --frozen --no-parallelize -f 'PNG filter strategy eager frozen compatibility vectors'`

## Verification

- `moon -C modules/mb-image check png --target native --target-dir _build/phase38-recover7-native --frozen --diagnostic-limit 5` passed with pre-existing warnings.
- The full required target matrix and PNG quality lane were not run because the focused native vector test aborts.

## Deviations from Plan

None in the committed implementation. Temporary diagnostic changes to the test files were restored exactly to `ca04390`.

