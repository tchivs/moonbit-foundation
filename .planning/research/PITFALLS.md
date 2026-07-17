# Domain Pitfalls

**Domain:** High-integrity MoonBit registry publication and compatibility
**Milestone:** v0.2 Publication & Compatibility
**Researched:** 2026-07-17
**Overall confidence:** MEDIUM — failure controls are strongly supported by current MoonBit, GitHub, SLSA, and SemVer documentation; mooncakes.io recovery, immutability, propagation, and credential semantics are incompletely documented and must be measured rather than assumed.

## Executive Assessment

The dangerous transition in v0.2 is from deterministic local evidence to irreversible external state. v0.1 deliberately represented registry-dependent checks as blocked; v0.2 must replace those blockers with authentic publication and consumer evidence without weakening the existing Required gate or pretending uncertain mooncakes behavior is known.

The dominant failure pattern is **false confidence across boundaries**: workspace substitution looks like registry resolution, a publish timeout looks like failure, a generated attestation looks like verified provenance, a raw `.mbti` diff looks like semantic compatibility, and matching version strings look like one release state. Every boundary therefore needs observe-before-act logic and evidence from the system on the far side of that boundary.

Recommended phase ownership used below:

1. **Phase A — Identity & Compatibility Contract:** live namespace facts, final names, version rules, normalized API baselines.
2. **Phase B — Release Safety & Recovery:** package manifest, credential boundary, concurrency, retry model, negative rehearsals.
3. **Phase C — Ordered Publication & Consumers:** core → color → image, registry observation, clean external consumers.
4. **Phase D — Provenance & Closure:** attestations, immutable release/tag binding, final ledger, incident/recovery verification.

No phase should add a new module family.

## Critical Pitfalls

### Pitfall 1: Workspace substitution masquerades as registry success

**What goes wrong:** `moon check`, `moon test`, `moon info`, and downstream examples pass because `moon.work` resolves local members. The published manifest is missing a dependency, names the wrong module/version, or references a version that does not exist.

**Why it happens:** MoonBit workspaces intentionally resolve members locally, and `moon work sync` can update member dependency versions. That is excellent for development but it is not a mooncakes consumer proof.

**Consequences:** `mb-color` or `mb-image` publishes successfully yet fails for every real user, or resolves a different dependency graph than the one qualified in v0.1.

**Warning signs:** Consumer directory is under the repository; `moon.work` is discoverable in an ancestor; manifests contain paths; dependency tree omits a registry version; test passes with network/cache disabled but no isolated registry fixture was established.

**Prevention:** Phase A freezes exact canonical names and dependency versions. Phase C creates a fresh directory outside the repository with no path dependency or workspace file, isolates Moon home/cache, adds the exact published version, and imports only public packages.

**Detection:** Record `moon tree`, manifests, module cache provenance, and four-target results. Deliberately rename/remove the workspace file in a copy and prove the consumer still resolves from the registry.

**Owner:** Phase A for manifest rules; Phase C for authoritative proof.

### Pitfall 2: A publish timeout is treated as a failed publication

**What goes wrong:** Network response is lost after the registry accepts an upload. Automation immediately retries, increments the version, or overwrites local evidence without first observing external state.

**Why it happens:** Distributed mutations have an unknown-outcome state. Exit status alone cannot distinguish “not accepted” from “accepted but response lost” or “accepted but not yet visible.”

**Consequences:** Duplicate/conflicting attempts, skipped versions, partial dependency chains, or an incident where local digest and registry content disagree.

**Warning signs:** Retry loop calls `moon publish` directly; a timeout is classified as `failed`; no `(module, version, expected digest)` checkpoint exists; version bump is suggested automatically after any error.

**Prevention:** Phase B defines monotonic states: `qualified → publish_attempted → registry_observed → consumer_verified`. After any ambiguous outcome, query registry state with bounded backoff before another mutation. Never auto-bump to escape uncertainty.

**Detection:** Negative rehearsal terminates the client after request submission and verifies that resumption observes before acting. Audit logs show one mutation attempt per observed-absent state.

**Owner:** Phase B designs and tests the state machine; Phase C uses it.

### Pitfall 3: Partial success violates dependency order

**What goes wrong:** Jobs publish modules in parallel, or continue to `mb-color`/`mb-image` before the lower-layer registry package is visible and independently consumable.

**Why it happens:** The monorepo makes the modules appear like one build unit, while mooncakes publishes modules independently and Moon uses declared dependency versions.

**Consequences:** Downstream upload rejection, registry packages pointing to unavailable dependencies, misleading “release complete” status, and difficult recovery.

**Warning signs:** Matrix strategy covers all modules; no per-module registry consumer checkpoint; `needs` relationships stop at build jobs; downstream publish starts while registry propagation is unresolved.

**Prevention:** Phase C serializes core publish → core consumer → color publish → color consumer → image publish → full consumer. Partial success is valid state: preserve a verified core release and resume downstream later.

**Detection:** Release ledger cannot advance a module unless every declared MNF dependency has `consumer_verified`. Synthetic missing-dependency cases must fail before credentials are exposed.

**Owner:** Phase C.

### Pitfall 4: Credentialed jobs execute untrusted or mutable code

**What goes wrong:** A mooncakes token is available to pull-request code, a mutable third-party action, a broad reusable workflow, or an earlier build step that does not need it.

**Why it happens:** Repository-level secrets, broad `GITHUB_TOKEN` permissions, unsafe `pull_request_target`/`workflow_run` patterns, and action tags make release convenience override isolation.

**Consequences:** Registry takeover, malicious publication, token leakage, and inability to trust any release produced by the workflow.

**Warning signs:** Secret at repository scope; publish job checks out an untrusted ref; `permissions: write-all`; action uses `@vN`; secret appears in environment before qualification; self-hosted runner retains state.

**Prevention:** Phase B uses a dedicated environment and job, trusted tag/manual trigger, full-SHA action pins, read-only default permissions, and injects the registry token only at the final publish step. OIDC is used for GitHub attestations where supported; it must not be claimed for mooncakes unless live documentation proves support.

**Detection:** Static workflow policy, fork-event negative tests, permission snapshot, secret-canary/redaction review, and verified absence of the credential from build/test jobs.

**Owner:** Phase B; re-audited in Phase D.

### Pitfall 5: Concurrent or cancelled workflows split one release

**What goes wrong:** Two manual/tag runs publish different modules for the same intended release, or `cancel-in-progress` kills a job after an external mutation but before its checkpoint is recorded.

**Why it happens:** CI concurrency defaults are designed for replaceable builds, not irreversible ordered publication.

**Consequences:** Unrecorded successful publication, duplicated attempts, tag/version ambiguity, or downstream modules qualified against a different source state.

**Warning signs:** Concurrency key excludes release identity; publication runs can overlap; cancellation is enabled for release jobs; checkpoint is written only at workflow end.

**Prevention:** Phase B defines one release-wide concurrency group and disables cancellation after mutation begins. Write each checkpoint immediately after re-observing external state. A new run resumes; it does not supersede.

**Detection:** Start two synthetic runs and confirm only one reaches the credential boundary. Cancel after a fake publish and prove resume performs observation first.

**Owner:** Phase B.

### Pitfall 6: Tag, manifest, baseline, changelog, and artifact describe different commits

**What goes wrong:** A tag points to one commit while packages, `.mbti` baselines, dependency versions, changelogs, or attestations were generated from another. Late “metadata-only” commits invalidate the frozen release relation.

**Why it happens:** Independent module versions plus one repository create several identifiers, and evidence is often generated at different times.

**Consequences:** SemVer claims cannot be audited, consumers cannot reconstruct the release, and provenance attests the wrong bytes or source.

**Warning signs:** Dirty worktree during qualification; baseline generated before final source changes; tag created before dependency sync; package digest absent from the release manifest; changelog version differs by case/prefix.

**Prevention:** Phase A defines one canonical module/version/tag grammar. Phase B freezes a machine-readable release manifest at an exact clean commit; all artifacts and baselines are generated from it. Phase D creates immutable releases only after all assets are ready.

**Detection:** Closed-set gate compares manifest version, tag, changelog heading, dependency versions, API baseline digest, archive digest, source commit, and attestation subject.

**Owner:** Phase A policy, Phase B enforcement, Phase D final binding.

### Pitfall 7: Provenance exists but is not meaningfully verified

**What goes wrong:** The workflow emits an attestation and calls the release “proven,” while no consumer checks the exact artifact digest, trusted repository/workflow identity, builder, source ref, parameters, or resolved dependencies.

**Why it happens:** Signature generation is visible and easy; expectation-based verification is the security boundary. SLSA explicitly requires matching the subject digest and trusted signer-builder expectations.

**Consequences:** A valid attestation for the wrong artifact or untrusted workflow passes; registry substitution remains undetected; provenance is confused with correctness or compatibility.

**Warning signs:** Verification only tests “signature valid”; no expected repository/workflow is supplied; attested subject is a directory/glob with unstable contents; local archive and registry artifact are never compared.

**Prevention:** Phase D verifies signature, exact SHA-256 subject, expected repository/workflow/builder identity, source commit/tag, build type, external parameters, and resolved dependencies. Keep correctness, API compatibility, registry equality, and provenance as distinct evidence fields.

**Detection:** Negative attestations with wrong subject, repository, workflow, commit, or parameter must fail. Verification must run outside the producer job against downloaded assets.

**Owner:** Phase D.

### Pitfall 8: `.mbti` text equality is mistaken for semantic compatibility

**What goes wrong:** Raw generated-interface diffs reject harmless formatting/ordering/alias/toolchain changes, or pass changes in behavior, error contracts, representation, resource limits, trait coherence, and documentation not captured by declarations.

**Why it happens:** Official `moon info` generates public `.mbti` interfaces, but reviewed official docs do not define byte stability or provide a semantic compatibility verdict.

**Consequences:** False positives block releases; false negatives ship breaking candidate changes under the wrong version.

**Warning signs:** Baseline is one unnormalized text file; target/toolchain identity missing; unknown grammar is ignored; “no diff” is the only compatibility evidence; behavior contracts have no consumer tests.

**Prevention:** Phase A pins the toolchain and generates per-target, `--no-alias` baselines; normalization removes only proven nonsemantic variance. Phase B classifier recognizes a deliberately small set of additions/removals/signature changes and fails closed on unknown syntax. Phase C consumers cover documented behavior.

**Detection:** Corpus of compatible, incompatible, target-specific, alias, ordering, documentation, and behavioral changes with expected classifications. Reproduce baselines on two clean machines before freezing the format.

**Owner:** Phase A baseline design; Phase B classifier; Phase C behavioral backstop.

## Moderate Pitfalls

### Pitfall 9: Cache warmth hides registry or dependency failure

**What goes wrong:** A consumer succeeds using a locally cached candidate or stale registry index even though a clean machine cannot resolve the release.

**Warning signs:** First-install evidence has no isolated cache path, registry update, or resolved artifact timestamps.

**Prevention:** Phase C isolates Moon home/cache and records registry update/install/tree evidence. Run a cold consumer first, then a warm rerun only as secondary evidence.

**Detection:** Unexpected success while registry reports absence; dependency files predate publication; network-disabled run is presented as first install.

**Owner:** Phase C.

### Pitfall 10: Registry propagation delay is confused with permanent failure

**What goes wrong:** Immediate post-publish lookup fails, so automation republishes, rolls forward, or marks a valid release broken.

**Warning signs:** One lookup controls mutation; no timestamped observation series or distinct propagation state exists.

**Prevention:** Phase B defines bounded exponential polling and distinguishes `not_yet_observed` from `rejected` and `mismatch`. Phase C stops safely when the observation window expires.

**Detection:** Time-series registry observations are retained; recovery never mutates solely because one lookup missed.

**Owner:** Phase B policy; Phase C observation.

### Pitfall 11: SemVer major-zero ambiguity becomes an excuse for arbitrary breakage

**What goes wrong:** Because SemVer says `0.y.z` is initial development, incompatible changes ship in patch releases without migration notes.

**Warning signs:** Version decision cites only “0.x may change”; classifier permits removals in patches; changelog lacks migration classification.

**Prevention:** Phase A adopts a stricter MNF candidate contract: patch forbids incompatible public changes; additive public API uses minor; incompatible candidate change uses minor plus migration note. Released bytes are never modified regardless of major zero.

**Detection:** Version-classification negatives and changelog/baseline cross-check.

**Owner:** Phase A.

### Pitfall 12: Documentation claims capabilities that the registry has not proven

**What goes wrong:** README or release notes claim organization namespaces, immutable mooncakes versions, yanking, token scopes, OIDC, registry digests, or successful publication based on analogy rather than evidence.

**Warning signs:** A mooncakes claim cites GitHub/npm behavior, lacks an official URL or live observation, or changes from “unknown” straight to “supported.”

**Prevention:** Phase A labels each registry behavior `documented`, `observed`, or `unknown`. Unknowns become experiments and stop conditions. GitHub release immutability must not be projected onto mooncakes.

**Detection:** Claims gate requires a source or captured live observation for every external-state statement.

**Owner:** Phase A classification; Phase D final claims audit.

### Pitfall 13: Recovery destroys evidence

**What goes wrong:** Logs/checkpoints are overwritten during retry, tags are moved, assets are replaced, or a version is deleted before the mismatch is investigated.

**Warning signs:** A single `latest.json` is the only record; retries reuse artifact paths; remediation begins before evidence snapshot.

**Prevention:** Append-only attempt records, immutable release assets, forward corrections, and incident snapshots before any supported registry remediation. SemVer requires new versions for modified released contents.

**Detection:** Every retry preserves prior attempt ID, observed state, digest, and decision; final ledger links all attempts.

**Owner:** Phase B storage model; Phase D immutable closure.

### Pitfall 14: Solo-maintainer workflow invents a nonexistent second reviewer

**What goes wrong:** The plan depends on team approval, CODEOWNERS quorum, or separation of duties that cannot exist for the current sole developer, leading to bypasses or permanently blocked releases.

**Warning signs:** Required reviewer has no eligible second actor; success evidence says “independent approval” when the same maintainer initiated it.

**Prevention:** Phase B uses controls that work for one maintainer: explicit manual dispatch/tag intent, protected environment secret timing, concurrency, immutable evidence, deterministic negative tests, and independent machine verification. Do not claim human independence that did not occur.

**Detection:** Every required approval maps to an available actor; no gate requires a second person unless the project actually gains one.

**Owner:** Phase B.

## Minor Pitfalls

### Pitfall 15: Package listing and registry payload diverge

**What goes wrong:** Qualification hashes a custom archive while `moon publish` uploads a differently selected file set.

**Warning signs:** Digest input was not produced by the official package path; package inventory and attestation subject differ.

**Prevention:** Phase B derives the qualified subject from the exact official packaging path and checks `moon package --list --frozen`; record both file inventory and digest. If mooncakes does not expose the uploaded digest, state that equality is unproven and use the strongest observable substitute.

**Detection:** Repackage twice in clean copies, compare inventories/digests, and bind the same digest into the release ledger.

**Owner:** Phase B; Phase C confirms the strongest registry-visible identity.

### Pitfall 16: Version checks ignore build metadata precedence

**What goes wrong:** Two versions differing only in SemVer build metadata are treated as ordered releases even though build metadata does not affect precedence.

**Warning signs:** Release identity relies on `+commit` to distinguish registry revisions of otherwise equal versions.

**Prevention:** Phase A rejects ambiguous release identity schemes and uses normal `MAJOR.MINOR.PATCH` candidate versions for registry publication.

**Detection:** Version-policy negative fixtures reject equal-precedence release identities.

**Owner:** Phase A.

### Pitfall 17: Required gate is weakened to make publication pass

**What goes wrong:** Existing selectors, target coverage, deterministic packages, or honest blocked-state checks are deleted rather than evolved to authenticated outcomes.

**Warning signs:** Selector count drops without replacement mapping; registry success bypasses package/source-isolation checks; old negative cases disappear.

**Prevention:** Phase B adds authenticated result states and negative cases while retaining all applicable v0.1 Required guarantees. A new passing path must replace blockers with stronger evidence, not skip them.

**Detection:** Requirement/selector traceability compares v0.1 and v0.2 gates and rejects any unmapped removal.

**Owner:** Phase B, independently rechecked in Phase D.

## Phase-Specific Warnings

| Phase | Highest-risk failure | Mandatory mitigation | Exit evidence |
|------|----------------------|----------------------|---------------|
| Phase A — Identity & Compatibility Contract | Wrong namespace/name or unstable API baseline | Live authority observation; final names; pinned normalized per-target `.mbti`; strict candidate rules | Namespace fact record, baseline reproducibility, compatibility negative corpus |
| Phase B — Release Safety & Recovery | Token exposure, overlapping runs, ambiguous retry, payload drift | Isolated credential job, full-SHA pins, no unsafe triggers, monotonic state machine, exact package inventory, recovery rehearsal | Workflow policy negatives and mutation-free recovery simulations |
| Phase C — Ordered Publication & Consumers | Workspace/cache false positive or partial dependency chain | Serial core→color→image checkpoints, cold registry-only consumers, bounded propagation observation | Exact-version dependency trees and four-target external consumer results |
| Phase D — Provenance & Closure | Attestation without expectations or tag/artifact mismatch | Exact subject verification, trusted identity checks, immutable tag/assets, closed release ledger | External attestation verification and all-identifiers consistency gate |

## Unknown Official Semantics — Do Not Convert to Negative Claims

The reviewed official sources did **not** establish the following mooncakes behaviors. The correct conclusion is “unknown pending live validation,” not “unsupported”:

- organization namespace creation/delegation beyond the documented username prefix;
- token scopes, publish-only credentials, rotation/revocation guarantees, or OIDC publishing;
- whether a published module version can be overwritten, deleted, or yanked;
- registry propagation timing and consistency model;
- a canonical registry-side digest for the exact uploaded package;
- a noninteractive or dry-run `moon publish` mode in the pinned toolchain;
- an official semantic compatibility comparator for `.mbti` files.

Phase A should resolve identity/compatibility unknowns; Phase B should resolve credential and dry-run mechanics without publishing; Phase C should measure publication/propagation/recovery behavior with the real namespace. Until observed, gates must fail closed or report an honest blocked state.

## Sources

- [MoonBit: Workspace Support](https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html) — local workspace resolution, version sync, module-scoped publication
- [MoonBit: Module Configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html) — names, versions, dependencies, package include/exclude, metadata
- [MoonBit: Use and publish packages](https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html) — account token, SemVer, minimal version selection, external package use
- [MoonBit: Command-Line Help](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — `--frozen`, `moon package --list`, `moon publish`, and `moon info`
- [Semantic Versioning 2.0.0](https://semver.org/) — released-content immutability, public API, major-zero limits, and forward correction
- [GitHub Actions: Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use) — untrusted triggers, least privilege, secrets, full-SHA action pins
- [GitHub: Deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments) — environment secrets and protection timing
- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — concurrency and cancellation behavior
- [GitHub: Using artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations) — attestation generation and consumer verification
- [GitHub: Immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases) — tag/asset immutability and draft-first publication; applies to GitHub, not mooncakes
- [SLSA v1.2: Verifying artifacts](https://slsa.dev/spec/v1.2/verifying-artifacts) — subject digest, signature, trusted builder, parameters, and consumer-side verification

All source-backed findings are **MEDIUM confidence** under the configured research confidence classifier. Project-specific mitigations are reasoned recommendations grounded in those primary sources and the verified v0.1 repository state.
