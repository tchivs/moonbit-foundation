---
milestone: v0.20
name: High-Precision GrayAlpha Decode
audited: 2026-07-23T16:58:00+08:00
status: passed
requirements: 3/3
phases: 3/3
integration_score: 100/100
flows: 4/4
---

# v0.20 Milestone Audit — High-Precision GrayAlpha Decode

## Verdict

**PASS.** The milestone delivers an explicit, portable, high-precision Type-4/16 GrayAlpha PNG decode contract while preserving the historical generic RGBA8 behavior.

## Requirements

| Requirement | Phase | Status | Evidence |
| --- | --- | --- | --- |
| GRA16DEC-01 | 62 | ✓ Complete | `decode_graya16` preserves the existing little-endian `graya16` component bytes for legal encoded-sRGB Type-4/16 input; generic decoding remains high-byte RGBA8. |
| GRA16DEC-02 | 63 | ✓ Complete | `new_graya16` selects the same bounded machine and preserves eager parity, accepted-only progress, atomic failure, and sticky terminals. |
| GRA16DEC-03 | 64 | ✓ Complete | Independent filter/Adam7 vectors, hostile/resource regressions, frozen generic compatibility, and `moon -C modules/mb-image test png --target all --frozen`: 235/235 on wasm, wasm-gc, js, native. |

## Cross-Phase Integration

| Flow | Status | Evidence |
| --- | --- | --- |
| Explicit eager selector → shared profile → packed U16 result | ✓ PASS | Phase 62 selector uses the established decode machine and `graya16` descriptor/storage. |
| Explicit chunk selector → shared profile → finish-only result | ✓ PASS | Phase 63 adds only the public factory; chunk lifecycle and terminal state remain shared. |
| Adam7/profile handoff → U16 lane store | ✓ PASS | Phase 64 removes only the explicit interlace prohibition and threads the profile to Adam7 scatter, leaving generic high-byte expansion intact. |
| Portable qualification | ✓ PASS | Direct unwrapped full PNG package command passed all four targets. |

## Scope and Quality

- No alternate decoder, source-sized staging buffer, generic result widening, conversion API, FFI, wrapper, copied source tree, or release automation was added.
- The generic decoder remains explicitly lossy for Type-4/16: `RGBA8(Ghi,Ghi,Ghi,Ahi)`.
- Existing profile rejections for incompatible type/depth, transparency, legacy colour declarations, and ICC input remain covered.

## Gaps

None within v0.20 scope. Deferred colour-managed/non-sRGB conversion and public conversion APIs remain explicitly future work.
