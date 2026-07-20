# Phase 15: Public QOI Processing Example - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver one small runnable portable MoonBit example that decodes a fixed QOI image, applies one existing public image operation, encodes QOI again, and prints deterministic evidence on js, wasm, wasm-gc, and native. Document how to run it. Do not add new image APIs, registry behavior, FFI, streaming, benchmarks, release automation, or a CLI host adapter.

</domain>

<decisions>
## Implementation Decisions

### Public workflow shape
- **D-01:** Add a separate `examples/qoi-portable` executable rather than modifying the PPM example. It will import only the public core/image packages and run entirely in memory.
- **D-02:** Keep the processing step deliberately focused: decode a fixed valid QOI source, call the existing `flip_horizontal` operation, then encode with `QoiEncoder`. Assert dimensions, transformed pixel positions, bytes read/written, diagnostics, and exact canonical output bytes before printing success.
- **D-03:** Use explicit fresh budgets, codec limits, reader, writer, options, and diagnostics at every public boundary, following `examples/ppm-portable`; the example must not depend on private helpers, GUI state, FFI, or host filesystem input.

### Evidence and documentation
- **D-04:** Print one stable, human-readable status line only after all assertions pass. Record its output bytes/rolling digest in the example and verify the same required markers by actually running all four portable targets.
- **D-05:** Add the QOI example to the public image README alongside the existing portable PPM example, with the four exact frozen run commands.

### the agent's Discretion
- Select the smallest QOI input and output that make the horizontal transform visibly testable, and choose the precise digest/marker wording after running it on all targets.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and phase scope
- `.planning/ROADMAP.md` — Phase 15 goal, QOI-06, and success criteria.
- `.planning/REQUIREMENTS.md` — QOI-06 acceptance boundary and release-automation exclusion.
- `.planning/PROJECT.md` — portable MoonBit-native and no-FFI constraints.
- `.planning/phases/14-canonical-qoi-encode-and-four-target-vectors/14-CONTEXT.md` — encoder boundaries and canonical-byte policy.
- `.planning/phases/14-canonical-qoi-encode-and-four-target-vectors/14-01-SUMMARY.md` — verified public encoder/fixture outcome.

### Consumer and public API patterns
- `examples/ppm-portable/moon.mod.json` — portable example module manifest pattern.
- `examples/ppm-portable/main/moon.pkg` — public import and executable package pattern.
- `examples/ppm-portable/main/main.mbt` — explicit public Reader/Writer/budget/diagnostic and deterministic-evidence pattern.
- `modules/mb-image/qoi/qoi.mbt` — public QOI decoder and encoder values.
- `modules/mb-image/codec/contracts.mbt` — public codec traits/options/results/limits.
- `modules/mb-image/ops/copy_flip.mbt` — existing public horizontal-flip operation.
- `modules/mb-image/README.mbt.md` — documented public examples and four-target run command convention.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `QoiDecoder` and `QoiEncoder` implement the public codec traits without a registry.
- `@ops.flip_horizontal` is a portable image operation that makes transformed pixel order directly observable.
- `MemoryReader`, `MemoryWriter`, `CodecLimits`, `Budget`, and `Diagnostics` are sufficient for a GUI-free all-target example.

### Established Patterns
- Portable example executables assert every observable before their single status line.
- The public README lists each example and supplies the same frozen commands for js, wasm, wasm-gc, and native.

### Integration Points
- New `examples/qoi-portable/` module and a constrained update to `modules/mb-image/README.mbt.md` connect the verified codec to a user-facing runnable consumer.

</code_context>

<specifics>
## Specific Ideas

The user explicitly prioritizes implementation and tests. This is a compact public-consumer proof, not a release or automation project.

</specifics>

<deferred>
## Deferred Ideas

- Multi-operation public pipeline, external files/CLI flags, streaming, registry discovery, benchmarks, FFI, and release automation remain out of this phase.

</deferred>

---

*Phase: 15-Public QOI Processing Example*
*Context gathered: 2026-07-20*
