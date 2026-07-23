---
phase: 73-explicit-packed-grayscale-png
plan: 01
subsystem: png-encoder
tags: [moonbit, png, grayscale, stored-deflate, packed-raster]
requires:
  - phase: 72-rgba16-encode-qualification
    provides: profile-aware bounded PNG encoder and explicit grayscale routes
provides:
  - explicit eager Gray1, Gray2, and Gray4 Type-0 PNG selectors
  - exact-level preflight admission and MSB-first packed wire bytes
  - independent Stored/None wire and atomic-rejection evidence
affects: [phase-74, phase-75, png-encoding]
tech-stack:
  added: []
  patterns:
    - profile-aware packed PNG wire rows from a canonical Gray/U8 source
    - exact-level admission before resource accounting
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
key-decisions:
  - "Low-bit grayscale remains eager-only and fixed to Stored/None/non-interlaced output."
  - "The shared bounded machine packs source samples on demand; no packed raster is staged."
patterns-established:
  - "Validate exact source levels before layout, limits, budget charge, machine construction, or writer progress."
requirements-completed: [GRAYPACK-01, GRAYPACK-02]
coverage:
  - id: D1
    description: Explicit Gray1, Gray2, and Gray4 Type-0 PNG output has correct IHDR and odd-width MSB-first Stored rows.
    requirement: GRAYPACK-01
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#PNG Gray1 eager Stored output packs MSB-first and rejects atomically
        status: pass
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#PNG Gray2 and Gray4 eager Stored output packs exact levels atomically
        status: pass
      - kind: unit
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Nonrepresentable Gray/U8 levels reject before output and preserve all caller budget fields.
    requirement: GRAYPACK-02
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#packed grayscale atomic rejection cases
        status: pass
    human_judgment: false
duration: 24min
completed: 2026-07-23
status: complete
---

# Phase 73 Plan 01: Explicit Packed Grayscale PNG Summary

**Eager Gray1, Gray2, and Gray4 PNG profiles serialize canonical Gray/U8 images as exact, MSB-first Type-0 Stored/None wire data.**

## Performance

- **Tasks:** 2/2
- **Files modified:** 4
- **Verification:** native and all-target PNG package tests passed (260/260 on every target).

## Accomplishments

- Added only the three explicit eager selectors, each fixed to Stored DEFLATE, filter None, and no interlace.
- Admitted only exact U8 grayscale levels before planner, limits, budget charge, machine construction, or writer progress.
- Reused the existing bounded encoder to derive packed row bytes on demand, with zero-filled tail lanes and profile-correct Type-0 IHDR depths.
- Added a standalone bounded Stored-IDAT parser plus all-depth odd-width wire and atomic failure coverage.

## Files Created/Modified

- `modules/mb-image/png/png.mbt` — private profiles and eager Gray1/2/4 selectors.
- `modules/mb-image/png/encode.mbt` — exact admission, checked packed layout, and scalar MSB-first packing.
- `modules/mb-image/png/stream_encode.mbt` — Type-0 IHDR depths for the low-bit profiles.
- `modules/mb-image/png/encode_test.mbt` — independent Stored wire oracle and atomic rejection tests.

## Decisions Made

- Public low-bit APIs expose no compression, filter, chunk, or interlace strategy variants.
- Packed rows are synthesized byte-by-byte by the existing encoder machine instead of allocating a staging raster.

## Deviations from Plan

None - plan executed as specified.

## Known Stubs

None.

## Next Phase Readiness

The eager packed-grayscale contract is complete and leaves caller-buffered, Adam7, and broader strategy surfaces intentionally deferred.

## Self-Check: PASSED

- All four planned source/test files and this summary exist.
- Native and all-target package gates completed successfully.
