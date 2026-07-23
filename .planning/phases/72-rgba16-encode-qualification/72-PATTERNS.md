# Phase 72: RGBA16 Encode Qualification - Pattern Map

**Mapped:** 2026-07-23  
**Files classified:** 2 production-test files (plus this planning artifact)  
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data flow | Closest existing analog | Match quality |
|---|---|---|---|---|
| `modules/mb-image/png/encode_test.mbt` | public integration/regression test | transform: source image -> eager PNG wire -> bounded test parser + public RGBA16 decode | Existing RGBA16 normal and Adam7 evidence in the same file | exact |
| `modules/mb-image/png/stream_encode_test.mbt` | public streaming/regression test | streaming: source view -> fresh chunk encoder -> caller lease -> accepted prefix -> terminal replay | Existing RGBA16 normal and Adam7 hostile-drain/lifecycle evidence in the same file | exact |

`modules/mb-image/png/png_test.mbt` is a related explicit-decode qualification corpus, not the implementation location for this phase's eager/chunk encoder evidence. Do not move the existing public encoder tests into it. `moon.pkg`, scripts, fixtures, target wrappers, and production `.mbt` files are not phase inputs.

## Pattern Assignments

### `modules/mb-image/png/encode_test.mbt` — independent eager wire and decode qualification

**Primary analogs:**

- `encode_test.mbt:351-415` — non-symmetric 5x5 RGBA16 source and independent all-seven-pass Type-6/16 raster oracle.
- `encode_test.mbt:594-647` — deliberately bounded public PNG/Stored-DEFLATE parser, not a production cursor or general inflater.
- `encode_test.mbt:1410-1456` — normal Type-6/16 eager wire order plus explicit `decode_rgba16` lane comparison.
- `encode_test.mbt:1514-1585` — Adam7 Stored/None wire oracle, selector parity, full lane decode, and three-by-two framing matrix.
- `encode_test.mbt:1181-1245` (continue the existing test rather than split it) — literal method-0 legacy eager baseline convention.

**Fixture and independent-oracle pattern** (`encode_test.mbt:351-415`):

```moonbit
for y = 0UL; y < 5UL; y = y + 1UL {
  for x = 0UL; x < 5UL; x = x + 1UL {
    let sample = y * 5UL + x
    for component = 0UL; component < 4UL; component = component + 1UL {
      view.set_component_byte(x, y, component, 0UL,
        (b'\\x10'.to_uint64() + 32UL * component + sample).to_byte()).unwrap()
      view.set_component_byte(x, y, component, 1UL,
        (b'\\x80'.to_uint64() + 32UL * component + sample).to_byte()).unwrap()
    }
  }
}
```

Copy the *formula* and the compact Adam7 tuple loop, not encoder traversal. The expected PNG bytes must use PNG `high,low` U16 order in R/G/B/A component order, while the source and explicit decode checks use packed little-endian `lane 0, lane 1`. Keep every component and lane distinct; symmetric pixels or high-byte-only expectations are invalid here.

**Bounded wire-parser pattern** (`encode_test.mbt:594-647`):

```moonbit
if cursor + 12UL + data_length > bytes.length().to_uint64() {
  abort("png gray16 public chunk bounds")
}
...
if !saw_iend || idat.length() != (scanline_length + 11UL).to_int() {
  abort("png gray16 public stored idat shape")
}
...
if idat[0] != b'\\x78' || idat[1] != b'\\x01' || idat[2] != b'\\x01' { abort(...) }
```

For a `Stored` / `None` proof, reuse this parser with the known normal or Adam7 scanline length and compare it against an independently authored expected raster. It is intentionally restricted to the known Stored block. Do not add a generic inflater, a private cursor/profile assertion, or an encoder-derived expected byte string.

**Normal eager public seam** (`encode_test.mbt:1413-1455`):

```moonbit
let (_, writer) = png_encode_with(
  PngEncoder::new_rgba16_with_strategies(
    PngCompressionStrategy::Stored, PngFilterStrategy::None,
  ),
  rgba,
)
let bytes = png_encode_prefix(writer)
let restored = PngDecoder::decode_rgba16(
  @io.MemoryReader::new(owner.view()) as &@io.Reader,
  @codec.DecodeOptions::new(require_complete_input=true, preserve_opaque_metadata=false),
  png_encode_limits(output=4096UL, work=1048576UL),
  png_encode_budget(bytes=4096UL, work=1048576UL), @error.Diagnostics::new(),
).unwrap().image().view()
```

Retain the `IHDR` assertions (`depth == 16`, `colour type == 6`, `interlace == 0`) and compare every decoded component/lane explicitly. Strengthen this route, if needed, by using the bounded Stored parser and independent normal raster instead of relying only on absolute output offsets (`:1423-1430`). The emitted eager PNG may be the chunk-parity oracle, but never the sole fidelity oracle.

**Adam7 eager public seam** (`encode_test.mbt:1516-1564`):

```moonbit
let expected = Bytes::from_array(png_encode_rgba16_adam7_expected_passes())
...
if bytes[24] != b'\\x10' || bytes[25] != b'\\x06' || bytes[28] != b'\\x01' ||
  png_encode_gray16_public_stored_scanlines(bytes, 211) != expected {
  abort("png rgba16 Adam7 eager pass profile")
}
...
for y = 0UL; y < 5UL; y = y + 1UL {
  for x = 0UL; x < 5UL; x = x + 1UL {
    for component = 0UL; component < 4UL; component = component + 1UL {
      for lane = 0UL; lane < 2UL; lane = lane + 1UL { ... }
    }
  }
}
```

Use the two explicit Adam7 eager constructors shown at `:1520-1526`; for the six legal selector pairs, use the existing nested `Stored|FixedOrStored|DynamicOrFixedOrStored` × `None|Adaptive` matrix at `:1567-1585`. When expanding evidence, apply the same independent decode helper/oracle after framing checks where the test needs fidelity evidence; do not claim a six-pair framing-only loop is a wire/decode oracle.

**Legacy compatibility pattern** (`encode_test.mbt:1181-1245`): keep literal complete Stored/None PNG byte values and assert `bytes[28] == b'\\x00'`. Preserve the smallest existing Gray8, Gray16, GrayAlpha8, RGB8, and RGBA8 normal baselines byte-for-byte. RGBA16 and Adam7 wire fixtures are separate evidence, never replacements for these frozen method-0 compatibility artifacts.

### `modules/mb-image/png/stream_encode_test.mbt` — eager/chunk selector, hostile lease, and lifecycle qualification

**Primary analogs:**

- `stream_encode_test.mbt:982-1037` — normal RGBA16 public drain with accepted-prefix accounting and sticky-success lease check.
- `stream_encode_test.mbt:1130-1168` — fresh eager output used only as a separately constructed caller-buffered parity oracle.
- `stream_encode_test.mbt:1888-2019` — normal and Adam7 three-by-two selector matrices with direct zero, one-byte, and ragged schedules.
- `stream_encode_test.mbt:2021-2106` and `:4538-4697` — atomic admission, released-lease terminal, and source-revision/mutation replay seams.
- `stream_encode_test.mbt:2150-2235` (continue the existing test) — literal method-0 legacy chunk-vector convention.

**Normal hostile-drain pattern** (`stream_encode_test.mbt:982-1037`):

```moonbit
let pulled = owner.with_mut(0UL, capacity, fn(lease) { Ok(encoder.pull(lease)) }).unwrap()
if pulled.written() > capacity || pulled.total_written() != before + pulled.written() {
  abort("png rgba16 public accepted progress")
}
for index = pulled.written(); index < capacity; index = index + 1UL {
  if owner.view().get(index).unwrap() != b'Z' { abort("png rgba16 public lease tail") }
}
...
if later.written() != 0UL || later.total_written() != pulled.total_written() ||
  !(later.outcome() is PngChunkPullOutcome::Finished) { abort(...) }
```

Construct a fresh `PngChunkEncoder::new_rgba16_with_strategies(...)` inside each drain. Seed each caller lease with `b'Z'`; append exactly `written` bytes, assert `total_written` increases only by the accepted prefix, and prove both the current tail and a later seven-byte successful-terminal lease remain untouched. A zero capacity listed in a schedule does **not** replace the direct zero-length lease assertion.

**Selector/schedule matrix** (`stream_encode_test.mbt:1888-1919` and `:2001-2018`):

```moonbit
for strategy in [
  PngCompressionStrategy::Stored,
  PngCompressionStrategy::FixedOrStored,
  PngCompressionStrategy::DynamicOrFixedOrStored,
] {
  for filter_strategy in [PngFilterStrategy::None, PngFilterStrategy::Adaptive] {
    // direct empty lease, then independent drains
    ... [0UL, 1UL] ...
    ... [1UL] ...
    ... [0UL, 8UL, 4UL, 1UL, 13UL, 2UL, 5UL, 3UL, 21UL] ...
  }
}
```

For Adam7 use `PngChunkEncoder::new_rgba16_with_all_strategies(..., PngInterlaceStrategy::Adam7, ...)` and its matching eager all-strategies factory (`:1924-1978`). Keep normal and Adam7 drains independent: an eager output is valid only for chunk identity after a separately derived wire/decode oracle has proved each path's data fidelity.

**Atomic admission and failure replay patterns:**

- Copy `png_rgba16_combined_public_reject` (`:4540-4581`) for incompatible descriptor plus output/work/budget admission. Pair eager `ImageEncoder::encode(...).unwrap_err()` with chunk construction `unwrap_err()`, require the same typed error, `writer.position() == 0`, unchanged caller budget, and unchanged sentinel owner.
- Copy `png_rgba16_replay_mutation_is_sticky` (`:4586-4637`) for source-revision failure: acknowledge a prefix, mutate the source, then require zero newly written bytes, unchanged accepted total, same error on a later pull, and unchanged first/later `Z` leases.
- Copy the released-lease shape (`:4671-4697`; Adam7 analogue `:2052-2068`): call `lease.release()` before `pull`, require a zero-write `Failed`, replay the same typed failure on a fresh lease, and keep both owners unchanged.

Use clear lower-case `png rgba16 ...` abort labels matching the existing family. Assertions that describe a failure must check outcome, bytes written, cumulative total, error identity, and caller memory—checking only `Err` or only a total is insufficient.

**Legacy chunk compatibility pattern** (`stream_encode_test.mbt:2150-2235`): drain real legacy chunk encoders through the established `[0UL, 1UL, 3UL, 2UL, 5UL]` schedule, compare to literal complete PNG values, and assert interlace method `0`. Do not regenerate these expected values with an encoder and do not blend explicit RGBA16/Adam7 data into this frozen corpus.

## Shared Patterns

### Public API boundary and data-oracle separation

Apply to both files. Build output only through public `PngEncoder` / `PngChunkEncoder`, inspect output via a bounded test parser, and decode through public `PngDecoder::decode_rgba16`. Expected raster bytes and decoded U16 lanes come from independently authored source formulas/fixtures. Do not call private traversal, cursor, profile, or test-only production hooks.

### U16 endian boundary

Apply to normal and Adam7 evidence. Source and `decode_rgba16` checks are packed little-endian storage (`lane 0` low, `lane 1` high); PNG Type-6/16 wire is big-endian per component (`high,low`). Assert all four components, both lanes, and every Adam7 pass. Never reduce this to RGBA8 high-byte canonicalization.

### Freshness, ownership, and terminal state

Apply to all caller-buffered tests. A new encoder is required for each hostile drain; a new eager encoder supplies only parity bytes for the corresponding strategy/filter/interlace selection. Tests must distinguish `NeedOutput`, `Finished`, and `Failed(error)` and protect caller-owned tails with `Z` sentinels. After either success or terminal failure, later pulls must write zero bytes, preserve the accepted total, retain terminal identity, and leave the later lease untouched.

### Test naming and portability gate

Use `test "PNG RGBA16 ..."` names and narrow functions prefixed `png_encode_rgba16_` / `png_stream_rgba16_` / `png_rgba16_`. Keep tests MoonBit-only in the existing `png` package. The integration command is exactly:

```text
moon -C modules/mb-image test png --target all --frozen
```

Run it as the ordinary full package suite after focused native tests; it is the four-target proof for wasm, wasm-gc, js, and native. Do not create a target wrapper, release script, copied source tree, recovery/debug directory, or target-specific test branch.

## Explicit Anti-Patterns

| Do not do this | Why it is invalid | Existing pattern to use instead |
|---|---|---|
| Derive expected normal/Adam7 pixels or wire bytes from encoder output. | A self-oracle can hide the same traversal/endian defect in both sides. | Independent formulas and Adam7 tuple loop at `encode_test.mbt:351-415`; bounded parser at `:594-647`. |
| Treat fresh eager/chunk byte equality as fidelity proof. | It proves only parity between two encoder routes. | Pair it with independently parsed Stored/None bytes and full `decode_rgba16` lanes. |
| Add a general DEFLATE decoder or duplicate a production pass cursor. | Expands scope and ceases to be bounded public evidence. | The known-structure Stored parser at `encode_test.mbt:594-647`. |
| Append an entire caller lease or accept a terminal outcome without tail checks. | Only the reported prefix is encoder-owned. | `written` prefix / `Z` tail / later lease pattern at `stream_encode_test.mbt:982-1037`. |
| Reuse an encoder after a prior hostile schedule. | Initial capacity and terminal behavior can be hidden by prior state. | Construct the chunk encoder inside each drain and perform the direct zero-length pull first. |
| Replace frozen legacy values with generated expectations or alter their method-0 behavior. | This silently weakens the compatibility contract. | Existing literal eager/chunk vectors at `encode_test.mbt:1181+` and `stream_encode_test.mbt:2150+`. |
| Add production code, APIs, FFI, fixtures, scripts, source copies, staging encoders, or a second pass planner. | Phase 72 is qualification-only and must stay source-tree-only. | Test-only adjustments in the two assigned public test files. |

## No Analog Found

None. The repository already contains exact public RGBA16 normal/Adam7, bounded parser, hostile chunk, lifecycle, and frozen compatibility seams. The planner should extend these seams minimally rather than introduce helpers in another package.

## Metadata

**Analog search scope:** `modules/mb-image/png/{encode_test,stream_encode_test,png_test}.mbt`; Phase 55, 58, and 61 plans/summaries and verification records.  
**Files scanned:** 3 current PNG test files; 12 historical plan/summary files (with focused Phase 58/61 evidence records).  
**Pattern extraction date:** 2026-07-23
