# Phase 85: Indexed Compression API and Fixed Wire Contract - Pattern Map

**Mapped:** 2026-07-24  
**Files analyzed:** 6 expected modifications  
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/encode.mbt` | service / public eager façade | transform | Generic `FixedOrStored` preflight in the same file | exact role, adapted source type |
| `modules/mb-image/png/stream_encode.mbt` | service / caller-buffered façade and machine | streaming | Generic strategy-aware `PngEncodeMachine::new_with_profile` | exact role, adapted source type |
| `modules/mb-image/png/encode_test.mbt` | public API test | request-response / transform | Generic Fixed-or-Stored eager selection and work-admission tests | exact test role |
| `modules/mb-image/png/stream_encode_test.mbt` | public streaming API test | streaming | Generic eager/chunk parity and existing indexed eager/chunk tracer helpers | exact test role |
| `modules/mb-image/png/encode_wbtest.mbt` | white-box planning test | transform | Generic Fixed-or-Stored preflight plan/work assertions | exact test role |
| `modules/mb-image/png/stream_encode_wbtest.mbt` | white-box acknowledged-replay test | streaming | Fixed preview/acknowledgement and replay-integrity tests | exact test role |

No `png.mbt` change is implied: `PngCompressionStrategy::{Stored, FixedOrStored, DynamicOrFixedOrStored}` already exists at `modules/mb-image/png/png.mbt:155-159`. The four additive APIs belong beside the indexed eager/chunk façades, rather than in a new indexed-only strategy type.

## Pattern Assignments

### `modules/mb-image/png/encode.mbt` (service, transform)

**Primary analogs:** indexed Stored preflight at `modules/mb-image/png/encode.mbt:2096-2215`; generic Fixed-or-Stored selection at `modules/mb-image/png/encode.mbt:1925-1956`; eager indexed forwards at `modules/mb-image/png/encode.mbt:2278-2393`.

**Error-construction pattern** (`encode.mbt:2-18`): use the existing typed capability constructor and a frozen context, not a local error object.

```moonbit
fn _png_encode_capability(context : String) -> @error.CoreError {
  @codec.capability_unavailable("png-encode", context)
}
```

Add the indexed-only strategy gate before indexed preflight, budget charge, and machine construction. The Dynamic arm must return the stable capability error directly; do not delegate it to generic planning.

**Legacy-forward pattern** (`encode.mbt:2278-2289`, selected): existing default APIs are one-hop forwards. Convert these to literal `Stored` forwards into new non-interlaced compression-selector APIs; leave the interlace selector route as the Stored/None compatibility route.

```moonbit
pub fn PngEncoder::encode_indexed8(...) -> Result[@codec.EncodeResult, @error.CoreError] {
  PngEncoder::encode_indexed8_with_interlace_strategy(
    _self, source, PngInterlaceStrategy::None, writer, limits, budget, diagnostics,
  )
}
```

**Generic selector pattern** (`encode.mbt:1925-1956`): retain the exact tie rule, but replace the generic non-palette total with indexed `PngFrameFacts` totals for both candidates.

```moonbit
PngCompressionStrategy::FixedOrStored => {
  let pass = match _png_filtered_match_traverse_with_interlace(...) { ... }
  let fixed = match _png_fixed_plan_with_interlace(...) { ... }
  if fixed.total_length <= stored.total_length {
    PngDeflatePlan::Fixed(fixed)
  } else {
    PngDeflatePlan::Stored(stored)
  }
}
```

For indexed code, construct `stored_frame` and `fixed_frame` with `_png_frame_facts(source.palette_length(), trns_length, candidate_idat_length)`, then compare `fixed_frame.total_length <= stored_frame.total_length`. Do not copy generic `fixed.total_length`: that value currently comes from the non-palette `+57` arithmetic at `encode.mbt:1719-1737`.

**Frame-facts pattern** (`encode.mbt:344-395`, `2175-2180`): preserve its checked additions and canonical tRNS length scan. It is the sole source of PLTE/tRNS/IDAT/IEND offsets and exact Type-3 total length.

```moonbit
let frame = match _png_frame_facts(
  source.palette_length(), trns_length, idat_length,
) {
  Err(error) => return Err(error)
  Ok(value) => value
}
```

**Bounded raw/match producer pattern** (`encode.mbt:1151-1269`, `1649-1737`): generalize `PngFilteredMatchCursor`, not the matcher. It owns logical position, a 262-byte ring, and lazy production; `ensure` may probe but only `consume` commits. Adapt its producer field to expose the immutable indexed filter-None stream, then route Stored traversal, Fixed planning, and Fixed replay through that single abstraction.

```moonbit
priv struct PngFilteredMatchCursor {
  producer : PngFilteredCursor
  logical_position : UInt64
  produced_exclusive : UInt64
  retained_start : UInt64
  window : Array[Byte]
}
// ... window: Array::make(262, b'\x00')
```

The existing matcher guarantees distances 1--4 and bounded 258-byte matches at `encode.mbt:1272-1304`; retain it and do not make an indexed-only matcher or image-sized byte/token staging buffer.

### `modules/mb-image/png/stream_encode.mbt` (service, streaming)

**Primary analogs:** generic configured construction at `modules/mb-image/png/stream_encode.mbt:891-973`; existing indexed façade constructors at `modules/mb-image/png/stream_encode.mbt:21-84`; existing indexed machine construction at `modules/mb-image/png/stream_encode.mbt:978-1011`.

**Chunk façade pattern** (`stream_encode.mbt:23-49`): selectors construct a machine before wrapping `Active(machine)`, so an error exposes no lease/state.

```moonbit
let machine = match PngEncodeMachine::new_with_indexed_profile(
  source, PngIndexedWireProfile::Eight, interlace_strategy, limits, budget, diagnostics,
) {
  Err(error) => return Err(error)
  Ok(value) => value
}
Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
```

Add `new_indexed8_with_compression_strategy` and `new_indexed_with_compression_strategy` beside these constructors. Make legacy `new_indexed8`/`new_indexed` literal `Stored` forwards to them. Do not add an interlace-plus-compression factory in this phase.

**Single-machine initialization pattern** (`stream_encode.mbt:978-1011`): extend `new_with_indexed_profile` to accept the requested strategy, perform the gate first, and initialize `strategy`, `plan`, `stored_cursor`, and `fixed_state` from the indexed preflight result. This is the only indexed construction seam.

```moonbit
let facts = match _png_encode_indexed_preflight_with_profile(
  source, wire_profile, interlace_strategy, limits, budget,
) {
  Err(error) => return Err(error)
  Ok(value) => value
}
```

**Acknowledgement-safe replay pattern** (`stream_encode.mbt:1256-1392`): Fixed preview returns a prospective scalar state; it is assigned only after acknowledgement. Reuse the `PngFixedState` machinery and make its cursor be the shared indexed raw/match producer when the selected indexed plan is Fixed.

```moonbit
let (byte, next) = match self.fixed_preview_byte() { ... }
self.pending_fixed = Some(next)
return Ok(byte)
```

**Stored traversal pattern** (`stream_encode.mbt:1171-1221`): the stored IDAT path already prefers `stored_cursor.next()` when a cursor exists. Supply the same indexed raw producer for selected non-interlaced indexed output instead of calling `scanline_byte` independently in Stored and Fixed paths.

### `modules/mb-image/png/encode_test.mbt` (test, transform)

**Primary analogs:** Fixed selection/wire assertion at `modules/mb-image/png/encode_test.mbt:2845-2861`; public exact work/admission test at `modules/mb-image/png/encode_test.mbt:3204-3237`.

Copy the compact public test style: encode a deterministic compressible source, assert final DEFLATE BTYPE after the actual indexed IDAT offset (do not hard-code `43` for palette-bearing frames), and decode/assert semantics.

```moonbit
let (_, writer) = png_encode_with(
  PngEncoder::new_with_compression_strategy(PngCompressionStrategy::FixedOrStored), image,
)
let bytes = png_encode_prefix(writer)
inspect((bytes[43] & b'\x07') == b'\x03', content="true")
```

For Phase 85 add public eager coverage for: legacy bytes equal explicit `Stored` for Indexed8 and 1/2/4; Fixed-or-Stored chooses deterministically (including tie-to-Fixed); and `DynamicOrFixedOrStored` returns the exact capability context without writer progress or budget charge.

### `modules/mb-image/png/stream_encode_test.mbt` (test, streaming)

**Primary analogs:** configured eager/chunk parity at `modules/mb-image/png/stream_encode_test.mbt:2281-2292`; legacy byte freeze at `modules/mb-image/png/stream_encode_test.mbt:2592-2607`; existing indexed eager oracle plus chunk tracer at `modules/mb-image/png/stream_encode_test.mbt:4900-4981`.

**Parity pattern:** use the eager selected-indexed helper as the chunk oracle, drain with a small ragged schedule, and assert exact bytes.

```moonbit
let eager = png_stream_test_eager_with_strategy(image, PngCompressionStrategy::FixedOrStored)
let encoder = PngChunkEncoder::new_with_compression_strategy(...).unwrap()
let chunked = png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap()
inspect(chunked == eager, content="true")
```

**Existing indexed helper shape** (`stream_encode_test.mbt:4917-4933`): create companion eager helpers that take `PngCompressionStrategy`; use them for Indexed8 and `PngIndexedBitDepth::{One, Two, Four}` selected API coverage.

Dynamic-rejection tests should call both eager and chunk compression selectors and assert `error.context() == Some("indexed-dynamic-compression-unavailable")`, unchanged budget, and no writer output / no encoder instance. Keep hostile-lease qualification out of this phase except for already-established regression parity.

### `modules/mb-image/png/encode_wbtest.mbt` (test, transform)

**Primary analog:** `modules/mb-image/png/encode_wbtest.mbt:1009-1056`.

Use this for private indexed-plan assertions: inspect `PngDeflatePlan::{Stored, Fixed}`, candidate IDAT/frame lengths, the tie rule, bounded matcher work, and exact one-time work charge. The structure is:

```moonbit
let facts = _png_encode_preflight(...).unwrap()
let selected = before.work() - generous.remaining().work()
match facts.plan {
  PngDeflatePlan::Fixed(plan) => {
    inspect(selected == facts.total_length + plan.matcher_work + plan.matcher_work, content="true")
  }
  PngDeflatePlan::Stored(_) => panic()
  PngDeflatePlan::Dynamic(_) => panic()
}
```

Add private tests against the indexed preflight seam rather than an independently constructed frame calculator. In particular, prove PLTE and canonical shortest tRNS participate in both stored and Fixed candidate frame totals.

### `modules/mb-image/png/stream_encode_wbtest.mbt` (test, streaming)

**Primary analogs:** pending Fixed preview is non-mutating at `modules/mb-image/png/stream_encode_wbtest.mbt:544-565`; pending Fixed state changes only on acknowledgement at `modules/mb-image/png/stream_encode_wbtest.mbt:602-638`; replay drift error identity at `modules/mb-image/png/stream_encode_wbtest.mbt:641-690`.

Preserve the preview/ack boundary when wiring indexed Fixed replay:

```moonbit
let fixed_header = machine.present().unwrap().unwrap()
inspect(machine.present().unwrap() == Some(fixed_header), content="true")
inspect(machine.completed(), content="43")
machine.acknowledge(fixed_header).unwrap()
inspect(machine.completed(), content="44")
```

Phase-85 white-box tests should establish that an indexed Fixed plan and replay use the same raw stream/matcher facts. Do not create a second replay algorithm merely to test it.

## Shared Patterns

### Public naming and default compatibility

**Sources:** `modules/mb-image/png/encode.mbt:2278-2393`; `modules/mb-image/png/stream_encode.mbt:21-84`.

Use additive `*_with_compression_strategy` names with the existing `PngCompressionStrategy`; ordinary indexed APIs forward explicitly to `Stored` and filter `None`. Adam7 selectors remain the legacy Stored/None route.

### Atomic capability failure

**Sources:** `modules/mb-image/png/encode.mbt:16-18`; `modules/mb-image/png/stream_encode.mbt:978-991`.

The indexed Dynamic gate must precede `_png_encode_indexed_preflight_with_profile`, the `budget.charge` at `encode.mbt:2199-2205`, and `PngChunkEncoderState::Active`. Return `_png_encode_capability("indexed-dynamic-compression-unavailable")` once, and test exact context plus no side effects.

### Exact Type-3 frame accounting

**Sources:** `modules/mb-image/png/encode.mbt:344-395`; `modules/mb-image/png/encode.mbt:2167-2180`.

Always derive complete frame totals through `_png_frame_facts(palette_length, canonical_trns_length, idat_length)`. This owns IHDR/PLTE/tRNS/IDAT/IEND structure. Generic `+57` totals are not valid for palette-bearing selection.

### Single bounded raw stream and existing Fixed replay

**Sources:** `modules/mb-image/png/encode.mbt:1151-1304`; `modules/mb-image/png/stream_encode.mbt:1171-1221`; `modules/mb-image/png/stream_encode.mbt:1256-1392`.

One immutable indexed filter-None producer must feed Stored traversal, Fixed planning, and acknowledgement-safe Fixed replay. Preserve the 262-byte cursor window, distance-1..4 matcher, scalar `PngFixedState`, and `present`/`acknowledge` ownership model.

### Test conventions

**Sources:** `modules/mb-image/png/encode_test.mbt:2845-2861`; `modules/mb-image/png/stream_encode_test.mbt:2281-2292`; `modules/mb-image/png/encode_wbtest.mbt:1009-1056`.

Public `*_test.mbt` tests assert bytes, decoded semantics, façade parity, and atomic failure. `*_wbtest.mbt` tests assert plans, arithmetic, bounded work, and acknowledgement state. Use deterministic in-source sources and exact byte/error assertions, not opaque snapshots.

## No Analog Found

None. The generic compression, indexed Stored routes, fixed matcher, frame facts, acknowledged machine, and both test layers all have direct in-package analogs. The only new internal design choice is how to adapt the raw producer type; it must preserve the shared-cursor contract above rather than introduce a parallel encoder.

## Metadata

**Analog search scope:** `modules/mb-image/png/{png,encode,stream_encode,encode_test,encode_wbtest,stream_encode_test,stream_encode_wbtest}.mbt`  
**Files scanned:** 7  
**Pattern extraction date:** 2026-07-24
