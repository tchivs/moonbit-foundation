---
quick_id: 260721-3xb
name: validate-decode-non-interlaced-8-bit-indexed-png
status: complete
requirements: [PNGX-01]
subsystem: png
tags: [png, indexed-colour, plte, deflate, fixtures]
provides: [strict-non-interlaced-8-bit-indexed-png-rgb8-decode]
affects: [mb-image-png]
metrics: { tasks: 3, targets: 4 }
---

# Quick Task 260721-3xb: Indexed PNG Decode Summary

Implemented the strict non-interlaced 8-bit indexed PNG subset: a single valid pre-IDAT PLTE is reconstructed through one-byte index filters and mapped into RGB8 without changing type 0, 2, or 6 behavior.

## Completed Work

- Added type-3 IHDR support, exact PLTE length/order/CRC validation, and a palette-only stream transport path.
- Reserved RGB image storage and two width-byte index rows through one child budget; all three allocations consume that same child.
- Reconstructed indexed filter lanes separately from RGB output and reject an index outside the declared PLTE entry count.
- Generated public vectors for every indexed filter and every nonempty two-IDAT split, plus missing, malformed, duplicate, post-IDAT, CRC-invalid, overrun, and tRNS cases.

## Scope Completion

This task completes only the opaque 8-bit indexed PLTE-to-RGB8 slice of
PNGX-01. Indexed transparency, low bit depths, palette-preserving output,
16-bit profiles, Adam7, and colour-management support remain future work.

## Verification

- `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check`
- `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngStructuralVectors.ps1 -Check`
- `moon -C modules/mb-image test png --target all --frozen` — 22/22 passed on wasm, wasm-gc, js, and native.
- `pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed.

## Commits

- `af83ac3` — RED coverage for type-3 IHDR.
- `2d8f3e3` — PLTE transport and budget reservation.
- `2690a24` — RED coverage for indexed filter reconstruction.
- `acd83dc` — indexed filter and palette RGB8 decoder.
- `9c8bbe6` — generated indexed corpus and manifests.

## Deviations from Plan

None - the generator corpus was extended inline and its independently reconstructed RGB oracle caught a floor-division mismatch during fixture development before artifacts were emitted.

## Self-Check: PASSED

- All committed PNG source, fixture, generator, and generated-vector files exist.
- Every listed commit is present on the current branch.
