# Phase 91: SVG Numeric Contract - Research

**Researched:** 2026-07-25  
**Domain:** Portable, bounded SVG numeric admission and route-matrix qualification  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Derive one documented, target-neutral finite numeric envelope from existing canvas, raster, and resource constraints; do not choose an arbitrary generic `Double` magnitude. — **Reversibility:** costly — the contract is exercised by every SVG numeric ingress and compatibility fixture.
- **D-02:** Route-matrix evidence must cover both source parsing and every derived path (relative geometry, viewBox mapping, affine construction/composition, and trigonometric transforms).

### Explicit versus absent values
- **D-03:** An explicitly supplied malformed, non-finite, out-of-envelope, or unsafe numeric value is a structured SVG error. Only an absent attribute may take the existing SVG default or inheritance path. — **Reversibility:** costly — changing it later would weaken published parser behavior and test fixtures.
- **D-04:** Stable error category/context is required; full diagnostic-message text is not a compatibility contract.

### Valid geometry and rendering ownership
- **D-05:** Retain finite singular transforms such as `scale(0)`; non-invertibility alone is not numeric unsafety.
- **D-06:** `mb-svg` validates numeric input before a `SceneNode` exists. `lower_to_drawing_list` and `mb-canvas` remain total consumers of that validated scene; RFC 0008 opacity/layer behavior is unchanged.

### the agent's Discretion
Choose the exact helper placement and test organization from existing `mb-svg` parser patterns, provided the admission policy stays centralized and target-neutral.

### Deferred Ideas (OUT OF SCOPE)
None — SVG feature expansion, layer optimization, and native acceleration remain outside v0.30.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SVGPR-01 | Library users receive a documented, target-neutral SVG numeric admission contract with route-matrix tests for every supported scalar ingress and derived-value path. | The documented 65,536 envelope, source/derived route matrix, stable error assertions, and four-target test command below. [VERIFIED: repository `REQUIREMENTS.md`, `modules/mb-svg/svg/`] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models should be written in MoonBit; the phase must not replace the portable numeric boundary with a foreign wrapper.
- Native is the primary target, but portable targets are supported through capability boundaries and conformance tests; the contract and its evidence must hold on `js`, `wasm`, `wasm-gc`, and `native`.
- Public packages must have acyclic, explicitly documented dependencies; do not introduce a reverse `mb-canvas`/`mb-svg` dependency for validation.
- Public operations should be deterministic and usable without GUI state; the documented admission outcome and route matrix must be automation-friendly.
- Public API stability follows Semantic Versioning after a package is stable; stable error fields are preferable to diagnostic-message text.
- New modules and breaking architectural changes require RFCs; this phase keeps the existing `mb-svg` → `mb-canvas` ownership boundary.
- `*_test.mbt` black-box tests validate public APIs and `*_wbtest.mbt` cover internal invariants; add route-matrix evidence in the existing MoonBit test convention.
- Prefer codebase-memory graph tools for code discovery and fall back to text search only if the graph lacks the needed MoonBit symbols; the graph was queried first and had no usable MoonBit source-symbol index. [VERIFIED: `AGENTS.md`; VERIFIED: graph probe 2026-07-25]
- Do not make direct production edits outside a GSD workflow; this research phase writes only its planning artifact. [VERIFIED: `AGENTS.md`]

## Summary

The implementation-ready contract is: admit a scalar only when it is finite and lies in the inclusive portable envelope `[-65536.0, 65536.0]`; apply the same predicate to every value produced while building geometry or an affine transform. [VERIFIED: repository `modules/mb-svg/svg/{scene,path_data}.mbt`; inference from both default `ResourceLimits.width` and `.height` being `65536UL`] The magnitude is not a generic `Double` limit: it is the already-declared SVG resource dimension ceiling, and it remains safely representable by the canvas rasterizer's `Double -> Int -> UInt64` device-coordinate clamp. [VERIFIED: repository `modules/mb-svg/svg/{scene,path_data}.mbt`, `modules/mb-canvas/canvas/rasterize.mbt`]

Phase 91 should publish that policy and install executable route-matrix evidence, without performing the fallible parser/scene signature migration reserved for Phase 92. [VERIFIED: repository `91-CONTEXT.md`] The matrix must identify each current coercion seam—length/list parsing, path reader, scene defaults/inheritance, transforms, viewBox lowering, and functional colour components—and specify whether Phase 92 must reject it at source or after a derived calculation. [VERIFIED: repository `modules/mb-svg/svg/{length,path_data,scene,transform,lower,color}.mbt`]

**Primary recommendation:** Add `docs/policies/svg-numeric-admission.md` and a table-driven `numeric_contract_wbtest.mbt` route matrix now; make Phase 92 implement one package-private scalar/derived/affine validation seam that satisfies those tests. [VERIFIED: repository documentation and test layout; inference from current package-local `*_wbtest.mbt` convention]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Lexical SVG scalar admission | API / Backend (`mb-svg`) | — | `parse_length`, `parse_number_list`, and `read_number` convert untrusted SVG text before scene construction. [VERIFIED: repository `modules/mb-svg/svg/{length,path_data}.mbt`] |
| Derived coordinate and affine admission | API / Backend (`mb-svg`) | — | Relative paths, viewBox mapping, and transform composition are SVG semantic calculations, not raster operations. [VERIFIED: repository `modules/mb-svg/svg/{path_data,transform,lower}.mbt`] |
| Typed scene invariant | API / Backend (`mb-svg`) | — | `parse_svg` returns a `SceneNode`; lowering accepts that typed node and has no error result. [VERIFIED: repository `modules/mb-svg/svg/{scene,lower}.mbt`] |
| Device conversion and pixel bounds | Database / Storage (`mb-image`) plus API / Backend (`mb-canvas`) | — | `mb-canvas` clamps raster coordinates to the supplied image view; `mb-image` owns checked image storage/view dimensions. [VERIFIED: repository `modules/mb-canvas/canvas/rasterize.mbt`, `modules/mb-image/{model,storage}/`] |
| Opacity layers | API / Backend (`mb-canvas`) | `mb-svg` producer | The lowerer emits `PushLayer`/`PopLayer`; canvas owns bounded offscreen allocation and the depth cap. [VERIFIED: repository `modules/mb-svg/svg/lower.mbt`, `modules/mb-canvas/canvas/rasterize.mbt`; CITED: `docs/rfcs/0008-mb-canvas-layer.md`] |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why standard |
|----------------|---------|---------|--------------|
| MoonBit toolchain | `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf` | Compile and execute the portable SVG test suite. | Installed project toolchain; the existing `mb-svg` module declares `js`, `wasm`, `wasm-gc`, and `native`. [VERIFIED: local `moon --version`, `modules/mb-svg/{moon.mod.json,svg/moon.pkg}`] |
| MoonBit `Double` | bundled | `is_nan()` and `is_inf()` provide portable non-finite predicates. | Both methods are implemented in the installed core library and are usable on the project's targets. [VERIFIED: installed MoonBit core `builtin/double.mbt`] |
| `mb-core/error::CoreError` | workspace | Stable category/code/operation/context assertions. | It exposes typed accessors while keeping representation private; rendered prose is deliberately not needed as a test contract. [VERIFIED: repository `modules/mb-core/error/core_error.mbt`] |
| `mb-core/budget::ResourceLimits` | workspace | Existing resource basis for the envelope. | Both default SVG parsing entry points set width and height limits to `65536UL`. [VERIFIED: repository `modules/mb-svg/svg/{scene,path_data}.mbt`] |

### Supporting

| Library | Version | Purpose | When to use |
|---------|---------|---------|
| `mb-core/math::Affine2` | workspace | Stores transform coefficients and composes them with multiply/add arithmetic. | Validate all six output coefficients after construction and every composition; do not change `Affine2` itself. [VERIFIED: repository `modules/mb-core/math/affine.mbt`] |
| `mb-svg` white-box tests | workspace | Package-private route-matrix checks. | Put policy-level checks beside `parse_wbtest.mbt`, `path_data_wbtest.mbt`, `transform_wbtest.mbt`, and `scene_wbtest.mbt`; retain black-box conformance controls. [VERIFIED: repository `modules/mb-svg/svg/*_wbtest.mbt`] |

**Installation:** None—this phase needs no external package. [VERIFIED: repository `modules/mb-svg/moon.mod.json`]

## Package Legitimacy Audit

Not applicable: Phase 91 installs no external package. [VERIFIED: phase scope in `91-CONTEXT.md`]

## Numeric Admission Contract

### Exact envelope

Use `SVG_NUMERIC_LIMIT = 65536.0` and define `accepted(v) = !v.is_nan() && !v.is_inf() && v >= -SVG_NUMERIC_LIMIT && v <= SVG_NUMERIC_LIMIT`. [VERIFIED: installed MoonBit core `builtin/double.mbt`; VERIFIED: repository `modules/mb-svg/svg/{scene,path_data}.mbt`; inference from the shared `65536UL` resource dimension limit]

Apply the inclusive boundary to **source scalars and each derived scalar/component**; do not apply it to an affine determinant or use invertibility as admission. [VERIFIED: repository `modules/mb-core/math/affine.mbt`; CITED: `91-CONTEXT.md` D-05] This accepts signed zero, ordinary negative coordinates, and all finite singular matrices such as `scale(0)`. [CITED: `91-CONTEXT.md` D-05; VERIFIED: repository `modules/mb-core/math/affine.mbt`]

`65536.0` is the only presently evidenced cross-target coordinate/dimension magnitude in the SVG resource defaults. [VERIFIED: repository `modules/mb-svg/svg/{scene,path_data}.mbt`] It is deliberately a symmetric scalar envelope so negative SVG user-space coordinates retain the existing supported semantic, while width/height remain separately subject to their usual SVG validity rules during Phase 92. [VERIFIED: repository `modules/mb-svg/svg/{scene,lower}.mbt`; inference from current negative-coordinate fixture and viewBox logic]

### Stable error contract

Preserve the existing SVG error shape—`ErrorCategory::Data`, `operation="svg"`, and a stable route-specific `context`—rather than asserting message prose. [VERIFIED: repository `modules/mb-svg/svg/svg.mbt`, `modules/mb-core/error/core_error.mbt`; CITED: `91-CONTEXT.md` D-04]

| Failure | Required category/code | Stable context | Route owns it |
|---------|------------------------|----------------|----------------|
| Malformed numeric token or unsupported suffix | `Data` / `InvalidEncoding` | `svg-numeric-source` | length, list, points, path, transform, style, colour numeric components. [VERIFIED: existing SVG errors use `Data` / `InvalidEncoding` in `svg.mbt`; recommendation is route normalization] |
| Parsed non-finite value | `Data` / `InvalidEncoding` | `svg-numeric-nonfinite` | shared scalar admission. [VERIFIED: installed MoonBit core predicates; recommendation preserves existing SVG error family] |
| Finite source value outside envelope | `Data` / `InvalidRange` | `svg-numeric-range` | shared scalar admission. [VERIFIED: repository `CoreError` supports `InvalidRange`; recommendation] |
| Unsafe result after arithmetic | `Data` / `InvalidRange` | `svg-numeric-derived` | relative path, viewBox, transform construction/composition, trigonometry. [VERIFIED: repository arithmetic paths; recommendation] |

The Phase 91 tests should compare `category()`, `code()`, `operation()`, and `context()`; they must not snapshot `render_error` or message text. [VERIFIED: repository `modules/mb-core/error/core_error.mbt`; CITED: `91-CONTEXT.md` D-04]

## Architecture Patterns

### System Architecture Diagram

```text
SVG text / explicit attribute
        |
        v
length/list/path/transform lexical readers
        |  source scalar: finite + [-65536, 65536]
        v
fallible SVG builders ──invalid──> CoreError(category/code/context)
        |
        |  derived scalar/component: same admission
        v
validated SceneNode
        |
        v
lower_to_drawing_list (total) --> DrawingList --> mb-canvas render
                                           |             |
                                           |             +-- owns device clamp, image budget,
                                           |                 PushLayer/PopLayer semantics
                                           +-- finite singular transforms remain representable
```

The illustrated boundary matches the current parse-to-scene-to-total-lowering flow; Phase 92 makes the two admission arrows real. [VERIFIED: repository `modules/mb-svg/svg/{scene,lower}.mbt`; CITED: `91-CONTEXT.md` D-06]

### Recommended Project Structure

```text
docs/policies/
└── svg-numeric-admission.md       # public envelope, error fields, route matrix
modules/mb-svg/svg/
├── numeric_contract_wbtest.mbt     # table-driven policy and derived-route evidence
├── parse_wbtest.mbt                # lexical length/list controls
├── path_data_wbtest.mbt            # path and relative-coordinate controls
├── transform_wbtest.mbt            # affine/trigonometric controls
├── scene_wbtest.mbt                # absent-vs-explicit and style/geometry controls
└── lower_wbtest.mbt                # valid-boundary and opacity non-regression controls
```

This adds a focused matrix without moving existing focused test coverage or changing production parsing in Phase 91. [VERIFIED: repository test layout; CITED: `91-CONTEXT.md` phase boundary]

### Pattern 1: Central admission predicates, separate source from derived

**What:** Specify three private Phase-92 helpers: `admit_source_scalar`, `admit_derived_scalar`, and `admit_affine` (the last validates `a,b,c,d,tx,ty`). [VERIFIED: repository scalar and `Affine2` seams; recommendation]

**When to use:** Source admission immediately after lexical conversion; derived admission after every operation that can add, subtract, multiply, divide, convert degrees, invoke trigonometry, or compose an affine. [VERIFIED: repository `modules/mb-svg/svg/{path_data,transform,lower}.mbt`]

**Example:**

```moonbit
// Sources: installed MoonBit core builtin/double.mbt; repository svg.mbt pattern.
fn admit_derived_scalar(value : Double) -> Result[Double, @error.CoreError] {
  if value.is_nan() || value.is_inf() || value < -65536.0 || value > 65536.0 {
    Err(svg_error("svg-numeric-derived", "unsafe derived SVG scalar"))
  } else {
    Ok(value)
  }
}
```

The exact helper implementation belongs to Phase 92; this example records the predicate and error seam which Phase 91 tests/documentation must lock. [CITED: `91-CONTEXT.md` phase boundary]

### Pattern 2: Missing attribute is a control-flow branch, invalid explicit value is an error

`None` may select an existing default or inherited value; `Some(s)` must invoke a fallible numeric parser and propagate failure. [VERIFIED: repository `modules/mb-svg/svg/scene.mbt`; CITED: `91-CONTEXT.md` D-03] Current `attr_double`, `inherit_double`, root width/height/viewBox handling, points, and functional colour parsing instead turn some explicit failures into defaults, inheritance, `None`, empty arrays, or zero. [VERIFIED: repository `modules/mb-svg/svg/{scene,path_data,color}.mbt`]

### Route matrix to lock in Phase 91

| Route | Current seam | Required Phase-92 admission/evidence |
|-------|--------------|--------------------------------------|
| `width`, `height`, `viewBox` | `build_svg_root_attrs` converts explicit parse errors to `None`; `parse_viewbox` currently accepts 4-or-more values. | Exact four source scalars; present invalid/out-of-range fails; omitted width/height remains `None`; test derived `sx`, `sy`, translation. [VERIFIED: repository `length.mbt`, `scene.mbt`, `lower.mbt`] |
| Shape geometry (`rect`, `circle`, `ellipse`, `line`) | `attr_double` defaults explicit parse failures. | Every supported geometry attribute accepts boundary controls and rejects malformed/non-finite/out-of-range values before node creation. [VERIFIED: repository `scene.mbt`] |
| `points` | `points_from_attrs` returns `[]` when an explicit list fails. | Validate every list scalar and each paired `Point2`; explicit failure is an error, missing attribute remains empty. [VERIFIED: repository `scene.mbt`, `length.mbt`] |
| Paths | `read_number` maps parse failure to `(0.0, i)`; relative branches add to `cur_*`; smooth commands reflect control points. | Reject missing/malformed number positions and validate every relative addition/reflection/end point; cover M/L/H/V/C/Q/S/T/A. [VERIFIED: repository `path_data.mbt`] |
| Transforms | `parse_number_list` feeds `matrix`, translate, scale, rotate, skew; `Affine2::compose` multiplies/adds six coefficients. | Exact transform arity; source and each constructed/composed coefficient admitted; retain `scale(0)` control. [VERIFIED: repository `transform.mbt`, `modules/mb-core/math/affine.mbt`] |
| Trigonometry | degrees-to-radians feeds `Affine2::rotate`; skew currently stores converted angle directly. | Validate degree conversion and all rotate/skew affine output components; test finite source that derives unsafe result. [VERIFIED: repository `transform.mbt`, `modules/mb-core/math/affine.mbt`] |
| Paint numerics | `inherit_double`, `attr_double`, dash list, and `parse_double_or` feed opacity/stroke/colour components. | Present invalid style scalar fails; absent inherited/default style remains unchanged; finite opacity range normalization and layer semantics stay unchanged. [VERIFIED: repository `scene.mbt`, `color.mbt`, `lower.mbt`; CITED: `91-CONTEXT.md` D-06] |
| Lower-only derivation | `viewbox_transform`, rounded-rect ratios, and circle sampling perform arithmetic after scene construction. | Phase 91 specifies controls and Phase 92 validates unsafe results before a usable SceneNode/lowering path; valid boundary scenes retain existing drawing-list output. [VERIFIED: repository `lower.mbt`; CITED: `91-CONTEXT.md` D-06] |

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Non-finite detection | String comparison against `NaN`/`Infinity` spellings | `Double::is_nan()` and `Double::is_inf()` after the repository's lexical conversion | These predicates cover runtime values resulting from overflow as well as any accepted spelling. [VERIFIED: installed MoonBit core `builtin/double.mbt`; VERIFIED: repository `number_parse.mbt`] |
| Structured error representation | An SVG-local error enum or message snapshots | Existing `@error.CoreError` typed category/code/operation/context fields | It is already the public result type and its fields are stable accessors. [VERIFIED: repository `modules/mb-core/error/core_error.mbt`, `modules/mb-svg/svg/`] |
| Affine arithmetic | A duplicate SVG matrix type | `@math.Affine2`, followed by SVG-side admission validation | The current parser/lowerer/canvas already exchange this type. [VERIFIED: repository `modules/mb-svg/svg/{transform,lower}.mbt`, `modules/mb-core/math/affine.mbt`] |

**Key insight:** resource budgets limit document work but do not validate floating-point semantics; the SVG contract must combine the existing dimensional bound with explicit `Double` admission at the parse/scene boundary. [VERIFIED: repository `modules/mb-core/budget/budget.mbt`, `modules/mb-svg/svg/{scene,path_data}.mbt`; CITED: `docs/rfcs/0002-mb-svg.md` §8.1]

## Common Pitfalls

### Pitfall 1: Source-only checking

**What goes wrong:** Finite operands can yield an unsafe sum, product, quotient, or affine coefficient. [VERIFIED: repository `path_data.mbt`, `transform.mbt`, `lower.mbt`, `affine.mbt`]

**How to avoid:** The matrix must include a relative-coordinate overflow, rotate-about-centre composition overflow, transform-list composition overflow, and viewBox scale/translation overflow, with the same error fields as source failure. [VERIFIED: repository arithmetic routes; recommendation]

### Pitfall 2: Fail-open present attributes

**What goes wrong:** The current code may turn explicit parse failure into a default, inherited value, `None`, empty points, or path coordinate zero. [VERIFIED: repository `modules/mb-svg/svg/{scene,path_data,color}.mbt`]

**How to avoid:** Give every route a paired absent control and explicit-invalid test, and require `Err` for the latter. [CITED: `91-CONTEXT.md` D-03]

### Pitfall 3: Rejecting singular transforms

**What goes wrong:** Using `Affine2::inverse()` as a validation predicate rejects determinant-zero matrices. [VERIFIED: repository `modules/mb-core/math/affine.mbt`]

**How to avoid:** Assert `parse_transform("scale(0)")` succeeds; validate coefficient finiteness/range, not determinant. [CITED: `91-CONTEXT.md` D-05]

### Pitfall 4: Altering opacity/layer semantics

**What goes wrong:** Numeric hardening can accidentally move group/element opacity into paint alpha or change `PushLayer`/`PopLayer` emission. [VERIFIED: repository `modules/mb-svg/svg/lower.mbt`; CITED: `docs/rfcs/0008-mb-canvas-layer.md`]

**How to avoid:** Keep valid opacity draw-op and overlap controls in `lower_wbtest.mbt`; do not touch canvas layer code in this phase. [CITED: `91-CONTEXT.md` D-06]

## Code Examples

### Four-target policy gate

```powershell
moon test modules/mb-svg/svg --target all --frozen
```

This command ran successfully during research: 84 tests passed on `wasm`, `wasm-gc`, `js`, and `native`. [VERIFIED: local command run 2026-07-25]

### Stable error assertion shape

```moonbit
match parse_svg("<svg><rect x=\"65537\"/></svg>") {
  Err(error) => {
    inspect(error.category(), content="Data")
    inspect(error.code(), content="InvalidRange")
    inspect(error.operation(), content="Some(\\\"svg\\\")")
    inspect(error.context(), content="Some(\\\"svg-numeric-range\\\")")
  }
  Ok(_) => inspect(false, content="true")
}
```

The assertion values are the recommended Phase-91 contract; the current parser does not yet provide this failure and Phase 92 supplies it. [CITED: `91-CONTEXT.md` phase boundary; VERIFIED: repository `CoreError` accessors]

## State of the Art

| Old approach | Current Phase-91 contract | Impact |
|--------------|----------------------------|--------|
| Budget only: depth/work and uncharged width/height defaults; parser fallback values can enter scene data. | Explicit finite/bounded source and derived admission using the already-declared 65,536 resource dimension. | Makes numeric safety inspectable before SceneNode creation and portable across declared targets. [VERIFIED: repository `modules/mb-svg/svg/{scene,path_data}.mbt`; CITED: `docs/rfcs/0002-mb-svg.md` §8.1] |

**Deprecated/outdated:** treating `@text.parse_double` success as numeric admission is insufficient because its arithmetic can yield infinity through exponent multiplication and current callers do not check `is_nan()`/`is_inf()`. [VERIFIED: repository `modules/mb-core/text/number_parse.mbt`, `modules/mb-svg/svg/{length,path_data}.mbt`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | None. The 65,536 recommendation is an explicit inference from the repository's two identical default SVG dimension limits, not a claim about an external SVG standard. | Numeric Admission Contract | The planner must keep that derivation and boundary tests visible so a future resource-policy change triggers an intentional contract review. [VERIFIED: repository `modules/mb-svg/svg/{scene,path_data}.mbt`] |

## Open Questions (RESOLVED)

1. **Should Phase 91 land intentionally failing tests before Phase 92? — RESOLVED: No.**
   - Phase 91 keeps the passing `moon test modules/mb-svg/svg --target all --frozen` baseline. Its route matrix is executable through valid finite/boundary controls and parse-to-lower preservation checks; it does not assert rejection behavior that the current parser does not yet implement. [CITED: `91-CONTEXT.md` phase boundary; decision supplied for plan revision]
   - Phase 92 owns behavior-changing rejection assertions for explicitly supplied malformed, non-finite, out-of-envelope, and unsafe-derived values, including the structured-error fields required by D-03 and D-04. This does not defer Phase 91 route coverage: the policy and valid controls name every route now. [CITED: `91-CONTEXT.md` D-03, D-04; decision supplied for plan revision]

2. **Which colour-function numeric forms belong to SVGPR-01? — RESOLVED: Cover only current parser ingress.**
   - Phase 91 tests the supported lowercase, comma-separated `rgb()`/`rgba()` routes through their three consumed components: numeric or percent RGB components. It also tests lowercase, comma-separated `hsl()`/`hsla()` through hue parsed as a number and saturation/lightness through the current percent-component path. The fourth alpha component in `rgba()`/`hsla()` is not a current numeric ingress because `parse_func_color` consumes only the first three components. [VERIFIED: repository `modules/mb-svg/svg/color.mbt`; decision supplied for plan revision]
   - CSS Color 4 space-separated or slash-alpha forms, and unsupported functions such as `hwb()`, `lab()`, `lch()`, and `color()`, are unsupported/non-ingress for SVGPR-01. They are documented as excluded routes, not converted into tests of unsupported behavior. [VERIFIED: repository `modules/mb-svg/svg/color.mbt`; decision supplied for plan revision]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` / `moonc` / `moonrun` | Policy route-matrix qualification | ✓ | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | — [VERIFIED: local `moon --version`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local tool probe]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard control |
|---------------|---------|------------------|
| V2 Authentication | No | This library phase has no authentication boundary. [VERIFIED: repository `modules/mb-svg/`] |
| V3 Session Management | No | This library phase has no session state. [VERIFIED: repository `modules/mb-svg/`] |
| V4 Access Control | No | This phase accepts SVG data but contains no authorization decision. [VERIFIED: repository `modules/mb-svg/`] |
| V5 Input Validation | Yes | Parse untrusted scalar text once, reject malformed/non-finite/out-of-envelope source and derived values before scene creation. [CITED: https://owasp.org/www-project-application-security-verification-standard/; CITED: `91-CONTEXT.md` D-03] |
| V6 Cryptography | No | No cryptographic operation is in scope. [VERIFIED: phase scope `91-CONTEXT.md`] |

### Known Threat Patterns for portable SVG parsing

| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| Numeric coercion to a plausible default | Tampering | Stable `CoreError` for an explicit invalid value; default/inheritance only on attribute absence. [VERIFIED: current fallback routes; CITED: `91-CONTEXT.md` D-03] |
| Finite operands creating unsafe derived geometry | Denial of service | Apply the same predicate immediately after relative arithmetic, affine construction/composition, viewBox derivation, and trigonometry. [VERIFIED: repository arithmetic routes; CITED: `91-CONTEXT.md` D-02] |
| Huge or non-finite geometry reaching device conversion | Denial of service | Bound at SVG ingress using the existing 65,536 resource dimension rather than relying on later raster clamp. [VERIFIED: repository `scene/path_data/rasterize`; inference] |

## Sources

### Primary (HIGH confidence)

- Repository SVG seams: `modules/mb-svg/svg/{length,path_data,transform,scene,lower,color}.mbt` — scalar ingress, defaults, derivations, lowering. [VERIFIED: repository source]
- Repository numeric/resource seams: `modules/mb-core/{text/number_parse,error/core_error,math/affine,budget/budget}.mbt` — lexical conversion, errors, affine arithmetic, limits. [VERIFIED: repository source]
- Repository canvas/image seams: `modules/mb-canvas/canvas/{rasterize,style}.mbt` and `modules/mb-image/{model,storage}/` — device clamp, layer ownership, bounded image path. [VERIFIED: repository source]
- Installed MoonBit core `builtin/double.mbt` — `Double::is_nan()` and `Double::is_inf()`. [VERIFIED: installed toolchain source]
- `docs/rfcs/0002-mb-svg.md` §8.1 and `docs/rfcs/0008-mb-canvas-layer.md` §§4–7 — SVG checked-geometry target and unchanged layer ownership. [CITED: repository RFCs]

### Secondary (MEDIUM confidence)

- OWASP ASVS project page — validation/sanitization control category used for the security mapping. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — live toolchain and installed core source were inspected. [VERIFIED: local tool probe]
- Architecture: HIGH — all parse, scene, lower, affine, and raster seams were inspected in the live repository. [VERIFIED: repository source]
- Pitfalls: HIGH — each is tied to a current fallback or arithmetic route. [VERIFIED: repository source]

**Research date:** 2026-07-25  
**Valid until:** 2026-08-24, unless Phase 92 changes the default SVG resource limits or `Affine2` API. [VERIFIED: repository dependency points]
