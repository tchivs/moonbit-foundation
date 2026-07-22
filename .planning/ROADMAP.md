# Roadmap: MoonBit Native Foundation

## Milestones

- ✅ **v0.1 Foundation** — Phases 1-5, 41 plans, 36/36 requirements (shipped 2026-07-17). [Full history](./milestones/v0.1-ROADMAP.md).
- ⏸️ **v0.2 Publication & Compatibility** — Phases 6-8; registry publication remains deliberately deferred without a registry mutation.
- ✅ **v0.3 Image Processing Core** — Phases 9-12, 9 requirements (shipped 2026-07-20). [Full history](./milestones/v0.3-ROADMAP.md).
- ✅ **v0.4 Portable Image Interchange** — Phases 13-16, pure-MoonBit QOI 1.0 across four targets (shipped 2026-07-20). [Full history](./milestones/v0.4-ROADMAP.md).
- ✅ **v0.5 QOI Streaming I/O** — Phases 17-19, resumable caller-buffered QOI streams across four targets (shipped 2026-07-20). [Full history](./milestones/v0.5-ROADMAP.md).
- ✅ **v0.6 PNG Interchange** — Phases 20-22, strict bounded RGB/RGBA PNG interchange and pure-MoonBit DEFLATE (shipped 2026-07-21).
- ✅ **v0.7 PNG Colour Fidelity** — Phases 23-25, strict PNG colour declarations without silent non-sRGB loss (shipped 2026-07-21).
- ✅ **v0.8 Resumable PNG Decode** — Phases 26-28, portable caller-buffered decode with strict completion and four-target evidence (shipped 2026-07-21). [Full history](./milestones/v0.8-ROADMAP.md).
- ✅ **v0.9 Resumable PNG Encode** — Phases 29-31, portable caller-buffered canonical PNG output with eager parity and four-target evidence (shipped 2026-07-21). [Full history](./milestones/v0.9-ROADMAP.md).
- ✅ **v0.10 PNG Compression Optimization** — Phases 32-34, opt-in fixed-Huffman-or-stored PNG compression with stored-DEFLATE defaults preserved, bounded admission, and four-target corpus evidence (shipped 2026-07-22). [Full history](./milestones/v0.10-ROADMAP.md).
- ✅ **v0.11 PNG Dynamic Huffman Compression** — Phases 35-37, bounded opt-in Dynamic DEFLATE with frozen Stored/FixedOrStored baselines, strict complete-PNG selection, acknowledgement-safe replay, and four-target evidence (shipped 2026-07-22). [Full history](./milestones/v0.11-ROADMAP.md).
- 📋 **v0.12 PNG Filter Optimization** — Phases 38-40, opt-in adaptive PNG row filtering with legacy filter-None compatibility, bounded planner integration, and four-target evidence.

## Phases

Adaptive filtering is delivered as an additive route: first freeze the public compatibility boundary, then apply bounded row-filter selection to the existing atomic encoding path, then prove the resulting behavior through generated four-target evidence.

- [x] **Phase 38: Adaptive Filter Compatibility** - Publish the explicit opt-in strategy/factory seam while preserving every legacy filter-None byte route. (completed 2026-07-22)
- [x] **Phase 39: Bounded Filter Planning and Replay** - Select stable standard row filters before Stored, FixedOrStored, and Dynamic planning without weakening atomic resource semantics. (completed 2026-07-22)
- [ ] **Phase 40: Portable Adaptive-Filter Evidence** - Prove intended wins, eager/chunk identity, and public decode fidelity for generated RGB8 and RGBA8 sources on all targets.

## Phase Details

### Phase 38: Adaptive Filter Compatibility

**Goal**: Library users can explicitly select adaptive PNG row filtering without changing the bytes produced by existing filter-None constructors or compression routes.
**Depends on**: Phase 37
**Requirements**: PNGF-01
**Success Criteria** (what must be TRUE):

  1. A user can opt into adaptive row filtering through documented eager and caller-buffered encoder factories.
  2. A user who continues to use each legacy constructor or existing compression strategy receives its frozen filter-None PNG bytes unchanged.

**Plans**: TBD

### Phase 39: Bounded Filter Planning and Replay

**Goal**: Opted-in compatible images use deterministic, bounded standard PNG row filtering before the existing compression planners while retaining atomic eager and caller-buffered behavior.
**Depends on**: Phase 38
**Requirements**: PNGF-02, PNGF-03
**Success Criteria** (what must be TRUE):

  1. A user encoding a compatible RGB8 or straight-RGBA8 image with adaptive filtering receives rows selected deterministically from None, Sub, Up, Average, and Paeth using one documented stable winner rule.
  2. A user can combine adaptive filtering with Stored, FixedOrStored, or Dynamic compression and receive output from the corresponding existing compression-selection route.
  3. A user whose source capability, geometry, output/work limit, or budget is rejected observes the same atomic failure before eager output or a caller-buffered lease is exposed.

**Plans**: TBD

### Phase 40: Portable Adaptive-Filter Evidence

**Goal**: Library users have reproducible evidence that the opt-in adaptive route improves intended cases and preserves portable eager/caller-buffered interoperability.
**Depends on**: Phase 39
**Requirements**: PNGF-04
**Success Criteria** (what must be TRUE):

  1. Generated RGB8 and straight-RGBA8 cases demonstrate an intended strict output-size win for the adaptive-filter route.
  2. Under hostile caller-buffer capacities, a user receives byte-identical eager and chunked adaptive-filter PNG output.
  3. The public PNG decoder completely recovers each generated source on js, wasm, wasm-gc, and native.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 38. Adaptive Filter Compatibility | 1/1 | Complete    | 2026-07-22 |
| 39. Bounded Filter Planning and Replay | 7/7 | Complete    | 2026-07-22 |
| 40. Portable Adaptive-Filter Evidence | 0/TBD | Not started | - |
