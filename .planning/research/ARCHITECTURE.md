# Architecture Patterns

**Domain:** MoonBit registry publication, provenance, and API compatibility governance

**Project:** MoonBit Native Foundation v0.2 Publication & Compatibility

**Researched:** 2026-07-17
**Overall confidence:** MEDIUM

## Recommended Architecture

Keep the existing v0.1 architecture intact and add a release-control plane around it. The three MoonBit modules, package DAG, RFC-owned policy, and root `Required` selector pipeline remain the product architecture. v0.2 adds no runtime module and does not give publication credentials to `Required`.

The recommended design is a fail-closed, resumable publication state machine:

```text
                         no registry credential
                                 |
                                 v
RFC / namespace evidence -> Release Intent -> Required + API Diff + Package Build
                                  |                     |
                                  |                     +-> candidate digests
                                  |                     +-> compatibility report
                                  |                     +-> provenance attestation
                                  v
                       Manual publication authority
                     (exact intent digest + exact HEAD)
                                  |
                         environment-secret boundary
                                  v
                   Publish/resolve mb-core@version
                                  |
                   clean public registry consumer
                                  v
                  Publish/resolve mb-color@version
                                  |
                   clean public registry consumer
                                  v
                  Publish/resolve mb-image@version
                                  |
                   clean public registry consumer
                                  v
                 Immutable release manifest + assets
                                  |
                    GitHub immutable release seal
```

This extends the existing `policy/release-qualification.json`, `ReleaseQualification.Common.ps1`, `Invoke-ReleaseQualification.ps1`, static selector ledger, deterministic package reports, and consumer fixtures. Do not replace those seams with an unrelated release framework.

### Component Boundaries

| Component | Responsibility | Communicates With |
|---|---|---|
| RFC and namespace authority record | Records who controls `moonbit-foundation`, evidence date, verifier, permitted module names, and expiration/revalidation rule | Foundation policy, release intent validator |
| Existing Required pipeline | Re-runs all v0.1 selectors read-only and emits the canonical candidate report | Release preparation only; never publisher credentials |
| Release intent | Immutable tracked declaration of HEAD, module versions, dependency versions, package digests, baseline digests, authority evidence, and requested publication order | Required report, compatibility gate, publisher |
| Compatibility baseline store | Versioned normalized public interfaces per module/package/target plus toolchain identity | `moon info`, compatibility diff, release intent |
| Compatibility diff engine | Classifies removed/changed/additive/target-specific surface changes and enforces project status/SemVer policy | RFC policy, baseline store, release preparation |
| Candidate builder | Reuses deterministic two-clean-copy packaging and emits exact ZIP/list/manifest digests | Attestation step, publisher, immutable release |
| Publication authority gate | Human confirms one exact release-intent digest and HEAD; releases environment secret only after preparation succeeds | GitHub Environment or equivalent manual boundary |
| Publication orchestrator | Executes the fixed core -> resolve -> color -> resolve -> image -> resolve state machine and writes an append-only journal | mooncakes publisher adapter, registry verifier |
| mooncakes publisher adapter | The only component allowed to materialize registry authentication and execute `moon publish --frozen` | Publication orchestrator only |
| Registry consumer verifier | Creates clean no-`moon.work`, no-path-substitution consumers and resolves exact published versions on all required targets | Public mooncakes registry, publication journal |
| Provenance assembler | Binds HEAD, Required report, package digests, compatibility report, registry results, workflow identity, and timestamps | GitHub attestations, release manifest |
| Immutable release finalizer | Creates a draft, attaches the complete manifest/assets, then publishes an immutable GitHub release | GitHub Releases and release verification |
| Recovery/supersession controller | Reconciles interrupted state against registry evidence and creates corrective versions; never blindly republishes | Publication journal, registry verifier, RFC policy |

### Canonical Records

Use closed JSON schemas and exact property allowlists, matching the existing v0.1 pattern.

```text
policy/
  publication-authority.json       # namespace evidence and authorization rules
  compatibility.json               # status and version-change rules
release/
  intents/<release-id>.json        # immutable requested release
  compatibility/<module>/<ver>.json
  qualification/<release-id>/      # generated reports, not authority by themselves
  journals/<release-id>.json       # append-only/reconciled state
```

An intent should contain at least:

- schema version and release ID;
- exact Git commit and Required canonical digest;
- `mb-core`, `mb-color`, and `mb-image` exact versions;
- exact dependency constraints and topological order;
- ordered package lists, archive digests, and compatibility-baseline digests;
- namespace-authority evidence digest;
- compatibility classification and any required RFC ID;
- explicit statement that publication is requested but not yet performed.

The journal is evidence of observed state, not permission to publish. Permission comes only from the validated intent plus the manual authority boundary.

## Data Flow

### 1. Prepare without credentials

1. Check out one immutable commit.
2. Validate namespace-authority and release-intent schemas.
3. Run the existing Required lane without registry or GitHub write credentials.
4. Generate canonical `moon info` interfaces using the pinned toolchain.
5. Diff current interfaces against the last published baselines.
6. Enforce version and RFC rules before any network mutation.
7. Produce deterministic packages twice and bind their exact digests to the intent.
8. Generate artifact provenance for the candidate assets.

Preparation may be repeated freely because it is read-only with respect to the registry and release state.

### 2. Authorize one exact candidate

The human boundary approves the intent digest, not a branch name, mutable tag, or “latest successful run.” The publisher must independently recompute:

```text
approved intent digest == checked-out intent digest
intent HEAD             == GITHUB_SHA
Required HEAD           == intent HEAD
package digests         == intent package digests
compatibility digest    == intent compatibility digest
```

The project currently has one developer. Therefore do not configure “prevent self-review” as if two-person separation existed; that would make the environment unusable. Use `workflow_dispatch`, protected branch/tag restrictions, a fixed publication concurrency group, no admin bypass where available, and an explicit digest acknowledgement. When a second maintainer exists, upgrade the same environment to required independent review without changing the release protocol.

### 3. Publish and verify topologically

For each module in fixed order:

1. Query the public registry for the exact name/version.
2. If absent, materialize the credential only inside the publisher step and run `moon publish --frozen` from that module root.
3. Destroy the temporary credential material before consumer verification.
4. Refresh registry state using supported public commands.
5. Create a clean external consumer with exact registry dependency versions and no `moon.work`, local path, source copy, or Git URL fallback.
6. Run check/test on `js`, `wasm`, `wasm-gc`, and `native` as applicable.
7. Record the observed registry identity and consumer result before moving to the next module.

Do not publish `mb-color` until the exact `mb-core` registry consumer passes. Do not publish `mb-image` until the exact `mb-color` consumer, including its core dependency, passes.

### 4. Seal immutable provenance

After all registry consumers pass:

1. Finalize the release manifest with registry observations and compatibility baseline digests.
2. Create or update a draft GitHub release and attach all exact assets before publication.
3. Attach/verify artifact attestations for the package artifacts.
4. Publish the draft as an immutable release.
5. Verify the release and each local asset with GitHub CLI.
6. Promote the current interface records to the last-published compatibility baselines.

GitHub's immutable release attestation binds the Git tag, commit, and GitHub assets. It does not by itself prove mooncakes registry content, so the signed/attested release manifest must include the independently observed registry evidence.

## Patterns to Follow

### Pattern 1: Qualification and publication are separate trust domains

**What:** The large deterministic Required job remains `contents: read` and credential-free. A much smaller publisher job receives the mooncakes credential only after all candidate outputs are fixed.

**When:** Always. More tests in the credentialed job increase the attack surface and make retries ambiguous.

**Example boundary:**

```yaml
prepare:
  permissions:
    contents: read

publish:
  needs: prepare
  environment: mooncakes-production
  concurrency:
    group: mnf-mooncakes-publication
    cancel-in-progress: false
```

The workflow file must continue to pin third-party actions to full commit SHAs. GitHub identifies full-length commit pinning as the immutable form for an action reference.

### Pattern 2: Monotonic, reconciled publication state

**What:** Every transition records `not_observed`, `published`, `resolved`, `consumer_passed`, or `halted`. A retry first queries external state and reconciles it; it never repeats a publish command solely because the prior job lacked a success marker.

**When:** Any operation where the client may time out after the registry accepted the upload.

```text
prepared
  -> core_published -> core_consumer_passed
  -> color_published -> color_consumer_passed
  -> image_published -> image_consumer_passed
  -> sealed
```

No transition goes backward. Recovery either completes the current release or creates a superseding version.

### Pattern 3: Interface baselines are generated artifacts with policy-owned meaning

**What:** Use `moon info --frozen` and the existing exact semantic-interface normalization. Store package identity, target, toolchain, ordered semantic lines, and digest. Compare baselines mechanically, but let tracked policy decide the version consequence.

**When:** Every release preparation and every PR that changes a public package.

Recommended classification:

| Diff | Candidate package rule | Stable package rule |
|---|---|---|
| No semantic interface change | patch allowed if behavior remains compatible | patch allowed |
| Add public item without changing existing items | minor version | minor version |
| Remove/change signature, visibility, package path, target support, or dependency direction | explicit breaking RFC and version rule | major version |
| Backend-only interface divergence | reject unless explicitly declared and baseline-owned | reject or breaking RFC |

Textual interface comparison cannot detect all behavioral incompatibilities. Compatibility reports must therefore link the existing black-box, conformance, fixture, and registry-consumer evidence; do not market interface equality as complete semantic compatibility.

### Pattern 4: Publish once, correct forward

**What:** Treat a registry version as immutable even though current public MoonBit documentation does not clearly specify yank/delete/overwrite guarantees.

**When:** Every published version.

If a release is bad:

- stop the state machine;
- publish no higher dependent module until the lower dependency is safe;
- create a corrective patch or breaking successor according to compatibility policy;
- mark the bad version superseded in release metadata and documentation;
- preserve the original evidence and incident journal;
- never move a tag, overwrite an asset, or assume an unpublish operation exists.

### Pattern 5: Manual authority chooses intent, automation computes facts

**What:** A human may authorize or abort one exact candidate. Automation computes versions, digests, dependency order, compatibility classification, package contents, and consumer results.

**When:** Namespace ownership verification and production publication.

This prevents a manual step from editing generated values after qualification while retaining an intentional irreversible-action boundary.

## Strict Credential Boundaries

| Stage | Registry credential | GitHub write permission | Network mutation |
|---|---:|---:|---|
| PR/Required | Never | None | None |
| Release preparation | Never | `attestations: write` only if producing candidate attestations; otherwise none | Attestation only |
| Manual authorization | Secret remains withheld until protection rules pass | None | None |
| Module publisher | Available only to the single publish step | None | Exact `moon publish --frozen` |
| Registry consumer | Removed | None | Public registry reads only |
| Immutable release finalizer | No registry credential | `contents: write`, `attestations: write`, `id-token: write` as required | Draft assets, attestation, release publication |
| Recovery audit | Withheld by default | Read only | Registry/release reads only |

MoonBit's current official documentation describes `moon login` saving a token to `~/.moon/credentials.json`, but does not document a stable non-interactive environment-variable contract for `moon publish`. Therefore v0.2 needs a focused authentication spike before workflow implementation. Keep that detail behind the publisher adapter; do not make the rest of the architecture depend on an undocumented `MOONCAKES_TOKEN` convention. Never copy a developer's pre-existing credentials file into CI or let qualification enumerate it.

## Build and Implementation Order

1. **Authority and release-intent contracts**
   - Verify the real mooncakes owner namespace.
   - Record sole-owner authority honestly.
   - Define closed schemas and fail-closed negatives.

2. **Compatibility baseline and diff gate**
   - Capture v0.1 public interfaces before publication.
   - Implement target-aware normalization and version/RFC classification.
   - Integrate as a read-only Required selector.

3. **Credential-free release preparation**
   - Reuse deterministic packages and two-run evidence.
   - Bind intent, HEAD, package, interface, fixture, and benchmark digests.
   - Generate candidate provenance.

4. **Publisher adapter and state journal**
   - First spike the exact supported non-interactive mooncakes authentication seam.
   - Add fixed topological transitions, concurrency serialization, and reconciliation.
   - Keep credentials out of logs, reports, artifacts, and downstream jobs.

5. **Real registry consumers**
   - Publish/resolve core, then color, then image.
   - Replace v0.1's allowed blocked outcomes with exact successful public-registry evidence.
   - Test clean consumers on all declared targets.

6. **Immutable release finalization and recovery drills**
   - Draft assets first, publish immutable release last.
   - Verify attestations and assets.
   - Exercise timeout-after-publish, partial-chain halt, and corrective supersession scenarios without mutating real versions.

This ordering prevents credential automation from being built before the authority, compatibility, and recovery contracts it must enforce.

## CI and Manual Boundaries

| Decision/action | Automated | Manual |
|---|---:|---:|
| Toolchain, policy, interfaces, packages, tests, docs, benchmarks | Yes | No |
| Determine package digests and topological order | Yes | No |
| Classify API diff against tracked rules | Yes | Review only for ambiguous behavior |
| Approve a breaking RFC | No | Yes |
| Verify namespace ownership evidence initially or after authority change | Evidence validation automated | Authority assertion manual |
| Authorize irreversible publication of one intent digest | No | Yes |
| Publish modules in fixed order | Yes after authorization | No per-module clicking |
| Reconcile registry state after timeout | Yes, read-first | Manual resume if state is ambiguous |
| Decide corrective/superseding version | Policy proposes | Manual approval |
| Seal immutable GitHub release | Yes after all registry consumers pass | No asset mutation afterward |

## Anti-Patterns to Avoid

### Credentialing Required

**What:** Give the existing comprehensive quality workflow the mooncakes token.

**Why bad:** Untrusted test/build surfaces gain irreversible publication authority; reruns become unsafe.

**Instead:** Pass immutable outputs to a minimal publisher job after manual authorization.

### Publishing all modules and testing later

**What:** Upload core, color, and image in one unchecked loop.

**Why bad:** A broken lower dependency creates multiple bad public versions.

**Instead:** Publish, resolve, and externally consume each layer before the next.

### Workspace substitution as compatibility proof

**What:** Accept `moon.work` tests as evidence that released dependencies resolve.

**Why bad:** Workspace members can mask stale or impossible registry constraints.

**Instead:** Clean consumers with exact registry versions and no fallback sources.

### Mutable compatibility baseline

**What:** Regenerate “expected” interfaces in the same job that judges the diff.

**Why bad:** A breaking change can rewrite its own oracle.

**Instead:** Baselines are promoted only after successful publication and immutable release sealing.

### Blind retry after publish timeout

**What:** Re-run `moon publish` because the client did not receive success.

**Why bad:** External state may already have committed.

**Instead:** Query, compare exact identity, reconcile, then continue or halt.

### Pretend two-person governance

**What:** Enable self-review prevention while only one maintainer exists, or claim independent approval.

**Why bad:** It either deadlocks release or fabricates authority.

**Instead:** Record sole-owner authorization; upgrade controls when maintainership changes.

### Assume rollback means deletion

**What:** Depend on an undocumented registry unpublish/overwrite operation.

**Why bad:** Consumers may already cache or depend on the version, and the operation may not exist.

**Instead:** Immutable evidence plus corrective forward versions and supersession metadata.

## Scale and Evolution Considerations

| Concern | v0.2 / one maintainer | More maintainers | More module releases |
|---|---|---|---|
| Authorization | Sole-owner explicit intent approval | Required independent environment review | Per-module owner policy can be added without changing intent schema |
| Release serialization | One global publication concurrency group | Same | Partition only if dependency-independent releases are proven safe |
| Baselines | Three module/version records | Review ownership by domain | Content-addressed baseline index avoids one monolithic file |
| Evidence storage | One manifest per release | Same | Retention/indexing policy; immutable release remains anchor |
| Recovery | Manual resume after automated reconciliation | Incident reviewer added | State-machine tooling remains module-order aware |

## Open Gaps Requiring Phase Research

1. **Non-interactive mooncakes authentication — HIGH priority.** Official docs confirm `moon login` and `~/.moon/credentials.json`, but not a stable environment-secret mechanism. Verify against the exact pinned `moon` version and registry operator guidance before writing the credential adapter.
2. **Registry immutability/yank/delete semantics — HIGH priority.** Current public docs found for `moon publish` and SemVer do not document recovery operations. v0.2 should preserve the conservative publish-once/supersede-forward contract unless authoritative registry documentation says more.
3. **Published artifact identity — MEDIUM priority.** Determine what public registry metadata/digest can be queried after publish and bind it to the local deterministic package digest; do not assume the registry serves the identical ZIP representation.
4. **GitHub immutable releases availability/configuration — MEDIUM priority.** Confirm repository visibility/plan and enablement before making immutable-release verification a blocking gate.
5. **Behavioral compatibility classification — MEDIUM priority.** Interface diffs are reliable structural evidence but cannot classify every semantic change; RFC/manual review remains necessary for behavior changes with identical signatures.

## Sources

- [MoonBit: Use and publish packages](https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html) — official current docs; login credential location, module publication, SemVer/minimal version selection. Confidence: MEDIUM.
- [Moon build-system command manual](https://moonbitlang.github.io/moon/commands.html) — official command reference; `moon publish --frozen`, `moon package --list`, registry update/add, and current command boundaries. Confidence: MEDIUM.
- [MoonBit module configuration](https://docs.moonbitlang.com/en/stable/toolchain/moon/module.html) — official supported-target and module metadata behavior. Confidence: MEDIUM.
- [GitHub Actions deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments) — official environment approvals, branch/tag restrictions, secret-release timing, and bypass controls. Confidence: MEDIUM.
- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — official permissions and concurrency behavior. Confidence: MEDIUM.
- [GitHub secure-use reference](https://docs.github.com/en/actions/reference/security/secure-use) — official least-privilege and full-SHA action pinning guidance. Confidence: MEDIUM.
- [GitHub artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations) — official attestation permissions, subject digests, and verification. Confidence: MEDIUM.
- [GitHub immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases) — official tag/asset immutability and draft-first publication guidance. Confidence: MEDIUM.
- [GitHub release integrity verification](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/verify-release-integrity) — official `gh release verify` and `verify-asset` behavior. Confidence: MEDIUM.
- [Semantic Versioning 2.0.0](https://semver.org/) — primary versioning specification; released-version immutability and version-change vocabulary. Confidence: MEDIUM.

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Current repository seams | HIGH | Directly inspected policy, Required, packaging, reports, and consumer scripts |
| Moon publish/module behavior | MEDIUM | Current official docs and exact local CLI help agree; non-interactive auth and rollback remain undocumented |
| GitHub environment/attestation/immutable release behavior | MEDIUM | Current official GitHub docs cross-checked across multiple pages |
| Recommended state-machine architecture | HIGH | Derived from existing deterministic/fail-closed project patterns and irreversible-operation design |
| Registry recovery details | LOW | No authoritative mooncakes yank/delete/overwrite contract found; architecture intentionally does not depend on one |
