# RFC 0002: mb-svg Charter

- **Status:** Proposed
- **Authors:** MNF contributors
- **Created:** 2026-07-22
- **Target:** Document and Scene Layer SVG module charter
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

This RFC proposes `tchivs/mb-svg` as a new MNF module in the Document and Scene Layer, responsible for parsing, representing, and (through an explicit, deferred rasterization contract) rendering a bounded subset of the Scalable Vector Graphics format in portable MoonBit. It establishes the module boundary, the allowed public dependency direction, the v0.x subset scope, the rasterization strategy, and the phase ordering that resolves the present unavailability of `mb-canvas`.

This RFC does not implement `mb-svg`. It creates no `.mbt` source, no package manifest, and no module declaration. It proposes an architectural boundary for review. Per [RFC 0001](0001-moonbit-native-foundation.md) Section 11, creation of a new MNF module requires a Proposed RFC before implementation may merge.

## 2. Relationship to RFC 0001

[RFC 0001](0001-moonbit-native-foundation.md) Section 5 places `mb-svg` in the Document and Scene Layer alongside `mb-pdf`, `mb-font`, `mb-text`, and `mb-layout`. That layer sits above the Graphics Layers (`mb-canvas`, `mb-image`, `mb-color`) and the Foundation (`mb-core`). Arrows point from a consumer toward a dependency; dependencies point inward and downward only.

RFC 0001 Section 6.4 governs deferred layers: `mb-svg` retains the responsibilities shown by the architecture, its implementation is outside the v0.1 foundation charter, it may consume accepted lower-layer contracts, and it may not redefine them through implementation alone. This RFC proposes the boundary under which an implementation would later proceed; it does not modify RFC 0001.

The allowed public dependency direction proposed here is:

```text
tchivs/mb-svg -> tchivs/mb-image
tchivs/mb-svg -> tchivs/mb-color
tchivs/mb-svg -> tchivs/mb-core
```

No reverse edge, self-edge, cycle, or undeclared public edge is permitted. The edges to `mb-image`, `mb-color`, and `mb-core` mirror the already-accepted `mb-image` edges and remain within the downward-only rule. An edge to `mb-canvas` is architecturally permitted by RFC 0001's layering but is **not** proposed as an initial hard dependency in this RFC; see Section 7 for the resolution of the `mb-canvas` dependency gap.

## 3. Motivation

MNF's stated audience includes whiteboards, document tooling, and IDE extensions. These products routinely exchange vector graphics. Without a MoonBit-native SVG contract, each consumer rebuilds an incompatible parser and scene representation, which is precisely the fragmentation RFC 0001 Section 4.3 forbids the ecosystem to ignore.

A bounded SVG module delivers value in two distinct phases that do not require rasterization:

1. **Parse and represent.** A consumer can read a bounded SVG document into a typed scene tree, query geometry, validate structure, and emit it again, deterministically and on every target. This is immediately useful for tooling (diffing, validation, transformation, asset pipelines, MCP-driven editing) without any pixel output.
2. **Rasterize to a raster surface.** A consumer can convert the scene tree into an `mb-image` raster (for example, an RGB8 or RGBA8 `ImageDescriptor`) through an explicit, bounded rasterization contract. This phase requires a rasterization surface, which raises the `mb-canvas` question addressed in Section 7.

Splitting these phases lets the first deliver independently of the second and keeps this proposal honest about what is ready and what is not.

## 4. Module boundary

### 4.1 `tchivs/mb-svg` owns

- Parsing a bounded subset of SVG 1.1 / SVG 2 XML syntax into a typed, validated scene tree, including checked arithmetic on geometry, bounded string and byte input, and deterministic structured errors.
- A scene representation for the in-scope elements and attributes (Section 6), including path data, transforms, basic shapes, fill/stroke color, and document-level structure.
- Deterministic, target-neutral geometry evaluation: transform matrix composition, path command expansion into line/curve segments, bounding-box computation, and length resolution against the document coordinate system.
- Color resolution through the accepted `mb-color` contracts (`ColorSpaceIdentity`, `TransferIdentity`, alpha semantics) rather than a parallel color model.
- An explicit, documented rasterization seam that consumes a scene tree and writes into an `mb-image` raster surface, with the actual rasterization backend isolated behind a portability boundary (Section 7).
- Conformance fixtures with provenance and license metadata, consumed through test helpers, not embedded duplicated data.

### 4.2 `tchivs/mb-svg` does not own

- Image storage, pixel layout, codec selection, or format encode/decode — those remain in `mb-image`.
- Color component representation, transfer functions, or profile identity — those remain in `mb-color`.
- Font rasterization, text shaping, complex text layout, or glyph hinting — those belong to a future `mb-font` / `mb-text`. The SVG subset in Section 6 defers advanced text to keep this boundary clean.
- A windowing system, event loop, GPU context, or interactive rendering state. Per RFC 0001 Section 4.4, public operations are deterministic and usable by CLI, Agent, and MCP consumers without GUI state.
- Filesystem, network, or host-clock policy. Host access enters only through explicit capabilities or isolated native adapters, per RFC 0001 Section 8.
- XML parsing as a general-purpose library. The parser is scoped to the SVG subset; a general XML module, if ever needed, is a separate decision and a separate boundary.

## 5. Portability and native integration

`mb-svg` proposes the same portable contract as the existing foundation modules: supported targets are `js`, `wasm`, `wasm-gc`, and `native`, with `native` as the primary performance and system-integration target. Core parsing, the scene tree, geometry evaluation, and color resolution are portable MoonBit with no ambient host capability.

Any rasterization backend that requires target-specific acceleration (for example, a native GPU or platform blitter) is a native-only leaf adapter isolated behind the rasterization seam in Section 7. A native adapter remains a dependency leaf and cannot make the portable package transitively native-only, consistent with RFC 0001 Section 8. Native FFI stubs, if any, must document ownership, reference-counting, lifetime, thread, ABI, error, and build assumptions.

## 6. v0.x SVG subset scope

Full SVG is large and out of scope for an initial charter. This section proposes a bounded, useful subset and lists what is explicitly deferred. The exact element and attribute coverage is finalized in the implementing phases; this RFC fixes the subset's shape and its deferral boundary so implementation cannot silently expand scope.

### 6.1 In scope (proposed for v0.x)

- **Document structure:** the root `svg` element with `width`, `height`, `viewBox`, `preserveAspectRatio`, and nested groups (`g`) with `transform`.
- **Coordinate transforms:** `transform` attribute with `matrix`, `translate`, `scale`, `rotate`, `skewX`, `skewY`; transform composition and inversion.
- **Basic shapes:** `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`.
- **Paths:** the `path` element and its `d` attribute with all SVG path commands (`M L H V C S Q T A Z`), parsed into a typed command list and expanded into line and cubic/quadratic Bézier segments.
- **Fill and stroke:** `fill`, `stroke`, `fill-opacity`, `stroke-opacity`, `stroke-width`, `stroke-linecap`, `stroke-linejoin`, using `mb-color` for color values; `none` fill/stroke.
- **Presentational color:** `currentColor` resolution through an explicit context, and color keywords / hex / `rgb()` forms resolvable through `mb-color` quantization.
- **Opacity:** group and element opacity through bounded alpha composition.
- **Units and lengths:** user units, and the length units required to resolve `viewBox` and shape geometry deterministically.

### 6.2 Deferred (explicitly out of v0.x scope)

- Advanced text: `text`, `tspan`, `textPath`, and text-on-path. These await `mb-font` / `mb-text` and are deferred to keep the boundary clean.
- CSS, stylesheets, and selectors. Inline presentation attributes only.
- Gradients (`linearGradient`, `radialGradient`), patterns, masks, clipping paths, and filters beyond a documented minimum, if any.
- SMIL animation and scripting. The scene tree is static; animation is a separate boundary.
- References, external resources, and `<use>` shadow trees beyond a documented minimum.
- SVG 2 features not listed in Section 6.1.

Deferral is binding until a follow-up RFC or phase explicitly widens scope. Implementation MUST NOT silently pull in a deferred category.

## 7. Rasterization strategy and the `mb-canvas` dependency gap

The central technical decision in this RFC is how `mb-svg` reaches pixels, because RFC 0001 places `mb-canvas` directly below `mb-svg` in the Graphics Layer, and `mb-canvas` is not yet implemented. This section confronts that gap directly.

### 7.1 The gap

RFC 0001 Section 5 shows `mb-canvas` as the natural rasterization surface for `mb-svg`. As of this revision, `mb-canvas` has a **Proposed** charter (RFC 0003) but **no implementation and no module declaration**. A naive charter would assume an implemented `mb-canvas` exists; that assumption would silently make `mb-svg` unbuildable until a second module is implemented. This RFC refuses that assumption. The two-option resolution in Section 7.2 below remains valid precisely because `mb-canvas` is not yet implemented: option (1) is reached if and when RFC 0003 is implemented, and option (2) is the bounded fallback until then.

### 7.2 Resolution: phase ordering and an isolated rasterization seam

`mb-svg` proceeds in two ordered phases:

- **Phase A — Parse and represent (no rasterization).** The scene tree, geometry evaluation, and color resolution are delivered with no dependency on `mb-canvas` and no pixel output. This phase is independently useful (Section 3) and has no blocker.
- **Phase B — Rasterize.** Rasterization is reached only after a rasterization surface contract exists. That surface is satisfied by exactly one of:
  1. an accepted `mb-canvas` charter and implementation; or
  2. a narrow, documented rasterization contract owned by `mb-svg` that writes directly into an `mb-image` raster surface (for example, `ImageDescriptor`/storage views already accepted in `mb-image`), treating the `mb-image` raster as the portable surface instead of a full canvas.

  The choice between (1) and (2) is a deferred decision recorded here, not in implementation. Phase B does not begin until this decision is made. If `mb-canvas` is chartered first, option (1) is preferred to avoid a parallel rasterization surface. If the cost of a full `mb-canvas` charter is not justified by the SVG-only need, option (2) is the bounded fallback.

The rasterization seam in `mb-svg` is the portable boundary: a scene tree is evaluated into scanline or edge-list operations written to whatever surface the chosen option supplies, on all four targets. Any target-specific acceleration is a native-only leaf adapter behind that seam, never a property of the portable package.

### 7.3 Why not block the whole RFC on `mb-canvas`

Because Phase A (Section 7.2) is independently valuable and has no dependency on `mb-canvas`. Accepting this RFC and delivering Phase A does not require `mb-canvas` to exist. Phase B is gated on the Section 7.2 decision, not on this RFC's acceptance.

## 8. Determinism, bounds, and resource safety

Consistent with RFC 0001 Section 4.4 and the `mb-core` resource-budget contracts, `mb-svg` operations are deterministic and bounded:

- **Checked geometry.** All coordinate and length arithmetic uses `mb-core` checked arithmetic; overflow and out-of-bounds geometry fail with structured errors rather than wrapping silently.
- **Bounded input.** Parsing uses bounded readers/writers from `mb-core`; the parser enforces document-size, nesting-depth, path-command-count, and attribute-count limits through `mb-core` resource budgets.
- **Deterministic output.** A given SVG document and a given set of resolved context values (including `currentColor`) produce a single scene tree, and where rasterized, a single raster, on every target. No ambient state, no host clock, no nondeterministic iteration order in the public contract.
- **Hostile inputs.** Malformed documents, pathologically deep nesting, exponential-complexity path expressions, and oversized coordinate values are rejected before allocation, consistent with the security and resource-limit posture RFC 0001 Section 10 requires for untrusted inputs.

## 9. Alternatives considered and rejected

- **Wrap a mature SVG library as the core implementation.** Rejected. It violates RFC 0001 Section 4.1 (MoonBit implementation by default) and contaminates a portable package with foreign code. A foreign library may appear only as an isolated, replaceable native adapter behind the rasterization seam.
- **Block this RFC until `mb-canvas` exists.** Rejected. Phase A (parse and represent) is independently valuable and has no `mb-canvas` dependency. Blocking the entire charter on an unchartered lower module is unnecessary and delays useful work.
- **Make `mb-svg` own a full XML parser, color model, and font stack.** Rejected. It would violate the module boundaries in RFC 0001 Section 6 and the independent-consumption principle in Section 4.3.
- **Include advanced text in the initial subset.** Rejected. Text without font/shaping support is misleading, and a partial implementation invites silent scope growth. Text is deferred to `mb-font` / `mb-text`.
- **Ship rasterization in the same phase as parsing.** Rejected. It couples the first deliverable to the unresolved `mb-canvas` decision and hides the Section 7.2 gap.

## 10. Compatibility consequences

This RFC proposes a new module and a new public dependency edge. It does not modify any accepted module's boundary, public API, dependency direction, or portability seam. There is no impact on existing `mb-core`, `mb-color`, or `mb-image` consumers. If accepted, this RFC adds one row to the allowed public module edges in the spirit of RFC 0001 Section 5 and is subject to the publication and compatibility policies that govern all MNF modules.

Because `mb-svg` would ship as a `candidate`-stability module, it carries no pre-1.0 compatibility promise beyond the executable four-class policy in RFC 0001 Section 10.

## 11. Verification plan

Before `mb-svg` may merge, the implementing phases must produce, consistent with RFC 0001 Section 10:

1. Public and internal tests validating the parser, scene tree, geometry evaluation, and color resolution for the in-scope subset.
2. Declared-target CI evidence on `js`, `wasm`, `wasm-gc`, and `native`.
3. Conformance fixtures with provenance and license metadata, covering valid, edge, and hostile inputs.
4. Deterministic benchmarks with declared workloads and reproducible baselines for performance-sensitive work (path expansion, transform composition, rasterization).
5. A security and resource-limit review for untrusted SVG inputs, covering the bounds in Section 8.
6. Phase-A evidence (no rasterization) and, separately, Phase-B evidence gated on the Section 7.2 decision.

## 12. What this RFC does not decide

This RFC intentionally leaves the following open. They are decided in follow-up phases or RFCs, not by this charter:

- The exact element and attribute coverage list inside the Section 6.1 subset.
- The choice between Section 7.2 option (1) and option (2).
- Whether a general-purpose XML module is ever extracted, and under what boundary.
- The internal data structures of the scene tree and rasterizer.
- Numeric tolerances for rasterization, the exact antialiasing strategy, and sampling rules.
- Performance targets beyond the requirement that benchmarks declare workloads and baselines.
- The milestone version number and roadmap placement for `mb-svg` phases.

Any of these, if later shown to affect the module boundary, dependency direction, or portability seam, requires its own RFC per the governance gate in RFC 0001 Section 11.

## 13. References

- [RFC 0001: MoonBit Native Foundation](0001-moonbit-native-foundation.md) — canonical charter, architecture, and governance gate
- [MNF RFC process](../governance/rfc-process.md) — lifecycle, authority routes, and evidence
- [MNF RFC index](README.md) — proposal list and status
- [Decision 0001: sole project-owner bootstrap](../governance/decisions/0001-sole-owner-bootstrap.md) — acceptance authority context
- SVG 1.1 (Second Edition) and SVG 2 — the format subset referenced by Section 6
- MoonBit documentation: modules, packages, workspaces, supported targets, and publication
