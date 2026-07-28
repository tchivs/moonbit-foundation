# Phase 107: Hostile, Licensed, and Four-Target Qualification - Research

**Researched:** 2026-07-29  
**Domain:** Static CFF1 fixture qualification, hostile evidence, four-target conformance, provenance, and native observation-only benchmarking  
**Confidence:** HIGH for repository architecture and phase boundaries; MEDIUM for licensed specimen and host-oracle selection until Plan 107-01 completes its fail-closed intake

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Scope and closure

- **D-01:** Phase 107 is qualification-first. Preserve the exact 85-line public interface, the sole `tchivs/mb-core@0.1.0` runtime dependency, and all verified Phase 104-106 runtime semantics. Do not add a parser, CFF profile, public CFF query, public limit, or target-specific runtime path.
- **D-02:** Close CFF-06 through canonical fixtures, independent oracles, public workflow evidence, hostile/atomicity evidence, compatibility locks, a native observation-only baseline, and exactly four equal target records. Runtime changes require a failing canonical qualification case and a focused regression test.

### Generated name-keyed and CID vectors

- **D-03:** Add a separate ordered `fixtures/font/cff-qualification-cases.json` as the canonical generated corpus. Produce deterministic Apache-2.0 name-keyed and multi-FD CID CFF1 OTF vectors offline, then mirror their bytes and closed expected facts into test-private MoonBit through the existing font fixture generator.
- **D-04:** Hand-derived expected facts are authoritative for generated vectors: Unicode-to-GID mapping, selected FD/local environment, face-local `hmtx` metrics, conservative bounds, and exact ordered `MoveTo`/`LineTo`/`CubicTo`/`Close` commands. Production MoonBit and a host library must never be the sole oracle for fixtures they consume.
- **D-05:** Exercise every canonical generated face through standalone `Font` and selected TTC/OTC public workflows. The collection corpus must include a shared CFF table with deliberately distinct face-local cmap/hmtx/kern facts so table-root authority and public parity are both observable.
- **D-06:** Keep existing focused builders as diagnostic sources, but promote only a minimal closed qualification inventory. Generated records and test identities are versioned and ordered; schema drift, missing cases, reordered cases, or unexpected fields fail closed.

### Licensed Latin/CJK evidence and independent oracles

- **D-07:** Use one official redistributable static CFF1 Latin OTF from the Source Sans/Source Serif family and one official redistributable static CID-keyed CFF1 Source Han Serif OTF or deterministic subset. Intake must prove the exact profile before commitment; the CJK artifact must retain multiple FDs, FDSelect coverage, distinct local Subrs, and at least one fixed high-GID outline. If an official candidate fails these facts, research selects the nearest official artifact that satisfies them rather than weakening coverage.
- **D-08:** Treat any subset or repack as an externally derived artifact under its upstream license. Freeze official URL/repository revision or release tag, retrieval date, source length and SHA-256, derivative recipe and command, generator identity/digest, derivative length and SHA-256, license expression, notice path/digest, author/date, redistribution status, and expected use. Never relabel licensed or derived bytes as Apache-2.0 project-generated content. — **Reversibility:** costly; changing either specimen invalidates provenance, generated mirrors, oracles, policy allowlists, baselines, and canonical evidence.
- **D-09:** Build a closed host-only oracle path that never imports or invokes `tchivs/mb-font`. Pin exact semantic tools and executable/package digests after research verifies availability; use two independent CFF readers where practical for mappings, FD selection, metrics, bounds, and cubic commands, and use OTS only as structural acceptance evidence. Commit bounded oracle facts before portable target runs.
- **D-10:** Runtime tests perform no repository-file, network, subprocess, FFI, or ambient host-tool access. Licensed payload bytes are embedded once in generated test-private source and reconstructed portably when a standalone/collection wrapper is needed.

### Hostile, mutation, and static-glyf compatibility evidence

- **D-11:** Define one closed CFF hostile corpus with ordered structural, Type 2 program, semantic-limit, caller/ancestor resource, mutation, and multi-fault precedence groups. Cover Header/INDEX/DICT/String/CharStrings/Private/Subrs/charset/Encoding/FDArray/FDSelect/table ranges; stack/arity/subroutine/hint/mask/transient/random/flex/termination behavior; and exact/one-short boundaries for all applicable limits.
- **D-12:** Every hostile record freezes complete structured error fields, smallest failing GID when applicable, publication state, and all eight caller/ancestor budget dimensions before and after. Failures publish no partial `Font`, collection face, retained facts, or `Path2` and charge no uncommitted transaction.
- **D-13:** Preserve deterministic State → Resource → Capability → Data precedence. Use public black-box mutation evidence before/after operations and retain narrow test-private hooks only for otherwise unobservable admission, selected-face, Type 2 fetch, staged-path, and final-commit windows.
- **D-14:** Freeze the Phase 106 static-`glyf` standalone and collection fingerprint by semantic content: mappings, metrics, kerning, paths, errors, mutation ordering, and exact resource facts. Do not freeze a brittle aggregate test-count constant.

### Four-target evidence and policy

- **D-15:** Advance the existing font qualification lane to a fresh closed v3 workflow/schema identity and fresh managed evidence directory. Do not reuse v2 cleanup ownership. Each run produces exactly four ordered isolated records: `js`, `wasm`, `wasm-gc`, and `native`.
- **D-16:** Normalize only top-level `target` and `runner`. All generated name/CID facts, licensed Latin/CJK facts, oracle/tool identities and digests, cubic fingerprints, hostile/resource/mutation outcomes, static-glyf baseline, fixture identities, exact public interface, dependency/source inventories, exact MoonBit toolchain, focused assertion identities, and pass facts remain byte-canonical equality-bearing payload.
- **D-17:** Extend `Invoke-FontQualification.ps1`, its evidence-boundary negatives, policy, and the existing CI job rather than creating a competing correctness lane. Add fail-closed probes for missing/order/schema drift, GID/FD or cubic divergence, error/budget divergence, glyf drift, fixture/oracle drift, API/dependency expansion, target-root contamination, and unauthorized toolchain substitution.
- **D-18:** Refresh the stale policy inventories to the live Phase 106 production/test surface plus Phase 107 additions. Preserve pure MoonBit runtime, no ambient I/O/FFI, the five current package imports, and the exact public interface while updating documentation and module descriptions to acknowledge qualified static CFF1 support.

### Performance evidence

- **D-19:** Keep timing separate from four-target semantic equality. All four targets execute fixed benchmark workloads only to prove equal correctness digests; timings are captured only from native release builds and are never compared across backends.
- **D-20:** Add declared immutable workloads for Latin full admission, CJK full admission, a fixed Latin outline batch, and a fixed high-GID multi-FD CJK outline batch; collection open/open-face may be included only when it reuses those specimens without diluting the four mandatory workloads.
- **D-21:** Follow the existing native benchmark evidence pattern: exact command/workload order, immutable fixture/workload/correctness digests, exact host and toolchain facts, one excluded warmup, seven retained captures, and mean/median/sample standard deviation/min/max/coefficient of variation.
- **D-22:** The baseline is observation-only. It sets no CI threshold, regression verdict, cross-library ranking, or marketing claim. A read-only clean-worktree audit must reconstruct and verify the committed record.

### Sequencing

- **D-23:** Plan strict dependent slices: (1) canonical generated vectors plus licensed specimens, provenance, oracle, and generated mirror; (2) public workflows, hostile/mutation matrix, and static-glyf locks; (3) v3 four-target evidence, policy/CI/docs, and native baseline. Schema consumers must not be parallelized before fixture and assertion identities are frozen.

### the agent's Discretion

- Exact closed-schema field names and case ordering, provided validation is exact, deterministic, and fail closed.
- Exact upstream Source-family release and host-oracle versions, provided official provenance, static CFF1/CID facts, redistribution, and pinned integrity are verified before bytes are committed.
- Whether generated CFF bytes extend `generated_font_qualification_test.mbt` or use a dedicated generated test file, provided licensed bytes are embedded once and policy owns the generated identity.
- Whether the existing FontQualification CI timeout needs a minimal increase, but only after measuring the complete final lane.

### Deferred Ideas (OUT OF SCOPE)

- CFF2/variation execution, deprecated seac composition, WOFF1/WOFF2, shaping/bidi, hint rendering, rasterization, color/bitmap glyphs, authoring, discovery, FFI, and ambient I/O remain outside v0.34.
- Performance thresholds, cross-library comparisons, release blocking based on timing, and registry publication policy changes remain future work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CFF-06 | Reproducible generated, hostile, licensed, compatibility, performance, public-workflow, oracle, and exactly-four-target evidence. | The intake gate, canonical matrices, v3 schema, policy refresh, and native baseline below give the planner three executable dependent slices. [VERIFIED: `.planning/REQUIREMENTS.md`] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep algorithms and shared models MoonBit-native; host readers certify fixtures only and never enter runtime dependencies. [VERIFIED: `AGENTS.md`; `.planning/phases/107-hostile-licensed-and-four-target-qualification/107-CONTEXT.md` D-01/D-09]
- Preserve native as the performance target and the four portable targets as equal semantic conformance targets. [VERIFIED: `AGENTS.md`; 107-CONTEXT D-15/D-19]
- Keep public dependencies acyclic and explicit, preserve SemVer-facing API stability, deterministic headless automation, reproducible benchmarks, and RFC governance. [VERIFIED: `AGENTS.md`]
- Preserve small/isolated/replaceable FFI policy by keeping Phase 107 runtime and target tests free of FFI and ambient I/O. [VERIFIED: `AGENTS.md`; 107-CONTEXT D-10/D-18]
- This research is the delegated output of the required GSD planning workflow; no implementation file is changed here. [VERIFIED: `AGENTS.md`]

## Summary

Phase 107 should close evidence around the implementation verified in Phases 104-106, not extend that implementation. Static CFF1 structure/keying and atomic admission, bounded Type 2 execution and retained metrics, and exact cubic standalone/collection publication already passed their phase gates. [VERIFIED: `104-VERIFICATION.md`; `105-VERIFICATION.md`; `106-VERIFICATION.md`]

Reuse the shipped Phase 103 qualification architecture: canonical offline inputs feed an independent oracle and one portable generated mirror; named public and narrow white-box assertions feed a closed isolated runner; the runner emits four ordered records and removes only `target` and `runner` for equality. Reuse Phase 94's benchmark architecture separately for native timing. [VERIFIED: Phase 103 `103-VERIFICATION.md`; `scripts/quality/Invoke-FontQualification.ps1`; `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1`]

The licensed specimens are resolved. The Latin specimen is `SourceSans3-Regular.otf` from Adobe's official `OTF-source-sans-3.052R.zip`: 334,924 bytes, SHA-256 `08df266400933d3178d081a45f94a08814c3e55b4b7dd2e0ff69cb1329f13ab6`, `OTTO` with `CFF ` 1.0, name-keyed (`ROS` absent), 2,478 glyphs, 648 local Subrs, and 738 global Subrs. The official release archive is 2,387,997 bytes with SHA-256 `a4ebbdea20b08ccbd7bf3665a9462454eefdd01d9a6307129d3b3d4672981074`; the retained tag license is 4,579 bytes with SHA-256 `89ad2c4f66dd29127527493e729c31e731f111cf10faf5774c3db9275ed0c22c`. [CITED: https://github.com/adobe-fonts/source-sans/releases/tag/3.052R] [CITED: https://raw.githubusercontent.com/adobe-fonts/source-sans/3.052R/LICENSE.md] [VERIFIED: independent local fontTools 4.63.0 inspection and SHA-256, 2026-07-29]

The CJK specimen is `SubsetOTF/JP/SourceHanSerifJP-Regular.otf` from Adobe's official `12_SourceHanSerifJP.zip` at tag `2.003R`: 6,210,796 bytes, SHA-256 `e5f502bb193c28829895b098498f0f9dd8f658c760b0f83656ad41c1137a8785`, `OTTO` with `CFF ` 1.0, CID-keyed `ROS=["Adobe","Identity",0]`, 17,923 glyphs, 18 FDArray entries, all FDs 0-17 used by FDSelect, distinct local-Subr counts `[16,46,7,2004,39,131,0,1,7,0,0,205,21626,237,389,17,0,231]`, and 1,599 global Subrs. Fixed high GID 17,922 (`cid65390`) uses FD 17 and has a non-empty 136-token decompiled Type 2 program. The official archive is 36,831,708 bytes with SHA-256 `c5a3bbc213980cea04932457899c9fc2da4784d3d1d7cae469c41909dd112230`; `LICENSE.txt` is 4,463 bytes with SHA-256 `9ff5bb567e1b92c801fc1069e5fbf992ff8efccacb9db94e5959a5b3ba9bb903`. The committed specimen is the exact upstream OTF, not a new subset derivative. [CITED: https://github.com/adobe-fonts/source-han-serif/releases/tag/2.003R] [CITED: https://github.com/adobe-fonts/source-han-serif/blob/2.003R/LICENSE.txt] [VERIFIED: independent local fontTools 4.63.0 inspection and SHA-256, 2026-07-29]

**Primary recommendation:** preserve the three strict D-23 slices but implement them as five smaller dependent plans: reader/generated-vector contracts; atomic licensed intake/generated mirror; public/hostile/glyf evidence; v3 correctness/policy/CI/docs; and the separate native baseline. This preserves producer-before-consumer ordering while keeping executor context and task-commit boundaries sound. [VERIFIED: 107-CONTEXT D-23; plan-checker stall resolution, 2026-07-29]

## Architectural Responsibility Map

| Capability | Primary tier | Secondary tier | Rationale |
|------------|--------------|----------------|-----------|
| Licensed intake and provenance | Offline host tooling | Repository fixtures | Network/tool access ends before committed facts reach target tests. [VERIFIED: 107-CONTEXT D-08-D-10] |
| Generated name/CID vectors | Offline generator | Test-private MoonBit | Hand-derived facts remain authoritative; portable tests reconstruct bytes. [VERIFIED: 107-CONTEXT D-03-D-06] |
| CFF admission/VM/path behavior | Portable MoonBit runtime | — | Existing code is the system under test and must not gain target-specific paths. [VERIFIED: 104-106 verification; 107-CONTEXT D-01] |
| Semantic oracle | Two host-only readers | OTS structural acceptance | Oracle facts are committed before portable runs and never import `mb-font`. [VERIFIED: 107-CONTEXT D-09] |
| Public/hostile qualification | MoonBit tests | PowerShell runner | Tests produce semantic facts; the runner validates and compares them. [VERIFIED: Phase 103 analog; current qualification files] |
| v3 ownership/policy/CI | PowerShell policy tools | GitHub Actions | Extend the existing lane and managed-directory boundary. [VERIFIED: 107-CONTEXT D-15-D-18] |
| Timing | Native release benchmark | Read-only audit/doc | Timing is not part of cross-target semantic equality. [VERIFIED: 107-CONTEXT D-19-D-22] |

## Standard Stack

### Core

| Tool/seam | Version policy | Purpose |
|-----------|----------------|---------|
| MoonBit `moon`/`moonc`/`moonrun` | Exact versions already pinned by `policy/foundation.json`; records must reproduce them exactly. | Four isolated target runs and native release benchmark. [VERIFIED: `policy/foundation.json`; current runner] |
| PowerShell | Existing repository-supported runtime; record executable identity where used by evidence. | Generator, closed JSON, evidence ownership, comparison, and audit. [VERIFIED: current scripts] |
| Host semantic reader A | `fontTools==4.63.0`, CPython 3.12 Windows wheel `fonttools-4.63.0-cp312-cp312-win_amd64.whl`, 2,343,211 bytes, SHA-256 `59ac449f8cca9b4ffa08d2e7bbadad87ce710d69d1eda5c3c1ce579baa987272`. | `TTFont`, CFF structures, and recording pens emit one closed mapping/profile/keying/FD/metric/bounds/cubic projection. [VERIFIED: official package artifact independently downloaded and hashed, 2026-07-29] |
| Host semantic reader B | `afdko==5.0.1`, CPython 3.12 Windows wheel `afdko-5.0.1-cp312-cp312-win_amd64.whl`, 2,721,468 bytes, SHA-256 `c5aca7e9c8ed8ad3f411ba9e60cdcc5e820ca2326efc8332168fec995600c15a`; use AFDKO `tx` through a dedicated adapter. | A distinct Adobe CFF implementation family emits the same closed projection without importing reader A or `mb-font`; anti-alias/source scans and output disagreement fail closed. [VERIFIED: official package artifact independently downloaded and hashed, 2026-07-29] |
| OTS | Source tag `v9.2.0`; controlled build/executable digest is recorded by intake. | Structural acceptance only; never semantic truth and never a substitute for either semantic reader. [CITED: https://github.com/khaledhosny/ots/blob/v9.2.0/README.md] |

The semantic readers are fixed to fontTools 4.63.0 and AFDKO 5.0.1. Their adapters must use a shared closed output schema but remain implementation-independent; package/source/executable identity, forbidden-import scans, anti-alias checks, and exact result agreement are part of the intake gate. OTS v9.2.0 remains structural-only. FreeType is not a required oracle dependency for this milestone. [CITED: https://fonttools.readthedocs.io/en/latest/ttLib/ttFont.html] [CITED: https://fonttools.readthedocs.io/en/latest/pens/recordingPen.html] [CITED: https://github.com/adobe-type-tools/afdko] [CITED: https://github.com/khaledhosny/ots/blob/v9.2.0/README.md]

## Package Legitimacy Audit

No external runtime package may be added; `tchivs/mb-core@0.1.0` remains the sole runtime dependency. [VERIFIED: 107-CONTEXT D-01]

Host-oracle package selection is resolved to fontTools 4.63.0 and AFDKO 5.0.1 plus OTS v9.2.0 structural validation. Before promotion, the implementation must still verify official source identity, inspect packaging/scripts, reproduce the locked wheel/archive hashes above, hash the invoked executables/adapters, and reject any forbidden shared-backend or `mb-font` dependency. A mismatch blocks intake; it does not trigger floating-version fallback. [VERIFIED: 107-CONTEXT D-07-D-09; local package artifact audit, 2026-07-29]

**Packages removed due to SLOP:** none evaluated in this constrained research.  
**Packages flagged SUS:** none evaluated; the planner must not infer approval.

## Exact Existing Assets and Reuse Points

| File / symbol | Exact reuse |
|---------------|-------------|
| `scripts/fixtures/Generate-FontQualification.ps1` — `Get-FontQualificationSha256`, `Assert-ExactBytesIdentity` | Freeze every source, derivative, license, oracle, corpus, and generated-source length/SHA. [VERIFIED: current file] |
| Same — `ConvertTo-StableJson`, `Assert-ManifestRecord`, `Update-OrCheckManifest`, `Assert-FontQualificationOrderedKeys` | Enforce LF/UTF-8, exact key order, exact manifest lineage, and `-Check` drift. [VERIFIED: current file] |
| Same — `Read-FontQualificationSfntOracle`, `Read-FontQualificationTtcOracle` | Extend the host-only independent reader boundary; do not call production MoonBit. [VERIFIED: current file] |
| Same — `Write-FontQualificationGeneratedSource`, `Test-FontQualificationInputs` | Embed each licensed payload once, reconstruct wrappers portably, and verify generated output without mutation. [VERIFIED: current file] |
| `cff_name_keyed_fixture_wbtest.mbt` / `cff_cid_fixture_wbtest.mbt` | Promote minimal name-keyed charset/Encoding and CID FDSelect/FD/private/Subrs builders into canonical generated vectors. [VERIFIED: current tests] |
| `cff_hostile_fixture_wbtest.mbt` | Reuse atomic structural, exact/one-short, smallest-GID, caller authority, and precedence helpers. [VERIFIED: current tests] |
| `cff_type2_fixture_wbtest.mbt`, `cff_type2_wbtest.mbt`, `cff_type2_bounds_wbtest.mbt`, `cff_type2_path_wbtest.mbt` | Source the closed Type 2, limit, retained-bounds, and exact-cubic qualification cases. [VERIFIED: current tests] |
| `font_qualification_test.mbt` | Extend the named public qualification lane for generated/licensed standalone and selected collection workflows. [VERIFIED: current file] |
| `font_qualification_hostile_test.mbt` | Extend the closed public hostile and mutation record dispatcher. [VERIFIED: current file] |
| `font_test.mbt`, `font_wbtest.mbt`, `collection_test.mbt`, `collection_wbtest.mbt` | Reuse existing public fingerprints and narrow admission/selected-face/fetch/stage/commit mutation hooks. [VERIFIED: current files; `106-VERIFICATION.md`] |
| `scripts/quality/Invoke-FontQualification.ps1` — `Assert-FontQualificationEvidenceRecord`, `Get-FontQualificationSemanticPayload`, `Compare-FontQualificationEvidence` | Advance closed v2 records to v3 while preserving exact target order and target/runner-only normalization. [VERIFIED: current file] |
| Same — managed-root functions `Resolve-*`, `Assert-*Marker`, `Clear-*Files` | Create a fresh v3 owner and never authorize deletion from a v2 marker. [VERIFIED: current file] |
| `Test-FontQualificationEvidenceBoundary.ps1` | Extend version, containment, unrelated-file, link/reparse, write-swap, schema, and divergence negatives. [VERIFIED: current file] |
| `Assert-Policy.ps1`, `policy/foundation.json` | Refresh exact production/test inventories and keep 85 interface lines, five imports, one dependency, four targets, no FFI/I/O. [VERIFIED: current files; 107-CONTEXT D-18] |
| `.github/workflows/quality.yml` | Keep the single `font-qualification` job; update its evidence path/artifact identity to v3 only after final measurement. [VERIFIED: current workflow; 107-CONTEXT D-17] |
| `Invoke-SvgNativeBenchmarkBaseline.ps1`, `Test-BenchmarkQualification.ps1` | Reuse `Assert-CleanWorktree`, workload/correctness digests, one warmup + seven captures, `Get-Aggregate`, rendered evidence, and read-only audit. [VERIFIED: current scripts] |

## Architecture Patterns

### System Architecture Diagram

```text
official Source candidates ──> 107-01 fail-closed profile/license/hash gate
generated name/CID recipes ──> hand-derived closed expected facts
                                  |
                 two independent host readers + OTS structure
                                  |
              canonical JSON/binaries/oracles/manifest identities
                                  |
              one generated test-private MoonBit byte/fact mirror
                                  |
        public Font + selected FontCollection + narrow wb hooks
                                  |
         closed public/hostile/glyf/benchmark-correctness facts
                                  |
             Invoke-FontQualification.ps1 v3 runner
                    /       /         /          \
                   js     wasm     wasm-gc      native
                    \       \         \          /
            remove only target/runner; require byte equality
                                  |
             v3 comparison + policy/CI evidence

native correctness digest ──> separate release benchmark ──> 1+7 observation record
```

The host/target boundary is hard: portable tests consume committed bytes and facts only; no network, repository-file read, subprocess, host reader, or FFI is reachable from MoonBit runtime tests. [VERIFIED: 107-CONTEXT D-09/D-10]

### Recommended Project Structure

```text
fixtures/font/
├── cff-qualification-cases.json
└── <locked-source-specimen-id>/       # exact binaries, notices, oracle/provenance
scripts/fixtures/
└── Generate-FontQualification.ps1     # extend; keep one intake/check owner
modules/mb-font/font/
├── generated_font_qualification_test.mbt
├── font_qualification_test.mbt
└── font_qualification_hostile_test.mbt
scripts/quality/
├── Invoke-FontQualification.ps1
├── Test-FontQualificationEvidenceBoundary.ps1
└── Test-BenchmarkQualification.ps1
scripts/benchmarks/
└── Invoke-CffNativeBenchmarkBaseline.ps1
docs/benchmarks/
└── mb-font-cff-native-release-baseline.md
```

The exact licensed directory/file names are outputs of the 107-01 intake decision, not inputs to it. [VERIFIED: 107-CONTEXT D-07/D-08]

## Closed Canonical Inventories

### Generated/public inventory

Freeze ordered IDs for: name-keyed standalone; name-keyed selected collection; multi-FD CID standalone; multi-FD CID selected collection; licensed Latin standalone; licensed Latin selected collection; licensed CJK standalone; licensed CJK selected collection; and static-glyf standalone/collection compatibility. Each record carries mapping, GID, FD/local environment when applicable, `hmtx`, bounds, kerning/common facts where applicable, exact ordered path commands, error/publication state, and resource facts. [VERIFIED: 107-CONTEXT D-03-D-06/D-14]

### Hostile matrix

Use this exact ordered group sequence; IDs inside each group are frozen lexically after 107-01 schemas settle. [VERIFIED: 107-CONTEXT D-06/D-11-D-13]

| Group | Mandatory closed cases |
|-------|------------------------|
| `structural` | Header major/minor/hdrSize/offSize; Name/Top/String/GlobalSubrs/CharStrings INDEX count/offSize/offset/order/range/cardinality; DICT truncated number/operand/duplicate/unknown/capability; table directory/range/overlap; charset formats/predefined/custom/range/cardinality; Encoding formats/supplements/duplicate/range/cardinality; Private size/offset; local/global Subrs range; ROS/CID keying; FDArray empty/invalid/unused-FD validation; FDSelect format/range/sentinel/coverage. |
| `type2-program` | Operand stack under/overflow; operator arity; number decode; arithmetic/logical/storage; width framing; move/line/curve/flex; stem/hint count; `hintmask`/`cntrmask` bytes; transient index; local/global subr bias/call/return/depth/recursion; reserved/unsupported operator; deterministic `random`; root/subroutine termination; trailing bytes. |
| `semantic-limit` | Exact and one-short source/table/glyph/name/cmap/kern/outline/CFF structural/descriptor/subr/program/stack/stem/command/point/allocation/work limits that apply through existing private derivation. |
| `resource` | Caller and every ancestor exact/one-short checks for bytes, allocations, maximum allocation size, width, height, pixels, depth, and work; before/after snapshots always include all eight fields. |
| `mutation` | Public before/after admission and outline; private admission, selected-face, Type 2 fetch, staged-path, and final-commit windows; standalone and collection where the window exists. |
| `multi-fault-precedence` | State+Resource, Resource+Capability, Capability+Data, State+Data, and smallest-failing-GID ordering; expected precedence is State → Resource → Capability → Data. |

Every failure record must include exact error category/code/operation/payload/context, smallest failing GID or explicit absence, publication flags for `Font`/face/retained facts/`Path2`, and caller/ancestor before/after budgets. [VERIFIED: 107-CONTEXT D-12]

## v3 Four-Target Evidence Contract

- Proposed identities: workflow `font-complete-public-v3`, schema `3.0.0`, marker `mnf-font-qualification-evidence/v3`, local root `artifacts/release-qualification/font-v3`, CI root `artifacts/release-qualification/ci-font-v3`. These are new owners and must reject v2 markers. [VERIFIED: 107-CONTEXT D-15; Phase 103 ownership pattern]
- Exact target order is `js`, `wasm`, `wasm-gc`, `native`; each target gets an isolated target root and one independently validated record. [VERIFIED: 107-CONTEXT D-15]
- Proposed top-level key order: `schema_version`, `workflow_id`, `target`, `toolchain`, `fixtures`, `oracle_facts`, `generated_cff_facts`, `licensed_cff_facts`, `public_workflow_facts`, `cff_hostile_outcomes`, `mutation_atomicity_facts`, `glyf_compatibility_facts`, `benchmark_correctness_facts`, `boundary_facts`, `dependency_facts`, `focused_assertions`, `runner`, `pass`. [VERIFIED: 107-CONTEXT D-16/D-17; Phase 103 closed-record pattern]
- Semantic comparison constructs an explicit ordered object containing every key except top-level `target` and `runner`; it must not recursively delete volatile-looking fields. [VERIFIED: 107-CONTEXT D-16; current `Get-FontQualificationSemanticPayload`]
- `comparison.json` closes schema/workflow, normalization list exactly `["target","runner"]`, ordered targets, record SHA-256 values, one semantic SHA-256, and `equal: true`. [VERIFIED: Phase 103/current runner pattern]
- Negative probes mutate one fact at a time: target count/order/name; key count/order/unknown field; schema/workflow/marker; fixture/oracle/tool digest; GID/FD/local Subrs; cubic command; error/budget/publication; glyf fingerprint; API/source/dependency/import/toolchain; target-root containment/link; focused assertion identity; pass state; semantic divergence. [VERIFIED: 107-CONTEXT D-17]

## Policy Refresh

`policy/foundation.json` currently lists a pre-CFF font source surface, while the live package contains the Phase 104-106 `cff_*.mbt` production and white-box files. Refresh only after 107-01/02 freeze their generated and test files, then lock the exact actual list rather than a count. [VERIFIED: `policy/foundation.json`; `modules/mb-font/font`; 107-CONTEXT D-18/D-23]

The refreshed policy must retain the exact 85-line public interface, module dependency `tchivs/mb-core@0.1.0`, supported targets `+js+wasm+wasm-gc+native`, and exactly these five imports: `budget`, `bytes`, `checked`, `error`, and `math`. It must reject production/test file drift, public CFF symbols/limits, FFI, filesystem/network/subprocess/GUI access, target-specific runtime branches, CFF2/variation/WOFF/shaping/hint/raster additions, unowned fixtures, and workflow/toolchain drift. [VERIFIED: `modules/mb-font/font/moon.pkg`; `policy/foundation.json`; 107-CONTEXT D-01/D-18]

Update the existing module README/description/changelog and licensing policy/manifest facts to say “qualified static CFF1” without declaring CFF2, shaping, rendering, performance superiority, publication, or new stability policy. [VERIFIED: 107-CONTEXT D-01/D-08/D-18/D-22]

## Native Observation-Only Benchmark

The four targets run correctness workloads, not comparable timing: Latin full admission, CJK full admission, fixed Latin outline batch, and fixed non-empty high-GID multi-FD CJK outline batch. Freeze workload order, GID lists, fixture SHA, workload SHA, and correctness SHA in equality-bearing v3 records. [VERIFIED: 107-CONTEXT D-19/D-20]

Timing is a separate native release artifact. Copy the Phase 94 lifecycle: require clean worktree; exact command/target/release/frozen mode; exact git/toolchain/host facts; one successful warmup retained but excluded; seven retained invocations; per-workload mean, median, sample standard deviation, minimum, maximum, and coefficient of variation; raw output digests; and a read-only audit that reconstructs all non-timing identities and statistics without running MoonBit or rewriting the document. [VERIFIED: `Invoke-SvgNativeBenchmarkBaseline.ps1`; 107-CONTEXT D-21/D-22]

Do not add thresholds, regression verdicts, cross-backend timing, cross-library ranking, or marketing language. [VERIFIED: 107-CONTEXT D-19/D-22]

## Don't Hand-Roll

| Problem | Do not build | Use instead |
|---------|--------------|-------------|
| Runtime fixture acquisition | MoonBit file/network/process/FFI loader | One generated test-private byte mirror. [VERIFIED: 107-CONTEXT D-10] |
| Self-oracle | Expected JSON copied from `mb-font` output | Hand-derived generated facts plus two independent host readers. [VERIFIED: 107-CONTEXT D-04/D-09] |
| Generic schema equality | Hashtable equality or recursive ignored fields | Exact ordered keys and explicit semantic projection. [VERIFIED: 107-CONTEXT D-06/D-16] |
| Evidence cleanup | Recursive deletion of caller paths | Existing marker/containment/link/known-file ownership functions with fresh v3 identity. [VERIFIED: current runner/boundary] |
| Mutation timing | Threads, sleeps, backend timing | Existing deterministic test-private transition hooks. [VERIFIED: 106-VERIFICATION; 107-CONTEXT D-13] |
| Benchmark statistics/audit | New statistics format | Phase 94 `Get-Aggregate` and rendered read-only audit pattern. [VERIFIED: benchmark analog] |
| License inference | URL/hash alone as redistribution permission | Manifest, notice, license, parent/derivative lineage, and confirmed redistribution. [VERIFIED: `docs/policies/licensing-and-fixtures.md`] |

## Common Pitfalls

1. **Finalizing the Adobe candidates from prior inspection.** A filename or downloaded release is not the frozen profile/hash/license record. Stop 107-01 unless both exact profile gates pass. [VERIFIED: 107-CONTEXT D-07/D-08]
2. **Subsetting away the qualification property.** A smaller CJK derivative is invalid if it loses multiple used FDs, FDSelect ranges, distinct local Subrs, or the selected non-empty high GID. [VERIFIED: 107-CONTEXT D-07]
3. **Letting one reader define truth.** Reader disagreement is a blocking intake failure; OTS acceptance is structural only. [VERIFIED: 107-CONTEXT D-09]
4. **Duplicating licensed bytes.** Embed once and build standalone/collection wrappers over that representation. [VERIFIED: 107-CONTEXT D-10]
5. **Recording only the error.** Atomicity evidence is incomplete without publication flags and all eight caller/ancestor before/after dimensions. [VERIFIED: 107-CONTEXT D-12]
6. **Using a total-test constant.** Freeze named focused assertions and semantic fingerprints; allow unrelated legitimate tests. [VERIFIED: 107-CONTEXT D-14]
7. **Allowing v3 to clean v2.** A version mismatch must preserve every existing file and fail before deletion. [VERIFIED: 107-CONTEXT D-15]
8. **Refreshing policy before files settle.** Generate final source/test identities in 107-01/02, then write exact inventories in 107-03. [VERIFIED: 107-CONTEXT D-23]
9. **Benchmarking glyph discovery.** Use fixed GIDs proven non-empty and cross-FD; benchmark only admission/outline work. [VERIFIED: 107-CONTEXT D-20]
10. **Fixing runtime without a canonical failure.** Require the failing qualification vector plus a focused regression, then make the smallest non-public fix. [VERIFIED: 107-CONTEXT D-02]

## Code Examples

### Fail-closed profile gate shape

```powershell
$expectedKeys = @(
  'id','origin','release','source_url','source_length','source_sha256',
  'cff_version','keying','fd_select','used_fds','local_subrs_sha256',
  'high_gid','notice_path','notice_sha256','redistribution_status'
)
Assert-FontQualificationOrderedKeys $record $expectedKeys 'licensed intake'
Assert-ExactBytesIdentity $record.id $bytes $record.source_length $record.source_sha256
if ($record.cff_version -cne 'CFF1' -or $record.redistribution_status -cne 'confirmed') {
  throw 'licensed specimen failed closed intake'
}
```

This is a planning pattern over existing helpers; final fields and values must be frozen only after independent 107-01 inspection. [VERIFIED: current generator helpers; 107-CONTEXT D-07-D-09]

### Explicit semantic projection

```powershell
$semantic = [ordered]@{}
foreach ($key in $RecordKeys) {
  if ($key -cnotin @('target', 'runner')) {
    $semantic[$key] = $record[$key]
  }
}
$canonical = ConvertTo-FontQualificationJson $semantic -Compress
```

The implementation should extend current `Get-FontQualificationSemanticPayload`, not introduce a recursive deletion helper. [VERIFIED: current runner; 107-CONTEXT D-16]

## Validation Architecture

`workflow.nyquist_validation` is explicitly `false`; this section is included because the research assignment requires implementation-facing validation guidance, not because the workflow toggle changed. [VERIFIED: `.planning/config.json`]

| Requirement behavior | Test type | Exact seam | Gap |
|----------------------|-----------|------------|-----|
| Generated name/CID standalone + collection | Public black-box | `font_qualification_test.mbt` + generated mirror | Canonical ordered CFF corpus and facts must be added in 107-01/02. [VERIFIED: current tests] |
| Licensed Latin/CJK profile and semantics | Offline oracle + public black-box | generator/oracle + public qualification | Exact specimens/tools/hashes remain a blocking 107-01 gap. [VERIFIED: 107-CONTEXT D-07-D-10] |
| Structural/Type 2/limits | White-box + public closed record | existing `cff_*_wbtest.mbt` + hostile dispatcher | Diagnostic cases exist; minimal closed promotion remains. [VERIFIED: current tests] |
| Mutation/resource/precedence | Public + narrow white-box | hostile dispatcher, `font_wbtest.mbt`, `collection_wbtest.mbt` | Complete ordered eight-field records remain. [VERIFIED: current tests; 107-CONTEXT D-12/D-13] |
| Static-glyf compatibility | Public black-box | existing font/collection qualification facts | Convert Phase 106 behavior into one equality-bearing semantic fingerprint. [VERIFIED: 106-VERIFICATION] |
| Four equal targets | Integration/evidence | v3 runner + boundary negatives | v2 exists; v3 identity/schema/root must be new. [VERIFIED: current runner; 107-CONTEXT D-15] |
| Native baseline | Benchmark/read-only audit | Phase 94 script/audit pattern | CFF-specific workload runner and document are missing. [VERIFIED: current benchmark files] |

**Sampling:** each 107-01 task runs generator/oracle `-Check`; each 107-02 task runs its named focused assertion and package-local target check; 107-03 runs policy/boundary negatives, exactly four isolated records, semantic comparison, and the separate clean-worktree native audit. [VERIFIED: Phase 103/94 patterns; 107-CONTEXT D-17/D-22]

**Phase gate:** exactly four ordered records validate and compare equal after removing only `target`/`runner`; fixture/oracle/source/toolchain identities are exact; the 85-line API, sole dependency, five imports, pure runtime, static-glyf facts, and observation-only baseline audit remain closed. [VERIFIED: 107-CONTEXT D-01/D-14-D-22]

## Environment Availability

| Dependency | Status for planning | Required action |
|------------|---------------------|-----------------|
| Pinned MoonBit toolchain | Defined by existing policy. [VERIFIED: `policy/foundation.json`] | Fail on any local/CI mismatch. |
| PowerShell | Existing qualification and benchmark implementation language. [VERIFIED: repository scripts] | Reuse existing helpers. |
| Exact Latin specimen | Not finalized. [VERIFIED: assigned prior-research fact] | 107-01 proves exact file/profile/hash/license or stops. |
| Exact CJK specimen/derivative | Not finalized. [VERIFIED: assigned prior-research fact] | 107-01 proves CID/multi-FD/FDSelect/local-Subrs/high-GID facts or stops. |
| Two pinned semantic readers | Not finalized. [VERIFIED: 107-CONTEXT D-09] | Verify official provenance, availability, legitimacy, versions, and digests in 107-01. |
| Pinned OTS | Not finalized. [VERIFIED: 107-CONTEXT D-09] | Use only after exact structural-tool identity is frozen. |

There is no silent fallback for failed specimen profile, redistribution, independent-reader agreement, or tool identity. [VERIFIED: 107-CONTEXT D-07-D-09]

## Security Domain

| ASVS category | Applies | Control |
|---------------|---------|---------|
| V2 Authentication | No | Offline repository qualification has no authentication boundary. [VERIFIED: phase boundary] |
| V3 Session Management | No | No session state exists in this phase. [VERIFIED: phase boundary] |
| V4 Access Control | Yes, filesystem ownership | Literal managed-root containment, exact v3 marker, no link/reparse traversal, known-file cleanup only. [VERIFIED: current evidence boundary] |
| V5 Input Validation | Yes | Exact ordered schemas, lengths/SHA, profile facts, bounded counts/ranges, and rejection of extras. [VERIFIED: 107-CONTEXT D-06/D-11/D-17] |
| V6 Cryptography | Integrity only | Use platform SHA-256 for identity; do not hand-roll cryptography. [VERIFIED: current generator] |

Threats to test explicitly are asset/tool substitution, oracle self-reference, hostile-font denial of service, evidence-root escape, schema normalization hiding drift, and licensed derivatives mislabeled as project-generated. Controls are exact provenance/digests, independent readers, bounded runtime plus exact/one-short evidence, managed-root negatives, explicit projection, and retained upstream licensing. [VERIFIED: 107-CONTEXT D-08-D-17; `docs/policies/licensing-and-fixtures.md`]

## Plan Slices

### 107-01 — Canonical fixtures, licensed intake, provenance, and oracle

1. Freeze the ordered generated corpus schema and hand-derived name/CID facts.
2. Run the blocking official Source candidate intake; select nothing until exact Latin and CJK profile/license/hash facts pass.
3. Select/pin two independent readers and OTS, including legitimacy and executable/package/archive digests.
4. Generate canonical binaries/oracles/manifest lineage and one portable MoonBit mirror; make `-Check` reconstruct all committed outputs without network mutation.
5. Freeze fixture, oracle, case, command, workload, tool, notice, and source identities.

**Exit gate:** every exact specimen/profile/license/tool fact reproduces and both readers agree on the closed projection; otherwise stop. [VERIFIED: 107-CONTEXT D-03-D-10/D-23]

### 107-02 — Public workflows, hostile/atomicity matrix, and glyf lock

1. Add generated/licensed standalone and selected-collection public facts.
2. Promote the exact ordered hostile groups from existing builders.
3. Freeze complete errors, smallest GIDs, publication state, and all eight caller/ancestor dimensions.
4. Freeze static-glyf standalone/collection semantic fingerprints and named focused assertion identities.

**Dependency:** consumes only frozen 107-01 identities. **Exit gate:** every focused public/white-box identity passes on all four targets before v3 consumers are finalized. [VERIFIED: 107-CONTEXT D-05/D-11-D-14/D-23]

### 107-03 — v3 evidence, policy/CI/docs, and native baseline

1. Advance the existing runner/boundary to fresh v3 identities and exact nested schemas.
2. Refresh final live source/test inventories and retain API/dependency/import/capability locks.
3. Update the existing CI job and documentation; measure before any timeout change.
4. Record four equality-bearing correctness workloads and create the separate native 1+7 observation baseline/read-only audit.

**Dependency:** consumes frozen 107-01 fixture/oracle/workload identities and 107-02 assertion/fingerprint identities. **Exit gate:** exactly four equal ordered semantic records, green policy/boundary negatives, clean baseline reconstruction, and no public/runtime expansion. [VERIFIED: 107-CONTEXT D-15-D-23]

## State of the Art

| Before Phase 107 | After Phase 107 |
|------------------|-----------------|
| Diagnostic generated CFF builders and white-box tests | Minimal ordered generated name/CID corpus with hand-derived expected facts. [VERIFIED: current tests; 107-CONTEXT D-03-D-06] |
| No finalized licensed CFF qualification specimen | Exact official Latin and multi-FD CID CJK lineage, or intake fails without weakening coverage. [VERIFIED: 107-CONTEXT D-07-D-10] |
| v2 TTC/static-glyf qualification evidence | Fresh v3 CFF+glyf record with only target/runner normalized. [VERIFIED: Phase 103 analog; 107-CONTEXT D-14-D-17] |
| No CFF performance evidence | Four correctness digests plus separate native observation-only 1+7 record. [VERIFIED: 107-CONTEXT D-19-D-22] |

## Assumptions Log

| # | Claim | Risk if wrong |
|---|-------|---------------|
| A1 | AFDKO 5.0.1 `tx` can be provisioned from the locked wheel in the controlled host lane. [ASSUMED] | Medium; reader-adapter plan fails closed before fixture promotion if the exact command cannot be reconstructed. It may not substitute fontTools or OTS. |
| A2 | The current 20-minute CI timeout is retained for v3. [DECIDED] | Low; a measured overrun becomes an explicit later policy change, not an unplanned timeout expansion inside qualification. |

Exact specimen filenames, lengths, SHA-256 values, CJK FD count/usage, fixed high GID, license identities, and reader package versions/hashes are resolved above. Only environment-specific invoked executable/adapter digests are generated by the fail-closed intake and then frozen in provenance. [VERIFIED: local independent inspection, 2026-07-29; 107-CONTEXT D-07-D-09]

## Resolved Questions

1. **Licensed specimens — RESOLVED:** use exact upstream `SourceSans3-Regular.otf` and `SubsetOTF/JP/SourceHanSerifJP-Regular.otf` with the identities and proven CFF1/CID/FD facts above. No derivative recipe is required because both committed specimens are exact upstream files. [CITED: https://github.com/adobe-fonts/source-sans/releases/tag/3.052R] [CITED: https://github.com/adobe-fonts/source-han-serif/releases/tag/2.003R]
2. **Independent readers — RESOLVED:** pin fontTools 4.63.0 and AFDKO 5.0.1 by exact wheel identity; use two explicit adapters and closed-schema equality, with OTS v9.2.0 structural-only. Environment executable/adapter digests are generated and frozen before fixture promotion; any inability to reconstruct either reader blocks the plan. [VERIFIED: 107-CONTEXT D-09; package artifact audit above]
3. **CI timeout — RESOLVED:** retain the existing 20-minute timeout for v3. Do not add an automatic increase; report a measured overrun as a follow-up policy decision if it occurs. [VERIFIED: 107-CONTEXT agent discretion]

## Sources

### Primary (HIGH confidence)

- `.planning/phases/107-.../107-CONTEXT.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` — phase boundary, sequencing, and CFF-06.
- Phase 104-106 `CONTEXT.md`/`VERIFICATION.md` — implemented CFF profile, Type 2/resource semantics, cubic/collection guarantees.
- Phase 103 research/verification plus current font generator/runner/boundary/policy/CI files — qualification architecture.
- Current CFF/public/white-box tests and Phase 94 benchmark scripts/doc — exact reuse seams.

### Official candidate/tool sources (MEDIUM until 107-01 intake)

- https://github.com/adobe-fonts/source-sans/releases/tag/3.052R
- https://github.com/adobe-fonts/source-han-serif/releases/tag/2.003R
- https://github.com/adobe-fonts/source-sans/blob/3.052R/LICENSE.md
- https://github.com/adobe-fonts/source-han-serif/blob/2.003R/LICENSE.txt
- https://fonttools.readthedocs.io/en/latest/ttLib/ttFont.html
- https://fonttools.readthedocs.io/en/latest/pens/recordingPen.html
- https://freetype.org/freetype2/docs/reference/ft2-glyph_retrieval.html
- https://freetype.org/freetype2/docs/reference/ft2-character_mapping.html
- https://freetype.org/freetype2/docs/reference/ft2-outline_processing.html
- https://github.com/khaledhosny/ots/blob/v9.2.0/README.md

## Metadata

**Confidence breakdown:**
- Repository architecture and reuse: HIGH — current scripts/tests and passed predecessor verification define the seams.
- Hostile/resource/mutation matrix: HIGH — locked decisions map directly to existing diagnostic builders.
- v3/policy/benchmark architecture: HIGH — locked decisions extend passed Phase 103/94 patterns.
- Licensed specimen and host-tool identity: MEDIUM — official candidates are known, but exact files/profiles/hashes/tools remain a blocking 107-01 decision.

**Research date:** 2026-07-29  
**Valid until:** 2026-08-28 for repository architecture; external specimens/tools must be revalidated during 107-01 intake.
