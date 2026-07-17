# Phase 2: Bounded Core Primitives - Context

**Gathered:** 2026-07-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement the portable `mb-core` contract spine for checked numeric and range operations, owned byte storage and validated views, backend-neutral and bounded in-memory I/O, structured errors and diagnostics, shared resource budgets, and explicitly injected host capabilities. The phase proves safe processing of untrusted binary data on every declared portable target; it does not add color, image, codec, filesystem-policy, or application concepts.

</domain>

<decisions>
## Implementation Decisions

### Checked numeric and range semantics
- **D-01:** All caller-controlled overflow, underflow, invalid alignment, invalid dimension, invalid offset/range, and narrowing failures return structured checked results before any access, allocation, or work. Public checked operations never silently wrap, saturate, or panic.
- **D-02:** Ranges are half-open `[start, end)` and canonicalized from checked `start + length`. Empty ranges and zero-length operations are valid. Dimensions and logical sizes are non-negative; alignment must be a non-zero power of two.
- **D-03:** Cross-backend behavior is defined by explicit-width logical quantities and checked conversion into backend allocation/index types. A failed conversion is an error, never a truncation.

### Owned bytes and validated views
- **D-04:** Public storage and view representations are opaque. Immutable and mutable views retain their backing storage and carry a validated start/length window so a view cannot outlive or escape its allocation.
- **D-05:** Subviews are zero-copy when valid, use the same half-open semantics as ranges, and fail before access when the requested window is invalid.
- **D-06:** v0.1 does not expose APIs that manufacture simultaneous overlapping mutable aliases. Mutable access is exclusive by construction, with explicit non-overlapping split operations allowed only when disjointness is validated. Immutable aliases may coexist.
- **D-07:** Owned storage construction distinguishes allocation failure or budget rejection from range errors. Conversion from immutable external bytes may copy unless ownership is explicitly transferred through a documented API.

### Stream outcomes, bounded I/O, and seeking
- **D-08:** Reader and writer contracts explicitly distinguish successful progress, end-of-stream, and failure. Partial progress is normal and observable; a failure may report already completed progress without losing it.
- **D-09:** Exact helpers repeatedly consume partial progress, reject no-progress loops, and report unexpected end-of-stream with requested and completed counts. Zero-length operations succeed immediately without touching the backend.
- **D-10:** Seeking is a separate capability, not a mandatory method on every reader or writer. Origins and positions use checked arithmetic; unsupported seeking is represented by capability absence rather than a routine runtime failure.
- **D-11:** Bounded sub-readers and in-memory readers/writers enforce their own logical window regardless of underlying seekability. They never read, write, or seek outside the declared window and do not require filesystem access or full-input buffering.

### Errors and diagnostics
- **D-12:** Machine-readable failures use stable category/code pairs with typed context fields and optional source offsets. Human-readable text is deterministically rendered from structured data; consumers must not parse prose to recover semantics.
- **D-13:** Error and diagnostic rendering has a fixed field order, stable escaping, locale-independent numeric formatting, and no ambient path, clock, or backend exception text. Non-fatal diagnostics preserve encounter order.
- **D-14:** Backend/host failures are mapped at the adapter boundary into portable codes plus bounded context; foreign exception names and platform-specific numeric codes are not public portable semantics.

### Resource budgets and host capabilities
- **D-15:** Limits cover bytes, allocation count/size, dimensions/pixels, nesting depth, and abstract work units. Budget charges occur before prohibited allocation or work, and rejected charges do not partially consume allowance.
- **D-16:** Nested operations use shared hierarchical budget state so child scopes cannot reset or bypass a parent's remaining allowance. Enter/leave operations for nesting are balanced and deterministic on all exit paths.
- **D-17:** Host access is exposed through small, independently optional capability interfaces such as files/resources, logging/diagnostics, clock, cancellation, and resource resolution. There is no ambient fallback and no mandatory all-capabilities singleton.
- **D-18:** Phase 2 supplies portable in-memory implementations and contract/conformance doubles. Concrete native adapters remain isolated leaf packages and are implemented only where needed by a later phase or separately accepted scope.

### the agent's Discretion
- Exact MoonBit type names, package decomposition, internal representation, and error-code spelling are left to research and planning, provided the public behavior above remains explicit, acyclic, portable, and machine-testable.
- The planner may split delivery into independently verifiable packages/waves and may add property/adversarial tests beyond the minimum acceptance matrix.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 2 goal, dependency, requirements, and five success criteria.
- `.planning/REQUIREMENTS.md` — normative CORE-01 through CORE-08 user-facing requirements.
- `.planning/PROJECT.md` — project constraints, active milestone boundary, and out-of-scope layers.

### Architecture and portability contract
- `docs/rfcs/0001-moonbit-native-foundation.md` — accepted ownership boundary for `mb-core`, dependency direction, portability, explicit capabilities, and v0.1 scope.
- `.planning/research/ARCHITECTURE.md` — recommended `mb-core` package spine, bounded pipeline, host-adapter direction, and dependency anti-patterns.
- `.planning/research/STACK.md` — pinned MoonBit toolchain, four required targets, testing conventions, and narrow FFI rules.
- `docs/policies/targets.md` — required portable target declaration and native-leaf isolation policy.
- `docs/policies/api-stability.md` — candidate API expectations and requirement that this phase decide resource-budget semantics.

### Existing module surface
- `modules/mb-core/README.mbt.md` — current candidate module boundary and Phase 1 promises that Phase 2 replaces with real public contracts.
- `modules/mb-core/moon.mod.json` — independently publishable module identity and supported-target metadata.
- `modules/mb-core/moon.pkg` — current package-level target declaration to preserve or deliberately replace during package decomposition.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-core/` already provides the independently versioned module, changelog, literate README, portable target metadata, and a private scaffold test that can be replaced incrementally by public contract packages.
- `scripts/quality.ps1` and `scripts/quality/Invoke-MoonQuality.ps1` provide the root required lane and four-target execution path that Phase 2 tests must enter.
- `policy/foundation.json` is the machine-owned source for module identity, dependency direction, target support, and publication state.

### Established Patterns
- Public portable packages explicitly declare `+js+wasm+wasm-gc+native`, use black-box public API tests plus white-box invariant tests, and treat LLVM as experimental/non-blocking.
- Machine-verifiable metadata and adversarial evidence are preferred over prose-only promises; generated interfaces and package contents are checked from the repository root.
- Modules publish independently and dependencies point inward: `mb-core` has no MNF dependency, while later `mb-color` and `mb-image` consume it.

### Integration Points
- New public packages replace the Phase 1 private `scaffold.mbt` proof while preserving the `moonbit-foundation/mb-core` module and candidate `0.1.0` lifecycle.
- New tests and documentation must be reachable through the existing root quality workflow on all four required targets.
- Phase 3 consumes checked numeric/error contracts; Phase 4 consumes byte views, I/O, budgets, and capability contracts; Phase 5 exercises them through the bounded reference codec.

</code_context>

<specifics>
## Specific Ideas

- Prefer opaque types and constructors that make invalid state unrepresentable over public fields plus repeated defensive checks.
- Keep low-level errors compact and stable enough for CLI, Agent, MCP, and snapshot consumers, while retaining typed details for programmatic handling.
- Treat no-progress streams, shared-budget bypass, overlapping mutable views, and backend-width truncation as explicit adversarial test categories.

</specifics>

<deferred>
## Deferred Ideas

- Concrete native filesystem, clock, process, or networking adapters beyond the minimum contract surface are deferred until a consuming phase needs them.
- Image-specific layout/stride rules and detailed pixel-limit policy belong to Phase 4; Phase 2 supplies only generic checked dimensions and budget counters.
- Codec-specific decompression ratios, registry behavior, and PPM subset rules belong to Phase 5.

</deferred>

---

*Phase: 02-bounded-core-primitives*
*Context gathered: 2026-07-16*
