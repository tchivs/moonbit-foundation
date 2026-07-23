# v0.20 High-Precision GrayAlpha Decode — Pitfalls and Evidence

**Scope:** Type-4 / 16-bit PNG decode only.  This record identifies risks and
testable prevention criteria; it does not select or implement the public API.
**Researched:** 2026-07-23
**Overall confidence:** MEDIUM — the decisive external format and target facts
come from current primary documentation, but the GSD provider classifier assigns
the web-search retrieval path MEDIUM confidence.  The codebase anchors are direct
local evidence.

## Current Decode Fact Pattern

The v0.19 repository can *encode* a packed, little-endian `ImageFormat::graya16()`
source as Type-4/16 wire bytes, but the shared PNG decoder has an intentionally
different legacy result contract.  Structural preflight treats Type 4 as two
source channels and four output channels, then `_png_descriptor_with_metadata`
always constructs `rgb8` or `rgba8`.  After byte-domain filter reconstruction,
`_png_write_16bit_grayscale_alpha_row` reads `Ghi` and `Ahi` and expands them to
`(Ghi, Ghi, Ghi, Ahi)`.  `Glo` and `Alo` never reach the public result.

That is compatible behaviour, not a decoding bug.  v0.20 therefore needs an
explicit additive high-precision result/conversion boundary.  Changing the default
`PngDecoder` result descriptor or changing existing callers to receive GrayAlpha16
would violate the accepted RGB8/RGBA8 facade and invalidate frozen evidence.

## Critical Pitfalls

### 1. Accidental high-byte narrowing before the explicit conversion boundary

**What goes wrong:** A new Type-4/16 path shares the existing row writer or its
descriptor.  It reconstructs four input bytes correctly but stores only `Ghi` and
`Ahi`, silently losing the low bytes before the caller can request fidelity.

**Why it happens:** The current decoder deliberately canonicalizes all PNG profiles
to RGB8/RGBA8.  The literal narrowing point is
`modules/mb-image/png/raster_decode.mbt:205` in
`_png_write_16bit_grayscale_alpha_row`; the descriptor narrowing points are
`raster_decode.mbt:44-47` and `stream_decode.mbt:507-509`.  Preflight also prices
Type 4 as four 8-bit output channels at `structural.mbt:736-745`.

**Consequences:** A result labelled “16-bit” could contain high-byte replicas,
or a later conversion API could falsely claim losslessness.  Values differing only
in `Glo` or `Alo` would compare equal after decode.

**Prevention / acceptance evidence:**

- Use a distinct internal high-precision result/sink route selected before image
  descriptor allocation; do not make the old row writer conditional on a public
  flag after it has committed RGBA8 bytes.
- Decode a non-symmetric, multi-pixel Type-4/16 fixture whose `Ghi`, `Glo`, `Ahi`,
  and `Alo` all differ.  Assert the raw high-precision result preserves every
  component byte in defined storage order, including pairs with identical highs
  and different lows.
- Assert the explicit legacy conversion of that same result is exactly
  `(Ghi,Ghi,Ghi,Ahi)` for each pixel.  This makes the one intentional narrowing
  location executable evidence rather than an incidental side effect.
- Retain `raster_decode_wbtest.mbt:181` (`PNG 16-bit native-alpha raster maps
  source high bytes after bpp-sized reconstruction`) as a legacy-only test; add a
  separate fidelity oracle rather than rewriting it to expect a new default.

### 2. Endianness and filtering-order confusion

**What goes wrong:** The decoder interprets a PNG pair as local little-endian
storage before unfiltering, filters with a two-byte rather than four-byte Type-4
pixel distance, or swaps alpha/grey pairs while adapting to `graya16` storage.

**Why it happens:** PNG wire samples are MSB-first (`Ghi,Glo,Ahi,Alo`) but the
established `graya16` source model is little-endian; its encoder performs an
explicit byte reversal.  PNG filters operate on the serialized byte stream, so a
Type-4/16 `bpp` is four, not two components and not two output RGBA8 bytes.
Existing safeguards are `_png_source_bytes_per_pixel` in
`structural.mbt:537-545`, `PngPackedRows::reconstruct` in
`raster_decode.mbt:117-130`, and the Type-4 writer at `raster_decode.mbt:197-217`.

**Consequences:** Filter-None vectors may pass while Sub, Up, Average, Paeth, or
Adam7 fixtures decode wrong.  The failure can look like merely lower precision,
making it particularly difficult to diagnose from RGB8 output.

**Prevention / acceptance evidence:**

- Define the high-precision result storage order in the public contract and make
  the PNG-to-storage conversion occur only after full byte-domain reconstruction.
  A raw PNG byte assertion must demonstrate `Ghi,Glo,Ahi,Alo` on the wire and the
  declared in-memory order separately.
- Use filter fixtures for all five filter tags with values that force carries and
  distinguish each of four lanes.  For every output pixel, compare the full two
  U16 component values, not just their high bytes.
- Include a small all-seven-pass Adam7 Type-4/16 fixture; reset predictor history
  per pass and prove coordinate placement plus all four source bytes.  The current
  pass/local-row boundary is `PngRasterSink::new` and `emit` at
  `raster_decode.mbt:300-326,360-424`; pass row size comes from
  `_png_adam7_passes` at `structural.mbt:588-601`.
- Preserve the encoder's existing independent big-endian evidence:
  `encode_test.mbt:1281` and `encode_test.mbt:1432`, and add decode tests which
  use a fixture built independently of those encoder factories.

### 3. Straight-alpha or grey semantics drift

**What goes wrong:** The new result converts Type 4 to premultiplied alpha,
interprets it as a transparent-key image, treats alpha as a second grey channel,
or exposes high precision while relabelling its encoded-sRGB metadata as linear.

**Why it happens:** Existing canonicalization deliberately repeats grey into RGB
and labels alpha Straight.  Type-4 has a native, unassociated alpha sample; it is
not `tRNS`.  The current result metadata correctly chooses `Straight` for four
channels in `_png_empty_metadata` (`raster_decode.mbt:8-20`) and Type-4 source
channel selection occurs in `stream_decode.mbt:477-487`.  `tRNS` handling rejects
other type values at `stream_decode.mbt:399-421`, which is the correct place to
retain that prohibition.

**Consequences:** Correct sample bytes can composite incorrectly, and a prohibited
`tRNS` chunk might either be accepted or overwrite the explicit alpha values.

**Prevention / acceptance evidence:**

- Require `GrayAlpha16`, exactly two 16-bit components, and
  `AlphaMode::Straight` on the high-precision result.  Assert that a pixel with
  `G=0xffff, A=0x0000` retains white grey and zero alpha (no pre-multiplication).
- Reject Type-4 `tRNS` with the same typed semantic error as the legacy decoder;
  test it in both eager and chunk paths and verify no result becomes visible.
- Retain the current metadata/color-declaration path rather than performing a
  conversion that changes transfer identity.  Test one sRGB-declared Type-4/16
  fixture to ensure metadata survives while component bytes remain unmodified.
- The W3C PNG Third Edition confirms colour type 4 is grey then alpha, uses
  8/16-bit unassociated alpha, and forbids `tRNS` for types 4 and 6
  (<https://www.w3.org/TR/png-3/>).

### 4. Hostile input becomes more expensive or becomes partially observable

**What goes wrong:** An additive result route allocates a second image or changes
row/work accounting after the legacy RGBA8 budget was admitted; malformed or
enormous input can consume unexpected resources, or the chunk decoder exposes a
partially built high-precision image before IEND/EOF validation.

**Why it happens:** Existing 16-bit accounting assumes one four-bytes-per-pixel
RGBA8 image plus two encoded rows (`_png_16bit_decode_budget`,
`structural.mbt:642-676`).  A packed GrayAlpha16 result is also four bytes per
pixel, so it can retain that bound *only if it replaces rather than shadows* the
legacy result storage.
`_png_preflight_ihdr` runs before output allocation and checks width, height,
pixels, image bytes, filtered output, and work (`structural.mbt:700-791`).  The
resumable machine separately enforces input bytes before dispatch
(`stream_decode.mbt:664-688`) and keeps the sink private until terminal success.

**Consequences:** Limit checks can admit the legacy 4-bytes/pixel result but the
new route can allocate a second 4-bytes/pixel representation, or eager/chunk paths
can disagree in error, budget remaining, diagnostics, or terminal visibility.

**Prevention / acceptance evidence:**

- Create a precision-aware preflight/budget calculation before `OwnedImage` (or
  equivalent result storage) allocation.  Charge exactly one output representation
  (four bytes/pixel if the result is packed GrayAlpha16), the two maximum
  reconstructed source rows, allocations, allocation size, width, height, pixels,
  and work with checked arithmetic.  If an API requires a second conversion image,
  it must have an explicit separately bounded conversion operation.
- Boundary-test each resource dimension one below/exactly at/one above the
  calculated requirement.  On rejection, assert no public result, no partial
  result, unchanged caller-visible budget except documented diagnostic work, and
  a stable typed context (`width`, `height`, `pixels`, `image-bytes`,
  `output-bytes`, or `work`).
- Run the Type-4/16 accepted and malformed corpus through initial empty, one-byte,
  and ragged chunk schedules; compare result/error/diagnostics/budget remainders
  with eager decode and assert failure stays sticky.  Existing executable pattern:
  `stream_decode_test.mbt:404,484,539,589,610`.
- Keep IDAT boundaries semantically irrelevant: split a valid compressed stream
  within every interesting four-byte pixel/filter boundary.  PNG specifies IDATs
  form one zlib stream and have no scanline semantics
  (<https://www.w3.org/TR/png-3/>).

### 5. Backward-compatible facade is widened or frozen vectors drift

**What goes wrong:** The implementation changes `PngDecoder`, `PngChunkDecoder`,
or `DecodeResult` globally so legacy Type-4/16 decodes now return `graya16`; or it
changes 8-bit/other PNG output, errors, metadata, byte counts, or encoder bytes
while sharing code.

**Why it happens:** The component boundary is presently intentionally broad:
`PngDecoder` is documented as RGB8/RGBA8 interchange in `png.mbt:2-7`, and both
eager and chunk facades use `PngDecodeMachine::decode_reader` and the same private
machine (`stream_decode.mbt:944-977`).  v0.19 froze broad GrayAlpha16 encode and
legacy evidence, not a high-precision decode result.

**Consequences:** Source-compatible consumers can receive a descriptor their
storage/ops code does not expect; binary-compatible encoder output may be changed
despite v0.20 only being a decoder-contract milestone.

**Prevention / acceptance evidence:**

- Make high precision opt-in by a new, explicit decoder result/operation.  The
  legacy `PngDecoder` and `PngChunkDecoder` must still return RGB8/RGBA8 with the
  old high-byte mapping for the same Type-4/16 fixture.
- Freeze and rerun the existing GrayAlpha16 compatibility anchors: public eager
  wire/decode (`encode_test.mbt:1281`), encoder strategy parity
  (`encode_test.mbt:1458`), chunk public evidence
  (`stream_encode_test.mbt:1621`), and legacy constructor byte tests
  (`encode_test.mbt:1926`, `stream_encode_test.mbt:2140`).
- Compile an unchanged public consumer against the package and run its legacy
  decode → operation → encode workflow.  Compare descriptor, component bytes,
  metadata, result counters, and final encoded bytes to frozen literals/digests.

### 6. “Portable” proof silently covers only native

**What goes wrong:** The new byte-pair conversion passes on the native compiler
but has a target-specific narrowing, signed shift, `Byte` conversion, allocation,
or test-fixture issue on JavaScript, Wasm, or Wasm-GC.

**Why it happens:** All production source is intended to be shared, but supported
targets are a declared compatibility surface, not a guarantee.  The package and
PNG package both explicitly declare `+js+wasm+wasm-gc+native` in
`modules/mb-image/moon.mod.json` and `modules/mb-image/png/moon.pkg`; no target
split should be introduced for the decode contract.

**Consequences:** A claimed portable result can lose low bytes or have different
typed errors/diagnostics outside the developer's native machine.

**Prevention / acceptance evidence:**

- Run the focused high-precision wire/decode, hostile-resource, eager/chunk
  equivalence, and legacy-regression tests using
  `moon -C modules/mb-image test png --target all --frozen`, then record distinct
  passing counts for `wasm`, `wasm-gc`, `js`, and `native`.
- Require identical fixture component bytes, result shape, error category/code/
  context, diagnostics render, and budget remainders on all four targets; do not
  accept a target-specific oracle.
- The current MoonBit package documentation defines `--target all` as exactly
  those four backends (<https://docs.moonbitlang.com/en/stable/toolchain/moon/package.html>).

## Phase-Specific Warnings

| Work item | Failure to guard | Minimum evidence |
|---|---|---|
| Decoder contract | A new type leaks into legacy `DecodeResult` | Compile/run an unchanged legacy consumer plus new opt-in fixture |
| Raster sink | Full pairs reconstructed, then narrowed in the shared writer | Four-byte component oracle after filters and before conversion |
| Storage bridge | PNG MSB-first confused with `graya16` little-endian storage | Explicit wire bytes and explicit storage bytes, non-symmetric lanes |
| Preflight | Old RGBA8 allocation math approves new high-precision allocation | Exact/one-less resource matrix, no partial result |
| Streaming | High precision differs by caller chunk schedule | Empty/one/ragged eager-equivalence and sticky-terminal matrix |
| Portability | Native-only confidence | Same assertions and result/error/budget observations on all four targets |

## Existing Anchors to Preserve

- Decoder architecture and terminal visibility: `modules/mb-image/png/stream_decode.mbt:470-510,625-627,944-977`.
- Type-4 admission and byte-domain geometry: `modules/mb-image/png/structural.mbt:537-560,700-791`.
- Current deliberate narrowing: `modules/mb-image/png/raster_decode.mbt:197-217`.
- Current byte-domain 16-bit test: `modules/mb-image/png/raster_decode_wbtest.mbt:160-181`.
- Model/storage semantics: `modules/mb-image/model/model_test.mbt:265-416` and `modules/mb-image/storage/storage_test.mbt:219`.
- Resumable hostile decoder oracle: `modules/mb-image/png/stream_decode_test.mbt:404-610`.
- v0.19 completion evidence and four-target baseline: `.planning/milestones/v0.19-MILESTONE-AUDIT.md` and `.planning/v0.19-INTEGRATION.md`.

## Sources

- [W3C PNG Specification (Third Edition)](https://www.w3.org/TR/png-3/) — MEDIUM retrieval confidence; primary format authority.
- [MoonBit package configuration](https://docs.moonbitlang.com/en/stable/toolchain/moon/package.html) — MEDIUM retrieval confidence; official target behaviour.
- Local v0.19 code and audit artifacts cited above — direct repository evidence.

## What Might Be Missing

The intended public high-precision result type and conversion API have not been
chosen.  That decision determines whether the new sink owns `OwnedImage` with
`graya16`, a distinct decode-result variant, or another explicit representation.
Before implementation, phase research should resolve that API shape and verify
how operations/metadata contracts accept it without widening unrelated codecs.
