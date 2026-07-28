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
- ✅ **v0.32 TrueType Font Foundation** — Phases 97-100 (shipped 2026-07-28). [Full history](./milestones/v0.32-ROADMAP.md)
- 📋 **v0.33 TrueType Collection Adapters** — Phases 101-103 (planned).

## Phases

- [x] **Phase 101: Collection Contract and Bounded Envelope** - Open and inspect bounded raw TTC/OTC version 1 and 2 collections through a compact semantic contract. (completed 2026-07-28)
- [x] **Phase 102: Root-Relative Selected-Face Admission** - Select one supported collection face and use the existing `Font` behavior through a no-copy root-relative adapter. (completed 2026-07-28)
- [ ] **Phase 103: Hostile, Licensed, and Four-Target Qualification** - Prove atomic failures, standalone compatibility, licensed interoperability, and identical portable behavior.

## Phase Details

### Phase 101: Collection Contract and Bounded Envelope

**Goal**: Library authors can open caller-provided raw TTC/OTC version 1 or 2 bytes under explicit authority and inspect the collection's bounded semantic face facts without exposing parser internals.
**Depends on**: Phase 100
**Requirements**: TTC-01
**Success Criteria** (what must be TRUE):

  1. A library author can open immutable TTC/OTC version 1 or 2 bytes and observe the exact non-zero face count without copying the complete collection or materializing standalone fonts.
  2. A library author can inspect every zero-based face through a closed bounded profile that distinguishes supported static `glyf`, CFF/CFF2, variable, and other unsupported faces without exposing raw offsets or table records.
  3. A library author can distinguish a version-2 collection with no DSIG from one with a structurally present but explicitly unverified DSIG envelope.

**Plans**: 3/3 plans executed

- [x] 101-01-PLAN.md
- [x] 101-02-PLAN.md
- [x] 101-03-PLAN.md

### Phase 102: Root-Relative Selected-Face Admission

**Goal**: Library authors can select one supported static TrueType face from an admitted collection and use the existing opaque `Font` contract unchanged.
**Depends on**: Phase 101
**Requirements**: TTC-02, TTC-03
**Success Criteria** (what must be TRUE):

  1. A library author can select any in-range static `glyf`-based TrueType face and receive the existing `Font`, with metrics, Unicode mapping, kerning, glyph identity, and unhinted outlines matching the equivalent standalone logical font.
  2. Valid selected faces work when their table bytes occur before or after their non-zero face directory because table offsets are resolved against the collection root.
  3. A selected face admits correctly whether its table bytes are distinct or validly shared at exact ranges with sibling faces, without copying the retained collection root.
  4. A supported selected face remains usable beside unsupported CFF/CFF2 or variable siblings, while collection-specific table and checksum semantics remain enforced without disabling standalone checks.

**Plans**: 3/3 plans executed

- [x] 102-01-PLAN.md
- [x] 102-02-PLAN.md
- [x] 102-03-PLAN.md

### Phase 103: Hostile, Licensed, and Four-Target Qualification

**Goal**: Maintainers can reproduce the complete collection-to-`Font` workflow and its fail-closed boundaries with generated and licensed evidence on every supported target.
**Depends on**: Phase 102
**Requirements**: TTC-04, TTC-05
**Success Criteria** (what must be TRUE):

  1. Malformed collection structure, invalid face indices, unsupported selected profiles, checked-arithmetic failures, exhausted semantic limits, and exhausted budgets return deterministic structured outcomes without exposing a partial collection or font or charging an uncommitted transaction.
  2. Mutation before or during collection inspection, selected-face admission, or inherited `Font` queries fails closed without publishing stale semantic facts or partial geometry.
  3. Maintainers can reproduce generated TTC v1/v2, DSIG, sharing, mixed-profile, non-zero-base, hostile, and complete public collection-to-`Font` workflows from immutable fixtures.
  4. At least one provenance-tracked licensed collection or reproducible licensed derivative proves public interoperability while the complete v0.32 standalone-SFNT behavior remains unchanged.
  5. Independent `js`, `wasm`, `wasm-gc`, and `native` runs report identical semantic facts and preserve pure MoonBit execution, `mb-font -> mb-core` as the only runtime dependency, and the explicit WOFF/CFF implementation boundary.

**Plans**: 1/3 plans executed

- [x] 103-01-PLAN.md
- [ ] 103-02-PLAN.md
- [ ] 103-03-PLAN.md

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 101. Collection Contract and Bounded Envelope | 3/3 | Complete    | 2026-07-28 |
| 102. Root-Relative Selected-Face Admission | 3/3 | Complete    | 2026-07-28 |
| 103. Hostile, Licensed, and Four-Target Qualification | 1/3 | In Progress|  |

---
*Roadmap last updated: 2026-07-28 for v0.33 roadmap creation.*
