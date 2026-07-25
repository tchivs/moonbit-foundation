# Phase 92: Fail-Closed SVG Parsing - Research

**Researched:** 2026-07-26
**Domain:** Portable MoonBit SVG numeric admission and fail-closed scene parsing
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Admission ownership
- **D-01:** Use the Phase 91 target-neutral finite envelope (`[-65536.0, 65536.0]`) as the only numeric admission policy. Centralize finite/bounded checks at parser ingress and checked derived-value seams instead of spreading unrelated caps through lowering. — **Reversibility:** costly — every supported parser path and compatibility fixture relies on the public admission contract.
- **D-02:** Validate all explicit scalar routes: coordinates, lengths, transforms, viewBox values, path arguments, and supported paint scalars; validate relative-coordinate, viewBox, affine construction/composition, transform-to-geometry, and trigonometric derivations before a scene exists.

### Failure semantics
- **D-03:** Any explicitly supplied malformed, non-finite, out-of-envelope, or derivatively unsafe scalar returns a structured SVG error. It must never silently default, clamp, wrap, or create a partial scene/drawing list. — **Reversibility:** costly — weakening this would be a public error-contract regression.
- **D-04:** Omitted attributes alone retain their established SVG defaults/inheritance. Tests assert stable error category and source/derived context, not full message wording.

### Compatibility boundaries
- **D-05:** Finite singular transforms, including `scale(0)`, remain accepted; non-invertibility is not an unsafe numeric result.
- **D-06:** `S/s` and `T/t` smooth path semantics remain outside the public numeric-admission guarantee until their parser normalization is completed in this phase; do not claim partial support or preserve malformed reads as compatibility behavior.
- **D-07:** `lower_to_drawing_list` and `mb-canvas` are total consumers of a validated scene. RFC 0008 PushLayer/PopLayer opacity and the 16-layer capability boundary are unchanged.

### the agent's Discretion
Choose helper names, internal error variants, and test organization from existing `mb-svg` patterns, provided every invalid explicit path fails before scene creation and four-target behavior remains deterministic.

### Deferred Ideas (OUT OF SCOPE)

None — feature expansion, native acceleration, layer redesign, release automation, and benchmark work remain in later v0.30 phases.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SVGPR-02 | Explicit unsafe SVG coordinates, lengths, transforms, viewBox, path, and paint scalars return a structured error with no scene or drawing list. | The ingress, fallback, derived-arithmetic, error-contract, and four-target test anchors below define an implementation order. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 92 should make `parse_svg` and the public leaf parsers reject unsafe explicit values by propagating `Result[..., @error.CoreError]` instead of using the current zero/default/empty fallbacks. The durable seam is a package-private numeric-admission helper used immediately after lexical conversion and after every parser-owned arithmetic result; it emits the four Phase 91 contexts and preserves `operation="svg"`. [CITED: docs/policies/svg-numeric-admission.md] [VERIFIED: codebase grep]

The main correctness risk is not only lexical conversion. `scene.mbt` currently materializes nodes through non-result builders, `path_data.mbt::read_number` converts failed numeric reads to `0.0`, `build_paint` discards parser errors, and `lower.mbt` performs viewBox, rounded-rectangle, ellipse-sampling, and transform arithmetic after parsing. The parser must validate those same deterministic derived values before returning `Ok(SceneNode)`; `lower_to_drawing_list` must remain unchanged as a total consumer. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

`S/s` and `T/t` require a real normalization pass, not a bounds wrapper: the current smooth-cubic branch documents four arguments but reads six, while reflected controls are carried across unrelated commands. Normalize exact arity, previous-command eligibility, source admission, relative arithmetic, and reflected controls before claiming them as supported numeric routes. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

**Primary recommendation:** Add a single internal numeric helper plus a parser-side, no-drawing-list scene validation walk; refactor all explicit-attribute builders and all path/transform/color routes to propagate its `Result` before `parse_svg` returns a scene. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Lexical scalar admission and structured SVG errors | API / Backend | — | `mb-svg` parses attributes and already exposes `Result[..., CoreError]`; this is before a public scene is returned. [VERIFIED: codebase grep] |
| Scene construction and inherited/default attributes | API / Backend | — | `scene.mbt` resolves `SvgRoot`, `PaintContext`, shapes, and groups. [VERIFIED: codebase grep] |
| Parser-owned derived arithmetic and transformed-geometry admission | API / Backend | — | Phase 91 assigns the checks to SVG before a usable scene reaches lowering. [CITED: docs/policies/svg-numeric-admission.md] |
| Drawing-list emission and layer semantics | API / Backend | Database / Storage — | `lower_to_drawing_list` emits `DrawingList`; it must stay total, and canvas owns opacity/layer capacity. [VERIFIED: codebase grep] [CITED: docs/rfcs/0008-mb-canvas-layer.md] |
| Four-target behavioral qualification | CDN / Static — | API / Backend | The package declares `+js+wasm+wasm-gc+native` and Moon's all-target test command runs each target. [VERIFIED: codebase grep] [VERIFIED: target test run] |

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models must be MoonBit; native is primary but portable targets must cross capability boundaries and conformance tests. [VERIFIED: AGENTS.md]
- Keep public module dependencies acyclic; native stubs, if any, must be small, isolated, documented, and replaceable. [VERIFIED: AGENTS.md]
- Public APIs follow semantic-versioning stability rules; GUI-free deterministic CLI/agent/MCP usage is first-class. [VERIFIED: AGENTS.md]
- Public-package black-box `*_test.mbt` tests are mandatory; `*_wbtest.mbt` covers internals. [VERIFIED: AGENTS.md]
- Follow the repository's GSD workflow for edits; this research is the Phase 92 planning artifact. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MoonBit `moon` / `moonc` / `moonrun` | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | Compile and run `mb-svg` tests for all supported targets. | The workspace already pins and successfully uses this toolchain. [VERIFIED: target test run] |
| `tchivs/mb-core/error` | workspace `0.1.0` | Portable `CoreError`, `ErrorCategory`, and `ErrorCode`. | `mb-svg` already imports it and all parse APIs use it. [VERIFIED: codebase grep] |
| `tchivs/mb-core/math` | workspace `0.1.0` | `Affine2`, points, and path commands used by scene/lowering validation. | It is the existing geometry dependency; no new math library is warranted. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `tchivs/mb-core/text` | workspace `0.1.0` | Deterministic double parsing and markup tokenization. | Keep using it for lexical parsing, then immediately map/admit the parsed scalar at the SVG boundary. [VERIFIED: codebase grep] |
| `tchivs/mb-canvas/canvas` | workspace `0.1.0` | `CanvasPath` and `DrawingList`. | Consume it only after successful SVG admission; do not move numeric policy or layer behavior into canvas. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Parser-side preflight | Validate in `lower_to_drawing_list` | Rejected: lowering cannot return `Result`, and this would allow `parse_svg` to return an unsafe scene. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md] |
| A local numeric helper | A new cross-module numeric-policy package | Rejected for this phase: the only policy consumer is `mb-svg`, and a new public dependency/module is unnecessary. [VERIFIED: codebase grep] |
| Typed `CoreError` accessors | Matching rendered error prose | Rejected: `CoreError` exposes stable category/code/operation/context accessors, while policy excludes full diagnostic wording from compatibility. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md] |

**Installation:** No package installation is required. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
SVG string
  -> markup tokenizer
  -> explicit scalar parser
       -> malformed? ------------------> Err(svg-numeric-source) -> no SceneNode / no DrawingList
       -> non-finite? -----------------> Err(svg-numeric-nonfinite) -> no SceneNode / no DrawingList
       -> out of [-65536,65536]? ------> Err(svg-numeric-range) -> no SceneNode / no DrawingList
  -> Result-propagating scene builders
       -> source/derived route check ---> Err(svg-numeric-derived) -> no SceneNode / no DrawingList
       -> parser-side derived validation (viewBox, affine, transformed geometry, generated paths)
  -> Ok(validated SceneNode)
  -> lower_to_drawing_list (total consumer)
  -> mb-canvas DrawingList / existing PushLayer-PopLayer behavior
```

The diagram describes the required fail-closed ownership boundary; current code already has `parse_svg -> SceneNode` and `SceneNode -> lower_to_drawing_list`, while Phase 92 adds the missing admission gates between them. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

### Recommended Project Structure

```text
modules/mb-svg/svg/
├── svg.mbt                    # retain generic SVG error helper; add numeric-error constructor
├── length.mbt                 # source-token/list/viewBox admission
├── transform.mbt              # exact arity plus trig/affine checks
├── path_data.mbt              # Result scanner and normalized smooth commands
├── color.mbt                  # Result-propagating supported numeric paint components
├── scene.mbt                  # Result builders, omitted/default branches, parser-side preflight
├── lower.mbt                  # unchanged total lowerer; reusable pure geometry helpers only if needed
├── svg_test.mbt               # public parse-error contract tests
└── *_wbtest.mbt               # route-specific parser and derived-value assertions
```

This structure extends the existing package boundaries; `svg_test.mbt` is the required public black-box complement to existing white-box tests. [VERIFIED: codebase grep] [VERIFIED: AGENTS.md]

### Pattern 1: Classify then admit every scalar

**What:** Parse one lexical token, map malformed conversion to `svg-numeric-source`, reject `is_nan()`/`is_inf()` as `svg-numeric-nonfinite`, and reject finite values outside the inclusive limit as `svg-numeric-range`. [CITED: docs/policies/svg-numeric-admission.md] [VERIFIED: codebase grep]

**When to use:** `parse_length`, `parse_number_list`, path token scanning, transform parameters, and supported functional-colour numeric components. [CITED: docs/policies/svg-numeric-admission.md]

**Example:**

```moonbit
// Source: modules/mb-svg/svg/transform_wbtest.mbt proves is_nan/is_inf on all targets.
let SVG_NUMERIC_LIMIT = 65536.0

fn admit_source(value : Double) -> Result[Double, @error.CoreError] {
  if value.is_nan() || value.is_inf() {
    Err(svg_numeric_error(@error.ErrorCode::InvalidEncoding, "svg-numeric-nonfinite"))
  } else if value.abs() > SVG_NUMERIC_LIMIT {
    Err(svg_numeric_error(@error.ErrorCode::InvalidRange, "svg-numeric-range"))
  } else {
    Ok(value)
  }
}
```

The helper must receive only a successfully lexed `Double`; lexical failure is converted by the caller to `svg-numeric-source`, rather than leaking `text-parse-double` fields. [CITED: docs/policies/svg-numeric-admission.md] [VERIFIED: codebase grep]

### Pattern 2: Propagate explicit-value failures; preserve absent branches

**What:** Make `build_svg_root_attrs`, `build_paint`, `inherit_double`, shape builders, and points parsing return `Result` where an explicit scalar is parsed. Branch to established defaults/inheritance only when `attr_get` returns `None`. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

**When to use:** Root width/height/viewBox, geometry attributes, `points`, opacity/stroke scalar attributes, dash lists, and supported functional-colour components. [CITED: docs/policies/svg-numeric-admission.md]

**Example:**

```moonbit
// Source: modules/mb-svg/svg/scene.mbt has the current attr_get/default split.
fn checked_attr_double(
  attrs : Array[(String, String)], name : String, default : Double,
) -> Result[Double, @error.CoreError] {
  match attr_get(attrs, name) {
    None => Ok(default)       // omission only
    Some(text) => parse_length(text) // explicit failure propagates
  }
}
```

Do not keep the current `Err(_) => default`, `Err(_) => parent`, or `Err(_) => []` branches for explicit numeric input. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

### Pattern 3: Parser-side preflight for every lowering derivation

**What:** Before `parse_svg_with_budget` returns `Ok`, walk the completed internal scene without creating a `DrawingList`: compute/check the root viewBox affine, combine inherited root/group affines, apply them to shape/path coordinates and controls, and check the generated rounded-rect/circle/ellipse path scalars. [CITED: docs/policies/svg-numeric-admission.md] [VERIFIED: codebase grep]

**When to use:** After a node's source inputs have been admitted and before exposing the final root scene. This preserves `lower_to_drawing_list(root) -> DrawingList` as a total API. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

**Example:**

```moonbit
// Source: modules/mb-svg/svg/lower.mbt and modules/mb-core/math/path.mbt.
fn admit_derived(value : Double) -> Result[Double, @error.CoreError] {
  if value.is_nan() || value.is_inf() || value.abs() > SVG_NUMERIC_LIMIT {
    Err(svg_numeric_error(@error.ErrorCode::InvalidRange, "svg-numeric-derived"))
  } else {
    Ok(value)
  }
}

// The real walker must inspect every affine coefficient and every PathCommand
// coordinate after applying the accumulated affine; it must not call lowering.
```

### Pattern 4: Normalize smooth commands before admission

**What:** Replace the permissive `read_number -> (Double, Int)` scanner with a `Result` scanner, consume exactly four scalar arguments for `S/s` and two for `T/t`, and only reflect the prior control after an eligible preceding curve command. Validate all smooth source arguments and every reflected/relative result. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

**When to use:** The `S/s/T/t` branches in `parse_path_data_with_budget`; this is the scoped prerequisite to adding them to the public admission guarantee. [CITED: docs/policies/svg-numeric-admission.md]

### Anti-Patterns to Avoid

- **Lowering-only validation:** Cannot fail `parse_svg` and violates the total-lowerer boundary. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]
- **Fallback on explicit parse failure:** `0.0`, inherited paint, an empty point array, or a default root field silently changes hostile input into a scene. [VERIFIED: codebase grep]
- **Determinant test as validity test:** Rejecting `scale(0)` violates the locked contract; only non-finite/out-of-envelope coefficients or results fail. [CITED: docs/policies/svg-numeric-admission.md]
- **Checking only input tokens:** Relative additions, trigonometric coefficients, affine compositions, viewBox mapping, and generated geometry can exceed the envelope despite finite admitted inputs. [CITED: docs/policies/svg-numeric-admission.md]
- **Treating an ignored `rgba`/`hsla` alpha as an ingress:** Phase 91 identifies only the first three consumed components; do not silently expand this phase's surface. [CITED: docs/policies/svg-numeric-admission.md]

## Exact Failure Flow and Implementation Anchors

| Route | Current unsafe behavior | Required Phase 92 change | Primary anchors |
|-------|-------------------------|--------------------------|-----------------|
| Length/list/viewBox | `parse_length` and `parse_token` forward raw text errors; `parse_viewbox` accepts four-or-more values. | Wrap lexical failure as source context, admit every parsed scalar, and require exact viewBox arity before `SvgRoot`. | `length.mbt:11-74`; `scene.mbt:650-682`. [VERIFIED: codebase grep] |
| Root dimensions/viewBox | `build_svg_root_attrs` turns explicit failures into `None`; lower then uses identity/default behavior. | Return `Result[SvgRoot, CoreError]`; only absent width/height/viewBox retain `None`. | `scene.mbt:650-682`; `lower.mbt:160-190`. [VERIFIED: codebase grep] |
| Shapes and points | `attr_double` falls back to a caller default; `points_from_attrs` converts an explicit failure to `[]`. | Convert numeric helpers and each shape builder to `Result`; keep defaults/empty points only for absent attributes. | `scene.mbt:891-1017`. [VERIFIED: codebase grep] |
| Paint scalars | `inherit_double` falls back to inherited value; dash-list failure inherits; `parse_double_or` supplies zero inside RGB/HSL parsing. | Propagate errors for explicit supported numeric paint components, dash entries, and scalar styles through `build_paint -> Result`. Preserve non-numeric colour compatibility outside the numeric scope. | `scene.mbt:726-858`; `color.mbt:90-144`. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md] |
| Transform source/derived | Transform accepts over-arity forms and returns unchecked affine construction, radians, trig output, and composition. | Enforce exact arity; admit sources, radians, six constructed/composed coefficients, and retain finite zero determinant. | `transform.mbt:16-146`; `transform_wbtest.mbt:11-21,162-202`. [VERIFIED: codebase grep] |
| Direct path routes | `read_number` changes a malformed/missing numeric token into `(0.0, index)`. | Return `Result` from scanner/command reads; admit every direct command scalar and each relative-derived coordinate/control/endpoint. | `path_data.mbt:15-337`. [VERIFIED: codebase grep] |
| Smooth path routes | `S/s` comments say four inputs yet code reads six; reflection uses stale controls across commands. | Normalize exact grammar and previous-command state, then admit sources/reflections/relative endpoints before `CanvasPath` mutation. | `path_data.mbt:218-292`. [VERIFIED: codebase grep] |
| Scene-to-lower derivations | `viewbox_transform`, `rect_path`, and ellipse sampling derive unchecked values after `parse_svg` has succeeded. | Add a parser-side validation walker reusing the pure calculations/path representation; do not change lowerer's return type or canvas layer policy. | `lower.mbt:38-190,201-330`; `math/path.mbt:195-205`. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Structured error ABI | A new SVG error enum/string convention | Existing `@error.CoreError::new` plus category/code/operation/context accessors | The project already provides the portable representation and policy fixes its stable numeric fields. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md] |
| Floating-point predicates | Target-specific FFI or string-based NaN/Infinity detection | `Double::is_nan`, `Double::is_inf`, and `abs()` | Existing all-target tests use these predicates successfully. [VERIFIED: codebase grep] [VERIFIED: target test run] |
| Transform/path math | A second affine/path implementation | Existing `@math.Affine2`, `CanvasPath`, and `Path2` command inspection | Lowering and parser already share these types; duplication risks divergent arithmetic. [VERIFIED: codebase grep] |
| Failure verification | Comparing `render_error` output | Typed `CoreError` accessors | Rendered prose is not a compatibility promise; accessors are. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md] |

**Key insight:** Fail-closed behavior is achieved by preserving `Result` through all source and derived seams, not by clamping values or adding a later canvas check. [CITED: docs/policies/svg-numeric-admission.md]

## Common Pitfalls

### Pitfall 1: Source errors leak the wrong public identity

**What goes wrong:** Directly returning `@text.parse_double` errors produces `text-parse-double`/`InvalidInput`, whereas Phase 91 requires an SVG `Data` error with `svg-numeric-source`. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

**How to avoid:** Add an SVG numeric error constructor in `svg.mbt` that uses `ErrorCategory::Data`, `operation="svg"`, and a caller-selected `InvalidEncoding` or `InvalidRange` code/context. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

### Pitfall 2: Correct `Result` type but a partial scene remains observable

**What goes wrong:** A builder can append children or mutate a `CanvasPath` before a later scalar fails. Although the temporary object is not returned, an implementation that lowers while parsing could expose partial work. [VERIFIED: codebase grep]

**How to avoid:** Finish all parser-side validation before the sole `Ok(node)` return from `parse_svg_with_budget`, and never call `lower_to_drawing_list` on an `Err` branch. The `Result` type then makes scene/list absence directly testable. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

### Pitfall 3: Exact arity is essential for transforms and smooth paths

**What goes wrong:** Current transform builders accept additional parameters and current `S/s` reads six values despite SVG smooth-cubic arity of four in its own comment. Extra or missing values can bypass intended numeric reads. [VERIFIED: codebase grep]

**How to avoid:** Require exact parameter counts at the parser boundary and add malformed/missing/extra argument cases before adding smooth routes to the public contract. [CITED: docs/policies/svg-numeric-admission.md]

### Pitfall 4: Valid boundary inputs can generate unsafe values

**What goes wrong:** `scale(65536)` and `x="65536"` are individually admitted but their transformed coordinate is `4294967296`; analogous hazards occur in viewBox mapping, affine composition, rectangle arithmetic, and ellipse sampling. [CITED: docs/policies/svg-numeric-admission.md]

**How to avoid:** Validate every resulting affine coefficient and generated/transformed path scalar in a parser-side preflight walker. [CITED: docs/policies/svg-numeric-admission.md]

### Pitfall 5: Accidentally change opacity/layer semantics

**What goes wrong:** Adding an opacity-specific `[0,1]` admission rule or moving checks into canvas would redefine the separate RFC 0008 layer contract. [CITED: docs/policies/svg-numeric-admission.md] [CITED: docs/rfcs/0008-mb-canvas-layer.md]

**How to avoid:** Apply only the numeric envelope to SVG source/derived values, preserve existing lower-layer PushLayer/PopLayer output, and leave the 16-depth capability behavior untouched. [CITED: docs/policies/svg-numeric-admission.md]

## Code Examples

### Stable structured numeric error

```moonbit
// Source: modules/mb-svg/svg/svg.mbt and modules/mb-core/error/core_error.mbt.
fn svg_numeric_error(
  code : @error.ErrorCode,
  context : String,
) -> @error.CoreError {
  @error.CoreError::new(
    @error.ErrorCategory::Data,
    code,
    operation="svg",
    context=context,
  )
}
```

Use `InvalidEncoding` for source/non-finite contexts and `InvalidRange` for range/derived contexts. [CITED: docs/policies/svg-numeric-admission.md]

### Four-field public assertion

```moonbit
// Source: modules/mb-core/error/core_error.mbt accessors.
fn is_numeric_error(e : @error.CoreError, code : @error.ErrorCode, context : String) -> Bool {
  e.category() == @error.ErrorCategory::Data &&
    e.code() == code &&
    e.operation() == Some("svg") &&
    e.context() == Some(context)
}
```

Use this in a black-box `svg_test.mbt` helper and focused white-box tests; do not assert diagnostics beyond the context field. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Lenient scalar fallback (`Err -> default`, parent, empty list, or zero) | Result-propagating numeric admission and parser-side derived preflight | Phase 92 | Explicit unsafe inputs no longer produce a usable scene. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md] |
| Smooth-path approximation with ambiguous reads | Exact smooth-command normalization before public admission support | Phase 92 | `S/s/T/t` can enter the documented contract without preserving malformed behavior. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md] |

**Deprecated/outdated:** Treating `lower_to_drawing_list` as an error boundary is incompatible with its current total `SceneNode -> DrawingList` API and Phase 91 ownership rule. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

## Assumptions Log

All findings were verified against the current repository, Phase 91 policy/verification, or the current all-target test run; no implementation-affecting assumptions remain. [VERIFIED: codebase grep] [VERIFIED: target test run]

## Open Questions (RESOLVED)

1. **Public black-box suite:** Adopted for Phase 92. Add and extend `svg_test.mbt` as the compact public error-contract suite for `parse_svg`, while retaining route-local `*_wbtest.mbt` coverage for scanner, affine, and generated-path details. This meets the AGENTS.md black-box-test requirement for the public package. [VERIFIED: AGENTS.md] [VERIFIED: codebase grep]

2. **Safety enforcement boundary:** Adopted at the parser-produced `SceneNode` boundary. `parse_svg` must reject unsafe explicit and derived values before returning a scene; `lower_to_drawing_list` remains the total consumer of a successful parser result. Manually constructed public `SceneNode` values are outside Phase 92 numeric admission, so no fallible lowerer or public wrapper is added. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` toolchain | Compile and four-target package test | ✓ | `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf`, `moonrun 0.1.20260713` | — [VERIFIED: target test run] |
| Workspace modules (`mb-core`, `mb-canvas`, `mb-svg`) | Existing implementation and tests | ✓ | workspace `0.1.0` modules | — [VERIFIED: codebase grep] |

**Missing dependencies with no fallback:** None. [VERIFIED: target test run]

**Missing dependencies with fallback:** None. [VERIFIED: target test run]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No identity/session surface is in this parser phase. [VERIFIED: codebase grep] |
| V3 Session Management | no | No session surface is in this parser phase. [VERIFIED: codebase grep] |
| V4 Access Control | no | No authorization surface is in this parser phase. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Central source/derived numeric admission before a scene; typed `CoreError` on rejection. [CITED: docs/policies/svg-numeric-admission.md] |
| V6 Cryptography | no | No cryptographic operation is introduced. [VERIFIED: codebase grep] |

### Known Threat Patterns for MoonBit SVG parsing

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Numeric coercion changes hostile input into zero/default/empty geometry | Tampering | Propagate `Result` for explicit attributes and reject before `Ok(SceneNode)`. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md] |
| Finite source values overflow during affine/viewBox/geometry arithmetic | Tampering / Denial of service | Admit every derived scalar and return `svg-numeric-derived` before lowering. [CITED: docs/policies/svg-numeric-admission.md] |
| Path scanner consumes malformed or wrong-arity input inconsistently | Tampering | Result-returning scanner plus exact command arity and smooth normalization. [VERIFIED: codebase grep] |
| Deep/large SVG input consumes excessive work | Denial of service | Preserve existing `Budget` token/work/depth checks; numeric work must not bypass them. [VERIFIED: codebase grep] [CITED: docs/rfcs/0002-mb-svg.md] |

## Sources

### Primary (HIGH confidence)

- `docs/policies/svg-numeric-admission.md` — locked envelope, four stable error contexts, route matrix, and ownership boundary. [CITED: docs/policies/svg-numeric-admission.md]
- `modules/mb-svg/svg/{scene,length,transform,path_data,color,lower,svg}.mbt` — current failure flow, public symbols, and exact implementation seams. [VERIFIED: codebase grep]
- `modules/mb-core/error/core_error.mbt` and `modules/mb-core/math/{affine,path}.mbt` — portable error/accessor and geometry primitives. [VERIFIED: codebase grep]
- `.planning/phases/91-svg-numeric-contract/91-VERIFICATION.md` — Phase 91 baseline and explicit Phase 92 deferrals. [VERIFIED: codebase grep]
- `moon test modules/mb-svg/svg --target all --frozen` — 91/91 passing on wasm, wasm-gc, js, and native during this research. [VERIFIED: target test run]

### Secondary (MEDIUM confidence)

- No external documentation was required: current project policy and source are authoritative for this phase. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)

- None. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — existing workspace dependencies and installed toolchain were inspected and exercised. [VERIFIED: codebase grep] [VERIFIED: target test run]
- Architecture: HIGH — every parser-to-scene-to-lower seam and documented Phase 91 route was inspected. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]
- Pitfalls: HIGH — each listed issue is present in current source or specified by the locked policy. [VERIFIED: codebase grep] [CITED: docs/policies/svg-numeric-admission.md]

**Research date:** 2026-07-26
**Valid until:** 2026-08-25; re-check immediately if Phase 92 source or the numeric policy changes. [VERIFIED: codebase grep]
