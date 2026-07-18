# Phase 7: Release Safety, Intent, and Recovery Automation - Context

**Gathered:** 2026-07-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 7 turns the credential-free Phase 6 qualification evidence into one immutable release intent and implements a sole-maintainer, isolated, resumable publisher state machine. It defines authorization, secret isolation, serialization, journaling, negative rehearsal, and forward-only recovery for the exact `tchivs/mb-core` → `tchivs/mb-color` → `tchivs/mb-image` 0.1.0 release. It does not claim that local login alone proves remote publication authority, publish the production modules as part of ordinary Required qualification, perform Phase 8 registry-consumer proofs, or add a new module family.

</domain>

<decisions>
## Implementation Decisions

### Immutable Release Intent

- **D-01:** Required produces a closed-schema canonical JSON intent plus SHA-256 digest. The digest is the authorization identity; mutable filenames, prose, workflow inputs, or branch names are not authorization authority.
- **D-02:** The intent binds the trusted Git ref, exact source commit, pinned toolchain, ordered `tchivs/*` module identities and `0.1.0` versions, exact dependency graph, public package inventories, archive digests, interface-baseline digests, and qualification report/evidence digests.
- **D-03:** Use a dedicated immutable module-release tag/ref distinct from the existing `v0.1` milestone tag. Planning may select the exact conventional spelling, but the publisher must reject a movable branch, mismatched tag target, or intent generated from a dirty/untrusted source.
- **D-04:** Intent generation remains credential-free, deterministic, reproducible on a clean checkout, and part of Required. Rebuilding the same source and inputs must reproduce the same canonical digest.

### Sole-Maintainer Authorization and Secret Isolation

- **D-05:** Authorization is an explicit manual GitHub Actions dispatch by the sole maintainer `tchivs`, naming the exact release ref, source SHA, and intent SHA-256. No second approver, quorum, or organization-only ceremony is introduced.
- **D-06:** The publisher validates the dispatch actor, repository, default/protected trusted ref, immutable tag target, source SHA, and intent digest before requesting or exposing any Mooncakes credential. A mismatch fails before mutation.
- **D-07:** GitHub workflow permissions are read-only by default. Every third-party action is pinned to a full commit SHA. The Mooncakes secret is referenced only by the isolated mutation step in a dedicated publisher job/environment; preparation, Required, pull requests, and consumer verification never receive it.
- **D-08:** A current `moon whoami` match, read-only module/version observation, package/archive verification, and `moon publish --dry-run` are mandatory preflight evidence. They prove local identity and command readiness, not remote publish authority. Definitive remote authority is established only by the first real successful publication response and subsequent read-only registry observation.
- **D-09:** Phase 7 builds and rehearses the publisher without silently consuming a production version. The first irreversible Mooncakes mutation is an explicit operator checkpoint and belongs to the authorized live release transition feeding Phase 8, not an incidental test.

### Serialization and Monotonic Journal

- **D-10:** Use one release-wide GitHub Actions concurrency group derived from repository plus intent digest, with `cancel-in-progress: false`. A newer dispatch cannot cancel or supersede an in-progress publication.
- **D-11:** The publisher state machine is strictly monotonic: intent authorized → preflight passed → core mutation attempted → core registry state observed → core checkpoint verified → color attempted/observed/verified → image attempted/observed/verified → handoff ready. No transition may skip dependency order or move backward.
- **D-12:** Every transition appends a closed-schema, content-addressed journal record containing sequence number, prior-record digest, intent digest, sanitized observation, outcome, and timestamp. Raw credentials, headers, cookies, local credential paths, and unredacted CLI output are prohibited.
- **D-13:** Preserve completed checkpoints as GitHub workflow artifacts named by intent digest and sequence. Resume requires the exact prior run/artifact identity and verifies the full digest chain; registry re-observation remains authoritative when artifact state and external state disagree or an artifact expires.
- **D-14:** A duplicate or replayed dispatch with the same intent never republishes a verified module. It re-observes registry state, validates identity, records an idempotent checkpoint, and continues only to the next unpublished dependency-safe module.

### Failure and Forward-Only Recovery

- **D-15:** Credential-free rehearsals cover timeout/unknown outcome, partial success, existing matching version, existing mismatched version, invalid credential, evidence failure, replay, concurrent dispatch, cancellation, and dependency-order violation.
- **D-16:** Any ambiguous publish result stops mutation and performs read-only re-observation. Retry is permitted only when the exact version is still absent and a fresh authorization/preflight remains valid; an observed exact match is checkpointed without republishing.
- **D-17:** Published content that does not match the authorized archive/metadata intent is an incident. Automation stops, preserves evidence, and requires a newly generated and newly authorized forward-corrected unpublished version plus advisory. It never assumes overwrite, delete, unpublish, yank, transfer, or rename support.
- **D-18:** Invalid credentials and stale/mismatched evidence must fail before publication where observable. Authentication failure never weakens the intent or falls back to a different account, namespace, module identity, credential source, or untrusted ref.

### the agent's Discretion

- Exact schema filenames, PowerShell helper boundaries, journal artifact retention, and diagnostic codes, provided the contracts above remain deterministic, closed, content-addressed, and secret-free.
- Exact dedicated release tag spelling and GitHub environment name, provided they are stable, repository-scoped, distinct from the existing `v0.1` tag, and machine-validated.
- Whether the local state-machine engine is one script or narrowly separated generation, validation, and execution scripts, provided only the final isolated mutation step can read the credential.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Phase Contract

- `.planning/ROADMAP.md` — Phase 7 goal, REL-01 through REL-05 mapping, and observable success criteria.
- `.planning/REQUIREMENTS.md` — exact release-control requirements and milestone-wide distribution/provenance boundaries.
- `.planning/PROJECT.md` — sole-maintainer project constraints, publication-before-expansion decision, and Phase 6 handoff.
- `.planning/STATE.md` — current Phase 7 position and accumulated fail-closed/forward-only decisions.
- `.planning/phases/06-namespace-authority-and-compatibility-contract/06-CONTEXT.md` — canonical namespace, evidence classifications, credential-free Required boundary, and Phase 7 publisher seam.

### Authority and Qualification Contracts

- `policy/registry-authority.json` — required current registry facts, exact owner/modules/toolchain, freshness rules, and blocked authenticated publish seam.
- `release/registry/authority-observation.json` — current sanitized proof that login/account observation succeeded while namespace/publish authority remains unknown.
- `policy/release-qualification.json` — fixed module order, target set, exact versions/dependencies, package inventories, and publication state.
- `policy/compatibility.json` — candidate compatibility/version policy and interface-baseline authority.
- `release/qualification/phase-06-requirements.json` — reciprocal Phase 6 evidence that Phase 7 must consume without weakening.
- `release/qualification/package-schema.json` — closed qualification evidence and content-addressing pattern.

### Existing Automation and Governance

- `.github/workflows/quality.yml` — full-SHA-pinned, read-only Required workflow whose credential-free semantics must be preserved.
- `scripts/quality/Invoke-ReleaseQualification.ps1` — deterministic qualification orchestrator and release-intent generation integration point.
- `scripts/quality/ReleaseQualification.Common.ps1` — shared canonical serialization, hashing, and diagnostic helpers.
- `scripts/quality/Test-Phase06Qualification.ps1` — current Phase 6 Required integration and reciprocal coverage gate.
- `scripts/quality/Test-RegistryAuthority.ps1` — authority/currentness validation to reuse before publisher entry.
- `scripts/quality/Test-RegistryAuthorityNegative.ps1` — fail-closed negative-fixture pattern.
- `docs/governance/decisions/0001-sole-owner-bootstrap.md` — one-maintainer authorization boundary; no team approval is required.
- `docs/governance/rfc-process.md` — architectural-change threshold; Phase 7 must not silently expand ecosystem scope.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `policy/release-qualification.json`: already owns canonical order, versions, dependencies, inventories, targets, and archive exclusions needed by release intent generation.
- `policy/registry-authority.json` and `release/registry/authority-observation.json`: provide exact current-fact, freshness, redaction, and fail-closed vocabulary for publisher preflight.
- `scripts/quality/ReleaseQualification.Common.ps1`: natural home for canonical JSON, stable SHA-256, protected-file, and deterministic diagnostic helpers.
- `scripts/quality/Invoke-ReleaseQualification.ps1`: existing credential-free evidence pipeline can emit the release intent after all Required selectors pass.
- `.github/workflows/quality.yml`: establishes full-SHA action pins, `contents: read`, exact toolchain installation, and credential-free checkout patterns.

### Established Patterns
- Machine-readable policy owns truth; prose explains it but cannot override it.
- Required is deterministic and credential-free, unknown external facts fail closed, and real Native compile/link/runtime remains mandatory.
- Evidence uses closed schemas, exact enums/constants, stable digests, explicit module/package ordering, and adversarial negative selectors.
- Publication order is fixed: `mb-core` → read-only proof → `mb-color` → proof → `mb-image` → full graph proof.

### Integration Points
- Add release-intent and journal policy/schema/evidence under the existing `policy/` and `release/` contract families.
- Extend the Required orchestration only with credential-free intent generation and validation; keep live publisher execution in a separate manually dispatched workflow.
- Add a publisher workflow that consumes an already-qualified intent, performs isolated step-scoped credential use, uploads sanitized checkpoints, and hands verified registry state to Phase 8.
- Reuse Phase 6 registry validators and negative-test conventions for authentication, freshness, replay, mismatch, ambiguity, and dependency-order fixtures.

</code_context>

<specifics>
## Specific Ideas

- Treat “登录成功” as a proven local/account fact, while keeping remote publication authority honest until Mooncakes accepts the first exact module and read-only observation confirms it.
- Make the release intent digest the single value the maintainer authorizes; every workflow input and checkpoint must resolve back to it.
- Keep the live mutation surface deliberately tiny: trusted source, exact intent, one module at a time, then stop and observe before any downstream publish.

</specifics>

<deferred>
## Deferred Ideas

- Actual registry-only consumer proofs and the three-module live publication sequence — Phase 8 after the Phase 7 publisher and authorization gate are verified.
- Immutable public ledger, artifact provenance, GitHub release closure, and final milestone audit — Phase 9.
- Mooncakes OIDC/federated publishing — future requirement only after official registry support is documented.
- Organization namespace migration, destructive recovery, multi-maintainer approvals, and new module families — outside v0.2.

</deferred>

---

*Phase: 7-release-safety-intent-and-recovery-automation*
*Context gathered: 2026-07-18*
