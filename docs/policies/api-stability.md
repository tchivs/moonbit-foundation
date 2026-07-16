# API Stability Policy

## Status

All v0.1 public packages begin as candidate unless they are explicitly marked experimental. No MNF API is stable yet.

The machine-compared labels, current package status, target declarations, promotion order, and stable gate are owned by [`policy/foundation.json`](../../policy/foundation.json). This document explains those values; changing prose alone does not change policy.

## Active policy

- **Experimental** APIs carry no compatibility promise.
- **Candidate** API changes require migration notes that identify affected callers and the replacement path.
- **Stable** APIs follow Semantic Versioning.
- Promotion is ordered from experimental to candidate to stable; a package may start at candidate, but nothing may be described as stable until its public contract, conformance evidence, and release-policy gate all pass.
- A stable breaking change requires an accepted RFC, a major-version change, a migration guide, and compatibility qualification of every direct dependant.
- A stable removal requires deprecation in at least one prior minor release. A security exception may bypass that interval only when the exception and migration impact are documented.
- Stability and supported targets must appear in package documentation and checked metadata. Repository location and version numbers are not substitutes.

`PROH-GOV-03-PREMATURE-STABLE`: maintainers MUST NOT call an API stable before its contract, conformance evidence, and release-policy gate pass.

## Out of scope

- Numeric tolerances, image lifetime and layout semantics, resource-budget defaults, and the strict PPM subset are decided by their owning later phases.
- Candidate status is not a permanent compatibility floor and does not claim that the first public release has qualified as stable.

## Observable outcome

A consumer can determine a package's exact stability promise and supported targets from checked-in documentation and metadata, and automation can reject any mismatch against `policy/foundation.json`.
