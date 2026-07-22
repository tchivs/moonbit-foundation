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
- ✅ **v0.16 Grayscale Alpha PNG** — Phases 50-52, packed Gray+Alpha8 model, bounded PNG encoding, and portable public evidence (shipped 2026-07-23). [Full history](./milestones/v0.16-ROADMAP.md)
- 📋 **v0.17 GrayAlpha16 PNG Interchange** — Phases 53-55, packed U16 Gray+Alpha model, bounded non-interlaced Type-4/16 encoding, and portable public evidence.

## Phases

<details>
<summary>✅ v0.15 Gray16 PNG Interchange (Phases 47-49) — SHIPPED 2026-07-22</summary>

- [x] Phase 47: Gray16 Factory Compatibility (1/1 plan)
- [x] Phase 48: Bounded Gray16 Encoder Path (1/1 plan)
- [x] Phase 49: Portable Gray16 Public Evidence (1/1 plan)

</details>

<details>
<summary>✅ v0.16 Grayscale Alpha PNG (Phases 50-52) — SHIPPED 2026-07-23</summary>

- [x] Phase 50: Gray+Alpha Image Model (1/1 plan)
- [x] Phase 51: Bounded Gray+Alpha PNG Encoding (2/2 plans)
- [x] Phase 52: Portable Gray+Alpha Public Evidence (1/1 plan)

</details>

### 📋 v0.17 GrayAlpha16 PNG Interchange (Planned)

**Milestone Goal:** MoonBit library users can create packed U16 grayscale-plus-straight-alpha images and encode them as bounded, non-interlaced Type-4/16 PNGs with exact wire-level and portable public evidence, without changing existing image or PNG contracts.

- [x] **Phase 53: GrayAlpha16 Model and Checked Storage** - Establish the packed U16 two-component straight-alpha source contract while preserving existing descriptors and storage behavior. (Requirements: GRAYA16-01) (completed 2026-07-23)
- [ ] **Phase 54: Bounded Type-4/16 Encoder** - Route compatible GrayAlpha16 images through the shared eager and caller-buffered bounded PNG pipeline. (Requirements: GRAYA16-02, GRAYA16-03)
- [ ] **Phase 55: Portable Public Evidence** - Prove GrayAlpha16 wire/decode fidelity, hostile caller-buffered identity, legacy stability, and four-target execution. (Requirements: GRAYA16-04)

## Phase Details

### Phase 53: GrayAlpha16 Model and Checked Storage

**Goal**: Library users can create and inspect packed U16 grayscale-plus-alpha images with explicit straight-alpha semantics while existing image descriptor and storage behavior remains unchanged.
**Depends on**: Phase 52
**Requirements**: GRAYA16-01
**Success Criteria** (what must be TRUE):

1. A library user can create a packed U16 image with exactly one gray and one straight-alpha component and inspect its canonical descriptor metadata.
2. A library user can read and write both bytes of distinct gray and alpha U16 components through checked generic packed-image storage views.
3. Existing Gray, GrayAlpha8, RGB, and RGBA descriptors, storage access, and observable operations retain their prior behavior, while malformed or incompatible GrayAlpha16 descriptors are rejected.

**Plans**: 1/1 plans executed

Plans:

- [x] 53-01-PLAN.md — Add the exact GrayAlpha16 descriptor identity and prove generic U16 checked-storage compatibility.

### Phase 54: Bounded Type-4/16 Encoder

**Goal**: Library users can encode compatible packed U16 GrayAlpha images through explicit eager and caller-buffered factories as bounded, non-interlaced Type-4/16 PNGs.
**Depends on**: Phase 53
**Requirements**: GRAYA16-02, GRAYA16-03
**Success Criteria** (what must be TRUE):

1. A library user can choose explicit eager or caller-buffered GrayAlpha16 PNG factories and receive a non-interlaced PNG with colour type 4, bit depth 16, and each source pair serialized as `Ghi,Glo,Ahi,Alo`.
2. A compatible GrayAlpha16 image can use None or Adaptive filtering with Stored, FixedOrStored, or DynamicOrFixedOrStored compression through the same bounded encoding behavior, without image-sized staging.
3. Incompatible inputs and capability, geometry, output, work, or budget failures leave the eager writer empty and expose neither a usable caller-buffered lease nor partial output.
4. A caller-buffered GrayAlpha16 encoder advances only for accepted bytes and preserves its replay/terminal contract across supported strategy selections.

**Plans**: 2 plans

Plans:

- [ ] 54-01-PLAN.md — Add the explicit bounded GrayAlpha16 Type-4/16 eager and caller-buffered encoder path.
- [ ] 54-02-PLAN.md — Prove GrayAlpha16 atomic admission and acknowledgement-safe replay ownership.

### Phase 55: Portable Public Evidence

**Goal**: Library users have independent public proof that GrayAlpha16 PNG output is wire-faithful, caller-buffered-safe, legacy-compatible, and portable across every supported target.
**Depends on**: Phase 54
**Requirements**: GRAYA16-04
**Success Criteria** (what must be TRUE):

1. Public non-symmetric GrayAlpha16 vectors prove literal U16 `Ghi,Glo,Ahi,Alo` PNG wire order and the documented decoder canonicalization to straight RGBA8 high bytes.
2. Zero-capacity, one-byte, and ragged caller capacities produce output byte-identical to eager output, report accepted-only progress, preserve untouched lease tails, and retain sticky terminal outcomes.
3. Frozen Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 vectors retain their existing bytes, and the complete public PNG evidence runs independently on js, wasm, wasm-gc, and native.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 53. GrayAlpha16 Model and Checked Storage | 1/1 | Complete    | 2026-07-23 |
| 54. Bounded Type-4/16 Encoder | 0/TBD | Not started | - |
| 55. Portable Public Evidence | 0/TBD | Not started | - |
