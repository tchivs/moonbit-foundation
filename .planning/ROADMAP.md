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
- ✅ **v0.18 GrayAlpha16 Adam7 PNG** — Phases 56-58 (shipped 2026-07-23). [Full history](./milestones/v0.18-ROADMAP.md)
- 📋 **v0.19 GrayAlpha8 Adam7 PNG** — Phases 59-61: explicit Type-4/8 Adam7 selection, bounded shared semantics, and portable public evidence.

## Phases

### 📋 v0.19 GrayAlpha8 Adam7 PNG (Planned)

**Milestone Goal:** MoonBit library users can create bounded, explicit Adam7 Type-4/8 PNGs from legal packed U8 Gray+Alpha images while preserving frozen non-interlaced output and the existing single portable PNG pipeline.

- [ ] **Phase 59: GrayAlpha8 Adam7 Factory and Pass Profile** - Add explicit eager and caller-buffered Type-4/8 Adam7 selection while freezing existing non-interlaced routes. (Requirements: GRAYA8A7-01)
- [ ] **Phase 60: Bounded Adam7 Streaming Semantics** - Prove all six strategy pairs retain the shared traversal, atomic preflight, pass-local filtering, and replay guarantees. (Requirements: GRAYA8A7-02)
- [ ] **Phase 61: Portable GrayAlpha8 Adam7 Public Evidence** - Prove literal wire/decode fidelity, hostile caller schedules, frozen compatibility, and four-target portability. (Requirements: GRAYA8A7-03)

## Phase Details

### Phase 59: GrayAlpha8 Adam7 Factory and Pass Profile

**Goal**: Library users can explicitly select eager or caller-buffered Adam7 encoding for legal packed U8 Gray+Alpha images and receive standards-compliant interlaced Type-4/8 PNGs without changing existing non-interlaced behavior.
**Depends on**: Phase 58
**Requirements**: GRAYA8A7-01
**Success Criteria** (what must be TRUE):

  1. A library user can select explicit eager and caller-buffered GrayAlpha8 Adam7 factories for a legal packed straight-alpha image.
  2. Each selected factory emits PNG IHDR colour type 4, bit depth 8, and Adam7 interlace method 1, with seven-pass samples serialized as `G,A`.
  3. Existing GrayAlpha8 non-interlaced constructors continue to select interlace method 0 and retain their frozen output bytes.

**Plans**: 2/2 plans executed

Plans:

- [x] 59-01-PLAN.md — Deliver the explicit GrayAlpha8 Adam7 eager/chunk factory, shared-profile admission, and independent seven-pass G,A tracer.
- [x] 59-02-PLAN.md — Harden all-strategy eager framing and ordinary public chunk/eager selector parity while preserving legacy Type-4/8 output.

### Phase 60: Bounded Adam7 Streaming Semantics

**Goal**: Library users can use GrayAlpha8 Adam7 through the existing single bounded PNG pipeline with the same filter, compression, atomic-admission, and acknowledgement-safe replay guarantees as established formats.
**Depends on**: Phase 59
**Requirements**: GRAYA8A7-02
**Success Criteria** (what must be TRUE):

  1. Every None or Adaptive × Stored, FixedOrStored, or DynamicOrFixedOrStored GrayAlpha8 Adam7 selection uses one shared encoder route and yields eager/chunk byte identity.
  2. Adam7 traversal covers seven pass-local filter contexts, so Adaptive predictor history never crosses from one pass into another.
  3. Incompatible descriptor and capability, geometry, output, work, or budget requests fail atomically before eager output or caller-buffered lease exposure.
  4. A checked U8 source mutation before replay causes Stored, Fixed, and Dynamic routes to write zero further lease bytes, preserve accepted-only accounting, and return the same sticky terminal error on later pulls.

**Plans**: TBD

### Phase 61: Portable GrayAlpha8 Adam7 Public Evidence

**Goal**: Library users have independent public proof that GrayAlpha8 Adam7 output is pass-faithful, caller-buffered-safe, compatible with frozen routes, and portable on every supported target.
**Depends on**: Phase 60
**Requirements**: GRAYA8A7-03
**Success Criteria** (what must be TRUE):

  1. A public non-symmetric all-seven-pass vector proves literal Type-4/8 `G,A` wire data and decodes through the established straight-RGBA8 `(G,G,G,A)` canonicalization.
  2. Fresh zero-capacity, one-byte, and ragged caller-buffer schedules remain eager-byte-identical, report accepted-only progress, preserve untouched lease tails, and retain sticky terminal outcomes.
  3. Frozen non-interlaced GrayAlpha8 and legacy Gray8, Gray16, GrayAlpha16, RGB8, and straight-RGBA8 PNG vectors remain unchanged, and the complete PNG package passes on js, wasm, wasm-gc, and native.

**Plans**: TBD

## Scope Boundary

This milestone excludes staging buffers, alternate encoders, decoder-model widening, Big-endian changes, release or registry work, target wrappers, and copied-source workflows.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 59. GrayAlpha8 Adam7 Factory and Pass Profile | 2/2 | In Progress|  |
| 60. Bounded Adam7 Streaming Semantics | 0/TBD | Not started | - |
| 61. Portable GrayAlpha8 Adam7 Public Evidence | 0/TBD | Not started | - |
