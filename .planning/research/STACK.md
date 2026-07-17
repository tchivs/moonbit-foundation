# Technology Stack

**Project:** MoonBit Native Foundation — v0.2 Publication & Compatibility
**Researched:** 2026-07-17
**Overall confidence:** MEDIUM — MoonBit CLI behavior was verified locally and recommendations are grounded in current official MoonBit and GitHub documentation, but Mooncakes does not publicly document several authority, token, and retry semantics that must be probed before the first write.

## Executive Recommendation

Keep the existing MoonBit + PowerShell 7 quality system as the release authority. Do not add a general-purpose release framework. Extend the closed `Required` pipeline with three project-owned layers:

1. a read-only publication preflight that proves namespace authority, exact manifests, dependency order, package bytes, and clean registry consumer definitions;
2. a single serialized publication workflow that performs `mb-core` → verify → `mb-color` → verify → `mb-image` → verify and records every remote observation;
3. a compatibility gate that generates canonical `.mbti` files with the pinned toolchain and compares them with committed per-module baselines under an explicit SemVer change policy.

Use GitHub Actions as the remote orchestrator and provenance issuer only. Use a protected `mooncakes-production` environment, least-privilege workflow permissions, a repository-wide publication concurrency group, SHA-pinned actions, and GitHub artifact attestations for the exact candidate ZIPs and release evidence manifest. GitHub OIDC must **not** be described as Mooncakes authentication: no official Mooncakes trusted-publishing/OIDC interface was found.

Until a disposable credential test proves a documented non-interactive authentication mechanism, the safest first publication is an operator-approved job or an isolated manual step using `moon login`, with the resulting credential never committed or included in evidence. CI publication may use an environment-scoped secret containing the exact validated credential representation only after the schema, file location, token scope, revocation, and cleanup behavior are tested. Read-only post-publication verification must never require publisher credentials.

## Recommended Stack

### Core Toolchain

| Technology | Verified version | Purpose | Policy |
|---|---:|---|---|
| `moon` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Package, publish, registry resolution, interface generation | Keep the exact v0.1 pin for the v0.2 publication line until all candidates are published and verified. Record `moon version` in every evidence bundle. |
| `moonc` | `v0.10.4+2cc641edf` | Compile and type-check four-target consumers | Comes with the pinned toolchain; record, do not install independently. |
| `moonrun` | `0.1.20260713` (`75c7e1f`) | Execute target tests where required | Comes with the pinned toolchain; record, do not install independently. |
| PowerShell | `7.6.3` locally verified | Closed release state machine, JSON evidence, hashing, cleanup | Continue the existing `Set-StrictMode -Version Latest` / `$ErrorActionPreference = 'Stop'` pattern. Require PowerShell 7 in CI. |
| Git | repository-compatible current release | Clean clones, immutable HEAD/tag identity, tracked-diff assertions | Release only from an exact commit and annotated tag; reject dirty or detached evidence inputs that do not match the tag. |
| GitHub CLI | `2.96.0` locally verified | Verify GitHub attestations and inspect workflow/release state | Supporting verifier only; do not make it the Mooncakes publisher. |

The latest official MoonBit documentation observed during research identifies the compiler documentation line as v0.10.4, matching the installed compiler. The local `moon` build is the authoritative command surface for implementation because it is newer than some rendered command-reference pages.

### Registry and Package Operations

| Operation | Exact command surface | Use |
|---|---|---|
| Authentication identity | `moon whoami` | Record only the expected username/owner match; never record the token or credential file. A successful result is necessary but not sufficient proof that the owner namespace is writable. |
| Interactive authentication | `moon login` | Approved bootstrap/probe only. Official docs say it writes an API token to `~/.moon/credentials.json`. |
| Closed package inventory | `moon -C <module> package --frozen --list` | Reuse the existing exact allowlist and deterministic-ZIP checks before any remote write. |
| Publish | `moon -C <module> publish --frozen` | Execute exactly once per not-yet-observed module version, only after preflight. `--frozen` prevents dependency synchronization during the write. |
| Refresh registry | `moon update` | Run in a clean consumer environment after each successful or ambiguous publication response. |
| Exact registry dependency | `moon add tchivs/<module>@0.1.0` or an exact `deps` entry | Prefer generating a disposable consumer with the exact version and then asserting that the manifest was not rewritten unexpectedly. |
| Dependency graph | `moon tree` | Record the resolved graph for each clean consumer. This supplements, but does not replace, compilation and tests. |
| Consumer verification | `moon check --target <js|wasm|wasm-gc|native> --deny-warn --frozen` and `moon test --target <...> --frozen` | Run outside the repository and without `moon.work`, path dependencies, copied source, or publisher credentials. |
| Public interface generation | `moon -C <module> info --target all --frozen` | Generate canonical `pkg.generated.mbti` files and inspect backend differences. The installed CLI writes the canonical-backend form while checking requested target interfaces. |

The module publication DAG is fixed by committed manifests:

```text
tchivs/mb-core@0.1.0
  -> tchivs/mb-color@0.1.0
       -> tchivs/mb-image@0.1.0
```

Publication and verification must therefore be a six-step transaction log, not three independent parallel jobs:

```text
publish core -> resolve/test core
             -> publish color -> resolve/test color
                              -> publish image -> resolve/test image
```

The registry owner is an operational personal namespace; the project brand remains **MoonBit Native Foundation**. The unpublished bootstrap correction keeps `0.1.0` and requires no migration note. `https://github.com/tchivs/moonbit-foundation` is intended metadata only until a read-only existence check proves it live. Any later organization namespace is a new identity family requiring explicit forward migration; do not assume rename, transfer, overwrite, delete, unpublish, or yank support.

### GitHub Actions and Provenance

| Technology | Version / pin policy | Purpose | Why |
|---|---|---|---|
| GitHub Actions environments | Current hosted service | Protect the Mooncakes publisher credential and restrict publication refs | Environment secrets are unavailable until protection rules pass. For a sole owner, use tag restrictions plus an explicit environment approval if the plan supports it; do not invent a second reviewer. |
| Workflow `concurrency` | `group: mnf-mooncakes-production`, `cancel-in-progress: false` | Serialize all publication attempts | A running registry write must never be canceled by a newer run. One stable cross-workflow group prevents two versions from racing. |
| `actions/checkout` | Pin full SHA; `v5` resolved to `93cb6efe18208431cddfb8368fd83d5badbf9bfd` on 2026-07-17 | Exact source checkout | GitHub states a full commit SHA is the immutable way to consume an action. Re-resolve and review the SHA when implementing. |
| `actions/attest` | Pin full SHA; `v4` resolved to `36051bcae73b7c2a8a6945a48cbf80953c6baa35` on 2026-07-17 | Sign provenance for candidate ZIPs and the closed release evidence manifest | Official GitHub support; requires only `id-token: write`, `contents: read`, and `attestations: write` for non-container artifacts. |
| `gh attestation verify` | GitHub CLI `2.96.0` locally verified | Independent provenance verification | Makes the attestation useful; merely generating it is not a completed control. |

Workflow permissions should default to:

```yaml
permissions:
  contents: read
```

Only the attestation job adds:

```yaml
permissions:
  contents: read
  id-token: write
  attestations: write
```

The Mooncakes publish job does not need `contents: write`, `packages: write`, or GitHub OIDC unless a later, official Mooncakes integration explicitly requires them. Publication evidence should contain candidate SHA-256 values, module/version, source commit/tag, tool versions, ordered step outcomes, registry observations, consumer result digests, and attestation references. It must not contain credential paths copied from the runner, token values, authorization headers, or an unredacted environment dump.

### Compatibility Baseline

Use `moon info`, not a third-party semantic-release engine, as the source of public API facts. Direct testing on the pinned toolchain generated six `mb-core` `.mbti` files with byte-identical SHA-256 values across two consecutive runs. The official and local CLI expose interface generation but no documented semantic compatibility diff command.

Add a project-owned compatibility tree such as:

```text
compatibility/
  0.1.0/
    toolchain.json
    mb-core/<package>.mbti
    mb-color/<package>.mbti
    mb-image/<package>.mbti
    manifest.json
```

The gate should:

1. generate interfaces in a clean clone with the exact toolchain;
2. normalize only declared transport differences (UTF-8 without BOM and LF); never sort or rewrite declarations unless the generator itself proves nondeterministic;
3. require the exact closed package set and hash every baseline file;
4. compare generated interfaces with the last published baseline;
5. classify changes under a repository-owned policy: removal/signature/visibility/type-contract change = breaking; additive public declaration = backward-compatible feature; no public interface change = patch-eligible;
6. require an explicit reviewed change record and matching version bump for every accepted delta;
7. run clean registry consumers against both the declared minimum dependency versions and the newly published versions.

For `0.x`, SemVer permits rapid evolution, but MNF's stated stability policy is stricter than relying on SemVer's permissive interpretation. Treat any incompatible published API change as requiring an explicit compatibility decision and at least a minor-version bump until 1.0; never silently replace `0.1.0` or reinterpret an unchanged version.

## Credential and Retry Contract

The publication runner must be fail-closed and journaled. Store state after each network step in ignored evidence and, after the run, seal the redacted journal into the release evidence manifest.

| Observed state | Action |
|---|---|
| Version is absent; preflight and candidate digest match | Permit one publish attempt. |
| Publish returns success | Refresh registry, resolve the exact version in a clean consumer, verify module identity/API/tests, then mark remotely verified. |
| Publish times out, disconnects, or returns an unclassified error | Do **not** immediately retry. Refresh/query the registry from a credential-free clean environment. If the exact version resolves and passes, treat the write as successful; if absence is proven repeatedly, allow an operator-approved retry; if state remains ambiguous, stop. |
| Exact version already resolves and its observable package/interface evidence matches the candidate | Skip the write and continue post-publication verification, recording `already_present_matching`. This is recovery, not republishing. |
| Exact version resolves but differs from the candidate, or ownership is unexpected | Hard stop. Never overwrite, delete, or publish a replacement under the same version. |
| Core post-verification fails | Stop before color. |
| Color post-verification fails | Stop before image. |
| Credential cleanup cannot be proven | Fail the workflow even if publication succeeded, and rotate/revoke the credential. |

Because current official public documentation does not define Mooncakes duplicate-publish responses, immutable version guarantees, organization delegation, token scope, or an authority-check API, the implementation must capture and classify real responses using a disposable namespace/version before enabling production automation. Negative claims about these behaviors are intentionally not encoded as facts.

## Integration with the Existing Required Pipeline

Keep `pwsh -NoProfile -File scripts/quality.ps1 -Lane Required` credential-free, deterministic, and safe on every pull request. Extend it only with static/read-only checks:

- exact release policy schema and module DAG;
- candidate package bytes and allowlists;
- generated `.mbti` compatibility comparison;
- publish workflow policy linting (permissions, environment, concurrency, SHA pins, allowed commands, secret names but never secret values);
- clean consumer definitions and redacted evidence schema;
- negative fixtures for path substitution, source copying, fabricated registry success, retry-after-ambiguity, out-of-order publish, and interface change without version classification.

Place real network behavior in a separate explicit lane, for example:

```powershell
pwsh -NoProfile -File scripts/publication.ps1 -Lane Preflight -Version 0.1.0
pwsh -NoProfile -File scripts/publication.ps1 -Lane Publish -Version 0.1.0
pwsh -NoProfile -File scripts/publication.ps1 -Lane Verify -Version 0.1.0
```

`Preflight` may use authenticated identity but must not write. `Publish` is the only credential-bearing lane and must require the protected environment. `Verify` must use a fresh credential-free home/cache and prove external registry consumption. The existing `Required` run must pass at the same source HEAD before publication, and again after adding only immutable/redacted publication evidence; the release workflow must never weaken or bypass its selectors.

## What Not to Add

| Rejected addition | Why not |
|---|---|
| `dijdzv/moon-release` or another general release bot | It adds an unneeded third-party executable and its own compatibility heuristics to a repository that already has a closed qualification state machine. Its public documentation is useful ecosystem evidence, not a reason to delegate the release authority. |
| npm trusted publishing / generic GitHub OIDC for Mooncakes | Mooncakes OIDC support is not documented. GitHub OIDC tokens are audience-bound and do not authenticate to arbitrary registries without registry-side trust. |
| A custom package registry client | `moon publish`, `moon update`, and `moon add` are the supported contract. Reimplementing private APIs would be fragile and could mishandle credentials or server semantics. |
| Floating action tags in committed workflows | GitHub recommends full commit SHAs for immutable action consumption. Human-readable tags may be kept in comments only. |
| Automatic retry loops around `moon publish` | Publication is a non-idempotent remote write until exact server semantics are proven. Observe remote state before any retry. |
| Parallel publication jobs | `mb-color` depends on published `mb-core`; `mb-image` depends on both. Parallelism violates the manifest DAG and makes recovery ambiguous. |
| Binary-only API snapshots or documentation HTML diffs | `.mbti` is the compiler-generated public interface. HTML and compiled artifacts are noisier and less reviewable as the compatibility source of truth. |
| Immediate migration from `moon.mod.json` to `moon.mod` | It is unrelated to distribution/compatibility and would introduce manifest churn during the first real publication. Retain the proven JSON manifests for v0.2. |
| New graphics/document/media modules | Explicitly outside the milestone; publication and compatibility must become real first. |

## Installation and Bootstrap

No new language package or global release framework is required. CI should install the exact MoonBit toolchain using a reviewed, checksum-verified mechanism and assert versions before running the existing gates.

```powershell
moon version
$PSVersionTable.PSVersion
git --version
gh --version

pwsh -NoProfile -File scripts/quality.ps1 -Lane Required
moon -C modules/mb-core package --frozen --list
moon -C modules/mb-color package --frozen --list
moon -C modules/mb-image package --frozen --list
```

Before production publication, separately prove these live prerequisites:

```powershell
moon whoami
moon -C modules/mb-core publish --dry-run
moon -C modules/mb-color publish --dry-run
moon -C modules/mb-image publish --dry-run
```

`--dry-run` is a common `moon` option in the installed CLI, but its publication fidelity must be tested; it cannot prove remote namespace write authority because a real write is intentionally absent.

## Confidence and Open Gaps

| Topic | Confidence | Evidence / gap |
|---|---|---|
| Installed MoonBit command surface and versions | HIGH for observed local behavior | Directly executed `moon version` and command help on 2026-07-17. |
| Module naming, SemVer, dependency metadata, minimal version selection | MEDIUM | Current official MoonBit docs, cross-checked with committed manifests and local CLI. |
| `.mbti` as compatibility input | MEDIUM-HIGH | Official `moon info` contract plus repeatable local generation; semantic classification remains project-owned. |
| GitHub environments, concurrency, SHA pins, attestations | MEDIUM-HIGH | Current official GitHub documentation and live tag resolution. Repository plan/visibility constraints still need confirmation. |
| Mooncakes namespace authority and organization delegation | LOW until live proof | Official docs state username-prefixed names but do not document organization/owner delegation or an authority API. |
| Mooncakes non-interactive auth, token scope, expiry, revocation | LOW until disposable-token test | Official docs only document interactive `moon login` and `~/.moon/credentials.json`. |
| Duplicate publication, immutable versions, ambiguous-write recovery | LOW until live probe | No authoritative public contract found. The recommended state machine is deliberately conservative. |
| Registry artifact digest/API equivalence to local ZIP | LOW until post-publication inspection | Prove observable package/interface equivalence through clean consumers; do not claim registry byte identity without an official digest endpoint. |

Required phase-specific research before the first production write:

1. authenticate a disposable account/namespace and record sanitized `whoami`, allowed module prefixes, and permission failures;
2. publish a disposable version, then repeat the exact request to classify duplicate behavior and prove whether versions are immutable;
3. interrupt or simulate failure after request dispatch, then validate the read-before-retry recovery algorithm;
4. validate the exact credential representation, CI injection, filesystem location, log redaction, cleanup, revocation, and least available scope;
5. confirm whether the real repository is public and has a configured GitHub remote so public attestations and environment protections are available as planned.

## Sources

- [MoonBit: Use and publish packages](https://docs.moonbitlang.com/en/latest/toolchain/moon/package-manage-tour.html) — official; login credential location, module publication, SemVer, minimal version selection, metadata. **Confidence: MEDIUM.**
- [MoonBit: Command-line help for moon](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — official; `moon info`, `add`, `login`, `publish`, `package`, and `update` surfaces. Cross-checked against installed commands. **Confidence: MEDIUM-HIGH.**
- [MoonBit: Module configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html) — official; publication names, versions, `deps`, include/exclude, source and target metadata. **Confidence: MEDIUM.**
- [MoonBit: Package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — official; target behavior and `.mbti` diagnostics. **Confidence: MEDIUM.**
- [GitHub: Deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments) — official; protection rules, branch/tag restrictions, and environment-secret availability. **Confidence: MEDIUM-HIGH.**
- [GitHub: Workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — official; concurrency behavior. **Confidence: MEDIUM-HIGH.**
- [GitHub: Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use) — official; least privilege and full-SHA action pinning. **Confidence: MEDIUM-HIGH.**
- [GitHub: Using artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations) — official; `actions/attest`, permissions, subjects, and verification. **Confidence: MEDIUM-HIGH.**
- [GitHub: OpenID Connect reference](https://docs.github.com/en/actions/reference/security/oidc) — official; OIDC audience/subject and `id-token: write`. Used to bound, not claim, Mooncakes support. **Confidence: MEDIUM-HIGH.**
- Local verification on 2026-07-17 — `moon 0.1.20260713`, `moonc v0.10.4`, PowerShell `7.6.3`, GitHub CLI `2.96.0`; repeated `moon info --target all --frozen` produced stable `mb-core` interface files. **Confidence: HIGH for this pinned machine snapshot.**
