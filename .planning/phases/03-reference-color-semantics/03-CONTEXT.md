# Phase 3: Reference Color Semantics - Context

**Gathered:** 2026-07-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the private `mb-color` scaffold with portable, explicit reference semantics for normalized and encoded sRGB components, transfer functions, straight and premultiplied alpha, deterministic conversion and quantization, and a bounded opaque profile-metadata seam. This phase supplies the semantic oracle consumed by `mb-image`; it does not add image storage/layout, codecs, CSS syntax, rendering, broad color management, or ICC parsing.

</domain>

<decisions>
## Implementation Decisions

### Component, color-space, and transfer identity
- **D-01:** Public values make component representation, color-space identity, transfer function, and alpha mode explicit. No constructor or operation may obtain any of these from an ambient or undocumented default.
- **D-02:** Use opaque validated component types for normalized finite reference values and encoded 8-bit values. A universal public `Color` bag with freely combinable fields is prohibited; constructors must reject invalid combinations.
- **D-03:** Phase 3's normative built-ins are sRGB primaries/white point with either encoded-sRGB or linear-sRGB transfer. Space identity and transfer identity remain explicit concepts so later extensions do not redefine existing values.

### sRGB conversion and quantization
- **D-04:** Normalized reference components accept only finite values in `[0,1]`. NaN, infinity, and out-of-range values are structured errors; conversion never silently clamps, wraps, or substitutes a default.
- **D-05:** Encoded-sRGB to linear-sRGB and the inverse use the normative piecewise transfer curve with constants and branch boundaries recorded in the public contract and reference evidence. CPU MoonBit behavior is the correctness oracle on all four targets.
- **D-06:** Floating conversion assertions use operation-specific documented absolute tolerances. Float-to-8-bit quantization is a separate explicit operation using round-to-nearest, ties-to-even; validated input means no implicit saturation is required. Research must confirm a portable implementation against the pinned toolchain and official sources.

### Straight and premultiplied alpha
- **D-07:** Straight and premultiplied representations are distinct explicit public states; APIs do not guess or toggle alpha mode implicitly.
- **D-08:** Premultiplication and unpremultiplication operate on validated normalized values and encoded 8-bit values. Encoded operations use widened checked arithmetic and the same documented ties-to-even rule rather than backend casts.
- **D-09:** Zero alpha has one canonical result: color components are zero for both premultiply and unpremultiply. For nonzero alpha, a premultiplied encoded component greater than alpha is invalid and returns a structured error rather than being clamped. Round-trip identity is asserted only where mathematically guaranteed; otherwise error bounds are documented.

### Bounded profile identity and opaque metadata
- **D-10:** Built-in sRGB identity is represented directly. Non-built-in profile data crosses the public seam as an opaque, bounded payload with an explicit format tag; bytes round-trip exactly without interpreting or validating ICC contents.
- **D-11:** Opaque payload creation uses `mb-core` owned bytes/validated views and charges declared size/allocation budgets before copying or retaining data. Oversize, budget rejection, and invalid tag failures are structured and deterministic.
- **D-12:** Phase 3 does not inspect headers, compute transforms from profiles, or claim ICC conformance. A stable optional digest/identifier may be exposed only as identity metadata and must not imply semantic equivalence.

### Reference evidence and qualification
- **D-13:** Reference vectors come from official or otherwise primary specifications and are registered through the repository fixture provenance policy with origin, license/redistribution status, retrieval date, and digest. Hand-authored edge vectors are separate and labeled as derived tests.
- **D-14:** Conformance combines provenance-recorded conversion vectors with invariants: endpoint behavior, branch boundaries, monotonicity, finite/range preservation, quantization bounds, alpha zero/boundary cases, and bounded profile round-trip.
- **D-15:** Every public package and README example is checked on `js`, `wasm`, `wasm-gc`, and `native`. Exact semantic interfaces, imports, publication contents, package DAG, negative fixtures, and tracked-read-only behavior remain Required-lane gates.

### Package and dependency boundary
- **D-16:** Prefer focused acyclic packages such as model/components, transfer/conversion, alpha, and profile rather than a root catch-all. `mb-color` depends only on the minimum portable `mb-core` packages it uses; no reverse or image dependency is allowed.
- **D-17:** Remove the Phase 1 root scaffold once real public packages and checked documentation replace it. Keep the module independently versioned and candidate until later stability review.
- **D-18:** Additional spaces/transfers, chromatic adaptation, gamut mapping, interpolation, CSS syntax, image/pixel layout, codecs, rendering, and full ICC parsing are outside this phase.

### the agent's Discretion
- Exact MoonBit type and package names, internal polynomial/piecewise implementation structure, fixture file format, and tolerance magnitudes are left to research and planning, provided the locked semantics above remain explicit, portable, and independently testable.
- The planner may split the phase into sequential packages/waves and add property or adversarial tests beyond the minimum matrix.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 3 goal, dependency, and four success criteria.
- `.planning/REQUIREMENTS.md` — normative COLR-01 through COLR-05 requirements.
- `.planning/PROJECT.md` — project constraints and v0.1 milestone boundary.

### Architecture and policy
- `docs/rfcs/0001-moonbit-native-foundation.md` — accepted `mb-color` ownership, dependency boundary, portability, and v0.1 scope.
- `.planning/research/ARCHITECTURE.md` — color-layer responsibilities, reference-oracle rule, package direction, and anti-patterns.
- `.planning/research/STACK.md` — pinned toolchain, four targets, module/package model, tests, and dependency policy.
- `docs/policies/targets.md` — portable target requirements and native-leaf isolation.
- `docs/policies/api-stability.md` — candidate API and compatibility expectations.
- `docs/policies/licensing-and-fixtures.md` — mandatory provenance, licensing, digest, and containment rules for reference vectors.

### Existing implementation seams
- `modules/mb-color/README.mbt.md` — current module boundary and scaffold promises Phase 3 replaces.
- `modules/mb-color/moon.mod.json` — module identity and target metadata.
- `policy/foundation.json` — exact module identity, dependency edge, public-package/interface, and publication policy source.
- `modules/mb-core/error/core_error.mbt` — structured error vocabulary consumed by color validation.
- `modules/mb-core/checked/checked.mbt` — checked arithmetic and narrowing behavior for encoded alpha/quantization.
- `modules/mb-core/budget/budget.mbt` — resource charging contract for bounded profile payloads.
- `modules/mb-core/bytes/owned_bytes.mbt` and `modules/mb-core/bytes/views.mbt` — owned storage and retained immutable views for opaque profile round-trip.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-color/` already supplies an independently versioned module, four-target manifest, literate README, changelog, and private scaffold that can be replaced incrementally.
- `mb-core/error`, `checked`, `budget`, and `bytes` provide the validated, bounded primitives Phase 3 should reuse rather than duplicate.
- `scripts/quality.ps1`, `scripts/quality/Invoke-MoonQuality.ps1`, and `policy/foundation.json` already enforce four-target tests, exact interfaces/imports/package contents, and fail-closed negative fixtures.
- `fixtures/manifest.json` and `docs/policies/licensing-and-fixtures.md` provide the established provenance/digest mechanism for color vectors.

### Established Patterns
- Public portable packages declare all four targets, use black-box public tests plus white-box invariant tests, and expose opaque validated state.
- Machine-readable policy and generated interfaces are exact ordered/closed allowlists; package topology and policy change atomically.
- Deterministic reference behavior rejects ambient state and backend-width assumptions; structured errors carry stable codes and bounded typed context.

### Integration Points
- `mb-color` may add only declared inward dependencies on portable `mb-core` packages and must remain the sole semantic dependency of Phase 4 image color fields.
- New packages replace the root scaffold, update module README/CHANGELOG, and enter the existing root Required lane on every target.
- Phase 4 consumes explicit space/transfer/alpha/profile types; Phase 5 relies on the bounded profile seam and reference conversions through image/codec APIs.

</code_context>

<specifics>
## Specific Ideas

- Prefer types and constructors that make ambiguous color state unrepresentable over public fields plus documentation-only conventions.
- Treat branch thresholds, zero alpha, half-way quantization cases, and invalid premultiplied components as named adversarial test classes.
- Keep normative specification vectors distinct from locally derived edge/property fixtures so provenance claims remain honest.

</specifics>

<deferred>
## Deferred Ideas

- Full ICC parsing, profile validation, and profile-driven transforms are deferred beyond Phase 3.
- Additional color spaces and transfer functions, chromatic adaptation, gamut mapping, interpolation, and CSS color syntax require later accepted scope.
- Image storage/layout, channel order, pixel format, codecs, and rendering remain in their owning later phases.

</deferred>

---

*Phase: 03-reference-color-semantics*
*Context gathered: 2026-07-17*
