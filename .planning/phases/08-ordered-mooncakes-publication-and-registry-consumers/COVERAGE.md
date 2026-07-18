# Phase 8 Coverage and External API Capability Matrix

## Scope Contract

Phase 8 integrates only the Mooncakes capabilities required to publish one dependency-safe module per authorized run, observe it through credential-free structured surfaces, and prove exact cold registry consumption. The canonical semantic order is `tchivs/mb-core@0.1.0` -> `tchivs/mb-color@0.1.0` -> `tchivs/mb-image@0.1.0`. Normalized graph serialization is deterministic but never changes node/edge equality.

The assumption-delta detector phrase `Git fallback` maps to the noun **registry-only dependency source**, decision **no-change**, because an alternate source is prohibited rather than generalized into an identity model.

## Multi-Source Coverage Audit

| Source | ID | Feature / requirement | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | - | Three genuine publications and cold consumption in strict dependency order | 08-01..08-06 | COVERED | Reversible seam, explicit core checkpoint, and three one-module runs. |
| REQ | DIST-01 | Core exact publication and four-target cold proof before color | 08-03, 08-04, 08-05, 08-06 | COVERED | Explicit first mutation plus exact one-node proof. |
| REQ | DIST-02 | Color exact publication and core-color proof before image | 08-03, 08-04, 08-06 | COVERED | Verified core checkpoint is a hard predecessor. |
| REQ | DIST-03 | Image exact publication and full-graph PPM proof | 08-03, 08-04, 08-06 | COVERED | Third separate run and exact three-node proof. |
| REQ | DIST-04 | Outside-checkout, cold, no-credential registry-only evidence | 08-01, 08-02, 08-03, 08-06 | COVERED | Closed proof rejects all alternate state/source paths. |
| REQ | PROV-05 | Read-only exact public metadata observation | 08-02, 08-04, 08-06 | COVERED | Structured surfaces only; no SPA authority. |
| CONTEXT | D-01..D-04 | Deterministic bundle, one-step adapter, secret isolation, explicit first mutation | 08-01, 08-04, 08-05 | COVERED | Autonomous work stops before tag/dispatch/publish. |
| CONTEXT | D-05..D-07 | One mutation per run, strict predecessor proof, idempotent resume | 08-04, 08-06 | COVERED | Core/color/image are separate runs. |
| CONTEXT | D-08..D-12 | Exact cold registry consumers and four targets | 08-03, 08-06 | COVERED | Empty homes and exact graphs are mandatory. |
| CONTEXT | D-13..D-15 | Bounded polling, ambiguity stop, forward-only retry | 08-02, 08-04, 08-06 | COVERED | No automated republish. |
| CONTEXT | D-16..D-19 | Structured metadata, sanitized artifacts, fresh pre-core observation | 08-02, 08-05, 08-06 | COVERED | Phase 9 immutable closure excluded. |
| RESEARCH | Prepared bundle is complete before secret access | 08-01, 08-04 | COVERED | Publisher repeats validation. |
| RESEARCH | Cold consumer is a separate trust domain | 08-03 | COVERED | No checkout/workspace/cache/credential inheritance. |
| RESEARCH | Structured observation precedes presentation | 08-02, 08-06 | COVERED | Closed projection and exact comparison. |
| RESEARCH | Public surface shape is freshness-sensitive | 08-02, 08-05 | COVERED | Detect and sanitize live structured shape; unknown blocks. |

## Requirement Adjacency and Edge Rules

| Requirement | Required predecessor | Exact acceptance | Empty / missing | Ordering |
|---|---|---|---|---|
| DIST-01 | Explicit core authorization packet | Exact core 0.1.0 identity, one-node graph, metadata/artifact agreement, four targets, checked behavior | Fail | Core is first. |
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

## Artifacts This Phase Produces

- Deterministic schema-valid prepared bundle and adversarial validation evidence.
- Closed structured Mooncakes observations for core, color, and image.
- Cold registry-only one-node, two-node, and three-node consumer proofs across js, wasm, wasm-gc, and real native.
- Three monotonic one-module workflow checkpoints bound to immutable intent and journal digests.
- Credential-free reciprocal DIST-01..DIST-04 and PROV-05 qualification evidence.
