# Phase 77: Indexed PNG Transparency - Context

**Discussed:** 2026-07-24
**Status:** Ready for planning

## Locked Decisions

- Extend `PngIndexedImage` with per-entry alpha while keeping its owning, validated source contract and all opaque Phase 76 bytes unchanged.
- Canonicalize tRNS: omit it when every alpha is 255; otherwise emit bytes through the last non-255 entry, including intermediate opaque values.
- Preserve source validation/ownership and preflight atomicity before writer or budget exposure; alpha count must equal palette count.
- Extend the same private variable framing facts to emit `IHDR → PLTE → tRNS → IDAT → IEND`, with independent chunk order/CRC and public generic RGBA8 decode evidence.
- Scope is eager Indexed8 only. Caller-buffered parity, Indexed low bit depths, Adam7, strategy families, model widening, and quantization remain deferred.

## Success Criteria

1. Opaque indexed output remains byte-identical and has no tRNS.
2. Partial alpha produces canonical tRNS with exact order, length, and CRC; decode returns RGBA8 semantics.
3. Invalid alpha source and budget/limit requests fail atomically before output.
