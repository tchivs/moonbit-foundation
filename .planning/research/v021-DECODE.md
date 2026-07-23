# v0.21 PNG Type-6/16 Decoder Integration Research

**Scope:** add an opt-in, lossless PNG colour-type 6 / bit-depth 16 decode
profile. This does not change the established generic PNG decoder result
contract.

**Confidence:** HIGH for repository findings; MEDIUM for PNG-standard facts
(verified against W3C through search, but the configured provider reports LOW).

## Recommendation

Add one explicit preservation profile, Rgba16, with exactly two selectors:

- PngDecoder::decode_rgba16(...) for eager readers.
- PngChunkDecoder::new_rgba16(...) for caller-owned chunks.

It accepts only IHDR (colour_type=6, bit_depth=16) and returns packed,
little-endian, straight-alpha U16 RGBA. The generic decode and chunk-new
contracts stay frozen: Type-6/16 continues to return the existing RGBA8
high-byte projection. Precision is opt-in, matching the v0.20 GrayAlpha16
decision.

PNG Type 6 is RGB followed by alpha; 16-bit samples are MSB-first and alpha is
straight. Each reconstructed source pixel
Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo must therefore be stored as
Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi.

## Reuse the Existing Decoder Seam

| Concern | Existing implementation | v0.21 action |
|---|---|---|
| Public selection | PngDecodeProfile GenericRgba8 / GrayAlpha16 plus eager/chunk entry points | Add Rgba16 and matching selectors only. |
| IDAT preflight | PngDecodeMachine::preflight_first_idat | Validate exact Type-6/16, then construct metadata, descriptor, image and sink before IDAT data. |
| Filters | PngPackedRows::reconstruct consumes source_bytes_per_pixel | Reuse unchanged: Type-6/16 must use bpp 8 for Sub/Paeth. |
| Normal final store | 16-bit branches in PngRasterSink::emit | Add the precise four-U16 store branch. |
| Adam7 final store | _png_write_adam7_transport_row already takes profile and pass rows | Add the same store branch at final scatter coordinates. |
| Streaming lifecycle | private sink owns the image until zlib, raster, IEND, and EOF complete | Preserve unchanged; do not expose progressive stores. |

v0.20 GrayAlpha16 is the direct pattern: exact U16 storage, paired
eager/chunk tests, all five filter tags, and an independent all-seven-pass
Adam7 fixture. Its comments say “non-interlaced,” but its implementation and
tests already support Adam7; follow behaviour, not that stale wording.

## Minimal Design

### Model and descriptor

Add ImageFormat::rgba16() as canonical U16/Rgba/Packed/Little. Generic format,
component-byte storage views, and descriptor validation already support it.

Add _png_rgba16_descriptor_with_metadata beside the GrayAlpha16 descriptor:

    pixels       = checked_mul(width, height)
    storage      = checked_mul(pixels, 8)
    row_bytes    = checked_mul(width, 8)
    plane        = packed full extent, stride == row_bytes
    format       = rgba16()
    metadata     = alpha Straight

Keep Type-6 metadata semantics aligned with generic decoding. Reuse default,
sRGB, legacy, and ICC declaration handling. RGBA U16 has no GrayAlpha-style
built-in-sRGB identity restriction, so valid legacy/ICC declarations should
not be rejected only by this precision profile.

### Preallocation metadata gate

The first authenticated IDAT header remains the only output-allocation
boundary. IHDR and CRC-authenticated pre-IDAT chunks first determine colour
facts and metadata. At preflight_first_idat:

1. Reject any profile mismatch as rgba16-profile before output allocation.
2. Reuse existing colour-declaration validation and reserve/build metadata
   first.
3. Reserve the exact raster child budget, construct descriptor, OwnedImage,
   and sink once, then begin inflating IDAT bytes.

The shared budget helpers currently call their parameter channels but use it
as **storage bytes per pixel**. That is harmless for U8 generic output but
ambiguous for precision profiles: GrayAlpha16 is 2 channels / 4 bytes, Rgba16
is 4 channels / 8 bytes. Change the helper input to storage_bytes_per_pixel
(or a small profile-layout record), and use it for normal and Adam7
image_bytes, aggregate bytes, work, and allocation size.

| Route | Storage bytes/pixel |
|---|---:|
| Generic RGB8/RGBA8 | 3 or 4 |
| Existing GrayAlpha16 | 4 |
| New Rgba16 | 8 |

This is a resource-security gate, not an optimization: final-store allocation
and output limits must reflect U16 storage, while filtered-output limits remain
encoded scanline bytes. Regression-test v0.20 boundaries while making this
shared change.

### Normal and Adam7 stores

For normal rows, add the Rgba16 branch beside the existing 16-bit /
source-channel-4 generic high-byte path. It writes four set_component_byte
pairs, low byte then high byte. The generic path must not change.

For Adam7, add the identical branch inside _png_write_adam7_transport_row
after reconstructing the pass-local row:

    x = pass.x + column * pass.dx
    y = pass.y + row * pass.dy

The existing sink resets two encoded-row buffers between passes and keeps only
those buffers plus the final image. Reuse it; Type-6/16 needs neither an
image-sized staging buffer nor an intermediate-raster API.

## Compatibility Rules

- Generic Type-6/16 remains the historical U8 RGBA high-byte projection,
  including alpha.
- decode_rgba16/new_rgba16 preserve every component byte; no premultiply,
  scaling, rounding, or colour transform.
- Both selectors share PngDecodeMachine, retaining chunk consumption,
  zero-byte pushes, sticky first errors, finish, IEND/EOF precedence,
  diagnostics, and budget parity.
- Reject Type 0/2/4, Type 6 depth 8, malformed metadata, and invalid Type-6
  tRNS arrangements via existing structural validation. Do not broaden generic
  acceptance.

## Required Tests

1. **Model:** rgba16() produces packed little-endian U16 RGBA with 8-byte
   pixels and straight-alpha component-byte access.
2. **Normal eager:** independent 2x1 Type-6/16 literal with all eight source
   bytes distinct; assert storage order and unchanged generic high-byte output.
3. **Filters:** independent multi-row fixture using tags 0–4 with distinct low
   bytes, catching accidental bpp=4 reconstruction or high-byte-only writes.
4. **Adam7:** independent 5x5 Type-6/16 all-seven-pass fixture; assert every
   final component byte at every coordinate.
5. **Chunk parity:** zero then one-byte and ragged schedules for normal,
   filters, and Adam7. Compare descriptor, metadata, component bytes,
   bytes_read, diagnostics, and all budget remainders with eager.
6. **Admission/atomicity:** wrong IHDR profile, rejected metadata, truncated
   data, malformed filter, and post-terminal replay retain typed errors; no
   lifecycle/result exists before valid first-IDAT preflight.
7. **Resources:** exact and one-less normal/Adam7 output ceilings plus
   allocation-size and byte budgets prove the 8-byte store is charged before
   decompression advances.

## Implementation Order

1. Add rgba16() and descriptor/storage tests.
2. Generalize output-layout budgeting and regression-test existing GrayAlpha16.
3. Add Rgba16 profile preflight and the two selectors.
4. Add normal/Adam7 stores, independent fixtures, and full eager/chunk parity.

## Sources

- Repository evidence: modules/mb-image/png/{png.mbt,stream_decode.mbt,raster_decode.mbt,structural.mbt,png_test.mbt,stream_decode_test.mbt} and modules/mb-image/model/{descriptor.mbt,model_test.mbt} at e2128e7.
- [W3C PNG Specification (Third Edition): colour types, sample order, filtering, Adam7](https://www.w3.org/TR/png-3/). **External-source confidence: LOW** (provider classification); repository implementation/tests independently corroborate the integration seam.

