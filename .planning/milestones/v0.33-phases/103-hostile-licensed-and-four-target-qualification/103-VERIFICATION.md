---
phase: 103-hostile-licensed-and-four-target-qualification
verified: 2026-07-28T07:41:16Z
status: passed
score: 16/16 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 103: Hostile, Licensed, and Four-Target Qualification Verification Report

**Phase Goal:** Maintainers can reproduce the complete collection-to-`Font` workflow and its fail-closed boundaries with generated and licensed evidence on every supported target.
**Verified:** 2026-07-28T07:41:16Z
**Status:** passed
**Re-verification:** No — initial verification
**Verified revision:** `74357607fc7cd9d256133e81b8581fa2e2e09394`
**Verified tree:** `b927505605a731392da986508567a543284bfdc5`

## Goal Achievement

The phase goal is achieved. The current implementation, tests, policy, and generated evidence prove the complete generated/licensed collection-to-`Font` workflow and its fail-closed boundaries on `js`, `wasm`, `wasm-gc`, and `native`. The four target records are bound to the exact verified commit and tree, each records 14/14 focused gates and 152/152 package tests, and their semantic projection is equal with SHA-256 `faec7d06365bdd8d09d2d5a60448b2dbbe74be04b13da2babb9c0b50777abcbc`.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Malformed structure, invalid indices/profiles, checked arithmetic, semantic limits, and budgets fail deterministically without partial publication or uncommitted charge. | ✓ VERIFIED | The closed corpus contains 24 hostile, 44 limit, and 12 budget cases. `font qualification executes the closed collection hostile outcome matrix` passed independently on native. The dispatcher compares every structured error field and complete eight-field budget snapshots; ancestor failures compare both parent and child. All four exact-HEAD records carry the same outcomes. |
| 2 | Mutation during inspection, selected-face admission, or inherited `Font` queries fails closed without stale facts or partial geometry. | ✓ VERIFIED | Nine mutation cases are canonical. The independently run public and mid-operation mutation tests each passed; the four inherited query tests are among the 14 passing focused gates in every exact-HEAD record. Tests assert `State`/revision-drift results and unchanged budgets or no path publication. |
| 3 | Generated TTC v1/v2, DSIG, sharing, mixed-profile, non-zero-base, hostile, and complete public collection workflows are reproducible from immutable fixtures. | ✓ VERIFIED | The corpus has eight public workflows and the required hostile/resource groups. `Generate-FontQualification.ps1 -Check` passed. The generated public workflow test passed independently and is one of the per-target focused gates. |
| 4 | A provenance-tracked licensed collection proves public interoperability while v0.32 standalone SFNT behavior remains unchanged. | ✓ VERIFIED | The 757,428-byte DejaVu derivative is externally licensed with confirmed redistribution and retained notice. Both selected faces run the same complete standalone DejaVu public-fact helper; the licensed test passed independently. Phase 100 fixture/oracle/corpus/license hashes remain exact, and the five named standalone gates pass in every record. |
| 5 | Independent `js`, `wasm`, `wasm-gc`, and `native` runs report identical facts and preserve pure MoonBit, the sole `mb-font -> mb-core` edge, and WOFF/CFF boundaries. | ✓ VERIFIED | Four ordered exact-HEAD records validate and report 14 focused gates plus 152/152 package tests each. Re-running the comparison validator recomputed equal semantics and the stated hash. Evidence records and policy show 13 production sources, five `mb-core` imports, one module dependency, no FFI/ambient I/O, WOFF/WOFF2/OTTO unavailable, CFF/CFF2/variable inspect-only, and DSIG present-unverified. |
| 6 | The licensed derivative has the frozen length and digest. | ✓ VERIFIED | Direct filesystem inspection: 757,428 bytes, SHA-256 `833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b`. |
| 7 | The derivative contains two 20-record directories at offsets 20 and 352 with one shared payload starting at 684. | ✓ VERIFIED | An independent byte-level read found `ttcf`, version `0x00010000`, count 2, offsets `20,352`, two 20-record/332-byte directories, payload start 684, and zero corresponding-record byte mismatches. |
| 8 | The TTC oracle independently closes structure, sharing, checksums, profiles, lineage, and standalone-oracle binding. | ✓ VERIFIED | `collection-oracle.json` has closed derivative/collection/faces/shared-tables/binding sections; the binding uses standalone oracle SHA-256 `4247394c...`. The generator is PowerShell-only and `-Check` independently reconstructed and validated all artifacts. |
| 9 | Portable MoonBit reconstructs the TTC from one DejaVu representation and uses no runtime file access. | ✓ VERIFIED | Generated source has exactly 185 existing DejaVu chunk definitions, one standalone accessor, and one TTC assembler. The assembler reuses the standalone bytes, duplicates only directories, patches 40 offsets, and copies the payload once. Policy confirms no production FFI or ambient I/O. |
| 10 | Generation, provenance, manifest order, and immutable Phase 100 identities fail closed. | ✓ VERIFIED | Generator `-Check`, fixture-policy matrix, and target-all check passed. The manifest's final three records distinguish generated corpus, externally derived TTC, and metadata-only oracle. Phase 100 hashes remain `a9a86e...`, `7da195...`, `424739...`, and `7a083b...`. |
| 11 | Evidence v2 uses a fresh managed identity and does not reuse v1 ownership. | ✓ VERIFIED | Runner constants are marker `mnf-font-qualification-evidence/v2`, workflow `font-complete-public-v2`, and directory `font-v2`; the marker on disk matches. The managed boundary test passed, including v1 marker, containment, link/reparse, cleanup, and unrelated-file cases. |
| 12 | Exactly four closed target records exist in required order with all mandatory semantic sections. | ✓ VERIFIED | `comparison.json` orders `js`, `wasm`, `wasm-gc`, `native`; the directory has only those four target records, the managed marker, and comparison. Each 16-key record validates against the current runner's closed schema, including source identities. |
| 13 | Semantic comparison removes exactly top-level `target` and `runner`. | ✓ VERIFIED | `Get-FontQualificationSemanticPayload` explicitly includes every other record section. The read-back validator recomputed the four file hashes and semantic hash and accepted `normalization_removed: ["target","runner"]` only. |
| 14 | Each target independently executes focused tests and the complete package under the exact pinned toolchain. | ✓ VERIFIED | Every record reports 14 focused commands with one pass each and `Total tests: 152, passed: 152, failed: 0.` The records match the exact policy identity: moon `0.1.20260713`, moonc `v0.10.4+2cc641edf`, moonrun `0.1.20260713`. The local toolchain gate also passed. |
| 15 | Evidence, workflow, and policy negative boundaries reject drift and unsafe ownership. | ✓ VERIFIED | Runner source has 29 counted negative probes spanning record count/order/schema, nested facts, budgets, capabilities, dependencies, focused source identities, toolchain substitution, and semantic divergence. The final lane reported all 29 passing; evidence-boundary and full foundation policy were independently rerun and passed. |
| 16 | Policy, CI, licensing documentation, README, and changelog describe and enforce the shipped contract without release-policy expansion. | ✓ VERIFIED | Foundation policy passed and locks 85 interface lines, 13 production sources, five imports, one dependency, four targets, source hashes, and capability negatives. The existing single CI job uses pinned actions, success-only v2 upload, and 20-minute timeout. README/changelog document TTC/OTC v1/v2, selected static-glyf, derivative identity, command/report, and exclusions. Foundation diff changes description/source-policy hashes only; publication/release fields are unchanged. |

**Score:** 16/16 truths verified (0 present-but-behavior-unverified)

## Roadmap Success Criteria

| # | Roadmap criterion | Disposition | Exact evidence |
|---|---|---|---|
| 1 | Deterministic structured hostile/resource outcomes with atomic publication and budget behavior. | ✓ SATISFIED | Truth 1; closed 24/44/12 outcome groups; passing hostile matrix on native and in all four records. |
| 2 | Mutation fails closed across collection inspection, admission, and inherited `Font` queries. | ✓ SATISFIED | Truth 2; nine mutation facts; passing public/private named tests; four inherited gates per target. |
| 3 | Generated v1/v2, DSIG, sharing, mixed-profile, non-zero-base, hostile, and public workflows are immutable and reproducible. | ✓ SATISFIED | Truths 3 and 10; generator drift check and generated workflow behavior pass. |
| 4 | Licensed interoperability is proven and v0.32 standalone behavior remains unchanged. | ✓ SATISFIED | Truth 4; licensed test pass, exact lineage/digest, both-face equality, immutable Phase 100 hashes, standalone focused gates. |
| 5 | Four targets are semantically equal and preserve implementation/dependency/capability boundaries. | ✓ SATISFIED | Truths 5 and 11–15; exact-HEAD records, equality hash, policy/toolchain validation, no FFI/I/O, sole dependency. |

## Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
|---|---|---|---|---|
| TTC-04 | 103-01, 103-02, 103-03 | Hostile structure/profile/index/arithmetic/limit/budget/mutation outcomes are structured and atomic. | ✓ SATISFIED | 24 hostile + 44 limit + 12 budget + 9 mutation facts; exact error and budget validation; hostile/public/private mutation named tests pass; equal facts in all targets. |
| TTC-05 | 103-01, 103-02, 103-03 | Generated, licensed, standalone, and complete public evidence is reproducible and identical on four targets. | ✓ SATISFIED | Immutable fixtures/oracles, both licensed faces equal standalone, four records at exact HEAD/tree, 14 focused and 152 package passes per target, equal semantic hash. |

No Phase 103 requirement is orphaned. `.planning/REQUIREMENTS.md` maps only TTC-04 and TTC-05 to this phase, and every plan claims both.

## Locked Decision Disposition

| Decision | Status | Verification |
|---|---|---|
| D-01 | ✓ VERIFIED | No production MoonBit file changed from the pre-phase base; policy remains exactly 85 semantic lines. |
| D-02 | ✓ VERIFIED | Phase output is qualification fixtures/tests/evidence/policy; no new parser or runtime capability was added. |
| D-03 | ✓ VERIFIED | Separate collection corpus and portable mirror exist; Phase 100 hashes are unchanged. |
| D-04 | ✓ VERIFIED | Exact two-face TTC v1 derivative, sharing geometry, length, and digest independently verified. |
| D-05 | ✓ VERIFIED | Manifest retains external origin, DejaVu license, parent/generator/notice digests, confirmed redistribution, and intended use. |
| D-06 | ✓ VERIFIED | Independent closed PowerShell TTC reader/oracle binds semantics to the standalone oracle, not target output. |
| D-07 | ✓ VERIFIED | Closed 24 hostile, 44 limit, and 12 budget matrix is executed, not merely listed. |
| D-08 | ✓ VERIFIED | Public mutation is black-box; existing private hooks cover only mid-open/mid-admission; inherited queries remain separately named. |
| D-09 | ✓ VERIFIED | Standalone corpus digest, 11 outcomes, exact interface, focused identities, and full package remain explicit; no source total constant is used. |
| D-10 | ✓ VERIFIED | Fresh v2 schema, four records, closed nested facts, and target/runner-only normalization validate. |
| D-11 | ✓ VERIFIED | The existing `FontQualification` selector/job runs independent targets; no second lane/job exists. |
| D-12 | ✓ VERIFIED | CFF/CFF2/variable are inspect-only; WOFF absent; pure MoonBit, sole `mb-core` edge, and exact interface are policy/evidence facts. |
| D-13 | ✓ VERIFIED | Fixture/evidence/foundation/source/CI policy updated; timeout remains 20; publication/release policy did not change. |
| D-14 | ✓ VERIFIED | README/changelog contain collection workflow, provenance, evidence route, and retained exclusions. |
| D-15 | ✓ VERIFIED | Git chronology shows strict 103-01 → 103-02 → 103-03 execution. Review remediation later strengthened and regenerated the frozen corpus and consumers together; current evidence binds the final synchronized HEAD/tree and all focused source hashes, so no stale schema consumer remains. |

## Prohibition Checks

| Prohibition concern | Status | Evidence |
|---|---|---|
| Preserve Phase 100 fixtures, oracle, license, standalone test identities, and interface. | ✓ VERIFIED | Exact locked hashes pass; 85-line interface and named standalone gates are current evidence. |
| Do not duplicate licensed bytes, self-certify through production parsing, relabel the derivative, or add a duplicate notice. | ✓ VERIFIED | One DejaVu literal representation; independent PowerShell oracle; external manifest record; one retained LICENSE. |
| Do not add production runtime capability, hooks, threads/timers, ambient I/O, FFI, dependency, target-specific semantics, or materialization. | ✓ VERIFIED | No production source diff; policy negatives and evidence boundary facts pass. |
| Do not weaken focused test names/outcomes or normalize semantic fields beyond target/runner. | ✓ VERIFIED | Closed focused array and source hashes validate; semantic projection includes every non-target/non-runner field. |
| Do not add a second runner/job, accept unsafe evidence roots, follow links, upload failing evidence, reuse v1, or increase timeout without measurement. | ✓ VERIFIED | Single selector/job, passing ownership boundary matrix, success-only upload, v2 marker, timeout 20. |
| Do not change publication/release policy. | ✓ VERIFIED | Pre-phase-to-HEAD foundation/workflow diff contains no publication or release-policy change. |

The review-fix cycle did revise Plan 103-01/103-02 qualification artifacts after their initial summaries. This does not leave a current prohibition breach: the revisions closed critical correctness gaps, regenerated the corpus/mirror/manifest together, preserved public/runtime/Phase-100 identities, and the final evidence binds every synchronized source at the exact verified tree.

## Required Artifacts

| Artifact | Levels 1–4 | Status | Details |
|---|---|---|---|
| `fixtures/font/collection-qualification-cases.json` | Exists; substantive closed 97-case data; generated/hostile tests consume it; all groups flow into evidence. | ✓ VERIFIED | 8 public, 24 hostile, 9 mutation, 44 limit, 12 budget cases. |
| `fixtures/font/dejavu-sans-2.37/DejaVuSans-two-face-v1.ttc` | Exists; exact binary; consumed by generator/oracle/mirror/tests/evidence. | ✓ VERIFIED | 757,428 bytes; frozen digest and sharing geometry. |
| `fixtures/font/dejavu-sans-2.37/collection-oracle.json` | Exists; closed independent facts; bound to standalone oracle; consumed by validator/evidence. | ✓ VERIFIED | 20 shared-table records and both face records. |
| `fixtures/manifest.json` | Exists; exact ordered provenance; policy-enforced. | ✓ VERIFIED | 14 records with three Phase 103 records after unchanged Phase 100 record. |
| `scripts/fixtures/Generate-FontQualification.ps1` | Exists; substantive generator/oracle/check implementation; wired to all fixture/generated paths. | ✓ VERIFIED | `-Check` passed. |
| `modules/mb-font/font/generated_font_qualification_test.mbt` | Exists; substantive generated mirror; consumed by public/hostile tests. | ✓ VERIFIED | One DejaVu representation and one TTC assembler. |
| `modules/mb-font/font/font_qualification_test.mbt` | Exists; substantive public workflows; wired to generated bytes and public collection APIs. | ✓ VERIFIED | Generated and licensed named tests pass. |
| `modules/mb-font/font/font_qualification_hostile_test.mbt` | Exists; substantive closed dispatcher; wired through generated case accessors and public APIs. | ✓ VERIFIED | Hostile matrix and public mutation tests pass. |
| `modules/mb-font/font/collection_wbtest.mbt` | Exists; substantive deterministic transition tests; wired to existing private final-guard hooks. | ✓ VERIFIED | Mid-open/mid-admission test passes. |
| `scripts/quality/Invoke-FontQualification.ps1` | Exists; closed runner, validators, records, probes, comparison; wired to tests and evidence. | ✓ VERIFIED | Current comparison validator passed. |
| `scripts/quality/Test-FontQualificationEvidenceBoundary.ps1` | Exists; substantive managed-root/link/cleanup/version matrix; invoked by policy/final lane. | ✓ VERIFIED | Independently passed. |
| `scripts/quality/Assert-Policy.ps1` | Exists; substantive interface/source/dependency/fixture/workflow negatives; wired to policy and CI. | ✓ VERIFIED | Independently passed. |
| `policy/foundation.json` | Exists; collection-aware closed contract; policy-consumed. | ✓ VERIFIED | 85 interface lines, 13 sources, five imports, one dependency, four targets. |
| `modules/mb-font/moon.mod.json` | Exists; synchronized description; used by Moon/package evidence. | ✓ VERIFIED | Sole dependency remains `tchivs/mb-core`. |
| `.github/workflows/quality.yml` | Exists; exact single job; calls runner and uploads success-only v2 evidence. | ✓ VERIFIED | Pinned checkout/upload, pinned toolchain installer, timeout 20. |
| `docs/policies/licensing-and-fixtures.md` | Exists; explicit external-derivative policy; linked to manifest enforcement. | ✓ VERIFIED | Parent/generator/notice/derivative/redistribution requirements. |
| `modules/mb-font/README.mbt.md` | Exists; executable collection example and evidence route; runner checks it per target. | ✓ VERIFIED | TTC/OTC, derivative, command/report, and boundaries documented. |
| `modules/mb-font/CHANGELOG.md` | Exists; collection candidate history and exclusions. | ✓ VERIFIED | No release or stability promotion claim. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Generator | TTC derivative / collection oracle / generated MoonBit | Deterministic construction, independent read, stable rendering | ✓ WIRED | All paths are explicit and generator `-Check` passed. |
| Collection oracle | Standalone oracle | `standalone_oracle_binding` path and exact SHA-256 | ✓ WIRED | Both selected faces bind to standalone semantic facts. |
| Public qualification test | Generated mirror and collection runtime | TTC assembler + `FontCollection::open/open_face` | ✓ WIRED | Both public named tests pass. |
| Hostile qualification test | Generated collection corpus | `font_qualification_cases()` → `font_collection_qualification_cases()` | ✓ WIRED | The plan's older literal pattern `font_qualification_collection_cases` is stale, but manual tracing proves the actual accessor link. |
| White-box qualification | Collection runtime | Existing `open_after_normalize` and `open_face_after_admit` hooks | ✓ WIRED | Named transition test passes. |
| Runner | Focused tests / four records / comparison | Exact names, serial target commands, read-back validation | ✓ WIRED | 14 focused identities and eight focused-source hashes are closed. |
| Policy | Foundation / fixtures / runner / workflow / docs | Independent classifiers and mutation negatives | ✓ WIRED | Full foundation policy passed. |
| CI workflow | Existing FontQualification runner | Single v2 command and success-only upload | ✓ WIRED | Exact workflow schema accepted; continuation/toolchain mutations rejected. |

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces real data | Status |
|---|---|---|---|---|
| Generated MoonBit mirror | TTC bytes and 97 cases | Canonical JSON, DejaVu TTF, independent PowerShell generator | Yes; byte-equal derivative and ordered case rows | ✓ FLOWING |
| Public/hostile tests | Collection and `Font` outcomes | Generated bytes/cases through shipped APIs | Yes; named behavioral tests execute results and exact errors | ✓ FLOWING |
| Target records | Semantic facts and command outcomes | Actual focused/full target commands plus current fixtures/policy/source hashes | Yes; pass totals and facts are non-empty and exact-HEAD-bound | ✓ FLOWING |
| `comparison.json` | File hashes and normalized semantic hash | Four read-back-validated records | Yes; file hashes recompute and semantic equality validates | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Generated collection workflows | `moon ... font_qualification_test.mbt -f 'font-complete-public qualifies generated collection workflows' --target native ...` | 1/1 passed | ✓ PASS |
| Licensed two-face workflow | `moon ... font_qualification_test.mbt -f 'font-complete-public qualifies licensed DejaVu collection faces' --target native ...` | 1/1 passed | ✓ PASS |
| Closed hostile/resource matrix | `moon ... font_qualification_hostile_test.mbt -f 'font qualification executes the closed collection hostile outcome matrix' --target native ...` | 1/1 passed | ✓ PASS |
| Public mutation atomicity | `moon ... font_qualification_hostile_test.mbt -f 'font qualification preserves public collection mutation atomicity' --target native ...` | 1/1 passed | ✓ PASS |
| Mid-operation mutation atomicity | `moon ... collection_wbtest.mbt -f 'collection qualification preserves mid-operation mutation atomicity' --target native ...` | 1/1 passed | ✓ PASS |
| Four-target complete behavior | Current `js/wasm/wasm-gc/native` evidence records | 14 focused gates and 152/152 package tests per target, all `pass: true` | ✓ PASS |

## Static, Policy, and Evidence Checks

| Check | Result | Status |
|---|---|---|
| `Generate-FontQualification.ps1 -Check` | Intake, oracle, matrix, and generated source verification passed | ✓ PASS |
| `Test-FixturePolicy.ps1` | Canonical and negative fixture matrix passed | ✓ PASS |
| `Test-FontQualificationEvidenceBoundary.ps1` | Destructive/ownership boundary matrix passed | ✓ PASS |
| `Assert-FontFoundationPolicy` | Fixtures, schemas, inventories, dependency, interface, source, workflow, and docs passed | ✓ PASS |
| `moon -C modules/mb-font check --target all --frozen` | Exit 0 on all targets | ✓ PASS |
| Comparison read-back validator | All target hashes, record schemas, source identities, equality, and semantic digest revalidated | ✓ PASS |
| Pinned toolchain validator | Exact moon/moonc/moonrun identity passed | ✓ PASS |
| `git diff --check` | Exit 0 | ✓ PASS |

## Probe Execution

No conventional `scripts/**/tests/probe-*.sh` probe is declared. The phase's probes are embedded in the managed runner. Source audit counts 29 runner evidence-negative probes, and the exact-HEAD final lane reported all 29 passing. The separate destructive evidence-boundary probe matrix was independently rerun and passed.

## Anti-Patterns Found

No blocker or warning anti-pattern was found in the 26 files changed from the pre-phase base. The only `TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER` match in implementation is a policy regex that rejects placeholder approvals; it is enforcement code, not debt. The binary TTC naturally matched a text scanner and is not a placeholder.

## Disconfirmation Pass

- **Stale plan wiring pattern:** automated key-link verification missed the hostile corpus link because the plan named `font_qualification_collection_cases`, while the generated accessor is now `font_collection_qualification_cases()` and the hostile file enters through `font_qualification_cases()`. Manual source tracing and passing behavior prove the link is real.
- **Stale historical hashes:** 103-03 summary/review hashes describe earlier pre-review evidence. They were not accepted as proof. The current exact-HEAD evidence was read back and recomputed independently, producing `faec7d...`.
- **Timing is not semantic evidence:** the supplied final lane measurement was 114.328 seconds, safely below the 20-minute CI timeout, but elapsed time is not persisted in `comparison.json`. This does not affect a roadmap/requirement truth; all resulting records and semantic facts are persisted and validated.

## Human Verification Required

None. The phase is deterministic, offline, non-visual, and all required runtime transitions have named passing behavioral tests. Licensed interoperability uses a committed, provenance-tracked fixture and does not depend on an external service.

## Deferred Items

None. The milestone roadmap has no later phase after Phase 103. WOFF decode/admission, CFF execution, variable execution, shaping, hinting, rasterization, publication, and release promotion are explicit out-of-scope future requirements, not failed Phase 103 truths.

## Gaps Summary

No gaps. All merged must-haves, both requirements, all five roadmap criteria, and D-01 through D-15 are verified at the current revision. No override was used, no behavior remains unexercised, and no human decision is required.

---

_Verified: 2026-07-28T07:41:16Z_
_Verifier: the agent (gsd-verifier)_
