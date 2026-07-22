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
- ✅ **v0.15 Gray16 PNG Interchange** — Phases 47-49, bounded U16 Gray PNG across four targets (shipped 2026-07-22). [Full history](./milestones/v0.15-ROADMAP.md)
- 📋 **v0.16 Grayscale Alpha PNG** — Phases 50-52, packed Gray+Alpha8 model, bounded PNG encoding, and portable public evidence.

## Phases

<details>
<summary>✅ v0.15 Gray16 PNG Interchange (Phases 47-49) — SHIPPED 2026-07-22</summary>

- [x] Phase 47: Gray16 Factory Compatibility (1/1 plan)
- [x] Phase 48: Bounded Gray16 Encoder Path (1/1 plan)
- [x] Phase 49: Portable Gray16 Public Evidence (1/1 plan)

</details>

### 📋 v0.16 Grayscale Alpha PNG (Planned)

**Milestone Goal:** MoonBit library users can create packed straight-alpha grayscale images and encode them as bounded, non-interlaced Gray+Alpha8 PNGs with portable public proof, without changing existing PNG or image-model contracts.

- [x] **Phase 50: Gray+Alpha Image Model** - Establish the explicit packed U8 two-component image contract while preserving existing image formats. (completed 2026-07-23)
- [x] **Phase 51: Bounded Gray+Alpha PNG Encoding** - Route compatible Gray+Alpha8 sources through the shared eager and caller-buffered bounded encoder. (completed 2026-07-23)
- [ ] **Phase 52: Portable Gray+Alpha Public Evidence** - Prove wire fidelity, hostile caller-buffered identity, legacy compatibility, and four-target behavior.

## Phase Details

### Phase 50: Gray+Alpha Image Model

**Goal**: Library users can create and inspect a packed U8 grayscale-plus-alpha image with explicit straight-alpha semantics without changing existing Gray, RGB, or RGBA behavior.
**Depends on**: Phase 49
**Requirements**: GRAYA-01
**Success Criteria** (what must be TRUE):

  1. A library user can create a packed U8 grayscale-plus-alpha image whose pixels contain exactly one gray and one alpha component.
  2. A library user can inspect the image descriptor and observe explicit straight-alpha metadata for the two-component format.
  3. Existing Gray, RGB, and RGBA descriptors, views, storage, and operations retain their prior observable behavior.

**Plans**: TBD

### Phase 51: Bounded Gray+Alpha PNG Encoding

**Goal**: Library users can produce standards-compliant, non-interlaced Gray+Alpha8 PNGs through the existing bounded eager and caller-buffered pipeline.
**Depends on**: Phase 50
**Requirements**: GRAYA-02, GRAYA-03
**Success Criteria** (what must be TRUE):

  1. A library user can select explicit eager or caller-buffered factories for a compatible Gray+Alpha8 image and receive a non-interlaced PNG with color type 4 and bit depth 8.
  2. Decoding the emitted PNG preserves every source gray/alpha pair for compatible images.
  3. The explicit Gray+Alpha8 route supports None and Adaptive filtering with Stored, FixedOrStored, and DynamicOrFixedOrStored compression selections under the established bounded contract.
  4. Incompatible inputs and resource-limit failures are reported before any eager output or caller-buffered lease is exposed.

**Plans**: 2/2 plans executed

Plans:
**Wave 1**

- [x] 51-01-PLAN.md — Deliver the bounded Gray+Alpha8 eager/caller-buffered encoder tracer and factory families.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 51-02-PLAN.md — Prove bounded strategy parity and atomic Gray+Alpha preflight rejection.

### Phase 52: Portable Gray+Alpha Public Evidence

**Goal**: Library users can rely on documented Gray+Alpha8 PNG fidelity and caller-buffered semantics across every supported portable target while legacy output remains stable.
**Depends on**: Phase 51
**Requirements**: GRAYA-04, GRAYA-05
**Success Criteria** (what must be TRUE):

  1. Public Gray+Alpha8 vectors with non-symmetric gray and alpha values prove exact PNG wire-pair preservation and the documented decode canonicalization to straight RGBA8.
  2. Zero-capacity, one-byte, and ragged caller-buffered schedules produce output byte-identical to eager output, report accepted-only progress, and retain sticky terminal outcomes.
  3. Frozen Gray8, Gray16, RGB8, and straight-RGBA8 vectors retain their existing bytes.
  4. The complete Gray+Alpha8 evidence executes independently on js, wasm, wasm-gc, and native.

**Plans**: 1 plan

Plans:

**Wave 1**

- [ ] 52-01-PLAN.md — Add public GrayAlpha wire/decode, hostile caller-buffered, frozen-vector, and four-target evidence.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 50. Gray+Alpha Image Model | 1/1 | Complete    | 2026-07-23 |
| 51. Bounded Gray+Alpha PNG Encoding | 2/2 | Complete    | 2026-07-23 |
| 52. Portable Gray+Alpha Public Evidence | 0/TBD | Not started | - |
