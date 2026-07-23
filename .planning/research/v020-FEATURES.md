# Feature Landscape: v0.20 High-Precision GrayAlpha Decode

**Domain:** Portable, bounded PNG Type-4/16 decoding in `mb-image`
**Researched:** 2026-07-23
**Confidence:** HIGH for repository behaviour; MEDIUM for the external PNG and MoonBit target corroboration retrieved through the verified web seam.

## Product Boundary

v0.20 adds one deliberately narrow capability: a caller who explicitly asks to
preserve a PNG Type-4/16 image receives the already-supported packed,
little-endian `graya16` image rather than the generic decoder's RGB8/RGBA8
canonical image. It is a preservation profile, not a general 16-bit decoder
initiative.

The minimal user-facing surface is:

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

The chunk constructor deliberately retains the existing `push` and `finish`
methods; `finish()` remains the only result-transfer boundary and returns the
existing `DecodeResult`. A new wrapper, trait method, options field, or generic
decoder-result variant would add surface without adding capability. The explicit
method/constructor makes the profile selection visible at the call site.

The preservation profile accepts only Type-4/16 input that the existing
`graya16` identity can represent: encoded sRGB grey data, straight alpha, and
top-left orientation. Its successful image is `ImageFormat::graya16()` with two
U16 components in `Glo,Ghi,Alo,Ahi` storage order. It preserves every
reconstructed PNG wire byte (`Ghi,Glo,Ahi,Alo`) after that one endian change;
callers observe them through `ImageView::get_component_byte`.

## Table Stakes

| Feature | Why expected | Complexity | Testable required behaviour |
|---|---|---:|---|
| Explicit eager preservation | A caller must be able to request fidelity without changing every generic PNG consumer. | Low | `PngDecoder::decode_graya16` accepts valid Type-4/16 and returns the ordinary `DecodeResult` with packed LE `graya16`, straight alpha, exact dimensions, and exact `bytes_read`. |
| Explicit caller-chunk preservation | Resumable users need the same result contract, not a weaker eager-only path. | Low | `PngChunkDecoder::new_graya16` uses the established `push`/`finish` lifecycle; empty, one-byte, and ragged input schedules yield the same component bytes and result count as a fresh eager decode. |
| Exact four-byte component fidelity | The feature is not credible if it retains only `Ghi`/`Ahi`. | Medium | The asymmetric existing wire fixture `1234/a7c5`, `be0f/5a76` produces storage components `(34,12,c5,a7)` and `(0f,be,76,5a)` by coordinate/channel/component-byte. |
| Type-4/16-only capability gate | A preservation selector must never silently return an unrelated RGBA8 profile. | Medium | Type-4/8, Type-0/16, Type-6/16, malformed Type-4/16, and incompatible colour declarations fail with a typed profile/encoding error before output allocation and expose no result. |
| Explicit colour/alpha identity | Exact sample bytes are insufficient if metadata promises a different colour or alpha model. | Medium | No-declaration and sRGB Type-4/16 succeed as builtin encoded sRGB with `AlphaMode::Straight`; gAMA/cHRM and iCCP Type-4/16 fail the preservation route rather than being mislabeled. `tRNS` remains rejected for Type 4. |
| Existing conversion boundary is frozen | Current callers rely on the generic RGB8/RGBA8 facade and cannot receive a U16 image unexpectedly. | Low | Generic `ImageDecoder::decode(PngDecoder::new(), ...)` and `PngChunkDecoder::new()` retain `RGBA8(Ghi,Ghi,Ghi,Ahi)` for the same Type-4/16 fixture, including old metadata, byte-count, error, and terminal semantics. |
| Filter and Adam7 correctness | Fidelity must survive the byte-domain mechanisms where most lane/endian bugs hide. | High | All five filter tags and an all-seven-pass Adam7 fixture preserve both bytes of grey and alpha at their output coordinates; predictors run over four PNG wire bytes before the final endian swap. |
| Bounded, portable terminal semantics | Precision must not cost an unbounded buffer, partial image, or native-only result. | High | One 4-bytes/pixel output representation plus existing reconstructed rows passes exact/one-less budgets; eager/chunk errors are sticky and equivalent; focused and package tests pass on wasm, wasm-gc, js, and native. |

## Conversion Boundary

There is exactly one intentional lossy conversion in v0.20, and it already
belongs to the generic compatibility profile:

```text
PNG Type-4/16 reconstructed wire  Ghi,Glo,Ahi,Alo
                         ├─ explicit preservation → GrayAlpha16 LE(Glo,Ghi,Alo,Ahi)
                         └─ generic compatibility → RGBA8(Ghi,Ghi,Ghi,Ahi)
```

`decode_graya16` / `new_graya16` select the left branch before output allocation.
The ordinary `PngDecoder` trait implementation and `PngChunkDecoder::new`
retain the right branch exactly. v0.20 adds no general `GrayAlpha16 → RGBA8`
operation: a caller that wants the legacy conversion continues to use the
generic decoder deliberately. This prevents an apparently lossless preserved
result from being narrowed later by a hidden convenience conversion.

## Differentiators

| Feature | Value proposition | Complexity | Notes |
|---|---|---:|---|
| Same `DecodeResult`, narrower selector | High precision is additive without duplicating image ownership, disposition, or progress types. | Low | The existing result already transfers an owned image only at terminal success. |
| One shared decode machine | The feature inherits strict framing, CRC, IDAT, DEFLATE, filtering, EOF, and chunk safety instead of reimplementing them. | High | Use one private profile to choose descriptor, budget, and final row/scatter write only. |
| Byte-level fidelity oracle | Non-symmetric lanes expose loss, channel swap, and endianness defects that U16-value or RGBA-only checks conceal. | Medium | Assert `get_component_byte`, not `get_byte`, which is deliberately U8-only. |
| Legacy proof next to preservation proof | It makes the compatibility conversion an executable contract rather than an undocumented side effect. | Low | Run the same Type-4/16 source through both routes and compare each to its own expected representation. |

## Requirement Candidates

| ID | Requirement | Acceptance evidence |
|---|---|---|
| **GRAYA16D-01** | A library user can explicitly decode a valid encoded-sRGB Type-4/16 PNG eagerly into a packed little-endian, straight-alpha `graya16` `DecodeResult`, preserving both bytes of each grey and alpha component. | Public direct decode uses the independent asymmetric 2×1 wire fixture and asserts descriptor/metadata, `Glo,Ghi,Alo,Ahi` bytes per pixel, and `bytes_read`; standard Type-4 `tRNS` rejection remains covered. |
| **GRAYA16D-02** | A library user can select the same Type-4/16 preservation contract with caller-owned input chunks while retaining exact consumption, explicit finish, no caller-view retention, no partial result, and sticky errors. | Empty, one-byte, and ragged schedules through `new_graya16` equal fresh eager results byte-for-byte; incomplete, malformed, limit, and terminal calls preserve the established error/progress rules. |
| **GRAYA16D-03** | The preservation profile accepts no unrepresentable PNG profile and changes no generic decode behaviour. | Type/depth/legacy-colour/ICC rejection happens before output allocation and leaves no result visible. Existing generic eager/chunk Type-4/16 tests still assert `RGBA8(Ghi,Ghi,Ghi,Ahi)` and frozen diagnostics/budgets. |
| **GRAYA16D-04** | High-precision Type-4/16 decode retains exact bytes after all supported filter and interlace paths under declared resource limits on every portable target. | Five-filter and all-seven-pass Adam7 component-byte fixtures, exact/one-less resource matrix, eager/chunk equivalence, then `moon -C modules/mb-image test png --target all --frozen` with independent wasm, wasm-gc, js, and native passes. |

## Explicit Exclusions

| Excluded feature | Why exclude it | Do instead |
|---|---|---|
| Changing `PngDecoder` trait decode or `PngChunkDecoder::new` | It breaks the established generic RGBA8 interoperability contract. | Keep them on `RGBA8(Ghi,Ghi,Ghi,Ahi)`; add only the explicit eager method and chunk constructor. |
| A `DecodeOptions` flag, result wrapper, or broad decoder result union | These widen every decoder consumer for one PNG source profile. | Reuse `DecodeResult` and make the type-4/16 request visible by method/constructor name. |
| A general U16 colour/alpha conversion API | It introduces separate rounding, colour-management, alpha, and budget contracts. | Treat the generic decoder as the only deliberate high-byte conversion boundary in this milestone. |
| RGB16/RGBA16, Gray16, Type-4/8 preservation, palette, `tRNS`, or APNG expansion | Each has a distinct source model or metadata/canonicalization decision. | Limit acceptance to Type-4/16; retain current generic paths for all other PNG forms. |
| Non-sRGB/ICC preservation, colour transformation, or premultiplied alpha | Existing `graya16` identity cannot represent these truthfully. | Reject them before allocation; leave generic decoder metadata behaviour unchanged and consider a future model milestone if required. |
| New module, FFI, target split, copied parser/inflater, raw-raster staging, or release work | None is needed to preserve four reconstructed bytes in the current portable machine. | Parameterize the existing private decode profile and use in-tree MoonBit storage. |

## Feature Dependencies

```text
existing graya16 descriptor + component-byte views
  → explicit eager method / chunk constructor
    → private Type-4/16 preservation profile selected at first IDAT
      → profile-aware descriptor, identity gate, and 4-bytes/pixel preflight
        → existing bytewise filters + shared non-interlaced/Adam7 sink
          → final Ghi,Glo,Ahi,Alo → Glo,Ghi,Alo,Ahi storage write
            → DecodeResult only after EOF / chunk finish
              → generic-regression and four-target qualification
```

## Recommended Delivery Order

1. **Public contract and admission** — deliver `GRAYA16D-01`'s selectors,
   Type-4/16+sRGB identity gate, descriptor, and exact non-interlaced fixture.
   The generic conversion regression belongs in this phase, making the two
   observable result contracts explicit before raster work grows.
2. **Shared raster and resumable proof** — deliver `GRAYA16D-02`: route the
   selected profile through the one machine, add component-byte row writing,
   and prove empty/one-byte/ragged schedules, EOF authority, non-retention, and
   sticky terminals.
3. **Interlace, resource, and portability qualification** — deliver
   `GRAYA16D-03` and `GRAYA16D-04`: Adam7/filter vectors, pre-allocation
   rejection, exact budget boundaries, legacy-vector freeze, and four-target
   evidence.

## Sources

- Local public seams: `modules/mb-image/png/png.mbt` and
  `modules/mb-image/png/stream_decode.mbt` — HIGH local evidence for the
  established generic decoder, chunk lifecycle, exact progress, EOF transfer,
  and sticky terminal rules.
- Local representation seams: `modules/mb-image/model/descriptor.mbt` and
  `modules/mb-image/storage/views.mbt` — HIGH local evidence for `graya16`
  identity and checked storage-order component access.
- Local format and test seams: `modules/mb-image/png/raster_decode.mbt`,
  `structural.mbt`, `encode_test.mbt`, `raster_decode_wbtest.mbt`, and
  `stream_decode_test.mbt` — HIGH local evidence for the current high-byte
  mapping, Type-4/16 wire fixture, filter/Adam7 mechanism, and hostile chunk
  conventions.
- [W3C PNG Specification](https://www.w3.org/TR/png-3/) — MEDIUM confidence
  through verified official web retrieval; corroborates Type-4 grey-plus-alpha,
  16-bit sample representation, and the `tRNS` prohibition when alpha is present.
- [MoonBit package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — MEDIUM confidence through verified official web retrieval; documents the four `--target all` backends.

## Open Question

The public names above are the recommended minimal contract. Phase discussion
should only revisit their spelling if it improves MoonBit API consistency; it
should not broaden them into a generic precision option or a new result type.
