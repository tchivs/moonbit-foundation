---
phase: 05-reference-codec-and-release-qualification
verified: 2026-07-17T03:34:00Z
status: passed
score: 12/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 5: Reference Codec and Release Qualification Verification Report

**Phase Goal:** Demonstrate that the three modules work as independently consumable release candidates through a strict bounded reference codec, end-to-end public examples, and reproducible release evidence.
**Verified:** 2026-07-17T03:34:00Z
**Status:** passed
**Re-verification:** No — initial independent verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---:|---|---|---|
| 1 | The public codec interfaces decode and encode the locked strict PPM P6/sRGB subset. | VERIFIED | `PpmDecoder` implements `ImageDecoder` in `decode.mbt`; `PpmEncoder` implements `ImageEncoder` in `encode.mbt`. Independent `moon test --frozen --target all --package moonbit-foundation/mb-image/ppm` passed 23/23 on each of js, wasm, wasm-gc, and native. |
| 2 | Header grammar, decimal arithmetic, header/token/comment ceilings, and chunk independence are bounded before allocation. | VERIFIED | `parser.mbt` is a closed byte-state parser using `@checked.checked_mul`/`checked_add`; `parser_wbtest.mbt` exercises malformed syntax, UInt64 overflow, all four parser ceilings, first-raster-byte isolation, and four deterministic schedules. |
| 3 | Decode validates shape/input/output/work limits, makes one authoritative image allocation, fills it through callback-scoped mutable authority, and requires EOF. | VERIFIED | `decode.mbt` preflights checked pixels/payload/input/work before `OwnedImage::new_operation` at line 292, fills under `with_mut_view` at line 301, and performs the one-byte post-payload probe. Black-box tests cover atomic budget rejection, short/no/failed progress, truncation, trailing data, and concatenation. |
| 4 | Encode validates capability before output and emits only the canonical header plus logical RGB rows with exact progress. | VERIFIED | `encode.mbt` completes capability validation before its first `write_all`; tight and padded views produce identical bytes; tests cover zero/short/failed Writer progress and exact completed counts. |
| 5 | Conformance, adversarial, provenance, round-trip, canonicalization, chunk-schedule, and metamorphic evidence is deterministic. | VERIFIED | `fixtures/ppm/cases.json`, generated vectors, `Generate-PpmVectors.ps1 -Check`, parser schedule tests, semantic/byte round trips, appended-byte rejection, and noncanonical-header canonicalization are wired into the four-target PPM suite and Required reports. |
| 6 | The portable and Native CLI-shaped examples complete public stream-image-transform-stream flows without ambient path policy. | VERIFIED | Portable example calls public decode, `flip_horizontal`, and encode; Native adapter receives Reader, Writer, options, limits, Budget, Diagnostics, and transform. Independent qualification returned `workspace_examples: pass`, `source_isolation: pass`, and the exact honest registry blocker. |
| 7 | Every candidate module has runnable documentation, exact metadata/support, changelog, examples, provenance, and bounded claims. | VERIFIED | Independent `Test-CandidateDocumentation.ps1` passed all positive and negative checks and all twelve README target checks. Candidate docs explicitly reject stable/full-codec/published/LLVM/marketing claims. |
| 8 | Benchmark evidence is public-API, correctness-first, environment-complete, variance-bearing, and non-marketing. | VERIFIED | Eight workloads, seven captured invocations, raw summary hashes, environment/toolchain/hardware identity, corpus/correctness digests, aggregates, and the local-only catastrophic threshold passed the closed benchmark gate and five negative mutations. |
| 9 | All three packages are deterministic across two clean same-HEAD copies. | VERIFIED | Both Required release reports record identical ordered lists, archive inventories, ZIP bytes, SHA-256, sizes, and exact manifests for core/color/image; both clean copies name locked HEAD `a38e7b87eace371f83c393ec6168d3397cb193fd`. |
| 10 | The exact extracted mb-core artifact is independently consumable without `moon.work`. | VERIFIED | Release runner extracts the exact ZIP, injects only the checked public consumer package, and checks/tests it on all four targets; both reports record `mb-core.artifact_consumer=pass`. |
| 11 | Downstream limitations are represented honestly while source independence and publication order remain proven. | VERIFIED | Both reports record `source_isolation=pass`, `artifact_consumer=blocked_unpublished_dependency`, and `registry_resolution=blocked_unpublished_namespace` for mb-color/image, with exact post-publication publish/resolve order core → color → image. No path rewrite or credential access is used. |
| 12 | Phase-close evidence is static-ledger-owned, fail-closed, read-only, and repeatable at one committed baseline. | VERIFIED | Independent two-report verifier passed 19 selectors, 7 reciprocal requirements, 5 artifact contracts, same HEAD, unchanged tracked diff, and canonical digest `b93ca8492242d39b1085c860aceddda1c825493961cd69bdb089e83b6793e9c0`. The 19-rule negative matrix passed under exact owning IDs. |

**Score:** 12/12 truths verified; 0 behavior-unverified.

### Required Artifacts

| Artifact group | Status | Details |
|---|---|---|
| `modules/mb-image/ppm/{ppm,parser,decode,encode}.mbt` | VERIFIED | Substantive implementations, closed imports/targets, public traits wired, no stubs. |
| PPM test/vector/generator/fixture files | VERIFIED | Four-target behavioral tests and byte-reproducible generated evidence. |
| `examples/ppm-portable` and `examples/ppm-native-cli` | VERIFIED | Executed public consumers with exact semantic output and source audit. |
| Candidate READMEs/changelogs/manifests and `docs/release/v0.1-candidate.md` | VERIFIED | Runnable, policy-compared candidate contract. |
| Benchmark module, harness, schema, and baseline | VERIFIED | Closed eight-workload/seven-run evidence contract. |
| Release policy, schema, qualification runner, and consumer fixtures | VERIFIED | Deterministic packages, core artifact consumer, downstream source and registry probes. |
| `release/qualification/v0.1-requirements.json` | VERIFIED | Static closed 19-selector reciprocal map with no dynamic run fields. |
| `required-run-1/report.json` and `required-run-2/report.json` | VERIFIED | Same HEAD, all selectors pass, identical canonical deterministic evidence. |

### Key Link Verification

| From | To | Status | Evidence |
|---|---|---|---|
| `ppm/decode.mbt` | codec + checked + storage + Reader | WIRED | Public trait implementation, checked preflight, `OwnedImage::new_operation`, `with_mut_view`, exact byte reads. |
| `ppm/encode.mbt` | codec + checked + Writer | WIRED | Public trait implementation and `@io.write_all` for header/rows. |
| generated PPM table | canonical fixture source | WIRED | Generator `-Check`, fixture digest gate, and package-local consumers. |
| portable/Native examples | public PPM + ops APIs | WIRED | Both execute decode → `flip_horizontal` → encode with exact output digest. |
| benchmark harness | public benchmark package | WIRED | Pinned native release invocation, correctness-before-timing, closed record validation. |
| release runner | release policy + exact artifacts/consumers | WIRED | Policy-driven package inspection, extracted-core consumer, source isolation, registry probes. |
| Required entrypoint | examples/docs/benchmark/release/read-only gates | WIRED | `Invoke-MoonQuality.ps1` invokes every selector and writes the closed report. |
| static ledger | both Required reports | WIRED | Independent `-VerifyTwoRuns` command validates reciprocal selectors/artifacts and canonical equality. |

### Data-Flow Trace (Level 4)

Not applicable to UI/database rendering. Runtime byte flow was traced directly: Reader → parser → checked descriptor/allocation → mutable raster → image operation → Writer; release data flows from committed policy/fixtures through clean packaging and consumer probes into closed reports.

### Behavioral Spot-Checks

| Behavior | Result | Status |
|---|---|---|
| `moon test --frozen --target all --package moonbit-foundation/mb-image/ppm` | 23/23 on each of four targets | PASS |
| `Test-ReleaseQualificationNegative.ps1` | 19 exact rule-owned negatives rejected | PASS |
| `Test-PublicExamples.ps1 -Example all -Mode qualify` | workspace/source isolation pass; registry blocker exact | PASS |
| `Test-CandidateDocumentation.ps1` | docs/metadata/claims positive and negative matrix pass | PASS |
| `Test-BenchmarkQualification.ps1` | 8 workloads, 7 samples, closed schema and 5 negatives pass | PASS |
| `Test-FixturePolicy.ps1` | identity, digest, containment, provenance matrix pass | PASS |
| `Test-ReleaseQualification.ps1 -StaticLedger ... -VerifyTwoRuns ...` | same HEAD and canonical digest pass | PASS |

### Probe Execution

No `probe-*.sh` migration probes are declared for this phase. The phase-declared executable qualification commands above were run directly.

### Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| WORK-06 | SATISFIED | Independent per-module target/docs/interface/content/DAG selectors, deterministic topological packages, exact core artifact consumer, honest downstream outcomes. |
| QUAL-01 | SATISFIED | Strict bounded decoder/encoder, structured failures, pre-allocation limits, four-target behavioral suite. |
| QUAL-02 | SATISFIED | Portable all-target consumer and injected Native adapter execute public end-to-end flows. |
| QUAL-03 | SATISFIED | Black-box/white-box, conformance, adversarial, limit, progress, chunk, round-trip and metamorphic evidence runs in Required. |
| QUAL-04 | SATISFIED | Runnable docs/examples, matrices, changelogs, exact metadata, provenance and claim negatives. |
| QUAL-05 | SATISFIED | Correctness-gated benchmark baseline with complete environment, seven raw samples, variance and local-only threshold. |
| QUAL-06 | SATISFIED | Closed package/report policy, clean-copy determinism, artifact/source/registry checks, exact blockers, provenance, ordering, and two-run read-only proof. |

No Phase 5 requirement is orphaned: all seven occur in plan frontmatter and in the reciprocal static ledger.

### Anti-Patterns and Disconfirmation Pass

No unresolved `TBD`, `FIXME`, `XXX`, TODO/HACK/placeholder implementation, credential access, publication action, path dependency, ambient codec policy, or fabricated registry pass was found in Phase 5 production changes.

Adversarial checks specifically considered: (1) downstream registry resolution is not a pass, but this is the locked D-22 prepublication result and is fail-closed rather than concealed; (2) the generated schedule-inventory test alone would be weak, but `parser_wbtest.mbt` separately executes four schedules against valid and overflowing inputs; (3) no single test covers every possible EOF-probe backend failure variant, but the public goal's malformed/oversized/progress/trailing behaviors are directly exercised and the implementation propagates non-EOS probe errors. None is a blocker or human-verification item.

### Human Verification Required

None. The phase is headless and all roadmap truths are executable or structurally closed.

### Gaps Summary

No blocking gaps, warnings, deferred Phase 5 items, or overrides. Real registry publication and namespace verification remain intentionally outside v0.1 candidate qualification and are represented as explicit blocked outcomes.

---

_Verified: 2026-07-17T03:34:00Z_
_Verifier: independent gsd-verifier agent_
