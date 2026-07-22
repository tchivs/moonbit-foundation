# Phase 47: Gray16 Factory Compatibility - Context

**Gathered:** 2026-07-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Add explicit Stored, filter-None, non-interlaced Gray16 PNG factories for packed U16 Gray images. The phase establishes correct PNG type-0/16-bit big-endian wire emission, eager/caller-buffered parity, atomic admission, and legacy compatibility only. Phase 48 owns all strategy/filter expansion; Phase 49 owns hostile capacities and four-target evidence.
</domain>

<decisions>
## Implementation Decisions

- **D-01:** Public APIs mirror the explicit Gray8 eager/chunk factory family with `gray16` names, bind Stored/None/None, and do not make Gray16 implicit in legacy constructors.
- **D-02:** Accept only packed, tightly packed, top-left, U16 `ChannelOrder::Gray` input with canonical metadata and no alpha. Treat the image storage bytes as the source representation, but serialize every Gray16 sample high byte then low byte as required by PNG.
- **D-03:** Add a bounds-checked storage accessor for a byte within a packed U8/U16 component, then keep a private Gray16 profile in the existing machine/preflight path. The encoder serializes U16 component bytes in PNG big-endian order through that accessor; it does not add a second encoder, retained full-image buffer, or separate stream driver.
- **D-04:** Preserve single-preflight atomicity: unsupported component/profile/geometry/output/work/budget failures happen before eager writer bytes or a usable chunk encoder exists. Gray16 Adam7 stays rejected.
- **D-05:** Test exact type-0/16-bit/non-interlaced bytes including a non-symmetric two-byte sample, eager/chunk identity, atomic bad-profile rejection, and unchanged Gray8/RGB8/RGBA8 vectors on native. Phase 49 owns broad schedule and four-target proof.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` — Phase 47 / `GRAY16-01` scope.
- `modules/mb-image/png/png.mbt` and `stream_encode.mbt` — public Gray8 factory patterns.
- `modules/mb-image/png/encode.mbt` — `_png_encode_source`, profile-aware preflight, scanline emission, and IHDR selection.
- `modules/mb-image/png/raster_decode.mbt` — existing Gray16 PNG wire order and public RGB canonicalization behavior.
- `modules/mb-image/png/encode_test.mbt` and `stream_encode_test.mbt` — Gray8 and frozen legacy test helpers.
</canonical_refs>

<deferred>
## Deferred Ideas

None/Adaptive and Stored/Fixed/Dynamic strategy parity, zero/one/ragged schedules, public wire/decode corpus, and independent four-target execution belong to Phases 48–49. Gray+alpha, RGB/RGBA16, Gray16 Adam7, palette/low-bit output, transparency conversion, publication, and release automation remain outside v0.15.
</deferred>
