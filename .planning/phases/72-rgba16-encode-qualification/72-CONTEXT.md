# Phase 72: RGBA16 Encode Qualification - Context

**Gathered:** 2026-07-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Qualify the completed explicit RGBA16 PNG encoder through public, independent
normal and Adam7 evidence. The phase proves exact Type-6/16 lanes, bounded
caller-buffered failures, frozen legacy behavior, and the ordinary full PNG
package across wasm, wasm-gc, js, and native. It is a qualification phase, not
new encoder, release, or build-system work.

</domain>

<decisions>
## Implementation Decisions

### Independent fidelity proof

- **D-01:** Retain or strengthen deterministic non-symmetric normal and Adam7
  RGBA16 source vectors that independently parse/inflate PNG wire bytes and
  explicitly decode all packed little-endian U16 source lanes. Encoder output
  must not be the sole oracle for either route.
- **D-02:** Exercise both public eager and caller-buffered RGBA16 selector
  families, including explicit Adam7 selection. Cross the legal three
  compression strategies and two filter strategies where existing public
  harnesses already express that matrix.

### Bounded and compatibility behavior

- **D-03:** Qualify hostile public admission and lifecycle behavior without
  changing production semantics: incompatible descriptors and capability,
  output, work, budget, source-revision, and released-lease failures must be
  atomic, acknowledged-only where applicable, tail-safe, and sticky.
- **D-04:** Freeze the established legacy RGB8/RGBA8 and Gray/GrayAlpha normal
  and Adam7 behavior using the smallest existing public compatibility vectors;
  do not widen generic descriptor admission or change legacy byte output.

### Portability and scope

- **D-05:** Run the ordinary full `png` package suite with `--target all` and
  `--frozen`. Keep tests in the existing source package; do not create target
  wrappers, release scripts, copied source trees, or persistent debug/recovery
  build directories.
- **D-06:** Production changes are forbidden unless a public qualification test
  exposes a real contract defect. Any such fix remains narrow, goes through the
  plan's deviation protocol, and does not add staging, FFI, a second pass
  planner, color conversion, or alternate encoder paths.

### the agent's Discretion

- Reuse the closest Phase 55, 58, and 61 public-evidence fixtures, wire parser,
  drain helpers, and frozen compatibility assertions. Prefer the smallest
  tests-only change that closes an actual evidence gap.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### v0.22 contract

- `.planning/ROADMAP.md` — Phase 72 goal, success criteria, and exclusions.
- `.planning/REQUIREMENTS.md` — `RGBA16ENC-04` qualification requirement.
- `.planning/phases/69-explicit-rgba16-png-encoding/69-VERIFICATION.md` —
  normal Type-6/16 source-fidelity baseline.
- `.planning/phases/70-resumable-rgba16-png-encoding/70-VERIFICATION.md` —
  caller-buffered admission and lifecycle baseline.
- `.planning/phases/71-rgba16-adam7-png-encoding/71-VERIFICATION.md` —
  explicit Adam7 factories and seven-pass fidelity baseline.

### Closest qualification patterns

- `.planning/milestones/v0.17-phases/55-portable-public-evidence/55-CONTEXT.md`
  — normal high-precision public qualification pattern.
- `.planning/milestones/v0.18-phases/58-portable-adam7-public-evidence/58-CONTEXT.md`
  — high-precision Adam7 public evidence and four-target boundary.
- `.planning/milestones/v0.19-phases/61-portable-grayalpha8-adam7-public-evidence/61-CONTEXT.md`
  — latest Adam7 qualification and compatibility pattern.

### Public PNG seams

- `modules/mb-image/png/encode_test.mbt` — eager public wire, inflate, and
  exact decoder-lane checks.
- `modules/mb-image/png/stream_encode_test.mbt` — caller leases, hostile
  resources, source replay, and generic-constructor checks.
- `modules/mb-image/png/png_test.mbt` and existing package tests — frozen
  compatibility corpus exercised by the normal full-package command.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Phase 71 already has a 5x5 all-seven-pass RGBA16 Adam7 coordinate-derived
  raster oracle and full `decode_rgba16` lane reconstruction.
- Existing eager and chunk RGBA16 tests cover public strategy selection,
  zero/one/ragged leases, resource admission, released leases, and source
  mutation terminal replay.
- The package-level `moon ... test png --target all --frozen` command is the
  intended portability evidence; no phase-local launcher is needed.

### Established Patterns

- Fresh eager output is valid only as a caller-buffered parity oracle; wire
  fidelity needs a separately derived expected raster or fixed fixture.
- High-precision wire order is PNG big-endian while the documented `rgba16`
  storage model is packed little-endian; qualification must assert both sides.
- Public qualification adds tests and reports, not an implementation parallel
  to the encoder.

### Integration Points

- Work remains in existing PNG test files and Phase 72 planning artifacts.
- The final target run must be the ordinary package test invocation, not a
  generated script or copied test tree.

</code_context>

<specifics>
## Specific Ideas

The user explicitly prioritizes implementation and test evidence over release
automation and asked that no copied-source debug/recover artifacts accumulate.
Automatic decisions therefore choose a tests-first, source-tree-only
qualification path.

</specifics>

<deferred>
## Deferred Ideas

No release automation, registry publishing, target wrappers, source copies,
staging encoder, FFI, color conversion, Big-endian model support, generic
constructor widening, or another encoder/pass planner.

</deferred>

---

*Phase: 72-rgba16-encode-qualification*
*Context gathered: 2026-07-23*
