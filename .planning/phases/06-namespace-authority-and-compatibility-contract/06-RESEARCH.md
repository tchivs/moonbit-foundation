# Phase 6: Namespace Authority and Compatibility Contract — Research

**Researched:** 2026-07-17  
**Status:** Ready for planning with explicit live-registry unknowns  
**Overall confidence:** HIGH for repository and pinned local CLI behavior; MEDIUM for documented Mooncakes behavior; LOW/unknown for unobserved authenticated and destructive registry semantics.

<user_constraints>
## User Constraints (Locked)

### Registry Authority Evidence

- **D-01:** A credential-redacted machine-readable contract is authoritative for namespace identity, canonical module names, pinned toolchain, exact version availability, publish seam, registry observation, and resolution facts. Human-readable prose may explain those facts but cannot override them.
- **D-02:** Keep the current `moonbit-foundation/*` manifest identities unchanged until the authenticated owner evidence proves that namespace. A mismatch is a fail-closed planning input, not permission to guess or silently rewrite names.
- **D-03:** Evidence records identity, timestamp, toolchain, command shape, sanitized result, and evidence digest. Tokens, cookies, authorization headers, credential paths, and secret-derived values are never recorded.

### Safe Capability Probing

- **D-04:** Every capability is classified as `documented`, `safely_observed`, or `unknown`, with source/evidence and a disposition. Unknown required facts block release; unknown optional/destructive capabilities select a fail-closed or forward-only recovery rule.
- **D-05:** Do not consume or mutate a production module version merely to test overwrite, delete, unpublish, yank, duplicate-publish, or propagation behavior. A disposable scratch identity may be used only when authority is already proven, the action cannot affect the three production modules, and the resulting public artifact is intentionally acceptable.
- **D-06:** Phase 6 may inspect local CLI help, authenticated identity/status, read-only registry responses, and official documentation. It must not perform the real `mb-core`, `mb-color`, or `mb-image` publication.

### Public-Interface Baselines

- **D-07:** Preserve both the pinned-toolchain raw interface output and a deterministic normalized representation for each public module/package/target. The raw form is evidence; the normalized form is the comparison authority.
- **D-08:** The classifier emits exactly `exact`, `additive`, `incompatible`, or `unknown`. It fails closed on parser ambiguity and never claims behavioral, resource-limit, or full semantic compatibility from interface text.
- **D-09:** Baseline identity includes toolchain versions, module/package name, target, normalization schema version, raw digest, and normalized digest. Two clean runs must produce the same normalized baseline.

### Candidate Policy and Publication Documentation

- **D-10:** One machine-checked project policy governs public-interface, supported-target, minimum-toolchain, and dependency-floor changes. Module changelogs and migration notes consume that policy rather than redefining it.
- **D-11:** For pre-1.0 modules: patches contain no incompatible delta; additive public API requires a minor release; incompatible changes require a minor release plus migration note. RFC evidence is additionally required only for module-boundary, architecture, or governance changes.
- **D-12:** Before publication, each module's documentation set must collectively provide exact install/import commands, candidate status, supported targets/toolchain, change class, changelog, support route, security-reporting route, and any migration note, using metadata that Mooncakes can render.

### Agent Discretion

- Exact JSON schema filenames and directory layout, provided authority facts, observations, baselines, and policy are separately versioned and machine-validated.
- Normalization mechanics and diagnostic wording, provided output is deterministic, reviewable, and fails closed on unknown syntax.
- Whether read-only observations are captured directly by PowerShell or a small helper, provided the existing credential-free Required boundary remains intact.

### Deferred Ideas

- Mooncakes OIDC or narrower publish federation — adopt only after official support is verified.
- Destructive registry recovery automation — no overwrite, delete, unpublish, or yank assumptions in v0.2.
- New module families and 1.0 stability — wait until publication and compatibility evolution are proven.
</user_constraints>

<phase_requirements>
## Phase Requirements

| Requirement | Research support |
|---|---|
| REG-01 | Define a redacted authority observation artifact binding authenticated identity, intended namespace, three module identities, toolchain, time, sanitized command result, and digest. Current namespace authority remains `unknown` until that artifact is captured. [VERIFIED: `.planning/REQUIREMENTS.md`, `06-CONTEXT.md`] |
| REG-02 | Model authentication, token scope, dry-run, version immutability, propagation, artifact identity, and destructive recovery as closed capability records with `documented`, `safely_observed`, or `unknown`. [VERIFIED: `.planning/REQUIREMENTS.md`, `06-CONTEXT.md`] |
| REG-03 | Make namespace authority, canonical names, pinned toolchain, version availability, authenticated publish seam, registry observation, and resolution mandatory-current facts; all other unknowns get fail-closed or forward-only dispositions. [VERIFIED: `.planning/REQUIREMENTS.md`, `06-CONTEXT.md`] |
| COMP-01 | Generate canonical raw `.mbti`, run all four target inspections, normalize deterministically per package/target record, and prove two clean normalized runs match. [VERIFIED: local `moon info --help` and clean-copy probe] |
| COMP-02 | Use only `exact`, `additive`, `incompatible`, and `unknown`; ambiguity is `unknown`. [VERIFIED: `06-CONTEXT.md`] |
| COMP-03 | Centralize API, supported-target, minimum-toolchain, and dependency-floor consequences in one compatibility policy. [VERIFIED: `.planning/REQUIREMENTS.md`] |
| COMP-04 | Require version/changelog/migration evidence, plus RFC evidence only for boundary, architecture, or governance changes. [VERIFIED: `.planning/REQUIREMENTS.md`, `docs/governance/rfc-process.md`] |
| PROV-03 | Machine-check each module's install/import, candidate status, targets/toolchain, change class, changelog, support/security routes, migration evidence, and renderable metadata. [VERIFIED: `.planning/REQUIREMENTS.md`] |
</phase_requirements>

## Summary

Phase 6 should add two deliberately separated planes: an operator-run, credential-redacted **observation plane** that may invoke safe authenticated/read-only commands, and the existing credential-free **Required validation plane** that validates tracked policy, schemas, observations, baselines, documentation, and fail-closed outcomes without materializing credentials. This preserves the v0.1 contract that records `performed=false`, `credentials_read=false`, and `namespace_verified=false` honestly until authenticated evidence exists. [VERIFIED: `scripts/quality/ReleaseQualification.Common.ps1`, `release/qualification/package-schema.json`]

The compatibility source is the pinned compiler's public interface output, but the comparison authority is a project-owned normalized model. `moon info --target <target>` inspects backend-specific interfaces while writing `pkg.generated.mbti` from the canonical preferred backend; it does not produce a different raw file for each requested target. Therefore each package/target record should reference the canonical raw digest and additionally record that target's inspection command and no-divergence result. Any reported divergence is `unknown` or `incompatible`, never silently folded into equality. [VERIFIED: installed `moon 0.1.20260713` help and clean-copy target probe]

Authenticated namespace ownership, token scope/revocation, duplicate-version behavior, propagation guarantees, registry artifact digest, overwrite/delete/yank semantics, and Mooncakes OIDC are currently **unknown**. They must not be inferred from a local credential file, a workspace resolution success, or generic registry practice. Required release facts block; destructive/optional unknowns select no-retry-without-query and forward-only recovery. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html]

## Architectural Responsibility Map

| Component | Owns | Must not own |
|---|---|---|
| `policy/registry-authority.json` | Intended identities, required fact freshness, capability dispositions, observation references | Credentials or fabricated live results |
| Authority observation schema/artifact | Sanitized authenticated/read-only facts and their digest | Tokens, cookies, headers, credential paths, destructive probes |
| `policy/compatibility.json` | Four change classes and version/evidence consequences | Compiler/interface generation or behavioral compatibility claims |
| Baseline generator | Canonical raw capture, target inspections, normalization, digests | Registry publication or policy decisions |
| Compatibility comparator | Structural delta classification and ambiguity handling | Automatic version rewriting |
| Documentation qualification | Manifest/README/changelog/support/security/migration consistency | Alternate policy truth |
| Existing Required orchestrator | Credential-free validation and deterministic report binding | Authentication or publication |

[VERIFIED: existing `policy/release-qualification.json`, `ReleaseQualification.Common.ps1`, and locked decisions]

## Project Constraints

- Core/shared implementation remains MoonBit; Phase 6 automation may be PowerShell because it operates the existing qualification boundary. [VERIFIED: `AGENTS.md`, existing `scripts/quality/*.ps1`]
- Portable public packages keep `js`, `wasm`, `wasm-gc`, and `native`; LLVM remains outside Required. [VERIFIED: `AGENTS.md`, three module manifests]
- Public package dependencies remain acyclic and independently versioned in order `mb-core` → `mb-color` → `mb-image`. [VERIFIED: `policy/release-qualification.json`]
- Required remains deterministic, credential-free, and honest about blocked external outcomes. [VERIFIED: `release/qualification/package-schema.json`, `ReleaseQualification.Common.ps1`]
- Semantic Versioning governs stable releases; this milestone intentionally applies the stricter D-11 candidate policy before 1.0. [CITED: https://semver.org/]
- No production publication, registry mutation, identity rewrite, new module family, or fabricated second approver is in scope. [VERIFIED: `06-CONTEXT.md`, sole-owner governance decision]

## Environment Availability

| Dependency/capability | Availability | Planning consequence |
|---|---|---|
| `moon 0.1.20260713 (75c7e1f)` | Available locally | Pin exact CLI identity in baseline and authority evidence. [VERIFIED: local CLI] |
| `moonc v0.10.4` / bundled `moonrun` | Available locally | Record the complete toolchain triplet, not only `moon`. [VERIFIED: local toolchain] |
| PowerShell 7.6.3 | Available locally | Reuse strict-mode JSON, hashing, negative-test, and orchestration patterns. [VERIFIED: local runtime] |
| Git 2.54.0.windows.1 | Available locally | Bind observations/baselines to commit and retain tracked-diff checks. [VERIFIED: local CLI] |
| Node 22.23.1 | Available for GSD tooling | Not required in the Phase 6 product contract. [VERIFIED: local CLI] |
| Official MoonBit documentation | Available | Establishes documented CLI/manifest behavior only. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html] |
| Authenticated Mooncakes identity/namespace | Unknown; intentionally not probed by reading credentials | Planning may proceed; production release remains blocked until a sanitized operator observation is captured. [VERIFIED: research boundary] |
| Scratch namespace safe for mutation | Unknown | Do not plan a mutation probe as an acceptance dependency. [VERIFIED: D-05] |

No new package or external runtime dependency is required. [VERIFIED: repository patterns and local CLI]

## Recommended Architecture

### 1. Authority facts and observations

Use separate versioned files so policy cannot be confused with a live observation:

- `policy/registry-authority.json`: intended namespace/module identities, required capabilities, maximum observation age, and unknown dispositions.
- `release/registry/authority-observation-schema.json`: closed schema for sanitized live evidence.
- `release/registry/capability-matrix-schema.json`: closed records for `documented|safely_observed|unknown`.
- `release/registry/authority-observation.json`: tracked sanitized evidence only after an operator deliberately captures it; before then, either omit it and report a precise blocker or use an explicit schema-valid `unknown` state.
- `scripts/quality/Invoke-RegistryObservation.ps1`: operator-only seam that invokes allowed commands, captures stdout/stderr, rejects secret-shaped or path-shaped fields, and emits sanitized JSON; it must never open a credentials file.
- `scripts/quality/Test-RegistryAuthority.ps1`: credential-free validator used by Required.

[VERIFIED: D-01 through D-06 and existing closed-schema patterns]

Each observation should contain: schema version, source commit, UTC observation time, `moon`/`moonc`/`moonrun` identities, command identifier plus allowlisted argument shape, sanitized identity/namespace/result, exact module/version facts, and SHA-256 over a stable object that excludes run-local paths/timestamps where repeatability is expected. Never store raw environment dumps or command output before redaction. [VERIFIED: D-03 and `Get-RequiredRunStableObject` pattern]

Initial capability dispositions:

| Capability | Current state | Disposition |
|---|---|---|
| CLI login/whoami/publish/package surfaces | `documented` | May inform an allowlist; documentation alone does not prove current authority. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html] |
| Username-prefixed module identity and SemVer version | `documented` | Canonical identity remains provisional until authenticated namespace proof. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html] |
| Authenticated `moonbit-foundation` authority | `unknown` | Blocks REG-01/REG-03 and publication. |
| Token scope, expiry, revocation, non-interactive auth | `unknown` | Blocks unattended publisher design; no credential inspection. |
| Dry-run fidelity | `unknown` | Dry-run can be evidence only after safely observed; never proof that publication will succeed. |
| Exact version availability | `unknown` until read-only observation | Blocks the corresponding module publish intent. |
| Version immutability / duplicate behavior | `unknown` | Never retry blindly; query state and correct forward. |
| Propagation timing/guarantee | `unknown` | Poll with a bounded timeout; timeout is ambiguous, not failure proof. |
| Registry artifact digest/byte identity | `unknown` | Do not claim byte identity; use consumer/interface/metadata evidence unless a canonical digest is exposed. |
| Delete/unpublish/yank/overwrite | `unknown` | No destructive recovery automation; forward-only release. |
| Mooncakes OIDC | `unknown` | Deferred; do not use generic GitHub OIDC as registry auth. |

[VERIFIED: reviewed official documentation and research boundary; unknown rows are explicit absence-of-proof statements]

### 2. Interface baselines

Recommended layout:

```text
compatibility/
  schema/
    baseline-schema.json
    comparison-schema.json
  baselines/0.1.0/
    mb-core/<package>/raw.mbti
    mb-core/<package>/baseline.json
    mb-color/<package>/...
    mb-image/<package>/...
policy/compatibility.json
scripts/quality/New-PublicInterfaceBaseline.ps1
scripts/quality/Compare-PublicInterfaceBaseline.ps1
scripts/quality/Test-PublicCompatibility.ps1
```

[ASSUMED: exact filenames are agent discretion; responsibilities are locked]

Generation algorithm:

1. Verify exact toolchain and clean isolated copy; run with `--frozen`. [VERIFIED: existing quality conventions]
2. Run `moon info` for the module and preserve every canonical `pkg.generated.mbti` as UTF-8 raw evidence before normalization. [VERIFIED: local CLI]
3. Independently invoke target inspection for `js`, `wasm`, `wasm-gc`, and `native`; record exit code and sanitized difference status for each target. Do not describe the canonical raw file as target-generated. [VERIFIED: local `moon info --help`]
4. Parse only a closed, versioned subset of known `.mbti` syntax. Canonicalize line endings, representation fields, declaration ordering rules, and JSON serialization explicitly. Unknown syntax returns `unknown`; it is never dropped. [VERIFIED: D-07/D-08]
5. Emit one record per module/package/target containing toolchain, module/package, target, normalization schema, canonical raw digest, normalized digest, and target inspection result. [VERIFIED: D-09]
6. Repeat in a second independent clean copy and require identical normalized records. Keep both run summaries, but commit one canonical baseline. [VERIFIED: D-09]

The local research probe ran `moon info --target js|wasm|wasm-gc|native|all --frozen` in a clean copy. All invocations exited successfully, emitted no target-difference warning, and the six `mb-core` raw interface files produced the same combined SHA-256 `0ffef8be8360f62a817769457c0f3033f46e219b995e6c1bcde522ecd4125f8a`. This is evidence for this pinned machine snapshot only, not a cross-machine stability guarantee. [VERIFIED: local clean-copy probe]

### 3. Deterministic comparison rules

The normalized model should preserve package identity/imports plus each public type, alias, trait, method, function, error, visibility, generic constraint, parameter, and return signature exposed by the current grammar. If a declaration cannot be represented losslessly, the whole affected package/target is `unknown`. [ASSUMED: parser field list must be reconciled with actual generated grammar during implementation]

Classification precedence:

1. `unknown`: parse failure, unrecognized syntax, target divergence, missing baseline, toolchain mismatch without an approved baseline migration, or ambiguous matching.
2. `incompatible`: removed/renamed public declaration; changed kind, signature, constraints, visibility, identity, supported target, or dependency floor contrary to policy.
3. `additive`: old normalized declarations remain exact and only permitted public declarations were added.
4. `exact`: normalized structures and all policy-controlled compatibility facts match.

[VERIFIED: D-08, D-10, D-11; detailed declaration matching is project-owned]

Do not infer runtime behavior, numeric tolerances, resource budgets, representation layout, performance, or semantic equivalence from `.mbti`. Those remain owned by conformance tests and other phase evidence. [VERIFIED: COMP-01 and D-08]

### 4. Candidate version and evidence policy

`policy/compatibility.json` should be the only owner of consequences:

| Delta | Minimum pre-1.0 version action | Required evidence |
|---|---|---|
| `exact` | Patch permitted | Changelog/change-class entry; all other gates pass |
| `additive` | Minor required | Changelog and exact added-surface report |
| `incompatible` | Minor required | Changelog plus migration note; RFC only when boundary/architecture/governance is affected |
| `unknown` | No release | Resolve ambiguity and regenerate evidence |

[VERIFIED: D-10/D-11]

Supported-target removal is incompatible; adding a required target is at least additive and must be checked for architecture implications. Raising a minimum toolchain or dependency floor is policy-controlled and must not be hidden inside manifest drift. Dependency direction or module-boundary changes additionally route through the accepted RFC process. [VERIFIED: COMP-03/COMP-04, `docs/governance/rfc-process.md`]

### 5. Registry-renderable publication documentation

Extend the canonical policy with a per-module documentation contract and validate the collective set rather than requiring every fact in every file:

- `moon.mod.json`: exact name/version, description, Apache-2.0 license, repository, README path, preferred/supported targets, exact dependency floors; add only metadata fields confirmed supported by the pinned toolchain/documentation.
- `README.mbt.md`: exact install command, exact public-package import examples, candidate status, supported targets, pinned toolchain/minimum floor, current compatibility class, support route, security-reporting route, changelog and migration links.
- `CHANGELOG.md`: version, candidate/publication status, change class, additions/removals, and migration link when required.
- Project-owned support/security documents: stable public routes referenced identically by all modules.
- Migration note: required for incompatible changes; absent only when policy says not applicable.

[VERIFIED: existing manifests/readmes/changelogs, PROV-03, D-12; Mooncakes renders manifest/README metadata per official docs]

Because actual registry rendering has not been observed safely, `registry_renders_intended_metadata` remains `unknown` and blocks the final PROV-03 publication claim until a read-only registry page/API observation is captured after a non-production-safe opportunity or the real publication in its later phase. Phase 6 can fully validate renderable source metadata without claiming rendered equality. [VERIFIED: requirement boundary and absence of observation]

## Integration with Existing Quality Architecture

Reuse these established mechanisms:

- `Read-ReleaseJson`, `Assert-ReleaseExactSequence`, `Assert-ReleaseExactSet`, and `Assert-ReleaseClosedProperties` for closed input validation. [VERIFIED: `ReleaseQualification.Common.ps1`]
- `Get-ReleaseSha256` / `Get-ReleaseTextSha256` and UTF-8-no-BOM JSON with a trailing newline for content identity. [VERIFIED: `ReleaseQualification.Common.ps1`, `Invoke-ReleaseQualification.ps1`]
- Stable-object digests that exclude run-local metadata while retaining a separate run-local section. [VERIFIED: `Get-RequiredRunStableObject`]
- Rule-owned negative fixtures and exact rejection diagnostics for unknown syntax, unexpected properties, stale observations, target drift, incompatible delta, insufficient version bump, missing migration/RFC, and documentation mismatch. [VERIFIED: `Test-ReleaseQualificationNegative.ps1`]
- Tracked-diff snapshots so generators and validators cannot mutate source during Required. [VERIFIED: `Assert-ReleaseTrackedSnapshot`]

Do not alter the meaning or schema of the locked v0.1 Required report. Add new Phase 6 selectors/artifacts beside it, and let the top-level Required lane aggregate both contracts. [VERIFIED: `release/qualification/v0.1-requirements.json`, phase context]

## Exact Planning Tasks

1. **Authority contracts:** add registry authority policy, observation schema, capability schema, credential-free validator, and negative fixtures; keep all required live facts `unknown` until sanitized evidence exists.
2. **Safe observation seam:** add an operator-only allowlisted PowerShell collector that never reads credential files and refuses secret-shaped output; do not invoke it in Required.
3. **Baseline schema/generator:** capture canonical raw interfaces and four target inspections for all 17 current public packages, then prove two-clean-run normalized equality. [VERIFIED: `policy/release-qualification.json` currently lists 6+5+6 packages]
4. **Comparator/policy:** implement the four-class structural comparator and centralized API/target/toolchain/dependency-floor consequences with ambiguity negatives.
5. **Documentation qualification:** complete install/import, toolchain, change-class, support/security, changelog, and migration contracts across all three modules; validate renderable source metadata while retaining registry-render result as `unknown`.
6. **Required integration:** add selectors/artifact digests without weakening the existing credential-free report or blocked publication truth.

## Common Pitfalls

- Treating `moon whoami` success as proof of authority over `moonbit-foundation`; identity and namespace authorization are separate facts. [VERIFIED: REG-01/D-01]
- Reading or hashing the credentials file to prove authentication; credential paths and secret-derived values are forbidden evidence. [VERIFIED: D-03]
- Treating `moon publish --dry-run` as a registry authority or immutability guarantee. [VERIFIED: current capability is unknown]
- Testing duplicate/delete/yank/overwrite against a production identity. [VERIFIED: D-05]
- Treating workspace dependency resolution as registry resolution. [VERIFIED: existing qualification distinguishes artifact and registry outcomes]
- Claiming four raw target baselines when `moon info --target` writes the canonical backend interface. [VERIFIED: local CLI help]
- Normalizing away unknown syntax or comments/attributes whose meaning is uncertain. [VERIFIED: D-08]
- Calling textual equality behavioral compatibility. [VERIFIED: COMP-01]
- Allowing README/changelog prose to override policy JSON. [VERIFIED: existing policy ownership pattern]
- Changing a baseline and implementation together without an independently reviewable delta report. [ASSUMED: recommended review control]

## Security Domain

Phase 6 touches authentication evidence and namespace authorization, but does not implement credential storage or a publisher. [VERIFIED: phase boundary]

| Area | Required treatment |
|---|---|
| Authentication (V2) | Invoke only allowed status/read-only commands through the operator seam; never open or copy credentials; sanitize before persistence. |
| Session lifecycle (V3) | Token expiry/revocation/non-interactive lifecycle is `unknown`; do not claim unattended readiness. |
| Access control (V4) | Prove exact owner namespace and canonical module identities; mismatch blocks and never triggers an automatic rename. |
| Input validation (V5) | Closed schemas, exact enums/sets, allowlisted command shapes, strict paths, and rejection of extra properties. |
| Cryptography (V6) | Use platform SHA-256 only for integrity; no custom cryptography and no claim that a digest authenticates registry authority. |

[VERIFIED: D-01 through D-06 and repository helper patterns]

STRIDE-focused threats and controls:

- **Spoofing:** fabricated username/namespace → bind sanitized command result, toolchain, time, commit, and evidence digest; retain `unknown` without proof.
- **Tampering:** edited observation/baseline → closed schema, SHA-256, tracked review, stable-object recomputation.
- **Repudiation:** unclear operator/run → record non-secret identity, UTC time, command identifier, and source commit.
- **Information disclosure:** token/path/header leakage → allowlist output fields, reject secret/path shapes, never preserve raw auth output.
- **Denial/ambiguity:** propagation timeout or partial response → bounded polling and `unknown`, never blind retry.
- **Elevation of privilege:** local login mistaken for namespace authority → require explicit namespace authorization evidence.

[VERIFIED: security analysis against locked evidence contract]

## Claim Provenance

| Claim family | Confidence | Source |
|---|---|---|
| Existing schema, hashing, deterministic-report, negative-test, and credential-free patterns | HIGH | Repository files inspected directly. |
| Installed CLI behavior and canonical-target interface behavior | HIGH for this machine | Local help and clean-copy execution on 2026-07-17. |
| MoonBit naming, publishing, SemVer, manifest, README, and command surfaces | MEDIUM | Official MoonBit documentation linked below. |
| Released-content immutability and SemVer vocabulary | MEDIUM | SemVer 2.0.0 specification. |
| Authenticated namespace authority and unobserved Mooncakes semantics | Unknown | Deliberately no credential read, production mutation, or unsupported inference. |

## Open Unknowns

These do not block Phase 6 planning or credential-free implementation, but required ones block publication:

1. Does the authenticated account have authority over the exact `moonbit-foundation` owner namespace and all three names? **Required; blocks release.**
2. What are the real token scope, expiry, revocation, and non-interactive authentication semantics? **Required for the Phase 7 unattended publisher; currently unknown.**
3. Does dry-run contact the registry and faithfully check namespace/version availability? **Unknown; do not rely on it alone.**
4. Are published versions immutable, and what exact response represents duplicate/ambiguous publication? **Unknown; forward-only/no-blind-retry.**
5. What propagation signal and bound are reliable after publication? **Unknown; bounded observation and ambiguity state.**
6. Does Mooncakes expose a canonical artifact digest? **Unknown; do not claim byte identity.**
7. What delete/unpublish/yank/overwrite semantics exist? **Unknown and intentionally not probed; no destructive recovery.**
8. Does Mooncakes render every intended manifest/README field exactly? **Unknown until safe registry-side observation.**
9. Is `.mbti` normalization stable across supported clean machines on the pinned toolchain? **Phase 6 must prove two clean runs; current research proves only the local snapshot.**

## Sources

### Primary repository sources

- `.planning/phases/06-namespace-authority-and-compatibility-contract/06-CONTEXT.md`
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/research/SUMMARY.md`
- `policy/release-qualification.json`
- `release/qualification/package-schema.json`, `release/qualification/v0.1-requirements.json`
- `scripts/quality/ReleaseQualification.Common.ps1`
- `scripts/quality/Invoke-ReleaseQualification.ps1`
- `scripts/quality/Test-ReleaseQualification.ps1`
- `scripts/quality/Test-ReleaseQualificationNegative.ps1`
- `modules/mb-{core,color,image}/moon.mod.json`, `README.mbt.md`, and `CHANGELOG.md`
- `docs/policies/{publication,api-stability,targets}.md`
- `docs/governance/rfc-process.md` and sole-owner bootstrap decision

### Official external sources

- [MoonBit: Use and publish packages](https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html)
- [MoonBit: Command-line help](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html)
- [MoonBit: Module configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html)
- [MoonBit: Package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)
- [Semantic Versioning 2.0.0](https://semver.org/)

## Research Metadata

**Nyquist validation architecture:** intentionally omitted because `.planning/config.json` sets `workflow.nyquist_validation=false`. [VERIFIED: project configuration]

**Research conclusion:** Ready for plan generation. Plan around the credential-free contract now; preserve authenticated and registry-side facts as explicit `unknown` until a later safe operator observation supplies evidence.
