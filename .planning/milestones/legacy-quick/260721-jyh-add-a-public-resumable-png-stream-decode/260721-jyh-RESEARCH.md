# Public Resumable PNG Decode — Focused Research

**Date:** 2026-07-21  
**Scope:** first safe public, caller-chunk-fed PNG decode phase; codebase-grounded only.  
**Conclusion:** this is a **new milestone / planned phase**, not a quick task.

## Recommendation

Expose a decode-only `PngChunkDecoder` API, deliberately **not** `PngStreamDecoder` (the quality negative fixture explicitly prohibits that name), with the same caller-owned `ByteView` and explicit `finish()` shape as QOI. [VERIFIED: `scripts/quality/Assert-Policy.ps1:1020`; `modules/mb-image/qoi/qoi.mbt:9-55`]

```moonbit
pub struct PngChunkDecoder { /* private state */ }
pub(all) enum PngChunkPushOutcome { NeedInput; Failed(@error.CoreError) }
pub struct PngChunkPushResult { /* consumed + outcome */ }

pub fn PngChunkDecoder::new(
  @codec.DecodeOptions, @codec.CodecLimits, @budget.Budget, @error.Diagnostics,
) -> PngChunkDecoder
pub fn PngChunkDecoder::push(Self, @bytes.ByteView) -> PngChunkPushResult
pub fn PngChunkDecoder::finish(Self) -> Result[@codec.DecodeResult, @error.CoreError]
pub fn PngChunkPushResult::consumed(Self) -> UInt64
pub fn PngChunkPushResult::outcome(Self) -> PngChunkPushOutcome
```

`PngChunkDecoder` should initially promise the **same accepted PNG decode profile and metadata semantics as `PngDecoder`**, not a quietly smaller RGB/RGBA-only subset. The eager decoder already accepts grayscale, indexed/`PLTE`/`tRNS`, 16-bit and Adam7 paths and returns colour declarations; a public stream-only subset would make API selection unsafe and force another public compatibility change. [VERIFIED: `modules/mb-image/png/png.mbt:120-199`; `modules/mb-image/png/structural.mbt:1416-1518`]

The minimum useful scope is decode only. It consumes caller-owned chunks without retaining a `ByteView`, reports exactly the bytes accepted from each call, preserves all current strict framing/DEFLATE/filtering behaviour, and returns an image only after the complete PNG has passed validation. Do not add a streaming encoder, progressive image access, APNG, metadata preservation, new imports, FFI, or a `codec.ImageDecoder` trait change. [VERIFIED: `modules/mb-image/codec/contracts.mbt:220-234`; `policy/foundation.json:1336-1342`]

## Stable Contract and State Boundaries

Use QOI's external contract, but not its implementation: `push` returns `NeedInput` after every nonterminal chunk, including a chunk that contains all pixels; `finish` is the caller's only EOF declaration; a fatal error and successful finish are terminal, and later `push` consumes zero bytes and returns the terminal state error. [VERIFIED: `modules/mb-image/qoi/stream_decode.mbt:366-480`; `modules/mb-image/qoi/stream_decode_test.mbt:19-153`]

Private states should be explicit and yield-safe:

1. **Signature / chunk header / ancillary payload+CRC** — retain only bounded partial fixed fields and the already-required bounded `PLTE`, `tRNS`, and colour data.
2. **Pre-IDAT validated** — after IHDR, palette/transparency/colour validation, create the same descriptor and child budgets as eager code. Allocate the output image and row buffers exactly once before consuming compressed raster bytes.
3. **IDAT framing + DEFLATE + raster** — a chunk source owns length remaining, rolling CRC, chunk ordering, compressed-bit buffer, DEFLATE block/tree/repeat/match continuation, 32 KiB history, scanline filter/pass cursor, and packed-row state. It must be able to stop between *any* input byte.
4. **Post-zlib / trailer** — verify zlib Adler-32, finish the current IDAT CRC, reject a later IDAT, validate IEND length+CRC, then require explicit EOF (no unconsumed trailing bytes).
5. **Failed / Finished** — sticky and result-free except the one successful `finish` return.

`finish()` errors are strict: incomplete signature/header/chunk field/payload/CRC/DEFLATE/adler/IEND become `UnexpectedEndOfStream` with stable PNG context; zlib completion before a partially consumed IDAT is `zlib-trailing`; missing IEND, malformed IEND, noncontiguous IDAT, and trailing bytes remain their existing typed errors. Never infer EOF from an empty `push`; empty chunks return `NeedInput`. [VERIFIED: `modules/mb-image/png/structural.mbt:1575-1648`; `modules/mb-image/png/deflate_inflate.mbt:97-287`]

## Safety, Visibility, and Reuse

The image may be allocated and privately filled after validated pre-IDAT preflight, but must **not be publicly observable** until `finish()` has authenticated the last IDAT CRC, zlib Adler-32, IEND CRC, and end-of-input. This preserves the repository's stated whole-datastream acceptance rule and avoids exposing pixels later invalidated by framing. A failure after allocation returns no image and remains terminal. [VERIFIED: `.planning/research/FEATURES.md:32-34`; `modules/mb-image/png/structural.mbt:1377-1412`]

Keep all existing `CodecLimits` checks: increment total input before accepting each byte; check width/height/pixels/output/work before raster allocation; retain the eager child-budget split for metadata and raster; do not charge caller budgets for partial-token/chunk bookkeeping beyond an explicitly preflighted envelope. The QOI tests establish the useful precedent: rejected header preflight leaves the caller budget unchanged; accepted allocation/work is charged once. [VERIFIED: `modules/mb-image/qoi/stream_decode.mbt:124-165,379-405`; `modules/mb-image/qoi/stream_decode_wbtest.mbt:191-226`]

Reusable unchanged: PNG type/CRC helpers, IHDR and colour grammar/preflight, output-budget calculations, descriptors/metadata constructors, row writers, Adam7 pass calculations, Huffman construction, and error contexts. Refactor rather than wrap: `_png_read_stream_transport` and `PngIdatSource` are private `Reader`-backed synchronous machines; `_png_inflate_zlib_to_raster` owns all DEFLATE/raster locals in one call; `PngDeflateBits` converts an empty reader into a terminal `Result` error. A buffered `MemoryReader` adapter would only defer eager decode to `finish`, retain all caller input, and is not resumable decoding. [VERIFIED: `modules/mb-image/png/structural.mbt:1313-1346,1416-1518`; `modules/mb-image/png/deflate_bits.mbt:1-44`; `modules/mb-image/png/deflate_inflate.mbt:97-287`]

## Required Policy and Interface Changes

- Add `stream_decode.mbt`, `stream_decode_test.mbt`, and `stream_decode_wbtest.mbt` to the PNG directory inventory; add `stream_decode.mbt` after `generated_vectors.mbt` in PNG production-source order (matching QOI's split). [VERIFIED: `scripts/quality/Assert-Policy.ps1:985-997`; `policy/foundation.json:1273-1280`]
- Update `policy/foundation.json` PNG `semantic_interface` with the `PngChunkDecoder`, `PngChunkPushOutcome`, and `PngChunkPushResult` declarations plus their `new`/`push`/`finish` and result-accessor methods, retaining the present `PngDecoder` and `PngEncoder` entries and all four targets/imports. [VERIFIED: `policy/foundation.json:1336-1342`]
- Update `Assert-PngFoundationPolicy`'s hard-coded `$sources` and `$files`, plus its negative-fixture expected inventory. Replace the current "extra public stream type" fixture with two checks: required `PngChunkDecoder` interface entries are present, and forbidden `PngStreamDecoder` remains rejected. Do not weaken exact-set/sequence checks. [VERIFIED: `scripts/quality/Assert-Policy.ps1:975-1024`]

## Test and Delivery Plan

**Phase A — internal resumable substrate (no public surface):** byte-fed chunk parser/source, yielding DEFLATE state machine, and yielding scanline/raster state; prove one-byte, every chunk boundary, IDAT payload/CRC boundary, DEFLATE bit/tree/match boundary, row/filter boundary, and IEND/EOF boundary are equivalent to eager results/errors. Include stored/fixed/dynamic DEFLATE and Adam7 fixtures. This is the rewrite-risk phase.

**Phase B — public contract and policy:** add `PngChunkDecoder`, policy inventory/interface updates, public schedule tests and a four-target portable example. Test exact consumed count; caller mutation after a pushed partial header/chunk/token (proves no borrowed view); malformed/truncated header, CRC, zlib, Adler, IEND and trailing data; input/output/work/budget boundaries; sticky failure/success; eager-versus-stream descriptor, pixels, metadata, disposition, and `bytes_read` equality for all generated accepted and rejected vectors. Reuse the QOI hostile-schedule pattern, but add PNG-specific split points. [VERIFIED: `modules/mb-image/qoi/stream_decode_test.mbt:155-249`; `modules/mb-image/png/png_test.mbt:482-708`]

**Phase C — qualification:** add the isolated PNG quality selector evidence and the public `decode → flip/resize → encode` streaming-input workflow on `js`, `wasm`, `wasm-gc`, and `native`; run the policy guard and four-target package tests. [VERIFIED: `scripts/quality/Invoke-MoonQuality.ps1:773-774`; `examples/qoi-portable/main/main.mbt:180-250`]

## Risks and Planning Decision

This is not appropriate for a quick task. It adds a permanent public API to a candidate package, changes exact policy/interface/file inventories, and requires a continuation-state redesign across structural parsing, CRC, zlib/DEFLATE, filters, and Adam7. The current milestone explicitly defers public PNG push/pull streaming, while `PNGX-03` names it as a future requirement. Create a new milestone/phase with `PNGX-03` as the primary requirement and Phase A/B/C as separate plans; do not combine it with the v0.7 colour-fidelity work. [VERIFIED: `.planning/REQUIREMENTS.md:21-32`; `.planning/STATE.md:47-49,100-102`]

The main technical risk is false resumability: a synchronous wrapper can preserve bytes but cannot safely resume at a DEFLATE bit, dynamic-tree repeat, back-reference, Paeth filter, partial CRC, or IEND/EOF transition. The main product risk is progressive visibility: returning an image when raster bytes finish but before final framing validates violates the existing security stance. Both need explicit phase gates and adversarial split-boundary evidence.
