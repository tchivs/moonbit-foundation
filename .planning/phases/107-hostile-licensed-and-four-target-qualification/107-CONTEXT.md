# Phase 107: Hostile, Licensed, and Four-Target Qualification - Context

**Gathered:** 2026-07-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 107 closes v0.34 by turning the already implemented static CFF1 admission, Type 2 validation, cubic outline, standalone `Font`, and selected `FontCollection` behavior into immutable, provenance-tracked, independently checked qualification evidence. It may add generated and licensed fixtures, offline fixture/oracle tooling, public and white-box qualification tests, hostile matrices, native performance baselines, closed evidence schemas, policy gates, CI wiring, and documentation. It must not add public API or new runtime font capabilities. Production MoonBit changes are allowed only when qualification exposes a concrete correctness defect.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract and predecessor guarantees

- `.planning/ROADMAP.md` — Phase 107 goal, CFF-06, and four success criteria.
- `.planning/REQUIREMENTS.md` — complete CFF-06 qualification contract and deferred capability boundaries.
- `.planning/PROJECT.md` — v0.34 ecosystem, portability, compatibility, performance, and governance constraints.
- `.planning/phases/104-cff1-profile-and-bounded-data-model/104-CONTEXT.md` and `104-VERIFICATION.md` — frozen CFF1 profile, structural bounds, keying, and atomic admission.
- `.planning/phases/105-bounded-type-2-validation-and-retained-metrics/105-CONTEXT.md` and `105-VERIFICATION.md` — Type 2 VM, resource, retained bounds, and metric authority.
- `.planning/phases/106-cubic-path-and-public-ttc-integration/106-CONTEXT.md` and `106-VERIFICATION.md` — cubic publication, standalone/collection routing, atomicity, and static-glyf compatibility.

### Existing qualification architecture

- `.planning/milestones/v0.33-phases/103-hostile-licensed-and-four-target-qualification/` — closest fixture/oracle/hostile/four-target architectural analog.
- `scripts/fixtures/Generate-FontQualification.ps1` — deterministic offline intake, independent oracle, generated MoonBit mirror, manifest, and `-Check` drift seam.
- `scripts/quality/Invoke-FontQualification.ps1` — isolated four-target runner, managed evidence ownership, closed records, and semantic comparison.
- `scripts/quality/Test-FontQualificationEvidenceBoundary.ps1` — destructive-boundary and schema negative patterns.
- `scripts/quality/Assert-Policy.ps1`, `policy/foundation.json`, and `.github/workflows/quality.yml` — source/interface/dependency/fixture/workflow gates and CI lane.
- `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1`, `scripts/quality/Test-BenchmarkQualification.ps1`, and `docs/benchmarks/mb-svg-native-release-baseline.md` — native observation-only benchmark and read-only audit pattern.

### Fixture and licensing policy

- `docs/policies/licensing-and-fixtures.md` — mandatory source, digest, license, redistribution, derivative, and expected-use metadata.
- `fixtures/manifest.json` — authoritative fixture inventory.
- `fixtures/font/dejavu-sans-2.37/` — existing licensed source/derivative/oracle lineage pattern that must remain intact.

### Current CFF evidence seams

- `modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt`
- `modules/mb-font/font/cff_cid_fixture_wbtest.mbt`
- `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt`
- `modules/mb-font/font/cff_type2_fixture_wbtest.mbt`
- `modules/mb-font/font/cff_type2_wbtest.mbt`
- `modules/mb-font/font/cff_type2_bounds_wbtest.mbt`
- `modules/mb-font/font/cff_type2_path_wbtest.mbt`
- `modules/mb-font/font/font_test.mbt`
- `modules/mb-font/font/font_wbtest.mbt`
- `modules/mb-font/font/collection_test.mbt`
- `modules/mb-font/font/collection_wbtest.mbt`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- The Phase 103 generator/runner/policy pipeline already owns canonical fixture intake, offline independent oracles, generated portable mirrors, exact manifest drift, closed evidence records, semantic normalization, safe managed-directory cleanup, and CI upload.
- Name-keyed, two-FD CID, hostile structural, Type 2, path, mutation, standalone, and shared-CFF collection builders already cover the runtime seams that Phase 107 must promote into a minimal canonical matrix.
- `font_qualification_test.mbt` and `font_qualification_hostile_test.mbt` already provide public qualification identities and closed structured-result patterns.
- Phase 94 benchmark tooling already provides correctness-gated native-release timing, statistics, host/toolchain identity, and read-only reconstruction.

### Established Patterns

- Canonical JSON/binary input is validated independently, mirrored into generated test-private MoonBit, and checked byte-for-byte by a read-only generator mode.
- Production MoonBit never certifies its own expected fixture facts; public tests observe only opaque `Font`/`FontCollection` APIs.
- Closed evidence validates exact keys, values, ordering, target count/order, toolchain and fixture identities, then compares an explicit semantic projection.
- Portable targets run independently in fresh target directories; benchmark timing is a distinct native-only evidence product.

### Integration Points

- `Generate-FontQualification.ps1` connects generated recipes and licensed Source-family bytes to provenance, host oracles, manifest facts, and portable MoonBit mirrors.
- Public/white-box qualification files connect canonical cases to standalone/collection APIs and narrow deterministic mutation hooks.
- `Invoke-FontQualification.ps1` connects focused assertions, complete package runs, exact four-target semantic records, policy facts, and CI evidence.
- A dedicated CFF benchmark package/script/document connects immutable licensed workloads and correctness digests to native release observations without entering runtime dependencies.

</code_context>

<specifics>
## Specific Ideas

- Prefer a small official Latin static CFF1 OTF and a deterministic CJK subset only when the subset provably retains multiple FDs and local Subrs; otherwise commit a bounded full official asset.
- Use fixed public GID lists that cross CJK FDSelect ranges and include at least one high GID, rather than timing glyph discovery or shaping.
- Preserve the v2 evidence directory and records as historical artifacts; v3 owns a fresh marker and path.
- Keep the current 85-line public API as an equality-bearing evidence fact, not a manually maintained prose claim.

</specifics>

<deferred>
## Deferred Ideas

- CFF2/variation execution, deprecated seac composition, WOFF1/WOFF2, shaping/bidi, hint rendering, rasterization, color/bitmap glyphs, authoring, discovery, FFI, and ambient I/O remain outside v0.34.
- Performance thresholds, cross-library comparisons, release blocking based on timing, and registry publication policy changes remain future work.

</deferred>

---

*Phase: 107-hostile-licensed-and-four-target-qualification*
*Context gathered: 2026-07-29*
