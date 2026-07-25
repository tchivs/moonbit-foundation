# Phase 94: SVG Benchmark Evidence - Context

**Gathered:** 2026-07-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn the existing `mb-svg` path parse, transform composition, and parse-to-lower benchmarks into correctness-gated, reproducible workloads. Qualify that each workload builds and runs on all portable targets, and record a native-release baseline whose seven captures can be compared only with like-for-like future native captures. This phase does not set performance thresholds, compare timings across targets, or change rendering/parser behavior.

</domain>

<decisions>
## Implementation Decisions

### Workload correctness
- **D-01:** Keep exactly three accurately named workload families: path parse, transform composition, and parse-to-lower. Each gets deterministic pre-benchmark assertions for command/count, affine, or drawing-operation facts, so timing can never mask a broken workload. — **Reversibility:** costly — workload identity and correctness digest form the baseline comparison contract.
- **D-02:** Use existing MoonBit `*_bench.mbt` / `@bench.T` conventions and test-local deterministic builders; do not add a benchmark framework or external package.

### Target policy
- **D-03:** Build and run correctness gates on js, wasm, wasm-gc, and native. Record no cross-target timing table, ranking, or claimed performance comparison; only native release captures are baseline evidence.

### Native baseline record
- **D-04:** Store a documented native release baseline with exact command, corpus + correctness digests, MoonBit toolchain and host facts, warmup protocol, and seven individual captures plus summary. Capture the environment honestly; a missing host fact must be marked unavailable rather than invented. — **Reversibility:** costly — the baseline becomes the durable like-for-like comparison point.

### the agent's Discretion
Choose the benchmark document location, command formatting, digest procedure, host facts available on the current machine, and stable correctness assertions, provided the three workloads remain fixed and the record remains reproducible.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` §Phase 94 — SVGPR-04 goal and success criteria.
- `.planning/REQUIREMENTS.md` §SVGPR-04 — benchmark evidence requirement.
- `.planning/phases/93-svg-compatibility-portable-qualification/93-VERIFICATION.md` — portable compatibility baseline before measurement.
- `docs/rfcs/0002-mb-svg.md` §11.4 — declared SVG workload and baseline expectations.
- `modules/mb-svg/svg/svg_bench.mbt` — existing three workload implementations and MoonBit benchmark convention.
- `docs/policies/toolchain.md` and `policy/foundation.json` — exact toolchain policy source.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `modules/mb-svg/svg/svg_bench.mbt`: the three existing named workloads.
- `modules/mb-svg/svg/path_data.mbt`, `transform.mbt`, and `lower.mbt`: APIs that support pre-benchmark correctness assertions.
- `modules/mb-svg/svg/portable_qualification_wbtest.mbt`: four-target deterministic test structure.

### Established Patterns
- MoonBit benchmark tests use `@bench.T` and `b.bench`; results are sunk with `keep` to prevent elimination.
- All production targets are validated with `moon test ... --target all --frozen`; raw timing is not portable correctness evidence.

### Integration Points
- Benchmark correctness gates live beside `svg_bench.mbt`; the baseline document records a native release command and immutable workload/digest facts.

</code_context>

<specifics>
## Specific Ideas

Auto-selected evidence policy: correctness first, four-target runnable qualification second, native-only seven-capture timing record last; never make cross-target timing claims.

</specifics>

<deferred>
## Deferred Ideas

None — performance thresholds, host fleet comparison, CI performance gating, native acceleration, and new SVG functionality are outside v0.30.

</deferred>

---

*Phase: 94-SVG Benchmark Evidence*
*Context gathered: 2026-07-26*
