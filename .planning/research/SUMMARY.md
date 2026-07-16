# Research Summary: MoonBit Native Foundation v0.1

**Research date:** 2026-07-16  
**Inputs:** `STACK.md`, `FEATURES.md`, `ARCHITECTURE.md`, `PITFALLS.md`  
**Planning lens:** coarse horizontal-layer roadmap for the v0.1 Foundation milestone

## Executive summary

The four research tracks converge on one central conclusion: MNF v0.1 should be a **contract-and-conformance milestone**, not a format-count or application-demo milestone. Its product is a small, independently consumable MoonBit foundation whose byte, stream, error, resource-limit, color, alpha, pixel-layout, storage, view, transform, and codec contracts are explicit enough that later graphics and document modules do not need to reinterpret them.

The recommended implementation shape is a coordinated MoonBit workspace with independently publishable `mb-core`, `mb-color`, and `mb-image` domains and a strict dependency DAG:

```text
mb-core <- mb-color
   ^          ^
   +------ mb-image
```

Portable algorithms and data models should run the same behavioral tests on every target they claim. Host access, native stubs, system codecs, GPU resources, and other foreign facilities should be optional leaf adapters that depend inward on portable contracts. Native remains the primary development and performance target, but “Native first” must not turn otherwise portable packages into Native-only packages.

The roadmap should therefore proceed horizontally: first governance and reproducibility, then the `mb-core` safety spine, then explicit color semantics, then validated image representation and operations, and finally an end-to-end reference codec plus release qualification. A strict bounded PPM P6 path and small Native/in-memory consumer examples are vertical proofs inside that horizontal plan; they are not reasons to expand v0.1 into production codecs, canvas, SVG, fonts, PDF, GPU, AI, or MCP.

The greatest delivery risk is premature stability: publishing plausible but underspecified low-level APIs would force every later MNF module either to preserve mistakes or fork core concepts. Exit gates must therefore emphasize checked behavior, explicit representation, resource bounds, cross-target conformance, independent consumption, documentation, and reproducible evidence.

## Key findings

### 1. Product and scope

- **Verified project intent:** MNF is an RFC-led infrastructure ecosystem, not an application, GUI framework, game engine, or all-in-one library bundle.
- **Research consensus:** v0.1 should implement only `mb-core`, `mb-color`, and `mb-image`, plus repository, governance, documentation, conformance, and release machinery.
- **Research recommendation:** measure success by whether downstream-shaped consumers can reuse the contracts without translation, ambient host state, or unrelated dependencies—not by package count, codec count, or visual demos.
- **Explicit deferrals:** production PNG/JPEG/WebP and other codecs, ICC parsing/engine completeness, canvas, SVG, fonts/text/layout, PDF, effects, GPU, AI inference, MCP transport, GUI/windowing, and broad async/system frameworks.

### 2. Repository and publication topology

- **Verified MoonBit behavior:** a module is the publication/versioning unit; a package is a namespace and compilation unit; `moon.work` coordinates local modules while publication remains module-specific.
- **Strong recommendation from stack and architecture research:** begin with three workspace member modules so the intended release boundaries are exercised from day one.
- **Required dependency direction:** `mb-core` has no graphics/document dependencies; `mb-color` depends only on `mb-core`; `mb-image` depends on `mb-core` and `mb-color`. Codecs and host adapters remain opt-in leaves.
- **Release consequence:** qualify and release in dependency order (`mb-core`, `mb-color`, `mb-image`), while avoiding forced lockstep version numbers.
- **Important test consequence:** workspace substitution can hide invalid published dependency constraints, so release qualification needs both workspace CI and a clean registry-resolution/consumer view.

### 3. Toolchain, targets, and reproducibility

- **Verified local baseline on the research date:** `moon 0.1.20260713`, `moonc v0.10.4`, and `moonrun 0.1.20260713`.
- **Verified tool behavior:** `--target all` covers `wasm`, `wasm-gc`, `js`, and `native`, but not experimental LLVM.
- **Recommendation:** pin the exact v0.1 development/CI toolchain and record versions in build and release provenance; do not declare that snapshot as the permanent public minimum until release-candidate compatibility testing.
- **Recommendation:** require explicit `supported-targets` metadata for every public package. Omission is unsafe because MoonBit interprets it as supporting all targets.
- **Acceptance implication:** advertised portability requires identical behavioral/conformance tests on each claimed target, not only successful compilation. LLVM should remain an optional non-blocking experiment until meaningful support can be demonstrated.

### 4. `mb-core` is the safety and portability spine

The first stable candidate contracts should cover:

- checked add, multiply, align, cast, range, slice, offset, dimension, and allocation calculations;
- owned bytes plus validated read-only and mutable views;
- reader/writer contracts, exact and partial operations, optional seek as a separate capability, bounded sub-readers, and in-memory implementations;
- structured machine-readable errors and diagnostics with deterministic rendering;
- safe-by-default resource budgets for bytes, allocation, dimensions/pixels, nesting, and later parser/decompression work;
- explicit capability boundaries for filesystem, clock, cancellation, logging, resource resolution, and other host concerns.

No portable parser or algorithm should open a path, URL, or ambient host resource. Host adapters depend on these contracts; the contracts never import the adapters.

### 5. Color and image representations must be explicit

`mb-color` should begin narrowly with verified sRGB encoded/linear identities, transfer functions, conversion behavior, explicit component conventions, and distinct straight versus premultiplied alpha semantics. ICC-facing identifiers or opaque metadata hooks may be reserved, but a full ICC parser/engine is not part of v0.1.

`mb-image` must make dimensions, channel order, component type/depth, packed/planar form, plane count, stride, relevant endianness, color-space identity, alpha representation, orientation, ownership, and metadata preservation policy explicit. Public constructors must make invalid layouts impossible or return structured failure before access or allocation.

The research consistently rejects a universal image/color type with implicit canonicalization. Deterministic transforms and conversions should specify rounding and tolerances, and CPU reference algorithms should remain the correctness oracle for later optimized/native/GPU implementations.

### 6. End-to-end proof without premature breadth

The recommended vertical proof is a strict, bounded, test/reference-quality PPM P6 subset:

```text
bounded Reader -> codec interface -> validated Image
               -> view/transform/conversion
               -> codec interface -> Writer
```

This proves streams, limits, diagnostics, image construction, transforms, encoding, and malformed-input handling without taking on production PNG complexity. It should be paired with a Native CLI-shaped example and a fully in-memory portable example that use only public contracts.

### 7. Quality and release evidence are part of the product

Every stable public package needs runnable API documentation and examples, black-box API tests, internal invariant tests, conformance and adversarial fixtures, an explicit target matrix, compatibility/stability labels, a changelog, and an independently usable dependency surface. Parsing and conversion code also needs property/metamorphic, differential, known-vector, and resource-limit evidence where applicable.

Benchmarks should establish reproducible baselines for selected core operations. Early measurements are regression evidence, not marketing claims. Results must record toolchain, target, optimization mode, hardware/runtime, corpus, repetitions, variance, and correctness/resource assumptions.

## Concrete implications for a coarse horizontal-layer v0.1 roadmap

### Phase 1: Charter, decisions, and reproducible workspace

**Outcome:** implementation can begin without silently changing ecosystem boundaries.

- Resolve RFC 0001 acceptance mechanics, decision authority, stability labels, contribution/RFC lifecycle, and compatibility policy.
- Decide the license and mooncakes.io owner/namespace.
- Establish one `moon.work` with independently identifiable `mb-core`, `mb-color`, and `mb-image` members.
- Pin the development/CI toolchain; define the forward-compatibility lane and explicit target metadata policy.
- Establish formatting, check/test, API snapshot, docs/example, package-content, dependency-DAG, and target-matrix CI skeletons.
- Record whether v0.1 uses `moon.mod.json` or `moon.mod`; avoid mixing formats without a deliberate compatibility decision.

**Exit gate:** the repository is reproducible, the dependency direction is executable policy, target claims are explicit, and no governance/publication blocker is hidden.

### Phase 2: `mb-core` bounded primitives

**Outcome:** every later parser and raster operation has one portable safety model.

- Implement checked arithmetic/ranges and canonical byte/view validation.
- Implement structured errors/diagnostics and deterministic presentation.
- Implement reader/writer/seek capability contracts, bounded wrappers, and in-memory references.
- Implement resource budgets with safe defaults and limit-exceeded errors.
- Define capability-injection rules; add a Native file adapter only if it does not delay portable contracts.

**Exit gate:** boundary/property/negative tests pass on every claimed target; invalid ranges and budgets fail before access/allocation; portable packages have no native/ambient dependency.

### Phase 3: `mb-color` reference semantics

**Outcome:** later images, canvas, SVG, and PDF share one tested meaning of color and alpha.

- Define component, color-space, transfer-function, and alpha representations.
- Implement sRGB encoded/linear conversions and premultiply/unpremultiply semantics.
- Specify finite/range behavior, zero-alpha behavior, rounding, and cross-target tolerances.
- Add standards-derived or independently generated reference vectors and invariants.
- Reserve only the minimum profile/metadata boundary required by later codecs; defer ICC implementation.

**Exit gate:** the same vectors pass across claimed targets within documented tolerances, and no public image representation needs to guess color or alpha semantics.

### Phase 4: `mb-image` model, views, and deterministic operations

**Outcome:** consumers can safely create, share, inspect, and transform raster data without hidden layout policy.

- Implement validated dimensions, pixel/plane/layout descriptors, owned storage, and safe immutable/mutable views.
- Define crop/view lifetime rules and centralize stride/plane/last-byte validation.
- Implement deterministic copy, flips/orientation, nearest-neighbor resize, and minimal required pixel conversions.
- Define metadata preservation and codec contracts separately from codec registry/policy.
- Use downstream-shaped spikes to test public ergonomics before candidate stabilization.

**Exit gate:** invalid layouts cannot be constructed publicly; views cannot escape backing storage or declared bounds; deterministic operations pass exact or tolerance-based cross-target fixtures.

### Phase 5: Reference codec, conformance kit, and release qualification

**Outcome:** the three modules form an adoptable, independently publishable v0.1 foundation.

- Implement the strict bounded PPM P6 reference adapter and malformed/oversized fixtures.
- Complete the Native CLI-shaped and portable in-memory public examples.
- Publish conformance helpers/fixtures with provenance, licensing, limits, and tolerances.
- Establish benchmark manifests and raw baselines for representative core operations.
- Run workspace and clean-consumer/registry-resolution qualification; inspect packaged contents.
- Generate docs/changelogs/support matrices, classify API maturity, and release in dependency order.

**Exit gate:** the complete bounded stream-to-image-to-transform-to-stream path works through public APIs; all claimed targets run the same conformance suite; each module can be consumed without deferred layers; release provenance and compatibility set are recorded.

## Phase ordering rationale

1. **Governance and repository policy come first** because namespace, publication unit, stability class, target claims, and toolchain pinning change what “public API” means. Deferring them would make early code accidentally normative.
2. **`mb-core` precedes domain models** because checked arithmetic, byte views, limits, diagnostics, and host capabilities are security and portability prerequisites for every later parser and image operation.
3. **Color stabilizes before image stabilization** because an image layout cannot be interoperable if color space, transfer function, and alpha meaning remain implicit. Color implementation can overlap late `mb-core` work after its numeric/error contracts settle.
4. **Image design may start early but stabilizes later** because dimensions/layout can be explored in parallel, while its public color/alpha/view contracts depend on Phases 2 and 3.
5. **The codec and consumer proofs come after the contracts** because their purpose is to falsify and refine those contracts. Shipping them earlier risks allowing a convenient PPM or CLI implementation to dictate general-purpose APIs.
6. **Qualification is a distinct final phase** because workspace builds alone can hide publication dependency problems, and cross-target checks alone do not prove behavioral portability.

## Phase-specific research flags

| Phase | Research flag | Why it must be resolved or validated |
|---|---|---|
| Phase 1 | mooncakes.io namespace and license | Blocks final module identities and public publication |
| Phase 1 | `moon.mod.json` versus `moon.mod` | Stack research favors JSON for rollout compatibility; architecture examples use the newer form |
| Phase 1 | exact setup-action/install mechanism | Toolchain versions are verified, but exact reproducible CI installation syntax still needs an implementation spike |
| Phase 1 | API maturity labels and RFC acceptance threshold | Prevents draft APIs becoming stable by accident |
| Phase 2 | resource-budget dimensions and cancellation semantics | Core limits are mandatory; cancellation/deadline breadth and public shape remain less settled |
| Phase 2 | native file adapter placement | Decide whether it remains a leaf package inside `mb-core` or becomes a separate module when dependency/cadence pressure is known |
| Phase 3 | numeric component types, rounding, and tolerances | Cross-backend color behavior cannot be qualified without a precise numeric contract |
| Phase 3 | redistributable color vectors | Standards may define behavior without granting convenient corpus redistribution |
| Phase 4 | safe borrowed/external-memory view model | Must be validated against actual MoonBit lifetime/GC ergonomics rather than imported Rust terminology |
| Phase 4 | zero-size, negative-stride, planar overlap, and metadata policies | These edge semantics affect every future codec and rendering consumer |
| Phase 5 | exact strict PPM subset and color interpretation | Research recommends single-image P6/maxval 255, but grammar leniency and explicit sRGB fixture semantics need a written decision |
| Phase 5 | registry-resolution test mechanism | Workspace substitution is known to mask dependency constraints; the clean-consumer procedure must be proven |
| Later | SVG/font/text/PDF standards and corpus research | Current risk guidance is strong, but detailed implementation design is intentionally deferred |

## Preserved disagreements and decision points

1. **Publication granularity:** stack and architecture research recommend three independently publishable modules from day one. Feature research allows a documented interim single-module/multi-package layout as a fallback and lists granularity as an open decision. Planning should adopt three modules unless an implementation spike reveals a concrete registry/tooling blocker; a fallback must include an explicit split plan and preserve the DAG.
2. **Manifest format:** stack research recommends `moon.mod.json` during v0.1 because the newer format appears rollout-sensitive in the verified toolchain. Architecture examples use `moon.mod`. This is not an architectural disagreement, but it is a reproducibility choice that must be settled in Phase 1 and revisited at the release candidate.
3. **Cancellation and work budgets:** architecture includes cancellation/deadline capabilities in the core model, while feature research lists a cooperative cancellation hook as “should ship if capacity remains.” The common bounded resource model is mandatory; cancellation should be researched and shaped now, but may remain experimental if MoonBit ergonomics or schedule do not support a stable v0.1 contract.
4. **Borrowed image views:** all research agrees views are necessary and must be safe, but the representation is unresolved: retained backing storage, copy-on-write ownership, external-memory discipline, or a more restrictive callback-style API. No Rust-like lifetime terminology should be promised without MoonBit-level proof.
5. **ICC scope:** architecture describes ICC as part of the eventual `mb-color` domain and allows bounded parsing if capacity permits; feature research explicitly defers full ICC parsing/management. v0.1 should ship only the minimum profile identity/metadata seam and verified foundational conversions.
6. **Native adapters:** research agrees they must be narrow leaf packages, but not whether the first native file adapter belongs inside the `mb-core` publication unit or a fourth module. Start with no required adapter; decide placement only when an adapter exists and its dependencies/release cadence are measurable.

## Verified facts versus recommendations

| Topic | Verified fact from research | Recommendation derived from it |
|---|---|---|
| Publication | MoonBit modules publish/version independently; packages compile as namespaces; workspaces coordinate members | Use three workspace member modules and release them topologically |
| Targets | Current documented targets include `wasm`, `wasm-gc`, `js`, and `native`; `--target all` excludes LLVM | Test each claimed package target; keep LLVM non-blocking/experimental |
| FFI | Ownership annotations matter, defaults are migrating, and payload aggregate layout is unstable | Require explicit ownership tables/annotations and opaque narrow adapters |
| Local toolchain | The July 2026 `moon`/`moonc`/`moonrun` versions were verified locally | Pin them for v0.1 CI, while postponing the permanent minimum floor |
| Standards | PNG, CSS Color, ICC, and PPM define richer and sometimes distinct color/alpha/format semantics | Keep representation explicit and use narrow standards-derived v0.1 behavior |
| Workspace resolution | Local members can substitute for versioned dependencies | Add clean registry-resolution/consumer qualification before publication |
| Security risk | Untrusted media/document inputs can amplify allocation, decompression, nesting, offsets, and work | Make checked arithmetic and monotonic safe-default budgets release blockers |

## Confidence assessment

| Area | Confidence | Basis and caveat |
|---|---|---|
| v0.1 scope and horizontal ordering | High | All four research tracks converge on the same foundation-first critical path |
| Multi-module workspace and dependency DAG | High | Directly supported by current MoonBit module/workspace behavior; registry namespace remains unresolved |
| Target policy and conformance requirement | High | Current target metadata and `--target all` behavior are documented; exact long-term support floor is not decided |
| Checked bytes, limits, diagnostics, and image-layout gates | High | These are shared architectural and security prerequisites across all later domains |
| Explicit color/alpha model | High | Standards and downstream dependency pressure agree; exact numeric/tolerance policy remains open |
| PPM P6 as the v0.1 reference adapter | Medium-high | Strong fit for an auditable proof, but exact subset and fixture semantics still require a decision |
| `moon.mod.json` selection | Medium | Recommended from current rollout/tooling evidence and should be rechecked before release |
| Exact CI toolchain installation method | Medium | Versions are known; third-party setup action/version syntax needs live implementation verification |
| Borrowed/external memory public API | Medium-low | Safety requirement is clear, but MoonBit-specific ergonomic/lifetime proof is incomplete |
| Later SVG/font/text/PDF/GPU/AI details | Medium to low | Layer boundaries are credible; implementation-specific standards, corpora, and threat models are intentionally not yet researched deeply |

## Unresolved gaps

### Blocking before public implementation identities are finalized

- mooncakes.io organization/owner namespace;
- project and fixture licenses;
- RFC acceptance authority, review threshold, and stability-label policy;
- manifest format and exact reproducible CI installation procedure.

### Blocking before candidate API stabilization

- numeric/color component types, rounding rules, and cross-target tolerances;
- safe storage/view/external-memory lifetime model;
- canonical zero-sized image, stride, plane overlap, endianness, and metadata-preservation semantics;
- exact resource-budget fields/defaults and whether cancellation is stable or experimental;
- strict PPM grammar, limits, and color interpretation;
- API snapshot/diff and package-target metadata enforcement approach.

### Blocking before public release

- redistributable fixture/corpus provenance and licenses;
- clean registry-resolution testing and exact tested compatibility manifest format;
- evidence that each module is independently consumable;
- release-candidate decision on the minimum supported MoonBit toolchain;
- benchmark variance characterization before any regression threshold is enforced.

### Intentionally deferred research

- production codec selection and PNG implementation strategy;
- ICC parser/transform engine;
- font container, shaping, bidi, and layout standards/corpora;
- SVG parsing/style/resource/rendering boundaries in implementation detail;
- PDF parser/generator/filter/rendering threat models and package decomposition;
- CPU canvas semantics and the future shared render-command RFC;
- GPU, AI runtime, MCP, and Wasm optimization adapters.

## Planning recommendation

Approve a five-phase horizontal v0.1 roadmap with explicit exit gates, treating Phase 2 (`mb-core`) as the hard safety/portability prerequisite, Phase 3 (`mb-color`) as the semantic prerequisite for image stabilization, and Phase 5 as an independent qualification/release phase. Permit narrow exploratory spikes from later phases only when they test a foundation boundary; do not publish their APIs or broaden the milestone until all Foundation gates are green.
