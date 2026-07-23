---
phase: 59-grayalpha8-adam7-factory-and-pass-profile
audited: 2026-07-23
verdict: SECURED
threats_closed: 9
threats_open: 0
asvs_level: 1
---

# Phase 59: Security Verification

## Verdict

**SECURED.** All nine Phase 59 threats are mitigated; no unregistered flag was
identified. The U8 source-mutation/replay guard remains deliberately deferred to
Phase 60 and is not claimed by this phase.

## Evidence

- Public admission retains packed, sRGB, top-left, straight-alpha, U8, and
  tight-row checks. The only lifted gate is the former GrayAlpha8 Adam7 ban.
- The existing checked Adam7 pass geometry and scalar wire reads remain the sole
  raster traversal. No image/pass staging or alternate encoder was added.
- Eager and caller-buffered factories both enter the existing
  `PngEncodeMachine::new_with_profile` path and its shared source, geometry,
  output, work, and budget ledger.
- Legacy constructors explicitly retain `None`; frozen Type-4/8 method-0 byte
  tests cover both eager and caller-buffered output.
- Independent non-symmetric `G,A` pass-wire coverage, all six filter/compression
  combinations, and fresh eager/chunk parity cover the new selectable surface.

## Verification

`moon -C modules/mb-image test png --target native --frozen` completed with
**223 passed, 0 failed** on 2026-07-23.
