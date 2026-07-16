# Feature Landscape: MoonBit Native Foundation

**Research date:** 2026-07-16  
**Scope:** RFC-led MoonBit infrastructure for graphics, image, color, documents, font/text, AI/automation, CLI/MCP, Native, and WebAssembly consumers  
**Decision horizon:** v0.1 Foundation, with later-module boundaries recorded to avoid foundational lock-in

## Executive conclusion

MNF should compete first on **coherent contracts, portability discipline, and evidence**, not on format count. The credible v0.1 product is a small but end-to-end usable substrate: bounded byte/stream operations, structured diagnostics, explicit color and alpha semantics, checked image storage/views, deterministic transforms, and one deliberately simple reference codec. It must build and test against an explicit MoonBit target matrix and remain usable without a GUI, filesystem, network, or process-global state.

The strongest differentiator is not "implemented in MoonBit" alone. It is that the same well-specified models can be used by Native CLI tools and portable Wasm consumers, while host access and foreign code stay behind narrow capability adapters. MoonBit officially supports `wasm`, `wasm-gc`, `js`, and `native`; the build system can declare supported targets per package and `--target all` covers those four targets but not experimental LLVM. That makes package-level portability a buildable contract rather than a marketing claim. [MoonBit documentation](https://docs.moonbitlang.com/en/latest/) · [package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)

Conversely, attempting PNG, ICC, SVG, font shaping, PDF, GPU, AI runtimes, or MCP transport completeness in v0.1 would obscure the foundation and multiply conformance/security obligations before its core types are proven. Those domains should influence interfaces now but be implemented in later milestones.

## Product lens

MNF is not a consumer feature checklist. Its "users" are library and application authors, and its value is measured by whether independently developed components can share data without importing a monolith or translating between incompatible representations.

Three feature classes matter:

1. **Foundation behavior:** byte access, limits, errors, color, pixels, storage, views, transforms, codecs, target declarations.
2. **Ecosystem behavior:** publication boundaries, versioning, documentation, conformance fixtures, benchmarks, governance.
3. **Deferred domain behavior:** drawing, scene/document parsing, fonts/text, AI adapters, MCP exposure, GPU acceleration.

The first two belong in v0.1. The third must have clear dependency boundaries, but not implementations.

## Table stakes

These are minimum expectations for a reusable infrastructure foundation. Missing any of them makes adoption risky even if demos work.

| Capability | Minimum credible behavior | Why it is table stakes | v0.1 disposition |
|---|---|---|---|
| Explicit target support | Every public package declares supported backends; CI exercises each declared backend | MoonBit packages can be filtered and validated by backend, and reachable dependencies must support the selected backend | **Ship** |
| Reproducible multi-module workspace | One `moon.work`, independently identifiable modules/packages, workspace-wide check/test, module-local publication | MoonBit workspaces are designed for multiple modules in one repository while publication remains module-scoped | **Ship** |
| Stable byte model | Owned bytes plus immutable/mutable views or slices; offsets and lengths use checked arithmetic | Every image/document/font parser depends on safe byte ranges | **Ship** |
| Bounded stream abstractions | Reader, writer, seek where available, exact/partial reads, bounded sub-readers, in-memory implementations | Parsers must not assume a filesystem or full buffering; Wasm host I/O varies | **Ship** |
| Structured errors and diagnostics | Machine-readable category/code, byte offset/context, deterministic rendering, no process termination for recoverable input failures | CLI, IDE, agent, and MCP consumers need errors they can inspect, not scrape | **Ship** |
| Resource budgets | Explicit limits for allocation, dimensions, pixel count, bytes consumed, nesting/recursion hooks | Untrusted media and documents can trigger oversized allocations before later parsers exist | **Ship** |
| Explicit color semantics | Component type, color-space identity, transfer function, alpha convention; conversion errors are visible | "RGBA" is not interoperable unless color space and alpha representation are known | **Ship, narrow set** |
| Explicit image layout | Dimensions, pixel format, channel order, bit depth, endianness, planes, row stride, color space, alpha representation | Consumers need to interpret and share image memory without guessing | **Ship** |
| Checked image storage and views | Overflow-safe allocation, owned storage, borrowed crop/view, row access, bounds validation | Copy-only images are expensive; unconstrained views are unsafe | **Ship** |
| Deterministic reference operations | Crop/view, copy, nearest-neighbor resize, orientation/flip, basic pixel conversion with specified rounding | A data model needs executable semantics and cross-target golden tests | **Ship** |
| Codec boundary | Probe/decode/encode contracts accept streams/options/limits and return metadata/diagnostics; codecs are separate dependencies | Format support must not turn `mb-image` into a monolith | **Ship interface** |
| Minimal reference codec | One simple, auditable codec or fixture adapter proving streaming, limits, image construction, and round-trip behavior | Without an end-to-end path the abstractions remain speculative | **Ship PPM P6 subset** |
| Documentation and runnable examples | Public API docs, Native CLI example, portable/in-memory example, compatibility matrix | Infrastructure adoption depends on discoverability and proven composition | **Ship** |
| Conformance and benchmark harness | Golden/property/negative/limit tests plus declared benchmark workloads and environment | Correctness and performance must be evidence-backed | **Ship harness + baselines** |
| Versioning and changelog | Per-publishable-unit version, stability marker, changelog; stable APIs obey SemVer | Independent publication requires explicit compatibility expectations | **Ship process** |

### Standards-derived details that must shape the table stakes

- **Color and alpha:** CSS Color 4 standardizes multiple RGB and device-independent spaces, distinguishes color-space conversion from interpolation, and specifies premultiplication for interpolation with alpha. MNF does not need CSS syntax in v0.1, but it must not collapse color space, transfer function, and alpha representation into an unlabeled tuple. [CSS Color Module Level 4](https://www.w3.org/TR/css-color-4/)
- **Image formats are richer than pixel buffers:** PNG supports grayscale, truecolor, indexed color, optional alpha, 1–16-bit samples, streaming, integrity checking, and embedded color information. These requirements justify extensible pixel/metadata/codec contracts, while simultaneously showing why full PNG is not a suitable "minimal codec" milestone item. [PNG Specification, Third Edition](https://www.w3.org/TR/png-3/)
- **Reference codec choice:** Netpbm describes PPM as a deliberately simple lowest-common-denominator RGB format that is easy to write and analyze, while also documenting its inefficiency and weak metadata. A strict, bounded P6 subset is useful as a harness adapter, not as a flagship production codec. [Netpbm PPM specification](https://netpbm.sourceforge.net/doc/ppm.html)
- **Host capability separation:** MoonBit's FFI documentation notes that the outside world differs across C, JavaScript, Wasm, and WasmGC hosts, and Wasm interactions depend on imports from a host. Therefore filesystem, clock, environment, logging sinks, and similar facilities must be injected capabilities rather than assumptions in portable packages. [MoonBit FFI documentation](https://docs.moonbitlang.com/en/latest/language/ffi.html)

## Differentiators

These features could make MNF the preferred MoonBit substrate rather than merely another utility library. They should be designed into v0.1 where inexpensive, but each must remain evidence-backed.

| Differentiator | User-visible value | v0.1 action | Proof required |
|---|---|---|---|
| One contract across Native and portable targets | Algorithms and data models compose in CLI/server and browser/Wasm contexts | Keep `mb-core`, `mb-color`, and computational `mb-image` packages portable; isolate host adapters | Same conformance vectors pass on every declared target |
| Capability-oriented host boundary | Library authors can supply memory, filesystem, Wasm host, or test doubles without forking parsers | Define minimal reader/writer/logging contracts and in-memory implementations | No portable package imports native stubs or assumes a path |
| Resource safety as API, not patch | Downstream parsers inherit budgets and checked range operations by construction | Make limits mandatory/default-safe in readers, image constructors, and codec options | Adversarial tests reject overflow and excessive dimensions before allocation |
| Representation transparency | FFI, GPU, and encoder adapters can inspect exact layout and transfer ownership deliberately | Expose validated layout descriptors; distinguish storage from view | Round-trip layout tests and documented ownership/lifetime rules |
| Deterministic headless semantics | CI, CLI, MCP, IDE, and AI tools receive reproducible results without UI state | Specify rounding, conversion, ordering, diagnostics, and metadata preservation behavior | Cross-target golden hashes/values |
| Reference implementation before acceleration | Later SIMD/GPU/native paths can be validated against a portable truth implementation | Keep simple MoonBit reference algorithms | Differential tests compare optimized adapters with reference results |
| Conformance kit as a product | Third-party codecs or adapters can claim compatibility without joining the monorepo | Publish reusable fixtures, test helpers, and required behavior | External/example adapter runs the same kit |
| Honest package-level portability | Consumers can select dependencies without discovering backend failures late | Generate a support matrix from package declarations and CI | Matrix links to passing CI jobs |
| AI/automation-ready errors and operations | Agents can discover failures, retry safely, and serialize options/results | Use typed option/result records and stable diagnostic identifiers | JSON/tool mapping can be added later without changing core semantics |
| RFC-governed boundaries | Contributors can extend the ecosystem without creating overlapping modules | Require RFCs for new modules and boundary-breaking changes | Accepted RFC records dependency and portability impact |

### Differentiators that are explicitly later

- **Full ICC color management:** ICC publishes profile-format specifications, and proper profile parsing/transform behavior is a substantial standards and conformance domain. v0.1 should reserve profile identity/opaque metadata hooks and implement verified foundational conversions only. [International Color Consortium specifications](https://www.color.org/specification/ICC1v43_2010-12.pdf)
- **Production PNG codec:** PNG is a strong first major image codec after the image contract stabilizes because it tests streaming, checksums, filtering, compression, multiple pixel models, alpha, and color metadata. That breadth is precisely why it belongs after v0.1.
- **CPU reference canvas:** A deterministic headless renderer will be a major ecosystem differentiator in the Graphics program, but it depends on stable color/image semantics.
- **Composable text pipeline:** Separating font containers, shaping-facing runs, bidi/script concerns, and layout can avoid GUI lock-in; implementation requires dedicated standards/corpus research.
- **Automation adapters:** MCP and CLI bindings should wrap the same deterministic operations, not define parallel business APIs. MCP transport/tool implementation remains optional and above the core.

## Anti-features

These are attractive-sounding capabilities that would weaken MNF if included or promised at this stage.

| Anti-feature | Why to reject | Safer alternative |
|---|---|---|
| "Supports every MoonBit target" at ecosystem level | Native adapters and host facilities cannot honestly share one support claim; LLVM remains outside `--target all` and experimental | Declare and test support per package |
| "100% Pure MoonBit, zero foreign code" | OS, codec, device, and accelerator integration may require narrow FFI; purity claims invite hidden wrappers | Pure MoonBit reference/data layers plus documented replaceable adapters |
| Umbrella module that imports everything | Increases build size, couples release cadence, and makes lightweight consumers pay for unused formats | Independent modules/packages with optional convenience bundles only after adoption evidence |
| Universal `Image` that silently canonicalizes | Erases stride, planes, color space, alpha mode, precision, and metadata; forces costly copies | Explicit format/layout descriptor and fallible conversions |
| Implicit sRGB or implicit alpha mode | Produces subtly wrong compositing/conversion across SVG, PNG, canvas, and UI consumers | Require color space and alpha representation in relevant types |
| Ambient filesystem/global logger/default runtime | Breaks Wasm portability, tests, embedding, and deterministic automation | Pass capabilities and sinks explicitly |
| Unbounded `read_all` as the parser foundation | Makes malformed or huge media an allocation hazard | Bounded readers, subranges, streaming, and explicit budgets |
| Exceptions/process exit as recoverable parser behavior | Prevents libraries, IDEs, servers, and agents from controlling failures | Typed results plus structured diagnostics |
| Full PNG/ICC/SVG/PDF/font stack in v0.1 | Each is a major conformance and security program; parallel implementation would freeze weak foundation contracts | One minimal codec, domain-informed interfaces, staged RFCs |
| GUI/window/event-loop integration in core | Locks infrastructure to one application model and makes headless use second-class | Adapters above MNF, with canvas producing buffers/commands |
| GPU-first rendering contract | Hardware APIs can distort data ownership and semantics before a CPU truth model exists | Portable CPU reference semantics, optional acceleration later |
| Bundled AI inference runtime | Couples MNF to model formats/providers and introduces large native dependencies | Later `mb-ai` adapter contracts over stable images/tensors/streams |
| MCP-specific types in core modules | Protocol evolution would leak into foundational APIs | Map typed deterministic operations in a separate `mb-mcp` layer |
| Marketing performance claims | "Native" does not prove speed or memory behavior | Versioned benchmark workloads with environment and regression thresholds |
| Stable 1.0 APIs before usage evidence | Premature compatibility freezes poor boundaries | Mark experimental APIs, graduate small interfaces based on examples/conformance |

## Feature dependencies

The critical path is horizontal; higher-level modules should consume foundation semantics rather than redefine them.

```text
RFC / governance / publication policy
        │
        ├──────────────► workspace + target-aware CI
        │                         │
        ▼                         ▼
checked arithmetic ─────► byte storage/views ─────► bounded streams
        │                         │                       │
        │                         └───────────────┬───────┘
        │                                         ▼
        │                              diagnostics + resource budgets
        │                                         │
        ▼                                         ▼
color component types ──► transfer functions ─► color conversions
        │                                         │
        └────────────────────┬────────────────────┘
                             ▼
                  image format/layout descriptor
                             │
           ┌─────────────────┼──────────────────┐
           ▼                 ▼                  ▼
     owned storage      borrowed views    pixel conversion
           │                 │                  │
           └─────────────────┼──────────────────┘
                             ▼
                       codec interface
                             │
                             ▼
                   bounded PPM fixture codec
                             │
                             ▼
              examples + conformance + benchmarks
```

### Downstream dependency map

| Later capability | Foundation contracts it requires | Boundary that must be preserved now |
|---|---|---|
| `mb-canvas` | color conversion, alpha mode, image views, checked dimensions, deterministic rounding | Canvas must not own windowing or redefine pixels/colors |
| `mb-svg` | bounded streams, diagnostics, color, image/codec access, later canvas/text | Parse/resource resolution/rendering must be separable; recursion/external-resource limits explicit |
| `mb-font` | bounded random access, checked offsets, byte views, diagnostics | Font data access must not require UI or text layout |
| `mb-text` | font glyph contracts plus explicit script/direction/language metadata | Shaping-facing runs stay separate from block layout |
| `mb-layout` | shaped runs, metrics, deterministic measurement | No GUI widget/event concepts |
| `mb-pdf` | bounded seekable streams, diagnostics, filters, color, image, font/text, later canvas | Object parsing, generation, content interpretation, and rendering stay separable |
| production codecs | codec SPI, streams, budgets, metadata, image layouts | Each codec is optional and separately testable |
| `mb-effects` | images/views, color, alpha/compositing rules | CPU reference results precede acceleration |
| `mb-gpu` | explicit layouts, ownership transfer, reference rendering semantics | GPU resources do not become the canonical image model |
| `mb-ai` | image/tensor interchange, streams, deterministic preprocessing | No provider/model runtime leaks into lower layers |
| `mb-mcp` / CLI | typed operations/options/results, diagnostics, serialization adapters | Transport and presentation remain outside core |

## Realistic v0.1 Foundation scope

### Must ship

#### 1. Charter and repository contract

- RFC 0001 accepted with terminology, dependency direction, portability classes, stability labels, RFC lifecycle, and contribution rules.
- One MoonBit workspace containing independently identifiable `mb-core`, `mb-color`, and `mb-image` publishable units (or a documented interim package layout with an explicit split plan).
- Per-package `supported-targets`; workspace `check` and `test` across all declared targets. MoonBit officially supports multi-module workspaces through `moon.work`, workspace-wide commands, and module-scoped publishing. [MoonBit workspace documentation](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html)
- Generated API docs, changelog, license, examples, and target matrix.
- Experimental versus stable API annotation/policy. Stable public APIs use SemVer; incompatible public API changes require a major version after 1.0. [Semantic Versioning 2.0.0](https://semver.org/)

#### 2. `mb-core` candidate contracts

- Checked integer operations needed for `offset + length`, `width * height`, `stride * rows`, and narrowing conversions.
- Owned byte buffer and range-validated read-only/mutable views.
- Reader/writer interfaces with partial and exact operations; seek as a separate capability.
- Bounded sub-reader/window; in-memory reader/writer; explicit end-of-input behavior.
- Resource budget types covering at least maximum bytes, allocation, dimensions/pixels, and a generic nesting counter for future parsers.
- Structured error/diagnostic type with stable code/category, offset/range when known, cause/context, and deterministic text formatting.
- Pluggable logging/diagnostic sink interface with a no-op default passed explicitly where needed; no process-global configuration.
- Native filesystem adapter as a separate host-adapted package only if schedule permits; it is not required to prove portable core semantics.

#### 3. `mb-color` candidate contracts

- Clearly named scalar/component conventions and finite/range validation behavior.
- `sRGB` encoded and linear-sRGB identities; XYZ D65 only if required as an explicit conversion pivot.
- Verified sRGB transfer encode/decode and sRGB ↔ linear-sRGB conversion.
- Straight/unassociated and premultiplied/associated alpha represented distinctly or carried as an explicit descriptor.
- Premultiply/unpremultiply with specified zero-alpha and rounding behavior.
- Reference conversion vectors sourced from standards or independently generated high-precision fixtures.
- Opaque profile/color-space identifier and metadata hooks sufficient for later ICC/PNG integration, without an ICC parser.

#### 4. `mb-image` candidate contracts

- Non-negative, checked dimensions and pixel count.
- Extensible pixel-format descriptor supporting at minimum grayscale 8-bit, RGB8, RGBA8, and BGRA8 if a concrete Native adapter needs it; unsupported combinations fail explicitly.
- Channel order, component depth/type, packed versus planar form, plane count, row stride, endianness where relevant, color-space identity, and alpha representation are explicit.
- Owned contiguous storage plus validated borrowed immutable/mutable views; crop/view without copy when layout permits.
- Row and pixel access that cannot escape declared plane/stride bounds.
- Deterministic copy, horizontal/vertical flip, 90-degree orientation transforms, nearest-neighbor resize, and the minimal pixel-format conversions required by examples.
- Metadata container with namespaced/typed extension points and a documented preservation policy; avoid committing to arbitrary mutable string maps as the only model.
- Codec interface separated from registry/policy: probe, header/info, decode, encode, options, limits, diagnostics, and stream ownership rules.
- Strict bounded PPM P6 fixture adapter supporting one image, 8-bit RGB, declared limits, comments/whitespace per the chosen subset, round-trip tests, malformed input tests, and rejection of unsupported variants. The adapter must be labeled test/reference quality because PPM is inefficient and metadata-poor.

#### 5. Evidence and usability

- Cross-target conformance vectors for checked ranges, stream behavior, sRGB transfer, alpha operations, layout validation, views, transforms, and PPM round trip.
- Property tests for range/view invariants and color round-trip tolerances where tool support permits.
- Negative fixtures for truncation, overflow, impossible stride, excessive dimensions, invalid headers, and allocation-budget rejection.
- Native CLI example: decode PPM from an adapter or memory, transform/convert, encode result, print structured diagnostics.
- Portable example operating entirely on in-memory streams; a Wasm host demo is optional, but the package must build/test for every claimed portable target.
- Benchmark baselines for byte scanning/copy, color conversion, image copy/view creation, and nearest-neighbor resize. Record toolchain, backend, CPU/runtime, input shape, warmup/repetition, and allocation assumptions; set regression gates only after variance is understood.

### Should ship if capacity remains

- Cancellation/cooperative work-budget hook designed for future long operations.
- Read-only image view over externally owned memory with a documented lifetime discipline that works safely in MoonBit's actual ownership/GC model.
- Simple codec registry in a separate convenience package, provided it does not rely on global mutation or codec name guessing.
- Native file adapter and a Native-only microbenchmark comparing stream/file strategies.
- Machine-readable manifest for package maturity, targets, conformance level, and benchmark links.

### Explicitly not in v0.1

- Full PNG/APNG, JPEG, WebP, TIFF, EXR, or production codec coverage.
- ICC profile parsing or full color-management engine; CMYK, spot colors, HDR tone mapping, gamut mapping, and display calibration.
- General resampling kernels, convolution/effects suite, compositing engine, or canvas/path rasterizer.
- SVG/XML, PDF, OpenType/font parsing, shaping, bidi, line/block layout.
- GPU resources, shader APIs, SIMD promises, or platform-specific zero-copy claims.
- AI model loading/inference, tensor runtime ownership, OCR, MCP server/transport, IDE integration, GUI/windowing.
- Broad async I/O framework, networking stack, process management, or general-purpose standard-library replacement.
- Stable 1.0 designation for all APIs.

## Acceptance evidence for v0.1

v0.1 should be considered complete only when all of the following are observable:

1. A clean checkout can run documented workspace checks/tests for the declared target matrix.
2. No portable foundation package reaches a native stub, path-based filesystem API, browser API, or required ambient global.
3. Invalid byte ranges, image dimensions, stride calculations, and allocation sizes fail before memory access/allocation.
4. The same color and image conformance vectors pass on Native and every claimed portable backend within documented numeric tolerances.
5. A bounded PPM P6 sample travels through stream → codec → image view/transform → codec, and malformed/oversized inputs produce structured failures.
6. Consumers can depend on each publishable unit without pulling in deferred graphics/document/AI integrations.
7. Public APIs, support status, examples, changelogs, fixtures, and benchmark methodology are published and linked from the package documentation.
8. At least one downstream-shaped spike—such as a tiny headless image CLI and an in-memory Wasm-oriented example—uses only public contracts, with resulting contract changes resolved before candidate stabilization.

## Prioritization

| Priority | Theme | Rationale |
|---|---|---|
| P0 | Checked bytes, budgets, diagnostics, target-aware workspace | All later safety, portability, and parsing work depends on these |
| P0 | Explicit color/alpha and image layout/storage/view contracts | These are the interoperability center of graphics, documents, AI preprocessing, and codecs |
| P0 | Cross-target conformance and minimal end-to-end codec | Validates that contracts are executable rather than architectural prose |
| P1 | Deterministic transforms/conversions and benchmarks | Establish useful behavior and performance baselines without widening domains |
| P1 | Publication, docs, examples, SemVer/maturity policy | Turns internal packages into adoptable infrastructure |
| P2 | Host file adapter, cancellation hook, external-memory view | Valuable extensions, but they must not delay portable core validation |
| Deferred | Production formats, canvas, SVG, fonts/text, PDF, GPU, AI, MCP | Depend on validated foundation semantics and deserve separate RFC/conformance programs |

## Open feature decisions before implementation freezes

1. **Publication granularity:** three coordinated modules versus one initial module with independent packages. Decide using actual MoonBit registry/versioning workflow; preserve acyclic boundaries either way.
2. **Minimum toolchain:** use the local July 2026 baseline for development, but declare a minimum only after CI proves it.
3. **Numeric model:** exact component types and tolerance/rounding rules for color conversions across backends.
4. **Borrowed/external memory:** which safe lifetime patterns MoonBit exposes consistently enough for public APIs; do not emulate Rust terminology without language-level proof.
5. **PPM subset:** exact grammar leniency, maximum values, multi-image behavior, and metadata/color semantics. The recommendation here is a strict single-image P6, max value 255 subset with explicit sRGB interpretation for MNF fixtures, clearly documented as narrower than Netpbm PPM.
6. **Compatibility maturity:** naming and graduation criteria for experimental, candidate, and stable APIs before 1.0.
7. **Fixture licensing:** which official/third-party vectors and corpora may be redistributed; generate original fixtures when rights are unclear.

## Primary sources

- MoonBit, [Documentation overview and supported backends](https://docs.moonbitlang.com/en/latest/)
- MoonBit, [Workspace Support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html)
- MoonBit, [Package Configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)
- MoonBit, [Managing Projects with Packages](https://docs.moonbitlang.com/en/latest/language/packages.html)
- MoonBit, [Foreign Function Interface](https://docs.moonbitlang.com/en/latest/language/ffi.html)
- W3C, [CSS Color Module Level 4](https://www.w3.org/TR/css-color-4/)
- W3C, [Portable Network Graphics Specification, Third Edition](https://www.w3.org/TR/png-3/)
- International Color Consortium, [ICC.1 profile format specification](https://www.color.org/specification/ICC1v43_2010-12.pdf)
- Netpbm, [PPM Format Specification](https://netpbm.sourceforge.net/doc/ppm.html)
- Semantic Versioning, [Semantic Versioning 2.0.0](https://semver.org/)

## Recommended decision

Approve v0.1 as a **contract-and-conformance milestone** for `mb-core`, `mb-color`, and `mb-image`. Treat the bounded PPM path and two downstream-shaped examples as vertical proofs, not as a change to horizontal-layer planning. Reject format-count and integration-count as v0.1 success metrics. The milestone succeeds when later modules can depend on the foundation without needing to reinterpret bytes, color, alpha, pixels, errors, resource limits, or target support.
