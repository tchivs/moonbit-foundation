# Phase 59: GrayAlpha8 Adam7 Factory and Pass Profile - Pattern Map

**Mapped:** 2026-07-23  
**Files analyzed:** 5 modified files  
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/png.mbt` | public encoder factory | batch transform | GrayAlpha16 Adam7 eager factories, lines 262-285 | exact |
| `modules/mb-image/png/stream_encode.mbt` | public caller-buffered factory | streaming | GrayAlpha16 Adam7 chunk factories, lines 226-260 | exact |
| `modules/mb-image/png/encode.mbt` | profile admission / scalar raster producer | bounded transform | profile-aware Adam7 preflight, lines 1543-1565 | exact seam |
| `modules/mb-image/png/encode_test.mbt` | public eager regression test | batch transform | GrayAlpha16 Adam7 pass-profile tests, lines 1192-1222 and 1315-1390 | exact |
| `modules/mb-image/png/stream_encode_test.mbt` | public chunk regression test | streaming | GrayAlpha16 Adam7 chunk-parity test, lines 1103-1140 | exact |

## Pattern Assignments

### `modules/mb-image/png/png.mbt` (public eager factory, batch transform)

**Analog:** `modules/mb-image/png/png.mbt:262-285` (`GrayAlpha16` Adam7 selectors).

Add two *additive* `GrayAlpha8` selectors immediately after the existing non-interlaced `new_graya8_with_strategies` route (lines 182-220). Do not change those legacy constructors; they must continue to hard-code `PngInterlaceStrategy::None`.

```moonbit
pub fn PngEncoder::new_graya16_with_interlace_strategy(
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  PngEncoder::new_graya16_with_all_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None, interlace_strategy,
  )
}

pub fn PngEncoder::new_graya16_with_all_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> PngEncoder {
  { strategy, filter_strategy, interlace_strategy, profile: PngEncodeProfile::GrayAlpha16 }
}
```

Copy the shape exactly, substituting only `graya8` / `GrayAlpha8`. This is a selector, not an alternate encoder; it only configures the existing `PngEncoder` record.

### `modules/mb-image/png/stream_encode.mbt` (public caller-buffered factory, streaming)

**Analog:** `modules/mb-image/png/stream_encode.mbt:226-260` (`GrayAlpha16` Adam7 selectors).

Add the matching narrow and all-strategies `GrayAlpha8` factories after `new_graya8_with_strategies` (lines 141-160). The narrow factory forwards Stored/None; the all-strategies factory constructs the one profile-aware machine and returns the ordinary active state.

```moonbit
pub fn PngChunkEncoder::new_graya16_with_interlace_strategy(
  source : @storage.ImageView,
  interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits,
  budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  PngChunkEncoder::new_graya16_with_all_strategies(
    source, PngCompressionStrategy::Stored, PngFilterStrategy::None,
    interlace_strategy, limits, budget, diagnostics,
  )
}

pub fn PngChunkEncoder::new_graya16_with_all_strategies(...) -> Result[PngChunkEncoder, @error.CoreError] {
  let machine = match PngEncodeMachine::new_with_profile(
    source, PngEncodeProfile::GrayAlpha16, strategy,
    filter_strategy, interlace_strategy, limits, budget, diagnostics,
  ) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}
```

Do not add staging, a second cursor, or a separate admission branch. The preflight and pull protocol are already behind `PngEncodeMachine::new_with_profile`.

### `modules/mb-image/png/encode.mbt` (profile admission / scalar raster producer, bounded transform)

**Analog:** `modules/mb-image/png/encode.mbt:1543-1565` (the sole profile-aware preflight gate).

The Phase 59 production change is intentionally one deletion: remove the `GrayAlpha8` non-interlaced rejection only. Retain Gray8 and Gray16 rejections. Once that guard is gone, the existing profile-aware ledger below it is the single path for all U8 Gray+Alpha8 Adam7 selectors.

```moonbit
match profile {
  PngEncodeProfile::Gray8 if interlace_strategy != PngInterlaceStrategy::None =>
    return Err(_png_encode_capability("gray8-noninterlaced-required"))
  PngEncodeProfile::Gray16 if interlace_strategy != PngInterlaceStrategy::None =>
    return Err(_png_encode_capability("gray16-noninterlaced-required"))
  PngEncodeProfile::GrayAlpha8 if interlace_strategy != PngInterlaceStrategy::None =>
    return Err(_png_encode_capability("graya8-noninterlaced-required"))
  _ => ()
}
```

**Existing shared pass/profile behavior that must remain untouched:**

- `encode.mbt:130-139` admits only `ChannelOrder::GrayAlpha`, straight alpha, and U8, then fixes `channels = 2UL`.
- `encode.mbt:556-603` derives all seven-pass positions from `_png_adam7_passes(..., channels, 8)` and reads samples through `_png_wire_byte`; U8 falls through to `source.get_byte(position / channels, row, position % channels)` at lines 434-445. Thus the existing scalar order is exactly `G,A` for GrayAlpha8.
- `encode.mbt:644-774` resolves Adaptive filters per local Adam7 row and never crosses pass boundaries.
- `encode.mbt:1601-1650` is the sole bounded preflight ledger; for Adam7 it sums the same pass geometry before any output state exists.

### `modules/mb-image/png/encode_test.mbt` (public eager regression test, batch transform)

**Analog:** `modules/mb-image/png/encode_test.mbt:1192-1222` and `1315-1390`.

Create a 5x5 legal `ImageFormat::graya8()` fixture and independent expected-pass helper by copying the structure at lines 217-273 but emitting two bytes per pixel in source `G,A` order. The test must enumerate seven geometry tuples independently of the encoder:

```moonbit
for pass in [
  (0UL, 0UL, 8UL, 8UL), (4UL, 0UL, 8UL, 8UL), (0UL, 4UL, 4UL, 8UL),
  (2UL, 0UL, 4UL, 4UL), (0UL, 2UL, 2UL, 4UL), (1UL, 0UL, 2UL, 2UL),
  (0UL, 1UL, 1UL, 2UL),
] { ... }
```

Copy the dual-selector parity assertion at lines 1195-1222, changing IHDR checks to bit depth `0x08`, colour type `0x04`, and interlace `0x01`; assert the Stored/None IDAT pass payload equals the independent `G,A` expected raster. Then use the helper pattern at lines 1317-1390 to cover all six compression/filter pairs, asserting Type-4/8 Adam7 framing. Keep the existing noninterlaced U8 factory test at lines 1393-1420 frozen and add an explicit `interlace_method == 0` assertion for legacy routes if the new coverage needs to make that freeze visible.

### `modules/mb-image/png/stream_encode_test.mbt` (public chunk regression test, streaming)

**Analog:** `modules/mb-image/png/stream_encode_test.mbt:1103-1140`.

Use the same 5x5 GrayAlpha8 Adam7 fixture and copy the narrow-versus-all-strategies construction. Drain through `png_chunk_test_drain_encoder` with the ordinary `[3UL, 7UL]` schedule, then assert both bytes equal their independently constructed eager counterparts and carry Type-4/8 Adam7 IHDR bytes.

```moonbit
let narrow = png_chunk_test_drain_encoder(
  PngChunkEncoder::new_graya16_with_interlace_strategy(
    narrow_source.view(), PngInterlaceStrategy::Adam7,
    png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
  ).unwrap(),
  [3UL, 7UL],
).unwrap()
```

Substitute `graya8` only. Phase 59 should stop at factory/profile parity. Do **not** copy the replay-mutation matrix at lines 3155+ (Phase 60) or the hostile zero/one/ragged schedule matrix at lines 3515-3613 (Phase 61).

## Shared Patterns

### Explicit opt-in preserves legacy output

**Sources:** `png.mbt:208-220`, `png.mbt:262-285`, `stream_encode.mbt:141-160`, `stream_encode.mbt:226-260`.

Existing factory names with `with_strategies` remain non-interlaced. Only the new `with_interlace_strategy` / `with_all_strategies` APIs accept Adam7. This prevents an additive capability from changing frozen method-0 output.

### One bounded, profile-aware encoder machine

**Sources:** `encode.mbt:1543-1565`, `encode.mbt:1601-1650`, `stream_encode.mbt:152-160`.

Admission runs before any planning/output state, and both eager and caller-buffered APIs enter the same `PngEncodeMachine::new_with_profile` construction. Phase 59 must not fork this path.

### Test oracle discipline

**Sources:** `encode_test.mbt:250-273`, `encode_test.mbt:1195-1222`.

The expected Adam7 payload is formed by independent pass coordinates and literal sample bytes, not by encoder helpers. This catches cursor-order regressions and demonstrates `G,A` PNG order directly.

## No Analog Found

None. GrayAlpha16 Adam7 supplies exact public and streaming analogs; the GrayAlpha8 non-interlaced factories supply the exact profile substitution points.

## Metadata

**Analog search scope:** `modules/mb-image/png/`  
**Files scanned:** 5  
**Pattern extraction date:** 2026-07-23
