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
- ✅ **v0.15 Gray16 PNG Interchange** — Phases 47-49 (shipped 2026-07-22). [Full history](./milestones/v0.15-ROADMAP.md)
- ✅ **v0.16 Grayscale Alpha PNG** — Phases 50-52 (shipped 2026-07-23). [Full history](./milestones/v0.16-ROADMAP.md)
- ✅ **v0.17 GrayAlpha16 PNG Interchange** — Phases 53-55 (shipped 2026-07-23). [Full history](./milestones/v0.17-ROADMAP.md)
- 📋 **v0.18 GrayAlpha16 Adam7 PNG** — Phases 56-58: bounded Type-4/16 interlaced output, replay-safe streaming, and portable public evidence.

## Phases

<details>
<summary>✅ v0.17 GrayAlpha16 PNG Interchange (Phases 53-55) — SHIPPED 2026-07-23</summary>

- [x] Phase 53: GrayAlpha16 Model and Checked Storage (1/1 plan)
- [x] Phase 54: Bounded Type-4/16 Encoder (2/2 plans)
- [x] Phase 55: Portable Public Evidence (1/1 plan)

</details>

### 📋 v0.18 GrayAlpha16 Adam7 PNG (Planned)

**Milestone Goal:** MoonBit library users can create bounded, explicit Adam7 Type-4/16 PNGs from legal packed U16 Gray+Alpha images while preserving strict little-endian descriptor admission, frozen non-interlaced bytes, and the existing single portable PNG pipeline.

- [x] **Phase 56: GrayAlpha16 Adam7 Factory and Pass Profile** - Add explicit eager and caller-buffered Adam7 Type-4/16 selection for the legal U16 GrayAlpha source contract. (Requirements: GRAYA16A7-01) (completed 2026-07-23)
- [ ] **Phase 57: Bounded Adam7 Streaming Semantics** - Extend the shared bounded traversal, filter, compression, and replay path to the new Type-4/16 Adam7 profile. (Requirements: GRAYA16A7-02)
- [ ] **Phase 58: Portable Adam7 Public Evidence** - Prove public pass-aware wire/decode fidelity, hostile caller-buffer behavior, legacy stability, and four-target portability. (Requirements: GRAYA16A7-03)

## Phase Details

### Phase 56: GrayAlpha16 Adam7 Factory and Pass Profile

**Goal**: Library users can explicitly select eager or caller-buffered Adam7 encoding for legal packed U16 Gray+Alpha images and receive standards-compliant interlaced Type-4/16 PNGs.
**Depends on**: Phase 55
**Requirements**: GRAYA16A7-01
**Success Criteria** (what must be TRUE):

  1. A library user can select explicit eager and caller-buffered GrayAlpha16 Adam7 factories for a legal packed little-endian image.
  2. Each generated image declares Adam7 interlace, colour type 4, and bit depth 16, with every pass sample serialized in PNG order as `Ghi,Glo,Ahi,Alo`.
  3. The strict Big-endian GrayAlpha16 descriptor rejection remains in force, and existing non-interlaced GrayAlpha16 factory selection remains unchanged.

**Plans**: 2/2 plans executed

- [x] 56-01-PLAN.md
- [x] 56-02-PLAN.md

### Phase 57: Bounded Adam7 Streaming Semantics

**Goal**: Library users can use the new GrayAlpha16 Adam7 factories with the existing bounded PNG guarantees across filtering, compression, and caller-buffered replay.
**Depends on**: Phase 56
**Requirements**: GRAYA16A7-02
**Success Criteria** (what must be TRUE):

  1. A legal GrayAlpha16 Adam7 image can use None or Adaptive filtering with Stored, FixedOrStored, or DynamicOrFixedOrStored compression through one bounded encoder route.
  2. Adam7 filtering traverses the seven passes with pass-local predictor history and emits the same accepted bytes through eager and caller-buffered encoding.
  3. Incompatible input and capability, geometry, output, work, or budget failures leave the eager writer empty and expose neither partial output nor a usable caller-buffered lease.
  4. Caller-buffered replay validates the source before writing after a mutation, advances only for accepted bytes, and retains sticky terminal outcomes.

**Plans**: TBD

### Phase 58: Portable Adam7 Public Evidence

**Goal**: Library users have independent public proof that GrayAlpha16 Adam7 PNG output is pass-faithful, caller-buffered-safe, compatible with frozen routes, and portable on every supported target.
**Depends on**: Phase 57
**Requirements**: GRAYA16A7-03
**Success Criteria** (what must be TRUE):

  1. Public non-symmetric multi-pass vectors prove Adam7 pass placement and literal Type-4/16 `Ghi,Glo,Ahi,Alo` wire data, then decode through the documented straight-RGBA8 high-byte canonicalization.
  2. Fresh zero-capacity, one-byte, and ragged caller-buffer schedules remain eager-byte-identical, report accepted-only progress, preserve untouched lease tails, and retain sticky terminal outcomes.
  3. Frozen non-interlaced and legacy Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 PNG bytes remain unchanged, and the complete public PNG evidence passes on js, wasm, wasm-gc, and native.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 56. GrayAlpha16 Adam7 Factory and Pass Profile | 2/2 | Complete    | 2026-07-23 |
| 57. Bounded Adam7 Streaming Semantics | 0/TBD | Not started | - |
| 58. Portable Adam7 Public Evidence | 0/TBD | Not started | - |
