# Roadmap: MoonBit Native Foundation

## Milestones

- ✅ **v0.1 Foundation** — Phases 1-5 (shipped 2026-07-17). [Full history](./milestones/v0.1-ROADMAP.md)
- ⏸️ **v0.2 Publication & Compatibility** — Phases 6-8, deliberately deferred without a registry mutation.
- ✅ **v0.3 Image Processing Core** — Phases 9-12 (shipped 2026-07-20). [Full history](./milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Portable Image Interchange** — Phases 13-16 (shipped 2026-07-20). [Full history](./milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 QOI Streaming I/O** — Phases 17-19 (shipped 2026-07-20). [Full history](./milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 PNG Interchange** — Phases 20-22 (shipped 2026-07-21).
- ✅ **v0.7 PNG Colour Fidelity** — Phases 23-25 (shipped 2026-07-21).
- ✅ **v0.8 Resumable PNG Decode** — Phases 26-28 (shipped 2026-07-21). [Full history](./milestones/v0.8-ROADMAP.md)
- ✅ **v0.9 Resumable PNG Encode** — Phases 29-31 (shipped 2026-07-21). [Full history](./milestones/v0.9-ROADMAP.md)
- ✅ **v0.10 PNG Compression Optimization** — Phases 32-34 (shipped 2026-07-22). [Full history](./milestones/v0.10-ROADMAP.md)
- ✅ **v0.11 PNG Dynamic Huffman Compression** — Phases 35-37 (shipped 2026-07-22). [Full history](./milestones/v0.11-ROADMAP.md)
- ✅ **v0.12 PNG Filter Optimization** — Phases 38-40 (shipped 2026-07-22). [Full history](./milestones/v0.12-ROADMAP.md)
- ✅ **v0.13 PNG Adam7 Encode** — Phases 41-43 (shipped 2026-07-22). [Full history](./milestones/v0.13-ROADMAP.md)
- ✅ **v0.14 Gray8 PNG Interchange** — Phases 44-46 (shipped 2026-07-22). [Full history](./milestones/v0.14-ROADMAP.md)
- ✅ **v0.15 Gray16 PNG Interchange** — Phases 47-49 (shipped 2026-07-22). [Full history](./milestones/v0.15-ROADMAP.md)
- ✅ **v0.16 Grayscale Alpha PNG** — Phases 50-52 (shipped 2026-07-23). [Full history](./milestones/v0.16-ROADMAP.md)
- ✅ **v0.17 GrayAlpha16 PNG Interchange** — Phases 53-55 (shipped 2026-07-23). [Full history](./milestones/v0.17-ROADMAP.md)
- ✅ **v0.18 GrayAlpha16 Adam7 PNG** — Phases 56-58 (shipped 2026-07-23). [Full history](./milestones/v0.18-ROADMAP.md)
- ✅ **v0.19 GrayAlpha8 Adam7 PNG** — Phases 59-61 (shipped 2026-07-23). [Full history](./milestones/v0.19-ROADMAP.md)
- ✅ **v0.20 High-Precision GrayAlpha Decode** — Phases 62-64 (shipped 2026-07-23). [Full history](./milestones/v0.20-ROADMAP.md)
- ✅ **v0.21 RGBA16 PNG Decode** — Phases 65-68 (shipped 2026-07-23). [Full history](./milestones/v0.21-ROADMAP.md)
- ✅ **v0.22 RGBA16 PNG Encode** — Phases 69-72 (shipped 2026-07-23). [Full history](./milestones/v0.22-ROADMAP.md)
- ✅ **v0.23 Low-Bit Grayscale PNG Encode** — Phases 73-75 (shipped 2026-07-24). [Full history](./milestones/v0.23-ROADMAP.md)
- ✅ **v0.24 Indexed PNG Encode** — Phases 76-78 (shipped 2026-07-24). [Full history](./milestones/v0.24-ROADMAP.md)
- ✅ **v0.25 Indexed Low-Bit PNG Encode** — Phases 79-80 (shipped 2026-07-24). [Full history](./milestones/v0.25-ROADMAP.md)
- 📋 **v0.26 Indexed8 Adam7 PNG Encode** — Phases 81-82 (planned).

## Phases

### 📋 v0.26 Indexed8 Adam7 PNG Encode

- [x] **Phase 81: Indexed8 Adam7 Machine and Eager Wire Contract** — Add the bounded Type-3/8 Adam7 machine path, frozen legacy wrappers, exact framing, and atomic admission.
- [x] **Phase 82: Indexed8 Adam7 Streaming and Qualification** — Expose the same machine to caller buffers and qualify lifecycle, independent wire/decode evidence, compatibility, and portability. (completed 2026-07-24)

## Phase Details

### Phase 81: Indexed8 Adam7 Machine and Eager Wire Contract

**Goal:** Users can explicitly encode a canonical `PngIndexedImage` as a bounded Type-3/8 Adam7 PNG through the existing acknowledged machine while legacy Indexed8 routes remain byte-identical and non-interlaced.

**Depends on:** Phase 80 (shipped)

**Requirements:** INDEXADAM7-01, INDEXADAM7-02, INDEXADAM7-03, INDEXADAM7-04

**Scope guard:** Add only explicit Indexed8 interlace selection. Reuse `_png_adam7_passes(..., 1, 8)`, `PngIndexedImage::index_at`, `PngFrameFacts`, and the sole `PngEncodeMachine`; no Indexed1/2/4 Adam7, strategy expansion, generic model/API widening, or image/pass/output staging.

**Success criteria:**

1. Additive eager and caller-buffered selector seams accept `Adam7`, while `encode_indexed8` and `new_indexed8` keep their signatures and frozen IHDR interlace-0 bytes.
2. Adam7 Indexed8 preflight derives checked pass-row scanlines, Stored IDAT/frame/work facts, limits, and the single budget charge from shared seven-pass geometry before any output.
3. The existing machine emits a filter-None tag for every nonempty pass row and reads canonical indices only at mapped pass coordinates, without a second encoder or staging allocation.
4. Independent eager evidence proves `IHDR → PLTE → optional canonical tRNS → IDAT → IEND`, valid CRCs, exact seven-pass Type-3/8 raster, and complete public RGB8/RGBA8 decode.

### Phase 82: Indexed8 Adam7 Streaming and Qualification

**Goal:** The same admitted Indexed8 Adam7 machine is usable through caller-owned leases with eager-identical bytes, sticky outcomes, independent transport evidence, frozen compatibility, and four-target proof.

**Depends on:** Phase 81

**Requirements:** INDEXADAM7-05, INDEXADAM7-06

**Scope guard:** Add only a thin `PngChunkEncoder` adapter over Phase 81's machine and tests/evidence. Do not create another stream/encoder, add low-bit Adam7, change the indexed source model, add filters/compression strategies, wrappers, copied trees, FFI, or release automation.

**Success criteria:**

1. Zero-capacity, one-byte, and ragged lease schedules reproduce fresh eager Adam7 bytes; progress counts accepted bytes only and untouched lease tails remain sentinel-filled.
2. Released leases yield sticky zero-write failures; repeated finished pulls remain zero-write `Finished` and cannot mutate later destinations.
3. Chunk-origin output independently passes chunk/CRC/raw-pass/decode checks, rather than relying only on eager parity.
4. Existing Indexed8 opaque/transparent and Indexed1/2/4 non-interlaced literal vectors remain unchanged.
5. The ordinary frozen PNG package gate passes on wasm, wasm-gc, js, and native.
