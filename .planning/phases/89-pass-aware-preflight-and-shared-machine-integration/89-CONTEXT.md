---
phase: 89
name: Pass-Aware Preflight and Shared-Machine Integration
status: discussed
---

# Phase 89 Context

## Goal

Prove and, only where necessary, correct the existing indexed Adam7 compression seam so every FixedOrStored request computes the exact pass-aware candidate before any output/lease/budget side effect and then uses the same acknowledged machine for eager and chunked output.

## Locked decisions

- D-01: Keep the Phase 88 additive API names and the `Stored`/`FixedOrStored` strategy enum; no Dynamic indexed path.
- D-02: Use one scalar pass-local filter-None packed producer for Stored facts, Fixed matching, and replay; no image/pass/output staging.
- D-03: Candidate comparison includes the complete Type-3 frame (PLTE, shortest canonical tRNS, IDAT, IEND) and selects Fixed on a tie.
- D-04: Preflight validates geometry, palette, exact output and exact work before exposing writer bytes or caller leases; one selected-work budget charge is the only charge.
- D-05: Legacy Stored wrappers and v0.28 non-interlaced output remain byte-frozen.
- D-06: This phase is code/test focused; hostile lease schedules and independent decoder qualification remain Phase 90.

## Acceptance criteria

1. Indexed1/2/4/8 Adam7 FixedOrStored preflight exposes a plan whose retained frame facts equal the selected Stored or Fixed candidate.
2. Exact `max_output_bytes`/`max_work` and exact budget work admit; one-less values fail with unchanged budget state.
3. Eager and chunk constructors converge on `PngEncodeMachine::new_with_indexed_profile_and_strategy`; no alternate encoder or public source-model change appears in the diff.
