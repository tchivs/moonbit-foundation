# Phase 18: Resumable QOI Buffer Encode - Context

**Gathered:** 2026-07-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a separate stateful QOI encoder that preflights a compatible `ImageView`
once and drains its existing canonical representation into arbitrary
caller-owned mutable byte leases. Existing eager encoder traits and writer
semantics remain unchanged.

</domain>

<decisions>
## Implementation Decisions

### Output contract
- **D-01:** Expose a separate `QoiStreamEncoder` and a per-call result carrying
  bytes written plus `NeedOutput`, `Finished`, or typed `Failed` outcome.
- **D-02:** `pull` never retains a caller mutable lease. It reports zero bytes
  for a zero-capacity destination and only reports `Finished` after the final
  end-marker byte is copied.
- **D-03:** Completion/errors are sticky; later `pull` calls report zero written
  with a deterministic terminal-state error.

### Canonicality and resource safety
- **D-04:** Construction repeats eager validation, exact chunk-length preflight,
  limit ordering, metadata setup, and one work-budget charge before any output
  byte can become visible.
- **D-05:** Generate every header, token, deferred run, and marker into private
  pending storage before draining it. Advance codec state on token generation
  and only advance pending offset/total on copied bytes.
- **D-06:** Every capacity schedule, including zero and one byte, must produce
  the exact eager canonical bytes with no duplicate, missing, or reordered data.

### Source lifetime
- **D-07:** The encoder is zero-copy and retains an immutable `ImageView`; its
  caller contract requires the backing image to remain unchanged from `new()`
  through terminal state. Do not add a snapshot, lock, or new allocation path.

### the agent's Discretion
- Exact public names and counter accessors should match the Phase 17 stream
  result style and existing QOI naming, while preserving all decisions above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` §Phase 18 — goal and success criteria.
- `.planning/REQUIREMENTS.md` §Streaming Encode — QSTR-04 and QSTR-05.
- `.planning/PROJECT.md` §Current Milestone: v0.5 QOI Streaming I/O — scope exclusions.

### Existing implementation and contracts
- `modules/mb-image/qoi/encode.mbt` — canonical token selection and eager preflight order.
- `modules/mb-image/qoi/qoi.mbt` — QOI public package surface and Phase 17 stream result conventions.
- `modules/mb-image/qoi/stream_decode.mbt` — sticky state and public streaming API pattern.
- `modules/mb-image/qoi/encode_test.mbt` and `modules/mb-image/qoi/encode_wbtest.mbt` — canonical, budget, and token vector evidence.
- `modules/mb-core/bytes/views.mbt` — callback-scoped mutable byte lease rules.
- `modules/mb-image/storage/views.mbt` and `modules/mb-image/storage/owned_image.mbt` — retained image-view lifetime and mutation semantics.
- `modules/mb-image/codec/contracts.mbt` — `CodecLimits`, `EncodeOptions`, `EncodeResult`, and eager compatibility traits.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Eager `qoi_encode_source`, `qoi_chunk_length`, header generation, pixel access,
  signed-delta, hash, and canonical token rules provide the exact stream source.
- Existing generated encode vectors exercise every QOI token family and canonical bytes.
- Phase 17 supplies established public result, terminal-state, inventory, and
  four-target testing conventions.

### Established Patterns
- Eager encoder rejects capability/limit/budget/setup failures before writer output.
- Mutable byte leases and mutable image views are callback-scoped and cannot be retained.
- Public QOI remains pure MoonBit on js, wasm, wasm-gc, and native.

### Integration Points
- New source and tests belong in `modules/mb-image/qoi` beside stream decode.
- Exact QOI policy assertions in `policy/foundation.json` and
  `scripts/quality/Assert-Policy.ps1` must be extended in lockstep.

</code_context>

<specifics>
## Specific Ideas

The source view is immutable through this API but callers must keep its backing
unchanged until termination; this matches the zero-copy scope and avoids a
hidden snapshot/allocation contract.

</specifics>

<deferred>
## Deferred Ideas

- Public streaming decode-process-encode example and final hostile schedules: Phase 19.
- Snapshotting or locking mutable source backing: deferred until a broader image concurrency contract exists.
- FFI, PNG/DEFLATE, release automation, and registry work remain out of scope.

</deferred>

---

*Phase: 18-Resumable QOI Buffer Encode*
*Context gathered: 2026-07-20*
