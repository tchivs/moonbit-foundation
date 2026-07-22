# Technology Stack

**Project:** MoonBit Native Foundation — v0.17 GrayAlpha16 PNG Interchange
**Researched:** 2026-07-23
**Confidence:** HIGH for the implementation recommendation (current source, tests, and v0.15/v0.16 artifacts); LOW for the separately cited web-provider confidence on the normative PNG wording.

## Executive Recommendation

Implement GrayAlpha16 as an additive profile of the existing portable `mb-image` model and PNG encoder. Add no dependencies, packages, target-specific code, FFI, copied source, or parallel encoder. The current code already has the required foundations: packed U16 component-byte access, a profile-aware scalar PNG wire-byte producer, one shared eager/caller-buffered preflight-and-replay machine, and a decoder that accepts PNG colour type 4 at bit depth 16.

The public source model should add `ImageFormat::graya16()` over the existing `ChannelOrder::GrayAlpha`, with packed U16, two components, and straight-alpha metadata. The PNG package should add a private `GrayAlpha16` profile and explicit `new_graya16*` factory families for `PngEncoder` and `PngChunkEncoder`. Their only supported raster profile is non-interlaced PNG bit depth 16, colour type 4. The shared bounded machine remains the sole implementation path.

## Recommended Stack

### Core implementation

| Technology | Version | Purpose | Why |
|---|---:|---|---|
| MoonBit / existing `tchivs/mb-image` module | workspace `0.1.0` | Model, storage, PNG codec, and tests | The behavior is an additive extension of the current public module; a separate module would duplicate contracts and fragment compatibility. |
| `mb-image/model` | existing package | `graya16()` format and descriptor admission | `ChannelOrder::GrayAlpha` already gives a two-component identity and descriptor validation centralizes metadata/layout policy. |
| `mb-image/storage` | existing package | Packed U16 component construction and scalar reads | Checked `get_component_byte` / `set_component_byte` already support packed U16; do not create a special image owner or view. |
| `mb-image/png` | existing package | Explicit eager/chunk factories and Type-4/16 profile | `PngEncodeProfile`, `_png_wire_byte`, filtering, compression planning, and `PngEncodeMachine::new_with_profile` already isolate profile differences. |
| `mb-core` and `mb-color` workspace dependencies | existing `0.1.0` | Existing checked arithmetic, budgets, errors, byte leases, alpha and sRGB identities | Reuse the imports already declared by `mb-image`; no new dependency solves a missing problem. |

### Required additions

| Component | Add | Reuse | Contract |
|---|---|---|---|
| Public image format | `ImageFormat::graya16()` | `ChannelOrder::GrayAlpha`, `ImageDescriptor`, generic owned storage/views | Packed U16, two components per pixel, encoded sRGB, builtin profile, top-left orientation, and `AlphaMode::Straight`. |
| Descriptor validation | Admit the U16 GrayAlpha identity while retaining the narrow U8 identity | Existing `GrayAlpha` validation branch | Reject planar, F32, premultiplied/missing alpha, non-sRGB/builtin metadata, and non-top-left input. |
| Private PNG profile | `PngEncodeProfile::GrayAlpha16` | Existing `Gray16` and `GrayAlpha8` profile pattern | Enforce packed/tight U16 GrayAlpha source, four raster bytes per pixel, type 4, depth 16, and non-interlaced output. |
| Wire-byte mapping | Four-byte per-pixel scalar mapping | `_png_wire_byte` and `get_component_byte` | Emit `gray-msb, gray-lsb, alpha-msb, alpha-lsb`, independent of host storage endianness, before filtering, planning, checksums, and replay. |
| Public factories | `new_graya16`, compression-only, filter-only, and combined strategy factories on eager and chunk encoders | Exact `new_gray16*` / `new_graya8*` family shape | All factories bind `PngInterlaceStrategy::None`; legacy constructors stay unchanged. |

## Dependency Policy

**Install nothing.** `modules/mb-image/moon.mod.json` already depends only on `tchivs/mb-core` and `tchivs/mb-color`; the model and PNG packages already declare the repository's shared target set. A third-party PNG codec would bypass the project-owned bounded preflight, caller-owned output lease, and deterministic byte contracts instead of extending them.

```text
mb-image/model ──> mb-image/storage ──> mb-image/png
                         │                     │
                         └── checked U16 access └── shared preflight/replay machine
```

## Public API Shape

```moonbit
// Additive format factory; exact spelling follows existing `graya8` convention.
let format = @model.ImageFormat::graya16()

// Explicit, never selected by legacy generic constructors.
let encoder = @png.PngEncoder::new_graya16_with_strategies(
  @png.PngCompressionStrategy::Stored,
  @png.PngFilterStrategy::None,
)
```

The eager and caller-buffered APIs should expose the same three strategy levels already established for Gray16 and GrayAlpha8: baseline, compression-only, filter-only, and combined strategy constructors. Do not add an interlace-selecting GrayAlpha16 constructor.

## Existing Seams to Preserve

| Seam | Current evidence | v0.17 rule |
|---|---|---|
| U16 storage | `get_component_byte`/`set_component_byte` already distinguish U16 from packed-U8 access | Read components through this checked API; never introduce manual byte offsets in PNG code. |
| Filtering | The filter stride is a byte distance, and Gray16 already maps storage bytes to PNG wire bytes before filters | GrayAlpha16 uses a stride of four bytes per pixel, not a logical channel count of two. |
| Compression/replay | Stored, FixedOrStored, and DynamicOrFixedOrStored share scalar cursors and bounded replay | Feed the new wire-byte mapping into the existing cursors; retain no converted row, image-sized staging buffer, or second stream driver. |
| Atomic construction | `PngEncodeMachine::new_with_profile` performs source/limit/work/budget admission before output state | Invalid source/profile/geometry/output/work/budget input must expose neither eager bytes nor a usable chunk encoder. |
| Decode boundary | Existing raster decoding accepts type 4 at depth 16 and publishes RGBA8 high-byte canonicalization | Document and test this boundary; do not promise U16 decode round-trip through the current public decoder. |

## Alternatives Rejected

| Category | Recommended | Alternative | Why not |
|---|---|---|---|
| Model identity | Reuse `ChannelOrder::GrayAlpha` with a U16 factory | Add another channel-order enum case | The order is still grey then alpha; bit depth belongs to `ComponentType`. |
| PNG implementation | Add one private profile to the shared machine | Build a dedicated GrayAlpha16 encoder | It would duplicate preflight, budgeting, filtering, compression, replay, and streaming semantics. |
| Expected PNG bytes | Literal, non-symmetric wire assertions | Regenerate expected bytes with another current encoder | A second encoder call cannot detect a shared serialization defect. |
| Decode claim | Explicit RGBA8 high-byte canonicalization | Claim public U16 model round-trip from decoder | Current decoder intentionally publishes U8 RGBA data; low bytes belong in wire-fidelity evidence. |

## Verification Stack

| Layer | Evidence required |
|---|---|
| Model/storage | Construct a valid packed U16 pair image; check both components and reject invalid metadata/layout/component identities. |
| Eager encode | Assert IHDR `(depth=16, colour-type=4, interlace=0)` and a literal Stored/None inflated scanline containing asymmetric U16 grey/alpha pairs. |
| Decoder boundary | Decode those public bytes and assert `(R,G,B,A) = (gray-high, gray-high, gray-high, alpha-high)`; assert low bytes only at the wire boundary. |
| Caller-buffered encode | For all 3 compression × 2 filter pairs, compare fresh chunk output with a fresh eager oracle under zero, one-byte, and deterministic ragged leases; assert accepted-only totals, unchanged unwritten tails, and sticky completion. |
| Compatibility | Keep literal Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 byte vectors in eager and chunk tests. |

The current native package invocation reported `196 passed, 0 failed`, then exceeded the local command timeout while waiting on `_build/.moon-lock`; treat that as a diagnostic observation, not a newly completed suite result. The v0.17 acceptance command should remain `moon -C modules/mb-image test png --target all --frozen`.

## Sources

- Local source and tests: `modules/mb-image/model/descriptor.mbt`, `storage/views.mbt`, `png/png.mbt`, `png/encode.mbt`, `png/stream_encode.mbt`, `png/raster_decode.mbt`, `png/encode_test.mbt`, and `png/stream_encode_test.mbt` — HIGH local evidence.
- Archived implementation contracts: v0.15 Phases 47–49 and v0.16 Phases 50–52 in `.planning/milestones/` — HIGH local evidence.
- [W3C PNG Specification, Third Edition](https://www.w3.org/TR/png-3/) — type 4 permits 8/16-bit samples, orders pixels grey then alpha, and stores 16-bit samples MSB-first. The source-provider confidence seam returned LOW; it corroborates, but does not replace, the local implementation evidence.
- [MoonBit package documentation](https://docs.moonbitlang.com/en/stable/toolchain/moon/package.html) and [module documentation](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html) — current dependency and `supported-targets` semantics; source-provider confidence seam returned LOW.
