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

## Phases

### 📋 v0.23 Low-Bit Grayscale PNG Encode

- [ ] **Phase 73: Explicit Packed Grayscale PNG** — Add exact, non-interlaced Type-0 1/2/4-bit eager output from representable Gray/U8 sources.
- [ ] **Phase 74: Resumable Packed Grayscale PNG** — Add caller-buffered packed output through the existing bounded encoder machine.
- [ ] **Phase 75: Packed Grayscale PNG Qualification** — Prove independent wire fidelity, hostile behavior, compatibility, and four-target portability.

## Phase Details

### Phase 73: Explicit Packed Grayscale PNG

**Goal:** Library users can select lossless Type-0/1, Type-0/2, or Type-0/4 output from exactly representable canonical Gray/U8 source levels.
**Depends on:** Phase 72
**Requirements:** GRAYPACK-01, GRAYPACK-02
**Scope guard:** Reuse the one bounded PNG encoder; no implicit quantization, bit-packed image model, Adam7, palette, or staging path.

### Phase 74: Resumable Packed Grayscale PNG

**Goal:** Library users can emit the same packed Type-0 PNG through caller-owned output leases with existing atomic and sticky semantics.
**Depends on:** Phase 73
**Requirements:** GRAYPACK-03
**Scope guard:** Reuse Phase 73's packed profile/provider and the existing caller-buffered machine; no second transport.

### Phase 75: Packed Grayscale PNG Qualification

**Goal:** Library users can rely on exact, bounded, portable low-bit grayscale PNG output.
**Depends on:** Phase 74
**Requirements:** GRAYPACK-04
**Scope guard:** Independent test evidence and the ordinary source tree only; no wrappers, release automation, or copied trees.
