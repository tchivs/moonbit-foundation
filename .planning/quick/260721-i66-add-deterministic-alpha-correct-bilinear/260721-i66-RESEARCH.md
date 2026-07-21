# Deterministic Alpha-Correct Bilinear Resize — Research

**Researched:** 2026-07-21  
**Scope:** Portable RGB8 and straight-RGBA8 bilinear resize in `mb-image/ops`.

## Recommendation

Add one public operation:

```moonbit
pub fn resize_bilinear(
  source : @storage.ImageView,
  width : UInt64,
  height : UInt64,
  budget : @budget.Budget,
) -> Result[ImageOperationResult, @error.CoreError]
```

Keep it in `modules/mb-image/ops/resize.mbt`, alongside `resize_nearest`. It must create fresh, tightly packed output, preserve the source metadata/disposition exactly as nearest resize does, and operate only on packed U8 encoded-sRGB RGB8-without-alpha and straight-RGBA8. [VERIFIED: codebase — `resize.mbt`, `copy_flip.mbt`, `README.mbt.md`]

For a transform that decodes to linear sRGB, additionally require `metadata.profile().is_builtin_srgb()`; reject an opaque/custom ICC profile or a non-sRGB transfer/space as `InvalidRange` with an `image-resize-bilinear-metadata` context, before budget charge. A resize must not claim alpha/color correctness by applying the sRGB transfer curve to data whose declared profile says otherwise. [VERIFIED: codebase — `processing.mbt`, `.planning/STATE.md`]

## Locked Sampling Contract

Use the existing nearest coordinate convention, not pixel-centre or endpoint-aligned coordinates:

```text
product   = checked(destination_index * source_extent)
low       = product / destination_extent
remainder = product % destination_extent
high      = min(low + 1, source_extent - 1)
t         = remainder / destination_extent
```

Then bilerp the four `(x_low/x_high, y_low/y_high)` samples with `t_x` and `t_y`. This is exactly compatible with the documented nearest base coordinate `min(source_extent - 1, floor(destination * source_extent / destination_extent))`; it deliberately means a `1×1` result samples the upper-left source coordinate rather than averaging the source. Clamp only the upper neighbour, so the final edge remains the final source sample. [VERIFIED: codebase — `resize.mbt:nearest_source_index`, `README.mbt.md`]

Do all index products and output geometry/work arithmetic with `@checked`; never compute indices by floating point. Convert only the already-bounded `remainder / destination_extent` fraction to `Double` for blending.

## Pixel Semantics

1. Load each source sample as linear-light, premultiplied RGBA.
   - RGB8: sRGB-decode RGB and use alpha `1.0`.
   - straight-RGBA8: reuse/extract the established `load_linear_premultiplied` sequence: dequantize alpha, sRGB-decode, then `@alpha.premultiply_normalized`.
2. Interpolate premultiplied linear R/G/B and alpha independently (horizontal then vertical is equivalent to the four bilinear weights).
3. For straight RGBA8, unpremultiply only after interpolation, sRGB-encode RGB, and quantize with the existing ties-to-even helpers. For RGB8, write the opaque RGB result directly after sRGB encoding. [VERIFIED: codebase — `processing.mbt`, `quantize.mbt`, `transfer.mbt`]

This prevents transparent saturated RGB from leaking into visible neighbours. Do **not** interpolate encoded bytes, interpolate straight RGB before premultiplication, or route the result through the encoded-alpha conversion helpers. [VERIFIED: codebase — `processing_wbtest.mbt`]

Package-private sampling/store helpers should be shared with `processing.mbt` (or moved to a new ops-internal file) rather than copied with subtly different transfer/quantization rules. The existing helpers are file-private today, so make the chosen shared helpers package-visible intentionally. [VERIFIED: codebase — `processing.mbt`]

## Checked Limits and Budget Contract

Follow `resize_nearest` preflight order:

1. capability/metadata gate;
2. reject zero destination axes with `InvalidDimensions` and an operation-specific context;
3. build output descriptor with checked `width*height`, row bytes, and storage bytes;
4. check `(width - 1) * source.width()` and `(height - 1) * source.height()` before any allocation; and
5. allocate once through `OwnedImage::new_operation`.

Set deterministic work to `checked(output_pixels * 4)`: every destination pixel reads four bilinear taps, matching the existing `box_blur` convention of one work unit per sampled tap. Pass it unchanged to `new_operation`, which authoritatively charges bytes, one allocation, dimensions, pixels, and work in one operation. A preflight failure must leave every budget field unchanged. [VERIFIED: codebase — `resize.mbt`, `processing.mbt:box_blur`, `storage/owned_image.mbt`, `resize_convert_wbtest.mbt`]

Suggested error naming: operation `image-resize-bilinear`; format context `image-resize-bilinear-format`; metadata context `image-resize-bilinear-metadata`; zero-axis context `zero-destination-axis`. Keep overflow errors from `@checked` intact rather than translating them after partial allocation.

## Concrete Test Plan

- Public test (`resize_convert_test.mbt`): RGB black→white, `2×1 → 3×1`, must yield `[0, 213, 255]` per channel. This proves linear-light filtering; encoded-byte averaging would give 170. The middle coordinate is `2/3` under the existing mapping and existing ties-to-even quantization produces 213. [VERIFIED: codebase — `quantize.mbt`, `transfer.mbt`, `resize.mbt`]
- White-box mapping test (`resize_convert_wbtest.mbt`): verify base, neighbour, and remainder for asymmetric upscale and downscale axes; explicitly lock `2×1 → 1×1` to source x=0 and `2×1 → 3×1` coordinates `(0, 0/3), (0, 2/3), (1, 1/3 clamped)`. This protects the nearest-compatible convention.
- Alpha correctness: straight RGBA `[255,0,0,0], [0,0,0,255]`, `2×1 → 3×1`. The middle must be `[0,0,0,170]`; a red fringe proves interpolation happened before premultiplication. Also assert RGB8 output is opaque-by-construction and has no alpha metadata. [VERIFIED: codebase — `processing_wbtest.mbt`]
- Identity/edge: `1×1 → N×M` is byte-identical; opaque straight RGBA has the same RGB values as RGB8 for equivalent input; last-neighbour clamping never reads out of bounds.
- Rejections/atomicity: zero width/height, unsupported U16/gray/premultiplied RGBA, non-sRGB/custom-profile input, output-byte limit, four-tap work limit, and checked-overflow dimensions. Assert exact error operation/context where established and full `Budget.remaining()` equality before/after each failure.
- Four-target: run the isolated ops tests on `js`, `wasm`, `wasm-gc`, and `native`; retain exact byte vectors, not tolerance assertions. [VERIFIED: codebase — `resize_convert_wbtest.mbt`, `modules/mb-image/README.mbt.md`]

## Pitfalls

- `supports_copy_flip` accepts premultiplied RGBA because copying preserves bytes; bilinear must not reuse it unchanged because this API is deliberately only RGB8 and **straight** RGBA8. [VERIFIED: codebase — `copy_flip.mbt`]
- `load_linear_premultiplied` and `store_linear_premultiplied` are RGBA-specific; RGB needs the opaque adapter and a three-channel writer.
- Reusing nearest's `work = output_bytes` undercharges relative to four taps; treating every channel as a separate tap would overcharge relative to existing processing conventions.
- Pixel-centre, endpoint-aligned, or fixed `0.5` coordinate shifts are valid alternative APIs but are breaking semantic differences from the already-documented nearest mapping; do not silently choose one.
- `resize_nearest` preserves all metadata. Bilinear may preserve orientation/opaque metadata, but it must fail closed unless the profile/transfer identify samples that can truthfully be decoded as sRGB. This aligns with the active PNG colour-fidelity constraint. [VERIFIED: codebase — `.planning/STATE.md`, `README.mbt.md`]

## Validation Commands

```powershell
moon test --target js modules/mb-image/ops
moon test --target wasm modules/mb-image/ops
moon test --target wasm-gc modules/mb-image/ops
moon test --target native modules/mb-image/ops
```

No external package is needed. This remains pure MoonBit and four-target portable. [VERIFIED: codebase — `AGENTS.md`, `modules/mb-image/README.mbt.md`]
