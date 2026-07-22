# Phase 53: GrayAlpha16 Model and Checked Storage - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add one additive packed U16 grayscale-plus-straight-alpha image identity and prove checked storage behavior. PNG encoder factories, wire framing, hostile streaming schedules, and four-target public PNG evidence remain in Phases 54–55.

</domain>

<decisions>
## Implementation Decisions

### Descriptor contract
- **D-01:** Add an explicit `ImageFormat::graya16()` identity using packed `ChannelOrder::GrayAlpha`, `ComponentType::U16`, `Some(AlphaMode::Straight)`, encoded builtin sRGB, and top-left orientation. — **Reversibility:** one-way — public format spelling and metadata form a compatibility contract.
- **D-02:** Admit GrayAlpha16 only with its exact packed U16 two-component descriptor identity. Reject malformed, opaque, premultiplied, linear/unknown-colour, or altered-layout variants through existing validation rather than silently normalizing them.

### Storage and compatibility
- **D-03:** Reuse the existing generic checked packed-image storage access; non-symmetric gray and alpha samples must expose both U16 bytes per component without a new backing representation or conversion buffer.
- **D-04:** Existing Gray8, Gray16, GrayAlpha8, RGB8, and straight-RGBA8 descriptors, views, storage, and reference operations remain unchanged. GrayAlpha formats remain unsupported by reference operations unless a later phase adds a deliberate semantic contract.

### the agent's Discretion
- Mirror the smallest existing Gray16 and GrayAlpha8 model/storage test patterns and preserve exhaustive test helper coverage for formats.
- Keep the change localized to the model and storage packages; no codec, release, FFI, platform branch, or source-copy work.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract
- `.planning/ROADMAP.md` — Phase 53 goal, GRAYA16-01, and later-phase boundaries.
- `.planning/REQUIREMENTS.md` — U16 GrayAlpha requirement and exclusions.
- `.planning/PROJECT.md` — v0.17 compatibility and Pure MoonBit constraints.
- `.planning/research/SUMMARY.md` — approved U16 GrayAlpha architecture, phases, and risk summary.
- `.planning/milestones/v0.15-phases/47-gray16-factory-compatibility/47-CONTEXT.md` — packed U16 grayscale model precedent.
- `.planning/milestones/v0.16-phases/50-gray-alpha-image-model/50-CONTEXT.md` — GrayAlpha8 descriptor and storage precedent.

### Existing implementation
- `modules/mb-image/model/descriptor.mbt` — channel order, component, alpha, and format validation rules.
- `modules/mb-image/model/descriptor_test.mbt` — public descriptor regressions.
- `modules/mb-image/storage/owned_image.mbt` — packed storage and checked view construction.
- `modules/mb-image/storage/storage_test.mbt` — checked U16 component access patterns.
- `modules/mb-image/ops/copy_flip.mbt` — existing reference-operation capability boundary.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ImageFormat::gray16()` supplies the packed-U16 descriptor and storage baseline.
- `ImageFormat::graya8()` supplies the exact two-component straight-alpha metadata baseline.
- Generic packed `ImageView` component reads/writes already carry indexed U16 bytes through checked storage.

### Established Patterns
- Additive format identities preserve every older validation and byte path.
- Public model tests use non-symmetric values and explicit invalid-descriptor cases.
- Reference-operation capability is explicit, not inferred from component count.

</code_context>

<specifics>
## Specific Ideas

Use distinct high and low bytes in both gray and alpha samples so component swaps and byte-order regressions remain observable before PNG work begins.

</specifics>

<deferred>
## Deferred Ideas

- Type-4/16 PNG factories and wire emission — Phase 54.
- Public decode, hostile caller schedules, frozen PNG vectors, and four-target PNG qualification — Phase 55.
- GrayAlpha16 Adam7, colour conversion, premultiplied alpha, palette/low-bit formats, release automation, and copied source trees.

</deferred>

---

*Phase: 53-grayalpha16-model-and-checked-storage*
*Context gathered: 2026-07-23*
