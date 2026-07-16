# Decision 0001: Sole project-owner bootstrap for RFC 0001

- **Decision identity:** `sole-project-owner`
- **Acceptance route:** `sole-project-owner-bootstrap`
- **Applies to:** RFC 0001 only
- **Current effect:** Conditional preauthorization; RFC 0001 remains Proposed until all conditions below pass

## Owner instruction

> 现在只有我一个人开发，跳过

The transparent repository identity for the speaker is `sole-project-owner`. No legal name or
email address is inferred.

## Conversation context and interpretation

The instruction answered the assistant's request for authentic D-03 acceptance evidence after
the original two-maintainer and seven-day project-lead routes had blocked Plan 01-08. It is
interpreted as the sole project owner's authentic preauthorization to pass RFC 0001's acceptance
gate once both mandatory edge reviews complete without any unresolved blocking objection.

## Authorization and conditions

This instruction is the approval that Plan 01-08 consumes. It does not authorize an agent to
synthesize or record a later approval. No second maintainer approval and no seven-day public-review
interval are claimed.

The authorization is valid only while `policy/maintainers.json` contains exactly one unique
maintainer identity, that identity is `sole-project-owner`, and it has the `project-owner` role.
Before acceptance, `EDGE-GOV-01-UNCLASSIFIED` and `EDGE-GOV-02-UNCLASSIFIED` must both be completed
and dispositioned, with no unresolved blocking objection. Eligibility expires immediately if the
canonical roster contains more than one distinct maintainer.

- `AUTH-ONE-OWNER`: Eligibility requires the canonical roster to contain exactly one unique maintainer identity with the project-owner role.
- `AUTH-EXPIRES-SECOND-MAINTAINER`: Eligibility expires immediately when a second distinct maintainer is present.
- `AUTH-TWO-EDGE-REVIEWS`: EDGE-GOV-01-UNCLASSIFIED and EDGE-GOV-02-UNCLASSIFIED must both be completed and dispositioned.
- `AUTH-NO-LATER-APPROVAL`: The recorded owner instruction is consumed; no later approval may be synthesized.

## Edge review results

- `EDGE-GOV-01-UNCLASSIFIED`: **Completed. Disposition: no-omission-found.** Scope reviewed:
  the architecture diagram and arrow meaning; the exact three allowed v0.1 dependency edges;
  owned and excluded responsibilities for `mb-core`, `mb-color`, and `mb-image`; deferred-layer
  ownership; the portable-core/native-leaf adapter seam; the v0.1 inclusion and exclusion boundary;
  and the accepted-RFC gate for new modules, public dependency-direction changes, and breaking
  public boundaries. Result: the charter covers each reviewed boundary explicitly, forbids reverse,
  cyclic, self, and undeclared public edges, and leaves the five later-phase design topics deferred
  rather than silently deciding them. No material architectural omission or blocking objection was
  found.
- `EDGE-GOV-02-UNCLASSIFIED`: **Completed. Disposition: no-omission-found.** Scope reviewed:
  every state and permitted transition in the lifecycle table; the terminal behavior of `Rejected`
  and `Superseded`; transition-ledger and replacement-RFC evidence; all three mutually exclusive
  acceptance routes; the roster conditions and expiry of both single-maintainer routes; exact
  route-specific evidence; objection resolution, withdrawal, or rejecting disposition; and
  RFC-header/index/policy synchronization. Result: each transition and authority case is explicit,
  the sole-owner route is limited to the exact RFC 0001 decision artifact and current one-owner
  roster, and missing or conflicting evidence fails closed to the less advanced truthful state. No
  omitted transition, omitted authority case, or blocking objection was found.
- Unresolved blocking objections: **none**.
