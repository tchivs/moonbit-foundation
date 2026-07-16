# RFC 0001: MoonBit Native Foundation

- **Status:** Draft
- **Authors:** MNF contributors
- **Created:** 2026-07-16
- **Target:** Foundation charter and v0.1 architecture
- **Discussion:** To be established

## Abstract

MoonBit Native Foundation (MNF) is a coordinated ecosystem of native-first, composable infrastructure modules for MoonBit. It addresses foundational gaps that otherwise force every graphics, document, media, AI, and system-oriented project to recreate byte handling, image models, color conversion, drawing, text, file-format, and automation primitives.

This RFC defines MNF's purpose, architectural layers, module boundaries, dependency direction, portability model, API principles, quality gates, and staged delivery. It deliberately does not standardize an application, GUI framework, or engine.

## 1. Motivation

MoonBit applications can target native, WebAssembly, WebAssembly GC, and JavaScript environments, but sophisticated creative and document software needs more than a compiler backend. It needs shared data contracts, well-tested algorithms, predictable I/O boundaries, interoperable representations, and reusable format implementations.

Without a coordinated foundation:

- projects invent incompatible pixel, color, path, font, and stream types;
- format parsers cannot share diagnostics, allocation limits, or I/O abstractions;
- native integrations leak into otherwise portable packages;
- performance work is repeated and benchmark results are hard to compare;
- downstream tools couple themselves to a GUI or host runtime;
- AI and automation consumers receive APIs designed only for interactive applications.

MNF exists to make the reusable layer a first-class product.

## 2. Vision

MNF should become the default MoonBit-native substrate for building:

- image and PDF tools;
- SVG editors and whiteboards;
- OCR and AI image-processing pipelines;
- CLI utilities and MCP servers;
- IDE extensions and desktop applications;
- browser and standalone WebAssembly software.

Success means that independently built MoonBit products exchange data through MNF contracts and reuse MNF modules without inheriting an application framework.

## 3. Goals

1. Define coherent, versioned contracts for graphics, documents, media, and related system primitives.
2. Implement core algorithms in MoonBit wherever practical.
3. Deliver high-performance Native support while keeping portable packages portable.
4. Publish modules that are independently useful, documented, tested, and releasable.
5. Make deterministic headless use cases as natural as interactive ones.
6. Establish conformance, security, resource-limit, and benchmark practices suitable for parsing untrusted documents and media.
7. Give contributors an RFC path for extending the ecosystem without dissolving its boundaries.

## 4. Non-goals

MNF does not directly build Photoshop, Figma, Office, a GUI toolkit, a game engine, or a single all-in-one creative application. It does not promise that every package supports every MoonBit target. It also does not prohibit all foreign code: narrow adapters are acceptable where operating systems, codecs, devices, or mature native libraries make them necessary.

## 5. Principles

### 5.1 Pure MoonBit by default

Data models, parsers, transforms, raster operations, layout algorithms, and other reusable logic should be implemented in MoonBit unless a documented technical constraint justifies an adapter. Foreign code must not become the de facto public API.

### 5.2 Native first, portability explicit

Native is the primary target for system access and performance validation. Each package declares its supported targets. Portable algorithms should be separated from host capabilities so `wasm`, `wasm-gc`, and `js` builds can reuse them.

### 5.3 Modular and acyclic

Each module has one dominant responsibility and a small public surface. Dependency direction follows the architecture layers. Cycles between public modules are prohibited.

### 5.4 Runtime neutrality

Core packages do not require a particular windowing system, browser API, game engine, event loop, or AI framework.

### 5.5 Automation first

APIs expose deterministic operations, structured errors, explicit resource limits, and serializable options. Hidden global state and mandatory UI interaction are rejected.

### 5.6 Evidence over claims

Correctness comes from conformance fixtures and differential tests. Performance comes from reproducible benchmarks. Compatibility comes from a declared target matrix and CI, not slogans.

## 6. Architecture

```text
Applications and Integrations
├── IDE / CLI / Desktop / Wasm
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

The arrows represent allowed dependency direction. Lower layers never import document, integration, or application layers.

## 7. Module boundaries

### 7.1 `mb-core`

Owns shared byte containers, checked arithmetic helpers, stream and seek abstractions, bounded readers/writers, structured errors, diagnostics, logging interfaces, and capability boundaries for files or hosts. It does not own image, color, SVG, font, or PDF concepts.

### 7.2 `mb-color`

Owns color component types, transfer functions, color-space identifiers, conversion pipelines, alpha conventions, and ICC-facing contracts. It depends only on `mb-core`. Full ICC parsing may be staged after core conversions, but the boundary must not require image storage.

### 7.3 `mb-image`

Owns image dimensions, pixel formats, planes, row stride, owned and borrowed views, metadata, transforms, sampling, and codec interfaces. It depends on `mb-core` and `mb-color`. Individual codecs should be separate packages so users do not pay for formats they do not use.

### 7.4 `mb-canvas`

Owns paths, transforms, paints, blending, clipping, rasterization contracts, and drawing command semantics. It consumes image and color contracts but does not own windowing or event input.

### 7.5 `mb-font`, `mb-text`, and `mb-layout`

`mb-font` owns font containers and glyph access. `mb-text` owns shaping-facing text runs and bidi/script boundaries. `mb-layout` owns line and block layout. Their separation prevents font parsing from depending on a UI layout model.

### 7.6 `mb-svg`

Owns XML/SVG parsing, typed DOM, style resolution, resource references, and translation into scene or canvas operations. It must expose resource and recursion limits for untrusted inputs.

### 7.7 `mb-pdf`

Owns PDF object syntax, cross-reference handling, document model, generation, content interpretation, and rendering orchestration. Filters, fonts, images, and color reuse lower-layer contracts. Parsing and rendering are separable so generation-only consumers remain lightweight.

### 7.8 Planned modules

`mb-effects` provides reusable filters and compositing effects. `mb-gpu` provides an optional device abstraction without replacing CPU reference behavior. `mb-ai` defines tensor/model integration boundaries rather than embedding one inference runtime. `mb-mcp` maps deterministic operations to discoverable tool contracts.

## 8. Repository and publication model

The initial implementation uses one coordinated repository and MoonBit workspace to make cross-module contract changes reviewable. Each publishable unit must have:

- an explicit module/package identity;
- a minimal dependency set;
- a supported-target declaration;
- public API documentation and examples;
- its own changelog and Semantic Versioning lifecycle;
- conformance tests and, where relevant, benchmarks.

The monorepo is an implementation convenience, not a requirement that consumers install every module. Splitting repositories remains possible after dependency and release boundaries stabilize.

## 9. Portability and native integration

MNF distinguishes three kinds of package:

1. **Portable:** pure computation and data contracts tested across supported non-experimental targets.
2. **Host-adapted:** portable core plus target-specific I/O or environment adapters.
3. **Native-only:** packages whose purpose requires native libraries or OS facilities.

Native FFI and stub packages must document ownership, lifetime, thread, error, and build assumptions. Unsafe size conversions and unchecked lengths at FFI boundaries are prohibited. LLVM support remains experimental until MoonBit's toolchain and FFI story make it testable for the relevant package.

## 10. API design rules

- Use explicit result/error types for recoverable failures.
- Make resource limits configurable and safe by default.
- Separate owned storage from views and borrowed access.
- State alpha representation, channel order, endianness, stride, and color space in image contracts.
- Avoid ambient mutable global state.
- Prefer builders or option records when operations have many parameters.
- Keep parsing separate from rendering and filesystem access.
- Permit streaming for inputs that need not be fully buffered.
- Make deterministic behavior the default; document platform-dependent behavior.
- Stabilize small interfaces before exposing convenience layers.

## 11. Security and robustness

Image, font, SVG, and PDF inputs are frequently untrusted. Packages that parse them must support bounded allocation, checked dimensions and offsets, recursion/decompression limits, cancellation where practical, and structured failure without process termination. Fuzzing and corpus testing should be added as the toolchain permits; until then, property tests, adversarial fixtures, differential tests, and strict limit tests are required.

## 12. Quality contract

A module is not stable until it has:

- formatting and static checks passing;
- unit, property, and conformance tests appropriate to the domain;
- a declared target matrix validated in CI;
- public API docs and runnable examples;
- benchmark baselines for performance-sensitive operations;
- compatibility and breaking-change policy;
- no undocumented dependency on a host runtime;
- a security/resource-limit review for untrusted input paths.

## 13. Delivery roadmap

### Program 1: Foundation

Define the RFC and implement `mb-core`, `mb-color`, and `mb-image`. The exit condition is a coherent data model and portable/native quality harness, not merely package skeletons.

### Program 2: Graphics

Implement `mb-canvas`, `mb-font`, `mb-text`, `mb-layout`, and `mb-svg` on validated foundation contracts. The exit condition is a headless 2D reference pipeline with reproducible rendering fixtures.

### Program 3: Documents

Implement `mb-pdf`, additional codecs, and advanced text/document behavior. The exit condition is safe parsing, generation, and reference rendering for representative documents.

### Program 4: Advanced

Evaluate GPU acceleration, AI inference adapters, MCP integration, and Wasm-specific optimization. Each capability remains optional and cannot redefine lower-layer contracts without an RFC.

## 14. Initial milestone: v0.1 Foundation

The first milestone delivers:

1. an accepted foundation charter and contribution/RFC process;
2. a reproducible MoonBit workspace and target-aware CI contract;
3. stable candidate contracts for bounded byte/stream handling and structured diagnostics;
4. color primitives and verified conversion behavior;
5. image storage/views, transforms, and a codec interface with at least one minimal reference codec or fixture adapter;
6. documentation, examples, conformance fixtures, and benchmark baselines.

Canvas, SVG, font, text layout, PDF, GPU, AI, and MCP implementation are explicitly deferred from v0.1.

## 15. Open questions

- Which organization/namespace will own published modules on mooncakes.io?
- Should v0.1 publish one module with multiple packages or several modules released together?
- Which minimum MoonBit toolchain version becomes the first compatibility floor?
- Which color and image standards/corpora can be redistributed in conformance fixtures?
- What governance threshold changes an RFC from Draft to Accepted?
- Which license best balances ecosystem adoption and contributor expectations?

## 16. Acceptance

This RFC is accepted when maintainers agree on the architecture, v0.1 boundaries, target policy, RFC process, and publication strategy, and when every unresolved item that blocks implementation has either a decision or an explicitly assigned follow-up RFC.

## 17. References

- MoonBit documentation: multi-backend toolchain and target model
- MoonBit FFI documentation: C backend, native stubs, ABI, and ownership rules
- Moon build-system documentation: modules, packages, workspaces, tests, and publication
- Semantic Versioning 2.0.0
