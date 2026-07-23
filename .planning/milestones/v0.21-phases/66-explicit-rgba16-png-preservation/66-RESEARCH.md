# Phase 66: Explicit RGBA16 PNG Preservation - Research

**Date:** 2026-07-23
**Requirement:** `RGBA16DEC-02`
**Status:** Ready for planning

## Recommendation

Add `PngDecodeProfile::Rgba16` and only the eager public selector
`PngDecoder::decode_rgba16`.  Reuse the existing byte-fed decoder machine,
unfiltering, lifecycle and Adam7 traversal; the new profile changes profile
admission, output-layout charging, the checked `rgba16` descriptor, and the
two final stores.  The generic `GenericRgba8` path is not changed.

## Evidence and Integration Seams

| Concern | Existing seam | Phase 66 action |
|---|---|---|
| Public eager entry point | `modules/mb-image/png/png.mbt` delegates to the decode machine | Add `decode_rgba16` with the Rgba16 profile; defer chunk construction. |
| Profile selection | `PngDecodeProfile` and `PngDecodeMachine::new_with_profile` in `stream_decode.mbt` | Add Rgba16 beside GrayAlpha16; retain generic default. |
| First-IDAT admission | `PngDecodeMachine::preflight_first_idat` | Require colour type 6 / depth 16, legal encoded-sRGB metadata and no transparency before sink construction. |
| Allocation layout | shared preflight helpers and descriptor construction | Use four channels and **eight storage bytes per pixel** for output/allocation/budget checks; do not mistake source channels for storage bytes. |
| Normal raster | profile-aware `PngRasterSink` final row emission | Store each decoded wire pixel `Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo` as `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi`. |
| Adam7 raster | `_png_write_adam7_transport_row` final scatter | Use the identical four-U16 store at `(pass.x + col*pass.dx, pass.y + row*pass.dy)`. |

## Locked Compatibility and Admission

- Only Type-6/16 may enter Rgba16.  Type/depth mismatches, `tRNS`, legacy
  colour declarations and ICC declarations must fail before the explicit
  image exists.  An absent colour declaration and `sRGB` are the two legal
  modes.
- The current `.planning/REQUIREMENTS.md` and `66-CONTEXT.md` override the
  older `.planning/research/v021-DECODE.md` suggestion to admit legacy/ICC
  metadata.
- Generic Type-6/16 decoding remains the historic high-byte result
  `RGBA8(Rhi,Ghi,Bhi,Ahi)`; neither generic descriptor nor final-store branch
  changes.
- Filters remain byte-domain and need an eight-byte source pixel stride.
  Both ordinary rows and Adam7 are in scope because they are existing paths
  through the same machine; no second decoder or full-image staging buffer is
  required.

## Implementation and Test Order

1. Add focused RED tests for the eager selector, strict profile admission,
   packed lane order, generic high-byte regression, and correct eight-byte
   allocation boundary.
2. Add Rgba16 profile and a small profile-layout seam so Type-6/16 preflight
   reserves and builds the Phase-65 `rgba16` descriptor before inflate.
3. Add normal and Adam7 final stores only under the explicit profile.
4. Run targeted PNG tests first, then the ordinary four-target PNG package
   command.  Preserve existing GrayAlpha16 limit cases while changing shared
   layout accounting.

## Scope Fences

- No `PngChunkDecoder::new_rgba16` or caller-buffered lifecycle work.
- No non-sRGB/ICC transform, endianness option, high-precision conversion
  API, alternate decoder, copied source tree, or release automation.
- Broad independent filter/Adam7 wire qualification and hostile resource
  matrix remain Phase 68, but Phase 66 must make its shared stores correct.
