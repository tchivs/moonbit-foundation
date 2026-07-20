# Roadmap: MoonBit Native Foundation

## Milestones

- ✅ **v0.1 Foundation** — Phases 1-5, 41 plans, 36/36 requirements (shipped 2026-07-17). Full history: [v0.1 roadmap](./milestones/v0.1-ROADMAP.md).
- ⏸️ **v0.2 Publication & Compatibility** — Phases 6-8 completed or partially prepared; registry publication and closure remain deferred without a registry mutation.
- ✅ **v0.3 Image Processing Core** — Phases 9-12, 9 requirements (shipped 2026-07-20). Full history: [v0.3 roadmap](./milestones/v0.3-ROADMAP.md).
- 🗺️ **v0.4 Portable Image Interchange** — Phases 13-15, 6 requirements planned; pure-MoonBit QOI 1.0 interchange across four targets.

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

### 🗺️ v0.4 Portable Image Interchange (Planned)

**Milestone goal:** Add strict, bounded QOI 1.0 interchange to the existing portable image contracts without foreign codec dependencies.

- [x] **Phase 13: QOI Format Core and Safe Decode** - Users can identify and decode valid QOI images while hostile input fails deterministically before unsafe work. (completed 2026-07-20)
- [x] **Phase 14: Canonical QOI Encode and Four-Target Vectors** - Users can create lossless canonical QOI output proven by specification-derived vectors on every supported target. (completed 2026-07-20)
- [ ] **Phase 15: Public QOI Processing Example** - Users can run a documented portable QOI decode-process-encode workflow with deterministic evidence.

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

**Execution order:** 9 → 10 → 11 → 12 → 13 → 14 → 15

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
| 9. Checked Image Geometry and Diagnostics | v0.3 | 2/2 | Complete   | 2026-07-20 |
| 10. Alpha-Correct Pixel Processing | v0.3 | 2/2 | Complete   | 2026-07-20 |
| 11. Portable Processing Pipeline Evidence | v0.3 | 3/3 | Complete   | 2026-07-20 |
| 12. Strict PPM End-to-End Filter Coverage | v0.3 | 1/1 | Complete   | 2026-07-20 |
| 13. QOI Format Core and Safe Decode | v0.4 | 1/1 | Complete    | 2026-07-20 |
| 14. Canonical QOI Encode and Four-Target Vectors | v0.4 | 1/1 | Complete    | 2026-07-20 |
| 15. Public QOI Processing Example | v0.4 | 0/TBD | Not started | - |

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

---
*Roadmap updated: 2026-07-20 for v0.4 Portable Image Interchange planning*
