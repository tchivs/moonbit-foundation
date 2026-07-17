# Requirements: v0.2 Publication & Compatibility

**Defined:** 2026-07-17  
**Milestone:** v0.2 Publication & Compatibility  
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.2 Requirements

### Registry Authority

- [ ] **REG-01**: The sole maintainer can verify the authenticated Mooncakes owner namespace and the final names of all three modules using repository-bound evidence that contains no credential material.
- [ ] **REG-02**: The sole maintainer can produce a credential-redacted registry capability matrix that marks authentication, token scope, dry-run, version immutability, propagation, artifact identity, and destructive recovery semantics as documented, safely observed, or unknown without polluting a production module version.
- [ ] **REG-03**: The release gate refuses to publish unless namespace authority, canonical module identity, pinned toolchain identity, exact version availability, an authenticated publish seam, and registry observation/resolution are known and current; other unknown capabilities receive an explicit fail-closed or forward-only disposition.

### Compatibility Contract

- [x] **COMP-01**: The sole maintainer can reproducibly generate canonical public-interface baselines for every public package in `mb-core`, `mb-color`, and `mb-image` across `js`, `wasm`, `wasm-gc`, and `native` with the pinned toolchain, without claiming behavioral compatibility from interface text alone.
- [ ] **COMP-02**: The compatibility gate classifies every candidate public-interface delta as exact, additive, incompatible, or unknown using deterministic, documented rules.
- [ ] **COMP-03**: The candidate-version policy governs public-interface, supported-target, minimum-toolchain, and dependency-floor changes; it permits patch releases only without incompatible deltas, requires a minor release for additive public API, and requires both a minor release and migration note for an incompatible pre-1.0 change.
- [ ] **COMP-04**: The release gate fails closed on incompatible or unknown deltas unless the required version change, changelog entry, and migration evidence are present, plus RFC evidence when module boundaries, architecture, or governance rules require it.

### Release Control

- [ ] **REL-01**: The credential-free Required path produces an immutable release intent that binds one authorized release tag/ref name to an exact source commit, ordered module versions, exact dependency versions, package inventory, archive digests, interface-baseline digests, and qualification evidence.
- [ ] **REL-02**: The credentialed publisher accepts only the sole maintainer's explicit authorization of one exact intent from a protected trusted ref; all third-party actions are full-SHA pinned, default permissions are read-only, and a least-privilege Mooncakes credential is exposed only to the isolated publication step.
- [ ] **REL-03**: A release-wide global serialization lock and monotonic journal prevent concurrent, replayed, duplicate, cancelled-in-progress, or dependency-order-violating publication transitions while preserving completed module checkpoints.
- [ ] **REL-04**: Credential-free negative rehearsals cover timeout, partial success, existing-version mismatch, invalid credential, and evidence failure; after an ambiguous or failed publication the real workflow re-observes and compares registry state with the authorized intent before retrying any mutation.
- [ ] **REL-05**: Recovery preserves a correctly published checkpoint and continues downstream, re-observes an unknown outcome, re-authorizes a corrected unpublished intent, and stops with incident evidence plus a forward corrected version and advisory when published content mismatches intent; automation never assumes overwrite, delete, unpublish, or yank support.

### Registry Distribution

- [ ] **DIST-01**: After `mb-core` publication, a fresh registry-only consumer resolves its exact version and passes a deterministic public behavioral assertion on all four supported targets before `mb-color` may publish.
- [ ] **DIST-02**: After `mb-color` publication, a fresh registry-only consumer resolves its exact version plus the intended published `mb-core` dependency and passes a deterministic public behavioral assertion on all four targets before `mb-image` may publish.
- [ ] **DIST-03**: After `mb-image` publication, a fresh registry-only consumer resolves the exact full dependency graph and passes the bounded PPM public stack on all four supported targets.
- [ ] **DIST-04**: Every distribution proof starts outside the repository with an isolated cold Moon home, no publisher credential, `moon.work`, path dependency, copied source, or Git fallback, and records registry-visible metadata, the strongest available package identity, resolved dependencies, toolchain, target results, and behavioral assertion.

### Provenance and Closure

- [ ] **PROV-01**: Every published module version has an immutable ledger entry linking its registry identity, source commit and tag, package inventory, exact dependency graph, archive digest, interface-baseline digest, pinned toolchain, qualification report, and consumer proof.
- [ ] **PROV-02**: Standard artifact provenance and a closed evidence manifest for every qualified archive verify outside the producer job against the expected repository, workflow identity, source ref, and SHA-256 digest; provenance is not treated as proof of compatibility or correctness.
- [ ] **PROV-03**: Before publication, each module's source documentation set collectively provides exact install/import commands, candidate status, supported targets and toolchain, public-interface change class, support and security-reporting routes, changelog, migration note when required, and the intended registry metadata source.
- [ ] **PROV-04**: Final closure verifies immutable release tag/assets, rehearses provenance and recovery failures, repeats the full credential-free Required gate from the release source, proves publication/verification did not mutate that source or leak secrets, validates all ledger and registry evidence, and confirms that no new module family entered v0.2.
- [ ] **PROV-05**: After publication, read-only Mooncakes observation proves that each published module page renders the intended public metadata from the qualified source documentation without credential disclosure or registry mutation.

## Future Requirements

- **FUT-01**: Add new module families such as `mb-canvas`, `mb-svg`, `mb-font`, or `mb-pdf` after registry distribution and compatibility evolution are proven.
- **FUT-02**: Declare stable 1.0 compatibility only after external adoption and at least one intentionally managed compatibility evolution.
- **FUT-03**: Adopt Mooncakes OIDC or narrower publish-only federation if the registry officially supports and documents it.
- **FUT-04**: Add broader SBOM and dependency-vulnerability automation when native adapters or meaningful transitive dependencies enter the published graph.

## Out of Scope

- New graphics, document, media, AI, MCP, or integration modules in v0.2.
- Multi-maintainer approval, quorum, or separation-of-duties workflows while the project has one maintainer.
- Automatic publication on every merge or exposure of registry credentials to pull-request and Required jobs.
- Registry overwrite, delete, unpublish, or yank automation without a verified official contract.
- A general-purpose, multi-ecosystem release platform or custom cryptographic signing scheme.
- Treating workspace builds, path dependencies, copied sources, or warm caches as registry-consumption evidence.
- Claiming 1.0 stability, long-term support, guaranteed response times, or compatibility beyond the pinned and tested toolchain/targets.

## Definition of Done

1. All v0.2 requirements above are mapped to exactly one roadmap phase and carry passing verification evidence.
2. The authenticated namespace and final module identities are recorded without credentials, and every unknown live registry semantic has a fail-closed disposition.
3. `mb-core`, `mb-color`, and `mb-image` are published in dependency order and each passes its own fresh exact-version registry consumer across all four supported targets.
4. Compatibility baselines and candidate-version rules reject incompatible and unknown public-interface changes without the required release evidence.
5. Release intent, monotonic journal, safe retry, forward recovery, provenance, and immutable ledger form one auditable source-to-registry evidence chain.
6. The v0.1 Required contract remains credential-free and passes unchanged in strength at milestone closure.
7. No new module family or unrelated public feature is added during v0.2.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REG-01 | Phase 6 | Pending |
| REG-02 | Phase 6 | Pending |
| REG-03 | Phase 6 | Pending |
| COMP-01 | Phase 6 | Complete |
| COMP-02 | Phase 6 | Pending |
| COMP-03 | Phase 6 | Pending |
| COMP-04 | Phase 6 | Pending |
| REL-01 | Phase 7 | Pending |
| REL-02 | Phase 7 | Pending |
| REL-03 | Phase 7 | Pending |
| REL-04 | Phase 7 | Pending |
| REL-05 | Phase 7 | Pending |
| DIST-01 | Phase 8 | Pending |
| DIST-02 | Phase 8 | Pending |
| DIST-03 | Phase 8 | Pending |
| DIST-04 | Phase 8 | Pending |
| PROV-01 | Phase 9 | Pending |
| PROV-02 | Phase 9 | Pending |
| PROV-03 | Phase 6 | Pending |
| PROV-04 | Phase 9 | Pending |
| PROV-05 | Phase 8 | Pending |

**Coverage:** 21/21 requirements mapped exactly once

---
*Requirements defined: 2026-07-17*
