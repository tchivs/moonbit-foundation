---
phase: 39-bounded-filter-planning-and-replay
plan: "04"
subsystem: png-encoder
tags: [png, adaptive-filtering, resource-accounting]
status: partial
requires: [39-01, 39-02, 39-03]
provides: [adaptive-traversal-facts, strategy-filter-work-ledger]
affects: [modules/mb-image/png/encode.mbt, modules/mb-image/png/stream_encode.mbt]
tech-stack:
  added: []
  patterns: [persistent-forward-cursor, checked-work-composition]
key-files:
  created: []
  modified:
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_wbtest.mbt
    - modules/mb-image/png/stream_encode_wbtest.mbt
decisions:
  - Adaptive preflight records candidate and selected residual work from bounded forward traversals.
metrics:
  completed_date: 2026-07-22
status_reason: Replay match probing still calls the stateless adaptive byte supplier.
---

# Phase 39 Plan 04: Adaptive Traversal Ledger Summary

Added private forward adaptive cursor facts and atomic strategy-specific filter-work admission tests.

## Completed Work

- Added `PngFilteredCursor` and `PngFilteredTraversalFacts` for one-time row selection and selected residual accounting.
- Added Stored, FixedOrStored, and DynamicOrFixedOrStored exact/one-less budget coverage.
- Preserved filter-None and existing compression output-selection behavior.

## Verification

- RED: native `*adaptive cursor work ledger*` selector failed before implementation.
- GREEN: native `*adaptive*cursor*` selector passed (5 tests).
- GREEN: native `PNG adaptive combined eager routes` passed.
- `moon check png --target native` passed before final focused test execution.
- Removed all named `phase39-04-red` and `phase39-04-filter-cursor` target directories after testing.

## Deviations from Plan

### Deferred Issue

**[Blocked completion] Fixed and Dynamic match probing still uses `_png_filtered_match_at`, which calls the stateless Adaptive supplier for random lookups.**

The added cursor is used to establish bounded traversal facts and tests, but it is not yet the bounded 258-byte look-ahead/history source for matcher probing. Completing PNGF-02/PNGF-03 requires replacing that helper with an acknowledgement-safe ring-buffer matcher cursor, then rerunning the full requested four-target matrix.

## Self-Check: PASSED

- Task commits exist: `8b560b3`, `d36b484`.
- Summary file exists at the planned phase path.
