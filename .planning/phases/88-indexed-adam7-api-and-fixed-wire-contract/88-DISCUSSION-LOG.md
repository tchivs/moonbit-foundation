# Phase 88 Discussion Log

**Mode:** `--auto` (user-authorized optimal defaults)
**Gathered:** 2026-07-24

## Domain Boundary

Phase 88 defines only additive Indexed Adam7 compression API and the exact
Fixed-vs-Stored pass-local wire contract. Phase 89 owns admission/machine
integration; Phase 90 owns hostile and independent qualification.

## Auto-Resolved Decisions

1. **API compatibility:** Add paired `with_interlace_and_compression_strategy`
   eager/chunk selectors; preserve existing interlace-only methods as Stored
   forwards.
2. **Depth coverage:** Include Indexed1, Indexed2, Indexed4, and Indexed8 in
   one coherent contract rather than introducing a second partial API.
3. **Pass packing:** Restart each Adam7 pass at local column zero, pack low-bit
   samples MSB-first, and zero unused tail bits.
4. **Selection rule:** Compare complete palette-aware PNG frame facts and select
   Fixed on win or tie; retain Stored otherwise.
5. **Scope guard:** Exclude Dynamic, adaptive filters, wider matching, staging,
   decoder changes, FFI, and release work.

## Open Implementation Questions Delegated to Planner

- Private cursor and state names, provided they preserve the single bounded
  producer and existing acknowledgement machine.
- Exact test fixture dimensions, provided odd/narrow pass tails and all depths
  are exercised.

## Next Step

Proceed to `$gsd-plan-phase 88`.
