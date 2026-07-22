# Phase 48 Research: Bounded Gray16 Encoder Path

## Conclusion

Gray16 must use a profile-aware PNG wire-byte producer across every filter, match, Fixed, Dynamic, checksum, and replay traversal. The current Phase 47 Stored/None special path is intentionally transitional and must be removed.

## Existing Seams

- `modules/mb-image/png/encode.mbt`: `_png_fixed_scanline_byte`, `_png_filter_image_raw_byte`, `PngFilteredCursor`, `PngFilteredMatchCursor`, Fixed/Dynamic planners, and profile-aware preflight.
- `modules/mb-image/png/stream_encode.mbt`: machine cursor construction and Fixed/Dynamic replay reads.
- `modules/mb-image/png/png.mbt` and `stream_encode.mbt`: Gray8 strategy factory family to mirror.

## Required Design

1. Introduce a private profile-aware wire-byte source for raw rows and scanlines. For Gray16 it maps one U16 Gray component to high-byte/low-byte PNG order through `ImageView::get_component_byte`; legacy and Gray8 retain `get_byte` behavior.
2. Carry profile information into all bounded filtering, match, Fixed, Dynamic, and stream replay cursors. The existing `channels` scalar is the Gray16 filter stride (`2UL`) and must remain the byte-distance for Sub/Average/Paeth.
3. Remove the Gray16 `Stored/None` preflight gate and the `gray16_stored_none` planning/replay bypass. Retain the non-interlace rejection.
4. Mirror the Gray8 eager/chunk compression-only, filter-only, and combined explicit Gray16 factories.

## Invariants and Tests

- Gray16 stays PNG type 0, bit depth 16, non-interlaced; every wire sample is high byte then low byte regardless of source endianness.
- No converted row or image-sized staging; retain scalar cursors and the existing bounded matcher window only.
- Planning/replay, Adler, fingerprint, filters, and emitted bytes consume one identical wire stream.
- Test all six compression/filter pairs, little/big-endian non-symmetric samples, adaptive byte-stride behavior, eager/chunk identity, repeated preview/sticky failure, atomic rejection, and frozen legacy vectors.
