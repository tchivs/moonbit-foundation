---
phase: 35-png-dynamic-strategy-compatibility
plan: "01"
subsystem: png-encoding
tags: [png, deflate, compatibility, strategy, moonbit]
requires:
  - phase: 33-fixed-or-stored-png-planning-and-emission
    provides: frozen FixedOrStored planning and emission route
provides:
  - additive DynamicOrFixedOrStored public compression strategy
  - frozen eager and caller-buffered PNG compatibility vectors
  - documented strict complete-PNG dynamic selection contract
affects: [phase-36-dynamic-huffman-implementation]
requirements-completed: [PNGD-01]
tech-stack:
  added: []
  patterns: [public-enum-addition, shared-preflight-routing, byte-vector-compatibility-tests]
key-files:
  created:
    - .planning/phases/35-png-dynamic-strategy-compatibility/35-01-SUMMARY.md
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
    - policy/foundation.json
decisions:
  - DynamicOrFixedOrStored shares the unchanged FixedOrStored candidate route until Phase 36 owns dynamic DEFLATE planning and emission.
  - Stored and FixedOrStored retain independent complete eager and hostile-capacity caller-buffered byte-vector baselines.
metrics:
  duration: 24m
  completed: 2026-07-22
  tasks_completed: 2
  files_modified: 6
status: complete
---

# Phase 35 Plan 01: Dynamic Strategy Compatibility Summary

Added the opt-in DynamicOrFixedOrStored public contract while preserving frozen Stored and FixedOrStored PNG output bytes.

## Tasks Completed

1. Added RED compatibility-vector tests for eager and caller-buffered PNG factories, then committed them as `0d8c1a7`.
2. Added the public enum case, documented the strict complete-PNG win/tie contract, routed it through the existing bounded FixedOrStored preflight, and registered the generated interface as `a9fee9f`.

## Implementation Notes

- `PngCompressionStrategy::DynamicOrFixedOrStored` remains equality-comparable and is accepted by both configured factories.
- DynamicOrFixedOrStored currently returns the exact unchanged FixedOrStored plan. No dynamic plan, tree, matcher, emitter, framing, checksum, budget, acknowledgement, or terminal behavior was added or changed.
- Public documentation reserves Dynamic output for a strict complete-PNG size win and retains FixedOrStored on ties; it records the phase exclusions for filtering, matching/history, staging, optimization, FFI/host streaming, APNG, colour, and metadata.

## Verification

- RED: `moon -C modules/mb-image test png --target native --frozen -f '*dynamic strategy*'` failed before production edits because `DynamicOrFixedOrStored` did not exist.
- Quick interface compile: `moon -C modules/mb-image info --target all --frozen` passed and regenerated the PNG interface containing the additive enum case.
- Four-target named selectors passed: `moon -C modules/mb-image test png --target {js|wasm|wasm-gc|native} --frozen -f '*dynamic strategy*'` — 2/2 tests on each target.
- The full `--target all` PNG suite was started in the earlier execution window but interrupted before a result was available; it is not claimed as passing.
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` was not run, per the operator's explicit resume instruction to avoid the PNG quality lane. This remains follow-up verification, not a passing result.

## Deviations from Plan

None - implementation scope and code changes executed exactly as planned. Verification was intentionally narrowed by the operator after the initial long-running full-suite attempt was interrupted.

## Known Stubs

None. DynamicOrFixedOrStored intentionally reuses the existing complete FixedOrStored route in this compatibility phase; it is a documented contract, not an unwired placeholder.

## Threat Surface

No new network, authentication, file-access, or trust-boundary surface was introduced. The strategy enters the existing atomic preflight and retains its capability, geometry, output, work, and budget validation.

## Self-Check: PASSED

- Confirmed all six planned source, test, and policy files exist.
- Confirmed commits `0d8c1a7` and `a9fee9f` exist in git history.
