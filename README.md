# MoonBit Native Foundation

MoonBit Native Foundation (MNF) is an RFC-led, native-first foundation for
graphics, documents, media, and system-oriented MoonBit software. It provides
small, composable modules with explicit boundaries, deterministic behavior,
bounded resource use, and deliberate portability across MoonBit targets.

MNF is infrastructure rather than an end-user application. Image editors,
whiteboards, PDF/SVG tools, OCR pipelines, CLIs, MCP servers, and WebAssembly
applications are intended to consume these contracts instead of rebuilding
incompatible foundations.

## Project status

The repository is in active `0.1.x` candidate development. The modules are
not stable and have not been published as a public release. The roadmap records
the completed foundation and image milestones; the active line is v0.27,
focused on low-bit indexed Adam7 PNG encoding.

Publication remains intentionally gated on verifying the exact Mooncakes
namespace authority. The repository may contain newer candidate modules and
examples than the original v0.1 foundation charter, but no candidate API should
be treated as a stable compatibility promise.

- [Roadmap and milestone history](.planning/ROADMAP.md)
- [Project charter and requirements](.planning/PROJECT.md)
- [RFC index](docs/rfcs/README.md)
- [Security policy](SECURITY.md)

## Workspace modules

Every module is independently publishable and currently targets
`js`, `wasm`, `wasm-gc`, and `native` unless its manifest says otherwise.
Native is the preferred performance and system-integration target; portable
algorithms stay in MoonBit and native adapters remain narrow leaves.

| Module | Responsibility | Direct dependencies |
| --- | --- | --- |
| [`tchivs/mb-core`](modules/mb-core/README.mbt.md) | Checked arithmetic, bounded storage, budgets, I/O, diagnostics, and host capabilities | — |
| [`tchivs/mb-color`](modules/mb-color/README.mbt.md) | Explicit color identities, sRGB transfer, alpha semantics, quantization, and profiles | `mb-core` |
| [`tchivs/mb-image`](modules/mb-image/README.mbt.md) | Image descriptors, storage/views, raster operations, codec contracts, PPM, QOI, and PNG | `mb-core`, `mb-color` |
| [`tchivs/mb-canvas`](modules/mb-canvas/README.mbt.md) | Deterministic drawing lists and coverage-antialiased rasterization into `mb-image` surfaces | `mb-core`, `mb-color`, `mb-image` |
| [`tchivs/mb-svg`](modules/mb-svg/README.mbt.md) | Bounded SVG parsing and scene-tree lowering into an `mb-canvas` drawing list | `mb-core`, `mb-color`, `mb-image`, `mb-canvas` |

The dependency direction is deliberately downward: document formats produce
scene or drawing data, graphics modules produce pixels, and image/color/core
modules own storage and safety primitives. SVG parsing does not own rasterization;
canvas does not parse documents; image operations do not depend on canvas.

## Examples

The workspace includes runnable examples under [`examples/`](examples/):

- `ppm-portable` — bounded PPM decode/transform/encode on all four targets.
- `ppm-native-cli` — the same pipeline with explicitly injected native-facing
  capabilities.
- `qoi-portable` — caller-buffered QOI decode and encode with hostile schedules.
- `png-portable` — resumable PNG decode, resize, and encode.
- `mb-svg-demo` — SVG parse → scene tree → canvas drawing list → RGBA8 pixels.

For example, run the SVG demo on Native:

```powershell
moon -C examples/mb-svg-demo run main --target native --frozen
```

The example modules are compatibility consumers, not alternate production
implementations. Their source is useful when learning the public seams.

## Quick start

The CI-verified development baseline is:

- `moon 0.1.20260713` (`75c7e1f`)
- `moonc v0.10.4+2cc641edf`
- `moonrun 0.1.20260713` (`75c7e1f`)

After installing the pinned toolchain, run the repository quality lane from a
PowerShell prompt:

```powershell
./scripts/quality.ps1 `
  -Lane Required `
  -EvidenceDirectory artifacts/release-qualification/local
```

For a focused package check, use the same frozen commands used by the quality
scripts, for example:

```powershell
moon -C modules/mb-image info --target all --frozen
moon -C modules/mb-image test png --target native --frozen
```

The required lane checks module topology, public interfaces, RFC/policy
consistency, fixtures, examples, benchmarks, and the four declared targets.
The optional CI lane `LlvmExperimental` is non-blocking and is not part of the
portable compatibility floor.

## Design commitments

- Core algorithms and shared data models are MoonBit-owned wherever practical.
- Native integration is isolated behind documented, replaceable capability
  boundaries.
- Public packages have explicit, acyclic dependencies and narrow imports.
- Resource limits and checked arithmetic are preflighted before allocation,
  mutation, or output.
- Caller-buffered APIs expose accepted progress and sticky terminal outcomes;
  rejected destination tails remain untouched.
- Existing output remains frozen when a new strategy is opt-in. New behavior
  does not silently rewrite legacy bytes.
- Automation is deterministic and does not depend on GUI state.
- New modules and breaking architectural changes require an RFC.

## Documentation map

- [`docs/rfcs/`](docs/rfcs/) — module charters and architecture decisions.
- [`docs/policies/`](docs/policies/) — API stability, targets, toolchain, licensing,
  and publication policy.
- [`docs/governance/`](docs/governance/) — RFC process and review records.
- Each module's `README.mbt.md` — executable public API documentation and
  package-specific examples.
- [`docs/support.md`](docs/support.md) — support and issue-routing guidance.

## Stability and publication

All current modules are `0.1.0` candidates. Until a module is declared stable,
its compatibility policy is the executable pre-1.0 policy documented in the
module README and RFC 0001. Once stable, public API compatibility follows
Semantic Versioning and the repository's compatibility evidence must be
updated with the release.

MNF does not claim a registry publication, namespace transfer, or release
artifact merely because a manifest contains a module name. Registry mutations
remain a separately verified operation.

## License

MNF is released under the [Apache License 2.0](LICENSE).
