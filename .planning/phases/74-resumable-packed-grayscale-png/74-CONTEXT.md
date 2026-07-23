# Phase 74: Resumable Packed Grayscale PNG - Context

**Discussed:** 2026-07-23
**Status:** Ready for planning

<user_constraints>
## User Constraints

- Continue autonomously through the GSD workflow, choosing the best option when no material decision remains.
- Prioritize feature implementation and tests over release automation or copied-source workflows.
- Preserve portable MoonBit implementation and the existing single bounded PNG encoder machine.
</user_constraints>

<decisions>
## Locked Decisions

### D-01: Add only explicit caller-buffered low-bit selectors

Add `PngChunkEncoder::new_gray1`, `new_gray2`, and `new_gray4`, each fixed to
Stored DEFLATE, filter None, and non-interlaced output. Do not add public
strategy-taking overloads, generic-constructor widening, or a new transport.

### D-02: Reuse the Phase 73 profile and bounded machine

The new factories must call `PngEncodeMachine::new_with_profile` with Phase
73's existing private profiles. There is no packed staging buffer, duplicate
row provider, source-model change, or second encoder state machine.

### D-03: Preserve caller-buffered semantics exactly

Admission errors occur before a lease is exposed and leave caller budgets
unchanged. After admission, hostile zero/small output capacities, retry,
acknowledgement, and terminal paths retain the existing lease ownership and
sticky typed terminal behavior.

### D-04: Prove byte identity and lifecycle safety

For all three depths, completed chunk output must equal its Phase 73 eager
counterpart for the same canonical source. Tests must cover fragmented/hostile
capacities, all-depth atomic rejection, and sticky terminal behavior without
depending on the production packing helper as an oracle.

### D-05: Keep deferred scope deferred

No Adam7, compression/filter strategy matrices, palette/index encoding,
bit-packed model, implicit conversion, release automation, wrappers, copied
trees, or FFI belongs in this phase.
</decisions>

<success_criteria>
## Phase Success Criteria

1. The three explicit chunk selectors are the only new public APIs.
2. Valid canonical Gray/U8 sources complete through caller-owned leases with
   bytes identical to the matching eager selector.
3. Invalid levels reject atomically before any lease/budget exposure.
4. Existing hostile lease and sticky-terminal semantics remain true at every
   low-bit depth.
</success_criteria>

<deferred>
## Deferred Ideas

- Broad strategy and interlace matrices, including Adam7 low-bit output.
- Palette/index source and encoding support.
- Qualification-only independent decode vectors and the final all-target audit
  reserved for Phase 75.
</deferred>
