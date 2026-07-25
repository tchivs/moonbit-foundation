# RFC 0008: mb-canvas Layer and Group Opacity

- **Status:** Proposed
- **Authors:** MNF contributors
- **Created:** 2026-07-25
- **Target:** Graphics Layer raster-layer extension to `tchivs/mb-canvas` (RFC 0003)
- **Discussion:** To be established
- **Normative process:** [RFC process](../governance/rfc-process.md)
- **Authority / project owner:** `sole-project-owner`

> The acceptance-machinery header fields this RFC previously carried (acceptance route, maintainer approvals, blocking objections, public review window, acceptance evidence) were removed on 2026-07-23 when the RFC process was simplified to `Draft -> Proposed` for this sole-owner project. A Proposed RFC is now sufficient to proceed. See the [RFC process](../governance/rfc-process.md).

## Transition history

| From | To | Evidence |
|---|---|---|
| — | Draft | Initial RFC in repository history |
| Draft | Proposed | This revision resolves the two Draft open questions — the offscreen write-back strategy (§5: in-place source-over, reusing the rasterizer's existing `porter_duff_composite` per-pixel path) and the layer nesting-depth cap (§7: 16) — and concretizes the verification plan (§10). Repository history is the transition record |

No transition to Rejected or Superseded has occurred. Under the simplified RFC process the lifecycle is `Draft -> Proposed`; a Proposed RFC is sufficient to proceed. Every future transition must update this ledger.

## 1. Abstract

This RFC proposes a **capability extension** to the `tchivs/mb-canvas` module chartered by [RFC 0003](0003-mb-canvas.md): two new drawing-list operations, `PushLayer(opacity)` and `PopLayer`, that give the rasterizer an explicit raster-layer (offscreen-composite) primitive. On `PushLayer` the rasterizer allocates a transparent offscreen surface of the current target's dimensions, switches subsequent rasterization onto it, and on `PopLayer` composites that surface back onto the parent target through `mb-image/ops::composite_source_over` scaled by the layer's opacity. This is the precise primitive required to honor SVG group and element `opacity` (SVG 1.1 §14.4), which is the single remaining deferred item of [RFC 0002](0002-mb-svg.md) §6.1.

This RFC is **not** a new module charter. It does not modify RFC 0003's module boundary, public dependency direction, or portability seam; it extends the `DrawOp` set and the rasterizer's target management, both of which RFC 0003 §5 and §6 already scope to canvas. The v0.x surface is deliberately narrow — opacity-only layer compositing — and explicitly excludes blend modes, filters, and masking, all of which RFC 0003 §7.2 already defers.

## 2. Relationship to RFC 0001, RFC 0003, and RFC 0002

[RFC 0001](0001-moonbit-native-foundation.md) Section 5 places `mb-canvas` in the Graphics Layer and authorizes portable MoonBit raster operations (Section 4.1). This RFC operates entirely within that authorization.

[RFC 0003](0003-mb-canvas.md) is the charter this RFC extends. It already anticipates raster layer blending:

- §5.2 enumerates the drawing-list operations (fill, stroke, transform push/pop, clip push/pop) — this RFC adds layer push/pop to that enumeration.
- §6.1 states the reference rasterizer "does not allocate its own pixel store; it borrows the caller's raster surface." This RFC confronts that constraint directly: a raster layer requires a temporary offscreen surface, which is a **bounded exception** to §6.1's no-allocation rule, scoped to `PushLayer`/`PopLayer` and bounded by `mb-core/budget` (see §3.2, §7).
- §7.1 includes "Compositing delegation to `mb-image/ops::composite_source_over` for raster layer blending" — the layer primitive this RFC defines is exactly the canvas-side consumer of that delegated compositing path.
- §7.2 defers "Advanced blend modes beyond source-over at the raster-raster layer; image owns that surface." This RFC respects that deferral: it carries opacity (a scalar multiplier on source-over), not blend modes.

[RFC 0002](0002-mb-svg.md) §6.1 lists "Opacity: group and element opacity through bounded alpha composition" as in-scope for `mb-svg`. The `mb-svg` implementation records group opacity as deferred specifically because `mb-canvas` has no layer abstraction (see `modules/mb-svg/svg/lower.mbt` header). This RFC is the unblock path for that item.

This RFC does not modify RFC 0003's text. It references it normatively and, once Proposed, authorizes the `DrawOp` extension described in §4.

## 3. The layer problem and its resolution

### 3.1 Why a layer primitive is required

SVG 1.1 §14.4 defines group `opacity` as: the group's content is rendered as if `opacity` were 1, and then the rendered group result is composited onto the backdrop at the given opacity. Concretely, for a group containing several possibly-overlapping shapes:

1. shapes inside the group composite **with each other** at full opacity (their own `fill-opacity`/`stroke-opacity` applies, but the group `opacity` does not);
2. only the final, fully-resolved group result is multiplied by the group `opacity` and composited onto the backdrop.

Any approximation that pushes the group `opacity` down into each child shape's paint alpha diverges from this whenever two semi-transparent shapes overlap inside the group: the approximation pre-multiplies the group opacity into the intra-group compositing, darkening or over-transparenting the overlap. The divergence is not a rounding error; it is a semantic difference visible on common inputs (e.g. two overlapping 50%-fill-opacity circles inside a 50%-opacity group). The `mb-svg` lowering layer documents and rejects this approximation. Precise semantics require an offscreen intermediate: render the group to its own surface, then composite that surface once at the group opacity. That intermediate is a raster layer, and it belongs to the rasterizer (`mb-canvas`), not the document layer (`mb-svg`), because it is a property of how a drawing list becomes pixels, not of SVG semantics.

### 3.2 Tension with RFC 0003 §6.1 ("the rasterizer does not allocate")

RFC 0003 §6.1 deliberately constrains the reference rasterizer to borrow the caller's surface and allocate no pixel store of its own. This keeps the rasterizer's memory footprint caller-controlled and its determinism simple. A raster layer breaks that constraint: the offscreen surface is rasterizer-allocated temporary state.

This RFC resolves the tension as a **bounded, budget-controlled exception**, not a repeal of §6.1:

- Allocation occurs **only** at `PushLayer` and is released at `PopLayer`; the rasterizer's primary target remains borrowed for the entire render, exactly as §6.1 requires.
- Every offscreen allocation is charged against the render's `mb-core/budget` (bytes and pixels dimensions); an exhausted budget yields a structured error before allocation, consistent with RFC 0001 §10 and the bounds posture already applied in `mb-svg` (RFC 0002 §8.1).
- Layer nesting depth is bounded (see §7), so a hostile drawing list cannot induce unbounded layer stacks.

The net effect is that §6.1's guarantee — "the rasterizer does not silently allocate unbounded pixel store against the caller's wishes" — is preserved in spirit: layer allocation is explicit (an opt-in `DrawOp`), bounded (budget), and transient (push/pop scoped). This scoped exception is recorded here so RFC 0003's §6.1 text is not silently contradicted by implementation.

## 4. DrawOp extension (the core contract)

Two variants are added to the `DrawOp` enum (RFC 0003 §5.2):

- `DrawOp::PushLayer(opacity : Double)` — begin a raster layer. `opacity` is the straight-alpha multiplier applied when the layer is composited back, clamped to `[0, 1]` (NaN clamps to 0), matching the clamp policy of `FillStyle::with_alpha`. Rasterization semantics: allocate a transparent RGBA8 offscreen `OwnedImage` of the current render target's dimensions, push it onto the render-target stack, and direct subsequent rasterization onto it. The layer inherits the current transform and clip state at the point of `PushLayer`.
- `DrawOp::PopLayer` — end the innermost raster layer. Pop the render-target stack and composite the offscreen surface onto the now-current parent target with source-over, scaling the source alpha by the layer's opacity, then release the offscreen surface. The composite is performed in-place per pixel (see §5), not via a second full-image allocation.

The `DrawingList` builder gains two methods mirroring the existing transform/clip pair:

- `DrawingList::push_layer(opacity : Double) -> Unit`
- `DrawingList::pop_layer() -> Unit`

Balance and recovery rules follow the established `PopTransform` / `PopClip` convention: `PushLayer`/`PopLayer` should be balanced; an unbalanced `PopLayer` (empty layer stack) is a no-op at rasterization time, never a panic.

## 5. Rasterization changes

The reference rasterizer (RFC 0003 §6.1) maintains a **render-target stack** in addition to its existing transform and clip stacks. Each stack frame carries the active `MutImageView` plus, for offscreen layers, the owning `OwnedImage`. The primary (bottom-of-stack) target remains the caller-borrowed view.

- On `PushLayer`: allocate a transparent RGBA8 `OwnedImage` of the current target's width × height, charging bytes and pixels against the budget; push a new frame whose view is the offscreen's mutable view. Initialize it transparent (all channels zero).
- On `PopLayer`: read the inner frame's offscreen and composite it onto the parent frame's view with source-over, scaling the source alpha by the layer opacity, then pop the frame and release the offscreen.

**Write-back strategy (resolved): in-place per-pixel source-over.** `PopLayer` walks the offscreen and parent views pixel-by-pixel and applies `mb-color/blend::porter_duff_composite(CompositeOp::SourceOver, ...)` directly into the parent view, with the source alpha pre-multiplied by the layer opacity. This reuses the exact per-pixel blend path the rasterizer already runs for fills and strokes (`composite_pixel` in `rasterize.mbt`, which already calls `@blend.porter_duff_composite(SourceOver, …)`), so no new composite machinery is introduced and **no second full-image allocation** occurs at `PopLayer`. The alternative — calling `mb-image/ops::composite_source_over`, which returns a fresh `ImageOperationResult` that must be copied back — is rejected for v0.x because it doubles per-layer allocation and adds a copy, with no accuracy benefit (the underlying porter-duff math is identical). The delegated `composite_source_over` op remains the canonical raster-raster composite for callers who want a standalone image-image blend; the layer path uses the rasterizer's own in-place blend for allocation efficiency.

This decision is recorded as resolved (not open) because it follows directly from existing rasterizer structure: the per-pixel blend helper already exists and is already the path fills/strokes use, so the layer composite is a straightforward second consumer of it.

## 6. v0.x scope

### 6.1 In scope

- `PushLayer(opacity)` / `PopLayer` drawing-list operations.
- Offscreen RGBA8 layer surfaces, full-size relative to the current target.
- Opacity-only layer compositing: source-over with the layer opacity scaling the source alpha.
- Budget-bounded offscreen allocation and layer nesting depth.

### 6.2 Deferred (explicitly out of v0.x scope)

- Blend modes other than source-over (multiply, screen, overlay, etc.). RFC 0003 §7.2 already defers these to the raster-raster surface owned by `mb-image`.
- Filters (Gaussian blur, drop shadow, color matrix). These belong to a future `mb-effects`.
- Masking (alpha/luminance mask) and complex clip beyond RFC 0003 §5.2's clip operations.
- Layer bounding-box optimization. v0.x allocates a full-target-size offscreen; computing and clipping to the layer content's bounding box is a performance follow-up, not a correctness concern.
- Layer-specific blend compositing delegation beyond `composite_source_over`.

Deferral is binding until a follow-up RFC or phase explicitly widens scope. Implementation MUST NOT silently pull in a deferred category — in particular, `PushLayer` carries only opacity in v0.x; it does not carry a blend-mode or filter parameter that is then ignored.

## 7. Determinism, bounds, and resource safety

Consistent with RFC 0003 §8 and RFC 0001 §10:

- **Bounded allocation.** Every offscreen `OwnedImage` is charged against the render's `mb-core/budget` (bytes and pixels). A budget whose allocation dimension is exhausted yields a structured `CoreError` before the offscreen is created, exactly as `mb-svg` bounds do at parse time (RFC 0002 §8.1).
- **Bounded nesting.** Layer nesting depth is capped at **16**. Each layer holds a full-target-size RGBA8 offscreen, so 16 is chosen as a memory-bounded ceiling: it far exceeds any reasonable SVG group-nesting depth (real documents rarely exceed 4–5), while bounding worst-case offscreen memory to 16 × (target width × height × 4) bytes. This is stricter than the depth=64 used for transform/clip in `mb-svg`, because layers allocate a full intermediate surface per level whereas transform/clip stack frames are small. A drawing list that nests layers beyond 16 fails with a structured error rather than recursing or allocating without limit. The cap is enforced through the budget's depth dimension (the render's `Budget::enter_depth` is invoked at `PushLayer`, mirroring `mb-svg`'s group-depth bound).
- **Deterministic output.** A given `DrawingList` and a given primary target produce a single raster on every target, under the declared antialiasing tolerance. Offscreen compositing is a pure function of the offscreen content, the parent content, and the opacity; no ambient state, no host clock, no nondeterministic iteration.
- **Hostile drawing lists.** Deeply nested layers, pathologically large layer content, and oversized offscreen requests are rejected before allocation through the budget, consistent with the security posture RFC 0003 §8 requires.

## 8. Alternatives considered and rejected

- **Push the group `opacity` down into each child shape's paint alpha (the approximation).** Rejected. It diverges from SVG §14.4 whenever two semi-transparent shapes overlap inside the group (§3.1). `mb-svg` already documents and rejects this approximation; importing the bug into a layer primitive would defeat the purpose.
- **A broad layer abstraction carrying blend mode, filter, and mask parameters up front.** Rejected. It pulls in three categories RFC 0003 §7.2 explicitly defers, violates the "MUST NOT silently pull in a deferred category" rule, and speculates on APIs (blend enums, filter chains, mask semantics) before there is a consuming use case. Each of those capabilities deserves its own RFC; this RFC carries only opacity.
- **Render the group twice into the primary surface instead of allocating an offscreen.** Rejected. It cannot express "the group's shapes composite with each other at full opacity before the group meets the backdrop": without an intermediate, intra-group shapes meet the backdrop as they draw, pre-multiplying the backdrop into the intra-group result. The offscreen is the minimal surface that captures the required ordering.
- **Handle layer compositing entirely inside `mb-image` without extending `mb-canvas`'s `DrawOp`.** Rejected. A layer is drawing-list semantics — it has a position in the op stream, inherits transform/clip state, and is consumed by the same rasterizer that consumes fill/stroke. `mb-image` provides atomic composite primitives; it does not, and should not, replay drawing-list state. The layer op belongs to canvas; canvas then delegates the pixel composite to `mb-image`, exactly as RFC 0003 §7.1 already states.

## 9. Compatibility consequences

This RFC adds two `DrawOp` variants and two `DrawingList` methods. It is **additive**: it does not alter the existing `Fill`, `Stroke`, `PushTransform`, `PopTransform`, `PushClip`, or `PopClip` operations or their semantics. Existing `DrawingList` producers and consumers are unaffected unless they choose to use layers.

`mb-canvas` remains a Graphics Layer module with no new public dependency edges: the offscreen path uses `mb-image/storage` (already a dependency per RFC 0003), `mb-image/ops` (the delegated composite, already anticipated by RFC 0003 §7.1), and `mb-core/budget` (already a dependency). No reverse edge, self-edge, cycle, or undeclared public edge is introduced.

The downstream consequence is that `mb-svg`'s deferred group/element `opacity` (RFC 0002 §6.1) becomes implementable: `mb-svg` lowers `<g opacity="...">` to `PushLayer(opacity)` / `PopLayer` around the group's children. That lowering is a follow-up to this RFC reaching Proposed; it is out of scope for this document.

## 10. Verification plan

Before the layer primitive may be considered delivered, the implementing phase must produce, consistent with RFC 0003 §11 and RFC 0001 §10:

1. Unit tests for the rasterizer: `PushLayer`/`PopLayer` balance; opacity composite pixel correctness (a semi-transparent layer over an opaque backdrop yields the exact source-over result, e.g. a 50%-opacity red-over-white layer produces `(255,128,128,255)` as already verified in `mb-svg`'s paint-opacity path); nested layers; unbalanced `PopLayer` as no-op; transform/clip state correctly inherited by the layer and restored on pop.
2. Bounds tests: a 17-deep nested layer list (beyond the §7 cap of 16) fails with a structured error; an oversized offscreen request rejected by the budget before allocation.
3. Determinism evidence: identical `DrawingList` + primary target produce identical rasters across `js`, `wasm`, `wasm-gc`, and `native`.
4. Integration evidence: once `mb-svg` lowers group opacity onto this primitive, an end-to-end `<g opacity="...">` case renders correctly through `parse_svg` → `lower_to_drawing_list` → `render`.

## 11. What this RFC does not decide

This RFC intentionally leaves the following open. They are decided in follow-up RFCs or phases, not by this document:

- The blend-mode enumeration, filter chain, and mask semantics. All deferred (§6.2); each requires its own RFC.
- The layer bounding-box optimization. A performance follow-up; v0.x uses full-target-size offscreens.
- Any native-acceleration specifics for layers. RFC 0003 §6.2's seam is unchanged; a native layer path, if any, must meet the same pixel-identity-or-declared-deviation rule as other accelerated paths.

The two questions this RFC opened as Draft — the offscreen write-back strategy (§5: in-place per-pixel source-over) and the layer nesting-depth cap (§7: 16) — are now resolved in this Proposed revision and are therefore no longer open.

## 12. References

- [RFC 0001: MoonBit Native Foundation](0001-moonbit-native-foundation.md) — canonical charter, architecture, governance gate, resource-budget posture
- [RFC 0002: mb-svg Charter](0002-mb-svg.md) — §6.1 Opacity is the primary consumer of this RFC's primitive
- [RFC 0003: mb-canvas Charter](0003-mb-canvas.md) — §5.2 operations, §6.1 rasterizer no-allocation rule (the tension in §3.2), §7.1 compositing delegation, §7.2 deferred blend modes
- [MNF RFC process](../governance/rfc-process.md) — lifecycle, transition evidence
- SVG 1.1 (Second Edition) §14.4 — group opacity compositing semantics
- `mb-image/ops::composite_source_over` — the delegated raster-raster composite primitive
