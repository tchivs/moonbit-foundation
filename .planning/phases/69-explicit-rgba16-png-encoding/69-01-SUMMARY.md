---
phase: 69-explicit-rgba16-png-encoding
plan: 01
subsystem: png-encoder
tags: [moonbit, png, rgba16, u16, eager, preflight]
requires:
  - phase: 65-packed-rgba16-decode-model
    provides: Checked packed little-endian rgba16 descriptor and component-byte views.
  - phase: 66-explicit-rgba16-png-preservation
    provides: Explicit decoder used as an independent round-trip oracle.
provides:
  - Explicit eager PngEncoder::new_rgba16 factory family for non-interlaced PNG Type-6/16.
  - Exact packed little-endian RGBA16 to PNG big-endian component-lane mapping.
  - Atomic RGBA16 profile and output-limit rejection without widening generic encoding.
affects: [phase-70-rgba16-chunk-encoding, phase-71-rgba16-adam7-encoding, png-encoder]
tech-stack:
  added: []
  patterns:
    - Explicit high-precision encoder profiles reuse the existing bounded preflight and machine.
    - U16 source storage is mapped to PNG wire order once by the shared byte traversal.
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/encode.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
key-decisions:
  - "RGBA16 encoding is eager-only and non-interlaced in this phase."
  - "The existing profile-aware machine owns admission, accounting, filtering, compression, and output; no staging or alternate machine is introduced."
requirements-completed: [RGBA16ENC-01]
coverage:
  - id: D1
    description: Explicit eager RGBA16 output is Type-6/16, non-interlaced, and preserves every U16 lane byte exactly.
    requirement: RGBA16ENC-01
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#RGBA16 public eager tests
        status: pass
      - kind: integration
        ref: moon -C modules/mb-image test png --target wasm|wasm-gc|js|native --frozen
        status: pass
    human_judgment: false
  - id: D2
    description: Incompatible sources and one-byte-short output limits reject before writer output; generic encoding remains U8-only.
    requirement: RGBA16ENC-01
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#RGBA16 eager factory admission
        status: pass
    human_judgment: false
completed: 2026-07-23
status: complete
---

# Phase 69 Plan 01: Explicit RGBA16 PNG Encoding Summary

**Eager PNG encoding now writes checked packed `rgba16` images as non-interlaced Type-6/16 streams while preserving the generic RGB8/RGBA8 encoder contract.**

## Accomplishments

- Added four explicit eager `PngEncoder::new_rgba16*` factory shapes.
- Reused the existing profile-aware bounded encoder to emit `Rhi,Rlo,Ghi,Glo,Bhi,Blo,Ahi,Alo` for little-endian U16 storage.
- Added exact wire, explicit decode round-trip, factory, atomic rejection, and generic-compatibility tests.

## Task Commits

1. `9e78597` `feat(png): encode explicit rgba16 profile`
2. `d726aa2` `docs(69): add code review report`

## Verification

- Focused JS RGBA16 encoder suite: 2/2 passed.
- Ordinary PNG package: 247/247 passed on wasm, wasm-gc, js, and native.
- Standard code review: clean, no findings.

## Next Phase Readiness

Phase 70 can add caller-buffered RGBA16 construction through the same `Rgba16` profile without changing the eager wire contract. Adam7 selection remains Phase 71 scope.

## Self-Check: PASSED

The four planned implementation/test files, code-review report, verification report, and implementation commit are present.
