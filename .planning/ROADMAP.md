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
- ✅ **v0.30 SVG Production Readiness** — Phases 91-94 (shipped 2026-07-26). [Full history](./milestones/v0.30-ROADMAP.md)
- 📋 **v0.31 SVG Numeric Boundary Unification** — Phases 95-96 (planned).

## Phases

- [x] **Phase 95: Shared SVG Geometry Boundary** - Make parser preflight and lowering use one checked geometry seam while retaining valid SVG behavior. (completed 2026-07-26)
- [ ] **Phase 96: SVG Boundary Parity Qualification** - Prove fail-closed unsafe geometry and compatibility parity on every supported target.

## Phase Details

### Phase 95: Shared SVG Geometry Boundary

**Goal**: Library users retain established valid SVG scenes and drawing lists while transforms, viewBox mapping, and shape/path coordinate derivation use one checked internal geometry implementation.
**Depends on**: Nothing (first phase)
**Requirements**: SVGUNI-01
**Success Criteria** (what must be TRUE):

  1. Valid SVG fixtures that use transforms, viewBox mapping, shapes, and paths produce their established scene and drawing-list behavior.
  2. Maintainers can verify that parser preflight and lowering obtain checked geometry facts for each supported geometry family from the same internal seam.
  3. Existing valid SVG behavior remains available without a new public API, changed numeric limit, or changed public error schema.

**Plans**: 2/2 plans executed

- [x] 95-01-PLAN.md
- [x] 95-02-PLAN.md

### Phase 96: SVG Boundary Parity Qualification

**Goal**: Unsafe SVG geometry fails at the shared numeric boundary before publication, and maintainers can detect future parser/lowerer divergence without changing established compatibility behavior.
**Depends on**: Phase 95
**Requirements**: SVGUNI-02, SVGUNI-03
**Success Criteria** (what must be TRUE):

  1. Explicit unsafe and derived-overflow SVG geometry returns the established structured error before a scene, drawing list, or raster result is published.
  2. Maintainers can run deterministic adversarial controls that fail if parser preflight and lowering disagree about a numeric-boundary outcome.
  3. Valid finite singular transforms continue to lower successfully, and RFC 0008 opacity and layer behavior remains unchanged.
  4. The parity and compatibility controls pass on `wasm`, `wasm-gc`, `js`, and `native`.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 95. Shared SVG Geometry Boundary | 2/2 | Complete    | 2026-07-26 |
| 96. SVG Boundary Parity Qualification | 0/TBD | Not started | - |

---
*Roadmap last updated: 2026-07-26 for v0.31 planning.*
