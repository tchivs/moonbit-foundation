# Phase 68: RGBA16 Decode Qualification - Research

**Date:** 2026-07-23
**Requirement:** `RGBA16DEC-04`
**Status:** Ready for planning

## Recommendation

Extend the established public PNG test fixtures rather than change decoder
architecture.  Add independent Type-6/16 literals for all five filter tags
and every Adam7 pass, then route those same literals through eager and chunk
helpers.  Add exact/one-less resource tests around the existing Rgba16
preflight and retain the ordinary serial four-target package command as the
final proof.

## Existing Seams

| Need | Reuse | Phase 68 addition |
|---|---|---|
| Eager exact lanes | `png_test_rgba16_literal` and `png_test_rgba16_adam7_literal` in `png_test.mbt` | Independent multi-row all-filter Type-6/16 literal plus complete coordinate assertions. |
| Adam7 traversal | existing 5x5 sRGB literal | Assert every eight-byte lane at every output coordinate and retain generic high-byte projection. |
| Chunk schedules | `png_rgba16_chunk_schedule` and `png_rgba16_chunk_eager` in `stream_decode_test.mbt` | Feed independent filter/Adam7 vectors through empty, one-byte and ragged schedules; compare exact components and budget/diagnostics. |
| Atomic admission/layout | `_png_rgba16_machine_*` helpers in `stream_decode_wbtest.mbt` | Exact and one-less normal/Adam7 output, allocation, image and work boundaries with no outcome. |

## Qualification Rules

- Expected output must be encoded in hand-authored wire literals with distinct
  high and low bytes; PngEncoder must not generate the oracle.
- The result pixel is eight bytes (`Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi`) while
  PNG filtering operates on MSB-first, eight-byte Type-6/16 source pixels.
- Keep Rgba16 profile, generic GenericRgba8, and the one machine unchanged
  unless a test proves a real defect.  No copied source tree or alternative
  decoder is permitted.
- Run `moon -C modules/mb-image test png --target <target> --frozen`
  serially for wasm, wasm-gc, js and native; aggregate `--target all` may
  exceed the runner limit and is not the authoritative final command.

## Test Order

1. Red/green public all-filter + all-lane eager and frozen generic tests.
2. Red/green chunk parity/hostile terminal tests on the same independent
   fixtures.
3. Red/green exact/one-less normal and Adam7 resource fixtures.
4. Serial ordinary full package test for all four targets.
