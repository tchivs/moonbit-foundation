---
phase: 58-portable-adam7-public-evidence
plan: "03"
subsystem: png-portable-qualification
tags: [png, adam7, graya16, public-api, wasm, wasm-gc, js, native]
requires:
  - phase: 58-portable-adam7-public-evidence
    provides: public eager wire/decode and chunk hostile-schedule evidence
provides:
  - one serialized four-target public PNG package qualification run
  - audited two-public-test-file Phase 58 implementation boundary
affects: [v0.18-milestone-audit, modules/mb-image/png/encode_test.mbt, modules/mb-image/png/stream_encode_test.mbt]
tech-stack:
  added: []
  patterns: [ordinary-moon-package-test-as-portable-gate, public-evidence-only-diff-audit]
key-files:
  created: [.planning/phases/58-portable-adam7-public-evidence/58-03-SUMMARY.md]
  modified: []
decisions:
  - "Use the ordinary frozen public PNG package command as the sole four-target qualification gate; do not add a release runner or target wrapper."
  - "Keep v0.18 functional changes confined to the two public PNG test files; planning records are the only other phase artifacts."
metrics:
  duration: "~6 minutes"
  completed: "2026-07-23"
  tasks_completed: 2
  files_modified: 1
requirements-completed: [GRAYA16A7-03]
coverage:
  - id: D-05
    description: "The complete public PNG package passes unchanged on wasm, wasm-gc, js, and native from one serialized command."
    requirement: GRAYA16A7-03
    verification:
      - kind: integration
        ref: "moon -C modules/mb-image test png --target all --frozen"
        status: pass
    human_judgment: false
  - id: scoped-public-evidence
    description: "Phase 58 functional changes are limited to the eager and caller-buffered public PNG test surfaces."
    requirement: GRAYA16A7-03
    verification:
      - kind: other
        ref: "git diff --check; phase change-surface audit"
        status: pass
    human_judgment: false
status: complete
---

# Phase 58 Plan 03: Portable Adam7 Public Evidence Qualification Summary

The normal frozen PNG package suite now qualifies the completed GrayAlpha16 Adam7 public evidence with 219 passing tests on each portable target, while the Phase 58 functional diff remains exactly its two public test files.

## Completed Tasks

1. **Serialized four-target public PNG evidence gate**
   - Ran `moon -C modules/mb-image test png --target all --frozen` after Plans 58-01 and 58-02 were complete.
   - The one command passed on wasm, wasm-gc, js, and native: **219/219** on every target.

2. **Final Phase 58 implementation-surface audit**
   - `git diff --check` passed for both the phase range and working tree.
   - Relative to the Phase 58 fork point, the only functional files are `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt`; every other changed path is a Phase 58 planning artifact.
   - The evidence uses public `PngEncoder`, `PngChunkEncoder`, and `PngDecoder` seams. No production/API, fixture, script, target-specific, FFI, staging, source-copy, debug, recover, or probe artifact was introduced.

## Verification

- `moon -C modules/mb-image test png --target all --frozen` — passed: wasm 219/219, wasm-gc 219/219, js 219/219, native 219/219.
- `git diff --check` — passed with no whitespace errors.
- Phase-scoped `git diff --name-status` — functional surface limited to `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt`.
- Recursive source-copy/debug/recover/probe directory audit — none found. The pre-existing ignored `_build/` directory is MoonBit build output, not a copied source tree, and was not added to Git.

## Task Commits

This plan is verification-only; it creates no implementation or test commit. The following metadata commit records the evidence and state transition.

## Decisions Made

- Preserve the single ordinary MoonBit all-target command as the reproducible portable gate instead of creating release automation or wrapper scripts.
- Treat the two public test files as the complete functional boundary for Phase 58; do not widen scope in response to a passing qualification run.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- `58-03-SUMMARY.md` records the actual four-target counts and scoped-diff result.
- The phase range contains no production, script, fixture, FFI, target-branch, source-copy, debug, recover, or probe addition.
- Both public evidence files and their Plan 58 summaries exist in the current history.
