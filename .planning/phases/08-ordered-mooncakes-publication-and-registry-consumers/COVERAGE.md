# Phase 8 Coverage and External API Capability Matrix

## Scope Contract

Phase 8 integrates only the Mooncakes capabilities required to publish one dependency-safe module per authorized run, observe it through credential-free structured surfaces, and prove exact cold registry consumption. The canonical semantic order is `tchivs/mb-core@0.1.0` -> `tchivs/mb-color@0.1.0` -> `tchivs/mb-image@0.1.0`. Normalized graph serialization is deterministic but never changes node/edge equality.

The failed attempt on protected `modules-v0.1.0` and the annotated `modules-v0.1.0-r1` preparation attempt are immutable terminal-negative historical evidence, not reusable release inputs. The new pre-publication forward retry uses monotonic ref `modules-v0.1.0-r2` with a fresh initial intent/root/genesis journal/prepared manifest while retaining module version `0.1.0`, `intent_kind: initial`, `correction_sequence: 0`, and no predecessor; `modules-correction-N` remains reserved for published-content mismatch recovery that advances module versions. The r2-capable implementation is tested, atomically committed, and pushed before r2 is created. Only the absent mutation branch may run HostedPreflight and PublisherDryRun to prove isolated exact `moon whoami == tchivs`; actor mismatch, parse ambiguity, stderr, raw-output persistence, or secret-shaped content blocks packet and receipt acceptance. Exact-existing is packet-, receipt-, actor-, preflight-, and dry-run-free.

The assumption-delta detector phrase `Git fallback` maps to the noun **registry-only dependency source**, decision **no-change**, because an alternate source is prohibited rather than generalized into an identity model.

## Multi-Source Coverage Audit

| Source | ID | Feature / requirement | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | - | Three genuine publications and cold consumption in strict dependency order | 08-01..08-10 | COVERED | r2 contracts, hosted seam, explicit non-mutating authority handoff, and ordered closure are sequential; attempt zero and r1 remain terminal history. |
| REQ | DIST-01 | Core exact publication and four-target cold proof before color | 08-03, 08-04, 08-05, 08-06, 08-07, 08-08, 08-09, 08-10 | COVERED | Exclusive AuthorityUnion is the adjacency: absent requires packet plus literal receipt; exact-existing is packet/receipt-free; both require one-node cold proof before color. |
| REQ | DIST-02 | Color exact publication and core-color proof before image | 08-03, 08-04, 08-06, 08-10 | COVERED | Verified published-now or exact-existing core authority is a hard predecessor. |
| REQ | DIST-03 | Image exact publication and full-graph PPM proof | 08-03, 08-04, 08-06, 08-10 | COVERED | Image uses the same closed outcome switch and exact three-node proof. |
| REQ | DIST-04 | Outside-checkout, cold, no-credential registry-only evidence | 08-01, 08-02, 08-03, 08-06, 08-10 | COVERED | Closed proof rejects all alternate state/source paths for published-now and exact-existing authority. |
| REQ | PROV-05 | Read-only exact public metadata observation | 08-02, 08-04, 08-06, 08-10 | COVERED | Structured surfaces only; no SPA authority. |
| CONTEXT | D-01..D-04 | Deterministic bundle, one-step adapter, secret isolation, explicit first mutation | 08-01, 08-04, 08-05, 08-06, 08-07, 08-08, 08-09 | COVERED | r2 contracts/seam are committed before exact push/tag; absent needs packet plus literal receipt, exact-existing needs neither; HostedPreflight is mutation-branch only. |
| CONTEXT | D-05..D-07 | One mutation per run, strict predecessor proof, idempotent resume | 08-04, 08-06, 08-08, 08-10 | COVERED | Closed absent/exact switch permits no republish of exact-existing content. |
| CONTEXT | D-08..D-12 | Exact cold registry consumers and four targets | 08-03, 08-06, 08-10 | COVERED | Empty homes and exact graphs are mandatory for both authority kinds. |
| CONTEXT | D-13..D-15 | Bounded polling, ambiguity stop, forward-only retry | 08-02, 08-04, 08-05, 08-06, 08-07, 08-08, 08-09, 08-10 | COVERED | Mismatch records forward correction; ambiguity stops; exact never republishes; r2 remains initial. |
| CONTEXT | D-16..D-19 | Structured metadata, sanitized artifacts, fresh pre-core observation | 08-02, 08-05, 08-06, 08-08, 08-09, 08-10 | COVERED | Observations are sanitized and fresh; absent packet/receipt and exact authority form an exclusive handoff. |
| RESEARCH | Prepared bundle is complete before secret access | 08-01, 08-04 | COVERED | Publisher repeats validation. |
| RESEARCH | Cold consumer is a separate trust domain | 08-03 | COVERED | No checkout/workspace/cache/credential inheritance. |
| RESEARCH | Structured observation precedes presentation | 08-02, 08-06, 08-09, 08-10 | COVERED | Closed projection and exact comparison. |
| RESEARCH | Public surface shape is freshness-sensitive | 08-02, 08-06, 08-09, 08-10 | COVERED | Detect and sanitize live structured shape; unknown blocks. |
| DEBUG | hosted-toolchain-setup-failure | Preserve failed runs and prove corrected setup before credentials | 08-05, 08-06, 08-07, 08-08, 08-09 | COVERED | Attempt-zero and r1 facts are terminal-negative; HostedPreflight runs only on the absent mutation branch for r2. |
| DEBUG | publisher actor identity | Prove the credential resolves to exactly `tchivs` without persisting raw authentication output | 08-05, 08-06, 08-08, 08-09, 08-10 | COVERED | Isolated exact parse, closed sanitized packet/receipt, and reciprocal actor digest. |
| DEBUG | fresh authorization continuation | Treat checkpoint output as untrusted and revalidate all recovery state before receipt | 08-08, 08-09, 08-10 | COVERED | Structured absent packet exposes all recovery identities; fresh continuation reloads disk/remote state and re-proves LF boundary, histories, actor, dry run, and absence before receipt. |
| TEST | fixed handoff isolation | Production path is non-overridable and tests never touch it | 08-08 | COVERED | LibraryOnly fixtures inject independent GUID roots, clean only owned paths in finally, and assert the real fixed path absent before and after each suite. |

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
