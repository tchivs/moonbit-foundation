# Phase 48: Bounded Gray16 Encoder Path - Context

**Gathered:** 2026-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the explicit Gray16 PNG route from the Phase 47 Stored/None baseline to the established bounded None/Adaptive filtering and Stored/FixedOrStored/DynamicOrFixedOrStored compression paths. The phase preserves atomic eager and caller-buffered admission and acknowledgement-safe replay; Phase 49 owns hostile-capacity and four-target public evidence.
</domain>

<decisions>
## Implementation Decisions

- **D-01:** Mirror the existing Gray8 public eager and caller-buffered compression-only, filter-only, and combined strategy factory families with explicit `gray16` names. Legacy constructors remain unchanged and Gray16 Adam7 remains unavailable. — **Reversibility:** costly — removing public factory names later breaks consumers that selected an explicit bounded route.
- **D-02:** Generalize the shared filtered-byte producer so every planner and replay cursor reads a profile-aware PNG wire byte. For Gray16, that source maps tightly packed U16 Gray storage to high-byte/low-byte PNG order before filters, matching, checksums, and emission; it retains only existing scalar cursors and bounded matcher windows, never converted rows or an image-sized staging buffer.
- **D-03:** Gray16 uses the same preflight ledger as Gray8/RGB8/RGBA8 for all allowed strategy pairs. Profile facts carry the two-byte PNG filter stride, and capability, geometry, output, work, budget, and Adam7 failures occur before eager output or a usable chunk encoder.
- **D-04:** Native regression evidence covers all six Gray16 strategy pairs, exact type-0/16-bit wire ordering, eager/chunk identity, atomic rejected construction, and sticky replay behavior. Phase 49 adds zero/one/ragged schedules and four-target runs.

### the agent's Discretion

- Use the smallest profile-aware helper/signature changes that preserve the existing bounded producer and frozen Gray8/RGB8/RGBA8 byte routes.
</decisions>

<canonical_refs>
## Canonical References

### Milestone scope
- `.planning/ROADMAP.md` — Phase 48 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `GRAY16-02` acceptance boundary and deferrals.
- `.planning/phases/47-gray16-factory-compatibility/47-CONTEXT.md` — locked Gray16 source contract, wire order, atomicity, and phase split.
- `.planning/phases/47-gray16-factory-compatibility/47-01-SUMMARY.md` — shipped Stored/None baseline.

### Encoder implementation
- `modules/mb-image/png/png.mbt` — Gray8 factory family to mirror explicitly for Gray16.
- `modules/mb-image/png/encode.mbt` — profile-aware preflight plus bounded filter, match, Fixed, and Dynamic planners.
- `modules/mb-image/png/stream_encode.mbt` — shared eager/caller-buffered machine and acknowledgement-safe replay state.
- `modules/mb-image/storage/views.mbt` — checked packed component-byte source access for U16 input.
- `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt` — public native encoder and replay regression patterns.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PngFilteredCursor` and `PngFilteredMatchCursor` in `modules/mb-image/png/encode.mbt`: bounded filter selection and matcher replay producers.
- `PngEncodeMachine::new_with_profile` in `modules/mb-image/png/stream_encode.mbt`: one atomic construction seam for eager and chunk encoders.
- `ImageView::get_component_byte` in `modules/mb-image/storage/views.mbt`: validated U16 storage-order access introduced by Phase 47.

### Established Patterns
- Gray8 strategy factories bind a private profile while sharing one preflight and replay machine.
- Filter selection is defined over on-wire bytes; the filter stride is bytes per pixel, not logical channel count.
- All constructor failures precede writer bytes, caller leases, and budget charges.

### Integration Points
- Add Gray16 public factories beside existing Gray8 constructors in `png.mbt` and `stream_encode.mbt`.
- Route profile-aware wire bytes through every filter, match, Fixed, and Dynamic traversal in `encode.mbt` and machine replay in `stream_encode.mbt`.
</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond the locked bounded, code-first PNG contract; choose the existing Gray8 patterns as the compatibility model.
</specifics>

<deferred>
## Deferred Ideas

Zero/one/ragged caller-capacity evidence and independent js/wasm/wasm-gc/native runs belong to Phase 49. Gray16 Adam7, Gray+alpha, RGB/RGBA16, palette/low-bit output, publication, and release automation remain out of scope.
</deferred>

---

*Phase: 48-bounded-gray16-encoder-path*
*Context gathered: 2026-07-22*
