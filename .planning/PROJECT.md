# MoonBit Native Foundation

## What This Is

MoonBit Native Foundation (MNF) is an RFC-led ecosystem initiative that defines and implements composable infrastructure for graphics, documents, media, AI, and system-oriented MoonBit software. It is not an end-user application or a loose catalog of unrelated libraries: the Whitepaper establishes shared architecture, compatibility policy, module boundaries, and quality standards, while independently publishable MoonBit modules implement those contracts over time.

The primary audience is MoonBit library authors and application developers building image tools, PDF/SVG tooling, whiteboards, OCR and AI pipelines, CLI tools, MCP servers, IDE extensions, desktop software, and WebAssembly applications.

## Core Value

MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## Requirements

### Validated

- [x] Publish an accepted foundation RFC defining vision, terminology, layering, module boundaries, portability, and governance. — Validated in Phase 1: Foundation Charter and Reproducible Workspace.
- [x] Establish a reproducible multi-module repository and CI quality contract for Native and portable targets. — Validated in Phase 1: Foundation Charter and Reproducible Workspace.
- [x] Implement and validate the first reusable contracts in `mb-core`, `mb-color`, and `mb-image`. — Validated across Phases 2-4 and the Phase 5 release-candidate gate.
- [x] Keep native-specific code behind narrow adapters while implementing core data models and algorithms in MoonBit. — Validated by the four-target portable packages and injected Native CLI-shaped example.
- [x] Provide generated API documentation, examples, benchmarks, and conformance tests for every candidate public package. — Validated by the closed Phase 5 documentation, benchmark, fixture, and release selectors.
- [x] Provide a portable, pure-MoonBit QOI 1.0 decoder and canonical encoder with hostile-input handling and four-target vectors. — Validated in v0.4 Phases 13-14.
- [x] Prove public QOI decode-process-encode interoperability on all supported targets. — Validated in v0.4 Phases 15-16.
- [x] Provide resumable QOI decode and encode APIs with hostile-schedule and public workflow evidence on all four portable targets. — Validated in v0.5 Phases 17-19.

### Active

- [ ] Provide a public caller-buffered, resumable PNG decode API with explicit completion, exact progress, and no partial-image visibility.
- [ ] Preserve eager PNG decoding as a compatible facade while refactoring its framing, IDAT, DEFLATE, and raster pipeline into pausable MoonBit-owned state.
- [ ] Prove hostile PNG chunk schedules and strict EOF/IEND semantics unchanged on js, wasm, wasm-gc, and native.

### Out of Scope

- Photoshop-, Figma-, or Office-class applications — applications are downstream consumers, not MNF deliverables.
- A GUI framework or game engine — MNF must remain runtime- and UI-independent.
- `mb-canvas`, `mb-svg`, `mb-font`, and `mb-pdf` implementation in the initial milestone — their boundaries are defined now, but implementation depends on validated foundation contracts.
- GPU abstraction, AI inference, and MCP integration in the initial milestone — advanced layers are deferred until graphics and document primitives stabilize.
- Claiming zero C/C++ under all circumstances — system integration and codecs may require narrow native stubs; Pure MoonBit is a priority for core algorithms, not an unverifiable purity claim.

## Context

The project replaces an earlier application-oriented direction centered on building products such as image or PDF editors. The new product is the underlying MoonBit-native infrastructure ecosystem those applications could consume.

MoonBit currently supports `wasm`, `wasm-gc`, `js`, and `native`, with LLVM still experimental. The C-backed Native path supports C FFI and native stubs; therefore portability must be expressed package-by-package rather than assumed globally. A MoonBit module is the publishing unit and can contain multiple packages, so MNF can start as a coordinated workspace while preserving future independent release boundaries.

The local baseline at initialization is `moon 0.1.20260713`, `moonc v0.10.4`, and `moonrun 0.1.20260713`. These are development baselines, not permanent minimum versions.

## Current State

v0.1 shipped on 2026-07-17 as a verified release-candidate foundation: five phases, 41 plans, and 36/36 requirements complete. The repository contains independently publishable `mb-core`, `mb-color`, and `mb-image` modules; strict bounded PPM P6 proves the public stack end to end across `js`, `wasm`, `wasm-gc`, and `native`.

The locked qualification baseline passed 19/19 selectors twice at one unchanged HEAD with identical canonical evidence. Exact `mb-core` artifact consumption succeeds outside `moon.work`; downstream color/image registry resolution remains intentionally blocked until namespace ownership and dependency publication are real.

Phase 6 completed on 2026-07-18 with 25/25 plans and 8/8 requirements verified. The active module identities are `tchivs/mb-core`, `tchivs/mb-color`, and `tchivs/mb-image`; deterministic compatibility baselines, reciprocal requirement/edge/prohibition evidence, and the real credential-free Required lane now pass. Publication remains deliberately blocked until Phase 7 proves the authenticated publish seam before any registry mutation.

## Current State: v0.5 QOI Streaming I/O Shipped

**Delivered:** `mb-image` now supports bounded, resumable QOI decode and encode beside its eager codec APIs. The sole public QOI consumer proves caller-owned chunk decode → horizontal flip → caller-owned lease encode on `js`, `wasm`, `wasm-gc`, and `native` with fixed schedules, exact counters, canonical bytes, and SHA-256 evidence.

**Validated streaming properties:**

- Explicit decoder completion preserves strict marker, trailing-data, limit, budget, and terminal-state guarantees without changing `Reader` EOF behavior.
- Encoder construction preserves eager-equivalent preflight before any byte is exposed; pulls emit canonical bytes through arbitrary caller leases.
- Generated hostile schedules and the isolated QOI quality lane protect four-target conformance without release automation, registry work, FFI, or PNG/DEFLATE expansion.

Registry publication remains deferred: the existing v0.2 qualification artifacts are retained, but no further release automation is in scope for the next code-first milestone.

## Current Milestone: v0.8 Resumable PNG Decode

**Goal:** Add a portable, caller-buffered PNG decode path that can pause at arbitrary input boundaries yet preserves eager PNG semantics, strict completion, bounded resources, and private output until success.

**Target features:**

- Refactor the eager PNG framing, IDAT/CRC transport, DEFLATE, and raster pipeline into resumable MoonBit state without narrowing the already supported PNG profiles.
- Publish `PngChunkDecoder` with caller-owned chunk input, explicit `finish()`, sticky terminal behavior, exact consumed-byte accounting, and one completed owned image only after strict IEND/EOF validation.
- Prove split boundaries across framing, IDAT, zlib/DEFLATE, filters, IEND, and hostile failures on js, wasm, wasm-gc, and native, without FFI, release work, or a public streaming encoder in this milestone.


## Constraints

- **Implementation**: Core algorithms and shared data models should be written in MoonBit — ecosystem credibility depends on exercising MoonBit rather than wrapping a foreign stack.
- **Backend**: Native is the primary performance and system-integration target — portable targets are supported deliberately through capability boundaries and conformance tests.
- **FFI**: Native stubs must remain small, isolated, documented, and replaceable — FFI ownership and reference-counting rules create correctness risk.
- **Modularity**: Public packages must have acyclic, explicitly documented dependencies — consumers must not import the whole ecosystem for one primitive.
- **Compatibility**: Public API stability follows Semantic Versioning after a package is declared stable — experimental APIs must be visibly marked.
- **Automation**: Public operations should be deterministic and usable without GUI state — CLI, AI Agent, and MCP consumers are first-class.
- **Performance**: Benchmarks require declared workloads and reproducible baselines — marketing claims without evidence are not acceptance criteria.
- **Governance**: New modules and breaking architectural changes require RFCs — implementation cannot silently redefine ecosystem boundaries.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Treat MNF as an RFC/Whitepaper-led foundation | The product is a long-lived ecosystem contract, not one application or an unstructured library bundle | ✓ Validated in Phase 1 |
| Use horizontal-layer planning | Infrastructure dependencies require shared contracts before higher-level modules | ✓ Validated in Phase 1 |
| Scope the first implementation milestone to `mb-core`, `mb-color`, and `mb-image` | These modules establish reusable data, color, and image contracts needed by all later graphics/document work | ✓ Validated in v0.1 |
| Prefer Pure MoonBit without banning narrow FFI adapters | This advances MoonBit-native capability while remaining practical for OS, codec, and hardware integration | ✓ Validated in v0.1 |
| Make target support explicit per package | Native-specific integration must not accidentally contaminate portable packages | ✓ Validated in Phase 1 |
| Use an RFC gate for new modules and breaking boundaries | Ecosystem coherence needs reviewable architectural decisions | ✓ Validated in Phase 1 |
| Use checked budgets, explicit capabilities, and forward-only I/O as shared safety contracts | Untrusted binary and image processing must fail before prohibited access, allocation, or work | ✓ Validated in Phases 2-5 |
| Treat deterministic evidence and honest blocked outcomes as release requirements | Candidate qualification must not depend on fabricated publication or noisy marketing claims | ✓ Validated in Phase 5 |
| Keep unknown live registry authority fail-closed and prove it only inside the isolated publisher | Public account identity and module-name availability do not prove current-token publication authority | ✓ Validated in Phase 6 |
| Complete publication and compatibility before adding the next module family | Unpublished foundations cannot provide a dependable ecosystem contract to downstream authors | — Pending in v0.2 |
| Prioritize reusable image-processing code over further publication automation | The release route is already recoverable enough for a future manual operation; the ecosystem benefits more from implementable raster capabilities | ✓ Validated in v0.3 |
| Implement QOI before a heavyweight lossless codec | QOI adds a real RGB/RGBA interchange format while preserving a pure MoonBit, four-target implementation and bounded attack surface | ✓ Validated in v0.4 |
| Add streaming QOI before a heavyweight codec | Stateful chunked I/O completes the existing forward-only codec contract without widening scope to PNG/DEFLATE or FFI | ✓ Validated in v0.5 |
| Preserve PNG colour declarations before implementing colour transforms | Raw sample bytes cannot honestly be treated as sRGB when a file declares different colour semantics | ✓ Validated in v0.7 |
| Build public PNG streaming as a separate state-machine milestone | A public caller-buffered API must preserve strict framing, image-visibility, and resource semantics rather than expose the eager transport internals | — Active in v0.8 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition**:
1. Move validated requirements to Validated with the phase reference.
2. Move invalidated requirements to Out of Scope with the reason.
3. Add newly discovered requirements to Active.
4. Record consequential decisions and update their outcomes.
5. Check that What This Is and Core Value still describe the actual project.

**After each milestone**:
1. Review every section against shipped artifacts and community feedback.
2. Confirm the Core Value still drives prioritization.
3. Audit deferred and excluded scope.
4. Update toolchain, compatibility, benchmark, and adoption context.

---
*Last updated: 2026-07-21 after v0.8 Resumable PNG Decode milestone creation*
