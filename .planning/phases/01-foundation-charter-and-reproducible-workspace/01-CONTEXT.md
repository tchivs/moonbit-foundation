# Phase 1: Foundation Charter and Reproducible Workspace - Context

**Gathered:** 2026-07-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the accepted v0.1 foundation charter, governance and compatibility policy, publication and licensing decisions, and a reproducible three-module MoonBit workspace with root-level quality and target-matrix enforcement. This phase scaffolds and governs `mb-core`, `mb-color`, and `mb-image`; it does not implement their domain algorithms.

</domain>

<decisions>
## Implementation Decisions

### RFC governance and acceptance
- RFC 0001 is the architectural charter and must define vision, terminology, layer boundaries, dependency direction, portability policy, v0.1 scope, and governance.
- Use the lifecycle `Draft -> Proposed -> Accepted -> Implemented`, with `Rejected` and `Superseded` terminal states; every transition is recorded in the RFC header and repository history.
- Acceptance requires two maintainer approvals with no unresolved blocking objection. Until the project has two maintainers, the project lead may accept after a minimum seven-day public review window; this bootstrap exception must be explicit.
- New modules, public dependency-direction changes, and breaking architectural changes require an accepted RFC. Implementation PRs may not silently redefine an accepted boundary.

### Licensing, namespace, and naming
- License project-authored source, documentation, and generated fixtures under Apache-2.0 to provide a permissive license with an explicit patent grant.
- Maintain a fixture manifest recording source, author, retrieval date, SHA-256, SPDX/license, redistribution status, and expected use. Prefer generated fixtures; do not commit externally sourced fixtures without confirmed redistribution permission.
- Reserve `moonbit-foundation` as the intended mooncakes.io owner namespace and use `moonbit-foundation/mb-core`, `moonbit-foundation/mb-color`, and `moonbit-foundation/mb-image`. Public publication is blocked until ownership is verified; local manifests still use these final intended names to avoid a later rename.
- Keep module names domain-specific and independently publishable. Do not add an umbrella `mnf/all` module or package, and do not force lockstep versions.

### API stability and compatibility
- Public APIs are labeled `experimental`, `candidate`, or `stable`. Experimental APIs have no compatibility promise; candidate APIs require documented migration notes for changes; stable APIs follow Semantic Versioning.
- v0.1 packages begin as candidate unless explicitly marked experimental. No package is called stable before its contract, conformance evidence, and release policy meet the stable gate.
- Stable breaking changes require an accepted RFC, a major-version change, a migration guide, and compatibility qualification of direct dependants. Stable removals require at least one prior minor release of deprecation unless a documented security exception applies.
- Stability status and supported targets must be visible in package documentation and checked metadata, not inferred from repository location or version number alone.

### Workspace, toolchain, and quality contract
- Use one `moon.work` with three member modules under `modules/mb-core`, `modules/mb-color`, and `modules/mb-image`; each module has its own manifest, version, changelog, and publication lifecycle.
- Pin the v0.1 development baseline exactly to `moon 0.1.20260713` (`75c7e1f`), recording the bundled `moonc v0.10.4+2cc641edf` and `moonrun 0.1.20260713` in checked-in policy and CI logs.
- Use `moon.mod.json` for the v0.1 compatibility floor while `moon.mod` rollout remains transitional. Every public package declares `+js+wasm+wasm-gc+native`; native-only leaf adapters declare `native`. Avoid a restrictive module-level target intersection.
- Provide one root PowerShell 7 quality entry point that runs formatting checks, workspace checks, tests, documentation checks, package-content inspection, explicit target-matrix checks, and dependency-DAG/metadata validation. CI invokes the same entry point and treats LLVM as experimental and non-blocking.

### the agent's Discretion
- Exact document filenames, helper-script decomposition, CI job layout, and minimal placeholder package APIs may be chosen during planning, provided the decisions above and Phase 1 requirements remain machine-verifiable.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, and `.planning/ROADMAP.md` already define the project boundary, all Phase 1 requirement IDs, and the five-layer milestone sequence.
- `.planning/research/ARCHITECTURE.md` already contains the recommended multi-module topology, dependency direction, portability seams, release ordering, and anti-patterns.
- `.planning/research/STACK.md` records the verified local MoonBit toolchain and current manifest/target guidance.

### Established Patterns
- The repository is documentation-first and currently contains no implementation modules, so Phase 1 establishes the initial code and governance conventions.
- Architectural rules are expected to have executable checks; documentation alone is not sufficient acceptance evidence.
- Portable contracts point inward and native adapters remain leaf packages; public dependencies must stay acyclic.

### Integration Points
- Root workspace metadata and quality scripts connect all three independently publishable modules.
- RFC, license, fixture, compatibility, and support-matrix documents feed package manifests, CI gates, and later release qualification.
- Phase 2 consumes the accepted `mb-core` boundary and workspace quality contract; Phases 3-5 depend on the same target and compatibility policies.

</code_context>

<specifics>
## Specific Ideas

- Prefer enforceable metadata and repository checks over prose-only promises.
- Preserve final intended module paths from the first scaffold, while explicitly blocking public publication until the mooncakes.io owner is verified.
- Use the official MoonBit four-target set (`js`, `wasm`, `wasm-gc`, `native`) for portable packages and keep LLVM outside the required matrix.

</specifics>

<deferred>
## Deferred Ideas

- Native host adapters may split into a fourth module if dependency weight or release cadence later diverges; v0.1 keeps them as isolated leaf packages within the owning module.
- Numeric tolerances, image lifetime/layout semantics, resource-budget defaults, and the strict PPM subset remain decisions for their owning later phases.

</deferred>
