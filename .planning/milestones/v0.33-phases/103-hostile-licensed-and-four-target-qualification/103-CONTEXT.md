# Phase 103: Hostile, Licensed, and Four-Target Qualification - Context

**Gathered:** 2026-07-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 103 closes v0.33 by turning the already implemented collection-to-`Font` behavior into immutable, provenance-tracked, independently checked qualification evidence. It may add fixtures, offline fixture/oracle generation, tests, evidence schemas/reports, policy gates, CI wiring, and documentation. It must not add public API or new runtime font capabilities. Production MoonBit changes are allowed only if the new TTC-04 evidence exposes a concrete correctness defect.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements and locked predecessor contracts

- `.planning/ROADMAP.md` — Phase 103 goal and five success criteria.
- `.planning/REQUIREMENTS.md` — TTC-04/TTC-05 plus deferred WOFF/CFF execution boundaries.
- `.planning/PROJECT.md` — v0.33 state, active qualification requirements, and ecosystem constraints.
- `.planning/phases/101-collection-contract-and-bounded-envelope/101-CONTEXT.md` — collection inspection and bounded envelope decisions.
- `.planning/phases/101-collection-contract-and-bounded-envelope/101-VERIFICATION.md` — verified collection-opening baseline.
- `.planning/phases/102-root-relative-selected-face-admission/102-CONTEXT.md` — selected-face decisions, especially D-17's Phase 103 boundary.
- `.planning/phases/102-root-relative-selected-face-admission/102-VERIFICATION.md` — verified root-relative selected-face baseline and review-fix evidence.

### Existing qualification design

- `.planning/milestones/v0.32-phases/100-portable-font-qualification/100-CONTEXT.md` — standalone fixture/oracle/evidence decisions that must remain compatible.
- `scripts/fixtures/Generate-FontQualification.ps1` — deterministic offline fixture intake, oracle generation, generated-source mirror, and `-Check` drift pattern.
- `scripts/quality/Invoke-FontQualification.ps1` — existing four-target runner, evidence ownership boundary, normalization, and semantic digest comparison.
- `scripts/quality/Test-FontQualificationEvidenceBoundary.ps1` — managed evidence-directory safety and negative boundary tests.
- `scripts/quality/Assert-Policy.ps1` — exact interface, dependency, source, target, fixture, workflow, and capability gates.
- `.github/workflows/quality.yml` — existing FontQualification CI job and evidence upload.
- `policy/foundation.json` — current 85-line interface, target/dependency policy, and module description.

### Licensed fixture and provenance policy

- `docs/policies/licensing-and-fixtures.md` — mandatory source, digest, license, redistribution, and expected-use metadata.
- `fixtures/manifest.json` — authoritative fixture inventory and confirmed redistribution records.
- `fixtures/font/dejavu-sans-2.37/LICENSE` — upstream reproduction, distribution, and modification terms.
- `fixtures/font/dejavu-sans-2.37/LICENSE` — exact upstream license/notice retained for both the source font and derivative; do not duplicate it as a new `NOTICE`.
- `fixtures/font/dejavu-sans-2.37/oracle.json` — independently produced standalone semantic facts reused by selected-face qualification.

### Public module documentation

- `modules/mb-font/README.mbt.md` — public workflow documentation that must gain collection examples and qualification commands.
- `modules/mb-font/CHANGELOG.md` — compatibility/boundary statements that must be corrected for the shipped collection adapter.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `FontCollection::open` / `FontCollection::open_face`: already verified public collection-to-`Font` workflow; qualification should consume it unchanged.
- `collection_test.mbt` and `collection_wbtest.mbt`: existing v1/v2, DSIG, sharing, mixed-profile, non-zero-base, mutation, precedence, and exact-budget builders/assertions to promote into named qualification cases.
- Phase 100 DejaVu fixture, oracle, generated test mirror, and hostile corpus: stable standalone baseline and licensed source lineage.
- `Generate-FontQualification.ps1`: existing deterministic generator/check seam suitable for the collection corpus and TTC derivative.
- `Invoke-FontQualification.ps1`: hardened four-target evidence runner and semantic digest comparator to evolve to v2.

### Established Patterns

- Canonical JSON/fixture input is mirrored into generated test-private MoonBit; portable tests never read repository files at runtime.
- Independent PowerShell oracle and policy paths prevent production MoonBit from certifying its own fixtures or public interface.
- Evidence schemas use closed keys, exact target order, managed directories, and negative fixtures for missing/divergent records.
- Public behavior is compared through opaque `Font` observations; private hooks are limited to deterministic mid-operation revision windows.

### Integration Points

- Fixture generator/intake connects DejaVu source bytes to the two-face TTC derivative, closed TTC oracle, generated collection mirror, and manifest drift check.
- Focused collection qualification tests connect generated/hostile cases to the current public and white-box APIs without widening production surface.
- FontQualification runner connects focused identities, full package execution, policy facts, and canonical v2 target records to CI evidence upload.
- README/changelog and `foundation.json` connect the shipped runtime contract to maintainers' reproducible qualification workflow.

</code_context>

<specifics>
## Specific Ideas

- Prefer a two-face exact-sharing DejaVu TTC v1 derivative over introducing a new upstream collection or a one-face wrapper.
- Keep the Phase 100 standalone fixture file and digest untouched; collection qualification has its own closed corpus and schema identity.
- Make WOFF absence an executable policy probe, not documentation-only wording.
- Preserve old v1 evidence rather than reusing or auto-deleting its directory; v2 owns a fresh managed path.

</specifics>

<deferred>
## Deferred Ideas

- WOFF1/WOFF2 decode/admission, CFF/CFF2 execution, variable-font execution, shaping, hinting, and rasterization remain future requirements.
- Registry publication and release-qualification policy changes remain outside v0.33.
- A new upstream licensed TTC may be considered in a later interoperability milestone if it adds distinct real-world coverage beyond the deterministic DejaVu derivative.

</deferred>

---

*Phase: 103-Hostile, Licensed, and Four-Target Qualification*
*Context gathered: 2026-07-28*
