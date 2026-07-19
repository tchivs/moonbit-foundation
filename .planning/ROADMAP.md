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

- [x] **Phase 6: Namespace Authority and Compatibility Contract** — Verify registry authority and establish deterministic public-interface, versioning, and publication-documentation contracts. (completed 2026-07-18)
- [x] **Phase 7: Release Safety, Intent, and Recovery Automation** — Bind publication to an exact credential-free intent and a resumable, forward-only state machine. (completed 2026-07-18)
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

**Plans:** 25/25 plans complete
**Completed foundation**

- [x] 06-02-PLAN.md — Define baseline contracts and mechanically generate 17-package × 4-target interface evidence.

**Wave 2** *(depends on 06-02)*

- [x] 06-03-PLAN.md — Implement four-class comparison, version/evidence policy enforcement, and exact negatives.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 06-04-PLAN.md — Establish shared support/security routes and the collective source-document validator.

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 06-05-PLAN.md — Complete the three bounded module publication-documentation sets.

**Wave 5 — canonical personal identity authority** *(depends on Wave 4)*

- [x] 06-07-PLAN.md — Rebase closed policies, schemas, and the blocked authority seed to canonical `tchivs/*` 0.1.0 truth.

**Wave 6 — canonical module roots** *(depends on Wave 5)*

- [x] 06-12-PLAN.md — Rebase the three module manifests and one bounded root-adjacent smoke package.

**Wave 7 — active module source graph** *(depends on Wave 6)*

- [x] 06-08-PLAN.md — Rebase the remaining 15 explicit package files and close the 17-package graph on all four targets.

**Wave 8 — examples and benchmark** *(depends on Wave 7)*

- [x] 06-09-PLAN.md — Rebase both public examples and the bounded benchmark with executable qualification.

**Wave 9 — qualification prerequisite repair** *(depends on Wave 8)*

- [x] 06-25-PLAN.md — Reconcile the three module repository fields and shared positive qualification constants before the real consumer path resumes.

**Wave 10 — package consumers and release qualification** *(depends on Wave 9)*

- [x] 06-13-PLAN.md — Rebase isolated package consumers and retain exact positive/negative release-qualification ownership.

**Wave 11 — public documentation truth** *(depends on Wave 10)*

- [x] 06-10-PLAN.md — Reconcile the explicit project, research, and module documentation set while preserving branding.

**Wave 12 — shared routes and collective validators** *(depends on Wave 11)*

- [x] 06-14-PLAN.md — Reconcile support/security routes and collective source, compatibility, and authority validators.

**Wave 13 — baseline batch tooling** *(depends on Wave 12)*

- [x] 06-15-PLAN.md — Add deterministic exact-package batching and guarded manifest finalization semantics.

**Wave 14 — baseline batch 1** *(depends on Wave 13)*

- [x] 06-16-PLAN.md — Regenerate the bounded mb-core budget and bytes baseline outputs.

**Wave 15 — baseline batch 2** *(depends on Wave 14)*

- [x] 06-17-PLAN.md — Regenerate the bounded mb-core checked and error baseline outputs.

**Wave 16 — baseline batch 3** *(depends on Wave 15)*

- [x] 06-18-PLAN.md — Regenerate the bounded mb-core host and io baseline outputs.

**Wave 17 — baseline batch 4** *(depends on Wave 16)*

- [x] 06-19-PLAN.md — Regenerate the bounded mb-color alpha and model baseline outputs.

**Wave 18 — baseline batch 5** *(depends on Wave 17)*

- [x] 06-20-PLAN.md — Regenerate the bounded mb-color profile and quantize baseline outputs.

**Wave 19 — baseline batch 6** *(depends on Wave 18)*

- [x] 06-21-PLAN.md — Regenerate the bounded mb-color transfer and mb-image codec baseline outputs.

**Wave 20 — baseline batch 7** *(depends on Wave 19)*

- [x] 06-22-PLAN.md — Regenerate the bounded mb-image metadata and model baseline outputs.

**Wave 21 — baseline batch 8** *(depends on Wave 20)*

- [x] 06-23-PLAN.md — Regenerate the bounded mb-image ops and ppm baseline outputs.

**Wave 22 — baseline batch 9** *(depends on Wave 21)*

- [x] 06-24-PLAN.md — Regenerate the bounded mb-image storage baseline outputs.

**Wave 23 — final manifest, history, and full-suite closure** *(depends on Wave 22)*

- [x] 06-11-PLAN.md — Finalize the single exact 103-file-tree manifest, enforce immutable identity/history classification, and run the full credential-free suite.

**Wave 24 — external identity checkpoint** *(depends on Wave 23)*

- [x] 06-01-PLAN.md — Complete one human Mooncakes OAuth checkpoint, capture sanitized read-only personal-namespace proof, and enforce readiness without external repository creation or publication.

**Wave 25** *(blocked on Waves 2-24 completion)*

- [x] 06-06-PLAN.md — Freeze reciprocal requirement, 22-edge, and seven-prohibition coverage and integrate all credential-free gates into Required.

### Phase 7: Release Safety, Intent, and Recovery Automation

**Goal:** The sole maintainer can authorize one exact credential-free release intent and safely execute or resume an isolated publisher state machine.

**Depends on:** Phase 6

**Requirements:** REL-01, REL-02, REL-03, REL-04, REL-05

**Success Criteria:**

1. Required produces an immutable, credential-free release intent binding one authorized release tag/ref to the exact source commit, ordered module versions and dependencies, package inventories and archive digests, interface-baseline digests, and qualification evidence.
2. The publisher accepts only the sole maintainer's explicit authorization of that exact intent from a protected trusted ref; third-party actions are full-SHA pinned, default permissions are read-only, and the least-privilege Mooncakes credential reaches only the isolated mutation step.
3. A release-wide serialization lock and monotonic journal prevent concurrent, replayed, duplicate, cancelled-in-progress, and dependency-order-violating transitions while preserving completed checkpoints.
4. Credential-free negative rehearsals cover timeout, partial success, existing-version mismatch, invalid credential, and evidence failure; ambiguous real failures trigger registry re-observation before any retry, and mismatches stop with incident evidence plus a forward corrected version and advisory.

**Plans:** 3/3 plans complete

- [x] 07-01-PLAN.md
- [x] 07-02-PLAN.md
- [x] 07-03-PLAN.md

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

**Plans:** 12/14 plans executed
**Wave 1**

- [x] 08-01-PLAN.md

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 08-02-PLAN.md

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 08-03-PLAN.md

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 08-04-PLAN.md

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 08-05-PLAN.md

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 08-06-PLAN.md

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 08-07-PLAN.md — Define r2 attempt-family, terminal history, receipt, and handoff contracts.

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 08-08-PLAN.md — Wire r2 publisher/hosted seam and UTC-stable state tests.

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 08-09-PLAN.md — Define r3 attempt-family and three-history prepared/authority contracts.

**Wave 10** *(blocked on Wave 9 completion)*

- [x] 08-10-PLAN.md — Wire r3 publisher/hosted seam and preserve helper/UTC/LF/no-tags regressions.

**Wave 11** *(blocked on Wave 10 completion)*

- [x] 08-11-PLAN.md — Define r4 attempt-family and four-history prepared/authority contracts.

**Wave 12** *(blocked on Wave 11 completion)*

- [x] 08-12-PLAN.md — Wire r4 exact14 receipt-parity hosted seam and preserve isolation regressions.

**Wave 13** *(blocked on Wave 12 completion)*

- [ ] 08-13-PLAN.md — Establish the LF-clean r4 boundary and non-mutating AuthorityUnion handoff.

**Wave 14** *(blocked on Wave 13 completion)*

- [ ] 08-14-PLAN.md — Publish or recover core/color/image in order and close reciprocal evidence.

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
| 6. Namespace Authority and Compatibility Contract | v0.2 | 25/25 | Complete    | 2026-07-18 |
| 7. Release Safety, Intent, and Recovery Automation | v0.2 | 3/3 | Complete | 2026-07-18 |
| 8. Ordered Mooncakes Publication and Registry Consumers | v0.2 | 12/14 | In Progress|  |
| 9. Provenance, Immutable Closure, and Milestone Audit | v0.2 | 0/TBD | Not started | — |

## Stable Audit Anchors

- **phase-1-foundation-charter-and-reproducible-workspace:** Archived with its complete source inventory under `.planning/milestones/v0.1-phases/`.

---
*Roadmap updated: 2026-07-18 after Phase 7 completion*
