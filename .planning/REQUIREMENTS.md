# Requirements: v0.2 Publication & Compatibility

**Defined:** 2026-07-17  
**Milestone:** v0.2 Publication & Compatibility  
**Core Value:** MoonBit developers can reuse stable, high-performance native infrastructure contracts instead of rebuilding incompatible foundations for every graphics, document, media, or automation product.

## v0.2 Requirements

### Registry Authority

- [ ] **REG-01**: The sole maintainer can verify the authenticated Mooncakes owner namespace and the final names of all three modules using repository-bound evidence that contains no credential material.
- [ ] **REG-02**: The sole maintainer can run a disposable live probe that records the pinned toolchain's current authentication, token-scope, dry-run, version-immutability, propagation, and artifact-identity behavior before any production publication.
- [ ] **REG-03**: The release gate refuses to publish when namespace authority, module identity, toolchain identity, version availability, or required registry semantics are unknown or have drifted from the recorded contract.

### Compatibility Contract

- [ ] **COMP-01**: The sole maintainer can reproducibly generate canonical public semantic-interface baselines for every public package in `mb-core`, `mb-color`, and `mb-image` across `js`, `wasm`, `wasm-gc`, and `native` with the pinned toolchain.
- [ ] **COMP-02**: The compatibility gate classifies every candidate public-interface delta as exact, additive, incompatible, or unknown using deterministic, documented rules.
- [ ] **COMP-03**: The candidate-version policy permits patch releases only without incompatible public-interface deltas, requires a minor release for additive public API, and requires both a minor release and migration note for an incompatible pre-1.0 change.
- [ ] **COMP-04**: The release gate fails closed on incompatible or unknown deltas unless the required version change, changelog entry, migration evidence, and RFC evidence are present.

### Release Control

- [ ] **REL-01**: The credential-free Required path produces an immutable release intent that binds the source commit and tag, ordered module versions, exact dependency versions, package inventory, archive digests, interface-baseline digests, and qualification evidence.
- [ ] **REL-02**: The credentialed publisher accepts only an authorized exact release intent from a trusted ref and exposes a least-privilege Mooncakes credential only to the isolated publication step.
- [ ] **REL-03**: A monotonic release journal prevents concurrent, replayed, duplicate, or dependency-order-violating publication transitions while preserving completed module checkpoints.
- [ ] **REL-04**: After an ambiguous timeout or failed publication, the release workflow re-observes the registry and compares external state with the authorized intent before retrying any mutation.
- [ ] **REL-05**: Partial or mismatched releases have a documented forward-only recovery path using a corrected version and advisory; automation does not assume overwrite, delete, unpublish, or yank support.

### Registry Distribution

- [ ] **DIST-01**: After `mb-core` publication, a fresh registry-only consumer resolves its exact version and passes a stable public-API assertion on all four supported targets before `mb-color` may publish.
- [ ] **DIST-02**: After `mb-color` publication, a fresh registry-only consumer resolves its exact version plus the intended published `mb-core` dependency and passes a stable public-API assertion on all four targets before `mb-image` may publish.
- [ ] **DIST-03**: After `mb-image` publication, a fresh registry-only consumer resolves the exact full dependency graph and passes the bounded PPM public stack on all four supported targets.
- [ ] **DIST-04**: Every distribution proof starts outside the repository with no `moon.work`, path dependency, copied source, or warm-cache-only success, and records the resolved dependency graph, toolchain, target results, and behavioral assertion.

### Provenance and Closure

- [ ] **PROV-01**: Every published module version has an immutable ledger entry linking its registry identity, source commit and tag, package inventory, exact dependency graph, archive digest, interface-baseline digest, pinned toolchain, qualification report, and consumer proof.
- [ ] **PROV-02**: Standard artifact provenance for every qualified archive verifies successfully against the expected repository, workflow identity, source ref, and SHA-256 digest; provenance is not treated as proof of compatibility or correctness.
- [ ] **PROV-03**: Every module README and changelog documents its exact install/import commands, candidate status, supported targets and toolchain, public-interface change class, support route, security-reporting route, and migration note when required.
- [ ] **PROV-04**: Final milestone closure repeats the full credential-free Required gate from the release source, verifies all ledger and registry evidence, detects no tracked mutation or secret leakage, and confirms that no new module family entered v0.2.

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
| REG-01 | TBD | Pending |
| REG-02 | TBD | Pending |
| REG-03 | TBD | Pending |
| COMP-01 | TBD | Pending |
| COMP-02 | TBD | Pending |
| COMP-03 | TBD | Pending |
| COMP-04 | TBD | Pending |
| REL-01 | TBD | Pending |
| REL-02 | TBD | Pending |
| REL-03 | TBD | Pending |
| REL-04 | TBD | Pending |
| REL-05 | TBD | Pending |
| DIST-01 | TBD | Pending |
| DIST-02 | TBD | Pending |
| DIST-03 | TBD | Pending |
| DIST-04 | TBD | Pending |
| PROV-01 | TBD | Pending |
| PROV-02 | TBD | Pending |
| PROV-03 | TBD | Pending |
| PROV-04 | TBD | Pending |

**Coverage:** 0/20 requirements mapped (roadmap pending)

---
*Requirements defined: 2026-07-17*
