# Phase 75: Packed Grayscale PNG Qualification - Context

**Discussed:** 2026-07-24
**Status:** Ready for planning

## Locked Decisions

### D-01: Qualification proves contracts, not just a green aggregate

Add or refine independent black-box evidence for all 1/2/4-bit outputs: literal
packed wire bytes, canonical decode behavior, caller-buffered lifecycle, and
frozen legacy routes. Production packing helpers or decoder internals cannot
be the sole oracle for a packing assertion.

### D-02: Cover eager and caller-buffered outputs

Qualification must prove eager/chunk byte identity under hostile capacities as
well as pre-output atomic rejection and sticky terminals for the explicit
low-bit profiles.

### D-03: Preserve all-target portability as the final gate

Use the ordinary frozen PNG package command across wasm, wasm-gc, js, and
native. Do not create target wrappers, copied source trees, release scripts,
or environment-specific test paths.

### D-04: Scope stays qualification-only

Do not add Adam7 low-bit output, palette/indexed writing, quantization,
strategy matrices, a bit-packed model, or FFI. If current Phase 73/74 tests
already satisfy an evidence item, document and retain them rather than
rebuilding production functionality.

## Success Criteria

1. Independent evidence proves low-bit PNG wire correctness and canonical
   decode semantics at 1/2/4 bits.
2. Lifecycle, atomicity, and legacy compatibility have explicit evidence.
3. The ordinary all-target PNG package gate passes with the final test set.
