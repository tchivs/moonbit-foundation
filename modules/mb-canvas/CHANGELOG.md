# Changelog

All notable changes to `tchivs/mb-canvas` will be recorded in this file. This module follows an independent release lifecycle.

## 0.1.0 candidate (unpublished) - 2026-07-23

Compatibility status: candidate. Pre-1.0 candidates carry no compatibility promise beyond the executable four-class policy; exact changes are patch-eligible, additive public surface requires a minor release, and incompatible change requires a minor release plus a migration note.

### Added

- `tchivs/mb-canvas/canvas`: portable deterministic drawing-list abstraction (fill, stroke, transform push/pop, clip push/pop) and coverage-antialiased rasterization of line and Bézier path geometry into `mb-image` RGB8 and straight-RGBA8 mutable raster surfaces, under RFC 0003. Pure MoonBit across js, wasm, wasm-gc, and native.
