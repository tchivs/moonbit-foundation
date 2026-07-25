# Phase 93: SVG Compatibility & Portable Qualification - Research

**Researched:** 2026-07-26  
**Domain:** portable MoonBit SVG parse → lowering → canvas raster qualification  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Portable compatibility evidence
- **D-01:** Use a compact, curated finite SVG fixture matrix and assert deterministic drawing-operation structure plus semantic raster pixels on all four production targets. Do not use target-specific snapshots, host-dependent binary encodings, or cross-target timing assertions. — **Reversibility:** costly — the fixture matrix is the public evidence for SVGPR-03 across the supported targets.
- **D-02:** Keep parser rejection/no-partial-result checks as portable controls alongside valid-fixture qualification, but do not reopen Phase 92 numeric-policy design unless a target-specific regression proves it necessary.

### Opacity and layer semantics
- **D-03:** Treat RFC 0008 isolated layers as the canonical opacity contract: group and element `opacity` wrap the affected subtree/element using balanced `PushLayer`/`PopLayer`; `fill-opacity` and `stroke-opacity` remain per-paint alpha. Verify mixed fill/stroke and nested group/element cases by operations and raster outcome. — **Reversibility:** costly — changing this would alter public rendering semantics and RFC 0008 conformance.
- **D-04:** Test composition semantically at selected stable pixels (including transparent/opaque backdrop cases) rather than merely counting layer operations, while retaining operation-order assertions to make diagnostics precise.

### Capacity boundary
- **D-05:** Preserve the current 16 nested raster-layer capability exactly: documents within the limit render normally; the 17th layer produces the established raster capacity error. Do not clamp, flatten, recover partially, or redesign layer allocation in this phase. — **Reversibility:** costly — the limit is an RFC 0008 resource contract shared by canvas and SVG callers.

### the agent's Discretion
Choose fixture data, exact stable pixel coordinates, package/test-file placement, and whether qualification needs small test-only helpers, provided all assertions are deterministic on `js`, `wasm`, `wasm-gc`, and `native` and production opacity policy remains unchanged.

### Deferred Ideas (OUT OF SCOPE)
None — SVG surface expansion, image-sized layer optimizations, native acceleration, and benchmark timing methodology remain outside this phase.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Core algorithms and shared data models remain MoonBit; native is primary but the four declared portable targets must be deliberately supported. [VERIFIED: AGENTS.md]
- Keep FFI absent here; any future FFI must be small, isolated, documented, and replaceable. [VERIFIED: AGENTS.md]
- Preserve acyclic, explicit public package dependencies, deterministic GUI-free automation, RFC-governed architecture, and SemVer-facing compatibility. [VERIFIED: AGENTS.md]
- Public package behavior needs black-box tests, internal invariants need `*_wbtest.mbt`, and binary/raster expectations must use semantic byte/pixel assertions instead of opaque snapshots. [VERIFIED: AGENTS.md]
- Do not expand SVG surface area, rendering policy, benchmarks, native acceleration, or governance boundaries during this qualification phase. [VERIFIED: AGENTS.md, `93-CONTEXT.md`]
- Work remains inside the active GSD planning/execution workflow; no product code is part of this research deliverable. [VERIFIED: AGENTS.md, parent task]
- Code discovery normally prefers the project graph; it is unavailable because `.planning/graphs/graph.json` is absent, so this research used targeted code search for test/config string and source discovery. [VERIFIED: codebase probe]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| SVGPR-03 | Library users retain deterministic lowering and raster output for valid finite SVG, including isolated group/element opacity and the existing 16-layer canvas capability boundary, on `js`, `wasm`, `wasm-gc`, and `native`. | A single all-target SVG qualification suite can exercise `parse_svg → lower_to_drawing_list → @canvas.render`, operation order, stable RGBA pixels, parser controls, and the exact canvas depth error. [VERIFIED: `.planning/REQUIREMENTS.md`, `modules/mb-svg/svg/lower.mbt`, `modules/mb-canvas/canvas/rasterize.mbt`] |
</phase_requirements>

## Summary

Phase 93 is an evidence-first integration phase. The product path already exists: `parse_svg` returns a validated scene, `lower_to_drawing_list` emits portable canvas operations, and `@canvas.render` writes an RGBA8 target under a caller-provided budget. Current SVG tests prove parser/lowering behavior on all four targets, while canvas tests prove direct layer compositing and the depth limit; the missing proof is their joined end-to-end path. [VERIFIED: Phase 92 verification, `modules/mb-svg/svg/{conformance_wbtest,lower_wbtest,svg_test}.mbt`, `modules/mb-canvas/canvas/{rasterize,render_wbtest}.mbt`]

The qualification suite should use a small, named matrix of fully finite SVG literals that keep asserted pixels well inside axis-aligned shapes. It must assert both (1) exact, diagnostic operation sequences and (2) semantic RGBA pixels on transparent and opaque backdrops. This gives target-neutral evidence without serialized-image snapshots, host encoders, timing, or a new renderer. [VERIFIED: `93-CONTEXT.md`, AGENTS.md, `examples/mb-svg-demo/main/main.mbt`]

**Primary recommendation:** Add one SVG-owned portable qualification test seam with tiny RGBA8/budget helpers, extend the existing fixture manifest/matrix as the normative provenance record, and run `moon test modules/mb-svg/svg --target all --frozen`; touch production lowering/raster code only if this evidence exposes a reproducible target regression. [VERIFIED: `.planning/config.json`, MoonBit Package Configuration docs: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html, `modules/mb-svg/svg/moon.pkg`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Parse valid/invalid SVG into a scene | API / Backend | — | `parse_svg` is the target-neutral admission boundary and produces a `Result[SceneNode, CoreError]`. [VERIFIED: `modules/mb-svg/svg/{scene,svg_test}.mbt`] |
| Lower scene semantics into operations | API / Backend | Database / Storage | `lower_to_drawing_list` owns SVG-to-`DrawOp` translation; the list remains portable data until rasterization. [VERIFIED: `modules/mb-svg/svg/lower.mbt`] |
| Render drawing list and isolate opacity | API / Backend | Database / Storage | Canvas owns temporary offscreen RGBA8 layers and source-over write-back; SVG must not implement compositor behavior. [VERIFIED: `docs/rfcs/0008-mb-canvas-layer.md`, `modules/mb-canvas/canvas/rasterize.mbt`] |
| Store/inspect pixels for qualification | Database / Storage | API / Backend | `OwnedImage` is caller-owned storage and the renderer mutates it in place; tests inspect selected RGBA bytes. [VERIFIED: `modules/mb-canvas/canvas/{rasterize,render_wbtest}.mbt`] |
| Four-target qualification | API / Backend | — | Moon expands test target `all` to `wasm`, `wasm-gc`, `js`, and `native`; no browser/GUI tier is involved. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` | `0.1.20260713` | Compile and execute the portable SVG test matrix. | Locally installed project toolchain; `moon test --target all` covers the four declared production targets. [VERIFIED: local `moon --version`; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |
| `tchivs/mb-svg/svg` | workspace `0.1.0` | Parse finite fixtures and lower to `DrawingList`. | Existing public SVG seam; no new package or API is warranted. [VERIFIED: `modules/mb-svg/{moon.mod.json,svg/lower.mbt}`] |
| `tchivs/mb-canvas/canvas` | workspace `0.1.0` | Render drawing lists, composite `PushLayer` surfaces, enforce layer depth. | Existing renderer and RFC 0008 capability owner. [VERIFIED: `modules/mb-canvas/{moon.mod.json,canvas/rasterize.mbt}`] |
| `tchivs/mb-image/{model,storage,metadata}` | workspace `0.1.0` | Construct a tiny RGBA8 target and read selected pixels in tests. | Existing test helper pattern and caller-owned raster surface. [VERIFIED: `modules/mb-canvas/canvas/render_wbtest.mbt`] |

### Supporting

| Library / tool | Version | Purpose | When to Use |
|---|---:|---|---|
| `fixtures/svg/cases.json` + `fixtures/manifest.json` | repository data | Provenance-bearing source of canonical/edge/adversarial SVG text. | Extend with a compact `portable_qualification_cases` schedule, then mirror literal data in the MoonBit test because wbtests do not read JSON at runtime. [VERIFIED: `modules/mb-svg/svg/conformance_wbtest.mbt`, `fixtures/{svg/cases.json,manifest.json}`] |
| `@budget.Budget` | workspace `0.1.0` | Give every 8×8 render enough bytes, allocations, pixels, work, and depth for up to 17 layer attempts. | Reuse the canvas render-test resource-limit shape; do not make ambient allocation assumptions. [VERIFIED: `modules/mb-canvas/canvas/render_wbtest.mbt`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| SVG-owned all-target test | Extend only `examples/mb-svg-demo` and loop `moon run` once per target | The demo is a useful public smoke test, but current `moon run --target all` is rejected and `moon test` provides stronger, automatic four-target coverage. Keep the demo unchanged unless a public workflow proof is separately needed. [VERIFIED: local command `moon -C examples/mb-svg-demo run main --target all --frozen`; `examples/mb-svg-demo/main/main.mbt`] |
| Semantic RGBA assertions | PNG/PPM snapshots or target-specific binary output | Snapshots introduce encoding/host variance and obscure composition failures; individual stable interior/exterior bytes identify the broken operation precisely. [VERIFIED: AGENTS.md, `93-CONTEXT.md`] |
| SVG end-to-end layer boundary test | Only direct canvas 16/17-layer test | Direct canvas coverage is necessary but cannot prove that nested SVG `opacity` lowers to the same capacity boundary. [VERIFIED: `modules/mb-canvas/canvas/render_wbtest.mbt`, `modules/mb-svg/svg/lower.mbt`] |

**Installation:** None — this phase adds no external packages. [VERIFIED: `modules/mb-svg/moon.mod.json`]

## Architecture Patterns

### System Architecture Diagram

```text
finite SVG fixture
       |
       v
parse_svg ──Err──> public parser-control assertion (no SceneNode, no lower/raster)
       |
      Ok(SceneNode)
       |
       v
lower_to_drawing_list
       |                         nested group/element opacity
       v                                  |
DrawingList <──────── exact DrawOp order (PushLayer / Fill|Stroke / PopLayer)
       |
       v
@canvas.render(list, RGBA8 OwnedImage, Budget)
       |                          |
       |                          +── 17th PushLayer → Resource/BudgetExceeded
       v
selected interior/exterior pixel assertions
```

The operation and pixel assertions must remain paired: order exposes incorrect lowering, while pixels prove isolated source-over composition instead of a superficial matching layer count. [VERIFIED: `93-CONTEXT.md`, `docs/rfcs/0008-mb-canvas-layer.md`]

### Recommended Project Structure

```text
fixtures/
├── manifest.json                         # update provenance/digest/expected use
└── svg/cases.json                        # compact portable_qualification_cases schedule
modules/mb-svg/svg/
├── moon.pkg                              # test-only direct imports only if needed by helpers
├── conformance_wbtest.mbt                # retain broad parse → lower controls
└── portable_qualification_wbtest.mbt     # new parse → lower → raster / capacity matrix
```

The new file should be an internal `*_wbtest.mbt`: it needs controlled `OwnedImage` construction and reads internal operation structure, while `svg_test.mbt` remains the public parser error contract. [VERIFIED: AGENTS.md, `modules/mb-svg/svg/{conformance_wbtest,lower_wbtest,svg_test}.mbt`]

### Pattern 1: Fixture literal + normative metadata mirror

**What:** Maintain the compact fixture schedule in `fixtures/svg/cases.json` with provenance in `fixtures/manifest.json`; mirror its literal SVG text and expected semantic facts in the wbtest. [VERIFIED: `modules/mb-svg/svg/conformance_wbtest.mbt`, `fixtures/manifest.json`]

**When to use:** For each supported valid/edge/invalid class added to portable qualification. [VERIFIED: RFC 0002 §11.1, `fixtures/svg/cases.json`]

**Example:**

```moonbit
// Source: existing conformance fixture pattern
let source = "<svg><rect width=\"8\" height=\"8\" fill=\"red\"/></svg>"
let scene = parse_svg(source).unwrap()
let list = lower_to_drawing_list(scene)
// Assert expected operation shape before render, then selected RGBA bytes.
```

### Pattern 2: Stable-pixel, semantic raster oracle

**What:** Render 8×8, axis-aligned, whole-pixel shapes and inspect center `(4,4)` plus an exterior pixel such as `(0,0)`; avoid path edges, transformed diagonals, and image encoders. [VERIFIED: `modules/mb-canvas/canvas/render_wbtest.mbt`, `examples/mb-svg-demo/main/main.mbt`]

**When to use:** For opaque color, transparent target, opaque backdrop, fill/stroke opacity, group/element isolation, and post-error unchanged-target assertions. [VERIFIED: `93-CONTEXT.md`]

**Expected fixture set (prescriptive):**

| Fixture ID | SVG/target | Operation oracle | Raster oracle |
|---|---|---|---|
| `opaque-rect` | 8×8 red rect on transparent RGBA8 | one `Fill`, no layer ops | center `(255,0,0,255)`; corner stays `(0,0,0,0)`. [VERIFIED: existing canvas/demo raster pattern] |
| `viewbox-blue-rect` | `viewBox="0 0 4 4" width="8" height="8"` with blue rect | root `PushTransform`, `Fill`, `PopTransform` | center opaque blue; proves valid root mapping reaches raster. [VERIFIED: `modules/mb-svg/svg/lower_wbtest.mbt`] |
| `fill-stroke-opacity` | opaque fill plus a non-overlapping/center-safe stroke sample | fill alpha and stroke alpha remain paint fields; no element layer at opacity 1 | assert an interior fill pixel and a stroke-only pixel against the opaque backdrop, not an antialiased boundary. [VERIFIED: `modules/mb-svg/svg/{lower,lower_wbtest}.mbt`] |
| `isolated-group-overlap` | group `opacity=.5` containing two overlapping `fill-opacity=.5` full rects | group exactly wraps child ops with one balanced pair | on opaque white, overlap must retain the isolated-layer relationship and differ from per-child group-alpha pushdown; assert fixed channels/ordering at the center. [CITED: https://www.w3.org/Graphics/SVG/1.1/masking.html; VERIFIED: RFC 0008 §3.1] |
| `nested-group-element-opacity` | group `.5`, child element `.25`, mixed fill+stroke | nested `PushLayer(.5)`, `PushLayer(.25)`, fill/stroke, `PopLayer`, `PopLayer` | opaque-backdrop center proves multiplicative post-composition; transparent-backdrop center proves alpha is preserved without backdrop contamination. [VERIFIED: `modules/mb-svg/svg/lower_wbtest.mbt`, `modules/mb-canvas/canvas/render_wbtest.mbt`] |
| `layer-depth-16` / `layer-depth-17` | generated nested `<g opacity=".5">` around a full rect | 16/17 balanced SVG-generated layer pairs | 16 returns `Ok` and has a non-empty expected center; 17 returns the exact established canvas resource error and leaves the primary image unchanged. [VERIFIED: `modules/mb-canvas/canvas/rasterize.mbt`] |

### Pattern 3: Exact structured boundary error

**What:** Assert the 17-layer result as `ErrorCategory::Resource`, `ErrorCode::BudgetExceeded`, operation `Some("canvas-render")`, and context `Some("canvas-layer-depth: layer nesting depth exceeded")`; do not accept an arbitrary error. [VERIFIED: `modules/mb-canvas/canvas/rasterize.mbt`]

**When to use:** Only the generated 17-nested-SVG qualification case. The existing 16-layer direct-canvas test remains as a lower-tier control. [VERIFIED: `93-CONTEXT.md`, `modules/mb-canvas/canvas/render_wbtest.mbt`]

### Anti-Patterns to Avoid

- **Per-child application of group opacity:** It changes overlap results; group/object opacity is an offscreen postprocess, unlike fill/stroke opacity. [CITED: https://www.w3.org/Graphics/SVG/1.1/masking.html]
- **Counting only `PushLayer` operations:** A balanced but incorrectly composited layer stream can still produce wrong pixels. [VERIFIED: `93-CONTEXT.md`]
- **Asserting antialiased edge pixels:** Coverage sampling makes boundary values poor portability sentinels; test full-coverage interior/exterior points. [VERIFIED: `modules/mb-canvas/canvas/{coverage_wbtest,render_wbtest}.mbt`]
- **Making `moon run --target all` the gate:** The installed CLI rejects `--target all` for `run`; use the test command’s all-target expansion. [VERIFIED: local command execution; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]
- **Changing numeric admission or layer allocation policy to make a test pass:** Both are explicitly locked/out of scope; first prove a target-specific regression. [VERIFIED: `93-CONTEXT.md`, Phase 92 verification]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| SVG opacity compositor | SVG-side alpha multiplication or a second rasterizer | Existing `DrawingList::push_layer/pop_layer` and `@canvas.render` | Canvas owns offscreen isolation, source-over, budget charging, and depth enforcement. [VERIFIED: RFC 0008, `modules/mb-canvas/canvas/rasterize.mbt`] |
| Image serializer/snapshot harness | Target-specific PNG/PPM golden files | Existing RGBA8 `OwnedImage` helpers and selected byte reads | Pixels are already deterministic portable data; encoding adds an unrelated compatibility surface. [VERIFIED: AGENTS.md, `modules/mb-canvas/canvas/render_wbtest.mbt`] |
| Numeric rejection reimplementation | Test-only number parser/policy | `parse_svg` public `Result` controls from Phase 92 | The parser is the established admission boundary and already has all-target evidence. [VERIFIED: Phase 92 verification, `modules/mb-svg/svg/svg_test.mbt`] |
| Parallel depth implementation | SVG nesting counter/cap | Existing canvas `MAX_LAYER_DEPTH = 16` behavior | A duplicate cap can drift from the shared resource contract. [VERIFIED: `modules/mb-canvas/canvas/rasterize.mbt`, RFC 0008 §7] |

**Key insight:** Phase 93 should prove the existing layer primitive through SVG, not recreate any of its policy or rendering math. [VERIFIED: `93-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Valid parser coverage mistaken for raster qualification

**What goes wrong:** `conformance_wbtest.mbt` currently establishes parse success and non-empty lists but never invokes `@canvas.render`. [VERIFIED: `modules/mb-svg/svg/conformance_wbtest.mbt`]

**How to avoid:** Keep that broad fixture control and add the small end-to-end raster matrix rather than enlarging every fixture into an image oracle. [VERIFIED: `93-CONTEXT.md`]

### Pitfall 2: Lossy opacity oracle

**What goes wrong:** A single semi-transparent child cannot distinguish group isolation from pushing group opacity into paint alpha. [CITED: https://www.w3.org/Graphics/SVG/1.1/masking.html]

**How to avoid:** Include two overlapping children inside an opaque-backdrop group, plus nested group/element coverage; pair the pixel with the exact layer sequence. [VERIFIED: RFC 0008 §3.1, `93-CONTEXT.md`]

### Pitfall 3: Depth test proves only failure

**What goes wrong:** The current canvas test accepts any `Err` for 17 direct layers and does not prove SVG-generated 16 layers still render. [VERIFIED: `modules/mb-canvas/canvas/render_wbtest.mbt`]

**How to avoid:** Add both generated SVG cases, exact accessors for the 17th error, and a primary-target unchanged-byte check after the failure. [VERIFIED: `modules/mb-canvas/canvas/rasterize.mbt`, `93-CONTEXT.md`]

### Pitfall 4: Incorrect all-target executable command

**What goes wrong:** The installed Moon CLI allows `--target all` for `moon test` but rejects it for `moon run`. [VERIFIED: local command execution]

**How to avoid:** Make `moon test modules/mb-svg/svg --target all --frozen` the phase gate; if a demo run is retained, invoke four explicit `moon -C examples/mb-svg-demo run main --target <target> --frozen` commands. [VERIFIED: local command execution; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]

## Code Examples

Verified patterns from repository sources:

### Public parser control that cannot leak a drawing list

```moonbit
// Source: modules/mb-svg/svg/svg_test.mbt
match parse_svg("<svg><rect opacity=\"bad\"/></svg>") {
  Ok(_) => inspect(false, content="true")
  Err(error) => {
    inspect(error.operation(), content="Some(\"svg\")")
    inspect(error.context(), content="Some(\"svg-numeric-source\")")
  }
}
```

### SVG-generated capacity assertion

```moonbit
// Source: modules/mb-canvas/canvas/rasterize.mbt error contract
match @canvas.render(list, image, qualification_budget()) {
  Ok(_) => inspect(false, content="true") // only for 17 nested opacity groups
  Err(error) => {
    inspect(error.category() == @error.ErrorCategory::Resource, content="true")
    inspect(error.code() == @error.ErrorCode::BudgetExceeded, content="true")
    inspect(error.operation(), content="Some(\"canvas-render\")")
    inspect(error.context(), content="Some(\"canvas-layer-depth: layer nesting depth exceeded\")")
  }
}
```

## State of the Art

| Old / insufficient evidence | Required current approach | Impact |
|---|---|---|
| Parse/lower fixture accepts `Ok` and non-empty drawing list | End-to-end parse → lower → raster matrix on all four targets | Adds observable portable output evidence without changing supported SVG surface. [VERIFIED: `modules/mb-svg/svg/conformance_wbtest.mbt`, `93-CONTEXT.md`] |
| Direct canvas 17-layer failure only | SVG-originated 16-success/17-exact-error pair | Proves lowering reaches the shared canvas resource boundary. [VERIFIED: `modules/mb-canvas/canvas/render_wbtest.mbt`, `modules/mb-svg/svg/lower.mbt`] |
| Counting layer operations | Layer-order plus stable-pixel compositing assertions | Detects semantic opacity regressions, not merely structural ones. [VERIFIED: `93-CONTEXT.md`] |

**Deprecated/outdated:** Treating target-specific image snapshots or cross-target render timings as compatibility evidence is out of scope for this phase. [VERIFIED: `93-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| — | None — all implementation-critical claims were checked against the codebase, locked context, RFCs, local Moon CLI, or official documentation. [VERIFIED: research evidence above] | — | No user confirmation gate is needed. [VERIFIED: research evidence above] |

## Open Questions

None. Fixture placement and helper placement are delegated choices, but the recommended `portable_qualification_wbtest.mbt` plus normative fixture-metadata extension satisfies every locked decision without changing production semantics. [VERIFIED: `93-CONTEXT.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` / `moonc` / `moonrun` | Four-target compilation and test gate | ✓ | `moon 0.1.20260713`; `moonc v0.10.4+2cc641edf`; `moonrun 0.1.20260713` | — [VERIFIED: local `moon --version`] |
| Workspace module dependencies | SVG/canvas/image qualification helpers | ✓ | workspace `0.1.0` modules | — [VERIFIED: `modules/mb-svg/moon.mod.json`] |

**Missing dependencies with no fallback:** None. [VERIFIED: local Moon test execution]

**Missing dependencies with fallback:** None. [VERIFIED: local Moon test execution]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | no | No identity or credential path is in SVG parse/lower/raster qualification. [VERIFIED: phase scope] |
| V3 Session Management | no | No session state is present. [VERIFIED: phase scope] |
| V4 Access Control | no | No authorization boundary is introduced. [VERIFIED: phase scope] |
| V5 Input Validation | yes | Preserve Phase 92 `parse_svg` structured-error/no-scene controls alongside valid raster fixtures. [VERIFIED: Phase 92 verification, `93-CONTEXT.md`] |
| V6 Cryptography | no | No cryptographic operation or secret is involved. [VERIFIED: phase scope] |

### Known Threat Patterns for SVG/canvas qualification

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Malformed/non-finite/out-of-envelope SVG becomes a partial render | Tampering / Denial of Service | Assert `parse_svg` returns structured `Err`; do not lower or render an absent scene. [VERIFIED: Phase 92 verification, `modules/mb-svg/svg/svg_test.mbt`] |
| Nested opacity consumes unbounded memory | Denial of Service | Canvas enforces 16 nested layers and returns the structured `canvas-layer-depth` budget error before a 17th offscreen allocation. [VERIFIED: `modules/mb-canvas/canvas/rasterize.mbt`, RFC 0008 §7] |
| Group opacity is applied to each paint | Tampering | Assert balanced layer order and overlap pixels that require offscreen isolation. [CITED: https://www.w3.org/Graphics/SVG/1.1/masking.html] |

## Recommended Plan Decomposition

1. **Fixture/provenance and RED qualification seam.** Extend the existing SVG fixture authority with the compact named matrix and manifest digest/expected-use text; create a focused SVG wbtest with reusable tiny RGBA8, pixel-read, render-budget, and generated-nested-group helpers. Include explicit operation-order expectations before every raster assertion. [VERIFIED: `fixtures/{svg/cases.json,manifest.json}`, `modules/mb-canvas/canvas/render_wbtest.mbt`]
2. **Portable raster and opacity qualification.** Implement finite rect/viewBox/path and fill/stroke/group/element/nested-opacity cases. Require transparent and opaque backdrop assertions at full-coverage pixels, and retain the Phase 92 malformed-input public control in the same four-target command. [VERIFIED: `93-CONTEXT.md`, `modules/mb-svg/svg/{svg_test,lower_wbtest}.mbt`]
3. **Shared 16/17 layer-boundary qualification and regression-only fix.** Generate 16 and 17 nested SVG opacity groups. Assert 16 success, 17’s exact `canvas-render` resource error, and no changed primary pixel after failure; only then make the smallest demonstrated production fix if any target fails. [VERIFIED: `93-CONTEXT.md`, `modules/mb-canvas/canvas/rasterize.mbt`]

## Sources

### Primary (HIGH confidence)

- [RFC 0002](../../../docs/rfcs/0002-mb-svg.md) — supported SVG subset, portability, conformance, and raster seam. [VERIFIED: repository RFC]
- [RFC 0008](../../../docs/rfcs/0008-mb-canvas-layer.md) — isolated layer semantics, source-over policy, and 16-depth boundary. [VERIFIED: repository RFC]
- `modules/mb-svg/svg/{lower.mbt,lower_wbtest.mbt,conformance_wbtest.mbt,svg_test.mbt}` — concrete SVG lowering/parser seams. [VERIFIED: codebase grep]
- `modules/mb-canvas/canvas/{rasterize.mbt,render_wbtest.mbt}` — concrete raster, pixel, budget, and error seams. [VERIFIED: codebase grep]
- Phase 92 summaries and verification — retained parser/no-partial behavior and passing four-target baseline. [VERIFIED: `.planning/phases/92-fail-closed-svg-parsing/{92-03-SUMMARY.md,92-VERIFICATION.md}`]

### Secondary (MEDIUM confidence)

- [MoonBit Package Configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — `--target all` target expansion and supported-target behavior. [CITED: official documentation]
- [SVG 1.1 opacity semantics](https://www.w3.org/Graphics/SVG/1.1/masking.html) — object/group opacity as offscreen postprocessing, distinct from fill/stroke opacity. [CITED: official specification]

### Tertiary (LOW confidence)

- None. [VERIFIED: research source inventory]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all components are local workspace modules and the exact installed Moon toolchain was queried. [VERIFIED: local commands]
- Architecture: HIGH — the end-to-end path, layer ownership, and error contract are explicit in current source and RFCs. [VERIFIED: codebase/RFC sources]
- Pitfalls: HIGH — each maps to a current test gap, locked decision, or executed CLI behavior. [VERIFIED: codebase/context/local command]

**Research date:** 2026-07-26  
**Valid until:** 2026-08-25 (stable internal contracts; re-check Moon CLI behavior when toolchain pin changes). [VERIFIED: local `moon --version`]
