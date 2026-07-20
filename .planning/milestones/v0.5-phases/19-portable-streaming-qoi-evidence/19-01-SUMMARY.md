---
phase: 19-portable-streaming-qoi-evidence
plan: "01"
subsystem: image-codec
tags: [moonbit, qoi, streaming, conformance, portable-evidence]
requires:
  - phase: 17-resumable-qoi-chunk-decode
    provides: caller-owned chunk decoder with explicit strict completion
  - phase: 18-resumable-qoi-buffer-encode
    provides: caller-owned lease encoder with canonical output progress
provides:
  - Generated hostile QOI input and output schedules with QSTR-06 provenance
  - Four-target progress, canonical-byte, finish, and terminal-state evidence
  - One portable streaming decode-flip-encode example with QOI-only isolation proof
affects: [v0.5 milestone completion, qoi streaming conformance]
tech-stack:
  added: []
  patterns: [generated stream schedules, explicit stream counters, isolated quality lane]
key-files:
  created: []
  modified:
    - fixtures/qoi/cases.json
    - modules/mb-image/qoi/generated_vectors.mbt
    - modules/mb-image/qoi/stream_decode_wbtest.mbt
    - modules/mb-image/qoi/stream_encode_wbtest.mbt
    - examples/qoi-portable/main/main.mbt
    - scripts/quality/Invoke-MoonQuality.ps1
key-decisions:
  - "Hostile schedule identities and capacities are generator-owned fixture data, not duplicated in tests."
  - "qoi-portable is the sole public consumer and surfaces its fixed stream schedules and counters in one exact line."
  - "The selected QOI quality lane dispatches through its isolation probe and directly exercises the scoped public example."
patterns-established:
  - "Streaming fixture tests advance a schedule turn even for a zero-capacity call and assert cumulative progress plus post-terminal behavior."
requirements-completed: [QSTR-06, QSTR-07]
coverage:
  - id: D1
    description: Generated QOI vectors exercise named hostile input/output schedules with exact progress, output bytes, strict completion, and sticky terminals on all portable targets.
    requirement: QSTR-06
    verification:
      - kind: unit
        ref: moon -C modules/mb-image test qoi --target all --frozen
        status: pass
      - kind: integration
        ref: pwsh -File scripts/fixtures/Generate-QoiVectors.ps1 -Check
        status: pass
    human_judgment: false
  - id: D2
    description: The existing qoi-portable executable streams fixed chunks through decode, flip_horizontal, and fixed output leases with an exact four-target evidence line and scoped lane isolation.
    requirement: QSTR-07
    verification:
      - kind: integration
        ref: pwsh -File scripts/quality/Test-PublicExamples.ps1 -Example qoi -Mode workspace -Target all -IsolationProbe
        status: pass
      - kind: integration
        ref: pwsh -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Qoi
        status: pass
    human_judgment: false
duration: 6min
completed: 2026-07-20
status: complete
---

# Phase 19 Plan 01: Portable Streaming QOI Evidence Summary

**Generated hostile QOI schedules now prove four-target stream progress, and the single public QOI example performs streaming decode → horizontal flip → streaming canonical encode.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-20T22:09:21+08:00
- **Completed:** 2026-07-20T22:14:40+08:00
- **Tasks:** 3/3
- **Files modified:** 13

## Accomplishments

- Split repository-derived stream schedules into named hostile input and output capacities, regenerated the MoonBit helpers, and recorded QSTR-06 in fixture provenance.
- Exercised every generated valid vector through zero/one-byte and token/marker schedules while checking per-call and cumulative progress, canonical output, strict finish, and terminal stickiness on js, wasm, wasm-gc, and native.
- Upgraded qoi-portable in place to a fixed public streaming decode → flip → streaming encode route, documented caller-owned leases, and made the QOI lane execute its isolation proof directly.

## Task Commits

1. **Task 1: Generate boundary-complete hostile streaming schedules** — `016dcde` (`feat`)
2. **Task 2: Prove all generated vectors under adversarial stream progress schedules** — `ee1535e` (`test`)
3. **Task 3: Upgrade qoi-portable to the public streaming workflow and freeze its QOI-only evidence** — `26953c4` (`test`, RED) and `522f09e` (`feat`, GREEN)

## Files Created/Modified

- `fixtures/qoi/cases.json`, `scripts/fixtures/Generate-QoiVectors.ps1`, and `modules/mb-image/qoi/generated_vectors.mbt` — deterministic named input/output hostile schedule source and generated helpers.
- `fixtures/manifest.json` — current fixture digest and explicit QSTR-06 expected use.
- `modules/mb-image/qoi/stream_decode_test.mbt`, `stream_decode_wbtest.mbt`, `stream_encode_test.mbt`, and `stream_encode_wbtest.mbt` — generated schedule progress, canonical-byte, finish, and sticky-terminal evidence.
- `examples/qoi-portable/main/main.mbt` — fixed chunked public decoder and fixed caller-owned output-lease encoder around the existing horizontal flip.
- `modules/mb-image/README.mbt.md`, `scripts/quality/Test-PublicExamples.ps1`, and `scripts/quality/Invoke-MoonQuality.ps1` — public streaming documentation, exact evidence contract, and selected-lane isolation execution.

## Decisions Made

- Keep the existing qoi-portable executable as the only public proof; no workspace member, host adapter, or additional codec was added.
- Preserve QOI scope by running the lane through `Assert-QoiLaneIsolation`, which verifies the exact four-stage trace and direct isolation-probe invocation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed the obsolete eager I/O import from qoi-portable**
- **Found during:** Task 3 verification
- **Issue:** Replacing eager Reader/Writer use left `mb-core/io` unused; its multi-line compiler warning was interpreted as public-example output on wasm and broke the exact one-line evidence assertion.
- **Fix:** Removed the unused dependency from `examples/qoi-portable/main/moon.pkg` and its public import allowlist entry.
- **Files modified:** `examples/qoi-portable/main/moon.pkg`, `scripts/quality/Test-PublicExamples.ps1`
- **Verification:** Four-target public-example isolation probe and QOI lane both pass.
- **Committed in:** `522f09e`

**2. [Rule 3 - Blocking] Repaired stale completion fields after the state handler could not advance the plan**
- **Found during:** Plan metadata update
- **Issue:** The pre-existing `STATE.md` recorded `Plan: Not started`, so `state.advance-plan` could not parse its plan position after the plan had completed.
- **Fix:** Updated the current position, milestone text, and Phase 19 roadmap completion fields to match the generated summary and completed requirement traceability.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** Requirement completion is recorded for QSTR-06 and QSTR-07; the roadmap lists Plan 19 as 1/1 Complete.

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** The dependency removal preserved the one-line evidence contract, and the planning metadata repair recorded the completed state; neither added a product capability or route.

## Issues Encountered

- Existing formatter-only changes in QOI implementation files were left unmodified and unstaged because they were outside this plan's owned files.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- QSTR-06 and QSTR-07 have reproducible four-target evidence, completing the v0.5 portable streaming scope.
- PNG/DEFLATE, FFI, registry, publication, release automation, credentials, and source-snapshot work remain out of scope.

## Self-Check: PASSED

- Confirmed every plan artifact and `19-01-SUMMARY.md` exists.
- Confirmed task commits `016dcde`, `ee1535e`, `26953c4`, and `522f09e` exist in repository history.
