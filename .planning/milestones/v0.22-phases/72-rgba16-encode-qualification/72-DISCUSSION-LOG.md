# Phase 72 Discussion Log

**Mode:** Autonomous best-choice continuation
**Date:** 2026-07-23

## Decision Record

The project owner authorized continuation through the GSD workflow and asked
that implementation and tests take precedence over elaborate release scripts.
This qualification phase therefore uses the established public PNG harnesses
and the ordinary multi-target package command only.

| Decision | Chosen approach | Reason |
| --- | --- | --- |
| Evidence boundary | Public wire parsing, inflate, explicit decode, and caller-buffered APIs | Avoids testing private encoder internals as the oracle. |
| Portability | One ordinary `png --target all --frozen` suite | Covers all supported production targets without wrappers or copied trees. |
| Scope | Tests and qualification artifacts first | Phase 69–71 already implemented the encoder; no feature work is justified absent a demonstrated defect. |
| Compatibility | Reuse existing frozen public vectors | Preserves established behavior without manufacturing redundant baselines. |

## Locked Exclusions

- Release, publish, and target-wrapper scripts.
- Copied source trees or phase-local debug/recover build directories.
- FFI, staging buffers, color transforms, generic API widening, or another
  pass planner/encoder machine.
