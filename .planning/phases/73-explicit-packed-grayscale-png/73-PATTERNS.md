# Phase 73: Explicit Packed Grayscale PNG - Pattern Map

**Mapped:** 2026-07-23
**Files analyzed:** 3 planned modifications; 3 boundary/reference files
**Analogs found:** 3 / 3 planned files

## Scope Lock

This phase is strictly the eager `PngEncoder` path for PNG colour type 0 at bit
depths 1, 2, and 4. Keep the canonical source model as packed `Gray/U8` bytes;
pack only the PNG wire rows. Reuse the current bounded machine and its atomic
admission. Do not modify `stream_encode.mbt`, add caller-buffered factories,
Adam7, palette/index support, a bit-packed image model, implicit sample
conversion, or generic/API strategy surface.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/png.mbt` | public API / config | request-response | `PngEncoder::new_gray8` and `new_gray16` | exact |
| `modules/mb-image/png/encode.mbt` | encoder service / bounded row provider | streaming transform | `Gray8`/`Gray16` profile admission and filter-None row provider | role-match; low-bit packing is new |
| `modules/mb-image/png/encode_test.mbt` | black-box test / wire oracle | request-response + transform | Gray16 public Stored wire parser and Gray8 atomic admission test | exact |

## Pattern Assignments

### `modules/mb-image/png/png.mbt` (public API/config, request-response)

**Analog:** `modules/mb-image/png/png.mbt:182-258,461-490`

Add private profile variants and only three eager public constructors, parallel
to `Gray8` / `Gray16`. Each constructor must freeze `Stored`, filter `None`,
and non-interlace; it must not expose `*_with_compression_strategy`,
`*_with_filter_strategy`, `*_with_strategies`, or caller-buffered counterparts.

**Profile and selector pattern** (`png.mbt:185-192,213-227`):

```moonbit
priv enum PngEncodeProfile {
  LegacyRgbOrRgba
  Gray8
  Gray16
  // Add Gray1, Gray2, Gray4 beside these explicit grayscale profiles.
}

pub fn PngEncoder::new_gray8() -> PngEncoder {
  PngEncoder::new_gray8_with_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
  )
}
```

**Non-interlaced profile literal pattern** (`png.mbt:249-258,481-490`):

```moonbit
{
  strategy,
  filter_strategy,
  interlace_strategy: PngInterlaceStrategy::None,
  profile: PngEncodeProfile::Gray16,
}
```

For Phase 73, use this structure internally to produce the new eager values,
but retain no strategy-taking public selector. Existing generic and Gray8
constructors must remain byte-identical.

### `modules/mb-image/png/encode.mbt` (encoder service / bounded row provider, streaming transform)

**Primary analogs:**

- Profile admission: `encode.mbt:54-173` (`_png_encode_source`)
- U16/byte row-provider split: `encode.mbt:431-476`
- Non-interlace gate and atomic profile preflight: `encode.mbt:1556-1576,1613-1822`
- IHDR emission: `stream_encode.mbt:1288-1308` (reference only; do not modify in Phase 73 unless the existing machine implementation is located there)
- Inverse low-bit layout semantics: `raster_decode.mbt:652-675` (reference only)

**Canonical source admission pattern** (`encode.mbt:71-85,108-118`):

```moonbit
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

PngEncodeProfile::Gray8 => match format.channels() {
  @model.ChannelOrder::Gray =>
    if format.component() != @model.ComponentType::U8 {
      return Err(_png_encode_capability("component-u8-required"))
    } else if metadata.alpha() is Some(_) {
      return Err(_png_encode_capability("gray-alpha-unsupported"))
    } else {
      1UL
    }
  _ => return Err(_png_encode_capability("gray8-required"))
}
```

Apply the same `Gray/U8`, packed, opaque, builtin encoded-sRGB, top-left, and
tightly packed-row checks for Gray1/2/4. Before `_png_encode_source` reports
success, validate every sample against the exact legal level set for its
selected profile. That validation is an admission check: on failure return a
capability error before preflight charges `budget` or creates output.

`model/descriptor.mbt:19-65` establishes that the existing model represents
this source as `ComponentType::U8 + ChannelOrder::Gray + PlaneLayout::Packed`;
do not add a new descriptor/component representation.

**Existing scalar row-provider pattern** (`encode.mbt:440-476`):

```moonbit
fn _png_wire_byte(...) -> Result[Byte, @error.CoreError] {
  match profile {
    PngEncodeProfile::Gray16 | PngEncodeProfile::GrayAlpha16 | PngEncodeProfile::Rgba16 => {
      // Map storage endian lanes to PNG big-endian component order.
      ...
    }
    _ => source.get_byte(position / channels, row, position % channels)
  }
}

fn _png_fixed_scanline_byte(...) -> Result[Byte, @error.CoreError] {
  let row_width = row_bytes + 1UL
  let in_row = index % row_width
  if in_row == 0UL {
    Ok(b'\x00')
  } else {
    let sample = in_row - 1UL
    _png_wire_byte(source, profile, index / row_width, channels, sample)
  }
}
```

Extend this single row-provider seam rather than materialising a packed row.
For a source `x`, derive `raw` only after exact-level validation; write it at
`start = x * bit_depth`, `byte = start / 8`,
`shift = 8 - bit_depth - (start % 8)`, with MSB-first packing. Return zero for
unwritten tail bits by constructing every output byte from its in-range
samples, never by reusing a source byte.

**Low-bit inverse to mirror** (`raster_decode.mbt:660-666`):

```moonbit
let start = x * bit_depth.to_uint64()
let byte = rows.current.view().get(start / 8UL).unwrap().to_int()
let shift = 8 - bit_depth - (start % 8UL).to_int()
let raw = (byte >> shift) & mask
let expanded = _png_scale_grayscale_sample(raw, bit_depth).to_byte()
```

Encoding is the inverse: map exact U8 levels to `raw` (1-bit: 0/1; 2-bit:
0..3; 4-bit: 0..15), shift into the selected MSB-first lane, OR it into a
fresh zero byte. Do not call the decoder scaler as an encoder conversion and
do not scale, quantize, or dither.

**Atomic preflight/budget pattern** (`encode.mbt:1623-1642,1795-1822`):

```moonbit
let channels = match _png_encode_source(source, profile) {
  Err(error) => return Err(error)
  Ok(value) => value
}
// Compute layout and plan every candidate before the one charge.
...
match budget.charge(@budget.ResourceCharge::new(
  bytes=0UL, allocations=0UL, allocation_size=0UL, width=source.width(),
  height=source.height(), pixels=0UL, work=selected_work,
)) {
  Err(error) => return Err(error)
  Ok(_) => ()
}
```

For 1/2/4-bit profiles, row bytes must be the checked ceiling of
`width * bit_depth / 8` and scanline bytes are `row_bytes + 1`; do not use the
current scalar `width * channels` calculation unchanged. Keep
`PngInterlaceStrategy::None` as the only admitted route. The existing profile
gate (`encode.mbt:1566-1571`) is the pattern for rejecting any non-None route.

**IHDR pattern** (`stream_encode.mbt:1301-1308`, reference only):

```moonbit
let colour_type = match self.profile {
  PngEncodeProfile::Gray8 | PngEncodeProfile::Gray16 => b'\x00'
  ...
}
let bit_depth = if _png_profile_uses_u16_component_wire(self.profile) { b'\x10' } else { b'\x08' }
return Ok([bit_depth, colour_type, b'\x00', b'\x00',
  if self.interlace_strategy == PngInterlaceStrategy::Adam7 { b'\x01' } else { b'\x00' }][...])
```

Extend the type-0 profile match and select `0x01`, `0x02`, or `0x04` for the
new profiles. The final IHDR byte must remain `0x00`. Do not introduce Adam7
or alter existing type-0 8/16-bit results.

### `modules/mb-image/png/encode_test.mbt` (black-box test / wire oracle, request-response + transform)

**Primary analogs:**

- Source fixture builder: `encode_test.mbt:66-103`
- Atomic eager rejection: `encode_test.mbt:1302-1352`
- Stored IDAT structural parser: `encode_test.mbt:591-646`
- Public Gray16 wire fidelity: `encode_test.mbt:1959-1999`

**Fixture-builder pattern** (`encode_test.mbt:71-103`):

```moonbit
@model.ImageFormat::new(
  @model.ComponentType::U8, @model.ChannelOrder::Gray,
  @model.PlaneLayout::Packed, @model.Endianness::Little,
).unwrap()
...
view.set_byte(x, y, 0UL, pixels[(y * width + x).to_int()]).unwrap()
```

Reuse this exact canonical Gray/U8 fixture shape for legal-level and
out-of-level samples. It verifies that Phase 73 packs wire data only and adds
no bit-packed source model.

**Independent Stored wire-parser pattern** (`encode_test.mbt:591-646`):

```moonbit
// Walk PNG chunks, collect IDAT bytes, and assert Stored-zlib framing.
if idat[0] != b'\x78' || idat[1] != b'\x01' || idat[2] != b'\x01' ||
  idat[3] != scanline_length.to_byte() ||
  idat[4] != (scanline_length >> 8).to_byte() {
  abort("png gray16 public stored block")
}
for index = 0; index < expected_scanline_length; index = index + 1 {
  scanlines.push(idat[7 + index])
}
```

Create a Phase-73-named bounded parser/helper rather than reusing its
Gray16-specific name. Its caller supplies the known scanline length, and the
test authors explicit expected filtered rows. Test every bit depth with odd
widths that leave tail lanes (Gray1: widths not divisible by 8; Gray2: not by
4; Gray4: odd), including a row whose unused final bits must be zero.

**Atomic rejection assertion pattern** (`encode_test.mbt:1313-1322`):

```moonbit
let budget = png_encode_budget()
let before = budget.remaining()
let rejected = @io.MemoryWriter::new(...).unwrap()
let error = @codec.ImageEncoder::encode(...).unwrap_err()
inspect(rejected.position() == 0UL &&
  png_adam7_same_remaining(before, budget.remaining()), content="true")
```

For each profile, test one invalid U8 level and assert no writer position and
no caller-budget field changes. Separately assert IHDR `[24]=depth`,
`[25]=0`, and `[28]=0`, plus the independent Stored scanline oracle. Do not
add caller-buffered lease tests or Adam7/strategy-matrix tests in this phase.

## Shared Patterns

### Profile-aware bounded machine

**Source:** `modules/mb-image/png/stream_encode.mbt:765-845`
**Apply to:** `encode.mbt` additions and existing eager encode call path.

`PngEncodeMachine::new_with_profile` runs preflight first, stores preflight
facts, and returns only a fully admitted machine. Phase 73 must keep this one
machine and one output traversal; it must not stage a packed raster or create a
second encoder.

### Eager-only output path

**Source:** `modules/mb-image/png/encode.mbt:1826-1866`
**Apply to:** public selectors through the existing `PngEncoder` trait impl.

The trait implementation constructs the profile-aware machine before the first
writer call, then presents and acknowledges bytes one at a time. New selectors
must flow through it unchanged.

### PNG bit ordering

**Source:** `modules/mb-image/png/raster_decode.mbt:652-675`
**Apply to:** packed low-bit row provider in `encode.mbt`.

The authoritative decoder uses `shift = 8 - bit_depth - (start % 8)`;
therefore the encoder must use the same lane convention in reverse. This is
the only low-bit implementation analog; it is decoder code and is not a Phase
73 modification target.

## Boundary Files — Do Not Modify

| File | Why it was inspected | Phase 73 direction |
|---|---|---|
| `modules/mb-image/png/stream_encode.mbt` | Owns caller-buffered constructors and machine byte/IHDR emission | No new `PngChunkEncoder` factories or hostile-lease coverage. Only touch if the existing single IHDR switch physically requires the new private profiles; otherwise leave it unchanged. |
| `modules/mb-image/png/raster_decode.mbt` | Defines authoritative low-bit MSB-first unpacking | Read-only inverse reference; no decode expansion. |
| `modules/mb-image/model/descriptor.mbt` | Defines `Gray/U8/Packed` canonical model | Read-only contract; no bit-packed model/API. |

## No Direct Encoder Analog

| Concern | Closest reference | Planner guidance |
|---|---|---|
| Low-bit Gray U8-to-PNG packing | `raster_decode.mbt:652-675` | Implement the inverse at the shared row-provider seam; preserve exact-level admission and zero unused tail bits. There is no prior encoder-side low-bit packer to copy. |

## Metadata

**Analog search scope:** `modules/mb-image/png/`, `modules/mb-image/model/`
**Files scanned:** 7 source/test files plus Phase 73 context
**Pattern extraction date:** 2026-07-23
