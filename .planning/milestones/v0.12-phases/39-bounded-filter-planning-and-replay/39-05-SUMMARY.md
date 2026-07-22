---
phase: 39-bounded-filter-planning-and-replay
plan: "05"
subsystem: png-encoder
tags: [png, adaptive-filter, deflate, tdd, gap-closure]
status: blocked
dependency_graph:
  requires: [39-04]
  provides: [reproducible-fixed-dynamic-matcher-gap]
  affects: [png-adaptive-preflight]
tech_stack:
  added: []
  patterns: [MoonBit white-box TDD]
key_files:
  created: []
  modified: [modules/mb-image/png/encode_wbtest.mbt, modules/mb-image/png/stream_encode_wbtest.mbt]
decisions: []
metrics:
  duration: "~20m"
  completed_date: 2026-07-22
---

# Phase 39 Plan 05: Bounded Adaptive Matcher Replay Summary

Added RED coverage that proves Fixed and Dynamic planning undercount their Adaptive traversal work; the bounded matcher implementation remains unresolved.

## Completed Work

- Added FixedOrStored assertions for Stored plus Fixed planning traversal facts and one replay traversal.
- Added DynamicOrFixedOrStored assertions for Stored, Fixed, frequency/fingerprint, exact-bit, and replay traversal facts.
- Added a stream-side Fixed accounting assertion at the acknowledgement boundary.

## Evidence

- RED native selector `*adaptive match cursor*` failed as intended: Fixed reported 2 resolved planning rows instead of 4, and Dynamic reported 6 instead of 8.
- Fixed-specific matcher accounting passed on JS and native during the attempted GREEN implementation.
- Dynamic-specific implementation verification failed: the new Dynamic preflight returned an error on JS, while the native test executable terminated with `0xc0000409`.
- Every temporary Plan 05 target directory was removed with `.NET` `Directory.Delete` in `finally` and verified absent.

## Deviations from Plan

### Deferred Issue

**[Rule 3 - Blocking implementation defect] Dynamic acknowledgement-safe matcher replay could not be completed.**

- **Found during:** Task 2 GREEN implementation.
- **Issue:** A preliminary 262-byte cursor implementation passed Fixed traversal accounting but failed Dynamic preflight/replay; retaining it would leave an unverified regression in the shared source.
- **Resolution:** Restored `encode.mbt` and `stream_encode.mbt` to their committed Plan 04 baseline. The failing tests remain committed as a precise reproduction.
- **Required follow-up:** Implement and verify the bounded cursor for Dynamic frequency, bit-counting, and replay before wiring the complete four-target matrix.

## Known Stubs

None.

## Self-Check: PASSED

- RED commit `fee6fe2` exists.
- The two regression tests and this summary exist at their planned paths.
