# v0.20 Stack Research: High-Precision GrayAlpha Decode

**Project:** MoonBit Native Foundation
**Milestone:** v0.20 High-Precision GrayAlpha Decode
**Researched:** 2026-07-23
**Overall confidence:** MEDIUM — the standards and the repository implementation are directly verified; the exact additive public API remains a design decision for the milestone.

## Recommendation

Implement an **additive, opt-in Type-4/16 preservation result** within the existing `mb-image/png` decoder. Use the existing packed little-endian `ImageFormat::graya16()` and `OwnedImage` storage for the preserved result; retain the existing `PngDecoder` / `PngChunkDecoder` RGBA8 result as the legacy compatibility route. The decoder must reconstruct PNG's four wire bytes per pixel (`Ghi, Glo, Ahi, Alo`) before storing them as little-endian component bytes (`Glo, Ghi, Alo, Ahi`). Do not add a package, native stub, FFI adapter, BigInt route, or colour-management dependency.

This is the smallest credible stack because the public model already supports exactly the destination representation: `U16 + GrayAlpha + Packed + Little` is constructed by `ImageFormat::graya16()` ([`descriptor.mbt:89`](../../modules/mb-image/model/descriptor.mbt#L89)), and the descriptor explicitly permits that format only with straight alpha, built-in sRGB identity, and top-left orientation ([`descriptor.mbt:489`](../../modules/mb-image/model/descriptor.mbt#L489)). Storage already provides checked `get_component_byte` / `set_component_byte` APIs for packed U8 or U16 data ([`views.mbt:238`](../../modules/mb-image/storage/views.mbt#L238), [`views.mbt:535`](../../modules/mb-image/storage/views.mbt#L535)).

## Standards Contract

| Concern | Required contract | Implementation implication |
|---|---|---|
| PNG colour type 4 | Each pixel is grayscale then alpha. | The source-channel count is two; do not reinterpret the second component as premultiplied alpha. |
| Type 4 bit depth | PNG permits 8 or 16 bits/sample. v0.20 scope is the 16-bit branch. | Reject neither legal Type-4/16 nor the existing Type-4/8 route. |
| 16-bit wire order | Samples are network byte order (MSB first). | Reconstruct/filter in `Ghi,Glo,Ahi,Alo`; only the destination storage swaps to little-endian. |
| Filtering | PNG filters operate on encoded source bytes, not a converted image format. | Keep `source_bytes_per_pixel = 4` and `bpp = 4` through reconstruction. Do not filter U16 host-order words or canonical RGBA8. |
| Adam7 | Adam7 passes are separately filtered reduced images. | Reset packed row predictors at each pass; scatter fully reconstructed U16 components to destination coordinates. |

The [W3C PNG Fourth Edition](https://w3c.github.io/png/) is the governing standard source: it specifies grayscale/alpha image arrays, same-sized 8- or 16-bit alpha samples, and the PNG data model. The legacy PNG specification additionally states that 16-bit samples are MSB-first and that multi-sample pixels are not bit-packed ([PNG Specification](https://www.w3.org/TR/REC-png-961001)). **Source confidence: MEDIUM** (official sources retrieved through the configured web seam).

Repository structural validation already matches the proposed scope: Type 4 accepts only bit depths 8 or 16 ([`structural.mbt:727`](../../modules/mb-image/png/structural.mbt#L727)); source byte distance becomes `source_channels * 2` at depth 16 ([`structural.mbt:535`](../../modules/mb-image/png/structural.mbt#L535)).

## Existing Stack and the Exact Loss Boundary

```text
PNG Type-4/16 wire bytes      current decoder                        current public result
Ghi Glo Ahi Alo        ->     bytewise PNG filter reconstruction ->  RGBA8(Ghi,Ghi,Ghi,Ahi)
                                      |
                                      +-- v0.20 opt-in path --> GrayAlpha16 LE(Glo,Ghi,Alo,Ahi)
```

The current pipeline already makes the right ordering decision: `PngRasterSink` allocates a private result only after IDAT preflight ([`stream_decode.mbt:469`](../../modules/mb-image/png/stream_decode.mbt#L469)), reconstructs packed source rows with byte-level `bpp = source_bytes_per_pixel` ([`raster_decode.mbt:386`](../../modules/mb-image/png/raster_decode.mbt#L386)), and keeps Adam7 predictor rows pass-local ([`raster_decode.mbt:256`](../../modules/mb-image/png/raster_decode.mbt#L256)). It also withholds the image until zlib, raster, IEND, and EOF validation complete ([`stream_decode.mbt:521`](../../modules/mb-image/png/stream_decode.mbt#L521)). Preserve all of those ownership, boundedness, and terminal semantics.

The loss occurs only at the row writer: `_png_write_16bit_grayscale_alpha_row` reads `Ghi` at offset 0 and `Ahi` at offset 2, replicates grayscale into RGB, and writes only four U8 output bytes ([`raster_decode.mbt:210`](../../modules/mb-image/png/raster_decode.mbt#L210)). The public descriptor is correspondingly hard-coded to RGB8/RGBA8 ([`raster_decode.mbt:44`](../../modules/mb-image/png/raster_decode.mbt#L44)), and IHDR preflight calls Type 4 an RGB(A) exposure ([`structural.mbt:743`](../../modules/mb-image/png/structural.mbt#L743)). Existing generated Type-4/16 cases visibly assert that high-byte canonicalization ([`generated_decode_vectors_test.mbt:896`](../../modules/mb-image/png/generated_decode_vectors_test.mbt#L896)).

## Recommended Minimal Component Changes

| Existing component | v0.20 responsibility | Do not change |
|---|---|---|
| `model/descriptor.mbt` | Reuse `ImageFormat::graya16()` and its identity rules. | No new global image component type or endianness policy. |
| `storage/views.mbt` | Reuse component-byte access to write/read exact LE bytes. | Do not redefine `get_byte`; it is intentionally U8-only ([`views.mbt:182`](../../modules/mb-image/storage/views.mbt#L182)). |
| `png/structural.mbt` | Parameterize output descriptor/budget by explicit decoder result profile only where Type-4/16 preservation is selected. | Keep IHDR validation, PNG wire order, checked arithmetic, colour declaration handling, and all limits. |
| `png/raster_decode.mbt` | Add a Type-4/16 writer that stores both reconstructed source bytes per component in LE destination order; add equivalent Adam7 scatter writer. | Keep the legacy high-byte row writer as the default compatibility conversion. |
| `png/stream_decode.mbt` | Carry the selected result profile into preflight and private sink construction. | Keep no-visible-partial-image and `finish()` terminal authority. |
| `png/png.mbt` | Add an explicit decoder/factory/result selector naming the preservation contract. | Do not silently alter `PngDecoder::new()` or `PngChunkDecoder::new()` return behavior. |

Use one private result-profile enum rather than a second decoder. It should choose (1) destination descriptor, (2) output-byte count and budgets, and (3) the row/scatter writer. The shared parser, CRC, IDAT, inflater, row buffers, filter reconstruction, colour-chunk parser, and chunked state machine must remain one implementation.

## Public Contract Boundary

### Preserve route

The opt-in result must promise all of the following only for Type-4/16:

- destination format is packed `graya16`, little-endian, straight alpha, built-in encoded sRGB/top-left identity;
- component bytes equal the reconstructed PNG samples exactly after the documented endian change: PNG `Ghi,Glo,Ahi,Alo` maps to storage `Glo,Ghi,Alo,Ahi`;
- it does **not** apply scaling, rounding, premultiplication, alpha compositing, or a colour transform;
- output becomes observable only through the existing successful eager return or chunk `finish()` boundary.

### Legacy conversion route

Keep `PngDecoder::new()` and `PngChunkDecoder::new()` byte-for-byte and API-compatible. Their Type-4/16 conversion remains `RGBA8(Ghi,Ghi,Ghi,Ahi)`, with the low bytes intentionally discarded. That boundary is existing behavior, not an implicit guarantee that all PNG decode results preserve source precision; the current public decoder is explicitly documented as RGB8/RGBA8 interchange ([`png.mbt:2`](../../modules/mb-image/png/png.mbt#L2)).

No generic conversion API should be widened in this milestone. `ops/convert.mbt` currently supports RGB8/straight-RGBA8 conversion only ([`convert.mbt:33`](../../modules/mb-image/ops/convert.mbt#L33)); expanding colour, alpha, or U16 conversion semantics would be a separate contract. If v0.20 needs a convenience conversion, make it a narrowly named, explicitly lossy `GrayAlpha16 -> straight RGBA8` operation with an unambiguous high-byte rule and separate budgeting—not a hidden decode fallback.

## Portability and Dependencies

| Decision | Recommendation | Evidence |
|---|---|---|
| Implementation language | Pure MoonBit using `UInt64`, `Byte`, `Bytes`, checked arithmetic, and existing owned storage. | The current code already uses those primitives throughout preflight and raster reconstruction. |
| External libraries | None. | The needed U16 type, LE storage, callback-scoped mutability, PNG parser, DEFLATE, filters, and Adam7 traversal are in-tree. |
| FFI | None. | No host codec or byte-order intrinsic is necessary; byte swapping is two explicit indexed byte writes. |
| Target support | Require `wasm`, `wasm-gc`, `js`, and `native` from the same source and fixtures. | [MoonBit package documentation](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) documents these production targets and `supported-targets`; repository history requires all four. **Source confidence: MEDIUM.** |
| Byte order | PNG wire remains big-endian; only the public U16 storage representation is little-endian. | The model's existing `graya16()` contract is little-endian; the encoder already emits Type-4/16 wire in PNG order per the project archive. |

## Budget and Security Requirements

The preservation route changes the final image from 4 bytes/pixel RGBA8 to 4 bytes/pixel GrayAlpha16, so its **image allocation size is the same** for Type-4/16. It must nevertheless remain a separate descriptor and keep both reconstructed source rows (`2 * width * 4`) inside the declared budget. Reuse the checked `UInt64` preflight pattern already used by `_png_16bit_decode_budget` ([`structural.mbt:640`](../../modules/mb-image/png/structural.mbt#L640)) and its Adam7 analogue ([`structural.mbt:607`](../../modules/mb-image/png/structural.mbt#L607)); do not calculate byte counts with `Int` or create an image-sized intermediate wire buffer.

Required regression matrix:

1. Non-symmetric `Ghi != Glo` and `Ahi != Alo` fixture proves exact Type-4/16 wire-to-LE storage mapping.
2. Each PNG filter proves filtering precedes endian conversion; include values whose high bytes match but low bytes differ.
3. Adam7 Type-4/16 fixture proves all seven pass scatters and pass-local filter reset retain both bytes.
4. Eager and one-byte/ragged `PngChunkDecoder` schedules produce the same preserved components, diagnostics, budgets, and sticky errors.
5. Existing RGBA8 Type-4/16 high-byte vectors, Type-4/8 vectors, and legacy formats remain frozen.
6. Repeat the complete public and internal suites on `wasm`, `wasm-gc`, `js`, and `native`.

## Risks and Rejected Approaches

| Risk / approach | Why it fails | Required mitigation |
|---|---|---|
| Change the default decoder result to GrayAlpha16 | Breaks callers expecting the established RGBA8 image and changes public decode semantics. | Add an explicit preservation selector/result only. |
| Store PNG bytes directly as big-endian image storage | Violates the existing `graya16()` little-endian model and makes encoders/consumers inconsistent. | Swap only at the final storage boundary. |
| Convert to U16 before unfiltering | PNG predictors operate on encoded source bytes; U16-word arithmetic changes valid images. | Reconstruct four wire bytes first with `bpp=4`. |
| Widen all RGB/RGBA U16 decoder results now | Multiplies metadata, conversion, and API compatibility decisions beyond the narrow GrayAlpha contract. | Limit the profile to Type-4/16. |
| Reuse `get_byte` / `set_byte` for the U16 result | Those APIs intentionally require packed U8 and reject U16 views. | Use checked component-byte APIs. |
| Add a C codec or endian helper | Adds portability and ownership risk for a two-byte copy problem. | Use in-tree MoonBit byte reads/writes. |

## Phase Ordering Implication

1. **Contract and descriptor/profile phase:** specify the additive result type/selector, exact LE mapping, compatibility promise, and the profile-aware budget/descriptor seam.
2. **Raster preservation phase:** implement non-interlaced and Adam7 Type-4/16 row/scatter writers in the shared private state machine; retain legacy RGBA8 writer unchanged.
3. **Independent proof phase:** add literal wire/component fixtures, hostile chunk schedules, budget/error tests, frozen compatibility cases, and four-target evidence.

This ordering prevents a deceptively local row-writer edit from bypassing public result semantics or changing resource accounting.

## Sources and Evidence

- [W3C PNG Specification, Fourth Edition](https://w3c.github.io/png/) — colour/alpha/sample and interlace standard. **MEDIUM** confidence via verified official web source.
- [W3C PNG Specification](https://www.w3.org/TR/REC-png-961001) — MSB-first 16-bit sample representation and multi-sample layout. **MEDIUM** confidence via verified official web source.
- [MoonBit package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — supported target declaration and portable target set. **MEDIUM** confidence via verified official documentation search.
- Repository anchors cited throughout: `model/descriptor.mbt`, `storage/views.mbt`, `png/structural.mbt`, `png/raster_decode.mbt`, `png/stream_decode.mbt`, and `png/png.mbt`. **HIGH** confidence as local source inspection.

## Open Decisions for Phase Discussion

- The exact public naming and shape of the opt-in result selector is not derivable from the current code; choose an additive API that makes preservation visibly opt-in and preserves the `ImageDecoder` legacy contract.
- Confirm whether preservation accepts only sRGB-compatible Type-4/16 declarations (matching `graya16` descriptor identity) or needs a future broader metadata/storage contract. The current recommendation is to reject/retain existing declaration semantics rather than invent a non-sRGB GrayAlpha16 model in v0.20.
- Keep generic U16-to-RGBA conversion out of scope unless a concrete downstream workflow requires it; if approved later, specify its loss policy independently.
