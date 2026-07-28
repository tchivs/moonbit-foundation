# Phase 103: Hostile, Licensed, and Four-Target Qualification - Research

**Researched:** 2026-07-28
**Domain:** Deterministic TTC qualification fixtures, independent licensed-oracle validation, atomic hostile evidence, and four-target release evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Scope and closure

- **D-01:** Phase 103 is qualification-only. Preserve the exact 85-line public interface and all Phase 101/102 runtime semantics; do not implement a new parser, container, outline profile, or public query.
- **D-02:** Close TTC-04/TTC-05 by promoting the existing focused behavior into canonical qualification artifacts and independent four-target reports, not by rewriting already verified parser behavior.

### Fixture, license, and oracle strategy

- **D-03:** Add a separate ordered `fixtures/font/collection-qualification-cases.json` and generate test-private portable MoonBit mirrors through the existing font fixture generator. Keep the Phase 100 standalone qualification corpus and its digest unchanged.
- **D-04:** Use a deterministic two-face TTC v1 derivative of the committed DejaVu Sans 2.37 fixture as the licensed collection specimen. Both face directories reference one exact shared set of collection-root-relative table payloads, and selecting either face must equal the existing standalone DejaVu public facts. — **Reversibility:** costly — changing the licensed specimen later would invalidate fixture digests, oracle facts, generated source, policy allowlists, and canonical evidence.
- **D-05:** Record the TTC as an externally derived DejaVu artifact under the same upstream license and confirmed redistribution status. Preserve exact lineage, source/generator identity, digests, author/date, notice, and expected use; never relabel licensed bytes as Apache-2.0 project-generated content.
- **D-06:** Build an independent closed TTC oracle in the PowerShell intake/generator path. It verifies TTC version/count, directory coordinates, exact sharing, table records/checksums, derivative digest, and expected profiles; selected semantic facts remain bound to the existing independently audited SFNT oracle.

### Hostile, mutation, and compatibility evidence

- **D-07:** Define a separate closed collection hostile matrix covering malformed header/directory/DSIG/overlap, invalid index, CFF/CFF2/variable selection, checked range/arithmetic failure, semantic-limit boundaries, caller/ancestor budget boundaries, and source mutation. Freeze exact structured errors, publication state, and complete budget-before/after equality.
- **D-08:** Use black-box public evidence for pre/post-publication mutation and retain deterministic test-private hooks only for otherwise unobservable mid-collection-open and mid-selection windows. Do not introduce threads, ambient I/O, or target-specific race machinery.
- **D-09:** Preserve the v0.32 standalone baseline by name and semantic content: compact/DejaVu public facts, all 11 standalone hostile outcomes, the exact `Font` interface subsequence, focused assertions, and the full package run on every target. Do not freeze a brittle aggregate test-count constant.

### Four-target evidence and boundaries

- **D-10:** Introduce a new closed v2 workflow/schema identity and fresh managed evidence directory. Each of exactly four ordered target records contains the standalone baseline, generated collection facts, licensed derivative facts, collection hostile outcomes, mutation/atomicity facts, boundary/dependency facts, fixture/toolchain digests, focused assertion identities, and pass status. Semantic comparison removes only `target` and `runner`; all other byte-canonical payload fields must match.
- **D-11:** Extend the existing `FontQualification` runner and CI job rather than creating a second collection lane. Run independent `js`, `wasm`, `wasm-gc`, and `native` checks, focused public/private qualification assertions, and the full package through the existing evidence ownership and canonical comparison boundary.
- **D-12:** Keep CFF/CFF2 and variable faces inspectable but not selectable, and keep WOFF1/WOFF2 entirely absent from runtime decode/admission. Canonical evidence and policy negatives must state and enforce this boundary while preserving pure MoonBit, no ambient I/O/FFI, `mb-font -> mb-core`, and the exact 85-line interface.

### Policy, documentation, and sequencing

- **D-13:** Update fixture/evidence policy, `foundation.json`, source/interface negative gates, and the module description, while leaving publication/release policy unchanged. Retain the existing 20-minute CI timeout unless the actual final four-target run proves it insufficient.
- **D-14:** Correct README/changelog statements that still exclude collections. Document TTC/OTC v1/v2 inspection, selected static-`glyf` admission, licensed derivative provenance, the v2 qualification command/report, and retained WOFF/CFF/variable/DSIG-trust exclusions.
- **D-15:** Plan three strict dependent slices: (1) canonical collection fixtures, licensed derivative, oracle, and provenance; (2) public workflow, hostile matrix, mutation/atomicity, and standalone locks; (3) v2 four-target evidence, policy/CI, and documentation. Do not parallelize schema consumers before their fixture/test identities are settled.

### the agent's Discretion

- Exact closed-schema field names and ordering, provided the records stay versioned, deterministic, and fail closed.
- Exact generated MoonBit helper layout, provided the licensed DejaVu bytes are not needlessly duplicated in generated source.
- Exact hostile case ordering and grouping, provided every TTC-04 category and all eight budget dimensions are explicit.
- Whether the existing 20-minute CI timeout needs a minimal increase, but only after measuring the complete final lane.

### Deferred Ideas (OUT OF SCOPE)

- WOFF1/WOFF2 decode/admission, CFF/CFF2 execution, variable-font execution, shaping, hinting, and rasterization remain future requirements.
- Registry publication and release-qualification policy changes remain outside v0.33.
- A new upstream licensed TTC may be considered in a later interoperability milestone if it adds distinct real-world coverage beyond the deterministic DejaVu derivative.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TTC-04 | Malformed collection structure, invalid face indices, unsupported selected profiles, source mutation, checked-arithmetic failures, semantic-limit exhaustion, and budget exhaustion return deterministic structured outcomes without publishing a partial collection or font or charging an uncommitted transaction. | The closed case schema, ordered case inventory, eight-field budget snapshots, public/private mutation split, exact error fields, and atomic publication rules below map every required failure class to an existing test seam. [VERIFIED: `.planning/REQUIREMENTS.md`; `collection_test.mbt:334-357,939-1584`; `collection_wbtest.mbt:299-551,993-1034`] |
| TTC-05 | Maintainers can reproduce generated hostile, licensed interoperability, standalone-compatibility, and complete public collection-to-`Font` workflow evidence with identical semantic facts on `js`, `wasm`, `wasm-gc`, and `native`. | The prescribed generator/oracle layout and v2 runner record extend the current four-target lane without adding runtime I/O, dependencies, or a second CI job. [VERIFIED: `.planning/REQUIREMENTS.md`; `Generate-FontQualification.ps1:1075-1333`; `Invoke-FontQualification.ps1:620-902`; `.github/workflows/quality.yml:11-32`] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Core algorithms and shared models remain MoonBit implementations; this phase must not replace the collection implementation with foreign code. [VERIFIED: `AGENTS.md` Project Constraints]
- Native remains the primary target, while `js`, `wasm`, `wasm-gc`, and `native` portability is enforced through capability boundaries and conformance evidence. [VERIFIED: `AGENTS.md`; `modules/mb-font/moon.mod.json`]
- Any FFI must remain isolated and documented, but Phase 103 must add none. [VERIFIED: `AGENTS.md`; `103-CONTEXT.md` D-12]
- Public package dependencies remain explicit and acyclic; `tchivs/mb-font` has exactly one module dependency, `tchivs/mb-core`. [VERIFIED: `AGENTS.md`; `modules/mb-font/moon.mod.json`; `Assert-Policy.ps1:2423-2425`]
- The exact pre-stable public interface remains governed and must stay at 85 ordered semantic lines. [VERIFIED: `103-CONTEXT.md` D-01; `policy/foundation.json:2261-2346`; `Assert-Policy.ps1:2421-2422`]
- Public operations and qualification must be deterministic and independent of GUI, filesystem, network, or host-font state. [VERIFIED: `AGENTS.md`; `.planning/REQUIREMENTS.md` Out of Scope; `Assert-Policy.ps1:1429-1448`]
- Performance claims require reproducible workloads; Phase 103 records correctness evidence and should not introduce unmeasured performance claims. [VERIFIED: `AGENTS.md`]
- New modules or breaking architecture require RFCs; neither is allowed in this qualification phase. [VERIFIED: `AGENTS.md`; `103-CONTEXT.md` D-01]
- Code discovery used the required codebase-memory graph first; the graph exposes this repository mainly as files/sections and returned no callable `FontCollection` symbols, so targeted MoonBit/PowerShell/JSON searches were the permitted fallback. [VERIFIED: codebase-memory `get_architecture` and `search_graph` results, 2026-07-28]

## Summary

Phase 103 should be implemented as an extension of the Phase 100 qualification pipeline, not as a runtime-font phase. The existing PowerShell generator already supplies the correct trust split: canonical repository inputs, an independently audited closed SFNT reader, exact byte/digest checks, ordered manifest enforcement, deterministic generated MoonBit, and `-Check` drift detection. The existing runner already supplies the correct release boundary: a managed-directory marker, link/reparse rejection, closed ordered JSON keys, exactly four ordered targets, focused tests, complete package runs, record read-back, normalized semantic equality, and SHA-256 evidence. [VERIFIED: `Generate-FontQualification.ps1:1-66,483-785,847-958,1075-1333`; `Invoke-FontQualification.ps1:1-374,620-902`; `Test-FontQualificationEvidenceBoundary.ps1:34-143`]

The main design obligation is to introduce a second, separately versioned collection corpus while leaving every Phase 100 byte and identity intact. The licensed specimen should be a two-face TTC v1 whose two directories are exact metadata copies and whose 20 payload ranges are shared once. A deterministic layout derived from the current 757,076-byte DejaVu file produces a 757,428-byte TTC with face directories at offsets 20 and 352, payload start 684, and SHA-256 `833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b`; each table payload is byte-identical to the corresponding standalone table and both faces point to the same root-relative range. [VERIFIED: local read-only derivation from `DejaVuSans.ttf` and `oracle.json`, 2026-07-28]

The v2 evidence record should be a strict superset in meaning, not a mutation of v1 evidence. It should preserve the named compact, format-4, DejaVu, 11-case hostile, unsupported-container/profile, exact-interface, and full-package baselines; add generated collection, licensed derivative, hostile, mutation, limit/budget, and policy facts; and compare four records after removing only `target` and `runner`. [VERIFIED: `103-CONTEXT.md` D-09-D-12; `font_qualification_test.mbt:161-340`; `font_qualification_hostile_test.mbt:329-358`; `font_test.mbt:5181-5209`; `Invoke-FontQualification.ps1:659-715`]

**Primary recommendation:** Freeze the collection JSON/oracle/test identities first, generate the licensed TTC and its no-duplicate MoonBit assembler second, then extend the existing tests and only afterward advance the runner/policy/CI/documentation to `font-complete-public-v2`. [VERIFIED: `103-CONTEXT.md` D-15]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical collection recipes and expected outcomes | Repository fixture tier | Policy tier | Ordered JSON is the source of truth; policy independently closes keys, IDs, order, digest, and license. [VERIFIED: Phase 100 pattern at `Generate-FontQualification.ps1:847-958`; `Assert-Policy.ps1:2482-2498`] |
| Licensed TTC derivation and byte oracle | Offline PowerShell tooling | Fixture/provenance tier | Only offline tooling reads repository files; portable runtime tests consume generated bytes and facts. [VERIFIED: `Generate-FontQualification.ps1:483-688,788-845`; `103-CONTEXT.md` D-04-D-06] |
| Collection-to-`Font` semantic proof | Portable MoonBit test tier | Existing library runtime | Tests call the already-shipped public APIs; production code stays unchanged unless evidence finds a defect. [VERIFIED: `collection_test.mbt:780-936,1217-1278`; `103-CONTEXT.md` D-01-D-02] |
| Mid-operation mutation proof | Test-private MoonBit tier | Public black-box tier | Existing deterministic hooks cover otherwise unobservable final revision windows; ordinary mutation is tested through public APIs. [VERIFIED: `collection.mbt:88-104,162-184`; `font.mbt:411-432,516-553,571-605`; `collection_wbtest.mbt:299-408,993-1034`] |
| Four-target canonical evidence | PowerShell quality runner | CI workflow | The runner owns schema validation, target execution, normalization, and digests; CI invokes that same lane and uploads only passing evidence. [VERIFIED: `Invoke-FontQualification.ps1:620-902`; `.github/workflows/quality.yml:11-32`] |
| API/dependency/format boundary | Policy script and `foundation.json` | Full package tests | Exact interface and source/dependency classifiers fail closed, while public tests prove inspectable-but-not-selectable and unsupported-container behavior. [VERIFIED: `Assert-Policy.ps1:981-1092,1429-1460,2371-2616`; `font_test.mbt:5181-5209`] |

## Standard Stack

### Core

| Tool/Library | Verified Version | Purpose | Why Standard Here |
|--------------|------------------|---------|-------------------|
| `moon` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Four-target checks/tests and literate README checks | This is the repository-pinned current toolchain and the runner already captures its exact identity. [VERIFIED: local `moon version --all`; `Invoke-FontQualification.ps1:376-390`] |
| `moonc` | `v0.10.4+2cc641edf` (2026-07-15) | MoonBit compilation | It is supplied by the same pinned toolchain and recorded per evidence record. [VERIFIED: local `moon version --all`; `Invoke-FontQualification.ps1:376-390`] |
| PowerShell | `7.6.3` | Closed fixture/oracle generation, JSON canonicalization, policy, and evidence | The existing qualification and CI scripts are PowerShell and use invariant .NET byte/JSON primitives. [VERIFIED: local `$PSVersionTable`; `.github/workflows/quality.yml:21-26`] |
| `tchivs/mb-core` | `0.1.0` | Bytes, checked arithmetic, errors, budgets, and paths used by `mb-font` | It is the only runtime dependency and must remain so. [VERIFIED: `modules/mb-font/moon.mod.json`; `modules/mb-font/font/moon.pkg`] |
| .NET `SHA256.HashData` | PowerShell runtime API | Fixture identity, generated drift, record hashes, and semantic digest | The generator and runner already use the same lowercase SHA-256 encoding. [VERIFIED: `Generate-FontQualification.ps1:33-40`; `Invoke-FontQualification.ps1:50-56`] |

### Supporting

| Asset | Current Identity | Purpose | Phase 103 Use |
|-------|------------------|---------|---------------|
| `DejaVuSans.ttf` | 757,076 bytes; SHA-256 `7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954` | Licensed standalone interoperability source | Sole byte source for the two-face derivative. [VERIFIED: `Generate-FontQualification.ps1:25-29`; local hash] |
| DejaVu `LICENSE` | 8,816 bytes; SHA-256 `7a083b136e64d064794c3419751e5c7dd10d2f64c108fe5ba161eae5e5958a93` | Upstream license/notice | Reuse as the retained notice for both standalone and derivative; do not create a duplicate `NOTICE`. [VERIFIED: `Generate-FontQualification.ps1:14,27-29,833-835`; `fixtures/manifest.json` font license record] |
| Standalone oracle | `mnf-powershell-closed-sfnt-reader/1.1.0`; file SHA-256 `4247394c3795a56aaf28c1885403201cfc277b06125f5887e14a40f3b4c6229a` | Independent table and semantic facts | Remains the semantic oracle for both selected TTC faces. [VERIFIED: `oracle.json`; local hash] |
| Phase 100 cases | 11 ordered cases; SHA-256 `a9a86ed5c080571fffe3317eead29865c5fdad222475251423621fddb09c1d18` | Standalone hostile baseline | Keep byte-for-byte unchanged and expose as `standalone_baseline`. [VERIFIED: `qualification-cases.json`; local hash; `103-CONTEXT.md` D-03/D-09] |
| Existing generated source | 3,064,383 bytes; SHA-256 `ad1af33a596a0e272fe1052f0c48754cd534c3274915b369b87b4269c1232677` | One portable embedded copy of DejaVu plus generated expectations | Extend with TTC assembly metadata; do not embed a second licensed byte copy. [VERIFIED: local file facts; `Generate-FontQualification.ps1:1161-1202`] |

**Installation:** no external package installation is required. Use the repository-pinned MoonBit installer in CI and the existing PowerShell/.NET runtime locally. [VERIFIED: `.github/workflows/quality.yml:21-26`; `scripts/ci/Install-PinnedMoonBit.ps1`]

## Package Legitimacy Audit

Not applicable: Phase 103 should install no npm, PyPI, crates.io, or other third-party package. [VERIFIED: `103-CONTEXT.md` D-01/D-12; current generator and runner imports]

## Exact Existing Assets and Reuse Points

| Asset | Exact reusable pattern |
|-------|------------------------|
| `scripts/fixtures/Generate-FontQualification.ps1:51-66` | Reuse `Assert-ExactBytesIdentity` for standalone, derivative, license, oracle, cases, and generated-source length/digest checks. [VERIFIED: local code] |
| `scripts/fixtures/Generate-FontQualification.ps1:68-109` | Reuse checked big-endian readers and table slicing; add symmetric bounded big-endian writers for derivative construction. [VERIFIED: local code] |
| `scripts/fixtures/Generate-FontQualification.ps1:483-688` | Extend the independent reader with a separate TTC reader; do not call `FontCollection` or reuse production MoonBit results. [VERIFIED: local code] |
| `scripts/fixtures/Generate-FontQualification.ps1:690-785` | Reuse stable LF JSON and exact ordered manifest record comparison. Refactor the current “qualification cases must be last” assumption at lines 931-948 because Phase 103 must append new records after the unchanged Phase 100 record. [VERIFIED: local code; `103-CONTEXT.md` D-03] |
| `scripts/fixtures/Generate-FontQualification.ps1:847-903` | Mirror the closed document/key/order/enum validation for `collection-qualification-cases.json`. [VERIFIED: local code] |
| `scripts/fixtures/Generate-FontQualification.ps1:1075-1202` | Retain the existing DejaVu chunks exactly once; generate a TTC assembler that copies the directory/payload regions from `font_qualification_dejavu_sans_237_bytes()` and patches root-relative offsets. [VERIFIED: local code; `103-CONTEXT.md` D-04] |
| `collection_test.mbt:38-63` | Reuse the directory writer for compact generated fixtures. [VERIFIED: local code] |
| `collection_test.mbt:66-111` | Promote the existing v2/absent-DSIG/mixed-profile shape. [VERIFIED: local code] |
| `collection_test.mbt:115-181` | Promote wrong-rebase, exact range, touching, same-face overlap, and cross-face metadata cases. [VERIFIED: local code] |
| `collection_test.mbt:429-468` | Reuse the non-zero-directory and before/after-payload pattern; do not use this one-face wrapper as the licensed derivative algorithm. [VERIFIED: local code] |
| `collection_test.mbt:510-590,810-936` | Reuse public opaque-`Font` equivalence assertions for metrics, mappings, kerning, glyph identity, and exact path commands. [VERIFIED: local code] |
| `collection_test.mbt:593-684,1217-1278` | Reuse exact shared-directory construction and CFF/CFF2/variable sibling selection gates. [VERIFIED: local code] |
| `collection_test.mbt:334-357` | Reuse the complete eight-field `ResourceLimits` equality assertion: bytes, allocations, allocation size, width, height, pixels, depth, and work. [VERIFIED: local code; `mb-core/budget/budget.mbt:1-77`] |
| `collection_wbtest.mbt:299-551,993-1034` | Reuse the selected final-revision, staged caller/ancestor authority, and collection final-revision hooks; keep them test-private. [VERIFIED: local code] |
| `font_wbtest.mbt:710-809` | Reuse deterministic post-read/post-decode hooks for inherited mapping, kerning, and simple/composite outline publication. [VERIFIED: local code] |
| `Invoke-FontQualification.ps1:261-374` | Reuse exact key-order validation and exact focused assertion identity checks. [VERIFIED: local code] |
| `Invoke-FontQualification.ps1:659-715` | Reuse ordered four-record comparison, explicit semantic projection, LF compact JSON, record hashes, and semantic hash. [VERIFIED: local code] |
| `Test-FontQualificationEvidenceBoundary.ps1:34-143` | Reuse caller-owned, unowned, corrupted-marker, unrelated-file, and link/reparse destructive-boundary probes. [VERIFIED: local code] |
| `Assert-Policy.ps1:981-1092` | Rename the independent classifier to a phase-neutral/v0.33 name while preserving the exact 85-line allowlist byte-for-byte. [VERIFIED: local code; `103-CONTEXT.md` D-01] |
| `Assert-Policy.ps1:1429-1460,2524-2613` | Extend the executable-source lexer probes with WOFF1, WOFF2, and variable execution/admission names; retain current FFI/filesystem/GUI/shaping/hinting/CFF/rasterization probes. [VERIFIED: local code; `103-CONTEXT.md` D-12] |

## Architecture Patterns

### System Architecture Diagram

```text
Committed DejaVu TTF + LICENSE + standalone oracle
                         |
                         v
       Generate-FontQualification.ps1 (offline only)
          |             |                 |
          |             |                 +--> closed collection cases
          |             +--> independent TTC structural oracle
          +--> deterministic two-face TTC derivative
                         |
                         v
       generated_font_qualification_test.mbt
       (one licensed literal copy + TTC assembler)
                         |
                         v
      Public qualification tests ----> existing FontCollection/Font APIs
      Private mutation tests --------> existing deterministic hooks
                         |
                         v
          Invoke-FontQualification.ps1 v2
        /          /          /           \
       js        wasm      wasm-gc       native
        \          \          \           /
         four closed records -> normalize target/runner only
                         |
                         v
         comparison.json + CI artifact upload
```

The service boundary is explicit: repository and licensed bytes are read only by offline PowerShell tooling; portable MoonBit receives generated bytes; production APIs certify behavior but never generate expected facts; and the runner, not a target, owns canonical evidence comparison. [VERIFIED: current generator/runner architecture; `103-CONTEXT.md` D-03-D-12]

### Pattern 1: Canonical input → independent oracle → generated portable mirror

Use one canonical JSON/binary identity, validate it independently, then generate a test-private MoonBit representation and fail `-Check` on any byte drift. [VERIFIED: `Generate-FontQualification.ps1:483-688,847-958,1075-1333`]

### Pattern 2: Public black-box evidence with narrow private transition hooks

Use `FontCollection::open`, `face_profile`, `open_face`, and existing opaque `Font` queries for observable behavior. Invoke private callbacks only to mutate after normalization/admission/lookup/decode but before the final revision guard. [VERIFIED: `collection_test.mbt`; `collection_wbtest.mbt:299-408,993-1034`; `font_wbtest.mbt:710-809`; D-08]

### Pattern 3: Closed evidence with explicit normalization

Validate exact key order and enum values at every nested level, then build one explicit ordered semantic projection that omits only top-level `target` and `runner`. [VERIFIED: `Invoke-FontQualification.ps1:261-374,659-715`; D-10]

### Anti-Patterns to Avoid

- **Runtime self-certification:** never derive expected TTC facts from `FontCollection`/`Font` output. [VERIFIED: D-06]
- **Schema-by-convention:** never accept arbitrary extra JSON keys or unordered IDs. [VERIFIED: current generator/runner/policy closed schemas]
- **Target aggregation:** never use one `--target all` test result as the four semantic records; run four independent target commands. [VERIFIED: D-11]
- **Fixture mutation in tests:** never patch the committed licensed TTC in place; tests construct owned copies from generated immutable bytes. [VERIFIED: existing test owner pattern]

## Fixture, Derivative, Oracle, and Generated-Source Architecture

### Canonical files

```text
fixtures/font/
├── qualification-cases.json                         # unchanged Phase 100 standalone corpus
├── collection-qualification-cases.json              # new Apache-2.0 closed collection recipes/outcomes
└── dejavu-sans-2.37/
    ├── DejaVuSans.ttf                               # unchanged upstream bytes
    ├── LICENSE                                      # unchanged upstream notice/license
    ├── oracle.json                                  # unchanged standalone semantic oracle
    ├── DejaVuSans-two-face-v1.ttc                   # new externally-derived licensed bytes
    └── collection-oracle.json                       # new generated facts; no payload-byte copies
modules/mb-font/font/
└── generated_font_qualification_test.mbt            # one DejaVu literal copy + generated TTC assembler/case mirror
```

This layout keeps Phase 100 identities unchanged, keeps the derived licensed bytes beside their source/license, and gives the new corpus an independent schema/digest. [VERIFIED: `103-CONTEXT.md` D-03-D-06; current fixture tree]

### Deterministic TTC v1 derivative algorithm

Use this exact layout and freeze it in generator constants:

1. Verify the input is the exact 757,076-byte DejaVu file and SHA-256 before reading any directory field. [VERIFIED: existing pattern at `Generate-FontQualification.ps1:483-491`]
2. Read `numTables=20`; set one SFNT directory length `D = 12 + 16*20 = 332`. [VERIFIED: `oracle.json` table inventory; local derivation]
3. Emit TTC header `ttcf`, version `0x00010000`, `numFonts=2`, and face offsets `[20, 352]`. [VERIFIED: OpenType-compatible layout already consumed by `collection_test.mbt:615-639`; local derivation]
4. Set shared payload start to `align4(352 + 332) = 684`. [VERIFIED: local checked arithmetic derivation]
5. Copy the standalone 332-byte offset-table/directory block to both face offsets. For every table record in both copies, replace `offset` with `684 + (standalone_offset - 332)`, preserving tag, length, checksum, order, and search facts. [VERIFIED: closest code pattern `collection_test.mbt:593-612`; local derivative validation]
6. Copy the standalone byte tail `[332, 757076)` exactly once to derivative `[684, 757428)`. Do not normalize table bytes, gaps, padding, or the stored `head.checksumAdjustment`. [VERIFIED: local derivative validation]
7. Verify both directories have 20 records with byte-identical `(tag, checksum, offset, length)` tuples and that every pair of corresponding records points to one exact root range. [VERIFIED: `103-CONTEXT.md` D-04/D-06]
8. Verify every derivative table payload equals its standalone source slice. Recompute each OpenType table checksum over four-byte padding; for `head`, zero bytes 8-11 only during checksum calculation. Compare recomputed values to both record checksums and the standalone oracle. [VERIFIED: checksum behavior at `directory.mbt:883-940`; `103-CONTEXT.md` D-06]
9. Freeze derivative length `757428` and SHA-256 `833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b`. [VERIFIED: local read-only derivation from committed bytes]

The unchanged standalone `head.checksumAdjustment` is correct for this phase: selected collection admission validates the `head` table with bytes 8-11 zeroed and deliberately skips only the standalone whole-root adjustment rule. Rewriting that field would break byte identity without adding a required collection invariant. [VERIFIED: Phase 102 verification truth 6; `directory.mbt:883-940`]

### Independent collection oracle

Use top-level key order:

```text
schema_version
oracle
lineage
derivative
collection
faces
shared_tables
standalone_oracle_binding
```

Use identity `mnf-powershell-closed-ttc-reader/1.0.0` and independence text `offline parser; does not invoke tchivs/mb-font`. [VERIFIED: follows closed identity pattern at `oracle.json` and `Assert-Policy.ps1:2448-2459`]

- `lineage`: source path/length/SHA-256, source archive URL, source retrieval date, generator path, generation date, license expression, redistribution status, and retained notice path/digest. [VERIFIED: fixture policy; `fixtures/manifest.json` font records]
- `derivative`: path, length, SHA-256, TTC signature/version, and generator algorithm identity such as `dejavu-two-face-exact-sharing-v1`. [VERIFIED: `103-CONTEXT.md` D-04-D-06]
- `collection`: exact face count `2`, ordered offsets `[20,352]`, directory length `332`, payload start `684`, DSIG status `absent`, and expected profiles `[StaticGlyf,StaticGlyf]`. [VERIFIED: local derivation]
- `faces`: two closed records containing index, directory offset, SFNT signature, table count/search facts, and ordered table records. [VERIFIED: `103-CONTEXT.md` D-06]
- `shared_tables`: 20 ordered records containing tag, root offset, length, stored checksum, recomputed checksum, source offset, and source-payload SHA-256. [VERIFIED: required independent validation in D-06]
- `standalone_oracle_binding`: path and SHA-256 of `oracle.json`, plus the explicit assertion that face 0 and face 1 public semantics use that oracle rather than a second self-derived semantic copy. [VERIFIED: `103-CONTEXT.md` D-04/D-06; current oracle hash]

### License and manifest disposition

- Record `DejaVuSans-two-face-v1.ttc` as `origin: external`, license `Bitstream-Vera AND LicenseRef-DejaVu-Arev`, redistribution `confirmed`, with source text naming both the immutable upstream URL/source TTF and `scripts/fixtures/Generate-FontQualification.ps1`. Never label the binary Apache-2.0. [VERIFIED: `103-CONTEXT.md` D-05; `docs/policies/licensing-and-fixtures.md`]
- Retain `LICENSE` as the exact upstream notice. The `103-CONTEXT.md` canonical-reference name `NOTICE` does not exist in the worktree; the generator, manifest, README, and digest all establish that the actual 8,816-byte upstream notice is `LICENSE`. Do not create a duplicate notice file. [VERIFIED: current fixture tree; `Generate-FontQualification.ps1:14,24,27-29`; `README.mbt.md:312-321`]
- Record `collection-qualification-cases.json` as project-generated Apache-2.0 because it contains project-authored recipes/expectations and no licensed payload bytes. [VERIFIED: fixture policy and D-03/D-05]
- `collection-oracle.json` may be recorded as project-generated metadata only if policy explicitly asserts it contains no copied payload bytes; its lineage must still bind the external source/derivative/license. [VERIFIED: `docs/policies/licensing-and-fixtures.md`; D-05/D-06]
- Append new manifest records after the unchanged `font-qualification-cases` record. Update generator/policy order checks to the new exact sequence without changing any existing record value or digest. [VERIFIED: `fixtures/manifest.json`; `Generate-FontQualification.ps1:931-948`; D-03]

### Generated MoonBit without licensed-byte duplication

Keep the current 185 DejaVu 4,096-byte literal chunks as the only licensed byte embedding. Generate `font_qualification_dejavu_two_face_ttc_v1_bytes()` that:

- obtains the existing standalone bytes;
- allocates exactly 757,428 bytes;
- writes the 20-byte TTC header;
- copies the standalone directory twice;
- patches each copied offset by `+352`;
- copies the standalone tail from offset 332 once to output offset 684; and
- returns `Bytes` for public collection tests. [VERIFIED: current chunk/join pattern at `Generate-FontQualification.ps1:1123-1202`; local derivative layout]

The PowerShell generator must independently render/reconstruct this helper result, compare it byte-for-byte to the committed TTC, and verify length/SHA-256 in both normal and `-Check` modes. Runtime MoonBit does not need SHA-256 and performs no file I/O. [VERIFIED: existing round-trip pattern at `Generate-FontQualification.ps1:1179-1192,1268-1284`; D-03/D-08]

## Closed Collection Schema and Case Inventory

### Recommended JSON schema

Use top-level ordered keys:

```text
schema_version, workflow_id, license, fixtures, public_workflows,
hostile_cases, mutation_cases, limit_cases, budget_cases
```

Use `schema_version: "1.0.0"`, `workflow_id: "font-collection-complete-public-v2"`, and `license: "Apache-2.0"`. Every nested object must have an independently asserted exact key sequence. [VERIFIED: closest closed schema at `Generate-FontQualification.ps1:847-903`; D-03/D-07/D-10]

Every outcome-bearing case should use:

```text
id, fixture_id, stage, entrypoint, face_index, mutation_window,
authority, boundary, error, publication, budget_before, budget_after
```

`error` has exact ordered nullable fields `category, code, operation, context, source_offset, requested, limit`. Each budget snapshot has exactly `bytes, allocations, allocation_size, width, height, pixels, depth, work`; failures require byte-for-byte equality of the two complete objects. [VERIFIED: `CoreError` assertions in `collection_test.mbt:939-1214`; eight fields at `collection_test.mbt:345-357`; D-07]

### Fixture/public workflow IDs

Freeze this order:

1. `generated-ttc-v1-static-selected`
2. `generated-ttc-v2-dsig-absent`
3. `generated-ttc-v2-dsig-present-unverified`
4. `generated-ttc-v1-exact-sharing`
5. `generated-ttc-v2-mixed-profiles`
6. `generated-ttc-v1-nonzero-directory-base`
7. `licensed-dejavu-two-face-v1-face-0`
8. `licensed-dejavu-two-face-v1-face-1`

The generated workflows promote existing v1/v2, DSIG, exact-sharing, mixed-profile, wrong-rebase, and selection behavior; the two licensed workflows bind both faces to the existing DejaVu facts. [VERIFIED: `collection_test.mbt:66-181,429-684,780-936,1217-1278,2328-2725`; D-03/D-04]

### Hostile IDs

Freeze this order:

1. `collection-header-truncated`
2. `collection-signature-invalid`
3. `collection-version-unsupported`
4. `collection-face-count-zero`
5. `collection-offset-array-truncated`
6. `collection-face-directory-truncated`
7. `collection-directory-search-facts-invalid`
8. `collection-directory-tags-unordered`
9. `collection-table-range-overflow`
10. `collection-protected-range-overlap`
11. `collection-same-face-overlap`
12. `collection-cross-face-partial-overlap`
13. `collection-shared-range-metadata-conflict`
14. `collection-dsig-partial-zero-tuple`
15. `collection-dsig-range-not-at-eof`
16. `collection-dsig-envelope-malformed`
17. `collection-dsig-version-unsupported`
18. `collection-dsig-format-unsupported`
19. `collection-dsig-block-overlap`
20. `collection-face-index-equal-count`
21. `collection-select-cff`
22. `collection-select-cff2`
23. `collection-select-variable`
24. `collection-checked-pair-work-overflow`

These IDs cover every TTC-04 structural/profile/arithmetic class while retaining stable traversal/error precedence. [VERIFIED: `collection_test.mbt:939-1214,1693-1739,1874-2199,2328-2755`; `collection_wbtest.mbt:921-991`; D-07]

### Mutation IDs

Freeze this order:

1. `mutation-collection-after-open-before-query` — public
2. `mutation-collection-mid-open-final-guard` — private hook
3. `mutation-selection-before-open-face` — public revision-first gate
4. `mutation-selection-mid-admission-final-guard` — private hook
5. `mutation-selected-font-after-publication` — public, all inherited queries
6. `mutation-glyph-lookup-mid-query` — private hook
7. `mutation-kerning-mid-query` — private hook
8. `mutation-simple-outline-mid-query` — private hook
9. `mutation-composite-outline-mid-query` — private hook

All mutation cases must use mutate-then-restore where practical so revision identity, not changed content, is the proved invariant. No threads or timing are needed. [VERIFIED: `collection_test.mbt:1587-1642,1822-1868`; `collection_wbtest.mbt:299-408,993-1034`; `font_wbtest.mbt:710-809`; D-08]

### Semantic-limit boundary matrix

Generate exact/one-short pairs for all eight `FontCollectionLimits` dimensions in constructor order:

`max_source_bytes`, `max_faces`, `max_tables_per_face`, `max_table_records`, `max_dsig_records`, `max_dsig_bytes`, `max_retained_bookkeeping_bytes`, `max_work`. [VERIFIED: `collection_limits.mbt`; `collection_test.mbt:1751-1799,2106-2199,2432-2589`]

Also freeze selected-face pairs for the `FontLimits` dimensions exercised by the selected semantic pipeline: source bytes, tables, table bytes, glyphs, name records, cmap records, kern subtables, kern pairs, outline points/contours/components/instruction bytes, post-name bytes, and total work. Existing standalone behavior remains the oracle; Phase 103 only proves that selection reaches the same established limits. [VERIFIED: `FontLimits::new` exact interface; Phase 102 verification truths 7, 11, and 12]

### Caller/ancestor budget matrix

Use exact/one-short caller pairs for charged dimensions `bytes`, `allocations`, `allocation_size`, and `work`, plus one-short ancestor pairs for `bytes` and `work`. In every result, record all eight before/after fields, including unchanged `width`, `height`, `pixels`, and `depth`. [VERIFIED: `mb-core/budget/budget.mbt:1-77`; `collection_test.mbt:1282-1584`; `collection_wbtest.mbt:411-551`]

Do not invent width/height/pixels/depth charges for fonts. Their explicit evidence is equality, while the actual font charge dimensions retain their existing semantics. [VERIFIED: `ResourceCharge` fields at `budget.mbt:80-110`; Phase 101/102 verification reports]

## v2 Evidence Schema and Four-Target Rules

### Identity and directory

- Marker schema: `mnf-font-qualification-evidence/v2`. [VERIFIED: v1 pattern at `Invoke-FontQualification.ps1:22-23`; D-10]
- Workflow ID: `font-complete-public-v2`. [VERIFIED: D-10]
- Local default directory: `artifacts/release-qualification/font-v2`. [VERIFIED: fresh-directory requirement D-10; v1 default at runner line 4]
- CI directory: `artifacts/release-qualification/ci-font-v2`. [VERIFIED: fresh-directory requirement D-10; current workflow line 26]
- Target order: `js`, `wasm`, `wasm-gc`, `native`. [VERIFIED: runner line 14; D-10/D-11]
- Target build directories: `target/phase103-font-qualification-{target}`. [VERIFIED: isolation pattern at runner line 796]

Changing the default and CI path ensures v2 never auto-deletes or overwrites a v1-owned directory. Marker validation must reject v1 markers inside the new path rather than “upgrade” them. [VERIFIED: current ownership boundary at runner lines 181-258; D-10]

### Target record key order

Use this exact top-level order:

```text
schema_version
workflow_id
target
toolchain
fixtures
standalone_baseline
generated_collection_facts
licensed_derivative_facts
collection_hostile_outcomes
mutation_atomicity_facts
boundary_facts
dependency_facts
focused_assertions
runner
pass
```

The mapping directly covers every mandatory D-10 payload. [VERIFIED: `103-CONTEXT.md` D-10; v1 record pattern at runner lines 620-656]

- `fixtures` contains relative path, length, and SHA-256 for the unchanged TTF/license/oracle/standalone cases/generated source/tests plus the collection cases, TTC, collection oracle, policy file, and focused test files. [VERIFIED: v1 fixture facts at runner lines 768-790; D-10]
- `standalone_baseline` contains the existing compact and DejaVu public facts, the exact 11 standalone outcomes, named focused assertions, the 85-line `Font` subsequence digest, and pass state. [VERIFIED: D-09; v1 public/hostile facts at runner lines 437-581]
- `generated_collection_facts` contains workflow IDs, v1/v2 versions, DSIG statuses, profile sequences, exact sharing, non-zero-base selection, and selected public facts. [VERIFIED: D-10]
- `licensed_derivative_facts` contains derivative identity, face/directory/shared-table facts, both selected-face public facts, and standalone oracle binding. [VERIFIED: D-04-D-06/D-10]
- `collection_hostile_outcomes` and `mutation_atomicity_facts` contain the exact ordered result records, including full budget snapshots and publication states. [VERIFIED: D-07/D-10]
- `boundary_facts` contains interface line count/digest, WOFF absence, CFF/CFF2/variable inspectable-but-not-selectable outcomes, DSIG unverified-only state, pure-MoonBit/no-ambient-I/O/FFI status, and source inventory digest. [VERIFIED: D-12]
- `dependency_facts` retains module name/version, sole module dependency, exact package imports, and four targets. [VERIFIED: runner lines 584-617]
- `focused_assertions` is an ordered array of `{id,file,name,kind,passed}` for every public/private standalone/collection assertion; commands stay in `runner` because they contain target-specific paths. [VERIFIED: D-09-D-11]

### Normalization and digests

Construct the semantic projection explicitly in `[ordered]` form with every top-level field except `target` and `runner`; do not use a recursive “delete volatile fields” helper. Serialize with `ConvertTo-Json -Depth 64 -Compress`, normalize CRLF to LF, encode UTF-8 without BOM, and SHA-256 the exact compact bytes. [VERIFIED: current safe projection at `Invoke-FontQualification.ps1:674-704`; D-10]

Exactly four records in exact target order are required. Validate each closed record before writing, write each target file, read it back, validate again, compute per-record file hashes, then write/validate `comparison.json`. [VERIFIED: runner lines 659-715,865-888]

`comparison.json` should use exact keys `schema_version, workflow_id, normalization_removed, targets, record_sha256, semantic_sha256, equal`, with `normalization_removed` exactly `["target","runner"]`. [VERIFIED: v1 pattern at runner lines 705-713; D-10]

### Required negative evidence probes

Retain missing-record and semantic-divergence probes, then add:

- duplicate, reordered, and unknown target;
- extra/missing/reordered top-level or nested key;
- wrong v2 schema/workflow;
- false pass state;
- licensed derivative digest divergence;
- shared-table coordinate divergence;
- collection hostile error-field divergence;
- one changed budget-after dimension;
- WOFF boundary or dependency fact divergence;
- focused assertion missing/duplicate/reordered;
- v1 ownership marker presented to v2;
- caller-owned root, managed root itself, non-empty unowned directory, corrupted marker, unrelated file preservation, and link/reparse traversal. [VERIFIED: current negative patterns at runner lines 718-730,876-887 and boundary test lines 34-143; D-10-D-12]

## Runner and CI Wiring

Keep the `FontQualification` selector unchanged in `scripts/quality.ps1`; update only the invoked runner’s v2 defaults and behavior. Keep the existing `font-qualification` CI job and 20-minute timeout initially, change its evidence path to `ci-font-v2`, and upload the v2 directory only on success. [VERIFIED: `scripts/quality.ps1:4-18`; `.github/workflows/quality.yml:11-32`; D-11/D-13]

Per target, run in this order:

1. `moon ... check --target {target} --frozen --serial`
2. named standalone compact public assertion
3. named standalone format-4 assertion
4. named standalone DejaVu assertion
5. named standalone 11-case hostile assertion
6. named generated collection public workflow assertion
7. named licensed derivative public workflow assertion
8. named collection hostile/limit/budget assertion
9. named collection mutation/atomicity public assertion
10. named collection/private mid-operation assertion
11. full `moon ... test font --target {target} --frozen --no-parallelize`

This preserves named baselines and avoids a brittle total-test constant; only each focused `-f` command must report exactly one passing test. [VERIFIED: current focused-command/pass-summary pattern at runner lines 802-849; D-09/D-11]

Run `Test-FontQualificationEvidenceBoundary.ps1`, generator `-Check`, and `Assert-FontFoundationPolicy` once before the target loop. Run the four README literate checks after semantic comparison as today. [VERIFIED: runner lines 747-767,888-896; boundary test]

## Standalone and Deferred-Capability Gates

### Standalone baseline

Preserve these exact test identities and semantics:

- `font-complete-public freezes compact public workflow facts`
- `font-complete-public exercises the compact format-4 branch`
- `font-complete-public freezes DejaVu Sans 2.37 public facts`
- `font qualification executes the closed hostile outcome matrix`
- `unsupported containers outlines variations color and bitmap profiles are capabilities`

[VERIFIED: `font_qualification_test.mbt:161,226,243`; `font_qualification_hostile_test.mbt:329`; `font_test.mbt:5181`]

Preserve the standalone case JSON and hash, DejaVu TTF/license/oracle bytes, current public facts, all 11 case IDs/outcomes, exact 85-line interface and 56-line `Font` subsequence, standalone whole-root checksum behavior, and full package run on every target. [VERIFIED: D-03/D-09; Phase 101/102 verification reports]

### WOFF/CFF/variable/source/dependency/API gates

- Public behavior: the existing standalone test proves `wOFF`, `wOF2`, and `OTTO` are unsupported capabilities, while collection mixed-profile tests prove CFF, CFF2, and variable faces are inspectable and selection-local Capability failures. Promote both into focused v2 evidence. [VERIFIED: `font_test.mbt:5181-5209`; `collection_test.mbt:1874-1916,1217-1278`]
- Source policy: extend `Assert-FontPortableSourceBoundary` with executable WOFF1/WOFF2 decoder/admission and variable-instantiation patterns, protected by the existing comment/string/interpolation-aware lexer. [VERIFIED: `Assert-Policy.ps1:1167-1448,2530-2613`; D-12]
- API policy: keep the exact 85-line allowlist and add negative lines such as `Font::open_woff`, `FontCollection::extract_face`, `Font::cff_outline`, and `Font::instantiate_variable`; every probe must fail the independent classifier. [VERIFIED: `Assert-Policy.ps1:981-1092,2524-2529`; D-01/D-12]
- Dependency policy: preserve the exact module edge and five `mb-core` package imports; retain the negative added-`mb-image` probe. [VERIFIED: runner lines 584-617; policy lines 2423-2425,2527-2529]
- Production-source policy: keep the current 13-file production set unchanged unless TTC-04 exposes a defect. Fixture/test changes belong only in the test source inventory. [VERIFIED: `policy/foundation.json:2236-2259`; D-01]
- Module description: change both `moon.mod.json` and `foundation.json` to mention bounded standalone TrueType plus TTC/OTC v1/v2 inspection and selected static-`glyf` admission, without claiming WOFF/CFF/variable execution or stability. [VERIFIED: current stale description at `foundation.json:2184`; D-13]

## Recommended Project Structure

```text
scripts/fixtures/Generate-FontQualification.ps1
  ├── immutable Phase 100 SFNT intake/oracle
  ├── collection JSON schema validation
  ├── deterministic TTC derivative writer
  ├── independent TTC oracle reader
  ├── manifest/provenance updates
  └── one generated MoonBit mirror

modules/mb-font/font/
  ├── generated_font_qualification_test.mbt   # generated only
  ├── font_qualification_test.mbt             # standalone + public collection workflows
  ├── font_qualification_hostile_test.mbt     # standalone + public collection matrix
  ├── collection_wbtest.mbt                   # collection mid-operation hooks
  └── font_wbtest.mbt                         # inherited query mid-operation hooks

scripts/quality/
  ├── Invoke-FontQualification.ps1            # v2 records/runner/comparison
  ├── Test-FontQualificationEvidenceBoundary.ps1
  └── Assert-Policy.ps1
```

This minimizes file proliferation and keeps generated data, public qualification, private hooks, and evidence ownership in their established tiers. [VERIFIED: current repository structure and D-11]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Runtime fixture loading | Filesystem/network/host-font loaders in MoonBit | Existing generated test-private source | Ambient I/O breaks four-target determinism and D-08/D-12. [VERIFIED: generator lines 1075-1202; source policy] |
| Second licensed byte embedding | A second 757 KB TTC literal set | Generated assembler over the existing DejaVu chunks | It avoids needless licensed duplication while still reproducing exact committed TTC bytes. [VERIFIED: D-04/D-05; current 3,064,383-byte generated file] |
| Semantic self-oracle | `mb-font` output copied into expected JSON | Independent PowerShell TTC structural oracle plus existing SFNT semantic oracle | Production code cannot certify its own parser behavior. [VERIFIED: D-06; Phase 100 oracle pattern] |
| Generic JSON comparison | Unordered hashtable equality or broad ignored fields | Exact ordered keys + explicit semantic projection + canonical LF UTF-8 digest | It fails closed on schema drift and removes only the two approved target-specific fields. [VERIFIED: runner lines 261-374,659-715; D-10] |
| New collection lane | Separate CI job/runner | Extend `FontQualification` | A second lane would split ownership and allow baselines to diverge. [VERIFIED: D-11] |
| Race-based mutation test | Threads, sleeps, target-specific timing | Existing deterministic test-private callbacks | Callbacks hit the exact final-guard windows portably. [VERIFIED: collection/font private hook tests; D-08] |
| License inference | Treating digest/source URL as permission | Existing manifest confirmed-redistribution contract and retained license | Redistribution must fail closed and derivative bytes retain upstream terms. [VERIFIED: licensing policy; D-05] |
| Custom evidence cleanup | Recursive deletion of caller paths | Existing marker, child containment, link checks, and known-file cleanup | The current boundary prevents path escape and preserves unrelated files. [VERIFIED: runner lines 94-258; boundary test] |

## Common Pitfalls

### Pitfall 1: Moving or rewriting the Phase 100 record
**What goes wrong:** The standalone corpus digest or manifest identity changes even though D-03/D-09 require preservation. [VERIFIED: D-03/D-09]  
**How to avoid:** Append Phase 103 records and refactor only the current “standalone cases must be last” assertion. [VERIFIED: generator lines 931-948]  
**Warning sign:** `qualification-cases.json`, its manifest SHA, or existing generated standalone helper diff changes.

### Pitfall 2: Duplicating DejaVu in generated MoonBit
**What goes wrong:** The generated file gains a second multi-megabyte escaped byte body and obscures which licensed copy is canonical. [VERIFIED: current generated file size/chunk pattern]  
**How to avoid:** Generate the TTC from the existing standalone chunks using the frozen layout recipe. [VERIFIED: D-04/D-05]

### Pitfall 3: Applying standalone aggregate checksum rules to TTC
**What goes wrong:** A valid collection face is rejected or its shared `head` bytes are rewritten. [VERIFIED: Phase 102 verification truth 6]  
**How to avoid:** Recompute per-table checksums with `head[8..12]` zeroed, but do not enforce standalone root `0xB1B0AFBA` on TTC. [VERIFIED: `directory.mbt:883-940`]

### Pitfall 4: Treating byte equality as exact sharing
**What goes wrong:** Equal payload copies pass even though the locked specimen requires both directories to name one identical root range. [VERIFIED: Phase 101 D-08; Phase 103 D-04]  
**How to avoid:** Oracle and tests compare offsets, lengths, checksums, and range identity, not only bytes/digests.

### Pitfall 5: Weakening v2 normalization
**What goes wrong:** Removing toolchain, fixtures, pass state, or nested runner-like fields can hide cross-target drift. [VERIFIED: D-10]  
**How to avoid:** Explicitly project every field except top-level `target` and `runner`.

### Pitfall 6: Reusing the v1 managed directory
**What goes wrong:** v2 cleanup deletes or relabels v1 evidence. [VERIFIED: D-10]  
**How to avoid:** Use fresh `font-v2`/`ci-font-v2` paths and a v2 marker that rejects v1.

### Pitfall 7: Freezing total test count
**What goes wrong:** Unrelated legitimate test additions break qualification without semantic drift. [VERIFIED: D-09]  
**How to avoid:** Freeze focused names and one-test pass summaries; run the full package for pass/fail only.

### Pitfall 8: Confusing inspectability with selectability
**What goes wrong:** CFF/CFF2/variable profiles become executable or disappear from inspection. [VERIFIED: D-12]  
**How to avoid:** Evidence must show profile enumeration succeeds and each `open_face` fails Capability with no budget change.

### Pitfall 9: Documentation-only WOFF exclusion
**What goes wrong:** A future runtime decoder can enter unnoticed while README still says unsupported. [VERIFIED: D-12]  
**How to avoid:** Combine exact API, executable-source lexer, dependency, public unsupported-signature, and negative-policy probes.

### Pitfall 10: Partial budget equality
**What goes wrong:** Tests compare only bytes/work and miss allocation-size, depth, or another counter. [VERIFIED: D-07; existing complete helper at `collection_test.mbt:345-357`]  
**How to avoid:** Use one eight-field snapshot type/helper everywhere and serialize both snapshots in evidence.

## Code Examples

### Exact eight-field atomicity assertion

```moonbit
// Source: modules/mb-font/font/collection_test.mbt:345-357
fn assert_budget_unchanged(before : @budget.ResourceLimits, budget : @budget.Budget) -> Unit raise {
  let after = budget.remaining()
  inspect(after.bytes() == before.bytes(), content="true")
  inspect(after.allocations() == before.allocations(), content="true")
  inspect(after.allocation_size() == before.allocation_size(), content="true")
  inspect(after.width() == before.width(), content="true")
  inspect(after.height() == before.height(), content="true")
  inspect(after.pixels() == before.pixels(), content="true")
  inspect(after.depth() == before.depth(), content="true")
  inspect(after.work() == before.work(), content="true")
}
```

### Explicit semantic projection

```powershell
# Source pattern: scripts/quality/Invoke-FontQualification.ps1:674-687
$semantic = [pscustomobject][ordered]@{
  schema_version = $record.schema_version
  workflow_id = $record.workflow_id
  toolchain = $record.toolchain
  fixtures = $record.fixtures
  standalone_baseline = $record.standalone_baseline
  generated_collection_facts = $record.generated_collection_facts
  licensed_derivative_facts = $record.licensed_derivative_facts
  collection_hostile_outcomes = $record.collection_hostile_outcomes
  mutation_atomicity_facts = $record.mutation_atomicity_facts
  boundary_facts = $record.boundary_facts
  dependency_facts = $record.dependency_facts
  focused_assertions = $record.focused_assertions
  pass = $record.pass
}
```

### Derivative offset rule

```powershell
# Source pattern: collection_test.mbt:593-612; frozen Phase 103 layout
$newOffset = 684L + ($standaloneOffset - 332L)
# Write $newOffset into the corresponding record in both directories.
```

All arithmetic must be range-checked before allocating/copying; the oracle then verifies the generated result independently. [VERIFIED: generator checked-reader style; D-06]

## State of the Art

| Existing v1 State | Required v2 State | Impact |
|-------------------|-------------------|--------|
| `font-complete-public-v1` with standalone public/hostile facts | `font-complete-public-v2` with standalone baseline plus collection/licensed/atomicity/boundary facts | v1 semantics are preserved as a named nested baseline. [VERIFIED: runner lines 633-655; D-09/D-10] |
| Default `artifacts/release-qualification/font` | Fresh `artifacts/release-qualification/font-v2` | No old evidence is mutated. [VERIFIED: runner line 4; D-10] |
| One TTF and one generated byte mirror | One unchanged TTF mirror plus deterministic TTC assembler | Adds licensed collection evidence without duplicating payload literals. [VERIFIED: D-04/D-05] |
| 11 standalone hostile outcomes | Separate unchanged standalone 11 plus closed collection matrices | TTC-04 gains broad atomic failure coverage without rewriting v0.32 facts. [VERIFIED: D-07/D-09] |
| CFF execution source probe; WOFF only covered by full-package test | CFF/variable/WOFF executable-source, API, public behavior, and evidence gates | Deferred formats become explicit release evidence. [VERIFIED: `Assert-Policy.ps1:1433-1441`; `font_test.mbt:5181-5209`; D-12] |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| PowerShell | Generator, runner, policy, CI scripts | ✓ | 7.6.3 | None needed. [VERIFIED: local probe] |
| MoonBit `moon` | Four-target check/test/readme | ✓ | 0.1.20260713 | CI uses pinned installer. [VERIFIED: local probe; workflow] |
| `moonc` | Compilation | ✓ | v0.10.4+2cc641edf | Supplied by pinned toolchain. [VERIFIED: local probe] |
| `moonrun` | Test execution | ✓ | 0.1.20260713 | Supplied by pinned toolchain. [VERIFIED: local probe] |
| Git | Drift and whitespace verification | ✓ | 2.54.0.windows.1 | CI checkout supplies repository state. [VERIFIED: local probe] |

**Missing dependencies with no fallback:** none. [VERIFIED: local environment audit]  
**Missing dependencies with fallback:** none. [VERIFIED: local environment audit]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No identity/authentication surface is introduced. [VERIFIED: qualification-only scope D-01] |
| V3 Session Management | no | No sessions exist. [VERIFIED: library/tooling architecture] |
| V4 Access Control | limited tooling analogue | Managed evidence must remain under the owned root and reject links/reparse points and unowned directories. [VERIFIED: runner lines 94-258; boundary test] |
| V5 Input Validation | yes | Checked binary ranges/arithmetic, closed JSON keys/order/enums, exact fixture IDs, exact target order, and fail-closed manifest/policy validation. [VERIFIED: collection tests; generator/runner/policy] |
| V6 Cryptography | identity only | Use platform SHA-256 for artifact identity; make no signature/authenticity claim and keep DSIG `PresentUnverified`. [VERIFIED: licensing policy; D-12; `FontCollectionDsigStatus`] |

### STRIDE Threats and Mitigations

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| A substituted derivative or oracle impersonates the licensed specimen | Spoofing | Bind source, generator, author/date, license, notice, length, and SHA-256 in manifest/oracle/evidence. [VERIFIED: D-05/D-06] |
| Fixture/generated/evidence bytes are modified | Tampering | Generator `-Check`, exact digests, closed keys/order, read-back validation, record hashes, and semantic hash. [VERIFIED: generator lines 1268-1333; runner lines 659-715] |
| Provenance or exact commands cannot be reconstructed | Repudiation | Record lineage, toolchain, focused assertion identities, runner commands, target order, and per-record hashes. [VERIFIED: D-05/D-10] |
| Tooling leaks host paths or reads ambient font data | Information Disclosure | Store repository-relative paths and prohibit runtime filesystem/network/host-font access. [VERIFIED: runner lines 58-67; source policy] |
| Malicious counts/ranges exhaust work or CI time | Denial of Service | Checked arithmetic, semantic ceilings, staged caller/ancestor preflights, no parallelized Moon tests, and bounded CI timeout. [VERIFIED: Phase 101/102 contracts; workflow timeout] |
| Evidence cleanup escapes its directory | Elevation of Privilege | Child-only path resolution, ownership marker, reparse/link rejection, and deletion of only known evidence files. [VERIFIED: runner lines 94-258; boundary test] |

## Concrete Files Likely Modified

| Slice | File | Change |
|------|------|--------|
| 1 | `fixtures/font/collection-qualification-cases.json` | Add closed ordered collection corpus. [VERIFIED: D-03] |
| 1 | `fixtures/font/dejavu-sans-2.37/DejaVuSans-two-face-v1.ttc` | Add exact licensed derivative. [VERIFIED: D-04/D-05] |
| 1 | `fixtures/font/dejavu-sans-2.37/collection-oracle.json` | Add independent TTC structural/checksum/lineage oracle. [VERIFIED: D-06] |
| 1 | `fixtures/manifest.json` | Append exact new provenance records; preserve every existing record. [VERIFIED: D-03/D-05] |
| 1 | `scripts/fixtures/Generate-FontQualification.ps1` | Add derivative writer, TTC oracle, collection schema/manifest validation, no-duplicate generated helper, and `-Check`. [VERIFIED: D-03-D-06] |
| 1 | `modules/mb-font/font/generated_font_qualification_test.mbt` | Regenerate from settled schemas; add only metadata/assembler/case mirrors. [VERIFIED: D-03] |
| 2 | `modules/mb-font/font/font_qualification_test.mbt` | Preserve existing tests; add generated/licensed public collection workflows. [VERIFIED: D-02/D-09] |
| 2 | `modules/mb-font/font/font_qualification_hostile_test.mbt` | Preserve 11 standalone cases; add public collection hostile/limit/budget/mutation dispatch. [VERIFIED: D-07-D-09] |
| 2 | `modules/mb-font/font/collection_wbtest.mbt` | Add named qualification aggregation for collection mid-operation hooks/arithmetic. [VERIFIED: existing hooks] |
| 2 | `modules/mb-font/font/font_wbtest.mbt` | Preserve and focus inherited query mutation hook identities if the runner filters them individually. [VERIFIED: lines 710-809] |
| 3 | `scripts/quality/Invoke-FontQualification.ps1` | Advance to v2 schema/directory/assertion list/negative probes while retaining ownership and comparison functions. [VERIFIED: D-10/D-11] |
| 3 | `scripts/quality/Test-FontQualificationEvidenceBoundary.ps1` | Advance marker/workflow fixtures and add v1-marker rejection. [VERIFIED: D-10] |
| 3 | `scripts/quality/Assert-Policy.ps1` | Update manifest/oracle/case schemas, exact test inventory, phase-neutral 85-line classifier, WOFF/variable negatives, and docs checks. [VERIFIED: D-12-D-14] |
| 3 | `policy/foundation.json` | Add fixture/test inventory facts as needed, preserve exact interface, update module description. [VERIFIED: D-01/D-13] |
| 3 | `modules/mb-font/moon.mod.json` | Match the updated bounded collection-aware description only. [VERIFIED: `Assert-Policy.ps1:2632-2633`; D-13] |
| 3 | `.github/workflows/quality.yml` | Point the existing job to v2 evidence and retain timeout pending measurement. [VERIFIED: D-11/D-13] |
| 3 | `modules/mb-font/README.mbt.md` | Add collection workflow/provenance/v2 command; remove stale collection exclusion. [VERIFIED: stale text at lines 383-393; D-14] |
| 3 | `modules/mb-font/CHANGELOG.md` | Add TTC/OTC inspection/selection/qualification and correct the collection exclusion while retaining candidate/unpublished status. [VERIFIED: stale text at lines 68-74; D-14] |

No production `.mbt` file should change unless a failing canonical case demonstrates a concrete defect, in which case the fix needs a focused regression and an explicit 85-line interface recheck. [VERIFIED: D-01]

## Plan Ordering and Dependencies

1. **Fixture/oracle/provenance slice:** settle the collection JSON schema and ordered IDs; implement the derivative/oracle; append manifest records; regenerate the MoonBit mirror; pass normal generation and `-Check`. All later tasks depend on these byte and identity contracts. [VERIFIED: D-15]
2. **Behavior/atomicity slice:** add public generated/licensed workflows, hostile/limit/budget dispatch, public mutation cases, and private mid-operation assertions; lock the standalone baseline by exact name/content. This slice depends on the generated mirror and must not edit production code unless a canonical failure proves a defect. [VERIFIED: D-01/D-02/D-07-D-09/D-15]
3. **Evidence/policy/CI/docs slice:** advance runner/boundary tests to v2, update policy/manifest/interface/source gates and descriptions, wire the existing CI job, run/measure all four targets, then update README/changelog with final identities/digests/commands. This slice depends on final fixture and test IDs. [VERIFIED: D-10-D-15]

Do not parallelize generator schema work with runner/policy schema consumers. A digest, key-order, or test-name change would force coordinated rewrites across every consumer. [VERIFIED: D-15]

## Verification Commands

Run from repository root in this order:

```powershell
./scripts/fixtures/Generate-FontQualification.ps1
./scripts/fixtures/Generate-FontQualification.ps1 -Check
./scripts/quality/Test-FixturePolicy.ps1
./scripts/quality/Test-FontQualificationEvidenceBoundary.ps1
pwsh -NoProfile -Command ". ./scripts/quality/Assert-Policy.ps1; Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json"
moon -C modules/mb-font check --target all --frozen
./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/font-v2
git diff --check
```

The final runner command must itself execute independent per-target checks, every named focused public/private assertion, full package tests, four README checks, record read-back, negative evidence probes, and canonical comparison. [VERIFIED: current runner behavior; D-11]

After the first complete CI-equivalent run, record elapsed time. Keep `timeout-minutes: 20` unless that measured run demonstrates inadequate headroom; if it does, increase only minimally and record the reason. [VERIFIED: D-13]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. All implementation defaults are prescribed from locked Phase 103 decisions and verified local code/fixture behavior. | — | — |

## Prescriptive Defaults

None. The only discovered reference mismatch is resolved prescriptively: the repository’s exact upstream notice is the existing `LICENSE` file, so no duplicate `NOTICE` should be introduced. [VERIFIED: current fixture tree and Phase 100 generator/manifest/docs]

## Sources

### Primary (HIGH confidence)

- `.planning/phases/103-hostile-licensed-and-four-target-qualification/103-CONTEXT.md` — locked D-01 through D-15 and canonical references.
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md` — TTC-04/TTC-05 and all five success criteria.
- Phase 101/102 context and verification artifacts — verified collection/selection behavior, atomicity, exact interface, and deferred Phase 103 scope.
- `.planning/milestones/v0.32-phases/100-portable-font-qualification/100-CONTEXT.md` — preserved standalone fixture/oracle/evidence design.
- `scripts/fixtures/Generate-FontQualification.ps1` — current generator, oracle, manifest, and generated-source implementation.
- `scripts/quality/Invoke-FontQualification.ps1` and `Test-FontQualificationEvidenceBoundary.ps1` — current evidence schema, ownership boundary, runner, normalization, and negatives.
- `scripts/quality/Assert-Policy.ps1`, `policy/foundation.json`, `.github/workflows/quality.yml` — API/dependency/source/CI contracts.
- `fixtures/font/dejavu-sans-2.37/{DejaVuSans.ttf,LICENSE,oracle.json}`, `fixtures/manifest.json`, and `docs/policies/licensing-and-fixtures.md` — exact bytes, independent facts, provenance, and redistribution policy.
- `modules/mb-font/font/{collection_test.mbt,collection_wbtest.mbt,font_wbtest.mbt,font_qualification_test.mbt,font_qualification_hostile_test.mbt}` — reusable builders, public equivalence, hostile boundaries, mutation hooks, and standalone qualification.

### Secondary (MEDIUM confidence)

None; no external research was needed because the locked local architecture and fixtures fully determine the phase.

### Tertiary (LOW confidence)

None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — locally installed versions and pinned repository workflow agree.
- Fixture/derivative architecture: HIGH — derived from exact committed bytes, audited oracle inventory, locked decisions, and a read-only deterministic construction/digest check.
- Hostile/mutation architecture: HIGH — every required category maps to existing passing public/private test seams.
- Evidence/policy architecture: HIGH — extends the current closed, four-target, managed-directory implementation directly.
- Licensing/provenance: HIGH — based on the repository’s exact license bytes, manifest, generator intake, and fixture policy.

**Research date:** 2026-07-28  
**Valid until:** 2026-08-27, or earlier if the fixture/schema/test identities change.
