# Phase 57: Bounded Adam7 Streaming Semantics - Pattern Map

**Mapped:** 2026-07-23  
**Files analyzed:** 7 (3 likely test modifications; 4 production/test seams verified)  
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/encode_wbtest.mbt` | white-box test | streaming / transform | RGB/RGBA Adam7 Adaptive pass-history and exact-work test | exact composition |
| `modules/mb-image/png/encode_test.mbt` | public integration test | request-response / transform | RGB/RGBA Adam7 eager admission matrix plus existing GrayAlpha16 selectors | exact composition |
| `modules/mb-image/png/stream_encode_test.mbt` | public integration test | streaming | existing GrayAlpha16 six-pair admission and U16 replay helpers plus Adam7 chunk drain | exact composition |
| `modules/mb-image/png/encode.mbt` | encoder service | streaming / transform | profile-aware Adam7 filtered cursor and atomic planner | verified seam — no change unless a regression exposes a gap |
| `modules/mb-image/png/stream_encode.mbt` | encoder service | streaming / event-driven acknowledgement | `PngEncodeMachine` profile construction, preview, acknowledgement, replay revision guard | verified seam — no change unless a regression exposes a gap |
| `modules/mb-image/png/stream_encode_wbtest.mbt` | white-box test | event-driven | Adam7 preview/acknowledgement test | existing coverage; extend only if public tests cannot localize a failure |
| `modules/mb-image/png/structural.mbt` | utility / model | transform | `_png_adam7_passes` pass geometry authority | reuse only; do not modify |

## Pattern Assignments

### `modules/mb-image/png/encode_wbtest.mbt` (white-box test, streaming / transform)

**Analog:** `modules/mb-image/png/encode_wbtest.mbt:297-337`, composed with the new legal `GrayAlpha16` Adam7 profile.

**Pass-local Adaptive and exact-work pattern** (`encode_wbtest.mbt:300-337`):

```moonbit
let passes = _png_adam7_passes(2UL, 2UL, channels, 8).unwrap()
let mut cursor = PngFilteredCursor::new_with_interlace(
  image.view(), 2UL * channels, channels, PngFilterStrategy::Adaptive,
  PngInterlaceStrategy::Adam7,
)
for pass in passes {
  if pass.width == 0UL || pass.height == 0UL { continue }
  while cursor.index < offset {
    let (_, next) = cursor.next().unwrap(); cursor = next
  }
  let (tag, next) = cursor.next().unwrap()
  inspect(tag != b'\x02', content="true")
  cursor = next
  offset = offset + (pass.row_bytes + 1UL) * pass.height
}

let admitted = _png_encode_preflight_with_interlace(
  image.view(), strategy, PngFilterStrategy::Adaptive, PngInterlaceStrategy::Adam7,
  png_wb_limits(), png_wb_budget(work=1048576UL),
).unwrap()
let exact = png_wb_budget(work=admitted.selected_work)
ignore(_png_encode_preflight_with_interlace(..., exact).unwrap())
let one_less = png_wb_budget(work=admitted.selected_work - 1UL)
let before = one_less.remaining()
let error = _png_encode_preflight_with_interlace(..., one_less).unwrap_err()
inspect(error.context() == Some("work") &&
  png_wb_same_remaining(before, one_less.remaining()), content="true")
```

**Apply:** introduce the smallest legal packed little-endian GrayAlpha16 fixture and invoke the profile-aware cursor/preflight seam (`PngFilteredCursor::new_with_interlace(..., profile=PngEncodeProfile::GrayAlpha16)` and `_png_encode_preflight_with_interlace_profile(...)`).  Cover each of Stored, FixedOrStored, and DynamicOrFixedOrStored with both `None` and `Adaptive`; assert a first row of every nonempty pass cannot use `Up`, and exact/one-less work remains one atomic charge.  This is a white-box composition test, not a new filter implementation.

**Production source it proves:**

```moonbit
// modules/mb-image/png/encode.mbt:724-775
if self.interlace_strategy == PngInterlaceStrategy::Adam7 {
  let (pass, row, in_row) = match _png_adam7_cursor_location(
    self.source, self.channels, self.index,
  ) { Err(error) => return Err(error); Ok(value) => value }
  if in_row == 0UL {
    let winner = match self.filter_strategy {
      PngFilterStrategy::None => PngRowFilter::None
      PngFilterStrategy::Adaptive => match _png_adam7_row_winner(
        self.source, self.profile, pass, row, self.channels,
      ) { Err(error) => return Err(error); Ok(value) => value }
    }
    return Ok((_png_filter_tag(winner), { ..self, ... }))
  }
  let byte = match _png_adam7_candidate_byte(
    winner, self.source, self.profile, pass, row, self.channels, in_row - 1UL,
  ) { Err(error) => return Err(error); Ok(value) => value }
  return Ok((byte, { ..self, ... }))
}
```

The `row` passed to `_png_adam7_candidate_byte` is local to one `PngAdam7Pass`; lines `624-632` zero `up`/`upper_left` at `row == 0UL`, which is the required predictor reset.

---

### `modules/mb-image/png/encode_test.mbt` (public integration test, request-response / transform)

**Analog:** `modules/mb-image/png/encode_test.mbt:634-695` and `1685-1708` (Adam7 eager atomic admission), composed with the existing legal GrayAlpha16 eager selector family.

**Atomic eager matrix pattern** (`encode_test.mbt:668-695`):

```moonbit
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  let budget = png_encode_budget(bytes=1048576UL, work=work)
  let before = budget.remaining()
  let writer = @io.MemoryWriter::new(
    1048576UL, png_encode_budget(bytes=1048576UL, work=0UL),
  ).unwrap()
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_with_all_strategies(
      strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
    ), image.view(), writer as &@io.Writer,
    @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
    limits, budget, @error.Diagnostics::new(),
  ).unwrap_err())
  if writer.position() != 0UL || !png_adam7_same_remaining(before, budget.remaining()) {
    abort("png adam7 eager admission atomic")
  }
}
```

**Apply:** adapt the helper to `PngEncoder::new_graya16_with_all_strategies(strategy, filter_strategy, Adam7)` and nest `None`/`Adaptive` filters inside the existing three compression choices.  Use a legal little-endian GrayAlpha16 5x5 source; run the five existing failure modes (incompatible capability, geometry, output, work, budget).  For every eager rejection require `writer.position() == 0UL` and every resource-ledger field unchanged.  Preserve the Phase-56 Big-endian descriptor rejection and frozen non-interlaced tests; they are compatibility boundaries, not an additional variant of this matrix.

**Selection and atomicity seams to preserve:**

```moonbit
// modules/mb-image/png/encode.mbt:1543-1565
fn _png_encode_preflight_with_interlace_profile(...) -> Result[PngEncodePreflight, @error.CoreError] {
  match profile {
    PngEncodeProfile::Gray8 if interlace_strategy != PngInterlaceStrategy::None =>
      return Err(_png_encode_capability("gray8-noninterlaced-required"))
    PngEncodeProfile::Gray16 if interlace_strategy != PngInterlaceStrategy::None =>
      return Err(_png_encode_capability("gray16-noninterlaced-required"))
    PngEncodeProfile::GrayAlpha8 if interlace_strategy != PngInterlaceStrategy::None =>
      return Err(_png_encode_capability("graya8-noninterlaced-required"))
    _ => ()
  }
  _png_encode_preflight_with_filter_layout_idat_limit_profile(...)
}
```

`GrayAlpha16` deliberately falls through to the one profile-aware ledger; do not add a format-specific Adam7 preflight branch.

---

### `modules/mb-image/png/stream_encode_test.mbt` (public integration test, streaming)

**Analog 1 — six-pair atomic admission:** `modules/mb-image/png/stream_encode_test.mbt:2684-2728`.

```moonbit
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    let eager = @codec.ImageEncoder::encode(
      PngEncoder::new_graya16_with_strategies(strategy, filter_strategy), ...,
    ).unwrap_err()
    if writer.position() != 0UL ||
      !png_fixed_or_stored_same_remaining(eager_before, eager_budget.remaining()) {
      abort("png graya16 eager admission exposed output")
    }
    let sentinel = png_chunk_test_owner(7UL, fill=b'Z')
    let chunk = PngChunkEncoder::new_graya16_with_strategies(...).unwrap_err()
    if !png_chunk_test_same_error(eager, chunk) ||
      !png_fixed_or_stored_same_remaining(chunk_before, chunk_budget.remaining()) {
      abort("png graya16 chunk admission mismatch")
    }
    for index = 0UL; index < 7UL; index = index + 1UL {
      if sentinel.view().get(index).unwrap() != b'Z' {
        abort("png graya16 admission exposed lease")
      }
    }
  }
}
```

**Apply:** retain the loops and assertions, replacing both factory calls with their Adam7 all-strategy GrayAlpha16 counterparts.  Reuse the same five isolated invalid inputs/limits from the existing test at `stream_encode_test.mbt:2854-2870`.  The public eager/chunk errors must be equivalent; neither output nor budget nor any sentinel byte may change.

**Analog 2 — accepted-only, eager-parity drain:** `stream_encode_test.mbt:3339-3396`.

```moonbit
let eager = png_stream_test_eager_with_all_strategies(
  image, strategy, PngFilterStrategy::None, PngInterlaceStrategy::Adam7,
)
let zero = empty.with_mut(0UL, 0UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
if zero.written() != 0UL || zero.total_written() != 0UL ||
  !(zero.outcome() is PngChunkPullOutcome::NeedOutput) {
  abort("png adam7 empty lease progress")
}
let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
  abort("png adam7 accepted-only progress")
}
```

**Apply:** make the helper select `new_graya16_with_all_strategies(..., Adam7, ...)`, run all three compression strategies and both filters, and compare the terminal accumulated bytes against the matching eager GrayAlpha16 Adam7 factory.  Keep schedules deliberately small (one-byte and `[0, 1, 3, 2, 5]`) only as the smallest existing replay seam; broader hostile schedules are Phase 58.

**Analog 3 — pre-write U16 replay drift and sticky terminal:** `stream_encode_test.mbt:3042-3113`.

```moonbit
while prefix.length() < 44 {
  let pull = png_chunk_test_pull(encoder, 1UL, prefix)
  if pull.written() != 1UL { abort("png graya16 replay prefix") }
}
image.with_mut_view(fn(view) {
  view.set_component_byte(0UL, 0UL, 1UL, 0UL, b'\xff')
}).unwrap()
let accepted_total = prefix.length().to_uint64()
let first = png_chunk_test_owner(post_capacity, fill=b'Z')
let failed = first.with_mut(0UL, post_capacity, fn(lease) {
  Ok(encoder.pull(lease))
}).unwrap()
if failed.written() != 0UL || failed.total_written() != accepted_total { ... }
for index = 0UL; index < post_capacity; index = index + 1UL {
  if first.view().get(index).unwrap() != b'Z' { ... }
}
let replay = later.with_mut(0UL, post_capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
if replay.written() != 0UL || replay.total_written() != accepted_total ||
  !png_chunk_test_same_error(error, replay_error) { ... }
```

**Apply:** change construction to the Adam7 GrayAlpha16 selector and retain `PngFilterStrategy::Adaptive`; execute FixedOrStored and DynamicOrFixedOrStored separately so the existing expected first-DEFLATE-bit checks continue to prove the intended replay path.  Mutate a checked U16 alpha lane after accepted framing.  The first and every later post-mutation pull must be a zero-write failure with unchanged sentinel lease bytes and identical terminal error/progress.

**Production replay seam:**

```moonbit
// modules/mb-image/png/stream_encode.mbt:803-819
fn PngEncodeMachine::validate_u16_replay_revision(self : PngEncodeMachine)
  -> Result[Unit, @error.CoreError] {
  if !_png_profile_uses_u16_component_wire(self.profile) ||
    self.source.mutation_revision() == self.source_revision { return Ok(()) }
  match self.plan {
    PngDeflatePlan::Fixed(_) =>
      Err(_png_encode_machine_state_error("png-encode-fixed-replay-drift"))
    PngDeflatePlan::Dynamic(_) =>
      Err(_png_encode_machine_state_error("png-encode-dynamic-replay-drift"))
    PngDeflatePlan::Stored(_) => Ok(())
  }
}
```

Use the public helper because it proves this guard runs before a lease byte is copied.  Do not add a second source-mutation mechanism.

---

### `modules/mb-image/png/encode.mbt` and `stream_encode.mbt` (verified production seams; streaming)

**No source modification is presently implied.** The current code already composes the new profile through the required single bounded route.  Keep these excerpts as the disconfirmation checklist for the implementation plan.

**One pass-aware, profile-aware preflight ledger** (`encode.mbt:1602-1811`):

```moonbit
let scanlines = match interlace_strategy {
  PngInterlaceStrategy::None => ...
  PngInterlaceStrategy::Adam7 => {
    let passes = match _png_adam7_passes(source.width(), source.height(), channels, 8) {
      Err(error) => return Err(error); Ok(value) => value
    }
    let mut total = 0UL
    for pass in passes {
      if pass.width == 0UL || pass.height == 0UL { continue }
      let per_row = match @checked.checked_add(pass.row_bytes, 1UL) { ... }
      let bytes = match @checked.checked_mul(per_row, pass.height) { ... }
      total = match @checked.checked_add(total, bytes) { ... }
    }
    total
  }
}
// Stored, Fixed, and Dynamic each call an interlace/profile-aware fresh traversal.
let adaptive_replay_facts = match _png_filtered_match_traverse_with_interlace(
  source, row_bytes, channels, filter_strategy, scanlines, interlace_strategy, profile=profile,
) { Err(error) => return Err(error); Ok(value) => value }
// Limits are checked, then the single budget charge occurs only at the end.
match budget.charge(@budget.ResourceCharge::new(..., work=selected_work)) { ... }
```

**Single construction/replay route** (`stream_encode.mbt:628-706`):

```moonbit
let facts = match _png_encode_preflight_with_interlace_profile(
  source, profile, strategy, filter_strategy, interlace_strategy, limits, budget,
) {
  Err(error) => return Err(error)
  Ok(value) => value
}
// Every U16, Adam7, or Adaptive route gets the same scalar filtered-match cursor.
stored_cursor: if _png_profile_uses_u16_component_wire(profile) ||
  interlace_strategy == PngInterlaceStrategy::Adam7 ||
  filter_strategy == PngFilterStrategy::Adaptive {
  Some(PngFilteredMatchCursor::new_with_interlace(
    source, facts.row_bytes, facts.channels, filter_strategy, interlace_strategy,
    profile=facts.profile,
  ))
} else { None },
```

**Acknowledgement is the sole commit point** (`stream_encode.mbt:1187-1258`):

```moonbit
fn PngEncodeMachine::present(self : PngEncodeMachine) -> Result[Byte?, @error.CoreError] {
  match self.pending {
    Some(byte) => Ok(Some(byte))
    None => {
      let byte = match self.byte_at(self.emitted) { ... }
      self.pending = Some(byte)
      Ok(Some(byte))
    }
  }
}

fn PngEncodeMachine::acknowledge(self : PngEncodeMachine, accepted : Byte)
  -> Result[Unit, @error.CoreError] {
  let pending = match self.pending { ... }
  if pending != accepted { return Err(_png_encode_machine_state_error("png-encode-acknowledgement")) }
  // Commit CRC/Adler and pending cursor successor only here.
  self.pending = None
  self.pending_stored = None
  self.pending_fixed = None
  self.pending_dynamic = None
  self.emitted = self.emitted + 1UL
  Ok(())
}
```

If any Phase-57 test fails, fix the smallest broken shared seam above; do not create GrayAlpha16-specific compression, output buffering, geometry, or replay code.

## Shared Patterns

### Profile-aware scalar pass traversal

**Sources:** `modules/mb-image/png/encode.mbt:556-670`, `724-775`  
**Apply to:** all Adam7 `None`/`Adaptive` strategy tests

`_png_adam7_cursor_location` regenerates checked pass geometry from `_png_adam7_passes` for each scalar lookup and skips empty passes. `_png_adam7_raw_byte` uses `_png_wire_byte`, so GrayAlpha16 obtains `Ghi,Glo,Ahi,Alo` before filtering. Test the shared route; do not retain a pass table, selected-row cache, or image-sized staging output.

### Atomic admission before writer or lease exposure

**Sources:** `encode.mbt:1602-1811`; `stream_encode.mbt:628-643`; `stream_encode_test.mbt:2684-2728`, `3291-3336`  
**Apply to:** all capability, geometry, output, work, and budget rejection tests

Both eager and chunk factories must call the same profile-aware preflight.  Assert empty eager writer, equal typed error, all resource-ledger fields unchanged, and untouched `b'Z'` lease sentinels.  `Stored × FixedOrStored × DynamicOrFixedOrStored` crossed with `None × Adaptive` is the required six-pair matrix.

### Replay is preview then acknowledgement

**Sources:** `stream_encode.mbt:1187-1258`; `stream_encode_wbtest.mbt:244-291`; `stream_encode_test.mbt:3339-3396`  
**Apply to:** caller-buffered ordinary drain and mutation tests

Only an accepted byte advances `emitted` or cursor/checksum state.  Zero-capacity pulls are no-ops, `total_written` rises exactly by `written`, output collected over a ragged schedule matches the eager peer, and terminal re-pulls leave caller bytes intact.

### U16 replay mutation is pre-write and sticky

**Sources:** `stream_encode.mbt:803-819`; `stream_encode_test.mbt:3042-3113`  
**Apply to:** Adaptive FixedOrStored and DynamicOrFixedOrStored Adam7 GrayAlpha16 tests

Mutate a valid checked U16 component only after framing has been acknowledged. The next pull must fail before copying into the supplied lease; all later pulls return the same failure with zero newly accepted bytes and unchanged sentinel buffers.

## No Analog Found

None. Phase 57 is an exact composition of the archived v0.13 Adam7 bounded/replay tests and the archived v0.17 GrayAlpha16 atomic/replay tests. Current production code already has the profile/pass forwarding those tests require.

## Metadata

**Analog search scope:** `.planning/phases/57-bounded-adam7-streaming-semantics/57-CONTEXT.md`; Phase 56 context, summaries, and verification; archived v0.13 Phase 42 context/summaries (`git show 869f362`); archived v0.17 Phase 54 context/summary; `modules/mb-image/png/{encode,stream_encode,structural}.mbt` and focused eager/stream/white-box PNG tests.  
**Files scanned:** 12 planning artifacts and 7 PNG implementation/test files.  
**Pattern extraction date:** 2026-07-23
