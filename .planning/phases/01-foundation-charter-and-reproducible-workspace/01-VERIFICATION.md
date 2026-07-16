---
phase: 01-foundation-charter-and-reproducible-workspace
verified: 2026-07-16T13:06:19Z
status: passed
score: 13/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 1: Foundation Charter and Reproducible Workspace Verification Report

**Phase Goal:** Contributors and consumers have an accepted architectural charter, explicit governance and compatibility rules, and a reproducible multi-module workspace with enforceable target and quality policies.

**Verified:** 2026-07-16T13:06:19Z  
**Status:** passed  
**Re-verification:** Yes - focused post-fix check after `1ed6719`

## Goal Achievement

### Observable Truths

The five roadmap success criteria were merged with the plan-level truths. Clear restatements were deduplicated; plan-specific interface, source-audit, and sole-owner evidence requirements remain separate.

| # | Truth | Status | Evidence |
|---:|---|---|---|
| 1 | A contributor can follow an authentically Accepted foundation RFC through architecture, v0.1 boundaries, lifecycle, and acceptance authority. | VERIFIED | `docs/rfcs/0001-moonbit-native-foundation.md:3,16,71,118,179`; `docs/governance/rfc-process.md:13,55,74`; the current Accepted route passed the RFC matrix. |
| 2 | A consumer can identify stability promises, project/fixture licensing, namespace and naming policy, and package target support from checked artifacts. | VERIFIED | `docs/policies/*.md`, `LICENSE`, `fixtures/manifest.json`, `policy/foundation.json`; Required policy validation passed. |
| 3 | The exact three-binary toolchain and three independent MoonBit modules are reproducible from one workspace without umbrella, path, or lockstep machinery. | VERIFIED | `moon.work`; three `moon.mod.json` files; exact `moon`, `moonc`, and `moonrun` identity stage passed before build work. |
| 4 | One root workflow performs format, policy/DAG, target checks/tests, docs, interfaces, package allowlists, and read-only checkout validation. | VERIFIED | `scripts/quality.ps1` calls `Invoke-MoonQuality`; `Invoke-RequiredQuality` at `scripts/quality/Invoke-MoonQuality.ps1:92-146`; full Required lane exited 0. |
| 5 | Required CI wiring covers all declared portable targets while LLVM is isolated and non-blocking. | VERIFIED | `.github/workflows/quality.yml:7-44` is read-only, full-SHA pinned, calls the same locally proven Required controller, and marks LLVM `continue-on-error: true`. |
| 6 | The Phase 1 no-silent-drop inventory is exactly 1 goal, 9 requirements, 16 decisions, 29 research items, 17 edge items, and 5 prohibitions with unique IDs and reciprocal plan mappings. | VERIFIED | `Assert-PhaseSourceAudit` at `scripts/quality/Assert-Policy.ps1:770-842`; canonical, LF/CRLF, missing-anchor, unknown-plan, duplicate-plan, and wrong-plan cases passed. |
| 7 | `mb-core` exposes only its exact package declaration during Phase 1. | VERIFIED | Four-target tests passed; generated semantic interface is exactly `package "moonbit-foundation/mb-core"`. |
| 8 | `mb-color` exposes only its exact package declaration during Phase 1. | VERIFIED | Four-target tests passed; generated semantic interface is exactly `package "moonbit-foundation/mb-color"`. |
| 9 | `mb-image` exposes only its exact package declaration during Phase 1. | VERIFIED | Four-target tests passed; generated semantic interface is exactly `package "moonbit-foundation/mb-image"`. |
| 10 | Sole-owner bootstrap eligibility comes from exactly one canonical maintainer identity with both maintainer and project-owner roles. | VERIFIED | `policy/maintainers.json`; `Assert-RfcAcceptanceState` at `scripts/quality/Assert-Policy.ps1:366-644`; zero/multiple/duplicate/mismatched roster cases failed closed. |
| 11 | Both mandatory architecture and authority edge reviews are completed, dispositioned, and have no unresolved blocker. | VERIFIED | `docs/governance/decisions/0001-sole-owner-bootstrap.md:39-59`; independent review found the recorded scopes cover the architecture diagram, exact DAG, ownership/exclusions, portability, lifecycle, three routes, expiry, evidence, objections, and synchronization. |
| 12 | Acceptance consumes the original owner instruction without inventing a later approval, second approver, or seven-day review. | VERIFIED | Exact owner instruction is preserved at decision line 8; policy has empty approvers/approval records and null public-review fields; legacy-assertion and fabricated-route tests failed closed. |
| 13 | RFC, index, roster, decision artifact, and policy agree on the Accepted `sole-project-owner-bootstrap` route. | VERIFIED | RFC status and route, RFC index row, roster evidence, decision anchors/reviews, and `policy/foundation.json:198-238` agree; exact route validation passed. |

**Score:** 13/13 truths verified (0 present-but-behavior-unverified)

### Plan Must-Have Coverage

| Plan | Truths | Artifacts | Key links | Result |
|---|---:|---:|---:|---|
| 01-01 | 2 | 3 | 2 | VERIFIED - canonical Accepted charter, lifecycle, index, and bidirectional governance links |
| 01-02 | 4 | 4 | 3 | VERIFIED - policy, source audit, fixture provenance, license, stability/publication/target/toolchain prose |
| 01-03 | 3 | 4 | 3 | VERIFIED - exact workspace, identities, target sets, independent versions, and inward DAG |
| 01-04 | 3 | 3 | 2 | VERIFIED - mb-core checked docs/private test/exact interface |
| 01-05 | 3 | 3 | 2 | VERIFIED - mb-color checked docs/private test/exact interface |
| 01-06 | 3 | 3 | 2 | VERIFIED - mb-image checked docs/private test/exact interface |
| 01-07 | 5 | 3 | 3 | VERIFIED - exact toolchain, ordered stages, explicit targets, source audit, isolated LLVM, pinned CI |
| 01-08 | 5 | 5 | 4 | VERIFIED - sole-owner eligibility, edge reviews, original preauthorization, synchronized acceptance, final qualification |

All eight `verify plan-structure` invocations returned `valid: true` with zero errors or warnings. PyYAML independently parsed all nested must-have blocks (28 truths, 28 artifacts, 21 key links). The bundled `verify.artifacts`/`verify.key-links` helper emitted a parser warning for these valid nested blocks, so artifact and link results below were checked directly against the repository instead of accepting the helper's empty fallback.

## Required Artifacts

| Artifact group | Status | Details |
|---|---|---|
| Charter/process/index | VERIFIED | RFC 0001 is substantive and Accepted; lifecycle, authority, evidence, boundary rules, index status, and links are present. |
| Foundation policy/source audit | VERIFIED | JSON parses; exact module/toolchain/target/DAG/RFC/publication facts and exact 1/9/16/29/17/5 inventory pass fail-closed validators. |
| License/fixture policy | VERIFIED | Canonical Apache-2.0 text exists; fixture manifest schema and empty initial inventory pass the 13-case identity/containment matrix. |
| Workspace/manifests/packages | VERIFIED | Exact three members, three final identities, independent `0.1.0` versions, four-target module/package sets, and only allowed module dependencies. |
| Module docs/scaffolds/tests | VERIFIED | All three candidate READMEs and Unreleased ledgers are substantive; private probes are exercised on every target and emit no public API. |
| Quality scripts | VERIFIED | Toolchain, policy, lifecycle, fixture, source-audit, ordered Moon quality, package, and mutation checks are implemented and invoked by the root controller. |
| CI workflow | VERIFIED | Read-only permissions, no publication secrets, full action pins, exact toolchain input, blocking Required job, and non-blocking LLVM job. |
| Sole-owner decision/roster | VERIFIED | Exact user instruction, canonical identity/roles/evidence, four required anchors, two completed reviews, and no unresolved objection. |

Direct artifact validation found all 28/28 plan-declared artifacts and all declared `contains` markers. Substance and wiring were then established through source inspection and the behavioral checks below; none is a placeholder or orphan.

## Key Link Verification

| Plan | Link group | Status | Details |
|---|---|---|---|
| 01-01 | RFC index -> charter -> normative process | WIRED | Canonical relative links resolve and current status is synchronized. |
| 01-02 | Stability policy -> foundation JSON; licensing policy -> fixture manifest; source audit -> validator | WIRED | Prose points to machine owners; Required passes the canonical audit path to `Assert-PhaseSourceAudit`. |
| 01-03 | Workspace -> manifests; color -> core; image -> core/color | WIRED | Members and normal named dependencies match the allowed DAG. |
| 01-04..06 | Scaffold -> generated interface; README -> manifest/package metadata | WIRED | Exact interfaces generated; candidate/target/dependency facts agree for each module. |
| 01-07 | Policy validator -> audit; runner -> validators; CI -> root lanes | WIRED | Both validators run before build stages; both workflow jobs call the same controller. |
| 01-08 | Roster -> owner instruction -> edge reviews -> RFC/policy acceptance; Required -> RFC matrix | WIRED | Exact evidence anchors and synchronized route are validated inside Required. |

Direct semantic checks passed 21/21 key links.

## Data-Flow Trace (Level 4)

Not applicable: Phase 1 contains governance/configuration, deterministic CLI orchestration, and private constant scaffold probes; it has no UI or dynamic rendered-data artifact. Relevant policy flow was instead traced from JSON -> validators -> root controller -> CI and exercised end to end.

## Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Complete Required contract | `pwsh -NoProfile -File .\scripts\quality.ps1 -Lane Required` | Exit 0 in 83.8s | PASS |
| RFC evidence/lifecycle matrix | Required pre-stage; 75 declared acceptance cases plus direct harness/reparse cases | All PASS, including final CR-01..04 and WR-01..04 regressions | PASS |
| Fixture identity/containment | Required pre-stage | 13 cases PASS, including digest, invalid dates, traversal, missing file, external policy, symlink escape | PASS |
| Source-audit provenance | Required pre-stage | LF and CRLF markers plus canonical/missing-anchor/unknown-plan/duplicate-plan/wrong-plan cases PASS | PASS |
| Required targets | Required stage | `js`, `wasm`, `wasm-gc`, `native`: 3/3 tests each, 12/12 total | PASS |
| Docs/interfaces/packages | Required stage | Three docs builds, three exact package-only interfaces, three exact six-file package allowlists | PASS |
| Read-only operation | Required final stage plus `git status --short` | Tracked diff unchanged; only pre-existing untracked graph/cache directories remain | PASS |
| Plan structure/artifacts/links | GSD structure validator plus direct YAML/semantic checks | 8/8 plans, 28/28 artifacts, 21/21 links | PASS |
| Documented commit evidence | `git cat-file -e <sha>^{commit}` for all summary/review-fix hashes | All referenced commits exist | PASS |

## Probe Execution

No conventional `probe-*.sh` files are declared. The phase's declared runnable probes are the PowerShell RFC, fixture, source-audit, and root Required matrices; each was executed in its own process through the sole public controller and passed.

## Requirements Coverage

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| GOV-01 | 01-01, 01-08 | SATISFIED | Accepted canonical charter with architecture, terminology, boundaries, route evidence, and synchronized index/policy. |
| GOV-02 | 01-01, 01-07, 01-08 | SATISFIED | Complete lifecycle/authority/evidence/objection rules plus adversarial route matrix. |
| GOV-03 | 01-02, 01-04..07, 01-08 | SATISFIED | Experimental/candidate/stable promises, candidate module docs/metadata, promotion/removal rules, and premature-stable prohibition. |
| GOV-04 | 01-02, 01-03, 01-07, 01-08 | SATISFIED | Apache-2.0, fixture provenance, namespace block, final names, independent publication rules, read-only/no-secret CI. |
| WORK-01 | 01-03..06, 01-08 | SATISFIED | Three independently packaged workspace modules with module-owned manifests/docs/tests/changelogs. |
| WORK-02 | 01-02, 01-07, 01-08 | SATISFIED | Exact `moon`, `moonc`, and `moonrun` policy and passing pre-build identity gate. |
| WORK-03 | 01-02..08 | SATISFIED | Exact four-target module/package/documentation agreement for every public root package. |
| WORK-04 | 01-07, 01-08 | SATISFIED | One root command executes all required stages and package/DAG/mutation checks. |
| WORK-05 | 01-07, 01-08 | SATISFIED | Explicit four-target check/test evidence; LLVM remains separate, experimental, and non-blocking. |

No Phase 1 requirement is orphaned: all nine occur in plan frontmatter and in the exact source audit.

## Prohibitions and Threat Controls

| Control | Status | Enforcement evidence |
|---|---|---|
| No fabricated RFC acceptance evidence | VERIFIED | Exact evidence-set binding, route-specific artifact resolution, path/reparse guards, and adversarial matrix. |
| No premature stable claim | VERIFIED | All modules and public packages are candidate; policy and READMEs explicitly deny stable status. |
| No unproven external fixture | VERIFIED | Empty canonical inventory and fail-closed provenance/digest/redistribution/path matrix. |
| No namespace publication before ownership | VERIFIED | `publication.blocked=true`, `owner_verified=false`, no publication job/secret. |
| LLVM must not become supported/blocking | VERIFIED | Exact required/experimental sets and independent `continue-on-error` job. |

All HIGH threats from Plan 01-08 are mitigated by current roster checks, canonical contained evidence resolution, completed review records, synchronized status, and final qualification. None is accepted or unresolved.

## Anti-Patterns and Disconfirmation Pass

No blocker debt markers, empty implementations, public placeholder APIs, command execution from policy data, `Invoke-Expression`, `moon work sync`, unpinned CI actions, publication credentials, or reparse components were found. Matches for words such as `placeholder` occur only in prohibitions and negative tests.

Three explicit disconfirmation checks were made:

1. **Resolved freshness check:** commit `1ed6719` changed the decision header to the historically scoped statement `Decision-time effect: Conditional preauthorization; RFC 0001 remained Proposed until all conditions below passed.` This removes the stale-current-status reading without changing the original authorization, route, conditions, or evidence. Current `Assert-RfcAcceptanceState` and `Assert-FoundationPolicy` checks passed after the change.
2. **Potentially misleading helper result:** the bundled GSD artifact/key-link parser reports empty nested blocks even though the YAML is valid and PyYAML parses 28 artifacts/21 links. Direct existence, substance, behavior, and wiring checks replace that helper result.
3. **Uncovered environment path:** no Git remote exists, so no hosted Actions run is inspectable. The workflow is statically complete and invokes the exact controller that passed locally; action availability remains an operational watch item, not a missing Phase 1 repository contract.

## Human Verification Required

None. The two substantive governance reviews were independently repeated against the final charter/process and found no omitted boundary or authority case. No visual, interactive, or runtime-only state transition remains untested for this phase's repository contract.

## Gaps Summary

No blocking gaps, uncertain must-haves, missing artifacts, broken links, or unresolved HIGH threats were found. Phase 1's goal is achieved and it is ready to transition to Phase 2.

---

_Verified: 2026-07-16T13:06:19Z_  
_Verifier: the agent (gsd-verifier)_
