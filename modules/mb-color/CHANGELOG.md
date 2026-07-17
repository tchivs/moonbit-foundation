# Changelog

All notable changes to `moonbit-foundation/mb-color` will be recorded in this
file. This module follows an independent release lifecycle.

## 0.1.0 candidate (unpublished) - 2026-07-17

Compatibility status: candidate. Public changes require migration notes; no
stable API or registry publication is claimed.

### Added

- Candidate module metadata and explicit `js`, `wasm`, `wasm-gc`, and `native`
  target declarations.
- Five candidate public packages: `model`, `transfer`, `quantize`, `alpha`, and
  `profile`, with explicit color identity, reference sRGB transfer, deterministic
  ties-to-even quantization, distinct alpha states, and bounded opaque profile
  metadata.
- Four package-local generated vector tables for transfer, quantize, alpha, and
  profile conformance without runtime filesystem access.
- Executable public examples, exact numerical/profile contracts, target matrix,
  publication order, dependency DAG, provenance boundaries, and publication
  block documentation.
- Exact Apache-2.0, repository, description, four-target, and
  `moonbit-foundation/mb-core = 0.1.0` candidate manifest metadata.

### Removed

- The Phase 1 private root package, scaffold source, and scaffold white-box test;
  the candidate module now exposes only the five focused public packages.

Deferred: additional color spaces, gamut/CSS/interpolation features, full ICC
parsing or transforms, registry publication, LLVM support, and performance
claims.
