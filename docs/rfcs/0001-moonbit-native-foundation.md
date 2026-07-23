# RFC 0001: MoonBit Native Foundation

- **Status:** Proposed
- **Authors:** MNF contributors
- **Created:** 2026-07-16
- **Target:** Foundation charter and v0.1 architecture
- **Discussion:** To be established
- **Normative process:** [RFC process](../governance/rfc-process.md)

> **Note on governance history.** This RFC was originally `Accepted` on 2026-07-17 via the `sole-project-owner-bootstrap` route (see [Decision 0001](../governance/decisions/0001-sole-owner-bootstrap.md) for the historical record). On 2026-07-23 the project owner simplified the RFC process: the acceptance machinery (authority routes, seven-day public-review windows, mandatory edge reviews, maintainer approvals) was removed as disproportionate for a sole-owner project. The lifecycle is now `Draft -> Proposed`, with a Proposed RFC sufficient to proceed (see §11 and the [RFC process](../governance/rfc-process.md)). This RFC's status returns to `Proposed` under the simplified process; it remains the in-force foundation charter. The original acceptance evidence is retained as a historical record, not as a live authority route.

## Transition history

| From | To | Evidence |
|---|---|---|
| — | Draft | Initial RFC in repository history |
| Draft | Proposed | This revision makes the charter reviewable; repository history is the transition record |
| Proposed | Accepted | Historical (2026-07-17): docs/governance/decisions/0001-sole-owner-bootstrap.md — superseded by the row below |
| Accepted | Proposed | 2026-07-23 governance simplification: the acceptance machinery was removed from the RFC process; this RFC returns to Proposed as the in-force foundation charter under the simplified lifecycle |

Under the simplified process the lifecycle is `Draft -> Proposed`. A transition to `Superseded` (by a replacement RFC) or `Rejected` remains available. The intermediate historical `Accepted` state is retained in this ledger as an accurate record but is no longer a live status in the process.

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
- **Candidate API:** A v0.1 public API under qualification; it is not yet stable and follows the executable four-class compatibility and version policy.

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
tchivs/mb-color -> tchivs/mb-core
tchivs/mb-image -> tchivs/mb-color
tchivs/mb-image -> tchivs/mb-core
```

No reverse edge, self-edge, cycle, or undeclared public edge is permitted.

## 6. Module boundaries

### 6.1 `tchivs/mb-core`

Owns checked arithmetic and ranges, byte containers and validated views, bounded readers and writers, backend-neutral stream behavior, structured errors and diagnostics, resource budgets, and explicit host-capability boundaries. It does not own color, image, codec, SVG, font, PDF, GUI, or application concepts. It depends on no other MNF module.

### 6.2 `tchivs/mb-color`

Owns component representations, color-space identity, transfer functions, deterministic reference conversions, alpha conventions, and bounded profile identity or opaque metadata seams. It does not own image storage, pixel layout, codec selection, rendering, or host I/O. It depends only on `mb-core`.

### 6.3 `tchivs/mb-image`

Owns image dimensions and descriptions, pixel and plane layout, stride and endianness, owned storage and validated immutable or mutable views, metadata behavior, deterministic foundational transforms, and codec-facing contracts. It does not own filesystem policy, a global codec registry, GUI state, document models, or system codec implementations. It depends on `mb-core` and `mb-color`.

### 6.4 Deferred layers

`mb-canvas`, `mb-svg`, `mb-font`, `mb-text`, `mb-layout`, `mb-pdf`, `mb-effects`, `mb-gpu`, `mb-ai`, and `mb-mcp` retain the responsibilities shown by the architecture, but their implementations are outside v0.1. They may consume accepted lower-layer contracts; they may not redefine them through implementation alone.

## 7. Repository and publication model

The initial implementation uses one repository and one MoonBit workspace for coordinated contract changes. `mb-core`, `mb-color`, and `mb-image` remain separate modules with their own manifest, version, changelog, documentation, tests, and publication lifecycle. The monorepo is a coordination mechanism, not a consumer dependency or a promise of lockstep versions.

The initial registry identities use the sole maintainer's personal `tchivs` namespace. This operational owner does not rename MoonBit Native Foundation. Because no module was published under the superseded bootstrap owner, the correction retains candidate version `0.1.0` without a migration note. `https://github.com/tchivs/moonbit-foundation` is intended repository metadata and must not be described as live until a read-only existence check proves it.

A future organization namespace would create new module identities and requires an explicit forward migration and publication plan. This charter does not assume that the registry supports rename, transfer, overwrite, delete, unpublish, or yank operations.

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

v0.1 packages begin as candidate unless explicitly marked experimental. Stable APIs follow Semantic Versioning. Experimental APIs carry no compatibility promise. For pre-1.0 candidates, exact changes are patch-eligible, additive public surface requires a minor release, and incompatible change requires a minor release plus a migration note. RFC evidence is additionally required only for boundary, architecture, or governance impact. Detailed executable policy is maintained separately, but it cannot override this charter's architecture or governance gate.

## 11. Governance and RFC-required changes

The normative lifecycle and transition rules are defined by the [RFC process](../governance/rfc-process.md). The [RFC index](README.md) is the discoverable list of proposals and their current status.

A Proposed RFC is required before any of the following may merge:

- creation of a new MNF module;
- addition, removal, or reversal of a public module dependency direction;
- a breaking change to an established architectural layer, module responsibility, portability seam, governance rule, or other public boundary.

Implementation PRs may refine internals within an established boundary, but they MUST NOT silently redefine that boundary. If implementation exposes a conflict with this charter, the change pauses until an RFC explicitly resolves it.

## 12. Lifecycle

The lifecycle is `Draft -> Proposed`. A Proposed RFC is reviewable and sufficient to proceed with implementation. `Rejected` and `Superseded` are terminal states available when a proposal is withdrawn or replaced by another RFC.

Every transition must be recorded in the RFC header's transition ledger and repository history. The [RFC process](../governance/rfc-process.md) defines the transition mechanics.

> **Historical note.** This section previously defined a `Draft -> Proposed -> Accepted -> Implemented` lifecycle with three acceptance authority routes (maintainer approval, project-lead public review, and sole-project-owner bootstrap). That machinery was removed on 2026-07-23 as disproportionate for a sole-owner project. The original acceptance records are retained in [Decision 0001](../governance/decisions/0001-sole-owner-bootstrap.md) and the edge-review files as historical artifacts.

## 13. References

- [MNF RFC process](../governance/rfc-process.md)
- [MNF RFC index](README.md)
- MoonBit documentation: modules, packages, workspaces, supported targets, and publication
- MoonBit FFI documentation: native stubs, ABI, ownership, and reference counting
- Semantic Versioning 2.0.0
