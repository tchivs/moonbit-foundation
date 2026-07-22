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
- ✅ **v0.13 PNG Adam7 Encode** — Phases 41-43, explicit bounded Adam7 encoding with frozen legacy output and four-target public evidence (shipped 2026-07-22). [Full history](./milestones/v0.13-ROADMAP.md)
- 📋 **v0.14 Gray8 PNG Interchange** — Phases 44-46, explicit non-interlaced Gray8 output through the bounded PNG encoder and portable public evidence.

## v0.14 Gray8 PNG Interchange

**Milestone Goal:** Library users can explicitly encode existing 8-bit `ChannelOrder::Gray` images as standards-compliant non-interlaced Gray8 PNGs through eager and caller-buffered APIs, without changing RGB8/RGBA8 output or encoder safety semantics.

## Phases

- [x] **Phase 44: Gray8 Factory Compatibility** - Add the explicit non-interlaced Gray8 eager and caller-buffered selection boundary while preserving RGB8/RGBA8 behavior. (completed 2026-07-22)
- [ ] **Phase 45: Bounded Gray8 Encoder Path** - Route Gray8 through the shared bounded preflight, filtering, compression, and acknowledgement-safe replay pipeline.
- [ ] **Phase 46: Portable Gray8 Public Evidence** - Prove Gray8 public fidelity, hostile-capacity eager/chunk identity, RGB/RGBA compatibility, and independent four-target execution.

## Phase Details

### Phase 44: Gray8 Factory Compatibility

**Goal**: Users can explicitly request standards-compliant, 8-bit, non-interlaced Gray8 PNG output for existing `ChannelOrder::Gray` images through eager and caller-buffered PNG factories without changing RGB8/RGBA8 results.
**Depends on**: Phase 43
**Requirements**: GRAYPNG-01
**Success Criteria** (what must be TRUE):

  1. A library user can encode an existing 8-bit `ChannelOrder::Gray` image through explicit eager and caller-buffered PNG factory routes and receive a non-interlaced Gray8 PNG.
  2. A library user using any existing RGB8 or straight-RGBA8 PNG factory receives the same output bytes and behavior as before the Gray8 addition.
  3. The public Gray8 route has a clear deterministic boundary: it does not silently select palette output, low-bit packing, 16-bit samples, transparency conversion, or Adam7 interlacing.

**Plans**: TBD

### Phase 45: Bounded Gray8 Encoder Path

**Goal**: Gray8 eager and caller-buffered output uses the established bounded PNG pipeline before any byte or caller lease is exposed.
**Depends on**: Phase 44
**Requirements**: GRAYPNG-02
**Success Criteria** (what must be TRUE):

  1. A valid Gray8 image can be encoded through the established filter and Stored, FixedOrStored, or DynamicOrFixedOrStored compression selections without an image-sized staging buffer.
  2. A Gray8 eager writer observes no bytes, and a caller-buffered user receives no encoder lease, when capability, geometry, output, work, or budget admission fails.
  3. A caller-buffered Gray8 encoder reports exact accepted progress through arbitrary supplied capacity and advances replay only for accepted output bytes.

**Plans**: TBD

### Phase 46: Portable Gray8 Public Evidence

**Goal**: Users have independent public proof that Gray8 PNG output is faithful, caller-buffered-safe, compatible with RGB/RGBA output, and portable across every supported target.
**Depends on**: Phase 45
**Requirements**: GRAYPNG-03
**Success Criteria** (what must be TRUE):

  1. Generated Gray8 images encoded through the public eager API decode with pixel values that faithfully reproduce their source gray samples.
  2. Zero, one-byte, and ragged caller capacities produce Gray8 output byte-identical to equivalent eager output, while frozen RGB8 and straight-RGBA8 cases retain their compatibility bytes.
  3. The public Gray8 fidelity and compatibility cases run independently on js, wasm, wasm-gc, and native.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 44. Gray8 Factory Compatibility | 1/1 | Complete    | 2026-07-22 |
| 45. Bounded Gray8 Encoder Path | 0/TBD | Not started | - |
| 46. Portable Gray8 Public Evidence | 0/TBD | Not started | - |

## Next

Plan Phase 44: Gray8 Factory Compatibility.
