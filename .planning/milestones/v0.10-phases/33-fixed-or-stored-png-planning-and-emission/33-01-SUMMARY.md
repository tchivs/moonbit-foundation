---
phase: 33-fixed-or-stored-png-planning-and-emission
plan: "01"
subsystem: png-encoding
tags: [png, deflate, fixed-huffman, moonbit, streaming]
dependency_graph:
  requires: [phase-32-compression-strategy]
  provides: [bounded-fixed-or-stored-emission]
  affects: [png-eager-encoder, png-chunk-encoder]
tech_stack:
  added: []
  patterns: [scalar-preflight-plan, deterministic-replay, present-acknowledge]
key_files:
  created: []
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/stream_encode_test.mbt
    - modules/mb-image/png/stream_encode_wbtest.mbt
decisions:
  - FixedOrStored selects fixed only when its exact complete PNG length is no larger than Stored.
  - The private A1 matcher is limited to distances one through four and is replayed from scalar state.
  - Fixed byte state, Adler-32, and replay cursors advance only on acknowledgement.
metrics:
  duration: 1h
  completed_date: 2026-07-22
  tasks_completed: 3
  files_modified: 7
status: complete
---

# Phase 33 Plan 01: Fixed-or-Stored PNG Planning and Emission Summary

Implemented deterministic, bounded fixed-Huffman-or-stored PNG emission with exact preflight admission and acknowledgement-safe eager/chunk delivery.

## Completed Work

- Added a private scalar DEFLATE plan that preserves explicit Stored emission while choosing Fixed only when its exact PNG total is no larger.
- Added A1 distance-1-through-4 longest-match scanning, exact fixed-code bit accounting, selected work admission, selected IDAT length validation, and one final budget charge.
- Added scalar fixed replay with LSB reversed codes, zlib/IDAT checksum handling, and preview-before-acknowledge state changes.
- Added focused eager, chunk, and white-box coverage for fixed selection, code arithmetic, hostile-capacity parity, and acknowledgement stability.
- Corrected strategy documentation without changing the public enum, factory signatures, or legacy Stored constructors.

## Verification

- RED: `moon -C modules/mb-image test png --target native --frozen -f 'PNG fixed-or-stored'` failed because the fixed private code helpers were absent.
- GREEN: full native PNG suite passed: 106/106.
- Focused FixedOrStored tests passed: 4/4 each on js, wasm, wasm-gc, and native.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` passed, including policy, generated vectors, full four-target PNG suites, and lane isolation.

## Decisions Made

- Fixed plans use exact full-PNG length comparison, with ties selecting Fixed.
- Fixed replay stores no tokens, history, payload, scanline buffer, or caller output lease.
- Existing `PngEncoder::new()` and `PngChunkEncoder::new(...)` retain explicit Stored output.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added the fixed DEFLATE block header to replay emission**
- **Found during:** Task 2 GREEN verification.
- **Issue:** The first fixed byte initially contained the first literal code without BFINAL/BTYPE bits.
- **Fix:** Added a scalar `header_written` preview state and writes the final fixed-block header before replaying tokens.
- **Files modified:** `modules/mb-image/png/stream_encode.mbt`
- **Commit:** b97bac3

## Known Stubs

None.

## Self-Check: PASSED

- Verified all seven plan-owned PNG files exist.
- Verified commits `0254023`, `b97bac3`, and `668452b` exist in git history.
