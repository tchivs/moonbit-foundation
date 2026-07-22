---
phase: 48-bounded-gray16-encoder-path
plan: "01"
subsystem: png
tags: [moonbit, png, gray16, u16, deflate, adaptive-filter]
requires:
  - phase: 47-gray16-factory-compatibility
    provides: Explicit non-interlaced Gray16 PNG factory baseline and U16 component access.
provides:
  - Gray16 eager and caller-buffered compression-only, filter-only, and combined strategy factories.
  - One profile-aware bounded scalar wire-byte producer for Stored, Fixed, Dynamic, filter, match, checksum, and replay paths.
  - Native six-pair Gray16 framing, endian, stride, eager/chunk identity, and atomic-admission evidence.
affects: [png, gray16, encoding, regression-testing]
key-files:
  created:
    - .planning/phases/48-bounded-gray16-encoder-path/48-01-SUMMARY.md
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - Gray16 source U16 component storage is exposed to every bounded traversal as high-byte/low-byte PNG wire bytes without converted-row staging.
  - The existing shared preflight ledger remains the single admission point; Gray16 uses two-byte filter stride and stays non-interlaced.
  - Explicit Gray16 strategy families mirror Gray8 while legacy constructors remain unchanged.
requirements-completed: [GRAY16-02]
completed: 2026-07-22
status: complete
---

# Phase 48 Plan 01: Bounded Gray16 Encoder Path Summary

Gray16 PNG encoding now uses the same bounded Stored/Fixed/Dynamic, None/Adaptive filter, admission, and caller-buffered machinery as the existing explicit profiles while preserving PNG type-0, 16-bit big-endian wire samples.

## Accomplishments

- Added three eager and three caller-buffered Gray16 strategy factories, all explicitly non-interlaced.
- Replaced the transitional Stored/None Gray16 bypass with one profile-aware scalar wire-byte producer threaded through filtering, matching, planning, checksums, and replay cursors.
- Removed the `gray16-stored-none-required` gate while preserving `gray16-noninterlaced-required` and shared atomic preflight.
- Added native evidence for all six compression/filter pairs, eager/chunk byte identity, U16 little/big source-endian equivalence, Adaptive two-byte stride, and capability/geometry/output/work/budget atomicity.

## Verification

| Command | Result |
| --- | --- |
| `moon -C modules/mb-image test png --target native --frozen` | PASS — 187 passed, 0 failed |
| `rg -n "gray16-stored-none-required|gray16_stored_none|_png_gray16_scanline_byte" modules/mb-image/png` | PASS — no matches |
| `rg -n "gray16-noninterlaced-required" modules/mb-image/png/encode.mbt` | PASS — retained in preflight |

Existing package compiler warnings remain non-fatal and predate this phase.

## Task Commits

1. `bd44940` — failing Gray16 bounded-path tracer tests.
2. `97d6498` — profile-aware Gray16 strategy implementation.
3. `3e3ec90` — Gray16 six-pair, endian, and atomic-admission native contracts.

## Next Phase Readiness

Phase 49 can add hostile capacity schedules and portable target evidence without introducing a second Gray16 encoding path.
