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
- ✅ **v0.26 Indexed8 Adam7 PNG Encode** — Phases 81-82 (shipped 2026-07-24). [Full history](./milestones/v0.26-ROADMAP.md)
- 📋 **v0.27 Low-Bit Indexed Adam7 PNG Encode** — Phases 83-84 (planned).

## Phases

### 📋 v0.27 Low-Bit Indexed Adam7 PNG Encode

- [x] **Phase 83: Low-Bit Indexed Adam7 Machine and Eager Contract** — Add selected-depth packed Adam7 traversal, exact framing, and atomic admission to the sole machine.
- [x] **Phase 84: Low-Bit Indexed Adam7 Streaming Qualification** — Qualify the admitted route under hostile leases with independent chunk-origin evidence, frozen compatibility, and four-target proof. (completed 2026-07-24)

## Phase Details

### Phase 83: Low-Bit Indexed Adam7 Machine and Eager Contract

**Goal:** Users can explicitly encode the canonical unpacked `PngIndexedImage` as bounded Type-3/1, /2, or /4 Adam7 output through the sole acknowledged machine, with deterministic packed pass rows, exact framing, and atomic resource admission.

**Depends on:** Phase 82 (shipped)

**Requirements:** INDEXLOWADAM7-01, INDEXLOWADAM7-02, INDEXLOWADAM7-03, INDEXLOWADAM7-04

**Scope guard:** Add only selected-depth Adam7 to the existing low-bit selector families. Reuse one depth-aware `_png_adam7_passes(..., 1UL, depth)` fact source, `PngIndexedImage::index_at`, `PngFrameFacts`, and the sole `PngEncodeMachine`; no model widening, additional strategies, staging, second encoder, FFI, wrappers, copied trees, or release work.

**Success criteria:**

1. Additive eager and caller-buffered selectors accept `Adam7` at depths 1, 2, and 4, while established non-interlaced Indexed1/2/4 and Indexed8 APIs produce their frozen bytes.
2. Every nonempty Adam7 pass row starts packing at its local first pixel, emits one filter-None tag, maps canonical source indices by pass coordinates, packs MSB-first, and zeroes unused final-byte tail bits.
3. Each selected-depth output has legal capped actual-entry PLTE, shortest canonical tRNS, valid chunk framing and CRCs, a Stored/filter-None seven-pass IDAT raster, and public RGB8/RGBA8 palette-exact decode.
4. Before writer progress, chunk lease exposure, or budget mutation, preflight validates selected-depth dimensions/palette capacity and checked packed pass/frame/work/output facts; exact limits pass and all one-less, overflow, or arithmetic failures are atomic.

**Plans:** 1/1 plans complete

- [x] 83-01-PLAN.md

### Phase 84: Low-Bit Indexed Adam7 Streaming Qualification

**Goal:** Each admitted low-bit Indexed Adam7 route is safe through caller-owned leases, independently wire-qualified from collected stream bytes, compatibility-frozen, and proven on all four declared targets.

**Depends on:** Phase 83

**Requirements:** INDEXLOWADAM7-05, INDEXLOWADAM7-06

**Scope guard:** Do not alter encoder architecture: qualify the Phase 83 selector and its existing `present → destination.set → acknowledge` machine lifecycle only. No new stream/encoder, source-model changes, strategies, staging, FFI, wrappers, copied trees, or release automation.

**Success criteria:**

1. For depths 1, 2, and 4, zero-capacity, one-byte, and ragged caller leases reproduce fresh eager Adam7 bytes; accepted-only progress and every unaccepted sentinel-filled tail remain unchanged.
2. A released lease yields a sticky zero-write failure replayed unchanged into later destinations, and pulls after completion are zero-write `Finished` with the entire destination untouched.
3. Independently parsing collected chunk bytes proves Type-3 Adam7 chunk order, CRCs, each selected-depth packed raw pass raster including tail zeros, and public RGB8/RGBA8 decode without relying on eager bytes or production packer/preflight helpers.
4. Existing Type-3/1, /2, and /4 non-interlaced literals and Type-3/8 Adam7 vectors remain frozen.
5. The ordinary frozen PNG package gate passes on wasm, wasm-gc, js, and native.

**Plans:** 1/1 plans complete

- [x] 84-01-PLAN.md

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 83. Low-Bit Indexed Adam7 Machine and Eager Contract | 1/1 | Complete    | 2026-07-24 |
| 84. Low-Bit Indexed Adam7 Streaming Qualification | 1/1 | Complete    | 2026-07-24 |
