# Phase 10: Alpha-Correct Pixel Processing - Research

**Researched:** 2026-07-20  
**Domain:** Portable RGBA8 sRGB compositing and filtering in MoonBit  
**Confidence:** HIGH for the existing API surface and operation structure; MEDIUM for cross-target floating-point bit identity until the planned four-target run proves it.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)

- SIMD/GPU acceleration, separable/sliding-window optimization, and arbitrary filters belong after the portable reference contract is established.
- New codecs and quality interpolation remain outside Phase 10.
- End-to-end PPM examples and benchmarks belong to Phase 11.
</user_constraints>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RASTER-01 | Composite RGBA using alpha-correct source-over semantics. | Straight-RGBA8 gate; decode to linear, premultiply, source-over, unpremultiply, encode, then quantize. |
| RASTER-02 | Deterministic grayscale and alpha-aware box blur with checked dimensions and bounded storage. | Same linear-premultiplied pixel helpers; one output allocation, checked radius/window arithmetic, and atomic budget preflight. |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared models stay in MoonBit; no foreign implementation is needed for this reference phase. [VERIFIED: AGENTS.md]
- `mb-image/ops` must remain portable on `js`, `wasm`, `wasm-gc`, and `native`; it is explicitly configured for those four targets. [VERIFIED: modules/mb-image/ops/moon.pkg]
- Public packages have acyclic dependencies. `ops` already imports `mb-color/model`, `alpha`, and `profile`, so adding the existing `transfer` and `quantize` package imports preserves the module direction (`mb-image` -> `mb-color`). [VERIFIED: modules/mb-image/ops/moon.pkg]
- Public tests use `*_test.mbt`; internal/adversarial coverage uses `*_wbtest.mbt`. [VERIFIED: AGENTS.md; modules/mb-image/ops]
- No release automation or unpublished files are in scope. [VERIFIED: 10-CONTEXT.md]

## Summary

Implement the phase as three new `mb-image/ops` functions over **straight** packed `RGBA8`, sRGB, encoded-transfer input only: `composite_source_over`, `grayscale`, and `box_blur`. Their output remains straight `RGBA8`, encoded sRGB, with source metadata preserved and a non-lossy disposition that marks `color` transformed for all three operations. Restricting to straight inputs is the smallest correct public boundary: an existing premultiplied RGBA8 value is premultiplied in encoded space, while this phase needs linear-light premultiplication before blending or averaging. [VERIFIED: modules/mb-image/ops/copy_flip.mbt; modules/mb-image/ops/convert.mbt; modules/mb-color/alpha/alpha.mbt; modules/mb-color/transfer/transfer.mbt]

The internal representation must be normalized **linear-premultiplied** RGBA. For each input byte, create typed encoded components, dequantize via `@quantize.dequantize_encoded_srgb`/`@quantize.dequantize_alpha`, decode color via `@transfer.decode_srgb`, construct `@alpha.StraightNormalizedSrgba::linear`, and call `@alpha.premultiply_normalized`. Compute source-over or filter sums there. For the output, build `@alpha.PremultipliedNormalizedSrgba::linear`, call `@alpha.unpremultiply_normalized`, encode each linear component with `@transfer.encode_srgb`, and quantize with `@quantize.quantize_encoded_srgb` plus `@quantize.quantize_alpha`. This is the exact existing helper sequence that prevents an encoded-space shortcut. [VERIFIED: modules/mb-color/alpha/alpha.mbt; modules/mb-color/transfer/transfer.mbt; modules/mb-color/quantize/quantize.mbt]

**Primary recommendation:** Add private linear-premultiplied load/store helpers in `mb-image/ops`; expose straight-only operations and allocate one fresh tight output through `OwnedImage::new_operation` after all deterministic validation/preflight.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Source-over, grayscale, box blur | API / Backend (portable library) | Database / Storage | Pure MoonBit `ops` owns pixel transforms; `storage` only provides checked views and owned allocation. [VERIFIED: modules/mb-image/ops; modules/mb-image/storage] |
| Transfer conversion and quantization | API / Backend (`mb-color`) | — | Color package owns typed transfer domains and deterministic byte conversion. [VERIFIED: modules/mb-color/transfer/transfer.mbt; modules/mb-color/quantize/quantize.mbt] |
| Budget/resource accounting | API / Backend (`mb-core`) | Database / Storage | `OwnedImage::new_operation` applies the one authoritative storage/work charge against `Budget`. [VERIFIED: modules/mb-image/storage/owned_image.mbt; modules/mb-core/budget/budget.mbt] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `tchivs/mb-image/ops` | workspace `0.1.0` | Public raster operations | Existing result, capability, descriptor, and allocation conventions live here. [VERIFIED: modules/mb-image/moon.mod.json; modules/mb-image/ops/copy_flip.mbt] |
| `tchivs/mb-color/alpha` | workspace `0.1.0` | Typed straight/premultiplied RGBA contracts | Validates premultiplied invariants and canonical zero-alpha behavior. [VERIFIED: modules/mb-color/moon.mod.json; modules/mb-color/alpha/alpha.mbt] |
| `tchivs/mb-color/transfer` | workspace `0.1.0` | sRGB decode/encode | Carries encoded/linear component types through the conversion boundary. [VERIFIED: modules/mb-color/transfer/transfer.mbt] |
| `tchivs/mb-color/quantize` | workspace `0.1.0` | Deterministic ties-to-even byte quantization | Avoids target-specific casts/rounding for RGBA8 output. [VERIFIED: modules/mb-color/quantize/quantize.mbt] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `tchivs/mb-core/budget` | workspace `0.1.0` | Atomic resource charge | Pass caller budget to the one output allocation after preflight. [VERIFIED: modules/mb-core/budget/budget.mbt] |
| `tchivs/mb-core/checked` | workspace `0.1.0` | Checked dimensions/work arithmetic | Radius/window/output-size products and loop work estimates. [VERIFIED: modules/mb-image/ops/geometry.mbt; modules/mb-image/ops/resize.mbt] |
| `tchivs/mb-core/error` | workspace `0.1.0` | Typed deterministic diagnostics | Use existing `operation_error` shape and `CoreError` accessors. [VERIFIED: modules/mb-image/ops/copy_flip.mbt; modules/mb-core/error/core_error.mbt] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Linear-premultiplied processing | Existing `premultiply_encoded` / `unpremultiply_encoded` | Reject: those helpers intentionally perform encoded-byte conversion and would blend/filter in encoded space. [VERIFIED: modules/mb-color/alpha/alpha.mbt] |
| Straight-only public operations | Also accept encoded-premultiplied images | Reject for this phase: decoding encoded-premultiplied channels does not recover linear-premultiplied color. An explicit conversion/API contract would be a larger new boundary. [VERIFIED: modules/mb-color/alpha/alpha.mbt; modules/mb-image/ops/convert.mbt] |
| Direct box window reference loop | Sliding-window/separable buffers | Defer: it changes intermediate-storage and work semantics before the reference behavior is proven. [VERIFIED: 10-CONTEXT.md] |

**Installation:** None. This phase adds no external packages. [VERIFIED: modules/mb-image/moon.mod.json]

## Architecture Patterns

### System Architecture Diagram

```text
ImageView (straight RGBA8, encoded sRGB)
  -> capability + equal-dimension/radius + checked arithmetic preflight
  -> tight output descriptor + one OwnedImage::new_operation budget charge
  -> per pixel/window: byte -> typed encoded -> linear -> premultiplied
  -> source-over / luminance / alpha-aware average
  -> premultiplied linear -> straight linear -> encoded -> ties-even RGBA8
  -> ImageOperationResult (owned image + metadata disposition)
```

### Recommended Project Structure

```text
modules/mb-image/ops/
├── copy_flip.mbt            # retain shared result/error/descriptors and capability helpers
├── processing.mbt           # new public composite/filter APIs and private linear helpers
├── processing_test.mbt      # public behavior/metadata/diagnostic examples
└── processing_wbtest.mbt    # preflight, oracle, budget and hostile-input proof
```

### Pattern 1: Straight-RGBA8 capability gate

**What:** Add a private `supports_straight_rgba8_processing` gate requiring U8, packed, RGBA, sRGB, encoded transfer, and `Some(Straight)` alpha. It must reject an empty source before descriptor/allocation. [VERIFIED: modules/mb-image/ops/copy_flip.mbt; modules/mb-image/model/descriptor.mbt]

**When to use:** At the first line of every Phase 10 public operation; dimensions are then separately checked for compositing. [VERIFIED: modules/mb-image/ops/geometry.mbt; modules/mb-image/ops/resize.mbt]

### Pattern 2: Linear-premultiplied private pixel helper

**What:** Keep the conversion pipeline private in `processing.mbt`; do not add a public `mb-color` API unless more than this image operation requires it. Existing alpha types already validate the resulting premultiplied linear tuple. [VERIFIED: modules/mb-color/alpha/alpha.mbt]

**Exact load sequence:**

```moonbit
// Source: verified local mb-color contracts
let encoded_r = @quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(r))
let encoded_g = @quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(g))
let encoded_b = @quantize.dequantize_encoded_srgb(@color.EncodedSrgb8Component::from_byte(b))
let alpha = @quantize.dequantize_alpha(@color.EncodedAlpha8::from_byte(a))
let straight = @alpha.StraightNormalizedSrgba::linear(
  @transfer.decode_srgb(encoded_r), @transfer.decode_srgb(encoded_g),
  @transfer.decode_srgb(encoded_b), alpha,
)
let premultiplied = @alpha.premultiply_normalized(straight)
```

**Exact store sequence:** Construct `@alpha.PremultipliedNormalizedSrgba::linear(r, g, b, a)`, call `@alpha.unpremultiply_normalized`, extract `linear_rgb()`, then for each component call `@transfer.encode_srgb` followed by `@quantize.quantize_encoded_srgb`; encode coverage with `@quantize.quantize_alpha`. Handle the `Result` from the alpha constructors/converters by returning its typed `CoreError`. [VERIFIED: modules/mb-color/alpha/alpha.mbt; modules/mb-color/transfer/transfer.mbt; modules/mb-color/quantize/quantize.mbt]

### Pattern 3: One owned result and exact work charge

**What:** Build a tight descriptor from source dimensions and metadata, validate all input conditions, perform any operation-specific preflight that can fail, then call `OwnedImage::new_operation(descriptor, budget, allocator, work)` once and write through `with_mut_view`. [VERIFIED: modules/mb-image/ops/geometry.mbt; modules/mb-image/ops/convert.mbt; modules/mb-image/storage/owned_image.mbt]

**Work policy:** Composite and grayscale charge one work unit per output pixel. Blur must charge the checked sum of visited window samples (or a documented conservative upper bound) and must not allocate an intermediate image. The output allocation itself charges bytes, allocation count, width, height, pixels, and work atomically. [VERIFIED: modules/mb-core/budget/budget.mbt; modules/mb-image/storage/owned_image.mbt]

### Filter semantics to lock in code/docs

- `composite_source_over(source, destination, budget)` processes equal dimensions only; source is over destination. For every linear-premultiplied channel, `p = ps + pd * (1 - as)` and `a = as + ad * (1 - as)`. Output is **straight RGBA8 encoded sRGB** after the store sequence. [VERIFIED: 10-CONTEXT.md; modules/mb-color/alpha/alpha.mbt]
- `grayscale(source, budget)` preserves alpha exactly at normalized coverage before final quantization. Compute linear luminance `Y = 0.2126*r + 0.7152*g + 0.0722*b`, then use `(Y*a, Y*a, Y*a, a)` as the linear-premultiplied result. The coefficients are an implementation choice requiring an explicit code/doc decision before execution. [ASSUMED]
- `box_blur(source, radius, budget)` clamps every sample coordinate to image bounds (edge extension), sums linear-premultiplied RGB and alpha, divides all four by the fixed `(2r+1)^2` sample count, then stores through the same sequence. Averaging premultiplied color makes zero-alpha colored texels contribute zero color, preventing transparent-edge halos. [ASSUMED]

### Anti-Patterns to Avoid

- **Encoded-space alpha arithmetic:** `@alpha.premultiply_encoded`, byte sums, or encoded RGB averaging are not the phase’s linear-light composition/filter pipeline. [VERIFIED: modules/mb-color/alpha/alpha.mbt; modules/mb-color/transfer/transfer.mbt]
- **Filter straight RGB and alpha independently:** It gives invisible RGB nonzero weight after a blur and causes color fringes; average linear-premultiplied tuples instead. [ASSUMED]
- **Allocate before mismatch/radius/preflight validation:** It breaks the established unchanged-budget-on-known-failure contract. [VERIFIED: modules/mb-image/ops/resize_convert_wbtest.mbt; modules/mb-core/budget/budget.mbt]
- **Silently accept metadata/alpha mismatch:** return `CapabilityUnavailable` with operation-specific token; do not convert/crop/resize. [VERIFIED: 10-CONTEXT.md; modules/mb-image/ops/copy_flip.mbt]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Byte/normalized conversion | casts or `Double` scaling | `dequantize_*` / `quantize_*` | Existing ties-to-even policy is portable and typed. [VERIFIED: modules/mb-color/quantize/quantize.mbt] |
| sRGB transfer | local gamma approximation | `decode_srgb` / `encode_srgb` | Existing functions encode the established thresholds and typed domain boundary. [VERIFIED: modules/mb-color/transfer/transfer.mbt] |
| Premultiplied validity | ad-hoc `p <= a` checks | `PremultipliedNormalizedSrgba::linear` | Existing constructor returns typed `InvalidRange`. [VERIFIED: modules/mb-color/alpha/alpha.mbt] |
| Output resource charge | separate bytes/work counters | `OwnedImage::new_operation` | The allocation path delegates a complete atomic `ResourceCharge`. [VERIFIED: modules/mb-image/storage/owned_image.mbt; modules/mb-core/budget/budget.mbt] |

## Common Pitfalls

### Pitfall 1: Treating encoded premultiplication as alpha-correct compositing

**What goes wrong:** Output alpha follows source-over while color is visibly too dark/light around translucent pixels.  
**Why it happens:** `premultiply_encoded` uses byte-domain ratio rounding, whereas source-over must combine linear-light premultiplied values. [VERIFIED: modules/mb-color/alpha/alpha.mbt; modules/mb-color/transfer/transfer.mbt]  
**How to avoid:** Require straight input and use the exact load/store chain above.  
**Warning signs:** A quantization-sensitive translucent red-over-blue test equals a simple `byte * alpha / 255` oracle. [ASSUMED]

### Pitfall 2: Haloing at transparent blur boundaries

**What goes wrong:** Transparent pixels containing arbitrary RGB bleed a colored fringe into visible neighbors.  
**Why it happens:** Straight RGB was averaged before alpha weighting. [ASSUMED]  
**How to avoid:** Convert each sample to linear premultiplied form before summing; unpremultiply only once for the output.  
**Warning signs:** Blurring opaque white beside transparent red yields pink instead of neutral gray/white transition. [ASSUMED]

### Pitfall 3: Radius overflow or partial budget consumption

**What goes wrong:** `2*radius+1`, its square, or total work wraps; a known invalid request charges the caller budget.  
**Why it happens:** Radius-derived arithmetic and input validation are delayed until after output allocation.  
**How to avoid:** Use `@checked.checked_mul`/`checked_add` for radius/window/work before `new_operation`; preserve the full `Budget.remaining()` snapshot on every pre-allocation error. [VERIFIED: modules/mb-image/ops/geometry.mbt; modules/mb-image/ops/resize_convert_wbtest.mbt]

## Code Examples

### Source-over arithmetic after typed conversion

```moonbit
// Source: verified local alpha/transfer/quantize APIs
let inverse_source_alpha = 1.0 - source.alpha().value()
let output_alpha = @color.NormalizedAlpha::new(
  source.alpha().value() + destination.alpha().value() * inverse_source_alpha,
).unwrap()
let output = @alpha.PremultipliedNormalizedSrgba::linear(
  @color.LinearSrgbComponent::new(source_r.value() + destination_r.value() * inverse_source_alpha).unwrap(),
  @color.LinearSrgbComponent::new(source_g.value() + destination_g.value() * inverse_source_alpha).unwrap(),
  @color.LinearSrgbComponent::new(source_b.value() + destination_b.value() * inverse_source_alpha).unwrap(),
  output_alpha,
)
```

This is only the arithmetic core; production code must return constructor errors rather than `unwrap()` when an input-dependent path can fail. With inputs constructed from valid premultiplied values, the bounds are mathematically preserved; an internal test should still verify this. [VERIFIED: modules/mb-color/alpha/alpha.mbt]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic packed U8 reference operations accept straight or encoded-premultiplied RGBA. | Phase 10 processing gate is straight-only encoded RGBA8 and converts to linear-premultiplied internally. | Phase 10 plan | Correct alpha semantics without silently reinterpreting old encoded-premultiplied storage. [VERIFIED: modules/mb-image/ops/copy_flip.mbt; modules/mb-image/ops/convert.mbt] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Rec.709 linear luminance coefficients `0.2126/0.7152/0.0722` are the desired grayscale policy. | Filter semantics | Different documented policy changes expected pixels/API contract. |
| A2 | Clamp-to-edge is the desired box-blur boundary policy. | Filter semantics | Different edge policy changes border output. |
| A3 | Transparent colored pixels create halos only when straight RGB is averaged rather than premultiplied RGB. | Pitfalls | Test oracle/justification would need correction, though linear-premultiplied filtering remains the selected architecture. |

## Open Questions

1. **Lock grayscale coefficients and blur border policy in the Phase 10 plan.**
   - What we know: Existing contracts supply the color conversion pipeline but no grayscale/blur policy constants. [VERIFIED: modules/mb-color/alpha/alpha.mbt; modules/mb-color/transfer/transfer.mbt]
   - What's unclear: Whether the project prefers Rec.709 coefficients and clamp-to-edge over another deterministic policy.
   - Recommendation: Use the A1/A2 policies above, document them in `mb-image/README.mbt.md`, and add exact byte-vector tests before treating them as stable public behavior.

2. **Define a named radius upper bound independent of caller resource limits only if test/runtime evidence requires it.**
   - What we know: `Budget` can bound total work and `checked` can reject overflow. [VERIFIED: modules/mb-core/budget/budget.mbt; modules/mb-core/checked/checked.mbt]
   - What's unclear: Whether an extremely large but mathematically valid radius should be categorically invalid versus resource-limited.
   - Recommendation: Avoid an arbitrary new cap; use checked window/work preflight and return `BudgetExceeded` when the declared workload exceeds the caller budget.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | four-target tests | ✓ | local workspace toolchain | — |
| C toolchain / native target | native test leg | pending execution verification | — | no fallback; all four targets are required |

## Verification Plan

Create `processing_test.mbt` for public contracts and `processing_wbtest.mbt` for independent arithmetic/preflight proof, matching the adjacent Phase 9 split. Run `moon test modules/mb-image/ops --target js`, `wasm`, `wasm-gc`, and `native`; Phase 9 established these as the required four portable target legs. [VERIFIED: modules/mb-image/ops/*_test.mbt; modules/mb-image/ops/*_wbtest.mbt; 09-VERIFICATION.md]

| Behavior | Test level | Required oracle/assertion |
|----------|------------|---------------------------|
| Opaque source-over | public | Exact RGBA output equals source (with alpha 255) and output stays straight RGBA8. [ASSUMED] |
| Translucent/quantization-sensitive source-over | white-box | Independently execute decode → linear-premultiplied source-over → encode/quantize; assert it differs from an encoded-byte blend fixture. [ASSUMED] |
| Dimension and representation rejection | public + white-box | `CapabilityUnavailable`/operation-context or incompatible-dimensions `CoreError`; complete `Budget.remaining()` snapshot unchanged. [VERIFIED: modules/mb-image/ops/copy_flip_wbtest.mbt; modules/mb-image/ops/resize_convert_wbtest.mbt] |
| Grayscale alpha preservation | public | Alpha byte is preserved for an exactly representable alpha; RGB channels equal after the selected luminance policy. [ASSUMED] |
| Transparent-edge blur | white-box | Transparent saturated neighbor has zero premultiplied contribution; expected output has no color halo. [ASSUMED] |
| Radius/budget hostile inputs | white-box | Invalid/overflowing radius and insufficient bytes/allocations/work fail before `new_operation` charge. [VERIFIED: modules/mb-core/budget/budget.mbt; modules/mb-image/ops/resize_convert_wbtest.mbt] |

The config explicitly disables the formal Nyquist Validation Architecture section, but it does not relax the project’s four-target behavioral evidence requirement. [VERIFIED: .planning/config.json; REQUIREMENTS.md; 09-VERIFICATION.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Capability, dimensions, radius and checked arithmetic validation precede allocation. [VERIFIED: modules/mb-image/ops/geometry.mbt; modules/mb-image/ops/resize.mbt] |
| V6 Cryptography | no | No cryptographic operation. [VERIFIED: Phase 10 scope] |

### Known Threat Patterns for portable raster processing

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dimension/radius arithmetic overflow | Denial of service | Checked arithmetic before descriptor/allocation. [VERIFIED: modules/mb-image/ops/geometry.mbt; modules/mb-image/ops/resize.mbt] |
| Allocation/work exhaustion | Denial of service | One atomic `Budget` charge and unchanged counters on preflight rejection. [VERIFIED: modules/mb-core/budget/budget.mbt; modules/mb-image/storage/owned_image.mbt] |
| Mislabelled/unsupported pixel representation | Tampering | Straight-RGBA capability gate returns typed `CapabilityUnavailable`. [VERIFIED: modules/mb-image/ops/copy_flip.mbt; 10-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- Local `modules/mb-color/alpha/alpha.mbt` — typed normalized and encoded alpha representations plus conversion contracts.
- Local `modules/mb-color/transfer/transfer.mbt` and `quantize/quantize.mbt` — exact transfer and deterministic quantization APIs.
- Local `modules/mb-image/ops/convert.mbt`, `copy_flip.mbt`, `geometry.mbt`, and `resize.mbt` — capability/error/descriptor/allocation conventions.
- Local `modules/mb-image/storage/owned_image.mbt`, `views.mbt`, and `modules/mb-core/budget/budget.mbt` — owned write boundary and atomic charge behavior.
- `.planning/phases/09-checked-image-geometry-and-diagnostics/09-VERIFICATION.md` — verified four-target predecessor contract.

### Secondary (MEDIUM confidence)
- None; this research is deliberately grounded in the repository’s current public API rather than a third-party package.

### Tertiary (LOW confidence)
- A1-A3 in the Assumptions Log; confirm during plan review before locking external pixel-policy constants.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all components are present in the workspace and imported by adjacent code.
- Architecture: HIGH — follows existing `ops` allocation/result/error patterns and exact color APIs.
- Pitfalls: MEDIUM — encoded-space risk is source-verified; the proposed grayscale/border policy needs a project decision.

**Research date:** 2026-07-20  
**Valid until:** Stable until Phase 10 changes the referenced public API.
