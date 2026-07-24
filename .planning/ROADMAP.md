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
- ✅ **v0.27 Low-Bit Indexed Adam7 PNG Encode** — Phases 83-84 (shipped 2026-07-24). [Full history](./milestones/v0.27-ROADMAP.md)
- 📋 **v0.28 Indexed PNG Compression Profiles** — Phases 85-87 (planned).

## Phases

### 📋 v0.28 Indexed PNG Compression Profiles

- [x] **Phase 85: Indexed Compression API and Fixed Wire Contract** - Establish additive Stored-or-Fixed selectors and the exact bounded Fixed Type-3 contract. (completed 2026-07-24)
- [x] **Phase 86: Ancillary-Aware Preflight and Shared-Machine Integration** - Select and admit the exact palette-aware candidate plan through the existing eager and caller-buffered machine. (completed 2026-07-24)
- [ ] **Phase 87: Hostile Indexed Streaming and Independent Qualification** - Prove lifecycle safety, independent wire/decode behavior, compatibility, and four-target portability.

## Phase Details

### Phase 85: Indexed Compression API and Fixed Wire Contract

**Goal:** Library users can explicitly request deterministic non-interlaced Fixed-or-Stored compression for Type-3/1, /2, /4, and /8 PNG output without changing any legacy indexed Stored/filter-None byte stream.

**Depends on:** Phase 84 (shipped)

**Requirements:** INDEXCOMP-01, INDEXCOMP-02

**Scope guard:** Add only non-interlaced indexed compression selectors. Old APIs must literally forward Stored; `DynamicOrFixedOrStored` is rejected as unavailable. Reuse one bounded filter-None indexed raw-byte/match producer, the existing 1--4-distance matcher, and Fixed emitter; no Dynamic DEFLATE, adaptive filters, Adam7 compression selection, generic model widening, staging, second encoder, FFI, copied trees, or release work.

**Success criteria:**

1. Users can choose `Stored` or `FixedOrStored` through additive eager and caller-buffered selectors for each non-interlaced Type-3 depth, while old/default routes and explicit Stored selection remain byte-identical compatibility output.
2. A Dynamic request receives the documented unavailable-capability failure before planning or budget charge, rather than silently selecting another compression profile.
3. For a Fixed-or-Stored request, the bounded shared indexed raw-byte producer yields the exact filter-None scanline bytes used to choose and emit Fixed only when its complete Type-3 frame is no larger than Stored; a larger Fixed candidate falls back to Stored.

**Plans:** 1/1 plans complete

### Phase 86: Ancillary-Aware Preflight and Shared-Machine Integration

**Goal:** The selected indexed compression profile is fully preflighted with its actual palette/transparency framing and admitted once into the established acknowledged eager and caller-buffered machine.

**Depends on:** Phase 85

**Requirements:** INDEXCOMP-03

**Scope guard:** Compute non-interlaced selected-depth facts only. `PngFrameFacts` remains the owner of PLTE/tRNS/IDAT/IEND offsets, and the existing acknowledgement lifecycle remains the sole output path; no new stream encoder, Dynamic route, filter choice, Adam7 compression, staging, FFI, wrappers, copied trees, or release automation.

**Success criteria:**

1. Before any writer byte, caller lease, or budget mutation, a selected Type-3 depth has checked geometry, actual PLTE, shortest canonical tRNS, and exact Stored/Fixed frame, output, and work facts.
2. The selected candidate is admitted by exactly one budget charge and then drives both eager and caller-buffered output through the existing acknowledged machine.
3. Exact selected limits pass, while one-less output/work, palette-capacity overflow, and checked-arithmetic failures expose no output or lease and leave the budget unchanged.

**Plans:** 1/1 plans complete

### Phase 87: Hostile Indexed Streaming and Independent Qualification

**Goal:** Users can rely on the new indexed compression profile under hostile caller leases and obtain independently verifiable, decodable, portable PNG bytes without disturbing frozen indexed compatibility routes.

**Depends on:** Phase 86

**Requirements:** INDEXCOMP-04, INDEXCOMP-05

**Scope guard:** Qualify the Phase 86 admitted machine only; no architecture redesign, new compression/filter/interlace profile, source-model change, staging, FFI, target wrapper, copied tree, registry work, or release automation.

**Success criteria:**

1. Fixed winners and Stored fallbacks produce fresh eager-identical bytes under zero-capacity, one-byte, and ragged leases, count only accepted bytes, and preserve every rejected sentinel-filled destination tail.
2. Released leases and replay-accounting mismatches yield sticky zero-write terminal failures; pulls after finish are zero-write `Finished` and leave destinations unchanged.
3. Independent test-local parsers of eager and collected chunk-origin bytes prove DEFLATE selection, Type-3 framing, PLTE/tRNS canonicalisation, filter-None packed rows/tails, Adler/CRCs, and public RGB8/RGBA8 decode without calling production planning, matching, packing, or frame helpers.
4. Legacy non-interlaced Type-3/1, /2, /4, /8 Stored vectors and all existing indexed Adam7 Stored/None vectors remain byte-frozen.
5. The ordinary PNG package gate passes on wasm, wasm-gc, js, and native.

**Plans:** 0/1 plans complete

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 85. Indexed Compression API and Fixed Wire Contract | 1/1 | Complete    | 2026-07-24 |
| 86. Ancillary-Aware Preflight and Shared-Machine Integration | 1/1 | Complete    | 2026-07-24 |
| 87. Hostile Indexed Streaming and Independent Qualification | 0/1 | Not started | - |
