# Phase 56: GrayAlpha16 Adam7 Factory and Pass Profile - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add explicit eager and caller-buffered Adam7 Type-4/16 factory selection for the already-legal packed little-endian U16 Gray+Alpha source. The shared bounded filtering, compression, atomicity, hostile replay, and complete public compatibility proof remain Phases 57–58.

</domain>

<decisions>
## Implementation Decisions

### Public Adam7 route

- **D-01:** Mirror the established explicit Adam7 eager and chunk factory families, adding only legal `graya16` Adam7 entry points. — **Reversibility:** one-way — public factory spellings are a compatibility contract.
- **D-02:** Reuse the existing private GrayAlpha16 profile and Adam7 pass traversal; generated IHDR must select colour type 4, bit depth 16, method 0, and interlace 1. Each pass reads source lanes as `Ghi,Glo,Ahi,Alo`.

### Compatibility and admission

- **D-03:** Preserve Phase 53's strict little-endian descriptor admission. A Big-endian U16 GrayAlpha descriptor remains invalid before PNG factory admission, not a second storage-order encoder variant. — **Reversibility:** one-way — widening descriptor admission would change the public model contract.
- **D-04:** Preserve all existing non-interlaced GrayAlpha16 factories and frozen legacy image routes byte-for-byte. This phase adds an explicit opt-in only.

### the agent's Discretion

- Use the smallest existing Adam7 RGB/RGBA factory and test helpers as the structural analogue, plus the Phase 54 GrayAlpha16 profile as the format analogue.
- Keep production changes within the existing PNG package and avoid staging buffers, alternate pipelines, target branches, FFI, release automation, and source copies.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and prior decisions

- `.planning/ROADMAP.md` — Phase 56 goal, success criteria, and Phase 57–58 boundaries.
- `.planning/REQUIREMENTS.md` — GRAYA16A7-01 and exclusions.
- `.planning/PROJECT.md` — v0.18 public compatibility constraints.
- `.planning/milestones/v0.17-phases/53-grayalpha16-model-and-checked-storage/53-CONTEXT.md` — locked legal little-endian U16 GrayAlpha descriptor contract.
- `.planning/milestones/v0.17-phases/54-bounded-type-4-16-encoder/54-CONTEXT.md` — Type-4/16 profile and public GrayAlpha16 factory precedent.
- `.planning/milestones/v0.17-phases/55-portable-public-evidence/55-CONTEXT.md` — public wire/decode and frozen-vector boundary.
- `.planning/milestones/v0.13-phases/41-adam7-encode-foundation/41-CONTEXT.md` — Adam7 factory and pass-profile precedent.

### Existing implementation

- `modules/mb-image/png/png.mbt` — public eager factory family and profile selection.
- `modules/mb-image/png/encode.mbt` — profile admission and source-lane wire traversal.
- `modules/mb-image/png/stream_encode.mbt` — caller-buffered factory construction and Adam7 machine route.
- `modules/mb-image/png/structural.mbt` — private Adam7 pass geometry.
- `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt` — GrayAlpha16 and Adam7 public test patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- The PNG package already owns private Adam7 pass geometry and supports Adam7 for RGB8/straight-RGBA8 through explicit eager and caller-buffered factories.
- The v0.17 GrayAlpha16 profile already supplies exact Type-4/16 admission and four-byte U16 wire lanes on the shared `PngEncodeMachine`.

### Established Patterns

- Format variants are added by explicit profile/factory composition, never a second machine.
- Adam7 is opt-in; legacy non-interlaced constructors and bytes remain unchanged.
- Legal U16 GrayAlpha storage is little-endian, while PNG output order is independently defined at the wire boundary.

</code_context>

<specifics>
## Specific Ideas

Use a 5×5 legal U16 GrayAlpha fixture with distinct gray/alpha high and low bytes so all seven Adam7 passes can expose lane-order mistakes without accidentally matching symmetric data.

</specifics>

<deferred>
## Deferred Ideas

- Bounded strategy matrices, atomic resource failures, and replay-mutation coverage — Phase 57.
- Public all-target pass-aware vectors, hostile schedules, and frozen compatibility vectors — Phase 58.
- Big-endian descriptor support, colour conversion, decoder widening, palette/low-bit formats, release automation, and copied-source workflows.

</deferred>

---

*Phase: 56-grayalpha16-adam7-factory-and-pass-profile*
*Context gathered: 2026-07-23*
