# Phase 55: Portable Public Evidence - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Turn the completed legal little-endian GrayAlpha16 model and bounded Type-4/16 encoder into public compatibility proof: exact U16 wire/decode vectors, zero/one/ragged caller schedules, frozen legacy bytes, and independent four-target execution. No new encoder behavior is introduced.

</domain>

<decisions>
## Implementation Decisions

### Public compatibility vectors
- **D-01:** Use compact public package tests with non-symmetric legal U16 GrayAlpha samples and literal expected `Ghi,Glo,Ahi,Alo` PNG wire bytes. Assert public decoder canonicalizes them to straight RGBA8 high bytes.
- **D-02:** Keep all evidence at public `PngEncoder`, `PngChunkEncoder`, and decoder seams; do not test private profiles or add test-only encoder paths.

### Caller-buffered and legacy proof
- **D-03:** Run every existing compression/filter pair under zero-capacity, one-byte, and deterministic ragged schedules, asserting eager byte identity, accepted-only progress, untouched tails, and sticky terminals.
- **D-04:** Freeze existing Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 literal eager/chunk vectors. Any byte change is a regression, not a rebaseline.

### Portability boundary
- **D-05:** Run the same public PNG suite with `--target all`; tests remain portable MoonBit without native branches, FFI, release work, source copies, or new codec architecture.
- **D-06:** Big-endian GrayAlpha16 descriptors remain invalid under the Phase 53 model contract; public evidence uses legal little-endian sources and retains strict descriptor-boundary rejection coverage rather than claiming unsupported backing parity.

### the agent's Discretion
- Reuse the closest v0.15 Gray16 and v0.16 GrayAlpha8 public-evidence helpers and choose the smallest readable literal vectors.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` — GRAYA16-04 contract.
- `.planning/research/SUMMARY.md` — approved v0.17 architecture.
- `.planning/phases/54-bounded-type-4-16-encoder/54-VERIFICATION.md` — verified encoder boundary and legal endian contract.
- `.planning/milestones/v0.15-phases/49-portable-gray16-public-evidence/49-CONTEXT.md` — U16 public evidence analog.
- `.planning/milestones/v0.16-phases/52-portable-gray-alpha-public-evidence/52-CONTEXT.md` — GrayAlpha hostile/vector analog.
- `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt` — public vector, hostile-drain, terminal, and legacy-vector helpers.

</canonical_refs>

<code_context>
## Existing Code Insights

- Phase 54 exposes legal public `graya16` eager/chunk factories through the shared bounded machine.
- Existing Gray16 evidence supplies U16 byte-order and high-byte RGBA canonicalization patterns; GrayAlpha8 supplies Type-4 hostile strategy patterns.
- The portable target suite is `moon -C modules/mb-image test png --target all --frozen`.

</code_context>

<specifics>
## Specific Ideas

Select U16 pairs with four distinct bytes so wire-order, component-order, and high-byte decode canonicalization cannot pass accidentally.

</specifics>

<deferred>
## Deferred Ideas

- GrayAlpha16 Adam7, Big-endian GrayAlpha16 descriptor support, colour conversion, palette/low-bit formats, release automation, and copied-source workflows.

</deferred>

---

*Phase: 55-portable-public-evidence*
*Context gathered: 2026-07-23*
