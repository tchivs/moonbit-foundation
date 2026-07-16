# Changelog

All notable changes to `moonbit-foundation/mb-color` will be recorded in this
file. This module follows an independent release lifecycle.

## Unreleased

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

### Removed

- The Phase 1 private root package, scaffold source, and scaffold white-box test;
  the candidate module now exposes only the five focused public packages.

No public release is claimed by this entry.
