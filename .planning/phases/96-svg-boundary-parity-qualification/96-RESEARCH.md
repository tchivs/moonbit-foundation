# Phase 96: SVG Boundary Parity Qualification - Research

**Researched:** 2026-07-26
**Domain:** MoonBit SVG numeric-boundary qualification and target-neutral regression tests
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Boundary publication controls
- **D-01:** Treat parser-produced `SceneNode`/drawing/raster results as forbidden after an unsafe explicit or derived geometry result; assert the established structured error at the parse boundary.
- **D-02:** Keep `lower_to_drawing_list` total for manually constructed invalid public scene values. Its deterministic empty/identity recovery is a separate compatibility behavior, not a parser-success path.

### Parity qualification
- **D-03:** Use semantic adversarial fixtures and white-box seam controls to prove the parser and lowerer reach identical numeric-boundary outcomes. Do not use source-text duplication checks or timing comparisons.
- **D-04:** Run the final controls under wasm, wasm-gc, js, and native. Assert observable operation/error semantics, not target-specific internal timing.

### Compatibility preservation
- **D-05:** Preserve finite `scale(0)`, valid viewBox/default behavior, and RFC 0008 group opacity/layer behavior as explicit regression controls; no new public API, numeric bound, or error schema.

### the agent's Discretion
- Select the narrowest existing test files and fixtures that cover every geometry family while keeping controls deterministic and target-neutral.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Prefer `codebase-memory-mcp` graph discovery for code definitions/relationships; use text search only when graph results are insufficient or when locating literals/configuration. The graph has no indexed nodes for `modules/mb-svg/svg`, so this research used the allowed scoped text-search fallback. [VERIFIED: AGENTS.md; codebase-memory-mcp]
- Keep shared algorithms and data models in MoonBit; native is primary, while portability is explicit through capability boundaries and conformance tests. [VERIFIED: AGENTS.md]
- Keep FFI isolated and replaceable, public dependencies acyclic, public operations deterministic without GUI state, public APIs SemVer-safe, performance claims reproducible, and architectural changes RFC-governed. [VERIFIED: AGENTS.md]
- The reverse-engineering routing rule is not triggered: this is MoonBit test qualification, not a reverse-engineering or penetration-testing task. [VERIFIED: AGENTS.md]
- This phase may change only existing test/qualification evidence; it must not add a public API, numeric bound, error schema, SVG feature, or production-path behavior. [VERIFIED: 96-CONTEXT.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| SVGUNI-02 | Explicit unsafe or derived-overflow SVG geometry returns the established structured error before a scene, drawing list, or raster operation is published, regardless of whether it reaches the parser or lowerer boundary. | Public `parse_svg` error controls plus private semantic-seam matrix distinguish parser rejection from the total-lowerer fallback. [VERIFIED: REQUIREMENTS.md; modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt] |
| SVGUNI-03 | Maintainers have deterministic regression controls that detect parser/lowerer numeric-boundary divergence while preserving valid finite singular transforms and RFC 0008 opacity/layer behavior on wasm, wasm-gc, js, and native. | Existing `geometry_wbtest`, `lower_wbtest`, `svg_test`, and `portable_qualification_wbtest` are the narrow test homes; one all-target package command is authoritative. [VERIFIED: REQUIREMENTS.md; modules/mb-svg/svg/*_test.mbt; modules/mb-svg/moon.mod.json] |
</phase_requirements>

## Summary

Phase 95 has already centralized live parser preflight and lowering geometry checks in package-private `geometry.mbt`: `parse_svg` publishes a `SceneNode` only after `preflight_scene` returns `Ok`, while `lower_to_drawing_list` intentionally returns a `DrawingList` for every manually constructed scene and maps invalid root/path facts to identity or empty-path recovery. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt; 95-VERIFICATION.md]

Phase 96 should add qualification evidence, not alter the implementation. The proof must pair public parser fixtures with white-box semantic controls over the same invalid geometry: parser/preflight and the checked seam must return the established `CoreError`; lowerer input deliberately constructed outside the parser must produce the documented identity/empty-path sentinel without changing layer ordering. This proves parity without source-text scans, timings, or a false claim that total lowering reports a parser error. [VERIFIED: 96-CONTEXT.md; modules/mb-svg/svg/svg_test.mbt; modules/mb-svg/svg/geometry_wbtest.mbt; modules/mb-svg/svg/lower_wbtest.mbt]

**Primary recommendation:** Add one adversarial, table-driven white-box parity matrix in `geometry_wbtest.mbt`, strengthen the public publication-boundary assertions in `svg_test.mbt`, retain the existing manual-fallback and RFC 0008 semantic raster controls, then qualify the entire package with `moon test modules/mb-svg/svg --target all --frozen`. [VERIFIED: modules/mb-svg/svg/*test.mbt; modules/mb-svg/moon.mod.json; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Admit explicit SVG numeric input | API / Backend | — | `parse_svg` converts untrusted SVG text to `Result[SceneNode, CoreError]`; lexical/source failure must end before a scene exists. [VERIFIED: modules/mb-svg/svg/svg.mbt; modules/mb-svg/svg/svg_test.mbt] |
| Check derived transform, viewBox, primitive, point-list, and path geometry | API / Backend | — | `geometry.mbt` owns the package-private Result-returning arithmetic facts consumed by parser preflight and lowering. [VERIFIED: modules/mb-svg/svg/geometry.mbt; modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt] |
| Publish a parsed SVG scene | API / Backend | — | `parse_svg` invokes `preflight_scene` before returning `Ok(node)`. [VERIFIED: modules/mb-svg/svg/scene.mbt] |
| Recover manual-invalid public scene values | API / Backend | — | The public lowerer owns compatibility recovery: invalid root maps become identity and invalid paths become empty paths. [VERIFIED: modules/mb-svg/svg/lower.mbt] |
| Render opacity layers | API / Backend | Database / Storage | `mb-svg` emits layer operations; the canvas rasterizer owns bounded offscreen composition and the caller owns the image target. [VERIFIED: docs/rfcs/0008-mb-canvas-layer.md; modules/mb-svg/svg/lower.mbt] |
| Four-target parity qualification | CI / Toolchain | API / Backend | `mb-svg` declares wasm, wasm-gc, js, and native support, and Moon's `--target all` expands to precisely those four backends. [VERIFIED: modules/mb-svg/moon.mod.json; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|---|---:|---|---|
| MoonBit `moon` / `moonc` / `moonrun` | `0.1.20260713` / `v0.10.4+2cc641edf` / `0.1.20260713` | Compile and execute the existing package tests. | Installed project toolchain; `moon test` supports `--target all` and `--frozen`. [VERIFIED: local `moon --version`; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html] |
| `modules/mb-svg/svg` tests | repository source | Public and white-box semantic qualification. | Existing package already contains public parser, private seam, total-lowering, and portable raster test homes. [VERIFIED: modules/mb-svg/svg/svg_test.mbt; modules/mb-svg/svg/geometry_wbtest.mbt; modules/mb-svg/svg/lower_wbtest.mbt; modules/mb-svg/svg/portable_qualification_wbtest.mbt] |

### Supporting

| Library / tool | Version | Purpose | When to Use |
|---|---:|---|---|
| `@error.CoreError` accessors | existing `mb-core` dependency | Assert category, code, operation, and context of parser errors. | Every unsafe parser fixture must assert all four structured facts, not merely `Err`. [VERIFIED: modules/mb-svg/svg/svg_test.mbt] |
| `@canvas.DrawingList` / `DrawOp` | existing `mb-canvas` dependency | Observe lowerer recovery and opacity/layer ordering. | Assert identity/empty recovery and semantic operation ordering for manually invalid scenes. [VERIFIED: modules/mb-svg/svg/lower.mbt; modules/mb-svg/svg/lower_wbtest.mbt] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Semantic fixtures and direct private-seam controls | Source-text duplication/call-site scans | Rejected: a textual check cannot prove the observable parser/lowerer outcome and is explicitly forbidden by D-03. [VERIFIED: 96-CONTEXT.md] |
| Deterministic DrawOp/error assertions | Timing/performance comparison | Rejected: timing is target-sensitive and is explicitly forbidden by D-03/D-04. [VERIFIED: 96-CONTEXT.md] |
| Existing test files | A new test package or public diagnostic API | Rejected: the required seams are already package-private and covered by established test homes; a new public API violates D-05. [VERIFIED: 96-CONTEXT.md; modules/mb-svg/svg/*_wbtest.mbt] |

**Installation:** None — Phase 96 installs no external package and must not change dependencies. [VERIFIED: 96-CONTEXT.md; modules/mb-svg/moon.mod.json]

## Architecture Patterns

### System Architecture Diagram

```text
untrusted SVG source
        |
        v
parse_svg / source admission ---- explicit-invalid ----> Err(CoreError) ──> no SceneNode / DrawOps / raster
        |
        v
build SceneNode
        |
        v
preflight_scene ──uses──> checked geometry seam ──derived-invalid──> Err(CoreError) ──> no publication
        |
        v
published parser SceneNode
        |
        v
lower_to_drawing_list ──uses──> checked geometry seam ──valid──> DrawOps ──> canvas render

manual public SceneNode (may be invalid)
        |
        v
lower_to_drawing_list ──failed checked fact──> identity/empty deterministic fallback ──> DrawOps
```

The two invalid branches intentionally differ only at the public boundary: parser-originated invalid data returns the structured error before publication; manually supplied invalid public values are total-lowered into observable fallback DrawOps. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt]

### Recommended Test Placement

```text
modules/mb-svg/svg/
├── svg_test.mbt                    # exported parser error facts and no-publication contract
├── geometry_wbtest.mbt             # table-driven private seam / preflight / lowerer parity matrix
├── lower_wbtest.mbt                # deterministic manual-invalid fallback and DrawOp order
└── portable_qualification_wbtest.mbt # RFC 0008 layer ordering and semantic raster regression
```

Use these existing files; do not add a new production module, fixture format, or public API. [VERIFIED: 96-CONTEXT.md; modules/mb-svg/svg/*test.mbt]

### Pattern 1: Three-observation boundary matrix

**What:** For each adversarial geometry family, assert (1) a source fixture yields the expected public `CoreError`, (2) the directly invoked checked/preflight seam yields the same structured derived outcome, and (3) the equivalent manually constructed `SceneNode` lowers to its specified deterministic sentinel. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/geometry.mbt; modules/mb-svg/svg/lower.mbt]

**When to use:** Use for root viewBox mapping, composed group transforms, rounded rectangles, circles/ellipses, lines, polylines/polygons, and CanvasPath commands; the existing seam exposes a `checked_*` fact for each of these families. [VERIFIED: modules/mb-svg/svg/geometry.mbt; modules/mb-svg/svg/scene.mbt]

**Deterministic matrix controls:**

| Family | Parser fixture / expected outcome | White-box seam observation | Manual lowerer observation |
|---|---|---|---|
| Explicit source scalar | `65537` or `1e999` source scalar yields `InvalidRange`/`InvalidEncoding` with `svg-numeric-range`/`svg-numeric-nonfinite`. | Source admission remains an error before geometry construction. | Not applicable: this is an ingress-only control. [VERIFIED: modules/mb-svg/svg/svg_test.mbt] |
| viewBox map | A finite source-valid viewBox whose derived translation exceeds the envelope yields `InvalidRange`, `svg-numeric-derived`. | `checked_viewbox_transform` returns that derived error. | Invalid manual root yields identity mapping; assert no `PushTransform` is introduced for the fallback. [VERIFIED: modules/mb-svg/svg/svg_test.mbt; modules/mb-svg/svg/geometry.mbt; modules/mb-svg/svg/lower.mbt] |
| group affine | A source-valid transform composition drives a child point out of range and parser returns `svg-numeric-derived`. | `checked_compose_affine` and/or `checked_transform_point` returns the same error. | Invalid manual group/child must lower with an empty geometry result, never a parser-success claim. [VERIFIED: modules/mb-svg/svg/svg_test.mbt; modules/mb-svg/svg/geometry.mbt; modules/mb-svg/svg/lower.mbt] |
| rect / circle / ellipse | Source-valid extrema or edge construction exceeds the envelope and parser returns `svg-numeric-derived`. | `checked_rect_path` / `checked_circle_path` / `checked_ellipse_path`, followed by point validation where required, rejects. | Equivalent manual shape produces `Fill(emptyPath, ...)`; layers and fill/stroke ordering remain stable. [VERIFIED: modules/mb-svg/svg/svg_test.mbt; modules/mb-svg/svg/geometry.mbt; modules/mb-svg/svg/lower_wbtest.mbt] |
| line / point list / path | Source-valid transform or path coordinate drives a point/control/end point out of range and parser returns `svg-numeric-derived`. | `checked_line_path`, `checked_polyline_path`, `checked_polygon_path`, or `checked_canvas_path` plus `checked_path_points` rejects. | Equivalent manual path/list lowers to an empty fill/stroke path deterministically. [VERIFIED: modules/mb-svg/svg/geometry.mbt; modules/mb-svg/svg/geometry_wbtest.mbt; modules/mb-svg/svg/lower.mbt] |

**Example (test-only sketch):**

```moonbit
// Source: repository patterns in svg_test.mbt, geometry_wbtest.mbt, lower_wbtest.mbt
// Parser publication control: no SceneNode is obtainable on Err.
assert_public_numeric_error(
  parse_svg("<svg><g transform=\"scale(65536) scale(2)\"><rect width=\"1\" height=\"1\"/></g></svg>"),
  @error.ErrorCode::InvalidRange,
  "svg-numeric-derived",
)

// White-box fact: direct shared arithmetic reaches the same derived error.
match checked_transform_point(@math.Affine2::scale(65536.0, 1.0), @math.Point2::new(2.0, 0.0)) {
  Err(error) => inspect(error.context(), content="Some(svg-numeric-derived)")
  Ok(_) => inspect(false, content="true")
}

// Compatibility control: this manually constructed invalid value is not parser output.
match lower_to_drawing_list(invalid_scene).get(0) {
  Some(@canvas.DrawOp::Fill(path, _)) => inspect(path.length(), content="0")
  _ => inspect(false, content="true")
}
```

The planner should reuse the repository's actual helper/constructor patterns rather than introduce this sketch verbatim. [VERIFIED: modules/mb-svg/svg/svg_test.mbt; modules/mb-svg/svg/geometry_wbtest.mbt; modules/mb-svg/svg/lower_wbtest.mbt]

### Pattern 2: Compatibility sentinels stay independent

**What:** Keep `scale(0)`, valid root viewBox/default behavior, and RFC 0008 group/element opacity controls as positive regressions beside the negative parity matrix. [VERIFIED: 96-CONTEXT.md; modules/mb-svg/svg/svg_test.mbt; modules/mb-svg/svg/portable_qualification_wbtest.mbt]

**When to use:** Run them in the same all-target package command so a failure means observable portability/compatibility drift, not a machine-specific timing difference. [VERIFIED: modules/mb-svg/moon.mod.json; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]

### Anti-Patterns to Avoid

- **Treating total-lowerer output as parser success:** an invalid manually constructed scene may produce empty paths or an identity map by contract; it is not evidence that parser admission succeeded. [VERIFIED: modules/mb-svg/svg/lower.mbt; 96-CONTEXT.md]
- **Asserting only `Err(_)`:** assert `Data`, the existing error code, `operation == Some("svg")`, and exact numeric context to preserve the established structured-error contract. [VERIFIED: modules/mb-svg/svg/svg_test.mbt]
- **Cross-target timing or source-search tests:** they neither prove public semantics nor satisfy D-03/D-04. [VERIFIED: 96-CONTEXT.md]
- **Deleting superseded helper blocks as part of qualification:** Phase 95 recorded the unreachable helpers in `scene.mbt` and `lower.mbt` as non-blocking maintenance debt; leave them untouched unless they prevent the semantic proof. [VERIFIED: 95-VERIFICATION.md; modules/mb-svg/svg/scene.mbt]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Numeric-boundary oracle | A second test-only arithmetic implementation | The existing `checked_*` Result-returning geometry seam. | A duplicate oracle can drift with production semantics and recreate the very disagreement this phase must detect. [VERIFIED: modules/mb-svg/svg/geometry.mbt; 96-CONTEXT.md] |
| Parser-error assertions | A new error wrapper or string matcher | `assert_public_numeric_error` and `CoreError` accessors. | Existing tests already assert category, code, operation, and context. [VERIFIED: modules/mb-svg/svg/svg_test.mbt] |
| Manual-invalid recovery | A new `Result`-returning public lower API | Existing identity/empty private total adapters plus DrawOp assertions. | D-02 requires total lowering to remain a distinct compatibility behavior. [VERIFIED: 96-CONTEXT.md; modules/mb-svg/svg/lower.mbt] |
| Cross-target driver | Per-target scripts or timing harness | `moon test modules/mb-svg/svg --target all --frozen`. | Moon documents that `all` selects wasm, wasm-gc, js, and native; the module declares the same support set. [VERIFIED: modules/mb-svg/moon.mod.json; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |

**Key insight:** The parity proof is not two independently reimplemented formulas agreeing; it is three semantic observations proving that source parsing fails closed, the private checked fact reports the same boundary failure, and the total lowerer uses only its explicitly allowed manual-value recovery. [VERIFIED: 96-CONTEXT.md; modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt]

## Common Pitfalls

### Pitfall 1: Confusing parser rejection with lowerer fallback

**What goes wrong:** A test builds an invalid `SceneNode`, sees a `DrawingList`, and incorrectly concludes unsafe SVG has been accepted. [VERIFIED: modules/mb-svg/svg/lower.mbt]

**Why it happens:** `lower_to_drawing_list` is intentionally total, while `parse_svg` is the only source-publication boundary. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt]

**How to avoid:** Label manual scenes explicitly, assert their identity/empty-path sentinel, and test parser fixtures separately as structured `Err` outcomes. [VERIFIED: modules/mb-svg/svg/lower_wbtest.mbt; modules/mb-svg/svg/svg_test.mbt]

**Warning signs:** A negative test calls `lower_to_drawing_list(parse_svg(source).unwrap())`, or checks only list length after an unsafe source fixture. [VERIFIED: modules/mb-svg/svg/svg_test.mbt; modules/mb-svg/svg/lower_wbtest.mbt]

### Pitfall 2: Missing a geometry family while claiming parity

**What goes wrong:** The suite covers transforms and rectangles but not viewBox, sampled ellipse extrema, point lists, or CanvasPath control/end points. [VERIFIED: modules/mb-svg/svg/geometry.mbt]

**Why it happens:** The shared seam exposes different fact constructors for affine composition, root mapping, primitive generation, and path traversal. [VERIFIED: modules/mb-svg/svg/geometry.mbt]

**How to avoid:** Keep the matrix row-per-family and pair it with `geometry_wbtest`'s direct primitive/path controls. [VERIFIED: modules/mb-svg/svg/geometry_wbtest.mbt]

**Warning signs:** A new parity test has no case for root mapping, polyline/polygon, or CanvasPath. [VERIFIED: modules/mb-svg/svg/geometry.mbt]

### Pitfall 3: Regressing valid compatibility while hardening failures

**What goes wrong:** A broad rejection change rejects finite `scale(0)`, changes viewBox/default output, or changes RFC 0008 layer ordering. [VERIFIED: 96-CONTEXT.md]

**Why it happens:** Negative fixtures alone cannot protect allowed singular-but-finite transforms or operation ordering. [VERIFIED: modules/mb-svg/svg/svg_test.mbt; modules/mb-svg/svg/portable_qualification_wbtest.mbt]

**How to avoid:** Preserve explicit positive assertions for `scale(0)`, the compact viewBox/default scene, group/element `PushLayer`/`PopLayer` order, and semantic raster pixels. [VERIFIED: modules/mb-svg/svg/svg_test.mbt; modules/mb-svg/svg/portable_qualification_wbtest.mbt; docs/rfcs/0008-mb-canvas-layer.md]

**Warning signs:** A target run only exercises errors, or layer assertions are reduced to a nonzero DrawingList length. [VERIFIED: modules/mb-svg/svg/portable_qualification_wbtest.mbt]

## Code Examples

### Four-target qualification command

```powershell
moon test modules/mb-svg/svg --target all --frozen
```

This is the phase gate: it runs the test package against wasm, wasm-gc, js, and native, with dependency synchronization disabled. [VERIFIED: local `moon test --help`; modules/mb-svg/moon.mod.json; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]

### Manual fallback distinction

```moonbit
// Existing pattern: lower_wbtest.mbt
let first = lower_to_drawing_list(invalid_scene)
let second = lower_to_drawing_list(invalid_scene)
inspect((first.length(), second.length()), content="(8, 8)")
// Verify empty geometry and preserved PushLayer/Fill/Stroke/PopLayer order.
```

This is a lowerer-compatibility test only; it must remain distinct from `parse_svg(source) == Err(error)`. [VERIFIED: modules/mb-svg/svg/lower_wbtest.mbt; 96-CONTEXT.md]

## State of the Art

| Old approach | Current approach | When Changed | Impact |
|---|---|---|---|
| Parser preflight and lowerer had duplicate private geometry arithmetic. | Live parser preflight and total lowerer use `geometry.mbt` checked facts; obsolete private helper blocks remain unreachable. | Phase 95, verified 2026-07-25. | Phase 96 can test semantic observations instead of comparing duplicated implementations. [VERIFIED: 95-VERIFICATION.md; modules/mb-svg/svg/geometry.mbt; modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt] |

**Deprecated/outdated:**

- Superseded private helper blocks in `scene.mbt` and `lower.mbt`: retain as out-of-scope cleanup unless they obstruct the proof; live callers already use the shared seam. [VERIFIED: 95-VERIFICATION.md]

## Assumptions Log

All claims in this research were verified or cited — no user confirmation needed.

## Open Questions (RESOLVED)

1. **RESOLVED — no blocking implementation question.**
   - What we know: existing test homes cover public parser errors, private checked facts, total-lowerer fallback, and opacity/layer semantic raster behavior. [VERIFIED: modules/mb-svg/svg/*test.mbt]
   - **RESOLVED:** the historical canonical-reference filename in `96-CONTEXT.md` does not match the repository file; the authoritative repository path is `docs/rfcs/0008-mb-canvas-layer.md`. [VERIFIED: 96-CONTEXT.md; docs/rfcs/0008-mb-canvas-layer.md]
   - Resolution: cite and preserve the actual RFC 0008 file; do not rename it in this phase. [VERIFIED: docs/rfcs/0008-mb-canvas-layer.md; 96-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `moon` toolchain | Compile/run all portable SVG controls | ✓ | `moon 0.1.20260713`, `moonc v0.10.4+2cc641edf`, `moonrun 0.1.20260713` | — [VERIFIED: local `moon --version`] |
| Four declared package targets | SVGUNI-03 gate | ✓ | wasm, wasm-gc, js, native | — [VERIFIED: modules/mb-svg/moon.mod.json; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html] |

**Missing dependencies with no fallback:** None. [VERIFIED: local `moon --version`; modules/mb-svg/moon.mod.json]

**Missing dependencies with fallback:** None. [VERIFIED: local `moon --version`; modules/mb-svg/moon.mod.json]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | SVG parser/lowerer has no authentication boundary in this phase. [VERIFIED: 96-CONTEXT.md; modules/mb-svg/svg/scene.mbt] |
| V3 Session Management | No | SVG parser/lowerer has no session state in this phase. [VERIFIED: 96-CONTEXT.md; modules/mb-svg/svg/scene.mbt] |
| V4 Access Control | No | No authorization decision or protected resource is introduced. [VERIFIED: 96-CONTEXT.md] |
| V5 Validation, Sanitization and Encoding | Yes | Positive numeric admission and fail-closed `CoreError` checks before `SceneNode` publication; the semantic matrix exercises source and derived geometry. [VERIFIED: modules/mb-svg/svg/svg.mbt; modules/mb-svg/svg/scene.mbt; CITED: https://owasp.org/www-project-application-security-verification-standard/] |
| V6 Cryptography | No | No cryptographic operation or secret is involved. [VERIFIED: 96-CONTEXT.md] |

### Known Threat Patterns for MoonBit SVG parsing

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Oversized, non-finite, malformed, or out-of-range numeric scalar | Tampering / Denial of Service | Preserve parser-side source admission and assert exact structured rejection before `SceneNode` publication. [VERIFIED: modules/mb-svg/svg/svg.mbt; modules/mb-svg/svg/svg_test.mbt] |
| Source-valid values whose transform/viewBox/path arithmetic overflows | Tampering / Denial of Service | Route preflight through `checked_*` facts and assert `svg-numeric-derived` before publication. [VERIFIED: modules/mb-svg/svg/geometry.mbt; modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/svg_test.mbt] |
| Semantic drift between preflight and total lowering | Tampering | Add semantic seam matrix; use error facts for parser and identity/empty DrawOp sentinels for manual-invalid lowering. [VERIFIED: 96-CONTEXT.md; modules/mb-svg/svg/lower.mbt] |
| Excessive opacity-layer nesting during rasterization | Denial of Service | Preserve RFC 0008's bounded layer depth and existing 16-success/17-failure portable semantic controls. [VERIFIED: docs/rfcs/0008-mb-canvas-layer.md; modules/mb-svg/svg/portable_qualification_wbtest.mbt] |

## Sources

### Primary (HIGH confidence)

- Repository source: `modules/mb-svg/svg/scene.mbt`, `geometry.mbt`, and `lower.mbt` — publication boundary, shared seam, and total-recovery behavior. [VERIFIED: codebase grep]
- Repository tests: `svg_test.mbt`, `geometry_wbtest.mbt`, `lower_wbtest.mbt`, and `portable_qualification_wbtest.mbt` — existing test patterns and target-neutral semantic observations. [VERIFIED: codebase grep]
- `95-VERIFICATION.md` — Phase 95 verified behavior and explicit non-blocking legacy-helper cleanup note. [VERIFIED: codebase grep]
- `docs/rfcs/0008-mb-canvas-layer.md` — group/element opacity and bounded-layer semantics. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- [MoonBit command-line documentation](https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html) — `moon test` target/frozen options. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]
- [MoonBit package configuration](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html) — `--target all` target expansion. [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/) — current ASVS release and versioned category reference. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — installed toolchain, module target declaration, and official MoonBit documentation agree. [VERIFIED: local `moon --version`; modules/mb-svg/moon.mod.json; CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html]
- Architecture: HIGH — parser and lowerer source directly show their distinct public-boundary and total-recovery behavior. [VERIFIED: modules/mb-svg/svg/scene.mbt; modules/mb-svg/svg/lower.mbt]
- Pitfalls: HIGH — each pitfall is represented in existing source, test controls, or locked phase decisions. [VERIFIED: 96-CONTEXT.md; modules/mb-svg/svg/*test.mbt]

**Research date:** 2026-07-26
**Valid until:** 2026-08-25 (stable repository-local qualification plan; recheck Moon toolchain command semantics before a later execution date). [CITED: https://docs.moonbitlang.com/en/latest/toolchain/moon/commands.html]
