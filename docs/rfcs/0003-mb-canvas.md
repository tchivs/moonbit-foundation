# RFC 0003: mb-canvas Charter

- **Status:** Proposed
- **Authors:** MNF contributors
- **Created:** 2026-07-22
- **Target:** Graphics Layer canvas and rasterization module charter
- **Discussion:** To be established
- **Normative process:** [RFC process](../governance/rfc-process.md)
- **Authority / project owner:** `sole-project-owner`

> The acceptance-machinery header fields this RFC previously carried (acceptance route, maintainer approvals, blocking objections, public review window, acceptance evidence) were removed on 2026-07-23 when the RFC process was simplified to `Draft -> Proposed` for this sole-owner project. A Proposed RFC is now sufficient to proceed. See the [RFC process](../governance/rfc-process.md).

## Transition history

| From | To | Evidence |
|---|---|---|
| — | Draft | Initial RFC in repository history |
| Draft | Proposed | This revision makes the charter reviewable; repository history is the transition record |

No transition to Rejected or Superseded has occurred. Under the simplified RFC process the lifecycle is `Draft -> Proposed`; a Proposed RFC is sufficient to proceed. Every future transition must update this ledger.

## 1. Abstract

This RFC proposes `tchivs/mb-canvas` as a new MNF module in the Graphics Layer, responsible for a portable, deterministic drawing-list abstraction and the bounded rasterization of that list into `mb-image` raster surfaces. It establishes the module boundary, the allowed public dependency direction, the drawing-list contract, the rasterization seam, the compositing responsibility split between canvas and image, and the v0.x scope.

`mb-canvas` answers a single question: how does an MNF consumer turn vector geometry into pixels, deterministically and on every target, without each consumer rebuilding an incompatible rasterizer. RFC 0001 names `mb-canvas` in the Graphics Layer directly above `mb-image`, but Section 6 does not define its responsibilities because canvas was deferred. This RFC fills that gap.

This RFC does not implement `mb-canvas`. It creates no `.mbt` source, no package manifest, and no module declaration. Per [RFC 0001](0001-moonbit-native-foundation.md) Section 11, creation of a new MNF module requires a Proposed RFC before implementation may merge.

## 2. Relationship to RFC 0001

[RFC 0001](0001-moonbit-native-foundation.md) Section 5 places `mb-canvas` in the Graphics Layer alongside `mb-image` and `mb-color`, above the Foundation (`mb-core`). RFC 0001 Section 4.1 explicitly includes "raster operations" among the reusable logic implemented in MoonBit; this proposal takes that as standing authorization for a portable MoonBit rasterizer.

RFC 0001 Section 6.4 governs deferred layers: `mb-canvas` retains the responsibilities shown by the architecture, its implementation is outside the v0.1 foundation charter, it may consume accepted lower-layer contracts, and it may not redefine them through implementation alone.

The allowed public dependency direction proposed here is:

```text
tchivs/mb-canvas -> tchivs/mb-image
tchivs/mb-canvas -> tchivs/mb-color
tchivs/mb-canvas -> tchivs/mb-core
```

No reverse edge, self-edge, cycle, or undeclared public edge is permitted. The edges mirror the already-accepted `mb-image` edges and remain within the downward-only rule. A reverse edge from `mb-image` to `mb-canvas` is forbidden: image does not depend on canvas.

## 3. The boundary problem and its resolution

The central difficulty in chartering `mb-canvas` is that RFC 0001 Section 6 defines precise boundaries for `mb-core` (Section 6.1), `mb-color` (Section 6.2), and `mb-image` (Section 6.3), but says nothing about canvas beyond its layer position. This section establishes the boundary by drawing three clean cuts: image versus canvas, canvas versus svg, and composite versus rasterize.

### 3.1 Image versus canvas: storage versus production

`mb-image` owns the **pixel container** — dimensions, format, plane layout, owned storage, immutable and mutable views (`OwnedImage`, `ImageView`, `MutImageView`), and pixel-level operations including `composite_source_over`, `grayscale`, `box_blur`, and `resize`. Image answers "what is the raster and what can be done to an existing raster."

`mb-canvas` owns the **production of a raster from vector geometry** — the drawing list, path and style representation, transform evaluation, scanline and edge rasterization, and antialiasing. Canvas answers "how do I fill or stroke this geometry into that raster." Canvas consumes `mb-image` storage as its write target; it does not re-own storage, format, or layout.

The cut is: **if the operation takes two rasters and produces a raster, it belongs to `mb-image/ops`. If the operation takes geometry and produces pixels into a raster, it belongs to `mb-canvas`.** A canvas fill lowers to scanline writes into a `MutImageView`; a final composite of two rasters delegates to `mb-image/ops`.

### 3.2 Canvas versus svg: execution versus document

`mb-svg` (RFC 0002) owns **the document** — parsing SVG syntax into a typed scene tree, document structure, element and attribute semantics, `currentColor` resolution, and unit resolution against the document coordinate system.

`mb-canvas` owns **the execution** — turning a sequence of draw operations into pixels. SVG does not rasterize; it builds and queries a scene tree. Canvas does not parse documents; it rasterizes geometry. The connection is that SVG translates its scene tree into a canvas drawing list and then asks canvas to rasterize it. Neither module reaches into the other's domain.

The cut is: **document semantics, structure, and format-specific coordinate systems belong to the document layer; drawing-list construction and pixel production belong to canvas.** Canvas is format-neutral: it does not know what SVG is.

### 3.3 Composite versus rasterize: two-lower operation

There are two distinct pixel-blending concerns, and RFC 0001's existing `mb-image/ops::composite_source_over` already owns one:

- **Raster-raster composite** (owned by `mb-image/ops`): blending two complete rasters under source-over or other modes. This is already accepted, tested, and frozen.
- **Geometry-raster rasterization** (owned by `mb-canvas`): coverage-antialiased fill or stroke of a single path into a raster, including partial-coverage alpha. This is new and is what canvas introduces.

Canvas's rasterizer produces coverage for each pixel under a path and writes premultiplied or straight color with that coverage into the target. When two raster layers must be combined, canvas delegates to `mb-image/ops::composite_source_over`. This split prevents canvas from re-owning composite logic that image already provides.

## 4. Module boundary

### 4.1 `tchivs/mb-canvas` owns

- A **drawing-list** abstraction: a portable, pure-data, append-only list of draw operations (fill, stroke) over path geometry, style, and transform state. The list is the public contract; it is deterministic, serializable, inspectable, and buildable by CLI, Agent, and MCP consumers without any render.
- **Path geometry representation** for rasterization: line segments, and cubic and quadratic Bézier curves, flattened to a bounded tolerance, with bounding-box computation. Canvas accepts already-parsed geometry from a caller; it does not own SVG path syntax.
- **Style representation** for fill and stroke: color resolved through `mb-color`, stroke width, cap, join, and dash. Style carries color identity (space, transfer, alpha mode) rather than a parallel color model.
- **Transform evaluation**: a 2D affine transform stack (translate, scale, rotate, skew, matrix) with composition and application to path geometry and stroke widths, using `mb-core` checked arithmetic.
- **Rasterization**: deterministic coverage-antialiased fill and stroke of path geometry into an `mb-image` mutable raster surface (`MutImageView`), including the choice of even-odd or nonzero winding fill rule.
- **The rasterization seam**: a documented boundary between the portable software rasterizer and any target-specific acceleration. The portable rasterizer is the reference; a native acceleration adapter is an optional leaf that must produce identical or better-approximating coverage under declared tolerances.
- **Compositing delegation**: when a rasterized result must be blended with an existing raster, canvas calls into `mb-image/ops` rather than reimplementing composite.

### 4.2 `tchivs/mb-canvas` does not own

- Pixel storage, image format, plane layout, stride, or endianness — those remain in `mb-image`.
- Color component representation, transfer functions, or profile identity — those remain in `mb-color`.
- Raster-raster compositing modes beyond what `mb-image/ops` already provides. Canvas rasterizes geometry; it delegates layer compositing to image.
- Any document format. Canvas does not parse SVG, PDF, or any other document syntax. It is format-neutral geometry-to-pixel execution.
- Font rasterization, glyph outlines, or text shaping. Text-to-geometry is a future `mb-font`/`mb-text` concern; canvas accepts caller-supplied geometry.
- A windowing system, display surface, GPU context, swap chain, or event loop. Per RFC 0001 Section 4.4, public operations are deterministic and headless.
- Filesystem, network, or host-clock policy. Host access enters only through explicit capabilities or isolated native adapters, per RFC 0001 Section 8.

## 5. The drawing-list contract

The drawing list is `mb-canvas`'s primary public contribution and the reason a draw-list-and-rasterizer model was chosen over immediate-mode or bare-primitive alternatives.

### 5.1 Why a drawing list

A drawing list is a **pure-data, value-typed** sequence of operations. It satisfies four RFC 0001 principles at once:

- **Determinism (§4.4):** a list has no ambient state. Given the same list and target, rasterization produces identical pixels on every target.
- **Automation-first (§4.4):** a CLI, Agent, or MCP consumer can construct, inspect, validate, transform, or diff a list without rendering. A render is one operation on a list, not the only way to interact with canvas.
- **Evidence (§4.5):** a list is a reproducible workload. A benchmark declares a list; a test asserts a list's rasterization; a conformance fixture is a list.
- **Portability (§4.2):** the list is portable pure data; only the rasterizer backend is target-specific, and only as an optional leaf.

### 5.2 Operations

The drawing list comprises:

- **Path fill:** fill a path with a resolved color, a fill rule (nonzero or even-odd), and the current transform.
- **Path stroke:** stroke a path with a resolved color, stroke style (width, cap, join, dash), and the current transform.
- **Transform push/pop:** save and restore a 2D affine transform, enabling hierarchical coordinate systems.
- **Clip push/pop:** establish a clip path under the current transform; subsequent draws are confined to the clip until popped.

The list is append-only. State changes (transform, clip) are recorded as operations in the list, not as ambient mutable context, preserving value semantics and replay determinism.

### 5.3 What the list does not carry

The list does not carry text (deferred to font/text), images as textures beyond a documented bitmap-fill minimum (Section 7), gradients or complex shaders (deferred), or scripting. It is a geometry-and-style list, not a document model.

## 6. Rasterization and the portability seam

### 6.1 The portable reference rasterizer

The portable software rasterizer is the **reference implementation** and is mandatory: it runs on `js`, `wasm`, `wasm-gc`, and `native`, produces deterministic, coverage-antialiased output under declared numeric tolerances, and is the source of truth for conformance. Per RFC 0001 Section 4.1, raster operations are MoonBit-implemented logic; this proposal relies on that authorization.

The rasterizer writes into an `mb-image` `MutImageView`. It does not allocate its own pixel store; it borrows the caller's raster surface and respects the surface's format, stride, and metadata. Coverage is computed per pixel and written as premultiplied or straight color per the surface's alpha convention, resolving any mismatch through `mb-color` alpha conversions.

### 6.2 Native acceleration as an optional leaf

A native-only acceleration adapter (for example, a CPU SIMD path or a future GPU backend) is permitted as an **optional leaf** behind the rasterization seam. It must satisfy one of:

1. produce pixel-identical output to the reference rasterizer under the declared tolerance; or
2. declare its deviation as a documented approximation with a stricter or equal error bound, so a consumer choosing the adapter accepts the declared trade-off knowingly.

A native adapter is never the portable package's only path, never makes the portable package transitively native-only, and must document ownership, reference-counting, lifetime, ABI, and error assumptions per RFC 0001 Section 8.

## 7. v0.x scope

### 7.1 In scope (proposed for v0.x)

- Drawing list with fill, stroke, transform push/pop, and clip push/pop.
- Path geometry in line segments, and cubic and quadratic Bézier curves, with bounded flattening tolerance.
- Affine transforms: `matrix`, `translate`, `scale`, `rotate`, `skewX`, `skewY`, with composition and checked arithmetic.
- Fill rules: nonzero and even-odd winding.
- Stroke style: width, butt/round/square cap, miter/round/bevel join, with bounded miter limit. Dash patterns are in scope if bounded; otherwise deferred to a documented minimum.
- Coverage antialiasing via a deterministic sampling strategy with a declared sample count and tolerance.
- Solid color fill and stroke, with color resolved through `mb-color`.
- Rasterization into `mb-image` RGB8 and straight-RGBA8 `MutImageView` targets.
- Compositing delegation to `mb-image/ops::composite_source_over` for raster layer blending.

### 7.2 Deferred (explicitly out of v0.x scope)

- Gradients (linear, radial, conic) beyond a documented minimum, if any.
- Bitmap and pattern fills beyond a documented minimum, if any. A full texture-sampling pipeline is a larger surface.
- Image filters, convolution, and effects. Those belong to a future `mb-effects`.
- Advanced blend modes beyond source-over at the raster-raster layer; image owns that surface.
- Masking and complex clipping beyond the clip-path operations in Section 5.2.
- Path morphing, boolean path operations, and advanced vector utilities beyond what rasterization needs.
- GPU-native backends. A future `mb-gpu` may supply one behind the seam; canvas v0.x ships the portable reference.

Deferral is binding until a follow-up RFC or phase explicitly widens scope. Implementation MUST NOT silently pull in a deferred category.

## 8. Determinism, bounds, and resource safety

Consistent with RFC 0001 Section 4.4 and the `mb-core` resource-budget contracts, canvas operations are deterministic and bounded:

- **Checked geometry.** All coordinate and transform arithmetic uses `mb-core` checked arithmetic; overflow and out-of-bounds coordinates fail with structured errors rather than wrapping silently.
- **Bounded flattening.** Bézier flattening is bounded by a declared tolerance and a maximum subdivision count; a pathological curve fails with a structured error rather than looping or exhausting memory.
- **Bounded rasterization.** Scanline and edge rasterization enforce target-dimension, clip-region, and operation-count limits through `mb-core` resource budgets.
- **Deterministic output.** A given drawing list and a given target produce a single raster on every target, under the declared antialiasing tolerance. No ambient state, no host clock, no nondeterministic iteration in the public contract.
- **Hostile geometry.** Degenerate paths, zero-area fills, extreme coordinate magnitudes, and pathologically high subdivision demand are rejected before allocation, consistent with the security and resource-limit posture RFC 0001 Section 10 requires for untrusted inputs.

## 9. Alternatives considered and rejected

- **Immediate-mode 2D context (HTML5 Canvas / Cairo style).** Rejected as the primary contract. An immediate context embeds state in the execution flow, which undermines determinism (§4.4), makes the workload non-serializable and hard to benchmark (§4.5), and couples interaction to a single execution path. The draw-list model retains the ergonomics of a stateful builder but stores state as list operations, preserving value semantics. An immediate-style convenience wrapper may be offered as non-primary sugar built atop the list.
- **Bare low-level rasterization primitives only.** Rejected. Pixel-level primitives (scanline fill, edge table, pixel blend) are maximally flexible but push the drawing-API burden onto every consumer, fragmenting exactly the way RFC 0001 Section 4.3 forbids. The drawing list is the shared contract that prevents fragmentation; the primitives are internal.
- **Make canvas own compositing.** Rejected. `mb-image/ops::composite_source_over` is already accepted, tested, and frozen. Re-owning composite in canvas duplicates accepted surface and risks drift. Canvas rasterizes geometry; it delegates raster compositing to image (Section 3.3).
- **Make canvas own pixel storage.** Rejected. `mb-image` owns storage, format, stride, and views. Canvas borrows a `MutImageView` and writes into it. Re-owning storage violates the Section 3.1 boundary and duplicates `OwnedImage`/`ImageView`/`MutImageView`.
- **Bundle canvas into mb-image.** Rejected. Canvas is a distinct responsibility (vector-to-pixel production) with a distinct dependency profile and lifecycle. Bundling it would make `mb-image` consumers pay for a rasterizer they may not need, violating the independent-consumption principle (§4.3).
- **Block canvas on a GPU backend.** Rejected. The portable reference rasterizer is mandatory and ships first; a GPU backend is an optional leaf behind the seam, gated on a future `mb-gpu`.

## 10. Compatibility consequences

This RFC proposes a new module and a new public dependency edge. It does not modify any accepted module's boundary, public API, dependency direction, or portability seam. There is no impact on existing `mb-core`, `mb-color`, or `mb-image` consumers: canvas consumes image's `MutImageView` as a write target and delegates to `ops::composite_source_over`, both of which are already public.

If accepted, this RFC adds one row to the allowed public module edges in the spirit of RFC 0001 Section 5 and is subject to the publication and compatibility policies that govern all MNF modules.

Because `mb-canvas` would ship as a `candidate`-stability module, it carries no pre-1.0 compatibility promise beyond the executable four-class policy in RFC 0001 Section 10.

This RFC also unblocks [RFC 0002](0002-mb-svg.md) Section 7.2 option (1): once `mb-canvas` is accepted, `mb-svg`'s rasterization phase can target the canvas drawing list rather than a narrow image-raster fallback. RFC 0002 remains internally consistent under either option; this RFC makes option (1) available.

## 11. Verification plan

Before `mb-canvas` may merge, the implementing phases must produce, consistent with RFC 0001 Section 10:

1. Public and internal tests validating the drawing list, path flattening, transform evaluation, fill-rule rasterization, stroke expansion, and antialiasing for the in-scope subset.
2. Declared-target CI evidence on `js`, `wasm`, `wasm-gc`, and `native`, with pixel-level assertions against fixture rasters using digests plus semantic assertions, not opaque snapshots alone.
3. Conformance fixtures with provenance and license metadata, covering valid, edge, and hostile geometry.
4. Deterministic benchmarks with declared workloads (named drawing lists) and reproducible baselines for path flattening, scanline rasterization, and full-list render.
5. A security and resource-limit review for untrusted geometry, covering the bounds in Section 8.
6. If a native acceleration adapter is included, evidence that it meets the pixel-identity or declared-approximation requirement of Section 6.2.

## 12. What this RFC does not decide

This RFC intentionally leaves the following open. They are decided in follow-up phases or RFCs, not by this charter:

- The exact internal representation of paths, edges, and the scanline/coverage buffer.
- The exact antialiasing sample pattern and numeric tolerance values.
- The exact set of stroke dash capabilities in v0.x versus deferred.
- The internal data structures of the drawing list and rasterizer.
- Whether a GPU backend exists at all, and under what `mb-gpu` boundary.
- The milestone version number and roadmap placement for `mb-canvas` phases.
- Whether an immediate-mode convenience wrapper is provided, and as primary or non-primary surface.

Any of these, if later shown to affect the module boundary, dependency direction, or portability seam, requires its own RFC per the governance gate in RFC 0001 Section 11.

## 13. References

- [RFC 0001: MoonBit Native Foundation](0001-moonbit-native-foundation.md) — canonical charter, architecture, and governance gate
- [RFC 0002: mb-svg Charter](0002-mb-svg.md) — Document and Scene Layer consumer of canvas rasterization
- [MNF RFC process](../governance/rfc-process.md) — lifecycle, authority routes, and evidence
- [MNF RFC index](README.md) — proposal list and status
- [Decision 0001: sole project-owner bootstrap](../governance/decisions/0001-sole-owner-bootstrap.md) — acceptance authority context
- MoonBit documentation: modules, packages, workspaces, supported targets, and publication
