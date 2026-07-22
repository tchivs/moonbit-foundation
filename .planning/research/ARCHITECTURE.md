# Architecture Research: v0.17 GrayAlpha16 PNG Interchange

**Project:** MoonBit Native Foundation
**Milestone:** v0.17 GrayAlpha16 PNG Interchange
**Researched:** 2026-07-23
**Confidence:** HIGH — based on the current implementation and completed v0.15/v0.16 artifacts.

## Recommendation

Implement GrayAlpha16 as one additive model identity and one private PNG encode
profile. It must pass through the existing profile-aware, bounded PNG machine;
do not introduce a GrayAlpha16-specific encoder, raster buffer, decoder, or
target path.

The correct delivery order is:

```text
model descriptor
  -> checked owned storage and component-byte views
  -> private GrayAlpha16 encode profile + explicit public factories
  -> type-4 / depth-16, big-endian scalar wire traversal
  -> existing public decoder canonicalization to straight RGBA8 high bytes
  -> hostile caller-capacity, frozen compatibility, and four-target evidence
```

This is the combined pattern established by v0.15 Gray16 (U16 byte ordering and
replay) and v0.16 GrayAlpha8 (two-component semantics and type-4 profile).

## Recommended Architecture

```text
ImageFormat::graya16() / ImageDescriptor
             |
             v
OwnedImage -> ImageView / MutImageView
(generic packed-U16 component-byte access)
             |
             v
PngEncoder::new_graya16*        PngChunkEncoder::new_graya16*
             |                         |
             +----------+--------------+
                        v
             PngEncodeMachine::new_with_profile
                        |
     _png_encode_source + atomic preflight + one budget charge
                        |
  _png_wire_byte -> filtered cursor -> Stored/Fixed/Dynamic replay -> PNG bytes
                        |
       IHDR: bit depth 16, colour type 4, method 0, non-interlaced
                        |
                        v
     existing PngDecoder / PngRasterSink -> straight RGBA8 high-byte canonical form
```

### Component Boundaries and Exact Seams

| Layer | Existing seam | v0.17 change | Contract to preserve |
|---|---|---|---|
| Model | `modules/mb-image/model/descriptor.mbt` | Add `ImageFormat::graya16()` and widen only the GrayAlpha identity validator to admit packed U16 straight-alpha descriptors. | `ChannelOrder::GrayAlpha` remains the sole two-component order; GrayAlpha8 stays valid exactly as before. |
| Descriptor geometry | `ImageFormat::channel_count`, `bytes_per_component`, `validate_plane_shape` | No new layout algorithm. A packed U16 GrayAlpha row naturally validates as `width * 2 channels * 2 bytes` = `width * 4`. | Checked arithmetic, single plane, tight/declared row facts, and immutable descriptor metadata. |
| Storage | `storage/views.mbt`, `storage/owned_image.mbt` | Reuse `get_component_byte` / `set_component_byte` and callback-scoped mutable views; add only model/storage regressions needed for two U16 components. | `get_byte` remains U8-only; component-byte access stays checked for x/y/channel/component-byte bounds. |
| Eager public API | `modules/mb-image/png/png.mbt` | Add `PngEncodeProfile::GrayAlpha16` privately and the four explicit `PngEncoder::new_graya16*` factory shapes. | `new()` and all legacy RGB/RGBA factory selection stay on `LegacyRgbOrRgba`; no implicit profile inference. |
| Caller-buffered API | `modules/mb-image/png/stream_encode.mbt` | Add matching `PngChunkEncoder::new_graya16*` factories, each calling `PngEncodeMachine::new_with_profile`. | One machine owns preflight, output state, acknowledgement, and terminal behavior for eager and chunk routes. |
| Admission/preflight | `_png_encode_source`, `_png_encode_preflight_with_interlace_profile` in `encode.mbt` | Add a fail-closed GrayAlpha16 arm: packed `GrayAlpha`, U16, `Some(Straight)`, inherited encoded builtin-sRGB/top-left/empty-opaque metadata predicates, and a tight `width * 4` row. Return 4 scalar wire bytes per pixel. Reject Adam7. | Failure occurs before source reads, writer output, caller lease mutation, or budget charge. |
| Scalar wire | `_png_wire_byte` in `encode.mbt` | Generalize the existing Gray16 byte-order branch to both U16 profiles. For position `p`: `x = p / wire_bytes_per_pixel`, `channel = (p % wire_bytes_per_pixel) / 2`, and select storage byte 0/1 from source endianness so each gray then alpha component is emitted high-byte then low-byte. | PNG filtering, planning, checksums, and replay operate on canonical big-endian bytes, never host/source byte order. |
| Replay construction | `PngEncodeMachine::new_with_profile` in `stream_encode.mbt` | Treat GrayAlpha16 as a U16 scalar profile in all three `stored_cursor` / `filtered_cursor` selections. Generalize `validate_gray16_replay_revision` to the two U16 profiles. | Fixed/Dynamic source drift fails before a new caller lease is changed; Stored behavior remains the established behavior. |
| PNG framing | `PngEncodeMachine::byte_at` | Map `GrayAlpha16` to IHDR colour type `4` and depth `16`; compression/filter methods and interlace byte remain zero. | Gray8/Gray16/GrayAlpha8 and legacy IHDR branches retain their frozen values. |
| Decode | `structural.mbt`, `stream_decode.mbt`, `raster_decode.mbt` | Production decoder change is not required: type 4/depth 16 is already accepted and routed to `_png_write_16bit_grayscale_alpha_row`. Add public evidence only. | Canonical output remains straight RGBA8: gray high byte replicated to R/G/B, alpha high byte copied to A; low bytes are intentionally not exposed by this decoder API. |

## Model and Storage Contract

`ChannelOrder::GrayAlpha` already provides exactly two channels, and the generic
packed component-byte views already accept U8 or U16. The missing model boundary
is intentional: `validate_gray_alpha_identity` currently admits only U8,
little-endian GrayAlpha. v0.17 should make that validator explicitly
version-aware instead of removing it:

- Retain the existing U8, packed, little-endian GrayAlpha8 identity unchanged.
- Add `ImageFormat::graya16()` as the obvious packed-U16 convenience factory
  (little-endian default, consistent with current U8 convenience factories).
- Admit U16 GrayAlpha only when it is packed, straight alpha, encoded sRGB,
  builtin sRGB, and top-left. Both declared U16 storage byte orders should be
  valid through `ImageFormat::new`; the wire encoder normalizes them to PNG
  big-endian form. This matches the v0.15 Gray16 evidence model.
- Keep planar, F32, premultiplied, non-sRGB, non-builtin-profile, rotated, and
  malformed-row forms rejected at descriptor construction.

Storage needs no alternate byte container or view API. `OwnedImage::with_mut_view`
already permits packed U16 and `ImageView::get_component_byte` addresses a packed
component as `channel * bytes_per_component + component_byte`. Tests must write
distinct gray and alpha high/low bytes, then prove that a third channel and a
third component byte are rejected.

Existing reference/copy/flip operations deliberately reject GrayAlpha. Preserve
that capability boundary for both U8 and U16 rather than accidentally extending
image-processing semantics as a side effect of descriptor admission.

## Encode Profile and Bounded Execution

Add only `GrayAlpha16` to the private `PngEncodeProfile` enum. Its public surface
mirrors the established Gray16 and GrayAlpha8 families:

```text
PngEncoder::new_graya16()
PngEncoder::new_graya16_with_compression_strategy(...)
PngEncoder::new_graya16_with_filter_strategy(...)
PngEncoder::new_graya16_with_strategies(...)

PngChunkEncoder::new_graya16(...)
PngChunkEncoder::new_graya16_with_compression_strategy(...)
PngChunkEncoder::new_graya16_with_filter_strategy(...)
PngChunkEncoder::new_graya16_with_strategies(...)
```

Every combined factory fixes `PngInterlaceStrategy::None` and delegates to
`PngEncodeMachine::new_with_profile`. The machine must continue to call the
shared `_png_encode_preflight_with_interlace_profile` path, which performs
descriptor admission, checked dimensions/row/scanline arithmetic, filter and
compression planning, output/work-limit checks, and one atomic budget charge
before output state is created.

Reuse these current shared mechanisms without exception:

- `PngFilteredMatchCursor` for filter-None/Adaptive traversal;
- `PngDeflatePlan::{Stored, Fixed, Dynamic}` for all three compression choices;
- one acknowledgement-safe `present` / `acknowledge` machine for eager writers
  and caller-owned chunk leases;
- the existing fixed/dynamic replay integrity and source-revision checks.

The Gray16-only cursor conditions at `stream_encode.mbt` construction currently
exist because a U16 raster cannot use the legacy direct-U8 scalar provider.
Extend all three conditions (Stored, Fixed, Dynamic), not just Stored. Likewise,
generalize the currently named Gray16 replay-revision guard so GrayAlpha16
Fixed/Dynamic output cannot expose a changed source byte before returning its
sticky error.

## Type-4 / 16-bit Wire Contract

The profile must report four scalar wire bytes per pixel, even though the image
has two semantic channels:

```text
source pixel (little endian):  gray-lo gray-hi alpha-lo alpha-hi
PNG scanline:                  filter gray-hi gray-lo alpha-hi alpha-lo

source pixel (big endian):     gray-hi gray-lo alpha-hi alpha-lo
PNG scanline:                  filter gray-hi gray-lo alpha-hi alpha-lo
```

The U16 branch in `_png_wire_byte` is therefore the critical integration seam.
It must map by component, not merely reverse adjacent bytes globally; otherwise
the alpha bytes of a two-component pixel can be swapped with gray bytes. Filters
must receive this canonical byte stream with `bpp = 4`, so Sub/Up/Average/Paeth,
Stored, Fixed, and Dynamic all compute over the same wire representation.

## Decoder Canonicalization

The decoder already implements the required compatibility behavior:

- `structural.mbt` accepts colour type 4 at bit depth 16 and accounts for two
  source channels/four source bytes per pixel.
- Both eager and resumable raster routes select
  `_png_write_16bit_grayscale_alpha_row`.
- That writer reads the big-endian gray high byte at offset 0 and alpha high byte
  at offset 2, repeats gray into R/G/B, and writes alpha unchanged.

v0.17 must document and test this as *canonicalization*, not U16 image-model
round-trip. Wire evidence proves all four source bytes; decode evidence proves
the existing public RGBA8 result `(gray_hi, gray_hi, gray_hi, alpha_hi)`.

## Delivery and Evidence Order

1. **GrayAlpha16 model and checked storage**
   - Change descriptor admission and add the convenience factory.
   - Prove 4-byte packed rows, separate U16 gray/alpha bytes, straight-alpha
     metadata, rejected unsupported variants, and no regression for Gray,
     GrayAlpha8, RGB, or RGBA.

2. **Bounded non-interlaced PNG encoding**
   - Add private profile and explicit eager/chunk factory families.
   - Wire the profile through closed admission, `width * 4` preflight, all U16
     filtered/replay cursors, per-component big-endian scalar emission, U16
     replay drift protection, and IHDR type 4/depth 16.
   - Test all `Stored`, `FixedOrStored`, and `DynamicOrFixedOrStored` crossed
     with `None` and `Adaptive`, plus atomic capability/geometry/output/work/
     budget/interlace rejection before writer output or lease mutation.

3. **Public interchange and portability evidence**
   - Use non-symmetric Gray/Alpha U16 values and both source storage byte orders.
     Inflate only the bounded, known Stored/None test payload and assert every
     `gray_hi gray_lo alpha_hi alpha_lo` byte in every scanline.
   - Decode through the public decoder and assert the documented RGBA8 high-byte
     canonicalization.
   - For all six strategy/filter pairs, use fresh public chunk encoders under
     zero-capacity, one-byte, and deterministic ragged leases. Assert accepted
     progress only, untouched lease tails, eager byte identity, completion, and
     sticky terminal behavior.
   - Run `moon -C modules/mb-image test png --target all --frozen`; the same
     MoonBit-only suite must pass on js, wasm, wasm-gc, and native.

## Legacy Compatibility Rules

This must be an additive profile/factory change. The following are explicit
non-negotiables:

- Do not alter `PngEncoder::new()`, `PngChunkEncoder::new()`, legacy profile
  selection, defaults, or pre-existing compression/filter defaults.
- Preserve byte-for-byte frozen vectors for Gray8, Gray16, GrayAlpha8, RGB8,
  and straight-RGBA8 in eager and caller-buffered suites.
- Do not infer GrayAlpha16 from a descriptor on legacy factories; callers opt in
  via `graya16` factories.
- Do not add Adam7 GrayAlpha16, palette/low-bit modes, conversion buffers, a
  second stream driver, native FFI, target branches, or release automation.

## Sources and Confidence

| Source | Finding | Confidence |
|---|---|---|
| `modules/mb-image/model/descriptor.mbt` and `storage/views.mbt` | Current GrayAlpha descriptor is U8-only; checked packed U16 component-byte storage is already generic. | HIGH |
| `modules/mb-image/png/encode.mbt`, `png.mbt`, `stream_encode.mbt` | Gray16 supplies the exact scalar big-endian/replay path; GrayAlpha8 supplies the exact type-4 factory/profile pattern. | HIGH |
| `modules/mb-image/png/structural.mbt`, `stream_decode.mbt`, `raster_decode.mbt` | Type-4/depth-16 decode validation and RGBA8 high-byte canonicalization already exist. | HIGH |
| `.planning/milestones/v0.15-phases/*` and `v0.16-phases/*` | Previous phases establish the three-step delivery, public-only evidence, hostile schedules, frozen vectors, and four-target protocol. | HIGH |

## Architecture Risks to Guard in Planning

1. **Byte reversal at the wrong granularity.** Reversing four-byte pixels rather
   than each two-byte component produces `alpha_hi alpha_lo gray_hi gray_lo`.
   Require non-symmetric gray and alpha U16 values in wire tests.
2. **Incomplete U16 replay integration.** Adding the profile to Stored but not
   Fixed/Dynamic cursors or revision protection violates strategy parity and can
   expose mutated data. Cover the full six-pair matrix.
3. **Accidental decoder contract inflation.** The current public decoder returns
   RGBA8 high bytes, not a U16 GrayAlpha image. Test and document that boundary;
   wire bytes are the full-fidelity assertion.
4. **Legacy drift from generalized defaults.** Keep the new factories explicit
   and retain literal legacy vectors; do not refactor old profiles into inferred
   behavior during this milestone.
