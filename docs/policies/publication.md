# Publication Policy

## Status

Public publication is blocked. The authoritative block flag, reason, intended owner namespace, module identities, versions, and dependency edges are owned by [`policy/foundation.json`](../../policy/foundation.json).

## Publication boundary

The monorepo coordinates three modules; it is not a consumer-facing umbrella. Each module has its own manifest, `0.1.0` starting version, changelog, documentation, tests, and publication lifecycle. Releases are independent and do not require lockstep versions.

The final intended identities are `moonbit-foundation/mb-core`, `moonbit-foundation/mb-color`, and `moonbit-foundation/mb-image`. Local manifests use those names to avoid a later rename, but `PROH-GOV-04-NAMESPACE-PUBLISH` forbids publishing under them until ownership of the intended mooncakes.io namespace is verified and the canonical block is cleared.

No `mnf/all`, equivalent umbrella module, self-edge, reverse edge, cycle, or undeclared public dependency may be introduced. Allowed public edges point inward and downward exactly as recorded in the canonical policy.

## Release lifecycle

1. A module remains candidate while its contract and evidence are being qualified.
2. A release must preserve the module's own version and history rather than synchronize unrelated modules.
3. Stable qualification follows the adjacent stability promises and ordered gates in the canonical policy.
4. A new module, public dependency-direction change, or breaking architectural boundary change requires an accepted RFC before merge.
5. Publication automation must fail closed while the canonical publication block is true; no token or manual command may bypass it.

## Evidence

An Accepted RFC must carry the authority route, approval or public-review evidence, objection disposition, and transition history required by the RFC process. Empty or disputed evidence retains the less advanced status and cannot authorize publication.
