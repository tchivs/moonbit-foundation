# Phase 51: Bounded Gray+Alpha PNG Encoding - Pattern Map

**Mapped:** 2026-07-23  
**Files analyzed:** 5  
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/png.mbt` | public API / config | factory configuration | same file: `PngEncoder::new_gray16*` | exact |
| `modules/mb-image/png/encode.mbt` | service / capability boundary | transform + bounded preflight | same file: `Gray16` admission and wire mapping | exact |
| `modules/mb-image/png/stream_encode.mbt` | streaming route / service | streaming | same file: `PngChunkEncoder::new_gray16*` and profile-aware machine | exact |
| `modules/mb-image/png/encode_test.mbt` | test | transform / request-response | same file: Gray16 eager profile tests | exact |
| `modules/mb-image/png/stream_encode_test.mbt` | test | streaming | same file: Gray16 chunk, parity, and atomicity tests | exact |

## Pattern Assignments

### `modules/mb-image/png/png.mbt` (public API / factory configuration)

**Analog:** `PngEncodeProfile` and `PngEncoder::new_gray16*` in the same file.

**Profile and public factory family** (lines 107-111, 140-178):

```moonbit
priv enum PngEncodeProfile {
  LegacyRgbOrRgba
  Gray8
  Gray16
} derive(Eq)

pub fn PngEncoder::new_gray16_with_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::Gray16,
  }
}
```

Add the `GrayAlpha8` profile and mirror all four Gray16 factory shapes: default, compression-only, filter-only, and combined. Each convenience constructor delegates to the combined factory; the combined factory fixes `None` interlace and only changes the profile to `GrayAlpha8`. Do not alter legacy/Gray8/Gray16 constructors.

---

### `modules/mb-image/png/encode.mbt` (service / bounded profile admission and transform)

**Analog:** `_png_encode_source` Gray8/Gray16 profile arms, plus `_png_wire_byte`.

**Shared fail-closed admission before source read or budget charge** (lines 54-85):

```moonbit
fn _png_encode_source(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
) -> Result[UInt64, @error.CoreError] {
  if source.is_empty() {
    return Err(_png_encode_capability("empty-image"))
  }
  // width/height u32 validation omitted
  let format = source.format()
  let metadata = source.metadata()
  if format.layout() != @model.PlaneLayout::Packed {
    return Err(_png_encode_capability("packed-required"))
  }
  if metadata.space() != @color.ColorSpaceIdentity::Srgb ||
    metadata.transfer() != @color.TransferIdentity::EncodedSrgb ||
    !metadata.profile().is_builtin_srgb() {
    return Err(_png_encode_capability("builtin-encoded-srgb-required"))
  }
  if metadata.orientation() != @model.Orientation::TopLeft {
    return Err(_png_encode_capability("top-left-required"))
  }
}
```

**Profile-specific typed admission and channel count** (lines 108-130):

```moonbit
PngEncodeProfile::Gray16 => match format.channels() {
  @model.ChannelOrder::Gray =>
    if metadata.alpha() is Some(_) {
      return Err(_png_encode_capability("gray-alpha-unsupported"))
    } else if format.component() != @model.ComponentType::U16 {
      return Err(_png_encode_capability("component-u16-required"))
    } else {
      2UL
    }
  _ => return Err(_png_encode_capability("gray16-required"))
}
```

Add a separate exhaustive `GrayAlpha8` arm: require `ChannelOrder::GrayAlpha`, `ComponentType::U8`, and `Some(@color.AlphaMode::Straight)`, then return `2UL`. Retain the shared packed/sRGB/builtin-profile/top-left checks and their existing contexts; use the Gray-family short typed context convention for a wrong channel order (research recommends `graya8-required`). The existing tight-row check then derives the two-byte pixel/filter stride from `channels`.

**Scalar wire mapping: retain the normal U8 fallback** (lines 394-413):

```moonbit
fn _png_wire_byte(/* ... */) -> Result[Byte, @error.CoreError] {
  match profile {
    PngEncodeProfile::Gray16 => {
      let wire_byte = position % 2UL
      let storage_byte = match source.format().endianness() {
        @model.Endianness::Little => 1UL - wire_byte
        @model.Endianness::Big => wire_byte
      }
      source.get_component_byte(position / 2UL, row, 0UL, storage_byte)
    }
    _ => source.get_byte(position / channels, row, position % channels)
  }
}
```

Do not add a GrayAlpha wire-conversion branch: with `channels = 2UL`, the existing fallback emits component 0 then component 1 (gray then alpha) without staging.

**Non-interlace preflight guard** (lines 1518-1527):

```moonbit
match profile {
  PngEncodeProfile::Gray8 if interlace_strategy != PngInterlaceStrategy::None =>
    return Err(_png_encode_capability("gray8-noninterlaced-required"))
  PngEncodeProfile::Gray16 if interlace_strategy != PngInterlaceStrategy::None =>
    return Err(_png_encode_capability("gray16-noninterlaced-required"))
  _ => ()
}
```

Add the equivalent `GrayAlpha8` guard so every profile match is explicit and future non-`None` use is rejected before output exposure.

---

### `modules/mb-image/png/stream_encode.mbt` (streaming route / shared replay machine)

**Analog:** `PngChunkEncoder::new_gray16*` and `PngEncodeMachine::new_with_profile`.

**Caller-buffered factory and atomic construction** (lines 35-95):

```moonbit
pub fn PngChunkEncoder::new_gray16_with_strategies(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  let machine = match PngEncodeMachine::new_with_profile(
    source, PngEncodeProfile::Gray16, strategy,
    filter_strategy, PngInterlaceStrategy::None, limits, budget, diagnostics,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}
```

Mirror Gray16's four public caller-buffered factory shapes, changing only the profile and Gray+Alpha documentation. Preserve the early `Err` return: a `PngChunkEncoder` is not constructed until common preflight succeeds.

**Single profile-aware preflight/replay seam** (lines 461-507):

```moonbit
fn PngEncodeMachine::new_with_profile(/* ... */) -> Result[PngEncodeMachine, @error.CoreError] {
  let facts = match _png_encode_preflight_with_interlace_profile(
    source, profile, strategy, filter_strategy, interlace_strategy, limits, budget,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({
    source,
    profile: facts.profile,
    // shared facts, planner state, and bounded cursors
    channels: facts.channels,
    row_bytes: facts.row_bytes,
    // ...
  })
}
```

Route GrayAlpha8 through this method. Do not create a pixel buffer, a duplicate planner, or a separate streaming state machine. Keep existing Gray16-only filtered-cursor/replay-revision special cases unless a new exhaustive match genuinely requires adjustment; GrayAlpha8 uses the normal two-channel scalar path.

**IHDR profile specialization** (lines 984-1002):

```moonbit
let colour_type = match self.profile {
  PngEncodeProfile::Gray8 | PngEncodeProfile::Gray16 => b'\x00'
  PngEncodeProfile::LegacyRgbOrRgba => if self.channels == 3UL { b'\x02' } else { b'\x06' }
}
let bit_depth = if self.profile == PngEncodeProfile::Gray16 { b'\x10' } else { b'\x08' }
return Ok([
  bit_depth, colour_type, b'\x00', b'\x00',
  if self.interlace_strategy == PngInterlaceStrategy::Adam7 { b'\x01' } else { b'\x00' },
][(payload - 8UL).to_int()])
```

Add `GrayAlpha8 => b'\x04'`; retain the 8-bit branch and factory-fixed interlace byte `0`.

---

### `modules/mb-image/png/encode_test.mbt` (eager transform test)

**Analog:** Gray16 fixture and eager profile/strategy tests.

**Descriptor fixture construction** (lines 117-147):

```moonbit
let descriptor = @model.ImageDescriptor::new(
  2UL, 1UL,
  @model.ImageFormat::new(
    @model.ComponentType::U16, @model.ChannelOrder::Gray,
    @model.PlaneLayout::Packed, @model.Endianness::Little,
  ).unwrap(),
  // tight PlaneDescriptor plus encoded sRGB, builtin profile, TopLeft metadata
).unwrap()
```

Copy this helper layout for a packed U8 `GrayAlpha` fixture with `Some(Straight)` and non-symmetric `(gray, alpha)` pairs. Make component order observable in the Stored/None scanline assertion.

**Eager IHDR, typed rejection, and pre-output atomicity** (lines 813-839):

```moonbit
let error = @codec.ImageEncoder::encode(
  PngEncoder::new_gray16(), bad.view(), rejected as &@io.Writer,
  @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
  png_encode_limits(), budget, @error.Diagnostics::new(),
).unwrap_err()
inspect(error.context(), content="Some(gray16-required)")
inspect(rejected.position(), content="0")
```

Use the same shape to assert the GrayAlpha typed capability context, zero writer position, and unchanged budget. For the valid route assert IHDR `bytes[24] == b'\x08'`, `bytes[25] == b'\x04'`, and `bytes[28] == b'\x00'`.

**Strategy Cartesian product** (lines 874-906 and 933-947):

```moonbit
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    let (_, writer) = png_encode_with(
      PngEncoder::new_gray16_with_strategies(strategy, filter_strategy),
      png_encode_gray16_image(),
    )
    let bytes = png_encode_prefix(writer)
    inspect(bytes[24] == b'\x10' && bytes[25] == b'\x00' && bytes[28] == b'\x00', content="true")
  }
}
```

Use the same six-pair loop for GrayAlpha8, checking the type-4/8-bit/non-interlaced IHDR each time. Keep Phase 51 focused on eager fidelity and ordinary strategy pairing; hostile schedules and frozen public vectors remain Phase 52.

---

### `modules/mb-image/png/stream_encode_test.mbt` (caller-buffered streaming test)

**Analog:** Gray16 chunk fixture, eager/chunk parity loop, and combined atomic rejection helper.

**Factory-parity strategy grid** (lines 675-714):

```moonbit
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    let eager = png_stream_gray16_eager_with_strategies(gray, strategy, filter_strategy)
    let chunked = png_chunk_test_drain_encoder(
      PngChunkEncoder::new_gray16_with_strategies(
        gray.view(), strategy, filter_strategy, png_stream_test_limits(),
        png_stream_test_budget(), @error.Diagnostics::new(),
      ).unwrap(),
      [3UL, 7UL],
    ).unwrap()
    inspect(chunked == eager, content="true")
  }
}
```

Mirror it with a GrayAlpha packed-U8 fixture; assert eager/chunk byte identity and type-4/8-bit/non-interlaced IHDR. Retain the checks that each convenience factory compiles/constructs.

**Atomic rejection across every strategy pair** (lines 1991-2035):

```moonbit
let eager = @codec.ImageEncoder::encode(
  PngEncoder::new_gray16_with_strategies(strategy, filter_strategy),
  image.view(), writer as &@io.Writer,
  @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
  limits, eager_budget, @error.Diagnostics::new(),
).unwrap_err()
if writer.position() != 0UL ||
  !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
  abort("png gray16 eager admission exposed output")
}
let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
let chunk = PngChunkEncoder::new_gray16_with_strategies(
  image.view(), strategy, filter_strategy, limits, chunk_budget,
  @error.Diagnostics::new(),
).unwrap_err()
if !png_chunk_test_same_error(eager, chunk) ||
  !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
  abort("png gray16 chunk admission mismatch")
}
```

Copy this as a GrayAlpha helper and run it for an incompatible descriptor plus tight geometry/output/work/budget limit cases, as Gray16 does at lines 2117-2135. Its assertions are the required pre-exposure contract: no eager bytes, unchanged budgets, matching errors, and unchanged sentinel lease bytes.

## Shared Patterns

### Typed capability boundary

**Source:** `modules/mb-image/png/encode.mbt:54-138`  
**Apply to:** Both eager and caller-buffered GrayAlpha8 factories through `PngEncodeMachine::new_with_profile`.

Keep shared layout, metadata, geometry, tight-row, and limits validation ahead of the profile arm. The profile arm returns a channel count rather than allocating or converting pixels, so `2UL` propagates through filter stride, scanline size, and bounded planning.

### One bounded machine and atomic construction

**Source:** `modules/mb-image/png/stream_encode.mbt:463-535`  
**Apply to:** Both public `graya8` families.

The only profile-specific change is the selected `PngEncodeProfile`; all preflight, plan selection, filtering, replay, budget accounting, and caller-lease discipline remain in the existing machine.

### Semantic binary tests

**Source:** `modules/mb-image/png/encode_test.mbt:813-947`, `modules/mb-image/png/stream_encode_test.mbt:650-714,1991-2135`  
**Apply to:** GrayAlpha eager and chunk regressions.

Assert IHDR fields and non-symmetric gray/alpha scanline order, eager/chunk parity over the six strategy pairs, and atomic failure state. Do not add opaque whole-PNG snapshots or Phase 52 hostile-schedule/four-target evidence.

## No Analog Found

None. Gray16 is an exact structural analogue for every modified file; GrayAlpha8 changes only descriptor admission, explicit profile value, IHDR colour type, and the expected two-U8-component wire bytes.

## Metadata

**Analog search scope:** `modules/mb-image/png/{png,encode,stream_encode,encode_test,stream_encode_test}.mbt`  
**Files scanned:** 5 implementation/test files (plus Phase 51 context and research)  
**Pattern extraction date:** 2026-07-23
