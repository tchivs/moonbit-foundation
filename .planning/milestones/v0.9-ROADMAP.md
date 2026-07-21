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
- 🟡 **v0.9 Resumable PNG Encode** — Phases 29-31, portable caller-buffered canonical PNG output with eager parity and four-target evidence (planned).

## Phases

<details>
<summary>✅ v0.8 Resumable PNG Decode (Phases 26-28) — SHIPPED 2026-07-21</summary>

- [x] Phase 26: Pausable PNG Decode Substrate (1/1 plan) — completed 2026-07-21
- [x] Phase 27: Public PNG Chunk Decoder (3/3 plans) — completed 2026-07-21
- [x] Phase 28: Portable PNG Streaming Evidence (1/1 plan) — completed 2026-07-21

</details>

### v0.9 Resumable PNG Encode (Phases 29-31)

- [x] **Phase 29: Pausable PNG Encode Substrate** - Compatible images can be admitted or rejected before output while a private MoonBit state machine prepares canonical PNG emission. (completed 2026-07-21)
- [x] **Phase 30: Public PNG Chunk Encoder** - Library users can drain one canonical eager-equivalent PNG through arbitrary caller-owned output buffers. (completed 2026-07-21)
- [x] **Phase 31: Portable PNG Encode Evidence** - Four-target hostile-schedule proof and a public decode-process-encode workflow validate the complete contract. (completed 2026-07-21)

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

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 29. Pausable PNG Encode Substrate | 3/3 | Complete    | 2026-07-21 |
| 30. Public PNG Chunk Encoder | 1/1 | Complete    | 2026-07-21 |
| 31. Portable PNG Encode Evidence | 1/1 | Complete    | 2026-07-21 |

---
*Roadmap updated: 2026-07-21 for v0.9 resumable PNG encode planning.*
