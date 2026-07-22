# Phase 52: Portable Gray+Alpha Public Evidence - Pattern Map

**Mapped:** 2026-07-23  
**Files analyzed:** 2 planned test modifications  
**Analogs found:** 2 / 2

## Scope and Constraints

Phase 52 is test evidence only. Extend the existing PNG package tests; do not
modify `png.mbt`, `stream_encode.mbt`, encoder/decoder internals, build scripts,
fixtures, or source trees. There is no Phase 52 `RESEARCH.md`; this map uses
`52-CONTEXT.md`, the completed Phase 49 evidence artifacts, Phase 51
verification/research, and the current PNG implementation/tests.

The public seams are already available:

```moonbit
// modules/mb-image/png/png.mbt:181-218
pub fn PngEncoder::new_graya8_with_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  { strategy, filter_strategy, interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::GrayAlpha8 }
}
```

```moonbit
// modules/mb-image/png/stream_encode.mbt:144-159
pub fn PngChunkEncoder::new_graya8_with_strategies(...) -> Result[PngChunkEncoder, @error.CoreError] {
  let machine = match PngEncodeMachine::new_with_profile(
    source, PngEncodeProfile::GrayAlpha8, strategy,
    filter_strategy, PngInterlaceStrategy::None, limits, budget, diagnostics,
  ) { Err(error) => return Err(error); Ok(value) => value }
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}
```

Use only these public constructors and `@codec.ImageDecoder::decode(PngDecoder::new(), ...)`.
Do not introduce a profile, private decoder/encoder seam, staging buffer, retry
logic, target branch, source-tree copy, or new test module.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/encode_test.mbt` | test | transform / request-response | Same file's Gray16 public eager evidence at lines 252-379 and 1028-1066; GrayAlpha eager/decode tests at lines 152-177, 383-410, 905-956 | exact role, near-identical evidence flow |
| `modules/mb-image/png/stream_encode_test.mbt` | test | streaming | Same file's Gray16 hostile public evidence at lines 519-573 and 947-981; GrayAlpha chunk factory tests at lines 147-173 and 768-821 | exact role and data flow |

## Pattern Assignments

### `modules/mb-image/png/encode_test.mbt` (test, transform / public decode)

**Primary analog:** Gray16 portable public evidence:
`png_encode_gray16_public_fidelity_image` at lines 252-297,
`png_encode_gray16_public_decode_is_canonical` at lines 351-379, and test
`PNG Gray16 public eager fidelity` at lines 1028-1066.

**Gray+Alpha-specific analog:** `png_encode_graya8_image` at lines 152-177,
`png_encode_graya8_decode_matches_source` at lines 383-410, and tests at
lines 905-956.

#### Public byte-vector fixture and framing

Copy the Gray16 public-evidence organization, but use `@model.ImageFormat::graya8()` and a compact array of distinct `(gray, alpha)` U8 pairs. The current two-pixel fixture establishes the descriptor/metadata/byte-write shape:

```moonbit
// encode_test.mbt:152-176
let descriptor = @model.ImageDescriptor::new(
  2UL, 1UL, @model.ImageFormat::graya8(),
  [@model.PlaneDescriptor::new(0UL, 4UL, 4UL, 4UL, 1UL, 1UL, 2UL, 1UL).unwrap()],
  4UL,
  @model.ImageMetadata::new(
    @color.ColorSpaceIdentity::Srgb, @color.TransferIdentity::EncodedSrgb,
    Some(@color.AlphaMode::Straight), @profile.ProfileIdentity::builtin_srgb(),
    @model.Orientation::TopLeft, ...,
  ),
).unwrap()
// Write gray at component 0 and alpha at component 1.
view.set_byte(0UL, 0UL, 0UL, b'\x13').unwrap()
view.set_byte(0UL, 0UL, 1UL, b'\xa7').unwrap()
```

For compact public byte evidence, follow the GrayAlpha Stored assertion at
lines 905-916: assert fixed PNG framing (`IHDR` depth 8, colour type 4,
non-interlaced) plus literal expected stored scanline/payload bytes for the
non-symmetric fixture. If a full literal is clearer, follow the frozen-vector
style below; expected bytes must be literals, never emitted by a second current
encoder call.

```moonbit
// encode_test.mbt:905-916
inspect(
  bytes[0] == b'\x89' && bytes[1] == b'P' && bytes[24] == b'\x08' &&
    bytes[25] == b'\x04' && bytes[28] == b'\x00' && bytes[48] == b'\x00' &&
    bytes[49] == b'\x13' && bytes[50] == b'\xa7' && ...,
  content="true",
)
```

#### Decode canonicalization

Copy the existing public decoder helper exactly in shape. It is the direct
GrayAlpha analogue—not the Gray16 high-byte helper—because the required result
is straight RGBA8: R/G/B each equal source gray and A equals source alpha.

```moonbit
// encode_test.mbt:383-408
let decoded = @codec.ImageDecoder::decode(
  PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
  @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
  png_encode_limits(output=4096UL, work=1048576UL),
  png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
).unwrap()
let restored = decoded.image().view()
// Require Rgba; compare channels 0..2 to gray, then channel 3 to alpha.
```

Keep the test on this public decoder entry point. Do not inspect a private
profile or make a test-only encoder path.

#### Six-pair eager matrix

Use the nested strategy/filter loop from the current GrayAlpha factory test,
which already hits the exact public factory required by Phase 52:

```moonbit
// encode_test.mbt:944-955
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    let (_, writer) = png_encode_with(
      PngEncoder::new_graya8_with_strategies(strategy, filter_strategy), gray_alpha,
    )
    let bytes = png_encode_prefix(writer)
    inspect(bytes[24] == b'\x08' && bytes[25] == b'\x04' && bytes[28] == b'\x00', content="true")
  }
}
```

Extend each loop iteration with `png_encode_graya8_decode_matches_source(bytes)`
or its new public-corpus equivalent. Exact Stored/None byte proof belongs only
to the known Stored/None vector; other filter/compression results need framing
and public decode semantics, not opaque whole-file snapshots.

#### Frozen legacy vectors

Extend—not replace—the existing literal-vector test `PNG filter strategy eager
frozen compatibility vectors` at lines 775-845. It already freezes Gray8,
RGB8, and straight-RGBA8. Its literal-first pattern is mandatory:

```moonbit
// encode_test.mbt:775-793
let gray_stored = b"\\x89PNG..." // fixed literal, not generated
for bytes in [
  png_encode_prefix(gray_default_writer),
  png_encode_prefix(gray_configured_writer),
  png_encode_prefix(gray_adaptive_writer),
] {
  inspect(bytes == gray_stored, content="true")
}
```

Phase 52 additionally calls for a frozen Gray16 legacy vector. There is no
Gray16 literal in this current frozen test: use the existing Gray16 Stored
source/framing oracle at lines 874-889 and 993-1024 as the source shape, then
add a literal comparison beside the existing Gray8/RGB8/RGBA8 literals. Do not
replace it with the Gray16 public scanline-only assertion at lines 1028-1066.

### `modules/mb-image/png/stream_encode_test.mbt` (test, streaming)

**Primary analog:** `png_stream_gray16_public_drain` at lines 519-573 and
`PNG Gray16 chunk public evidence` at lines 947-981.

**Gray+Alpha-specific analog:** `png_stream_graya8_image` at lines 147-173;
`PNG GrayAlpha8 chunk Stored output matches eager` at lines 768-787; and
`PNG GrayAlpha8 chunk factory strategies match eager` at lines 791-821.

#### Shared fixture / eager oracle

Keep fixtures local to this test file, as Phase 49 did. Copy the GrayAlpha
descriptor and non-symmetric component writes from lines 147-173, expanding
only as needed for component fidelity. Build eager bytes with the local helper
pattern at lines 626-638 (`png_stream_graya8_eager_with_strategies`), then make
fresh chunk encoders for every schedule.

#### Hostile zero / one / ragged drains and accepted-only progress

Copy the Gray16 public drain as the exact streaming pattern; replace only the
fixture and constructor name. It proves both accepted ownership and output
identity:

```moonbit
// stream_encode_test.mbt:526-554
let encoder = PngChunkEncoder::new_gray16_with_strategies(
  image.view(), strategy, filter_strategy,
  png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
).unwrap()
...
if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
  abort("png gray16 public accepted progress")
}
for index = pulled.written(); index < capacity; index = index + 1UL {
  if owner.view().get(index).unwrap() != b'Z' { abort("png gray16 public lease tail") }
}
...
if Bytes::from_array(output) != eager { abort("png gray16 public eager parity") }
```

For GrayAlpha use `PngChunkEncoder::new_graya8_with_strategies` and retain all
three Phase 52 schedules from the direct test analog:

```moonbit
// stream_encode_test.mbt:960-978
// First pull is explicit: capacity 0, written 0, total 0, NeedOutput, sentinel unchanged.
[0UL, 1UL]
[1UL]
[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]
```

The zero lease must be asserted before calling the drain helper; a helper-only
test could hide a no-progress failure. Each drain call constructs a fresh
encoder internally, so never reuse an encoder after a schedule completes.

#### Sticky successful terminal

Keep the later-sentinel assertion from lines 555-568. This is the standard
successful terminal contract and must remain distinct from mutation/error
stickiness tests:

```moonbit
let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
let later = sentinel.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
if later.written() != 0UL || later.total_written() != pulled.total_written() ||
  !(later.outcome() is PngChunkPullOutcome::Finished) {
  abort("... terminal progress")
}
// Every sentinel byte remains b'Z'.
```

The underlying implementation confirms why this contract is portable:
`PngChunkEncoder::pull` returns zero bytes and retains `Finished` when already
terminal (`stream_encode.mbt:302-311`), increments `total_written` only after
acknowledgement (`lines 350-374`), and returns `NeedOutput` at capacity
exhaustion (`lines 382-387`). Tests should observe those public results only.

#### Frozen legacy chunk vectors

Extend the existing `PNG filter strategy chunk frozen compatibility vectors`
test at lines 1024-1087. It already uses literal Gray8, RGB8, and RGBA8 Stored
PNG values and drains default/configured/adaptive routes through the normal
helper. Add Gray16 literal coverage in this same test, using a small known
Stored vector; preserve the literal behavior of the three existing families.

## Shared Patterns

### Public API boundary

**Sources:** `png.mbt:181-218`, `stream_encode.mbt:144-159`  
**Apply to:** both test files

Use `PngEncoder::new_graya8_with_strategies` for eager evidence and
`PngChunkEncoder::new_graya8_with_strategies` for caller-buffered evidence.
Both have fixed type-4, no-interlace behavior. No private profile/constructor
belongs in tests.

### Decoder canonicalization

**Source:** `encode_test.mbt:383-410`  
**Apply to:** eager public-byte test and each six-pair decode check

Decode the complete PNG with `ImageDecoder::decode(PngDecoder::new(), ...)`.
Require `Rgba`; assert three gray copies and the original alpha. Fixtures must
give gray and alpha distinct values so a component swap or accidental opacity
cannot pass.

### Caller lease ownership and terminals

**Source:** `stream_encode_test.mbt:519-573, 947-981`  
**Apply to:** GrayAlpha hostile schedule matrix

Allocate each caller lease with a `b'Z'` sentinel. Append only indexes below
`pulled.written()`, compare `total_written` with previously accepted bytes, and
verify both unused lease tails and post-finish leases remain untouched. Test
zero capacity first, then one byte, then the deterministic ragged schedule.

### Frozen compatibility values

**Sources:** `encode_test.mbt:775-845`; `stream_encode_test.mbt:1024-1087`  
**Apply to:** eager and chunk target-level evidence

Expected PNGs are byte-string literals written before encoder calls. Compare
default/configured/adaptive output to those literals. Preserve current Gray8,
RGB8, and RGBA8 literals; add the required Gray16 literal alongside them.

### Portable test invocation

**Established command:**

```powershell
moon -C modules/mb-image test png --target all --frozen
```

This runs the same package suite on js, wasm, wasm-gc, and native. It is the
Phase 52 acceptance command; do not add target-specific implementations or
separate fixture routes. The Phase 49 four individual commands are historical
evidence, while `52-CONTEXT.md` locks `--target all` for this phase.

## No Analog Found

None. The implementation already has direct public GrayAlpha factory/decode
tests, and Phase 49 supplies an exact portable-public-evidence pattern for
wire vectors, hostile drains, accepted-only progress, sticky terminals, and
frozen regressions.

## Metadata

**Analog search scope:** `.planning/milestones/v0.15-phases/49-portable-gray16-public-evidence/`, `.planning/phases/51-bounded-gray-alpha-png-encoding/`, `modules/mb-image/png/{png,stream_encode,encode_test,stream_encode_test}.mbt`, and portable PNG planning evidence.  
**Files scanned:** 16 primary context, evidence, implementation, and test files.  
**Pattern extraction date:** 2026-07-23
