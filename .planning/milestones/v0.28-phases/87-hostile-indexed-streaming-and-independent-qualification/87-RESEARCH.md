---
phase: 87
slug: hostile-indexed-streaming-and-independent-qualification
date: 2026-07-24
status: complete
confidence: high
sources:
  - .planning/ROADMAP.md
  - .planning/REQUIREMENTS.md
  - .planning/research/v028-INDEXED-PNG-COMPRESSION.md
  - .planning/milestones/v0.27-phases/84-low-bit-indexed-adam7-streaming-qualification/84-01-SUMMARY.md
  - modules/mb-image/png/stream_encode.mbt
  - modules/mb-image/png/stream_encode_test.mbt
---

# Phase 87 Research: Hostile Indexed Streaming and Independent Qualification

## Executive Summary

Phase 87 can remain test-only. The Phase 86 selected plan already enters the
single acknowledged `PngEncodeMachine`; the repository contains reusable
hostile-lease and test-local PNG qualification patterns from Phase 84 and
earlier stream tests. The implementation work should extend those patterns to
non-interlaced Indexed1/2/4/8 `Stored` and `FixedOrStored` selectors without
adding a second encoder, parser dependency, source model, or release script.

## Scope and Requirements

- `INDEXCOMP-04`: hostile zero/one/ragged leases, accepted-only progress,
  sentinel-tail preservation, sticky released/replay failures, and zero-write
  terminal pulls for the admitted machine.
- `INDEXCOMP-05`: independent parsing of eager and collected chunk-origin Type-3
  bytes; Fixed-or-Stored/DEFLATE selection; PLTE/tRNS canonicalisation;
  filter-None packed rows/tails; Adler/CRC checks; public RGB8/RGBA8 decode;
  frozen legacy vectors; native/wasm/wasm-gc/js package gates.
- Explicitly exclude Dynamic/adaptive/Adam7 compression, staging, FFI,
  wrappers, copied source trees, registry/release automation, and production
  architecture changes.

## Existing Reusable Patterns

### Acknowledged stream lifecycle

`modules/mb-image/png/stream_encode.mbt` exposes `PngChunkEncoder::pull` over a
caller lease. The machine presents bytes and advances CRC/Adler/replay state
only after acknowledgement. `Finished` and `Failed` are sticky, and replay
revision/work validation already yields typed errors. Existing tests around
lines 2734-2810 and the Phase 84 qualification provide exact patterns for
zero-capacity leases, one-byte drains, ragged schedules, released leases,
terminal replay, accepted totals, and sentinel tails.

### Independent Type-3 oracle

`modules/mb-image/png/stream_encode_test.mbt` already contains test-local
chunk and raster assertions for low-bit/Adam7 output. `png_test.mbt` contains
literal CRC and public decoder qualification. Reuse only the parsing/data
structures; expected palette, tRNS, packed rows, DEFLATE block type, Adler, and
CRC values must come from the test-local corpus and arithmetic, never from
production frame/planner/matcher/packer helpers.

### Corpus

Phase 86's 512-pixel matrix has deterministic Fixed winners and Stored
fallbacks for One/Two/Four/Eight. Keep it as the main corpus. Add only compact
odd/narrow dimensions and partial-alpha palettes where needed to expose
non-byte-aligned final packed bytes, zero tail bits, and RGBA8 transparency
semantics. Avoid large binary fixtures and external compressors.

### Compatibility

Legacy non-interlaced Indexed1/2/4/8 APIs are literal `Stored` forwards and
must remain byte-identical. Existing Indexed Adam7 routes are Stored/filter-
None vectors and remain frozen. Explicit `Stored` selectors should be compared
byte-for-byte with their corresponding legacy methods.

### Target gates

`modules/mb-image/png/moon.pkg` declares `+js+wasm+wasm-gc+native`. The
ordinary package command is `moon -C modules/mb-image test png --target <target>
--frozen`; run it explicitly for `native`, `wasm`, `wasm-gc`, and `js`, and
record concrete results. A named focused filter must be run before any broad
gate to prevent a vacuous qualification.

## Recommended Test Shape

1. Add a small test-local indexed parser/deflate inspector and local packed-row
   oracle to `stream_encode_test.mbt`, or extend the closest existing helpers.
2. Add a hostile matrix for Fixed winner and Stored fallback: zero capacity,
   one byte, and ragged capacities, comparing accepted collected bytes to fresh
   eager output and checking untouched sentinel tails.
3. Add release/replay drift tests that assert the first terminal error and all
   subsequent pulls are zero-write and destination-preserving.
4. Parse collected chunk-origin bytes independently, then call public
   RGB8/RGBA8 decode and assert every source coordinate, including odd widths,
   alpha entries, and zero-tailed packed rows.
5. Freeze legacy non-interlaced and Adam7 vectors and compare explicit Stored
   selectors to legacy bytes.
6. Run focused filters and all four target package gates; capture results in the
   plan summary and verification report.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Oracle accidentally calls production helpers | Keep parser, row packing, CRC/Adler checks, and expected vectors test-local; review imports/call sites. |
| Zero-capacity lease aliases a sentinel owner | Use the established one-byte sentinel owner with a zero-length borrowed view and assert the sentinel remains unchanged. |
| Eager parity masks a chunk-origin bug | Parse the collected chunk bytes directly before comparing them to eager output. |
| Target gate is vacuous or blocked by toolchain | Run named focused tests first, then each declared target; record unavailable-target evidence without changing package scope. |
| Scope expands into production redesign | Keep all expected modifications in test files; Phase 87 must not add a new machine, compressor, staging buffer, FFI, or public API. |

## Open Questions Resolved by Prior Phases

- The compact 512-pixel Fixed/Stored matrix is the canonical corpus (Phases
  85/86).
- Selected work and frame facts are authoritative before one budget charge
  (Phase 86); Phase 87 qualifies lifecycle and wire behavior, not accounting
  redesign.
- Indexed Adam7 compression selection remains deferred; existing Adam7
  Stored/None bytes are compatibility fixtures.

## Plan Guidance

Use one Wave 1 plan if possible, with tests owned by the existing PNG stream
qualification module. Split tasks by independent evidence boundaries only when
they can avoid overlapping edits: hostile lifecycle first, independent parser/
decode and compatibility second, then target-gate verification. Production code
should be changed only if a failing qualification demonstrates a real defect.
