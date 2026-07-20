# Phase 11: Portable Processing Pipeline Evidence - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the completed portable raster API through one public PPM decode-transform-encode example, four-target behavioral evidence, and a reproducible resize-and-composite benchmark baseline. Phase 11 validates and documents the Phase 9/10 API; it does not add new processing algorithms or release automation.

</domain>

<decisions>
## Implementation Decisions

### Pipeline evidence
- **D-01:** The public example must use the real strict PPM decoder and encoder, and compose at least one Phase 9 geometry operation with one Phase 10 raster operation in one deterministic in-memory pipeline.
- **D-02:** The example uses only documented, representable straight RGBA8/sRGB metadata and compatible inputs so it proves successful normal use rather than a synthetic internal shortcut.
- **D-03:** Expected encoded bytes or digest plus semantic pixel assertions make the example deterministic across js, wasm, wasm-gc, and native.

### Test and benchmark evidence
- **D-04:** Public behavior and adversarial tests must run on all four supported targets and cover the composed processing pipeline plus at least one failure boundary.
- **D-05:** Benchmark workloads are explicit, reproducible and local: declared image dimensions, operation sequence, iteration/warm-up policy, toolchain/target, and recorded baseline. No performance marketing claims are added.
- **D-06:** Benchmarking must not require registry, credentials, GUI state, hosted workflows, or release scripts.

### the agent's Discretion
- Reuse or extend the portable PPM example versus adding a narrowly named processing example according to the existing examples layout.
- Select the smallest benchmark harness and output format consistent with existing `benchmarks/` conventions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/PROJECT.md` — v0.3 code-first scope.
- `.planning/REQUIREMENTS.md` — INTEG-01, INTEG-02, INTEG-03.
- `.planning/ROADMAP.md` — Phase 11 success criteria.
- `.planning/phases/09-checked-image-geometry-and-diagnostics/09-VERIFICATION.md` — verified geometry API.
- `.planning/phases/10-alpha-correct-pixel-processing/10-VERIFICATION.md` — verified raster-processing API.

### Existing pipeline and benchmark assets
- `examples/ppm-portable/main/main.mbt` — current portable PPM in-memory decode-transform-encode entry point.
- `examples/ppm-native-cli/main/adapter.mbt` — injected native example boundary, not required for this portable pipeline.
- `modules/mb-image/README.mbt.md` — executable package documentation and target commands.
- `benchmarks/` — current benchmark layout and workload conventions.
- `artifacts/benchmarks/` — prior recorded local evidence format, if reusable.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Strict PPM decoder/encoder and current portable example provide an already-tested end-to-end codec path.
- Phase 9 `crop`, rotations, and resize plus Phase 10 `composite_source_over`, `grayscale`, and `box_blur` are the real operations to demonstrate.

### Established Patterns
- Four-target test commands and executable `.mbt.md` examples are the project evidence standard.
- Benchmarks must declare workload and retain a reproducible baseline rather than claim a generic performance result.

### Integration Points
- Example changes belong under `examples/` and corresponding package documentation; benchmark changes belong under `benchmarks/` and its recorded artifact path.

</code_context>

<specifics>
## Specific Ideas

The final milestone phase should make the new code easy to run and verify by a MoonBit library user, not add another layer of release automation.

</specifics>

<deferred>
## Deferred Ideas

- New codecs, GPU acceleration, optimized kernels, registry publication, and GUI workflows remain outside Phase 11.

</deferred>

---

*Phase: 11-Portable Processing Pipeline Evidence*
*Context gathered: 2026-07-20*
