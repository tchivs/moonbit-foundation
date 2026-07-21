# Roadmap: MoonBit Native Foundation

## Milestones

- ✅ **v0.1 Foundation** — Phases 1-5, 41 plans, 36/36 requirements (shipped 2026-07-17). Full history: [v0.1 roadmap](./milestones/v0.1-ROADMAP.md).
- ⏸️ **v0.2 Publication & Compatibility** — Phases 6-8 completed or partially prepared; registry publication and closure remain deferred without a registry mutation.
- ✅ **v0.3 Image Processing Core** — Phases 9-12, 9 requirements (shipped 2026-07-20). Full history: [v0.3 roadmap](./milestones/v0.3-ROADMAP.md).
- ✅ **v0.4 Portable Image Interchange** — Phases 13-16, 6 requirements complete (shipped 2026-07-20); pure-MoonBit QOI 1.0 interchange across four targets.
- ✅ **v0.5 QOI Streaming I/O** — Phases 17-19, 7 requirements complete (shipped 2026-07-20); resumable caller-buffered QOI streams across four targets.
- 📋 **v0.6 PNG Interchange** — Phases 20-22, 7 requirements planned; strict bounded RGB/RGBA PNG interchange with pure-MoonBit DEFLATE and four-target evidence.
- 📋 **v0.7 PNG Colour Fidelity** — Phases 23-25, 5 requirements planned; strict PNG colour declarations without silent non-sRGB loss.

## Phases

<details>
<summary>✅ v0.1 Foundation (Phases 1-5) — SHIPPED 2026-07-17</summary>

- [x] Phase 1: Foundation Charter and Reproducible Workspace (8/8 plans) — completed 2026-07-16
- [x] Phase 2: Bounded Core Primitives (8/8 plans) — completed 2026-07-17
- [x] Phase 3: Reference Color Semantics (8/8 plans) — completed 2026-07-17
- [x] Phase 4: Image Model, Views, and Operations (9/9 plans) — completed 2026-07-17
- [x] Phase 5: Reference Codec and Release Qualification (8/8 plans) — completed 2026-07-17

</details>

<details>
<summary>⏸️ v0.2 Publication & Compatibility (Phases 6-8) — DEFERRED 2026-07-20</summary>

- [x] Phase 6: Namespace Authority and Compatibility Contract (25/25 plans) — completed 2026-07-18
- [x] Phase 7: Release Safety, Intent, and Recovery Automation (3/3 plans) — completed 2026-07-18
- [ ] Phase 8: Ordered Mooncakes Publication and Registry Consumers (34/36 plans) — deferred; no registry mutation performed

Publication, registry-consumer proof, provenance closure, and any release automation are deferred outside v0.3.

</details>

### ✅ v0.3 Image Processing Core (Shipped 2026-07-20)

**Milestone goal:** Expand `mb-image` from safe image storage and a reference codec into a practical, portable raster-processing foundation.

- [x] **Phase 9: Checked Image Geometry and Diagnostics** - Users can safely transform image extent and orientation with deterministic failure behavior. (completed 2026-07-20)
- [x] **Phase 10: Alpha-Correct Pixel Processing** - Users can composite and filter RGBA images with documented deterministic semantics. (completed 2026-07-20)
- [x] **Phase 11: Portable Processing Pipeline Evidence** - Users can run and maintain a verified, reproducible end-to-end image-processing workflow. (completed 2026-07-20)
- [x] **Phase 12: Strict PPM End-to-End Filter Coverage** - The public strict-P6 route proves geometry and alpha-aware filters before encoding. (completed 2026-07-20)

### ✅ v0.4 Portable Image Interchange (Shipped 2026-07-20)

**Milestone goal:** Add strict, bounded QOI 1.0 interchange to the existing portable image contracts without foreign codec dependencies.

- [x] **Phase 13: QOI Format Core and Safe Decode** - Users can identify and decode valid QOI images while hostile input fails deterministically before unsafe work. (completed 2026-07-20)
- [x] **Phase 14: Canonical QOI Encode and Four-Target Vectors** - Users can create lossless canonical QOI output proven by specification-derived vectors on every supported target. (completed 2026-07-20)
- [x] **Phase 15: Public QOI Processing Example** - Users can run a documented portable QOI decode-process-encode workflow with deterministic evidence. (completed 2026-07-20)
- [x] **Phase 16: QOI Policy and Public Example Quality Alignment** - The shipped QOI package and portable consumer have isolated, fail-closed quality evidence. (completed 2026-07-20)

### ✅ v0.5 QOI Streaming I/O (Shipped 2026-07-20)

**Milestone goal:** Add bounded, resumable QOI decode and encode APIs over caller-owned chunks and output buffers without changing the existing forward-only I/O contracts.

- [x] **Phase 17: Resumable QOI Chunk Decode** - Users can decode caller-owned QOI byte chunks safely and explicitly complete or reject a stream. (completed 2026-07-20)
- [x] **Phase 18: Resumable QOI Buffer Encode** - Users can pull canonical QOI bytes into caller-owned output buffers without losing stream progress or eager preflight guarantees. (completed 2026-07-20)
- [x] **Phase 19: Portable Streaming QOI Evidence** - Users and maintainers can run one public streaming processing workflow and verify hostile schedules on all portable targets. (completed 2026-07-20)

### 📋 v0.6 PNG Interchange (Planned)

**Milestone goal:** Add strict, bounded PNG RGB/RGBA interchange to the existing portable image contracts with pure-MoonBit DEFLATE and four-target evidence.

- [x] **Phase 20: PNG Structural Safety Gate** - Users can probe and validate PNG structure deterministically before image output is exposed. (completed 2026-07-21)
- [x] **Phase 21: Bounded PNG Decode and DEFLATE** - Users can decode the supported PNG subset across arbitrary IDAT boundaries while malformed or over-budget input fails deterministically. (completed 2026-07-21)
- [x] **Phase 22: Canonical PNG Encode and Portable Evidence** - Users can emit canonical PNG output and verify one public decode-process-encode workflow on every portable target. (completed 2026-07-21)

### 📋 v0.7 PNG Colour Fidelity (Planned)

**Milestone goal:** Preserve strict PNG colour declarations or reject unavailable transformations explicitly, without silently relabelling source samples as sRGB.

- [x] **Phase 23: PNG Colour Declaration and sRGB Semantics** - Users can receive strict validated PNG colour declarations, with sRGB mapped truthfully to the existing image model. (completed 2026-07-21)
- [x] **Phase 24: Bounded Non-sRGB and ICC Preservation** - Users can retain legal legacy and ICC declarations without implicit colour transforms. (completed 2026-07-21)
- [x] **Phase 25: Portable Colour Conformance Evidence** - Maintainers can independently verify colour-metadata behaviour across all portable targets. (completed 2026-07-21)

## Phase Details

### Phase 9: Checked Image Geometry and Diagnostics

**Goal**: Library users can safely crop, reorient, and resize images through composable portable APIs that report invalid work deterministically.
**Depends on**: Phase 5
**Requirements**: GEOM-01, GEOM-02, GEOM-03, RASTER-03
**Success Criteria** (what must be TRUE):

  1. A library user can crop an image to a valid rectangle and receives a typed deterministic error instead of out-of-bounds access or overflow-driven allocation for an invalid region or resource limit.
  2. A library user can flip an image horizontally or vertically and rotate it in right-angle increments while observing the expected pixel positions and dimensions.
  3. A library user can resize an image with a documented nearest-neighbor algorithm and receives identical output for the same input on every supported target.
  4. A library user receives typed, deterministic errors when an operation is requested for an unsupported pixel format or incompatible image dimensions.

**Plans**: 2/2 plans complete

Plans:
**Wave 1**

- [x] 09-01-PLAN.md — Implement checked owned crop and explicit right-angle rotations with public behavior tests.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 09-02-PLAN.md — Add adversarial geometry proof and document/retest the fixed nearest-neighbor baseline.

### Phase 10: Alpha-Correct Pixel Processing

**Goal**: Library users can compose and filter RGBA images with stable alpha and resource semantics.
**Depends on**: Phase 9
**Requirements**: RASTER-01, RASTER-02
**Success Criteria** (what must be TRUE):

  1. A library user can composite one RGBA image over another with documented source-over alpha behavior and predictable output pixels.
  2. A library user can apply grayscale to an RGBA image deterministically without changing its documented alpha semantics.
  3. A library user can apply a box blur with checked dimensions and bounded intermediate storage, receiving a deterministic result for the same input.

**Plans**: 2/2 plans complete

Plans:

- [x] 10-02-PLAN.md

**Wave 1**

- [x] 10-01-PLAN.md — Implement and prove alpha-correct source-over, grayscale, and box blur.

### Phase 11: Portable Processing Pipeline Evidence

**Goal**: Library users and maintainers can rely on a demonstrated, portable image-processing workflow and reproducible performance evidence.
**Depends on**: Phase 10
**Requirements**: INTEG-01, INTEG-02, INTEG-03
**Success Criteria** (what must be TRUE):

  1. A library user can run one public MoonBit example that combines geometry and raster operations and encodes the resulting image as PPM.
  2. Public behavioral and adversarial tests demonstrate the new API's expected results and failure behavior on `js`, `wasm`, `wasm-gc`, and `native`.
  3. A maintainer can reproduce a declared resize-and-compositing benchmark workload and compare it with its recorded baseline without running or depending on release automation.

**Plans**: 3/3 plans complete

Plans:
**Wave 1**

- [x] 11-01-PLAN.md — Extend the public portable PPM example into the resize-and-source-over processing pipeline.
- [x] 11-02-PLAN.md — Add four-target composed-pipeline behavioral and adversarial evidence.
- [x] 11-03-PLAN.md — Add isolated local native resize-and-composite benchmark evidence.

## Progress

**Execution order:** 9 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18 → 19 → 20 → 21 → 22

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation Charter and Reproducible Workspace | v0.1 | 8/8 | Complete | 2026-07-16 |
| 2. Bounded Core Primitives | v0.1 | 8/8 | Complete | 2026-07-17 |
| 3. Reference Color Semantics | v0.1 | 8/8 | Complete | 2026-07-17 |
| 4. Image Model, Views, and Operations | v0.1 | 9/9 | Complete | 2026-07-17 |
| 5. Reference Codec and Release Qualification | v0.1 | 8/8 | Complete | 2026-07-17 |
| 6. Namespace Authority and Compatibility Contract | v0.2 | 25/25 | Complete | 2026-07-18 |
| 7. Release Safety, Intent, and Recovery Automation | v0.2 | 3/3 | Complete | 2026-07-18 |
| 8. Ordered Mooncakes Publication and Registry Consumers | v0.2 | 34/36 | Deferred | 2026-07-20 |
| 9. Checked Image Geometry and Diagnostics | v0.3 | 1/1 | Complete    | 2026-07-20 |
| 10. Alpha-Correct Pixel Processing | v0.3 | 2/2 | Complete   | 2026-07-20 |
| 11. Portable Processing Pipeline Evidence | v0.3 | 3/3 | Complete   | 2026-07-20 |
| 12. Strict PPM End-to-End Filter Coverage | v0.3 | 1/1 | Complete   | 2026-07-20 |
| 13. QOI Format Core and Safe Decode | v0.4 | 1/1 | Complete    | 2026-07-20 |
| 14. Canonical QOI Encode and Four-Target Vectors | v0.4 | 1/1 | Complete    | 2026-07-20 |
| 15. Public QOI Processing Example | v0.4 | 1/1 | Complete    | 2026-07-20 |
| 16. QOI Policy and Public Example Quality Alignment | v0.4 | 1/1 | Complete | 2026-07-20 |
| 17. Resumable QOI Chunk Decode | v0.5 | 1/1 | Complete    | 2026-07-20 |
| 18. Resumable QOI Buffer Encode | v0.5 | 1/1 | Complete    | 2026-07-20 |
| 19. Portable Streaming QOI Evidence | v0.5 | 1/1 | Complete    | 2026-07-20 |
| 20. PNG Structural Safety Gate | v0.6 | 3/5 | Complete    | 2026-07-21 |
| 21. Bounded PNG Decode and DEFLATE | v0.6 | 2/3 | Complete    | 2026-07-21 |
| 22. Canonical PNG Encode and Portable Evidence | v0.6 | 1/1 | Complete    | 2026-07-21 |

### Phase 12: Strict PPM End-to-End Filter Coverage

**Goal:** Close the v0.3 audit's sole partial strict-PPM integration path with portable crop, rotation, grayscale, blur, and source-over evidence before encoding.
**Requirements**: INTEG-01, INTEG-02, RASTER-02, RASTER-03 (audit closure; no new requirement)
**Depends on:** Phase 11
**Plans:** 1/1 plans complete

Plans:

- [x] 12-01-PLAN.md — Prove the strict-PPM crop/rotate/filter/source-over route and atomic blur budget boundary on all targets.

### Phase 13: QOI Format Core and Safe Decode

**Goal**: Library users can safely identify and decode complete QOI 1.0 RGB and RGBA images through the portable codec contracts.
**Depends on**: Phase 12
**Requirements**: QOI-01, QOI-02, QOI-04
**Success Criteria** (what must be TRUE):

  1. A library user can probe caller-owned QOI prefixes without consuming a reader and receives deterministic `NoMatch` or minimum-length `NeedMore` results for incomplete or non-QOI prefixes.
  2. A library user can decode a valid complete QOI 1.0 RGB or RGBA image from a forward-only reader into an owned portable image with exact pixels, dimensions, channels, and straight-alpha semantics.
  3. A library user receives typed, deterministic failures for malformed headers/opcodes, truncated data, invalid end markers, trailing data, declared limits, and reader failures; a preflight rejection leaves output allocation and budget charges unchanged.

**Plans**: 1 plan

Plans:

- [x] 13-01-PLAN.md — Implement the independent bounded QOI decoder and prove generated vectors and hostile-input behavior across all portable targets.

### Phase 14: Canonical QOI Encode and Four-Target Vectors

**Goal**: Library users can losslessly create canonical QOI 1.0 bytes whose behavior is reproducibly conformant across every portable target.
**Depends on**: Phase 13
**Requirements**: QOI-03, QOI-05
**Success Criteria** (what must be TRUE):

  1. A library user can encode compatible RGB and straight-RGBA images through the public forward-only writer interface and decode the result to precisely the original pixels.
  2. The encoder emits one documented canonical QOI byte representation for a given compatible image and reports typed deterministic capability, limit, budget, or I/O failures.
  3. Maintainers can run specification-derived opcode, index, run, wraparound, and byte-round-trip vectors unchanged on `js`, `wasm`, `wasm-gc`, and `native`.

**Plans**: TBD

### Phase 15: Public QOI Processing Example

**Goal**: Library users can independently follow an end-to-end portable QOI workflow that demonstrates interoperability with the existing image operations.
**Depends on**: Phase 14
**Requirements**: QOI-06
**Success Criteria** (what must be TRUE):

  1. A library user can run one public documented example that decodes QOI, applies an existing image operation, encodes QOI, and produces deterministic output evidence.
  2. The example uses only the public portable image, codec, I/O, and budget contracts, so it runs without GUI state, FFI, or a platform-specific codec dependency.

**Plans**: TBD

### Phase 16: QOI policy and public example quality alignment

**Goal:** [To be planned]
**Requirements**: TBD
**Depends on:** Phase 15
**Plans:** 1/1 plans complete

Plans:

- [x] 16-01-PLAN.md — Add exact QOI package policy checks and the isolated four-target public-example quality lane.

### Phase 17: Resumable QOI Chunk Decode

**Goal**: Library users can feed a stateful QOI decoder caller-owned byte chunks, then explicitly obtain one complete owned image or a typed terminal result without changing `@io.Reader` EOF behavior.
**Depends on**: Phase 16
**Requirements**: QSTR-01, QSTR-02, QSTR-03
**Success Criteria** (what must be TRUE):

  1. A library user can submit arbitrary caller-owned `ByteView` chunks, including every QOI header and opcode boundary, and receives deterministic non-terminal input-needed progress until the complete image is available.
  2. A library user explicitly finishes a decode; valid completion yields exactly one owned RGB or RGBA image, while incomplete tokens, invalid or incomplete markers, trailing bytes, run overrun, and any use after a terminal result yield typed deterministic terminal errors.
  3. The streaming result has the same dimensions, pixels, descriptor semantics, consumed-byte accounting, limits, budget charging, diagnostics, and no-partial-image visibility guarantees as the eager decoder.

**Plans**: TBD

### Phase 18: Resumable QOI Buffer Encode

**Goal**: Library users can preflight a compatible image once and drain its canonical QOI representation through caller-supplied output buffers or leases with resumable progress.
**Depends on**: Phase 17
**Requirements**: QSTR-04, QSTR-05
**Success Criteria** (what must be TRUE):

  1. A library user can supply arbitrary output capacities and receive deterministic non-terminal output-needed progress until each canonical QOI byte has been written exactly once, in order, with no duplication or omission.
  2. A library user can observe the exact completed byte total and obtain the same canonical QOI bytes as the eager encoder for the same compatible source image.
  3. Incompatible source semantics, limits, budget exhaustion, and setup failures are reported before the first output byte becomes visible; terminal results reject further use deterministically.

**Plans**: TBD

### Phase 19: Portable Streaming QOI Evidence

**Goal**: Library users and maintainers can independently prove the new streaming contracts through a small public processing workflow and adversarial portable conformance evidence.
**Depends on**: Phase 18
**Requirements**: QSTR-06, QSTR-07
**Success Criteria** (what must be TRUE):

  1. Maintainers can run generated QOI vectors through hostile input chunk schedules and output capacities on `js`, `wasm`, `wasm-gc`, and `native`, proving exact pixels, canonical bytes, progress, and terminal failures.
  2. A library user can run one public portable example that feeds chunked QOI bytes to the streaming decoder, applies an existing image operation, drains canonical QOI bytes through streaming output buffers, and prints deterministic evidence.
  3. The streaming evidence uses only public portable MoonBit contracts and does not invoke FFI, alter `Reader` EOF semantics, add PNG/DEFLATE work, or introduce registry or release-automation work.

**Plans**: 1/1 plans executed

Plans:

- [x] 19-01-PLAN.md — Prove hostile portable QOI streaming schedules and upgrade the existing public QOI workflow.

### Phase 20: PNG Structural Safety Gate

**Goal**: Library users can safely identify and structurally validate the supported PNG subset before image output is exposed.
**Depends on**: Phase 19
**Requirements**: PNG-01, PNG-02, PNG-03
**Success Criteria** (what must be TRUE):

  1. A library user can non-consumingly probe a PNG signature and receives deterministic incomplete, unsupported, or invalid results within declared codec input limits.
  2. A library user receives typed deterministic rejection for invalid PNG framing, chunk ordering, chunk CRCs, unsupported critical or semantic chunks, incomplete IEND, and trailing input.
  3. A library user receives checked dimension, pixel, input, output, work, allocation, and metadata-policy rejection before PNG decode exposes an image.

**Plans**: 1/2 plans executed

- [ ] 20-01-PLAN.md
- [x] 20-02-PLAN.md

### Phase 21: Bounded PNG Decode and DEFLATE

**Goal**: Library users can decode the supported non-interlaced PNG RGB/RGBA subset through bounded, deterministic pure-MoonBit decompression and scanline reconstruction.
**Depends on**: Phase 20
**Requirements**: PNG-04, PNG-05
**Success Criteria** (what must be TRUE):

  1. A library user can decode non-interlaced 8-bit truecolour RGB and RGBA PNG images with each of the five PNG filters into the existing portable image contracts.
  2. A library user can decode legal zlib streams using stored, fixed-Huffman, or dynamic-Huffman DEFLATE blocks across arbitrary IDAT boundaries.
  3. A library user receives typed deterministic failure for malformed zlib headers, Huffman trees, distances, checksums, expansion attempts, or any decode that exceeds declared limits, without a partial image becoming visible.

**Plans**: 2/3 plans executed

Plans:

- [ ] 21-02-PLAN.md
- [x] 21-03-PLAN.md

- [x] 21-01-PLAN.md — Implement bounded IDAT/DEFLATE/raster eager decode and independent four-target evidence.

### Phase 22: Canonical PNG Encode and Portable Evidence

**Goal**: Library users can create deterministic PNG output and independently verify supported PNG interoperability through portable public evidence.
**Depends on**: Phase 21
**Requirements**: PNG-06, PNG-07
**Success Criteria** (what must be TRUE):

  1. A library user can encode a compatible RGB8 or straight-RGBA8 image view to one documented deterministic PNG byte sequence after eager-equivalent preflight has completed without writing output on failure.
  2. A library user can run a public PNG decode → existing image operation → encode workflow using only portable public contracts and receive deterministic output evidence.
  3. Maintainers can verify supported fixtures and hostile PNG cases with identical expected behavior on `js`, `wasm`, `wasm-gc`, and `native`.

**Plans**: 1/1 plans executed

- [x] 22-01-PLAN.md

### Phase 23: PNG Colour Declaration and sRGB Semantics

**Goal:** A library user can receive strict validated PNG colour declarations, with `sRGB` mapped truthfully to the existing encoded-sRGB image model.
**Depends on:** Phase 22
**Requirements:** PNGCM-01, PNGCM-02
**Success Criteria:**

1. `sRGB`, `gAMA`, `cHRM`, and `iCCP` singleton/order/payload rules are enforced before image visibility.
2. Valid `sRGB` images preserve their rendering intent and expose built-in encoded-sRGB metadata; malformed or conflicting declarations fail deterministically.
3. Existing reference operations continue to accept only actual encoded-sRGB images.

**Plans:** 2/2 plans complete

- [x] 23-02-PLAN.md

- [x] 23-01-PLAN.md

### Phase 24: Bounded Non-sRGB and ICC Preservation

**Goal:** A library user can retain legal legacy and ICC PNG colour declarations without treating samples as sRGB or performing an implicit transform.
**Depends on:** Phase 23
**Requirements:** PNGCM-03, PNGCM-04
**Success Criteria:**

1. Valid `gAMA`/`cHRM` declarations and bounded valid `iCCP` payloads are retained in explicit non-sRGB metadata with declared precedence.
2. Invalid profile names, methods, zlib payloads, incompatible ICC colour spaces, and resource expansion fail deterministically before output.
3. Reference operations and canonical PNG encoding return a typed capability result rather than losing non-sRGB semantics.

**Plans:** 2/2 plans complete

- [x] 24-01-PLAN.md

### Phase 25: Portable Colour Conformance Evidence

**Goal:** Maintainers can independently verify colour-metadata behaviour and bounded failures across all portable targets.
**Depends on:** Phase 24
**Requirements:** PNGCM-05
**Success Criteria:**

1. Generated fixtures cover precedence, every recognised chunk grammar, profile resource ceilings, and split-IDAT equivalence.
2. The PNG quality lane proves the same outcomes on js, wasm, wasm-gc, and native.
3. Public documentation precisely distinguishes declaration preservation from unimplemented colour transforms.

**Plans:** 1/1 plans complete

---
*Roadmap updated: 2026-07-21 for v0.7 PNG Colour Fidelity planning*
