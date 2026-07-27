---
status: complete
phase: 99-simple-and-composite-outlines
source:
  - 99-01-SUMMARY.md
  - 99-02-SUMMARY.md
  - 99-03-SUMMARY.md
  - 99-04-SUMMARY.md
started: 2026-07-27T12:48:19Z
updated: 2026-07-27T12:48:19Z
mode: auto
---

## Current Test

[testing complete]

## Tests

### 1. Guarded direct outline query
expected: Guarded direct `Path2` queries validate glyph identity and source revisions before publishing one complete result.
result: pass
source: automated
coverage_id: 99-01-D1

### 2. Exact simple-glyph geometry
expected: Simple `glyf` decoding preserves repeated flags, signed coordinate deltas, implied points, winding, contour order, and exact Q15 lowering.
result: pass
source: automated
coverage_id: 99-01-D2

### 3. Simple-outline hostile boundaries
expected: Limits, `maxp`, `max_work`, caller Budget, and malformed simple outlines fail closed without partial geometry.
result: pass
source: automated
coverage_id: 99-01-D3

### 4. Exact composite placement
expected: One-level composites support signed XY and real-point attachment plus uniform, independent-axis, and 2×2 transforms in component order.
result: pass
source: automated
coverage_id: 99-02-D1

### 5. Composite graph and capability taxonomy
expected: Cycles and malformed composites are Data while validated deeper graphs, phantom attachment, and grid rounding are Capability.
result: pass
source: automated
coverage_id: 99-02-D2

### 6. Transactional composite extraction
expected: Composite extraction is independently budgeted, mutation guarded, metrics neutral, and atomically published.
result: pass
source: automated
coverage_id: 99-02-D3

### 7. Four-target outline behavior
expected: Complete simple and bounded one-level composite behavior is identical on native, JS, Wasm, and Wasm-GC.
result: pass
source: automated
coverage_id: 99-03-D1

### 8. Public interface and policy closure
expected: The generated interface contains only intended Phase 99 additions and policy rejects private or deferred surface.
result: pass
source: automated
coverage_id: 99-03-D2

### 9. Published outline contract
expected: Executable package, changelog, and bilingual documentation publish the delivered and excluded Phase 99 contract without Phase 100 overclaim.
result: pass
source: automated
coverage_id: 99-03-D3

### 10. Manifest-description drift enforcement
expected: The `mb-font` manifest carries the exact approved Phase 99 description and the focused policy selector rejects future drift.
result: pass
source: automated
coverage_id: 99-04-D1

### 11. Public error taxonomy
expected: The executable README classifies `maxp` underclaims as Data and retained `FontLimits`, `max_work`, and Budget exhaustion as Resource on all four targets.
result: pass
source: automated
coverage_id: 99-04-D2

## Summary

total: 11
passed: 11
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None.

## Automated Evidence

- Full `mb-font/font` package: 92/92 passed on native, JS, Wasm, and Wasm-GC.
- Native package check and fresh all-target interface generation passed.
- Four-target executable README checks passed.
- Focused and repository-wide foundation policy gates passed.
- Temporary manifest-description drift fixture was rejected with the expected diagnostic.
- Phase verification passed 14/14 with `behavior_unverified: 0`.
- Phase security verification closed 21/21 threats with `threats_open: 0`.
