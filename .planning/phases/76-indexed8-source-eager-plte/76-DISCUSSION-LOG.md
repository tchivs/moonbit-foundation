# Phase 76 Discussion Log

## 2026-07-24 — Autonomous scope resolution

- **Chosen contract:** immutable `PngIndexedImage` in the PNG module, owning an unpacked index raster and RGB palette.
- **Reason:** Type-3 decode expands to RGB/RGBA and cannot reconstruct palette/index semantics; the generic image model has no Index channel.
- **First slice:** Indexed8 + opaque PLTE + eager Stored/None only. This forces a correct variable chunk layout before tRNS and resumable output expand the matrix.
- **Deferred:** palette alpha/tRNS, chunk lifecycle, low-bit index packing, Adam7 and compression/filter strategies.
