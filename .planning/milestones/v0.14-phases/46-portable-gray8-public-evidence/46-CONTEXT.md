# Phase 46: Portable Gray8 Public Evidence - Context

**Gathered:** 2026-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete `GRAYPNG-03` with public, black-box PNG regression evidence: generated Gray8 eager output must decode back to its original samples; caller-buffered Gray8 output must equal eager bytes under zero, one-byte, and ragged leases; frozen RGB8 and straight-RGBA8 compatibility bytes must remain guarded; and those cases must run independently on js, wasm, wasm-gc, and native. This phase adds tests and verification evidence only—no encoder behavior, public API, release script, or package publication changes.

</domain>

<decisions>
## Implementation Decisions

### Public fidelity oracle
- **D-01:** Generate compact deterministic Gray8 source images in the existing public test helpers, encode through `PngEncoder::new_gray8_with_strategies`, decode through `PngDecoder::new`, and compare dimensions, one-channel format, and every original sample. Cover Stored, FixedOrStored, DynamicOrFixedOrStored, None, and Adaptive without private encoder APIs or opaque binary snapshots.

### Caller-buffered schedules and compatibility
- **D-02:** Use the existing public `PngChunkEncoder` drain helper with schedules containing zero, one-byte, and ragged capacities; require byte-for-byte equality to the equivalent eager Gray8 result and correct accepted-byte progress. Do not add a separate stream harness or image staging.
- **D-03:** Keep existing frozen RGB8 and straight-RGBA8 byte fixtures in the same portable test scope; add no new compatibility format or fixture generator.

### Portable evidence
- **D-04:** Run the same `png` package test suite independently with `moon` on js, wasm, wasm-gc, and native. Record these exact commands and results in the plan summary/verification; do not add CI, PowerShell, release, or publication scripts.

### Scope boundary
- **D-05:** Keep Gray8 Adam7, palette/indexed formats, low-bit packing, Gray16, transparency conversion, decoder behavior changes, and external-package work out of scope. Production PNG source remains unchanged unless a portable test exposes a genuine existing defect.

### the agent's Discretion

Choose the smallest deterministic image dimensions and sample pattern that exercise multi-row adaptive filtering and compression while keeping all target tests fast and readable.

</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` — Phase 46 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `GRAYPNG-03` acceptance boundary.
- `.planning/phases/45-bounded-gray8-encoder-path/45-VERIFICATION.md` — bounded-path invariants already completed.
- `modules/mb-image/png/encode_test.mbt` — public eager helper, Gray8 image helper, and decode assertions.
- `modules/mb-image/png/stream_encode_test.mbt` — public caller-buffered drain helper, schedules, and frozen RGB/RGBA evidence.
- `modules/mb-image/png/png.mbt` and `stream_encode.mbt` — public Gray8 factory surface under test.

</canonical_refs>

<code_context>
## Existing Code Insights

- Phase 45 already supplies public Gray8 eager and caller-buffered strategy factories plus ordinary positive-capacity parity.
- `png_chunk_test_drain_encoder` already accounts for `total_written` and supports arbitrary capacity schedules, including zero.
- Existing RGB8/RGBA8 dynamic/fixed corpus cases provide frozen public compatibility guards; Phase 46 extends evidence rather than replaces them.
- The package declares all four supported targets, so target evidence belongs in ordinary package tests rather than an external runtime wrapper.

</code_context>

<deferred>
## Deferred Ideas

- Gray8 Adam7, palette/indexed encoding, low-bit packing, Gray16, transparency conversion, release scripts, registry publication, and external package mutation remain out of scope.

</deferred>
