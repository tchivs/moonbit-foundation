# v0.25 Research Summary: Indexed Low-Bit PNG Encode

**Recommendation:** Deliver Type-3 depths 1/2/4 as a narrowly parameterized extension of the shipped Indexed8 machine. Preserve canonical unpacked source indices and pack only at the final scanline boundary, MSB-first with zero-filled row tails.

## Roadmap Recommendation

1. **Phase 79: Indexed Low-Bit Preflight and Eager Packing**
   - Add explicit 1/2/4 depth selection, checked packed-row sizing, Type-3 IHDR depth emission, and MSB-first index packing.
   - Reuse `PngIndexedImage`, PLTE/tRNS frame facts, Stored/None DEFLATE and the existing shared machine.
   - Gate on palette capacity (`2`, `4`, `16`), exact output/work admission, independent wire/CRC checks and RGB8/RGBA8 decode-back.

2. **Phase 80: Resumable Indexed Low-Bit Parity and Qualification**
   - Add only a thin caller-buffered entry into the completed eager machine.
   - Qualify zero/one/ragged leases, accepted-only progress, sentinel tails, sticky success/error and four-target package tests.

## Non-Negotiable Acceptance Points

- `PngIndexedImage` remains canonical one-byte-per-pixel input; no bit-packed public image model.
- Low-bit row bytes are `ceil(width * depth / 8)` with checked arithmetic; each row starts with filter byte `0`.
- The final partial byte has zero-filled unused low bits, giving deterministic eager/chunk-identical output even though PNG leaves them unspecified.
- PLTE is capped by selected depth; existing optional canonical `tRNS` is reused unchanged and stays before IDAT.
- Indexed8 behavior and legacy PNG byte vectors remain unchanged.
- No Adam7, strategy expansion, quantization, generic model widening, staging, FFI, wrappers, copied source or release automation.

See [v025-INDEXED-LOW-BIT-ENCODE.md](v025-INDEXED-LOW-BIT-ENCODE.md) for requirements candidates, exact packing vectors, test anchors, risks and confidence.
