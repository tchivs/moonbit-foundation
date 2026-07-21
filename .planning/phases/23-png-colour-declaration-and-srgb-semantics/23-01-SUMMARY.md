---
phase: 23-png-colour-declaration-and-srgb-semantics
plan: "01"
subsystem: png
tags: [png, colour, srgb, fixtures, conformance]
requires: [22-01]
provides: [strict-colour-declaration-vectors, srgb-metadata-evidence]
affects: [png-decoder, png-fixture-generator]
tech-stack:
  added: []
  patterns: [independent-powershell-oracle, generated-portable-vectors]
key-files:
  created: []
  modified:
    - fixtures/png/decode-cases.json
    - fixtures/manifest.json
    - scripts/fixtures/Generate-PngDecodeVectors.ps1
    - modules/mb-image/png/generated_decode_vectors_test.mbt
    - modules/mb-image/png/png_test.mbt
decisions:
  - Generated PNG decode evidence carries a declared sRGB intent separately from raster expectations and inspects bounded opaque metadata on success.
  - The fixture generator independently assembles, CRC-checks, and grammar-checks recognised colour chunks before emitting MoonBit vectors.
metrics:
  tasks_completed: 2
status: complete
---

# Phase 23 Plan 01: PNG Colour Declaration and sRGB Semantics Summary

Strict PNG colour declarations now have portable, manifest-backed evidence for validated sRGB intent retention and explicit non-sRGB capability boundaries.

## Completed Work

- Task 1 (existing commits `d14e449`, `a7ab565`, `aea0e7f`): strict recognised-colour parsing, sRGB metadata mapping, and capability boundaries.
- Task 2 (`ec9e015`): added ordered `colour_chunks` fixture construction, independent CRC/order/payload oracle validation, accepted sRGB samples for RGB, RGBA, palette, grayscale, 16-bit, and Adam7 layouts, plus hostile gAMA/cHRM/iCCP/order/duplicate/precedence cases.

Generated tests now check decoded descriptor colour space, encoded-sRGB transfer, built-in sRGB profile, and the retained one-byte intent. Hostile and unsupported declarations assert typed category/code/context failures without a result image.

## Verification

- `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` — passed (3,770 executable cases).
- `moon -C modules/mb-image test png --target all --frozen` — passed on wasm, wasm-gc, js, and native (38/38 each).
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected compact fixture scanline and iCCP no-NUL expectations**
- **Found during:** Task 2 verification.
- **Issue:** Two new one-pixel vectors had an extra filtered byte, and the decoder classifies a no-NUL iCCP envelope as `png-iccp-envelope`.
- **Fix:** Reused the established two-byte stored-DEFLATE scanline and aligned the independent oracle/expected context with decoder behaviour.
- **Files modified:** `fixtures/png/decode-cases.json`, `scripts/fixtures/Generate-PngDecodeVectors.ps1`.
- **Commit:** `ec9e015`.

## Known Stubs

None.

## Self-Check: PASSED

- Task evidence commit `ec9e015` exists.
- Generated vectors, fixture manifest, generator, and PNG tests are present and verified.
