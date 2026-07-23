# Phase 56: GrayAlpha16 Adam7 Factory and Pass Profile - Pattern Map

**Mapped:** 2026-07-23  
**Files analyzed:** 5 planned modifications  
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/png.mbt` | provider / public factory | transform | generic RGB/RGBA Adam7 factory plus existing `graya16` family in the same file | exact composition |
| `modules/mb-image/png/encode.mbt` | service / profile-aware filtered traversal | streaming | current Adam7 cursor plus non-interlaced U16 wire mapping | exact composition |
| `modules/mb-image/png/stream_encode.mbt` | provider / caller-buffered factory | streaming | generic RGB/RGBA Adam7 chunk factory plus existing `graya16` family in the same file | exact composition |
| `modules/mb-image/png/encode_test.mbt` | public integration test | transform | GrayAlpha16 literal-wire test and generated Adam7 eager test | exact composition |
| `modules/mb-image/png/stream_encode_test.mbt` | public integration test | streaming | GrayAlpha16 eager/chunk parity test and Adam7 public chunk helper | exact composition |

## Pattern Assignments

### `modules/mb-image/png/png.mbt` (provider / public factory, transform)

**Analog:** the explicit `graya16` non-interlaced factory family at `modules/mb-image/png/png.mbt:222-260`, composed with generic Adam7 selection at `modules/mb-image/png/png.mbt:337-358`.

**Factory-family pattern** (`png.mbt:224-259`):

```moonbit
pub fn PngEncoder::new_graya16() -> PngEncoder {
  PngEncoder::new_graya16_with_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
  )
}

pub fn PngEncoder::new_graya16_with_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::GrayAlpha16,
  }
}
```

**Interlace-selector pattern** (`png.mbt:337-358`):

```moonbit
pub fn PngEncoder::new_with_interlace_strategy(
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  PngEncoder::new_with_all_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None, interlace_strategy,
  )
}
```

**Apply:** add only additive `graya16` interlace-only and all-strategy factories (the names should parallel the generic pair: `new_graya16_with_interlace_strategy` and `new_graya16_with_all_strategies`).  The existing default/compression/filter/`new_graya16_with_strategies` constructors must keep forwarding `PngInterlaceStrategy::None`; do not change their spelling, signature, or output selection.

---

### `modules/mb-image/png/encode.mbt` (service / profile-aware filtered traversal, streaming)

**Analog:** the profile-aware U16 wire reader at `modules/mb-image/png/encode.mbt:416-485`, composed with the sole Adam7 cursor/traversal at `modules/mb-image/png/encode.mbt:556-666` and `700-771`.

**U16 wire-order pattern** (`encode.mbt:416-445`):

```moonbit
fn _png_profile_uses_u16_component_wire(profile : PngEncodeProfile) -> Bool {
  match profile {
    PngEncodeProfile::Gray16 | PngEncodeProfile::GrayAlpha16 => true
    _ => false
  }
}

fn _png_wire_byte(
  source : @storage.ImageView,
  profile : PngEncodeProfile,
  row : UInt64,
  channels : UInt64,
  position : UInt64,
) -> Result[Byte, @error.CoreError] {
  match profile {
    PngEncodeProfile::Gray16 | PngEncodeProfile::GrayAlpha16 => {
      let component = (position % channels) / 2UL
      let wire_byte = position % 2UL
      let storage_byte = match source.format().endianness() {
        @model.Endianness::Little => 1UL - wire_byte
        @model.Endianness::Big => wire_byte
      }
      source.get_component_byte(position / channels, row, component, storage_byte)
    }
    _ => source.get_byte(position / channels, row, position % channels)
  }
}
```

**Adam7 pass and local-filter pattern** (`encode.mbt:556-640`):

```moonbit
fn _png_adam7_cursor_location(...) -> Result[(PngAdam7Pass, UInt64, UInt64), @error.CoreError] {
  let passes = match _png_adam7_passes(source.width(), source.height(), channels, 8) {
    Err(error) => return Err(error); Ok(value) => value
  }
  // Skip empty passes and map one scalar logical position to pass/local row.
}

fn _png_adam7_candidate_byte(...) -> Result[Byte, @error.CoreError] {
  let sample = match _png_adam7_raw_byte(...) {
    Err(error) => return Err(error); Ok(value) => value
  }
  // Sub/Up/Average/Paeth use only source pixels in this same pass.
  Ok(sample - predictor)
}
```

**Profile forwarding seam** (`encode.mbt:721-771`):

```moonbit
if self.interlace_strategy == PngInterlaceStrategy::Adam7 {
  let (pass, row, in_row) = match _png_adam7_cursor_location(
    self.source, self.channels, self.index,
  ) { Err(error) => return Err(error); Ok(value) => value }
  // ...
  let byte = match _png_adam7_candidate_byte(
    winner, self.source, pass, row, self.channels, in_row - 1UL,
  ) { Err(error) => return Err(error); Ok(value) => value }
}
```

**Apply:** remove only the `GrayAlpha16` non-interlaced capability arm in the profile gate (`encode.mbt:1541-1563`), leaving Gray8, Gray16, and GrayAlpha8 rejected for Adam7. Thread `self.profile` through the Adam7 raw/candidate/winner helpers and obtain each selected sample through the existing profile-aware component-wire mapping. For the legal packed-little-endian profile, every pass byte must therefore be `Ghi,Glo,Ahi,Alo`, before filtering, planning, checksums, and replay.

**Do not duplicate geometry:** `_png_adam7_passes` is the only geometry authority (`modules/mb-image/png/structural.mbt:565-602`).  Its `row_bytes` is already parameterized by four byte channels and the existing preflight already sums nonempty pass scanlines (`encode.mbt:1601-1650`).  Do not add per-pass arrays, image-sized staging, or a second traversal.

---

### `modules/mb-image/png/stream_encode.mbt` (provider / caller-buffered factory, streaming)

**Analog:** the GrayAlpha16 chunk factory at `modules/mb-image/png/stream_encode.mbt:162-223`, composed with generic Adam7 chunk selection at `modules/mb-image/png/stream_encode.mbt:332-362`.

**Construction pattern** (`stream_encode.mbt:208-223`):

```moonbit
pub fn PngChunkEncoder::new_graya16_with_strategies(
  source : @storage.ImageView,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  let machine = match PngEncodeMachine::new_with_profile(
    source, PngEncodeProfile::GrayAlpha16, strategy,
    filter_strategy, PngInterlaceStrategy::None, limits, budget, diagnostics,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}
```

**Generic interlace construction pattern** (`stream_encode.mbt:332-362`):

```moonbit
pub fn PngChunkEncoder::new_with_interlace_strategy(...) -> Result[PngChunkEncoder, @error.CoreError] {
  PngChunkEncoder::new_with_all_strategies(
    source, PngCompressionStrategy::Stored, PngFilterStrategy::None,
    interlace_strategy, limits, budget, diagnostics,
  )
}
```

**Shared-machine/IHDR pattern** (`stream_encode.mbt:591-645`, `1112-1131`):

```moonbit
let facts = match _png_encode_preflight_with_interlace_profile(
  source, profile, strategy, filter_strategy, interlace_strategy, limits, budget,
) { Err(error) => return Err(error); Ok(value) => value }

let colour_type = match self.profile {
  PngEncodeProfile::GrayAlpha8 | PngEncodeProfile::GrayAlpha16 => b'\x04'
  // ...
}
let bit_depth = if _png_profile_uses_u16_component_wire(self.profile) { b'\x10' } else { b'\x08' }
return Ok([bit_depth, colour_type, b'\x00', b'\x00',
  if self.interlace_strategy == PngInterlaceStrategy::Adam7 { b'\x01' } else { b'\x00' }
][...])
```

**Apply:** add the same two additive `graya16` interlace-only/all-strategy chunk factories, sending the source to `PngEncodeMachine::new_with_profile` with `GrayAlpha16` and the supplied interlace selector.  Keep the old chunk factories explicitly `None`.  Do not modify `PngEncodeMachine`, chunk acknowledgement, replay, or IHDR serialization: the shared machine already derives Type-4/depth-16/interlace-1 from the profile and selector.

---

### `modules/mb-image/png/encode_test.mbt` (public integration test, transform)

**Analog:** legal U16 fixture and literal-wire assertions at `modules/mb-image/png/encode_test.mbt:180-211` and `1065-1085`; generated eager Adam7 selection at `modules/mb-image/png/encode_test.mbt:1520-1589`.

**Non-symmetric legal U16 fixture pattern** (`encode_test.mbt:180-211`):

```moonbit
view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\x34').unwrap()
view.set_component_byte(0UL, 0UL, 0UL, 1UL, b'\x12').unwrap()
view.set_component_byte(0UL, 0UL, 1UL, 0UL, b'\xc5').unwrap()
view.set_component_byte(0UL, 0UL, 1UL, 1UL, b'\xa7').unwrap()
```

**Format/wire assertion pattern** (`encode_test.mbt:1067-1084`):

```moonbit
inspect(
  bytes[24] == b'\x10' && bytes[25] == b'\x04' && bytes[28] == b'\x00' &&
    bytes[49] == b'\x12' && bytes[50] == b'\x34' &&
    bytes[51] == b'\xa7' && bytes[52] == b'\xc5',
  content="true",
)
```

**Adam7 public-selector pattern** (`encode_test.mbt:1573-1588`):

```moonbit
let encoder = PngEncoder::new_with_all_strategies(
  strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
)
let (_, writer) = png_adam7_encode_with(encoder, image)
let bytes = png_encode_prefix(writer)
inspect(bytes[28] == b'\x01' && bytes[0] == b'\x89', content="true")
```

**Apply:** add a 5x5 legal `ImageFormat::graya16()` fixture with distinct high/low bytes in both components for every pixel. Test the two new eager selectors with Stored/None and assert IHDR depth `16`, colour type `4`, and interlace `1`. Use a stored uncompressed stream/pass-aware assertion to prove all seven nonempty passes emit `Ghi,Glo,Ahi,Alo`, not little-endian storage order or component-swapped lanes. Retain the existing Big-endian descriptor rejection test unchanged (`encode_test.mbt:1087-1111`) and retain the non-interlaced assertion (`bytes[28] == b'\x00'`) for every old GrayAlpha16 factory (`encode_test.mbt:1113-1155`).

---

### `modules/mb-image/png/stream_encode_test.mbt` (public integration test, streaming)

**Analog:** GrayAlpha16 chunk/eager parity at `modules/mb-image/png/stream_encode_test.mbt:1000-1057`, paired with the Adam7 chunk factory/drain helper at `modules/mb-image/png/stream_encode_test.mbt:1816-1856`.

**Factory parity pattern** (`stream_encode_test.mbt:1002-1022`):

```moonbit
let chunked = png_chunk_test_drain_encoder(
  PngChunkEncoder::new_graya16(
    gray_alpha.view(), png_stream_test_limits(), png_stream_test_budget(),
    @error.Diagnostics::new(),
  ).unwrap(),
  [3UL, 7UL],
).unwrap()
inspect(
  chunked == eager && chunked[24] == b'\x10' && chunked[25] == b'\x04' &&
    chunked[28] == b'\x00',
  content="true",
)
```

**Adam7 chunk-construction pattern** (`stream_encode_test.mbt:1818-1855`):

```moonbit
let eager = png_stream_test_eager_with_all_strategies(
  source, strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
)
let one_byte_encoder = PngChunkEncoder::new_with_all_strategies(
  source.view(), strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
  png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
).unwrap()
```

**Apply:** use a fresh legal 5x5 GrayAlpha16 source and call the new chunk interlace-only/all-strategy selectors. Assert its complete output equals the eager selected route and declares Type-4/depth-16/Adam7. Keep this phase to construction/profile selection plus ordinary parity; the zero/one/ragged schedules, accepted-only accounting, lease-tail sentinels, replay mutation, and sticky-terminal matrices are already established patterns but are deliberately Phase 57–58 work.

## Shared Patterns

### Explicit opt-in compatibility

**Sources:** `modules/mb-image/png/png.mbt:224-259`, `modules/mb-image/png/stream_encode.mbt:208-223`  
**Apply to:** all new GrayAlpha16 Adam7 factories

Existing constructors must remain explicit `PngInterlaceStrategy::None`; only the additive interlace selectors can supply `Adam7`. This preserves frozen non-interlaced output byte-for-byte.

### One profile-aware bounded machine

**Sources:** `modules/mb-image/png/stream_encode.mbt:591-645`, `modules/mb-image/png/encode.mbt:1601-1735`  
**Apply to:** factory forwarding and pass-wire correction

All routes preflight, count pass scanlines, choose DEFLATE plans, filter, checksum, and replay through the same profile/interlace-aware machine. Keep the pass cursor scalar and regenerate geometry from `_png_adam7_passes`; no alternate encoder or staging buffer is permitted.

### U16 source admission and wire order

**Sources:** `modules/mb-image/png/encode.mbt:141-160`, `modules/mb-image/png/encode.mbt:416-445`  
**Apply to:** GrayAlpha16 Adam7 only

The legal source has four logical byte channels but is a packed little-endian U16 Gray+Alpha descriptor. PNG wire ordering is separate: map each component to big-endian wire bytes before every Adam7 filter/planner/replay read. Big-endian descriptor construction stays invalid; do not add an encoder-side endian variant.

### IHDR derives from profile plus selector

**Source:** `modules/mb-image/png/stream_encode.mbt:1121-1131`  
**Apply to:** all new Adam7 factories

`GrayAlpha16` already produces `bit_depth=16` and `colour_type=4`; the supplied Adam7 selector produces `interlace=1`. Do not hand-frame IHDR or introduce an Adam7-specific profile.

## Scope and Pitfalls

- The current Adam7 raw helper at `encode.mbt:590-602` calls `source.get_byte` directly. That is correct for RGB8/RGBA8 but bypasses `GrayAlpha16`'s component-wise big-endian wire conversion. Passing the profile to the Adam7 raw/candidate/winner chain is the essential Phase 56 correction.
- Do not widen the model to Big-endian GrayAlpha16. The Phase 53 descriptor contract rejects it before PNG factory admission, and Phase 54 deliberately replaced impossible Big-endian parity tests with descriptor rejection.
- Do not remove the profile guard for Gray8, Gray16, or GrayAlpha8. Phase 56 legalizes only `GrayAlpha16 + Adam7`.
- Do not change existing `graya16` factories to Adam7 or replace frozen `None` output. The new selection surface is opt-in.
- Do not pull in Phase 57's atomic/adaptive/replay matrix or Phase 58's four-target hostile public corpus. Phase 56 should use the existing route and test only the new factory/profile/pass-lane seam.

## No Analog Found

None. The required work is an exact composition of existing `graya16` profile factories and RGB/RGBA Adam7 selection/traversal.

## Metadata

**Analog search scope:** `modules/mb-image/png/{png,encode,stream_encode,structural}.mbt` and PNG eager/stream/white-box tests; archived v0.13 Adam7 and v0.17 GrayAlpha16 phase contexts and summaries.  
**Files scanned:** 13 planning artifacts and 8 PNG implementation/test files.  
**Pattern extraction date:** 2026-07-23
