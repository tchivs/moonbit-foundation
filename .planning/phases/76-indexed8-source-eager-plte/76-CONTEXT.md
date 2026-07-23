# Phase 76: Indexed8 PNG Source & Eager PLTE - Context

**Discussed:** 2026-07-24
**Status:** Ready for planning

## Locked Decisions

- Add an owning, immutable PNG-only `PngIndexedImage` source contract; do not extend `ImageView`, `ImageFormat`, or generic `ImageEncoder`.
- The initial wire format is Type-3 at depth 8 only, non-interlaced, RGB palette only, Stored DEFLATE, and filter None.
- The source accepts canonical unpacked one-byte-per-pixel indices; it validates width/height, `indices.len == width * height`, palette count 1..256, and every index < palette count before output/budget exposure.
- Eager output must emit `IHDR → PLTE → IDAT → IEND` with exact independent CRC/wire tests and decode back through the existing public generic RGB8 route.
- Refactor the private machine framing facts as necessary to support variable ancillary chunks, but keep all legacy source profiles byte-identical and retain a single bounded traversal.
- tRNS, chunk output, non-Stored strategies, Indexed1/2/4, Adam7, quantization, and staging are deferred.

## Success Criteria

1. A caller can construct a valid Indexed8 RGB source without ambiguous `ImageView` semantics.
2. Valid eager encoding produces a legal Type-3/8 PNG with PLTE before IDAT and exact palette/index raster bytes.
3. Invalid source data fails atomically before writer/budget exposure.
4. Existing generic, Gray, GrayAlpha, and RGBA PNG output stays byte-identical.
