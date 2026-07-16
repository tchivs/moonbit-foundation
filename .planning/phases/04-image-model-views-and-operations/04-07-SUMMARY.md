---
phase: 04-image-model-views-and-operations
plan: "07"
subsystem: image-codec-contracts
tags: [moonbit, codec, reader-writer, non-seeking, budgets, diagnostics]

requires:
  - phase: 02-bounded-core-primitives
    provides: Forward-only Reader/Writer, retained byte views, budgets, errors, and diagnostics
  - phase: 04-image-model-views-and-operations/04-03
    provides: Owned images and immutable image views
  - phase: 04-image-model-views-and-operations/04-01
    provides: Machine-readable metadata disposition
provides:
  - Prefix-only Match/NoMatch/NeedMore probing over caller-owned ByteView
  - Open decoder and encoder traits over Reader and Writer without seeking
  - Explicit codec options, limits, budgets, diagnostics, progress, and dispositions
affects: [05-bounded-ppm-p6-proof, codec-authors, image-qualification]

tech-stack:
  added: []
  patterns:
    - Caller supplies a prefix independently from the forward-only decode stream
    - Codec results report exact progress and executable metadata disposition

key-files:
  created:
    - modules/mb-image/codec/moon.pkg
    - modules/mb-image/codec/contracts.mbt
    - modules/mb-image/codec/codec_test.mbt
    - modules/mb-image/codec/codec_wbtest.mbt
  modified:
    - modules/mb-image/codec/reference_vectors_wbtest.mbt
    - scripts/fixtures/Generate-ImageVectors.ps1
    - policy/foundation.json

key-decisions:
  - "Keep probing independent from Reader state: codecs inspect only the caller-owned prefix and return Match, NoMatch, or the minimum total NeedMore length."
  - "Make decode and encode open traits over Reader and Writer alone, with explicit options, limits, authoritative budgets, diagnostics, progress, and metadata disposition."
  - "Use the existing CapabilityUnavailable code with bounded operation/context tokens for unsupported codec behavior instead of introducing a new error vocabulary."

patterns-established:
  - "Codec seam: prefix probe, forward-only decode, forward-only encode; no Seeker, path, URL, registry, global state, or concrete codec."
  - "Generated short-progress evidence exercises both Reader and Writer one byte at a time without rewind."

requirements-completed: [IMAG-07]

coverage:
  - id: D1
    description: Codec authors can probe caller-owned prefix bytes without consuming or rewinding a stream.
    requirement: IMAG-07
    verification:
      - kind: unit
        ref: "modules/mb-image/codec/codec_test.mbt; moon -C modules/mb-image test codec --target all --frozen (6/6 per target)"
        status: pass
    human_judgment: false
  - id: D2
    description: Decoder and encoder contracts require only forward-only Reader and Writer capabilities with explicit bounded inputs and inspectable results.
    requirement: IMAG-07
    verification:
      - kind: integration
        ref: "modules/mb-image/codec/codec_wbtest.mbt and reference_vectors_wbtest.mbt; generated Reader/Writer short-progress cases have zero seeker calls"
        status: pass
    human_judgment: false
  - id: D3
    description: The codec package has an exact portable interface and no ops, host, filesystem, URL, registry, or concrete-codec dependency.
    requirement: IMAG-07
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required; 169/169 workspace tests per target and exact 55-line codec interface"
        status: pass
    human_judgment: false

duration: 16min
completed: 2026-07-17
status: complete
---

# Phase 4 Plan 7: Backend-Neutral Codec Contracts Summary

**Prefix-only probing plus open forward-only Reader/Writer codec traits with explicit limits, budgets, diagnostics, progress, and metadata disposition**

## Performance

- **Duration:** 16 min
- **Completed:** 2026-07-17
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added a closed prefix probe result that cannot consume stream state and reports the minimum total prefix required.
- Added open decoder and encoder traits over `Reader` and `Writer` only, with explicit options, caller ceilings, authoritative budgets, diagnostics, exact progress, owned decode output, and metadata disposition.
- Consumed every generated codec case and proved one-byte short progress through both non-seeking Reader and Writer doubles on all four targets.
- Registered the codec package after metadata/model/storage/ops with an exact 55-line semantic interface and no reverse or ambient dependency.

## Task Commits

1. **Task 1 RED: Add failing codec contract tests** - `319ea8e` (test)
2. **Task 1 GREEN: Define bounded codec contracts** - `81b30de` (feat)
3. **Blocking fix: Keep generated codec evidence formatter-clean** - `0b99b59` (fix)
4. **Task 2: Freeze codec package boundary** - `871f903` (chore)
5. **Coverage fix: Exercise short-progress Writer seam** - `65f9cba` (test)

## Files Created/Modified

- `modules/mb-image/codec/contracts.mbt` - Probe outcomes, explicit options/limits/results, bounded capability error, and open decoder/encoder traits.
- `modules/mb-image/codec/codec_test.mbt` - Public prefix, option/limit, and forward-only decoder evidence.
- `modules/mb-image/codec/codec_wbtest.mbt` - Capability error and generated non-seeking Reader/Writer short-progress evidence.
- `modules/mb-image/codec/moon.pkg` - Exact portable inward imports and four-target declaration.
- `modules/mb-image/codec/reference_vectors_wbtest.mbt` - Canonically formatted generated codec cases.
- `scripts/fixtures/Generate-ImageVectors.ps1` - Formatter-clean deterministic codec table renderer.
- `policy/foundation.json` - Exact publication inventory, dependency allowlist, targets, and 55-line codec interface.

## Decisions Made

- Kept probe input separate from decode input so callers own buffering policy and codecs never require rewind.
- Used generic completeness/losslessness and opaque-metadata options without prescribing PPM grammar or a registry.
- Returned exact byte progress and metadata disposition from successful results while leaving codec-specific diagnostics in the caller-supplied bounded diagnostics sink.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made the pre-generated codec table formatter-clean when the package became active**
- **Found during:** Task 2 Required verification
- **Issue:** Before `codec/moon.pkg` existed, the generated codec table was outside MoonBit format qualification; activating the package exposed its compact one-line renderer and new-source formatting differences.
- **Fix:** Updated the deterministic image generator to emit canonical multiline codec cases, formatted all codec sources, and preserved byte-identical `-Check` behavior.
- **Files modified:** `scripts/fixtures/Generate-ImageVectors.ps1`, `modules/mb-image/codec/reference_vectors_wbtest.mbt`, and new codec sources
- **Committed in:** `0b99b59`

**2. [Rule 2 - Missing critical verification] Exercised short-progress Writer behavior as well as Reader behavior**
- **Found during:** Final Task 2 verification review
- **Issue:** The exact encoder trait proved Writer-only dependency, but the generated short-progress case initially exercised only the Reader double behaviorally.
- **Fix:** Added a one-byte-progress Writer double and consumed the same generated bounded-progress case through `write_all`, with zero seek capability.
- **Files modified:** `modules/mb-image/codec/codec_wbtest.mbt`
- **Committed in:** `65f9cba`

**Total deviations:** 2 auto-fixed (1 blocking formatter integration, 1 critical verification-strength gap). **Impact:** No API or product scope change.

## Issues Encountered

- The Required lane's expected negative README fixture prints a missing-file error while its enclosing fail-closed check succeeds; the lane exited 0 as designed.

## User Setup Required

None - no external services or host capabilities are required.

## Verification

- `pwsh -NoProfile -File ./scripts/fixtures/Generate-ImageVectors.ps1 -Check`: all generated image artifacts and manifest were byte-identical.
- `moon -C modules/mb-image test codec --target all --frozen`: 6/6 passed independently on js, wasm, wasm-gc, and native.
- `moon -C modules/mb-image check --target all --deny-warn --frozen`: passed on all four targets.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`: passed with 169/169 workspace tests per target, exact 55-line codec interface, publication allowlist, dependency DAG, negative fixtures, and read-only proof.

## Self-Check: PASSED

- All seven planned or necessary generator/policy files exist.
- Commits `319ea8e`, `81b30de`, `0b99b59`, `871f903`, and `65f9cba` resolve in repository history.
- No TODO/FIXME/placeholder stub or new network, filesystem, host, URL, registry, authentication, schema, Seeker, concrete-codec, or ops dependency was introduced.

## Next Phase Readiness

- Plan 04-08 can document and close the complete image boundary and remove the private scaffold.
- Phase 5 can implement bounded PPM P6 through this seam without changing prefix, Reader, Writer, budget, diagnostics, image, or disposition contracts.

---
*Phase: 04-image-model-views-and-operations*
*Completed: 2026-07-17*
