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

## Phases

### 📋 v0.25 Indexed Low-Bit PNG Encode

- [x] **Phase 79: Indexed Low-Bit Eager Packing** — Add exact bounded Type-3/1, /2, and /4 eager output from canonical Indexed8 sources. (completed 2026-07-24)
- [ ] **Phase 80: Resumable Indexed Low-Bit Qualification** — Add caller-buffered parity, hostile lease proof, independent vectors, and four-target qualification.

## Phase Details

### Phase 79: Indexed Low-Bit Eager Packing

**Goal:** Library users can explicitly encode an existing `PngIndexedImage` as bounded non-interlaced Type-3/1, /2, or /4 PNG with exact MSB-first packed rows and PLTE/tRNS framing.
**Depends on:** Phase 78
**Requirements:** INDEXLOW-01, INDEXLOW-02, INDEXLOW-03
**Scope guard:** Reuse the owning Indexed8 source and one bounded machine; no generic model widening, quantization, Adam7, strategy expansion, staging, FFI, or release automation.

### Phase 80: Resumable Indexed Low-Bit Qualification

**Goal:** Library users can emit the same low-bit Indexed PNG through caller-owned leases with eager-identical bytes, sticky terminals, and portable independent evidence.
**Depends on:** Phase 79
**Requirements:** INDEXLOW-04, INDEXLOW-05
**Scope guard:** Add only a thin caller-buffered entry to Phase 79's machine and qualify it; no second transport, indexed Adam7, model widening, strategies, wrappers, copied source trees, or release automation.
