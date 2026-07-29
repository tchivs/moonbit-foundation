---
milestone: v0.35
name: Text Shaping Foundation
created: 2026-07-30
mode: auto
---

# v0.35 Milestone Context — Text Shaping Foundation

## Goal

Let MoonBit library authors transform bounded single-font horizontal Unicode
text into deterministic positioned glyph runs through explicit script,
language, direction, and feature choices on `js`, `wasm`, `wasm-gc`, and
`native`.

## Selected Vertical Slice

- Consume the existing opaque `Font` and caller-provided Unicode scalars.
- Publish a format-neutral run containing glyph identity, source cluster,
  advance, and x/y offset facts.
- Parse only the bounded OpenType layout data needed for a minimal,
  implementation-honest profile: single substitution, standard/required
  ligatures, legacy `kern`, and basic pair positioning.
- Make feature order, cluster propagation, direction, limits, budgets,
  mutation precedence, and publication atomicity explicit and deterministic.
- Qualify generated and licensed `glyf` and CFF1 fonts with independent oracle
  facts, hostile fixtures, frozen compatibility, and four equal target records.

## Explicit Exclusions

- Full Arabic, Indic, Khmer, cursive, contextual, mark attachment, or complex
  reordering engines.
- Font fallback, multi-font shaping, discovery, host font lookup, ambient
  locale, or ambient I/O.
- Unicode normalization, bidi paragraph analysis, line breaking,
  justification, rich-text segmentation, or vertical layout.
- Rasterization, hint execution, color/bitmap glyphs, variable fonts, WOFF,
  subsetting, authoring, HarfBuzz/ICU/FFI, or publication/stability promotion.

## Constraints Carried Forward

- Core algorithms and retained data models remain pure MoonBit and portable.
- `tchivs/mb-core` remains the only runtime dependency of `tchivs/mb-font`
  unless research proves a stricter existing local seam is required.
- Public packages remain acyclic and avoid exposing raw OpenType tables,
  offsets, lookup records, or mutable font internals.
- Every parser and shaping operation uses explicit limits, budget authority,
  mutation guards, structured errors, and atomic publication.
- Qualification is deterministic, exact-target, provenance-bound, and
  independent of GUI or host state.

## Optimal Defaults

- Continue phase numbering at 108.
- Run project research before finalizing requirements.
- Prefer a small complete Latin-style layout profile over broad partial complex
  script claims.
- Treat native timing as observation-only; correctness remains equal across all
  four supported targets.
