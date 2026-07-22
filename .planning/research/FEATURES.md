# Feature Landscape

**Domain:** v0.17 GrayAlpha16 PNG Interchange for `mb-image`
**Researched:** 2026-07-23
**Confidence:** HIGH for the feature boundary, based on the live model/PNG code and shipped v0.15/v0.16 evidence.

## Product Boundary

The milestone adds one deliberately narrow interchange profile: a first-class packed U16 greyscale-plus-straight-alpha source that encodes through explicit eager and caller-buffered PNG factories as non-interlaced type 4, bit depth 16 output. It extends the existing model and bounded encoder instead of broadening generic PNG constructors or claiming a new lossless U16 decoder result.

PNG requires type-4 pixels to contain grey then alpha samples, and 16-bit samples use MSB-first wire order. The public decoder already turns a type-4/16 input into straight RGBA8 using the high byte of each component. That asymmetric contract is important: source-to-PNG preserves every U16 byte; PNG-to-public-image canonicalizes to U8.

## Table Stakes

| Feature | Why expected | Complexity | Required behavior |
|---|---|---:|---|
| Packed U16 GrayAlpha model | A U16 PNG encoder needs an unambiguous in-memory source contract | Medium | `ImageFormat::graya16()` represents two packed U16 components in grey, alpha order; only straight alpha and current canonical metadata are admitted. |
| Checked U16 construction/access | Callers must populate both U16 components without unsafe offsets | Low | Reuse packed component-byte APIs and generic owned image/views; channel 0 is grey and channel 1 alpha. |
| Explicit eager PNG factory | Users need an intentional way to select a 16-bit type-4 PNG | Medium | `PngEncoder::new_graya16*` emits IHDR depth 16, type 4, no interlace; generic legacy constructors never infer this profile. |
| Explicit caller-buffered factory | Streaming consumers require the same profile under caller-owned output leases | Medium | `PngChunkEncoder::new_graya16*` shares eager preflight, planning, replay, byte output, and terminal behavior. |
| Exact U16 wire serialization | Interoperability fails if host byte order or components are swapped | High | Every scanline serializes each pixel as `Ghi,Glo,Ahi,Alo` before filters, compression, checksums, and replay. |
| Existing bounded strategy surface | A new profile must not silently weaken output guarantees | High | Support Stored, FixedOrStored, DynamicOrFixedOrStored × None, Adaptive through the current single machine and its existing limit/budget admission. |
| Explicit decode canonicalization | Callers need truthful expectations when inspecting a decoded 16-bit PNG | Low | Public decode returns straight RGBA8 with `R=G=B=gray-high` and `A=alpha-high`; low bytes are not represented in the current output model. |
| Literal compatibility regressions | Additive encoding must leave shipped profiles stable | Medium | Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 literal eager/chunk vectors remain byte-identical. |
| Portable public evidence | A public contract is only useful when the same test path exercises the declared package targets | Medium | A single all-target PNG suite uses only public model, encoder, chunk encoder, and decoder seams. |

## Differentiators

| Feature | Value proposition | Complexity | Notes |
|---|---|---:|---|
| One profile-aware bounded pipeline | U16 GrayAlpha gains all established output semantics without a codec fork | High | The scalar wire-byte seam lets filtering and compression stay byte-accurate without materializing converted rows. |
| Endianness-independent public evidence | Non-symmetric samples catch both per-component byte order and grey/alpha order defects | Medium | Build equivalent little- and big-endian source storage and require identical PNG bytes. |
| Hostile lease ownership evidence | Caller-buffered correctness includes more than byte equality | Medium | Verify zero-capacity, one-byte, and ragged leases, accepted-prefix accounting, untouched tails, and sticky terminals. |
| Honest U16-to-U8 decode contract | Consumers know exactly where fidelity is preserved and where canonicalization occurs | Low | Wire checks preserve four bytes per pixel; decode checks only documented high-byte expansion. |

## Future Requirement Candidates

| ID | Requirement | Acceptance evidence |
|---|---|---|
| **GRAYA16-01** | A library user can create and inspect a packed U16 GrayAlpha image with exactly grey and alpha components, straight-alpha metadata, and no change to existing format behavior. | Public model/storage tests construct non-symmetric U16 pairs, inspect both channels, and reject non-packed, non-U16, missing/premultiplied-alpha, noncanonical-metadata, and invalid-orientation variants. |
| **GRAYA16-02** | A library user can select explicit eager and caller-buffered GrayAlpha16 PNG factories that accept only compatible packed inputs and emit non-interlaced PNG type 4/depth 16. | Public IHDR and construction tests demonstrate factory selection and reject incompatible input before observable output state. |
| **GRAYA16-03** | GrayAlpha16 output preserves `Ghi,Glo,Ahi,Alo` wire samples across the shared bounded filter/compression/replay path. | A generated asymmetric corpus proves both source storage orders produce identical Stored/None scanlines and all six compression/filter pairs decode successfully. |
| **GRAYA16-04** | GrayAlpha16 callers receive eager/chunk byte identity, accepted-only progress, terminal stickiness, documented RGBA8 canonicalization, frozen legacy bytes, and all-target public evidence. | Public encoder/decoder and chunk tests cover zero/one/ragged capacities, untouched lease tails, literal legacy vectors, and the single package suite on every declared target. |

## Recommended Delivery Order

1. **GrayAlpha16 model contract** — deliver `GRAYA16-01` first. The encoder cannot safely infer two U16 components until descriptor validation and generic storage access agree on their identity.
2. **Bounded profile and explicit factories** — deliver `GRAYA16-02` and the implementation half of `GRAYA16-03`. Reuse the existing shared machine; retain atomic admission as a non-negotiable behavior.
3. **Public interchange evidence** — complete `GRAYA16-03` and `GRAYA16-04` with literal wire/decode, hostile lease, compatibility, and portable public tests.

```text
GRAYA16-01 model
  → GRAYA16-02 explicit PNG profile/factories
    → GRAYA16-03 wire mapping + bounded strategies
      → GRAYA16-04 public decode/chunk/compatibility evidence
```

## Explicit Exclusions

| Excluded feature | Why exclude it | Do instead |
|---|---|---|
| Implicit GrayAlpha16 selection by generic PNG constructors | It would change established legacy admission behavior and obscure the new data contract. | Require `new_graya16*` factories. |
| GrayAlpha16 Adam7 encoding | Interlacing is a separate traversal contract. | Keep every new factory non-interlaced. |
| RGB16/RGBA16 output | They add distinct model/profile/wire matrices with no dependency on this two-component slice. | Scope them as separate profiles later. |
| Palette/indexed, low-bit, `tRNS`, or automatic transparency conversion | Those PNG profiles have different packing and color semantics. | Preserve current explicit capability boundaries. |
| New GrayAlpha processing, resize, composite, or copy semantics | Valid storage is not permission to reuse RGB/RGBA operation algorithms. | Retain existing capability gates until operations have their own requirements. |
| A new U16 public decoder result | The current public decoder returns canonical RGBA8. | State and test high-byte canonicalization; preserve low-byte fidelity at the PNG wire seam. |
| New dependency, FFI, release automation, target branch, or source copy | None is needed to extend the project-owned portable implementation; each would expand scope without adding feature value. | Keep changes in the existing MoonBit model, storage, PNG, and test packages. |

## Feature Dependencies

```text
ImageFormat::graya16 + descriptor admission
  → generic U16 storage/view access
    → GrayAlpha16 encoder profile
      → endian-correct wire-byte mapping
        → existing filter/compression/replay strategies
          → eager and chunk public factories
            → literal wire/decode and hostile-lease evidence
```

## Sources

- Live local model/PNG implementation and tests under `modules/mb-image/` — HIGH local evidence.
- v0.15 Gray16 and v0.16 GrayAlpha milestone requirements, plans, summaries, and verification reports under `.planning/milestones/` — HIGH local evidence.
- [W3C PNG Specification, Third Edition](https://www.w3.org/TR/png-3/) — type-4/16 legal profile, grey-then-alpha sample ordering, and MSB-first 16-bit samples. Source-provider confidence was classified LOW, so this is normative corroboration rather than the basis for local feature assertions.
