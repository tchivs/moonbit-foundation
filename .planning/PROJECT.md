# MoonBit Native Foundation

## What This Is

MoonBit Native Foundation (MNF) is an RFC-led ecosystem initiative that defines and implements composable infrastructure for graphics, documents, media, AI, and system-oriented MoonBit software. It is not an end-user application or a loose catalog of unrelated libraries: the Whitepaper establishes shared architecture, compatibility policy, module boundaries, and quality standards, while independently publishable MoonBit modules implement those contracts over time.

The primary audience is MoonBit library authors and application developers building image tools, PDF/SVG tooling, whiteboards, OCR and AI pipelines, CLI tools, MCP servers, IDE extensions, desktop software, and WebAssembly applications.

## Core Value

MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Publish an accepted foundation RFC defining vision, terminology, layering, module boundaries, portability, and governance.
- [ ] Establish a reproducible multi-module repository and CI quality contract for Native and portable targets.
- [ ] Implement and validate the first reusable contracts in `mb-core`, `mb-color`, and `mb-image`.
- [ ] Keep native-specific code behind narrow adapters while implementing core data models and algorithms in MoonBit.
- [ ] Provide generated API documentation, examples, benchmarks, and conformance tests for every stable public package.

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
| Treat MNF as an RFC/Whitepaper-led foundation | The product is a long-lived ecosystem contract, not one application or an unstructured library bundle | — Pending |
| Use horizontal-layer planning | Infrastructure dependencies require shared contracts before higher-level modules | — Pending |
| Scope the first implementation milestone to `mb-core`, `mb-color`, and `mb-image` | These modules establish reusable data, color, and image contracts needed by all later graphics/document work | — Pending |
| Prefer Pure MoonBit without banning narrow FFI adapters | This advances MoonBit-native capability while remaining practical for OS, codec, and hardware integration | — Pending |
| Make target support explicit per package | Native-specific integration must not accidentally contaminate portable packages | — Pending |
| Use an RFC gate for new modules and breaking boundaries | Ecosystem coherence needs reviewable architectural decisions | — Pending |

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
*Last updated: 2026-07-16 after initialization*
