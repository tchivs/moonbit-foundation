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
- 📋 **v0.11 PNG Dynamic Huffman Compression** — Phases 35-37, a bounded opt-in dynamic route that is selected only for a strict complete-PNG size win over unchanged FixedOrStored output.

## Phases

### v0.11 PNG Dynamic Huffman Compression (Phases 35-37)

**Milestone goal:** Library users can explicitly opt into bounded dynamic-Huffman PNG compression that never changes existing Stored or FixedOrStored bytes and selects Dynamic only for a strict complete-PNG size win.

**Scope boundary:** Retain filter-None scanlines and the distance-1-through-4 matcher. Do not add adaptive filtering, a 32 KiB dictionary, broader matching, image-sized staging, length-limited/package-merge optimization, FFI, host adapters, external packages, CI/release/registry work, APNG, colour work, or metadata expansion. Preserve one-IDAT framing, zlib, CRC, Adler-32, eager/caller-lease lifecycles, exact progress, and sticky terminals.

- [x] **Phase 35: Dynamic Strategy Compatibility** - Users can choose the explicit dynamic route while Stored and FixedOrStored stay frozen compatibility baselines. (completed 2026-07-22)
- [x] **Phase 36: Bounded Dynamic Planning and Replay** - Dynamic output is an exact, bounded, acknowledgement-safe strict winner or falls back to the existing FixedOrStored bytes. (completed 2026-07-22)
- [ ] **Phase 37: Four-Target Dynamic Compression Evidence** - A generated corpus proves deterministic dynamic wins and complete decoded fidelity across all supported targets.

## Phase Details

### Phase 35: Dynamic Strategy Compatibility

**Goal**: Library users can explicitly select a documented dynamic compression route without changing the frozen Stored defaults or established FixedOrStored byte sequences.
**Depends on**: Phase 34
**Requirements**: PNGD-01
**Success Criteria** (what must be TRUE):

  1. A library user can select `DynamicOrFixedOrStored` through additive eager and caller-buffered factories.
  2. A library user continuing to use legacy constructors receives the same frozen Stored PNG bytes for compatible RGB8 and straight-RGBA8 sources.
  3. A library user selecting `FixedOrStored` receives the same frozen byte sequence as before; only the new strategy may ever choose a dynamic block.
  4. Public strategy documentation states the strict-win policy and excludes adaptive filters, broader matching, and host-streaming expansion.

**Plans**: TBD

### Phase 36: Bounded Dynamic Planning and Replay

**Goal**: A dynamic-strategy user receives a deterministic, bounded Dynamic PNG only when it is strictly smaller than the unchanged FixedOrStored winner, with exact preflight and acknowledgement-safe eager/chunk replay.
**Depends on**: Phase 35
**Requirements**: PNGD-02, PNGD-03
**Success Criteria** (what must be TRUE):

  1. An admitted compatible image receives either a legal single Dynamic DEFLATE block or the byte-identical existing FixedOrStored winner, with Dynamic selected only when the complete PNG is strictly smaller.
  2. A dynamic candidate whose ordinary canonical construction cannot stay within DEFLATE's 15-bit bound falls back to FixedOrStored without a length-limited optimizer or image-sized staging.
  3. Capability, geometry, output, work, and budget rejection occurs before an eager writer or caller lease observes any byte; the selected exact plan is charged once.
  4. A library user can drain dynamic eager and caller-buffered output under arbitrary valid capacities with exact progress, byte-identical results, acknowledgement-only state commits, and sticky completion/failure behavior.

**Plans**: TBD

### Phase 37: Four-Target Dynamic Compression Evidence

**Goal**: Maintainers can reproduce portable evidence that the explicit dynamic route is deterministic, strictly wins where intended, and decodes faithfully through the public PNG API.
**Depends on**: Phase 36
**Requirements**: PNGD-04
**Success Criteria** (what must be TRUE):

  1. A generated periodic five-symbol RGB8 and straight-RGBA8 corpus is available in memory and is sufficiently literal-heavy for the existing distance-1-through-4 matcher to exercise a dynamic win.
  2. On js, wasm, wasm-gc, and native, DynamicOrFixedOrStored produces a `BTYPE=10` result strictly smaller than unchanged FixedOrStored for each declared corpus case.
  3. Repeated eager encodes and hostile-schedule caller-buffered encodes produce identical Dynamic bytes for each corpus case.
  4. Every generated eager and chunk result completes public PNG decoding with dimensions, channel count, and every source component preserved.

**Plans**: TBD

## Requirement Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PNGD-01 | Phase 35 | Pending |
| PNGD-02 | Phase 36 | Pending |
| PNGD-03 | Phase 36 | Pending |
| PNGD-04 | Phase 37 | Pending |

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 35. Dynamic Strategy Compatibility | 1/1 | Complete    | 2026-07-22 |
| 36. Bounded Dynamic Planning and Replay | 2/2 | Complete    | 2026-07-22 |
| 37. Four-Target Dynamic Compression Evidence | 0/TBD | Not started | - |

---
*Roadmap updated: 2026-07-22 for v0.11 PNG Dynamic Huffman Compression planning.*
