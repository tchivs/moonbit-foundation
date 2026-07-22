# Phase 8: Ordered Mooncakes Publication and Registry Consumers - Context

**Gathered:** 2026-07-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 8 makes the Phase 7 control plane genuinely executable, performs the first authorized production publication, and then publishes `tchivs/mb-core` → `tchivs/mb-color` → `tchivs/mb-image` at `0.1.0` only after each predecessor passes a fresh registry-only consumer proof. It also proves the qualified public metadata through credential-free Mooncakes observation. It does not add a module family, weaken Required, introduce team approval ceremony, assume destructive registry recovery, or close the immutable provenance ledger and milestone audit owned by Phase 9.

</domain>

<decisions>
## Implementation Decisions

### Executable Live Seam and First Mutation

- **D-01:** Before any release tag or live dispatch, replace the Phase 7 `{}` prepared-manifest placeholder with a deterministic bundle that satisfies `release/prepared/schema.json`, contains every exact payload, validates every digest and binding, and is covered by positive and adversarial credential-free tests.
- **D-02:** Replace the null live adapter path with one tracked adapter that may publish only the next dependency-safe module from the verified journal. It uses `moon publish --frozen` from the exact prepared module source and cannot loop over all modules.
- **D-03:** The environment secret is materialized only inside the publisher step as the minimum ephemeral Moon credential state required by the pinned CLI, under a new isolated `MOON_HOME`; it is never passed as a command argument, printed, uploaded, or made available to prepare/consumer jobs. `MOON_TOOLCHAIN_ROOT` remains bound to the pinned installed toolchain.
- **D-04:** The first irreversible `tchivs/mb-core@0.1.0` publication remains an explicit operator checkpoint after the executable seam, clean trusted source, release intent, release tag, dry run, hosted settings, and current absent-version observation all pass. Autonomous planning and coding must stop at that checkpoint rather than consume the version implicitly.

### Ordered One-Module Publication

- **D-05:** One authorized workflow run may attempt at most one module mutation. The fixed sequence is `mb-core mutation → observe → cold proof`, then `mb-color mutation → observe → cold proof`, then `mb-image mutation → observe → full-graph cold proof`.
- **D-06:** A downstream module is ineligible until the preceding module has an exact matching registry observation, a complete sanitized checkpoint, and its required four-target consumer proof. A successful CLI exit alone is insufficient.
- **D-07:** Each new run resumes the immutable root intent and verified journal chain. Duplicate dispatches re-observe existing state; they never republish an exact verified checkpoint.

### Exact Cold Registry Consumers

- **D-08:** Every DIST proof runs in a newly created directory outside the checkout with a new empty `MOON_HOME`, an explicit pinned `MOON_TOOLCHAIN_ROOT`, no `credentials.json`, no `moon.work`, no path or Git dependency, no copied module source, and no pre-existing registry index, cache, `.mooncakes`, or target directory.
- **D-09:** Consumer manifests declare the intended `0.1.0` dependency floors, but proof must separately assert the actual resolved graph. Moon's minimal version selection means the manifest floor alone is not exact-version evidence.
- **D-10:** Record a normalized `moon tree`, registry-index version/dependency/checksum data, downloaded archive SHA-256, and the downloaded module manifest. The observed graph must be node-for-node equal to the expected `0.1.0` graph before target tests count.
- **D-11:** Reuse the existing deterministic public behavior where possible: checked/core behavior for `mb-core`, public color behavior for `mb-color`, and bounded PPM encode/decode across the complete public graph for `mb-image`. Each consumer checks and tests `js`, `wasm`, `wasm-gc`, and real `native` with the pinned toolchain.
- **D-12:** Consumer jobs never receive the publisher secret. They prove a normal unauthenticated ecosystem consumer can resolve and execute the published modules.

### Propagation, Ambiguity, and Recovery

- **D-13:** After a mutation attempt, use bounded credential-free polling across registry observation surfaces. Polling intervals, attempt count, start/end timestamps, HTTP/CLI classifications, and terminal disposition are recorded deterministically.
- **D-14:** Timeout, nonzero publish exit, missing version, inconsistent checksums, or conflicting observation surfaces produce an `unknown` or incident checkpoint and stop. They do not trigger automatic republish or downstream publication.
- **D-15:** Retry is permitted only through the Phase 7 forward-only authorization rules after read-only observation proves the exact version absent. An observed exact match is checkpointed without mutation; an observed mismatch requires a newly qualified forward correction.

### Public Metadata and Evidence

- **D-16:** PROV-05 uses Mooncakes' structured public API, registry index, downloadable archive, and versioned assets rather than scraping the SPA HTML. Required fields are projected into a closed sanitized observation before comparison.
- **D-17:** Compare exact qualified source metadata for identity, version, description, license, repository, README, package inventory, dependency graph, supported targets when exposed, and strongest available checksum/identity. Missing, drifted, or ambiguous required metadata blocks the next mutation.
- **D-18:** Live raw output is never committed. Sanitized observations, normalized graphs, target results, timestamps, and content digests are uploaded as intent-bound checkpoint artifacts; Phase 9 owns their immutable ledger/provenance closure.
- **D-19:** The current pre-publication observation (`tchivs` exists with no modules and `tchivs/mb-core` is absent) is a freshness-sensitive planning fact, not permanent evidence. It must be re-observed immediately before the first mutation.

### the agent's Discretion

- Exact polling cadence and maximum observation window, provided it is bounded, testable, and cannot authorize a retry by itself.
- Exact consumer package layout and normalized evidence filenames, provided each proof remains outside the checkout, closed-schema, content-addressed, and independently reproducible.
- Whether public API, registry index, archive, and assets observations are implemented as one script or narrow helpers, provided disagreement fails closed and all network output is sanitized before persistence.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Phase Contract

- `.planning/ROADMAP.md` — Phase 8 goal, DIST-01 through DIST-04 and PROV-05 mapping, and exact success criteria.
- `.planning/REQUIREMENTS.md` — distribution, metadata, credential isolation, out-of-scope recovery, and milestone acceptance contract.
- `.planning/PROJECT.md` — v0.2 publication goal, canonical `tchivs/*` identities, and publication-before-expansion decision.
- `.planning/STATE.md` — current Phase 8 position and accumulated sole-maintainer, fail-closed, and forward-only decisions.
- `.planning/phases/07-release-safety-intent-and-recovery-automation/07-CONTEXT.md` — immutable intent, one-step mutation, journal, re-observation, and explicit first-mutation checkpoint.
- `.planning/phases/07-release-safety-intent-and-recovery-automation/07-03-SUMMARY.md` — hosted environment readiness and the exact non-live Phase 8 handoff.

### Release Control and Qualification

- `.github/workflows/publish-modules.yml` — current hosted skeleton and the placeholder bundle/null-adapter gaps Phase 8 must close.
- `scripts/quality/Invoke-ReleasePublisher.ps1` — current request validation, rehearsal, correction, and guarded live seam.
- `scripts/quality/ReleasePublisher.Common.ps1` — monotonic journal and sanitized publisher helper contract.
- `release/prepared/schema.json` — required prepared-bundle fields, payload roles, and digest contract.
- `release/intent/schema.json` — authorized release intent contract.
- `release/journal/record-schema.json` — append-only checkpoint record contract.
- `policy/release-qualification.json` — canonical module order, versions, dependency graph, public package inventory, targets, and metadata.
- `policy/registry-authority.json` — current-fact freshness, observation, redaction, and fail-closed policy.
- `release/registry/authority-observation.json` — sanitized pre-publication authority evidence that must be refreshed before mutation.
- `release/qualification/phase-07-requirements.json` — Phase 7 reciprocal evidence that Phase 8 must preserve.

### Existing Consumer and Module Surfaces

- `qualification/consumers/mb-core/main/main.mbt` — deterministic public core behavior suitable for the first registry consumer.
- `qualification/consumers/downstream-public/main.mbt` — existing downstream public-import consumer pattern to replace with real behavior per layer.
- `modules/mb-core/moon.mod.json` — exact core identity and qualified public metadata.
- `modules/mb-color/moon.mod.json` — color identity and `mb-core` dependency floor.
- `modules/mb-image/moon.mod.json` — image identity and full dependency floors.
- `modules/mb-core/README.mbt.md` — qualified core public documentation rendered by registry metadata.
- `modules/mb-color/README.mbt.md` — qualified color public documentation.
- `modules/mb-image/README.mbt.md` — qualified image public documentation and bounded PPM surface.

### Official MoonBit and Mooncakes Semantics

- `https://docs.moonbitlang.com/en/stable/toolchain/moon/package-manage-tour.html` — official publish flow, minimal version selection, dependencies, and rendered metadata.
- `https://docs.moonbitlang.com/en/latest/toolchain/moon/workspace.html` — official member-scoped workspace publication command.
- `https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html` — dependency and module metadata contract.
- `https://github.com/moonbitlang/moon/blob/main/crates/mooncake/src/resolver/mvs.rs` — authoritative minimal-version resolver behavior.
- `https://github.com/moonbitlang/moon/blob/main/crates/moonutil/src/moon_dir.rs` — authoritative `MOON_HOME` and `MOON_TOOLCHAIN_ROOT` separation.
- `https://github.com/moonbitlang/moon/blob/main/crates/mooncake/src/registry/online.rs` — registry index/download behavior used to design cold proofs.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Invoke-ReleasePublisher.ps1`: exact request and correction validation, explicit live guard, and one-step adapter seam.
- `ReleasePublisher.Common.ps1`: canonical hashing, sanitized journal records, lock identity, and reducer primitives.
- `release/prepared/schema.json`: already defines the content-addressed cross-job bundle inventory.
- `policy/release-qualification.json`: single source of truth for publication order, versions, dependencies, targets, packages, and metadata.
- Existing qualification consumers: deterministic core and full public-import patterns can seed real cold consumers.

### Established Patterns

- Required remains credential-free and non-publishing; live observation and mutation are isolated selectors/jobs.
- Machine-readable policy owns truth; schemas are closed; evidence is content-addressed; ambiguity fails closed.
- Publication and recovery are monotonic and forward-only, with the sole maintainer authorizing one exact intent.

### Integration Points

- Replace the placeholder prepare block in `.github/workflows/publish-modules.yml` with a tested prepared-bundle generator.
- Complete `LiveOneStep` through the existing adapter seam rather than bypassing `Invoke-ReleasePublisher.ps1`.
- Add a Phase 8 qualification/consumer policy and selectors alongside existing Phase 6/7 evidence without making Required network-dependent.
- Add separate credential-free hosted consumer/observer jobs after each mutation and bind their artifacts into the existing checkpoint chain.

</code_context>

<specifics>
## Specific Ideas

- Treat the first accepted `mb-core@0.1.0` response plus consistent public observation as the point where remote publish authority becomes proven.
- Verify exact resolved versions independently from manifest floors because Moon uses minimal version selection.
- Use Mooncakes public manifest/assets/download surfaces for structured proof and reserve browser-rendered pages for human review, not machine authority.
- Keep the live mutation surface small enough that one authorization can never publish more than one module.

</specifics>

<deferred>
## Deferred Ideas

- Immutable ledger entries, GitHub release/provenance closure, and final milestone audit — Phase 9.
- Organization namespace migration, destructive recovery, multi-maintainer approvals, and new module families — outside v0.2.

</deferred>

---

## Forward Recovery Addendum — r10

**Recorded:** 2026-07-19
**Status:** Locked planning fact for the forward recovery plans 08-24 through 08-27.

- The already-pushed `modules-v0.1.0-r9` tag is immutable terminal evidence. Its peeled commit is `4158dff`; it must not be retagged, moved, reused as a current attempt, or re-executed.
- r9 stopped after `InitializeBoundary` and before active-locator creation because the protected r8 terminal record predates later history fields under PowerShell StrictMode. Commit `3a761ae` narrowly recognizes only the verified legacy-r8 inventory/digest/stage; it is locally committed and is not a publication, credential, dispatch, or registry event.
- r10 is the sole forward retry. Its history family is attempt-zero plus r1 through r9. r9 must be carried as exact partial terminal evidence with no locator, hosted run, credential access, packet, receipt, handoff, PublishOne, registry mutation, or successor.
- No plan may infer Mooncakes authorization from a tag, local authentication state, a dry run, or a previous observation. A future blocking `authorize-core` decision is required only after completed static and non-publishing r10 qualification has fresh sanitized evidence.
- The recovery sequence is monotonic: static r10 contracts → r10 hosted/zero-write seam → unique r10 non-publishing boundary and authorization checkpoint → separately ordered core, color, and image publication/proof. A stop or any ambiguity ends without retrying r9 or mutating the registry.

## Forward Recovery Addendum — r11

**Recorded:** 2026-07-19
**Status:** Locked planning fact for the r11 recovery plans 08-26 through 08-30.

- `modules-v0.1.0-r10` is immutable terminal evidence: tag object `0546025` peels to `d49edc5`. After clean-clone and fetch/tag verification, its PrepareAttempt stopped at `REL01-REF` because the initial release ref was not bound as the dedicated immutable tag. It produced no prepared bundle, packet, receipt, handoff, hosted run, dry run, observation, PublishOne call, registry operation, credential access, or publication.
- r11 is the sole permitted forward retry. Its immutable family is attempt-zero plus r1 through r10. r10 must be represented only by attested checkpoint facts; do not infer unrecorded locator or active-attempt facts.
- Before an r11 tag may be created, the real clean-clone `InitializeBoundary → PrepareAttempt` fixture must prove the clone-local policy, fetched dedicated tag, tag peel, and source SHA bind together. A direct intent-builder test is not sufficient.
- The existing exact six-path user-dirty baseline remains allowed only when status and content hashes are unchanged; all other worktree drift fails closed, and release artifacts originate only from exact committed HEAD or its clean clone.
- No plan infers Mooncakes authority. A future `authorize-core` decision is emitted only for a completed r11 confirmed-absent, non-publishing qualification; exact-existing needs no receipt or handoff.

## Forward Recovery Addendum — r12

**Recorded:** 2026-07-19
**Status:** Locked planning fact for r12 plans 08-29 through 08-33.

- `modules-v0.1.0-r11` is immutable: tag object `735ad679` peels to source `30479a`. A real disposable remote clone proves the clone policy’s canonical `refs/tags/modules-v0.1.0-r11` reaches the PrepareAttempt provider; the original failure was a caller-supplied noncanonical ref, not tag resolution.
- Commit `508eccc` adds the real remote-clone regression. r12 must include it and use a non-overridable boundary wrapper that derives the release ref from clone-local policy; no manual ref is allowed in its boundary path.
- r12 is the only current retry. Its immutable history is attempt-zero plus r1 through r11. r11 must never be retagged, reused as current state, or reduced to a generic ref-failure record.
- The exact eight-path user-dirty baseline persists unchanged: the original six paths plus `.github/workflows/quality.yml` and `.planning/quick/260719-fix-github-actions-ci/PLAN.md`. All release artifacts derive only from exact committed HEAD or a fresh no-local/no-tags clone, and no baseline path may enter artifacts. Mooncakes authority continues to require completed non-publishing evidence and a same-turn absent-only `authorize-core` decision.

*Phase: 8-ordered-mooncakes-publication-and-registry-consumers*
*Context gathered: 2026-07-18*
