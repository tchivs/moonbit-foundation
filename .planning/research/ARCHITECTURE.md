# Architecture Research: MoonBit Native Foundation

**Status:** Research recommendation for RFC 0001 and the v0.1 Foundation milestone  
**Date:** 2026-07-16  
**Scope:** Architecture, module boundaries, portability seams, data flow, release topology, and implementation order

## Executive recommendation

Build MNF as a **multi-module MoonBit workspace with a strict package-level dependency DAG**. Use one publishable MoonBit module per stable domain (`mb-core`, `mb-color`, `mb-image`, then later graphics and document modules), and several small packages inside each module for internal layering and optional features. Keep algorithms and data contracts in portable packages. Put OS access, native stubs, codecs backed by foreign libraries, GPU access, and other host facilities in leaf adapter packages that depend inward on portable contracts.

This aligns with MoonBit's actual build model: a module is the publication/versioning unit, while a package is the namespace and compilation unit. A `moon.work` workspace can coordinate multiple local modules, but publication remains module-by-module. MoonBit also enforces target compatibility across reachable package dependencies, which makes a clean adapter boundary mechanically testable rather than merely conventional.

The v0.1 architecture should therefore establish three independently publishable modules:

```text
mb-core  <--  mb-color  <--  mb-image
   ^             ^             |
   +-------------+-------------+

Allowed arrows point toward dependencies. No reverse imports.
```

Within those modules, public data contracts sit below optional algorithms and adapters. There should be no umbrella runtime package that all consumers must import.

## Evidence from the current MoonBit toolchain

The recommendations below are constrained by current official MoonBit behavior, not a language-agnostic monorepo pattern:

- A MoonBit **module** is a publishing unit containing multiple **packages**; a package is a namespace and compilation unit. Published module names must begin with the mooncakes.io username or organization namespace. This makes the unresolved registry namespace a release blocker, but not an implementation blocker. ([Modules](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html), [packages and publishing](https://docs.moonbitlang.com/en/stable/toolchain/moon/package-manage-tour.html))
- A `moon.work` file coordinates multiple modules, resolves workspace members locally, supports workspace-wide `check`, `test`, and `info`, and provides `moon work sync`; `publish` must still run from an individual member module. ([Workspace support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html))
- `supported-targets` may be declared at module and package level, with the effective set being their intersection. An omitted declaration means all backends are claimed. Reachable required dependencies are checked, so a portable package that accidentally imports a native-only package will fail on another selected backend. `--target all` currently covers `wasm`, `wasm-gc`, `js`, and `native`, but not `llvm`. ([Package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html))
- Per-file `targets` and package-level `native-stub` support allow target-specific code to be localized. Virtual packages can supply replaceable implementations, but explicit capability values are simpler for most I/O and automation APIs and should be the default. ([Package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html))
- C FFI carries real lifetime risk: the C and Wasm backends use reference counting for MoonBit objects, FFI ownership is expressed with `#borrow` and `#owned`, and the documentation says the default is migrating toward borrowed semantics. Payload struct/enum layout is currently unstable. FFI must therefore use narrow functions, scalar/byte inputs, and opaque external handles rather than treating MoonBit object layout as a stable ABI. ([MoonBit FFI](https://docs.moonbitlang.com/en/latest/language/ffi.html))

## Architectural layers and dependency direction

### Layer 0: contracts and bounded primitives

`mb-core` owns only concepts that every upper layer can use without learning a graphics or document vocabulary:

- checked sizes, offsets, ranges, dimensions, and arithmetic;
- byte storage and read-only/mutable views;
- sequential reader/writer and optional seek contracts;
- bounded readers, writers, allocation budgets, recursion/decompression limits;
- structured errors and non-fatal diagnostics;
- cancellation/deadline capability contracts;
- logging/event sink interfaces with no global logger requirement.

The base packages must be portable. Concrete filesystem, process, clock, memory-map, or native-library adapters are leaf packages and may be native-only. `mb-core` must not become a miscellaneous utility drawer: a primitive belongs here only if at least two independent higher domains need it and its semantics contain no domain-specific policy.

### Layer 1: color and raster data

`mb-color` depends only on portable `mb-core` packages. It owns:

- color-space and transfer-function identities;
- component and alpha conventions;
- conversions, adaptation, gamut and interpolation policy;
- profile-facing contracts and, when implemented, ICC parsing/evaluation.

It does not own image dimensions, row stride, pixel buffers, canvas paints, or CSS syntax. Keep low-level color values separate from format-specific syntax. CSS Color 4 explicitly covers multiple color spaces and premultiplied-alpha interpolation, while ICC.1 defines a profile architecture and format; those are independent concerns and should not be collapsed into a single `Color` convenience type. ([CSS Color 4](https://www.w3.org/TR/css-color-4/), [ICC.1:2022](https://www.color.org/specifications/ICC.1-2022-05.pdf))

`mb-image` depends on `mb-core` and `mb-color`. It owns:

- dimensions, pixel/channel format descriptors, planes, stride, orientation, and metadata;
- owned storage and safe logical views;
- crop, transform, resample, and pixel conversion operations;
- codec contracts, probing outcomes, frame/animation metadata, and decode/encode options.

Codec implementations should be separate packages. A pure MoonBit reference codec may live in the `mb-image` module initially; large, native-backed, independently versioned, or license-sensitive codecs should become separate modules that depend on `mb-image` contracts. `mb-image` itself must never require every codec.

### Layer 2: drawing and text primitives

After foundation contracts stabilize:

- `mb-canvas` depends on `mb-core`, `mb-color`, and `mb-image`; it owns geometry, paths, transforms, paints, clips, blending, command recording, and CPU reference rasterization contracts.
- `mb-font` depends on `mb-core` and may depend on `mb-color` only for color-font payloads; font parsing must not depend on canvas or layout.
- `mb-text` depends on `mb-core` and `mb-font`; it owns Unicode/script/bidi/shaping-facing runs, not paragraphs or widgets.
- `mb-layout` depends on `mb-text` and `mb-font`; it owns line breaking and block layout, not font parsing or rendering devices.

An optional shared scene/paint contract may be extracted only after two real consumers demonstrate identical semantics. Do not create a speculative `mb-graphics-common` module in v0.1.

### Layer 3: document and scene formats

- `mb-svg` depends on lower graphics/text contracts. It owns SVG/XML syntax, typed DOM, style resolution, resource resolution policy, and conversion to render commands. Its DOM is not the canvas display list: SVG 2 distinguishes the document model from the rendering tree, so preserving that separation avoids corrupting authoring semantics to fit a renderer. ([SVG 2 rendering model](https://www.w3.org/TR/SVG2/render.html))
- `mb-pdf` depends on core, image, color, font/text, and canvas-level contracts. Internally separate object parsing, cross-reference resolution, filters, document model, generation, content interpretation, and rendering orchestration. ISO 32000 explicitly describes readers, writers, interactive processors, and other processors as distinct product roles; MNF packages should allow parsing-only and generation-only consumers without pulling in rendering. ([ISO 32000-2 overview](https://pdfa.org/resource/iso-32000-2/))

### Layer 4: optional integrations

`mb-effects`, `mb-gpu`, `mb-ai`, and `mb-mcp` are consumers of stable lower contracts. GPU and AI adapters must not redefine canonical image/color storage. CPU behavior remains the reference for correctness. MCP exposes application-selected operations; it does not become a dependency of document or graphics libraries.

## Recommended repository topology

Use a coordinated multi-module workspace from the start, because module boundaries are the release boundaries MNF intends to validate:

```text
moonbit-foundation/
├── moon.work
├── docs/
│   ├── rfcs/
│   └── architecture/
├── fixtures/                 # licensing manifest + shared external corpora metadata
├── tools/                    # workspace-only validation/generation tools
└── modules/
    ├── mb-core/
    │   ├── moon.mod
    │   ├── bytes/
    │   ├── io/
    │   ├── limits/
    │   ├── diagnostics/
    │   └── host/native/      # explicitly native-only leaf adapter
    ├── mb-color/
    │   ├── moon.mod
    │   ├── model/
    │   ├── convert/
    │   └── icc/              # staged; no dependency on mb-image
    └── mb-image/
        ├── moon.mod
        ├── model/
        ├── view/
        ├── transform/
        ├── codec/
        └── codecs/reference/
```

Exact package names should be confirmed by implementation spikes, but the direction is fixed. Each directory containing a package has its own `moon.pkg`. Module manifests declare only cross-module dependencies; package manifests declare exact package imports.

Do not set a restrictive module-level `supported-targets` on a mixed portable/native module, because the intersection would make its portable packages native-only. Declare target support explicitly on every public package, use per-file `targets` sparingly, and put substantial target differences into separate packages. CI should treat a missing target declaration on a public package as an error even though MoonBit interprets it as support for all targets.

## Portability seams

### Capability injection first

Portable parsers and algorithms receive explicit capabilities:

```text
Reader / Writer / Seeker
ResourceResolver
AllocationBudget / DecodeLimits
Cancellation
DiagnosticSink
```

A parser consumes `Reader`; it never opens a path. A renderer receives decoded resources or a `ResourceResolver`; it never performs hidden network or filesystem access. A CLI or application chooses native, browser, in-memory, or sandbox adapters at the composition root.

Use MoonBit virtual packages only when one build must replace a package implementation globally and explicit injection would be unreasonably pervasive. Avoid making virtual-package override selection part of basic library use; explicit values are more deterministic for tests, MCP tools, and concurrent operations.

### Target-specific leaf packages

The portable contract package must not import its implementation. Adapters depend inward:

```text
mb-core/io             <--- mb-core/host/native-file
mb-image/codec         <--- mb-image-codec-system
mb-canvas/device       <--- mb-gpu/backend-...
mb-ai/contracts        <--- runtime-specific inference adapter
```

Native stub packages declare `supported-targets = native` and own their C files. Wrappers must document ownership, lifetime, threading, error mapping, and ABI assumptions. Do not pass MoonBit payload structs/enums through C. Prefer scalars, `Bytes` under an explicit ownership attribute, and opaque `#external` handles with one clear destroy path.

### Determinism boundary

Clock, randomness, locale, platform font discovery, and floating-point/backend variance are host capabilities or explicitly documented policies. Core transforms must not read ambient state. Golden rendering fixtures record backend, precision, tolerance, and color-space assumptions rather than asserting unexplained byte identity across all targets.

## Canonical data flow

All document/media paths should share the same staged shape:

```text
Host adapter
    │ Bytes / Reader + explicit limits
    ▼
Probe / bounded syntax parser
    │ typed syntax + diagnostics
    ▼
Validated semantic model
    │ resolved resources through injected capability
    ▼
Domain operations / immutable command stream
    │ explicit color, alpha, transform, clipping semantics
    ▼
CPU renderer or optional device adapter
    │ Image / frame / document objects
    ▼
Encoder / Writer
    │
    ▼
Host adapter
```

Important invariants:

1. Probe is non-destructive or reports bytes consumed; format sniffing has a strict byte limit.
2. Syntax parsing does not render, allocate from untrusted dimensions unchecked, or open resources.
3. Validation produces checked offsets, sizes, recursion depth, and decompression budgets before expensive work.
4. Semantic models preserve format information needed for round-trip/generation; renderer-specific caches are separate.
5. Color space, alpha representation, channel order, endianness, row stride, and ownership are explicit at every raster boundary.
6. A read-only view retains or is otherwise safely tied to its storage; no API exposes a dangling FFI pointer or relies on undocumented aliasing.
7. Diagnostics are structured data separate from fatal/recoverable errors, allowing CLI, IDE, and MCP consumers to present them differently.
8. Encoders write to `Writer` and can operate without filesystem access.

## Release topology and compatibility

### Independent modules, coordinated compatibility

Each domain module owns its version and changelog. Do not force lockstep versions merely because `moon work sync` can align workspace references. Release lower modules first, then update and publish dependants in topological order:

```text
mb-core -> mb-color -> mb-image -> mb-canvas/font/text -> mb-svg/pdf -> integrations
```

Workspace resolution ignores the dependency version for another member, which is convenient during development but can hide registry incompatibilities. Therefore every release candidate needs two CI views:

1. **workspace CI:** check/test/bench the whole `moon.work` graph on the declared matrix;
2. **registry-resolution CI:** test a clean consumer graph using published/staged module versions rather than workspace substitution.

Before publication, run module-local packaging and inspect its contents (`moon package --list`). Publish each module from its member directory. Record a compatibility manifest in the repository/docs that lists the exact module versions tested together; it is evidence, not a new runtime dependency.

### Version policy

Use SemVer per published module. During `0.y.z`, label stable-candidate packages and experimental APIs explicitly; do not imply that every `0.x` change is compatible. Once a module declares `1.0.0`, its documented public API becomes the compatibility contract. Released artifacts are immutable, as required by SemVer. ([Semantic Versioning 2.0.0](https://semver.org/))

A breaking lower-layer release triggers compatibility qualification of all direct dependants before their next release. It does not require an immediate lockstep version bump for unchanged upper modules, but the compatibility manifest must not claim an untested pair.

### Optional-feature isolation

MoonBit dependency selection occurs at module/package boundaries rather than a Cargo-style feature system. Optional heavy capabilities should therefore be separate packages or modules, not boolean switches that mutate the behavior of a core package. Consumers import only the codec, renderer, or host adapter they need.

## Build order

The horizontal dependency graph requires foundation-first implementation, but work can proceed in parallel after contracts are pinned.

### Stage 0: governance and reproducibility

1. Accept RFC 0001 or record blocking decisions.
2. Decide registry namespace and license.
3. Create `moon.work` and three module manifests with explicit package target declarations.
4. Establish formatting, `moon check`, tests, docs, package-content inspection, and target-matrix CI.
5. Add an architecture test/lint that rejects forbidden imports and missing public-package target metadata.

### Stage 1: `mb-core` contract spine

1. Checked sizes/offsets/ranges and structured errors.
2. Byte storage and safe views.
3. Reader/writer/seek contracts plus bounded wrappers.
4. Resource limits, cancellation, diagnostics.
5. In-memory reference implementations across portable targets.
6. Native file adapter as a leaf package, with FFI audit tests if a stub is needed.

Exit before upper-layer stabilization: property tests for bounds and stream behavior pass on every claimed target; native adapters are not imported by portable packages.

### Stage 2: `mb-color`

1. Color-space IDs, component/alpha conventions, transfer functions.
2. Reference conversions with published vectors and stated tolerances.
3. Premultiplication/interpolation policy.
4. ICC contracts, then bounded profile parsing only if milestone capacity permits.

Color work can begin once checked numeric and diagnostics contracts are stable; it need not wait for native file I/O.

### Stage 3: `mb-image`

1. Dimensions, pixel/plane/stride descriptors and owned storage.
2. Read-only/mutable view rules.
3. Pixel/color conversion and transform contracts.
4. Codec interface and bounded probe/decode options.
5. One minimal pure MoonBit reference codec or fixture adapter.
6. Cross-target conformance and benchmark baselines.

Image model design may start in parallel with color conversions, but its public API stabilizes only after alpha and color-space contracts are validated.

### Stage 4: qualification and release

1. Run workspace target matrix (`native`, `wasm`, `wasm-gc`, `js` as actually claimed; keep LLVM experimental and separate).
2. Run adversarial limit, property, conformance, and differential tests.
3. Generate API docs and runnable examples per public package.
4. Inspect packaged contents and test clean registry resolution.
5. Publish `mb-core`, then `mb-color`, then `mb-image`.
6. Record the tested compatibility set and baseline toolchain.

Only after these exits should canvas/font/text implementation begin. Their interface exploration may occur earlier in non-stable spike packages to validate whether foundation contracts are sufficient.

## Architecture enforcement

Documented rules need executable checks:

- Parse `moon.mod`/`moon.pkg` metadata in CI and reject dependency edges that point upward or form cycles.
- Require an explicit `supported-targets` expression for every public package.
- Run `moon check --target all` and `moon test --target all` at workspace root, supplemented by explicit LLVM experiments rather than treating `all` as including LLVM.
- Test portable packages without native stub files present in their reachable graph.
- Produce a dependency report (`moon tree` plus a normalized checked-in or CI artifact) for every release.
- Keep conformance fixtures versioned with provenance, license, expected result, resource limits, and tolerance metadata.
- Treat C stub additions and ownership-attribute changes as security/reliability review triggers.

## Anti-patterns to reject

1. **Single mega-module marketed as modular.** Packages help compile-time separation, but a single module still couples publication and versioning for unrelated domains.
2. **Umbrella imports.** `mnf/all` or a prelude that imports every domain defeats independent adoption and target portability.
3. **Native code below portable contracts.** If `mb-core/io` imports a native filesystem package, every parser becomes native by reachability.
4. **Omitted target metadata.** MoonBit interprets omission as all targets; that is an unsupported compatibility claim, not a neutral default.
5. **Per-file conditionals as the architecture.** Small target shims are acceptable; substantially different implementations belong in distinct packages.
6. **FFI as public object model.** Exposing unstable struct/enum layouts or undocumented RC ownership creates an ABI and memory-safety trap.
7. **Parser opens files, URLs, fonts, or images itself.** This prevents sandboxing, deterministic tests, browser use, and Agent/MCP control.
8. **Parsing equals rendering.** It makes generation-only use heavy, loses source semantics, and turns malformed-input recovery into renderer behavior.
9. **One universal `Color` or `Image` with implicit metadata.** Hidden alpha, color-space, stride, orientation, or ownership assumptions guarantee cross-module bugs.
10. **Global registries and ambient defaults.** Global codecs, fonts, loggers, locale, or device state make concurrent and automated use nondeterministic.
11. **Format-specific types in lower layers.** CSS colors, SVG nodes, PDF objects, and codec chunks stay in their owning modules; lower layers expose neutral contracts only.
12. **GPU output as the correctness oracle.** CPU reference behavior and tolerance-defined fixtures remain authoritative; accelerators are optional implementations.
13. **Workspace-only compatibility testing.** Local member substitution can hide stale or impossible published dependency constraints.
14. **Lockstep versioning by convenience.** Coordinated testing is necessary; identical version numbers across independently evolving domains are not.
15. **Premature common abstractions.** Do not extract scene, geometry, storage, or plugin frameworks until multiple implemented consumers demonstrate the same semantics.

## Decisions to carry into planning

The following should be treated as architecture decisions for v0.1:

| Decision | Recommendation | Planning consequence |
|---|---|---|
| Repository form | One `moon.work`, multiple publishable member modules | Scaffold module boundaries before implementation |
| v0.1 modules | `mb-core`, `mb-color`, `mb-image` | Publish and version independently |
| Portability | Explicit targets on every public package | Add metadata lint and per-target CI |
| Host access | Injected capability contracts; adapters are leaf packages | Parsers never open paths or URLs |
| FFI | Narrow native-only wrappers with audited ownership | No public FFI-shaped object model |
| Codecs | Interface in `mb-image`; implementations in optional packages/modules | Reference codec first; no mandatory codec bundle |
| Compatibility | Workspace CI plus registry-resolution CI | Release in dependency order |
| Correctness | CPU reference algorithms plus standards-based fixtures | GPU/FFI paths differential-test against reference |
| Higher layers | Define boundaries now, implement after foundation exits | Spikes allowed; no stable API commitment yet |

## Open architecture questions

These require explicit resolution before first public publication:

1. What mooncakes.io organization/namespace owns the modules?
2. Does `mb-core` include native leaf adapter packages in the same published module for v0.1, or should host adapters be a fourth module? Start together for simplicity; split if native dependencies or cadence diverge.
3. What exact target set does each v0.1 package claim? “Native first” does not imply every algorithm package should be native-only.
4. What numeric precision and tolerance contract governs color conversion and resampling across backends?
5. Which reference codec and conformance fixtures have redistribution-compatible licenses?
6. Are borrowed image views represented by retained backing storage, copy-on-write handles, or a more restrictive callback API? Validate against MoonBit ergonomics before stabilizing.
7. Which RFC governs the future shared render-command/scene contract used by canvas, SVG, and PDF?

None of these questions justifies collapsing the initial module boundaries. They should be settled through targeted spikes and follow-up RFCs while the dependency direction remains fixed.

