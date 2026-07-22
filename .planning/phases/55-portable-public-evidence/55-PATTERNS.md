# Phase 55: Portable Public Evidence - Pattern Map

**Mapped:** 2026-07-23  
**Files analyzed:** 2 modified test files  
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/encode_test.mbt` | test | transform (public encode → PNG wire bytes → public decode) | The Gray16 public-evidence helper/test at `encode_test.mbt:316-445,1197-1238`, combined with GrayAlpha8's public type-4 decode seam at `encode_test.mbt:447-475,983-1001` | exact composite |
| `modules/mb-image/png/stream_encode_test.mbt` | test | streaming (caller-owned mutable leases) | The Gray16 hostile public drain/matrix at `stream_encode_test.mbt:592-648,1158-1194`, combined with the GrayAlpha8 type-4 counterpart at `stream_encode_test.mbt:650-706,1196-1232` | exact composite |

## Pattern Assignments

### `modules/mb-image/png/encode_test.mbt` (test, transform)

**Primary analogs:**

- U16 wire/decode: `modules/mb-image/png/encode_test.mbt:316-445,1197-1238` (Phase 49 Gray16 public evidence)
- Type-4 public decode seam: `modules/mb-image/png/encode_test.mbt:447-475,983-1001` (Phase 52 GrayAlpha8 public evidence)
- Legal Type-4/16 framing and explicit endian boundary: `modules/mb-image/png/encode_test.mbt:1016-1056,1058-1099`
- Frozen eager literals: `modules/mb-image/png/encode_test.mbt:841-904`

**Public U16 source construction pattern** (`encode_test.mbt:343-361`):

```moonbit
let wire = [
  [b'\x12', b'\x34'], [b'\xab', b'\xcd'], [b'\x00', b'\xff'],
  [b'\x7f', b'\x01'], [b'\x80', b'\x02'], [b'\xfe', b'\x10'],
]
image.with_mut_view(fn(view) {
  for y = 0UL; y < 2UL; y = y + 1UL {
    for x = 0UL; x < 3UL; x = x + 1UL {
      let sample = wire[(y * 3UL + x).to_int()]
      view.set_component_byte(x, y, 0UL, 0UL, sample[1]).unwrap()
      view.set_component_byte(x, y, 0UL, 1UL, sample[0]).unwrap()
    }
  }
  Ok(())
}).unwrap()
```

For Phase 55, copy the fixture structure but use a **legal** `@model.ImageFormat::graya16()`/little-endian packed image and set both components per pixel. Choose four distinct byte lanes per pixel so the test exposes `Ghi,Glo,Ahi,Alo`, not merely a gray U16 order. The existing legal compact fixture is already a suitable two-pixel seed: it stores `12 34 / A7 C5` and `BE 0F / 5A 76` as component bytes in `encode_test.mbt:1018-1029`.

**Literal wire assertion pattern** (`encode_test.mbt:1018-1029`):

```moonbit
let (_, writer) = png_encode_with(PngEncoder::new_graya16(), gray_alpha)
let bytes = png_encode_prefix(writer)
inspect(
  bytes[0] == b'\x89' && bytes[1] == b'P' && bytes[24] == b'\x10' &&
    bytes[25] == b'\x04' && bytes[28] == b'\x00' && bytes[48] == b'\x00' &&
    bytes[49] == b'\x12' && bytes[50] == b'\x34' && bytes[51] == b'\xa7' &&
    bytes[52] == b'\xc5' && bytes[53] == b'\xbe' && bytes[54] == b'\x0f' &&
    bytes[55] == b'\x5a' && bytes[56] == b'\x76',
  content="true",
)
```

Use `PngEncoder::new_graya16_with_strategies(Stored, None)` for the exact vector. Retain the literal expected order at the public PNG boundary; do not obtain expected bytes by invoking a second encoder. The direct Phase-55 assertion should make the filter byte and each `Ghi,Glo,Ahi,Alo` lane explicit.

**Public decoder canonicalization pattern** — combine the Gray16 public decoder call (`encode_test.mbt:417-445`) with the GrayAlpha8 RGBA channel oracle (`encode_test.mbt:449-475`):

```moonbit
let decoded = @codec.ImageDecoder::decode(
  PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
  @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
  png_encode_limits(output=4096UL, work=1048576UL),
  png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
).unwrap()
let restored = decoded.image().view()
for channel = 0UL; channel < 3UL; channel = channel + 1UL {
  if restored.get_byte(x, 0UL, channel).unwrap() != gray_high {
    abort("png graya16 public decoded grayscale")
  }
}
if restored.get_byte(x, 0UL, 3UL).unwrap() != alpha_high {
  abort("png graya16 public decoded alpha")
}
```

The Phase-55 decoder oracle must require straight `Rgba`/`U8`, compare RGB with the gray **high** byte, and compare alpha with the alpha **high** byte. Low bytes are proved only by the literal PNG wire vector; do not claim a public U16 decode round trip.

**Six-pair public factory matrix** (`encode_test.mbt:1071-1082`):

```moonbit
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    let (_, writer) = png_encode_with(
      PngEncoder::new_graya16_with_strategies(strategy, filter_strategy), gray_alpha,
    )
    let bytes = png_encode_prefix(writer)
    inspect(bytes[24] == b'\x10' && bytes[25] == b'\x04' && bytes[28] == b'\x00', content="true")
  }
}
```

Copy this loop and invoke the new public decoder helper for every pair, as Gray16 does in `encode_test.mbt:1221-1236`. Restrict the byte-for-byte scanline oracle to `Stored` + `None`; Adaptive residuals and DEFLATE choices are not frozen scanline semantics.

**Frozen eager literal-vector pattern** (`encode_test.mbt:841-904`):

```moonbit
let gray_stored = b"...literal complete PNG..."
let (_, gray_default_writer) = png_encode_with(PngEncoder::new_gray8(), gray)
let (_, gray_configured_writer) = png_encode_with(
  PngEncoder::new_gray8_with_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
  ),
  gray,
)
for bytes in [png_encode_prefix(gray_default_writer), png_encode_prefix(gray_configured_writer)] {
  inspect(bytes == gray_stored, content="true")
}
```

Extend this single established test with a literal GrayAlpha8 Stored/None vector, while retaining the literal Gray8, Gray16, RGB8, and straight-RGBA8 vectors. These values are compatibility baselines, so expected values must be declared before encoder calls and compared directly.

### `modules/mb-image/png/stream_encode_test.mbt` (test, streaming)

**Primary analogs:**

- U16 hostile drain, progress, tails, and terminal: `modules/mb-image/png/stream_encode_test.mbt:592-648,1158-1194` (Phase 49)
- Type-4 hostile drain/matrix: `modules/mb-image/png/stream_encode_test.mbt:650-706,1196-1232` (Phase 52)
- Public eager oracle: `modules/mb-image/png/stream_encode_test.mbt:778-796`
- Frozen chunk literals: `modules/mb-image/png/stream_encode_test.mbt:1275-1332`

**Fresh public eager oracle** (`stream_encode_test.mbt:778-796`):

```moonbit
fn png_stream_graya16_eager_with_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> Bytes {
  let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_graya16_with_strategies(strategy, filter_strategy),
    image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap())
  // copy exactly writer.position() bytes into a Bytes result
}
```

This existing helper is the Phase-55 oracle. Compute it fresh for each strategy/filter pair; do not use a private machine, cached chunk output, or a separate encoder implementation.

**Accepted-only, untouched-tail, sticky-terminal drain** — copy the helper shape exactly and replace only the factory/profile (`stream_encode_test.mbt:650-705`):

```moonbit
let owner = png_chunk_test_owner(capacity, fill=b'Z')
let before = output.length().to_uint64()
let pulled = owner.with_mut(0UL, capacity, fn(lease) {
  Ok(encoder.pull(lease))
}).unwrap()
if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
  abort("png graya16 public accepted progress")
}
for index = 0UL; index < pulled.written(); index = index + 1UL {
  output.push(owner.view().get(index).unwrap())
}
for index = pulled.written(); index < capacity; index = index + 1UL {
  if owner.view().get(index).unwrap() != b'Z' {
    abort("png graya16 public lease tail")
  }
}
```

On `Finished`, retain the exact later-sentinel assertion from `stream_encode_test.mbt:687-701`: compare `Bytes::from_array(output)` to eager output; then pull into a new seven-byte `Z` lease and require `written() == 0`, unchanged `total_written()`, `Finished`, and every sentinel byte unchanged. This successful-terminal test is distinct from the Phase-54 mutation-to-error sticky tests at `stream_encode_test.mbt:2818-2877`.

**Zero/one/ragged six-pair test matrix** (`stream_encode_test.mbt:1198-1232`):

```moonbit
let zero_owner = png_chunk_test_owner(1UL, fill=b'Z')
let zero = zero_owner.with_mut(0UL, 0UL, fn(lease) {
  Ok(zero_encoder.pull(lease))
}).unwrap()
if zero.written() != 0UL || zero.total_written() != 0UL ||
  !(zero.outcome() is PngChunkPullOutcome::NeedOutput) ||
  zero_owner.view().get(0UL).unwrap() != b'Z' {
  abort("png graya16 public empty lease")
}
png_stream_graya16_public_drain(image, strategy, filter_strategy, [0UL, 1UL], eager)
png_stream_graya16_public_drain(image, strategy, filter_strategy, [1UL], eager)
png_stream_graya16_public_drain(
  image, strategy, filter_strategy,
  [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL], eager,
)
```

Create a dedicated `png_stream_graya16_public_drain` from the Gray16/GrayAlpha8 helpers and apply this matrix to all three compression strategies × both filters. The direct zero-capacity pull must precede helper drains so no-progress/untouched-sentinel behavior is independently observable. Each schedule must build a fresh chunk encoder inside the drain helper.

**Frozen chunk literal-vector pattern** (`stream_encode_test.mbt:1275-1306`):

```moonbit
let gray16_stored = b"...literal complete PNG..."
let gray16_default = png_chunk_test_drain_encoder(PngChunkEncoder::new_gray16(
  gray16.view(), png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
let gray16_configured = png_chunk_test_drain_encoder(PngChunkEncoder::new_gray16_with_strategies(
  gray16.view(), PngCompressionStrategy::Stored, PngFilterStrategy::None,
  png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
).unwrap(), [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
for bytes in [gray16_default, gray16_configured] {
  inspect(bytes == gray16_stored, content="true")
}
```

Extend the same frozen-vector test with GrayAlpha8, and retain literal Gray8, Gray16, RGB8, and straight-RGBA8 vectors. Use ordinary public drains against the literals; never use eager output as the expected frozen value.

## Shared Patterns

### Public API and evidence boundary

**Sources:** `encode_test.mbt:985-1001,1018-1029`; `stream_encode_test.mbt:758-796,1196-1232`  
**Apply to:** both modified test files

All Phase-55 construction must stay at `PngEncoder::new_graya16_with_strategies`, `PngChunkEncoder::new_graya16_with_strategies`, and `ImageDecoder::decode(PngDecoder::new(), ...)`. Test helpers may only assemble real public output, caller leases, and expected literals; they must not expose a private profile, add a test-only encoder path, or use native-only APIs.

### Legal little-endian GrayAlpha16 scope

**Sources:** `encode_test.mbt:1032-1056`; `stream_encode_test.mbt:2623-2643`; Phase 54 verification truth 1  
**Apply to:** every new GrayAlpha16 fixture/test

The Phase-55 source corpus is strictly legal little-endian `GrayAlpha16`. Keep the existing negative descriptor-boundary check for big-endian unchanged, but do not make big-endian a PNG parity fixture or add a fallback branch. The authoritative statement already present in the stream test is:

```moonbit
///| All legal little-endian GrayAlpha16 strategy pairs reject capability,
///| geometry, output, work, and budget failures before observable eager or
///| caller-buffered state. Big-endian GrayAlpha16 is rejected at descriptor
///| construction and is deliberately not a PNG-admission parity case.
```

### Literal compatibility policy

**Sources:** `encode_test.mbt:841-904`; `stream_encode_test.mbt:1275-1332`; Phase 52 summary  
**Apply to:** eager and chunk frozen-vector additions

Freeze complete PNG byte strings for the legacy family exactly named by Phase 55: Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8. Preserve the existing literal values unchanged and add only the missing GrayAlpha8 literal coverage. Direct byte-literal comparison is required; a current encoder cannot generate its own expected compatibility output.

### Portable all-target command

**Source:** Phase 52 summary/verification and Phase 55 context  
**Apply to:** final Phase-55 verification

```powershell
moon -C modules/mb-image test png --target all --frozen
```

This is one portable MoonBit suite for wasm, wasm-gc, js, and native. Do not add target branches, FFI, scripts, copied sources, or separate target-specific tests. Phase 49's four individual target commands are historical; Phase 55 is locked to this single all-target invocation.

## No Analog Found

None. Phase 55 is a direct composition of the Phase 49 U16 public-evidence pattern and the Phase 52 Type-4 public-evidence pattern. The only new test-local helper expected is the mechanical `png_stream_graya16_public_drain` specialization; it should copy the established drain contract rather than introduce a new streaming driver.

## Metadata

**Analog search scope:** `AGENTS.md`; Phase 55 context; Phase 54 verification; archived Phase 49 and 52 context, plans, summaries, verification, and patterns; `modules/mb-image/png/{encode_test,stream_encode_test,png,encode,stream_encode}.mbt`.  
**Files scanned:** 16 primary planning, verification, and PNG source/test files.  
**Pattern extraction date:** 2026-07-23
