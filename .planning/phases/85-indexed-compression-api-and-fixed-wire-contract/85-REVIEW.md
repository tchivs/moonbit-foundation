---
phase: 85-indexed-compression-api-and-fixed-wire-contract
reviewed: 2026-07-24T05:58:33Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - modules/mb-image/png/encode.mbt
  - modules/mb-image/png/stream_encode.mbt
  - modules/mb-image/png/encode_test.mbt
  - modules/mb-image/png/stream_encode_test.mbt
  - modules/mb-image/png/encode_wbtest.mbt
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 85: Code Review Report

**Reviewed:** 2026-07-24T05:58:33Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The review traced both public selector families through indexed preflight and the sole acknowledged machine. Dynamic rejection precedes source admission and budget charging; Fixed selection uses palette-aware frame facts; and the new producer remains bounded and shared by Stored output, Fixed planning, and Fixed replay. The package native test suite passed (302/302). One public chunk API lacks regression coverage.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Indexed8 chunk compression selector has no regression coverage

**File:** `modules/mb-image/png/stream_encode_test.mbt:4948`
**Issue:** The new test iterates only `IndexedBitDepth::{One, Two, Four}` and invokes `PngChunkEncoder::new_indexed_with_compression_strategy`; no changed test invokes `PngChunkEncoder::new_indexed8_with_compression_strategy`. The eager Indexed8 test does not exercise caller-buffered acknowledgement, so a future divergence in the Indexed8 chunk constructor's strategy forwarding or Dynamic rejection would remain undetected.
**Fix:** Add an Indexed8 chunk case that drains explicit Stored and FixedOrStored output against the eager byte oracle, and asserts `DynamicOrFixedOrStored` returns `indexed-dynamic-compression-unavailable` without exposing an encoder or charging its budget.

---

_Reviewed: 2026-07-24T05:58:33Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
