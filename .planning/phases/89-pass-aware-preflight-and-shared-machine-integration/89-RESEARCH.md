---
phase: 89
status: complete
---

# Phase 89 Research

## Current implementation seams

- `modules/mb-image/png/encode.mbt` already computes Adam7 pass scanlines in `_png_encode_indexed_preflight_with_profile_and_strategy` and routes Fixed matching through `PngFilteredMatchCursor::new_indexed_with_interlace`.
- The same private constructor is used by eager and chunked selector families in `encode.mbt` and `stream_encode.mbt`.
- `PngIndexedRawCursor::next` delegates each Adam7 byte to `_png_indexed_adam7_scanline_byte`; this preserves local MSB-first packing and zero tails without staging.
- Existing non-interlaced Phase 85 matrix tests and Stored Adam7 Phase 83/87 tests cover adjacent contracts but do not retain candidate-frame equality for Adam7 FixedOrStored across all four profiles.

## Verification strategy

Add a compact white-box fixture with odd 5x5 geometry and a two-entry palette for each wire profile. For each profile, run Adam7 FixedOrStored preflight, inspect the retained `PngDeflatePlan` candidate and frame total, then re-run with exact and one-less output/work limits and budgets. Keep source bytes independent of production pass/preflight helpers.

## Scope fences

No Dynamic/adaptive indexed compression, wider matching, dictionary, staging, second encoder, decoder changes, FFI, target wrapper, copied tree, release script, or registry work.
