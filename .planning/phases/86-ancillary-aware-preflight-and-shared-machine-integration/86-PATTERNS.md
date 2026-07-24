# Phase 86: Ancillary-Aware Preflight and Shared-Machine Integration - Pattern Map

**Mapped:** 2026-07-24  
**Files analyzed:** 6 expected modified files  
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/encode.mbt` | service | transform | `_png_encode_indexed_preflight_with_profile_and_strategy` in the same file | exact |
| `modules/mb-image/png/stream_encode.mbt` | service | streaming | `PngEncodeMachine::new_with_indexed_profile_and_strategy` in the same file | exact |
| `modules/mb-image/png/encode_wbtest.mbt` | test | transform | indexed compression matrix in the same file | exact |
| `modules/mb-image/png/encode_test.mbt` | test | request-response | eager dynamic-rejection observation in the same file | role-match |
| `modules/mb-image/png/stream_encode_test.mbt` | test | streaming | indexed chunk-construction atomicity tests in the same file | exact |
| `modules/mb-image/png/png.mbt` | model | transform | `PngIndexedImage::new` checked-constructor path in the same file | exact |

No new production type, stream encoder, staging buffer, or public wrapper is implied by the phase. `png.mbt` is an invariant source for the checked-arithmetic test; modify it only if a demonstrated constructor defect requires it.

## Pattern Assignments

### `modules/mb-image/png/encode.mbt` (service, transform)

**Analog:** `_png_encode_indexed_preflight_with_profile_and_strategy` (lines 2226-2390).

Keep this private preflight as the single admission owner. It derives geometry, enforces the selected profile cap, calculates the canonical trailing non-opaque alpha prefix, builds complete Stored and Fixed frame facts, and retains only the chosen tuple.

**Checked geometry and palette-cap pattern** (lines 2247-2265):

```moonbit
let pixels = match @checked.checked_mul(width, height) {
  Err(error) => return Err(error)
  Ok(value) => value
}
let palette_entries = source.palette_length() / 3UL
if palette_entries > wire_profile.palette_cap() {
  return Err(_png_encode_capability("indexed-palette-cap"))
}
let bits = match @checked.checked_mul(width, wire_profile.depth()) {
  Err(error) => return Err(error)
  Ok(value) => value
}
```

**Ancillary-aware candidate selection pattern** (lines 2301-2344):

```moonbit
let mut trns_length = 0UL
for entry = 0UL; entry < palette_entries; entry = entry + 1UL {
  let alpha = match source.alpha_at(entry) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if alpha != b'\xff' { trns_length = entry + 1UL }
}
let stored_frame = match _png_frame_facts(
  source.palette_length(), trns_length, idat_length,
) { Err(error) => return Err(error); Ok(value) => value }
// Build Fixed facts from a fresh cursor; compare full frame totals, not IDAT bytes.
if fixed_frame.total_length <= stored_frame.total_length {
  (PngDeflatePlan::Fixed(fixed), fixed_frame, work)
} else {
  (PngDeflatePlan::Stored(stored), stored_frame, stored_frame.total_length)
}
```

**Limit-before-charge pattern** (lines 2358-2381):

```moonbit
for item in [
  ("width", width, limits.max_width()),
  ("height", height, limits.max_height()),
  ("pixels", pixels, limits.max_pixels()),
  ("output-bytes", frame.total_length, limits.max_output_bytes()),
  ("work", selected_work, limits.max_work()),
] {
  let (context, requested, limit) = item
  _png_encode_limit(context, requested, limit) ?
}
budget.charge(@budget.ResourceCharge::new(
  bytes=0UL, allocations=0UL, allocation_size=0UL, width~, height~,
  pixels~, work=selected_work,
)) ?
```

**Framing ownership pattern:** keep PLTE/tRNS/IDAT/IEND offsets in `PngFrameFacts`, via `_png_frame_facts` (lines 344-394). Its checked additions already make it the sole complete-frame accounting oracle:

```moonbit
let idat_start = if plte_length == 0UL { plte_start } else {
  @checked.checked_add(plte_start, 12UL + plte_length) ?
}
let iend_start = @checked.checked_add(idat_start, 12UL + idat_length) ?
let total_length = @checked.checked_add(iend_start, 12UL) ?
```

Do not add candidate budget charges, separate palette arithmetic, or an eager-only preflight.

---

### `modules/mb-image/png/stream_encode.mbt` (service, streaming)

**Analog:** `PngEncodeMachine::new_with_indexed_profile_and_strategy` (lines 1024-1077), plus both chunk constructors (lines 36-47 and 84-96).

The machine is the only state that may exist after admission. It consumes the selected facts instead of re-deriving output/accounting in either facade.

**Selected-facts-to-machine pattern** (lines 1036-1069):

```moonbit
let facts = _png_encode_indexed_preflight_with_profile_and_strategy(
  source, wire_profile, interlace_strategy, strategy, limits, budget,
) ?
Ok({
  indexed_source: Some(source),
  profile: facts.profile,
  row_bytes: facts.row_bytes, scanlines: facts.scanlines, blocks: facts.blocks,
  idat_length: facts.idat_length, frame: facts.frame,
  total_length_value: facts.total_length, plan: facts.plan,
  disposition: facts.disposition,
  fixed_state: match facts.plan {
    PngDeflatePlan::Fixed(_) => Some({ /* fresh bounded indexed cursor */ })
    _ => None
  },
  // ...
})
```

**Chunk-constructor pattern** (lines 43-47, 92-96):

```moonbit
let machine = PngEncodeMachine::new_with_indexed_profile_and_strategy(
  source, PngIndexedWireProfile::Eight, PngInterlaceStrategy::None, strategy,
  limits, budget, diagnostics,
) ?
Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
```

Return the preflight error before constructing `PngChunkEncoderState::Active`; do not expose a lease, wrap a different machine, or replicate accounting.

---

### `modules/mb-image/png/encode_wbtest.mbt` (test, transform)

**Analogs:** `png_wb_same_remaining` (lines 994-1006), exact selected-work test (lines 1009-1055), low-bit preflight admission test (lines 1235-1281), and the indexed compression matrix (lines 1333-1421).

This is the private fact/accounting test location. Extend the existing matrix rather than create a parallel expected-size oracle.

**Complete budget-snapshot assertion** (lines 994-1006):

```moonbit
fn png_wb_same_remaining(left : @budget.ResourceLimits, right : @budget.ResourceLimits) -> Bool {
  left.bytes() == right.bytes() &&
  left.allocations() == right.allocations() &&
  left.allocation_size() == right.allocation_size() &&
  left.width() == right.width() && left.height() == right.height() &&
  left.pixels() == right.pixels() && left.depth() == right.depth() &&
  left.work() == right.work()
}
```

**Exact/one-less test shape** (lines 1253-1263):

```moonbit
let exact = png_wb_budget(work=admitted.selected_work)
ignore(_png_encode_indexed_preflight_with_profile(..., exact).unwrap())
inspect(exact.remaining().work() == 0UL, content="true")
let one_less = png_wb_budget(work=admitted.selected_work - 1UL)
let before = one_less.remaining()
let error = _png_encode_indexed_preflight_with_profile(..., one_less).unwrap_err()
inspect(error.context() == Some("work") &&
  png_wb_same_remaining(before, one_less.remaining()), content="true")
```

For Phase 86, obtain the exact values from an admitted `FixedOrStored` preflight's selected facts, then apply exact and one-less `max_output_bytes` and `max_work` to the same production preflight. Assert `frame.plte_length` equals the actual palette byte count and `frame.trns_length == 1UL` for every profile/winner pair.

**Palette-overflow pattern** (lines 1265-1280):

```moonbit
let oversized = PngIndexedImage::new(
  1UL, 1UL, b"\x00", oversized_palette, oversized_alpha,
  png_wb_budget(bytes=128UL, work=0UL),
).unwrap()
let rejected_before = rejected_budget.remaining()
let rejected = _png_encode_indexed_preflight_with_profile(
  oversized, profile, PngInterlaceStrategy::None, png_wb_limits(), rejected_budget,
).unwrap_err()
inspect(rejected.context() == Some("indexed-palette-cap") &&
  png_wb_same_remaining(rejected_before, rejected_budget.remaining()), content="true")
```

**Fixed-winner/Stored-fallback source pattern** (lines 1335-1421): use `png_indexed_compression_matrix_source(profile, stored_fallback)`. It supplies all four Type-3 depths, a real `cap * 3` PLTE, and one non-opaque alpha entry; its assertions already compare full `PngFrameFacts` totals and verify the retained plan.

---

### `modules/mb-image/png/encode_test.mbt` (test, request-response)

**Analogs:** `png_encode_prefix` and full resource comparator (lines 827-883); eager rejection observation (lines 954-966); indexed constructor atomicity (lines 1525-1635).

Use public APIs and a real `@io.MemoryWriter`, never a custom writer spy.

**Writer-visible atomicity pattern** (lines 954-966):

```moonbit
let rejected_budget = png_encode_budget(work=4096UL)
let before = rejected_budget.remaining()
let rejected_writer = @io.MemoryWriter::new(
  512UL, png_encode_budget(bytes=512UL, work=0UL),
).unwrap()
let error = PngEncoder::encode_indexed8_with_compression_strategy(
  PngEncoder::new(), source, strategy, rejected_writer as &@io.Writer,
  limits, rejected_budget, @error.Diagnostics::new(),
).unwrap_err()
inspect(png_adam7_same_remaining(before, rejected_budget.remaining()), content="true")
inspect(png_encode_prefix(rejected_writer).length(), content="0")
```

Use this shape for one-less selected output/work and palette-cap failure. Cover Indexed8 and `encode_indexed_with_compression_strategy` selected depths; do not calculate a second full-frame oracle in this public suite.

**Checked-arithmetic test analog** (lines 1608-1615):

```moonbit
let constructor_budget = png_encode_budget()
let constructor_before = constructor_budget.remaining()
let constructor_error = PngIndexedImage::new(
  4294967296UL, 1UL, b"\x00", b"\x12\x34\x56", b"\xff", constructor_budget,
).unwrap_err()
inspect(constructor_error.context() == Some("png-u32-dimensions"), content="true")
inspect(png_adam7_same_remaining(constructor_before, constructor_budget.remaining()), content="true")
```

The overflow is correctly a constructor-level test: a rejected source cannot reach an eager writer or chunk constructor.

---

### `modules/mb-image/png/stream_encode_test.mbt` (test, streaming)

**Analogs:** indexed strategy constructor parity (lines 4975-5030) and no-encoder atomic construction (lines 5999-6035).

Construct through the public `PngChunkEncoder` selectors. A rejection must be an `Err`; do not call `pull` or introduce a hostile lease schedule in this phase.

**Shared-constructor parity pattern** (lines 5009-5029):

```moonbit
let eager = png_stream_indexed_low_bit_eager_with_compression(
  source, depth, PngCompressionStrategy::FixedOrStored,
)
let encoder = PngChunkEncoder::new_indexed_with_compression_strategy(
  source, depth, PngCompressionStrategy::FixedOrStored,
  png_stream_test_limits(), png_stream_test_budget(work=4096UL),
  @error.Diagnostics::new(),
).unwrap()
inspect(png_chunk_test_drain_encoder(encoder, [32UL]).unwrap() == eager, content="true")
```

**Atomic constructor pattern** (lines 6005-6034):

```moonbit
let output_budget = png_stream_test_budget()
let output_before = output_budget.remaining()
inspect(PngChunkEncoder::new_indexed(
  source, bit_depth, png_stream_test_limits(output=1UL), output_budget,
  @error.Diagnostics::new(),
) is Err(_), content="true")
inspect(png_adam7_stream_same_remaining(
  output_before, output_budget.remaining(),
), content="true")
```

For selected `FixedOrStored` facts, repeat this with exact success and one-less selected output/work. The `Err` itself proves no caller-visible active machine/lease exists; preserve Phase 87's ownership of hostile pull schedules and independent chunk-origin parsing.

---

### `modules/mb-image/png/png.mbt` (model, transform)

**Analog:** `PngIndexedImage::new` (lines 246-333).

Retain validation and checked allocation sizing before `OwnedBytes` is allocated or charged:

```moonbit
match _png_encode_u32(width) { Err(error) => return Err(error); Ok(_) => () }
match _png_encode_u32(height) { Err(error) => return Err(error); Ok(_) => () }
let pixels = match @checked.checked_mul(width, height) {
  Err(error) => return Err(error)
  Ok(value) => value
}
let indexed_and_palette = @checked.checked_add(pixels, palette_length) ?
let total_length = @checked.checked_add(
  indexed_and_palette, palette_alpha.length().to_uint64(),
) ?
let owned_bytes = @bytes.OwnedBytes::new_with_allocator_and_charge(
  total_length, budget, allocator, width, height, pixels, 0UL,
) ?
```

Do not create a test-only invalid `PngIndexedImage` merely to force an unreachable encoder preflight failure.

## Shared Patterns

### Exact-limit and budget atomicity

**Sources:** `encode.mbt:2358-2381`; `encode_wbtest.mbt:994-1006, 1253-1263`  
**Apply to:** selected preflight and all exact/one-less tests.

Read `PngEncodePreflight.total_length` and `selected_work` after candidate selection. Check output/work limits before exactly one `budget.charge`; compare every remaining resource dimension after any error.

### Ancillary framing

**Source:** `encode.mbt:344-394, 2301-2344`  
**Apply to:** Stored/Fixed selection and white-box fact assertions.

Use `_png_frame_facts(source.palette_length(), trns_length, idat_length)` per candidate. `trns_length` is the final non-opaque palette index plus one. Compare `frame.total_length`, not compressed payload length.

### One admitted machine, two facades

**Sources:** `stream_encode.mbt:36-47, 84-96, 1024-1077`; `encode.mbt:2477-2495, 2570-2588`  
**Apply to:** eager and caller-buffered integration.

Both facade constructors call `PngEncodeMachine::new_with_indexed_profile_and_strategy`. Eager output only begins at `machine.present()` after successful construction; chunk state becomes `Active(machine)` only after successful construction.

### Test placement

**Sources:** `encode_wbtest.mbt:994-1421`; `encode_test.mbt:827-966`; `stream_encode_test.mbt:4975-5035, 5999-6035`  
**Apply to:** Phase 86 evidence.

Keep selected-frame internals, retained plan, and exact accounting in `encode_wbtest.mbt`; use `MemoryWriter` for public eager visibility; use public chunk construction for absence of a caller-visible encoder.

## No Analog Found

None. The current preflight, machine, writer observation, chunk construction, palette-cap, and checked-constructor patterns directly cover the phase.

## Metadata

**Analog search scope:** `modules/mb-image/png/{png,encode,stream_encode,encode_wbtest,encode_test,stream_encode_test}.mbt`  
**Files scanned:** 6  
**Pattern extraction date:** 2026-07-24  
**Discovery note:** codebase-memory graph searches returned zero MoonBit symbols for this checkout; source-text fallback was used as allowed by `AGENTS.md`.
