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

### Active

- [ ] Verify the mooncakes.io owner namespace and publish `mb-core`, `mb-color`, and `mb-image` in strict dependency order with independent registry consumers.
- [ ] Automate auditable, credential-minimal, repeatable release qualification and provenance without weakening the existing Required gate.
- [ ] Freeze machine-checkable public API compatibility baselines and candidate-version change rules before ecosystem expansion.

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

## Current Milestone: v0.2 Publication & Compatibility

**Goal:** Turn the verified 0.1.0 candidate modules into genuinely published, independently resolvable ecosystem foundations with auditable release automation and machine-checked compatibility baselines.

**Target features:**

- Verify registry namespace authority, publish in core → color → image order, and prove clean external consumers against the real registry.
- Add credential-minimal release automation, immutable provenance, safe retry/recovery rules, and post-publication verification.
- Establish semantic-interface compatibility baselines and candidate-version evolution gates for future module work.

No new graphics, document, media, AI, or integration module is added in v0.2. Distribution and compatibility must be real before the ecosystem surface expands.

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
| Complete publication and compatibility before adding the next module family | Unpublished foundations cannot provide a dependable ecosystem contract to downstream authors | — Pending in v0.2 |

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
*Last updated: 2026-07-17 at v0.2 milestone start*
