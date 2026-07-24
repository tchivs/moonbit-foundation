# Phase 87: Hostile Indexed Streaming and Independent Qualification - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Qualify the Phase 86 non-interlaced indexed `Stored`/`FixedOrStored` machine
under hostile caller-buffer schedules and independent wire/decode oracles.
Freeze legacy Indexed1/2/4/8 compatibility bytes, prove sticky lifecycle
failures and accepted-only progress, and run the declared PNG package gate on
native, wasm, wasm-gc, and js. This phase adds evidence and test-local
qualification only; it does not redesign the encoder or add another profile.

</domain>

<decisions>
## Implementation Decisions

### Hostile caller leases
- **D-01:** Use the existing acknowledged-machine test harness and exercise
  zero-capacity, one-byte, and ragged capacities for both a Fixed winner and a
  Stored fallback at each selected depth where practical. Compare only
  accepted bytes to fresh eager output, assert `total_written` advances by the
  accepted count, and verify every rejected sentinel tail remains unchanged.
- **D-02:** Treat released leases, replay-accounting drift, and source-revision
  mismatches as sticky zero-write terminal failures. After `Finished` or
  `Failed`, subsequent pulls must perform zero writes and preserve destination
  contents.

### Independent wire/decode qualification
- **D-03:** Build a test-local parser/oracle from raw eager and collected
  chunk-origin bytes. It must independently validate PNG signature/chunk order,
  IHDR, PLTE, shortest canonical tRNS, IDAT DEFLATE block type, Adler-32,
  per-chunk CRCs, filter-None packed scanlines and zero tails, then invoke the
  public RGB8/RGBA8 decoder for coordinate-level semantic checks. Do not call
  production planning, matcher, packing, frame-facts, or preflight helpers in
  the oracle.
- **D-04:** Keep the corpus compact and deterministic: retain the established
  512-pixel Fixed-winner/Stored-fallback matrix, plus odd/narrow dimensions and
  partial-alpha palettes needed to expose packed tails and RGBA8 decode. Do
  not introduce external compressors, copied source trees, or generated binary
  fixtures without provenance.

### Compatibility and portability gates
- **D-05:** Freeze existing non-interlaced Indexed1/2/4/8 Stored vectors and
  all indexed Adam7 Stored/None vectors byte-for-byte; explicit `Stored` must
  equal the corresponding legacy API. Run the ordinary `png` package test gate
  explicitly for `native`, `wasm`, `wasm-gc`, and `js`, recording named
  commands and failures rather than relying on a filtered test alone.

### the agent's Discretion
- Choose the smallest existing test files/helpers that can host the parser,
  corpus, and hostile schedules without duplicating production logic.
- Select exact target command syntax and skip only a target that is unavailable
  in the pinned local toolchain, recording concrete evidence and preserving the
  other gates.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` — Phase 87 goal, success criteria, and scope guard.
- `.planning/REQUIREMENTS.md` — INDEXCOMP-04 and INDEXCOMP-05 acceptance
  requirements and traceability.
- `.planning/research/v028-INDEXED-PNG-COMPRESSION.md` §Required Evidence and
  Adversarial Tests — verified hostile-schedule, wire, decode, and target-gate
  expectations.

### Prior implementation and qualification contracts
- `.planning/phases/85-indexed-compression-api-and-fixed-wire-contract/85-CONTEXT.md`
  — additive selectors, Stored compatibility, and single bounded producer.
- `.planning/phases/85-indexed-compression-api-and-fixed-wire-contract/85-VERIFICATION.md`
  — shipped API and wire-selection baseline.
- `.planning/phases/86-ancillary-aware-preflight-and-shared-machine-integration/86-CONTEXT.md`
  — selected-frame admission and one-charge boundary.
- `.planning/phases/86-ancillary-aware-preflight-and-shared-machine-integration/86-VERIFICATION.md`
  — verified shared-machine integration and atomic limits.
- `.planning/milestones/v0.27-phases/84-low-bit-indexed-adam7-streaming-qualification/84-CONTEXT.md`
  — existing independent qualification and Adam7 compatibility patterns.

### Production/test seams
- `modules/mb-image/png/stream_encode.mbt` — acknowledged `present` /
  `acknowledge` lifecycle, sticky terminal states, replay validation, and
  indexed constructors.
- `modules/mb-image/png/encode.mbt` — eager selector output and retained
  frame/plan facts.
- `modules/mb-image/png/png.mbt` — indexed source and public compression
  strategy contracts.
- `modules/mb-image/png/stream_encode_test.mbt` — existing hostile lease,
  sentinel, release, and eager-parity harnesses.
- `modules/mb-image/png/png_test.mbt` and `structural_wbtest.mbt` — public
  decode and independent CRC/DEFLATE test patterns.
- `modules/mb-image/png/moon.pkg` — declared `+js+wasm+wasm-gc+native`
  target set.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `png_chunk_test_pull`, `png_chunk_test_drain_encoder`, and
  `png_chunk_test_owner` already exercise bounded caller leases, sentinels,
  accepted totals, sticky `Finished`, and released-lease failures.
- Existing indexed compression corpus helpers produce deterministic Fixed
  winners and Stored fallbacks at all four depths.
- Public `@codec.ImageDecoder::decode` tests already validate RGB8/RGBA8
  views and can be reused only after the new parser has independently checked
  the collected bytes.

### Established Patterns
- Acknowledgement-safe output advances CRC/Adler and replay state only after
  destination acceptance; terminal `Finished`/`Failed` results are sticky.
- Test-local literal parsers in `png_test.mbt` validate chunk CRCs and
  decompression without deriving expected values from production planners.
- Compatibility tests compare explicit selector bytes to literal legacy
  forwards, while Adam7 remains Stored/filter-None.

### Integration Points
- Add qualification tests beside existing indexed stream tests, keeping
  production files unchanged unless a verifier finds a real lifecycle defect.
- Record target gate commands and results in phase artifacts; no release script
  or copied tree is needed.

</code_context>

<specifics>
## Specific Ideas

`--auto` discussion mode selected the recommended minimal, test-only path for
each gray area. The user prioritizes code and tests over release automation and
authorizes choosing the optimal scoped implementation without pausing for
choices.

</specifics>

<deferred>
## Deferred Ideas

Dynamic indexed DEFLATE, adaptive indexed filters, indexed Adam7 compression
selection, generic source-model changes, FFI/target wrappers, copied source
trees, registry publication, release automation, and any new public API remain
outside Phase 87 and the v0.28 milestone scope.

</deferred>

---

*Phase: 87-Hostile Indexed Streaming and Independent Qualification*
*Context gathered: 2026-07-24*
