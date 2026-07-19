# Phase 8 Coverage and External API Capability Matrix

## Scope Contract

Phase 8 integrates only the Mooncakes capabilities required to publish one dependency-safe module per authorized run, observe it through credential-free structured surfaces, and prove exact cold registry consumption. The canonical semantic order is `tchivs/mb-core@0.1.0` -> `tchivs/mb-color@0.1.0` -> `tchivs/mb-image@0.1.0`. Normalized graph serialization is deterministic but never changes node/edge equality.

Attempt-zero, r1, r2, r3, and r4 at `ee4a8eb9b8dca5d69b404c9a4a1cd81608a5462a` are five distinct immutable terminal-negative histories. r4's only hosted run `29667231047/1` failed during credential-free HostedPreflight qualification because a valid clean empty tracked snapshot could not bind to `Before`; PublisherDryRun, packet, receipt, handoff, and mutation remained zero. The retry uses `modules-v0.1.0-r5` with fresh initial root/genesis/prepared/store, module `0.1.0`, sequence 0, root=current, and no predecessor. Every eligibility artifact binds five individual digests plus the ordered set. Only absent may preflight/dry and needs packet+literal receipt; exact needs neither.

The assumption-delta detector phrase `Git fallback` maps to the noun **registry-only dependency source**, decision **no-change**, because an alternate source is prohibited rather than generalized into an identity model.

## Multi-Source Coverage Audit

| Source | ID | Feature / requirement | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | - | Three genuine publications and cold consumption in strict dependency order | 08-01..08-16 | COVERED | r5 contracts, seam, union, closure sequential; five attempts terminal. |
| REQ | DIST-01 | Core exact publication and four-target cold proof before color | 08-03..08-16 | COVERED | r5 union binds five histories; absent packet+receipt, exact neither. |
| REQ | DIST-02 | Color exact publication and core-color proof before image | 08-03, 08-04, 08-06, 08-16 | COVERED | Verified r5 core predecessor. |
| REQ | DIST-03 | Image exact publication and full-graph PPM proof | 08-03, 08-04, 08-06, 08-16 | COVERED | Closed switch/exact graph. |
| REQ | DIST-04 | Outside-checkout cold credential-free evidence | 08-01, 08-02, 08-03, 08-06, 08-16 | COVERED | Alternate state rejected. |
| REQ | PROV-05 | Read-only exact public metadata | 08-02, 08-04, 08-06, 08-16 | COVERED | Structured only. |
| CONTEXT | D-01..D-04 | Bundle, adapter, isolation, first mutation | 08-01, 08-04..08-15 | COVERED | r5 code precedes tag; absent receipt vs exact. |
| CONTEXT | D-05..D-07 | One mutation/run, predecessor, resume | 08-04, 08-06, 08-08, 08-10, 08-12, 08-14, 08-16 | COVERED | No exact republish. |
| CONTEXT | D-08..D-12 | Exact four-target cold consumers | 08-03, 08-06, 08-16 | COVERED | Empty homes/exact graphs. |
| CONTEXT | D-13..D-15 | Polling, ambiguity stop, forward retry | 08-02, 08-04..08-16 | COVERED | r5 remains initial. |
| CONTEXT | D-16..D-19 | Structured metadata, sanitized evidence, fresh core observation | 08-02, 08-05, 08-06, 08-08, 08-10, 08-12, 08-14, 08-15, 08-16 | COVERED | Fresh observation feeds r5 union. |
| RESEARCH | Prepared bundle is complete before secret access | 08-01, 08-04 | COVERED | Publisher repeats validation. |
| RESEARCH | Cold consumer is a separate trust domain | 08-03 | COVERED | No checkout/workspace/cache/credential inheritance. |
| RESEARCH | Structured observation precedes presentation | 08-02, 08-06, 08-11, 08-12 | COVERED | Closed projection and exact comparison. |
| RESEARCH | Public surface shape is freshness-sensitive | 08-02, 08-06, 08-11, 08-12 | COVERED | Unknown shape blocks. |
| DEBUG | hosted setup/field/parity/snapshot failures | Preserve attempts and corrected contracts | 08-05..08-15 | COVERED | Five histories bind stages; r4 run failed on empty clean snapshot; r5 preserves snapshot and exact14 fixes. |
| DEBUG | publisher actor identity | Prove exact `tchivs` without raw authentication output | 08-05, 08-06, 08-08, 08-10, 08-11, 08-12 | COVERED | Exact parse, sanitized packet/receipt, reciprocal digest. |
| DEBUG | fresh authorization continuation | Revalidate untrusted checkpoint before receipt | 08-08, 08-10, 08-12, 08-14, 08-15, 08-16 | COVERED | Same-turn verbatim user literal; reload LF boundary, five histories/set, actor, dry run, absence. |
| TEST | fixed handoff/tag isolation | Production path/tags non-overridable | 08-08, 08-10, 08-12, 08-14, 08-15 | COVERED | r5 LibraryOnly GUID/no-tags/owned cleanup/fixed absence. |
| TEST | hosted exact14 receipt parity | Controller/workflow declarations/propagation | 08-10, 08-12, 08-14, 08-16 | COVERED | Prevents parity/receipt/vector drift. |
| TEST | clean tracked snapshot | Equal empty clean state passes; unequal nonempty drift fails | 08-13, 08-14, 08-15, 08-16 | COVERED | Preserves clean checkout and mutation detection. |

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
