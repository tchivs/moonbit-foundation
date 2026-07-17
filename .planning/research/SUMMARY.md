# Project Research Summary

**Project:** MoonBit Native Foundation — v0.2 Publication & Compatibility
**Domain:** High-integrity MoonBit registry publication, provenance, and public API compatibility
**Researched:** 2026-07-17
**Confidence:** MEDIUM

## Executive Summary

v0.2 is a publication-integrity milestone, not a feature release. The already-qualified `mb-core`, `mb-color`, and `mb-image` candidates must become genuinely published, independently resolvable Mooncakes modules without weakening the v0.1 Required gate. The expert approach is to preserve the existing MoonBit and PowerShell quality architecture, add a credential-free release-preparation plane, and place the one irreversible registry mutation behind a small, serialized, manually authorized publisher.

The recommended chain is deliberately strict: verify the real namespace and canonical names; freeze toolchain-owned `.mbti` compatibility baselines and major-zero change rules; qualify deterministic package inputs; publish and externally consume `mb-core`; then do the same for `mb-color`; then `mb-image`; finally bind source, package digests, registry observations, consumer results, interfaces, and workflow identity into verified provenance and an immutable release ledger. A successful CLI exit, workspace build, generated attestation, or matching version string is never sufficient evidence by itself.

The dominant risk is unknown external state. Current official MoonBit documentation does not fully specify Mooncakes organization delegation, non-interactive authentication, token scope/revocation, duplicate-publication behavior, version immutability, propagation timing, destructive recovery, or a registry-side package digest. These are not assumptions to fill in: they are live-probe gates. Until each relevant behavior is documented or safely observed, automation must fail closed, query before retry, preserve partial success, and correct forward with a new version rather than overwrite history. No graphics, document, media, AI, MCP, or other module family belongs in v0.2.

## Key Findings

### Recommended Stack

Keep the exact v0.1 MoonBit line and the existing PowerShell 7 Required pipeline as the release authority. Add project-owned compatibility, publication, and evidence scripts rather than a general-purpose release bot. GitHub Actions supplies protected environments, serialization, SHA-pinned execution, and artifact attestations; it does not supply Mooncakes authentication unless Mooncakes explicitly implements a trusted-publishing contract.

**Core technologies:**

- `moon 0.1.20260713` / `moonc v0.10.4` / `moonrun 0.1.20260713`: package, publish, resolve, generate `.mbti`, and verify four targets — retain the exact pin until the publication chain closes.
- PowerShell `7.6.3`: closed JSON policies, fail-closed orchestration, hashing, evidence, and cleanup — extend the established strict-mode scripts.
- Git and deterministic clean clones: bind one clean commit/tag to package bytes, interfaces, and evidence — reject dirty or identity-drifting candidates.
- GitHub Actions protected environment and one global concurrency group: expose the publisher credential only after authorization and never cancel a running mutation.
- SHA-pinned `actions/attest` plus `gh attestation verify`: attest and independently verify exact artifacts and the evidence manifest — provenance remains distinct from correctness and registry equality.
- `moon info --target all --frozen`: generate the public interface facts for committed compatibility baselines — project policy classifies changes because no official semantic-diff verdict is available.

Detailed stack decisions are in [STACK.md](STACK.md).

### Expected Features

**Must have (table stakes):**

- Verified owner namespace and canonical module identities, recorded without credentials.
- Exact independent module versions and dependency manifests with no path or workspace substitution.
- Deterministic package inventory and archive digests before any registry write.
- Machine-checked `.mbti` baselines and stricter-than-default major-zero change rules.
- One monotonic core → color → image publication state machine with observe-before-act recovery.
- Fresh registry-only consumers for each module layer, including the complete graph on `js`, `wasm`, `wasm-gc`, and `native`.
- Least-privilege credential isolation, full-SHA action pins, immutable attempt records, support/security contacts, changelogs, and migration notes.
- Post-publication registry observation and provenance verification against expected source/workflow identity.

**Should have (differentiators):**

- A source-to-registry evidence chain joining commit, Required digest, deterministic archive, interface baseline, registry resolution, consumer result, and attestation.
- Fail-closed interface classification that rejects unknown syntax or ambiguous behavioral impact.
- Resumable monotonic publication that preserves a valid lower-layer release when a dependent module fails.
- A small, versioned, consumer-readable release manifest and rehearsed recovery negatives before credentials are enabled.

**Defer beyond v0.2:**

- Every new graphics, document, media, AI, MCP, GPU, or integration module family.
- Stable `1.0.0`, long-term support promises, or compatibility beyond the tested toolchain and targets.
- A generic multi-ecosystem release platform, automatic destructive registry recovery, broad SBOM/vulnerability machinery, or a custom signing scheme.

Detailed scope and acceptance evidence are in [FEATURES.md](FEATURES.md).

### Architecture Approach

Keep the runtime architecture unchanged and add a release-control plane around it. Qualification and publication are separate trust domains: the large Required job stays credential-free and read-only; a release intent fixes HEAD, module/version DAG, package digests, interface digests, authority evidence, and order; an explicit sole-owner authorization releases one exact intent to a minimal publisher; a journaled orchestrator publishes and verifies each dependency layer; provenance and immutable release closure happen only after all clean registry consumers pass.

**Major components:**

1. **Namespace authority and release-intent contracts** — closed records for owner facts, exact HEAD, versions, dependency order, candidate digests, interface digests, and authorization.
2. **Compatibility baseline and diff gate** — pinned `.mbti` generation, minimal normalization, closed package/target sets, version/RFC classification, and negative corpus.
3. **Credential-free preparation** — the full existing Required lane, deterministic two-copy packaging, candidate reports, and provenance inputs.
4. **Publication authority and publisher adapter** — one exact intent approval and the only boundary allowed to materialize Mooncakes credentials.
5. **Monotonic publication journal** — fixed module transitions, external-state reconciliation, bounded propagation observation, and no blind retries.
6. **Registry consumer verifier** — cold external projects without `moon.work`, path dependencies, copied sources, Git fallbacks, warm caches, or publisher credentials.
7. **Provenance and immutable finalizer** — attest exact artifacts/evidence, verify trusted identity, seal the release ledger, and promote published compatibility baselines.
8. **Recovery/supersession controller** — preserve evidence and partial success, then correct forward; never assume overwrite, yank, delete, or tag movement.

Detailed boundaries and data flow are in [ARCHITECTURE.md](ARCHITECTURE.md).

### Critical Pitfalls

1. **Workspace substitution masquerades as registry success** — authoritative consumers must live outside the repository, use exact registry versions, isolate cache/home state, and record dependency trees plus four-target results.
2. **A timeout is treated as a failed publish** — enter an explicit unknown-outcome state, query the registry with bounded observation, and never retry or bump versions before reconciling external facts.
3. **Modules publish in parallel or before dependencies are consumable** — serialize publish → resolve → consume for core, then color, then image; partial verified success is valid resumable state.
4. **Credentialed jobs execute broad or mutable code** — keep Required credential-free, use a protected environment and trusted ref, pin actions by full SHA, and expose the registry credential only to the publish step.
5. **Concurrent/cancelled workflows split a release** — use one global publication concurrency group, disable cancellation after mutation begins, and checkpoint observations immediately.
6. **Tag, manifest, baseline, changelog, and artifact refer to different commits** — one clean release intent must close every identifier and digest before authorization.
7. **Provenance is generated but not verified meaningfully** — verify exact subject digest and expected repository, workflow, builder, commit, parameters, and dependencies outside the producer job.
8. **`.mbti` text equality is mistaken for semantic compatibility** — pin and normalize conservatively, fail closed on unknown diffs, and retain black-box/conformance/consumer behavioral evidence.

The complete failure catalog and ownership map are in [PITFALLS.md](PITFALLS.md).

## Implications for Roadmap

The v0.1 roadmap ended at Phase 5. Continue numbering from Phase 6 with four phases.

### Phase 6: Namespace Authority and Compatibility Contract

**Rationale:** Identity, names, version rules, and compatibility oracles must be fixed before building any credentialed automation or publishing irreversible versions.

**Delivers:**

- live, sanitized namespace/authority evidence and canonical module names;
- explicit classification of every Mooncakes claim as documented, observed, or unknown;
- safe disposable probes for owner-prefix/permission, dry-run fidelity, credential representation, and `.mbti` reproducibility;
- committed per-module/package compatibility baselines with toolchain and digest manifests;
- strict candidate-version, migration-note, dependency-floor, target, and RFC rules;
- negative corpus for additive, incompatible, target-specific, alias/order, and unknown interface changes.

**Addresses:** verified identity, exact manifests, public API baselines, candidate evolution rules, metadata/support/changelog contracts.

**Avoids:** wrong namespace, unstable baseline, major-zero arbitrary breakage, undocumented claims, and incompatible patch releases.

### Phase 7: Release Safety, Intent, and Recovery Automation

**Rationale:** The publisher must enforce a closed intent and proven recovery model before it receives production credentials.

**Delivers:**

- closed release-intent, publication-policy, journal, evidence, and compatibility schemas;
- Required integration that retains every applicable v0.1 selector and adds workflow/interface/recovery negatives;
- credential-free preparation joining HEAD, Required digest, package bytes, interface digests, versions, and authority evidence;
- minimal publisher adapter behind the validated authentication seam;
- protected-environment policy, full-SHA action pins, least permissions, global serialization, and no cancellation after mutation;
- monotonic observe-before-act state machine with bounded propagation handling and recovery rehearsals for timeout, partial success, mismatched existing version, invalid credentials, and evidence failure.

**Uses:** PowerShell 7, pinned MoonBit, Git clean clones, GitHub environments/concurrency, and project-owned JSON policies.

**Implements:** release intent, preparation plane, authorization boundary, publisher adapter, and publication journal.

**Avoids:** token exposure, broad credentialed jobs, blind retry, payload drift, overlapping runs, evidence destruction, and pretend two-person governance.

### Phase 8: Ordered Mooncakes Publication and Registry Consumers

**Rationale:** Only real registry publication and external consumption can replace v0.1's honest blocked outcomes. Dependency order makes this one serialized phase with hard checkpoints.

**Delivers:**

- production authority preflight for one exact intent;
- `mb-core@0.1.0` publication followed by cold registry-only four-target consumer proof;
- `mb-color@0.1.0` publication followed by consumer proof against published core;
- `mb-image@0.1.0` publication followed by full-graph PPM consumer proof;
- registry propagation observations, dependency trees, module metadata, support/changelog visibility, and strongest available package identity evidence;
- resumable partial-state evidence with no duplicate mutation on rerun.

**Addresses:** real distribution, exact dependency resolution, clean consumers, registry-real target matrix, post-publication verification, and safe partial recovery.

**Avoids:** workspace/cache false positives, out-of-order packages, one oversized consumer, propagation-driven republish, and fabricated registry equality.

### Phase 9: Provenance, Immutable Closure, and Milestone Audit

**Rationale:** Attestation and immutable release claims are meaningful only after the public registry graph is proven consumable.

**Delivers:**

- artifact attestations for exact qualified package artifacts and the closed evidence manifest;
- independent `gh attestation verify` checks against expected repository/workflow identity;
- immutable tag/release/assets and all-identifiers consistency checks where repository plan/configuration supports them;
- final append-only release ledger linking attempts, registry facts, consumers, compatibility baselines, changelogs, support/security routes, and recovery dispositions;
- recovery drills for provenance failure and corrective supersession without destructive real-version mutation;
- final Required rerun, cross-phase audit, and explicit proof that no new module family entered v0.2.

**Addresses:** source-to-registry evidence, consumer-readable release manifest, verified provenance, immutable history, and milestone closeout.

**Avoids:** signature-only claims, wrong-subject attestations, mutable release assets, tag/asset drift, and evidence loss during recovery.

### Phase Ordering Rationale

- Namespace authority and compatibility policy precede tooling because they define what the publisher is allowed to publish and what version is valid.
- Safety/recovery precedes credentials because ambiguous remote writes cannot be repaired reliably by adding retries later.
- Publication follows the manifest DAG, and every lower layer must be externally consumable before a dependent layer is mutated.
- Provenance closes the chain after registry facts exist; it cannot substitute for registry consumers or API compatibility.
- Four phases keep irreversible live publication separate from policy/tool construction while preserving one cohesive publication transaction.
- New module families remain excluded throughout; expanding API surface before distribution and compatibility are real would violate the milestone goal.

### Research Flags

Phases requiring deeper phase research:

- **Phase 6:** mandatory live research for Mooncakes namespace authority, organization delegation, credential storage/scope/revocation, dry-run fidelity, and cross-machine `.mbti` stability.
- **Phase 7:** mandatory focused research/spike for the exact non-interactive authentication seam, duplicate/ambiguous publish responses, cleanup proof, and repository environment/plan constraints.
- **Phase 8:** live measurement is part of execution for propagation timing, registry artifact identity, cache isolation, and already-present reconciliation; plan it as bounded observation rather than assuming semantics.

Phases with mostly established patterns:

- **Phase 9:** GitHub attestations, expected-identity verification, draft-first immutable release handling, closed ledgers, and final audits are well documented; only repository availability/configuration needs confirmation.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Exact local MoonBit/PowerShell/GitHub CLI behavior was verified and GitHub controls are officially documented; Mooncakes automation details remain unknown. |
| Features | MEDIUM | The acceptance chain is strongly supported by official tooling/security specifications and the v0.1 baseline; live registry behavior limits certainty. |
| Architecture | MEDIUM-HIGH | The control plane extends proven repository seams and standard irreversible-operation patterns; the publisher adapter depends on an unverified auth contract. |
| Pitfalls | MEDIUM-HIGH | Boundary failures and mitigations are well established; Mooncakes-specific failure responses and propagation must be observed. |

**Overall confidence:** MEDIUM

### Gaps to Address

- **Namespace authority:** prove the real account can publish the final prefix; do not infer authority from GitHub organization ownership or a public page.
- **Authentication:** determine the supported non-interactive representation, least scope, expiry, rotation, revocation, redaction, and cleanup behavior with a disposable credential.
- **Version mutation semantics:** safely observe duplicate publish, immutability, yank/delete/overwrite behavior, and correct response classification without depending on destructive recovery.
- **Unknown outcome and propagation:** establish bounded observation/backoff and read-before-retry behavior from real responses.
- **Registry artifact identity:** discover whether Mooncakes exposes a canonical digest; otherwise state the limit and use clean consumer/interface/metadata evidence without claiming byte identity.
- **Compatibility stability:** reproduce `.mbti` baselines for all modules and targets on at least two clean environments before treating the normalized form as authoritative.
- **GitHub release controls:** confirm the repository remote, visibility, plan, environment protections, and immutable-release availability before making those exact controls blocking.
- **Behavioral compatibility:** interface comparison cannot prove resource, error, representation, or behavior compatibility; keep black-box, fixture, conformance, and registry-consumer evidence mandatory.

## Sources

### Primary and Official

- [MoonBit: Use and publish packages](https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html) — login, registry publication, SemVer, minimal version selection, and metadata.
- [MoonBit: Command-line help](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — `moon info`, `package`, `publish`, `update`, and dependency commands.
- [MoonBit: Module configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html) — names, versions, dependencies, contents, metadata, and targets.
- [MoonBit: Workspace support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html) — local-member substitution and module-scoped publication boundaries.
- [Semantic Versioning 2.0.0](https://semver.org/) — released-content and version-change semantics.
- [GitHub Actions: Deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments) — protection and secret-release timing.
- [GitHub Actions: Workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — permissions, serialization, and cancellation behavior.
- [GitHub Actions: Secure use](https://docs.github.com/en/actions/reference/security/secure-use) — least privilege, untrusted triggers, credentials, and full-SHA pins.
- [GitHub: Artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations) — provenance generation and verification.
- [GitHub: Immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases) — draft-first release sealing and GitHub tag/asset immutability.
- [SLSA v1.2 provenance and verification](https://slsa.dev/spec/v1.2/provenance) — subject, builder, parameters, dependencies, and verifier expectations.
- [Sigstore verification guidance](https://docs.sigstore.dev/cosign/verifying/verify/) — identity-aware verification boundaries.

### Direct Project Evidence

- The v0.1 Required selector, deterministic package, policy, report, and consumer seams inspected by the architecture researcher.
- Local 2026-07-17 command verification for `moon 0.1.20260713`, `moonc v0.10.4`, PowerShell `7.6.3`, and GitHub CLI `2.96.0`.
- Repeated pinned-toolchain `moon info --target all --frozen` generation with stable `mb-core` `.mbti` hashes on the local research machine.

### Unknown / Live Validation Required

- Mooncakes namespace delegation, token model, version mutation, propagation, registry digest, and ambiguous-publication semantics have no sufficiently complete official public contract in the reviewed sources. Treat each as unknown until a sanitized live probe or registry-operator documentation establishes it.

---
*Research completed: 2026-07-17*
*Ready for roadmap: yes, with live-probe gates preserved*
