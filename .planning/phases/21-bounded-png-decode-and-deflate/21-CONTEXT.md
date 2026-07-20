# Phase 21: Bounded PNG Decode and DEFLATE - Context

**Gathered:** 2026-07-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn the Phase 20 structurally accepted RGB/RGBA PNG subset into an atomic
eager decode result by adding bounded pure-MoonBit zlib/DEFLATE and PNG
scanline reconstruction. This phase does not encode PNG or add a public PNG
streaming API.

</domain>

<decisions>
## Implementation Decisions

### Decode Scope
- **D-01:** Decode all legal zlib/DEFLATE block forms—stored, fixed Huffman,
  and dynamic Huffman—across arbitrary IDAT boundaries for the Phase 20
  non-interlaced 8-bit RGB/RGBA profile.
- **D-02:** Reconstruct all five PNG filters with byte-per-pixel values 3/4
  into existing encoded-sRGB RGB8/straight-RGBA8 image contracts.

### Resource and Result Semantics
- **D-03:** Keep `PngDecoder` and existing eager `ImageDecoder`/`Reader`
  contracts. Internal incremental byte/bit/scanline state is private; no
  public push/pull PNG API is introduced.
- **D-04:** No image becomes visible until zlib header, all DEFLATE blocks,
  Adler-32, exact filtered-byte accounting, IEND, and strict EOF succeed.
  Output storage and budget charging follow existing checked contracts.
- **D-05:** DEFLATE history is bounded to 32 KiB; malformed trees, reserved
  symbols, invalid distances, expansion, checksum, and reader failures are
  deterministic typed errors with no partial result.

### Evidence
- **D-06:** Use small independently derived valid/invalid fixtures, including
  stored/fixed/dynamic blocks, all filter modes, IDAT splits, checksum failures,
  overlap distances, and limits. Run package evidence on js, wasm, wasm-gc,
  and native.

### the agent's Discretion

Choose private package/file layout and test fixture generation that preserve
acyclic dependencies and keep `deflate` reusable internally without exposing a
generic public compression API.

</decisions>

<canonical_refs>
## Canonical References

- `.planning/REQUIREMENTS.md` — PNG-04 and PNG-05.
- `.planning/ROADMAP.md` — Phase 21 success criteria.
- `.planning/research/SUMMARY.md` — accepted decoder architecture and DEFLATE
  safety research.
- `.planning/phases/20-png-structural-safety-gate/20-VERIFICATION.md` —
  structural input and interim capability-result contract to replace.
- `modules/mb-image/png/` — Phase 20 package and structural parser.
- `modules/mb-image/codec/contracts.mbt` — eager codec, resource, diagnostics,
  and result contracts.

</canonical_refs>

<code_context>
## Existing Code Insights

- Phase 20 provides strict PNG framing, CRC, IDAT continuity, limits, and
  opaque-metadata policy. Phase 21 consumes that structural state; it must not
  weaken it.
- `mb-core` checked arithmetic, budget, bytes, and io provide the bounded
  primitives. QOI/PPM provide eager codec and all-target evidence patterns.

</code_context>

<specifics>
## Specific Ideas

Prefer correctness and bounded behavior over compression performance. PNG
encoding, optimization, public streaming, APNG, palette/grayscale/16-bit and
colour-management profiles remain deferred.

</specifics>

<deferred>
## Deferred Ideas

Canonical PNG encoding and public workflow are Phase 22. FFI, registry,
release automation, compression benchmarks, Adam7, palette, grayscale,
`tRNS`, 16-bit, APNG, and public streaming are out of this phase.

</deferred>

---

*Phase: 21-bounded-png-decode-and-deflate*
*Context gathered: 2026-07-21*
