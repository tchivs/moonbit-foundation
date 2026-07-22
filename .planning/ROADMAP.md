# Roadmap: MoonBit Native Foundation

## Milestones

- ✅ **v0.1 Foundation** — Phases 1-5, 41 plans, 36/36 requirements (shipped 2026-07-17). [Full history](./milestones/v0.1-ROADMAP.md)
- ⏸️ **v0.2 Publication & Compatibility** — Phases 6-8; registry publication remains deliberately deferred without a registry mutation.
- ✅ **v0.3 Image Processing Core** — Phases 9-12, 9 requirements (shipped 2026-07-20). [Full history](./milestones/v0.3-ROADMAP.md)
- ✅ **v0.4 Portable Image Interchange** — Phases 13-16, pure-MoonBit QOI 1.0 across four targets (shipped 2026-07-20). [Full history](./milestones/v0.4-ROADMAP.md)
- ✅ **v0.5 QOI Streaming I/O** — Phases 17-19, resumable caller-buffered QOI streams across four targets (shipped 2026-07-20). [Full history](./milestones/v0.5-ROADMAP.md)
- ✅ **v0.6 PNG Interchange** — Phases 20-22, strict bounded RGB/RGBA PNG interchange and pure-MoonBit DEFLATE (shipped 2026-07-21).
- ✅ **v0.7 PNG Colour Fidelity** — Phases 23-25, strict PNG colour declarations without silent non-sRGB loss (shipped 2026-07-21).
- ✅ **v0.8 Resumable PNG Decode** — Phases 26-28, portable caller-buffered decode with strict completion and four-target evidence (shipped 2026-07-21). [Full history](./milestones/v0.8-ROADMAP.md)
- ✅ **v0.9 Resumable PNG Encode** — Phases 29-31, portable caller-buffered canonical PNG output with eager parity and four-target evidence (shipped 2026-07-21). [Full history](./milestones/v0.9-ROADMAP.md)
- ✅ **v0.10 PNG Compression Optimization** — Phases 32-34, opt-in fixed-Huffman-or-stored PNG compression with stored-DEFLATE defaults preserved, bounded admission, and four-target corpus evidence (shipped 2026-07-22). [Full history](./milestones/v0.10-ROADMAP.md)
- ✅ **v0.11 PNG Dynamic Huffman Compression** — Phases 35-37, bounded opt-in Dynamic DEFLATE with frozen Stored/FixedOrStored baselines, strict complete-PNG selection, acknowledgement-safe replay, and four-target evidence (shipped 2026-07-22). [Full history](./milestones/v0.11-ROADMAP.md)
- ✅ **v0.12 PNG Filter Optimization** — Phases 38-40, explicit bounded adaptive PNG row filtering with legacy compatibility and four-target evidence (shipped 2026-07-22). [Full history](./milestones/v0.12-ROADMAP.md)
- 📋 **v0.13 PNG Adam7 Encode** — Phases 41-43, explicit bounded Adam7 encoding with frozen legacy output and four-target public evidence.

## v0.13 PNG Adam7 Encode

**Milestone Goal:** Library users can explicitly encode existing RGB8 and straight-RGBA8 images as bounded Adam7 PNGs without changing legacy non-interlaced output or caller-buffered safety semantics.

## Phases

- [ ] **Phase 41: Adam7 Opt-In Compatibility** - Add the explicit interlace selection boundary while preserving every existing non-interlaced route.
- [ ] **Phase 42: Bounded Adam7 Pass Encoding** - Traverse and replay seven Adam7 passes through bounded filtering and compression admission.
- [ ] **Phase 43: Portable Adam7 Public Evidence** - Prove fidelity, eager/chunk identity, compatibility, and independent four-target execution.

## Phase Details

### Phase 41: Adam7 Opt-In Compatibility
**Goal**: Users can explicitly select Adam7 interlaced eager and caller-buffered PNG encoding for compatible RGB8 and straight-RGBA8 images without changing legacy non-interlaced bytes.
**Depends on**: Phase 40
**Requirements**: PNGI-01
**Success Criteria** (what must be TRUE):
  1. A library user can explicitly select Adam7 interlaced output through the existing eager and caller-buffered encoder factories for compatible RGB8 and straight-RGBA8 images.
  2. A library user using every existing constructor or compression-only factory receives the same byte-identical non-interlaced PNG output as before.
  3. A library user receives a deterministic typed rejection before output when requesting the Adam7 route for an unsupported image capability.
**Plans**: TBD

### Phase 42: Bounded Adam7 Pass Encoding
**Goal**: Opted-in images are encoded as deterministic, bounded Adam7 passes while preserving atomic admission and acknowledgement-safe caller-buffered replay.
**Depends on**: Phase 41
**Requirements**: PNGI-02, PNGI-03
**Success Criteria** (what must be TRUE):
  1. An opted-in compatible image produces seven deterministic Adam7 passes whose geometry, scanline bytes, selected filters, and compression input stay within the declared limits without image-sized staging.
  2. An eager or caller-buffered Adam7 encoder rejects incompatible geometry, output, work, or budget requests before exposing encoded bytes or accepting a caller lease.
  3. A caller can drain Adam7 output through arbitrary capacities with exact progress; replay advances only for accepted bytes and yields the same bytes as eager output.
**Plans**: TBD

### Phase 43: Portable Adam7 Public Evidence
**Goal**: Users have independent public proof that Adam7 encoding faithfully round-trips RGB8 and straight-RGBA8 images across every supported portable target.
**Depends on**: Phase 42
**Requirements**: PNGI-04
**Success Criteria** (what must be TRUE):
  1. Generated RGB8 and straight-RGBA8 Adam7 cases encode through the public API and decode back to exactly the source pixels.
  2. Hostile caller-buffer capacities produce byte-identical Adam7 output to eager encoding, while the frozen legacy non-interlaced cases retain their baseline bytes.
  3. The public Adam7 compatibility and fidelity cases execute independently on js, wasm, wasm-gc, and native.
**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 41. Adam7 Opt-In Compatibility | 0/TBD | Not started | - |
| 42. Bounded Adam7 Pass Encoding | 0/TBD | Not started | - |
| 43. Portable Adam7 Public Evidence | 0/TBD | Not started | - |

## Next

Plan Phase 41: Adam7 Opt-In Compatibility.
