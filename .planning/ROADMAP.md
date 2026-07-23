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
- 📋 **v0.21 RGBA16 PNG Decode** — Phases 65-68 (planned).

## Phases

Completed milestone detail is archived under `.planning/milestones/`.

- [x] **Phase 65: Packed RGBA16 Decode Model** - Establish the checked, explicit high-precision image result contract. (completed 2026-07-23)
- [x] **Phase 66: Explicit RGBA16 PNG Preservation** - Let eager callers preserve legal Type-6/16 source lanes without changing generic decode. (completed 2026-07-23)
- [ ] **Phase 67: Resumable RGBA16 PNG Preservation** - Deliver the same preservation contract through caller-owned chunks.
- [ ] **Phase 68: RGBA16 Decode Qualification** - Prove exact lane fidelity, bounded failure, compatibility, and four-target portability.

## Phase Details

### Phase 65: Packed RGBA16 Decode Model

**Goal**: Library users can construct and inspect a checked packed little-endian, straight-alpha `rgba16` image without changing existing image contracts.
**Depends on**: Phase 64
**Requirements**: RGBA16DEC-01
**Success Criteria** (what must be TRUE):

  1. A library user can construct an `rgba16` image whose descriptor reports packed U16 RGBA, an eight-byte pixel stride, little-endian component storage, top-left orientation, and straight alpha.
  2. A library user can inspect distinct component bytes in observable `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi` storage order through the established image access contract.
  3. Existing `rgba8` and `graya16` descriptors and their public behavior remain unchanged.

**Plans**: TBD
**Scope guard**: This adds one checked packed representation only; no high-precision conversion APIs, big-endian storage, premultiplication, or widening of U8-only operations.

### Phase 66: Explicit RGBA16 PNG Preservation

**Goal**: Library users can explicitly decode legal encoded-sRGB Type-6/16 PNG input into a byte-preserving `rgba16` result while generic decoding stays frozen.
**Depends on**: Phase 65
**Requirements**: RGBA16DEC-02
**Success Criteria** (what must be TRUE):

  1. A library user can call `PngDecoder::decode_rgba16` for a legal Type-6/16 PNG with no colour declaration or an `sRGB` declaration and receive packed little-endian, straight-alpha `rgba16` output.
  2. Every reconstructed Type-6/16 source lane is observable in `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi` output order, without scaling, premultiplication, or colour conversion.
  3. The same input through the established generic decoder still yields frozen `RGBA8(Rhi,Ghi,Bhi,Ahi)` output.
  4. Unsupported colour type/depth or transparency, legacy-colour, and ICC declarations are rejected before a preservation result is allocated or exposed.

**Plans**: TBD
**Scope guard**: The profile reuses the shared decoder and adds only a final packed store; generic result shape, non-sRGB/ICC conversion, image-sized staging, and alternate decoders remain out of scope.

### Phase 67: Resumable RGBA16 PNG Preservation

**Goal**: Library users can obtain the same exact RGBA16 result through caller-owned input chunks with the established bounded decoder lifecycle.
**Depends on**: Phase 66
**Requirements**: RGBA16DEC-03
**Success Criteria** (what must be TRUE):

  1. A library user can create `PngChunkDecoder::new_rgba16`, provide a legal Type-6/16 stream in empty, one-byte, or ragged schedules, and receive component-byte-identical output to a fresh eager decode.
  2. Chunk callers observe accepted-only input progress and obtain the sole decoded image only from a successful `finish()`, with no partial image or retained caller view exposed.
  3. Truncated, malformed, profile-invalid, or resource-limited streams fail before a result is exposed and retain the established sticky typed terminal behavior under later pushes and repeated `finish()` calls.

**Plans**: TBD
**Scope guard**: Eager and chunk selectors use the one existing byte-fed bounded machine; no alternate decoder, target wrapper, or image-sized staging buffer is introduced.

### Phase 68: RGBA16 Decode Qualification

**Goal**: Library users can rely on exact Type-6/16 preservation through PNG filters and Adam7, with bounded hostile-input behavior and portable compatibility evidence.
**Depends on**: Phase 67
**Requirements**: RGBA16DEC-04
**Success Criteria** (what must be TRUE):

  1. Independent Type-6/16 fixtures using all five PNG filters and all seven Adam7 passes preserve all eight stored component bytes at every expected output coordinate.
  2. Exact and one-less normal and Adam7 image, output, and work limits demonstrate that the eight-byte result allocation is charged before decompression progresses and failure exposes no result.
  3. Explicit eager and chunk selectors reject hostile metadata, malformed data, invalid profiles, and terminal replay safely, while generic eager and chunk Type-6/16 behavior remains frozen as RGBA8 high-byte projection.
  4. The ordinary full PNG package, including the explicit preservation and legacy compatibility suite, passes on wasm, wasm-gc, js, and native.

**Plans**: TBD
**Scope guard**: Qualification uses fixed independent wire literals and the ordinary source tree only; no generated explicit oracle, copied-source workflow, FFI, release automation, or target-specific expectation is allowed.

## Progress

| Phase | Plans Complete | Status | Completed |
|---|---|---|---|
| 65. Packed RGBA16 Decode Model | 1/1 | Complete    | 2026-07-23 |
| 66. Explicit RGBA16 PNG Preservation | 1/1 | Complete    | 2026-07-23 |
| 67. Resumable RGBA16 PNG Preservation | 0/TBD | Not started | - |
| 68. RGBA16 Decode Qualification | 0/TBD | Not started | - |
