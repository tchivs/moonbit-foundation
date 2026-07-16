# mb-core

Portable safety and capability foundations for MoonBit Native Foundation.

`mb-core` is an independently versioned MoonBit module. Its Phase 1 package is a
buildable private scaffold only; public domain contracts begin in Phase 2.

## Status

Candidate. No API is stable yet, and the current package intentionally exposes
no public domain API.

Public publication is blocked until ownership of the intended
`moonbit-foundation` mooncakes.io namespace is verified. The local manifest uses
the final intended name `moonbit-foundation/mb-core` so consumers do not inherit
a later rename.

## Initial scope

`mb-core` owns shared byte containers, checked arithmetic, stream and seek
abstractions, bounded readers and writers, structured errors, diagnostics, and
explicit host-capability boundaries.

It does not own color, image, SVG, font, PDF, GUI, codec policy, or application
concepts. This Phase 1 scaffold introduces none of those future contracts.

## Supported targets

The module manifest and root package both declare the same support set:

| Target | Status |
| --- | --- |
| `js` | Required |
| `wasm` | Required |
| `wasm-gc` | Required |
| `native` | Required and preferred |

Native-only host adapters, when introduced, remain isolated leaf packages and
do not narrow this portable root package.

## Design commitments

- Implement core algorithms and shared data models in MoonBit.
- Keep the public dependency graph acyclic and directed toward `mb-core`.
- Require deterministic checks and tests across every declared target.
- Keep native FFI narrow, documented, replaceable, and outside portable packages.
- Mark public APIs experimental, candidate, or stable with their corresponding
  compatibility promise.
- Release this module on its own version and changelog lifecycle rather than in
  lockstep with `mb-color` or `mb-image`.

## Next step

Phase 2 replaces the private scaffold with bounded core primitives. Until then,
this checked document intentionally contains no fabricated public example API.
