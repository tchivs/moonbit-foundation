---
phase: 17-resumable-qoi-chunk-decode
plan: "01"
subsystem: image-codec
tags: [moonbit, qoi, streaming, chunked-decode, policy]
requires:
  - phase: 13-qoi-format-core-and-safe-decode
    provides: eager QOI parsing, limits, diagnostics, and storage contracts
provides:
  - Caller-chunk-fed QOI decoder with explicit strict completion
  - Generated-vector and hostile-schedule streaming evidence
  - Exact QOI source and public-interface policy inventory
affects: [18-resumable-qoi-chunk-encode, 19-qoi-streaming-public-evidence]
tech-stack:
  added: []
  patterns: [private resumable parser state, explicit finish terminal gate]
key-files:
  created:
    - modules/mb-image/qoi/stream_decode.mbt
    - modules/mb-image/qoi/stream_decode_test.mbt
    - modules/mb-image/qoi/stream_decode_wbtest.mbt
  modified:
    - modules/mb-image/qoi/qoi.mbt
    - modules/mb-image/qoi/pkg.generated.mbti
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
key-decisions:
  - "Streaming remains a separate QoiStreamDecoder; eager traits and Reader EOF semantics are unchanged."
  - "Only finish validates the strict QOI marker and trailing bytes; push reports precise caller-chunk acceptance."
  - "The parser owns only copied token state and a private OwnedImage, reacquiring its mutable view for each pump."
patterns-established:
  - "Resumable codecs use NeedInput plus explicit finish rather than repurposing Reader EOF."
requirements-completed: [QSTR-01, QSTR-02, QSTR-03]
coverage:
  - id: D1
    description: Caller-owned QOI chunks expose exact progress, explicit input-needed state, strict finish, and sticky terminal failures.
    requirement: QSTR-01
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test qoi --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Stream output matches eager QOI semantics across generated and hostile chunk schedules with preflight resource coverage.
    requirement: QSTR-02
    verification:
      - kind: unit
        ref: modules/mb-image/qoi/stream_decode_wbtest.mbt
        status: pass
    human_judgment: false
  - id: D3
    description: Exact QOI source, file, target, and generated-interface policy assertions fail closed.
    requirement: QSTR-03
    verification:
      - kind: integration
        ref: pwsh Assert-QoiFoundationPolicy and Assert-QoiQualificationNegativeFixtures
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-07-20
status: complete
---

# Phase 17 Plan 01: Resumable QOI Chunk Decode Summary

**A private, bounded QOI state machine now accepts arbitrary caller-owned chunks and returns one eager-equivalent image only after explicit strict completion.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-20T13:14:52Z
- **Completed:** 2026-07-20T13:21:03Z
- **Tasks:** 2/2
- **Files modified:** 8

## Accomplishments

- Added `QoiStreamDecoder`, consumed-byte `QoiStreamPushResult`, and explicit `NeedInput`/typed-failure push outcomes without altering the eager codec traits or Reader contract.
- Preserved eager header preflight, limits, budget charging, descriptor, pixel, disposition, diagnostics, and byte-accounting behavior while never exposing partial image storage.
- Added generated hostile-chunk/resource-state tests and exact broad/scoped QOI policy-interface inventory checks.

## Task Commits

1. **Task 1: Define and implement the resumable QOI decoder contract** — `3263b55` (`feat`)
2. **Task 2: Prove bounded state behavior and freeze the QOI policy inventory** — `6476dc5` (`test`)

## Files Created/Modified

- `modules/mb-image/qoi/qoi.mbt` — public stream decoder and push result contract.
- `modules/mb-image/qoi/stream_decode.mbt` — private copied-token parser, resource preflight, strict finish, and sticky terminal states.
- `modules/mb-image/qoi/stream_decode_test.mbt` — public progress, terminal, copied-buffer, and eager-equivalence tests.
- `modules/mb-image/qoi/stream_decode_wbtest.mbt` — generated-schedule, parser-state, and budget/preflight tests.
- `modules/mb-image/qoi/pkg.generated.mbti` — regenerated compiler-derived interface (repository-ignored generated output).
- `policy/foundation.json` and `scripts/quality/Assert-Policy.ps1` — exact QOI stream inventory and broad/scoped fail-closed assertions.

## Decisions Made

- Streaming is a separate API so temporary caller input absence cannot change Reader EOF behavior.
- Marker/trailing validation is deferred to `finish`, while parser state copies only the bytes required for partial tokens and the marker.
- The controlled broad-policy fixture temporarily aligns only the known ops import inventory so it can prove QOI source-order coverage independently.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `pkg.generated.mbti` is regenerated and validated but repository-ignored, so it remains an intentional generated workspace artifact rather than a tracked task commit file.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 18 can add resumable encoding beside this decoder contract. Phase 19 can use the explicit stream surface for final public cross-target evidence without changing eager QOI APIs.

## Self-Check: PASSED

- Confirmed all declared stream source, test, policy, generated-interface, and summary files exist.
- Confirmed task commits `3263b55` and `6476dc5` exist in repository history.
