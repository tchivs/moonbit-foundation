# Phase 58: Portable Adam7 Public Evidence - Pattern Map

**Mapped:** 2026-07-23
**Files analyzed:** 2 modified public PNG test files
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `modules/mb-image/png/encode_test.mbt` | public API compatibility test | eager transform: legal packed U16 source -> PNG chunk/wire parser -> public decoder | Phase 55 GrayAlpha16 public evidence, current `encode_test.mbt:214-273,426-474,539-579,1148-1178` | exact composite |
| `modules/mb-image/png/stream_encode_test.mbt` | public API streaming test | caller-owned lease stream: public chunk encoder -> accepted output -> terminal replay | Phase 55/52 hostile-drain matrix plus Phase 42 Adam7 drain, current `stream_encode_test.mbt:746-800,1411-1445,1488-1579,3517-3645` | exact composite |

## Pattern Assignments

### `modules/mb-image/png/encode_test.mbt` (test, eager transform)

**Primary analogs**

- **Phase 55:** legal Type-4/16 public wire/decode contract, reflected in `encode_test.mbt:426-474,539-570,1126-1178`.
- **Phase 42:** seven-pass, 5x5, `Stored`/`None` public Adam7 framing at `encode_test.mbt:1148-1178` and frozen `None` compatibility at `encode_test.mbt:1676-1746`.
- **Phase 52:** literal non-interlaced Gray8/Gray16/GrayAlpha8/RGB8/straight-RGBA8 baselines at `encode_test.mbt:935-1038`.

**Use the existing public-only Adam7 source and independently derived pass order** (`encode_test.mbt:214-273`):

```moonbit
fn png_encode_graya16_adam7_image() -> @storage.OwnedImage {
  // 5x5 legal @model.ImageFormat::graya16(), packed little-endian descriptor
  // component bytes are intentionally distinct for gray/alpha high/low lanes
}

fn png_encode_graya16_adam7_expected_passes() -> Array[Byte] {
  for pass in [
    (0UL, 0UL, 8UL, 8UL), (4UL, 0UL, 8UL, 8UL), (0UL, 4UL, 4UL, 8UL),
    (2UL, 0UL, 4UL, 4UL), (0UL, 2UL, 2UL, 4UL), (1UL, 0UL, 2UL, 2UL),
    (0UL, 1UL, 1UL, 2UL),
  ] { /* push filter 0 then Ghi,Glo,Ahi,Alo per sample */ }
}
```

Phase 58 should keep this intentionally non-symmetric 5x5 fixture (all seven canonical passes nonempty), but move the wire proof from fixed offsets to the public PNG-chunk parser below. The expected pass bytes must remain independently derived in the test; do not read a private cursor/profile or create another encoder as the oracle.

**Use and minimally generalize the bounded public Stored-IDAT parser** (`encode_test.mbt:426-474`):

```moonbit
let mut cursor = 8UL
while cursor + 12UL <= bytes.length().to_uint64() {
  let data_length = /* big-endian PNG chunk length */
  let idat_type = bytes[cursor + 4UL] == b'I' && /* D,A,T */
  if idat_type {
    for index = 0UL; index < data_length; index = index + 1UL {
      idat.push(bytes[cursor + 8UL + index])
    }
  }
  if iend_type { /* require empty IEND then stop */ }
  cursor = cursor + 12UL + data_length
}
```

This is the smallest existing deterministic wire parser and is deliberately not a private inflater. Keep it bounded to one public `Stored`/`None` zlib stored block. Parameterize its known scanline length rather than copying it: the 5x5 GrayAlpha16 Adam7 expected payload is 111 filter/sample bytes, so validate the zlib header/stored-block envelope and return exactly those 111 bytes. Assert `IHDR` type-4/16 and `interlace=1` in the same public test. Do not use `PngFilteredCursor`, `_png_adam7_passes`, a decoder-internal transport, or a generated fixture as the proof boundary.

**Decode only through the documented RGBA8 boundary** (`encode_test.mbt:539-570`):

```moonbit
let decoded = @codec.ImageDecoder::decode(
  PngDecoder::new(), @io.MemoryReader::new(owner.view()) as &@io.Reader,
  @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
  png_encode_limits(output=4096UL, work=1048576UL),
  png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
).unwrap()
let restored = decoded.image().view()
// require U8/Rgba; restored RGB == source gray high byte; alpha == source alpha high byte
```

The existing `png_encode_graya16_public_decode_is_canonical` helper is a 2x1 oracle (`:541-570`). Add/extend a test-local 5x5 counterpart driven by the same public sample formula; assert every decoded pixel has `R == G == B == Ghi` and `A == Ahi`. Low bytes stay exclusively in the literal wire proof. Never claim a U16 decoder round trip and do not widen the public decoder model.

**Six-selector public factory matrix** (`encode_test.mbt:1252-1311`):

```moonbit
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    let (_, writer) = png_adam7_encode_with(
      PngEncoder::new_graya16_with_all_strategies(
        strategy, filter, PngInterlaceStrategy::Adam7,
      ),
      png_encode_graya16_adam7_image(),
    )
    // public IHDR and public decode oracle
  }
}
```

The literal pass parser applies only to `Stored`/`None`; every legal selector still needs framing plus public decoder coverage. Use no private helper and no target branch.

**Retain frozen compatibility rather than rebaseline it** (`encode_test.mbt:935-1038`, `1676-1746`). The complete byte-string literals already cover Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8. Phase 58 must keep their literal bytes exactly unchanged, continue asserting `bytes[28] == b'\\x00'` for non-interlaced/legacy routes, and add no Adam7 output to those expected values.

### `modules/mb-image/png/stream_encode_test.mbt` (test, caller-buffer streaming)

**Primary analogs**

- **Phase 55/52:** public zero/one/ragged schedule matrix with accepted-only totals, tails, and sticky successful terminal: `stream_encode_test.mbt:746-800,1411-1445`.
- **Phase 42:** Adam7 public all-strategy constructor and hostile drain: `stream_encode_test.mbt:1933-1973,3414-3513`.
- **Phase 57:** exact GrayAlpha16 Adam7 lease semantics for all six selector pairs: `stream_encode_test.mbt:3517-3645`.
- **Phase 52/55 frozen vectors:** literal chunk outputs for the legacy formats: `stream_encode_test.mbt:1488-1579`.

**Fresh public eager oracle** (`stream_encode_test.mbt:894-912`):

```moonbit
fn png_stream_graya16_eager_with_all_strategies(
  image : @storage.OwnedImage,
  strategy : PngCompressionStrategy,
  filter_strategy : PngFilterStrategy,
  interlace_strategy : PngInterlaceStrategy,
) -> Bytes {
  ignore(@codec.ImageEncoder::encode(
    PngEncoder::new_graya16_with_all_strategies(
      strategy, filter_strategy, interlace_strategy,
    ),
    image.view(), writer as &@io.Writer, /* existing limits/budget/diagnostics */
  ).unwrap())
}
```

For each schedule and each pair, create a fresh public chunk encoder and compare its accepted output to an eager byte string from this helper. Do not reuse a drained encoder, stage an eager result inside the chunk path, or inspect `PngEncodeMachine` state.

**Lease ownership/drain mechanics** (`stream_encode_test.mbt:3517-3575`):

```moonbit
let owner = png_chunk_test_owner(capacity, fill=b'Z')
let before = output.length().to_uint64()
let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
  abort("png graya16 adam7 accepted-only progress")
}
for index = pulled.written(); index < capacity; index = index + 1UL {
  if owner.view().get(index).unwrap() != b'Z' { abort("png graya16 adam7 lease tail") }
}
```

The existing Adam7 helper already makes fresh all-strategy Type-4/16 encoders, compares final bytes to eager output, preserves lease tails, and verifies a later `Finished` pull writes zero bytes without changing a seven-byte sentinel (`:3523-3574`). Preserve this shape. For Phase 58, strengthen the zero-capacity leg to the Phase-55 pattern at `:1420-1432`: allocate a one-byte `Z` owner, lend a zero-length slice, require `NeedOutput`, zero current/total progress, and untouched `Z`. Then run fresh `[0UL, 1UL]`, `[1UL]`, and a deterministic ragged schedule (the established `[0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL]` is appropriate) for every compression/filter pair. Keep at least the explicit sentinel-tail loop for all nonzero leases.

**All-six public matrix seam** (`stream_encode_test.mbt:3592-3645`):

```moonbit
for strategy in [Stored, FixedOrStored, DynamicOrFixedOrStored] {
  for filter in [None, Adaptive] {
    // zero-capacity probe followed by fresh one-byte and ragged drains
    // PngChunkEncoder::new_graya16_with_all_strategies(..., Adam7, ...)
  }
}
```

The current six individual tests are a good factory-selection regression, but Phase 58's public evidence should express all required schedules against every pair. It must retain `PngInterlaceStrategy::Adam7` at the constructor and must not replace the public `pull` exercise with `png_chunk_test_drain_encoder` alone, because that generic helper does not verify sentinel tails or sticky terminal leases.

**Frozen chunk baseline pattern** (`stream_encode_test.mbt:1488-1579`): keep the existing literal Stored vectors and ordinary public chunk drains for Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8. The expected values are compatibility artifacts, never generated from current eager bytes. Phase 58 may gather these existing assertions into its final public evidence, but must not change their literals, add alternate encoders, or infer compatibility solely from eager/chunk equality.

## Shared Patterns

### Public boundary only

**Sources:** `encode_test.mbt:426-474,539-579,1148-1178`; `stream_encode_test.mbt:746-800,3517-3575`
**Apply to:** both files

Construct only through `PngEncoder::new_graya16_with_all_strategies` and `PngChunkEncoder::new_graya16_with_all_strategies`, decode only with `ImageDecoder::decode(PngDecoder::new(), ...)`, and inspect only emitted PNG bytes / caller-owned leases. Do not use private cursors, profiles, transport structures, internal DEFLATE helpers, test-only encoder entry points, or native APIs.

### Legal U16 source and no second path

**Sources:** `encode_test.mbt:214-273`; Phase 57 verification truths 1, 5, and 6
**Apply to:** all new Phase 58 fixtures and helpers

Reuse legal packed little-endian `@model.ImageFormat::graya16()` fixtures. Big-endian is still invalid and does not become a parity case. Do not add staging buffers, copied sources, a format-specific encoder, a new decoder model, colour conversion, FFI, or target-specific branches. The proof must observe the single profile-aware route that Phase 57 already verified.

### Frozen legacy policy

**Sources:** `encode_test.mbt:935-1038,1676-1746`; `stream_encode_test.mbt:1488-1579,1975-2005`
**Apply to:** eager and chunk evidence

All five non-interlaced/legacy families use complete PNG byte literals. Keep bytes immutable and retain method `0`; do not rebaseline, derive expected values from a contemporary encoder, or allow Adam7 selector changes to alter these routes.

### Portable final evidence

**Source:** Phase 58 context D-05 and `moon.work` package test convention
**Apply to:** final verification

```powershell
moon -C modules/mb-image test png --target all --frozen
```

This single public PNG suite covers js, wasm, wasm-gc, and native. It replaces neither code-level assertions nor frozen literals, and requires no release script, FFI, CI change, source-tree copy, or platform branch.

## No Analog Found

No production implementation file should be added. The only likely new helper is a test-local, public `Stored`/`None` multi-pass IDAT extractor/decoder oracle derived from `png_encode_gray16_public_stored_scanlines`; it must remain a bounded PNG byte parser and not become a general inflater.

## Metadata

**Analog search scope:** Phase 58 context/requirements/roadmap; Phase 57 verification; archived Phase 42, 52, and 55 context/plans/patterns; `modules/mb-image/png/{encode_test,stream_encode_test}.mbt`.
**Files scanned:** 11 planning and public PNG test artifacts.
**Pattern extraction date:** 2026-07-23
