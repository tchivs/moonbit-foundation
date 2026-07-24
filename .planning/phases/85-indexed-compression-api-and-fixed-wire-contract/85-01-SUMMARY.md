---
phase: 85
plan: 01
subsystem: PNG indexed encoding
tags: [moonbit, png, indexed, deflate, streaming]
requires: []
provides: [indexed-stored-or-fixed-selectors, bounded-indexed-match-producer]
affects: [mb-image/png]
tech-stack:
  added: []
  patterns: [PngMatchProducer, PngIndexedRawCursor, PngFrameFacts]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
    - modules/mb-image/png/encode_wbtest.mbt
decisions:
  - Indexed Dynamic rejects before indexed preflight or budget mutation.
  - Fixed selection compares full palette-aware Type-3 frame facts and wins ties.
metrics:
  tasks_completed: 3
  native_tests: 302
status: complete
---

# Phase 85 Plan 01: Indexed Compression API and Fixed Wire Contract Summary

Non-interlaced Indexed1/2/4/8 PNG encoding now has explicit Stored-or-Fixed eager and chunk selectors backed by one bounded indexed filter-None match producer.

## Delivered

- Added the four additive compression-selector APIs and preserved legacy non-interlaced methods as literal Stored forwards.
- Rejected indexed Dynamic compression with `indexed-dynamic-compression-unavailable` before preflight, output, chunk activation, or budget charge.
- Routed Indexed8 and selected low-bit output through `PngMatchProducer::IndexedNone(PngIndexedRawCursor)` beneath the existing 262-byte matcher and acknowledged machine.
- Selected Fixed only when palette-aware `PngFrameFacts` make its complete Type-3 frame no larger than Stored.
- Added public Stored-parity, Dynamic-rejection, Fixed selection, eager/chunk parity, and all-depth private Fixed/Stored matrix coverage.

## Verification

- `moon -C modules/mb-image test png --target native --frozen` — passed, 302 tests.
- The white-box matrix proves all Indexed1/2/4/8 profiles select Fixed for 64 zero packed bytes and Stored for `0xc0..0xff`; it checks 81-byte Fixed versus 76-byte Stored IDAT fallback facts and canonical one-byte tRNS framing.
- Existing `stream_encode_wbtest.mbt` Fixed replay tests continue to cover repeated preview and acknowledgement-only state mutation; indexed Fixed replay uses that unchanged `PngFixedState` path.

## Commits

- `d5a2735` — failing Indexed8 selector regression (RED).
- `71ef5ea` — Indexed8 Stored-or-Fixed implementation (GREEN).
- `84ef01a` — selected-depth eager and chunk selector coverage.
- `c5833b9` — indexed all-depth Fixed-or-Stored private matrix.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test fixture limits] Used a dedicated 512-wide indexed matrix budget and limit fixture.**
- **Found during:** Task 3
- **Issue:** The repository's compact white-box defaults cap width at 64, while the specified Indexed1 matrix fixture is width 512 and a complete Indexed8 palette makes its frame exceed the default output cap.
- **Fix:** Added test-local matrix limits/budget only; production admission and API behavior are unchanged.
- **Files modified:** `modules/mb-image/png/encode_wbtest.mbt`
- **Commit:** `c5833b9`

## Known Stubs

None.

## Self-Check: PASSED

- All modified production and test files exist.
- All four task commits are present on `codex/phase85-executor`.
