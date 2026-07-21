# Phase 25: Portable Colour Conformance Evidence - Context

**Gathered:** 2026-07-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the shipped PNG colour-declaration behaviour independently reproducible on
js, wasm, wasm-gc, and native. This phase strengthens fixtures, quality
evidence, and public documentation; it does not add colour transforms.
</domain>

<decisions>
## Implementation Decisions

### Conformance Corpus
- **D-01:** Keep the existing declarative generator as the source of truth and
  add only independently assembled fixture cases needed to cover recognised
  grammar, precedence, ICC resource bounds, and split-IDAT equivalence.
- **D-02:** Assert observable metadata identities/opaque values, exact typed
  errors, image invisibility on rejection, and output/operation capability
  boundaries—not implementation-private helpers.

### Portable Evidence
- **D-03:** Use the PNG quality lane plus explicit all-target public package
  tests as the canonical proof; no CI/release automation is in scope.
- **D-04:** Add a deterministic split-IDAT equivalence matrix for legal colour
  declarations so chunk partitioning cannot change metadata or pixels.

### Documentation
- **D-05:** Document exactly that MNF preserves/identifies declarations but
  does not transform colour samples, and that retained non-sRGB inputs remain
  ineligible for reference operations and canonical PNG encoding.

### the agent's Discretion

Choose compact fixture partition schedules and documentation placement while
preserving generator provenance and the existing package policy.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` §Phase 25 — goal and success criteria.
- `.planning/REQUIREMENTS.md` §PNGCM-05 — portable evidence requirement.
- `.planning/phases/24-bounded-non-srgb-and-icc-preservation/24-VERIFICATION.md` — verified metadata/resource/capability behaviours to prove.
- `fixtures/png/decode-cases.json` and `scripts/fixtures/Generate-PngDecodeVectors.ps1` — independent fixture source and oracle.
- `modules/mb-image/png/png_test.mbt` — public decoder evidence harness.
- `scripts/quality/Invoke-MoonQuality.ps1` — portable PNG quality lane.
</canonical_refs>

<code_context>
## Existing Code Insights

- The generator already emits 3,780 public decoder vectors with grammar,
  precedence, ICC header/resource, and manifest checks.
- `PngDecoder`, `ImageDescriptor::supports_reference_operations`, and
  `PngEncoder` expose the observable metadata and typed-capability boundaries.
- The PNG quality lane already runs generator freshness, policy/isolation, and
  all four targets; Phase 25 must make its coverage explicit and complete.
</code_context>

<specifics>
## Specific Ideas

Automatic choice: favor compact reproducible evidence and clear public wording
over new colour APIs, transforms, FFI, release work, or registry automation.
</specifics>

<deferred>
## Deferred Ideas

Full ICC transforms, cICP/HDR, profile conversion, canonical encoder metadata
preservation, public streaming, release automation, and registry work remain
out of scope.
</deferred>
