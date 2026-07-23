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

### 📋 v0.24 Indexed PNG Encode

- [x] **Phase 76: Indexed8 PNG Source & Eager PLTE** — Define an owning PNG-only indexed source and emit bounded Type-3/8 eager PNG with PLTE. (completed 2026-07-24)
- [x] **Phase 77: Indexed PNG Transparency** — Add canonical optional tRNS emission and exact RGB/RGBA decode evidence. (completed 2026-07-24)
- [x] **Phase 78: Resumable Indexed PNG & Qualification** — Add caller-buffered parity, hostile leases, independent wire vectors, and four-target proof. (completed 2026-07-24)

## Phase Details

### Phase 76: Indexed8 PNG Source & Eager PLTE

**Goal:** Library users can construct a dedicated immutable Indexed8 source and eagerly emit bounded non-interlaced Type-3/8 PNG with PLTE.
**Depends on:** Phase 75
**Requirements:** INDEX-01, INDEX-02
**Scope guard:** Reuse one bounded PNG encoder; do not widen generic models or add transparency, caller-buffered output, low bit depths, Adam7, quantization, staging, FFI, or release automation.

### Phase 77: Indexed PNG Transparency

**Goal:** Library users can encode palette alpha as canonical optional tRNS and publicly decode exact RGB8/RGBA8 palette semantics.
**Depends on:** Phase 76
**Requirements:** INDEX-03
**Scope guard:** Extend the same owning Indexed8 source and shared eager frame machine only; caller-buffered parity and other indexed profiles remain deferred.

### Phase 78: Resumable Indexed PNG & Qualification

**Goal:** Library users can emit Indexed8 PNG through caller-owned output leases with eager-identical bytes, sticky terminals, independent wire vectors, and four-target proof.
**Depends on:** Phase 77
**Requirements:** INDEX-04, INDEX-05
**Scope guard:** Add one thin caller-buffered Indexed8 adapter to the existing bounded machine; no alternate transport, generic model widening, low bit depths, Adam7, strategy expansion, quantization, staging, FFI, release automation, target wrappers, or copied source trees.
