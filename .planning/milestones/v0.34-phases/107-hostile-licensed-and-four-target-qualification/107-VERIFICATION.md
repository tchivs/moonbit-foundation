---
phase: 107-hostile-licensed-and-four-target-qualification
verified: 2026-07-29T18:35:44Z
status: passed
score: 27/27 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 107: Hostile, Licensed, and Four-Target Qualification Verification Report

**Phase Goal:** Maintainers can reproduce interoperable, hostile-safe, compatibility-preserving CFF1 behavior on every supported target.
**Verified:** 2026-07-29T18:35:44Z
**Status:** passed
**Re-verification:** No previous VERIFICATION.md existed; this was an adversarial initial verification followed by closure verification of three findings.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Generated name-keyed, CID-keyed, shared-subroutine, and generated collection workflows exercise the public API. | ✓ VERIFIED | `cff_qualification_wbtest.mbt` calls `Font::open`, `FontCollection::open/open_face`, mapping, metrics, bounds, kerning, and ordered outline commands; generated public workflows pass on all four targets. |
| 2 | Licensed Source Sans 3 and Source Han Serif JP specimens are byte-pinned, provenance-pinned, and semantically qualified by two independent readers. | ✓ VERIFIED | Exact bytes, SHA-256, license bytes, fontTools 4.63.0, AFDKO 5.0.1, and non-semantic OTS structural acceptance are closed by the qualification documents, manifest, generator, and policy gate. |
| 3 | Hostile and mutation cases preserve exact error/category/context/GID/publication and caller/ancestor budget atomicity. | ✓ VERIFIED | 53 canonical rows pass the native named tracer and all four target tracers; private mutation-window test passes; exact B8 snapshots are present. |
| 4 | All four supported targets produce equal normalized semantic evidence. | ✓ VERIFIED | Ordered `js`, `wasm`, `wasm-gc`, `native` records each pass 275/275 package tests, 53 hostile rows, four runtime observations, and seven focused assertions; normalized semantic SHA is identical. |

**Score:** 27/27 must-haves verified (four roadmap success criteria plus D-01 through D-23).

### Phase Decision Coverage

| Decision | Status | Codebase evidence |
|---|---|---|
| D-01 | ✓ VERIFIED | Qualification corpus is the canonical, generator-validated source for recipes, workflows, targets, workloads, B8 order, hostile groups, and precedence cases. |
| D-02 | ✓ VERIFIED | Source Sans 3 and Source Han Serif JP files and licenses have exact byte lengths and SHA-256 identities. |
| D-03 | ✓ VERIFIED | External licensed intake and project-generated qualification artifacts have distinct provenance/license attribution. |
| D-04 | ✓ VERIFIED | fontTools 4.63.0 and AFDKO 5.0.1 agree on exact normalized semantic facts; OTS is structural only. |
| D-05 | ✓ VERIFIED | Host-toolchain handoff schema is closed, preflight/provisioning complete, and invoked roles are pinned. |
| D-06 | ✓ VERIFIED | Qualification input is ingested atomically and rejected fail-closed on tool, hash, schema, or provenance drift. |
| D-07 | ✓ VERIFIED | One private licensed payload carrier owns embedded specimen bytes; generator and policy enforce single ownership. |
| D-08 | ✓ VERIFIED | Public workflow tests use only public APIs; FD internals remain white-box/private evidence. |
| D-09 | ✓ VERIFIED | Public and private evidence regions are generator-delimited and checked for exact mirrors. |
| D-10 | ✓ VERIFIED | Every canonical hostile row records exact CoreError category, code, operation, payload, context, GID, publication, and B8 snapshots. |
| D-11 | ✓ VERIFIED | Real Type2 execution now reaches and asserts `font-cff-type2-width-duplicate`; strict outcome-trace closure remains enabled. |
| D-12 | ✓ VERIFIED | Structural, Type2, semantic-limit, resource, mutation, and precedence groups total exactly 53 rows. |
| D-13 | ✓ VERIFIED | Exact-limit and one-short semantic rows prove stack, stems, frame depth, outline points/contours, bytes, allocations, allocation size, and work behavior. |
| D-14 | ✓ VERIFIED | Public failure paths and private mutation windows keep the same caller and ancestor B8 snapshots before/after. |
| D-15 | ✓ VERIFIED | Static glyf compatibility locks remain present and pass their named semantic test. |
| D-16 | ✓ VERIFIED | Four target records are isolated, ordered, and normalized only by `target` and `runner`. |
| D-17 | ✓ VERIFIED | Marker plus exactly five evidence products form the closed v3 evidence set; stale/extra products fail closed. |
| D-18 | ✓ VERIFIED | Each target runs public, private, hostile, runtime, focused, and full package evidence lanes. |
| D-19 | ✓ VERIFIED | Module version, dependency, five package imports, supported targets, API surface, policy, CI, and docs remain closed. |
| D-20 | ✓ VERIFIED | The official runner owns generation checking, per-target execution, comparison, marker publication, and negative probes. |
| D-21 | ✓ VERIFIED | Benchmark qualification is separate from correctness evidence and uses a fresh Budget for every measured operation. |
| D-22 | ✓ VERIFIED | Native release benchmark command records one excluded warmup, seven retained captures, raw hashes, and six observation-only statistics. |
| D-23 | ✓ VERIFIED | Final baseline is bound to tracked inputs/workspace and passes a clean read-only audit after the final source changes. |

## Required Artifacts

| Artifact group | Expected | Status | Details |
|---|---|---|---|
| `fixtures/font/cff-qualification-cases.json` | Canonical qualification contract | ✓ VERIFIED | Substantive, generator-consumed, 53 hostile rows, four targets, four workloads, exact source locators. |
| Licensed specimen and qualification documents | Exact external bytes, licenses, provenance, and oracle facts | ✓ VERIFIED | Source Sans and Source Han exact lengths/hashes; semantic readers agree; OTS is explicitly non-semantic. |
| `benchmarks/font-cff/generated_cff_evidence.mbt` | Single private licensed payload carrier | ✓ VERIFIED | Package-private, generator-delimited, single-owner and public/private boundary checks pass. |
| `benchmarks/font-cff/cff_qualification_wbtest.mbt` | Public workflow and licensed evidence tests | ✓ VERIFIED | Public API calls and real returned data/commands are asserted; no placeholder path. |
| `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt` | Private hostile, mutation, and exact-budget evidence | ✓ VERIFIED | Native named tracer and mutation tests pass; real production staging receives the exact caller budget. |
| `scripts/fixtures/Generate-FontQualification.ps1` | Canonical generator and fail-closed checks | ✓ VERIFIED | Independent `-Check` passed mirror, locator, one-field negative, intake, oracle, and hostile matrix gates. |
| `scripts/quality/Invoke-FontQualification.ps1` | Four-target evidence owner | ✓ VERIFIED | Independent `-ContractOnly` passed closed v3 contract and one-field negatives. |
| Four-target evidence records/comparison/marker | Isolated per-target evidence and normalized equality | ✓ VERIFIED | Four records pass 275/275, 53 hostile rows, four runtime observations, and equal normalized semantic digest. |
| `policy/foundation.json` and CI/docs | Compatibility, publication, target, CI, and interface locks | ✓ VERIFIED | Independent `Assert-FontFoundationPolicy` passed; semantic interface count is 85. |
| `docs/benchmarks/mb-font-cff-native-release-baseline.md` | Final observation-only native baseline | ✓ VERIFIED | SHA-256 `769076233744efa13d1c74d1d76681baf585c0ee126047918953662a52a5de5c`, length 170412; audit passes. |

All 30 artifacts declared across the six PLAN frontmatters passed the GSD artifact query. Source inspection confirmed the files are substantive, not stubs.

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Canonical corpus | Generator | Parsed contract and closed validation | ✓ WIRED | `Generate-FontQualification.ps1 -Check` passes. |
| Licensed bytes/oracle documents | Generated carrier | Exact byte/hash/oracle projection | ✓ WIRED | Qualification and single-owner checks pass. |
| Generated carrier | Public/white-box tests | Package-private helpers and generated regions | ✓ WIRED | Direct same-package calls are present and exercised. |
| Hostile corpus | Production CFF/Type2 execution | Real admission/staging with exact caller budget | ✓ WIRED | Named hostile tracer executes all 53 rows. |
| Generator | Official runner | Mandatory preflight before contract/full lanes | ✓ WIRED | `Invoke-FontQualification.ps1 -ContractOnly` begins with generator checks. |
| Official runner | Four target records | Isolated target/runner invocations | ✓ WIRED | Ordered records and normalized equality verified. |
| Source inputs | Baseline document | Tracked identity plus native benchmark driver | ✓ WIRED | Read-only audit verifies source hashes, workspace, raw captures, warmup, and statistics. |
| Policy/CI/docs | Qualification outputs | Exact schema/interface/evidence identities | ✓ WIRED | Font policy gate and final targeted review pass. |

Two automated key-link pattern queries produced false negatives: one expected the obsolete literal `licensed_specimens` instead of the actual `licensed_intake` key, and one expected a filename literal where same-package functions are called directly. Manual source/data-flow inspection and executing the linked gates verified both links.

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces real data | Status |
|---|---|---|---|---|
| Public qualification tests | Font facts and ordered outlines | Generated and exact licensed font bytes through public `Font`/`FontCollection` APIs | Yes | ✓ FLOWING |
| Private hostile tracer | Exact errors/publication/B8 | Canonical rows through real CFF admission and Type2 staging | Yes | ✓ FLOWING |
| Four-target comparison | Target records | Isolated target runs, normalized only by target/runner | Yes | ✓ FLOWING |
| Native baseline | Timing samples/statistics | Exact native release command, fresh budgets, one warmup plus seven retained captures | Yes | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Duplicate Type2 width exact behavior | `moon -C modules/mb-font test --target native -p tchivs/mb-font/font -f "Type 2 width is accepted only in the first legal width position"` | 1/1 passed | ✓ PASS |
| Canonical corpus and generated mirrors | `Generate-FontQualification.ps1 -Check` | All canonical and negative probes passed | ✓ PASS |
| Seven closed contract modes | `Test-CffQualificationContracts.ps1` | 7/7 modes passed | ✓ PASS |
| Evidence destructive boundaries | `Test-FontQualificationEvidenceBoundary.ps1` | Passed | ✓ PASS |
| Official closed v3 contract | `Invoke-FontQualification.ps1 -ContractOnly` | Passed | ✓ PASS |
| Final native baseline integrity | `Invoke-CffNativeBenchmarkBaseline.ps1 -Audit` | Tracked inputs/workspace/raw hashes/1+7/six stats passed read-only | ✓ PASS |
| Font policy/interface compatibility | `Assert-FontFoundationPolicy` | Passed | ✓ PASS |
| Full target regression | `moon test --target all` plus official target tracers | 1287/1287 workspace tests per target; qualification 275/275 per target | ✓ PASS |

## Probe Execution

No `probe-*.sh` artifact is declared for this Windows PowerShell/MoonBit phase. The phase-declared runnable gates above were executed directly rather than accepting SUMMARY narration.

## Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
|---|---|---|---|---|
| CFF-06 | 107-01 through 107-06 | Hostile, licensed, and four-target CFF1 qualification | ✓ SATISFIED | All four roadmap criteria and D-01..D-23 are behaviorally verified. |

No Phase 107 requirement is orphaned, and there are no later milestone phases to which a missing Phase 107 requirement could be deferred.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| Phase-changed files | — | No unreferenced `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER`, placeholder UI/API, or hollow-data pattern | — | None |

No public export expansion, dependency drift, import drift, target drift, ambient file/network/subprocess/FFI use, or duplicate licensed payload owner was found. Final targeted delta review `6247fad4` reported 0 Critical and 0 Warning; security verification `91e8d0e7` passed.

## Verification Findings Closed

The verifier initially found three observable failures and withheld the report until each was fixed and independently rechecked:

1. Evidence-boundary expectations were stale relative to the v3 runtime-observation/tracer contract. Closed by `a71b8be3`; destructive boundary test now passes.
2. The canonical outcome trace required `font-cff-type2-width-duplicate`, but the row produced moveto arity and the production `endchar` path could not surface a second explicit width. Closed by `a890f3ce` with real production execution and an exact named behavioral assertion; strict trace closure was not weakened.
3. The native baseline still identified pre-fix corpus/carrier inputs. Closed by final observation-only recording and policy identity commit `c9c77db3`; the first post-commit baseline command was read-only `-Audit` and passed.

The final delta review of all three closures passed in `6247fad4`.

## Human Verification Required

None. This phase's claimed outcomes are deterministic code, contract, evidence, and benchmark-integrity behaviors with executable tests; no visual, real-time, or external-service judgment remains.

## Gaps Summary

No remaining gaps. All roadmap success criteria, CFF-06, and D-01 through D-23 are satisfied with codebase and behavioral evidence.

---

_Verified: 2026-07-29T18:35:44Z_
_Verifier: the agent (gsd-verifier)_
