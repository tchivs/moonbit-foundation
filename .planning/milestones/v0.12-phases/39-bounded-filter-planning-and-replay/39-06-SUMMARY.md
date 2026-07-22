---
phase: 39-bounded-filter-planning-and-replay
plan: "06"
status: complete
---

# Phase 39 Plan 06 Summary

Adaptive PNG planning and replay now use the bounded owned match cursor for
Stored, Fixed, and Dynamic routes. Fixed plans retain a scalar filtered-stream
fingerprint and replay validates it at end-of-block, matching the existing
Dynamic replay-drift protection.

Public Adaptive regressions cover Fixed and Dynamic BTYPE selection, sticky
terminal errors, unchanged caller leases, and strict Dynamic-versus-Fixed
selection on RGB8 and straight-RGBA8 corpora. The Fixed mutation changes a
shape-preserving literal so replay reaches the fingerprint check and reports
`png-encode-fixed-replay-drift`; the legacy None replay-work mutation remains
unchanged.

## Verification

- Focused JS/native replay-mutation and selection tests passed.
- Full targeted matrix passed on js, wasm, wasm-gc, and native.
- `moon -C modules/mb-image check png --target all --target-dir <temporary> --frozen` passed.
- Temporary `phase39-06-*` build roots were removed in `finally` blocks.

## Files

- `modules/mb-image/png/encode.mbt`
- `modules/mb-image/png/stream_encode.mbt`
- `modules/mb-image/png/stream_encode_test.mbt`
