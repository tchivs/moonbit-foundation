# MoonBit Native Foundation

## What This Is

MoonBit Native Foundation (MNF) is an RFC-led ecosystem initiative that defines and implements composable infrastructure for graphics, documents, media, AI, and system-oriented MoonBit software. It is not an end-user application or a loose catalog of unrelated libraries: the Whitepaper establishes shared architecture, compatibility policy, module boundaries, and quality standards, while independently publishable MoonBit modules implement those contracts over time.

The primary audience is MoonBit library authors and application developers building image tools, PDF/SVG tooling, whiteboards, OCR and AI pipelines, CLI tools, MCP servers, IDE extensions, desktop software, and WebAssembly applications.

## Core Value

MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## Current Milestone: Planning Next Code-First Increment

**Goal:** Select the next high-value MoonBit-native image or document infrastructure increment from validated public contracts.

**Validated baseline:** Packed U8 Gray+Alpha with explicit straight alpha, bounded non-interlaced Type 4 PNG encoding, public hostile caller-buffered behavior, frozen legacy vectors, and four-target proof shipped in v0.16.

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
- [x] Provide public caller-buffered, resumable PNG decode with explicit completion, exact progress, and no partial-image visibility. — Validated in v0.8 Phases 26-28.
- [x] Provide public caller-buffered, resumable PNG encoding with eager-equivalent bytes, sticky terminals, and four-target hostile-schedule evidence. — Validated in v0.9 Phases 29-31.
- [x] Preserve eager PNG decoding as a compatible facade while refactoring its framing, IDAT, DEFLATE, and raster pipeline into pausable MoonBit-owned state. — Validated in v0.8 Phases 26-28.
- [x] Prove hostile PNG chunk schedules and strict EOF/IEND semantics unchanged on js, wasm, wasm-gc, and native. — Validated in v0.8 Phases 26-28.
- [x] Add an explicit opt-in PNG Dynamic compression strategy while preserving Stored and FixedOrStored output. — Validated in v0.10-v0.11 Phases 32-37.
- [x] Produce smaller deterministic PNG output for repetitive images with bounded atomic preflight and caller-buffered semantics. — Validated in v0.10-v0.11 Phases 32-37.
- [x] Prove optimized eager and chunk PNG output across all portable targets with reproducible corpus and size evidence. — Validated in v0.10-v0.11 Phases 32-37.
- [x] Preserve existing PNG filter-None constructors and compressed bytes while allowing an explicit adaptive-filter opt-in. — Validated in v0.12 Phases 38-40.
- [x] Produce deterministic, bounded PNG scanline filtering with the standard None, Sub, Up, Average, and Paeth predictors. — Validated in v0.12 Phases 38-40.
- [x] Integrate selected filter bytes with Stored, FixedOrStored, and Dynamic compression planning without weakening atomic preflight or caller-buffered semantics. — Validated in v0.12 Phases 38-40.
- [x] Prove adaptive-filter output, eager/chunk determinism, and complete decode on all four portable targets. — Validated in v0.12 Phase 40.
- [x] Provide an explicit opt-in Adam7 PNG encoding route for RGB8 and straight-RGBA8 without changing legacy non-interlaced bytes. — Validated in v0.13 Phases 41-43.
- [x] Preserve bounded, atomic eager and caller-buffered encoder behavior while traversing Adam7 passes. — Validated in v0.13 Phases 41-43.
- [x] Prove public Adam7 encode/decode fidelity and eager/chunk identity across all portable targets. — Validated in v0.13 Phase 43.
- [x] Provide explicit bounded Gray8 PNG encoding and public four-target evidence. — Validated in v0.14 Phases 44-46.
- [x] Provide explicit packed-U16 Gray16 PNG encoding with byte-preserving wire evidence and bounded caller-buffered behavior. — Validated in v0.15 Phases 47-49.

### Active

- [ ] Define the next code-first milestone from the validated portable image contracts.

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

## Current State: v0.8 Resumable PNG Decode Shipped

**Delivered:** `mb-image` now has a public, portable `PngChunkDecoder` built over a private MoonBit byte-resumable PNG state machine. Callers provide their own chunks, obtain exact consumption/progress, and call `finish()` to receive one eager-equivalent image or a sticky typed terminal error; no partial image is exposed.

**Validated:** The complete PNG package passed 84/84 tests on each of `wasm`, `wasm-gc`, `js`, and `native`. The public workflow freezes `PngChunkDecoder` → bilinear resize → eager PNG encode to a 78-byte output with digest `626208771` on all four targets. The milestone audit passed all four requirements, all three phase verifications, six cross-phase handoffs, and two end-to-end flows.

## Current State: v0.11 PNG Dynamic Huffman Compression Shipped

**Delivered:** `mb-image` now supports the additive `DynamicOrFixedOrStored` PNG strategy. It retains frozen Stored and FixedOrStored compatibility output, constructs Dynamic DEFLATE plans entirely in MoonBit under fixed bounds, and emits Dynamic only for a strict complete-PNG size win.

**Validated:** The shared eager and caller-buffered machine uses acknowledgement-safe Dynamic replay with exact admission and sticky terminals. A generated periodic RGB8 and straight-RGBA8 corpus proves a `BTYPE=10` strict win, eager/chunk byte identity, and complete public decode on `wasm`, `wasm-gc`, `js`, and `native`; the full PNG package passed 131/131 tests on each target.

Registry publication and release automation remain deferred unless they directly unblock a concrete consumer or code path. The next milestone should prioritize another reusable implementation capability over delivery automation.

## Current State: v0.12 PNG Filter Optimization Shipped

**Delivered:** `mb-image` now exposes an additive `Adaptive` PNG filter strategy for eager and caller-buffered encoders. It selects among standard method-0 None, Sub, Up, Average, and Paeth filters deterministically, feeds bounded cursors into Stored, FixedOrStored, and DynamicOrFixedOrStored planning, and preserves frozen filter-None compatibility routes.

**Validated:** Generated RGB8 R1 and straight-RGBA8 A1 sources prove a strict same-strategy Adaptive size win; zero/tiny/ragged caller capacities produce byte-identical eager and chunk output; public decoding restores exact source data on `js`, `wasm`, `wasm-gc`, and `native`. The v0.12 audit passed 4/4 requirements, 3/3 phase verifications, and all cross-phase/E2E flows.

Registry publication and release automation remain deferred unless a concrete consumer is blocked by their absence.

## Current State: v0.14 Gray8 PNG Interchange Shipped

**Delivered:** `mb-image` now exposes explicit eager and caller-buffered non-interlaced Gray8 PNG factories, including Stored, FixedOrStored, DynamicOrFixedOrStored, None, and Adaptive selections through the established bounded pipeline.

**Validated:** Generated 5×3 Gray8 public round trips preserve every source sample through the documented RGB decoder canonicalization; caller-buffered zero, one-byte, and ragged schedules remain eager-byte-identical with accepted-only progress; frozen RGB8/straight-RGBA8 vectors and all Gray8 evidence pass independently on js, wasm, wasm-gc, and native.

## Current State: v0.15 Gray16 PNG Interchange Shipped

## Current State: v0.16 Grayscale Alpha PNG Shipped

**Delivered:** `mb-image` now has a first-class packed U8 Gray+Alpha format with explicit straight-alpha metadata and explicit eager/caller-buffered non-interlaced Type 4 PNG factories.

**Validated:** The shared bounded preflight, filtering, compression planning, and acknowledgement-safe replay path rejects incompatible or resource-limited requests before output or lease exposure. Public `(13,A7)/(D2,4C)` wire/decode vectors, zero/one/ragged hostile schedules, frozen Gray8/Gray16/RGB8/RGBA8 output, and four-target PNG evidence pass independently on `wasm`, `wasm-gc`, `js`, and `native` (196/196 each).

**Delivered:** `mb-image` now exposes explicit eager and caller-buffered Gray16 PNG factories for packed U16 grayscale sources. They use the shared bounded filter, Stored/Fixed/Dynamic compression, admission, and acknowledgement-safe replay machinery while emitting PNG-mandated big-endian type-0/16-bit samples.

**Validated:** Non-symmetric U16 images preserve every wire byte from either source-storage byte order. Eager and zero/one/ragged caller-buffered schedules are identical across all six compression/filter pairs; legacy Gray8/RGB8/RGBA8 vectors stay frozen. The PNG package passed 190/190 tests independently on js, wasm, wasm-gc, and native.


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
| Build public PNG streaming as a separate state-machine milestone | A public caller-buffered API must preserve strict framing, image-visibility, and resource semantics rather than expose the eager transport internals | ✓ Validated in v0.8 and v0.9 |
| Select Dynamic DEFLATE only for a strict complete-PNG win | Existing FixedOrStored bytes remain the compatibility baseline and ties must not churn output | ✓ Validated in v0.11 |
| Decline over-15-bit ordinary Huffman trees instead of adding a length-limited optimizer | Keep Dynamic planning bounded, portable, and within the declared scope | ✓ Validated in v0.11 |
| Make adaptive PNG filtering explicit and select only a stable strict candidate winner | Preserve legacy bytes while adding bounded compression improvements without image-sized staging | ✓ Validated in v0.12 |
| Extend grayscale encoding through explicit profile factories | Preserve legacy PNG bytes and resource semantics while adding Gray8 then U16 Gray16 capability incrementally | ✓ Validated in v0.14-v0.15 |
| Add Gray+Alpha8 through an explicit bounded PNG profile | Preserve legacy image/PNG contracts while exposing type-4 wire fidelity and portable public proof | ✓ Validated in v0.16 |

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
*Last updated: 2026-07-23 after v0.16 Grayscale Alpha PNG milestone*
