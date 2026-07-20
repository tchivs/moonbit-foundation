# Phase 17: Resumable QOI Chunk Decode - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a public, stateful QOI decoder that accepts caller-owned byte chunks and an
explicit completion signal. It returns exactly one complete owned image or a
typed sticky terminal error, while the eager codec traits and `@io.Reader` EOF
semantics remain unchanged.

</domain>

<decisions>
## Implementation Decisions

### Chunk and completion contract
- **D-01:** Expose a separate `QoiStreamDecoder` in `tchivs/mb-image/qoi`; do
  not add streaming methods to `@codec.ImageDecoder` or change `@io.Reader`.
- **D-02:** `push(ByteView)` consumes only reported bytes from that supplied
  chunk and returns an explicit non-terminal input-needed result. It retains no
  caller byte view.
- **D-03:** `finish()` is the sole EOF declaration. Strict decode validates the
  complete QOI marker and rejects trailing data only after that declaration.

### State, safety, and terminal behavior
- **D-04:** Header and resource preflight complete before the sole owned-image
  allocation; a partial image is never exposed to callers.
- **D-05:** Preserve existing limits, budget charging, diagnostics, descriptor,
  and total byte accounting semantics. Budget/storage charges are not refunded
  after a successfully preflighted allocation.
- **D-06:** Completion and errors are sticky. Any later `push` or `finish`
  produces a deterministic typed state error.
- **D-07:** The decoder state stores copied token/parser data only; it reacquires
  a mutable image view per pump rather than retaining a scoped mutable lease.

### Conformance depth
- **D-08:** Phase 17 covers split points in every header/opcode/end-marker
  boundary, incomplete finish states, run overrun, marker/trailing errors,
  limits/budgets, and generated-vector pixel equivalence. Phase 19 owns the
  final public example and full cross-target evidence lane.

### the agent's Discretion
- Exact public enum names, byte-count field shapes, and private state layout
  should follow the existing `codec`/`qoi` naming and MoonBit interface patterns
  while preserving the decisions above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` §Phase 17 — locked goal and observable success criteria.
- `.planning/REQUIREMENTS.md` §Streaming Decode — QSTR-01 through QSTR-03.
- `.planning/PROJECT.md` §Current Milestone: v0.5 QOI Streaming I/O — scope and exclusions.

### Existing portable contracts
- `modules/mb-core/io/traits.mbt` — forward-only Reader/Writer terminal EOF semantics.
- `modules/mb-core/io/exact.mbt` — exact I/O error/progress behavior that streaming must not repurpose.
- `modules/mb-image/codec/contracts.mbt` — limits, options, results, and eager compatibility traits.
- `modules/mb-image/qoi/decode.mbt` — QOI header, token, limits, diagnostics, and strict-stream behavior.
- `modules/mb-image/qoi/qoi.mbt` — public package surface and shared QOI helpers.
- `modules/mb-image/storage/owned_image.mbt` — owned-image and callback-scoped mutable-view rules.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `@io.MemoryReader`, `MemoryWriter`, bounded wrappers, and scripted I/O tests provide deterministic chunk/error adapters.
- Existing QOI header, pixel, hash, descriptor, metadata, checked-limit, and diagnostics helpers are reusable private primitives.
- `CodecLimits`, `DecodeOptions`, `DecodeResult`, `Budget`, and `Diagnostics` already define the required policy surface.

### Established Patterns
- Eager QOI validates dimensions/limits before `OwnedImage::new_operation` and returns typed deterministic failures.
- `MutImageView` is callback-scoped, so resumable state may own the image but must reacquire its mutable view per pump.
- Public packages support js, wasm, wasm-gc, and native without FFI.

### Integration Points
- New public streaming types belong in `modules/mb-image/qoi` beside `QoiDecoder`.
- Black-box contract tests belong beside existing QOI decode tests; internal vector/state tests belong beside existing wbtests.

</code_context>

<specifics>
## Specific Ideas

The public contract deliberately models temporary input absence with caller
chunks, not with `Reader::EndOfStream`; this preserves every existing eager
consumer's meaning of EOF.

</specifics>

<deferred>
## Deferred Ideas

- Resumable output draining is Phase 18.
- Public streaming decode-process-encode example and final four-target lane are Phase 19.
- PNG/DEFLATE, FFI, publication/release automation, benchmarks, and partial-image transforms are outside v0.5 Phase 17.

</deferred>

---

*Phase: 17-Resumable QOI Chunk Decode*
*Context gathered: 2026-07-20*
