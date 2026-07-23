# Phase 59: GrayAlpha8 Adam7 Factory and Pass Profile - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add explicit eager and caller-buffered Adam7 Type-4/8 selection for legal packed straight-alpha GrayAlpha8 images, while retaining existing non-interlaced factories and bytes.
</domain>

<decisions>
## Implementation Decisions

- **D-01:** Additive public eager and chunk GrayAlpha8 Adam7 factories follow the existing GrayAlpha16 Adam7 naming and strategy pattern; no legacy constructor changes.
- **D-02:** Permit GrayAlpha8 only through the existing profile-aware Adam7 machine and remove only its profile-specific non-interlaced rejection; no second encoder or staging path.
- **D-03:** Serialize Type-4/8 Adam7 samples in PNG order as `G,A` and use the existing seven-pass geometry/cursor.
- **D-04:** Keep legal packed straight-alpha sRGB/top-left admission and frozen interlace-method-0 legacy output unchanged.

### the agent's Discretion

- Reuse the smallest GrayAlpha16 Adam7 and GrayAlpha8 factory/profile tests; production changes must be limited to the shared admission/factory seam.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` — Phase 59 goal and criteria.
- `.planning/REQUIREMENTS.md` — GRAYA8A7-01 scope.
- `.planning/research/SUMMARY.md` — v0.19 architecture and risk synthesis.
- `modules/mb-image/png/png.mbt` — public PNG factory patterns.
- `modules/mb-image/png/encode.mbt` — profile admission and shared Adam7 cursor.
- `modules/mb-image/png/stream_encode.mbt` — caller-buffered factory construction.
- `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt` — existing GrayAlpha8/GrayAlpha16 evidence.
</canonical_refs>

<code_context>
## Existing Code Insights

- GrayAlpha8 currently has explicit non-interlaced factories but a profile-specific Adam7 rejection.
- GrayAlpha16 Adam7 already proves the exact additive eager/chunk factory and pass-profile composition pattern.
</code_context>

<deferred>
## Deferred Ideas

- Six-pair replay mutation protection belongs to Phase 60; public hostile schedules and all-target evidence belong to Phase 61.
</deferred>
