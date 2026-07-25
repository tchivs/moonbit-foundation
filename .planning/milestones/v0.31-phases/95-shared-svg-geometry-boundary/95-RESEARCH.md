# Phase 95: Shared SVG Geometry Boundary - Research

**Researched:** 2026-07-26  
**Domain:** Internal MoonBit SVG geometry/admission refactor  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Shared-geometry ownership
- **D-01:** Establish one package-private checked geometry seam as the authority for viewBox mapping, affine/point derivation, and supported shape/path construction facts. Parser preflight and lowering must consume that seam rather than maintain parallel arithmetic. — **Reversibility:** costly — reintroducing local geometry formulas would recreate the drift class that this milestone removes.
- **D-02:** Keep `parse_svg` as the public fail-closed publication boundary and preserve `lower_to_drawing_list` as the established total public consumer. The internal seam may expose checked facts, but Phase 95 must not add a public `Result` API or change behavior for valid scenes. — **Reversibility:** costly — public parser timing and lowerer totality are compatibility contracts already qualified across four targets.

### Numeric and rendering compatibility
- **D-03:** Preserve the v0.30 `[-65536.0, 65536.0]` finite envelope, existing structured source/derived error categories, omitted-attribute defaults, and acceptance of finite singular transforms such as `scale(0)`. — **Reversibility:** costly — these are externally observable parsing contracts.
- **D-04:** Preserve RFC 0008 group/element opacity ordering and the 16-layer capability boundary exactly; the shared geometry refactor must not alter layer operations, paint opacity, or raster semantics. — **Reversibility:** costly — changing these would break the existing SVG/canvas rendering contract.

### the agent's Discretion

Choose internal type/function names, factor boundaries, and test-file placement from existing `mb-svg` patterns. The planner may split mechanical extraction from compatibility proof, provided both parser preflight and lowering consume the same seam by phase completion.

### Deferred Ideas (OUT OF SCOPE)

None — new SVG elements, CSS/XML expansion, native acceleration, a second rasterizer, benchmark thresholds, and layer-policy changes remain outside this phase.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Keep core algorithms and shared data models in MoonBit; Phase 95 must remain a MoonBit-only package-local extraction. [VERIFIED: AGENTS.md]
- Native is the primary target, but portable targets are supported deliberately through capability boundaries and conformance tests; retain the existing four-target gate. [VERIFIED: AGENTS.md; modules/mb-svg/moon.mod.json]
- Keep dependencies modular and acyclic; do not introduce a new module edge or make consumers import a whole ecosystem for this private seam. [VERIFIED: AGENTS.md]
- Preserve public API/compatibility discipline: no silent public API or semantic redefinition is authorized by an internal refactor. [VERIFIED: AGENTS.md; 95-CONTEXT.md]
- Preserve deterministic, GUI-independent behavior; use deterministic CLI tests and semantic operation/pixel assertions. [VERIFIED: AGENTS.md; 95-CONTEXT.md]
- Do not make unsupported performance claims; this phase has no benchmark threshold or timing-comparison deliverable. [VERIFIED: AGENTS.md; 95-CONTEXT.md]
- Do not add FFI or alter FFI ownership; the scoped package already implements this path in portable MoonBit. [VERIFIED: AGENTS.md; modules/mb-svg/svg/moon.pkg]
- The project requests codebase-memory graph discovery before grep; its MCP tools are not exposed to this delegated runtime, so code inspection used the permitted fallback for source and non-code configuration discovery. [VERIFIED: AGENTS.md; runtime tool availability]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| SVGUNI-01 | Library consumers receive unchanged valid SVG scene and drawing-list behavior while parser preflight and lowering obtain transform, viewBox, shape, and path geometry facts from one checked internal implementation. | Extract the duplicated checked viewBox, affine, shape construction, and transformed-point routes into one private `Result`-returning geometry module; keep public entry points intact and prove its facts plus parse-to-lower compatibility with existing fixtures. [VERIFIED: codebase inspection] |
</phase_requirements>

## Summary

Phase 95 is a package-local consolidation, not a feature or numeric-policy change. `parse_svg_with_budget` constructs a `SceneNode`, runs `preflight_scene`, and publishes only on `Ok`; the current preflight recomputes the root viewBox transform, accumulated affine, rounded-rectangle intermediates, ellipse samples, and transformed path points. `lower_to_drawing_list` is intentionally total and independently recomputes the root viewBox transform and all supported primitive paths. That duplication is the technical debt recorded by the v0.30 milestone audit. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt; .planning/milestones/v0.30-MILESTONE-AUDIT.md]

**Primary recommendation:** Add one package-private `geometry.mbt` checked-facts module; make preflight propagate its `Result`s and make the total lowerer consume the same results through deterministic non-throwing adapters, while leaving parser error publication, valid drawing-list operations, and opacity/layer handling exactly where they are. [VERIFIED: 95-CONTEXT.md; modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt]

No external package, FFI, configuration migration, or public API is needed. The existing `mb-svg/svg` package is already portable across `js`, `wasm`, `wasm-gc`, and `native`, and the installed Moon tool exposes those targets plus `all`. [VERIFIED: modules/mb-svg/moon.mod.json; modules/mb-svg/svg/moon.pkg; local CLI]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Checked viewBox mapping and affine composition | SVG package / domain logic | Parser boundary | These are portable SVG geometry facts; parser preflight needs the error-bearing form before scene publication. [VERIFIED: modules/mb-svg/svg/scene.mbt; docs/policies/svg-numeric-admission.md] |
| Primitive/path construction and transformed-point admission | SVG package / domain logic | Parser boundary | Rect, circle, ellipse, line, polygon/polyline, and `Path2` geometry are created and checked in `mb-svg`; canvas should receive an already validated scene. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt; docs/policies/svg-numeric-admission.md] |
| Scene publication and structured parser errors | Public parser API | SVG geometry seam | `parse_svg` remains the only public `Result` publication boundary; its structured numeric contexts must remain unchanged. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/svg.mbt; docs/policies/svg-numeric-admission.md] |
| Drawing-list emission | SVG lowerer | Shared geometry seam | The lowerer owns DrawOp order, fill/stroke style creation, transform/layer pushes and pops; it should request geometry facts rather than recalculate them. [VERIFIED: modules/mb-svg/svg/lower.mbt] |
| Opacity compositing and layer-depth enforcement | Canvas renderer | SVG lowerer | SVG emits balanced `PushLayer`/`PopLayer`; canvas owns isolated compositing and the 16-layer capacity result. [VERIFIED: modules/mb-svg/svg/lower.mbt; modules/mb-svg/svg/portable_qualification_wbtest.mbt; docs/rfcs/0008-mb-canvas-layer.md] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| Existing `tchivs/mb-svg/svg` MoonBit package | repository HEAD | Hosts the parser, scene model, lowerer, and package-private tests. | The phase is an internal refactor of the package that already declares all four production targets. [VERIFIED: modules/mb-svg/svg/moon.pkg; modules/mb-svg/moon.mod.json] |
| MoonBit `moon` | `0.1.20260713` | Run focused and all-target SVG tests. | The local CLI lists `wasm`, `wasm-gc`, `js`, `native`, and `all` for `moon test --target`. [VERIFIED: local CLI] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---|---:|---|---|
| Existing `mb-core/math::Affine2`, `Point2`, and `Path2` | repository dependency | Carry affine and path facts consumed by parser and canvas lowering. | Reuse from the current SVG scene/lower implementation; do not introduce another geometry representation. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt; modules/mb-svg/svg/moon.pkg] |
| Existing `mb-core/error::CoreError` | repository dependency | Preserve `svg-numeric-derived` error output from checked calculations. | Use for the internal checked seam returned to parser preflight only. [VERIFIED: modules/mb-svg/svg/svg.mbt; modules/mb-svg/svg/transform.mbt] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| One private checked geometry module | Keep mirrored parser/lowerer arithmetic plus comments/tests | Rejected: the v0.30 audit identifies the mirrored arithmetic as the drift risk this phase exists to remove. [VERIFIED: .planning/milestones/v0.30-MILESTONE-AUDIT.md] |
| Private `Result` geometry facts | Add a public checked lowering API | Rejected by D-02: changes the public surface and undermines the established total lowerer. [VERIFIED: 95-CONTEXT.md] |
| Private `Result` geometry facts | Move validation into canvas | Rejected: numeric admission belongs before `SceneNode` publication; canvas owns layers/compositing rather than SVG admission. [VERIFIED: docs/policies/svg-numeric-admission.md] |

**Installation:** None — Phase 95 must not install packages. [VERIFIED: 95-CONTEXT.md; modules/mb-svg/svg/moon.pkg]

## Architecture Patterns

### System Architecture Diagram

```text
SVG source
    |
    v
parse_svg / parse_svg_with_budget
    | builds SceneNode, then asks checked geometry seam for:
    | viewBox transform, affine composition, primitive/path facts,
    | and transformed-point admission
    +---- Err(CoreError) --> public parser Err; no SceneNode published
    |
    +---- Ok -----------> SceneNode
                              |
                              v
                    lower_to_drawing_list (total)
                              | asks the same checked geometry seam
                              | for valid viewBox/path/affine facts
                              v
                   DrawingList: transforms + Fill/Stroke
                              |
                   opacity only: PushLayer/PopLayer
                              v
                        mb-canvas render (16-layer boundary)
```

The seam must expose domain facts, not DrawOps. In particular, keep `emit_shape`, `make_fill_style`, opacity checks, and `push_layer` / `pop_layer` in `lower.mbt`; move only the geometry formulas and their checked arithmetic. [VERIFIED: modules/mb-svg/svg/lower.mbt; docs/rfcs/0008-mb-canvas-layer.md]

### Recommended Project Structure

```text
modules/mb-svg/svg/
├── geometry.mbt                     # new private checked geometry facts
├── scene.mbt                        # parse/publication boundary + preflight traversal
├── lower.mbt                        # total DrawOp/layer emission using geometry facts
├── geometry_wbtest.mbt              # new focused white-box fact controls (recommended)
├── lower_wbtest.mbt                 # operation-order and valid-path compatibility controls
├── conformance_wbtest.mbt           # compact valid parse-to-lower fixture matrix
├── numeric_contract_wbtest.mbt      # finite envelope and scale(0) control
└── portable_qualification_wbtest.mbt # four-target raster/layer semantic controls
```

`geometry_wbtest.mbt` is the preferred location for direct private-seam controls because the package already separates internal `*_wbtest.mbt` representation tests from public `*_test.mbt` API tests. It is a recommendation, not a required filename. [VERIFIED: modules/mb-svg/svg/conformance_wbtest.mbt; modules/mb-svg/svg/svg_test.mbt; 95-CONTEXT.md]

### Pattern 1: Checked-facts core with parser and total-lowerer adapters

**What:** Define package-private `checked_*` functions which return `Result[Fact, @error.CoreError]` and are the sole owners of the arithmetic currently duplicated between `scene.mbt` and `lower.mbt`. Suitable fact operations are:

- `checked_viewbox_transform(root) -> Result[Affine2, CoreError]`
- `checked_compose_affine(current, next) -> Result[Affine2, CoreError]`
- `checked_path_for_shape(...) -> Result[Path2, CoreError]` for rect, circle, ellipse, line, polyline, polygon, and `CanvasPath.to_path2()` validation
- `checked_path_points(path, accumulated_affine) -> Result[Unit, CoreError]` and a checked affine-point helper for preflight. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt]

**When to use:** Every calculation which would otherwise be both (a) performed during parser preflight to decide publication and (b) performed later to create a path or root mapping. Keep lexical/source admission in `length.mbt`, `transform.mbt`, and `path_data.mbt`; Phase 95 is not a rewrite of those parsers. [VERIFIED: modules/mb-svg/svg/length.mbt; modules/mb-svg/svg/transform.mbt; modules/mb-svg/svg/path_data.mbt; docs/policies/svg-numeric-admission.md]

**Implementation shape:**

```moonbit
// geometry.mbt -- package-private; illustrative names only.
fn checked_viewbox_transform(root : SvgRoot)
  -> Result[@math.Affine2, @error.CoreError] {
  // Preserve existing identity cases, preserveAspectRatio branch selection,
  // and admit_derived after every division/product/sum before returning.
}

fn checked_rect_path(x : Double, y : Double, w : Double, h : Double,
                     rx : Double, ry : Double)
  -> Result[@math.Path2, @error.CoreError] {
  // Preserve the current sharp/rounded rect construction and kappa constant;
  // return an error rather than duplicate a preflight-only calculation.
}

// scene.mbt
let path = checked_rect_path(x, y, w, h, rx, ry)?
checked_path_points(path, accumulated_affine)?

// lower.mbt: never expose Result publicly and never unwrap/panic.
// For parser-produced valid scenes this is always Ok; retain a deterministic
// total fallback for manually constructed invalid public SceneNode values.
let path = total_path_or_empty(checked_rect_path(x, y, w, h, rx, ry))
emit_shape(paint, path, list)
```

The exact fallback name/representation is discretionary, but it must be explicit, deterministic, and non-panicking. For a checked root transform, identity is the compatible total fallback; for a failed primitive path, an empty `Path2` preserves the lowerer’s return type and lets existing paint/layer ordering remain owned by `emit_shape`. This fallback is only for manually constructed invalid `SceneNode` values; `parse_svg` must still return the original structured error before it can publish a scene. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt; .planning/milestones/v0.30-MILESTONE-AUDIT.md; 95-CONTEXT.md]

### Pattern 2: Preserve valid operation order as the compatibility oracle

**What:** Test valid fixtures through `parse_svg` then `lower_to_drawing_list`, asserting semantic operation forms and selected affine/path values, rather than snapshots or source-text searches. [VERIFIED: 95-CONTEXT.md; modules/mb-svg/svg/lower_wbtest.mbt; modules/mb-svg/svg/conformance_wbtest.mbt]

**When to use:** After extraction of the viewBox and primitive paths. The current suite directly checks meet/slice/none mapping, rounded-rect command shape, circle sample count, group and element layer nesting, and small semantic raster outputs. [VERIFIED: modules/mb-svg/svg/lower_wbtest.mbt; modules/mb-svg/svg/portable_qualification_wbtest.mbt]

### Anti-Patterns to Avoid

- **A second “preflight version” of a geometry formula:** Do not leave a calculation in `scene.mbt` merely to validate the later geometry result. Preflight should call the shared checked fact and inspect/transform its resulting points. [VERIFIED: .planning/milestones/v0.30-MILESTONE-AUDIT.md; 95-CONTEXT.md]
- **Unchecked lowerer extraction:** Do not move the old lowerer formula verbatim into a helper returning bare `Affine2` or `Path2`; the shared authority must retain derived-value admission and structured `svg-numeric-derived` errors for preflight. [VERIFIED: docs/policies/svg-numeric-admission.md; modules/mb-svg/svg/transform.mbt]
- **`unwrap`, panic, or a public `Result` lowerer:** `parse_svg` is the error boundary and `lower_to_drawing_list` is intentionally total. [VERIFIED: 95-CONTEXT.md; .planning/milestones/v0.30-phases/92-fail-closed-svg-parsing/92-CONTEXT.md]
- **Moving opacity/layers into geometry:** Geometry must not change `PushLayer`/`PopLayer`, per-paint alpha, or the 16-layer renderer boundary. [VERIFIED: 95-CONTEXT.md; modules/mb-svg/svg/lower.mbt; modules/mb-svg/svg/portable_qualification_wbtest.mbt]
- **Source-text duplication checks:** They cannot prove behavior and are explicitly excluded by D-05; direct private seam tests plus public semantic operation tests are required. [VERIFIED: 95-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Numeric derivation policy | A new limit/error family inside the new module | Existing `admit_derived` / `svg_numeric_error` path | It already emits the contract’s `svg-numeric-derived` `CoreError` under the inclusive 65536 envelope. [VERIFIED: modules/mb-svg/svg/transform.mbt; modules/mb-svg/svg/svg.mbt; docs/policies/svg-numeric-admission.md] |
| Affine math representation | A custom matrix/point type | Existing `@math.Affine2` and `@math.Point2` | Existing scene, lowering, transform parsing, and canvas operations already exchange these types. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt; modules/mb-svg/svg/transform.mbt] |
| SVG path representation | A parallel shape command model | Existing `@math.Path2` / `@canvas.CanvasPath.to_path2()` | This retains all existing lowering and `PathCommand` checks. [VERIFIED: modules/mb-svg/svg/lower.mbt; modules/mb-svg/svg/scene.mbt] |
| Opacity compositor | Custom alpha multiplication or geometry-stage layers | Existing canvas `PushLayer` / `PopLayer` emission and renderer | Isolated group opacity requires a layer; multiplying child alpha is explicitly rejected by RFC 0008. [VERIFIED: docs/rfcs/0008-mb-canvas-layer.md; modules/mb-svg/svg/lower.mbt] |

**Key insight:** the seam should consolidate *checked facts* and reuse existing numeric/error and canvas abstractions; it should not become a second parser, a renderer, or a new public API. [VERIFIED: 95-CONTEXT.md; docs/policies/svg-numeric-admission.md]

## Exact Likely Files and Change Boundaries

| File | Planned Role | Change Type |
|---|---|---|
| `modules/mb-svg/svg/geometry.mbt` | New package-private authority for checked viewBox transform, affine composition/point application, and shape/path construction. | Add. [VERIFIED: codebase inspection; 95-CONTEXT.md] |
| `modules/mb-svg/svg/scene.mbt` | Retain traversal and publication boundary; replace local preflight math and local primitive calls with shared checked facts. | Modify. [VERIFIED: modules/mb-svg/svg/scene.mbt] |
| `modules/mb-svg/svg/lower.mbt` | Retain DrawOp/style/layer emission; replace `viewbox_transform` and primitive builders with the shared facts through total adapters. | Modify. [VERIFIED: modules/mb-svg/svg/lower.mbt] |
| `modules/mb-svg/svg/geometry_wbtest.mbt` | Directly validate shared seam facts and error propagation without production-source searches. | Add, recommended. [VERIFIED: 95-CONTEXT.md; modules/mb-svg/svg/conformance_wbtest.mbt] |
| `modules/mb-svg/svg/lower_wbtest.mbt` | Retain/extend exact valid viewBox, rounded-rect, ellipse, and layer operation assertions. | Modify only if focused regressions need local coverage. [VERIFIED: modules/mb-svg/svg/lower_wbtest.mbt] |
| `modules/mb-svg/svg/conformance_wbtest.mbt` | Retain compact valid transform/viewBox/shape/path matrix as end-to-end compatibility coverage. | Normally unchanged; extend only if a missing geometry family is not otherwise covered. [VERIFIED: modules/mb-svg/svg/conformance_wbtest.mbt] |
| `modules/mb-svg/svg/numeric_contract_wbtest.mbt` and `svg_test.mbt` | Preserve finite `scale(0)` and public no-scene structured-error timing. | Normally unchanged; use as regression gate, not as a new policy design site. [VERIFIED: modules/mb-svg/svg/numeric_contract_wbtest.mbt; modules/mb-svg/svg/svg_test.mbt] |
| `modules/mb-svg/svg/portable_qualification_wbtest.mbt` | Preserve semantic opacity/raster and 16/17-layer behavior on all targets. | Normally unchanged; use as regression gate. [VERIFIED: modules/mb-svg/svg/portable_qualification_wbtest.mbt] |

Do not modify public `SceneNode`, `SvgRoot`, `Paint`, `parse_svg`, or `lower_to_drawing_list` signatures. Do not modify `moon.pkg` or `moon.mod.json`: the package already has the needed portable dependencies and target declaration. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt; modules/mb-svg/svg/moon.pkg; modules/mb-svg/moon.mod.json]

## Runtime State Inventory

| Category | Items Found | Action Required |
|---|---|---|
| Stored data | None — this is a code-only extraction with no renamed identifier, schema, fixture format, or persisted SVG state. Repository inspection found SVG source and fixture documentation, not a datastore owned by this package. [VERIFIED: phase scope; codebase inspection] | None — code edit only. |
| Live service config | None — `mb-svg` is a portable library and Phase 95 changes no deployment/service name, external UI configuration, or runtime endpoint. [VERIFIED: modules/mb-svg/README.mbt.md; 95-CONTEXT.md] | None. |
| OS-registered state | None — no executable, service, task, or registered package name is renamed or reinstalled by this internal module refactor. [VERIFIED: phase scope; codebase inspection] | None. |
| Secrets/env vars | None — the scoped implementation reads SVG input and package dependencies, not environment-provided credentials or renamed secret keys. [VERIFIED: modules/mb-svg/svg/moon.pkg; phase scope] | None. |
| Build artifacts / installed packages | None requiring migration — a normal MoonBit rebuild regenerates local outputs, and Phase 95 neither renames the module/package nor adds an installed dependency. [VERIFIED: modules/mb-svg/moon.mod.json; local CLI; 95-CONTEXT.md] | Rebuild/test normally; no data migration. |

## Common Pitfalls

### Pitfall 1: Sharing only the path builder, while retaining duplicate validation arithmetic

**What goes wrong:** The parser and lowerer use the same `rect_path` or `ellipse_path`, but still have separate viewBox, affine composition, and transformed-point math; later changes can again disagree about admission. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt]

**How to avoid:** Move checked viewBox mapping, affine composition, component/point application, and shape construction together. Let preflight use the facts for admission and lowering use them for emission. [VERIFIED: 95-CONTEXT.md; docs/policies/svg-numeric-admission.md]

### Pitfall 2: Breaking total lowering with `Result` propagation

**What goes wrong:** Changing `lower_to_drawing_list` to return `Result`, calling `unwrap`, or panicking on an error violates the public compatibility decision and affects manually constructed public `SceneNode` values. [VERIFIED: 95-CONTEXT.md; .planning/milestones/v0.30-MILESTONE-AUDIT.md]

**How to avoid:** Keep the checked seam private and make lowerer adapters total. Parser-produced scenes must take `Ok`; the adapter must have explicit deterministic recovery for invalid manually constructed scenes. [VERIFIED: modules/mb-svg/svg/scene.mbt; 95-CONTEXT.md]

### Pitfall 3: Treating a zero determinant as an error

**What goes wrong:** An affine helper may accidentally require invertibility and reject `scale(0)`. [VERIFIED: docs/policies/svg-numeric-admission.md]

**How to avoid:** Admit finite affine components only; do not add a determinant/inverse check. Keep the existing public and package-local `scale(0)` parse-to-lower tests green. [VERIFIED: modules/mb-svg/svg/transform_wbtest.mbt; modules/mb-svg/svg/numeric_contract_wbtest.mbt; modules/mb-svg/svg/svg_test.mbt]

### Pitfall 4: Reordering opacity/layer operations during geometry extraction

**What goes wrong:** Moving `emit_shape` or group lowering around the new seam can alter `PushTransform`, `PushLayer`, fill/stroke, `PopLayer`, `PopTransform` ordering or change the 16/17-layer behavior. [VERIFIED: modules/mb-svg/svg/lower.mbt; modules/mb-svg/svg/lower_wbtest.mbt; modules/mb-svg/svg/portable_qualification_wbtest.mbt]

**How to avoid:** Limit `geometry.mbt` to facts; leave the exact layer branches and style construction in `lower.mbt`, with operation and semantic raster regressions run unchanged. [VERIFIED: 95-CONTEXT.md; docs/rfcs/0008-mb-canvas-layer.md]

### Pitfall 5: Altering valid geometry under an ostensibly mechanical extraction

**What goes wrong:** Replacing the rounded-rect clamp/ratio order, the cubic kappa literal, 32 ellipse samples, or preserveAspectRatio branch ordering changes a valid path or transform. [VERIFIED: modules/mb-svg/svg/lower.mbt; modules/mb-svg/svg/lower_wbtest.mbt]

**How to avoid:** Move calculations mechanically first, preserving constants and branch order, then assert existing visible path command counts/coordinates and viewBox affine components. [VERIFIED: modules/mb-svg/svg/lower_wbtest.mbt; modules/mb-svg/svg/conformance_wbtest.mbt]

## Test Strategy

1. **Focused private seam controls:** Add direct `geometry_wbtest.mbt` tests for all geometry families: root viewBox (`meet`, `slice`, `none`, missing/non-positive identity), affine composition and point derivation, sharp/rounded rect, 32-sample circle/ellipse, line, polyline/polygon, and `Path2` command traversal. Include a finite singular affine and derived-overflow `Err` where a helper produces an error. This verifies the actual shared authority without inspecting production text. [VERIFIED: 95-CONTEXT.md; modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt]
2. **Parser timing/error regression:** Retain the public `svg_test.mbt` checks that inspect `Data`, `InvalidEncoding`/`InvalidRange`, operation `svg`, and `svg-numeric-*` context while proving `Err` means no scene reaches lowering. This phase must preserve these facts even though expanded unsafe-parity qualification belongs to Phase 96. [VERIFIED: modules/mb-svg/svg/svg_test.mbt; .planning/REQUIREMENTS.md]
3. **Valid parse-to-lower compatibility:** Run the existing conformance matrix and focused `lower_wbtest` assertions for transforms, viewBox variants, each primitive/path, rounded rectangle, and circle samples. Add a compact mixed fixture only if it is needed to cover a geometry family absent from direct seam controls. [VERIFIED: modules/mb-svg/svg/conformance_wbtest.mbt; modules/mb-svg/svg/lower_wbtest.mbt]
4. **Compatibility sentinels:** Retain `numeric_contract_wbtest` and public `scale(0)` lowering; retain nested group/element opacity operation/pixel tests plus the existing 16-success/17-atomic-failure layer tests. [VERIFIED: modules/mb-svg/svg/numeric_contract_wbtest.mbt; modules/mb-svg/svg/svg_test.mbt; modules/mb-svg/svg/portable_qualification_wbtest.mbt]
5. **Portable final gate:** Use the ordinary frozen SVG package suite rather than target-specific snapshots or timing comparisons. [VERIFIED: 95-CONTEXT.md; modules/mb-svg/moon.mod.json; local CLI]

**Focused command:**

```powershell
moon test modules/mb-svg/svg --target native --frozen -f '*geometry*'
```

**Full phase gate (all four targets):**

```powershell
moon test modules/mb-svg/svg --target all --frozen
```

The full command is established project precedent and the local CLI confirms that `all` expands across `wasm`, `wasm-gc`, `js`, and `native`. [VERIFIED: .planning/milestones/v0.30-phases/94-svg-benchmark-evidence/94-01-SUMMARY.md; local CLI]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Parser-side preflight mirrors lowerer geometry arithmetic. | One private checked geometry authority feeds both parser preflight and lowerer. | Phase 95 (planned). [VERIFIED: .planning/milestones/v0.30-MILESTONE-AUDIT.md; 95-CONTEXT.md] | Removes the known change-drift class without changing public API or valid output. [VERIFIED: 95-CONTEXT.md] |

**Deprecated/outdated:** Maintaining paired geometry formulas in `scene.mbt` and `lower.mbt` is the explicitly recorded v0.30 maintenance debt; do not retain it after the extraction. [VERIFIED: .planning/milestones/v0.30-MILESTONE-AUDIT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | A newly added private test file will be named `geometry_wbtest.mbt`. The filename is only a recommendation; the existing package test convention supports such placement. [ASSUMED] | Recommended Project Structure / Test Strategy | Low — planner can place focused tests in `lower_wbtest.mbt` instead. |
| A2 | The total-lowerer fallback may use identity for failed root affine facts and empty paths for failed shape facts. This preserves return totality and valid parser-produced behavior, but behavior for manually constructed invalid scenes is not specified by the locked decisions. [ASSUMED] | Pattern 1 | Medium — implementation must choose and test a deterministic fallback without altering valid output or adding an error API. |

## Open Questions (RESOLVED)

1. **Which deterministic fallback should the total lowerer use for a manually constructed invalid `SceneNode`?**
   - What we know: parser-produced scenes fail before publication; the public lowerer remains total for manually constructed scene values. [VERIFIED: modules/mb-svg/svg/scene.mbt; .planning/milestones/v0.30-MILESTONE-AUDIT.md]
   - What's unclear: existing invalid manually constructed geometry output is not documented as a compatibility oracle. [VERIFIED: codebase inspection]
   - **RESOLVED:** Use an internal non-panicking identity fallback for failed root facts and an empty `Path2` fallback for failed primitive/path facts. Apply it only to manually constructed invalid `SceneNode` values, keep paint/layer sequencing in `emit_shape`, test it privately, and do not add a public policy promise. Valid parser-produced scenes continue to consume successful checked facts unchanged. [DECIDED: 95-01/95-02 plan]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| MoonBit `moon` CLI | Compile and run SVG tests | ✓ | `0.1.20260713` | — [VERIFIED: local CLI] |
| `mb-svg/svg` four-target declaration | Portable phase gate | ✓ | `+js+wasm+wasm-gc+native` | — [VERIFIED: modules/mb-svg/moon.mod.json; modules/mb-svg/svg/moon.pkg] |

**Missing dependencies with no fallback:** None. [VERIFIED: local CLI; modules/mb-svg/moon.mod.json]

**Missing dependencies with fallback:** None. [VERIFIED: local CLI; modules/mb-svg/moon.mod.json]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | Library has no identity/authentication route in this phase. [VERIFIED: phase scope; modules/mb-svg/svg/moon.pkg] |
| V3 Session Management | No | Library has no session state in this phase. [VERIFIED: phase scope; modules/mb-svg/svg/moon.pkg] |
| V4 Access Control | No | No authorization boundary is introduced. [VERIFIED: phase scope] |
| V5 Input Validation | Yes | Keep source and derived numeric admission before `SceneNode` publication and preserve stable structured errors. [VERIFIED: docs/policies/svg-numeric-admission.md; modules/mb-svg/svg/scene.mbt] |
| V6 Cryptography | No | No cryptographic operation or secret is in scope. [VERIFIED: phase scope] |

### Known Threat Patterns for the SVG geometry seam

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Non-finite or out-of-envelope source/derived coordinate reaches rendering | Tampering / Denial of Service | Use the existing checked numeric helpers and return parser `Err` before scene publication. [VERIFIED: docs/policies/svg-numeric-admission.md; modules/mb-svg/svg/svg_test.mbt] |
| Parser/lowerer arithmetic drift bypasses a future checked route | Tampering | A single package-private checked-facts authority plus direct white-box controls. [VERIFIED: 95-CONTEXT.md; .planning/milestones/v0.30-MILESTONE-AUDIT.md] |
| Opacity refactor changes isolated compositing or resource behavior | Tampering / Denial of Service | Keep layers outside geometry; retain semantic opacity and 16/17-depth regression controls. [VERIFIED: docs/rfcs/0008-mb-canvas-layer.md; modules/mb-svg/svg/portable_qualification_wbtest.mbt] |

## Sources

### Primary (HIGH confidence)

- `95-CONTEXT.md` — locked boundary, compatibility decisions, and test policy. [VERIFIED: .planning/phases/95-shared-svg-geometry-boundary/95-CONTEXT.md]
- `scene.mbt`, `lower.mbt`, `transform.mbt`, and `svg.mbt` — current parsing, duplicated geometry, error, and total-lowering implementation. [VERIFIED: codebase inspection]
- `lower_wbtest.mbt`, `conformance_wbtest.mbt`, `numeric_contract_wbtest.mbt`, `svg_test.mbt`, and `portable_qualification_wbtest.mbt` — existing operation, public error, singular transform, and opacity/layer controls. [VERIFIED: codebase inspection]
- `svg-numeric-admission.md`, RFC 0008, and the v0.30 milestone audit — canonical numeric, rendering ownership, and recorded drift rationale. [VERIFIED: docs/policies/svg-numeric-admission.md; docs/rfcs/0008-mb-canvas-layer.md; .planning/milestones/v0.30-MILESTONE-AUDIT.md]
- Local `moon --version` and `moon test --help` — available toolchain and all-target commands. [VERIFIED: local CLI]

### Secondary (MEDIUM confidence)

None — this research is grounded in the repository’s current source, policy, test suite, and local Moon CLI. [VERIFIED: codebase inspection; local CLI]

### Tertiary (LOW confidence)

Only the focused test filename remains an implementation-placement assumption; the total-lowerer invalid-scene fallback is resolved in this research record. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new dependency; package target declaration and local CLI were inspected. [VERIFIED: modules/mb-svg/moon.mod.json; modules/mb-svg/svg/moon.pkg; local CLI]
- Architecture: HIGH — the currently duplicated functions, callers, and the locked shared-seam decision were inspected directly. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt; 95-CONTEXT.md]
- Pitfalls: HIGH — derived from the documented v0.30 drift debt and current numeric/layer compatibility controls. [VERIFIED: .planning/milestones/v0.30-MILESTONE-AUDIT.md; docs/policies/svg-numeric-admission.md; docs/rfcs/0008-mb-canvas-layer.md]

**Research date:** 2026-07-26  
**Valid until:** 2026-08-25 — source-local refactor guidance; revisit if the SVG package, numeric policy, or Moon toolchain changes. [ASSUMED]
