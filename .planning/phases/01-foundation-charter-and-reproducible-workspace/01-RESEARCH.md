# Phase 1: Foundation Charter and Reproducible Workspace - Research

**Researched:** 2026-07-16
**Domain:** MoonBit workspace governance, reproducible toolchain, target metadata, and quality automation
**Confidence:** HIGH for repository design and locally verified CLI behavior; MEDIUM for the third-party CI setup action

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- Native host adapters may split into a fourth module if dependency weight or release cadence later diverges; v0.1 keeps them as isolated leaf packages within the owning module.
- Numeric tolerances, image lifetime/layout semantics, resource-budget defaults, and the strict PPM subset remain decisions for their owning later phases.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GOV-01 | A contributor can read an accepted foundation RFC that defines MNF's vision, principles, terminology, architectural layers, dependency direction, and v0.1 boundaries. | Extend the existing RFC 0001 in place, remove resolved open questions, add terminology and an auditable acceptance header. |
| GOV-02 | A contributor can follow a documented RFC lifecycle with named statuses, acceptance authority, review expectations, and rules for breaking architectural changes. | Add a dedicated RFC process document and validate RFC header fields/status transitions. |
| GOV-03 | A package consumer can distinguish experimental, candidate, and stable public APIs and understand the compatibility promise of each status. | Add a compatibility policy plus checked package metadata and module README badges/tables. |
| GOV-04 | A contributor can identify the chosen project license, fixture licensing rules, mooncakes.io owner/namespace, and module naming policy before public release. | Add Apache-2.0 license, fixture manifest schema/example, namespace policy, and a publication-block flag checked by automation. |
| WORK-01 | A developer can clone the repository and operate `mb-core`, `mb-color`, and `mb-image` as three independently publishable MoonBit modules in one workspace. | Scaffold the locked three-member `moon.work`; use one manifest/changelog/version per member and module-local package dry runs. |
| WORK-02 | A developer can reproduce the v0.1 development environment from a checked-in toolchain policy that records the exact `moon`, `moonc`, and `moonrun` baseline. | Put all three expected version outputs in machine-readable policy and fail before build steps on any mismatch. |
| WORK-03 | A consumer can inspect every public package's explicit supported-target declaration and determine whether it supports `native`, `wasm`, `wasm-gc`, or `js`. | Require package-level `supported-targets` and cross-check it against a root package inventory. |
| WORK-04 | A maintainer can run root-level format, check, test, documentation, package-content, and dependency-DAG validation without manually entering each module. | Implement one PowerShell 7 entry point with deterministic stages and module iteration. |
| WORK-05 | A maintainer can verify portable package behavior on every declared target while LLVM remains clearly non-blocking and experimental. | Loop explicitly over `js`, `wasm`, `wasm-gc`, and `native`; isolate LLVM in a `continue-on-error` CI lane. |
</phase_requirements>

## Summary

Phase 1 should be planned as three coupled deliverables: an accepted governance contract, a minimal but real three-module Moon workspace, and one executable quality contract. The existing `docs/rfcs/0001-moonbit-native-foundation.md` is a Draft and still contains questions that CONTEXT.md has now resolved; update that canonical RFC rather than create a second charter. [VERIFIED: repository inspection] [VERIFIED: CONTEXT.md]

The workspace mechanics are directly supported by Moon: `moon.work` coordinates multiple member modules, root `check`, `test`, and `info` run in workspace context, and publication/package operations remain module-scoped with `moon -C`. Workspace dependencies resolve to members by module name and `moon work sync` aligns their declared versions. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html] [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html]

The most important planning detail is to make policy single-sourced and executable. A checked-in JSON policy should own module identities, exact tool versions, API-stability labels, required targets, allowed dependency edges, and the publication block. Prose documents explain the policy; `scripts/quality.ps1` verifies it against manifests, package metadata, the installed toolchain, and actual cross-target commands. [VERIFIED: CONTEXT.md] [VERIFIED: local CLI help]

**Primary recommendation:** Plan one governance task, one workspace-and-policy task, and one root-quality/CI task, with the quality task consuming and validating artifacts from the first two.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| RFC lifecycle and acceptance | Governance / repository policy | CI metadata validation | Humans decide acceptance; automation checks header completeness and allowed status values. |
| Compatibility, license, namespace, fixture rules | Governance / repository policy | Module metadata | Policy is repository-wide while each module exposes the applicable license, stability, and target facts. |
| Multi-module coordination | Workspace / build system | Module manifests | `moon.work` coordinates local members; each `moon.mod.json` remains the publication/version unit. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html] |
| Target support | Package metadata | Root quality runner | Package declarations define the contract; explicit target commands prove it. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |
| Toolchain reproducibility | Root machine-readable policy | CI setup and version gate | Setup obtains the requested toolchain; the policy comparison is the fail-closed source of truth. |
| Package content and dependency DAG | Module manifests / package descriptors | Root policy validator | Publication content and dependencies are module-local, while allowed edges are ecosystem-wide. |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must be MoonBit-owned; Phase 1 must not introduce foreign implementations. [VERIFIED: AGENTS.md]
- Native is primary, but portable targets are deliberate capability boundaries with conformance checks. [VERIFIED: AGENTS.md]
- Native FFI must remain small, isolated, documented, and replaceable; Phase 1 should contain no FFI. [VERIFIED: AGENTS.md]
- Public dependencies must be acyclic and explicit; consumers must not import unrelated layers. [VERIFIED: AGENTS.md]
- Stable APIs follow Semantic Versioning and experimental APIs are visibly marked. [VERIFIED: AGENTS.md]
- Operations must be deterministic and usable without GUI state. [VERIFIED: AGENTS.md]
- Benchmarks require declared workloads and reproducible baselines; benchmark work is outside this phase. [VERIFIED: AGENTS.md] [VERIFIED: CONTEXT.md]
- New modules and breaking architectural changes require RFCs. [VERIFIED: AGENTS.md]
- Code discovery must prefer codebase-memory MCP graph tools; the repository was indexed and currently consists of planning documents, one RFC, README, and no implementation modules. [VERIFIED: codebase-memory-mcp index and architecture]
- All file changes must run through GSD workflow; this research is the Phase 1 planning workflow output. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Component | Version / Pin | Purpose | Why Standard |
|-----------|---------------|---------|--------------|
| `moon` | `0.1.20260713` / `75c7e1f` | Workspace, format, check, test, docs, package operations | Locked baseline; locally verified on 2026-07-16. [VERIFIED: local `moon version`] |
| `moonc` | `v0.10.4+2cc641edf` | Compiler bundled with the pinned toolchain | Locked recorded compiler identity; locally verified. [VERIFIED: local `moonc -v`] |
| `moonrun` | `0.1.20260713` / `75c7e1f` | Runtime bundled with the pinned toolchain | Locked recorded runtime identity; locally verified. [VERIFIED: local `moonrun --version`] |
| `moon.work` | current locked syntax | Coordinate three local modules | Official workspace mechanism; root commands operate across members. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html] |
| `moon.mod.json` | compatibility-floor format | Per-module identity, SemVer, metadata, dependencies | Locked decision; current docs still document it alongside transitional `moon.mod`. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html] |
| `moon.pkg` | current package DSL | Package imports and explicit `supported-targets` | Current official package format; package target declarations intersect module declarations. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |
| PowerShell | 7.x (`7.6.3` available locally) | Cross-platform root quality orchestration | Locked root entry-point language and available locally. [VERIFIED: local `pwsh --version`] |

### Supporting

| Component | Version / Pin | Purpose | When to Use |
|-----------|---------------|---------|-------------|
| `hustcer/setup-moonbit` | commit `bdc8c076af1f4c5012a6ac3451a2009ec75bf921` (tag `v1.22`) | Install an exact MoonBit toolchain in GitHub Actions | Use only in CI, pinned to the full commit and followed by the local version gate. The action documents an exact `version` input in `0.x.y+hash` form. [CITED: https://github.com/hustcer/setup-moonbit] [VERIFIED: `git ls-remote`] |
| Git | `2.54.0` available locally | Repository-history evidence and clean-tree checks | Use for acceptance/history evidence and optional non-mutation checks. [VERIFIED: local `git --version`] |
| PowerShell `ConvertFrom-Json` | built in | Read policy and `moon.mod.json` without another dependency | Use in metadata/DAG validators. [VERIFIED: PowerShell 7 runtime] |

### External Package Audit

No npm, PyPI, Cargo, Mooncakes, or other external language packages are required for Phase 1. The three modules should depend only on workspace members and MoonBit core as needed. Therefore the package-legitimacy gate does not apply. [VERIFIED: phase scope and CONTEXT.md]

### Alternatives Considered

The primary repository, namespace, manifest-format, target, and toolchain choices are locked in CONTEXT.md and must not be reopened during planning. The only implementation choice researched here is CI setup: use the full-SHA-pinned setup action plus a fail-closed version comparison instead of tracking `latest` or a movable action tag. [VERIFIED: CONTEXT.md] [CITED: https://github.com/hustcer/setup-moonbit]

## Architecture Patterns

### System Architecture Diagram

```text
Contributor / CI
       |
       v
scripts/quality.ps1  (single entry point)
       |
       +--> load policy/foundation.json
       |       |
       |       +--> exact toolchain versions
       |       +--> module/package inventory
       |       +--> required targets and allowed DAG
       |       +--> publication blocked = true
       |
       +--> validate governance and metadata
       |       +--> RFC header/status and policy documents
       |       +--> module manifests/package target declarations
       |       +--> fixture manifest schema/content
       |
       +--> moon workspace quality
       |       +--> fmt/check/test/docs/info
       |       +--> js / wasm / wasm-gc / native
       |       +--> per-module package --list
       |
       +--> required lane result
       |
       +--> optional LLVM lane result (non-blocking)
```

### Recommended Project Structure

```text
moonbit-foundation/
├── LICENSE
├── moon.work
├── policy/
│   └── foundation.json              # machine-readable source of truth
├── docs/
│   ├── rfcs/
│   │   ├── README.md                # RFC index and current statuses
│   │   └── 0001-moonbit-native-foundation.md
│   ├── governance/
│   │   └── rfc-process.md
│   └── policies/
│       ├── api-stability.md
│       ├── licensing-and-fixtures.md
│       ├── publication.md
│       ├── targets.md
│       └── toolchain.md
├── fixtures/
│   └── manifest.json                # valid empty initial manifest
├── modules/
│   ├── mb-core/
│   │   ├── moon.mod.json
│   │   ├── moon.pkg
│   │   ├── README.mbt.md
│   │   ├── CHANGELOG.md
│   │   └── scaffold.mbt
│   ├── mb-color/
│   │   └── ... same publication-owned files
│   └── mb-image/
│       └── ... same publication-owned files
├── scripts/
│   ├── quality.ps1                  # only public entry point
│   └── quality/
│       ├── Assert-Policy.ps1
│       ├── Assert-Toolchain.ps1
│       └── Invoke-MoonQuality.ps1
└── .github/workflows/quality.yml
```

### Pattern 1: Machine-Readable Policy, Human-Readable Explanation

**What:** `policy/foundation.json` owns values that automation must compare: module names/paths/versions, public package paths, stability, required targets, allowed dependency edges, tool versions, and `publication.blocked=true` with reason `namespace ownership unverified`. Prose documents link to and explain those values. [VERIFIED: CONTEXT.md]

**When to use:** Use it for every Phase 1 promise that can drift across RFC text, READMEs, manifests, and CI.

**Planning implication:** The governance task creates policy and prose together; the quality task reads JSON and fails when another artifact diverges. Avoid separate JSON files for the same values.

### Pattern 2: Independently Publishable Workspace Members

**What:** `moon.work` lists exactly the three locked member paths. Each member uses its final intended registry name, its own version/changelog/readme, and module dependencies by final module name. At the workspace root, those dependencies resolve locally; publication/package commands still run with `moon -C modules/<member>`. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html] [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html]

**Recommended dependency edges:**

```text
moonbit-foundation/mb-core
  ^
  |
moonbit-foundation/mb-color
  ^                         (mb-image may also depend directly on mb-core)
  |
moonbit-foundation/mb-image
```

The validator should reject self-edges, unknown modules, cycles, and reverse edges. [VERIFIED: CONTEXT.md] [VERIFIED: AGENTS.md]

### Pattern 3: Empty Public Surface, Real Build Surface

**What:** Give each root package a package-private scaffold definition and a basic test, but no public domain API. `moon info` should therefore produce an empty or intentionally minimal public interface while format/check/test/docs/package commands exercise a real package. [VERIFIED: phase boundary]

**When to use:** Only in Phase 1. Phase 2 replaces the `mb-core` scaffold with actual contracts.

**Why:** Public placeholder functions create compatibility debt and falsely imply a domain contract. The package itself can still carry candidate stability and target metadata without exposing a fake API.

### Pattern 4: One Quality Entry Point with Two Lanes

**What:** `scripts/quality.ps1` accepts `-Lane Required` (default) or `-Lane LlvmExperimental`. Required runs all mandated checks; LLVM only checks/builds the experimental target and is invoked by a CI job with `continue-on-error: true`. [VERIFIED: CONTEXT.md]

**Required stage order:**

1. Validate PowerShell major version and exact Moon toolchain outputs.
2. Validate policy, RFC header fields, fixture manifest, module/package inventory, target declarations, and dependency DAG.
3. Run `moon fmt --check`.
4. For each of `js`, `wasm`, `wasm-gc`, `native`, run `moon check --target <target> --deny-warn --frozen` and `moon test --target <target> --frozen`.
5. Run `moon doc --frozen` and `moon info --target all --frozen`.
6. For each module, run `moon -C <path> package --frozen --list` and reject forbidden/generated/unrelated content.

The installed CLI confirms the target values, `--deny-warn`, `--frozen`, `fmt --check`, workspace commands, and `package --list`. [VERIFIED: local CLI help] Official docs confirm `--target all` expands to `wasm`, `wasm-gc`, `js`, and `native`, not LLVM. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]

### Pattern 5: Documentation as Executable Evidence

**What:** Put module usage/status documentation in `.mbt.md`; Moon automatically checks `mbt check` fences through `moon check` and runs document tests through `moon test`. Run `moon doc --frozen` as a separate generation gate. [CITED: https://docs.moonbitlang.com/en/latest/language/docs.html] [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]

### Anti-Patterns to Avoid

- **Create a second RFC 0001:** update the existing Draft in place and preserve history. [VERIFIED: repository inspection]
- **Leave resolved questions in the accepted RFC:** namespace, module count/names, license, acceptance authority, and compatibility labels are now locked. [VERIFIED: CONTEXT.md]
- **Track `latest` toolchains or movable action tags:** exact reproducibility requires the action commit, toolchain version input, and post-install checks. [VERIFIED: CONTEXT.md] [CITED: https://github.com/hustcer/setup-moonbit]
- **Use path dependencies for workspace members:** declare normal module dependencies and let `moon.work` resolve local members. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html]
- **Rely only on `--target all` logs:** explicitly loop targets so evidence identifies which backend failed and package policy can be compared target-by-target.
- **Treat module-level target metadata as sufficient:** WORK-03 requires every public package to carry explicit support metadata. [VERIFIED: REQUIREMENTS.md]
- **Run `moon work sync` inside the quality gate:** it mutates manifests and can hide drift. Run it during scaffolding/release preparation, then use `--frozen` in validation. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html]
- **Publish to test the scaffold:** packaging is permitted; publication remains blocked until namespace ownership is verified. [VERIFIED: CONTEXT.md]
- **Expose placeholder public APIs:** use a real package with no fake domain contract.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Workspace orchestration | Custom script that enters modules for check/test/info | `moon.work` and root Moon commands | Workspace context is built into Moon. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html] |
| JSON manifest parsing | Regex parser for `moon.mod.json` or policy | PowerShell `ConvertFrom-Json` | Built-in structured parsing avoids quoting/order errors. [VERIFIED: PowerShell 7] |
| Target expansion | Implicit assumptions about what `all` means | Explicit required target array plus Moon commands | Current `all` excludes LLVM and may evolve. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |
| Documentation test runner | Separate Markdown code-fence executor | Moon `.mbt.md` and doc tests | `moon check`/`moon test` already integrate checked documentation. [CITED: https://docs.moonbitlang.com/en/latest/language/docs.html] |
| Package tar/list generation | Home-grown file walker as the source of truth | `moon package --frozen --list` | It reports Moon's actual publication selection. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html] |
| Semantic versions | Custom version grammar | SemVer-compliant module version and documented policy | Mooncakes publication requires SemVer for module versions. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html] |
| License identifiers | Custom license labels | SPDX identifier `Apache-2.0` | Moon module metadata expects an SPDX license value. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html] |

**Key insight:** Custom automation should validate MNF-specific policy, not reimplement Moon's workspace, package, documentation, or target machinery.

## Common Pitfalls

### Pitfall 1: Governance Declared but Not Accepted

**What goes wrong:** RFC 0001 contains the right prose but remains `Draft`, lacks approval/review evidence, or retains unresolved blocking questions.

**How to avoid:** Plan explicit transitions through `Proposed` and `Accepted`, record dates/approvers/review link or bootstrap authority in the header, and make the validator require those fields for Accepted. The seven-day bootstrap window is a real elapsed-time condition; if not already satisfied, the plan must mark RFC acceptance as a human/time checkpoint rather than fabricate evidence. [VERIFIED: CONTEXT.md]

### Pitfall 2: Name Drift from Earlier Research

**What goes wrong:** Earlier planning research used `mnf-core` examples or shorter filesystem names, while locked decisions now require `moonbit-foundation/mb-*` and `modules/mb-*`.

**How to avoid:** Treat CONTEXT.md as authoritative and add exact identity assertions to `foundation.json`. [VERIFIED: CONTEXT.md] [VERIFIED: AGENTS.md embedded research summary]

### Pitfall 3: Toolchain Setup Succeeds with the Wrong Bundle

**What goes wrong:** CI installs `moon` but silently receives a different `moonc` or `moonrun` build.

**How to avoid:** Compare normalized outputs from all three commands before any build and print all outputs to CI logs. The local expected outputs were verified on 2026-07-16. [VERIFIED: local version probes]

### Pitfall 4: Package Target Metadata Is Accidentally Broader or Narrower

**What goes wrong:** Omitting `supported-targets` claims all backends; a restrictive module declaration intersects and silently narrows package declarations. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]

**How to avoid:** Keep the module declaration equal to the full portable set and require the same explicit set on each Phase 1 public package; reserve `native` only for future leaf adapters. Validate exact normalized target sets, not string ordering.

### Pitfall 5: Quality Checks Mutate the Checkout

**What goes wrong:** format or dependency synchronization repairs files in CI, hiding drift.

**How to avoid:** use `moon fmt --check`, `--frozen`, non-mutating metadata checks, and optionally assert a clean tracked diff after the quality entry point. [VERIFIED: local CLI help]

### Pitfall 6: Packaging Pulls Unrelated Workspace Content

**What goes wrong:** a module package includes root fixtures, other modules, generated `_build`, or credentials.

**How to avoid:** execute `moon -C <module> package --frozen --list` for each member and compare the list to allowed publication patterns. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]

### Pitfall 7: LLVM Becomes a De Facto Gate

**What goes wrong:** an experimental LLVM failure blocks Phase 1 or is advertised as support after a shallow check.

**How to avoid:** keep LLVM out of required package target metadata, run it in an isolated `continue-on-error` job, and label its result experimental/non-blocking in CI and policy. [VERIFIED: CONTEXT.md]

### Pitfall 8: CI Supply-Chain Drift

**What goes wrong:** `uses: hustcer/setup-moonbit@v1` moves over time or PR jobs receive publication credentials.

**How to avoid:** pin the action to the researched full SHA, grant read-only workflow permissions, do not configure mooncakes tokens in Phase 1, and retain the independent version gate. [CITED: https://github.com/hustcer/setup-moonbit] [VERIFIED: `git ls-remote`]

## Code Examples

### Workspace Manifest

```moonbit
members = [
  "./modules/mb-core",
  "./modules/mb-color",
  "./modules/mb-image",
]
```

Source pattern: official workspace documentation. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html]

### Portable Module Metadata Shape

```json
{
  "name": "moonbit-foundation/mb-core",
  "version": "0.1.0",
  "license": "Apache-2.0",
  "readme": "README.mbt.md",
  "preferred-target": "native",
  "supported-targets": "+js+wasm+wasm-gc+native"
}
```

The field names and compact target-set syntax are current official Moon metadata; the values are locked or recommended for this phase. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html] [VERIFIED: CONTEXT.md]

### Explicit Required Target Loop

```powershell
$requiredTargets = @('js', 'wasm', 'wasm-gc', 'native')
foreach ($target in $requiredTargets) {
  & moon check --target $target --deny-warn --frozen
  if ($LASTEXITCODE -ne 0) { throw "moon check failed for $target" }

  & moon test --target $target --frozen
  if ($LASTEXITCODE -ne 0) { throw "moon test failed for $target" }
}
```

The options and target names are verified against the pinned local CLI. [VERIFIED: local `moon check --help` and `moon test --help`]

### Pinned CI Setup Shape

```yaml
- name: Set up exact MoonBit toolchain
  uses: hustcer/setup-moonbit@bdc8c076af1f4c5012a6ac3451a2009ec75bf921
  with:
    version: 0.1.20260713+75c7e1f
- name: Run required quality lane
  shell: pwsh
  run: ./scripts/quality.ps1 -Lane Required
```

The action documents the exact-version input form; the tag-to-commit resolution was verified during research. The project version gate remains authoritative. [CITED: https://github.com/hustcer/setup-moonbit] [VERIFIED: `git ls-remote`]

## State of the Art

| Older / Riskier Approach | Current Phase 1 Approach | Impact |
|--------------------------|--------------------------|--------|
| One module or path-linked local dependencies | Three normal module dependencies resolved through `moon.work` | Preserves independent publication and workspace development. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html] |
| Implicit backend support | Explicit compact `supported-targets` at module and package levels | Makes portability inspectable and testable. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |
| `moon.mod` adoption during rollout | Locked `moon.mod.json` compatibility floor | Avoids transitional format drift for v0.1. [VERIFIED: CONTEXT.md] |
| README code examples only | `.mbt.md` and doc-comment tests integrated with check/test | Documentation becomes executable evidence. [CITED: https://docs.moonbitlang.com/en/latest/language/docs.html] |
| Floating CI action/toolchain | Full action SHA, exact toolchain input, three-binary version gate | Makes CI fail closed on toolchain drift. |

**Deprecated/outdated:** Legacy array syntax for `supported-targets` is accepted for compatibility but deprecated; use the compact target-set expression. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. Recommendations are derived from locked decisions, current official documentation, repository inspection, and local CLI probes. | — | — |

## Open Questions

1. **Has the minimum seven-day public review window for RFC 0001 already elapsed with public evidence?**
   - What we know: the RFC was created on 2026-07-16 and is currently Draft. [VERIFIED: repository inspection]
   - What's unclear: whether an external discussion started earlier or two maintainer approvals are available.
   - Recommendation: planning must include an acceptance checkpoint that records real evidence; implementation can scaffold before acceptance, but Phase 1 cannot be complete until the locked acceptance rule is met.

2. **Is `moonbit-foundation` ownership already verifiable on mooncakes.io?**
   - What we know: publication is explicitly blocked until verified, while manifests must use final names. [VERIFIED: CONTEXT.md]
   - What's unclear: current external ownership state was not part of this research task.
   - Recommendation: keep `publication.blocked=true`; do not make Phase 1 depend on actual publishing.

3. **Does the pinned setup action successfully fetch the exact requested bundle on all selected CI runners?**
   - What we know: its README documents exact version inputs and cross-platform runner support. [CITED: https://github.com/hustcer/setup-moonbit]
   - What's unclear: the specific 20260713 bundle has not been exercised in this repository's CI.
   - Recommendation: make the first CI implementation task run the action plus the three-binary gate; if setup cannot fetch it, use the official installer/archive mechanism but keep the same fail-closed policy.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| PowerShell 7 | Root quality runner | Yes | `7.6.3` | Install PowerShell 7 in CI image if absent. [VERIFIED: local probe] |
| `moon` | All workspace checks | Yes | `0.1.20260713` (`75c7e1f`) | No fallback; exact version is required. [VERIFIED: local probe] |
| `moonc` | Compilation/checks | Yes | `v0.10.4+2cc641edf` | No fallback; bundled identity is required. [VERIFIED: local probe] |
| `moonrun` | Test execution | Yes | `0.1.20260713` (`75c7e1f`) | No fallback; bundled identity is required. [VERIFIED: local probe] |
| Git | History/evidence and CI checkout | Yes | `2.54.0.windows.1` | CI checkout supplies Git. [VERIFIED: local probe] |

**Missing dependencies with no fallback:** none on the current machine.

**Missing dependencies with fallback:** none required for local Phase 1 execution.

## Security Domain

This phase has no web authentication, sessions, database, cryptographic protocol, or untrusted network parser. Security concerns are repository/CI supply-chain integrity, metadata validation, fixture provenance, and preventing accidental publication. [VERIFIED: phase boundary]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No application authentication exists in Phase 1. |
| V3 Session Management | No | No sessions exist. |
| V4 Access Control | Limited | GitHub workflow uses read-only permissions; publication is blocked and no token is configured. |
| V5 Input Validation | Yes | Parse JSON structurally, validate enumerated status/target/module values, and reject unknown dependency edges and malformed fixture records. |
| V6 Cryptography | Limited | Use SHA-256 fields for fixture integrity; do not implement a hash algorithm. |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Floating CI action ref changes executed code | Tampering | Full commit SHA pin plus version verification. |
| Pull request receives publication credentials | Elevation of privilege / Information disclosure | No publication job or mooncakes secret in Phase 1; read-only workflow permissions. |
| Fixture with unclear redistribution rights enters repository | Repudiation / Legal provenance risk | Required manifest fields, generated-fixture preference, and rejection when redistribution is not confirmed. [VERIFIED: CONTEXT.md] |
| Manifest claims broader support than tests prove | Spoofing | Cross-check target metadata against explicit per-target execution evidence. |
| Quality script executes arbitrary repository strings | Tampering | Treat policy as data; use fixed command arrays and enumerated values, never `Invoke-Expression`. |

## Sources

### Primary (HIGH confidence)

- Local pinned CLI: `moon version`, `moonc -v`, `moonrun --version`, and subcommand help — exact installed behavior and environment availability.
- Repository `01-CONTEXT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `AGENTS.md`, and existing RFC 0001 — locked scope and current state.
- codebase-memory-mcp index/architecture — documentation-first repository topology and absence of implementation modules.

### Secondary (MEDIUM confidence)

- https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html — workspace members, root operations, per-module publishing, version sync.
- https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html — module identity, dependencies, metadata, manifest formats, targets, package listing.
- https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html — package targets, target intersection, `--target all`, native-only metadata.
- https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html — command options for format, check, test, docs, info, package, and frozen mode.
- https://docs.moonbitlang.com/en/latest/language/docs.html — checked doc comments and literate `.mbt.md` behavior.
- https://www.moonbitlang.com/download/ — official current installer entry point.
- https://github.com/hustcer/setup-moonbit — exact-version action input and runner support; third-party, therefore retain a fail-closed version gate.

### Tertiary (LOW confidence)

- None used.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — exact tool versions and command flags were locally probed; official docs corroborate workspace and target semantics.
- Architecture: HIGH — driven by locked decisions and Moon's documented module/workspace model.
- Pitfalls: HIGH for repository/toolchain drift; MEDIUM for setup-action availability until CI executes it.
- CI bootstrap: MEDIUM — action interface and immutable commit were verified, but the exact bundle has not yet run in this repository's CI.

**Research date:** 2026-07-16
**Valid until:** 2026-07-23 for setup-action/toolchain details; governance and repository structure remain valid until a superseding accepted decision.
