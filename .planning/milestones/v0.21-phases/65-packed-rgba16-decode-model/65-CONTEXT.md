# Phase 65: Packed RGBA16 Decode Model - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the checked public packed `rgba16` result contract needed by later explicit Type-6/16 PNG decoding, without adding any decoder selector, conversion API, or change to existing U8 contracts.

</domain>

<decisions>
## Implementation Decisions

### Packed representation identity
- **D-01:** Add `ImageFormat::rgba16()` as one packed eight-byte-per-pixel plane in little-endian `Rlo,Rhi,Glo,Ghi,Blo,Bhi,Alo,Ahi` order. It is an explicit straight-alpha, top-left, encoded builtin-sRGB identity. — **Reversibility:** costly — later PNG selectors and external consumers depend on this observable storage contract.
- **D-02:** Add a narrow U16-RGBA validator rather than broadening existing RGBA validation, which currently permits alpha modes that are not valid for the preservation result.

### Existing APIs and compatibility
- **D-03:** Reuse `OwnedImage` plus the existing U16 component-byte access contract; do not add parallel storage, views, or conversion helpers.
- **D-04:** Existing `rgba8` and `graya16` descriptors are frozen. U8-only operations/accessors remain fail-closed for `rgba16` rather than silently narrowing samples.

### Phase boundary
- **D-05:** Phase 65 stops at model/storage identity, checked construction, component inspection, and compatibility regressions. `decode_rgba16`, chunk selection, filters, Adam7, and PNG resource qualification belong to Phases 66-68.

### the agent's Discretion
- Follow the closest existing `graya16` model/storage test structure and keep the public surface minimal.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### v0.21 requirements and research
- `.planning/REQUIREMENTS.md` — `RGBA16DEC-01` contract and compatibility boundary.
- `.planning/ROADMAP.md` — Phase 65 goal, success criteria, and scope guard.
- `.planning/research/v021-REPRESENTATION.md` — representation research and existing model/storage seams.
- `.planning/research/v021-SUMMARY.md` — locked v0.21 architecture and scope fences.

### Established high-precision precedent
- `.planning/milestones/v0.20-phases/62-explicit-grayalpha16-decode-contract/62-CONTEXT.md` — explicit packed-U16 profile precedent and frozen generic boundary.
- `modules/mb-image/model/descriptor.mbt` — existing public image format descriptors.
- `modules/mb-image/storage/` — existing owned-image and component-byte access implementation.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ImageFormat::graya16()` and its descriptor tests: closest packed-U16 public format precedent.
- Existing `OwnedImage` component-byte views: already expose checked U16 lane storage without a new buffer type.

### Established Patterns
- High-precision formats use explicit identity validation and preserve generic U8 APIs rather than coercing values.
- Public format regressions assert descriptor identity, storage order, component bounds, and fail-closed incompatible access.

### Integration Points
- `modules/mb-image/model/descriptor.mbt` supplies public format identity.
- Existing model/storage validation is the only Phase 65 integration point; PNG decode files remain untouched.

</code_context>

<specifics>
## Specific Ideas

No additional product requirements — use the established `graya16` patterns with four lanes and an eight-byte pixel stride.

</specifics>

<deferred>
## Deferred Ideas

- Explicit Type-6/16 eager decode — Phase 66.
- Caller-buffered Type-6/16 decode — Phase 67.
- Adam7/filter/resource/public all-target qualification — Phase 68.
- Colour-managed/non-sRGB conversion and public high-precision conversion APIs — future requirements.

</deferred>

---

*Phase: 65-Packed RGBA16 Decode Model*
*Context gathered: 2026-07-23*
