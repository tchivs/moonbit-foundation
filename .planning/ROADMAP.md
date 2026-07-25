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
- ✅ **v0.28 Indexed PNG Compression Profiles** — Phases 85-87 (shipped 2026-07-24). [Full history](./milestones/v0.28-ROADMAP.md)
- ✅ **v0.29 Indexed Adam7 Compression Profiles** — Phases 88-90 (shipped 2026-07-24). [Full history](./milestones/v0.29-ROADMAP.md)
- 📋 **v0.30 SVG Production Readiness** — Phases 91-94 (planned).

## Phases

- [x] **Phase 91: SVG Numeric Contract** - Define the target-neutral numeric admission envelope and prove every scalar route is covered. (completed 2026-07-26)
- [ ] **Phase 92: Fail-Closed SVG Parsing** - Reject unsafe explicit SVG numbers before they can form a scene or drawing list.
- [ ] **Phase 93: SVG Compatibility & Portable Qualification** - Preserve valid lowering, opacity layering, and canvas-capacity behavior across portable targets.
- [ ] **Phase 94: SVG Benchmark Evidence** - Provide correctness-gated workloads and a reproducible native-release baseline.

## Phase Details

### Phase 91: SVG Numeric Contract

**Goal**: Library users have a documented, target-neutral SVG numeric admission contract covering every supported scalar ingress and derived-value path.
**Depends on**: Nothing (first phase)
**Requirements**: SVGPR-01
**Success Criteria** (what must be TRUE):

  1. Library users can consult one documented finite, bounded SVG numeric admission contract that applies consistently on `js`, `wasm`, `wasm-gc`, and `native`.
  2. Supported SVG numeric inputs and derived calculations have route-matrix evidence that identifies their admission outcome under the documented envelope.
  3. Valid finite SVG controls at the documented boundary retain their established parse and lowering behavior.

**Plans**: 2/2 plans executed

- [x] 91-01-PLAN.md
- [x] 91-02-PLAN.md

### Phase 92: Fail-Closed SVG Parsing

**Goal**: Explicitly unsafe SVG numeric input is rejected with a structured error before it can produce a scene or drawing list.
**Depends on**: Phase 91
**Requirements**: SVGPR-02
**Success Criteria** (what must be TRUE):

  1. A user who supplies a non-finite, malformed, or out-of-envelope coordinate, length, transform, viewBox, path, or paint scalar receives structured SVG error context.
  2. An SVG value whose relative coordinate, viewBox, affine, trigonometric, or composition calculation becomes unsafe is rejected before lowering or rasterization.
  3. Rejected SVG input produces neither a scene nor a drawing list, while omitted attributes retain their established SVG defaults.
  4. Finite singular transforms remain valid according to the documented numeric contract.

**Plans**: TBD

### Phase 93: SVG Compatibility & Portable Qualification

**Goal**: Library users retain deterministic valid SVG lowering and raster output, including isolated opacity semantics and the canvas layer-capacity boundary, on every portable target.
**Depends on**: Phase 92
**Requirements**: SVGPR-03
**Success Criteria** (what must be TRUE):

  1. Valid finite SVG fixtures retain deterministic drawing-operation and raster-output results on `js`, `wasm`, `wasm-gc`, and `native`.
  2. Group, element, fill, stroke, and nested opacity compose through the existing isolated-layer semantics rather than changing per-paint output.
  3. Documents within the existing 16-layer canvas capability render as before, while a 17th nested opacity layer reports the established capacity outcome.
  4. Unsafe SVG rejection leaves no partial scene, drawing list, or raster result on all supported targets.

**Plans**: TBD

### Phase 94: SVG Benchmark Evidence

**Goal**: Maintainers can reproduce correctness-gated SVG workload measurements and compare a documented native-release baseline responsibly.
**Depends on**: Phase 93
**Requirements**: SVGPR-04
**Success Criteria** (what must be TRUE):

  1. Maintainers can run accurately named, fixed path-parse, transform-composition, and parse-to-lower workloads after each verifies its expected command, affine, or drawing-operation facts.
  2. The benchmark workloads build and run on `js`, `wasm`, `wasm-gc`, and `native` without using cross-target timings as a performance comparison.
  3. A documented native release baseline records the exact command, corpus and correctness digests, toolchain and host facts, warmup, and seven captures for like-for-like comparison.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 91. SVG Numeric Contract | 2/2 | Complete    | 2026-07-26 |
| 92. Fail-Closed SVG Parsing | 0/TBD | Not started | - |
| 93. SVG Compatibility & Portable Qualification | 0/TBD | Not started | - |
| 94. SVG Benchmark Evidence | 0/TBD | Not started | - |

---
*Roadmap last updated: 2026-07-25 for v0.30 planning.*
