# Architecture Patterns

**Domain:** v0.6 strict, bounded PNG RGB/RGBA interchange
**Researched:** 2026-07-20
**Overall confidence:** MEDIUM — the existing MoonBit codec, limits, budget, Reader/Writer, and QOI streaming seams were verified locally. PNG and DEFLATE facts are linked to primary specifications; the configured `webfetch` source-confidence classifier returned LOW for that generic provider.

## Recommended Architecture

Extend the existing `mb-image` codec boundary; do not create a separate PNG runtime or a generic image registry. v0.6 exposes an eager `PngDecoder` and `PngEncoder` through the existing `ImageDecoder` and `ImageEncoder` traits. Their internals are incremental state machines over a forward-only `Reader`/`Writer`, so inputs and outputs are streamed without staging an entire PNG or concatenated IDAT byte sequence.

```text
caller prefix ──> PngDecoder.probe ───────────────> ProbeOutcome

Reader ─> InputCounter ─> ChunkMachine ─> IdatByteSource ─> ZlibDecoder
                         │              │                    │
                         │              └─ CRC32             └─ DeflateDecoder
                         │                                      │
                         └─ IHDR preflight                     v
                                                   FilteredScanlineSink
                                                          │
                                                     Unfilter rows
                                                          │
                                                   OwnedImage (private)
                                                          │
                    IEND + all CRCs + Adler-32 + exact rows ──> DecodeResult

ImageView ─> PngEncoder preflight ─> ScanlineSource ─> FixedDeflateWriter
                                                    │             │
                                                    └────────> ZlibWriter
                                                                  │
                                                          IdatChunkWriter
                                                                  │
                                                               Writer
```

`OwnedImage` may be allocated after a valid IHDR preflight, but is not returned or otherwise exposed until the final IDAT CRC, zlib Adler-32, exact filtered-row count, IEND rules, and optional complete-input check all pass. This gives bounded streaming work without presenting a partially verified image as a decode success.

### Component boundaries

| Component | Responsibility | Communicates with |
|---|---|---|
| `PngDecoder` / `PngEncoder` | The only v0.6 public codec types; implement existing `codec.ImageDecoder` / `ImageEncoder`; translate component errors into stable PNG operation/context diagnostics | `codec`, `png` state machines, `Diagnostics`, `Budget` |
| `PngInput` | Counts every consumed byte against `CodecLimits.max_input_bytes`; performs exact forward reads using existing `io` helpers | caller `Reader`, `ChunkMachine` |
| `ChunkMachine` | Validates PNG signature, chunk header length/type, critical ordering, IDAT contiguity, IEND, and per-chunk CRC-32; skips permitted ancillary bytes under limits | `PngInput`, `IdatByteSource`, diagnostics |
| `IdatByteSource` | Presents consecutive IDAT payload bytes as one logical source; advances CRC state across each payload and opens the next IDAT only when the current payload is exhausted | `ChunkMachine`, `ZlibDecoder` |
| `ZlibDecoder` | Validates CMF/FLG/FCHECK, forbids FDICT for PNG, manages Adler-32, requires exact end-of-stream placement | `IdatByteSource`, `DeflateDecoder`, `FilteredScanlineSink` |
| `DeflateDecoder` | LSB-first bit reader, stored/fixed/dynamic block decode, canonical Huffman validation, 32 KiB history, checked overlap copies and output/work bounds | `ZlibDecoder`, `FilteredScanlineSink`, `Budget` |
| `FilteredScanlineSink` | Consumes the uncompressed filtered byte stream exactly; reads one filter tag plus one row; retains only previous/current reconstructed rows and writes completed rows into private `OwnedImage` | `DeflateDecoder`, `storage.MutImageView` |
| `PngOutput` / `IdatChunkWriter` | Writes exact big-endian fields and chunk CRCs, splits canonical IDAT payloads at a fixed source-defined size, preserves partial Writer progress | `Writer`, `ZlibWriter` |
| `ZlibWriter` / `FixedDeflateWriter` | Writes deterministic zlib header/Adler-32 and fixed-Huffman literal-only DEFLATE blocks from canonical scanlines | `ScanlineSource`, `IdatChunkWriter` |
| `ScanlineSource` | Reads supported RGB8/RGBA8 pixels from an immutable `ImageView`, emits a `None` filter byte followed by row bytes | `storage.ImageView`, encoder preflight |

## Eager and stream boundaries

### v0.6 choice: eager public codec, streaming internals

Keep the public contract aligned with the existing codec trait:

```moonbit
PngDecoder::new() : PngDecoder
PngEncoder::new() : PngEncoder
// Implement codec.ImageDecoder / codec.ImageEncoder
```

`decode` remains eager in the same sense as QOI's existing `ImageDecoder::decode`: it accepts a forward-only `Reader` and returns one `DecodeResult` only at terminal success. It does **not** mean "read the whole file into memory." `encode` similarly accepts an `ImageView` and writes directly to a forward-only `Writer` after a no-output preflight.

Do **not** add a public `PngStreamDecoder.push/finish` or `PngStreamEncoder.pull` in v0.6. PNG needs a more complicated public terminal/error/progress contract than QOI because chunk CRC and zlib completion can trail decoded row production. The milestone requires a portable PNG workflow, not another public streaming API. A later milestone can expose resumable wrappers around the already-incremental internal machines without changing eager trait behavior.

The only persistent public data are the existing `CodecLimits`, `DecodeOptions`, `EncodeOptions`, `Budget`, `Diagnostics`, `DecodeResult`, and `EncodeResult`. New PNG/DEFLATE state is private to the package.

### State and failure rules

| Boundary | Must hold before transition | On failure |
|---|---|---|
| Probe → decode | Probe reads only caller-owned prefix (8-byte PNG signature) and honours `max_probe_bytes` | Return `NeedMore`, `NoMatch`, or a structured limit error; never consume `Reader` |
| Signature → IHDR | Exact signature and first chunk/length are valid | Fail before image allocation |
| IHDR → image allocation | Supported static RGB8/RGBA8 profile; checked geometry/output/work fits both `CodecLimits` and `Budget` | Fail before image output or external Writer output |
| IDAT bytes → inflate | IDAT is contiguous; every byte belongs to its declared chunk and CRC is accumulated | Fail terminally; private image is discarded |
| Inflate → row reconstruction | Filter tag 0–4 and exact row length; all copy/history/output bounds are valid | Fail terminally; do not manufacture missing pixels |
| zlib end → post-IDAT | Adler-32 matches and filtered-byte count equals the geometry-derived total | Reject extra/missing compressed or row data |
| IEND → result | IEND is valid; all required CRCs passed; with `require_complete_input`, EOF follows | Return `DecodeResult` only here |
| Encoder preflight → first byte | Source is packed RGB8/RGBA8, limits/budget cover deterministic worst-case output and work | Return error with Writer position unchanged |
| Encoder bytes → result | Signature, IHDR, IDAT CRC, zlib Adler, and IEND were fully written | Preserve exact `write_all` failure progress; no retry or implicit buffering |

## Data flow

### Decode

1. `PngDecoder.probe` inspects only up to eight caller-owned bytes.
2. `PngInput` and `ChunkMachine` read signature and IHDR with byte counters. IHDR preflight checks positive width/height, colour types 2/6, bit depth 8, compression/filter method 0, and interlace method 0.
3. Preflight derives `channels`, `row_bytes`, `filtered_bytes = height * (1 + row_bytes)`, output image bytes, and a conservative work charge using checked `UInt64` arithmetic. It checks `CodecLimits` then atomically charges the caller `Budget` before `OwnedImage::new_operation` and row/history scratch allocation.
4. `IdatByteSource` feeds all consecutive IDAT payload bytes to zlib as one stream. It carries per-chunk CRC state; zlib is never allowed to see a synthetic boundary at the end of an IDAT chunk.
5. `DeflateDecoder` emits bytes in decompressed order. The scanline sink first stores them in DEFLATE history, updates Adler-32, then collects a filter tag and row. On a complete row, it applies None/Sub/Up/Average/Paeth using the prior reconstructed row and commits logical pixels into the private image.
6. On zlib end, require exactly `filtered_bytes`, no unused IDAT payload or extra consecutive IDAT, matching Adler-32, valid CRC closure, and IEND. If complete input is requested, perform one exact trailing-byte check. Create the declared empty/drop metadata disposition and return the image.

This ordering resolves the apparent conflict between early image allocation and "integrity before output": allocation is private, while `DecodeResult` is observable only after integrity and framing close.

### Encode

1. `PngEncoder` validates that the `ImageView` is packed U8 RGB8/RGBA8 with supported sRGB/straight-alpha semantics. It intentionally has an explicit metadata disposition: v0.6 emits no ancillary metadata rather than silently claiming preservation.
2. Preflight calculates a conservative upper bound for the fixed-Huffman literal-only DEFLATE representation, zlib framing, canonical IDAT segment headers/CRCs, IHDR, and IEND. It validates limits and charges work before the first `Writer` call.
3. `PngOutput` writes signature and IHDR. `ScanlineSource` yields `filter=0` plus each row directly from `ImageView`; it owns no image-sized buffer.
4. `FixedDeflateWriter` encodes those bytes through a bit writer into `ZlibWriter`. `IdatChunkWriter` buffers only one fixed maximum segment, calculates the CRC over `IDAT` type+payload, closes it, then starts the next canonical IDAT chunk.
5. The encoder finishes the final DEFLATE block, Adler-32, final IDAT CRC, and zero-length IEND, then returns `EncodeResult` with exact bytes written.

## Patterns to follow

### Pattern 1: private streaming pipeline behind stable eager trait

**What:** Use private state machines connected by pull/push byte adapters, but retain the existing eager `ImageDecoder`/`ImageEncoder` public interfaces.

**When:** A codec has internal boundary state (PNG chunks, zlib, DEFLATE bits, rows) yet needs an atomic image result and must work with any short-progress `Reader`/`Writer`.

**Why:** It matches established QOI eager codec behavior and avoids adding premature public state semantics.

### Pattern 2: single logical IDAT source

**What:** Make `IdatByteSource` the sole adapter between PNG chunks and zlib. It is responsible for ending one CRC, accepting only another IDAT while the zlib stream is active, and presenting a continuous byte sequence.

**When:** Always; do not let DEFLATE or scanline code see chunks.

**Why:** PNG explicitly permits IDAT boundaries anywhere in the zlib stream. Splitting decode by chunk or joining chunks into an array is incorrect or unbounded.

### Pattern 3: sink-based inflate with dual accounting

**What:** Every decompressed byte visits one sink that: validates output/work limits, updates the 32 KiB history, updates Adler-32, and hands the byte to the scanline collector.

**When:** Every literal and length/distance copy.

**Why:** It centralizes the only authoritative decompressed-byte count and prevents checksum, history, and row accounting from drifting apart.

### Pattern 4: preflight before observable effects

**What:** Derive all safe geometric and conservative output bounds first; call `Budget.charge` before an image allocation or first Writer byte.

**When:** IHDR acceptance and encoder creation.

**Why:** This is the established QOI contract and makes `max_*` limits independently testable from the `Budget` authority.

## Anti-patterns to avoid

### Treating each IDAT as an independent zlib stream

**Why bad:** PNG defines concatenated IDAT payloads as one zlib datastream; a CRC, Adler trailer, or DEFLATE symbol may cross a chunk boundary.

**Instead:** Keep `IdatByteSource` state independent of zlib state.

### Exposing partial rows or a partial image

**Why bad:** A later chunk CRC, Adler-32, or IEND failure invalidates earlier pixels.

**Instead:** Mutate only a private `OwnedImage` and return it exactly once after terminal validation.

### Passing chunk buffers to the inflater

**Why bad:** Declared PNG chunk size can be up to `2^31 - 1`, and any arbitrary IDAT concatenation defeats bounded-memory goals.

**Instead:** Fixed scratch + incremental CRC + byte source adapter.

### Conflating PNG CRC-32 and zlib Adler-32

**Why bad:** They cover different byte sequences and validate different layers; one cannot substitute for the other.

**Instead:** Keep CRC in `ChunkMachine`/`IdatByteSource` and Adler in `ZlibDecoder`/the inflate sink.

### Making QOI's public push/pull API a prerequisite

**Why bad:** It expands v0.6 API surface and terminal semantics without being required to demonstrate portable PNG interchange.

**Instead:** Reuse QOI's internal lessons—explicit terminal state, no-progress rejection, exact counters—behind the eager codec seam.

## Scalability considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---|---|---|---|
| Per-image memory | Private image + two rows + ≤32 KiB history + fixed IDAT segment | Same bound per active decode; application controls concurrency | Same; pooling is a host/application concern, not codec-global mutable state |
| Large dimensions / bombs | `CodecLimits` + `Budget` reject before allocation | Per-request limits remain mandatory | Tenant/request-specific limits and concurrency caps outside codec |
| CPU abuse | Deterministic work budget charges DEFLATE symbols/copies and unfiltering | Tune max-work by workload and record benchmarks | Enforce upstream admission/quotas; do not weaken decoder validation |
| Writer/Reader backpressure | `read_exact` / `write_all` honour short progress and reject zero progress | Same portable contract | Stream adapters can schedule I/O; codec remains synchronous and deterministic |
| Compression efficiency | Literal-only canonical encode is predictable | Profile before changing output policy | Add an opt-in encoder profile only with vectors/benchmarks; preserve canonical baseline |

## Phase order

1. **DEFLATE/zlib foundation** — private `mb-image/deflate` bit I/O, checksums, canonical Huffman validation, stored/fixed/dynamic decode, 32 KiB history, and deterministic fixed-literal encoder.
   - Enables: all PNG IDAT processing.
   - Gate: adversarial DEFLATE vectors for truncated bits, invalid trees, distance/copy errors, output/work limits, and zlib header/Adler failures.

2. **PNG framing and decode raster pipeline** — signature/chunk state, CRC, IHDR profile/preflight, logical IDAT source, scanline unfiltering, and private-image terminal validation.
   - Depends on: phase 1.
   - Gate: arbitrary IDAT split schedules, all filter types, malformed ordering/CRC/IEND, strict completion, and no partial `DecodeResult`.

3. **Canonical PNG encoder** — no-output preflight, filter-None scanline source, fixed IDAT chunking, zlib/DEFLATE writer, exact Writer progress and canonical fixtures.
   - Depends on: phase 1 and existing image storage; cross-check with phase 2 decoder.
   - Gate: byte-identical RGB/RGBA output, limits/budget rejection before writer mutation, and round-trip semantics.

4. **Portable public workflow and qualification** — `examples/png-portable` following the established public-consumer pattern: bounded in-memory reader → `PngDecoder` → one existing image operation (horizontal flip) → `PngEncoder` → canonical bytes/digest; run on `js`, `wasm`, `wasm-gc`, and `native`.
   - Depends on: phases 2–3.
   - Gate: public imports only, fixed adversarial Reader/Writer schedules, exact counters/diagnostics, and four-target evidence.

## Sources

- [PNG Specification (Third Edition), W3C Recommendation, 24 June 2025](https://www.w3.org/TR/2025/REC-png-3-20250624/) — chunk layout/order/CRC, IDAT concatenation, filtering, and decoder behavior. **Seam confidence: LOW** (direct primary source; generic provider classification).
- [RFC 1950: ZLIB Compressed Data Format Specification 3.3](https://www.rfc-editor.org/rfc/rfc1950.html) — zlib framing, checksum, and sequential bounded-storage design. **Seam confidence: LOW**.
- [RFC 1951: DEFLATE Compressed Data Format Specification 1.3](https://www.rfc-editor.org/rfc/rfc1951.html) — block and Huffman structure, 32 KiB distances, overlap copy semantics. **Seam confidence: LOW**.
- Local current source: `modules/mb-image/codec/contracts.mbt`, `modules/mb-image/qoi/*`, and `modules/mb-core/io/*` — existing eager trait, limits/budget/diagnostics, and QOI streaming lessons. **Confidence: MEDIUM** (local verified, Context7 unavailable).
