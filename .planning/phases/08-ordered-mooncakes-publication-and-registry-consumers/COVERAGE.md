# Phase 8 Coverage and External API Capability Matrix

## Scope Contract

Phase 8 integrates only the Mooncakes capabilities required to publish one dependency-safe module per authorized run, observe it through credential-free structured surfaces, and prove exact cold registry consumption. The canonical semantic order is `tchivs/mb-core@0.1.0` -> `tchivs/mb-color@0.1.0` -> `tchivs/mb-image@0.1.0`. Normalized graph serialization is deterministic but never changes node/edge equality.

The protected attempt-zero tag/run, annotated r1 at `09548df948f58ec1bdfff7494757596c03e4c9bd`, and annotated r2 at `73a3af920fc3938f49e93d14f16f79f116475f1e` are three distinct immutable terminal-negative histories, not reusable release inputs. r2 had no hosted workflow run, mutation, or authority: PrepareAttempt and confirmed_absent completed, then the old helper field-array construction failed before HostedPreflight dispatch. The new pre-publication retry uses `modules-v0.1.0-r3` with a fresh initial intent/root/genesis/prepared/store while retaining module version `0.1.0`, `intent_kind: initial`, `correction_sequence: 0`, and no predecessor. Every eligibility artifact binds all three individual history digests plus their canonical ordered-set digest. `modules-correction-N` remains reserved for published-content mismatch that advances versions. Only absent may run HostedPreflight/PublisherDryRun and requires packet plus literal receipt; exact-existing is packet-, receipt-, actor-, preflight-, and dry-run-free.

The assumption-delta detector phrase `Git fallback` maps to the noun **registry-only dependency source**, decision **no-change**, because an alternate source is prohibited rather than generalized into an identity model.

## Multi-Source Coverage Audit

| Source | ID | Feature / requirement | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | - | Three genuine publications and cold consumption in strict dependency order | 08-01..08-12 | COVERED | r3 contracts, hosted seam, non-mutating AuthorityUnion, and ordered closure are sequential; attempt-zero/r1/r2 remain terminal history. |
| REQ | DIST-01 | Core exact publication and four-target cold proof before color | 08-03, 08-04, 08-05, 08-06, 08-07, 08-08, 08-09, 08-10, 08-11, 08-12 | COVERED | r3 AuthorityUnion: absent requires packet+literal receipt; exact is packet/receipt-free; both bind three histories and require core cold proof. |
| REQ | DIST-02 | Color exact publication and core-color proof before image | 08-03, 08-04, 08-06, 08-12 | COVERED | Verified r3 core authority is the hard predecessor. |
| REQ | DIST-03 | Image exact publication and full-graph PPM proof | 08-03, 08-04, 08-06, 08-12 | COVERED | Image uses the closed switch and exact three-node proof. |
| REQ | DIST-04 | Outside-checkout, cold, no-credential registry-only evidence | 08-01, 08-02, 08-03, 08-06, 08-12 | COVERED | Proof rejects alternate state/source paths for both authority kinds. |
| REQ | PROV-05 | Read-only exact public metadata observation | 08-02, 08-04, 08-06, 08-12 | COVERED | Structured surfaces only; no SPA authority. |
| CONTEXT | D-01..D-04 | Deterministic bundle, one-step adapter, secret isolation, explicit first mutation | 08-01, 08-04, 08-05, 08-06, 08-07, 08-08, 08-09, 08-10, 08-11 | COVERED | r3 code is committed/pushed before tag; absent needs packet+receipt, exact neither; preflight is mutation-only. |
| CONTEXT | D-05..D-07 | One mutation per run, strict predecessor proof, idempotent resume | 08-04, 08-06, 08-08, 08-10, 08-12 | COVERED | Closed absent/exact switch permits no exact republish. |
| CONTEXT | D-08..D-12 | Exact cold registry consumers and four targets | 08-03, 08-06, 08-12 | COVERED | Empty homes and exact graphs are mandatory. |
| CONTEXT | D-13..D-15 | Bounded polling, ambiguity stop, forward-only retry | 08-02, 08-04, 08-05, 08-06, 08-07, 08-08, 08-09, 08-10, 08-11, 08-12 | COVERED | Ambiguity stops; exact never republishes; r3 remains initial. |
| CONTEXT | D-16..D-19 | Structured metadata, sanitized artifacts, fresh pre-core observation | 08-02, 08-05, 08-06, 08-08, 08-10, 08-11, 08-12 | COVERED | Fresh sanitized observations feed the exclusive r3 handoff. |
| RESEARCH | Prepared bundle is complete before secret access | 08-01, 08-04 | COVERED | Publisher repeats validation. |
| RESEARCH | Cold consumer is a separate trust domain | 08-03 | COVERED | No checkout/workspace/cache/credential inheritance. |
| RESEARCH | Structured observation precedes presentation | 08-02, 08-06, 08-11, 08-12 | COVERED | Closed projection and exact comparison. |
| RESEARCH | Public surface shape is freshness-sensitive | 08-02, 08-06, 08-11, 08-12 | COVERED | Unknown shape blocks. |
| DEBUG | hosted-toolchain/setup/field failures | Preserve all failed attempts and corrected setup before credentials | 08-05, 08-06, 08-07, 08-08, 08-09, 08-10, 08-11 | COVERED | Three terminal histories bind exact stages; r2 stopped before HostedPreflight dispatch; r3 retains the fixed 14-field builder. |
| DEBUG | publisher actor identity | Prove exact `tchivs` without raw authentication output | 08-05, 08-06, 08-08, 08-10, 08-11, 08-12 | COVERED | Exact parse, sanitized packet/receipt, reciprocal digest. |
| DEBUG | fresh authorization continuation | Revalidate untrusted checkpoint state before receipt | 08-08, 08-10, 08-11, 08-12 | COVERED | Fresh continuation reloads disk/remote state and re-proves LF boundary, three histories, actor, dry run, and absence. |
| TEST | fixed handoff/tag isolation | Production path/tags are non-overridable and tests never inherit them | 08-08, 08-10 | COVERED | LibraryOnly GUID roots plus no-tags clones, owned cleanup, and fixed-path absence assertions. |
| TEST | hosted 14-field vector | Exact grouped start/resume field count, order, and values | 08-10, 08-12 | COVERED | Prevents ungrouped-if execution and one-element concatenation collapse. |

## Requirement Adjacency and Edge Rules

| Requirement | Required predecessor | Exact acceptance | Empty / missing | Ordering |
|---|---|---|---|---|
| DIST-01 | Exclusive core AuthorityUnion | Absent: packet plus literal authorize-core receipt; exact-existing: packet/receipt-free authority. Both require exact core 0.1.0 identity, one-node graph, metadata/artifact agreement, four targets, and checked behavior | Fail | Core is first; HostedPreflight is mutation-branch only. |
| DIST-02 | Verified DIST-01 checkpoint | Exact color 0.1.0 plus core 0.1.0 edge, metadata/artifact agreement, four targets, color behavior | Fail | Color follows core only. |
| DIST-03 | Verified DIST-02 checkpoint | Exact image/color/core 0.1.0 graph, metadata/artifact agreement, four targets, bounded PPM behavior | Fail | Image follows color only. |
| DIST-04 | Selected module observation | Exact registry-only source, new empty home, pinned toolchain, exact graph/artifact/behavior record | Fail | Evidence serialization is canonical without weakening graph equality. |
| PROV-05 | All three exact module observations | Exact qualified metadata across structured public API/index/archive/manifest/assets/docs | Fail | Canonical module order core, color, image. |

## Mooncakes External API Capability Matrix

| API surface | Capability | Decision |
|---|---|---|
| Mooncakes CLI | `moon publish --frozen` for one journal-selected module | INTEGRATE - one authorized run can attempt exactly one eligible module. |
| Mooncakes CLI | `moon whoami` and publish preflight/dry-run classification | INTEGRATE - local identity/readiness is revalidated but is not remote authority by itself. |
| Mooncakes public structured API | Public user and module/version observation | INTEGRATE - credential-free exact identity/version/metadata observation. |
| Mooncakes registry index | Version, dependency, and checksum observation | INTEGRATE - exact resolved graph and package identity evidence. |
| Mooncakes downloadable archive | Archive download and SHA-256 comparison | INTEGRATE - strongest available content identity is required. |
| Mooncakes downloaded manifest | Module identity, version, dependencies, packages, metadata | INTEGRATE - compared exactly with qualified source and normalized graph. |
| Mooncakes versioned assets/docs | README and other version-bound public metadata assets | INTEGRATE - PROV-05 compares sanitized content/digests. |
| Mooncakes rendered SPA | HTML scraping as machine authority | OPT-OUT - presentation HTML is not a stable structured authority surface. |
| Mooncakes mutation | Multi-module publication in one run | OPT-OUT - each run may mutate at most one dependency-safe module. |
| Mooncakes recovery | Automatic retry after timeout, ambiguity, nonzero exit, or disagreement | OPT-OUT - read-only observation and explicit forward-only authorization are required. |
| Mooncakes recovery | Overwrite, delete, unpublish, or yank | OPT-OUT - no verified contract and forward-only recovery forbids destructive mutation. |
| Mooncakes ownership | Transfer or rename | OPT-OUT - outside the canonical personal-namespace release and not a recovery mechanism. |
| Mooncakes ownership | Organization migration | OPT-OUT - outside v0.2 and the locked `tchivs/*` module identities. |

## Explicit Prohibitions

1. No secret or credential state in prepare, observer, consumer, evidence, command arguments, logs, or uploaded artifacts.
2. No local/workspace/path/Git/copied-source/warm-cache proof and no `moon.work` in a cold consumer.
3. No more than one module mutation in a workflow run.
4. No automatic retry or successor dispatch after absent, timeout, nonzero, unknown, mismatch, checksum disagreement, or incomplete proof.
5. No rendered-SPA scraping as machine authority.
6. No Phase 9 immutable ledger, artifact provenance closure, GitHub release closure, or milestone audit in Phase 8.
7. No release tag creation, live dispatch, secret read, or publish call during autonomous preparation/seam implementation tasks.
8. No destructive overwrite/delete/unpublish/yank/transfer/rename operation and no organization migration.
9. No retarget/delete/recreate of `modules-v0.1.0`, no rerun of 29652468948, and no reuse of its intent digest, root, or journal as current authorization.

## Artifacts This Phase Produces

- Deterministic schema-valid prepared bundle and adversarial validation evidence.
- Closed structured Mooncakes observations for core, color, and image.
- Cold registry-only one-node, two-node, and three-node consumer proofs across js, wasm, wasm-gc, and real native.
- Three monotonic one-module workflow checkpoints bound to immutable intent and journal digests.
- Credential-free reciprocal DIST-01..DIST-04 and PROV-05 qualification evidence.
