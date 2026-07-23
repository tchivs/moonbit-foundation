# Phase 70: Resumable RGBA16 PNG Encoding - Pattern Map

**Mapped:** 2026-07-23  
**Files classified:** 2 modified; 4 source/test analogs inspected  
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/stream_encode.mbt` | public factory / streaming façade | request-response construction into caller-buffered streaming | `PngChunkEncoder::new_graya16*` in the same file, lines 201-261 | exact role and transport; profile substitution only |
| `modules/mb-image/png/stream_encode_test.mbt` | public contract test | streaming, atomic admission, and event-like terminal-state checks | GrayAlpha16 source/oracle/drain/admission/replay helpers at lines 278-312, 848-912, 975-1017, 2914-2961, 3329-3388 | exact test shape; RGBA16 source and non-interlaced factory substitution |

`png.mbt` remains unchanged. It is the eager-oracle and profile-definition reference, not a Phase 70 edit target. `stream_encode_wbtest.mbt` remains unchanged because its machine-state test is profile-agnostic and Phase 70 must not change the shared machine or `pull` lifecycle.

## Pattern Assignments

### `modules/mb-image/png/stream_encode.mbt` (public factory, construction → streaming)

**Primary analog:** `PngChunkEncoder::new_graya16*`, lines 201-261.

Create exactly these four public, non-interlaced shapes, matching the eager family in `png.mbt` lines 393-431:

1. `PngChunkEncoder::new_rgba16`
2. `PngChunkEncoder::new_rgba16_with_compression_strategy`
3. `PngChunkEncoder::new_rgba16_with_filter_strategy`
4. `PngChunkEncoder::new_rgba16_with_strategies`

**Delegating factory pattern** (`stream_encode.mbt:201-241`):

```moonbit
PngChunkEncoder::new_graya16_with_strategies(
  source, PngCompressionStrategy::Stored, PngFilterStrategy::None,
  limits, budget, diagnostics,
)

PngChunkEncoder::new_graya16_with_strategies(
  source, strategy, PngFilterStrategy::None, limits, budget, diagnostics,
)

PngChunkEncoder::new_graya16_with_strategies(
  source, PngCompressionStrategy::Stored, filter_strategy, limits, budget,
  diagnostics,
)
```

Copy these three forwarding shapes, changing only the `graya16` names to `rgba16`.

**Profile-aware construction and error-return pattern** (`stream_encode.mbt:245-261`):

```moonbit
let machine = match PngEncodeMachine::new_with_profile(
  source, PngEncodeProfile::GrayAlpha16, strategy,
  filter_strategy, PngInterlaceStrategy::None, limits, budget, diagnostics,
) {
  Err(error) => return Err(error)
  Ok(value) => value
}
Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
```

For the new final factory, substitute only `PngEncodeProfile::Rgba16`. Preserve the `match`/early-return syntax, fresh active state, and `PngInterlaceStrategy::None` literal.

**Why this is the atomic-admission seam:** `PngEncodeMachine::new_with_profile` calls `_png_encode_preflight_with_interlace_profile` before it creates state (`stream_encode.mbt:665-679`). Do not add factory-local geometry, output, work, or budget checks.

**Eager API shape to match:** `PngEncoder::new_rgba16*` delegates to the same four default/configured forms and fixes the relevant profile/interlace pair (`png.mbt:393-431`):

```moonbit
{
  strategy,
  filter_strategy,
  interlace_strategy: PngInterlaceStrategy::None,
  profile: PngEncodeProfile::Rgba16,
}
```

### `modules/mb-image/png/stream_encode_test.mbt` (public contract test, caller-buffered streaming)

**Primary analogs:** `png_stream_graya16_image` (lines 278-312), `png_stream_graya16_eager_with_strategies` (lines 975-993), `png_stream_graya16_public_drain` (lines 848-910), and the GrayAlpha16 public evidence test (lines 1621-1658).

Add a compact RGBA16 image helper with visibly distinct U16 component lanes, a fresh eager-RGBA16 oracle helper, and a drain helper that constructs only `new_rgba16_with_strategies`. Use `PngEncoder::new_rgba16_with_strategies` for the oracle; never derive expected output from another chunk encoder.

**Fresh eager oracle pattern** (`stream_encode_test.mbt:975-993`):

```moonbit
let writer = @io.MemoryWriter::new(1048576UL, png_stream_test_budget(work=0UL)).unwrap()
ignore(@codec.ImageEncoder::encode(
  PngEncoder::new_graya16_with_strategies(strategy, filter_strategy),
  image.view(), writer as &@io.Writer,
  @codec.EncodeOptions::new(lossless_required=true, preserve_opaque_metadata=false),
  png_stream_test_limits(), png_stream_test_budget(), @error.Diagnostics::new(),
).unwrap())
```

Substitute `new_rgba16_with_strategies`; retain the independent writer, fresh budget, and byte copy from the writer.

**Hostile lease drain pattern** (`stream_encode_test.mbt:848-910`):

```moonbit
if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
  abort("png graya16 public accepted progress")
}
for index = pulled.written(); index < capacity; index = index + 1UL {
  if owner.view().get(index).unwrap() != b'Z' {
    abort("png graya16 public lease tail")
  }
}
```

Retain the complete helper behavior: append only `written` bytes; require `NeedOutput` until completion; compare accumulated bytes with eager bytes; then perform a later pull that reports zero written, preserves total progress, returns `Finished`, and leaves a sentinel lease untouched.

**Required schedule matrix** (`stream_encode_test.mbt:1621-1658`):

```moonbit
[0UL, 1UL]
[1UL]
[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]
```

Cross each schedule with Stored, FixedOrStored, and DynamicOrFixedOrStored compression and None/Adaptive filtering. Before the drains, retain the dedicated zero-capacity lease assertion. Add direct coverage for the default, compression-only, and filter-only RGBA16 public factory forms as the existing GrayAlpha16 factory test does at lines 1354-1383; use the all-strategies form as the matrix path.

**Atomic-admission pattern:** copy `png_graya16_combined_public_reject` (lines 2914-2961) and the non-interlaced calls at lines 3114-3138. Replace its eager and chunk factory calls with their `new_rgba16_with_strategies` counterparts and remove the interlace parameter rather than introducing an RGBA16 interlace selector. Preserve error equality, unchanged budget reservation, and all-`Z` sentinel-lease assertions for incompatible source/profile, width, output, work, and budget rejections.

**Replay mutation / sticky terminal pattern:** copy the non-interlaced portion of `png_graya16_replay_mutation_is_sticky` (`stream_encode_test.mbt:3329-3388`) and its Fixed/Dynamic invocations (`3478-3490`). The first post-mutation pull and the later pull must both report zero accepted bytes, preserve the pre-mutation total, replay the same typed error, and leave both leases all `Z`.

## Shared Patterns

### Caller-buffer progress and typed terminals

**Source:** `modules/mb-image/png/stream_encode.mbt:440-529`  
**Apply to:** all four new RGBA16 factory results; do not copy or change this code.

```moonbit
match machine.validate_replay_revision() {
  Err(error) => {
    self.state = PngChunkEncoderState::Failed(error)
    return {
      written_value: 0UL,
      total_written_value: self.total_written,
      outcome_value: PngChunkPullOutcome::Failed(error),
    }
  }
  Ok(_) => ()
}
...
match destination.set(written, byte) { ... }
match machine.acknowledge(byte) { ... }
written = written + 1UL
self.total_written = machine.completed()
```

The byte is acknowledged only after it is written to the current lease; `total_written` advances from machine completion only after acknowledgement. The state caches `Finished` or `Failed`, so later pulls cannot write a new lease.

### Revision guard

**Source:** `modules/mb-image/png/stream_encode.mbt:844-856`  
**Apply to:** RGBA16 automatically through the shared machine.

```moonbit
if self.source.mutation_revision() == self.source_revision { return Ok(()) }
match self.plan {
  PngDeflatePlan::Fixed(_) =>
    Err(_png_encode_machine_state_error("png-encode-fixed-replay-drift"))
  PngDeflatePlan::Dynamic(_) =>
    Err(_png_encode_machine_state_error("png-encode-dynamic-replay-drift"))
  PngDeflatePlan::Stored(_) =>
    Err(_png_encode_machine_state_error("png-encode-stored-replay-drift"))
}
```

### Existing destination-failure evidence

**Source:** `modules/mb-image/png/stream_encode_test.mbt:2617-2646`  
**Apply to:** no new implementation; retain as the shared profile-independent proof.

The released-lease test verifies a zero-write failure, zero progress, same typed error on the next pull, and an untouched later lease. Do not fork `pull` or add a format-specific destination path solely for RGBA16.

### White-box machine accounting

**Source:** `modules/mb-image/png/stream_encode_wbtest.mbt:519-539`  
**Apply to:** no Phase 70 changes.

That white-box test proves `total_written == machine.completed()` only after one accepted lease byte. It is already profile-agnostic; the RGBA16 phase should add public façade/lifecycle evidence rather than mutate internal-machine tests.

## Cautions

- Do not add `new_rgba16_with_interlace_strategy` or `new_rgba16_with_all_strategies`; these would expose Adam7, which is Phase 71 scope. The only permitted interlace value is the literal `PngInterlaceStrategy::None`.
- Do not widen generic `PngChunkEncoder::new*` admission. The generic RGB8/RGBA8 constructor contract remains frozen.
- Do not edit `PngChunkEncoder::pull`, `PngEncodeMachine`, `png.mbt`, or white-box tests. RGBA16 selects an existing profile; it does not alter transport, preflight, U16 wire emission, or terminal behavior.
- Keep the eager encoder fresh and separate from the chunk encoder in every parity/admission comparison.
- Keep test assertions on acknowledged progress and untouched lease tails; a byte-parity-only test does not prove lease isolation or sticky terminals.

## No Analog Found

None. GrayAlpha16 is a direct analog for the caller-buffered U16 factory and public lifecycle contract; eager RGBA16 is a direct oracle shape.

## Metadata

**Analog search scope:** `modules/mb-image/png/{png,stream_encode,stream_encode_test,stream_encode_wbtest}.mbt`  
**Files scanned:** 4  
**Pattern extraction date:** 2026-07-23
