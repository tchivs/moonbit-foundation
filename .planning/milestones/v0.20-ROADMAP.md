# Roadmap: MoonBit Native Foundation

## Milestones

- ✅ **v0.1 Foundation** — Phases 1-5, 41 plans, 36/36 requirements (shipped 2026-07-17). [Full history](./milestones/v0.1-ROADMAP.md)
- ⏸️ **v0.2 Publication & Compatibility** — Phases 6-8; registry publication remains deliberately deferred without a registry mutation.
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
- 📋 **v0.20 High-Precision GrayAlpha Decode** — Phases 62-64 (planned).

## Phases

Completed milestone detail is archived under `.planning/milestones/`.

- [x] **Phase 62: Explicit GrayAlpha16 Decode Contract** - Opt-in eager Type-4/16 preservation with truthful sRGB identity and frozen generic compatibility. (completed 2026-07-23)
- [x] **Phase 63: Resumable GrayAlpha16 Decode** - Route the preservation profile through the existing caller-buffered decoder lifecycle. (completed 2026-07-23)
- [x] **Phase 64: GrayAlpha16 Decode Qualification** - Prove byte fidelity, hostile-input safety, compatibility, and portability. (completed 2026-07-23)

## Phase Details

### Phase 62: Explicit GrayAlpha16 Decode Contract

**Goal**: Users can explicitly decode a legal encoded-sRGB Type-4/16 PNG into the existing packed little-endian, straight-alpha `graya16` result without changing generic decoding.
**Depends on**: Phase 61
**Requirements**: GRA16DEC-01
**Success Criteria** (what must be TRUE):

  1. A user can call `PngDecoder::decode_graya16` on a Type-4/16 input with no colour declaration or an `sRGB` declaration and receive a normal `DecodeResult` whose image is packed little-endian `graya16`, straight alpha, top-left, and encoded-sRGB identity.
  2. An asymmetric Type-4/16 source preserves each reconstructed component byte in observable `Glo,Ghi,Alo,Ahi` storage order, with no scaling, premultiplication, or colour conversion.
  3. The existing generic eager decoder still returns its frozen `RGBA8(Ghi,Ghi,Ghi,Ahi)` result for that same Type-4/16 source.

**Plans**: TBD
**Scope guard**: The generic decoder, generic result shape, and conversion APIs remain unchanged.

### Phase 63: Resumable GrayAlpha16 Decode

**Goal**: Users can obtain the same preserved GrayAlpha16 result through caller-owned input chunks while retaining the established bounded decoder lifecycle.
**Depends on**: Phase 62
**Requirements**: GRA16DEC-02
**Success Criteria** (what must be TRUE):

  1. A user can create `PngChunkDecoder::new_graya16`, supply a legal Type-4/16 image in empty, one-byte, or ragged chunk schedules, and receive component-byte-identical output to a fresh eager preservation decode.
  2. Chunk callers observe accepted-only consumption and receive the sole result only from successful `finish()`, with no retained caller view or partial image exposed.
  3. Incomplete, malformed, or limit-exceeding chunk streams fail atomically with the established typed diagnostics and sticky terminal behavior.

**Plans**: TBD
**Scope guard**: Both selectors use the one existing bounded decode machine; no alternate decoder or image-sized staging buffer is introduced.

### Phase 64: GrayAlpha16 Decode Qualification

**Goal**: Users can rely on exact Type-4/16 preservation across filters, Adam7, hostile boundaries, legacy compatibility, and every supported portable target.
**Depends on**: Phase 63
**Requirements**: GRA16DEC-03
**Success Criteria** (what must be TRUE):

  1. Independent Type-4/16 fixtures using all five PNG filters and all seven Adam7 passes preserve every gray and alpha component byte at the expected output coordinate.
  2. The explicit profile rejects unsupported type/depth and unrepresentable legacy-colour or ICC declarations before image allocation, while exact and one-less resource cases preserve bounded no-result failure behavior.
  3. Existing generic eager and chunk Type-4/16 routes retain their frozen RGBA8 high-byte results, progress, diagnostics, and terminal semantics.
  4. The full PNG package, including preservation, hostile-schedule, and legacy vectors, passes independently on wasm, wasm-gc, js, and native.

**Plans**: TBD
**Scope guard**: The profile is encoded-sRGB-only and performs no colour, alpha, or high-precision conversion beyond the documented final byte-order store.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 62. Explicit GrayAlpha16 Decode Contract | 1/1 | Complete    | 2026-07-23 |
| 63. Resumable GrayAlpha16 Decode | 1/1 | Complete    | 2026-07-23 |
| 64. GrayAlpha16 Decode Qualification | 1/1 | Complete    | 2026-07-23 |
