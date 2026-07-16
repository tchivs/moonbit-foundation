# Phase 1: Foundation Charter and Reproducible Workspace - Pattern Map

**Mapped:** 2026-07-16
**Files analyzed:** 36 new/modified files
**Analogs found:** 14 / 36

## Repository Pattern Baseline

The repository is greenfield and documentation-first. The codebase-memory graph contains planning documents, one RFC, the root README, and no MoonBit modules, PowerShell automation, CI workflow, fixture manifest, license file, or tests. Consequently:

- the existing RFC and planning documents are usable analogs for document structure, scope statements, requirement traceability, and architectural language;
- `.planning/config.json` is only a partial analog for machine-readable JSON formatting;
- there is no repository-native code analog for `moon.work`, Moon manifests/packages, MoonBit source/tests, PowerShell quality automation, or GitHub Actions;
- for files without a repository analog, the planner must use the verified patterns and examples in `01-RESEARCH.md`, not invent compatibility-sensitive syntax.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `LICENSE` | config / legal policy | file-I/O | none | no analog |
| `moon.work` | config | batch workspace orchestration | none | no analog |
| `policy/foundation.json` | config / policy model | file-I/O, validation input | `.planning/config.json` | role-match only |
| `policy/phase-01-source-audit.json` | config / coverage audit model | file-I/O, validation input | `.planning/config.json` | role-match only |
| `docs/rfcs/README.md` | documentation / index | file-I/O | `README.md` | role-match |
| `docs/rfcs/0001-moonbit-native-foundation.md` | documentation / governance model | lifecycle / event-driven state transitions | same file | exact |
| `docs/governance/rfc-process.md` | documentation / governance policy | lifecycle / event-driven state transitions | `docs/rfcs/0001-moonbit-native-foundation.md` | partial |
| `docs/policies/api-stability.md` | documentation / compatibility policy | lifecycle / transform | `.planning/PROJECT.md` | partial |
| `docs/policies/licensing-and-fixtures.md` | documentation / provenance policy | file-I/O | `.planning/REQUIREMENTS.md` | partial |
| `docs/policies/publication.md` | documentation / release policy | lifecycle / batch | `docs/rfcs/0001-moonbit-native-foundation.md` | partial |
| `docs/policies/targets.md` | documentation / support policy | transform / matrix | `README.md` | partial |
| `docs/policies/toolchain.md` | documentation / reproducibility policy | batch / validation | `.planning/research/STACK.md` | partial |
| `fixtures/manifest.json` | config / provenance model | file-I/O, validation input | `.planning/config.json` | role-match only |
| `modules/mb-core/moon.mod.json` | config / module manifest | dependency resolution | none | no analog |
| `modules/mb-core/moon.pkg` | config / package descriptor | dependency resolution | none | no analog |
| `modules/mb-core/README.mbt.md` | executable documentation | check/test transform | `README.md` | role-match |
| `modules/mb-core/CHANGELOG.md` | documentation / release ledger | append-only lifecycle | none | no analog |
| `modules/mb-core/scaffold.mbt` | utility / private scaffold | transform | none | no analog |
| `modules/mb-core/scaffold_wbtest.mbt` | test | request-response assertion | none | no analog |
| `modules/mb-color/moon.mod.json` | config / module manifest | dependency resolution | none | no analog |
| `modules/mb-color/moon.pkg` | config / package descriptor | dependency resolution | none | no analog |
| `modules/mb-color/README.mbt.md` | executable documentation | check/test transform | `README.md` | role-match |
| `modules/mb-color/CHANGELOG.md` | documentation / release ledger | append-only lifecycle | none | no analog |
| `modules/mb-color/scaffold.mbt` | utility / private scaffold | transform | none | no analog |
| `modules/mb-color/scaffold_wbtest.mbt` | test | request-response assertion | none | no analog |
| `modules/mb-image/moon.mod.json` | config / module manifest | dependency resolution | none | no analog |
| `modules/mb-image/moon.pkg` | config / package descriptor | dependency resolution | none | no analog |
| `modules/mb-image/README.mbt.md` | executable documentation | check/test transform | `README.md` | role-match |
| `modules/mb-image/CHANGELOG.md` | documentation / release ledger | append-only lifecycle | none | no analog |
| `modules/mb-image/scaffold.mbt` | utility / private scaffold | transform | none | no analog |
| `modules/mb-image/scaffold_wbtest.mbt` | test | request-response assertion | none | no analog |
| `scripts/quality.ps1` | controller / public entry point | batch pipeline | none | no analog |
| `scripts/quality/Assert-Policy.ps1` | service / validator | file-I/O, transform | none | no analog |
| `scripts/quality/Assert-Toolchain.ps1` | service / validator | request-response process execution | none | no analog |
| `scripts/quality/Invoke-MoonQuality.ps1` | service / orchestrator | batch process execution | none | no analog |
| `.github/workflows/quality.yml` | CI config / provider | event-driven batch | none | no analog |

## Pattern Assignments

### `docs/rfcs/0001-moonbit-native-foundation.md` (governance model, lifecycle)

**Analog:** the same existing Draft RFC. Update it in place; do not create a second charter.

**Header pattern** (`docs/rfcs/0001-moonbit-native-foundation.md`, lines 1-7):

```markdown
# RFC 0001: MoonBit Native Foundation

- **Status:** Draft
- **Authors:** MNF contributors
- **Created:** 2026-07-16
- **Target:** Foundation charter and v0.1 architecture
- **Discussion:** To be established
```

Preserve this compact metadata-list style, but extend it with auditable transition history and acceptance evidence required by the locked lifecycle. Never fabricate review dates, approvals, or elapsed-time evidence.

**Architecture/dependency pattern** (lines 83-120):

```markdown
## 6. Architecture

```text
Applications and Integrations
...
Foundation
└── mb-core
...
MoonBit targets: native / wasm / wasm-gc / js
```

The arrows represent allowed dependency direction. Lower layers never import document, integration, or application layers.
```

Retain a diagram followed by an unambiguous prose rule. Align Phase 1 names with `moonbit-foundation/mb-core`, `moonbit-foundation/mb-color`, and `moonbit-foundation/mb-image` and the machine-readable allowed DAG.

**Per-module boundary pattern** (lines 122-134):

```markdown
### 7.1 `mb-core`

Owns shared byte containers, checked arithmetic helpers, stream and seek abstractions, bounded readers/writers, structured errors, diagnostics, logging interfaces, and capability boundaries for files or hosts. It does not own image, color, SVG, font, or PDF concepts.

### 7.2 `mb-color`

Owns color component types, transfer functions, color-space identifiers, conversion pipelines, alpha conventions, and ICC-facing contracts. It depends only on `mb-core`.
```

Continue the `Owns ... / does not own ... / depends on ...` form. This is the strongest existing boundary convention.

**Quality checklist pattern** (lines 196-207):

```markdown
## 12. Quality contract

A module is not stable until it has:

- formatting and static checks passing;
- unit, property, and conformance tests appropriate to the domain;
- a declared target matrix validated in CI;
- public API docs and runnable examples;
```

Convert broad claims into Phase 1-verifiable requirements and cross-link the executable policy. Remove the resolved `Open questions` at lines 240-247 or replace genuinely deferred matters with explicit follow-up ownership.

---

### Governance and policy documents

**Files:**

- `docs/rfcs/README.md`
- `docs/governance/rfc-process.md`
- `docs/policies/api-stability.md`
- `docs/policies/licensing-and-fixtures.md`
- `docs/policies/publication.md`
- `docs/policies/targets.md`
- `docs/policies/toolchain.md`

**Closest analogs:** `README.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, and RFC 0001.

**Status/scope pattern** (`README.md`, lines 9-19):

```markdown
## Status

Pre-implementation / RFC stage. No API is stable yet.

## Initial scope

- `mb-core`: byte buffers, streams, I/O abstractions, errors, and diagnostics
- `mb-color`: color types, conversions, and profile boundaries
- `mb-image`: image storage, pixel formats, transforms, and codec interfaces
```

Each policy document should begin with its current status/scope, state normative rules in compact lists or tables, and link the canonical machine-readable values in `policy/foundation.json` rather than duplicate independently editable facts.

**Active/out-of-scope separation** (`.planning/PROJECT.md`, lines 19-33):

```markdown
### Active

- [ ] Publish an accepted foundation RFC defining vision, terminology, layering, module boundaries, portability, and governance.
- [ ] Establish a reproducible multi-module repository and CI quality contract for Native and portable targets.

### Out of Scope

- Photoshop-, Figma-, or Office-class applications — applications are downstream consumers, not MNF deliverables.
- A GUI framework or game engine — MNF must remain runtime- and UI-independent.
```

Use explicit scope boundaries and reasons. Do not bring deferred numeric, image-lifetime, budget-default, or PPM decisions into Phase 1 policy.

**Requirement-verification wording** (`.planning/ROADMAP.md`, lines 25-31):

```markdown
**Success Criteria:**

1. A contributor can follow the accepted foundation RFC ...
2. A consumer can identify API stability promises ... from checked-in documentation or metadata.
3. From a clean clone, a developer can reproduce the recorded MoonBit toolchain ...
```

Prefer observable actor/outcome wording. The policy docs explain the rules; the validator proves their checked representations.

---

### `policy/foundation.json` (policy model, validation input)

**Partial analog:** `.planning/config.json`.

**JSON formatting pattern** (`.planning/config.json`, lines 1-13):

```json
{
  "mode": "yolo",
  "granularity": "coarse",
  "parallelization": true,
  "commit_docs": true,
  "model_profile": "inherit",
  "workflow": {
    "research": true,
    "plan_check": true
  }
}
```

Copy only the two-space indentation, quoted keys, booleans as booleans, and nested-object style. The schema itself has no analog. It must single-source:

- exact `moon`, `moonc`, and `moonrun` identities;
- required targets `js`, `wasm`, `wasm-gc`, `native`;
- module identities, paths, versions, public package inventory, and stability labels;
- allowed dependency edges;
- RFC allowed statuses and required acceptance fields;
- `publication.blocked: true` plus the namespace-ownership reason.

The PowerShell validator must use `ConvertFrom-Json`, validate enumerations and cross-artifact equality, and must not execute values from policy.

---

### `fixtures/manifest.json` (provenance model, validation input)

**Partial analog:** `.planning/config.json` for formatting only. There is no fixture-schema analog.

Start with a valid empty records collection plus an explicit schema/version marker chosen by the planner. Every non-empty record must require source, author, retrieval date, SHA-256, SPDX/license, redistribution status, and expected use. Externally sourced records with unconfirmed redistribution must fail validation. Generated fixtures remain preferred.

---

### Workspace and module scaffold files

**Files:** `moon.work`; all three `moon.mod.json`, `moon.pkg`, `README.mbt.md`, `CHANGELOG.md`, `scaffold.mbt`, and `scaffold_wbtest.mbt` files.

**Repository analog:** none for Moon syntax, manifests, tests, or changelogs. Root `README.md` is only a prose-layout analog for module READMEs.

**Workspace source pattern** (`01-RESEARCH.md`, lines 329-339):

```moonbit
members = [
  "./modules/mb-core",
  "./modules/mb-color",
  "./modules/mb-image",
]
```

Use exactly these three members. Do not add an umbrella module or path dependencies.

**Module metadata source pattern** (`01-RESEARCH.md`, lines 341-354):

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

Replicate the shape with the final intended identity for each module. Keep module versions and changelogs independent. Dependencies are normal module dependencies resolved by `moon.work`; dependency direction is `mb-core <- mb-color <- mb-image`, with `mb-image -> mb-core` allowed.

**README content pattern** (`README.md`, lines 9-27): use `Status`, scope, and design commitments sections. Each module README must visibly state `candidate` (unless deliberately experimental), the four supported targets, independent versioning, and publication-block status. Use checked `.mbt.md` examples, but do not expose a fake public domain API merely to make an example compile.

**Scaffold/test rule:** each package needs a real private build surface and a basic internal test while keeping the public interface empty or intentionally minimal. There is no repository analog; the planner should verify the exact syntax against the pinned toolchain. Do not introduce FFI, host access, or domain algorithms in Phase 1.

---

### PowerShell quality pipeline

**Files:**

- `scripts/quality.ps1`
- `scripts/quality/Assert-Policy.ps1`
- `scripts/quality/Assert-Toolchain.ps1`
- `scripts/quality/Invoke-MoonQuality.ps1`

**Repository analog:** none.

Use `scripts/quality.ps1` as the only public controller. Helpers are implementation services and should fail closed by throwing on a non-zero external process exit or invalid metadata. Avoid `Invoke-Expression`; use fixed command names and enumerated arguments.

**Required target-loop source pattern** (`01-RESEARCH.md`, lines 356-369):

```powershell
$requiredTargets = @('js', 'wasm', 'wasm-gc', 'native')
foreach ($target in $requiredTargets) {
  & moon check --target $target --deny-warn --frozen
  if ($LASTEXITCODE -ne 0) { throw "moon check failed for $target" }

  & moon test --target $target --frozen
  if ($LASTEXITCODE -ne 0) { throw "moon test failed for $target" }
}
```

**Required stage order:**

1. PowerShell major version and exact three-binary toolchain gate.
2. Policy, RFC header, fixture manifest, inventory, target metadata, and dependency-DAG validation.
3. `moon fmt --check`.
4. Explicit `check` and `test` for `js`, `wasm`, `wasm-gc`, and `native` with frozen dependency state.
5. `moon doc --frozen` and `moon info --target all --frozen`.
6. Per-module `moon -C <module> package --frozen --list` with allowed-content validation.

Do not run `moon work sync` inside quality validation because it mutates manifests and can conceal drift. LLVM belongs only to `-Lane LlvmExperimental`; it is never part of the required target contract.

---

### `.github/workflows/quality.yml` (CI provider, event-driven batch)

**Repository analog:** none.

**Pinned setup source pattern** (`01-RESEARCH.md`, lines 371-383):

```yaml
- name: Set up exact MoonBit toolchain
  uses: hustcer/setup-moonbit@bdc8c076af1f4c5012a6ac3451a2009ec75bf921
  with:
    version: 0.1.20260713+75c7e1f
- name: Run required quality lane
  shell: pwsh
  run: ./scripts/quality.ps1 -Lane Required
```

CI must call the same root entry point used locally, use read-only workflow permissions, expose no publication token, and retain the independent three-binary version gate. Put LLVM in a separate clearly named job with `continue-on-error: true`; do not mask failures in the required job.

## Shared Patterns

### Single source of executable truth

`policy/foundation.json` owns values automation compares. RFC/policy prose explains those values, module manifests declare their local subset, and quality validation rejects divergence. Do not create competing JSON sources for versions, targets, identities, or publication state.

### Explicit dependency direction

The existing RFC uses positive ownership plus negative boundary language and states that lower layers never import higher ones. Apply that rule to manifests and validate self-edges, unknown modules, reverse edges, and cycles.

### Fail-closed validation

Exact versions, enumerated statuses, target sets, required fixture fields, packaging allowlists, and external-command exit codes are mandatory. Normalize comparable values where ordering is irrelevant, but do not silently repair them.

### Documentation as evidence

Human documents use status, scope, and observable success criteria. Module `.mbt.md` documentation is checked by Moon. Accepted RFC metadata must point to real approval or elapsed-review evidence; automation may check evidence fields but may not invent governance evidence.

### No authentication or application error-response pattern

Phase 1 has no web controller, session, database, or untrusted network parser. There is therefore no repository authentication, request/response, or application error-handling pattern to copy. Relevant errors are deterministic PowerShell exceptions and non-zero process exits.

## No Analog Found

| Files | Role / Data Flow | Reason and planning source |
|---|---|---|
| `LICENSE` | legal config / file-I/O | No legal file exists; use canonical Apache-2.0 license text. |
| `moon.work` | workspace config / batch | No Moon workspace exists; use the verified research example. |
| All `moon.mod.json` and `moon.pkg` files | module/package config / dependency resolution | No Moon implementation exists; use official metadata shapes captured in research and validate with the pinned CLI. |
| All `CHANGELOG.md` files | release ledger / lifecycle | No changelog exists; initialize independent module histories without claiming a release that did not occur. |
| All `scaffold.mbt` and `scaffold_wbtest.mbt` files | private utility and internal test | No MoonBit code exists; create the smallest real private surface and test, with no fake public API. |
| All PowerShell quality files | controller/services / batch | No scripts exist; use the researched stage order and explicit exit checks. |
| `.github/workflows/quality.yml` | CI provider / event-driven batch | No workflow exists; use the full-SHA setup example and separate required/experimental lanes. |

## Metadata

**Analog search scope:** codebase-memory graph for the full repository, followed by targeted reads of `docs/rfcs/0001-moonbit-native-foundation.md`, `README.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/config.json`.

**Graph state:** 275 nodes / 273 edges; 13 indexed files; no functions, methods, classes, routes, or implementation packages.

**Files scanned as analog candidates:** 6 direct source files plus the indexed repository architecture.

**Pattern extraction date:** 2026-07-16
