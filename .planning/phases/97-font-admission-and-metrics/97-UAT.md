---
status: complete
phase: 97-font-admission-and-metrics
source: 97-01-SUMMARY.md, 97-02-SUMMARY.md, 97-03-SUMMARY.md
started: 2026-07-26T22:10:36Z
updated: 2026-07-27T04:29:11Z
---

## Current Test

[testing complete]

## Tests

### 1. Portable font contract
expected: `tchivs/mb-font` is a portable, independently consumable module with an opaque Font, explicit FontLimits, checked standalone TrueType admission, and units-per-em access.
result: pass
source: automated
coverage_id: D1

### 2. Generated standalone TrueType admission
expected: A generated checksum-correct standalone TrueType font opens successfully and reports its exact units-per-em value.
result: pass
source: automated
coverage_id: D2

### 3. Fail-closed admission boundaries
expected: Malformed, unsupported, over-limit, over-budget, and retained-source-mutated inputs fail closed deterministically without partial budget mutation.
result: pass
source: automated
coverage_id: D3

### 4. Checked standalone TrueType directory admission
expected: Standalone TrueType directories are normalized to checked table-local windows and rejected on malformed ordering, ranges, overlap, profiles, table checksums, or whole-font adjustment.
result: pass
source: automated
coverage_id: D1

### 5. Required table and cardinality admission
expected: All ten required tables, structural envelopes, hmtx length, and short/long loca offsets are admitted under explicit limits and cross-table cardinalities.
result: pass
source: automated
coverage_id: D2

### 6. Exact global font metrics
expected: Opaque Font queries publish exact units-per-em, global bounds, hhea line metrics, and OS/2 typographic metrics while uniformly rejecting retained-source revision drift.
result: pass
source: automated
coverage_id: D3

### 7. Exact per-glyph metrics
expected: Callers can obtain opaque range-checked glyph identities and exact advance, left bearing, optional bounds, and checked right bearing values.
result: pass
source: automated
coverage_id: D1

### 8. Hostile metric boundary handling
expected: Hostile hmtx, short/long loca, common glyf headers, budget edges, mutation drift, and interleaved fonts fail closed or return deterministic values.
result: pass
source: automated
coverage_id: D2

### 9. Independent mb-font governance
expected: mb-font is independently documented and governed by exact module, dependency, source, publication, target, and minimal semantic-interface allowlists.
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

[none]
