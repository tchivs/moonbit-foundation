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

## Edge review results

- `EDGE-GOV-01-UNCLASSIFIED`: Pending Plan 01-08 review and disposition.
- `EDGE-GOV-02-UNCLASSIFIED`: Pending Plan 01-08 review and disposition.
- Blocking objections: Not yet assessed through the mandatory edge reviews.
