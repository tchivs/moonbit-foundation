# Feature Landscape: v0.19 GrayAlpha8 Adam7 PNG

**Domain:** Portable, bounded PNG Type-4/8 interlaced encoding in `mb-image`
**Researched:** 2026-07-23
**Confidence:** HIGH — live source and shipped v0.16/v0.18 evidence establish both the existing GrayAlpha8 boundary and the intended Adam7 extension pattern.

## Product Boundary

v0.19 adds one additive capability: an explicitly selected Adam7 route for the existing legal packed U8 `GrayAlpha` source contract. It must emit PNG colour type 4 at bit depth 8, with each pixel serialized as `G,A`, while retaining the project's established bounded preflight, filter, DEFLATE, acknowledgement-safe replay, and portable test contract.

This is not a new image model, a decoder-model expansion, or a second encoder. The live profile admission currently rejects `PngEncodeProfile::GrayAlpha8` whenever interlace is not `None`; in contrast, GrayAlpha16 already exposes narrow `*_with_interlace_strategy` and full `*_with_all_strategies` eager and caller-buffered constructors through the shared profile-aware machine. v0.19 should make the U8 profile use those same two additive public selection shapes.

PNG permits greyscale-with-alpha as colour type 4 at depths 8 and 16; an 8-bit type-4 pixel is a grey sample immediately followed by alpha. Adam7 is interlace method 1 with seven pass images, and only non-empty pass scanlines have filter bytes. [PNG Specification](https://www.libpng.org/pub/png/spec/iso/index-object.html)

## Table Stakes

| Feature | Why expected | Complexity | Testable required behavior |
|---|---|---:|---|
| Explicit eager Adam7 selection | Users must opt in without changing legacy factory behavior. | Low | `PngEncoder::new_graya8_with_interlace_strategy(Adam7)` and `PngEncoder::new_graya8_with_all_strategies(..., Adam7)` construct legal encoders; existing `new_graya8*` constructors still produce IHDR `08 04 00`. |
| Explicit caller-buffered Adam7 selection | Streaming users need the same public capability, not an eager-only feature. | Low | Matching `PngChunkEncoder` constructors reach the same profile/machine and can drain an Adam7 output under caller-owned leases. |
| Legal Type-4/8 Adam7 framing | A route that writes RGB/RGBA or silently remains non-interlaced is not the requested feature. | Medium | Public bytes have IHDR depth `08`, colour type `04`, interlace `01`; a 5×5 non-symmetric source yields all seven non-empty Adam7 pass payloads in literal `G,A` order. |
| Shared all-strategy bounded path | GrayAlpha8 already supports Stored, FixedOrStored, DynamicOrFixedOrStored × None, Adaptive; Adam7 must not reduce that surface. | High | All six pairs encode/decode through one profile-aware traversal; Adaptive resets predictor history per pass and eager bytes equal chunk bytes for each pair. |
| Atomic admission | Interlacing cannot weaken the existing no-output/no-lease guarantee. | Medium | Incompatible descriptor and capability/geometry/output/work/budget failures leave eager output empty, do not charge an accepted result, and cannot expose a usable chunk lease for all six pairs. |
| Replay integrity before lease writes | A caller-buffered source mutation must not first alter the caller's next lease. | Medium | After one acknowledged prefix then U8 GrayAlpha mutation, Stored, Fixed, and Dynamic Adam7 routes fail with zero writes, unchanged sentinel tails, unchanged accepted total, and the same sticky terminal result on later pulls. |
| Public decode semantics | The feature needs a truthful observable round trip within the current decoder model. | Low | Decoding Type-4/8 output through the public PNG API yields straight RGBA8 with `R=G=B=source gray` and `A=source alpha` for every non-symmetric source position. |
| Legacy and portable proof | Additive encoder selection cannot destabilize shipped output or a single target. | Medium | Frozen non-interlaced GrayAlpha8 plus Gray8, Gray16, GrayAlpha16, RGB8, and straight-RGBA8 literals remain unchanged; the ordinary PNG package suite passes on js, wasm, wasm-gc, and native. |

## Differentiators

| Feature | Value proposition | Complexity | Notes |
|---|---|---:|---|
| Profile-aware Adam7 reuse | New Type-4/8 capability inherits all established safety and compression behavior without a raster-sized staging buffer. | High | Reuse the existing pass cursor, `_png_wire_byte`, preflight ledger, and `PngEncodeMachine`; do not make a GrayAlpha8-specific encoder fork. |
| Literal seven-pass public vector | Distinct grey and alpha bytes reveal component swaps and pass-coordinate errors that a uniform fixture hides. | Medium | Derive the expected stored/filter-None payload independently from the seven Adam7 geometries, rather than from a second encoder invocation. |
| Strong chunk contract | Exact bytes alone miss caller-memory and retry semantics. | Medium | Fresh encoder per zero-capacity, one-byte, and ragged schedule; append only accepted bytes and prove untouched tails and terminal stickiness. |
| Symmetric replay hardening | U8 GrayAlpha should receive the same pre-lease mutation rule now used for U16 wire profiles. | Low | Generalize the existing revision guard by replay semantics rather than sample width; fingerprint checks remain a terminal backstop, not the first detection point. |

## Requirement Candidates

| ID | Requirement | Acceptance evidence |
|---|---|---|
| **GRAYA8A7-01** | A library user can explicitly select eager and caller-buffered Adam7 encoding for a legal packed U8, straight-alpha GrayAlpha image, receiving an interlaced PNG with depth 8 and colour type 4. Existing GrayAlpha8 factories remain explicitly non-interlaced. | Public tests exercise the narrow and all-strategy eager/chunk constructors, assert IHDR `08 04 01` for Adam7 and `08 04 00` for frozen legacy routes, and reject incompatible non-GrayAlpha/non-U8/non-straight sources before output. |
| **GRAYA8A7-02** | GrayAlpha8 Adam7 reuses the single bounded profile-aware pipeline across Stored/FixedOrStored/DynamicOrFixedOrStored × None/Adaptive; each pass has local filter history and atomic preflight/replay semantics remain intact. | One 5×5 distinct-byte fixture proves seven-pass `G,A` wire order. A six-pair eager/chunk matrix proves byte identity and public decode. Resource failures prove empty eager output/no chunk lease. Mutation-after-prefix tests for Stored, Fixed, and Dynamic prove zero post-mutation lease writes, accepted-only progress, and sticky terminals. |
| **GRAYA8A7-03** | Public GrayAlpha8 Adam7 evidence proves pass-aware wire/decode fidelity, hostile caller-buffered behavior, legacy stability, and four-target portability. | Fresh zero, one-byte, and ragged drains preserve eager identity and untouched lease tails; literal frozen non-interlaced/legacy vectors survive; `moon -C modules/mb-image test png --target all --frozen` passes independently on js, wasm, wasm-gc, and native. |

## Explicit Exclusions

| Excluded feature | Why exclude it | Do instead |
|---|---|---|
| Implicit Adam7 in existing `new_graya8*` constructors | It would change compatibility bytes and make interlace selection invisible at call sites. | Add the two explicit interlace constructor shapes only. |
| Generic new PNG or DEFLATE pipeline | A parallel route risks different bounds, filtering, and replay behavior. | Parameterize the existing profile-aware machine. |
| Image-sized pass or converted-raster staging | It weakens bounded-memory intent without solving a Type-4/8 requirement. | Traverse existing source views through the Adam7 cursor. |
| Decoder model widening or alpha/colour conversion | Current public decode already has a documented GrayAlpha8-to-straight-RGBA8 canonicalization. | Test that established mapping; defer any richer decoder contract to its own milestone. |
| Gray8 Adam7, palette/low-bit/tRNS, RGB16/RGBA16, APNG | Each changes a distinct model, packing, or framing contract. | Keep the milestone limited to legal packed U8 GrayAlpha Type-4/8. |
| Release automation, registry publication, FFI, target wrappers, or copied source trees | None contributes to the requested portable encoder capability. | Use the established package command and in-tree MoonBit implementation. |

## Feature Dependencies

```text
existing packed U8 GrayAlpha descriptor + profile admission
  → explicit eager/chunk interlace constructors
    → shared Adam7 pass cursor and G,A wire mapping
      → pass-local None/Adaptive filtering
        → Stored/Fixed/Dynamic planning + atomic preflight
          → pre-lease replay-revision validation
            → public wire/decode, hostile lease, legacy, four-target evidence
```

## Recommended Delivery Order

1. **Factories and Type-4/8 Adam7 pass profile** — implement `GRAYA8A7-01` with the distinct-byte literal pass vector. This makes the public selection and exact wire contract concrete before broad strategy testing.
2. **Bounded streaming semantics** — implement `GRAYA8A7-02`, including pass-local Adaptive filtering, six-pair eager/chunk parity, atomic failure handling, and U8 pre-lease replay protection.
3. **Portable public qualification** — implement `GRAYA8A7-03` with hostile schedules, decode canonicalization, frozen literals, and the ordinary four-target package test.

## Sources

- Live local implementation: `modules/mb-image/png/png.mbt`, `encode.mbt`, and `stream_encode.mbt` — HIGH local evidence. It shows GrayAlpha8's current non-interlaced rejection and GrayAlpha16's additive Adam7 constructor/profile pattern.
- Live local public tests: `modules/mb-image/png/encode_test.mbt` and `stream_encode_test.mbt` — HIGH local evidence for six-pair, lease, decode, and literal-vector conventions.
- Shipped verification records: `.planning/milestones/v0.16-phases/52-portable-gray-alpha-public-evidence/52-VERIFICATION.md` and `.planning/milestones/v0.18-phases/58-portable-adam7-public-evidence/58-VERIFICATION.md` — HIGH local evidence for the expected public qualification structure.
- [PNG Specification, Second Edition](https://www.libpng.org/pub/png/spec/iso/index-object.html) — normative corroboration for type-4/8, grey-then-alpha ordering, and seven-pass Adam7 behavior.
