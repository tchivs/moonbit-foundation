# Changelog

All notable changes to `tchivs/mb-svg` will be recorded in this file. This module follows an independent release lifecycle.

## 0.1.0 candidate (unpublished) - 2026-07-24

Compatibility status: candidate. Pre-1.0 candidates carry no compatibility promise beyond the executable four-class policy.

### Added

- `tchivs/mb-svg/svg`: portable SVG subset parser (document structure, basic shapes, paths, transforms, fill/stroke) lowering to a `mb-canvas` drawing list, under RFC 0002. Pure MoonBit across js, wasm, wasm-gc, and native. Does not rasterize; it translates the scene tree into a drawing list consumed by `mb-canvas`.
