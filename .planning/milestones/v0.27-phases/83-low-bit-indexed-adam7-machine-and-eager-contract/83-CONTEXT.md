# Phase 83: Low-Bit Indexed Adam7 Machine and Eager Contract - Context

**Gathered:** 2026-07-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Add explicit bounded Adam7 Type-3/1, /2, and /4 eager output from the existing canonical `PngIndexedImage`, through the one acknowledged PNG machine. Existing non-interlaced low-bit and Indexed8 APIs and bytes remain frozen.
</domain>

<decisions>
## Implementation Decisions

- **D-01:** Add selected low-bit interlace companions using the existing `PngInterlaceStrategy`; legacy low-bit APIs explicitly select `None`.
- **D-02:** For every nonempty Adam7 pass row, derive `ceil(pass_width * depth / 8)` independently and repack pass-coordinate indices MSB-first with deterministic zero tail bits. Do not slice packed non-interlaced source rows.
- **D-03:** Reuse selected-depth `_png_adam7_passes` and the existing low-bit profile/machine. All packed pass scanline, frame, work, output and budget facts are checked before the sole budget charge or output.
- **D-04:** Phase 83 owns eager wire/preflight evidence; Phase 84 owns hostile caller-buffered lifecycle qualification.
- **D-05:** Preserve PLTE/tRNS and depth palette caps; independently validate seven-pass packed raw raster, chunk framing/CRC and public decode.

### the agent's Discretion

- Factor only a geometry/packing helper when it eliminates duplicated checked arithmetic without making a second encoder or staging buffer.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/REQUIREMENTS.md` — INDEXLOWADAM7-01 through -04.
- `.planning/ROADMAP.md` — Phase 83 goal and scope guard.
- `.planning/research/v027-LOWBIT-ADAM7.md` — packed-pass contract and risks.
- `.planning/milestones/v0.25-REQUIREMENTS.md` — non-interlaced low-bit compatibility baseline.
- `.planning/milestones/v0.26-phases/81-indexed8-adam7-machine-and-eager-wire-contract/81-VERIFICATION.md` — Adam7 machine/preflight evidence.
</canonical_refs>

<code_context>
## Existing Code Insights

- `modules/mb-image/png/encode.mbt` contains the low-bit profile, packed scanner, Adam7 geometry, frame facts, and sole `PngEncodeMachine`.
- `modules/mb-image/png/encode_test.mbt` and `encode_wbtest.mbt` contain indexed low-bit and Adam7 wire/preflight fixtures.
</code_context>

<specifics>
## Specific Ideas

The user-authorized priority is code and test correctness; no delivery/release work belongs here.
</specifics>

<deferred>
## Deferred Ideas

Caller-buffered hostile qualification is Phase 84. Generic model widening, filters/compression strategies, quantization, palette generation, staging, a second encoder, FFI, wrappers, copied trees and release automation remain excluded.
</deferred>
