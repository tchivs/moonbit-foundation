# Phase 87: Hostile Indexed Streaming and Independent Qualification - Pattern Map

**Mapped:** 2026-07-24  
**Files analyzed:** 10 (one expected test edit; nine supporting test/source/config analogs)  
**Analogs found:** 10 / 10 (the compressed indexed DEFLATE oracle is a partial match; see No Analog Found)

Phase 87 is evidence-only. The closest implementation path is the existing
`PngChunkEncoder` and its acknowledged `present -> destination.set ->
acknowledge` machine. The likely production diff is empty; add qualification
helpers/tests beside the existing indexed stream tests and keep the package
target declaration unchanged.

## File Classification

| New/Modified File or Contract | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/stream_encode_test.mbt` | test | streaming / caller-buffered | Indexed8 Adam7 and selected low-bit Adam7 hostile drains (lines 5391-5480, 6000-6089) | exact lifecycle role; adapt layout/strategy |
| `modules/mb-image/png/encode_test.mbt` | test | request-response / eager transform | Indexed compression selector, CRC/slice helpers, and Indexed8 wire/decode tests (lines 961-1141, 1276-1304, 1448-1534) | exact public eager/oracle role |
| `modules/mb-image/png/encode_wbtest.mbt` | test | batch/transform facts | 512-pixel Fixed-winner/Stored-fallback matrix (lines 1333-1426) | exact corpus/selection role; reuse, do not duplicate |
| `modules/mb-image/png/stream_encode_wbtest.mbt` | test | streaming / acknowledged state | Fixed-or-Stored preview/ack and sticky replay mismatch (lines 544-565, 641-699) | exact machine-state role |
| `modules/mb-image/png/png_test.mbt` | test | request-response / decode | Hand-authored zlib/PNG literals and public decoder checks (lines 1-106, 669-702) | role-match independent decode oracle |
| `modules/mb-image/png/stream_encode.mbt` | service | streaming | `PngChunkEncoder::pull` state machine (lines 694-780) and indexed strategy constructors (lines 23-96) | exact production contract; no change expected |
| `modules/mb-image/png/encode.mbt` | service/facade | request-response | Eager indexed Stored/Fixed selectors (lines 2453-2588) | exact production contract; no change expected |
| `modules/mb-image/png/png.mbt` | model | transform | Checked `PngIndexedImage::new` (lines 246-334) | exact source invariant; no change expected |
| `modules/mb-image/png/moon.pkg` | config | batch/target declaration | `supported_targets = "+js+wasm+wasm-gc+native"` (line 15) | exact gate input; keep unchanged |
| `scripts/quality/Invoke-MoonQuality.ps1` / `policy/foundation.json` | quality/config | batch | Explicit target loop and PNG package target/source allowlist (`Invoke-MoonQuality.ps1:793-799`, `Assert-Policy.ps1:985-1003`, `foundation.json:1707-1735`) | exact portability/policy gate; record commands, do not add a lane |

## Pattern Assignments

### `modules/mb-image/png/stream_encode_test.mbt` (test, streaming / caller-buffered)

**Primary analogs:** `png_chunk_test_owner`/`png_chunk_test_pull`/
`png_chunk_test_drain_encoder` (lines 757-805), selected low-bit Adam7
hostile matrix (lines 6000-6049), released-lease helper (lines 6054-6076),
and generic Fixed-or-Stored sticky-terminal test (lines 3981-4038).

**Caller lease and sentinel pattern** (lines 757-805):

```moonbit
fn png_chunk_test_owner(capacity : UInt64, fill? : Byte = b'\x00') -> @bytes.OwnedBytes {
  @bytes.OwnedBytes::from_bytes(
    Bytes::from_array(Array::make(capacity.to_int(), fill)),
    png_stream_test_budget(work=0UL),
  ).unwrap()
}

let owner = png_chunk_test_owner(capacity, fill=b'Z')
let pulled = owner.with_mut(0UL, capacity, fn(lease) {
  Ok(encoder.pull(lease))
}).unwrap()
if pulled.written() > capacity ||
  pulled.total_written() != before + pulled.written() { abort(...) }
for index = pulled.written(); index < capacity; index = index + 1UL {
  if owner.view().get(index).unwrap() != b'Z' { abort(...) }
}
```

For a zero-capacity schedule, retain a one-byte owner and lend a zero-length
view as the existing low-bit matrix does (lines 6013-6027). This leaves a
visible sentinel while `pull` must report `NeedOutput`, write zero bytes, and
leave `total_written` unchanged. Append only the accepted prefix; never use
the owner tail as stream output.

**Eager/chunk parity and strategy selection** (lines 4915-4972 and 5090-5144):

```moonbit
let eager = png_stream_indexed_low_bit_eager_with_compression(
  source, depth, PngCompressionStrategy::FixedOrStored,
)
let encoder = PngChunkEncoder::new_indexed_with_compression_strategy(
  source, depth, PngCompressionStrategy::FixedOrStored,
  png_stream_test_limits(), png_stream_test_budget(work=4096UL),
  @error.Diagnostics::new(),
).unwrap()
inspect(
  png_chunk_test_drain_encoder(encoder, [0UL, 1UL, 3UL, 2UL, 5UL]).unwrap() == eager,
  content="true",
)
```

Use the same shape for Indexed8 via
`png_stream_indexed8_eager_with_compression`. Construct a fresh eager and
chunk encoder for every schedule and every matrix case. Cover `Stored` and
`FixedOrStored`; retain the existing Dynamic capability rejection and assert
the stable `indexed-dynamic-compression-unavailable` context before any lease
can exist.

**Hostile matrix and completed terminal** (lines 6000-6049):

```moonbit
while turn < 4096UL {
  let capacity = schedule[(turn % schedule.length().to_uint64()).to_int()]
  let owner = png_chunk_test_owner(if capacity == 0UL { 1UL } else { capacity }, fill=b'Z')
  let before = output.length().to_uint64()
  let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
  if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
    abort("accepted-only progress")
  }
  for index = 0UL; index < pulled.written(); index = index + 1UL {
    output.push(owner.view().get(index).unwrap())
  }
  match pulled.outcome() {
    PngChunkPullOutcome::NeedOutput => turn = turn + 1UL
    PngChunkPullOutcome::Failed(_) => abort("drain failed")
    PngChunkPullOutcome::Finished => {
      if Bytes::from_array(output) != expected { abort("eager parity") }
      let later = png_chunk_test_owner(7UL, fill=b'Z')
      let replay = later.with_mut(0UL, 7UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
      if replay.written() != 0UL || replay.total_written() != pulled.total_written() ||
        !(replay.outcome() is PngChunkPullOutcome::Finished) { abort("sticky Finished") }
      return ()
    }
  }
}
```

Preserve the post-finish seven-byte sentinel check from lines 6036-6044,
including all bytes untouched. The required schedules are `[0UL, 1UL]`,
`[1UL]`, and `[0UL, 1UL, 3UL, 2UL, 5UL]`; add a longer ragged schedule only
if it remains deterministic and bounded.

**Released lease failure** (lines 6054-6076, with a generic
Fixed-or-Stored use at 4015-4038):

```moonbit
let released = png_chunk_test_owner(1UL, fill=b'Z')
let first = released.with_mut(0UL, 1UL, fn(lease) {
  lease.release()
  Ok(encoder.pull(lease))
}).unwrap()
let first_error = match first.outcome() {
  PngChunkPullOutcome::Failed(error) => error
  _ => abort("released lease outcome")
}
let later = png_chunk_test_owner(1UL, fill=b'Z')
let replay = later.with_mut(0UL, 1UL, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
let replay_error = match replay.outcome() {
  PngChunkPullOutcome::Failed(error) => error
  _ => abort("released lease replay")
}
if first.written() != 0UL || replay.written() != 0UL ||
  first.total_written() != 0UL || replay.total_written() != 0UL ||
  !png_chunk_test_same_error(first_error, replay_error) ||
  released.view().get(0UL).unwrap() != b'Z' || later.view().get(0UL).unwrap() != b'Z' {
  abort("released lease terminal")
}
```

For split parent/child lease ownership, the existing Indexed8 regression at
lines 6241-6308 is the closest extension: a split/inactive parent yields one
sticky zero-write failure, while a live child writes only inside its window
and the parent/tails remain `Z`. Reuse it if replay-accounting drift is part
of the selected evidence; do not invent a second lease abstraction.

**Independent collected-byte oracle** (lines 5328-5386 for Indexed8 Adam7 and
5900-5965 for low-bit Adam7):

The parser should be callable for both a fresh eager `Bytes` result and
`Bytes::from_array(output)` collected from accepted chunk prefixes; in the
chunk qualification call it with the collected value, not the eager bytes.
Preserve the existing test-local
`png_indexed_u32`, `png_indexed_slice`, and `png_indexed_crc32` helpers, then
validate in order: signature, IHDR (dimensions/depth/type-3/compression/filter/
interlace), actual PLTE, shortest canonical tRNS, IDAT, IEND, declared lengths,
and each CRC. For non-interlaced Fixed/Stored, independently inspect the zlib
header, DEFLATE BTYPE (`00` Stored or `01` Fixed), block bounds, Adler-32, and
filter-None packed rows including zero tail bits. Only after those checks invoke
the public decoder and compare every RGB8/RGBA8 coordinate to literal palette
and alpha values. The Adam7 parser's literal pass checks are a model for
pass-local packed rows, but Phase 87 must use non-interlaced row geometry.

## Supporting Pattern Assignments

### `modules/mb-image/png/encode_test.mbt` (test, eager request-response)

**Analogs:** `png_indexed_compression_source` (lines 970-991), selector and
legacy Stored compatibility test (lines 1106-1141), independent CRC/slice
helpers (lines 1276-1304), and Indexed8 Adam7 eager wire/decode test
(lines 1448-1534).

**Deterministic source and compatibility pattern** (lines 970-991, 1106-1131):

```moonbit
let source = png_indexed_compression_source(depth)
let legacy_writer = @io.MemoryWriter::new(...).unwrap()
ignore(PngEncoder::encode_indexed(
  PngEncoder::new(), source, depth, legacy_writer as &@io.Writer, ...
).unwrap())
let stored_writer = @io.MemoryWriter::new(...).unwrap()
ignore(PngEncoder::encode_indexed_with_compression_strategy(
  PngEncoder::new(), source, depth, PngCompressionStrategy::Stored,
  stored_writer as &@io.Writer, ...
).unwrap())
inspect(png_encode_prefix(legacy_writer) == png_encode_prefix(stored_writer), content="true")
```

Reuse this as the eager compatibility baseline. Retain the existing literals
for non-interlaced Indexed1/2/4/8 and all Adam7 Stored/None vectors; new tests
should compare explicit `Stored` to the old API and must not regenerate the
expected bytes through the new strategy.

**Independent frame helper pattern** (lines 1276-1304):

```moonbit
fn png_indexed_crc32(value : Bytes, start : Int, length : Int) -> UInt64 {
  let mut crc = 4294967295UL
  for index = 0; index < length; index = index + 1 {
    crc = crc ^ value[start + index].to_uint64()
    for bit = 0; bit < 8; bit = bit + 1 {
      crc = if (crc & 1UL) == 1UL { (crc >> 1) ^ 3988292384UL } else { crc >> 1 }
    }
  }
  crc ^ 4294967295UL
}
```

Use these test-local helpers (or a narrowly extended sibling) for chunk CRC,
u32 lengths, and byte slices. They must not call `_png_frame_facts`, matcher,
packing, or preflight. `png_encode_public_stored_scanlines` at lines 602-655
is a bounded Stored/None extractor; preserve its test-local shape and extend
only enough to parse the Fixed block/adler required by this phase.

**Public decode pattern:** the Indexed8 Adam7 test first checks literal frame
fields and CRCs, then owns the collected bytes and calls
`@codec.ImageDecoder::decode`, finally checking each palette coordinate and
alpha (lines 1490-1534). Keep decode as a semantic second oracle, never as a
substitute for wire parsing.

### `modules/mb-image/png/encode_wbtest.mbt` (test, batch/transform)

**Analog:** `png_indexed_compression_matrix_source` and its matrix test
(lines 1333-1426).

```moonbit
fn png_indexed_compression_matrix_source(
  profile : PngIndexedWireProfile,
  stored_fallback : Bool,
) -> PngIndexedImage {
  let depth = profile.depth()
  let width = 512UL / depth
  let cap = profile.palette_cap()
  // literal packed rows produce either an all-zero Fixed winner or a
  // literal-heavy Stored fallback; palette and one transparent entry are real.
  ...
}

for profile in [
  PngIndexedWireProfile::One, PngIndexedWireProfile::Two,
  PngIndexedWireProfile::Four, PngIndexedWireProfile::Eight,
] {
  for stored_fallback in [false, true] {
    let source = png_indexed_compression_matrix_source(profile, stored_fallback)
    // selected.plan is Fixed for the winner and Stored for the fallback.
  }
}
```

This is the established 512-pixel, all-four-depth corpus. Call it from the
public stream/eager qualification rather than rebuilding an expected raster.
Keep odd/narrow and partial-alpha fixtures alongside it to expose packed final
bytes and RGBA8 decode. The matrix test's full `PngFrameFacts` comparison is
white-box evidence; Phase 87's public parser must independently inspect the
wire bytes.

### `modules/mb-image/png/stream_encode_wbtest.mbt` (test, acknowledged state)

**Analog:** Fixed preview/acknowledgement stability (lines 544-565) and
replay mismatch sticky test (lines 641-699).

```moonbit
let byte = machine.present().unwrap().unwrap()
inspect(machine.present().unwrap() == Some(byte), content="true")
inspect(machine.completed() == completed, content="true")
machine.acknowledge(byte).unwrap()
inspect(machine.completed() == completed + 1UL, content="true")
```

The replay mismatch test captures the typed state error, confirms no pending
byte/CRC/Adler/progress mutation, calls `present` again, and compares the
replayed error with `png_stream_wb_same_error` (lines 588-599). If Phase 87
adds a white-box indexed Fixed replay-accounting case, copy this exact
mutation-before-EOB/sticky-error shape; do not alter production replay state.

### `modules/mb-image/png/png_test.mbt` (test, decode/request-response)

**Analogs:** hand-authored packed/zlib literals at lines 1-35 and the stored
zlib public decoder test at lines 669-702.

```moonbit
/// Hand-authored Type-0/1 PNG, including Stored-DEFLATE framing and CRCs.
fn png_test_gray1_qualification_literal() -> Bytes { ... }

let result = @codec.ImageDecoder::decode(
  PngDecoder::new(), reader as &@io.Reader,
  @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
  png_test_limits(), budget, diagnostics,
).unwrap()
inspect(result.image().view().get_byte(0UL, 0UL, 0UL).unwrap(), content="b'\\x12'")
```

Use this file's literal-first discipline for any new independent DEFLATE or
decode fixture. A parser test must own a bounded `OwnedBytes`, decode with
`require_complete_input=true`, and assert semantic RGB8/RGBA8 values plus
diagnostic cleanliness. Do not derive expected bytes from `PngDecoder` or
production compression planning.

### `modules/mb-image/png/stream_encode.mbt` (service, streaming contract)

**Analog:** indexed constructors (lines 23-96) and `PngChunkEncoder::pull`
(lines 694-780).

```moonbit
pub fn PngChunkEncoder::new_indexed_with_compression_strategy(...) -> Result[...] {
  let machine = match PngEncodeMachine::new_with_indexed_profile_and_strategy(
    source, _png_indexed_wire_profile(bit_depth),
    PngInterlaceStrategy::None, strategy, limits, budget, diagnostics,
  ) { Err(error) => return Err(error); Ok(value) => value }
  Ok({ state: PngChunkEncoderState::Active(machine), total_written: 0UL })
}
```

`pull` returns cached zero-write `Finished`/`Failed` before touching the lease
(lines 698-708), validates replay before its first `destination.set` (710-720),
and commits CRC/Adler/progress only after `destination.set` and
`machine.acknowledge` succeed (721-778). Phase 87 tests should observe this
contract through public selectors, not duplicate or replace it.

### `modules/mb-image/png/encode.mbt` (service/facade, eager)

**Analog:** `encode_indexed8_with_compression_strategy` and
`encode_indexed_with_compression_strategy` (lines 2468-2495 and 2560-2588).
Both construct `PngEncodeMachine::new_with_indexed_profile_and_strategy`,
emit via `present`, write one byte, then `acknowledge`. Eager bytes are the
fresh parity oracle only; collected chunk bytes remain the independent parser
input. No eager-only parser or second machine is permitted.

### `modules/mb-image/png/png.mbt` (model, transform)

**Analog:** `PngIndexedImage::new` (lines 246-334). It checks u32 dimensions,
checked `width * height`, index length, palette shape/count, alpha count, and
index bounds before the sole owned copy/charge. Reuse source fixtures through
this public constructor; do not widen the model or bypass its validation in a
qualification helper.

### Target/package configuration

**Analog:** `modules/mb-image/png/moon.pkg:15` declares exactly
`+js+wasm+wasm-gc+native`. `policy/foundation.json:1707-1735` repeats the
allowlist, production-source order, and package identity; `Assert-Policy.ps1`
checks the same target set and package inventory at lines 985-1003.

Run and record named ordinary gates:

```text
moon -C modules/mb-image test png --target native --frozen
moon -C modules/mb-image test png --target wasm --frozen
moon -C modules/mb-image test png --target wasm-gc --frozen
moon -C modules/mb-image test png --target js --frozen
moon -C modules/mb-image test png --target all --frozen
```

The quality lane's target loop and final all-target invocation are already in
`scripts/quality/Invoke-MoonQuality.ps1:793-800`; do not add target branches,
wrappers, release scripts, or copied source trees. If a pinned target is
unavailable, record the concrete command failure and still run the remaining
declared targets as D-05 permits.

## Shared Patterns

### One machine, two facades

**Sources:** `stream_encode.mbt:43-47,92-96,694-780` and
`encode.mbt:2477-2495,2570-2588`. Both eager and caller-buffered indexed
selectors converge on `PngEncodeMachine::new_with_indexed_profile_and_strategy`.
The chunk facade becomes `Active(machine)` only after successful admission;
the eager facade emits only after the same preflight. Phase 87 must qualify
this route, not add a stream/encoder or staging buffer.

### Accepted-only progress and caller-owned tails

**Sources:** `stream_encode_test.mbt:6000-6049` and `stream_encode.mbt:721-778`.
`written` and `total_written` advance only after an accepted lease byte and
`acknowledge`; rejected sentinel bytes stay untouched. The parser receives only
accepted prefixes.

### Sticky terminals

**Sources:** `stream_encode.mbt:698-708,710-718,732-778` and
`stream_encode_test.mbt:3981-4038,6054-6076`. `Finished`/`Failed` state is cached,
later pulls write zero bytes, totals remain at the accepted count, and later
sentinels remain unchanged. Error equivalence uses
`png_chunk_test_same_error` rather than string-only comparisons.

### Independent wire before public decode

**Sources:** `encode_test.mbt:599-655,1276-1304` and
`stream_encode_test.mbt:5328-5386,5900-5965`. Check signature, ordered chunk
lengths/types, PLTE/tRNS canonicalization, IDAT block framing, raw filter-None
rows/tails, Adler, and CRCs from literals/test-local arithmetic before invoking
`PngDecoder` for coordinate RGB8/RGBA8 semantics. Eager parity is an additional
assertion, never the only oracle.

### Fixed/Stored corpus and compatibility

**Sources:** `encode_wbtest.mbt:1333-1426`,
`stream_encode_test.mbt:695-719,4915-4972`, and
`encode_test.mbt:1106-1141`. Use deterministic winner/fallback sources and
compare complete frame bytes. Keep all legacy non-interlaced Indexed1/2/4/8
Stored and Indexed Adam7 Stored/None vectors byte-for-byte unchanged; explicit
`Stored` must equal the corresponding legacy selector.

### Four-target package gate

**Sources:** `moon.pkg:15`, `policy/foundation.json:1707-1735`, and
`scripts/quality/Invoke-MoonQuality.ps1:793-800`. The PNG package is already
portable across `js`, `wasm`, `wasm-gc`, and `native`; record the ordinary frozen
package command and each target result without changing package metadata.

## No Analog Found

| Concern | Closest partial analog | Planner guidance |
|---|---|---|
| Full independent Fixed-DEFLATE inflate/Adler parser for indexed Type-3 output | Stored extractor `png_encode_public_stored_scanlines` (`encode_test.mbt:602-655`) plus generic Fixed BTYPE assertion (`encode_test.mbt:3070-3086`) | Add a small test-local parser that validates Fixed/Stored block type, bounds, Adler, and packed rows. Do not call production matcher/planner/packing or an external compressor. |

## Metadata

**Analog search scope:** `modules/mb-image/png/{png,encode,encode_test,encode_wbtest,stream_encode,stream_encode_test,stream_encode_wbtest,png_test,structural_wbtest}.mbt`, `modules/mb-image/png/moon.pkg`, `policy/foundation.json`, `scripts/quality/{Assert-Policy,Invoke-MoonQuality}.ps1`  
**Files scanned:** 10 source/test/config files  
**Pattern extraction date:** 2026-07-24  
**Discovery note:** The codebase-memory graph had no scoped MoonBit nodes in this checkout; targeted source search/read was used per `AGENTS.md` fallback.
