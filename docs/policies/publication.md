# Publication Policy

## Status

Public publication is blocked. [`policy/registry-authority.json`](../../policy/registry-authority.json) owns the intended personal owner and exact module identities; [`policy/release-qualification.json`](../../policy/release-qualification.json) owns the candidate versions, dependency graph, repository metadata, and publication blocker. Prose cannot clear either machine gate.

## Publication boundary

The monorepo coordinates three modules; it is not a consumer-facing umbrella. Each module has its own manifest, `0.1.0` starting version, changelog, documentation, tests, and publication lifecycle. Releases are independent and do not require lockstep versions.

The initial canonical identities are `tchivs/mb-core`, `tchivs/mb-color`, and `tchivs/mb-image`. They use the sole maintainer's personal Mooncakes namespace while the project brand remains **MoonBit Native Foundation**. No version was published under the superseded bootstrap owner, so this correction keeps `0.1.0` and requires no migration note. Publication remains forbidden until the authenticated `tchivs` Mooncakes account, exact namespace authority, version availability, observation, and resolution facts are current and the machine-owned block is cleared.

`https://github.com/tchivs/moonbit-foundation` is intended repository metadata, not a verified-live source, support, or security route. Release readiness requires a later read-only existence check; this policy does not authorize repository creation or external writes.

If an organization namespace becomes available later, its modules are new identities and require an explicit forward migration and publication plan. Automation must not assume rename, transfer, overwrite, delete, unpublish, or yank behavior.

No `mnf/all`, equivalent umbrella module, self-edge, reverse edge, cycle, or undeclared public dependency may be introduced. Allowed public edges point inward and downward exactly as recorded in the canonical policy.

## Release lifecycle

1. A module remains candidate while its contract and evidence are being qualified.
2. A release must preserve the module's own version and history rather than synchronize unrelated modules.
3. Stable qualification follows the adjacent stability promises and ordered gates in the canonical policy.
4. A new module, public dependency-direction change, or breaking architectural boundary change requires an accepted RFC before merge.
5. Publication automation must fail closed while the canonical publication block is true; no token or manual command may bypass it.

## Evidence

An Accepted RFC must carry the authority route, approval or public-review evidence, objection disposition, and transition history required by the RFC process. Empty or disputed evidence retains the less advanced status and cannot authorize publication.
