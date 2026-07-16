# RFC 0001: MoonBit Native Foundation

- **Status:** Proposed
- **Authors:** MNF contributors
- **Created:** 2026-07-16
- **Target:** Foundation charter and v0.1 architecture
- **Discussion:** To be established
- **Normative process:** [RFC process](../governance/rfc-process.md)
- **Acceptance route:** Not yet satisfied
- **Maintainer approvals:** None recorded
- **Blocking objections:** Not yet assessed through an evidenced review
- **Public review window:** No start or completion evidence recorded
- **Acceptance evidence:** None; this RFC MUST remain Proposed until an authorized route is evidenced

## Transition history

| From | To | Evidence |
|---|---|---|
| — | Draft | Initial RFC in repository history |
| Draft | Proposed | This revision makes the charter reviewable; repository history is the transition record |

No transition to Accepted, Implemented, Rejected, or Superseded has occurred. Every future transition must update this ledger and point to authentic repository or public-review evidence.

## 1. Abstract

MoonBit Native Foundation (MNF) is an RFC-led ecosystem of independently publishable, composable infrastructure modules for graphics, documents, media, AI, automation, and system-oriented MoonBit software. This RFC is the single architectural charter for MNF. It defines the vocabulary, dependency direction, module boundaries, portability model, v0.1 scope, and governance constraints that implementation must follow.

MNF is not an end-user application, GUI framework, game engine, or an umbrella package that consumers must import as a whole.

## 2. Vision and success

MNF makes stable, high-performance native infrastructure contracts reusable across MoonBit projects so that image tools, document systems, whiteboards, OCR and AI pipelines, CLI tools, MCP servers, IDE extensions, desktop software, and WebAssembly applications do not rebuild incompatible foundations.

The foundation succeeds when independently built products can exchange data through MNF contracts, consume only the modules they need, run deterministic operations without GUI state, and validate behavior on every target a package declares.

## 3. Terminology

- **Module:** An independently versioned and publishable MoonBit unit. A module may contain multiple packages.
- **Package:** A compilation and import boundary inside a module. Target support is declared and verified per public package.
- **Layer:** A set of responsibilities whose dependencies point only toward lower layers.
- **Portable package:** MoonBit data or algorithms supported on `js`, `wasm`, `wasm-gc`, and `native` without ambient host capabilities.
- **Host adapter:** A narrow leaf package that supplies explicit operating-system, runtime, device, or foreign-library capabilities to portable contracts.
- **Native-only package:** A package whose documented purpose requires Native facilities and whose supported target is explicitly `native`.
- **Public boundary:** A module responsibility, public dependency edge, data contract, or portability seam on which downstream consumers may rely.
- **Candidate API:** A v0.1 public API under qualification; it is not yet stable and changes require documented migration notes.

## 4. Principles

### 4.1 MoonBit implementation by default

Shared data models, parsers, transforms, raster operations, layout algorithms, and other reusable logic are implemented in MoonBit unless a documented technical constraint requires an adapter. Foreign code must remain small, isolated, documented, replaceable, and outside the portable public contract.

### 4.2 Native first, portability explicit

Native is the primary performance and system-integration target. Portable packages explicitly support `js`, `wasm`, `wasm-gc`, and `native`; native-only integration is isolated behind leaf adapters. Target support is a checked contract, not an assumption inherited from repository location.

### 4.3 Modular, acyclic, and independently consumable

Each module owns one dominant responsibility, declares a minimal dependency set, and follows an independent version and publication lifecycle. Public module dependencies must be acyclic. MNF does not provide an umbrella module that forces consumers into the entire ecosystem or forces lockstep releases.

### 4.4 Runtime-neutral and automation-first

Core packages do not require a windowing system, browser API, game engine, event loop, AI framework, filesystem, or mutable global state. Public operations are deterministic and usable by CLI, Agent, MCP, and headless consumers through explicit inputs, capabilities, limits, and structured failures.

### 4.5 Evidence over claims

Correctness requires tests and conformance fixtures, performance requires reproducible workloads and baselines, target compatibility requires CI evidence, and governance transitions require authentic review evidence.

## 5. Architecture and dependency direction

```text
Applications and Integrations
├── IDE / CLI / Desktop / WebAssembly
├── AI Agent
└── MCP Server
          │
          ▼
Advanced and Integration Layers
├── mb-effects
├── mb-gpu       (planned)
├── mb-ai        (planned)
└── mb-mcp       (planned)
          │
          ▼
Document and Scene Layers
├── mb-svg
├── mb-pdf
├── mb-font
├── mb-text
└── mb-layout
          │
          ▼
Graphics Layers
├── mb-canvas
├── mb-image
└── mb-color
          │
          ▼
Foundation
└── mb-core
          │
          ▼
MoonBit targets: native / wasm / wasm-gc / js
```

Arrows point from a consumer toward a dependency. Dependencies may point inward and downward only. Lower layers never import document, integration, or application layers. The v0.1 allowed public module edges are:

```text
moonbit-foundation/mb-color -> moonbit-foundation/mb-core
moonbit-foundation/mb-image -> moonbit-foundation/mb-color
moonbit-foundation/mb-image -> moonbit-foundation/mb-core
```

No reverse edge, self-edge, cycle, or undeclared public edge is permitted.

## 6. Module boundaries

### 6.1 `moonbit-foundation/mb-core`

Owns checked arithmetic and ranges, byte containers and validated views, bounded readers and writers, backend-neutral stream behavior, structured errors and diagnostics, resource budgets, and explicit host-capability boundaries. It does not own color, image, codec, SVG, font, PDF, GUI, or application concepts. It depends on no other MNF module.

### 6.2 `moonbit-foundation/mb-color`

Owns component representations, color-space identity, transfer functions, deterministic reference conversions, alpha conventions, and bounded profile identity or opaque metadata seams. It does not own image storage, pixel layout, codec selection, rendering, or host I/O. It depends only on `mb-core`.

### 6.3 `moonbit-foundation/mb-image`

Owns image dimensions and descriptions, pixel and plane layout, stride and endianness, owned storage and validated immutable or mutable views, metadata behavior, deterministic foundational transforms, and codec-facing contracts. It does not own filesystem policy, a global codec registry, GUI state, document models, or system codec implementations. It depends on `mb-core` and `mb-color`.

### 6.4 Deferred layers

`mb-canvas`, `mb-svg`, `mb-font`, `mb-text`, `mb-layout`, `mb-pdf`, `mb-effects`, `mb-gpu`, `mb-ai`, and `mb-mcp` retain the responsibilities shown by the architecture, but their implementations are outside v0.1. They may consume accepted lower-layer contracts; they may not redefine them through implementation alone.

## 7. Repository and publication model

The initial implementation uses one repository and one MoonBit workspace for coordinated contract changes. `mb-core`, `mb-color`, and `mb-image` remain separate modules with their own manifest, version, changelog, documentation, tests, and publication lifecycle. The monorepo is a coordination mechanism, not a consumer dependency or a promise of lockstep versions.

Every publishable module must expose its identity, stability status, supported targets, direct dependencies, documentation, examples, conformance evidence, and release history. Public publication remains subject to the repository's publication and compatibility policies.

## 8. Portability and native integration

Core algorithms and shared data models belong in portable packages. Access to files, clocks, environment state, operating-system APIs, devices, and foreign libraries must enter through explicit capabilities or isolated adapters. A native adapter remains a dependency leaf and cannot make a portable package transitively native-only.

Native FFI stubs must document ownership, reference-counting, lifetime, thread, ABI, error, and build assumptions. Unsafe size conversion, unchecked lengths, hidden allocation, and implicit ownership at FFI boundaries are prohibited. LLVM remains experimental and is not part of the required v0.1 target contract.

## 9. v0.1 scope

v0.1 delivers:

1. this charter plus an auditable RFC process;
2. a reproducible three-module workspace and target-aware quality contract;
3. bounded core byte, range, I/O, diagnostic, budget, and capability primitives;
4. explicit reference color and alpha semantics;
5. safe image descriptions, storage/views, metadata behavior, and deterministic operations;
6. a strict bounded PPM P6 reference codec, public end-to-end examples, conformance fixtures, documentation, and reproducible qualification evidence.

Canvas, SVG, font, text layout, PDF, GPU, AI inference, and MCP integration implementations are outside v0.1. Numeric tolerances, image lifetime and layout details, resource-budget defaults, and the exact PPM subset are decided in their owning later phases and may not be preempted by Phase 1 implementation.

## 10. Quality and compatibility contract

A public package cannot be called stable until it has formatting and static checks, public and internal tests, declared-target CI, public API documentation and runnable examples, relevant conformance and adversarial evidence, reproducible benchmark baselines for performance-sensitive work, compatibility metadata, and a security/resource-limit review for untrusted inputs.

v0.1 packages begin as candidate unless explicitly marked experimental. Stable APIs follow Semantic Versioning. Experimental APIs carry no compatibility promise; candidate changes require migration notes. Detailed executable policy is maintained separately, but it cannot override this charter's architecture or governance gate.

## 11. Governance and RFC-required changes

The normative lifecycle, authority routes, evidence requirements, objection handling, and transition rules are defined by the [RFC process](../governance/rfc-process.md). The [RFC index](README.md) is the discoverable list of proposals and their current status.

An accepted RFC is required before any of the following may merge:

- creation of a new MNF module;
- addition, removal, or reversal of a public module dependency direction;
- a breaking change to an accepted architectural layer, module responsibility, portability seam, governance rule, or other public boundary.

Implementation PRs may refine internals within an accepted boundary, but they MUST NOT silently redefine that boundary. If implementation exposes a conflict with this charter, the change pauses until an RFC explicitly resolves it.

## 12. Lifecycle and acceptance

The lifecycle is `Draft -> Proposed -> Accepted -> Implemented`, with `Rejected` and `Superseded` as terminal states. Every transition must be recorded in this header ledger and repository history.

Acceptance requires exactly one of:

1. two maintainer approvals and no unresolved blocking objection; or
2. while the project has fewer than two maintainers, project-lead approval after a minimum seven-day public review window and no unresolved blocking objection; or
3. while the canonical roster contains exactly one unique maintainer and that identity has the `project-owner` role, `sole-project-owner-bootstrap` using the exact [sole-owner decision artifact](../governance/decisions/0001-sole-owner-bootstrap.md), completed and dispositioned `EDGE-GOV-01-UNCLASSIFIED` and `EDGE-GOV-02-UNCLASSIFIED` reviews, and no unresolved blocking objection.

Both single-maintainer routes expire as soon as the canonical roster contains more than one distinct maintainer. The sole-owner decision is conditional preauthorization consumed after the mandatory edge reviews pass; it does not create a later approval or claim a second approval or elapsed public-review time. A claim of acceptance must link the authentic route-specific evidence and objection disposition. Missing evidence fails closed: the status remains Proposed.

## 13. References

- [MNF RFC process](../governance/rfc-process.md)
- [MNF RFC index](README.md)
- MoonBit documentation: modules, packages, workspaces, supported targets, and publication
- MoonBit FFI documentation: native stubs, ABI, ownership, and reference counting
- Semantic Versioning 2.0.0
