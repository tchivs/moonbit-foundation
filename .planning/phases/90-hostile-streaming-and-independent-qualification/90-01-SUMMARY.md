---
phase: 90-hostile-streaming-and-independent-qualification
plan: "01"
subsystem: png
tags: [moonbit, png, indexed-color, adam7, deflate, crc, adler, streaming]
requires:
  - phase: 89-pass-aware-preflight-and-shared-machine-integration
    provides: exact Adam7 FixedOrStored preflight and shared acknowledged machine
provides:
  - Hostile zero/one/ragged lease qualification for Fixed Adam7 chunk output
  - Independent PNG/CRC/DEFLATE/Adler/pass-raster parser and public RGB/RGBA decode proof
  - Four-target final package gate for v0.29 indexed Adam7 compression
affects: [v0.29 milestone completion]
tech-stack:
  added: []
  patterns:
    - "Test-local wire parsers validate chunk-origin bytes without production planning helpers"
    - "Sentinel-filled leases verify accepted-only progress and sticky terminal behavior"
key-files:
  created:
    - .planning/phases/90-hostile-streaming-and-independent-qualification/90-CONTEXT.md
    - .planning/phases/90-hostile-streaming-and-independent-qualification/90-RESEARCH.md
    - .planning/phases/90-hostile-streaming-and-independent-qualification/90-01-PLAN.md
    - .planning/phases/90-hostile-streaming-and-independent-qualification/90-01-SUMMARY.md
  modified:
    - modules/mb-image/png/stream_encode_test.mbt
key-decisions:
  - "Use a 5x5 all-zero indexed fixture to force a complete Fixed candidate while making pass lengths independently auditable."
  - "Run both transparent and opaque palette variants to prove public RGBA8 and RGB8 decode outcomes."
patterns-established:
  - "Independent qualification parses CRC/chunk order, Fixed DEFLATE, Adler, raw pass length/tails, and decode results from collected bytes."
requirements-completed: [ADAM7COMP-04, ADAM7COMP-05]
coverage:
  - id: D1
    description: "Fixed Adam7 chunk output survives zero/one/ragged leases and sticky finish behavior."
    requirement: ADAM7COMP-04
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG indexed Adam7 FixedOrStored independent wire and decode qualification"
        status: pass
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG indexed Adam7 FixedOrStored released lease failure is sticky"
        status: pass
    human_judgment: false
  - id: D2
    description: "Independent parser proves Fixed DEFLATE, chunk/CRC order, Adler, pass raw lengths/tails, and canonical palette/tRNS."
    requirement: ADAM7COMP-05
    verification:
      - kind: unit
        ref: "png_phase90_parse_fixed_adam7 in modules/mb-image/png/stream_encode_test.mbt"
        status: pass
    human_judgment: false
  - id: D3
    description: "Transparent and opaque indexed fixtures decode as public RGBA8 and RGB8 across depths 1/2/4/8."
    requirement: ADAM7COMP-05
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG indexed Adam7 FixedOrStored independent wire and decode qualification"
        status: pass
    human_judgment: false
  - id: D4
    description: "The ordinary PNG package gate passes on all declared targets."
    verification:
      - kind: other
        ref: "moon test modules/mb-image/png --target all"
        status: pass
    human_judgment: false
metrics:
  duration: "~45 min"
  completed: 2026-07-24
  status: complete
---

# Phase 90: Hostile Streaming and Independent Qualification Summary

**Indexed Adam7 FixedOrStored output is now independently parseable, hostile-lease safe, and publicly decodable across all four indexed depths.**

## Accomplishments

- Added an independent test-local parser for PNG chunk order/CRC, Fixed DEFLATE, Adler-32, canonical PLTE/tRNS, and seven-pass raw lengths/tails.
- Collected eager-equivalent bytes under zero-capacity, one-byte, and ragged leases while preserving sentinel tails and sticky Finished behavior.
- Verified transparent fixtures decode as RGBA8 and opaque fixtures decode as RGB8 for Indexed1/2/4/8.
- Kept release/architecture scope unchanged; no production code change was needed.

## Verification

- `moon check modules/mb-image/png --target all` passed (warnings only).
- `moon test modules/mb-image/png --target all` passed: **320/320** on native, wasm, wasm-gc, and js.
- `git diff --check` passed.

## Next Phase Readiness

All v0.29 phase requirements are now implemented and verified. The next GSD action is milestone audit/completion and archiving, not another release-script expansion.

---
*Phase: 90-hostile-streaming-and-independent-qualification*
*Completed: 2026-07-24*
