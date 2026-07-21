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
- 📋 **v0.10 PNG Compression Optimization** — Phases 32-34, opt-in fixed-Huffman-or-stored PNG compression with stored-DEFLATE defaults preserved, bounded admission, and four-target corpus evidence (planned).

## Phases

<details>
<summary>✅ v0.8 Resumable PNG Decode (Phases 26-28) — SHIPPED 2026-07-21</summary>

- [x] Phase 26: Pausable PNG Decode Substrate (1/1 plan) — completed 2026-07-21
- [x] Phase 27: Public PNG Chunk Decoder (3/3 plans) — completed 2026-07-21
- [x] Phase 28: Portable PNG Streaming Evidence (1/1 plan) — completed 2026-07-21

</details>

<details>
<summary>✅ v0.9 Resumable PNG Encode (Phases 29-31) — SHIPPED 2026-07-21</summary>

- [x] **Phase 29: Pausable PNG Encode Substrate** - Compatible images can be admitted or rejected before output while a private MoonBit state machine prepares canonical PNG emission. (completed 2026-07-21)
- [x] **Phase 30: Public PNG Chunk Encoder** - Library users can drain one canonical eager-equivalent PNG through arbitrary caller-owned output buffers. (completed 2026-07-21)
- [x] **Phase 31: Portable PNG Encode Evidence** - Four-target hostile-schedule proof and a public decode-process-encode workflow validate the complete contract. (completed 2026-07-21)

</details>

### v0.10 PNG Compression Optimization (Phases 32-34)

**Milestone goal:** Library users can explicitly opt into deterministic, resource-bounded fixed-Huffman-or-stored PNG compression without silently changing the established stored-DEFLATE eager or caller-buffered output.

**Scope boundary:** Existing stored-DEFLATE constructors remain the default and byte-stable baseline. Dynamic Huffman, adaptive filters, a 32 KiB LZ77 dictionary, FFI codecs, host stream adapters, registry/release work, APNG, colour-transform work, and metadata expansion remain outside this milestone.

- [ ] **Phase 32: PNG Compression Strategy and Compatibility** - Users can select a documented additive compression strategy while legacy eager and chunk constructors retain their exact stored-DEFLATE bytes.
- [ ] **Phase 33: Fixed-or-Stored PNG Planning and Emission** - Optimized users receive deterministic, preflighted fixed-Huffman-or-stored eager and caller-buffered output with exact progress and sticky terminals.
- [ ] **Phase 34: Portable PNG Compression Corpus Evidence** - A reproducible four-target corpus proves valid, deterministic, never-larger optimized output and declared flat-image wins.

## Phase Details

### Phase 29: Pausable PNG Encode Substrate

**Goal**: Compatible RGB8 and straight-RGBA8 images can enter a private resumable MoonBit encoding state only after eager-equivalent capability, dimension, limit, and budget preflight succeeds.
**Depends on**: Phase 28
**Requirements**: PNGE-01
**Success Criteria** (what must be TRUE):

  1. A library user can begin chunked encoding for a compatible RGB8 or straight-RGBA8 image only after all eager-equivalent capability, dimension, limit, and budget checks have passed.
  2. A library user receives the existing typed rejection for an incompatible image or exhausted limit/budget before any PNG byte is exposed.

**Plans**: 3/3 plans executed

- [x] 29-01-PLAN.md
- [x] 29-02-PLAN.md
- [x] 29-03-PLAN.md

### Phase 30: Public PNG Chunk Encoder

**Goal**: Library users can emit exactly one canonical PNG through arbitrary caller-owned mutable output buffers with exact progress and sticky terminals.
**Depends on**: Phase 29
**Requirements**: PNGE-02, PNGE-03
**Success Criteria** (what must be TRUE):

  1. A library user can repeatedly supply empty, tiny, or irregular mutable output buffers and observe deterministic exact progress until canonical PNG output is complete.
  2. The concatenated bytes emitted through every valid output schedule exactly match the eager PNG encoder's canonical output, with no duplicated or omitted byte.
  3. After successful completion or a typed terminal failure, later calls expose no additional bytes and report the same sticky terminal outcome.

**Plans**: TBD

### Phase 31: Portable PNG Encode Evidence

**Goal**: Maintainers and library users can verify the public resumable PNG encode contract across all portable targets in hostile and end-to-end workflows.
**Depends on**: Phase 30
**Requirements**: PNGE-04, PNGE-05
**Success Criteria** (what must be TRUE):

  1. Maintainers can run a deterministic quality lane on js, wasm, wasm-gc, and native that verifies hostile output capacities, eager/chunk byte parity, preflight limits and budgets, and sticky terminal behavior.
  2. A library user can run one public chunk-decode to image-operation to chunk-encode workflow on every supported target and receive the same deterministic output evidence.

**Plans**: TBD

### Phase 32: PNG Compression Strategy and Compatibility

**Goal**: Library users can explicitly choose a documented PNG compression strategy without changing the byte-for-byte stored-DEFLATE behavior of existing eager or caller-buffered constructors.
**Depends on**: Phase 31
**Requirements**: PNGC-01
**Success Criteria** (what must be TRUE):

  1. A library user can request the documented opt-in compression strategy through an additive public contract rather than a changed default.
  2. A library user who keeps using the existing eager or chunk encoder constructor receives the identical stored-DEFLATE PNG bytes as before for the same compatible image.
  3. A library user can distinguish the supported optimized strategy from the stored baseline without gaining dynamic Huffman, adaptive filtering, host streaming, or other excluded compression behavior.

**Plans**: TBD

### Phase 33: Fixed-or-Stored PNG Planning and Emission

**Goal**: A library user selecting the optimized strategy receives deterministic fixed-Huffman-or-stored PNG output only after bounded exact admission, through both eager and caller-buffered encoder paths.
**Depends on**: Phase 32
**Requirements**: PNGC-02, PNGC-03
**Success Criteria** (what must be TRUE):

  1. A library user requesting optimized output receives capability, geometry, output, work, and budget rejection before any byte is exposed when the source cannot be admitted.
  2. A library user with an admitted compatible image receives one deterministic PNG byte sequence produced by a bounded exact plan that selects fixed-Huffman or stored DEFLATE without dynamic-Huffman or adaptive-filter expansion.
  3. A library user can drain optimized eager and caller-buffered output under arbitrary valid output capacities, observe exact progress, obtain byte-identical eager/chunk results, and receive unchanged sticky completion or failure semantics.

**Plans**: TBD

### Phase 34: Portable PNG Compression Corpus Evidence

**Goal**: Maintainers can reproduce four-target evidence that the opt-in optimized strategy remains valid and deterministic while delivering measured compression wins for its intended repetitive-image cases.
**Depends on**: Phase 33
**Requirements**: PNGC-04
**Success Criteria** (what must be TRUE):

  1. Maintainers can run a declared deterministic PNG corpus on js, wasm, wasm-gc, and native and verify optimized eager and chunk outputs decode back to their source images with matching target-neutral evidence.
  2. The corpus reproducibly proves that FixedOrStored output is never larger than the stored-DEFLATE baseline and records a declared compression win for both flat RGB8 and flat RGBA8 images.

**Plans**: TBD

## Requirement Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PNGC-01 | Phase 32 | Pending |
| PNGC-02 | Phase 33 | Pending |
| PNGC-03 | Phase 33 | Pending |
| PNGC-04 | Phase 34 | Pending |

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 29. Pausable PNG Encode Substrate | 3/3 | Complete    | 2026-07-21 |
| 30. Public PNG Chunk Encoder | 1/1 | Complete    | 2026-07-21 |
| 31. Portable PNG Encode Evidence | 1/1 | Complete    | 2026-07-21 |
| 32. PNG Compression Strategy and Compatibility | 0/TBD | Not started | - |
| 33. Fixed-or-Stored PNG Planning and Emission | 0/TBD | Not started | - |
| 34. Portable PNG Compression Corpus Evidence | 0/TBD | Not started | - |

---
*Roadmap updated: 2026-07-22 for v0.10 PNG Compression Optimization planning.*
