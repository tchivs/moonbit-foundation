# Phase 45: Bounded Gray8 Encoder Path - Context

**Gathered:** 2026-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the working Phase 44 Gray8 Stored route through the existing bounded filter, FixedOrStored, DynamicOrFixedOrStored, eager preflight, and acknowledgement-safe caller-buffered replay pipeline. This phase completes `GRAYPNG-02` without widening PNG colour formats or interlacing.

</domain>

<decisions>
## Implementation Decisions

### Symmetric strategy surface
- **D-01:** Add explicit Gray8 compression-only, filter-only, and combined-strategy factories on both eager and caller-buffered encoders. Existing RGB/RGBA factories and bytes remain untouched.
- **D-02:** Gray8 accepts Stored, FixedOrStored, DynamicOrFixedOrStored, None, and Adaptive through exactly the same selected-work and strict-winner rules as legacy profiles; Gray8 Adam7 remains rejected before output.

### One bounded implementation path
- **D-03:** Remove only the Gray8 strategy/filter exclusion and generalize the existing one-channel filter/traversal checks; do not create a parallel compression planner, image-sized staging buffer, or profile-specific replay state.
- **D-04:** Eager construction and chunk construction keep the existing atomic admission order: source/capability, geometry, output, work, and budget failure happens before writer bytes or a usable caller lease.

### Evidence for this phase
- **D-05:** Add focused native tests for all Gray8 strategy selections, exact eager/chunk equality, Atomic work/output/budget rejection, and accepted progress/replay. Generated public decode corpus, zero/one/ragged schedules, and four-target runs remain Phase 46.

### the agent's Discretion
Use the smallest naming and delegation additions consistent with the Phase 44 `new_gray8` API and existing `new_with_*` factory patterns.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 45 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `GRAYPNG-02` scope.
- `.planning/phases/44-gray8-factory-compatibility/44-VERIFICATION.md` — working Stored baseline and compatibility invariants.
- `modules/mb-image/png/png.mbt` — public profile and factory surface.
- `modules/mb-image/png/encode.mbt` — profile-aware preflight, filter traversal, work and budget ledger.
- `modules/mb-image/png/stream_encode.mbt` — private replay and caller-buffered construction seam.
- `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt` — existing strategy and atomicity test patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The private `PngEncodeProfile::Gray8` already flows through preflight and IHDR emission.
- Fixed/Dynamic planners already consume scalar row/filter traversal facts and do not need image-sized retained output.

### Established Patterns
- Legacy paths are frozen compatibility routes; opt-ins are explicit factory calls.
- Preflight is the sole admission point before writer output, budget charge, or chunk-encoder availability.

### Integration Points
- `_png_filter_candidate_byte` currently restricts channels to 3/4; it is the narrow filter gate that must admit one-channel Gray8.
- `_png_encode_preflight_with_interlace_profile` currently rejects non-Stored Gray8 strategy/filter combinations; Phase 45 replaces that restriction while retaining the Gray8 Adam7 rejection.

</code_context>

<specifics>
## Specific Ideas

No additional product requirements: retain the existing deterministic strict winner policy and public caller-buffered accounting semantics.

</specifics>

<deferred>
## Deferred Ideas

- Generated decode fidelity, hostile zero/one/ragged schedules, and independent js/wasm/wasm-gc/native proof belong to Phase 46.
- Palette, low-bit Gray, Gray16, transparency conversion, Gray8 Adam7, and release automation remain out of scope.

</deferred>
