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
- 📋 **v0.22 RGBA16 PNG Encode** — Phases 69-72 (planned).

## Phases

Completed milestone detail is archived under `.planning/milestones/`.

- [ ] **Phase 69: Explicit RGBA16 PNG Encoding** - Encode checked packed `rgba16` images as exact non-interlaced Type-6/16 PNG without changing legacy output.
- [x] **Phase 70: Resumable RGBA16 PNG Encoding** - Provide eager-identical caller-buffered Type-6/16 encoding through the bounded machine. (completed 2026-07-23)
- [ ] **Phase 71: RGBA16 Adam7 PNG Encoding** - Add explicit interlaced Type-6/16 output while retaining profile, filter, and compression semantics.
- [ ] **Phase 72: RGBA16 Encode Qualification** - Prove normal/Adam7 byte fidelity, hostile bounded behavior, compatibility, and four-target portability.

## Phase Details

### Phase 69: Explicit RGBA16 PNG Encoding

**Goal**: Library users can explicitly encode a checked `rgba16` image to a legal non-interlaced Type-6/16 PNG with byte-exact U16 lane preservation.
**Depends on**: Phase 68
**Requirements**: RGBA16ENC-01
**Success Criteria**:

1. An eager public encoder selector accepts only the checked packed little-endian, straight-alpha `rgba16` contract and emits PNG Type-6/16 big-endian component samples without scaling, premultiplication, or colour conversion.
2. Normal-row output round-trips through the explicit RGBA16 decoder with all `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi` component bytes preserved.
3. Existing RGB8/RGBA8 public encoder selectors and bytes remain frozen; incompatible descriptors or resource limits fail before output is exposed.

**Plans**: TBD
**Scope guard**: Reuse the existing bounded encoder and its compression/filter machinery; no alternate encoder, staging buffer, FFI, or generic API change.

### Phase 70: Resumable RGBA16 PNG Encoding

**Goal**: Library users can emit the same Type-6/16 PNG through caller-owned output chunks with established atomic admission and sticky terminal semantics.
**Depends on**: Phase 69
**Requirements**: RGBA16ENC-02
**Success Criteria**:

1. A caller-buffered RGBA16 selector produces byte-identical output to a fresh eager encode under zero, one-byte, and ragged capacities.
2. Progress, acknowledgement, lease isolation, and sticky typed terminals retain the existing bounded encoder contract under rejected capability, resource, mutation, and writer schedules.
3. Failed construction or admission exposes no partial eager output or caller-buffered bytes.

**Plans**: TBD
**Scope guard**: The feature selects the one existing byte-emission machine; it must not add a format-specific buffer, transport, or wrapper.

### Phase 71: RGBA16 Adam7 PNG Encoding

**Goal**: Library users can explicitly request Type-6/16 Adam7 output with exact lane reconstruction and preserved established encoder options.
**Depends on**: Phase 70
**Requirements**: RGBA16ENC-03
**Success Criteria**:

1. An explicit RGBA16 Adam7 selection produces legal seven-pass Type-6/16 output whose explicit decode restores each source component byte at its original coordinate.
2. Eager and caller-buffered Adam7 output remain identical across supported filter and compression selections, retaining atomic admission and frozen non-interlaced behavior.
3. Existing RGB8/RGBA8 and Gray/GrayAlpha interlace routes remain unchanged.

**Plans**: TBD
**Scope guard**: Extend only the established profile-aware Adam7 traversal; no generic interlace default, colour transform, or duplicated pass planner.

### Phase 72: RGBA16 Encode Qualification

**Goal**: Library users can rely on exact, bounded, portable RGBA16 PNG output under normal and Adam7 routes.
**Depends on**: Phase 71
**Requirements**: RGBA16ENC-04
**Success Criteria**:

1. Independent normal and Adam7 Type-6/16 wire/decode vectors prove complete U16 lane fidelity without using the current encoder as their oracle.
2. Eager and caller-buffered selectors reject hostile capability, descriptor, resource, and lease conditions atomically while legacy outputs stay frozen.
3. The ordinary full PNG package, including explicit encode/decode and compatibility suites, passes on wasm, wasm-gc, js, and native.

**Plans**: TBD
**Scope guard**: Qualification uses the ordinary source tree and fixed independent expectations only; no copied source trees, target-specific bypasses, release automation, or FFI.

## Progress

| Phase | Plans Complete | Status | Completed |
|---|---|---|---|
| 69. Explicit RGBA16 PNG Encoding | 0/1 | Not started | - |
| 70. Resumable RGBA16 PNG Encoding | 1/1 | Complete    | 2026-07-23 |
| 71. RGBA16 Adam7 PNG Encoding | 0/1 | Not started | - |
| 72. RGBA16 Encode Qualification | 0/1 | Not started | - |
