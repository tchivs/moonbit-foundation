# Project Research Summary

**Project:** MoonBit Native Foundation — v0.6 PNG Interchange
**Domain:** Bounded, pure-MoonBit portable PNG RGB/RGBA interchange
**Researched:** 2026-07-20
**Confidence:** MEDIUM

## Executive Summary

v0.6 is a deliberately narrow, interoperable PNG codec for the existing `mb-image` module—not a general PNG implementation. It should expose eager `PngDecoder` and `PngEncoder` through the established codec traits while implementing a private, forward-only streaming pipeline. The supported decode profile is static, non-interlaced 8-bit truecolour PNG (types 2 and 6) with all five PNG filters and all legal zlib/DEFLATE block forms. It maps directly to existing `rgb8` and straight-`rgba8` images and returns no `DecodeResult` until PNG framing, CRCs, Adler-32, row accounting, IEND, and trailing-input checks succeed.

Keep the work pure MoonBit and inside `tchivs/mb-image`: a narrowly scoped `deflate` package supplies bounded zlib/DEFLATE; a `png` package owns framing, raster handling, and codec integration. Reuse `mb-core` checked arithmetic, budgets, bytes, I/O, diagnostics, plus existing image storage/metadata contracts. Do not add a registry, FFI, a generic compression module, a whole-IDAT buffer, or a public resumable-PNG API.

The dominant risks are hostile-input correctness and false claims of PNG compatibility: arbitrary IDAT boundaries, malformed dynamic Huffman trees, overflow before limit checks, checksum layering, and silent colour/metadata loss. Mitigate them through one logical IDAT byte source, checked preflight before allocation or writes, a 32 KiB DEFLATE history ring, atomic eager results, adversarial split-boundary fixtures, and four-target exact-output evidence. The milestone must describe itself as an RGB/RGBA subset and reject unsupported semantic inputs explicitly.

## Key Findings

### Recommended Stack

Use the pinned MoonBit toolchain (`moon 0.1.20260713`) and retain `+js+wasm+wasm-gc+native`. Existing MNF primitives already provide the capability boundary needed for a hostile binary codec: `checked` for all derived geometry and accounting, `budget` for shared resource authority, `bytes`/`io` for bounded forward progress, and `codec`/`storage`/`metadata`/`mb-color` for the stable image contract.

**Core technologies:**

- `tchivs/mb-image/deflate`: private bit I/O, zlib wrapper, canonical-Huffman validation, complete DEFLATE decode, Adler-32, and a 32 KiB history ring.
- `tchivs/mb-image/png`: public `PngDecoder`/`PngEncoder`, framing/CRC state, IDAT adapter, scanline filtering, canonical output, and codec diagnostics.
- `tchivs/mb-core/checked`, `budget`, `bytes`, and `io`: mandatory checked arithmetic, precharged limits, fixed scratch ownership, and short-progress-safe reader/writer handling.
- Existing `mb-image` storage/model/codec and `mb-color` profile types: direct RGB8/RGBA8, encoded-sRGB, straight-alpha integration with no new image representation.

**Resolved encoder-policy tension:** STACK/ARCHITECTURE propose fixed-Huffman literal-only output, while FEATURES/PITFALLS propose stored DEFLATE blocks. Choose **stored DEFLATE blocks** for v0.6. They are equally standards-conformant and deterministic, but avoid an encoder Huffman bitstream implementation while the decoder still must support stored, fixed, and dynamic blocks for interoperability. Freeze one source-level stored-block maximum and fixed IDAT payload size (32 KiB recommended) before golden fixtures are accepted; use zlib `0x78 0x01`, filter `None`, no ancillary chunks, and no LZ matching. Fixed-Huffman encoding is a later size optimization, not a v0.6 requirement.

### Expected Features

**Must have (table stakes):**

- Non-consuming eight-byte probe with deterministic `NeedMore` and probe limit enforcement.
- Decode only IHDR `(depth=8, type=2|6, compression=0, filter=0, interlace=0)`; reconstruct filters 0–4.
- Validate signature; exactly one first IHDR; checked positive geometry; CRC for every processed chunk; contiguous IDAT; one empty IEND; and no trailing bytes after IEND.
- Treat all IDAT payloads as one zlib stream, regardless of chunk, block, checksum, or row boundaries.
- Validate zlib CMF/FLG/FCHECK and Adler-32, reject FDICT, and decode stored/fixed/dynamic DEFLATE with bounded canonical-Huffman and distance validation.
- Enforce input, chunk, dimensions, pixels, output, work, allocation, and scanline limits before and during processing; never expose a partial image.
- Encode compatible packed top-left builtin encoded-sRGB RGB8/RGBA8 images to one exact byte sequence, after a zero-write preflight.

**Should have (differentiators):**

- Private streaming internals behind the established eager public traits, avoiding both full-input staging and premature public streaming-state API.
- Small, provenance-tagged adversarial fixtures that split each meaningful zlib/DEFLATE/filter/checksum boundary.
- A public four-target `decode → flip_horizontal → encode` example that reports stable dimensions, digest, byte count, and metadata disposition.

**Defer (v2+):**

- Grayscale, palette, `tRNS`, 16-bit samples, Adam7, colour-management/HDR chunks, text/EXIF preservation, APNG, public resumable PNG I/O, compression optimization, benchmarks, FFI, and registry/release work.

**Resolved metadata-policy tension:** known colour-, pixel-, or animation-affecting chunks (`PLTE`, `tRNS`, colour-management/HDR, APNG) are rejected, never ignored. Unknown ancillary chunks are CRC-checked and may be discarded only when opaque-metadata preservation is disabled, with lossy `MetadataDisposition`; preservation requested means failure. Unknown critical chunks always fail.

### Architecture Approach

Retain the existing `ImageDecoder`/`ImageEncoder` seam. Decode flows `PngInput → ChunkMachine → IdatByteSource → ZlibDecoder → DeflateDecoder → FilteredScanlineSink → private OwnedImage`; only terminal validation can turn that private image into a result. Encode flows `ImageView preflight → ScanlineSource → StoredDeflateWriter → ZlibWriter → IdatChunkWriter → Writer`. `png` depends on `deflate`; neither reverses dependencies into `mb-core` or `mb-color`.

**Major components:**

1. **ChunkMachine and IdatByteSource** — signature, chunk ordering/CRC/limits, and a continuous logical IDAT stream.
2. **Zlib/DeflateDecoder** — bit state, stored/fixed/dynamic blocks, canonical trees, history, Adler-32, and output/work enforcement.
3. **FilteredScanlineSink** — exact decompressed-byte count, filter tag plus RGB/RGBA row reconstruction, two row buffers, and writes to a private image.
4. **PngOutput stack** — source preflight, exact big-endian PNG framing, filter-None rows, deterministic stored blocks, fixed IDAT partitioning, CRC-32, and Adler-32.

### Critical Pitfalls

1. **Treating IDAT boundaries as codec boundaries** — expose one resumable IDAT byte source to zlib; test splits inside every meaningful format boundary.
2. **Overflow or allocation before limit enforcement** — derive every geometry/output/work value with checked arithmetic and charge `Budget` before image allocation or writer mutation.
3. **Malformed dynamic trees or invalid distances** — bound repeat codes and alphabets, reject incomplete/oversubscribed/reserved cases, enforce `distance <= produced` and `<= 32768`, and copy overlap through the history rule.
4. **Checksum/terminal validation drift** — keep PNG CRC-32 (type+data) separate from zlib Adler-32 (uncompressed bytes); require exact output byte count, all CRCs, IEND, and strict EOF before success.
5. **Wrong byte-based filter arithmetic or semantic loss** — use bpp 3/4 bytes, two zero-initialized row buffers, wider predictor arithmetic, and explicit capability/metadata failures.

## Implications for Roadmap

### Phase 20: PNG Structural Core and Capability Gate

**Rationale:** The accepted profile, framing state, and every allocation bound must be unambiguous before DEFLATE can cause work or image storage.

**Delivers:** `png` package shape; public non-consuming probe; incremental signature/chunk parser; CRC-32; legal chunk/type/order state; contiguous-IDAT policy; known/unknown ancillary disposition; strict IEND/trailing-byte rule; IHDR subset gate; checked geometry/output/work preflight; and adversarial framing fixtures.

**Addresses:** codec parity, complete framing/integrity validation, checked resource accounting, and explicit metadata policy.

**Avoids:** chunk-length allocation, silent semantic loss, mismatched probe/decode behavior, CRC scope mistakes, and geometry overflow.

### Phase 21: Bounded zlib/DEFLATE Decode and Raster Pipeline

**Rationale:** Interoperable decoding depends on a complete bounded inflater; it is the highest-risk implementation and must be proved independently before PNG raster integration claims success.

**Delivers:** private `deflate` bit reader; zlib header/FDICT/Adler handling; stored/fixed/dynamic block decoder; canonical tree validation; 32 KiB history; output/work sink; logical IDAT adapter; filters 0–4; private `OwnedImage` construction; terminal atomic `DecodeResult`; RGB/RGBA corpus and split schedules.

**Addresses:** ordinary PNG interoperability across external DEFLATE strategies, all filters, eager atomic decode, and bounded internal streaming.

**Avoids:** IDAT desynchronization, Huffman/distance acceptance bugs, expansion abuse, incorrect Paeth/Average behavior, and partial-success leakage.

### Phase 22: Canonical Stored-Block Encoding and Portable Qualification

**Rationale:** Encoding should follow proven decode/storage contracts and start only with a frozen deterministic byte policy—not a compression heuristic.

**Delivers:** source capability/metadata preflight; conservative zero-write limit and budget gate; filter-None scanlines; fixed-size stored DEFLATE blocks; zlib wrapper; fixed 32 KiB IDAT segmentation; exact CRC/Adler/IEND output; golden RGB/RGBA bytes and digests; short-writer negatives; public portable example; and js/wasm/wasm-gc/native evidence.

**Addresses:** canonical RGB/RGBA output, deterministic baseline compression, public workflow, and four-target verification.

**Avoids:** target-varying bytes, output before preflight, hidden metadata loss, and premature optimizer complexity.

### Phase Ordering Rationale

- Phase 20 fixes the input contract, safety ceiling, and explicit rejection policy before data can reach the inflater or storage.
- Phase 21 centralizes all decompressed-byte effects in one bounded sink, then proves decode against arbitrary legal transport partitioning.
- Phase 22 consumes the settled image and zlib contracts to publish one reproducible wire format and cross-target proof.
- Keep decoder completeness for the supported PNG profile, but encoder minimality: accepting dynamic DEFLATE does not require generating it.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 21:** mandatory focused research/implementation spike for MoonBit bit-level representation, canonical-Huffman invalid-tree rules, and a curated independently derived DEFLATE negative corpus.
- **Phase 22:** confirm the exact stored-block/IDAT constants and conservative encoded-size formula before committing public golden bytes.

Phases with established patterns:

- **Phase 20:** existing QOI/PPM contracts provide established patterns for limits, diagnostics, reader progress, probe behavior, and eager atomic results; planning can primarily inspect and reuse them.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Existing toolchain and MNF seams were locally verified; source-provider scoring lowers confidence in externally fetched format research despite primary sources. |
| Features | MEDIUM-HIGH | Scope and acceptance criteria align across all reports and existing image representations. |
| Architecture | MEDIUM-HIGH | It follows verified QOI/codec/budget/I/O seams; DEFLATE implementation details remain high-risk. |
| Pitfalls | HIGH | Existing-contract integration is locally evidenced and PNG/zlib/DEFLATE failure modes are consistently specified. |

**Overall confidence:** MEDIUM

### Gaps to Address

- **DEFLATE corpus quality:** retain small specification-derived, independently checked valid and invalid vectors; generated outputs must not be the sole oracle.
- **Canonical constants:** lock stored-block maximum and IDAT payload size in code and golden fixtures before public release; do not later change them under a stability claim.
- **Strict terminal contract:** apply the resolved always-reject-post-IEND rule consistently with existing codec options, documenting any compatibility impact rather than making it accidental.
- **Metadata diagnostics:** verify the precise existing `MetadataDisposition` and capability-error shapes before naming public errors.
- **Performance baseline:** defer compression-ratio promises until a separate benchmarked optimization phase with declared workloads and preserved canonical baseline.

## Sources

### Primary

- [W3C PNG Specification, Third Edition](https://www.w3.org/TR/2025/REC-png-3-20250624/) — chunk framing/order, IDAT concatenation, filtering, colour/interlace scope, and conformance.
- [RFC 1950: zlib](https://www.rfc-editor.org/rfc/rfc1950.html) — wrapper, FDICT, FCHECK, and Adler-32.
- [RFC 1951: DEFLATE](https://www.rfc-editor.org/rfc/rfc1951.html) — block forms, canonical codes, lengths/distances, and bounded history.

### Direct project evidence

- `modules/mb-image/codec/contracts.mbt`, `qoi`, `ppm`, and `modules/mb-core/io` — eager codec, limits/budget, diagnostics, metadata disposition, and forward-only I/O patterns.
- Local MoonBit checks for the pinned toolchain and four portable targets.

---
*Research completed: 2026-07-20*
*Ready for roadmap: yes — phases 20–22, with Phase 21 research retained as a hard gate.*
