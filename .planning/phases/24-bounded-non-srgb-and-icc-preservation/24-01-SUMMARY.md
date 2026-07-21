---
phase: 24-bounded-non-srgb-and-icc-preservation
plan: "01"
subsystem: png-colour-metadata
tags: [png, iccp, metadata, deflate, portable]
requires:
  - phase: 23-png-colour-declaration-and-srgb-semantics
    provides: strict authenticated colour chunk grammar and encoded-sRGB metadata
provides:
  - bounded retained gAMA/cHRM and iCCP non-sRGB metadata
  - typed no-output PNG encoding boundary for retained semantics
affects: [phase-25-portable-colour-conformance-evidence]
tech-stack:
  added: []
  patterns: [authenticated declaration transport, bounded private ICC inflate]
key-files:
  created: []
  modified: [modules/mb-image/png/structural.mbt, modules/mb-image/png/png.mbt, scripts/fixtures/Generate-PngDecodeVectors.ps1]
key-decisions:
  - "Retained non-sRGB sources use opaque profiles and LinearSrgb transfer identity so encoded-sRGB-only operations remain unavailable."
  - "iCCP supports bounded RGB/gray ICC envelopes using the package-private pure-MoonBit DEFLATE machinery."
patterns-established:
  - "ICC profile names are canonical PNG opaque metadata while profile bytes stay in ProfileIdentity."
requirements-completed: [PNGCM-03, PNGCM-04]
coverage:
  - id: D1
    description: Bounded legacy and ICC colour declarations retain explicit non-sRGB metadata.
    requirement: PNGCM-03
    verification:
      - kind: integration
        ref: moon -C modules/mb-image test png --target all --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Canonical PNG encoding does not discard retained non-sRGB semantics.
    requirement: PNGCM-04
    verification:
      - kind: integration
        ref: modules/mb-image/png/encode_test.mbt#PNG encoder rejects retained non-sRGB metadata before output
        status: pass
    human_judgment: false
duration: 40min
completed: 2026-07-21
status: complete
---

# Phase 24 Plan 01: Bounded Non-sRGB and ICC Preservation Summary

**Portable PNG decoding retains authenticated legacy and bounded ICC declarations without transforming pixels or permitting lossy canonical re-encoding.**

## Accomplishments

- Retained legal gAMA/cHRM values as canonical opaque metadata with a non-encoded-sRGB identity.
- Added bounded private iCCP zlib/DEFLATE decoding, ICC size/signature/colour-space validation, and authoritative precedence.
- Regenerated manifest-backed vectors that assert metadata values, ICC profile ownership, malformed compression, and no-output encoding rejection across all targets.

## Task Commits

1. Task 1 RED test: `d80eb7b`.
2. Tasks 1–2 implementation: `3bfba7c`.
3. Task 3 generated evidence: `0f8e5f9`.

## Verification

- `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` — passed (3,772 cases).
- `moon -C modules/mb-image test png --target all --frozen` — passed (39/39 on wasm, wasm-gc, js, native).
- `moon -C modules/mb-image test model --target all --frozen` — passed (13/13 on all targets).
- `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` — passed.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Test correctness] Increased the focused retained-metadata test allocation envelope to include profile, opaque metadata, and image allocations.
2. [Rule 3 - Fixture generation] Added deterministic generator assembly for the minimal valid RGB ICC profile, avoiding manually embedded opaque profile bytes.

## Known Stubs

None.

## Self-Check: PASSED

All committed implementation, generated corpus, and verification commands are present and passed.
