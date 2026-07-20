# Phase 10: Alpha-Correct Pixel Processing - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Add portable reference pixel processing to `mb-image/ops`: source-over compositing, grayscale, and alpha-aware box blur. The phase builds on Phase 9 geometry and the existing straight/premultiplied RGBA conversion contracts; it does not add codecs, new resize kernels, GPU paths, or release automation.

</domain>

<decisions>
## Implementation Decisions

### Compositing semantics
- **D-01:** Expose a deterministic source-over operation for equal-dimension RGBA8 sRGB images; source is composited over destination and returns a new owned result under the supplied budget.
- **D-02:** Compositing must honor alpha mathematically: use premultiplied-alpha arithmetic internally and produce an explicitly documented output alpha representation. The researcher must select the existing color-transfer/quantization helpers required to prevent encoded-space shortcuts from masquerading as alpha correctness.
- **D-03:** Inputs with unsupported formats, alpha representations, dimensions, or metadata compatibility fail with typed deterministic `CoreError`; no implicit conversion, cropping, or resizing occurs.

### Filters
- **D-04:** Grayscale is deterministic and preserves alpha semantics. It should use a documented luminance policy compatible with the chosen composite color representation.
- **D-05:** Box blur is alpha-aware so transparent colored pixels cannot create edge halos. It uses a bounded reference implementation and validates radius/dimensions/budget before allocating output.
- **D-06:** This phase prioritizes correctness and reproducibility over optimized sliding windows, SIMD, or quality-tunable kernels.

### the agent's Discretion
- Exact public API names, whether operations accept straight-only or explicit straight/premultiplied variants, and the smallest reusable helpers should follow existing `mb-image/ops` and `mb-color` public contracts.
- Tests must include transparent/opaque edge cases, quantization-sensitive pixels, mismatched dimensions, unsupported forms, invalid radii, and budget atomicity.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/PROJECT.md` — code-first and portable foundation priorities.
- `.planning/REQUIREMENTS.md` — RASTER-01 and RASTER-02 acceptance scope.
- `.planning/ROADMAP.md` — Phase 10 goal and success criteria.
- `.planning/phases/09-checked-image-geometry-and-diagnostics/09-VERIFICATION.md` — completed geometry boundary that this phase builds on.

### Existing color and image contracts
- `modules/mb-color/alpha/alpha.mbt` — straight/premultiplied RGBA8 representations and deterministic conversions.
- `modules/mb-color/transfer/transfer.mbt` — sRGB transfer behavior available to reference operations.
- `modules/mb-color/quantize/quantize.mbt` — deterministic quantization helpers.
- `modules/mb-image/ops/convert.mbt` — image-level alpha conversion, capability, metadata disposition, budget, and error patterns.
- `modules/mb-image/ops/copy_flip.mbt` — `ImageOperationResult` and operation allocation conventions.
- `modules/mb-image/model/descriptor.mbt` — image format and alpha metadata invariants.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `@alpha.premultiply_encoded` / `unpremultiply_encoded` and the typed RGBA8 component contracts provide deterministic alpha conversion.
- `convert_pixel_image` demonstrates capability checks, metadata handling, output descriptor construction, budget preflight, and pixel loops.
- `OwnedImage::new_operation` and `with_mut_view` are the mandatory owned-output write boundary.

### Established Patterns
- Reference operations are portable MoonBit loops over packed U8 sRGB images and return `Result[..., @error.CoreError]`.
- Public tests and white-box adversarial tests live side-by-side in `modules/mb-image/ops`.
- Unsupported or invalid inputs fail before output allocation whenever preflight can prove failure.

### Integration Points
- New composite/filter APIs and tests belong in `modules/mb-image/ops`; any required color transfer and quantization calls must use existing `mb-color` package APIs.

</code_context>

<specifics>
## Specific Ideas

The user prioritized real code and tests. Phase 10 therefore supplies reference-quality raster operations with explicit semantics, not a release process or a performance claim.

</specifics>

<deferred>
## Deferred Ideas

- SIMD/GPU acceleration, separable/sliding-window optimization, and arbitrary filters belong after the portable reference contract is established.
- New codecs and quality interpolation remain outside Phase 10.
- End-to-end PPM examples and benchmarks belong to Phase 11.

</deferred>

---

*Phase: 10-Alpha Correct Pixel Processing*
*Context gathered: 2026-07-20*
