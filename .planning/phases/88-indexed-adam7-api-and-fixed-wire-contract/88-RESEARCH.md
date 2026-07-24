---
phase: 88
name: indexed-adam7-api-and-fixed-wire-contract
status: complete
sources:
  - modules/mb-image/png/png.mbt
  - modules/mb-image/png/encode.mbt
  - modules/mb-image/png/stream_encode.mbt
  - modules/mb-image/png/stream_encode_test.mbt
  - modules/mb-image/png/stream_encode_wbtest.mbt
  - modules/mb-image/png/encode_test.mbt
---

# Phase 88 Research

## Existing seams

- `PngCompressionStrategy` and `PngInterlaceStrategy` are public selectors in `png.mbt`; the additive API must preserve the existing interlace-only methods as Stored forwards.
- Public indexed eager/chunk methods are in `encode.mbt` and `stream_encode.mbt` (`encode_indexed8*`, `encode_indexed*`, `new_indexed8*`, `new_indexed*`). The existing compression-strategy methods already route through one shared `PngEncodeMachine`.
- `PngEncodeMachine::new_with_indexed_profile_and_strategy` is the sole indexed admission seam. `_png_encode_indexed_preflight_with_profile_and_strategy` already validates source facts, palette limits, Adam7 pass geometry, IDAT accounting, and rejects Dynamic before output/lease/budget.
- `PngIndexedRawCursor`/`PngMatchProducer` currently implement non-interlaced Type-3 filter-None production. Adam7 indexed scalar access is already available through `_png_indexed_adam7_scanline_byte` and `_png_adam7_passes`; Phase 89 should extend the producer/machine only after Phase 88 fixes the public contract.

## Contract facts to lock in tests

- Adam7 uses the existing seven-pass geometry from `_png_adam7_passes(width, height, 1, depth.to_int())`; each non-empty pass starts a local row at column zero, emits filter byte 0, packs low-bit indices MSB-first, and zeroes unused tail bits.
- `Stored` remains the exact byte-for-byte baseline. `FixedOrStored` may choose fixed DEFLATE only after the complete Type-3 Adam7 frame is known; Fixed wins ties and no second encoder or unbounded staging buffer is permitted.
- All four public indexed wire depths (1/2/4/8) share the same selector and machine contract. Legacy/default non-interlaced routes and v0.28 Stored Adam7 wrappers remain unchanged.
- Unsupported combinations (especially Dynamic and any capability outside the phase scope) must fail before output, lease acknowledgement, or budget charge.

## Recommended implementation/test shape

1. Add API-surface tests for eager and chunk selectors, all four depths, explicit Adam7, and compatibility forwards. Include compile-level calls so method naming/signatures are frozen.
2. Add deterministic pass fixtures that compare the filtered Adam7 stream and PNG framing fields (IHDR interlace=1, PLTE/tRNS, packed tails) against an independent reference/decode path.
3. Keep Phase 88 limited to additive selectors and the bounded Fixed-vs-Stored wire contract. Defer pass-aware preflight/machine admission, hostile lease lifecycle, and all-target qualification to Phases 89–90.

## Risks and mitigations

- Reusing the generic filtered cursor for indexed data can accidentally use source-pixel byte widths instead of packed wire widths; keep indexed pass geometry and bit packing explicit.
- Changing existing interlace-only wrappers could alter frozen vectors; implement them as literal Stored forwards and add regression assertions.
- A Fixed plan built from incomplete pass facts can make IDAT lengths/checksums diverge; require complete pass/frame facts before selection and test the Stored fallback on tiny/empty/one-row cases.

## Research conclusion

The repository already has the correct public strategy types, pass geometry, indexed source validation, and shared-machine seam. Phase 88 should therefore be a narrow additive API/wire-contract phase; the main production work is exposing explicit Adam7 compression selectors without duplicating the encoder and specifying the pass-local packed stream that Phase 89 will implement.
