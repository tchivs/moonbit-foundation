# Requirements: MoonBit Native Foundation

**Defined:** 2026-07-16  
**Milestone:** v0.1 Foundation  
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v1 Requirements

### Charter and Governance

- [x] **GOV-01**: A contributor can read an accepted foundation RFC that defines MNF's vision, principles, terminology, architectural layers, dependency direction, and v0.1 boundaries.
- [x] **GOV-02**: A contributor can follow a documented RFC lifecycle with named statuses, acceptance authority, review expectations, and rules for breaking architectural changes.
- [x] **GOV-03**: A package consumer can distinguish experimental, candidate, and stable public APIs and understand the compatibility promise of each status.
- [x] **GOV-04**: A contributor can identify the chosen project license, fixture licensing rules, mooncakes.io owner/namespace, and module naming policy before public release.

### Workspace and Portability

- [x] **WORK-01**: A developer can clone the repository and operate `mb-core`, `mb-color`, and `mb-image` as three independently publishable MoonBit modules in one workspace.
- [x] **WORK-02**: A developer can reproduce the v0.1 development environment from a checked-in toolchain policy that records the exact `moon`, `moonc`, and `moonrun` baseline.
- [x] **WORK-03**: A consumer can inspect every public package's explicit supported-target declaration and determine whether it supports `native`, `wasm`, `wasm-gc`, or `js`.
- [x] **WORK-04**: A maintainer can run root-level format, check, test, documentation, package-content, and dependency-DAG validation without manually entering each module.
- [x] **WORK-05**: A maintainer can verify portable package behavior on every declared target while LLVM remains clearly non-blocking and experimental.
- [ ] **WORK-06**: A release can qualify each module independently and in dependency order without requiring consumers to install unrelated MNF layers.

### Core Primitives

- [x] **CORE-01**: A library author can perform checked addition, multiplication, alignment, casts, ranges, offsets, dimensions, and allocation-size calculations with structured overflow failure.
- [x] **CORE-02**: A library author can create owned byte storage and validated immutable or mutable byte views without accessing outside the declared range.
- [x] **CORE-03**: A library author can read and write through backend-neutral interfaces that distinguish exact, partial, end-of-stream, and failed operations.
- [x] **CORE-04**: A parser can use bounded sub-readers and in-memory reader/writer implementations without requiring filesystem access or full-input buffering.
- [x] **CORE-05**: A consumer can use seek only when the supplied capability supports it, without forcing seekability into every stream.
- [x] **CORE-06**: A tool can receive machine-readable errors and diagnostics with stable categories/codes, source offsets or context, and deterministic human-readable rendering.
- [x] **CORE-07**: A caller can set safe resource budgets for bytes, allocations, dimensions/pixels, nesting, and work, and receives a structured limit error before prohibited work or allocation occurs.
- [x] **CORE-08**: A portable package can receive host capabilities such as files, logging, clocks, cancellation, or resource resolution explicitly rather than reading ambient process state.

### Color Semantics

- [x] **COLR-01**: A library author can represent color components, color-space identity, transfer function, and straight versus premultiplied alpha without implicit defaults.
- [x] **COLR-02**: A consumer can convert between encoded sRGB and linear sRGB using documented finite-value, range, rounding, and tolerance behavior.
- [x] **COLR-03**: A consumer can premultiply and unpremultiply alpha with specified zero-alpha and rounding semantics.
- [x] **COLR-04**: A maintainer can validate color behavior against provenance-recorded reference vectors and invariants on every declared target.
- [x] **COLR-05**: A future codec can preserve a bounded color-profile identity or opaque metadata seam without requiring a full ICC parser in v0.1.

### Image Model and Operations

- [x] **IMAG-01**: A library author can describe image dimensions, pixel format, component depth/type, channel order, packed or planar layout, stride, plane count, endianness, color space, alpha mode, and orientation explicitly.
- [x] **IMAG-02**: Public constructors reject overflow, invalid dimensions, impossible strides, insufficient storage, invalid plane ranges, and prohibited overlap before access or allocation.
- [x] **IMAG-03**: A consumer can create owned images and safe immutable or mutable views whose bounds and backing-storage rules are enforced.
- [x] **IMAG-04**: A consumer can crop or create subviews without copying when the representation permits it and without escaping the backing storage's safe lifetime.
- [x] **IMAG-05**: A consumer can perform deterministic copies, horizontal/vertical flips, orientation application, nearest-neighbor resize, and the minimal required pixel conversions.
- [x] **IMAG-06**: A consumer can predict whether metadata is preserved, transformed, or discarded by each image operation.
- [x] **IMAG-07**: A codec author can implement decoding and encoding against backend-neutral reader/writer and image contracts without importing a global registry or filesystem policy.

### Reference Proof and Release Evidence

- [x] **QUAL-01**: A developer can decode and encode a strict, bounded PPM P6 reference subset through the public codec interfaces, with malformed or oversized inputs producing structured failures.
- [x] **QUAL-02**: A Native CLI-shaped example and an in-memory portable example can execute the complete stream-to-image-to-transform-to-stream path using only public APIs.
- [x] **QUAL-03**: A maintainer can run black-box API tests, internal invariant tests, conformance vectors, adversarial limit fixtures, and applicable property or metamorphic tests for stable candidate behavior.
- [x] **QUAL-04**: A consumer can access runnable API documentation, examples, support matrices, changelogs, and fixture provenance for every release candidate module.
- [ ] **QUAL-05**: A maintainer can reproduce benchmark baselines that record toolchain, target, optimization mode, hardware/runtime, corpus, repetitions, variance, and correctness assumptions without treating noisy hosted results as marketing claims.
- [ ] **QUAL-06**: A release process verifies packaged contents, clean-consumer dependency resolution outside workspace substitution, target conformance, module independence, compatibility metadata, and release provenance before publishing in dependency order.

## v2 Requirements

### Graphics and Scene

- **GFX-01**: Developers can build paths, transforms, paints, blends, clips, and deterministic CPU raster operations with `mb-canvas`.
- **GFX-02**: Developers can parse and render a bounded SVG subset through `mb-svg` without depending on a GUI runtime.

### Font, Text, and Layout

- **TEXT-01**: Developers can load font containers and access glyph and metric data through `mb-font`.
- **TEXT-02**: Developers can shape and lay out text through separate `mb-text` and `mb-layout` contracts.

### Documents

- **DOC-01**: Developers can parse, generate, and render bounded PDF documents through layered `mb-pdf` packages.
- **DOC-02**: Developers can opt into production image codecs without adding them to `mb-image`'s mandatory dependency graph.

### Advanced Integrations

- **ADV-01**: Developers can opt into GPU acceleration while retaining CPU reference semantics as the correctness oracle.
- **ADV-02**: Developers can connect AI runtimes through replaceable adapter contracts rather than binding MNF to one inference engine.
- **ADV-03**: Developers can expose deterministic MNF operations through MCP without coupling core libraries to transport or agent state.
- **ADV-04**: Portable consumers can use target-specific Wasm optimizations without changing shared data semantics.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Photoshop-, Figma-, or Office-class application | MNF is the reusable substrate for such products, not the product UI itself |
| GUI framework or game engine | Core libraries must remain headless and runtime-neutral |
| Production PNG/JPEG/WebP codec suite in v0.1 | Format breadth would add security and conformance scope before the foundation contracts are proven |
| Full ICC parser and color-management engine in v0.1 | v0.1 needs explicit color semantics and a profile seam, not the full ICC domain |
| SVG, font shaping, text layout, or PDF implementation in v0.1 | These depend on validated core, color, and image contracts and remain v2 work |
| GPU, AI runtime, and MCP implementation in v0.1 | Advanced adapters must not dictate lower-layer APIs prematurely |
| Universal image type with implicit layout/color defaults | Hidden representation policy prevents reliable interoperability |
| Mandatory filesystem, network, GUI, or process-global state | Portable and automation consumers require explicit capabilities |
| Zero-FFI purity promise | Narrow, reviewed native adapters may be necessary; portable public contracts remain MoonBit-owned |
| LLVM compatibility claim | LLVM is experimental and excluded from the current required `--target all` matrix |

## Definition of Done

- Every v1 requirement maps to exactly one roadmap phase and has verification evidence.
- All declared target checks and behavioral conformance suites pass from a clean checkout.
- Public constructors and parsers reject invalid ranges, overflows, and configured resource-limit violations before unsafe access or allocation.
- The end-to-end PPM reference flow works through public APIs in Native and portable examples.
- Each module is independently documented, package-qualified, and consumable with correct dependency constraints.
- RFC 0001 and all blocking governance/publication decisions are accepted or assigned to explicit follow-up RFCs.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| GOV-01 | Phase 1 | Complete |
| GOV-02 | Phase 1 | Complete |
| GOV-03 | Phase 1 | Complete |
| GOV-04 | Phase 1 | Complete |
| WORK-01 | Phase 1 | Complete |
| WORK-02 | Phase 1 | Complete |
| WORK-03 | Phase 1 | Complete |
| WORK-04 | Phase 1 | Complete |
| WORK-05 | Phase 1 | Complete |
| WORK-06 | Phase 5 | Pending |
| CORE-01 | Phase 2 | Complete |
| CORE-02 | Phase 2 | Complete |
| CORE-03 | Phase 2 | Complete |
| CORE-04 | Phase 2 | Complete |
| CORE-05 | Phase 2 | Complete |
| CORE-06 | Phase 2 | Complete |
| CORE-07 | Phase 2 | Complete |
| CORE-08 | Phase 2 | Complete |
| COLR-01 | Phase 3 | Complete |
| COLR-02 | Phase 3 | Complete |
| COLR-03 | Phase 3 | Complete |
| COLR-04 | Phase 3 | Complete |
| COLR-05 | Phase 3 | Complete |
| IMAG-01 | Phase 4 | Complete |
| IMAG-02 | Phase 4 | Complete |
| IMAG-03 | Phase 4 | Complete |
| IMAG-04 | Phase 4 | Complete |
| IMAG-05 | Phase 4 | Complete |
| IMAG-06 | Phase 4 | Complete |
| IMAG-07 | Phase 4 | Complete |
| QUAL-01 | Phase 5 | Complete |
| QUAL-02 | Phase 5 | Complete |
| QUAL-03 | Phase 5 | Complete |
| QUAL-04 | Phase 5 | Complete |
| QUAL-05 | Phase 5 | Pending |
| QUAL-06 | Phase 5 | Pending |

**Coverage:**

- v1 requirements: 36 total
- Mapped to phases: 36
- Unmapped: 0

---
*Requirements defined: 2026-07-16*  
*Last updated: 2026-07-16 after initial research synthesis*
