# Phase 6: Namespace Authority and Compatibility Contract — Research

**Researched:** 2026-07-17  
**Domain:** Pre-publication Mooncakes identity correction, registry-authority evidence, and compatibility/release qualification
**Confidence:** HIGH for repository and local environment facts; HIGH for cited username-namespace rules; LOW/unknown for unobserved Mooncakes account and destructive-registry semantics

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Registry Authority Evidence

- **D-01:** A credential-redacted machine-readable contract is authoritative for namespace identity, canonical module names, pinned toolchain, exact version availability, publish seam, registry observation, and resolution facts. Human-readable prose may explain those facts but cannot override them.
- **D-02:** The authenticated personal GitHub identity `tchivs` is the intended initial Mooncakes owner. Canonical unpublished module identities are `tchivs/mb-core`, `tchivs/mb-color`, and `tchivs/mb-image`; `moonbit-foundation/*` is no longer an intended registry identity.
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

### Personal Namespace Transition

- **D-13:** Because no `moonbit-foundation/*` version has been published, the identity change is a pre-publication bootstrap correction, not a SemVer release break. Keep candidate version `0.1.0`, rewrite every active canonical module/package/dependency identity, and regenerate the 0.1.0 interface baselines from clean pinned-toolchain runs.
- **D-14:** Preserve archived v0.1 planning and verification artifacts as historical evidence. Active policies, source modules, generated baselines, qualification consumers, release documents, and owning tests must use `tchivs/*`; negative fixtures may retain an old identity only when explicitly proving drift rejection.
- **D-15:** Project branding remains **MoonBit Native Foundation**. The registry owner is an operational personal namespace and does not rename the foundation or add a new module family.
- **D-16:** If an organization namespace becomes available later, treat it as new module identities with an explicit migration and forward-only publication plan. Never assume Mooncakes supports rename, transfer, overwrite, delete, unpublish, or yank.
- **D-17:** `https://github.com/tchivs/moonbit-foundation` is intended repository metadata but is currently unproven because the remote repository does not exist. Source documents must not claim that route is live; external repository creation requires separate authorization, and release readiness requires a later read-only existence check.
- **D-18:** The Mooncakes user record for `tchivs` is currently absent. Replanning must keep publication fail-closed until `moon register` or `moon login` completes and the sanitized collector proves the exact authenticated account, namespace, and three module identities without persisting credentials or raw output.

### the agent's Discretion

- Exact JSON schema filenames and directory layout, provided authority facts, observations, baselines, and policy are separately versioned and machine-validated.
- Normalization mechanics and diagnostic wording, provided output is deterministic, reviewable, and fails closed on unknown syntax.
- Whether read-only observations are captured directly by PowerShell or a small helper, provided the existing credential-free Required boundary remains intact.

### Deferred Ideas (OUT OF SCOPE)

- Mooncakes OIDC or narrower publish federation — adopt only after official support is verified.
- Destructive registry recovery automation — no overwrite, delete, unpublish, or yank assumptions in v0.2.
- New module families and 1.0 stability — wait until publication and compatibility evolution are proven.
- Optional migration from `tchivs/*` to a future organization-owned namespace — only after that namespace exists and a separate migration RFC/release plan is accepted.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| REG-01 | Verify the authenticated Mooncakes owner namespace and all three final module names with credential-free repository evidence. | The intended owner is `tchivs`; the repo already has a redacted observation schema/collector, but the Mooncakes account and exact identity proof remain human-gated. [VERIFIED: `06-CONTEXT.md`, local read-only probes] |
| REG-02 | Produce a redacted capability matrix without consuming a production version. | Retain the existing closed matrix and refresh only documented/read-only facts; mutation-only and destructive semantics remain `unknown` with explicit dispositions. [VERIFIED: `release/registry/capability-matrix.json`, D-04 through D-06] |
| REG-03 | Fail closed unless authority, canonical identities, toolchain, exact version availability, authenticated publish seam, observation, and resolution are current. | First migrate active truth to `tchivs/*`, then require a fresh sanitized observation; repository migration alone cannot satisfy live authority. [VERIFIED: `policy/registry-authority.json`, D-18] |
| COMP-01 | Reproducibly generate baselines for every public package and four targets without behavioral claims. | The current 17-package/68-record baseline is identity-bound to `moonbit-foundation/*` and must be regenerated twice after the source migration. [VERIFIED: `compatibility/baselines/0.1.0/manifest.json`, D-07 through D-09, D-13] |
| COMP-02 | Classify deltas as exact, additive, incompatible, or unknown. | Preserve the completed comparator and re-run its positive/negative suite against regenerated identities; parser ambiguity remains fail-closed. [VERIFIED: completed 06-03 summary, D-08] |
| COMP-03 | Govern API, supported-target, toolchain-floor, and dependency-floor changes. | Preserve the completed machine policy; treat this unpublished owner correction as identity rebasing, not a SemVer delta. [VERIFIED: D-10, D-11, D-13] |
| COMP-04 | Enforce version/changelog/migration and conditional RFC evidence. | Revalidate the completed gate after identity migration; do not fabricate a migration note for an unpublished identity, but retain future forward-migration rules. [VERIFIED: D-11, D-13, D-16] |
| PROV-03 | Qualify install/import, candidate status, targets/toolchain, change class, support/security routes, changelog, migration, and intended metadata. | Rewrite active module documentation to `tchivs/*`, keep branding, and mark the intended GitHub repository route as not yet live until read-only verification succeeds. [VERIFIED: D-12, D-14, D-15, D-17] |
</phase_requirements>

## Summary

Phase 6 must now repair a pre-publication identity assumption before resuming live authority proof. Official MoonBit documentation says a Mooncakes module name must begin with the publishing username, and the official tutorial instructs users to authenticate/register with an existing GitHub account and use `<github account>/<project>` as the module name. MoonBit's official Mooncakes introduction likewise describes an independent `<username>/<package_name>` namespace per user. Those rules directly support `tchivs/mb-core`, `tchivs/mb-color`, and `tchivs/mb-image` as the locked initial identities. [CITED: https://docs.moonbitlang.com/en/stable/toolchain/moon/module.html; https://docs.moonbitlang.com/en/stable/tutorial/tour.html; https://www.moonbitlang.com/blog/intro-to-mooncakes]

This is not a three-manifest edit. A targeted audit found 161 active repository files outside archived v0.1 milestone material that contain the old canonical module family, plus 306 generated `_build` files. The old values span manifests, `moon.pkg` imports, policies, schemas, qualification consumers, examples, benchmark consumers, documentation, compatibility baselines, and owning tests. Completed Phase 6 summaries must remain truthful historical records; the correction needs a new remediation plan that changes active truth sources and regenerates derived evidence. [VERIFIED: local `rg` audit on 2026-07-17; D-13/D-14]

The repo-local migration can proceed without Mooncakes credentials. Live authority cannot: the authenticated GitHub CLI identity is `tchivs`, but the intended GitHub repository does not yet exist and `https://mooncakes.io/api/v0/users/tchivs` returned HTTP 404 during a read-only probe. No login, registration, external repository creation, or publication was performed. The plan must therefore finish all credential-free identity work first, then stop at a narrowly defined human OAuth/account-registration checkpoint, and only afterward run the sanitized read-only collector. [VERIFIED: local `gh api user`, `gh repo view`, and Mooncakes read-only HTTP probe on 2026-07-17]

**Primary recommendation:** add an explicit personal-namespace remediation plan before the revised 06-01 authority checkpoint; regenerate all active 0.1.0 identity-bound evidence, then require the user to register/login to Mooncakes and separately authorize/create the GitHub repository before REG-01 through REG-03 can become green.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Canonical unpublished identities | Repository policy | Module manifests/import graph | Policy owns exact identities; manifests and imports consume them. [VERIFIED: current architecture] |
| Source identity migration | Source/configuration | Tests and examples | Every active package path and dependency edge must move atomically. [VERIFIED: local audit] |
| Interface baseline regeneration | Build/evidence | Compatibility gate | Generated evidence is identity-bound and must follow source truth. [VERIFIED: baseline manifest/schema] |
| Authenticated account registration | External Mooncakes/GitHub OAuth | Human operator | It cannot be satisfied by repository edits or credential-free CI. [CITED: official tutorial] |
| Authority observation | Operator-only collector | Repository evidence validator | Collector may observe a session; Required validates only sanitized tracked evidence. [VERIFIED: existing collector/validator boundary] |
| Publication readiness | Credential-free release gate | External read-only checks | Missing or stale required facts block; publication remains out of scope. [VERIFIED: REG-03/D-06] |
| Project branding | Documentation/governance | Registry metadata | MoonBit Native Foundation remains the product identity while `tchivs` is the initial registry owner. [VERIFIED: D-15] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models remain MoonBit; Phase 6 automation follows the existing PowerShell qualification seam. [VERIFIED: `AGENTS.md`, `scripts/quality/`]
- Native remains primary, with `js`, `wasm`, `wasm-gc`, and `native` supported through explicit boundaries and conformance tests. [VERIFIED: `AGENTS.md`, active policy]
- Public module dependencies remain acyclic and ordered `mb-core` → `mb-color` → `mb-image`. [VERIFIED: `AGENTS.md`, `policy/release-qualification.json`]
- FFI remains small, isolated, documented, and replaceable; this phase adds none. [VERIFIED: `AGENTS.md`]
- Public API stability, deterministic automation, reproducible performance claims, and RFC-governed boundary changes remain mandatory. [VERIFIED: `AGENTS.md`]
- Code discovery should prefer the project knowledge graph, but no `.planning/graphs/graph.json` was present and the injected graph MCP tools were unavailable, so targeted `rg` was the documented fallback. [VERIFIED: local environment, `AGENTS.md`]
- GSD planning/execution artifacts must remain synchronized; this research modifies only `06-RESEARCH.md`. [VERIFIED: `AGENTS.md`, assigned scope]
- Sole-owner governance remains in force; do not add team approvals, quorum, or separation of duties. [VERIFIED: requirements out-of-scope and context]

## Standard Stack

No external package installation is required. Reuse the pinned project toolchain and existing repository helpers. [VERIFIED: local environment and existing implementation]

| Tool/component | Verified version/state | Purpose | Planning rule |
|---|---|---|---|
| `moon` | `0.1.20260713 (75c7e1f 2026-07-13)` | Check, info, package, dry-run surfaces | Keep the exact CI/tool evidence pin. [VERIFIED: local CLI] |
| `moonc` | `v0.10.4+2cc641edf (2026-07-15)` | Compiler identity in baselines | Record with every regenerated baseline. [VERIFIED: local CLI] |
| `moonrun` | `0.1.20260713 (75c7e1f 2026-07-13)` | Runtime identity | Record in evidence triplet. [VERIFIED: local CLI] |
| PowerShell | `7.6.3` | Deterministic policy, schema, hashing, and negative tests | Reuse strict-mode helpers; no new runtime. [VERIFIED: local runtime] |
| Git | `2.54.0.windows.1` | Source binding and clean-copy generation | Preserve user-dirty files and bind evidence to a commit. [VERIFIED: local CLI] |
| GitHub CLI | `2.96.0`; authenticated as `tchivs` | Read-only identity/repository observation | Do not create the absent repo without explicit authorization. [VERIFIED: local CLI] |
| Mooncakes | user `tchivs` absent at probed endpoint | Future account/namespace authority | Human registration/login is blocking; do not automate OAuth. [VERIFIED: read-only HTTP 404] |

## Package Legitimacy Audit

Not applicable: this phase installs no external npm, PyPI, Cargo, or Mooncakes dependency. [VERIFIED: implementation scope]

## Architecture Patterns

### System flow

```text
locked identity policy (tchivs/*)
        ↓
active manifests/imports/docs/consumers/tests migrate atomically
        ↓
clean pinned-toolchain checks + two-run baseline regeneration
        ↓
credential-free compatibility/documentation/Required gates
        ↓
human Mooncakes register/login (+ separately authorized GitHub repo setup)
        ↓
operator-only sanitized read-only observation
        ↓
credential-free authority validator
        ↓
REG-01..03 green or fail-closed blocker
```

### Pattern 1: Policy-first identity rebasing

Update the exact identity owner in `policy/registry-authority.json`, then make manifests, dependencies, package imports, examples, qualification consumers, release policy, documentation, and tests agree with that owner. Do not use a blind replacement for the project brand or for negative fixtures. [VERIFIED: D-14/D-15]

Identity mapping:

| Old active identity | New canonical identity |
|---|---|
| `moonbit-foundation/mb-core` | `tchivs/mb-core` |
| `moonbit-foundation/mb-color` | `tchivs/mb-color` |
| `moonbit-foundation/mb-image` | `tchivs/mb-image` |

The string `MoonBit Native Foundation`, RFC titles, and project-level names remain unchanged. The old owner string is permitted only in archived v0.1 evidence and explicit negative drift fixtures. [VERIFIED: D-14/D-15]

### Pattern 2: Regenerate identity-bound evidence

After all active sources compile under `tchivs/*`, run the existing baseline generator from clean copies twice with the pinned toolchain. Replace the active `compatibility/baselines/0.1.0` manifest, raw `.mbti` evidence, normalized baseline records, and digests as one generated set. Keep version `0.1.0`, package count 17, target count 4, and record count 68 unless the generator proves an intentional structural change. [VERIFIED: D-07 through D-09, D-13]

### Pattern 3: Human external checkpoint, machine verification afterward

Repository work must never invoke interactive `moon register` or `moon login`. The user performs OAuth/account creation outside Required; afterward the existing allowlisted collector records only sanitized identity, namespace, module identities, toolchain, timestamp, command shape, and stable digest. Raw output and credentials never enter git. [VERIFIED: D-03, D-18]

### Pattern 4: Honest repository metadata

`https://github.com/tchivs/moonbit-foundation` is the intended route, not a currently live source URL. Until separately authorized creation and read-only existence verification, active source documents and release evidence must distinguish `intended` from `verified_live`; they must not silently replace one false live URL with another. [VERIFIED: D-17 and local GitHub read-only probe]

## Runtime State Inventory

This is a rename/migration phase; all five runtime-state categories were checked explicitly.

| Category | Items Found | Action Required |
|---|---|---|
| Stored data | No application database, Redis store, or service datastore is part of this repository. Tracked JSON policies/evidence and compatibility records are files, not hidden runtime data. | **Code/data-file edit:** migrate active tracked JSON. **Data migration:** none outside tracked files. Preserve archived v0.1 files. [VERIFIED: repository architecture and targeted inventory] |
| Live service config | GitHub CLI is authenticated as `tchivs`; `tchivs/moonbit-foundation` does not exist. The Mooncakes `tchivs` user endpoint returned 404. A local Moon session previously reported authenticated state, but the exact account was not safely parseable. | **External human action:** register/login Mooncakes via GitHub OAuth. **Separate authorization:** create the GitHub repo only if the user authorizes it. **Read-only verification:** prove both routes afterward. No service-side rename exists because nothing was published. [VERIFIED: local probes and current observation] |
| OS-registered state | No Windows Scheduled Task with `moonbit`, `mooncakes`, or `mnf` in its task name/path was found. The project is not installed as a service. | **OS migration:** none. Recheck only if later publisher automation registers a runner/service. [VERIFIED: local task inventory] |
| Secrets and env vars | No environment-variable names matching Moon/registry/token/publish were present in the current process, and the repository search found no configured publisher secret name. The local Moon home has a registry directory; credential contents were not inspected. | **Code edit:** none now. Phase 7 must choose and validate an isolated secret contract. **Secret migration:** none known; never inspect or persist local credentials for Phase 6. [VERIFIED: name-only environment scan and repository scan] |
| Build artifacts / installed packages | 306 `_build` files contain old canonical package identities. `C:\Users\Admin\.moon\registry` exists and may contain cached registry/index state, but it was not searched for credential material or mutated. | **Build migration:** clean/regenerate repository build outputs after source migration; do not commit `_build`. **Installed/cache migration:** do not rewrite global registry state; later cold-consumer proofs must use an isolated Moon home. [VERIFIED: local `rg` count and Moon-home directory listing] |

Canonical answer: after every tracked active file is updated, stale `_build` outputs and external identity state still remain. `_build` is safely regenerated; Mooncakes account/repository state is verified through read-only observations, not edited as local data. [VERIFIED: runtime inventory]

## Active Source Migration Surface

The planner must enumerate files from generators/policies rather than hard-code the 161-file audit snapshot, but the following categories are mandatory. [VERIFIED: local audit]

| Category | Required handling |
|---|---|
| Module manifests and `moon.pkg` imports | Rewrite module names and all inter-module package imports to `tchivs/*`; keep versions `0.1.0`. |
| Examples, benchmarks, qualification consumers | Rewrite dependency identities and package imports; prove all four targets where currently required. |
| Policy, registry authority, schemas, qualification reports | Make `tchivs` and the three exact identities canonical; keep publication blocked until fresh authority evidence. |
| Baselines | Regenerate all 17 packages × 4 targets; never string-edit digests. |
| Active release/docs/RFC references | Update registry identity examples while preserving foundation branding and archived milestone history. |
| Tests and negative fixtures | Update positive expected truth; retain old identity only in named negative drift cases. |
| Repository URL | Represent the `tchivs` route as intended/unverified until it exists; do not claim support/security links are live through an absent repo. |
| Historical planning | Do not edit `.planning/milestones/v0.1-*`; completed Phase 6 summaries remain historical and a new remediation summary records the correction. |

## Compatibility and Versioning Consequences

- Keep candidate version `0.1.0`: no old Mooncakes identity was published, so there is no consumer-visible SemVer contract to bump. [VERIFIED: D-13]
- Regenerate, do not compare-and-approve, the active 0.1.0 baselines because package identity is part of baseline identity. [VERIFIED: D-09/D-13]
- Preserve the four-class comparator and candidate policy; the identity correction is a bootstrap rebase, not a fifth delta class. [VERIFIED: D-08/D-13]
- A future move from `tchivs/*` to an organization namespace is a new identity family with explicit migration and forward publication. Do not assume registry transfer/rename semantics. [VERIFIED: D-16]
- Interface text remains evidence of public surface only, never behavioral, resource, layout, or performance compatibility. [VERIFIED: COMP-01/D-08]

## Registry Capability Matrix Recommendation

| Capability | Current state | Disposition |
|---|---|---|
| Username-prefixed module identity | `documented` | `tchivs/*` is the only planned initial owner family. [CITED: official module docs/tutorial/blog] |
| CLI `login`, `register`, `publish`, package surfaces | `documented` and locally help-observed | Allowlist command shapes only; help does not prove account authority. [CITED: official command docs; VERIFIED: pinned CLI help] |
| GitHub identity `tchivs` | `safely_observed` | Useful external identity input, not Mooncakes authority proof. [VERIFIED: `gh api user`] |
| Mooncakes account/namespace authority | `unknown` | Block REG-01/03 until human registration/login and sanitized exact proof. [VERIFIED: HTTP 404 and D-18] |
| Exact `0.1.0` availability for three identities | `unknown` | Require a safe read-only query after account creation. |
| Authenticated publish seam/token lifecycle | `unknown` | Block the Phase 7 publisher design until safely observed/documented. |
| Dry-run fidelity | `unknown` | Never treat CLI `--dry-run` presence as semantic equivalence to publication. [VERIFIED: help exposes flag; fidelity unobserved] |
| Immutability/duplicate behavior | `unknown` | Query before retry; forward correction on mismatch. |
| Propagation and artifact identity | `unknown` | Bounded read-only observation; timeout is ambiguous. |
| Delete/unpublish/yank/overwrite/transfer/rename | `unknown` | No destructive automation; forward-only recovery. |
| Rendered metadata | `unknown` pre-publication | PROV-05 remains a post-publication read-only proof. |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Namespace allocation | A fake organization/alias layer | Official personal username namespace | Mooncakes names are username-prefixed. [CITED: official docs] |
| Identity migration | Blind global search/replace | Policy-driven category audit plus exact negative fixtures | Branding, history, and drift fixtures intentionally differ. [VERIFIED: D-14/D-15] |
| Baseline migration | String-editing `.mbti`/JSON/digests | Existing clean-run generator | Digests and normalized records must derive from real source/toolchain output. [VERIFIED: D-07/D-09] |
| OAuth automation | Scripted browser/token scraping | Human `moon register`/`moon login`, then sanitized collector | Credentials/raw auth output are forbidden evidence. [VERIFIED: D-03/D-18] |
| Registry recovery | Delete/overwrite/yank assumptions | Query-first, monotonic forward-only recovery | Destructive semantics are unverified. [VERIFIED: D-16] |
| Approval workflow | Fabricated second reviewer | Sole-owner intent plus independent machine gates | Multi-person approval is out of scope. [VERIFIED: project constraints] |

## Common Pitfalls

- Replacing the project brand `MoonBit Native Foundation` with `tchivs`. The namespace is operational ownership, not branding. [VERIFIED: D-15]
- Editing archived v0.1 artifacts or completed plan summaries to make history look as if it always used the new owner. [VERIFIED: D-14]
- Updating manifests while leaving `moon.pkg`, examples, qualification consumers, policies, tests, or baseline package identities on the old owner. [VERIFIED: local 161-file audit]
- String-editing generated baseline digests instead of regenerating two clean runs. [VERIFIED: D-07/D-09/D-13]
- Claiming the intended GitHub repository/support/security route is live before it exists. [VERIFIED: D-17]
- Treating the GitHub login `tchivs`, a local authenticated Moon session, or a credential file as Mooncakes namespace authority. [VERIFIED: REG-01/D-03/D-18]
- Running interactive OAuth or publication inside Required. [VERIFIED: D-06/D-18]
- Treating a `--dry-run` flag as proof of version availability, immutability, or publication authorization. [VERIFIED: local help vs. unobserved semantics]
- Introducing team approvals for a single-maintainer project. [VERIFIED: requirements out of scope]
- Assuming a future organization namespace can rename or absorb published personal modules. [VERIFIED: D-16]

## Concrete Planning Recommendation

Preserve the four completed Phase 6 summaries and add a new remediation plan rather than rewriting completed history. The optimal dependency sequence is:

1. **New personal-namespace remediation plan (credential-free):** depend on completed 06-05; rewrite all active truth sources to `tchivs/*`, update intended/unverified repository metadata semantics, regenerate 17-package/68-record 0.1.0 baselines twice, clean stale builds, run module/example/benchmark/qualification/compatibility/documentation negatives, and prove archived v0.1 planning files are untouched.
2. **Revise/resume 06-01 authority plan:** depend on the remediation. Its repository contract tasks run automatically, then it reaches one explicit human checkpoint for Mooncakes GitHub OAuth registration/login. GitHub repository creation remains a separate authorization boundary. After human action, run only sanitized read-only collectors; no publication.
3. **Revise 06-06 integration plan:** depend on the remediation and completed 06-01. Re-freeze reciprocal coverage and integrate authority, compatibility, candidate documentation, and identity-drift negatives into credential-free Required.
4. **Do not advance Phase 7** until REG-01 through REG-03 are current and green. If human registration is not yet done, Phase 6 remains honestly blocked after all repo-local work completes.

This ordering isolates the broad deterministic migration from the narrow external checkpoint, avoids falsifying completed work, and gives the user one precise action when automation reaches the actual boundary. [VERIFIED: current plan state, D-13 through D-18]

## Environment Availability

| Dependency | Required By | Available | Version/state | Fallback |
|---|---|---|---|---|
| Pinned MoonBit toolchain | Source migration and baselines | Yes | exact versions above | None; mismatch blocks evidence |
| PowerShell | Validators/generators | Yes | 7.6.3 | None needed |
| Git | clean copies/history protection | Yes | 2.54.0.windows.1 | None needed |
| GitHub CLI identity | Intended owner proof | Yes | `tchivs` | Browser/GitHub website only if later authorized |
| GitHub repository | Metadata-live verification | No | absent | Keep route explicitly intended/unverified |
| Mooncakes account `tchivs` | REG-01/03 | No/unknown | HTTP 404 at read-only endpoint | Human `moon register` or `moon login` |
| Safe production namespace mutation | Not required in Phase 6 | Intentionally unavailable | — | Do not mutate |

**Missing dependency with no automated fallback:** the human-created/authenticated Mooncakes `tchivs` account and a sanitized exact namespace observation. This blocks final Phase 6 authority requirements, not the repo-local remediation. [VERIFIED: D-18]

**Missing dependency with a safe fallback:** the absent GitHub repository can remain explicitly unverified during local migration; it must be created only under separate authorization before release metadata is declared live. [VERIFIED: D-17]

## Validation Architecture

Skipped because `.planning/config.json` explicitly sets `workflow.nyquist_validation` to `false`. Existing tests still form mandatory task verification; no Wave 0 test-framework installation is needed. [VERIFIED: project config]

## Security Domain

Security enforcement is not disabled, and this phase handles authentication evidence even though it does not implement credential storage or publication. [VERIFIED: config and phase boundary]

| ASVS category | Applies | Standard control |
|---|---|---|
| V2 Authentication | Yes | Human OAuth through official CLI plus sanitized post-auth observation; never persist raw output. |
| V3 Session Management | Yes, observational only | Token expiry/revocation/non-interactive lifecycle stays `unknown` until documented or safely observed. |
| V4 Access Control | Yes | Exact account, namespace, and three identities must match policy or publication blocks. |
| V5 Input Validation | Yes | Closed JSON schemas, exact enums/sets, allowlisted command shapes, forbidden-value patterns, freshness checks. |
| V6 Cryptography | Integrity only | Platform SHA-256 for evidence identity; no custom crypto and no claim that a digest proves authority. |

Threat controls:

- **Spoofing:** GitHub/local-session identity mistaken for Mooncakes authority → require exact sanitized Mooncakes account/namespace evidence. [VERIFIED: REG-01]
- **Tampering:** identity or baseline records edited manually → regenerate/recompute and validate closed schemas/digests. [VERIFIED: existing helpers]
- **Repudiation:** unclear operator/run → record source commit, UTC time, command id/arguments, toolchain, and stable digest without secrets. [VERIFIED: D-03]
- **Information disclosure:** credential/header/path leakage → allowlist fields, reject secret/path patterns, never persist raw auth output. [VERIFIED: policy/collector]
- **Denial/ambiguity:** registry timeout or absent account → retain `unknown`, bounded retry only for read-only observation, no mutation. [VERIFIED: D-04/D-16]
- **Elevation of privilege:** invented organization ownership → use the verified personal account namespace only. [CITED: official namespace rules]

## Source Provenance

### Primary — HIGH confidence

- [MoonBit module configuration](https://docs.moonbitlang.com/en/stable/toolchain/moon/module.html) — published module names must begin with the username; module metadata and SemVer rules.
- [MoonBit beginner tour](https://docs.moonbitlang.com/en/stable/tutorial/tour.html) — `moon login`, existing GitHub account, and `<github account>/<project>` publication naming.
- [Introducing Mooncakes](https://www.moonbitlang.com/blog/intro-to-mooncakes) — independent per-user `<username>/<package_name>` namespaces and integrated commands.
- [Moon command reference](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — current documented `login`, `register`, `publish`, `package`, and `info` surfaces.
- Repository policy, manifests, schemas, scripts, completed plan summaries, and active baseline files inspected on 2026-07-17.
- Local read-only CLI/HTTP probes and targeted identity/runtime inventory on 2026-07-17.

### Secondary — MEDIUM confidence

- None required for the locked identity decision; planning relies on official sources and repository evidence.

### Tertiary — LOW/unknown

- Token scope/lifecycle, dry-run fidelity, duplicate-version handling, propagation guarantees, artifact digest semantics, destructive recovery, namespace transfer/rename, and exact rendered metadata remain unobserved and are not inferred.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| — | None. All prescriptive identity decisions are locked in CONTEXT or supported by official/current repository evidence; unobserved registry semantics are explicitly `unknown`. | — | — |

## Open Questions

1. **When will the user complete Mooncakes GitHub OAuth registration/login?**
   - Known: current read-only user lookup returned 404; repository work can proceed.
   - Unknown: exact post-login CLI/API identity surface.
   - Recommendation: stop only after repo-local remediation, ask for the human action, then run the sanitized collector.
2. **Should Codex later create `tchivs/moonbit-foundation`?**
   - Known: it is intended metadata and currently absent.
   - Unknown: the user has not authorized external repo creation/push in this task.
   - Recommendation: keep metadata explicitly unverified and request separate authorization when release readiness needs it.
3. **Which Mooncakes semantics are safely observable without mutation after registration?**
   - Known: CLI help and official docs expose surfaces, not semantic guarantees.
   - Unknown: exact account/version/artifact endpoints and token lifecycle.
   - Recommendation: capture only allowlisted read-only evidence; retain all other capabilities as `unknown` with current dispositions.

## Metadata

**Confidence breakdown:**

- Identity decision: HIGH — locked by user context and supported by three official MoonBit/Mooncakes sources.
- Migration surface: HIGH — repository files and local generated artifacts were directly audited.
- Toolchain/baseline architecture: HIGH — existing implementation and pinned local tools were inspected.
- External account/repository state: HIGH for the 2026-07-17 snapshot — read-only probes; must be refreshed before release.
- Unobserved registry semantics: LOW/unknown — deliberately not inferred or mutation-tested.

**Research date:** 2026-07-17
**Valid until:** Re-run external account/repository observations immediately before resuming 06-01; repository findings remain valid until the remediation changes active identity sources.
