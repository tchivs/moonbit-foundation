# Phase 6: Namespace Authority and Compatibility Contract - Context

**Gathered:** 2026-07-17 (updated after personal namespace decision)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 6 verifies the sole maintainer's Mooncakes namespace and canonical module identities, records safely observable registry capabilities, freezes reproducible public-interface baselines, and defines the candidate version and publication-documentation gates. It does not publish a production module, introduce credentials into Required, build the Phase 7 publisher, or add a new module family.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Contract

- `.planning/ROADMAP.md` — Phase 6 goal, boundary, requirements, and observable success criteria.
- `.planning/REQUIREMENTS.md` — REG-01 through REG-03, COMP-01 through COMP-04, and PROV-03 acceptance contract.
- `.planning/research/SUMMARY.md` — research synthesis, live-validation gaps, and recommended sequencing.
- `.planning/research/FEATURES.md` — external-consumer, compatibility, support, recovery, and anti-feature findings.

### Existing Qualification Contract

- `policy/release-qualification.json` — current module order, targets, candidate metadata, exact manifests, publication blocker, and package allowlists.
- `release/qualification/package-schema.json` — strict credential-free qualification evidence schema and current blocked-publication assertions.
- `release/qualification/v0.1-requirements.json` — locked v0.1 requirement evidence that Phase 6 must not weaken.
- `docs/release/v0.1-candidate.md` — current public package DAG, candidate claims, blocked registry resolution, and documentation index.

### Identity Transition

- `policy/registry-authority.json` — canonical owner and exact module identity authority.
- `policy/release-qualification.json` — active module, dependency, package, and repository metadata identities.
- `compatibility/baselines/0.1.0/manifest.json` — baseline root that must be regenerated after the unpublished identity correction.
- `docs/rfcs/0001-moonbit-native-foundation.md` — project branding and active canonical module boundary descriptions.
- `modules/mb-core/moon.mod.json` — root identity for `tchivs/mb-core` and downstream package imports.
- `modules/mb-color/moon.mod.json` — root identity and `tchivs/mb-core` dependency.
- `modules/mb-image/moon.mod.json` — root identity and `tchivs/mb-core`/`tchivs/mb-color` dependencies.

### Governance and Automation

- `docs/governance/rfc-process.md` — when an RFC is required and how sole-owner bootstrap decisions are recorded.
- `docs/governance/decisions/0001-sole-owner-bootstrap.md` — single-maintainer governance boundary; no multi-person approval is introduced.
- `scripts/quality/Invoke-ReleaseQualification.ps1` — current deterministic qualification orchestrator and natural integration point.
- `scripts/quality/Test-ReleaseQualification.ps1` — positive qualification assertions to preserve.
- `scripts/quality/Test-ReleaseQualificationNegative.ps1` — fail-closed negative-test pattern to extend.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `policy/release-qualification.json`: already centralizes exact module order, targets, manifests, package allowlists, and the honest namespace blocker.
- `release/qualification/package-schema.json`: establishes strict JSON Schema, `additionalProperties: false`, exact enums/consts, and evidence validation patterns.
- `scripts/quality/ReleaseQualification.Common.ps1`: shared qualification helpers are the preferred seam for deterministic serialization, hashing, and diagnostics.
- `scripts/quality/Test-ReleaseQualificationNegative.ps1`: existing adversarial fixture pattern can host drift, ambiguity, and incompatible-delta cases.
- Module `moon.mod.json`, `README.mbt.md`, and `CHANGELOG.md` files already carry candidate metadata and independent versions.

### Established Patterns

- Required is credential-free, deterministic, and records blocked external outcomes honestly rather than replacing them with workspace/path success.
- Policy JSON owns machine facts; documentation contains machine-compared fingerprints but is not an alternate policy owner.
- Schemas are closed and versioned, package inventories are allowlisted, evidence is content-addressed, and negative selectors prove failure behavior.
- Module dependency order is fixed as `mb-core` → `mb-color` → `mb-image`; all four portable targets are mandatory.
- Unpublished identity corrections update active truth sources and regenerated evidence together while archived milestone artifacts remain immutable history.

### Integration Points

- Extend the release-qualification policy/schema family for authority capability and compatibility evidence without changing the meaning of the v0.1 locked report.
- Add Phase 6 selectors to `scripts/quality.ps1` and `.github/workflows/quality.yml` through the existing Required orchestration seam.
- Generate baselines from the three module manifests and public package inventories, then validate docs/changelogs against the same policy owner.

</code_context>

<specifics>
## Specific Ideas

- Treat the capability matrix as an auditable facts table, not a promise that every registry feature is known.
- Keep raw interface evidence beside normalized baseline digests so toolchain/parser changes can be diagnosed without pretending text equality is semantic equivalence.
- Preserve the sole-owner model: explicit maintainer intent plus independent machine verification, never a fabricated second approver.
- Keep the human-facing MoonBit Native Foundation name while publishing the initial module family under the sole maintainer's verified `tchivs` namespace.

</specifics>

<deferred>
## Deferred Ideas

- Mooncakes OIDC or narrower publish federation — adopt only after official support is verified.
- Destructive registry recovery automation — no overwrite, delete, unpublish, or yank assumptions in v0.2.
- New module families and 1.0 stability — wait until publication and compatibility evolution are proven.
- Optional migration from `tchivs/*` to a future organization-owned namespace — only after that namespace exists and a separate migration RFC/release plan is accepted.

</deferred>

---

*Phase: 6-namespace-authority-and-compatibility-contract*
*Context gathered: 2026-07-17*
