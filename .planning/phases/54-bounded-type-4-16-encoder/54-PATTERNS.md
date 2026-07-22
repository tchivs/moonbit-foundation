# Phase 54: Bounded Type-4/16 Encoder - Pattern Map

**Mapped:** 2026-07-23  
**Files analyzed:** 5 modified PNG-package files  
**Analogs found:** 5 / 5

## Scope Sources

- [54-CONTEXT.md](54-CONTEXT.md) locks one non-interlaced packed U16 GrayAlpha profile, explicit `graya16` eager/caller-buffered factories, `Ghi,Glo,Ahi,Alo` wire order, and reuse of the single bounded machine.
- Phase 48 is the U16 scalar wire/replay precedent: `.planning/milestones/v0.15-phases/48-bounded-gray16-encoder-path/48-{CONTEXT,RESEARCH,01-PLAN,01-SUMMARY,VERIFICATION}.md`.
- Phase 51 is the Type-4 factory/admission precedent: `.planning/milestones/v0.16-phases/51-bounded-gray-alpha-png-encoding/51-{CONTEXT,RESEARCH,PATTERNS,01-PLAN,02-PLAN,01-SUMMARY,02-SUMMARY,VERIFICATION}.md`.
- `54-RESEARCH.md` confirms the same Type-4/16 profile, four-byte U16 wire, cursor, and replay seams identified here; it is the technical authority alongside the locked context and archived implementation artifacts.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/png.mbt` | public API / config | transform | existing `Gray16` and `GrayAlpha8` factory families in the same file | exact composite |
| `modules/mb-image/png/encode.mbt` | encode service / admission utility | streaming transform | `Gray16` admission + wire reader, with `GrayAlpha8` profile admission | exact composite |
| `modules/mb-image/png/stream_encode.mbt` | streaming state machine / factory | streaming | `Gray16` replay and cursor selection, with `GrayAlpha8` chunk factories/IHDR | exact composite |
| `modules/mb-image/png/encode_test.mbt` | eager integration test | transform | Gray16 U16 wire/Adaptive tests + GrayAlpha8 Type-4 test | exact composite |
| `modules/mb-image/png/stream_encode_test.mbt` | caller-buffered integration test | streaming | Gray16 sticky replay helper + GrayAlpha8 parity/atomicity matrix | exact composite |

## Pattern Assignments

### `modules/mb-image/png/png.mbt` (public API/config, transform)

**Primary analogs:** `Gray16` factories, lines 141-179; `GrayAlpha8` factories, lines 181-219.

**Profile-enum pattern** (lines 104-112): add one private enum case only; do not change defaults or legacy construction.

```moonbit
priv enum PngEncodeProfile {
  LegacyRgbOrRgba
  Gray8
  Gray16
  GrayAlpha8
} derive(Eq)
```

**Factory-family pattern** (GrayAlpha8 lines 181-219; retain the Gray16 `U16` semantics from lines 141-179): create `new_graya16`, compression-only, filter-only, and combined factories. Each convenience factory delegates to combined; the combined value fixes non-interlace and the new profile.

```moonbit
pub fn PngEncoder::new_graya8_with_strategies(
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
) -> PngEncoder {
  {
    strategy,
    filter_strategy,
    interlace_strategy: PngInterlaceStrategy::None,
    profile: PngEncodeProfile::GrayAlpha8,
  }
}
```

**Phase-54 adaptation:** spell the parallel public APIs `new_graya16*`, bind `PngEncodeProfile::GrayAlpha16`, and keep `new()`, `new_gray8*`, `new_gray16*`, `new_graya8*`, and every legacy struct value byte-for-byte/behaviorally untouched.

---

### `modules/mb-image/png/encode.mbt` (encode service/admission utility, streaming transform)

**Primary analogs:** profile admission at lines 54-149; Gray16 scalar wire mapping at lines 405-424; profile-aware atomic preflight at lines 1519-1541 and 1577-1787.

**Fail-closed admission pattern** (GrayAlpha8 lines 130-140) combines with the Gray16 U16 constraint (lines 119-129). The common layout/metadata checks precede this match and must remain before source reads or budget charge.

```moonbit
PngEncodeProfile::GrayAlpha8 => match format.channels() {
  @model.ChannelOrder::GrayAlpha =>
    if metadata.alpha() != Some(@color.AlphaMode::Straight) {
      return Err(_png_encode_capability("straight-alpha-required"))
    } else if format.component() != @model.ComponentType::U8 {
      return Err(_png_encode_capability("component-u8-required"))
    } else {
      2UL
    }
  _ => return Err(_png_encode_capability("graya8-required"))
}
```

**Phase-54 admission adaptation:** add an exhaustive `GrayAlpha16` arm requiring `ChannelOrder::GrayAlpha`, `Some(Straight)`, and `U16`; return **wire bytes per pixel** `4UL`, not semantic component count `2UL`. Use a distinct typed context, conventionally `graya16-required`. The existing pre-match checks already enforce packed rows, builtin encoded sRGB, top-left orientation, empty opaque metadata, and tight `width * channels` row geometry; returning `4UL` makes that row geometry and all resource accounting four-byte-per-pixel.

**U16 wire-reader pattern** (Gray16 lines 405-424): always map component storage to PNG big-endian bytes before filtering, planning, checksumming, or replay.

```moonbit
PngEncodeProfile::Gray16 => {
  let wire_byte = position % 2UL
  let storage_byte = match source.format().endianness() {
    @model.Endianness::Little => 1UL - wire_byte
    @model.Endianness::Big => wire_byte
  }
  source.get_component_byte(position / 2UL, row, 0UL, storage_byte)
}
```

**Phase-54 wire adaptation:** use the same per-component storage-byte reversal, but derive pixel/component/lane from a four-byte position: `pixel = position / 4UL`, `component = (position % 4UL) / 2UL`, `wire_byte = position % 2UL`; call `get_component_byte(pixel, row, component, storage_byte)`. This yields `Ghi,Glo,Ahi,Alo`, never a reversal of the entire four-byte pixel. Keep the `_` branch unchanged for legacy/Gray8/GrayAlpha8.

**Preflight and filter pattern** (lines 1529-1541, 1588-1599, 1655-1739): add a non-interlace rejection arm alongside the three existing explicit profiles; continue threading `profile` and `channels` into every stored/fixed/dynamic/adaptive traversal. The single budget charge stays after source admission, planning, and all width/height/pixel/output/work checks (lines 1760-1787).

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

---

### `modules/mb-image/png/stream_encode.mbt` (streaming state machine/factory, streaming)

**Primary analogs:** GrayAlpha8 caller factories at lines 98-159; Gray16 U16 cursor/replay handling at lines 565-600 and 702-717; profile IHDR emission at lines 1048-1068.

**Caller-factory construction pattern** (GrayAlpha8 lines 141-159): construct no encoder before `PngEncodeMachine::new_with_profile` succeeds, so the constructor preserves pre-exposure atomicity.

```moonbit
let machine = match PngEncodeMachine::new_with_profile(
  source, PngEncodeProfile::GrayAlpha8, strategy,
  filter_strategy, PngInterlaceStrategy::None, limits, budget, diagnostics,
) {
  Err(error) => return Err(error)
  Ok(value) => value
}
Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
```

**Phase-54 adaptation:** mirror all four `new_graya16*` public constructors and bind `GrayAlpha16` here. Do not add an alternate stream driver.

**U16 filtered cursor/replay pattern** (Gray16 lines 565-600): U16 source profiles must select `PngFilteredMatchCursor` even for Stored/None, ensuring Stored, Fixed, Dynamic, filters, Adler/fingerprint, and acknowledgement replay all consume `_png_wire_byte` rather than the legacy raw route.

```moonbit
stored_cursor: if profile == PngEncodeProfile::Gray16 ||
  interlace_strategy == PngInterlaceStrategy::Adam7 ||
  filter_strategy == PngFilterStrategy::Adaptive {
  Some(PngFilteredMatchCursor::new_with_interlace(
    source, facts.row_bytes, facts.channels, filter_strategy, interlace_strategy,
    profile=facts.profile,
  ))
} else { None },
```

**Phase-54 adaptation:** extend all three identical U16 conditions (`stored_cursor` lines 565-571, `fixed_state.filtered_cursor` lines 576-582, and `dynamic_state.filtered_cursor` lines 591-597) to include `GrayAlpha16`. This is the exact seam that prevents a Stored/None or Fixed/Dynamic replay from bypassing the four-byte U16 wire reader.

**Pre-lease replay guard pattern** (lines 302-388 and 702-717): pull checks source revision before writing destination byte zero; Fixed/Dynamic errors become sticky `PngChunkEncoderState::Failed` with zero accepted bytes and unchanged lease.

```moonbit
if self.profile != PngEncodeProfile::Gray16 ||
  self.source.mutation_revision() == self.source_revision { return Ok(()) }
match self.plan {
  PngDeflatePlan::Fixed(_) =>
    Err(_png_encode_machine_state_error("png-encode-fixed-replay-drift"))
  PngDeflatePlan::Dynamic(_) =>
    Err(_png_encode_machine_state_error("png-encode-dynamic-replay-drift"))
  PngDeflatePlan::Stored(_) => Ok(())
}
```

**Phase-54 adaptation:** generalize this guard (and its name if appropriate) to both U16 profiles. Preserve the Fixed/Dynamic error contexts and leave Stored behavior unchanged. The guard executes before `destination.set` in `PngChunkEncoder::pull` (lines 318-327).

**IHDR pattern** (lines 1061-1067): type and depth are profile matches; both must be exhaustive.

```moonbit
let colour_type = match self.profile {
  PngEncodeProfile::Gray8 | PngEncodeProfile::Gray16 => b'\x00'
  PngEncodeProfile::GrayAlpha8 => b'\x04'
  PngEncodeProfile::LegacyRgbOrRgba => if self.channels == 3UL { b'\x02' } else { b'\x06' }
}
let bit_depth = if self.profile == PngEncodeProfile::Gray16 { b'\x10' } else { b'\x08' }
```

**Phase-54 adaptation:** make `GrayAlpha16` emit `colour_type = 0x04`, `bit_depth = 0x10`, compression/filter methods `0`, and the factory-fixed interlace byte `0`. Preserve all existing arms.

---

### `modules/mb-image/png/encode_test.mbt` (eager integration test, transform)

**Primary analogs:** GrayAlpha8 Type-4 fixture/evidence at lines 150-178 and 917-976; Gray16 U16 fixture/wire/Adaptive tests at lines 120-148 and 979-1044.

**Fixture pattern:** build a real `OwnedImage` with `ImageDescriptor`, then set individual bytes using checked component access. Gray16 demonstrates U16 storage versus wire order:

```moonbit
view.set_component_byte(0UL, 0UL, 0UL, 0UL, b'\x34').unwrap()
view.set_component_byte(0UL, 0UL, 0UL, 1UL, b'\x12').unwrap()
```

**Phase-54 fixture adaptation:** use `@model.ImageFormat::graya16()`, `row_bytes/stride = width * 4`, and unequal gray/alpha U16 samples. For a little-endian one-pixel fixture, storage `Glo=34, Ghi=12, Alo=C5, Ahi=A7` must yield raster `00 12 34 A7 C5`; use at least two non-symmetric pairs in the eager fixture.

**Eager assertion pattern** (GrayAlpha8 lines 917-947) validates signature, IHDR, literal Stored scanline bytes, decoder path, typed admission error, writer zero position, and unchanged budget. Combine it with Gray16's Type-0/16 assertion shape (lines 888-915), changing only Type 4 and four wire bytes per pixel.

**Strategy/stride matrix pattern:** copy the complete six-pair loop from Gray16 lines 1011-1044 and the Type-4 framing/decoder loop from GrayAlpha8 lines 950-976. For the graya16 Adaptive raster assertion, use repeated identical gray/alpha pairs so `Sub` visibly compares four-byte pixels (the residual after each first four bytes is zero), not two-byte components.

**Scope boundary:** do not add Phase-55 public vectors, hostile zero/one/ragged schedules, or four-target qualification. Native focused regression coverage belongs here.

---

### `modules/mb-image/png/stream_encode_test.mbt` (caller-buffered integration test, streaming)

**Primary analogs:** GrayAlpha8 eager/chunk parity at lines 824-880; GrayAlpha8 full atomicity helper at lines 2255-2300 and test at 2401-2419; Gray16 U16 sticky replay helper at lines 2522-2589.

**Chunk parity pattern** (GrayAlpha8 lines 847-880): instantiate the compression-only and filter-only convenience forms, then cross all three compression strategies with both filters; drain via real leases and compare every byte to the eager oracle.

```moonbit
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    let eager = png_stream_graya8_eager_with_strategies(gray_alpha, strategy, filter_strategy)
    let chunked = png_chunk_test_drain_encoder(
      PngChunkEncoder::new_graya8_with_strategies(/* ... */).unwrap(), [3UL, 7UL],
    ).unwrap()
    inspect(chunked == eager, content="true")
  }
}
```

**Phase-54 adaptation:** provide `png_stream_graya16_image` and `png_stream_graya16_eager_with_strategies`, then copy this matrix. Assert IHDR depth `0x10`, colour type `0x04`, interlace `0x00`; Stored/None must expose the literal `Ghi,Glo,Ahi,Alo` sequence.

**Atomic-admission pattern** (GrayAlpha8 lines 2255-2300): reuse the public eager and caller-buffered combined factories for all six pairs. Check same typed error, zero eager writer position, unchanged budgets, and every `Z` byte in a caller-owned sentinel lease untouched. Copy the Phase-51 test inputs at lines 2401-2419 for incompatible profile, width, output, work, and budget envelopes; add the private GrayAlpha16 Adam7/preflight rejection specified by Phase 54.

**U16 replay pattern** (Gray16 lines 2522-2589): accept framing bytes, mutate a U16 component using `set_component_byte`, then require immediate zero-byte Fixed/Dynamic failure, unchanged accepted total, all sentinel bytes intact, and identical sticky failure on a later lease. Adapt the fixture/mutated component to GrayAlpha16 and include the required Adaptive case. Keep the expected Fixed/Dynamic BTYPE checks so a fallback route cannot satisfy the test.

## Shared Patterns

### One profile-aware bounded machine

**Sources:** `stream_encode.mbt:527-605`, `encode.mbt:1520-1787`  
**Apply to:** both new eager and caller-buffered Graya16 routes.

All public paths select a profile and enter `PngEncodeMachine::new_with_profile`; do not introduce a row buffer, source copy, target branch, second preflight, or alternate encoder.

### Atomic failure ordering

**Sources:** `encode.mbt:54-149`, `encode.mbt:1588-1599`, `encode.mbt:1760-1787`; `stream_encode.mbt:152-159`  
**Apply to:** malformed/incompatible source, geometry, output, work, budget, and private Adam7 rejection.

Profile admission and limits must finish before the one budget charge and before eager output or a `PngChunkEncoder` exists. Tests observe writer position, budget ledger, and untouched `Z` leases rather than only an error value.

### Wire byte is the only raster source

**Sources:** `encode.mbt:405-465`, `encode.mbt:1655-1739`, `stream_encode.mbt:565-600`  
**Apply to:** Stored, FixedOrStored, DynamicOrFixedOrStored, None, Adaptive, plan fingerprints, checksums, and replay.

For GrayAlpha16, the private scalar reader is responsible for per-component byte order. Its returned `channels = 4UL` is also the filter left-predictor stride and checked raster row width.

### Replay is acknowledgement-safe and terminal-sticky

**Sources:** `stream_encode.mbt:302-388`, `stream_encode.mbt:702-717`; `stream_encode_test.mbt:2522-2589`  
**Apply to:** U16 Fixed/Dynamic caller-buffered Graya16.

Revision validation occurs before `destination.set`; a mutation-induced error writes zero bytes to that lease, preserves accepted total, and repeats exactly on later pulls.

## No Analog Found

None. Phase 54 is intentionally the composition of existing Gray16 U16 behavior and GrayAlpha8 Type-4 behavior in the same five PNG-package files.

## Metadata

**Analog search scope:** `modules/mb-image/png/`, Phase 48/51 archived artifacts, Phase 53 verification/model contract  
**Files scanned:** 5 current PNG implementation/test files, 2 current model/storage contract sources, 19 planning artifacts  
**Pattern extraction date:** 2026-07-23
