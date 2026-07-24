---
phase: 90
status: complete
---

# Phase 90 Research

## Existing evidence

- `stream_encode_test.mbt` already contains hostile Stored Adam7 schedules, released-lease replay checks, independent chunk parsers, and public RGB/RGBA decode helpers.
- `png_phase87_inflate` is a test-local LSB-first Fixed/Stored DEFLATE parser with Adler checking; `png_phase87_crc32` and chunk helpers are independent of production PNG framing.
- Phase 89 added all-profile preflight and shared-machine white-box checks but did not independently parse a Fixed Adam7 stream.

## Implementation approach

Add a compact all-zero 5x5 fixture. Its highly repetitive pass-local raster forces a complete Fixed candidate while making expected raw lengths (22/24/27/36 for depths 1/2/4/8) explicit. Collect chunk output on `[0,1,3,2,5]`, compare with eager bytes only for lifecycle parity, then independently parse CRC/chunk order, Fixed DEFLATE, Adler, raw length/tails, and public RGB8/RGBA8 decode.

## Scope fences

No new encoder, decoder, compression profile, source model, staging, FFI, copied tree, release automation, or registry action.
