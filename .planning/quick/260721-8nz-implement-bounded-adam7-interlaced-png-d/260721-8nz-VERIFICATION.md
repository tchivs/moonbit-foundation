---
phase: quick-260721-8nz
verified: 2026-07-21
status: passed_with_baseline_warning
score: 6/6 must-haves verified
behavior_unverified: 0
---

# Quick Task 260721-8nz Verification Report

**Goal:** Decode bounded Adam7 PNG inputs through the existing eager RGB8/RGBA8 model without weakening profile semantics or resource limits.

## Goal Achievement

| Observable truth | Status | Evidence |
| --- | --- | --- |
| All supported profile/depth mappings decode under Adam7 | VERIFIED | Corpus covers grayscale 1/2/4/8/16 (opaque+tRNS), indexed 1/2/4/8 (PLTE opaque+tRNS), RGB 8/16 (opaque+tRNS), grayscale-alpha 8/16, and RGBA 8/16. |
| Seven passes use pass-local filters and scatter coordinates | VERIFIED | `_png_adam7_passes`, `_png_inflate_zlib_to_raster`, and `_png_write_adam7_row` are exercised by full-pass vectors and geometry/budget white-box tests. |
| Source bpp and raw transparency semantics remain correct | VERIFIED | Packed low-bit/index rows, 16-bit bpp 2/6/4/8, palette alpha, and same-high-byte/different-low-byte RGB16 tRNS cases pass. |
| Bounds and failures expose no successful image | VERIFIED | Exact/below budget white-box test plus hostile short/extra/filter/limit/malformed/semantic corpus failures run through the public decoder. |
| IDAT segmentation is equivalent | VERIFIED | Every accepted profile and selected hostile cases emit an unsplit baseline plus every nonempty contiguous two-IDAT split. |
| Portable generated evidence is independently constructed | VERIFIED | PowerShell independently reconstructs/deinterlaces scanlines, validates declared pixels and manifest digest, and the generated public test passes on all four targets. |

## Commands

| Command | Result |
| --- | --- |
| `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | PASS — 3,738 executable cases |
| `moon -C modules/mb-image test png --target all --frozen` | PASS — 34/34 per wasm, wasm-gc, js, native |
| `pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | PASS — policy, generated vectors, four-target tests, lane isolation |
| `moon -C modules/mb-image check --target all --deny-warn --frozen` | BASELINE WARNING — fails on 26 pre-existing `unused_field` diagnostics in `generated_vectors.mbt` and legacy `PngTransport` fields; the Adam7 implementation adds no such diagnostic |

## Key Regression Fixes

1. The inflater now checks completed Adam7 pass state instead of the non-interlaced row counter at zlib EOF.
2. Indexed Adam7 uses the shared pair of pass rows, preserving the preflight's three-allocation contract.

## Requirement Coverage

`PNGX-01` is satisfied for the Adam7 slice. This report does not claim unrelated PNGX-01 work outside this quick task.

