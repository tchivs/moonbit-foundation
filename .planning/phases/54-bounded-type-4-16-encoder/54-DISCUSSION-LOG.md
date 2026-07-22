# Phase 54: Bounded Type-4/16 Encoder - Discussion Log

> **Audit trail only.** Decisions are captured in CONTEXT.md.

**Date:** 2026-07-23
**Phase:** 54-bounded-type-4-16-encoder
**Areas discussed:** public factory shape, U16 Type-4 wire mapping, bounded replay, compatibility

## Decisions

- Mirror explicit Gray16 and GrayAlpha8 eager/chunk factory families.
- Emit Type 4 / 16-bit / non-interlaced PNGs through one private profile and the existing bounded machine.
- Serialize pairs as `Ghi,Glo,Ahi,Alo`; keep all filters and compression strategies on the existing replay path.
- Preserve all existing factory bytes and defer public hostile/four-target evidence to Phase 55.
