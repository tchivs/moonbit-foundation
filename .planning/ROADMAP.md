# Roadmap: MoonBit Native Foundation

## Milestones

- ✅ **v0.1 Foundation** — Phases 1-5, 41 plans, 36/36 requirements (shipped 2026-07-17). Full history: [v0.1 roadmap](./milestones/v0.1-ROADMAP.md).
- 🚧 **v0.2 Publication & Compatibility** — Phases 6-9, 21 requirements (planning).

## Phases

<details>
<summary>✅ v0.1 Foundation (Phases 1-5) — SHIPPED 2026-07-17</summary>

- [x] Phase 1: Foundation Charter and Reproducible Workspace (8/8 plans) — completed 2026-07-16
- [x] Phase 2: Bounded Core Primitives (8/8 plans) — completed 2026-07-17
- [x] Phase 3: Reference Color Semantics (8/8 plans) — completed 2026-07-17
- [x] Phase 4: Image Model, Views, and Operations (9/9 plans) — completed 2026-07-17
- [x] Phase 5: Reference Codec and Release Qualification (8/8 plans) — completed 2026-07-17

</details>

### 🚧 v0.2 Publication & Compatibility (In Progress)

**Milestone goal:** Publish the three v0.1 modules through a fail-closed, compatibility-aware, recoverable release path and prove exact registry consumption with immutable evidence.

- [ ] **Phase 6: Namespace Authority and Compatibility Contract** — Verify registry authority and establish deterministic public-interface, versioning, and publication-documentation contracts.
- [ ] **Phase 7: Release Safety, Intent, and Recovery Automation** — Bind publication to an exact credential-free intent and a resumable, forward-only state machine.
- [ ] **Phase 8: Ordered Mooncakes Publication and Registry Consumers** — Publish the three modules in dependency order and prove cold registry-only consumption.
- [ ] **Phase 9: Provenance, Immutable Closure, and Milestone Audit** — Close the source-to-registry evidence chain and audit the completed milestone.

## Phase Details

### Phase 6: Namespace Authority and Compatibility Contract

**Goal:** The sole maintainer has a verified, fail-closed registry authority contract and a machine-checkable compatibility contract before any credentialed production publication.

**Depends on:** Phase 5

**Requirements:** REG-01, REG-02, REG-03, COMP-01, COMP-02, COMP-03, COMP-04, PROV-03

**Success Criteria:**

1. The sole maintainer can inspect sanitized repository-bound authority evidence and a credential-redacted capability matrix that classifies current authentication, token scope, dry-run, immutability, propagation, artifact identity, and destructive-recovery semantics as documented, safely observed, or unknown without consuming a production module version.
2. A release gate rejects missing or drifted namespace authority, canonical module identity, pinned toolchain identity, exact version availability, authenticated publish seam, or registry observation and resolution; every other unknown capability has an explicit fail-closed or forward-only disposition.
3. Canonical public-interface baselines for every public package are reproducibly generated across `js`, `wasm`, `wasm-gc`, and `native` and remain identical across clean runs with the pinned toolchain without being presented as behavioral compatibility proof.
4. Candidate deltas, including supported-target, minimum-toolchain, and dependency-floor changes, are deterministically classified and the gate enforces the required version, changelog, migration, and conditional RFC evidence.
5. Before publication, each module's source documentation contract covers exact install and import commands, candidate status, targets and toolchain, change class, changelog, support and security routes, migration notes when required, and the intended registry metadata source; actual Mooncakes rendering proof is deferred to PROV-05 after publication.

**Plans:** 2/6 plans executed
**Completed foundation**

- [x] 06-02-PLAN.md — Define baseline contracts and mechanically generate 17-package × 4-target interface evidence.

**Wave 2** *(depends on 06-02)*

- [x] 06-03-PLAN.md — Implement four-class comparison, version/evidence policy enforcement, and exact negatives.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 06-04-PLAN.md — Establish shared support/security routes and the collective source-document validator.

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 06-05-PLAN.md — Complete the three bounded module publication-documentation sets.

**Wave 5 — deferred external checkpoint** *(resume after Wave 4 when the exact account identity exists)*

- [ ] 06-01-PLAN.md — Freeze authority/capability contracts, capture sanitized read-only namespace proof, and enforce readiness. Contract work is retained; live authority proof is deferred by the sole maintainer. See `06-01-DEFERRED.md`.

**Wave 6** *(blocked on Waves 2-5 completion)*

- [ ] 06-06-PLAN.md — Freeze reciprocal Phase 6 coverage and integrate all credential-free gates into Required.

### Phase 7: Release Safety, Intent, and Recovery Automation

**Goal:** The sole maintainer can authorize one exact credential-free release intent and safely execute or resume an isolated publisher state machine.

**Depends on:** Phase 6

**Requirements:** REL-01, REL-02, REL-03, REL-04, REL-05

**Success Criteria:**

1. Required produces an immutable, credential-free release intent binding one authorized release tag/ref to the exact source commit, ordered module versions and dependencies, package inventories and archive digests, interface-baseline digests, and qualification evidence.
2. The publisher accepts only the sole maintainer's explicit authorization of that exact intent from a protected trusted ref; third-party actions are full-SHA pinned, default permissions are read-only, and the least-privilege Mooncakes credential reaches only the isolated mutation step.
3. A release-wide serialization lock and monotonic journal prevent concurrent, replayed, duplicate, cancelled-in-progress, and dependency-order-violating transitions while preserving completed checkpoints.
4. Credential-free negative rehearsals cover timeout, partial success, existing-version mismatch, invalid credential, and evidence failure; ambiguous real failures trigger registry re-observation before any retry, and mismatches stop with incident evidence plus a forward corrected version and advisory.

**Plans:** TBD

### Phase 8: Ordered Mooncakes Publication and Registry Consumers

**Goal:** All three modules are genuinely published and independently consumable from Mooncakes in strict dependency order.

**Depends on:** Phase 7

**Requirements:** DIST-01, DIST-02, DIST-03, DIST-04, PROV-05

**Success Criteria:**

1. `mb-core` is published first, then a fresh cold registry-only consumer resolves its exact version and passes a deterministic public behavioral assertion across all four supported targets before `mb-color` publication begins.
2. `mb-color` is published next, then a fresh consumer resolves its exact version and intended published `mb-core` dependency and passes across all four targets before `mb-image` publication begins.
3. `mb-image` is published last, then a fresh consumer resolves the exact full dependency graph and passes the bounded PPM public stack across all four targets.
4. Every proof runs outside the repository with an isolated cold Moon home and no publisher credential, `moon.work`, path dependency, copied source, Git fallback, or warm-cache-only success, and records registry metadata, strongest available package identity, resolved graph, toolchain, target results, and behavioral assertion.
5. After publication, credential-redacted read-only Mooncakes observation proves that each module page renders the intended qualified public metadata; missing, drifted, or ambiguous rendering blocks PROV-05 without registry mutation.

**Plans:** TBD

### Phase 9: Provenance, Immutable Closure, and Milestone Audit

**Goal:** Published versions have verified immutable provenance and documentation, and milestone closure proves the complete evidence chain without broadening v0.2 scope.

**Depends on:** Phase 8

**Requirements:** PROV-01, PROV-02, PROV-04

**Success Criteria:**

1. Every module version has an immutable ledger entry linking registry identity, source commit and tag, package inventory, exact dependencies, archive and interface digests, pinned toolchain, qualification report, and consumer proof.
2. Standard artifact provenance and a closed evidence manifest verify outside the producer job against the expected repository, workflow identity, source ref, and archive digest while remaining explicitly separate from compatibility and correctness evidence.
3. Closure verifies immutable release tags and assets and rehearses provenance and recovery failures so broken identity, evidence, or recovery paths fail closed.
4. Final closure reruns credential-free Required from the release source, verifies ledger and registry evidence, proves publication and verification caused no source mutation or secret leakage, confirms no new module family entered v0.2, and passes the milestone audit.

**Plans:** TBD

## Progress

**Execution order:** 6 → 7 → 8 → 9

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation Charter and Reproducible Workspace | v0.1 | 8/8 | Complete | 2026-07-16 |
| 2. Bounded Core Primitives | v0.1 | 8/8 | Complete | 2026-07-17 |
| 3. Reference Color Semantics | v0.1 | 8/8 | Complete | 2026-07-17 |
| 4. Image Model, Views, and Operations | v0.1 | 9/9 | Complete | 2026-07-17 |
| 5. Reference Codec and Release Qualification | v0.1 | 8/8 | Complete | 2026-07-17 |
| 6. Namespace Authority and Compatibility Contract | v0.2 | 2/6 | In Progress|  |
| 7. Release Safety, Intent, and Recovery Automation | v0.2 | 0/TBD | Not started | — |
| 8. Ordered Mooncakes Publication and Registry Consumers | v0.2 | 0/TBD | Not started | — |
| 9. Provenance, Immutable Closure, and Milestone Audit | v0.2 | 0/TBD | Not started | — |

## Stable Audit Anchors

- **phase-1-foundation-charter-and-reproducible-workspace:** Archived with its complete source inventory under `.planning/milestones/v0.1-phases/`.

---
*Roadmap updated: 2026-07-17 for v0.2 Publication & Compatibility*
