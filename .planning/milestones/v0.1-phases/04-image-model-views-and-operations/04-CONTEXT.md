# Phase 4: Image Model, Views, and Operations - Context

**Gathered:** 2026-07-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the private `mb-image` scaffold with explicit image descriptions, validated owned storage and safe immutable/mutable views, deterministic foundational operations, bounded metadata behavior, and backend-neutral codec-facing contracts. The model may describe packed and planar layouts broadly, while Phase 4 reference operations support a deliberately small explicit U8 format set. Codec implementations, filesystem policy, global registries, animation, advanced resampling, and rendering remain outside this phase.

</domain>

<decisions>
## Implementation Decisions

### Image description and format vocabulary
- **D-01:** Every public image value exposes dimensions, component type/depth, channel order, packed or planar layout, plane count, per-plane stride/range, endianness, color-space/transfer identity, alpha mode, orientation, and metadata identity. No field is inferred from a global or undocumented default.
- **D-02:** Use opaque validated descriptor types and closed candidate vocabularies for v0.1. The descriptor can represent packed and planar layouts and component kinds such as U8/U16/F32, but reference pixel operations are required only for explicit U8 packed formats selected below.
- **D-03:** The required operation formats are encoded-sRGB `Rgb8`, encoded-sRGB straight `Rgba8`, and encoded-sRGB premultiplied `Rgba8`. A format value carries channel order and alpha semantics; byte order is explicit even when irrelevant for single-byte components.
- **D-04:** Image dimensions are positive checked logical quantities. Empty rectangles may exist as ranges/crop requests, but an owned image with zero width or height is rejected in v0.1 to avoid multiple degenerate storage interpretations.

### Planes, stride, storage, and validation
- **D-05:** Each plane uses a half-open byte range plus row stride, row byte width, subsampling factors, and logical extent. Padding is allowed; negative stride, implicit bottom-up storage, and hidden base-pointer offsets are not.
- **D-06:** Constructors validate all checked products/sums/narrowing, minimum row stride, plane extent, storage containment, plane count, and prohibited overlap before allocation or access. Rejection has no partial budget charge or storage mutation.
- **D-07:** Distinct planes in one descriptor may share a backing allocation only when their validated byte ranges are disjoint. Public constructors reject overlap; aliasing through undocumented channel tricks is prohibited.
- **D-08:** Allocation and work charge caller-supplied hierarchical `mb-core` budgets before prohibited allocation or iteration. There are no built-in ambient resource limits; convenience constructors require explicit limits/options.

### Owned images and views
- **D-09:** `OwnedImage` owns or retains `mb-core` storage together with an immutable validated descriptor. Immutable views retain backing storage and can coexist. Public APIs expose no raw mutable backing.
- **D-10:** Mutable access is callback-scoped and runtime validated using `mb-core` mutable leases. Mutable views cannot escape the callback; overlapping mutable views are rejected; disjoint split/crop views are allowed only after checked range proof.
- **D-11:** Crops and subviews are zero-copy when every plane can represent the requested rectangle by adjusted checked offsets/strides. If the representation cannot express a zero-copy crop, the zero-copy API returns a structured unsupported-layout error; copying is a separate explicit operation.
- **D-12:** Rectangles are half-open and use logical display-independent coordinates. Empty zero-copy views are allowed only as non-owning operation results if research confirms MoonBit ergonomics; otherwise planners must reject them consistently and document the decision.

### Orientation and deterministic operations
- **D-13:** Orientation uses the eight EXIF-style transforms as neutral enum semantics, without importing EXIF parsing. Stored dimensions and display dimensions are both inspectable; orientations 5–8 swap display width/height.
- **D-14:** `apply_orientation` allocates a TopLeft-oriented result, remaps pixels deterministically, swaps dimensions where required, and sets orientation metadata to TopLeft. Plain copy/crop/resize/flip operate in stored coordinates and preserve the orientation tag unless their documented disposition says otherwise.
- **D-15:** Horizontal and vertical flips are exact index permutations. Copy must be overlap-safe or explicitly reject overlap before writing; no backend-dependent traversal is observable.
- **D-16:** Nearest-neighbor resize uses checked integer mapping `src_index = floor(dst_index * src_extent / dst_extent)`, clamped only by the mathematical final `min(src_extent - 1)` guard. It does not use floating point, filtering, or hidden color conversion.
- **D-17:** The minimum required pixel conversions are `Rgb8 encoded-sRGB -> Rgba8 straight` with opaque alpha, the inverse only when alpha is opaque or through an explicitly lossy/drop-alpha operation, and straight/premultiplied Rgba8 conversion using `mb-color` alpha semantics. Unsupported formats return structured errors.

### Metadata disposition
- **D-18:** Metadata is a bounded deterministic value, not an unbounded map. Core fields include explicit color/transfer/alpha/profile/orientation plus an ordered bounded list of opaque codec metadata entries with validated namespace/key/tag and bytes.
- **D-19:** Every operation has an executable metadata disposition: copy and zero-copy crop preserve all entries; flips and resize preserve opaque/profile/color entries and retain stored orientation; apply-orientation normalizes orientation only; pixel conversion updates format/alpha identity and preserves profile only when color identity is unchanged; explicitly lossy operations report discarded fields.
- **D-20:** Metadata ordering is stable and duplicates are either rejected or deterministically preserved according to one planner-selected rule. Operations cannot silently inspect or reinterpret opaque codec metadata.

### Codec-facing contracts
- **D-21:** Phase 4 defines small backend-neutral decoder/encoder-facing contracts over `mb-core` Reader/Writer, budgets, diagnostics, image descriptors, and owned images/views. A codec receives streams/capabilities; it never opens paths/URLs or consults a global registry.
- **D-22:** Codec contracts expose probe/decode/encode outcomes and explicit options/limits but do not implement a codec, auto-detection registry, animation model, or filesystem adapter. Phase 5 supplies the bounded PPM proof.

### Qualification and scope
- **D-23:** Use provenance-recorded generated fixtures for descriptors, plane/range adversarial cases, orientation maps, resize coordinate maps, pixel conversions, metadata dispositions, and codec-contract doubles. Portable tests consume package-local generated MoonBit tables without filesystem access.
- **D-24:** All public packages, examples, exact interfaces/imports/publication contents/DAG, prohibited source patterns, negative fixtures, and read-only behavior are Required on js, wasm, wasm-gc, and native.
- **D-25:** Additional component formats, YUV subsampling operations, arbitrary channel swizzles, advanced interpolation, color gamut conversion, animation, tiled/sparse/GPU storage, native codecs, and registry policy are deferred.

### the agent's Discretion
- Exact MoonBit type/package names, internal descriptor representation, metadata duplicate rule, empty-view policy, package decomposition, and fixture serialization are left to research and planning, provided all public semantics above remain explicit and behaviorally tested.
- The planner may add white-box/property/adversarial tests and split delivery into sequential topology increments.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/ROADMAP.md` — Phase 4 goal and five success criteria.
- `.planning/REQUIREMENTS.md` — normative IMAG-01 through IMAG-07 requirements.
- `.planning/PROJECT.md` — v0.1 milestone and MoonBit-native constraints.
- `docs/rfcs/0001-moonbit-native-foundation.md` — accepted mb-image ownership/dependency boundary.
- `.planning/research/ARCHITECTURE.md` — image layer, bounded pipeline, safe-view and codec architecture.
- `.planning/research/STACK.md` — pinned toolchain, targets, tests, manifests, and dependency policy.

### Existing contracts to reuse
- `.planning/phases/02-bounded-core-primitives/02-CONTEXT.md` — checked arithmetic, bytes/views, I/O, budgets, errors, and host-capability decisions.
- `.planning/phases/03-reference-color-semantics/03-CONTEXT.md` — explicit color/transfer/alpha/profile decisions.
- `modules/mb-core/README.mbt.md` — executable core contracts and package boundaries.
- `modules/mb-color/README.mbt.md` — executable color/alpha/profile contracts and tolerances.
- `modules/mb-image/README.mbt.md` — current scaffold boundary Phase 4 replaces.
- `policy/foundation.json` — exact module, dependency, target, interface, and publication policy source.
- `docs/policies/licensing-and-fixtures.md` and `fixtures/manifest.json` — provenance/digest mechanism.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mb-core` provides checked dimensions/ranges, owned bytes/retained views, callback-scoped mutable leases, bounded I/O, structured errors, diagnostics, budgets, and host-capability seams.
- `mb-color` provides identity-bearing encoded/linear components, exact U8 quantization, explicit straight/premultiplied alpha states, and bounded opaque profiles.
- Root quality scripts and `policy/foundation.json` already enforce four-target tests, exact generated interfaces, package allowlists/DAG, negative fixtures, generated evidence, README checks, and read-only proof.

### Established Patterns
- Public invalid states are prevented by opaque constructors; caller-controlled bounds/overflow failures are structured and occur before access/allocation.
- Mutable lifetimes are callback-scoped with group-wide invalidation; portable tests do not use filesystem or ambient state.
- Generated fixture tables are formatter-clean, byte-stable, package-local, and provenance-recorded separately from normative source claims.

### Integration Points
- New mb-image packages depend inward on the smallest required mb-core/mb-color packages and replace the root scaffold incrementally.
- Phase 5 consumes descriptor/view/operation/codec contracts for the PPM P6 reference proof; Phase 4 must not preempt the exact PPM grammar.
- README/CHANGELOG and policy topology close only after all packages have executable four-target examples and conformance tests.

</code_context>

<specifics>
## Specific Ideas

- Keep the general descriptor expressive, but make each operation's supported format set an explicit closed contract.
- Treat orientation 5–8, padded strides, plane overlap, one-byte-short storage, crop edge coordinates, resize 1×N/N×1, and in-place overlap as named adversarial classes.
- Make metadata disposition machine-testable per operation rather than relying on prose tables alone.

</specifics>

<deferred>
## Deferred Ideas

- Phase 5 implements the bounded PPM P6 codec and end-to-end reader/writer proof.
- YUV conversion, advanced resampling, arbitrary component formats, animation, tiled/GPU storage, native/system codecs, registries, and rendering remain future scope.

</deferred>

---

*Phase: 04-image-model-views-and-operations*
*Context gathered: 2026-07-17*
