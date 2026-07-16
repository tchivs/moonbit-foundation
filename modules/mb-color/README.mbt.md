# mb-color

Explicit color semantics for MoonBit Native Foundation.

`mb-color` is an independently versioned MoonBit module. Its Phase 1 package is
a buildable private scaffold only; public color contracts begin in Phase 3.

## Status

The module has candidate status. No API is stable yet, and the current package
intentionally exposes no public domain API.

Public publication is blocked until ownership of the intended
`moonbit-foundation` mooncakes.io namespace is verified. The local manifest uses
the final intended name `moonbit-foundation/mb-color` so consumers do not inherit
a later rename.

## Initial scope

`mb-color` owns color component representations, transfer functions, color-space
identities, conversion pipelines, alpha conventions, and profile boundaries.

It does not own byte and stream foundations, image storage, SVG, font, PDF, GUI,
codec policy, or application concepts. It depends only on `mb-core`; this Phase 1
scaffold introduces none of the deferred color contracts.

## Supported targets

The module manifest and root package both declare the same support set:

| Target | Status |
| --- | --- |
| `js` | Required |
| `wasm` | Required |
| `wasm-gc` | Required |
| `native` | Required and preferred |

Native-only adapters, when introduced, remain isolated leaf packages and do not
narrow this portable root package.

## Design commitments

- Implement color algorithms and shared data models in MoonBit.
- Keep the public dependency graph acyclic, with `mb-color` depending only on
  `mb-core`.
- Require deterministic checks and tests across every declared target.
- Keep native FFI narrow, documented, replaceable, and outside portable packages.
- Mark public APIs experimental, candidate, or stable with their corresponding
  compatibility promise.
- Release this module on its own version and changelog lifecycle rather than in
  lockstep with `mb-core` or `mb-image`.

## Next step

Phase 3 replaces the private scaffold with explicit reference color semantics.
Until then, this checked document intentionally contains no fabricated public
example API.
