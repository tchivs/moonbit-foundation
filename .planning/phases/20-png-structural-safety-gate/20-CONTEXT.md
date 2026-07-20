# Phase 20: PNG Structural Safety Gate - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the public PNG package boundary and strictly validate the supported
PNG profile's signature, chunk structure, integrity, metadata policy, and
resource envelope before Phase 21 introduces DEFLATE or image output.

</domain>

<decisions>
## Implementation Decisions

### Supported Profile
- **D-01:** v0.6 accepts only non-interlaced 8-bit truecolour PNG: colour type
  2 (RGB) or 6 (RGBA), compression/filter method 0. Other profiles are typed
  capability/data failures rather than lossy conversions.
- **D-02:** The public codec surface remains the established eager
  `ImageDecoder`/`ImageEncoder` model. This phase may establish `png` public
  types and a non-consuming probe, but it must not add public push/pull PNG
  streaming APIs.

### Structural Integrity
- **D-03:** Require the PNG signature, exactly one first IHDR, checked positive
  dimensions, contiguous IDAT, exactly one empty terminal IEND, CRC-32 over
  every processed chunk, and no post-IEND trailing input.
- **D-04:** Unknown critical chunks fail. Known colour-, transparency-,
  palette-, animation-, or HDR-affecting chunks fail. Unknown ancillary chunks
  are CRC-checked and may be discarded only when opaque metadata preservation
  is disabled; preservation requested fails rather than silently losing data.

### Safety and Evidence
- **D-05:** Probe is non-consuming and bounded. Derived chunk, geometry,
  pixel, output, work, allocation, and input values use the existing checked
  arithmetic, limits, budget, and diagnostics contracts before any future
  image allocation or output exposure.
- **D-06:** Keep fixtures small and provenance-tagged. Phase 20 must include
  hostile signature/chunk/order/CRC/IEND/trailing and limit cases; legal
  DEFLATE, filters, and public workflow evidence belong to Phases 21–22.

### the agent's Discretion

Choose private parser types, exact error helper reuse, and the smallest module
layout that preserves acyclic dependencies and four-target portability.

</decisions>

<canonical_refs>
## Canonical References

### Milestone scope
- `.planning/REQUIREMENTS.md` — PNG-01 through PNG-03 acceptance scope.
- `.planning/ROADMAP.md` — Phase 20 goal and success criteria.
- `.planning/research/SUMMARY.md` — accepted PNG subset, integrity policy, and
  phase boundaries.

### Existing contracts
- `modules/mb-image/codec/contracts.mbt` — eager codec, probe, limits,
  diagnostics, and result contracts.
- `modules/mb-image/qoi/decode.mbt` and `modules/mb-image/qoi/qoi.mbt` —
  bounded codec and public package patterns.
- `modules/mb-image/ppm/parser.mbt` and `modules/mb-image/ppm/decode.mbt` —
  forward-only parser and strict decode patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mb-core/checked`, `budget`, `bytes`, and `io`: checked calculations,
  resource accounting, byte views, and short-progress-safe I/O.
- `mb-image/codec`, `storage`, `metadata`, and `mb-color`: public image,
  capability, error, and disposition contracts.

### Established Patterns
- QOI keeps public eager traits stable while private state machines implement
  strict bounded parsing.
- QOI and PPM tests exercise public behavior in `*_test.mbt`, invariants in
  `*_wbtest.mbt`, and all four targets through package tests.

### Integration Points
- New `tchivs/mb-image/png` depends on existing image contracts and later on
  private `tchivs/mb-image/deflate`; neither may introduce FFI or reverse
  dependencies.

</code_context>

<specifics>
## Specific Ideas

No specific UI or wire-format preference beyond strict deterministic behavior;
use the smallest standards-conformant RGB/RGBA subset.

</specifics>

<deferred>
## Deferred Ideas

Palette, grayscale, `tRNS`, 16-bit, Adam7, colour-management/HDR metadata,
APNG, public PNG streaming, compression optimization, benchmarks, FFI, and
release/registry work are outside Phase 20 and v0.6 where stated in
`REQUIREMENTS.md`.

</deferred>

---

*Phase: 20-png-structural-safety-gate*
*Context gathered: 2026-07-20*
