# Changelog

All notable changes to `moonbit-foundation/mb-core` will be recorded in this
file. This module follows an independent release lifecycle.

## Unreleased

### Added

- Six candidate public packages in the dependency order `error`, `checked`,
  `budget`, `bytes`, `io`, and `host`, each supporting `js`, `wasm`, `wasm-gc`,
  and `native`.
- Structured errors and deterministic diagnostics; checked arithmetic, ranges,
  offsets, dimensions, and backend narrowing; atomic hierarchical budgets.
- Owned byte storage, retained immutable views, exclusive mutable leases,
  backend-neutral exact/bounded I/O, separate seeking, and explicitly injected
  host-capability contracts with portable deterministic fakes.
- Executable public examples covering the complete Phase 2 contract spine and
  the distinction between structured allocator/budget rejection and
  unrecoverable physical runtime OOM.

### Removed

- The private Phase 1 root scaffold package and its white-box probe.

No public release is claimed by this entry.
