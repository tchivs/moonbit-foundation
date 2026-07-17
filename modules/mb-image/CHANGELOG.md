# Changelog

All notable changes to `moonbit-foundation/mb-image` will be recorded in this
file. This module follows an independent release lifecycle.

## 0.1.0 candidate (unpublished) - 2026-07-17

Compatibility status: candidate. Public changes require migration notes; no
stable API or registry publication is claimed.

### Added

- Six rootless public candidate packages: `metadata`, `model`, `storage`,
  `ops`, `codec`, and `ppm`.
- Explicit validated image descriptors, retained immutable views,
  callback-scoped mutable leases, and zero-copy representable crops.
- Deterministic copy, flips, Exif orientation application, nearest resize, and
  closed packed-U8 pixel conversions with executable metadata disposition.
- Prefix-only probing and forward-only Reader/Writer codec contracts with
  explicit options, limits, budgets, diagnostics, and byte progress.
- Generated adversarial evidence and four-target fail-closed qualification.
- The MNF strict PPM P6/sRGB subset with bounded forward-only decoding,
  canonical logical-row encoding, deterministic conformance fixtures, and two
  public decode-transform-encode consumers.
- Exact Apache-2.0, repository, description, four-target, and named `0.1.0`
  mb-core/mb-color candidate dependency metadata.

Deferred: wider/full PPM behavior, PNG/JPEG/WebP, production codec breadth,
registries/filesystem policy, publication, LLVM support, and performance
claims.
