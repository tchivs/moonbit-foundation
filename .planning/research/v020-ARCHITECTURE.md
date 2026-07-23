# v0.20 Architecture: High-Precision GrayAlpha Decode

**Project:** MoonBit Native Foundation
**Milestone:** v0.20 High-Precision GrayAlpha Decode
**Scope:** Type-4 / 16-bit PNG decode only
**Confidence:** HIGH — derived from the current decoder, model/storage contracts, and v0.19 archive.

## Decision

Add one explicit, opt-in Type-4/16 decode profile to the existing PNG decoder
machine. It returns the existing `@codec.DecodeResult`, whose image is a
validated `@model.ImageFormat::graya16()` image. Do not alter the generic
`@codec.ImageDecoder` implementation for `PngDecoder`, the existing
`PngChunkDecoder::new`, or any existing RGB8/RGBA8 conversion behavior.

The narrow public surface should be:

```moonbit
PngDecoder::decode_graya16(
  reader : &@io.Reader,
  options : @codec.DecodeOptions,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[@codec.DecodeResult, @error.CoreError]

PngChunkDecoder::new_graya16(
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> PngChunkDecoder
```

`new_graya16` retains the existing `push` and `finish` APIs; `finish` still
returns `DecodeResult`. A new result wrapper is unnecessary: the result already
owns the image, descriptor, metadata disposition, and exact byte count. The
explicit method/constructor states that the caller requires high-precision
GrayAlpha rather than accepting the generic canonical image.

## Explicit Contract

### Accepted input

The opt-in profile accepts only a structurally valid PNG with colour type 4 and
bit depth 16. It must retain all current strict PNG framing, CRC, DEFLATE,
filter, IDAT-contiguity, IEND, EOF, input-limit, geometry-limit, work-limit,
budget, and sticky-terminal rules. Both non-interlaced and Adam7 inputs use the
already-supported source-row/pass machinery.

If IHDR names another legal PNG profile, the opt-in path returns a typed
capability/encoding error before output allocation; it never falls back to
RGBA8. The ordinary decoder remains the route for every other PNG profile.

### Successful image

For every decoded pixel, the result has:

| Property | Required value |
|---|---|
| Format | packed little-endian `graya16()` |
| Components | two U16 components, Gray then Alpha |
| Storage | four bytes/pixel: `Glo, Ghi, Alo, Ahi` |
| PNG source order | reconstructed `Ghi, Glo, Ahi, Alo` |
| Alpha | `Straight`; no premultiplication or alpha conversion |
| Dimensions/orientation | input width/height and `TopLeft` |
| Component fidelity | every reconstructed source byte is preserved exactly; no high-byte selection, scaling, rounding, dithering, or colour transform |
| Progress | existing exact `bytes_read` / chunk `consumed` semantics |

The contract is observable through `ImageView::get_component_byte`; the
established accessors already permit packed U16 component-byte reads and reject
the U8-only `get_byte` path for such an image. Do not add a parallel U16 view,
an RGBA16 model, or a conversion API.

### Colour identity and metadata

`ImageDescriptor::graya16` deliberately admits only packed little-endian,
top-left, builtin-sRGB, encoded-sRGB, straight-alpha data. Therefore this
milestone's explicit result contract is **encoded sRGB gray samples plus
straight alpha**. A PNG with no colour declaration or an `sRGB` declaration is
accepted; the `sRGB` rendering intent may remain in the existing opaque PNG
metadata entry. A legacy gAMA/cHRM declaration or iCCP declaration cannot be
represented faithfully by the established `graya16` descriptor and must be
rejected by this opt-in profile before its image is allocated.

This is intentionally a format-identity boundary, not an invitation to change
the colour model. The generic decoder keeps its current metadata behavior and
RGBA8 canonical result for those same inputs.

### Legacy compatibility

The generic `@codec.ImageDecoder::decode(PngDecoder::new(), ...)` and
`PngChunkDecoder::new(...)` stay unchanged. Type-4/16 continues to decode there
as straight RGBA8 `(Ghi, Ghi, Ghi, Ahi)`. Existing wire vectors, public
high-byte decode tests, chunk schedules, metadata behavior, and terminal errors
remain frozen compatibility evidence.

## Integration Shape

```text
PngDecoder::decode_graya16 / PngChunkDecoder::new_graya16
                         |
                         v
                 PngDecodeMachine(profile)
                         |
                 existing framing + IHDR validation
                         |
                 Type4/16 + sRGB-identity gate
                         |
              existing IDAT / DEFLATE / filter reconstruction
                         |
                         v
          PngRasterSink(profile-aware destination write)
                         |
             Ghi,Glo,Ahi,Alo --> Glo,Ghi,Alo,Ahi
                         |
                         v
                 existing DecodeResult at EOF

Generic ImageDecoder / PngChunkDecoder::new
                         |
                         v
              unchanged RGBA8 (Ghi,Ghi,Ghi,Ahi)
```

### Exact component boundaries

| Boundary | Required change | Must remain unchanged |
|---|---|---|
| `png.mbt` | Add the explicit eager method; keep trait `decode` calling the canonical profile. Add `new_graya16` beside the existing chunk constructor. | `PngDecoder` trait surface and all existing constructors. |
| `stream_decode.mbt` | Store a private decode profile in `PngDecodeMachine`/`PngChunkDecoder`; resolve it at first IDAT after colour facts are known. | Byte acceptance, caller-view non-retention, `push`, `finish`, EOF precedence, sticky terminals, and one-result transfer. |
| `structural.mbt` | Derive the profile's output layout and budget from IHDR. GrayAlpha16 needs four storage bytes/pixel plus the existing two reconstructed source rows. | PNG type/depth validation, source bytes-per-pixel, Adam7 geometry, and all generic output budgets. |
| `raster_decode.mbt` | Select the `graya16` descriptor and identity metadata for the opt-in profile. Add one shared pixel/store helper that writes the two reconstructed big-endian components in little-endian storage order; invoke it from the existing row and Adam7 writers. | Framing, inflation, filter reconstruction, row buffers, palette logic, generic raster writers, and generic descriptor creation. |
| model/storage | Reuse `ImageFormat::graya16`, descriptor validation, `OwnedImage`, and component-byte access exactly as they exist. | No changes to generic image, colour, operation, or storage APIs. |

The internal profile must be chosen once and passed through the one existing
machine. It is not a second decoder, staged raw-raster buffer, wrapper, copied
decode loop, target branch, or FFI seam.

## Allocation and Safety Contract

Resolve the Type-4/16 profile before creating `OwnedImage`. The layout is
`width * height * 4` output bytes, not `width * height * 2`: there are two
16-bit output components. Continue reserving exactly the existing two
reconstructed encoded rows (`width * 4` each) and applying checked arithmetic
to every dimension, output, allocation, and work value.

The colour-identity gate belongs at `preflight_first_idat`, after ancillary
colour facts are complete but before descriptor/image allocation. This retains
the current no-partial-image rule and prevents an incompatible declaration from
leaving a private output allocation behind. The generic profile's preflight
and output-ledger calculations must not change.

## Evidence Plan

1. **Non-interlaced direct decode:** Use the existing asymmetric 2×1 Type-4/16
   wire source (`1234/a7c5`, `be0f/5a76`). Assert descriptor format, straight
   alpha, sRGB identity, exact four component bytes at each pixel, and exact
   `bytes_read`.
2. **Adam7 direct decode:** Use the existing all-seven-pass asymmetric
   GrayAlpha16 fixture. Assert the coordinate-derived high and low Gray/Alpha
   bytes, so pass placement and byte order are independently visible.
3. **Chunk equivalence:** Run empty, one-byte, and established ragged input
   schedules through `new_graya16`; assert exact component-byte equality with a
   fresh direct eager decode, exact accepted counters, no caller-view retention,
   explicit-finish completion, and sticky terminals.
4. **Profile rejection before allocation:** Exercise Type-4/8, Type-0/16,
   Type-6/16, and a Type-4/16 legacy-colour/ICC declaration. Assert the new
   typed profile error, unchanged budget where admission fails before allocation,
   and no result visibility.
5. **Legacy regression:** Re-run the existing `PngDecoder` and ordinary chunk
   vectors for the same Type-4/16 bytes, asserting their `U8/Rgba` high-byte
   result exactly. Do not replace their literal or canonicalization checks.
6. **Qualification:** Run the full PNG package on `js`, `wasm`, `wasm-gc`, and
   `native`; the feature is pure MoonBit and has no target-specific route.

## Non-Goals

- No generic `DecodeOptions` field, `ImageDecoder` trait change, or broad
  decoder-result redesign.
- No preservation of non-sRGB/ICC Type-4/16 colour identity, no colour
  conversion, and no premultiplied-alpha support.
- No Big-endian image storage, RGB/RGBA 16-bit model expansion, or new image
  operations/conversions.
- No decoder-wide refactor, raw-raster/image-sized staging, copied parser or
  inflater, wrapper type, FFI, target wrapper, release work, or source copy.

## Risks and Guards

| Risk | Guard |
|---|---|
| Low bytes are reconstructed correctly but discarded by a legacy writer. | Use a distinct opt-in profile and assert all four storage bytes, not just U16 values or high-byte RGBA. |
| U16 storage order is accidentally PNG big-endian. | Test `Glo,Ghi,Alo,Ahi` through `get_component_byte` against an independent `Ghi,Glo,Ahi,Alo` wire fixture. |
| Budget is undercharged by treating `GrayAlpha` as two bytes/pixel. | Derive storage byte width from the selected output layout; test output and allocation ceilings at `4 * pixels`. |
| Non-sRGB metadata becomes silently mislabeled as sRGB. | Reject legacy/ICC colour declarations in the explicit profile before allocation; leave generic decode unchanged. |
| New work changes existing application-visible decode behavior. | Keep the trait implementation and ordinary chunk constructor on the canonical profile; retain existing high-byte fixtures. |
| Adam7 gets a separate implementation or loses source-byte filtering. | Reuse existing pass geometry, packed rows, reconstruction, and sink; change only final destination storage. |

## Sources

- `modules/mb-image/png/png.mbt` — public decoder and chunk-decoder seams; the
  generic trait currently owns the canonical result.
- `modules/mb-image/png/stream_decode.mbt` — first-IDAT allocation point,
  private lifecycle, exact chunk state, and terminal `DecodeResult` transfer.
- `modules/mb-image/png/structural.mbt` — Type-4/16 legality, source-row
  geometry, Adam7/budget helpers, and private transport facts.
- `modules/mb-image/png/raster_decode.mbt` — current high-byte Type-4/16
  canonicalization and shared reconstructed-row writers.
- `modules/mb-image/model/descriptor.mbt` and
  `modules/mb-image/storage/views.mbt` — existing `graya16` identity and
  packed-U16 component-byte contract.
- `modules/mb-image/png/encode_test.mbt`, `raster_decode_wbtest.mbt`, and
  `stream_decode_test.mbt` — asymmetric wire fixtures, current high-byte
  compatibility contract, and hostile public chunk patterns.
- `.planning/milestones/v0.19-REQUIREMENTS.md` and
  `.planning/milestones/v0.19-MILESTONE-AUDIT.md` — explicitly defer decoder
  widening to this dedicated milestone while preserving the finished v0.19
  scope and evidence.
