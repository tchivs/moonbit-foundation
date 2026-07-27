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
- ✅ **v0.31 SVG Numeric Boundary Unification** — Phases 95-96 (shipped 2026-07-26). [Full history](./milestones/v0.31-ROADMAP.md)
- 📋 **v0.32 TrueType Font Foundation** — Phases 97-100 (planned).

## Phases

- [x] **Phase 97: Font Admission and Metrics** - Open bounded TrueType SFNT data through `mb-font` and expose checked global and per-glyph metrics. (completed 2026-07-27)
- [ ] **Phase 98: Unicode Mapping and Kerning** - Resolve Unicode scalars and legacy horizontal kerning through deterministic, distinguishable query outcomes.
- [ ] **Phase 99: Simple and Composite Outlines** - Extract complete transactional `Path2`-compatible outlines for simple and bounded one-level composite glyphs.
- [ ] **Phase 100: Portable Font Qualification** - Prove the complete public font workflow and hostile-input behavior on all four supported targets.

## Phase Details

### Phase 97: Font Admission and Metrics

**Goal**: Library authors can open one bounded static TrueType-outline SFNT from immutable bytes and inspect stable font-wide and per-glyph horizontal metrics through the portable `tchivs/mb-font` module.
**Depends on**: Nothing (first phase in v0.32)
**Requirements**: FONT-01
**Success Criteria** (what must be TRUE):

  1. A library author can open a standalone `0x00010000` TrueType SFNT from caller-provided immutable bytes using explicit font limits and a shared budget.
  2. A library author can inspect named units-per-em, global bounds, horizontal and typographic line metrics without an invented target-dependent “best” metric.
  3. A library author can query any admitted glyph for its advance, left side bearing, bounds, and checked derived right side bearing, including empty glyphs and the repeated-final-advance `hmtx` tail.
  4. Unsupported containers/outlines, malformed or inconsistent required tables, exhausted limits, and changed backing storage return structured errors without publishing a partial font.

**Plans**: 3/3 plans executed

- [x] 97-01-PLAN.md
- [x] 97-02-PLAN.md
- [x] 97-03-PLAN.md

### Phase 98: Unicode Mapping and Kerning

**Goal**: Library authors can resolve Unicode scalars and basic legacy horizontal kerning through deterministic queries over the admitted font.
**Depends on**: Phase 97
**Requirements**: FONT-02, FONT-04
**Success Criteria** (what must be TRUE):

  1. A library author can map BMP and supplementary-plane Unicode scalars through deterministic format-12-then-format-4 selection and receive an in-range glyph ID.
  2. A valid unmapped scalar returns glyph zero, while an invalid Unicode scalar or malformed selected mapping returns a structured error.
  3. A library author can query a legacy version-0 horizontal format-0 kerning pair and receive its signed adjustment, with table absence and supported pair miss both returning neutral zero.
  4. Present-but-unsupported kerning data and malformed kerning data remain distinguishable from absence or a pair miss.

**Plans**: 3 plans
**Wave 1**

- [ ] 98-01-PLAN.md — Deliver the end-to-end Unicode scalar tracer and complete deterministic format-12/format-4 selection and lookup.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 98-02-PLAN.md — Add bounded optional legacy horizontal kerning with explicit limits and distinct absence, unsupported, and malformed outcomes.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 98-03-PLAN.md — Qualify both queries on all targets and close generated-interface, policy, and documentation publication.

### Phase 99: Simple and Composite Outlines

**Goal**: Library authors can extract complete unhinted `Path2`-compatible outlines for valid simple glyphs and bounded one-level composites without partial geometry on failure.
**Depends on**: Phase 98
**Requirements**: FONT-03
**Success Criteria** (what must be TRUE):

  1. A library author can extract a simple glyph with repeated flags, signed coordinate deltas, implied on-curve points, original contour order/winding, and deterministic closure represented as a complete `Path2`-compatible outline.
  2. A library author can extract a bounded one-level composite that applies supported XY or point attachment and uniform, nonuniform, or 2×2 transforms to its component outlines.
  3. Empty and degenerate valid glyphs return deterministic complete outline results without executing TrueType hinting or rasterizing pixels.
  4. Malformed streams, invalid component references or flags, cycles, checked-arithmetic failures, mutation, and resource exhaustion return structured errors without exposing partial points, contours, or path commands.

**Plans**: TBD

### Phase 100: Portable Font Qualification

**Goal**: Maintainers can reproduce the complete public font workflow and hostile-input behavior with immutable fixtures on every supported target.
**Depends on**: Phase 99
**Requirements**: FONT-05
**Success Criteria** (what must be TRUE):

  1. A maintainer can run one public immutable-bytes workflow that opens a font, maps Unicode, reads metrics, extracts simple and composite outlines, and queries kerning with identical semantic facts on `js`, `wasm`, `wasm-gc`, and `native`.
  2. Generated adversarial fixtures produce the same structured malformed-input, unsupported-feature, mutation, arithmetic, and resource-limit outcomes on all four targets.
  3. At least one licensed real-font specimen has immutable bytes, recorded provenance/license, digest, table inventory, and reproducible public interoperability facts.
  4. Isolated `mb-font` and workspace-wide qualification demonstrate the public dependency remains `mb-font -> mb-core` with no FFI, canvas dependency, host font discovery, GUI state, shaping, hinting, CFF, or rasterization.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 97. Font Admission and Metrics | 3/3 | Complete    | 2026-07-27 |
| 98. Unicode Mapping and Kerning | 0/3 | Not started | - |
| 99. Simple and Composite Outlines | 0/TBD | Not started | - |
| 100. Portable Font Qualification | 0/TBD | Not started | - |

---
*Roadmap last updated: 2026-07-26 for v0.32 planning.*
