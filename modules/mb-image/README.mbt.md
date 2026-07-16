# mb-image

Portable image foundations for MoonBit Native Foundation.

`mb-image` is an independently versioned MoonBit module. Its Phase 1 package is
a buildable private scaffold only; public image contracts begin in Phase 4.

## Status

The module has candidate status. No API is stable yet, and the current package
intentionally exposes no public domain API.

Public publication is blocked until ownership of the intended
`moonbit-foundation` mooncakes.io namespace is verified. The local manifest uses
the final intended name `moonbit-foundation/mb-image` so consumers do not inherit
a later rename.

## Initial scope

`mb-image` owns image storage, pixel formats, image views, transforms, and codec
interfaces.

It does not own byte and stream foundations, color semantics, SVG, font, PDF,
GUI, system codec implementations, or application concepts. It depends on
`mb-core` and `mb-color`; this Phase 1 scaffold introduces none of the deferred
image or codec contracts.

## Supported targets

The module manifest and root package both declare the same support set:

| Target | Status |
| --- | --- |
| `js` | Required |
| `wasm` | Required |
| `wasm-gc` | Required |
| `native` | Required and preferred |

Native-only system codec adapters, when introduced, remain isolated leaf
packages and do not narrow this portable root package.

## Design commitments

- Implement image algorithms and shared data models in MoonBit.
- Keep the public dependency graph acyclic, with `mb-image` depending only on
  `mb-core` and `mb-color`.
- Require deterministic checks and tests across every declared target.
- Keep native FFI narrow, documented, replaceable, and outside portable packages.
- Mark public APIs experimental, candidate, or stable with their corresponding
  compatibility promise.
- Release this module on its own version and changelog lifecycle rather than in
  lockstep with `mb-core` or `mb-color`.

## Next step

Phase 4 replaces the private scaffold with explicit image storage and view
contracts. Until then, this checked document intentionally contains no
fabricated public example API.
