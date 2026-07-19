# Phase 8 Coverage and External API Capability Matrix

## Scope Contract

Phase 8 integrates only the Mooncakes capabilities required to publish one dependency-safe module per authorized run, observe it through credential-free structured surfaces, and prove exact cold registry consumption. The canonical semantic order is `tchivs/mb-core@0.1.0` -> `tchivs/mb-color@0.1.0` -> `tchivs/mb-image@0.1.0`. Normalized graph serialization is deterministic but never changes node/edge equality.

Attempt-zero and r1 through r5 are six distinct immutable terminal-negative histories. r4's only hosted run `29667231047/1` failed during credential-free HostedPreflight qualification because a valid clean empty tracked snapshot could not bind to `Before`; PublisherDryRun, packet, receipt, handoff, and mutation remained zero. r5 is fixed at source `df105f06205298f1f82ac2f2cdca214d69d42e15` and annotated tag object `4a11582cf9aeae15802cf4f6d7394b013ece63ac`: PrepareAttempt completed, a fresh credential-free observation proved core absent, and HostedPreflight dispatch was rejected before run creation because the immutable workflow contained a duplicate environment key. r5 therefore has no hosted run and zero PublisherDryRun, packet, receipt, handoff, PublishOne, mutation, or successor effects. The next retry is `modules-v0.1.0-r6` with a fresh initial root/genesis/prepared/index/store, module `0.1.0`, sequence 0, root=current, and no predecessor. Every eligibility artifact binds six individual digests plus their canonical ordered set. Only absent may preflight/dry and requires packet plus same-turn literal receipt; exact-existing requires neither.

The assumption-delta detector phrase `Git fallback` maps to the noun **registry-only dependency source**, decision **no-change**, because an alternate source is prohibited rather than generalized into an identity model.

## Multi-Source Coverage Audit

| Source | ID | Feature / requirement | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | - | Three genuine publications and cold consumption in strict dependency order | 08-01..08-18 | COVERED | r6 contracts, seam, union, and closure are sequential; six attempts are terminal evidence. |
| REQ | DIST-01 | Core exact publication and four-target cold proof before color | 08-03..08-18 | COVERED | r6 union binds six histories; absent requires packet+receipt, exact-existing requires neither. |
| REQ | DIST-02 | Color exact publication and core-color proof before image | 08-03, 08-04, 08-06, 08-18 | COVERED | Verified r6 core predecessor. |
| REQ | DIST-03 | Image exact publication and full-graph PPM proof | 08-03, 08-04, 08-06, 08-18 | COVERED | Closed branch switch and exact graph. |
| REQ | DIST-04 | Outside-checkout cold credential-free evidence | 08-01, 08-02, 08-03, 08-06, 08-18 | COVERED | Alternate state and warm/local sources are rejected. |
| REQ | PROV-05 | Read-only exact public metadata | 08-02, 08-04, 08-06, 08-18 | COVERED | Structured surfaces only. |
| CONTEXT | D-01..D-04 | Bundle, adapter, isolation, first mutation | 08-01, 08-04..08-17 | COVERED | r6 code precedes tag; absent receipt versus exact-existing. |
| CONTEXT | D-05..D-07 | One mutation/run, predecessor, resume | 08-04, 08-06, 08-08, 08-10, 08-12, 08-14, 08-16, 08-18 | COVERED | No exact republish. |
| CONTEXT | D-08..D-12 | Exact four-target cold consumers | 08-03, 08-06, 08-18 | COVERED | Empty homes and exact graphs. |
| CONTEXT | D-13..D-15 | Polling, ambiguity stop, forward retry | 08-02, 08-04..08-18 | COVERED | r6 remains initial and r5 is immutable terminal evidence. |
| CONTEXT | D-16..D-19 | Structured metadata, sanitized evidence, fresh core observation | 08-02, 08-05, 08-06, 08-08, 08-10, 08-12, 08-14, 08-15, 08-16, 08-17, 08-18 | COVERED | Fresh observation feeds the r6 union and every successor. |
| RESEARCH | Prepared bundle is complete before secret access | 08-01, 08-04 | COVERED | Publisher repeats validation. |
| RESEARCH | Cold consumer is a separate trust domain | 08-03 | COVERED | No checkout/workspace/cache/credential inheritance. |
| RESEARCH | Structured observation precedes presentation | 08-02, 08-06, 08-11, 08-12 | COVERED | Closed projection and exact comparison. |
| RESEARCH | Public surface shape is freshness-sensitive | 08-02, 08-06, 08-11, 08-12 | COVERED | Unknown shape blocks. |
| DEBUG | hosted setup/field/parity/snapshot/workflow-key failures | Preserve attempts and corrected contracts | 08-05..08-17 | COVERED | Six histories bind stages; r4 had one failed run; r5 failed before run creation; r6 preserves every correction. |
| DEBUG | publisher actor identity | Prove exact `tchivs` without raw authentication output | 08-05, 08-06, 08-08, 08-10, 08-11, 08-12 | COVERED | Exact parse, sanitized packet/receipt, reciprocal digest. |
| DEBUG | fresh authorization continuation | Revalidate untrusted checkpoint before receipt | 08-08, 08-10, 08-12, 08-14, 08-16, 08-17, 08-18 | COVERED | Same-turn verbatim user literal; reload LF boundary, six histories/set, actor, dry run, absence, locator, active state, packet, and hosted receipts. |
| TEST | fixed handoff/tag isolation | Production path/tags non-overridable | 08-08, 08-10, 08-12, 08-14, 08-16, 08-17 | COVERED | r6 LibraryOnly GUID/no-tags/owned cleanup/fixed absence. |
| TEST | hosted exact14 receipt parity | Controller/workflow declarations/propagation | 08-10, 08-12, 08-14, 08-16, 08-18 | COVERED | Prevents parity, receipt, vector, and duplicate-key drift. |
| TEST | clean tracked snapshot | Equal empty clean state passes; unequal nonempty drift fails | 08-13, 08-14, 08-15, 08-16, 08-17, 08-18 | COVERED | Preserves clean checkout and mutation detection. |

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
