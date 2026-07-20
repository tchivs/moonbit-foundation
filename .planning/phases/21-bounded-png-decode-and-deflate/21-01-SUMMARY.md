---
phase: 21-bounded-png-decode-and-deflate
plan: "01"
subsystem: png
tags: [png, zlib, deflate, raster]
status: complete
requires: [phase-20-png-structural-safety-gate]
provides: [bounded-png-rgb-rgba-decode]
affects: [mb-image-png]
tech-stack: { added: [pure-moonbit-deflate], patterns: [logical-idat, atomic-result] }
key-files: [modules/mb-image/png/structural.mbt, modules/mb-image/png/deflate_inflate.mbt, modules/mb-image/png/raster_decode.mbt]
decisions: ["Kept PngDecoder as the sole public PNG API."]
metrics: { tasks: 3, targets: 4 }
---

# Phase 21 Plan 01: Bounded PNG Decode and DEFLATE Summary

Implemented the private PNG transport, bounded pure-MoonBit zlib/DEFLATE decoder, scanline reconstruction, and four-target evidence behind the unchanged `PngDecoder` API.

## Completed Work

- Logical IDAT transport retains signature, CRC, order, IEND, EOF, and limit checks.
- Private stored/fixed/dynamic DEFLATE validates zlib headers, FDICT, block trees, stored lengths, history distances, trailing bytes, and Adler-32.
- RGB8/RGBA8 inverse filters write local `OwnedImage` storage before `DecodeResult` construction.
- Added audited decode corpus metadata and .NET `ZLibStream` independent stored-stream check.
- Updated PNG policy inventories and lane coverage for all private decoder files.

## Verification

- `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check`
- `moon -C modules/mb-image test png --target all --frozen` — 15 tests passed on wasm, wasm-gc, js, and native.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed.

## Commits

- `eeeb47b` — bounded PNG DEFLATE transport.
- `622fd47` — atomic PNG raster decode.

## Deviations from Plan

The decode corpus is a compact declarative audit inventory; public and white-box behavioral proof stays in the package tests rather than generating a second large MoonBit table.

## Self-Check: PASSED

