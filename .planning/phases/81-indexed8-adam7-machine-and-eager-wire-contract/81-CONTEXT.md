# Phase 81: Indexed8 Adam7 Machine and Eager Wire Contract - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Add an explicit, bounded Type-3/8 Adam7 route for the existing immutable `PngIndexedImage` in the sole acknowledged PNG encoder machine. Preserve legacy non-interlaced Indexed8 and low-bit APIs and bytes. Phase 82 owns hostile caller-buffered lifecycle qualification.

</domain>

<decisions>
## Implementation Decisions

### Public layout selection

- **D-01:** Add opt-in Indexed8 interlace selection using the established public `PngInterlaceStrategy`; retain `encode_indexed8` and `new_indexed8` as explicit `None` compatibility wrappers. — **Reversibility:** costly — changing those frozen wrappers would alter published call sites and canonical byte vectors.
- **D-02:** Restrict this phase to Type-3/8. Indexed Type-3/1, /2, and /4 Adam7 stays deferred until packed pass traversal has a separately proven bounded contract.

### Traversal and boundedness

- **D-03:** Reuse `_png_adam7_passes(width, height, 1UL, 8)` as the only pass-geometry authority. Read source samples with scalar `PngIndexedImage::index_at` at mapped pass coordinates; share geometry only, never coerce indexed images to `ImageView`.
- **D-04:** Extend the existing profile-aware `PngEncodeMachine` and its checked preflight/facts path. Do not introduce a second encoder, pass/image/output staging, new filter/compression strategies, or generic model widening.
- **D-05:** Derive every nonempty Adam7 row's filter tag, scanline/frame/work/output facts, limit admission, and sole budget charge before any eager output. Exact limits pass; one-less failure is atomic.

### Wire and proof

- **D-06:** The Adam7 wire contract remains Stored DEFLATE plus filter None, with `IHDR → PLTE → optional shortest canonical tRNS → IDAT → IEND` and valid CRCs.
- **D-07:** Use a hand-authored non-symmetric 5×5 Indexed8 fixture whose all seven passes are nonempty. Its inflated raw pass raster is an independent test oracle, never generated through production traversal helpers.
- **D-08:** Preserve the existing opaque and transparent Indexed8 non-interlaced literal vectors and all Indexed1/2/4 literal vectors as compatibility evidence.

### the agent's Discretion

- Factor a geometry-only internal location helper only if it keeps the existing ImageView Adam7 path and indexed scalar path clear and avoids duplicated pass arithmetic.
- Choose the exact additive method spelling consistent with established selector families, after confirming the current public API patterns during research.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/REQUIREMENTS.md` — INDEXADAM7-01 through INDEXADAM7-04 and fixed exclusions for this phase.
- `.planning/ROADMAP.md` — Phase 81 goal, scope guard, and observable success criteria.
- `.planning/research/v026-ADAM7-SUMMARY.md` — accepted API, pass-oracle, preflight, and test recommendations.

### Prior indexed and Adam7 decisions
- `.planning/milestones/v0.25-REQUIREMENTS.md` — completed Indexed8/low-bit contracts and the deferred packed Adam7 boundary.
- `.planning/milestones/v0.25-phases/79-indexed-low-bit-eager-packing/79-SUMMARY.md` — selected indexed machine path and compatibility baseline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-image/png/encode.mbt`: the profile-aware `PngEncodeMachine`, checked frame facts, Indexed8 source/profile construction, and Adam7 production traversal.
- `modules/mb-image/png/stream_encode.mbt`: caller-buffered facade that must remain a thin route over the same machine.
- `modules/mb-image/png/encode_test.mbt` and `encode_wbtest.mbt`: eager wire, resource, and legacy-freeze evidence anchors.

### Established Patterns
- Explicit Adam7 is additive and leaves non-interlaced public entry points and byte vectors frozen.
- Preflight is atomic and consumes a caller budget exactly once only after all checked facts are admitted.
- Stored/filter-None indexed output carries PLTE and optional canonical tRNS in the shared machine.

### Integration Points
- Thread `PngInterlaceStrategy` through the indexed profile constructor/preflight and scanline cursor; leave legacy Indexed8 wrapper selection fixed to `None`.
- Add the scalar indexed Adam7 row read at the existing machine's scanline-byte seam.

</code_context>

<specifics>
## Specific Ideas

No additional product behavior: the feature is a narrow extension of the existing explicit Adam7 family, with code and independent tests prioritized over release automation.

</specifics>

<deferred>
## Deferred Ideas

Indexed low-bit Adam7, adaptive filters, Fixed/Dynamic indexed compression, palette generation, quantization, dithering, staging buffers, FFI, wrappers, copied source trees, and release automation are outside this phase.

</deferred>

---
*Phase: 81-indexed8-adam7-machine-and-eager-wire-contract*
*Context gathered: 2026-07-24*
