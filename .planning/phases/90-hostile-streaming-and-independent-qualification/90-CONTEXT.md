---
phase: 90
name: Hostile Streaming and Independent Qualification
status: discussed
---

# Phase 90 Context

## Goal

Qualify the Phase 89 machine under hostile caller leases and independently validate Adam7 FixedOrStored bytes, framing, checksums, packed pass tails, and public RGB8/RGBA8 decode.

## Locked decisions

- D-01: Use zero-capacity, one-byte, and ragged lease schedules; only accepted bytes may advance totals and sentinel tails must remain unchanged.
- D-02: Released leases and replay drift are sticky zero-write failures; post-finish pulls are sticky zero-write Finished results.
- D-03: The independent oracle parses chunk lengths/order/CRC, zlib/DEFLATE block type, Adler-32, and pass raster without calling production preflight, matcher, packer, or frame helpers.
- D-04: Exercise all four indexed depths and both public decode outcomes: transparent RGBA8 and opaque RGB8.
- D-05: Keep compatibility vectors and the full package gate on all four targets; no production architecture expansion.

## Acceptance criteria

1. Fixed Adam7 eager and chunk-origin bytes match under hostile schedules and are independently parseable.
2. Public decoder reconstructs the expected palette and RGB/RGBA channel shape for each indexed depth.
3. Existing hostile Stored/replay and v0.28 compatibility tests remain green on native, wasm, wasm-gc, and js.
