---
moonbit:
  import:
    - path: moonbit-foundation/mb-core/budget
      alias: budget
    - path: moonbit-foundation/mb-core/bytes
      alias: bytes
    - path: moonbit-foundation/mb-core/error
      alias: error
    - path: moonbit-foundation/mb-core/io
      alias: io
    - path: moonbit-foundation/mb-color/model
      alias: color
    - path: moonbit-foundation/mb-color/profile
      alias: profile
    - path: moonbit-foundation/mb-image/metadata
      alias: metadata
    - path: moonbit-foundation/mb-image/model
      alias: model
    - path: moonbit-foundation/mb-image/storage
      alias: storage
    - path: moonbit-foundation/mb-image/ops
      alias: ops
    - path: moonbit-foundation/mb-image/codec
      alias: codec
    - path: moonbit-foundation/mb-image/ppm
      alias: ppm
---

# mb-image

Portable, explicit image foundations for MoonBit Native Foundation.

`mb-image` is an independently versioned `0.1.0` candidate module. No API is
stable and no public release is claimed. Publication remains blocked until the
intended `moonbit-foundation` mooncakes.io namespace is verified.

The module has six independently consumable public packages, in exact
publication order: `metadata`, `model`, `storage`, `ops`, `codec`, and `ppm`.
There is no root facade or prelude.

## 0.1.0 candidate contract

| Field | Exact value |
| --- | --- |
| Module | `moonbit-foundation/mb-image` |
| Version/status | `0.1.0` candidate; no stable API or public release is claimed |
| License | Apache-2.0 ([repository license](../../LICENSE)) |
| Repository metadata | `https://github.com/moonbit-foundation/moonbit-foundation` |
| Direct module dependencies | `moonbit-foundation/mb-core = 0.1.0`; `moonbit-foundation/mb-color = 0.1.0` |
| Required targets | `+js+wasm+wasm-gc+native` |

The literate examples in this document are checked on every required target.
Candidate compatibility requires migration notes for public changes; it is not
a stable Semantic Versioning promise.

## Explicit descriptor and storage

Descriptors name positive dimensions, component type, channel order, packed or
planar layout, plane range, row stride, logical row bytes, subsampling,
endianness, color and transfer identity, alpha mode, profile, Exif orientation,
and bounded opaque metadata. Construction rejects overflow, short rows,
out-of-storage ranges, and overlapping planes before allocation or access.
Padding is allowed; negative strides and bottom-up addressing are not.

The model can describe packed or planar `U8`, `U16`, and `F32` storage. Phase 4
reference operations deliberately accept only packed encoded-sRGB `Rgb8`,
straight `Rgba8`, and premultiplied `Rgba8`.

```mbt check
///|
fn readme_budget(bytes : UInt64, work : UInt64) -> @budget.Budget {
  @budget.Budget::new(
    @budget.ResourceLimits::new(
      bytes~,
      allocations=1UL,
      allocation_size=bytes,
      width=16UL,
      height=16UL,
      pixels=256UL,
      depth=0UL,
      work~,
    ),
  )
}

///|
fn readme_metadata() -> @model.ImageMetadata {
  let opaque = @metadata.OpaqueMetadata::from_entries(
    [("example", "id", "raw", b"mnf")],
    @metadata.MetadataLimits::new(
      max_entries=1UL,
      max_token_bytes=16UL,
      max_value_bytes=3UL,
      max_total_bytes=32UL,
      max_disposition_fields=8UL,
    ),
    readme_budget(3UL, 0UL),
  ).unwrap()
  @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb,
    @color.TransferIdentity::EncodedSrgb,
    None,
    @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopRight,
    opaque,
  )
}

///|
fn readme_image() -> @storage.OwnedImage {
  let plane = @model.PlaneDescriptor::new(
    1UL, 14UL, 8UL, 6UL, 1UL, 1UL, 2UL, 2UL,
  ).unwrap()
  let descriptor = @model.ImageDescriptor::new(
    2UL,
    2UL,
    @model.ImageFormat::rgb8(),
    [plane],
    16UL,
    readme_metadata(),
  ).unwrap()
  @storage.OwnedImage::new(descriptor, readme_budget(16UL, 0UL)).unwrap()
}

///|
test "descriptor validation is explicit and allocation is caller-bounded" {
  let image = readme_image()
  inspect(image.descriptor().width(), content="2")
  inspect(image.view().row_stride(), content="8")
  inspect(image.metadata().orientation().code(), content="2")
  inspect(image.metadata().opaque_metadata().entry(0).unwrap().canonical_key(), content="example:id:raw")
  inspect(
    @model.PlaneDescriptor::new(
      0UL, 5UL, 5UL, 6UL, 1UL, 1UL, 2UL, 1UL,
    ) is Err(_),
    content="true",
  )
}
```

Budget ordering is fail-closed: pure descriptor and capability validation,
checked row/range arithmetic, containment and overlap checks, allocator
approval, then one atomic charge for bytes, allocation count, maximum
allocation, dimensions, pixels, and work. Invalid or unsupported input consumes
no budget.

## Retained views, crops, and deterministic operations

Immutable views retain backing storage. A representable half-open crop is
zero-copy and preserves its parent stride; a zero-area immutable crop is the
canonical backing-free empty view. Mutable views exist only inside
`with_mut_view`; descendants share one lease, become stale when the callback
ends, and split only across proven byte-disjoint regions. Raw mutable backing is
never exposed.

Copy, horizontal and vertical flips, Exif-orientation application, integer-floor
nearest resize, and named pixel conversions always produce fresh storage.
Ordinary copy, crop, flips, and resize use stored coordinates and preserve the
orientation field. `apply_orientation` performs the selected one of all eight
Exif mappings and normalizes it to `TopLeft`. Nearest resize maps
`min(source_extent - 1, floor(destination * source_extent / destination_extent))`
with checked integers and performs no filtering or hidden color conversion.

```mbt check
///|
test "views and operations expose lifetime and metadata disposition" {
  let image = readme_image()
  image.with_mut_view(fn(view) {
    view.set_byte(0UL, 0UL, 0UL, b'R')
  }).unwrap()
  let crop = image.view().crop(
    @model.Rect::new(0UL, 0UL, 1UL, 2UL).unwrap(),
  ).unwrap()
  inspect(crop.row_stride(), content="8")
  inspect(crop.get_byte(0UL, 0UL, 0UL).unwrap() == b'R', content="true")

  let copied = @ops.copy_image(image.view(), readme_budget(12UL, 12UL)).unwrap()
  inspect(copied.image().view().row_stride(), content="6")
  inspect(copied.disposition().preserved_length(), content="5")
  let horizontal = @ops.flip_horizontal(
    image.view(),
    readme_budget(12UL, 12UL),
  ).unwrap()
  inspect(horizontal.image().metadata().orientation().code(), content="2")
  let oriented = @ops.apply_orientation(
    image.view(),
    readme_budget(12UL, 12UL),
  ).unwrap()
  inspect(oriented.image().metadata().orientation().code(), content="1")
  inspect(oriented.disposition().transformed(0).unwrap().value(), content="orientation")
  let resized = @ops.resize_nearest(
    image.view(),
    1UL,
    1UL,
    readme_budget(3UL, 3UL),
  ).unwrap()
  inspect(resized.image().descriptor().pixel_count(), content="1")
  let rgba = @ops.rgb8_to_straight_rgba8(
    image.view(),
    readme_budget(16UL, 16UL),
  ).unwrap()
  inspect(rgba.image().descriptor().format().channel_count(), content="4")
  inspect(rgba.disposition().transformed(0).unwrap().value(), content="alpha")
}
```

Each operation returns a machine-readable metadata disposition. Copy and crop
preserve all fields; flips and resize preserve metadata and stored orientation;
orientation application transforms only orientation; format and alpha
conversions update those fields, preserving color/profile identity, and the
explicit lossy alpha-drop operation reports the discarded field.

## Prefix, Reader, and Writer codec contracts

Probe input is a caller-owned immutable prefix and yields `Match`, `NoMatch`, or
the minimum total `NeedMore` length. Decode consumes only an `mb-core/io.Reader`;
encode consumes only an `mb-core/io.Writer`. Options, limits, budgets,
diagnostics, byte progress, and metadata disposition are explicit. Neither
contract requires seeking, paths, URLs, filesystem access, a registry, ambient
selection, or a concrete codec.

```mbt check
///|
fn readme_codec_edges(
  _prefix : @bytes.ByteView,
  _reader : &@io.Reader,
  _writer : &@io.Writer,
) -> Unit {
  ()
}

///|
test "codec policy is explicit without selecting a backend" {
  let limits = @codec.CodecLimits::new(
    max_probe_bytes=16UL,
    max_input_bytes=1024UL,
    max_output_bytes=1024UL,
    max_width=16UL,
    max_height=16UL,
    max_pixels=256UL,
    max_work=4096UL,
  )
  let decode = @codec.DecodeOptions::new(
    require_complete_input=true,
    preserve_opaque_metadata=true,
  )
  let encode = @codec.EncodeOptions::new(
    lossless_required=true,
    preserve_opaque_metadata=true,
  )
  inspect(limits.max_probe_bytes(), content="16")
  inspect(decode.require_complete_input(), content="true")
  inspect(encode.lossless_required(), content="true")
  inspect(@codec.ProbeOutcome::NeedMore(2UL) == @codec.ProbeOutcome::NeedMore(2UL), content="true")
}
```

## MNF strict PPM P6/sRGB subset

The concrete `ppm` package implements the **MNF strict PPM P6/sRGB subset** over
the public codec contracts. It accepts one binary P6 image with positive decimal
dimensions, `maxval` exactly `255`, and exactly `width * height * 3` encoded-sRGB
RGB bytes. Decode requires EOF after that raster. Encode emits only
`P6\n<width> <height>\n255\n` plus tight logical RGB rows. This intentionally does
not claim full Netpbm colorimetry, arbitrary maxval scaling, multi-image PPM, P3,
or 16-bit PPM conformance.

```mbt check
///|
test "strict P6 construction keeps parser ceilings explicit" {
  let parser_limits = @ppm.PpmParserLimits::new(
    max_header_bytes=128UL,
    max_token_bytes=20UL,
    max_comment_bytes=64UL,
    max_comments=4UL,
  ).unwrap()
  let decoder = @ppm.PpmDecoder::new(parser_limits)
  let encoder = @ppm.PpmEncoder::new()
  inspect(parser_limits.max_header_bytes(), content="128")
  ignore(decoder)
  ignore(encoder)
}
```

Two standalone consumers use only public APIs:

- [portable in-memory decode-transform-encode example](../../examples/ppm-portable/main/main.mbt), executed on `js`, `wasm`, `wasm-gc`, and `native`;
- [Native CLI-shaped injected adapter](../../examples/ppm-native-cli/main/adapter.mbt), whose Reader, Writer, limits, budget, diagnostics, options, and transform are supplied explicitly.

Their copied-source qualification records `source_isolation: pass`. The
unchanged named-dependency no-workspace probe records
`registry_resolution: blocked_unpublished_namespace`; it is not reported as an
artifact-consumer or publication pass.

## Exact dependency DAG and targets

- `metadata -> mb-core/error + budget + bytes`
- `model -> metadata + mb-core/error + checked + budget + mb-color/model + profile`
- `storage -> model + metadata + mb-core/error + checked + budget + bytes + mb-color/model + profile`
- `ops -> storage + model + metadata + mb-core/error + checked + budget + bytes + mb-color/model + alpha + profile`
- `codec -> storage + model + metadata + mb-core/error + budget + bytes + io`
- `ppm -> codec + storage + model + metadata + mb-core/error + checked + budget + bytes + io + mb-color/model + profile`

Every package and example is checked independently on `js`, `wasm`, `wasm-gc`,
and `native`; native is preferred but has no wider portable contract.

Phase 5 owns the first bounded PPM P6 implementation: the MNF strict PPM
P6/sRGB subset documented above. The candidate intentionally defers YUV and arbitrary format conversions,
advanced resampling, animation, tiled/GPU storage, PNG/JPEG/WebP, wider PPM
variants, native/system codecs, registries, filesystem/URL policy, rendering,
publication, signed releases, and performance claims. LLVM is experimental and
is not part of the support matrix. No behavior for those features is fabricated
here.

Generated adversarial evidence is reproduced by
`scripts/fixtures/Generate-ImageVectors.ps1`, registered with source, license,
digest, and use in `fixtures/manifest.json`, and embedded as exactly five
package-local tables. The eight orientation equations are standards-literal
generator data independent of production mapping code.

The strict P6 corpus is fixture `ppm-p6-conformance-vectors`, SHA-256
`6e1f367c78839e8e06237a784ebe75732ee3fd2a27d3dc56434c7e6e12676967`,
generated from the cited Netpbm PPM specification plus repository-derived
adversarial schedules. The image corpus is `image-operation-vectors`, SHA-256
`c3ee7dc53faf0c06cce457857d5c23a381002208cf9e10569f2dad758f85c52b`.
Exact provenance, license, redistribution status, and expected use are in
[`fixtures/manifest.json`](../../fixtures/manifest.json); the unpublished
[0.1.0 candidate changelog](CHANGELOG.md) records the release boundary.

## Publication source contract

The records below are the exact pre-publication source intent for the `0.1.0`
candidate. The install command becomes usable only after registry publication;
it is not evidence that Mooncakes currently renders or resolves this module.
Package imports are listed in policy order, and the shared support, security,
changelog, compatibility, migration, and RFC routes remain explicit.

<!-- mnf-publication-source:v1 -->
01|install|moon add moonbit-foundation/mb-image@0.1.0
02|imports|moonbit-foundation/mb-image/metadata,moonbit-foundation/mb-image/model,moonbit-foundation/mb-image/storage,moonbit-foundation/mb-image/ops,moonbit-foundation/mb-image/codec,moonbit-foundation/mb-image/ppm
03|status|candidate
04|targets|js,wasm,wasm-gc,native
05|toolchain|moon=0.1.20260713;moonc=0.10.4;moonrun=0.1.20260713
06|class|exact
07|support|docs/support.md
08|security|SECURITY.md
09|changelog|CHANGELOG.md
10|migration|not-required
11|rfc|not-required
12|impacts|none
13|registry-source|moon.mod.json
14|registry-render|unknown;proof=PROV-05;phase=8
15|ambiguity|none
<!-- /mnf-publication-source -->
