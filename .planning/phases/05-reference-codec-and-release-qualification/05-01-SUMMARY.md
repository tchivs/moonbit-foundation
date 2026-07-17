---
phase: 05-reference-codec-and-release-qualification
plan: "01"
subsystem: image-codec-parser
tags: [moonbit, ppm, p6, parser, bounded-input, four-target]

requires:
  - phase: 02-bounded-core-primitives
    provides: Checked UInt64 arithmetic, stable portable errors, budgets, bytes, and forward-only I/O contracts
  - phase: 04-image-model-views-and-operations/04-07
    provides: Prefix-only codec probing and open decoder/encoder traits
provides:
  - Explicit PPM parser ceilings and behavior-free decoder/encoder values
  - Pure prefix-only strict P6 recognition
  - Forward-only byte-state header parser with checked decimal accumulation
  - Stable grammar, overflow, capability, and independent-limit failures
affects: [05-02-ppm-decode, 05-03-ppm-encode-and-evidence, release-qualification]

tech-stack:
  added: []
  patterns:
    - One pre-raster byte transition per parser step with no string or Int parsing
    - Independent header, token, comment-byte, and comment-count ceilings
    - Header completion consumes exactly one maxval separator and never examines raster data

key-files:
  created:
    - modules/mb-image/ppm/moon.pkg
    - modules/mb-image/ppm/ppm.mbt
    - modules/mb-image/ppm/parser.mbt
    - modules/mb-image/ppm/parser_wbtest.mbt
  modified: []

key-decisions:
  - "Keep PpmDecoder and PpmEncoder behavior-free in Plan 01; complete codec trait implementations remain exclusively in Plans 02 and 03."
  - "Treat comment payload bytes as the independently bounded bytes after # and before CR or LF; the introducer and terminator remain covered by the total header ceiling."
  - "Map malformed grammar to Data/InvalidEncoding, decimal overflow to InvalidInput/ArithmeticOverflow, non-255 maxval to Capability/CapabilityUnavailable, and parser ceilings to Resource/BudgetExceeded."

patterns-established:
  - "PPM parser errors always use operation ppm-header and fixed bounded context tokens."
  - "Chunk scheduling cannot affect parser state because the parser consumes exactly one byte per transition."

requirements-completed: [QUAL-01, QUAL-03]

coverage:
  - id: D1
    description: Strict P6 prefix recognition and explicit nonzero parser ceilings are portable and inspectable.
    requirement: QUAL-01
    verification:
      - kind: unit
        ref: "modules/mb-image/ppm/parser_wbtest.mbt; moon test --frozen --target all --package moonbit-foundation/mb-image/ppm (9/9 per target)"
        status: pass
    human_judgment: false
  - id: D2
    description: The byte-state header parser rejects malformed syntax, overflow, unsupported maxval, and every independent parser ceiling before allocation.
    requirement: QUAL-01
    verification:
      - kind: unit
        ref: "modules/mb-image/ppm/parser_wbtest.mbt#overflow unsupported maxval and every ceiling have exact errors"
        status: pass
    human_judgment: false
  - id: D3
    description: Valid and invalid headers have identical results across deterministic chunk schedules and leave authoritative budgets unchanged on failure.
    requirement: QUAL-03
    verification:
      - kind: unit
        ref: "modules/mb-image/ppm/parser_wbtest.mbt#all deterministic chunk schedules preserve completion and failure"
        status: pass
      - kind: unit
        ref: "modules/mb-image/ppm/parser_wbtest.mbt#header failures leave an authoritative budget unchanged"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-17
status: complete
---

# Phase 5 Plan 1: Strict P6 Contract and Header Parser Summary

**Portable strict-P6 values and a checked one-byte header state machine with independent resource ceilings and stable structured failures**

## Performance

- **Duration:** 25 min
- **Completed:** 2026-07-17T00:15:45Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added validated `PpmParserLimits`, behavior-free `PpmDecoder`/`PpmEncoder` values, and a pure caller-prefix P6 probe without introducing codec methods early.
- Added a forward-only parser for positive ASCII width/height and maxval 255 with bounded whitespace/comments, checked full-width decimal arithmetic, and no allocation seam.
- Proved exact structured error classes, all four independent ceilings, first-raster-byte isolation, chunk-schedule equivalence, and unchanged authoritative budgets on failure.
- Passed 9/9 focused PPM tests on each of js, wasm, wasm-gc, and native plus the full mb-image four-target deny-warning check.

## Task Commits

1. **Task 1 RED: Add failing PPM contract tests** - `53d2b7c` (test)
2. **Task 1 GREEN: Define strict PPM codec values** - `75e8c84` (feat)
3. **Task 2 RED: Add failing bounded header parser tests** - `4e37f21` (test)
4. **Task 2 GREEN: Implement bounded P6 header parser** - `fde14f0` (feat)

## Files Created/Modified

- `modules/mb-image/ppm/moon.pkg` - Closed four-target imports for codec types, bytes, checked arithmetic, errors, and test-only budget evidence.
- `modules/mb-image/ppm/ppm.mbt` - Public parser limits and codec values plus package-private prefix recognition.
- `modules/mb-image/ppm/parser.mbt` - Closed byte-state grammar, counters, checked decimal accumulation, header result, and error matrix.
- `modules/mb-image/ppm/parser_wbtest.mbt` - Contract, transition, adversarial grammar, ceiling, chunk, raster-boundary, and budget evidence.

## Decisions Made

- Comments begin only where whitespace is grammatically accepted; `#` inside a numeric token is invalid decimal syntax.
- CR and LF each terminate a comment; CRLF remains valid because the following LF is accepted as ordinary inter-token whitespace.
- Token and comment counters reset per token/comment while total header bytes and comment count remain cumulative.
- Parser-limit construction rejects zero using `Resource/BudgetExceeded` and the exact dimension token, keeping impossible unbounded configurations out of parser state.

## Deviations from Plan

None - plan execution stayed within the four declared PPM files and added no decoder/encoder trait method, option type, placeholder, registry, seeker, host, filesystem, storage, or operations dependency.

## Issues Encountered

- The full Required lane reached the existing mb-image package allowlist after all 183 workspace tests passed per target, then rejected the new `ppm` package as unregistered. This is an expected staged integration point: Plan 05-03 explicitly owns `policy/foundation.json` and the image quality scripts alongside completed encode/evidence. Plan 01 did not broaden into those later-plan files.
- The Required lane's expected missing-README negative emitted its usual canonicalization error while the enclosing negative check continued normally.

## User Setup Required

None.

## Verification

- `moon -C modules/mb-image check --frozen --deny-warn --target all`: passed.
- `moon test --frozen --target all --package moonbit-foundation/mb-image/ppm`: 9/9 passed on each required target.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`: all governance, generated evidence, source negatives, documentation, and 183/183 tests per target passed through interface checks; stopped at the intentionally not-yet-updated mb-image package allowlist for `ppm`, owned by Plan 05-03.

## Self-Check: PASSED

- All four planned PPM files exist.
- Commits `53d2b7c`, `75e8c84`, `4e37f21`, and `fde14f0` resolve in repository history.
- No TODO, FIXME, placeholder decode/encode method, trait implementation, external dependency, or new host/network/filesystem/security surface was introduced.

## Next Phase Readiness

- Plan 05-02 can implement the complete `ImageDecoder` trait over this parser without changing its limits, prefix semantics, or stable error vocabulary.
- Plan 05-03 remains responsible for the complete encoder, generated corpus, policy/interface registration, and Required-lane package allowlist closure.

---
*Phase: 05-reference-codec-and-release-qualification*
*Completed: 2026-07-17*
