# Phase 71: RGBA16 Adam7 PNG Encoding - Pattern Map

**Mapped:** 2026-07-23  
**Files analyzed:** 4 modified files  
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/png.mbt` | provider (public eager factory) | request-response | GrayAlpha16 explicit-interlace factories in the same file | exact |
| `modules/mb-image/png/stream_encode.mbt` | provider (public caller-buffered factory) | streaming | GrayAlpha16 explicit-interlace factories in the same file | exact |
| `modules/mb-image/png/encode_test.mbt` | test | transform | GrayAlpha16 5x5 Adam7 pass-raster and eager-profile tests | exact |
| `modules/mb-image/png/stream_encode_test.mbt` | test | streaming | GrayAlpha16 Adam7 eager/chunk parity and lease-lifecycle harness | exact |

## Pattern Assignments

### `modules/mb-image/png/png.mbt` (provider, request-response)

**Analog:** `PngEncoder::new_graya16_with_interlace_strategy` and `PngEncoder::new_graya16_with_all_strategies`, [png.mbt](../../../modules/mb-image/png/png.mbt:370) lines 370-390.

**Core factory pattern** (lines 370-390):

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

**Apply:** add exactly `new_rgba16_with_interlace_strategy` and `new_rgba16_with_all_strategies` immediately after the existing RGBA16 family. Preserve this delegation and field order; change only `GrayAlpha16` to `Rgba16`.

**Compatibility baseline to preserve:** [png.mbt](../../../modules/mb-image/png/png.mbt:393) lines 393-430. All four existing RGBA16 constructors delegate to `new_rgba16_with_strategies`, whose literal `interlace_strategy: PngInterlaceStrategy::None` is intentional. Do not change it, widen it, or make Adam7 implicit.

**Imports/error handling:** no import block is needed in this package file. This value factory has no fallible branch; eager error propagation remains in `ImageEncoder::encode` at [encode.mbt](../../../modules/mb-image/png/encode.mbt:1828), lines 1837-1843.

---

### `modules/mb-image/png/stream_encode.mbt` (provider, streaming)

**Analog:** `PngChunkEncoder::new_graya16_with_interlace_strategy` and `PngChunkEncoder::new_graya16_with_all_strategies`, [stream_encode.mbt](../../../modules/mb-image/png/stream_encode.mbt:329) lines 329-360.

**Core construction and error pattern** (lines 329-360):

```moonbit
pub fn PngChunkEncoder::new_graya16_with_interlace_strategy(
  source : @storage.ImageView, interlace_strategy : PngInterlaceStrategy,
  limits : @codec.CodecLimits, budget : @budget.Budget,
  diagnostics : @error.Diagnostics,
) -> Result[PngChunkEncoder, @error.CoreError] {
  PngChunkEncoder::new_graya16_with_all_strategies(
    source, PngCompressionStrategy::Stored, PngFilterStrategy::None,
    interlace_strategy, limits, budget, diagnostics,
  )
}

let machine = match PngEncodeMachine::new_with_profile(
  source, PngEncodeProfile::GrayAlpha16, strategy,
  filter_strategy, interlace_strategy, limits, budget, diagnostics,
) {
  Err(error) => return Err(error)
  Ok(value) => value
}
Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
```

**Apply:** add exactly `new_rgba16_with_interlace_strategy` and `new_rgba16_with_all_strategies` next to the existing RGBA16 family at [stream_encode.mbt](../../../modules/mb-image/png/stream_encode.mbt:263). Copy the GrayAlpha16 signatures, default delegation, `match`/`Err` propagation, and active-state initialization exactly; substitute only `PngEncodeProfile::Rgba16`.

**Compatibility baseline to preserve:** [stream_encode.mbt](../../../modules/mb-image/png/stream_encode.mbt:306) lines 306-323 hard-code `PngInterlaceStrategy::None` for the existing RGBA16 all-strategies constructor. It remains the non-interlaced compatibility route.

**Scope caution:** do not add a machine, pass planner, transport state, or new progress accounting. The private shared seam stores the selected profile and interlace strategy after atomic preflight, [stream_encode.mbt](../../../modules/mb-image/png/stream_encode.mbt:728) lines 728-800.

---

### `modules/mb-image/png/encode_test.mbt` (test, transform)

**Analog:** GrayAlpha16 5x5 fixture and independent Adam7 Stored-raster oracle, [encode_test.mbt](../../../modules/mb-image/png/encode_test.mbt:290) lines 290-348; selector/framing test, [encode_test.mbt](../../../modules/mb-image/png/encode_test.mbt:1447) lines 1447-1468; public wire/decode test, [encode_test.mbt](../../../modules/mb-image/png/encode_test.mbt:1557) lines 1557-1574.

**Independent seven-pass expected-data pattern** (lines 329-348):

```moonbit
let expected : Array[Byte] = []
for pass in [
  (0UL, 0UL, 8UL, 8UL), (4UL, 0UL, 8UL, 8UL), (0UL, 4UL, 4UL, 8UL),
  (2UL, 0UL, 4UL, 4UL), (0UL, 2UL, 2UL, 4UL), (1UL, 0UL, 2UL, 2UL),
  (0UL, 1UL, 1UL, 2UL),
] {
  let (start_x, start_y, stride_x, stride_y) = pass
  for y = start_y; y < 5UL; y = y + stride_y {
    expected.push(b'\x00')
    for x = start_x; x < 5UL; x = x + stride_x { /* coordinate-derived wire bytes */ }
  }
}
```

**Apply:** add an RGBA16-specific 5x5 little-endian packed fixture and independent expected raster. Keep the same seven literal tuples, add one filter-None tag for every pass row, and emit each selected pixel as `Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo`. The fixture must vary coordinate, component, and both storage lanes; assert the complete 211-byte uncompressed raster rather than relying only on encoder/chunk equality.

**Explicit fidelity oracle:** copy the direct `PngDecoder::decode_rgba16` + `get_component_byte` approach from [encode_test.mbt](../../../modules/mb-image/png/encode_test.mbt:1343), lines 1343-1388. Extend it from the current 2x1 non-interlaced vector to every `(x, y, component, storage-lane)` in the 5x5 Adam7 source.

**Framing/strategy pattern:** copy the GrayAlpha16 selector loop and IHDR assertions from [encode_test.mbt](../../../modules/mb-image/png/encode_test.mbt:1648) lines 1648-1721. For RGBA16 assert `IHDR[24] == 0x10`, `IHDR[25] == 0x06`, and `IHDR[28] == 0x01` for all three compression strategies crossed with `None` and `Adaptive` filters. Also exercise both new eager selector shapes under Stored/None.

**Scope caution:** retain the existing non-interlaced factory regression at [encode_test.mbt](../../../modules/mb-image/png/encode_test.mbt:1391) lines 1391-1445 unchanged (`IHDR[28] == 0x00`). Do not change generic constructors, colour gates, or source-layout tests.

---

### `modules/mb-image/png/stream_encode_test.mbt` (test, streaming)

**Analog:** GrayAlpha16 Adam7 fixture, eager identity helper, and caller-lease drain harness: [stream_encode_test.mbt](../../../modules/mb-image/png/stream_encode_test.mbt:347) lines 347-380, [stream_encode_test.mbt](../../../modules/mb-image/png/stream_encode_test.mbt:1109) lines 1109-1149, and [stream_encode_test.mbt](../../../modules/mb-image/png/stream_encode_test.mbt:4046) lines 4046-4144.

**Fresh eager/chunk parity and lifecycle pattern** (lines 4048-4106):

```moonbit
let eager = png_stream_graya16_eager_with_all_strategies(
  image, strategy, filter_strategy, PngInterlaceStrategy::Adam7,
)
let encoder = PngChunkEncoder::new_graya16_with_all_strategies(
  image.view(), strategy, filter_strategy, PngInterlaceStrategy::Adam7,
  png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
).unwrap()
// zero-capacity lease: NeedOutput, written/total_written == 0, sentinel unchanged
// scheduled leases: append only acknowledged prefix; verify tail sentinel
// Finished: aggregate == fresh eager, then a later pull is zero-write Finished
```

**Apply:** introduce RGBA16 equivalents of the fixture, eager helper, and drain helper. For each of Stored, FixedOrStored, and DynamicOrFixedOrStored crossed with None and Adaptive, create a fresh eager byte oracle and a fresh chunk encoder, then run `[0UL, 1UL]`, `[1UL]`, and `[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]` schedules exactly as in lines 4122-4144.

**Selector coverage:** use the narrow and all-strategy factory identity shapes from the GrayAlpha16 family rather than testing only one route. The adjacent RGBA16 non-interlaced factory test at [stream_encode_test.mbt](../../../modules/mb-image/png/stream_encode_test.mbt:1502) lines 1502-1552 is the compatibility baseline; its `stored[28] == 0x00` assertion must remain.

**Atomic admission pattern:** the combined eager/chunk rejection helper at [stream_encode_test.mbt](../../../modules/mb-image/png/stream_encode_test.mbt:3120) lines 3120-3158 and its Adam7 matrix at lines 3339-3363 establish the required no-output/no-lease/no-budget-drift checks. Adapt this only as RGBA16-specific selection evidence if needed; do not create a separate encoder lifecycle test mechanism.

## Shared Patterns

### Single profile-aware encoder machine

**Source:** [stream_encode.mbt](../../../modules/mb-image/png/stream_encode.mbt:728), lines 728-800; [encode.mbt](../../../modules/mb-image/png/encode.mbt:1828), lines 1828-1865.  
**Apply to:** both new factory families.

```moonbit
let facts = match _png_encode_preflight_with_interlace_profile(
  source, profile, strategy, filter_strategy, interlace_strategy, limits, budget,
) { Err(error) => return Err(error); Ok(value) => value }
// Later cursors are created with profile=facts.profile and interlace_strategy.
```

Forward caller-selected `PngInterlaceStrategy` and `PngEncodeProfile::Rgba16` into this seam. It owns atomic admission, selected strategy state, cursor creation, and later progress/terminal behavior.

### Adam7 traversal and U16 wire order

**Sources:** [structural.mbt](../../../modules/mb-image/png/structural.mbt:588), lines 588-603; [encode.mbt](../../../modules/mb-image/png/encode.mbt:438), lines 438-458; [encode.mbt](../../../modules/mb-image/png/encode.mbt:569), lines 569-616.  
**Apply to:** the new selectors and the independent test oracle only.

```moonbit
PngEncodeProfile::Gray16 | PngEncodeProfile::GrayAlpha16 | PngEncodeProfile::Rgba16 => {
  let component = (position % channels) / 2UL
  let wire_byte = position % 2UL
  let storage_byte = match source.format().endianness() {
    @model.Endianness::Little => 1UL - wire_byte
    @model.Endianness::Big => wire_byte
  }
  source.get_component_byte(position / channels, row, component, storage_byte)
}
```

No Phase 71 production change belongs in these private traversal/wire helpers. The tests must independently enumerate the seven standard pass tuples so they can detect a shared traversal regression.

### Error, admission, and lease semantics

**Source:** [stream_encode.mbt](../../../modules/mb-image/png/stream_encode.mbt:353), lines 353-360; [stream_encode_test.mbt](../../../modules/mb-image/png/stream_encode_test.mbt:4061), lines 4061-4106.  
**Apply to:** `PngChunkEncoder` selectors and their tests.

Return `Err(error)` unchanged from machine construction. Do not catch, wrap, or prewrite output. Tests must retain accepted-only `total_written`, untouched lease tails, and a later zero-write `Finished` pull.

## Scope Cautions

- Add only the four locked public APIs and RGBA16-specific evidence in the four files above.
- Preserve existing RGB8/RGBA8, Gray/GrayAlpha, generic, and all non-interlaced RGBA16 constructors and their `None` selections.
- Do not modify `encode.mbt`, `structural.mbt`, the pass planner, filtering, compression, source layout, colour identity gates, FFI, or qualification/release workflows.
- Phase 72 owns broad four-target qualification, frozen legacy sweeps, and an independent hostile matrix; this phase reuses the existing public GrayAlpha16 schedule harness.

## No Analog Found

None. Every required production and test change has an exact GrayAlpha16 Adam7 analog in the same PNG package.

## Metadata

**Analog search scope:** `modules/mb-image/png/{png,stream_encode,encode,structural,encode_test,stream_encode_test}.mbt`  
**Files scanned:** 6 source/test files plus Phase 71 context and research artifacts  
**Pattern extraction date:** 2026-07-23
