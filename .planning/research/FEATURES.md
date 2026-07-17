# Feature Landscape

**Domain:** High-integrity MoonBit library publication and compatibility
**Milestone:** v0.2 Publication & Compatibility
**Researched:** 2026-07-17
**Overall confidence:** MEDIUM — official MoonBit, GitHub, SLSA, Sigstore, and SemVer sources establish the mechanics and security model; mooncakes.io does not publicly document several recovery and immutability behaviors, so those must be proven against the live registry.

## Executive Recommendation

v0.2 should do one thing exceptionally well: turn the already-qualified `0.1.0` candidates into three genuinely consumable registry modules whose published bytes, dependency graph, source revision, public interfaces, and recovery state can be independently verified. Do not add library features or a new module family.

The minimum credible sequence is: verify the owner namespace and exact public names; freeze normalized public-interface baselines; qualify immutable package inputs; publish `mb-core`, then consume it outside the workspace; publish `mb-color`, then consume it against the registry `mb-core`; publish `mb-image`, then consume the complete registry graph; finally attach provenance and close the release ledger. Each step must be resumable without republishing an already-successful version.

The strongest differentiator is not merely automation. It is a fail-closed evidence chain from source commit to deterministic package digest to registry resolution to clean four-target external consumers. Automation should minimize credential exposure and human error, but the mooncakes token remains a protected, isolated credential unless and until the registry officially supports a tokenless/OIDC publishing flow.

## Table Stakes

Features users expect. Missing = the publication milestone is not credible.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Verified owner namespace and canonical module names | Mooncakes requires published module names to begin with the publishing username; a package cannot be consumed under a placeholder identity | Med | Prove authority with the real authenticated account before changing all manifests; record identity, not the token |
| Exact version and dependency manifests | Moon uses SemVer and minimal version selection; downstream results depend on declared versions | Med | Preserve independent versions; publish only exact named registry dependencies, never paths or workspace-only assumptions |
| Dependency-ordered publication | `mb-color` needs published `mb-core`; `mb-image` needs published lower layers | Med | Hard order: core → core consumer → color → color consumer → image → full consumer |
| Package-content preflight | Registry publication is effectively an external mutation; accidental files or missing docs cannot be corrected by pretending the upload did not happen | Low | Gate `moon package --list --frozen`, deterministic archive digests, license, README, API docs, changelog, support, and provenance inputs |
| Clean external registry consumers | A monorepo build does not prove real distribution | High | Create fresh projects without `moon.work`, path dependencies, copied sources, or warm local module caches; add exact versions and import public packages |
| Four-target compatibility consumers | MNF promises `js`, `wasm`, `wasm-gc`, and `native` portability | Med | External consumers must check/test every claimed target, not just Native |
| Public API baselines | Candidate evolution needs a precise, reviewable public surface | Med | Generate `moon info --target all --no-alias`; normalize and freeze `.mbti` output per module/package/target |
| Candidate-version change rules | SemVer alone permits broad change during major zero and does not define MoonBit-specific source compatibility | Med | MNF policy: patch = no incompatible public-interface delta; additive candidate API = minor; incompatible change = minor plus migration note until 1.0 |
| Metadata and discovery completeness | Mooncakes displays README and manifest metadata | Low | Require SPDX license, description, keywords, repository, homepage, supported targets, install/import snippet, and exact-version example |
| Changelog and migration notes | Consumers must understand what changed and whether action is required | Low | One changelog per independent module; link every interface delta to a version classification and migration note when incompatible |
| Support and security contact | Published foundations need an actionable maintenance path | Low | State support scope, issue location, vulnerability-reporting path, supported toolchain/targets, and response expectations without promising an organization-sized SLA |
| Least-privilege release job | Publication credentials must not be exposed to untrusted code or unrelated jobs | Med | Protected tag/manual environment; read-only by default; isolate the mooncakes token only in the publish step; pin actions to full SHAs |
| Artifact provenance and digest binding | Consumers need evidence that an artifact came from the intended source and builder | Med | Attest the exact deterministic package archives/digests with source commit, builder identity, parameters, and resolved dependencies |
| Post-publication verification | A successful CLI exit is not proof that registry content resolves correctly | High | Query the registry, add the exact version in a clean consumer, verify metadata and interfaces, and compare the observed artifact/digest when the registry exposes it |
| Safe retry and recovery state machine | Network and registry failures can leave partial success across three modules | High | Persist states such as `qualified`, `published`, `registry_verified`, `consumer_verified`; re-observe external state before every retry |
| Immutable release ledger | Publication evidence must survive CI log expiry and distinguish facts from intentions | Med | Record source/tag, module/version, package digest, API baseline digest, registry URL/identity, provenance identity, consumer result, and recovery disposition |

## External-Consumer Expectations

An external-consumer proof is valid only if all of the following are true:

1. It starts from a newly created directory outside the MNF repository and does not inherit `moon.work`.
2. It resolves the exact published module version through mooncakes.io using the documented `moon add`/manifest flow.
3. It imports and exercises only public package names and public APIs.
4. It checks or tests `js`, `wasm`, `wasm-gc`, and `native` with the pinned compatibility toolchain.
5. For `mb-color` and `mb-image`, its dependency tree shows the intended published lower-layer versions rather than local substitution.
6. It records module/version, resolved dependency tree, toolchain, target results, and a stable behavioral assertion.
7. It runs once from a deliberately clean module cache or isolated Moon home; a warm-cache rerun may supplement but never replace this proof.

The final v0.2 proof should include three small consumers, not one oversized showcase: a core-only consumer, a color consumer that proves registry `mb-core`, and an image/PPM consumer that proves the full graph. This localizes failures and gives each independently publishable module its own adoption contract.

## Differentiators

Features that set MNF apart. Not universally expected, but high value for a foundation.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Source-to-registry evidence chain | A consumer can trace a resolved version to one commit, deterministic package digest, API baseline, and attested build | High | Prefer standard GitHub/SLSA attestations over a custom signature format |
| Fail-closed compatibility classifier | Public-interface changes cannot silently pass under the wrong candidate version | High | Start with normalized `.mbti` exact/additive/removal/change rules; ambiguous syntax changes require review rather than optimistic classification |
| Registry-real target matrix | Portability claims are proven from published packages, not workspace sources | Med | Run the same public conformance slice against all four targets after each dependency layer publishes |
| Resumable monotonic release orchestration | A failed third publication can resume without mutating the first two releases | High | Observe-before-act and immutable per-module checkpoints make partial success recoverable |
| Consumer-readable release manifest | Downstream automation can verify versions, targets, digests, interfaces, support status, and evidence links | Med | Keep schema small and versioned; it summarizes authoritative artifacts rather than becoming another package manager |
| Recovery rehearsal before credentials | Failure modes are tested without risking registry mutations | Med | Exercise bad version, stale dependency, digest mismatch, missing evidence, interrupted step, and already-published-state handling in a local/fake seam |

## Provenance, Support, Changelog, and Recovery Contract

### Provenance

- Subject: each exact deterministic module archive, identified by SHA-256.
- Source: repository URL, immutable commit, and protected release tag/ref.
- Build: pinned MoonBit toolchain, workflow identity, declared parameters, and resolved dependencies.
- Signer/builder: use GitHub artifact attestations or a compatible Sigstore identity; consumers must verify the expected repository/workflow identity, not merely that a signature exists.
- Verification: publish the verification command and retain the attestation/evidence link in the release ledger.
- Boundary: provenance proves origin and process claims; it does not prove correctness, compatibility, or registry equality without the separate qualification and consumer evidence.

### Support and changelog

- Every module README must show exact install/import commands, current candidate status, supported targets/toolchain, documentation link, issue tracker, and security-reporting route.
- Every published version gets an immutable changelog entry. Entries distinguish additive public API, compatible fix, incompatible candidate change, documentation/evidence-only change, and dependency-floor change.
- An incompatible candidate change requires a migration note and a minor-version bump; removing or changing a public declaration in a patch release fails closed.
- Do not claim stable `1.0`, long-term support, guaranteed response times, or compatibility beyond the tested toolchain/targets.

### Retry and recovery

- Preflight is repeatable and side-effect free; publishing is a separate protected transition.
- Before acting, query the registry. If the exact name/version exists, verify it against expected metadata/artifact evidence and advance only on a match; mismatch is an incident, never an overwrite attempt.
- Never auto-increment a version merely to escape a failed publish. Diagnose whether the version is absent, successfully published, or published with unexpected content.
- If core succeeds and color/image fail, preserve core as a valid published release, correct downstream manifests/evidence, and resume in order.
- Because official mooncakes documentation reviewed here does not specify yank/delete/overwrite guarantees, v0.2 must discover and document the live behavior before relying on any of them. The default recovery is forward-only publication of a corrected new version plus an advisory, not destructive mutation.
- Credential rotation, registry outage, partial upload, post-publish verification failure, and provenance failure each need a runbook with an explicit stop/continue rule.

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| New module families or new image features | They dilute the publication milestone and create new compatibility surface before distribution works | Freeze `mb-core`, `mb-color`, and `mb-image` except compatibility/release fixes |
| Monolithic all-modules release | It defeats independent versioning and makes partial recovery harder | Publish and verify each module as its own transition |
| Workspace consumer presented as publication proof | Workspace substitution can hide missing or incorrect registry dependencies | Use isolated registry-only consumers without `moon.work` |
| Automated publishing on every merge | It expands credential exposure and converts ordinary source changes into irreversible external mutations | Protected release tag/manual approval after qualification |
| Long-lived credential in build/test jobs | Any dependency or action in those jobs could exfiltrate it | Inject the token only into the isolated publish step/environment |
| Unpinned third-party actions | Tags can move and make the release builder non-reproducible | Pin full commit SHAs and record them in provenance |
| Custom cryptographic signing scheme | It creates unverifiable maintenance risk and weak consumer tooling | Use GitHub artifact attestations/Sigstore-compatible standards |
| Compatibility by source diff or test pass alone | Private edits look breaking while public semantic changes can escape tests | Compare normalized generated public interfaces and run external consumers |
| Optimistic compatibility classification | MoonBit type/interface nuances may exceed a first classifier | Fail closed on unknown deltas and require explicit policy review |
| Registry overwrite/yank/delete automation | Public recovery semantics are not documented strongly enough to assume safe destructive operations | Verify live capabilities; prefer forward fixes and advisories |
| General-purpose release platform | A reusable multi-ecosystem engine is much larger than MNF v0.2 | Implement a small MNF-specific orchestrator with clear seams |
| Broad SBOM or dependency-vulnerability program | Useful later, but three source modules with known dependencies do not justify delaying real publication | Record exact resolved dependencies/provenance now; add SBOMs when native/transitive dependencies expand |
| Stable 1.0 promise | Three newly published candidates lack real consumer feedback | Retain candidate rules and collect adoption evidence first |

## Feature Dependencies

```text
live namespace authority
  → canonical module identities
    → exact manifests + dependency versions
      → normalized public-interface baselines
        → deterministic package qualification
          → protected credential boundary + release ledger
            → publish mb-core
              → clean core consumer
                → publish mb-color
                  → clean color consumer against registry core
                    → publish mb-image
                      → clean image consumer against full registry graph
                        → provenance verification + final compatibility closure
```

Cross-cutting dependencies:

```text
support/changelog policy → package qualification → publication
safe retry model → every external mutation
negative recovery rehearsal → credentialed workflow enablement
exact artifact digest → provenance attestation → post-publication evidence
public API baseline → version classifier → manifest/changelog approval
```

## Minimal v0.2 Recommendation

Prioritize:

1. **Identity and compatibility freeze:** verify the live namespace; choose final names; generate normalized per-target `.mbti` baselines; codify strict major-zero change rules.
2. **Release safety and evidence:** retain the v0.1 Required gate, qualify exact archives, isolate credentials, pin workflow dependencies, implement monotonic checkpoints, and rehearse recovery negatives.
3. **Layered real publication:** publish core → color → image, stopping after each for a clean exact-version four-target consumer.
4. **Provenance and closeout:** attest exact package digests, verify expected identity, publish support/changelog/recovery material, and freeze a machine-readable release ledger.

Defer:

- **Any new graphics/document/media/AI/MCP module:** distribution and compatibility must be proven first.
- **`1.0.0` stability:** wait for external usage and at least one intentionally managed compatibility evolution.
- **Generic release tooling:** keep the workflow specific to these three modules until reuse pressure is real.
- **Automatic destructive registry recovery:** no reliance until mooncakes documents or live tests prove exact semantics.
- **Full SBOM/vulnerability automation:** revisit when native adapters or meaningful transitive dependencies appear.
- **Signing beyond exact release artifacts:** attest the artifacts consumers can actually obtain; avoid evidence volume without a verifier use case.

## Acceptance Evidence

v0.2 is feature-complete only when:

1. The authenticated namespace and three final module names are recorded without exposing credentials.
2. Every published module/version is observable on mooncakes.io with correct metadata, exact dependencies, README, license, and changelog.
3. `mb-core`, `mb-color`, and `mb-image` each pass a fresh registry-only consumer; the complete graph passes all four supported targets.
4. Generated public-interface baselines are frozen, reproducible, and linked to version-policy decisions; negative deltas fail the gate.
5. The exact qualified archive digest is bound to source/build provenance and verification succeeds for the expected repository/workflow identity.
6. A rerun at any completed checkpoint performs no duplicate mutation and detects mismatched external state.
7. Recovery documentation covers partial publication, registry outage, invalid credential, provenance failure, unexpected existing version, and post-publication consumer failure.
8. No new module family or unrelated public feature entered the milestone.

## Open Gaps Requiring Live Validation

- Whether mooncakes supports organizations distinct from usernames and how authority is administered.
- Whether an already-published version is immutable, replaceable, deletable, or yankable, and what consumers observe after each operation.
- Whether `moon publish` has a supported noninteractive/dry-run mode in the pinned toolchain beyond `moon package --list --frozen`.
- Whether the registry exposes a canonical downloadable artifact digest that can be compared directly with the locally qualified archive.
- The precise token scope/rotation/revocation model and whether mooncakes supports OIDC or narrower publish-only credentials.
- Whether generated `.mbti` output is byte-stable across clean machines for all targets; normalization must be proven before it becomes the compatibility authority.

These gaps are not reasons to broaden scope. They are explicit first-phase experiments and stop conditions.

## Sources

- [MoonBit: Use and publish packages](https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html) — publishing, SemVer, minimal version selection, metadata, external imports (MEDIUM, official/current)
- [MoonBit: Module Configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html) — namespace-prefixed names, versions, dependencies, package contents, metadata (MEDIUM, official/current)
- [MoonBit: Workspace Support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html) — workspace substitution, version sync, module-scoped publishing (MEDIUM, official/current)
- [MoonBit: Command-Line Help](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — `moon publish`, `moon package`, `moon add`, and `moon info` `.mbti` generation (MEDIUM, official/current)
- [Semantic Versioning 2.0.0](https://semver.org/) — public API and version semantics, including major-zero limits (MEDIUM, primary specification)
- [GitHub: Using artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations) — OIDC permissions, artifact provenance, and verification (MEDIUM, official/current)
- [GitHub Actions: Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use) — least privilege, full-SHA pinning, and credential isolation rationale (MEDIUM, official/current)
- [SLSA v1.2 Provenance](https://slsa.dev/spec/v1.2/provenance) — provenance subject, build definition, dependencies, builder, and verification model (MEDIUM, primary/current)
- [Sigstore: Signing blobs](https://docs.sigstore.dev/cosign/signing/signing_with_blobs/) and [verifying signatures](https://docs.sigstore.dev/cosign/verifying/verify/) — standard keyless signing and identity-aware verification (MEDIUM, official/current)

## Recommended Decision

Approve v0.2 as a **publication-integrity milestone**, not a feature release. The optimal plan is the smallest real chain that proves independently resolvable modules: freeze interfaces and candidate rules, build a protected resumable release workflow, publish and externally verify one dependency layer at a time, then bind the resulting artifacts to standard provenance. Any proposal that adds a new module family, claims 1.0 stability, or treats a workspace build as registry evidence should be rejected for this milestone.
