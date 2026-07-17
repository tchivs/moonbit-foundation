---
phase: 05-reference-codec-and-release-qualification
plan: "02"
subsystem: image-codec-decode
tags: [moonbit, ppm, p6, streaming, budgets, four-target]

requires:
  - phase: 05-reference-codec-and-release-qualification/05-01
    provides: Strict P6 values, pure prefix probe, and bounded one-byte header parser
  - phase: 04-image-model-views-and-operations
    provides: Validated descriptors, atomic OwnedImage allocation, mutable callback authority, and codec contracts
provides:
  - Complete public ImageDecoder implementation for PpmDecoder
  - Checked strict-P6 preflight and one authoritative output allocation/work charge
  - Exact direct payload fill, truncation/progress failures, and strict one-byte EOF probe
affects: [05-03-ppm-encode-and-evidence, conformance, release-qualification]

tech-stack:
  added: []
  patterns:
    - One bounded scratch byte adapts forward-only Reader transitions without buffering input
    - Descriptor-derived output charges occur once after all codec ceilings pass
    - Raster bytes fill callback-scoped MutImageView authority directly

key-files:
  created:
    - modules/mb-image/ppm/decode.mbt
    - modules/mb-image/ppm/decode_wbtest.mbt
  modified:
    - modules/mb-image/ppm/decode_test.mbt
    - modules/mb-image/ppm/moon.pkg
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1

key-decisions:
  - "Count decode work as exact header bytes plus payload bytes and charge it with the single descriptor-derived output allocation."
  - "Use one private one-byte scratch owner to bridge Reader's capability-safe ReadWindow while retaining only one authoritative caller-budget output allocation."
  - "Always enforce the strict single-image EOF probe; DecodeOptions cannot broaden the locked PPM subset."

patterns-established:
  - "Payload stream failures are remapped to ppm-payload with exact total requested and completed counts."
  - "The successful bytes_read count excludes the zero-byte EOF observation and equals header plus raster bytes."

requirements-completed: [QUAL-01, QUAL-03]

coverage:
  - id: D1
    description: Strict P6 decode validates checked shape, codec ceilings, and authoritative budgets before one output allocation.
    requirement: QUAL-01
    verification:
      - kind: unit
        ref: "modules/mb-image/ppm/decode_test.mbt#every codec ceiling rejects before the authoritative output charge"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false
  - id: D2
    description: Forward-only payload fill handles short progress, truncation, zero progress, backend failure, and exact trailing-data rejection.
    requirement: QUAL-03
    verification:
      - kind: unit
        ref: "modules/mb-image/ppm/decode_test.mbt; moon test --frozen --target all --package moonbit-foundation/mb-image/ppm (16/16 per target)"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-07-17
status: complete
---

# Phase 5 Plan 2: Bounded Strict P6 Decode Summary

**Forward-only strict-P6 decoding with checked preflight, one authoritative image charge, direct callback-scoped raster fill, and exact single-image completion**

## Performance

- **Duration:** 35 min
- **Completed:** 2026-07-17
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Completed the public `ImageDecoder` implementation exclusively in `decode.mbt`, reusing Plan 01's pure probe and byte-state parser.
- Built tight packed encoded-sRGB `Rgb8`/TopLeft descriptors only after checked payload, input, output, shape, pixel, and work preflight.
- Filled raster bytes directly through callback-scoped mutable image authority with exact truncation, no-progress, and backend-failure counts.
- Required a one-byte EOF observation after every raster and rejected any trailing or concatenated image data with `ppm-trailing-data`.
- Passed 16/16 focused tests on each required target and the full Required lane at 190/190 workspace tests per target.

## Task Commits

1. **Task 1 RED: Add failing strict P6 decode contract** - `3243c49` (test)
2. **Tasks 1-2 GREEN: Implement bounded strict P6 decode and exact policy** - `e920d6b` (feat)
3. **Verification fix: Canonicalize decoder test formatting** - `8fb0fd7` (style)

## Files Created/Modified

- `modules/mb-image/ppm/decode.mbt` - Complete probe/decode trait behavior, checked preflight, descriptor construction, direct payload fill, and EOF probe.
- `modules/mb-image/ppm/decode_test.mbt` - Public success, budget/codec limit, progress, truncation, comment-boundary, raster, trailing, and concatenation evidence.
- `modules/mb-image/ppm/decode_wbtest.mbt` - Full-width checked arithmetic evidence.
- `modules/mb-image/ppm/moon.pkg` - Exact decoder dependencies.
- `policy/foundation.json` - Exact package contents, imports, and 22-line semantic interface.
- `scripts/quality/Assert-Policy.ps1` - Closed complete PPM decoder DAG assertion.

## Decisions Made

- Parser and output work are one deterministic `header_bytes + payload_bytes` scalar.
- A private one-byte scratch allocation is not charged to the caller budget; the caller budget observes exactly one descriptor-derived output allocation.
- Trailing-data enforcement is intrinsic to this strict single-image codec and does not depend on a permissive option.

## Deviations from Plan

None - plan executed as specified. The final formatting-only commit corrected the canonical source layout found by the Required format gate without changing behavior.

## Issues Encountered

- The first complete Required run found one non-canonical struct literal in `decode_test.mbt`; canonical formatting was applied and the full lane then passed.

## User Setup Required

None.

## Verification

- `moon test --frozen --target native --package moonbit-foundation/mb-image/ppm`: 16/16 passed.
- `moon test --frozen --target all --package moonbit-foundation/mb-image/ppm`: 16/16 passed on js, wasm, wasm-gc, and native.
- `moon -C modules/mb-image check --frozen --deny-warn --target native`: passed.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`: passed with 190/190 tests per target, exact 22-line PPM interface, contents, DAG, and read-only proof.

## Self-Check: PASSED

- All planned decoder implementation and evidence files exist.
- Commits `3243c49`, `e920d6b`, and `8fb0fd7` resolve in repository history.
- No decoder/encoder stub, TODO, FIXME, ambient filesystem/network access, seeking, registry, or whole-input buffering was introduced.

## Next Phase Readiness

- Plan 05-03 can add the canonical strict-P6 encoder and generated codec evidence without modifying decoder ownership.
- The exact PPM policy is green with the complete decoder and behavior-free encoder boundary.

---
*Phase: 05-reference-codec-and-release-qualification*
*Completed: 2026-07-17*
