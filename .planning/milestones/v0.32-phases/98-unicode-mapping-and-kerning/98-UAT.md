---
status: complete
phase: 98-unicode-mapping-and-kerning
source: [98-01-SUMMARY.md, 98-02-SUMMARY.md, 98-03-SUMMARY.md]
started: 2026-07-27T09:03:00Z
updated: 2026-07-27T09:03:00Z
---

# Phase 98 — UAT

## Current Test

[testing complete]

## Tests

### 1. Signed Unicode scalar mapping
expected: One signed scalar query maps BMP and supplementary Unicode values to an opaque GlyphId, returns glyph zero for valid misses, and reports structured errors for invalid scalars.
result: pass
source: automated
coverage_id: D1

### 2. Canonical cmap selection
expected: Font opening validates supported cmap records and selects exactly one canonical format-12-or-format-4 mapping independent of record order.
result: pass
source: automated
coverage_id: D2

### 3. Format-4 lookup boundaries
expected: Format-4 direct delta, glyph-array, raw-zero, hole, and supplementary miss behavior uses admitted allocation-free binary search.
result: pass
source: automated
coverage_id: D3

### 4. Public kerning taxonomy
expected: Font::kerning distinguishes absence and miss zero, signed hits, foreign glyph rejection, unsupported capability, malformed data, and retained-source mutation.
result: pass
source: automated
coverage_id: D1

### 5. Exact kern envelope admission
expected: Classic and Apple envelopes, exact format-0 lengths, canonical helpers, ordered unique in-range keys, and signed values are validated before publication.
result: pass
source: automated
coverage_id: D2

### 6. Bounded kern work
expected: Optional directory, classic/Apple subtable, and supported pair work is bounded by explicit ceilings, cumulative max_work, and the shared caller budget before traversal.
result: pass
source: automated
coverage_id: D3

### 7. Unicode-to-kerning public workflow
expected: One generated font maps BMP and supplementary scalars through the same public method and passes opaque glyph identities into signed legacy kerning.
result: pass
source: automated
coverage_id: D1

### 8. Portable hostile qualification
expected: Unicode and kern public/private hostile, resource, mutation, determinism, and error-taxonomy matrices execute identically on JS, Wasm, Wasm-GC, and native.
result: pass
source: automated
coverage_id: D2

### 9. Published contract and policy
expected: The generated interface, exact policy, literate documentation, changelog, and bilingual discovery text publish only the Phase 98 contract.
result: pass
source: automated
coverage_id: D3

## Summary

total: 9
passed: 9
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None.

## Automated Evidence

- `uat.classify-coverage`: 9/9 entries auto-passed, zero present, zero errors.
- `98-VERIFICATION.md`: 16/16 must-haves verified.
- `98-REVIEW.md`: final deep review clean after cumulative 4/4 fixes.
- `98-SECURITY.md`: 19/19 threats closed, `threats_open: 0`.
- `modules/mb-font/font`: 65/65 tests on JS, Wasm, Wasm-GC, and native.
- Generated interface remained byte-stable; font policy, manifest-description, bilingual README, and diff checks passed.
