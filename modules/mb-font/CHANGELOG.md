# Changelog

All notable changes to `tchivs/mb-font` will be recorded in this file. This
module follows an independent release lifecycle.

## 0.1.0 candidate (unpublished) - 2026-07-26

Compatibility status: candidate. No stable API or public release is claimed.

### Added

- `tchivs/mb-font/font`: portable, bounded admission of one standalone
  TrueType-outline SFNT from a caller-provided byte view, explicit `FontLimits`,
  and an authoritative `mb-core` budget.
- Opaque admitted `Font` and `GlyphId` values with retained-source mutation
  invalidation.
- Named global metric sources from `head`, `hhea`, and `OS/2`.
- Exact per-glyph `hmtx` advance/left-bearing semantics, optional common-header
  `glyf` bounds, empty-glyph handling, and checked right-side-bearing
  derivation.
- Deterministic one-scalar Unicode mapping through the canonical format-12 or
  format-4 `cmap`, returning an opaque glyph identity and glyph zero for a valid
  miss.
- Optional basic legacy horizontal `kern` version-0 format-0 pair lookup with
  exact signed adjustments and distinct absent, miss, unsupported, malformed,
  and retained-source mutation outcomes.
- Explicit nonzero `max_kern_subtables` and `max_kern_pairs` ceilings with
  preflighted exact work and caller-budget accounting.
- Deterministic generated micro-font qualification across `js`, `wasm`,
  `wasm-gc`, and `native`.

Phase 98 does not claim outline/path decoding, text shaping, GPOS/GSUB, string
normalization, hinting, rasterization, filesystem/host discovery, FFI,
collection/web-font support, or licensed real-font evidence. Licensed real-font
end-to-end qualification is reserved for Phase 100.
