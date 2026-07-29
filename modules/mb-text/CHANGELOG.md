# Changelog

All notable changes to `tchivs/mb-text` will be recorded in this file. This
module follows an independent release lifecycle.

## 0.1.0 candidate (unpublished) - 2026-07-30

Compatibility status: candidate. No stable API, registry publication, or
semantic four-target qualification is claimed.

### Added

- One closed `shape(font, scalars, options, limits, budget)` operation with
  explicit Unicode scalars, checked script/language tags, default-or-exact
  language choice, LTR/RTL direction, closed `liga`/`kern` choices, the exact
  two-field nonzero `ShapeLimits`, and one caller-owned budget.
- Opaque immutable `PositionedGlyph` and `ShapedRun` values with same-Font
  glyph identities, scalar-index clusters, signed design-unit placement,
  checked total advance, metadata, length, and indexed value access only.
- A fully validated and charged empty route with exact text-side `work=1`, one
  combined caller/ancestor commit, and stable structured errors.
- Private generated contract evidence for request-owned scalar snapshots,
  logical-first LTR/final-only RTL projection, ligature cluster minima, signed
  overflow, error precedence, retained-source mutation, limits, and atomic
  charges.
- Explicit `js`, `wasm`, `wasm-gc`, and `native` build/test portability for the
  Phase 108 boundary.

Nonempty real-font shaping remains fail-closed with
`CapabilityUnavailable` until later layout-admission/execution phases.
Phase 113 retains licensed-font oracle and semantic four-target qualification
authority.

Deferred: GSUB/GPOS/GDEF and legacy-kerning selection or execution,
normalization, bidi analysis, fallback, vertical text, arbitrary feature
values, variables, host lookup, external SDKs, native FFI, UI, registry
integration, persistent caches, publication, and stability promotion.

Change class: additive candidate contract
Migration: not-required
RFC: covered by RFC 0005 and the Phase 108 locked contract
