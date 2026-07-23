---
phase: 64-grayalpha16-decode-qualification
plan: 01
subsystem: png-decode
tags: [png, grayalpha16, adam7, filters, streaming]
requires: [62-01, 63-01]
provides: [grayalpha16-adam7-preservation, filter-qualification]
affects: [modules/mb-image/png]
tech-stack:
  added: []
  patterns: [fixed-wire-literals, profile-aware-adam7-scatter, public-chunk-parity]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png_test.mbt
    - modules/mb-image/png/stream_decode_test.mbt
    - modules/mb-image/png/stream_decode_wbtest.mbt
    - modules/mb-image/png/stream_decode.mbt
    - modules/mb-image/png/raster_decode.mbt
decisions:
  - Legal Type-4/16 Adam7 uses the existing GrayAlpha16 profile and shared decode machine.
  - Adam7 Type-4/16 stores reconstructed Glo,Ghi,Alo,Ahi directly through the existing component-byte representation.
metrics:
  tasks_completed: 2
  focused_js_tests: 8
  all_target_tests: unrun
  completed_date: 2026-07-23
status: blocked
---

# Phase 64 Plan 01: GrayAlpha16 Decode Qualification Summary

Legal Type-4/16 Adam7 input now enters the established explicit profile and preserves every U16 component byte through eager and chunk decode paths.

## Completed Work

- Added fixed, CRC-valid Type-4/16 literals for a 5x5 all-seven-pass Adam7 image and a 2x5 image using PNG filters 0 through 4.
- Added component-byte oracles that assert every explicit `Glo,Ghi,Alo,Ahi` lane and generic `RGBA8(Ghi,Ghi,Ghi,Ahi)` compatibility.
- Extended explicit chunk schedules with one-byte and ragged callers for both new literals, retaining finish-only result transfer and eager parity.
- Replaced the explicit-profile interlace rejection with legal Type-4/16 Adam7 admission while retaining type, depth, transparency, legacy-colour, and ICC gates.
- Threaded the selected profile into Adam7 scatter so only GrayAlpha16 writes the existing little-endian U16 component lanes; generic scatter remains the historical high-byte mapping.
- Added an exact/one-less output-limit assertion for the five-filter literal.

## Verification

- Passed: `moon -C modules/mb-image test png --target js --frozen --filter '*graya16*'`
  - Result: 8 passed, 0 failed.
- Blocked: `moon -C modules/mb-image test png --target all --frozen`
  - The direct command was attempted twice. The first exceeded the executor observation timeout without test or OOM output. The retry was stopped after confirming an orphaned, zero-byte workspace `_build/.moon-lock` (timestamp `2026-07-23 10:17:32`) and pre-existing `moon` PID `289128` whose parent no longer exists. The lock was neither deleted nor modified.

## TDD Gate Compliance

- RED: `84918ec` added the failing all-pass Adam7 admission and preservation contract; focused JS failed at the profile gate before the correction.
- GREEN: `d04a65a` made the focused JS suite pass after the minimal admission/scatter correction.
- Expansion: `5c8312a` added five-filter, chunk, generic-compatibility, and exact-limit evidence; the focused JS suite passed 8/8.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the missing explicit Adam7 final-store branch**
- **Found during:** Task 1
- **Issue:** Legal GrayAlpha16 Adam7 was rejected before lifecycle allocation, and the existing Adam7 writer would otherwise discard low bytes via generic RGBA8 expansion.
- **Fix:** Removed only the explicit interlace disqualifier and selected component-byte storage for Type-4/16 only when the profile is GrayAlpha16.
- **Files modified:** `stream_decode.mbt`, `raster_decode.mbt`
- **Commit:** `d04a65a`

### Verification Blocker

The required unwrapped all-target command remains unverified because of the orphaned workspace lock described above. No wrapper, copied build tree, generated fixture, lock deletion, or process termination outside the phase-owned retry was used.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed all five implementation/test files exist.
- Confirmed commits `84918ec`, `d04a65a`, and `5c8312a` exist in git history.
