# Roadmap: MoonBit Native Foundation

## Milestones

- ✅ **v0.1 Foundation** — Phases 1-5 (shipped 2026-07-17). [Full history](./milestones/v0.1-ROADMAP.md)
- ⏸️ **v0.2 Publication & Compatibility** — Phases 6-8, deliberately deferred without a registry mutation.
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
- ✅ **v0.19 GrayAlpha8 Adam7 PNG** — Phases 59-61 (shipped 2026-07-23). [Full history](./milestones/v0.19-ROADMAP.md)
- ✅ **v0.20 High-Precision GrayAlpha Decode** — Phases 62-64 (shipped 2026-07-23). [Full history](./milestones/v0.20-ROADMAP.md)
- ✅ **v0.21 RGBA16 PNG Decode** — Phases 65-68 (shipped 2026-07-23). [Full history](./milestones/v0.21-ROADMAP.md)
- ✅ **v0.22 RGBA16 PNG Encode** — Phases 69-72 (shipped 2026-07-23). [Full history](./milestones/v0.22-ROADMAP.md)
- ✅ **v0.23 Low-Bit Grayscale PNG Encode** — Phases 73-75 (shipped 2026-07-24). [Full history](./milestones/v0.23-ROADMAP.md)
- ✅ **v0.24 Indexed PNG Encode** — Phases 76-78 (shipped 2026-07-24). [Full history](./milestones/v0.24-ROADMAP.md)
- ✅ **v0.25 Indexed Low-Bit PNG Encode** — Phases 79-80 (shipped 2026-07-24). [Full history](./milestones/v0.25-ROADMAP.md)
- ✅ **v0.26 Indexed8 Adam7 PNG Encode** — Phases 81-82 (shipped 2026-07-24). [Full history](./milestones/v0.26-ROADMAP.md)
- ✅ **v0.27 Low-Bit Indexed Adam7 PNG Encode** — Phases 83-84 (shipped 2026-07-24). [Full history](./milestones/v0.27-ROADMAP.md)
- ✅ **v0.28 Indexed PNG Compression Profiles** — Phases 85-87 (shipped 2026-07-24). [Full history](./milestones/v0.28-ROADMAP.md)
- 📋 **v0.29 Indexed Adam7 Compression Profiles** — Phases 88-90 (planned).

## Phases

### 📋 v0.29 Indexed Adam7 Compression Profiles

- [x] **Phase 88: Indexed Adam7 API and Fixed Wire Contract** - Add additive Adam7 Stored/Fixed-or-Stored selectors and the bounded pass-aware Fixed candidate contract for Indexed1/2/4/8. (completed 2026-07-24)
- [ ] **Phase 89: Pass-Aware Preflight and Shared-Machine Integration** - Admit the exact palette-aware Adam7 candidate atomically through the established acknowledged machine.
- [ ] **Phase 90: Hostile Streaming and Independent Qualification** - Prove hostile lease behavior, independent wire/decode evidence, frozen compatibility, and four-target portability.

## Phase Details

### Phase 88: Indexed Adam7 API and Fixed Wire Contract

**Goal:** Library users have additive Adam7 compression selectors for Indexed1/2/4/8, with explicit Stored and Fixed-or-Stored choices that leave every existing indexed compatibility route unchanged.

**Depends on:** Phase 87 (shipped)

**Requirements:** ADAM7COMP-01

**Scope guard:** Add only additive eager and caller-buffered Adam7 compression selectors and their explicit Stored/Fixed-or-Stored profile spelling. Existing/default interlace APIs remain literal Stored/filter-None forwards, and v0.28 non-interlaced selectors remain byte-frozen. Do not add Dynamic indexed DEFLATE, adaptive indexed filtering, wider matching or a 32 KiB dictionary, image/pass/output staging, a second encoder, generic model or decoder changes, FFI, target wrappers, registry publication, or release automation.

**Success criteria:**

1. Users can select `Stored` or `FixedOrStored` through additive eager and caller-buffered Adam7 APIs for Indexed1/2/4/8, while existing interlace APIs and all v0.28 non-interlaced selectors produce their frozen bytes.
2. The selected Adam7 profile is carried consistently by eager and caller-buffered constructors without widening the indexed source model or introducing a decoder/FFI dependency; unsupported future profiles remain outside this API.

**Plans:** 1/1 plans complete

### Phase 89: Pass-Aware Preflight and Shared-Machine Integration

**Goal:** Every selected Adam7 indexed compression request derives exact pass-aware Fixed-or-Stored facts, is admitted atomically, and is rendered by the established acknowledged eager and caller-buffered machine with one exact candidate charge.

**Depends on:** Phase 88

**Requirements:** ADAM7COMP-02, ADAM7COMP-03

**Scope guard:** Integrate only the Phase 88 Indexed1/2/4/8 Adam7 profiles. Reuse one bounded pass-aware filter-None packed-row/match producer and the existing Fixed emitter; `PngFrameFacts` remains the owner of PLTE/tRNS/IDAT/IEND offsets and the existing acknowledgement lifecycle remains the sole output path. Do not introduce Dynamic indexed DEFLATE, adaptive indexed filtering, wider matching or a 32 KiB dictionary, another stream encoder, source-model change, staging, FFI, target wrapper, copied tree, registry work, or release automation.

**Success criteria:**

1. The bounded producer emits each canonical filter-None packed row from its pass-local column zero with deterministic tail bits, and the same source supplies Stored accounting, Fixed matching, and acknowledgement-safe replay without image/pass/output staging or a second encoder.
2. Before any writer byte, caller lease exposure, or budget mutation, the constructor computes actual PLTE, shortest canonical tRNS, exact Stored/Fixed frame and work facts, and chooses Fixed only when the complete Type-3 frame is no larger than Stored.
3. Exact selected limits admit one budget charge and both eager and caller-buffered APIs emit the selected plan through the established `present → accept → acknowledge` machine; one-less or overflowing output/work limits fail with output, lease, and budget state untouched.

**Plans:** TBD

### Phase 90: Hostile Streaming and Independent Qualification

**Goal:** Adam7 Fixed winners and Stored fallbacks are trustworthy under hostile caller leases, independently parseable and decodable, compatibility-safe, and portable across every supported target.

**Depends on:** Phase 89

**Requirements:** ADAM7COMP-04, ADAM7COMP-05

**Scope guard:** Qualify only the Phase 89 admitted machine and selectors. Do not redesign encoder architecture, add compression/filter/interlace profiles, widen the source model, add staging, FFI, target wrappers, copied trees, decoder changes, registry publication, or release automation.

**Success criteria:**

1. Fixed winners and Stored fallbacks reproduce fresh eager bytes under zero-capacity, one-byte, and ragged leases, count only accepted bytes, and leave every rejected sentinel tail untouched.
2. Released leases and replay-work drift produce sticky zero-write terminal failures; pulls after finish return sticky zero-write `Finished` outcomes and never alter the destination.
3. Independent test-local parsing of eager and collected chunk-origin bytes proves seven-pass framing, Fixed/Stored DEFLATE choice, PLTE/tRNS canonicalisation, packed-row tail bits, Adler/CRC values, and public RGB8/RGBA8 decode without calling production planning, matching, packing, or frame helpers.
4. Existing non-interlaced v0.28 Indexed1/2/4/8 vectors and all prior Adam7 Stored/filter-None vectors remain byte-identical.
5. The ordinary PNG package gate passes on native, wasm, wasm-gc, and js (including the aggregate `--target all` lane).

**Plans:** TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 88. Indexed Adam7 API and Fixed Wire Contract | 1/1 | Complete    | 2026-07-24 |
| 89. Pass-Aware Preflight and Shared-Machine Integration | 0/0 | Not started | - |
| 90. Hostile Streaming and Independent Qualification | 0/0 | Not started | - |

---
*Roadmap last updated: 2026-07-24 after v0.29 roadmap definition.*
