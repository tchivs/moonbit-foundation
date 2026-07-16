<!-- GSD:project-start source:PROJECT.md -->

## Project

**MoonBit Native Foundation**

MoonBit Native Foundation (MNF) is an RFC-led ecosystem initiative that defines and implements composable infrastructure for graphics, documents, media, AI, and system-oriented MoonBit software. It is not an end-user application or a loose catalog of unrelated libraries: the Whitepaper establishes shared architecture, compatibility policy, module boundaries, and quality standards, while independently publishable MoonBit modules implement those contracts over time.

The primary audience is MoonBit library authors and application developers building image tools, PDF/SVG tooling, whiteboards, OCR and AI pipelines, CLI tools, MCP servers, IDE extensions, desktop software, and WebAssembly applications.

**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

### Constraints

- **Implementation**: Core algorithms and shared data models should be written in MoonBit — ecosystem credibility depends on exercising MoonBit rather than wrapping a foreign stack.
- **Backend**: Native is the primary performance and system-integration target — portable targets are supported deliberately through capability boundaries and conformance tests.
- **FFI**: Native stubs must remain small, isolated, documented, and replaceable — FFI ownership and reference-counting rules create correctness risk.
- **Modularity**: Public packages must have acyclic, explicitly documented dependencies — consumers must not import the whole ecosystem for one primitive.
- **Compatibility**: Public API stability follows Semantic Versioning after a package is declared stable — experimental APIs must be visibly marked.
- **Automation**: Public operations should be deterministic and usable without GUI state — CLI, AI Agent, and MCP consumers are first-class.
- **Performance**: Benchmarks require declared workloads and reproducible baselines — marketing claims without evidence are not acceptance criteria.
- **Governance**: New modules and breaking architectural changes require RFCs — implementation cannot silently redefine ecosystem boundaries.

<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->

## Technology Stack

## Executive recommendation

| Component | Verified version | Policy |
|---|---:|---|
| `moon` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Exact CI pin for the v0.1 development line |
| `moonc` | `v0.10.4+2cc641edf` (2026-07-15) | Record in CI logs; comes with the pinned toolchain |
| `moonrun` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Record in CI logs; comes with the pinned toolchain |

## Repository and workspace model

### Alternatives rejected

- **One module with `core`, `color`, and `image` packages:** rejected because module-level versioning and `moon publish` would couple all releases and prevent consumers from selecting independent module lifecycles.
- **Three repositories immediately:** rejected because v0.1 requires frequent cross-contract changes; `moon.work` gives local coordination without sacrificing publication boundaries.
- **Path dependencies in `moon.mod.json`:** rejected for new work; official guidance recommends workspace resolution, and the new `moon.mod` syntax deprecates local dependency configuration.
- **Adopt `moon.mod` immediately:** deferred until its rollout status is stable across the declared compatibility floor.

## Targets and portability

- `mnf-core`: `"supported-targets": "+js+wasm+wasm-gc+native"` for portable data and algorithms; native host adapters belong in separate native-only packages.
- `mnf-color`: the same four-target set.
- `mnf-image`: the same four-target set for image models, transforms, and pure reference codecs; any system codec adapter is a separate package with `"supported-targets": "native"`.

## Native FFI and host adapters

### Alternatives rejected

- **Wrap mature C libraries as the core implementation:** rejected because it violates MNF's MoonBit-native purpose and contaminates portable packages.
- **Ban all C:** rejected because OS integration and mature codecs may require narrow adapters.
- **Rely on implicit FFI ownership convention:** rejected because the documented default is changing and mistakes produce leaks or memory errors.

## Testing, documentation, and benchmarks

- `*_test.mbt` black-box tests validate only the public API and are mandatory for every public package.
- `*_wbtest.mbt` and inline tests cover internal invariants, parsers, checked arithmetic, and representation logic.
- Snapshot tests are appropriate for structured diagnostics and small deterministic textual forms. Binary image expectations should use checked fixture bytes or digests plus semantic assertions, not opaque snapshots alone.
- Literate `.mbt.md` and `mbt check` examples should be used for public API documentation; document tests are black-box tests.
- Conformance fixtures and adversarial limit tests live in repository-level `fixtures/`, with provenance/license metadata; packages should consume them through test helpers rather than embed large duplicated data.

## CI and release pipeline

## Dependency policy

## Immediate implementation checklist

## Confidence and watch items

| Topic | Confidence | Watch item |
|---|---|---|
| Workspace and publication unit | High | Workspace commands are current and locally present |
| Four required production targets | High | `--target all` behavior is explicitly documented and locally exposed |
| Native FFI rules | High | Ownership default is actively migrating; explicit annotations are mandatory |
| `moon.mod.json` over `moon.mod` | Medium | Revisit after rollout flags disappear and compatibility floor is chosen |
| Exact CI installation method | Medium | Third-party action must be SHA-pinned and exact-version syntax verified during workflow implementation |
| Registry module names | Low until governance decision | mooncakes owner/organization is unresolved |
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
